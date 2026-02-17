"""
Shared Redis-backed TTL cache for workout generation.

Prevents duplicate AI generation calls when a user retries with identical
parameters within a short window (e.g., double-tap, network retry).
Cache entries expire after 5 minutes.

Uses RedisCache (shared across Gunicorn workers) with in-memory fallback.

Used by both:
- api/v1/workouts/generation.py (streaming generation)
- api/v1/workouts_db.py (non-streaming generation)
"""
import logging

from core.redis_cache import RedisCache

logger = logging.getLogger(__name__)

_generation_cache = RedisCache(prefix="gen", ttl_seconds=300, max_size=100)


def generation_cache_key(user_id: str, params: dict) -> str:
    """Create a deterministic cache key from user_id and generation parameters."""
    return RedisCache.make_key(user_id, params)


async def get_cached_generation(key: str):
    """Get a cached generation result if still valid. Returns None on miss."""
    result = await _generation_cache.get(key)
    if result is not None:
        logger.info(f"Cache HIT for workout generation key={key[:8]}")
    return result


async def set_cached_generation(key: str, result):
    """Store a successful generation result in the cache."""
    await _generation_cache.set(key, result)
    logger.info(f"Cache SET for workout generation key={key[:8]}")
