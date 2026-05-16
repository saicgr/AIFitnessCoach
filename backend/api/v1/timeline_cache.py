"""Shared timeline cache + invalidation helpers.

The Timeline aggregator (`api/v1/timeline.py`) caches the per-(user, date)
response with a 60s TTL. Every write hook (events log, food log, hydration,
habits, weight, mood, wearable sync) calls `invalidate_timeline_cache` so
the next read returns fresh data.

Lives in its own module to avoid a circular import: write sites in
`api/v1/wellness/`, `api/v1/nutrition/`, etc. import this without pulling
in the full `timeline.py` aggregator (which imports those write sites for
schema reuse).
"""
from typing import Optional

from core.logger import get_logger
from core.redis_cache import RedisCache

logger = get_logger(__name__)

# 60s TTL — Timeline data is read-heavy on the home screen but always
# satisfied by user-specific data, so per-user keys keep cache hit rates
# meaningful without serving more than 1 minute of stale state.
_timeline_cache = RedisCache(prefix="timeline", ttl_seconds=60, max_size=500)


def make_timeline_cache_key(user_id: str, date: str, days: int = 1) -> str:
    """Compose the cache key for a Timeline response.

    Mirrors the pattern in api/v1/workouts/today.py — `user_id:date:days`.
    """
    return f"{user_id}:{date}:days={days}"


async def get_timeline_cache(user_id: str, date: str, days: int = 1):
    """Return cached payload (dict) or None."""
    return await _timeline_cache.get(make_timeline_cache_key(user_id, date, days))


async def set_timeline_cache(user_id: str, date: str, payload: dict, days: int = 1):
    """Store the Timeline response payload."""
    await _timeline_cache.set(make_timeline_cache_key(user_id, date, days), payload)


async def invalidate_timeline_cache(user_id: str, date: Optional[str] = None):
    """Invalidate cached Timeline responses for a user.

    Args:
        user_id: User to invalidate.
        date: Optional YYYY-MM-DD. If supplied, invalidates the specific day
            (and the surrounding 1/7-day windowed variants). If None,
            falls back to deleting just the user's most-likely "today" key
            — callers that don't know the exact date should pass it
            explicitly so multi-day windows also get cleared.
    """
    if date is None:
        logger.debug(f"[Timeline] invalidate called without date for user {user_id} — partial invalidation only")
        return

    # Clear the common windowed variants (1, 7, 14, 30 days) so any read
    # that includes this date in its window misses cache.
    for days in (1, 7, 14, 30):
        await _timeline_cache.delete(make_timeline_cache_key(user_id, date, days))
    logger.debug(f"[Timeline] Invalidated cache for user {user_id} on {date}")
