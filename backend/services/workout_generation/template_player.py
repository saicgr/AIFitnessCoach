"""
Template player — resolve a stored workout_program_templates row into a
concrete, ready-to-log GeneratedWorkoutResponse.

Call shape:

    workout = await plan_workout_from_template(
        user_id=user.id,                 # required
        template_id=None,                # None → use the user's active template
        week=None,                       # None → use template.current_week
        day=None,                        # None → use template.current_day
    )
    if workout is None:
        workout = await ai_generate_workout(...)   # caller falls through

What it does:

  1. Reads workout_program_templates — either by `template_id` or the
     single active row (there's a partial unique index enforcing "at most
     one active per user" at the DB layer).
  2. Picks the week + day from the prescription tree (falling back to the
     template's current_week / current_day pointers).
  3. For every PrescribedSet whose load_prescription is percent-based:
       a. Looks up the user's CURRENT 1RM from strength_records (NOT the
          one_rm_inputs dict captured at import time — that's a stale
          snapshot).
       b. Multiplies by template.training_max_factor (0.9 for Wendler, 1.0
          for everyone else). This converts 1RM → TM on the fly.
       c. Rounds to the nearest `template.rounding_multiple_kg`.
  4. For RPE-prescribed sets we leave weight_kg=None and surface the RPE as a
     set target (the AI set-target generator already understands RPE).
  5. Absolute-kg sets pass their weight straight through.
  6. Emits a GeneratedWorkoutResponse that matches the existing AI generator
     output shape so the rest of the workout pipeline (logger, UI, history
     writer) works without changes.

Contract: returns None when there is no active template so callers fall
through to AI generation. Never raises for "no data" cases — the absence of
a template, 1RM, or a matching day are all non-error conditions.
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional
from uuid import UUID

from core.supabase_client import get_supabase
from models.gemini_schemas import (
    GeneratedWorkoutResponse,
    SetTargetSchema,
    WorkoutExerciseSchema,
)
from services.workout_import.canonical import (
    LoadPrescriptionKind,
    SetType,
)

logger = logging.getLogger("template_player")


async def plan_workout_from_template(
    *,
    user_id: UUID,
    template_id: Optional[UUID] = None,
    week: Optional[int] = None,
    day: Optional[int] = None,
) -> Optional[GeneratedWorkoutResponse]:
    """Materialize a single workout from the user's active program template.

    Returns None when:
      * no matching active template exists,
      * the requested (week, day) is out of range,
      * the template's prescription tree is malformed.

    Callers should treat None as "fall through to AI generation" — we never
    raise for the absence of a template.
    """
    tpl_row = _load_template_row(user_id=user_id, template_id=template_id)
    if tpl_row is None:
        logger.info(f"[template_player] no active template for user={user_id}")
        return None

    prescription = tpl_row.get("raw_prescription") or {}
    weeks = prescription.get("weeks") or []
    if not weeks:
        logger.warning(f"[template_player] template {tpl_row.get('id')} has no weeks")
        return None

    # Resolve pointers.
    week_num = int(week) if week is not None else int(tpl_row.get("current_week") or 1)
    day_num = int(day) if day is not None else int(tpl_row.get("current_day") or 1)

    week_obj = _find_week(weeks, week_num)
    if week_obj is None:
        # Wrap around to week 1 if we ran past the end — programs like GZCLP
        # are designed to restart. Alternative: return None for finite programs.
        if week_num > 1:
            week_obj = _find_week(weeks, 1)
            week_num = 1
    if week_obj is None:
        return None

    day_obj = _find_day(week_obj, day_num)
    if day_obj is None:
        # Wrap to day 1 if pointer overshot this week's day count.
        day_obj = (week_obj.get("days") or [None])[0]
        day_num = 1
    if day_obj is None:
        return None

    # Pull the user's current 1RM map for all referenced compound lifts.
    needed_refs = _collect_references(day_obj)
    user_one_rms = _fetch_user_current_1rms(user_id, needed_refs)

    # Also accept the snapshot as a fallback when strength_records has no
    # entries for that lift yet — but ONLY as a backfill. Live takes priority.
    snapshot = tpl_row.get("one_rm_inputs") or {}
    one_rms_merged: dict[str, float] = {}
    for ref in needed_refs:
        live = user_one_rms.get(ref)
        snap = snapshot.get(_snapshot_key_for(ref))
        if live is not None and live > 0:
            one_rms_merged[ref] = float(live)
        elif snap is not None:
            one_rms_merged[ref] = float(snap)

    tm_factor = float(tpl_row.get("training_max_factor") or 1.0)
    rounding_kg = float(tpl_row.get("rounding_multiple_kg") or 2.5)

    exercise_schemas: list[WorkoutExerciseSchema] = []
    for ex in day_obj.get("exercises") or []:
        schema = _resolve_exercise(
            ex=ex,
            one_rms=one_rms_merged,
            tm_factor=tm_factor,
            rounding_kg=rounding_kg,
        )
        if schema is not None:
            exercise_schemas.append(schema)

    if not exercise_schemas:
        logger.warning(
            f"[template_player] template {tpl_row.get('id')} produced 0 exercises"
        )
        return None

    program_name = tpl_row.get("program_name") or "Program Workout"
    day_label = day_obj.get("day_label") or f"Day {day_num}"

    return GeneratedWorkoutResponse(
        name=f"{program_name} — {day_label}",
        type="strength",
        difficulty="intermediate",
        description=(
            f"Imported creator program: {tpl_row.get('program_creator') or 'unknown'}. "
            f"Week {week_num}, Day {day_num}."
        ),
        duration_minutes=_estimate_duration(exercise_schemas),
        target_muscles=[],
        exercises=exercise_schemas,
        notes=tpl_row.get("notes"),
    )


# ─────────────────────────── Helpers ───────────────────────────

def _load_template_row(
    *, user_id: UUID, template_id: Optional[UUID],
) -> Optional[Dict[str, Any]]:
    """Return a single workout_program_templates row or None.

    Uses the Supabase client synchronously — Supabase-py doesn't expose an
    async builder, and this call lands behind the API request loop anyway.
    """
    try:
        supabase = get_supabase()
    except Exception as e:
        logger.warning(f"[template_player] supabase unavailable: {e}")
        return None

    try:
        q = supabase.table("workout_program_templates").select("*").eq(
            "user_id", str(user_id)
        )
        if template_id is not None:
            q = q.eq("id", str(template_id))
        else:
            q = q.eq("active", True)
        result = q.limit(1).execute()
    except Exception as e:
        logger.warning(f"[template_player] template lookup failed: {e}")
        return None

    if not result.data:
        return None
    return result.data[0]


def _find_week(weeks: List[Dict[str, Any]], week_num: int) -> Optional[Dict[str, Any]]:
    for w in weeks:
        if int(w.get("week_number") or 0) == week_num:
            return w
    return None


def _find_day(week_obj: Dict[str, Any], day_num: int) -> Optional[Dict[str, Any]]:
    for d in week_obj.get("days") or []:
        if int(d.get("day_number") or 0) == day_num:
            return d
    return None


def _collect_references(day_obj: Dict[str, Any]) -> set[str]:
    """Every lift the day's prescription cites by %1RM / %TM."""
    refs: set[str] = set()
    for ex in day_obj.get("exercises") or []:
        for s in ex.get("sets") or []:
            lp = s.get("load_prescription") or {}
            ref = lp.get("reference_1rm_exercise")
            if ref:
                refs.add(ref)
    return refs


# Map the refs we emit (back_squat / bench_press / deadlift / overhead_press)
# to the exercise_name and one_rm_inputs snapshot keys.
_REF_TO_EXERCISE_NAME = {
    "back_squat": "Back Squat",
    "bench_press": "Bench Press",
    "deadlift": "Deadlift",
    "overhead_press": "Overhead Press",
}

_REF_TO_SNAPSHOT_KEY = {
    "back_squat": "squat_kg",
    "bench_press": "bench_kg",
    "deadlift": "deadlift_kg",
    "overhead_press": "ohp_kg",
}


def _snapshot_key_for(ref: str) -> str:
    return _REF_TO_SNAPSHOT_KEY.get(ref, f"{ref}_kg")


def _fetch_user_current_1rms(
    user_id: UUID, needed_refs: set[str],
) -> Dict[str, float]:
    """Pull the MAX estimated_1rm per reference lift from strength_records.

    We match by exercise_name — the canonical names (Back Squat / Bench
    Press / Deadlift / Overhead Press) match what the template emits. This
    is a pragmatic choice; a stricter schema would match by exercise_id
    once every record also carried one, which is still inconsistent across
    legacy data.
    """
    if not needed_refs:
        return {}

    try:
        supabase = get_supabase()
    except Exception as e:
        logger.warning(f"[template_player] supabase unavailable for 1RM fetch: {e}")
        return {}

    out: Dict[str, float] = {}
    for ref in needed_refs:
        name = _REF_TO_EXERCISE_NAME.get(ref, ref.replace("_", " ").title())
        try:
            result = (
                supabase.table("strength_records")
                .select("estimated_1rm")
                .eq("user_id", str(user_id))
                .ilike("exercise_name", name)
                .order("estimated_1rm", desc=True)
                .limit(1)
                .execute()
            )
        except Exception as e:
            logger.warning(
                f"[template_player] 1RM lookup for {ref} failed: {e}"
            )
            continue
        if result.data:
            val = result.data[0].get("estimated_1rm")
            if val is not None:
                out[ref] = float(val)
    return out


def _resolve_exercise(
    *,
    ex: Dict[str, Any],
    one_rms: Dict[str, float],
    tm_factor: float,
    rounding_kg: float,
) -> Optional[WorkoutExerciseSchema]:
    """Resolve one PrescribedExercise → WorkoutExerciseSchema."""
    raw_name = ex.get("exercise_name_raw") or ex.get("exercise_name_canonical")
    if not raw_name:
        return None

    sets_list = ex.get("sets") or []
    if not sets_list:
        return None

    # Build per-set targets.
    set_targets: list[SetTargetSchema] = []
    total_reps: list[int] = []
    for s in sets_list:
        rep_target = s.get("rep_target") or {}
        rmin = int(rep_target.get("min") or 8)
        rmax = int(rep_target.get("max") or rmin)
        amrap = bool(rep_target.get("amrap_last"))
        # Mid-point reps is a reasonable default for the set target. AMRAP
        # sets surface min as the floor; UI shows "X+".
        target_reps = rmin if amrap else max(rmin, (rmin + rmax) // 2 or rmin)
        total_reps.append(target_reps)

        weight_kg = _resolve_set_weight(
            load_presc=s.get("load_prescription") or {},
            one_rms=one_rms,
            tm_factor=tm_factor,
            rounding_kg=rounding_kg,
        )
        target_rpe: Optional[int] = None
        rpe_target = s.get("rpe_target")
        if isinstance(rpe_target, dict):
            mv = rpe_target.get("max") or rpe_target.get("min")
            if mv is not None:
                target_rpe = int(mv)
        elif (s.get("load_prescription") or {}).get("kind") == LoadPrescriptionKind.RPE_TARGET.value:
            lp = s.get("load_prescription") or {}
            v = lp.get("value_max") or lp.get("value_min")
            if v is not None:
                target_rpe = int(v)

        # Map CanonicalProgramTemplate SetType string → SetTargetSchema set_type.
        stype_raw = (s.get("set_type") or SetType.WORKING.value)
        stype_str = stype_raw.value if hasattr(stype_raw, "value") else str(stype_raw)
        # SetTargetSchema only allows {warmup, working, drop, failure, amrap}.
        if stype_str not in ("warmup", "working", "drop", "failure", "amrap"):
            stype_str = "working"

        set_targets.append(SetTargetSchema(
            set_number=len(set_targets) + 1,
            set_type=stype_str,
            target_weight_kg=weight_kg,
            target_reps=target_reps,
            target_rpe=target_rpe,
        ))

    # Rep count used by the UI (integer) — pick the mode/most-common value.
    typical_reps = max(set(total_reps), key=total_reps.count) if total_reps else 8

    # Top-line starting weight = first working-set weight if we resolved one.
    first_working_weight: Optional[float] = None
    for t in set_targets:
        if t.target_weight_kg is not None:
            first_working_weight = t.target_weight_kg
            break

    return WorkoutExerciseSchema(
        name=raw_name,
        sets=len(sets_list),
        reps=typical_reps,
        weight_kg=first_working_weight,
        rest_seconds=_infer_rest_seconds(sets_list),
        muscle_group=None,
        notes=_first_set_notes(sets_list),
        set_targets=set_targets,
    )


def _resolve_set_weight(
    *,
    load_presc: Dict[str, Any],
    one_rms: Dict[str, float],
    tm_factor: float,
    rounding_kg: float,
) -> Optional[float]:
    """Return the absolute kg weight for a single PrescribedSet."""
    kind = load_presc.get("kind")
    if kind in (LoadPrescriptionKind.PERCENT_1RM.value,
                LoadPrescriptionKind.PERCENT_TM.value):
        ref = load_presc.get("reference_1rm_exercise")
        if not ref:
            return None
        one_rm = one_rms.get(ref)
        if one_rm is None or one_rm <= 0:
            return None
        # For %1RM prescriptions, apply training_max_factor to get TM first.
        # For %TM prescriptions the factor was already implicit in the value;
        # we still multiply so downstream math is consistent — the template
        # layer picks training_max_factor=1.0 for non-Wendler programs, so
        # for them this is a no-op.
        if kind == LoadPrescriptionKind.PERCENT_TM.value:
            tm = one_rm * tm_factor
        else:
            # PERCENT_1RM — no TM conversion.
            tm = one_rm
        pct_max = load_presc.get("value_max") or load_presc.get("value_min")
        if pct_max is None:
            return None
        target = float(tm) * float(pct_max)
        return _round_to_multiple(target, rounding_kg)

    if kind == LoadPrescriptionKind.ABSOLUTE_KG.value:
        v = load_presc.get("value_max") or load_presc.get("value_min")
        if v is None:
            return None
        return _round_to_multiple(float(v), rounding_kg)

    # BODYWEIGHT, RPE_TARGET, UNSPECIFIED → caller surfaces RPE as a target.
    return None


def _round_to_multiple(value: float, multiple: float) -> float:
    if multiple <= 0:
        return round(value, 2)
    return round(round(value / multiple) * multiple, 2)


def _infer_rest_seconds(sets_list: List[Dict[str, Any]]) -> int:
    for s in sets_list:
        r_max = s.get("rest_seconds_max")
        r_min = s.get("rest_seconds_min")
        if r_max is not None:
            return int(r_max)
        if r_min is not None:
            return int(r_min)
    # Defaults: compounds need 3 min, isolations 60-90s. We can't classify
    # here so we pick a middle-ground 120s.
    return 120


def _first_set_notes(sets_list: List[Dict[str, Any]]) -> Optional[str]:
    for s in sets_list:
        n = s.get("notes")
        if n:
            return str(n)
    return None


def _estimate_duration(exercises: List[WorkoutExerciseSchema]) -> int:
    """Rough per-session duration estimate: sets × (rest + 30s under tension)."""
    total_seconds = 0
    for ex in exercises:
        per_set = (ex.rest_seconds or 120) + 30
        total_seconds += ex.sets * per_set
    return max(15, total_seconds // 60)
