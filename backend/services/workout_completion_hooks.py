"""Shared "a workout just became completed" side-effect hooks.

CHOKEPOINT PROBLEM (2026-08, row 1 CRIT + row 56 HIGH of the UI_E2E sweep):
strength/fitness score recalculation (``schedule_score_recalc``) and trophy
checks (``check_workout_completion_trophies``) were wired ONLY into
``POST /workouts/{id}/complete`` (api/v1/workouts/crud_completion.py).

But migration 2256 (`sync_workout_completion_from_log.sql`) installs
``trg_sync_workout_completion`` on ``workout_logs``: whenever a
``workout_logs`` row's ``status`` becomes ``'completed'``, the trigger flips
``workouts.is_completed = true`` DIRECTLY IN POSTGRES — completely bypassing
the ``/complete`` endpoint and therefore every background task wired only
into it. That trigger exists precisely BECAUSE ``/complete`` is the fragile
write (see the migration's own comment: "workout completion is two
independent client writes ... (2) POST /workouts/{id}/complete -> flips
workouts.is_completed [fragile]"), so the population that needed the trigger
backstop is exactly the population that silently never got a strength/fitness
score or a trophy check.

Verified live (QA account 1aa02a24-...): 2 completed workouts / 4
workout_logs, workouts.is_completed=true on 2 rows, but ZERO rows in
strength_scores/fitness_scores/nutrition_scores/user_achievements/
trophy_progress, and ZERO ``workout_changes`` rows with
``change_type='completed'`` — proving neither completion ever passed through
``/complete``. Calling ``_recompute_strength_for_user`` directly for this
account immediately produced 16 muscle scores, confirming the calculators
themselves are correct — only the wiring was missing.

Any server-side write path that can set ``workout_logs.status = 'completed'``
must call ``run_post_completion_hooks`` (as a background task), not just
``/complete``. Currently that's:
  * ``POST /workouts/{id}/complete`` (api/v1/workouts/crud_completion.py) —
    already wired directly (kept as-is, not routed through here, to avoid
    touching a working call site).
  * ``POST /performance/workout-logs`` (create_workout_log) and
    ``PATCH /performance/workout-logs/{id}`` (update_workout_log) in
    api/v1/performance_db.py — the previously-missing call sites, wired here.

Best-effort: every hook swallows its own errors so a failure here can never
surface to the caller or block a workout-log write.
"""
from __future__ import annotations

from typing import Any, Dict, Optional

from core.logger import get_logger

logger = get_logger(__name__)


async def run_post_completion_hooks(
    *,
    user_id: str,
    supabase,
    timezone_str: str,
    workout_id: Optional[str] = None,
) -> None:
    """Fire strength/fitness score recalc + trophy checks for a completion.

    ``workout_id``, when given, is used to look up the workout's exercises so
    exercise-mastery / specific-exercise trophies (which need to know WHAT was
    trained) can be checked too — not just the workout-data-agnostic ones
    (volume, time, consistency). Missing/unresolvable workout_id degrades
    gracefully to the workout-data-agnostic checks only; it never blocks the
    score recalc half of this function.
    """
    try:
        from api.v1.workouts.crud_background_tasks import schedule_score_recalc

        schedule_score_recalc(user_id=user_id, supabase=supabase, timezone_str=timezone_str)
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[post_completion_hooks] score recalc schedule failed for user={user_id}: {e}")

    workout_data: Dict[str, Any] = {}
    if workout_id:
        try:
            wrow = (
                supabase.table("workouts")
                .select("exercises_json")
                .eq("id", workout_id)
                .maybe_single()
                .execute()
            )
            if wrow and wrow.data:
                exercises = wrow.data.get("exercises_json") or []
                if isinstance(exercises, str):
                    import json

                    exercises = json.loads(exercises) if exercises else []
                workout_data = {"exercises": exercises}
        except Exception as e:  # noqa: BLE001
            logger.warning(
                f"[post_completion_hooks] exercises lookup failed for workout_id={workout_id}: {e}"
            )

    try:
        from api.v1.trophy_triggers import check_workout_completion_trophies

        awarded = await check_workout_completion_trophies(user_id=user_id, workout_data=workout_data)
        if awarded:
            logger.info(f"[post_completion_hooks] awarded {len(awarded)} trophy(ies) to user={user_id}")
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[post_completion_hooks] trophy check failed for user={user_id}: {e}")
