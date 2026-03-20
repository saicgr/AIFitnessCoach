"""
Per-user fair semaphore for Gemini API calls.

Two-tier concurrency limiter: global cap + per-user cap.
Prevents one user from consuming all global slots.
"""

import asyncio
import logging
import time
from typing import Dict, Optional

logger = logging.getLogger(__name__)


class FairGeminiSemaphore:
    """Two-tier concurrency limiter: global cap + per-user cap.

    Acquisition order: per-user FIRST, then global.
    If a user is at their limit, their next request queues on the per-user
    semaphore WITHOUT consuming a global slot.

    user_id=None falls back to global-only (for system calls like embeddings).
    """

    def __init__(
        self,
        global_limit: int = 10,
        per_user_limit: int = 3,
        cleanup_interval: float = 300.0,
    ):
        self._global = asyncio.Semaphore(global_limit)
        self._per_user_limit = per_user_limit
        self._user_semaphores: Dict[str, asyncio.Semaphore] = {}
        self._user_last_seen: Dict[str, float] = {}
        self._cleanup_interval = cleanup_interval
        self._last_cleanup = time.monotonic()

    def _get_user_semaphore(self, user_id: str) -> asyncio.Semaphore:
        """Get or create a per-user semaphore (lazy init)."""
        if user_id not in self._user_semaphores:
            self._user_semaphores[user_id] = asyncio.Semaphore(self._per_user_limit)
        self._user_last_seen[user_id] = time.monotonic()
        return self._user_semaphores[user_id]

    def _maybe_cleanup(self) -> None:
        """Sweep idle users. Safe because asyncio is single-threaded."""
        now = time.monotonic()
        if now - self._last_cleanup < self._cleanup_interval:
            return
        self._last_cleanup = now

        stale_users = []
        for uid, last_seen in self._user_last_seen.items():
            if now - last_seen > self._cleanup_interval:
                sem = self._user_semaphores.get(uid)
                # Only remove if no in-flight calls (semaphore at max value)
                if sem is not None and sem._value == self._per_user_limit:
                    stale_users.append(uid)

        for uid in stale_users:
            del self._user_semaphores[uid]
            del self._user_last_seen[uid]

        if stale_users:
            logger.debug(f"[FairSemaphore] Cleaned up {len(stale_users)} idle user semaphores")

    def __call__(self, user_id: Optional[str] = None) -> "_FairAcquireContext":
        """Return an async context manager that acquires both semaphores."""
        self._maybe_cleanup()
        user_sem = self._get_user_semaphore(user_id) if user_id else None
        return _FairAcquireContext(self._global, user_sem)


class _FairAcquireContext:
    """Async context manager: acquires per-user first, then global."""

    __slots__ = ("_global_sem", "_user_sem")

    def __init__(
        self,
        global_sem: asyncio.Semaphore,
        user_sem: Optional[asyncio.Semaphore],
    ):
        self._global_sem = global_sem
        self._user_sem = user_sem

    async def __aenter__(self):
        # Per-user first — queue without wasting a global slot
        if self._user_sem is not None:
            await self._user_sem.acquire()
        await self._global_sem.acquire()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        # Release in reverse order
        self._global_sem.release()
        if self._user_sem is not None:
            self._user_sem.release()
        return False
