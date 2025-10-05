import logging
from typing import Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)

def transform_event(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Transform raw event data into structured format for storage

    Cleans data, calculates KPIs, and structures for DynamoDB/S3
    """
    try:
        match_id = event.get("match_id")
        score = event.get("score", {})

        # Calculate aggregated KPIs
        home_score = score.get("home", 0) or 0
        away_score = score.get("away", 0) or 0
        total_goals = home_score + away_score

        ht_home = score.get("half_time_home", 0) or 0
        ht_away = score.get("half_time_away", 0) or 0
        second_half_goals = total_goals - (ht_home + ht_away)

        # Determine match state
        match_status = event.get("status", "UNKNOWN")
        is_live = match_status in ["IN_PLAY", "LIVE", "PAUSED"]

        # Build transformed event
        transformed = {
            # Match identifiers
            "match_id": str(match_id),
            "competition": event.get("competition", "Premier League"),
            "matchday": event.get("matchday"),

            # Teams
            "home_team": {
                "id": str(event.get("home_team", {}).get("id", "")),
                "name": event.get("home_team", {}).get("name", "Unknown"),
                "short_name": event.get("home_team", {}).get("short_name", ""),
                "tla": event.get("home_team", {}).get("tla", ""),
            },
            "away_team": {
                "id": str(event.get("away_team", {}).get("id", "")),
                "name": event.get("away_team", {}).get("name", "Unknown"),
                "short_name": event.get("away_team", {}).get("short_name", ""),
                "tla": event.get("away_team", {}).get("tla", ""),
            },

            # Score data
            "score": {
                "home": home_score,
                "away": away_score,
                "half_time_home": ht_home,
                "half_time_away": ht_away,
            },

            # Calculated KPIs
            "kpis": {
                "total_goals": total_goals,
                "goal_difference": abs(home_score - away_score),
                "second_half_goals": second_half_goals if second_half_goals >= 0 else 0,
                "is_draw": home_score == away_score,
                "leading_team": (
                    "home" if home_score > away_score
                    else "away" if away_score > home_score
                    else "draw"
                ),
            },

            # Status and timestamps
            "status": match_status,
            "is_live": is_live,
            "utc_date": event.get("utc_date"),
            "event_timestamp": event.get("timestamp"),
            "processed_timestamp": datetime.utcnow().isoformat(),

            # Metadata
            "event_type": event.get("event_type", "match_update"),
            "producer_timestamp": event.get("producer_timestamp"),
        }

        logger.debug(f"Transformed event: {transformed}")
        return transformed

    except Exception as e:
        logger.error(f"Error transforming event: {e}", exc_info=True)
        # Return minimal valid structure on error
        return {
            "match_id": str(event.get("match_id", "unknown")),
            "error": str(e),
            "raw_event": event,
            "processed_timestamp": datetime.utcnow().isoformat(),
        }
