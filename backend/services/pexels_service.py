"""
Pexels dish-photo lookup for recipe cards.

Given a recipe title ("Chicken & Peppers Skillet"), returns a landscape stock
photo URL of the FINISHED DISH for the recipe card, or None. Pexels only
supplies the finished-dish hero image — it never drives ingredient detection
or recipe generation (that's Gemini).

Failure model (per project rule — no silent fake fallbacks):
  - no API key, no matching photo, or ANY error → return None. The card then
    renders with `image_url: null`; we never fabricate a URL.

Cache (RedisCache, shared across workers, `pexels_dish` prefix):
  - positive hits cached 7 days,
  - negative "no match" results cached briefly (600s) so a title with no photo
    doesn't hammer the API every time the user re-rolls recipes.
  A transient error is NOT cached, so the next call can retry.
"""
from __future__ import annotations

import logging
from typing import Optional

import httpx

from core.config import get_settings
from core.redis_cache import RedisCache

logger = logging.getLogger(__name__)

_PEXELS_SEARCH_URL = "https://api.pexels.com/v1/search"
_HIT_TTL_SECONDS = 7 * 24 * 60 * 60   # 7 days
_MISS_TTL_SECONDS = 600               # 10 min — don't re-hammer no-match titles
_SENTINEL_MISS = "__none__"           # cached marker for "searched, no photo"

_cache = RedisCache(prefix="pexels_dish", ttl_seconds=_HIT_TTL_SECONDS)


def _normalize_title(recipe_title: str) -> str:
    """Lowercase + collapse whitespace so cache keys are stable across the
    minor title variations the generator emits."""
    return " ".join((recipe_title or "").strip().lower().split())


async def get_dish_photo_url(recipe_title: str) -> Optional[str]:
    """Return a landscape Pexels photo URL for `recipe_title`, or None.

    Never raises — any failure returns None so callers can treat the photo as
    strictly optional decoration.
    """
    title = _normalize_title(recipe_title)
    if not title:
        return None

    api_key = get_settings().pexels_api_key
    if not api_key:
        logger.debug("[Pexels] no PEXELS_API_KEY configured — returning None")
        return None

    # Cache check (both positive hits and negative misses are cached).
    try:
        cached = await _cache.get(title)
        if cached is not None:
            return None if cached == _SENTINEL_MISS else cached
    except Exception as exc:
        logger.debug(f"[Pexels] cache get failed for '{title}': {exc}")

    url: Optional[str] = None
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(4.0, connect=3.0)) as client:
            resp = await client.get(
                _PEXELS_SEARCH_URL,
                params={"query": title, "per_page": 1, "orientation": "landscape"},
                headers={"Authorization": api_key},
            )
            resp.raise_for_status()
            payload = resp.json()
        photos = payload.get("photos") or []
        if photos:
            src = photos[0].get("src") or {}
            url = src.get("large") or None
    except Exception as exc:
        # Transient error (timeout / HTTP / parse). Return None WITHOUT caching
        # so the next call retries.
        logger.debug(f"[Pexels] lookup failed for '{title}': {exc}")
        return None

    # Cache the settled result: positive 7d, negative 10min.
    try:
        if url:
            await _cache.set(title, url)
        else:
            await _cache.set(title, _SENTINEL_MISS, ttl_override=_MISS_TTL_SECONDS)
    except Exception as exc:
        logger.debug(f"[Pexels] cache set failed for '{title}': {exc}")

    return url
