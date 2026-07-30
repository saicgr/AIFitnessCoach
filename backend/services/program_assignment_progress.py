"""Program assignment progress + lifecycle (E2E register row 54).

`user_program_assignments.progress_percentage / workouts_completed /
current_week / completed_at` had NO writer anywhere in the backend, so a
started program never reached a terminal state — and /today suppresses AI
generation on every weekday an assignment with `is_active AND
status='active'` prescribes (api/v1/workouts/today.py
`_assignment_covered_weekdays`). Result: starting a program killed generation
on its weekdays forever, with no date expiry.

Migration 2372 installs the two SQL chokepoints:

  program_assignment_progress_sync(uuid[])   -- derive counters from `workouts`
  program_assignment_settle_elapsed(uuid)    -- close an elapsed/empty program

The counters are DERIVED from the workouts rows on every call (never
incremented), so they cannot drift. A statement-level trigger on `workouts`
runs the first one for every write path that touches a program workout. This
module is the second half: the trigger cannot fire on the mere passage of
time, so the program read chokepoints call `sync_user_assignments()` to settle
assignments whose scheduled window has fully elapsed.

Both calls are advisory: a failure logs and returns 0, it never breaks the
read that invoked it.
"""
from __future__ import annotations

import os
from typing import Optional, Sequence

import psycopg2

from core.logger import get_logger

logger = get_logger(__name__)


def _dsn() -> str:
    dsn = os.environ.get("DATABASE_URL", "")
    if not dsn:
        raise RuntimeError("DATABASE_URL is not set")
    dsn = dsn.replace("postgresql+asyncpg://", "postgresql://")
    if "sslmode" not in dsn:
        dsn += ("&" if "?" in dsn else "?") + "sslmode=require"
    return dsn


def recompute_assignment_progress(
    assignment_ids: Optional[Sequence[str]] = None,
) -> int:
    """Recompute progress counters for the given assignments (None = all).

    Returns the number of assignment rows changed."""
    ids = [str(a) for a in (assignment_ids or []) if a] or None
    try:
        with psycopg2.connect(_dsn()) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT public.program_assignment_progress_sync(%s::uuid[])",
                    (ids,),
                )
                changed = cur.fetchone()[0] or 0
        return int(changed)
    except Exception as e:  # noqa: BLE001
        logger.warning("assignment progress recompute failed: %s", e)
        return 0


def settle_elapsed_assignments(user_id: Optional[str] = None) -> int:
    """Settle active/paused assignments whose scheduled window has elapsed
    (None = every user). Returns the number of assignments settled."""
    try:
        with psycopg2.connect(_dsn()) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT public.program_assignment_settle_elapsed(%s::uuid)",
                    (str(user_id) if user_id else None,),
                )
                settled = cur.fetchone()[0] or 0
        if settled:
            logger.info(
                "settled %d elapsed program assignment(s) for user=%s",
                settled, user_id or "ALL",
            )
        return int(settled)
    except Exception as e:  # noqa: BLE001
        logger.warning("elapsed-assignment settle failed: %s", e)
        return 0


def sync_user_assignments(user_id: str) -> dict:
    """Read chokepoint: bring one user's assignments up to date before they are
    read (progress from the workouts rows, then settle anything elapsed)."""
    return {
        "progress_synced": _sync_user_progress(user_id),
        "settled": settle_elapsed_assignments(user_id),
    }


def _sync_user_progress(user_id: str) -> int:
    """Recompute progress for one user's assignments."""
    try:
        with psycopg2.connect(_dsn()) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    # COALESCE to an EMPTY array, never NULL — NULL means "every
                    # assignment in the table" to the SQL function.
                    "SELECT public.program_assignment_progress_sync("
                    "  (SELECT COALESCE(array_agg(id), ARRAY[]::uuid[])"
                    "   FROM user_program_assignments"
                    "   WHERE user_id = %s::uuid))",
                    (str(user_id),),
                )
                return int(cur.fetchone()[0] or 0)
    except Exception as e:  # noqa: BLE001
        logger.warning("assignment progress sync (user) failed: %s", e)
        return 0
