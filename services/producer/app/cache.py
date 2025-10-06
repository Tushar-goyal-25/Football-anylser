import redis
import json
import os
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# Redis client
redis_client: Optional[redis.Redis] = None

def get_redis_client() -> Optional[redis.Redis]:
    """Get or create Redis client"""
    global redis_client

    if redis_client is None:
        redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
        try:
            redis_client = redis.from_url(redis_url, decode_responses=True)
            redis_client.ping()
            logger.info(f"Connected to Redis at {redis_url}")
        except Exception as e:
            logger.warning(f"Failed to connect to Redis: {e}. Caching disabled.")
            redis_client = None

    return redis_client


def cache_match(match: Dict[str, Any], ttl_hours: int = 24):
    """Cache a match by its ID"""
    client = get_redis_client()
    if not client:
        return

    try:
        match_id = str(match.get("match_id"))
        key = f"match:{match_id}"
        client.setex(key, timedelta(hours=ttl_hours), json.dumps(match))
        logger.debug(f"Cached match {match_id} for {ttl_hours} hours")
    except Exception as e:
        logger.error(f"Error caching match: {e}")


def get_cached_match(match_id: str) -> Optional[Dict[str, Any]]:
    """Get a cached match by ID"""
    client = get_redis_client()
    if not client:
        return None

    try:
        key = f"match:{match_id}"
        data = client.get(key)
        if data:
            logger.debug(f"Cache hit for match {match_id}")
            return json.loads(data)
        return None
    except Exception as e:
        logger.error(f"Error retrieving cached match: {e}")
        return None


def cache_finished_matches(matches: List[Dict[str, Any]]):
    """Cache all finished matches with 24 hour TTL"""
    for match in matches:
        if match.get("status") == "FINISHED":
            cache_match(match, ttl_hours=24)


def get_cached_finished_matches(match_ids: List[str]) -> Dict[str, Dict[str, Any]]:
    """Get multiple cached matches by IDs"""
    cached = {}
    for match_id in match_ids:
        match = get_cached_match(match_id)
        if match:
            cached[match_id] = match
    return cached


def should_fetch_from_api(last_fetch_key: str, interval_seconds: int) -> bool:
    """Check if enough time has passed since last API fetch"""
    client = get_redis_client()
    if not client:
        return True  # If Redis unavailable, always fetch

    try:
        last_fetch = client.get(last_fetch_key)
        if not last_fetch:
            return True

        last_fetch_time = datetime.fromisoformat(last_fetch)
        time_diff = (datetime.utcnow() - last_fetch_time).total_seconds()

        return time_diff >= interval_seconds
    except Exception as e:
        logger.error(f"Error checking fetch interval: {e}")
        return True


def set_last_fetch_time(last_fetch_key: str):
    """Record the last API fetch time"""
    client = get_redis_client()
    if not client:
        return

    try:
        client.setex(last_fetch_key, timedelta(hours=1), datetime.utcnow().isoformat())
    except Exception as e:
        logger.error(f"Error setting last fetch time: {e}")
