"""
Issue 3: Workout mutation tools for the in-workout AI coach.

These tools let the LangGraph Workout agent actually MUTATE the active
workout (log a single set, swap one exercise, build / break a superset,
reorder exercises) instead of only describing changes.

Every tool in this module returns the strict shape:

    {
      "success": bool,
      "action_data": {"action": str, ...payload},
      "summary_text": str,
      "requires_confirmation": bool,
    }

The chat node injects ``action_data`` into the assistant message metadata
so the Flutter ChatActionConfirmCard renders an Apply / Cancel UI before
the change is committed via the appropriate WorkoutRepository method.

Concurrent-edit safety
----------------------
Workout.exercises_json is the single source of truth. Any mutation here
re-reads the row, applies its delta, and stamps ``last_modified_at``
with the existing row's ``last_modified_at`` as the precondition. If the
caller observed a stale ``exercises_json`` (e.g., user manually swapped
in the UI between the LLM proposal and Apply), the tool returns
``success=False`` with reason="exercise list changed" so the frontend
can re-prompt the coach (edge case 38).
"""
from __future__ import annotations

import json
import re
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from langchain_core.tools import tool

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

_UUID_PATTERN = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE,
)

# Workout types that don't structurally support paired supersets — coach
# should suggest converting them to a circuit instead of silently failing.
_SUPERSET_INCOMPATIBLE_TYPES = {"amrap", "circuit", "emom", "tabata"}

LBS_TO_KG = 0.45359237


# ─────────────────────────────────────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────────────────────────────────────


def _is_uuid(value: str) -> bool:
    return bool(value and _UUID_PATTERN.match(str(value)))


def _ok(action: str, summary: str, payload: Dict[str, Any], requires_confirmation: bool = False) -> Dict[str, Any]:
    return {
        "success": True,
        "action_data": {"action": action, **payload},
        "summary_text": summary,
        "requires_confirmation": requires_confirmation,
    }


def _fail(action: str, summary: str, payload: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    return {
        "success": False,
        "action_data": {"action": action, **(payload or {})},
        "summary_text": summary,
        "requires_confirmation": False,
    }


def _load_workout(workout_id: str) -> Optional[Dict[str, Any]]:
    if not _is_uuid(workout_id):
        return None
    db = get_supabase_db()
    return db.get_workout(workout_id)


def _exercises_list(workout: Dict[str, Any]) -> List[Dict[str, Any]]:
    raw = workout.get("exercises_json") or workout.get("exercises") or []
    if isinstance(raw, str):
        try:
            raw = json.loads(raw) if raw else []
        except json.JSONDecodeError:
            raw = []
    return list(raw or [])


def _ensure_exercise_id(ex: Dict[str, Any]) -> str:
    """
    Workouts created before exercises had stable ids fall back to a
    deterministic id derived from the slot index + name. Tools that need
    to address an exercise by id will populate ``exercise_id`` on the
    fly when missing.
    """
    eid = ex.get("exercise_id") or ex.get("id") or ex.get("library_id")
    if not eid:
        eid = str(uuid.uuid4())
        ex["exercise_id"] = eid
    return str(eid)


def _commit_exercises(
    workout_id: str,
    exercises: List[Dict[str, Any]],
    expected_last_modified: Optional[str],
    method: str,
) -> bool:
    """
    Optimistic concurrency: only update if last_modified_at matches the
    snapshot we read. Returns False on stale write.
    """
    db = get_supabase_db()
    now = datetime.now(timezone.utc).isoformat()

    update = {
        "exercises_json": json.dumps(exercises),
        "last_modified_at": now,
        "last_modified_method": method,
    }

    if expected_last_modified:
        # Best-effort precondition. Supabase Python SDK doesn't expose a
        # native If-Match, so we re-read and compare before update.
        current = db.get_workout(workout_id)
        if not current:
            return False
        if current.get("last_modified_at") not in (None, expected_last_modified):
            logger.warning(
                "[mutation] Optimistic-lock miss on %s (expected=%s got=%s)",
                workout_id,
                expected_last_modified,
                current.get("last_modified_at"),
            )
            return False

    db.update_workout(workout_id, update)
    return True


def _kg_from(weight: Optional[float], unit: Optional[str]) -> Optional[float]:
    if weight is None:
        return None
    if (unit or "").lower() in ("lb", "lbs", "pound", "pounds"):
        return round(weight * LBS_TO_KG, 4)
    return float(weight)


# ─────────────────────────────────────────────────────────────────────────────
# Tools
# ─────────────────────────────────────────────────────────────────────────────


@tool
def swap_single_exercise(
    workout_id: str,
    old_exercise_name: str,
    new_exercise_name: str,
    reason: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Swap a single exercise in the user's current workout for another one.
    Equivalent server-side to POST /api/v1/workouts/swap-exercise — use
    this when the user says "replace X with Y" mid-workout.

    Args:
        workout_id: UUID of the active workout.
        old_exercise_name: Name of the exercise currently in the workout.
        new_exercise_name: Name of the replacement exercise.
        reason: Optional rationale shown in the confirm card.

    Returns:
        Strict tool envelope. action_data.action = "swap_exercise".
    """
    action = "swap_exercise"
    if not _is_uuid(workout_id):
        return _fail(action, f"Invalid workout id: {workout_id}.")

    workout = _load_workout(workout_id)
    if not workout:
        return _fail(action, f"Workout {workout_id} not found.")

    exercises = _exercises_list(workout)
    target = next(
        (e for e in exercises if e.get("name", "").lower() == old_exercise_name.lower()),
        None,
    )
    if not target:
        return _fail(
            action,
            f"'{old_exercise_name}' isn't in this workout right now.",
            {"workout_id": workout_id},
        )

    summary = f"Swap {old_exercise_name} → {new_exercise_name}"
    if reason:
        summary += f" ({reason})"

    return _ok(
        action,
        summary,
        {
            "workout_id": workout_id,
            "old": old_exercise_name,
            "new": new_exercise_name,
            "reason": reason,
        },
        requires_confirmation=True,
    )


@tool
def log_set(
    workout_id: str,
    exercise_id: str,
    set_index: int,
    weight: Optional[float] = None,
    reps: Optional[int] = None,
    rir: Optional[int] = None,
    side: Optional[str] = None,
    weight_unit: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Log a completed set for an exercise in the active workout.

    Args:
        workout_id: UUID of the workout.
        exercise_id: UUID of the exercise within the workout (or its
            library_id when no per-slot id exists).
        set_index: 1-based set number (e.g., 3 for "set 3").
        weight: Optional weight value. Bodyweight exercises pass null.
        reps: Reps completed (required unless duration-based).
        rir: Reps in reserve.
        side: 'L', 'R', or null for bilateral exercises.
        weight_unit: 'lb' or 'kg' (LLM passes whatever the user said).
            Backend converts to user's persisted unit.

    Returns:
        Tool envelope. If the set already has a completed log,
        ``requires_confirmation=True`` and summary asks to override.

        For drop-set syntax ("40-30-20 lb x 8-8-6"), the LLM is
        responsible for calling this tool once per row OR passing a
        single call where ``set_index`` is the first slot and the
        front-end batches — see ``log_drop_set`` (multi-set variant
        embedded in action_data when the LLM emits parallel calls).
    """
    action = "log_set"
    if not _is_uuid(workout_id):
        return _fail(action, f"Invalid workout id: {workout_id}.")

    workout = _load_workout(workout_id)
    if not workout:
        return _fail(action, f"Workout {workout_id} not found.")

    exercises = _exercises_list(workout)
    target = None
    for ex in exercises:
        if str(ex.get("exercise_id") or ex.get("id") or ex.get("library_id") or "") == str(exercise_id):
            target = ex
            break
        if ex.get("name", "").lower() == str(exercise_id).lower():
            target = ex
            break

    if not target:
        return _fail(action, "That exercise is no longer in your workout.")

    is_bodyweight = (
        (target.get("equipment") or "").lower() == "bodyweight"
        or weight is None
    )

    if not is_bodyweight and weight is None:
        return _fail(action, "Weight is required for non-bodyweight exercises.")
    if reps is None and not target.get("duration_seconds"):
        return _fail(action, "Reps are required for rep-based exercises.")

    if side and side.upper() not in ("L", "R"):
        return _fail(action, f"Side must be 'L' or 'R', got '{side}'.")

    weight_kg = _kg_from(weight, weight_unit) if not is_bodyweight else None

    # Detect override: any existing performance_log for this slot?
    db = get_supabase_db()
    requires_confirmation = False
    try:
        existing = (
            db.client.table("performance_logs")
            .select("id, set_number, weight_kg, reps_completed")
            .eq("user_id", workout.get("user_id"))
            .eq("exercise_name", target.get("name"))
            .eq("set_number", set_index)
            .order("recorded_at", desc=True)
            .limit(1)
            .execute()
        )
        if existing.data:
            requires_confirmation = True
    except Exception as e:
        logger.warning("[log_set] override-check failed: %s", e)

    bw_label = "bodyweight" if is_bodyweight else f"{weight} {weight_unit or 'lb'}"
    side_label = f" ({side.upper()} side only)" if side else ""
    summary = (
        f"Log set {set_index} for {target.get('name')}: "
        f"{bw_label} × {reps if reps is not None else target.get('duration_seconds', '?')} reps"
        f"{f' @ RIR {rir}' if rir is not None else ''}{side_label}"
    )
    if requires_confirmation:
        summary = f"Override existing log for set {set_index}? " + summary

    return _ok(
        action,
        summary,
        {
            "workout_id": workout_id,
            "exercise_id": _ensure_exercise_id(target),
            "exercise_name": target.get("name"),
            "set_index": set_index,
            "weight": weight,
            "weight_kg": weight_kg,
            "weight_unit": weight_unit,
            "reps": reps,
            "rir": rir,
            "side": side.upper() if side else None,
            "is_bodyweight": is_bodyweight,
            "is_override": requires_confirmation,
        },
        requires_confirmation=requires_confirmation,
    )


@tool
def create_superset(
    workout_id: str,
    exercise_ids: List[str],
) -> Dict[str, Any]:
    """
    Group 2+ exercises into a superset (or triset / giant set).

    Args:
        workout_id: UUID of the workout.
        exercise_ids: 2 or more exercise ids in the order they should
            be performed inside the superset.

    Behavior:
        • Non-adjacent exercises are reordered to be adjacent first;
          the summary surfaces "Reordered exercises 2-5".
        • If any exercise is already in another superset, that prior
          group is broken atomically.
        • AMRAP / circuit / EMOM workouts return success=False with
          a "convert to circuit?" suggestion.
        • Triset / giant set (3+) supported.
    """
    action = "create_superset"
    if not _is_uuid(workout_id):
        return _fail(action, f"Invalid workout id: {workout_id}.")
    if not exercise_ids or len(exercise_ids) < 2:
        return _fail(action, "Need at least 2 exercises to make a superset.")

    workout = _load_workout(workout_id)
    if not workout:
        return _fail(action, f"Workout {workout_id} not found.")

    workout_type = (workout.get("type") or "").lower()
    if any(t in workout_type for t in _SUPERSET_INCOMPATIBLE_TYPES):
        return _fail(
            action,
            "Workout type doesn't support supersets — convert to circuit?",
            {
                "workout_id": workout_id,
                "workout_type": workout_type,
                "suggest_convert_to_circuit": True,
            },
        )

    exercises = _exercises_list(workout)
    # Resolve ids → indices
    id_to_index: Dict[str, int] = {}
    for i, ex in enumerate(exercises):
        eid = str(ex.get("exercise_id") or ex.get("id") or ex.get("library_id") or "")
        if eid:
            id_to_index[eid] = i
        # Also accept name match as a fallback
        id_to_index.setdefault(ex.get("name", "").lower(), i)

    indices: List[int] = []
    for eid in exercise_ids:
        idx = id_to_index.get(str(eid)) or id_to_index.get(str(eid).lower())
        if idx is None:
            return _fail(
                action,
                f"Exercise '{eid}' isn't in this workout.",
                {"workout_id": workout_id},
            )
        indices.append(idx)

    needs_reorder = any(b - a != 1 for a, b in zip(indices, indices[1:]))

    new_group_id = str(uuid.uuid4())
    # Break any prior groups for these exercises (atomic, before assignment).
    for ex in exercises:
        eid = str(ex.get("exercise_id") or ex.get("id") or ex.get("library_id") or "")
        if eid in {str(x) for x in exercise_ids} and ex.get("superset_group_id"):
            ex.pop("superset_group_id", None)
            ex.pop("superset_group", None)

    if needs_reorder:
        # Pull selected items in user-supplied order, anchor at first index.
        anchor = min(indices)
        selected = [exercises[i] for i in indices]
        remaining = [ex for i, ex in enumerate(exercises) if i not in indices]
        new_list = remaining[:anchor] + selected + remaining[anchor:]
        exercises = new_list
        # Recompute indices to be contiguous starting at anchor
        indices = list(range(anchor, anchor + len(selected)))

    for i in indices:
        exercises[i]["superset_group_id"] = new_group_id
        # Backwards-compat numeric flag used by some legacy renderers.
        exercises[i]["superset_group"] = abs(hash(new_group_id)) % 1000

    ok = _commit_exercises(
        workout_id,
        exercises,
        workout.get("last_modified_at"),
        method="ai_create_superset",
    )
    if not ok:
        return _fail(
            action,
            "Workout changed since suggestion — coach is re-thinking.",
            {"workout_id": workout_id, "reason": "exercise list changed"},
        )

    names = [exercises[i].get("name", "?") for i in indices]
    summary = f"Created superset: {' + '.join(names)}"
    if needs_reorder:
        summary = f"Reordered exercises to make this superset: {' + '.join(names)}"

    return _ok(
        action,
        summary,
        {
            "workout_id": workout_id,
            "superset_group_id": new_group_id,
            "exercise_ids": exercise_ids,
            "reordered": needs_reorder,
        },
        requires_confirmation=False,  # already applied — confirm-card not needed for backend-applied
    )


@tool
def break_superset(
    workout_id: str,
    superset_group_id: str,
) -> Dict[str, Any]:
    """
    Clear a superset group, returning its exercises to standalone slots.

    Args:
        workout_id: UUID of the workout.
        superset_group_id: UUID of the group to break.

    Returns:
        success=False with current group ids if ``superset_group_id``
        is stale (already broken or never existed).
    """
    action = "break_superset"
    if not _is_uuid(workout_id):
        return _fail(action, f"Invalid workout id: {workout_id}.")

    workout = _load_workout(workout_id)
    if not workout:
        return _fail(action, f"Workout {workout_id} not found.")

    exercises = _exercises_list(workout)
    matching = [ex for ex in exercises if ex.get("superset_group_id") == superset_group_id]
    if not matching:
        current_groups = sorted({ex.get("superset_group_id") for ex in exercises if ex.get("superset_group_id")})
        return _fail(
            action,
            "That superset isn't active anymore.",
            {"workout_id": workout_id, "current_groups": current_groups},
        )

    for ex in matching:
        ex.pop("superset_group_id", None)
        ex.pop("superset_group", None)

    ok = _commit_exercises(
        workout_id,
        exercises,
        workout.get("last_modified_at"),
        method="ai_break_superset",
    )
    if not ok:
        return _fail(
            action,
            "Workout changed since suggestion — coach is re-thinking.",
            {"workout_id": workout_id, "reason": "exercise list changed"},
        )

    names = [ex.get("name", "?") for ex in matching]
    return _ok(
        action,
        f"Broke superset: {' + '.join(names)} are now separate.",
        {
            "workout_id": workout_id,
            "superset_group_id": superset_group_id,
            "freed_exercises": names,
        },
    )


@tool
def reorder_exercises(
    workout_id: str,
    new_order: List[str],
) -> Dict[str, Any]:
    """
    Reorder the exercises in a workout.

    Args:
        workout_id: UUID of the workout.
        new_order: Exercise ids in the desired order. Any exercise the
            user is currently mid-set on will keep its slot — the rest
            are reordered around it.
    """
    action = "reorder_exercises"
    if not _is_uuid(workout_id):
        return _fail(action, f"Invalid workout id: {workout_id}.")

    workout = _load_workout(workout_id)
    if not workout:
        return _fail(action, f"Workout {workout_id} not found.")

    exercises = _exercises_list(workout)
    by_id: Dict[str, Dict[str, Any]] = {}
    for ex in exercises:
        eid = str(ex.get("exercise_id") or ex.get("id") or ex.get("library_id") or "")
        if eid:
            by_id[eid] = ex
        by_id.setdefault(ex.get("name", "").lower(), ex)

    in_progress_idx: Optional[int] = None
    for i, ex in enumerate(exercises):
        if ex.get("in_progress") or ex.get("active_set"):
            in_progress_idx = i
            break

    desired: List[Dict[str, Any]] = []
    for token in new_order:
        ex = by_id.get(str(token)) or by_id.get(str(token).lower())
        if not ex:
            return _fail(action, f"Exercise '{token}' not in workout.")
        desired.append(ex)

    if in_progress_idx is not None:
        anchor = exercises[in_progress_idx]
        if anchor in desired:
            desired.remove(anchor)
        desired.insert(in_progress_idx, anchor)

    # Append exercises not mentioned in new_order at the end (preserve them).
    mentioned = {id(x) for x in desired}
    leftovers = [ex for ex in exercises if id(ex) not in mentioned]
    final_list = desired + leftovers

    ok = _commit_exercises(
        workout_id,
        final_list,
        workout.get("last_modified_at"),
        method="ai_reorder",
    )
    if not ok:
        return _fail(
            action,
            "Workout changed since suggestion — coach is re-thinking.",
            {"workout_id": workout_id, "reason": "exercise list changed"},
        )

    return _ok(
        action,
        f"Reordered {len(final_list)} exercises.",
        {
            "workout_id": workout_id,
            "new_order_names": [e.get("name") for e in final_list],
            "kept_in_progress": in_progress_idx is not None,
        },
    )


@tool
def add_set(
    workout_id: str,
    exercise_name: str,
    is_drop_set: bool = False,
) -> Dict[str, Any]:
    """
    Add one more set (or a drop set) to an exercise in the active workout.

    Use this when the user says "add a set to bench", "give me one more set of
    squats", or "add a drop set to leg press" mid-workout. A drop set is a
    back-off set at a lighter load with little/no rest — set ``is_drop_set=True``
    for that, otherwise it's a normal working set.

    Args:
        workout_id: UUID of the active workout.
        exercise_name: Name of the exercise to add the set to (as it appears in
            the workout, e.g. "Leg Press").
        is_drop_set: True to mark the new set as a drop set (lighter, no rest).

    Returns:
        Strict tool envelope. action_data.action = "add_set" with
        ``is_drop_set`` carried through so the frontend confirm-card and the
        ``/add-set`` endpoint render/apply it correctly.
    """
    action = "add_set"
    if not _is_uuid(workout_id):
        return _fail(action, f"Invalid workout id: {workout_id}.")

    workout = _load_workout(workout_id)
    if not workout:
        return _fail(action, f"Workout {workout_id} not found.")

    exercises = _exercises_list(workout)
    target = next(
        (e for e in exercises if e.get("name", "").lower() == exercise_name.lower()),
        None,
    )
    if not target:
        return _fail(
            action,
            f"'{exercise_name}' isn't in this workout right now.",
            {"workout_id": workout_id},
        )

    kind = "drop set" if is_drop_set else "set"
    summary = f"Add a {kind} to {target.get('name')}"

    return _ok(
        action,
        summary,
        {
            "workout_id": workout_id,
            "exercise_id": _ensure_exercise_id(target),
            "exercise_name": target.get("name"),
            "is_drop_set": is_drop_set,
        },
        requires_confirmation=True,
    )


# Public registry — appended to ALL_TOOLS via tools/__init__.py
ISSUE_3_MUTATION_TOOLS = [
    swap_single_exercise,
    log_set,
    create_superset,
    break_superset,
    reorder_exercises,
    add_set,
]
