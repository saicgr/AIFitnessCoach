"""
Regenerate-workout preview cache.

In-memory TTL cache used by the /regenerate + /regenerate-stream flow so that
regeneration does NOT mutate the database until the user explicitly approves
the generated plan from the review sheet.

Design notes
------------
- This is deliberately in-process (single-instance) and non-persistent. The
  preview lifecycle is ≤ 30 minutes and loss of a preview on backend restart
  is acceptable — the user simply regenerates. No Redis dependency.
- Keys are user-supplied ``preview_id`` strings (generated as UUID4 by the
  caller). All reads go through ``get_owned(preview_id, user_id)`` so an
  attacker cannot swap to another user's preview even if they guess the id.
- A secondary index ``_user_workout_index`` maps ``(user_id, workout_id)`` to
  the latest preview for that pair. When a user regenerates the same workout
  twice without approving the first attempt, the old preview is evicted so
  we don't leak memory.
- A background task evicts expired entries every 60s. We also opportunistically
  check expiry on every ``get``.

Thread/async safety
-------------------
All mutations go through an asyncio.Lock. That is sufficient for a single
uvicorn worker. If we ever move to multi-worker uvicorn or Lambda, we must
switch to Redis — noted in the module docstring.

Telemetry
---------
Lightweight in-memory counters exposed via ``get_stats()``. Not wired to a
metrics backend yet; the intent is to surface them on a debug endpoint if we
need to observe preview behaviour in production.
"""
from __future__ import annotations

import asyncio
import copy
import time
from dataclasses import dataclass, field
from typing import Any, Awaitable, Callable, Dict, Optional, Tuple

from core.logger import get_logger

logger = get_logger(__name__)

# Default TTL for a preview entry (seconds).
DEFAULT_TTL_SECONDS: int = 30 * 60  # 30 minutes

# How often the background task wakes up to sweep expired entries.
EVICTION_INTERVAL_SECONDS: int = 60


@dataclass
class PreviewEntry:
    """Single cached preview payload."""

    preview_id: str
    user_id: str
    original_workout_id: str
    payload: Dict[str, Any]
    created_at: float
    expires_at: float
    # Free-form metadata set at creation time (e.g. focus_area, injuries).
    # Kept separate from ``payload`` so swap/add mutations don't disturb it.
    metadata: Dict[str, Any] = field(default_factory=dict)

    def is_expired(self, now: Optional[float] = None) -> bool:
        return (now if now is not None else time.time()) >= self.expires_at


class RegenPreviewCache:
    """Process-local TTL cache for regenerate workout previews."""

    def __init__(self, ttl_seconds: int = DEFAULT_TTL_SECONDS) -> None:
        self._ttl_seconds = ttl_seconds
        self._entries: Dict[str, PreviewEntry] = {}
        # (user_id, original_workout_id) -> preview_id. Used to evict stale
        # previews when the user regenerates the same workout twice.
        self._user_workout_index: Dict[Tuple[str, str], str] = {}
        self._lock = asyncio.Lock()
        self._eviction_task: Optional[asyncio.Task] = None

        # Telemetry counters. Cheap atomic-ish counters (GIL-protected for ints).
        self._counters: Dict[str, int] = {
            "stores": 0,
            "hits": 0,
            "misses": 0,
            "expires": 0,
            "evicts_on_replace": 0,
            "deletes": 0,
            "auth_mismatches": 0,
        }

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def store(
        self,
        preview_id: str,
        payload: Dict[str, Any],
        user_id: str,
        original_workout_id: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> PreviewEntry:
        """Store a preview payload.

        If a prior preview exists for ``(user_id, original_workout_id)`` it is
        evicted first — regenerating the same workout twice without approving
        should not leak memory or leave a dangling preview.
        """
        now = time.time()
        entry = PreviewEntry(
            preview_id=preview_id,
            user_id=user_id,
            original_workout_id=original_workout_id,
            payload=payload,
            created_at=now,
            expires_at=now + self._ttl_seconds,
            metadata=metadata or {},
        )

        async with self._lock:
            # Idempotency: evict any prior preview for the same (user, workout).
            prior_id = self._user_workout_index.get((user_id, original_workout_id))
            if prior_id and prior_id != preview_id:
                self._entries.pop(prior_id, None)
                self._counters["evicts_on_replace"] += 1
                logger.info(
                    "🧹 [PreviewCache] Evicted prior preview %s for user=%s workout=%s",
                    prior_id, user_id, original_workout_id,
                )

            self._entries[preview_id] = entry
            self._user_workout_index[(user_id, original_workout_id)] = preview_id
            self._counters["stores"] += 1

        logger.info(
            "✅ [PreviewCache] Stored preview %s (user=%s workout=%s ttl=%ds)",
            preview_id, user_id, original_workout_id, self._ttl_seconds,
        )
        return entry

    async def get(self, preview_id: str) -> Optional[PreviewEntry]:
        """Return the preview entry if present AND not expired. Does NOT check
        ownership — prefer ``get_owned`` from request handlers."""
        async with self._lock:
            entry = self._entries.get(preview_id)
            if entry is None:
                self._counters["misses"] += 1
                return None
            if entry.is_expired():
                # Lazy eviction.
                self._entries.pop(preview_id, None)
                self._user_workout_index.pop(
                    (entry.user_id, entry.original_workout_id), None
                )
                self._counters["expires"] += 1
                self._counters["misses"] += 1
                return None
            self._counters["hits"] += 1
            return entry

    async def get_owned(
        self, preview_id: str, user_id: str
    ) -> Tuple[Optional[PreviewEntry], Optional[str]]:
        """Return ``(entry, None)`` on success or ``(None, reason)`` on failure.

        ``reason`` is one of:
          - ``"PREVIEW_EXPIRED"`` when missing/expired
          - ``"PREVIEW_NOT_OWNED"`` when present but owned by another user
        """
        entry = await self.get(preview_id)
        if entry is None:
            return None, "PREVIEW_EXPIRED"
        if entry.user_id != user_id:
            async with self._lock:
                self._counters["auth_mismatches"] += 1
            logger.warning(
                "⚠️ [PreviewCache] Auth mismatch: preview=%s owner=%s requester=%s",
                preview_id, entry.user_id, user_id,
            )
            return None, "PREVIEW_NOT_OWNED"
        return entry, None

    async def delete(self, preview_id: str) -> bool:
        """Remove a preview (used on approve-commit and on explicit discard).

        Returns True if something was removed.
        """
        async with self._lock:
            entry = self._entries.pop(preview_id, None)
            if entry is None:
                return False
            self._user_workout_index.pop(
                (entry.user_id, entry.original_workout_id), None
            )
            self._counters["deletes"] += 1
        logger.info("🗑️ [PreviewCache] Deleted preview %s", preview_id)
        return True

    async def evict_for_user_workout(
        self, user_id: str, original_workout_id: str
    ) -> Optional[str]:
        """Evict any preview currently associated with ``(user_id, workout_id)``.

        Returns the evicted ``preview_id`` or None if nothing was cached.
        Used before storing a fresh preview for the same pair.
        """
        async with self._lock:
            prior_id = self._user_workout_index.pop(
                (user_id, original_workout_id), None
            )
            if prior_id:
                self._entries.pop(prior_id, None)
                self._counters["evicts_on_replace"] += 1
        if prior_id:
            logger.info(
                "🧹 [PreviewCache] evict_for_user_workout user=%s workout=%s id=%s",
                user_id, original_workout_id, prior_id,
            )
        return prior_id

    async def update(
        self,
        preview_id: str,
        user_id: str,
        mutator: Callable[[Dict[str, Any]], Dict[str, Any]],
    ) -> Optional[PreviewEntry]:
        """Atomically mutate a preview payload.

        ``mutator`` receives a *deep copy* of the current payload and must
        return the new payload. The copy isolates the caller from in-place
        mutations that could race with a concurrent ``get``. The returned
        entry reflects the mutated state.

        Returns None if the preview is missing, expired, or not owned.
        """
        async with self._lock:
            entry = self._entries.get(preview_id)
            if entry is None or entry.is_expired():
                if entry is not None and entry.is_expired():
                    self._entries.pop(preview_id, None)
                    self._user_workout_index.pop(
                        (entry.user_id, entry.original_workout_id), None
                    )
                    self._counters["expires"] += 1
                self._counters["misses"] += 1
                return None
            if entry.user_id != user_id:
                self._counters["auth_mismatches"] += 1
                return None

            # Deep-copy to preserve invariant: mutator sees a snapshot.
            snapshot = copy.deepcopy(entry.payload)
            new_payload = mutator(snapshot)
            # Defensive: require mutator to return a dict.
            if not isinstance(new_payload, dict):
                raise ValueError(
                    "Preview mutator must return a dict payload, got "
                    f"{type(new_payload).__name__}"
                )
            entry.payload = new_payload
            self._counters["hits"] += 1
            return entry

    # ------------------------------------------------------------------
    # Background eviction
    # ------------------------------------------------------------------

    async def _run_eviction_loop(self) -> None:
        """Sweep expired entries at a fixed cadence.

        Errors inside the loop are logged but never propagated — we don't
        want a background sweeper to crash the process.
        """
        logger.info(
            "🧭 [PreviewCache] Eviction loop started (interval=%ss ttl=%ss)",
            EVICTION_INTERVAL_SECONDS, self._ttl_seconds,
        )
        while True:
            try:
                await asyncio.sleep(EVICTION_INTERVAL_SECONDS)
                await self._sweep()
            except asyncio.CancelledError:
                logger.info("🧭 [PreviewCache] Eviction loop cancelled")
                raise
            except Exception as e:  # pragma: no cover — defensive
                logger.warning(
                    "⚠️ [PreviewCache] Eviction loop error (continuing): %s", e,
                    exc_info=True,
                )

    async def _sweep(self) -> int:
        """Remove all expired entries. Returns count removed."""
        now = time.time()
        removed = 0
        async with self._lock:
            # Collect first to avoid mutating while iterating.
            expired_ids = [
                pid for pid, entry in self._entries.items() if entry.is_expired(now)
            ]
            for pid in expired_ids:
                entry = self._entries.pop(pid, None)
                if entry is not None:
                    self._user_workout_index.pop(
                        (entry.user_id, entry.original_workout_id), None
                    )
                    removed += 1
            if removed:
                self._counters["expires"] += removed
        if removed:
            logger.info("🧹 [PreviewCache] Swept %d expired preview(s)", removed)
        return removed

    def start_background_task(self) -> None:
        """Start the background eviction loop. Idempotent: no-op if already
        running. Call once from app startup (lifespan) after the event loop
        is available.
        """
        if self._eviction_task and not self._eviction_task.done():
            return
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            # No running loop yet — caller should re-invoke from within one.
            logger.debug(
                "[PreviewCache] start_background_task called without running loop"
            )
            return
        self._eviction_task = loop.create_task(
            self._run_eviction_loop(), name="preview-cache-eviction"
        )

    async def stop_background_task(self) -> None:
        """Cancel the eviction loop on shutdown. Idempotent."""
        if self._eviction_task is None:
            return
        self._eviction_task.cancel()
        try:
            await self._eviction_task
        except (asyncio.CancelledError, Exception):  # pragma: no cover
            pass
        self._eviction_task = None

    # ------------------------------------------------------------------
    # Telemetry / debug
    # ------------------------------------------------------------------

    def get_stats(self) -> Dict[str, Any]:
        """Snapshot of cache state + counters. Safe to read without lock for
        diagnostic purposes (dict reads are GIL-protected)."""
        return {
            "size": len(self._entries),
            "ttl_seconds": self._ttl_seconds,
            "counters": dict(self._counters),
        }


# ----------------------------------------------------------------------
# Module-level singleton
# ----------------------------------------------------------------------

_cache_singleton: Optional[RegenPreviewCache] = None


def get_preview_cache() -> RegenPreviewCache:
    """Return the process-wide preview cache.

    Lazy-initialised so importing this module is free of side effects. The
    background eviction loop is started opportunistically the first time the
    cache is accessed from inside a running event loop; subsequent calls are
    no-ops. This avoids a hard requirement on wiring through the FastAPI
    ``lifespan`` hook (which lives outside this agent's exclusive files).
    """
    global _cache_singleton
    if _cache_singleton is None:
        _cache_singleton = RegenPreviewCache()
    # start_background_task() is idempotent and loop-aware; it will silently
    # no-op if there is no running event loop yet.
    _cache_singleton.start_background_task()
    return _cache_singleton
