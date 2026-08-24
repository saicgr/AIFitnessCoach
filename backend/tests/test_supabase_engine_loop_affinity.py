"""Guard: the pooled async engine must not be reused across event loops.

WHY
---
``SupabaseManager`` is a process-wide singleton. It used to build its async
SQLAlchemy engine (wrapping asyncpg) exactly once and cache it forever. But
asyncpg binds a connection — and therefore this pooled engine — to whichever
event loop was running when it was created.

Production has one loop for the app's whole lifetime, so that was invisible
there. Tests do not: ``pytest.ini`` sets
``asyncio_default_fixture_loop_scope=function``, so every async test gets a
FRESH loop. Every DB-touching test after the first therefore reused a pool
bound to an already-closed loop, which surfaces as a rotating cast of
confusing errors deep inside asyncpg/SQLAlchemy:

    got Future <Future pending> attached to a different loop
    RuntimeError: Event loop is closed
    RuntimeError: Timeout context manager should be used inside a task

Those errors were present in the very first full backend run of the audit that
found this, and were repeatedly dismissed as environmental noise — they are
not. They accounted for a dozen order-dependent failures (RAG, safety-index
swap, food-image analysis, PR detection) that all passed in isolation.

THE INVARIANT
-------------
``SupabaseManager`` records the loop its engine was built on and rebuilds when
the running loop changes (``_ensure_engine_current``). This test asserts that
behaviour directly: build under one loop, then assert a DIFFERENT loop hands
back a DIFFERENT engine object, and that the manager's recorded loop follows.

If someone "optimises" the rebuild away, this fails immediately instead of
being rediscovered weeks later as flaky, order-dependent tests.
"""
from __future__ import annotations

import asyncio

import pytest

from core.supabase_client import SupabaseManager


def _engine_under_new_loop(manager: SupabaseManager):
    """Build/fetch the engine inside a brand-new event loop, then close it."""
    loop = asyncio.new_event_loop()
    try:
        asyncio.set_event_loop(loop)

        async def _get():
            return manager.engine

        return loop.run_until_complete(_get())
    finally:
        loop.close()
        asyncio.set_event_loop(None)


def test_manager_tracks_the_loop_its_engine_was_built_on():
    """The manager must remember which loop owns the current engine."""
    manager = SupabaseManager()
    assert hasattr(manager, "_engine_loop"), (
        "SupabaseManager no longer tracks _engine_loop. Without it the engine "
        "cannot know it is being used from a different event loop, which is "
        "exactly the cross-loop asyncpg reuse bug this guard exists to stop."
    )


def test_engine_is_rebuilt_when_the_event_loop_changes():
    """A new loop must not inherit a pool bound to a dead one."""
    manager = SupabaseManager()

    first = _engine_under_new_loop(manager)
    first_loop = manager._engine_loop

    second = _engine_under_new_loop(manager)
    second_loop = manager._engine_loop

    assert first is not None and second is not None, "engine was never built"
    assert second is not first, (
        "SupabaseManager handed back the SAME engine object to a different "
        "event loop. asyncpg connections are loop-bound, so the second loop is "
        "now using a pool owned by a closed loop — the source of "
        "'attached to a different loop' / 'Event loop is closed' / 'Timeout "
        "context manager should be used inside a task' failures that only "
        "appear in a FULL test run and never in isolation."
    )
    assert second_loop is not first_loop, (
        "_engine_loop did not follow the rebuild, so the next loop change "
        "will not be detected."
    )


@pytest.mark.asyncio
async def test_engine_is_stable_within_one_loop():
    """The rebuild must be loop-change-triggered, not per-access churn.

    Production runs one loop forever; rebuilding on every property access would
    discard the pool constantly and defeat pooling entirely.
    """
    manager = SupabaseManager()
    first = manager.engine
    second = manager.engine
    assert first is second, (
        "SupabaseManager rebuilt its engine twice within a single event loop. "
        "The rebuild must trigger only on a loop CHANGE, otherwise pooling is "
        "destroyed in production, which runs one loop for the whole process."
    )
