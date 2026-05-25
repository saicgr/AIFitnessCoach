"""
url_result_cache.py — 24h TTL cache for URL fetch results.

A user sharing the same recipe URL twice in a day shouldn't re-trigger
the full SSE pipeline (yt-dlp download + Gemini classify + Gemini
extract). We cache the SharedContent blob per (url, locale) for 24 h.

Backend: process-local LRU. We avoid Redis here because:
  * The blob is potentially large (transcript + caption).
  * Cache-hit latency from in-memory < cache-hit latency from Redis.
  * Per-instance is fine — share traffic per user is bursty, not
    cross-instance.

If we ever need cross-instance hits, swap `_LRU` for a Redis-backed impl
behind the same `get` / `set` API.
"""
from __future__ import annotations

import hashlib
import time
from collections import OrderedDict
from typing import Optional

from services.url_content_fetcher import SharedContent


_TTL_SECONDS = 24 * 3600
_MAX_ENTRIES = 1000


class _LRU:
    def __init__(self, max_entries: int = _MAX_ENTRIES) -> None:
        self._d: "OrderedDict[str, tuple[float, SharedContent]]" = OrderedDict()
        self._max = max_entries

    def get(self, key: str) -> Optional[SharedContent]:
        hit = self._d.get(key)
        if not hit:
            return None
        ts, content = hit
        if time.time() - ts > _TTL_SECONDS:
            self._d.pop(key, None)
            return None
        # Refresh recency.
        self._d.move_to_end(key)
        return content

    def set(self, key: str, content: SharedContent) -> None:
        self._d[key] = (time.time(), content)
        self._d.move_to_end(key)
        while len(self._d) > self._max:
            self._d.popitem(last=False)

    def clear(self) -> None:
        self._d.clear()


_cache = _LRU()


def _key(url: str, locale: Optional[str]) -> str:
    h = hashlib.sha256(((locale or "") + "|" + (url or "")).encode("utf-8"))
    return h.hexdigest()


def get(url: str, locale: Optional[str] = None) -> Optional[SharedContent]:
    return _cache.get(_key(url, locale))


def set_(url: str, content: SharedContent, locale: Optional[str] = None) -> None:
    _cache.set(_key(url, locale), content)


def clear() -> None:
    _cache.clear()
