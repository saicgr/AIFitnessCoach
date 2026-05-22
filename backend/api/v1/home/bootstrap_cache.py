"""Leaf module — the home-bootstrap Redis cache and its invalidation.

Deliberately separate from the heavy `bootstrap.py` route module: `bootstrap.py`
imports route siblings (e.g. `workouts.today`), and several write endpoints
(nutrition / workout / hydration) need `invalidate_bootstrap_cache`. Putting the
invalidator here — a true leaf that imports only `core` utilities — means a
write module can import it without a circular import back into a
partially-initialised `bootstrap`.
"""
from core.logger import get_logger
from core.redis_cache import RedisCache

logger = get_logger(__name__)

# 30 min nominal TTL — invalidated explicitly on data changes.
_BOOTSTRAP_TTL_SECONDS = 1800

_bootstrap_cache = RedisCache(
    prefix="home_bootstrap", ttl_seconds=_BOOTSTRAP_TTL_SECONDS, max_size=200
)


async def invalidate_bootstrap_cache(user_id: str, gym_profile_id: str = None):
    """Invalidate the cached bootstrap response after data changes.

    The bootstrap cache key is `{user_id}:{gym_profile_id}:{local_date}` where
    `local_date` is the user's LOCAL date. A targeted single-key delete cannot
    reliably reconstruct that key from a write endpoint: the writer doesn't
    know the user's timezone (so it can't derive the same local date) and may
    not know the active gym_profile_id. Deleting with a UTC date — as this used
    to — misses the real key whenever the user's local date differs from UTC,
    leaving a stale 30-min bootstrap (wrong workout/nutrition/hydration).

    FIX: SCAN-delete every per-date / per-profile variant under this user's
    prefix. `gym_profile_id` is kept in the signature for caller compatibility
    but is intentionally unused — we bust ALL of the user's variants.
    """
    await _bootstrap_cache.delete_prefix(f"{user_id}:")
    logger.debug(f"[CACHE] Invalidated all home_bootstrap variants for user={user_id}")
