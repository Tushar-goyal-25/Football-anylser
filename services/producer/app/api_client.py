import aiohttp
import logging
import os
from typing import List, Dict, Any
from datetime import datetime, timedelta
from cache import (
    cache_finished_matches,
    get_cached_match,
    should_fetch_from_api,
    set_last_fetch_time,
    get_redis_client
)

logger = logging.getLogger(__name__)

# For MVP, we'll use Football-Data.org API
# Get your free API key from: https://www.football-data.org/client/register
API_BASE_URL = "https://api.football-data.org/v4"
API_KEY = os.getenv("FOOTBALL_API_KEY", "")

# EPL Competition ID
EPL_COMPETITION_ID = "PL"

# Mock data toggle (set to "true" to enable mock live matches)
ENABLE_MOCK_DATA = os.getenv("ENABLE_MOCK_DATA", "false").lower() == "true"

async def fetch_epl_events() -> List[Dict[str, Any]]:
    """
    Fetch live EPL match events with adaptive smart caching

    Strategy:
    - Finished matches: Cached for 24 hours (won't change)
    - LIVE matches (IN_PLAY): Fetched every 30 seconds
    - Scheduled/No live matches: Fetched every 10 minutes
    - Historical matches: Fetched every 5 minutes

    Returns a list of match event dictionaries
    """
    if not API_KEY:
        logger.warning("FOOTBALL_API_KEY not set")
        return get_mock_events() if ENABLE_MOCK_DATA else []

    # Check if there are any live matches from last check
    client = get_redis_client()
    has_live_matches = False
    if client:
        has_live_matches = client.get("has_live_matches") == "true"

    # Adaptive intervals based on match state
    if has_live_matches:
        live_interval = 30  # 30 seconds when matches are LIVE
    else:
        live_interval = 600  # 10 minutes when no live matches

    should_fetch_live = should_fetch_from_api("last_fetch:live", interval_seconds=live_interval)
    should_fetch_history = should_fetch_from_api("last_fetch:history", interval_seconds=300)

    all_events = []
    current_has_live = False

    # Fetch today's matches
    if should_fetch_live:
        live_events = await fetch_matches_for_date_range(
            datetime.utcnow().date(),
            datetime.utcnow().date() + timedelta(days=1)
        )

        # Check if any match is actually LIVE
        for event in live_events:
            if event.get("status") in ["IN_PLAY", "LIVE", "PAUSED"]:
                current_has_live = True
                break

        all_events.extend(live_events)
        set_last_fetch_time("last_fetch:live")

        # Update live status in Redis
        if client:
            client.setex("has_live_matches", timedelta(minutes=2), "true" if current_has_live else "false")

        if current_has_live:
            logger.info(f"🔴 LIVE: Fetched {len(live_events)} matches (polling every 30s)")
        else:
            logger.info(f"Fetched {len(live_events)} today's matches (no live, next check in 10min)")

    # Fetch historical matches less frequently
    if should_fetch_history:
        history_events = await fetch_matches_for_date_range(
            datetime.utcnow().date() - timedelta(days=10),
            datetime.utcnow().date() - timedelta(days=1)
        )

        # Cache finished matches
        cache_finished_matches(history_events)

        all_events.extend(history_events)
        set_last_fetch_time("last_fetch:history")
        logger.info(f"Fetched {len(history_events)} historical matches")

    # If no API fetch was needed
    if not should_fetch_live and not should_fetch_history:
        status = "live matches ongoing" if has_live_matches else "no live matches"
        logger.info(f"Using cached data ({status}, no API call)")
        return []

    # Add mock data if enabled
    if ENABLE_MOCK_DATA:
        mock_events = get_mock_events()
        all_events.extend(mock_events)

    return all_events


async def fetch_matches_for_date_range(date_from: datetime.date, date_to: datetime.date) -> List[Dict[str, Any]]:
    """Fetch matches for a specific date range"""
    headers = {"X-Auth-Token": API_KEY}

    try:
        async with aiohttp.ClientSession() as session:
            url = f"{API_BASE_URL}/competitions/{EPL_COMPETITION_ID}/matches"
            params = {
                "dateFrom": date_from.strftime("%Y-%m-%d"),
                "dateTo": date_to.strftime("%Y-%m-%d")
            }

            async with session.get(url, headers=headers, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    matches = data.get("matches", [])

                    events = []
                    for match in matches:
                        # Check cache first for finished matches
                        match_id = str(match.get("id"))
                        if match.get("status") == "FINISHED":
                            cached_event = get_cached_match(match_id)
                            if cached_event:
                                events.append(cached_event)
                                continue

                        event = transform_match_to_event(match)
                        events.append(event)

                    return events

                elif response.status == 429:
                    logger.warning("API rate limit exceeded")
                    return []
                else:
                    logger.error(f"API request failed with status {response.status}")
                    return []

    except Exception as e:
        logger.error(f"Error fetching matches: {e}", exc_info=True)
        return []

def transform_match_to_event(match: Dict[str, Any]) -> Dict[str, Any]:
    """Transform Football-Data.org match object to our event schema"""
    return {
        "event_type": "match_update",
        "match_id": str(match.get("id")),
        "competition": "Premier League",
        "status": match.get("status"),
        "utc_date": match.get("utcDate"),
        "matchday": match.get("matchday"),
        "home_team": {
            "id": str(match.get("homeTeam", {}).get("id")),
            "name": match.get("homeTeam", {}).get("name"),
            "short_name": match.get("homeTeam", {}).get("shortName"),
            "tla": match.get("homeTeam", {}).get("tla"),
        },
        "away_team": {
            "id": str(match.get("awayTeam", {}).get("id")),
            "name": match.get("awayTeam", {}).get("name"),
            "short_name": match.get("awayTeam", {}).get("shortName"),
            "tla": match.get("awayTeam", {}).get("tla"),
        },
        "score": {
            "home": match.get("score", {}).get("fullTime", {}).get("home") or 0,
            "away": match.get("score", {}).get("fullTime", {}).get("away") or 0,
            "half_time_home": match.get("score", {}).get("halfTime", {}).get("home") or 0,
            "half_time_away": match.get("score", {}).get("halfTime", {}).get("away") or 0,
        },
        "timestamp": datetime.utcnow().isoformat(),
    }

def get_mock_events() -> List[Dict[str, Any]]:
    """
    Generate mock EPL events for testing without API key
    """
    return [
        {
            "event_type": "match_update",
            "match_id": 12345,
            "competition": "Premier League",
            "status": "IN_PLAY",
            "utc_date": datetime.utcnow().isoformat(),
            "matchday": 10,
            "home_team": {
                "id": 1,
                "name": "Arsenal FC",
                "short_name": "Arsenal",
                "tla": "ARS",
            },
            "away_team": {
                "id": 2,
                "name": "Chelsea FC",
                "short_name": "Chelsea",
                "tla": "CHE",
            },
            "score": {
                "home": 2,
                "away": 1,
                "half_time_home": 1,
                "half_time_away": 0,
            },
            "timestamp": datetime.utcnow().isoformat(),
        },
        {
            "event_type": "match_update",
            "match_id": 12346,
            "competition": "Premier League",
            "status": "IN_PLAY",
            "utc_date": datetime.utcnow().isoformat(),
            "matchday": 10,
            "home_team": {
                "id": 3,
                "name": "Liverpool FC",
                "short_name": "Liverpool",
                "tla": "LIV",
            },
            "away_team": {
                "id": 4,
                "name": "Manchester City FC",
                "short_name": "Man City",
                "tla": "MCI",
            },
            "score": {
                "home": 1,
                "away": 1,
                "half_time_home": 0,
                "half_time_away": 1,
            },
            "timestamp": datetime.utcnow().isoformat(),
        }
    ]
