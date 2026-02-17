"""
Redis-backed shared cache for Gemini API responses.

Replaces per-worker in-memory ResponseCache with a shared Redis cache
so all Gunicorn workers share cached embeddings, intents, summaries, etc.

Falls back to in-memory dict if Redis is unavailable.
"""
import hashlib
import json
import logging
from typing import Any, Optional

import redis.asyncio as aioredis

from core.config import get_settings

logger = logging.getLogger(__name__)

_redis_client: Optional[aioredis.Redis] = None
_redis_available: bool = False


async def init_redis() -> bool:
    """Initialize the shared Redis connection. Call once at startup."""
    global _redis_client, _redis_available
    settings = get_settings()
    if not settings.redis_url:
        logger.info("No REDIS_URL configured — using in-memory caches (per-worker)")
        return False
    try:
        _redis_client = aioredis.from_url(
            settings.redis_url,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_timeout=3,
            retry_on_timeout=True,
        )
        await _redis_client.ping()
        _redis_available = True
        logger.info("Redis connected — shared cache active across all workers")
        return True
    except Exception as e:
        logger.warning(f"Redis connection failed ({e}) — falling back to in-memory cache")
        _redis_client = None
        _redis_available = False
        return False


async def close_redis():
    """Close the Redis connection pool. Call on shutdown."""
    global _redis_client, _redis_available
    if _redis_client:
        await _redis_client.aclose()
        _redis_client = None
        _redis_available = False


class RedisCache:
    """
    TTL cache backed by Redis (shared across workers) with in-memory fallback.

    Drop-in replacement for ResponseCache — same get/set/make_key interface.
    """

    def __init__(self, prefix: str, ttl_seconds: int = 300, max_size: int = 200):
        self._prefix = f"fitwiz:{prefix}:"
        self._ttl = ttl_seconds
        self._max_size = max_size
        # In-memory fallback (used when Redis unavailable)
        self._local: dict = {}
        from datetime import datetime, timedelta
        self._local_ttl = timedelta(seconds=ttl_seconds)

    async def get(self, key: str) -> Optional[Any]:
        """Get a cached value. Tries Redis first, falls back to local."""
        if _redis_available and _redis_client:
            try:
                raw = await _redis_client.get(self._prefix + key)
                if raw is not None:
                    return json.loads(raw)
                return None
            except Exception as e:
                logger.debug(f"Redis GET error: {e}")
        # Fallback to local cache
        return self._local_get(key)

    async def set(self, key: str, value: Any):
        """Store a value. Writes to Redis if available, otherwise local."""
        if _redis_available and _redis_client:
            try:
                await _redis_client.set(
                    self._prefix + key,
                    json.dumps(value, default=str),
                    ex=self._ttl,
                )
                return
            except Exception as e:
                logger.debug(f"Redis SET error: {e}")
        # Fallback to local cache
        self._local_set(key, value)

    def _local_get(self, key: str) -> Optional[Any]:
        """In-memory fallback get."""
        from datetime import datetime
        if key in self._local:
            cached_at, value = self._local[key]
            if datetime.now() - cached_at < self._local_ttl:
                return value
            del self._local[key]
        return None

    def _local_set(self, key: str, value: Any):
        """In-memory fallback set."""
        from datetime import datetime
        if len(self._local) >= self._max_size:
            oldest_key = min(self._local, key=lambda k: self._local[k][0])
            del self._local[oldest_key]
        self._local[key] = (datetime.now(), value)

    def get_stats(self) -> dict:
        """Return basic cache statistics (for monitoring endpoints)."""
        return {
            "backend": "redis" if (_redis_available and _redis_client) else "local",
            "local_size": len(self._local),
            "max_size": self._max_size,
            "prefix": self._prefix,
            "ttl_seconds": self._ttl,
        }

    # Synchronous versions for non-async code paths
    def get_sync(self, key: str) -> Optional[Any]:
        """Synchronous get (local cache only)."""
        return self._local_get(key)

    def set_sync(self, key: str, value: Any):
        """Synchronous set (local cache only)."""
        self._local_set(key, value)

    @staticmethod
    def make_key(*args) -> str:
        """Create a deterministic cache key from arguments."""
        return hashlib.md5(
            json.dumps(args, sort_keys=True, default=str).encode()
        ).hexdigest()
