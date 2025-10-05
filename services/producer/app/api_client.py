import aiohttp
import logging
import os
from typing import List, Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)

# For MVP, we'll use Football-Data.org API
# Get your free API key from: https://www.football-data.org/client/register
API_BASE_URL = "https://api.football-data.org/v4"
API_KEY = os.getenv("FOOTBALL_API_KEY", "")

# EPL Competition ID
EPL_COMPETITION_ID = "PL"

async def fetch_epl_events() -> List[Dict[str, Any]]:
    """
    Fetch live EPL match events from Football-Data.org API

    Returns a list of match event dictionaries
    """
    if not API_KEY:
        logger.warning("FOOTBALL_API_KEY not set - using mock data")
        return get_mock_events()

    headers = {
        "X-Auth-Token": API_KEY
    }

    try:
        async with aiohttp.ClientSession() as session:
            # Fetch matches for today
            url = f"{API_BASE_URL}/competitions/{EPL_COMPETITION_ID}/matches"
            params = {
                "status": "LIVE,IN_PLAY,PAUSED"  # Only get live matches
            }

            async with session.get(url, headers=headers, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    matches = data.get("matches", [])

                    events = []
                    for match in matches:
                        event = transform_match_to_event(match)
                        events.append(event)

                    return events

                elif response.status == 429:
                    logger.warning("API rate limit exceeded - using mock data")
                    return get_mock_events()

                else:
                    logger.error(f"API request failed with status {response.status}")
                    return get_mock_events()

    except Exception as e:
        logger.error(f"Error fetching EPL events: {e}", exc_info=True)
        return get_mock_events()

def transform_match_to_event(match: Dict[str, Any]) -> Dict[str, Any]:
    """Transform Football-Data.org match object to our event schema"""
    return {
        "event_type": "match_update",
        "match_id": match.get("id"),
        "competition": "Premier League",
        "status": match.get("status"),
        "utc_date": match.get("utcDate"),
        "matchday": match.get("matchday"),
        "home_team": {
            "id": match.get("homeTeam", {}).get("id"),
            "name": match.get("homeTeam", {}).get("name"),
            "short_name": match.get("homeTeam", {}).get("shortName"),
            "tla": match.get("homeTeam", {}).get("tla"),
        },
        "away_team": {
            "id": match.get("awayTeam", {}).get("id"),
            "name": match.get("awayTeam", {}).get("name"),
            "short_name": match.get("awayTeam", {}).get("shortName"),
            "tla": match.get("awayTeam", {}).get("tla"),
        },
        "score": {
            "home": match.get("score", {}).get("fullTime", {}).get("home"),
            "away": match.get("score", {}).get("fullTime", {}).get("away"),
            "half_time_home": match.get("score", {}).get("halfTime", {}).get("home"),
            "half_time_away": match.get("score", {}).get("halfTime", {}).get("away"),
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
