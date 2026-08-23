"""Progression-sanity guard for generated `set_targets` (E2E register #162).

Gemini authors `set_targets` for every exercise from a free-text prompt, with
no deterministic check against what the user actually lifted last time. On a
repeat exercise that let a single set's target jump BOTH weight and reps at
once relative to the user's best set from their last session — e.g. Cable
Pulldown's set 2 read 70 lb x 11 the session after the heaviest set actually
performed was 66 lb x 9 (a +4 lb AND +2 rep jump in one step), while the
`progression_pace` contract elsewhere in this codebase (see
`services/progression_service.py`) only ever moves ONE variable per step.

This module enforces that contract on the FINAL exercise list, mirroring how
`services/exercise_rag/injury_guard.py` is the terminal chokepoint for injury
safety: for every exercise with a recent logged session, any working
`set_targets` entry that increases weight beyond one equipment increment over
the last session's best set AND increases reps beyond that same best set gets
its reps held back to the best set's reps — the weight progression (the
authored delta across the pyramid) is left untouched. Fail-open: any lookup or
parsing error leaves the original exercises untouched.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase
from core.weight_utils import get_equipment_increment

logger = get_logger(__name__)


async def _last_best_sets(
    names: List[str], user_id: str
) -> Dict[str, Dict[str, float]]:
    """For each exercise name, the best (heaviest, tie-break higher reps) set
    logged in the user's most recent SESSION for that exercise. Returns
    ``{lower_name: {"weight_kg": .., "reps": ..}}``. Only exercises with at
    least one completed working set in their history are included.
    """
    clean = sorted({n.lower() for n in names if n})
    if not clean:
        return {}

    engine = get_supabase().engine
    sql = text(
        """
        WITH ranked AS (
            SELECT lower(exercise_name) AS lname,
                   workout_log_id,
                   ROW_NUMBER() OVER (
                       PARTITION BY lower(exercise_name)
                       ORDER BY recorded_at DESC
                   ) AS rn
            FROM public.performance_logs
            WHERE user_id = :user_id
              AND lower(exercise_name) = ANY(CAST(:names AS text[]))
              AND is_completed = TRUE
              AND set_type = 'working'
        ),
        last_session AS (
            SELECT lname, workout_log_id FROM ranked WHERE rn = 1
        )
        SELECT lower(pl.exercise_name) AS lname,
               pl.weight_kg,
               pl.reps_completed
        FROM public.performance_logs pl
        JOIN last_session ls
          ON ls.lname = lower(pl.exercise_name)
         AND ls.workout_log_id = pl.workout_log_id
        WHERE pl.user_id = :user_id
          AND pl.is_completed = TRUE
          AND pl.set_type = 'working'
        """
    )
    async with engine.connect() as conn:
        rows = (
            await conn.execute(sql, {"user_id": user_id, "names": clean})
        ).mappings().all()

    best: Dict[str, Dict[str, float]] = {}
    for r in rows:
        w = r["weight_kg"]
        reps = r["reps_completed"]
        if w is None or reps is None:
            continue
        current = best.get(r["lname"])
        if current is None or w > current["weight_kg"] or (
            w == current["weight_kg"] and reps > current["reps"]
        ):
            best[r["lname"]] = {"weight_kg": float(w), "reps": int(reps)}
    return best


def _clamp_one_variable(
    target: Dict[str, Any],
    best_weight_kg: float,
    best_reps: int,
    equipment_type: Optional[str],
) -> bool:
    """Mutates ``target`` in place if it progresses BOTH weight and reps past
    the last best set at once. Returns True if it changed something."""
    tw = target.get("target_weight_kg")
    tr = target.get("target_reps")
    if not isinstance(tw, (int, float)) or not isinstance(tr, (int, float)):
        return False

    increment = get_equipment_increment(equipment_type or "")
    weight_progressed = tw > best_weight_kg + increment + 0.01
    reps_progressed = tr > best_reps

    if weight_progressed and reps_progressed:
        # Hold reps at the last session's best — the weight axis keeps the
        # authored progression, reps no longer moves in the same step.
        target["target_reps"] = best_reps
        return True
    return False


async def enforce_progression_sanity(
    exercises: List[Dict[str, Any]], user_id: Optional[str]
) -> List[Dict[str, Any]]:
    """Clamp any generated `set_targets` entry that double-progresses (weight
    AND reps in the same step) past the user's last logged best set for that
    exercise. Fail-open: returns ``exercises`` unchanged on any error.
    """
    if not exercises or not user_id:
        return exercises
    try:
        names = [
            (e.get("name") or "").strip()
            for e in exercises
            if isinstance(e, dict)
        ]
        best_by_name = await _last_best_sets(names, str(user_id))
        if not best_by_name:
            return exercises

        for ex in exercises:
            if not isinstance(ex, dict):
                continue
            name = (ex.get("name") or "").strip().lower()
            best = best_by_name.get(name)
            if not best:
                continue
            targets = ex.get("set_targets")
            if not isinstance(targets, list):
                continue
            equipment_type = ex.get("equipment")
            for target in targets:
                if not isinstance(target, dict):
                    continue
                if str(target.get("set_type", "working")).lower() != "working":
                    continue
                _clamp_one_variable(
                    target, best["weight_kg"], best["reps"], equipment_type
                )
        return exercises
    except Exception as e:  # noqa: BLE001 — never block generation on this
        logger.warning(f"⚠️ [ProgressionGuard] enforce_progression_sanity failed: {e}")
        return exercises
