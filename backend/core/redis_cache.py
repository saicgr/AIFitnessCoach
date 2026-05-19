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
        logger.warning(f"Redis connection failed ({e}) — falling back to in-memory cache", exc_info=True)
        _redis_client = None
        _redis_available = False
        return False


async def ping_redis() -> bool:
    """Ping Redis to keep the connection (and Upstash free-tier) alive."""
    if _redis_available and _redis_client:
        try:
            await _redis_client.ping()
            return True
        except Exception:
            return False
    return False


async def close_redis():
    """Close the Redis connection pool. Call on shutdown."""
    global _redis_client, _redis_available
    if _redis_client:
        await _redis_client.aclose()
        _redis_client = None
        _redis_available = False


async def acquire_lock(key: str, ttl_seconds: int) -> bool:
    """Atomically acquire a short-lived distributed lock (Redis SET NX EX).

    Returns True if the lock was acquired (caller owns it), False if another
    worker/instance already holds it. The TTL auto-releases the lock if the
    owner crashes mid-task.

    Fails OPEN: if Redis is unavailable, returns True. A rare duplicate is far
    better than a task that never runs because the lock store is down.
    """
    if _redis_available and _redis_client:
        try:
            got = await _redis_client.set(
                f"zealova:lock:{key}", "1", nx=True, ex=ttl_seconds
            )
            return bool(got)
        except Exception as e:
            logger.debug(f"Redis lock acquire error ({key}): {e}")
    return True


async def release_lock(key: str) -> None:
    """Release a lock acquired via acquire_lock(). Safe to call if Redis is
    down or the lock already expired."""
    if _redis_available and _redis_client:
        try:
            await _redis_client.delete(f"zealova:lock:{key}")
        except Exception as e:
            logger.debug(f"Redis lock release error ({key}): {e}")


# Process-wide registry of every RedisCache instance, so the observability
# endpoint can report hit-rate for ALL caches without each one being wired up
# individually. WeakSet so a discarded cache doesn't leak.
import weakref as _weakref
_cache_registry: "_weakref.WeakSet[RedisCache]" = _weakref.WeakSet()


def all_cache_stats() -> list:
    """Return hit/miss stats for every live RedisCache instance.

    Consumed by the admin observability endpoint (Phase D4) so cache pressure
    is visible per cache prefix. Cheap: just reads in-memory counters.
    """
    return [c.get_stats() for c in list(_cache_registry)]


class RedisCache:
    """
    TTL cache backed by Redis (shared across workers) with in-memory fallback.

    Drop-in replacement for ResponseCache — same get/set/make_key interface.

    Tracks lightweight in-process hit/miss counters (Phase D4 observability):
    every `get()` increments `_hits` or `_misses`. Counters are plain ints —
    incrementing them adds negligible overhead to the cache hot path. They are
    per-worker (like the cache's own local fallback) and reset on restart.
    """

    def __init__(self, prefix: str, ttl_seconds: int = 300, max_size: int = 200):
        self._prefix = f"zealova:{prefix}:"
        self._ttl = ttl_seconds
        self._max_size = max_size
        # In-memory fallback (used when Redis unavailable)
        self._local: dict = {}
        from datetime import datetime, timedelta
        self._local_ttl = timedelta(seconds=ttl_seconds)
        # Phase D4 — hit-rate counters (per-worker, reset on restart).
        self._hits = 0
        self._misses = 0
        _cache_registry.add(self)

    async def get(self, key: str) -> Optional[Any]:
        """Get a cached value. Tries Redis first, falls back to local.

        Records a hit/miss for observability. A Redis error falls through to
        the local cache and the local result determines hit vs miss, so the
        counters reflect the value actually served.
        """
        if _redis_available and _redis_client:
            try:
                raw = await _redis_client.get(self._prefix + key)
                if raw is not None:
                    self._hits += 1
                    return json.loads(raw)
                self._misses += 1
                return None
            except Exception as e:
                logger.debug(f"Redis GET error: {e}")
        # Fallback to local cache
        value = self._local_get(key)
        if value is not None:
            self._hits += 1
        else:
            self._misses += 1
        return value

    async def set(self, key: str, value: Any, ttl_override: Optional[int] = None):
        """Store a value. Writes to Redis if available, otherwise local.

        Args:
            ttl_override: Optional TTL in seconds to use instead of the default.
        """
        ttl = ttl_override if ttl_override is not None else self._ttl
        if _redis_available and _redis_client:
            try:
                await _redis_client.set(
                    self._prefix + key,
                    json.dumps(value, default=str),
                    ex=ttl,
                )
                return
            except Exception as e:
                logger.debug(f"Redis SET error: {e}")
        # Fallback to local cache
        self._local_set(key, value)

    async def delete(self, key: str):
        """Delete a cached value from Redis and local fallback."""
        if _redis_available and _redis_client:
            try:
                await _redis_client.delete(self._prefix + key)
            except Exception as e:
                logger.debug(f"Redis DELETE error: {e}")
        self._local.pop(key, None)

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
        total = self._hits + self._misses
        return {
            "backend": "redis" if (_redis_available and _redis_client) else "local",
            "local_size": len(self._local),
            "max_size": self._max_size,
            "prefix": self._prefix,
            "ttl_seconds": self._ttl,
            "hits": self._hits,
            "misses": self._misses,
            "lookups": total,
            "hit_rate": round(self._hits / total, 4) if total else 0.0,
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
