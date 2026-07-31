"""Server-side finalization of a `workout_logs` session row.

WHY THIS EXISTS
---------------
`workout_logs` is the per-SESSION summary row; `performance_logs` is the
durable per-SET store (``performance_logs.workout_log_id`` is NOT NULL, so a
set can never exist without its parent session row).

Two client tiers create the session row on the user's FIRST set with
``sets_json = []`` and only backfill the real set list at Finish:

* Easy tier   — ``POST /performance/workout-logs`` then ``PATCH
  /performance/workout-logs/{id}``. The PATCH is fire-and-forget on the client
  and is NOT in the offline queue, so a dropped connection at Finish leaves the
  row at ``status='in_progress'`` with ``sets_json='[]'`` forever — the session
  then vanishes from every ``.eq("status", "completed")`` reader even though
  the user's sets are sitting safely in ``performance_logs``.
* Watch sync  — ``/watch/sync`` streams sets straight into ``performance_logs``
  and closes the parent row at completion; it never had a sets_json backfill at
  all, so every watch session shipped a ``status='completed'`` row with an
  EMPTY set list.

Both are the same defect: the session summary is not derived from the durable
set store. This module is the ONE place that derivation lives. Callers:

* ``POST /workouts/{id}/complete``  (crud_completion.py) — the user explicitly
  finished, so any still-open log for that workout is closed here, server-side,
  regardless of whether the client's finalize PATCH ever landed.
* ``/watch/sync`` completion       (watch_sync.py)
* migration 2390                   — the same reconstruction, in SQL, for the
  rows that were already written empty.

NO FABRICATION: if a session has zero `performance_logs` rows, nothing is
invented — ``sets_json`` stays as it was and the caller is told so. An empty
set list is by definition not a finished session, which is exactly what
``trg_sync_workout_completion``'s empty-sets guard (migration 2390) enforces.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from core.logger import get_logger

logger = get_logger(__name__)

# Statuses that mean "this session row has not been closed yet".
_OPEN_LOG_STATUSES = ("in_progress",)


def build_sets_json_from_performance_logs(
    db, workout_log_id: str
) -> List[Dict[str, Any]]:
    """Rebuild a canonical ``sets_json`` array from the durable per-set store.

    Mirrors the shape the Easy/Advanced clients PATCH at Finish (flat list of
    sets, each carrying ``exercise_name`` + ``set_number`` + the logged
    numbers). Optional fields are omitted rather than defaulted so nothing is
    invented — a set with no RPE simply has no ``rpe`` key.

    Accepts either the Supabase DB facade (``db.client``) or a raw Supabase
    client, so the watch-sync path (which holds the raw client) can share it.

    Returns [] when the session has no logged sets.
    """
    client = getattr(db, "client", db)
    res = (
        client.table("performance_logs")
        .select(
            "exercise_name, exercise_id, set_number, reps_completed, weight_kg, "
            "rpe, rir, set_type, is_completed, set_duration_seconds, "
            "distance_meters, logging_mode, recorded_at"
        )
        .eq("workout_log_id", workout_log_id)
        .order("recorded_at", desc=False)
        .order("set_number", desc=False)
        .execute()
    )
    rows = res.data or []

    sets: List[Dict[str, Any]] = []
    for row in rows:
        entry: Dict[str, Any] = {
            "exercise_name": row.get("exercise_name"),
            "set_number": row.get("set_number"),
            # Both keys are present in the canonical client payload and
            # different readers use different ones — write both.
            "reps": row.get("reps_completed"),
            "reps_completed": row.get("reps_completed"),
            "weight_kg": row.get("weight_kg"),
            "is_completed": (
                True if row.get("is_completed") is None else bool(row["is_completed"])
            ),
        }
        for src, dst in (
            ("exercise_id", "exercise_id"),
            ("set_type", "set_type"),
            ("rpe", "rpe"),
            ("rir", "rir"),
            ("set_duration_seconds", "set_duration_seconds"),
            ("distance_meters", "distance_meters"),
            ("logging_mode", "logging_mode"),
            ("recorded_at", "completed_at"),
        ):
            if row.get(src) is not None:
                entry[dst] = row[src]
        sets.append(entry)

    return sets


def _count_completed_exercises(sets: Any) -> int:
    """Distinct-exercise count among completed sets, for ``exercises_completed``.

    E2E #139: the column is real (migration 1880) but no writer ever set it —
    the client posts its own count to a DIFFERENT table (``workout_exits``),
    not here. Derive it from the same durable set list this module already
    builds/uses, so ``exercises_completed`` reflects reality rather than
    staying at its ``DEFAULT 0`` forever.

    Prefers the stable ``exercise_id`` when present, falling back to
    ``exercise_name``. Accepts either a list of set dicts or a JSON string
    (the shapes ``_sets_json_is_empty`` already tolerates), so it works on
    both a freshly rebuilt ``sets_json`` and whatever the row already
    carried. A set explicitly marked ``is_completed: False`` doesn't count
    toward the exercise it belongs to.
    """
    if isinstance(sets, str):
        import json as _json
        try:
            sets = _json.loads(sets)
        except (ValueError, TypeError):
            sets = []
    if not isinstance(sets, list):
        return 0
    seen: set = set()
    for s in sets:
        if not isinstance(s, dict):
            continue
        if s.get("is_completed") is False:
            continue
        key = s.get("exercise_id") or s.get("exercise_name")
        if key:
            seen.add(key)
    return len(seen)


def _sets_json_is_empty(value: Any) -> bool:
    """True when the stored sets_json holds no sets."""
    if value is None:
        return True
    if isinstance(value, list):
        return len(value) == 0
    if isinstance(value, str):
        stripped = value.strip()
        return stripped in ("", "[]", "null")
    return False


def finalize_workout_log_row(
    db,
    log_row: Dict[str, Any],
    completed_at: Optional[str] = None,
    duration_minutes: Optional[int] = None,
    total_time_seconds: Optional[int] = None,
) -> Dict[str, Any]:
    """Close ONE session row: backfill sets_json from performance_logs, mark done.

    ``log_row`` must carry at least ``id`` and ``sets_json``.

    Returns ``{"log_id", "status_written", "sets_backfilled"}``.
    Raises whatever the DB raises — the caller decides whether a failure is
    fatal. Nothing here is silent.
    """
    client = getattr(db, "client", db)
    log_id = log_row["id"]
    update: Dict[str, Any] = {}
    sets_backfilled = 0

    if _sets_json_is_empty(log_row.get("sets_json")):
        rebuilt = build_sets_json_from_performance_logs(db, log_id)
        if rebuilt:
            update["sets_json"] = rebuilt
            sets_backfilled = len(rebuilt)

    # E2E #139: derive exercises_completed from the same set list — rebuilt
    # above when sets_json was empty, otherwise whatever the row already
    # carried. This is the terminal close step for the session row, so it's
    # the one place authoritative enough to always (re)write this column.
    final_sets = update.get("sets_json", log_row.get("sets_json"))
    exercises_completed = _count_completed_exercises(final_sets)
    update["exercises_completed"] = exercises_completed

    status_written = False
    if (log_row.get("status") or "") != "completed":
        update["status"] = "completed"
        status_written = True

    if completed_at and not log_row.get("completed_at"):
        update["completed_at"] = completed_at
    if duration_minutes is not None and log_row.get("duration_minutes") is None:
        update["duration_minutes"] = duration_minutes
    if total_time_seconds is not None and not log_row.get("total_time_seconds"):
        update["total_time_seconds"] = total_time_seconds

    if update:
        client.table("workout_logs").update(update).eq("id", log_id).execute()

    return {
        "log_id": log_id,
        "status_written": status_written,
        "sets_backfilled": sets_backfilled,
    }


def finalize_workout_log_by_id(
    db,
    workout_log_id: str,
    completed_at: Optional[str] = None,
    duration_minutes: Optional[int] = None,
    total_time_seconds: Optional[int] = None,
) -> Optional[Dict[str, Any]]:
    """Fetch + finalize a single session row by id. None when the row is gone."""
    client = getattr(db, "client", db)
    res = (
        client.table("workout_logs")
        .select("id, status, sets_json, completed_at, duration_minutes, total_time_seconds")
        .eq("id", workout_log_id)
        .limit(1)
        .execute()
    )
    rows = res.data or []
    if not rows:
        return None
    return finalize_workout_log_row(
        db,
        rows[0],
        completed_at=completed_at,
        duration_minutes=duration_minutes,
        total_time_seconds=total_time_seconds,
    )


def finalize_open_logs_for_workout(
    db,
    workout_id: str,
    user_id: str,
    completed_at: Optional[str] = None,
) -> Dict[str, int]:
    """Close every still-open session row belonging to ``workout_id``.

    Called from ``POST /workouts/{id}/complete``: the user pressed Finish, so
    the server — not a fire-and-forget client PATCH — is the authority that the
    session ended. Without this a lost finalize strands the log at
    'in_progress' and the session disappears from progress, streaks, PRs and
    every other ``status='completed'`` reader.

    Returns ``{"logs_closed", "sets_backfilled"}``.
    """
    completed_at = completed_at or datetime.now(timezone.utc).isoformat()
    client = getattr(db, "client", db)
    res = (
        client.table("workout_logs")
        .select("id, status, sets_json, completed_at, duration_minutes, total_time_seconds")
        .eq("workout_id", workout_id)
        .eq("user_id", user_id)
        .in_("status", list(_OPEN_LOG_STATUSES))
        .execute()
    )
    rows = res.data or []

    logs_closed = 0
    sets_backfilled = 0
    for row in rows:
        outcome = finalize_workout_log_row(db, row, completed_at=completed_at)
        logs_closed += 1 if outcome["status_written"] else 0
        sets_backfilled += outcome["sets_backfilled"]

    if logs_closed or sets_backfilled:
        logger.info(
            f"[LogFinalize] workout={workout_id} closed {logs_closed} open "
            f"session log(s), backfilled {sets_backfilled} set(s) from "
            f"performance_logs"
        )
    return {"logs_closed": logs_closed, "sets_backfilled": sets_backfilled}
