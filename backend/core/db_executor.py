"""Shared async offload for blocking supabase-py ``.execute()`` calls.

WHY THIS EXISTS
---------------
``supabase-py`` is synchronous. Calling ``.execute()`` directly inside an
``async def`` route blocks the uvicorn event loop for the entire DB round-trip,
which serializes EVERY in-flight request on that worker — one blocking endpoint
drags the whole burst down. This was *measured* against deployed prod: under a
single user's Home-open fan-out, ``/health`` p95 stalled from ~350 ms idle to
~5.9 s (16x), and even already-offloaded endpoints (``/stats``, ``/home/bootstrap``)
were dragged to 10 s because they shared the loop with un-offloaded blockers.

THE FIX (one chokepoint)
------------------------
Wrap each blocking call in :func:`run_db`, or several independent calls in
:func:`gather_db` to run them concurrently. Both use ``asyncio.to_thread``,
which dispatches to the 40-thread default executor installed in ``main.py`` —
so there is a single, shared, observable thread pool rather than a fragmented
per-module zoo of ``ThreadPoolExecutor``s.

USAGE
-----
    from core.db_executor import run_db, gather_db

    # one blocking call
    rows = await run_db(lambda: db.client.table("habits").select("*")
                        .eq("user_id", uid).execute())

    # several independent calls, concurrently (NOT serialized)
    streaks, today_logs = await gather_db(
        lambda: db.client.table("habit_streaks").select("*").eq("user_id", uid).execute(),
        lambda: db.client.table("habit_logs").select("*").eq("user_id", uid).execute(),
    )

Errors propagate (fail-fast → 500); no silent fallbacks. Pass
``return_exceptions=True`` to :func:`gather_db` only where a partial result is
explicitly acceptable (best-effort tiles), and handle the Exception members.
"""
from __future__ import annotations

import asyncio
from typing import Callable, TypeVar

T = TypeVar("T")


async def run_db(fn: Callable[[], T]) -> T:
    """Run one blocking DB call off the event loop (shared 40-thread executor)."""
    return await asyncio.to_thread(fn)


async def gather_db(*fns: Callable[[], object], return_exceptions: bool = False):
    """Run several independent blocking DB calls concurrently.

    Returns results in the same order as ``fns``. With
    ``return_exceptions=True``, failed calls come back as Exception instances
    instead of raising — use only for best-effort, partial-result paths.
    """
    return await asyncio.gather(
        *(asyncio.to_thread(fn) for fn in fns),
        return_exceptions=return_exceptions,
    )
