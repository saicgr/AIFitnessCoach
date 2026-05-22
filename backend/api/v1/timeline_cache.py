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

    Every Timeline cache key is user-scoped and prefixed ``{user_id}:`` — the
    remainder embeds the date and the ``days`` window size. The old
    implementation silently returned when ``date`` was None, leaving the
    timeline stale for any write hook that didn't know the exact date; and
    even with a date it only cleared four hardcoded window sizes. Bust the
    whole per-user namespace via a SCAN prefix delete so every date + window
    variant misses cache; keys re-populate in one query on the next read.

    Args:
        user_id: User to invalidate.
        date: Optional YYYY-MM-DD, accepted for signature compatibility with
            existing callers but no longer required — all of the user's
            Timeline keys are cleared regardless.
    """
    await _timeline_cache.delete_prefix(f"{user_id}:")
    logger.debug(f"[Timeline] Invalidated all cached Timeline variants for user {user_id}")
