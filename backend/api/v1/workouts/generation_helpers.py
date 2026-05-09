"""
Shared helper functions for workout generation endpoints.

These are generation-specific utilities that don't belong in the general utils
module. They handle Gemini response parsing, MET estimation, and exercise
normalization.
"""
import json
import asyncio
from typing import List, Dict, Any

from fastapi import HTTPException

from core.logger import get_logger
from services.exercise_rag.filters import BODYWEIGHT_TOKENS

logger = get_logger(__name__)


# Strength-style focuses that require physical resistance — barbell/dumbbell/
# bands/cables/machines/bodyweight — not cardio machines. If the user's
# entire equipment list resolves to category=cardio_equipment AND focus is
# strength-style, the candidate pool will be 0 and we should reject upfront
# with a clear, actionable error rather than fail later at the pool gate.
_STRENGTH_FOCUSES = frozenset({
    "strength", "hypertrophy", "powerlifting",
    "full_body", "full_body_push", "full_body_pull", "full_body_legs",
    "full_body_core", "full_body_upper", "full_body_lower",
    "full_body_power",
    "upper", "lower", "push", "pull", "legs",
    "upper_power", "lower_power", "upper_hypertrophy", "lower_hypertrophy",
    "chest_back", "shoulders_arms",
    "chest", "back", "shoulders", "arms", "core", "glutes",
})


def check_equipment_focus_compatibility(
    focus_area: str,
    equipment: List[str],
) -> None:
    """Reject cardio-only + strength-focus combos with a clean 422.

    Without this gate, the request flows to the RAG and trips the pool gate
    with a generic "Only N exercises selected" message. The cardio-only user
    benefits from a directed message: switch focus or add equipment.

    The check fails open: if the resolver isn't loaded or any equipment item
    is unknown/non-cardio/bodyweight-token, we let the request proceed.
    """
    if not equipment:
        return  # bw-only path; never trigger
    if focus_area not in _STRENGTH_FOCUSES:
        return  # cardio/endurance/mobility/flexibility focuses: cardio gear is fine

    eq_norm = [(e or "").strip().lower() for e in equipment]
    if any(e in BODYWEIGHT_TOKENS for e in eq_norm):
        return  # explicit bodyweight token in user list → strength is doable

    try:
        from services.equipment_resolver import EquipmentResolver
        resolver = EquipmentResolver._instance
        if not resolver or not resolver._loaded:
            return  # resolver not ready → fail open
        categories = set()
        for eq in equipment:
            cat = resolver.get_category(eq)
            if cat is None:
                return  # unknown equipment → fail open (don't over-reject)
            categories.add(cat)
        if categories and categories <= {"cardio_equipment"}:
            raise HTTPException(
                status_code=422,
                detail={
                    "code": "INCOMPATIBLE_EQUIPMENT_FOCUS",
                    "message": (
                        "Your equipment is cardio-only — strength focus needs "
                        "weights, bands, or bodyweight space. Switch focus to "
                        "'cardio' / 'endurance' / 'hiit' or add strength "
                        "equipment to your gym profile."
                    ),
                    "focus_area": focus_area,
                    "equipment_categories": sorted(categories),
                },
            )
    except HTTPException:
        raise
    except Exception as e:
        # Any resolver hiccup → fail open. The pool gate will still catch
        # genuinely-empty cases.
        logger.warning(f"check_equipment_focus_compatibility skipped due to: {e}", exc_info=True)


def _estimate_workout_met(exercises: list, workout_type: str = None, difficulty: str = None) -> float:
    """Estimate MET (Metabolic Equivalent of Task) from exercise composition."""
    met = 3.5
    if not exercises:
        return met

    compound_muscles = {
        'legs', 'back', 'chest', 'full_body', 'glutes',
        'quadriceps', 'hamstrings', 'shoulders',
    }
    compound_count = 0
    total_sets = 0
    total_reps = 0
    total_weight_volume = 0.0
    superset_groups = set()
    drop_set_exercises = 0
    rest_values = []

    for ex in exercises:
        sets = ex.get('sets') or 3
        reps = ex.get('reps') or 10
        weight = ex.get('weight') or 0

        total_sets += sets
        total_reps += sets * reps
        total_weight_volume += sets * reps * weight

        rest_sec = ex.get('rest_seconds')
        if rest_sec:
            rest_values.append(rest_sec)

        muscle = (ex.get('muscle_group', '') or ex.get('primary_muscle', '') or '').lower()
        if muscle in compound_muscles:
            compound_count += 1

        sg = ex.get('superset_group')
        if sg is not None:
            superset_groups.add(sg)

        if ex.get('is_drop_set'):
            drop_set_exercises += 1

    avg_rest = sum(rest_values) / len(rest_values) if rest_values else 60

    if len(exercises) >= 6:
        met += 0.3
    if len(exercises) >= 9:
        met += 0.2

    if compound_count >= 3:
        met += 0.5
    if compound_count >= 5:
        met += 0.3

    if total_sets >= 15:
        met += 0.3
    if total_sets >= 25:
        met += 0.3

    avg_reps = total_reps / len(exercises) if exercises else 10
    if avg_reps >= 12:
        met += 0.3
    if avg_reps >= 15:
        met += 0.2

    if total_weight_volume > 5000:
        met += 0.3
    if total_weight_volume > 15000:
        met += 0.3

    if avg_rest < 60:
        met += 0.5
    if avg_rest < 30:
        met += 0.3

    if superset_groups:
        met += 0.3 + min(len(superset_groups) * 0.1, 0.5)

    if drop_set_exercises > 0:
        met += 0.2 + min(drop_set_exercises * 0.1, 0.4)

    if workout_type:
        wt = workout_type.lower()
        if 'hiit' in wt or 'circuit' in wt:
            met += 1.5
        elif 'cardio' in wt:
            met += 1.0

    if difficulty:
        d = difficulty.lower()
        if d in ('hell', 'extreme', 'insane'):
            met += 2.0
        elif d in ('hard', 'advanced', 'challenging'):
            met += 1.2
        elif d in ('moderate', 'intermediate'):
            met += 0.5

    return min(met, 10.0)


def ensure_parsed_dict(value) -> Dict[str, Any]:
    """Ensure a value is a dict, parsing it from JSON string if needed."""
    if isinstance(value, dict):
        return value
    if isinstance(value, str):
        try:
            parsed = json.loads(value)
            if isinstance(parsed, dict):
                return parsed
        except (json.JSONDecodeError, ValueError) as e:
            logger.debug(f"Failed to parse dict from string: {e}")
    return {}


def ensure_exercises_are_dicts(exercises) -> List[Dict[str, Any]]:
    """Ensure all exercises and their set_targets are proper dicts."""
    if not exercises:
        return []

    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, ValueError):
            logger.error(f"Failed to parse exercises string: {exercises[:200]}", exc_info=True)
            return []

    if not isinstance(exercises, list):
        return []

    normalized = []
    for ex in exercises:
        if isinstance(ex, str):
            try:
                ex = json.loads(ex)
            except (json.JSONDecodeError, ValueError):
                logger.warning(f"Skipping unparseable exercise string: {ex[:100]}", exc_info=True)
                continue
        if not isinstance(ex, dict):
            continue

        if 'set_targets' in ex and ex['set_targets']:
            if isinstance(ex['set_targets'], str):
                try:
                    ex['set_targets'] = json.loads(ex['set_targets'])
                except (json.JSONDecodeError, ValueError):
                    ex['set_targets'] = []

            if isinstance(ex['set_targets'], list):
                parsed_targets = []
                for st in ex['set_targets']:
                    if isinstance(st, str):
                        try:
                            st = json.loads(st)
                        except (json.JSONDecodeError, ValueError):
                            continue
                    if isinstance(st, dict):
                        parsed_targets.append(st)
                ex['set_targets'] = parsed_targets

        normalized.append(ex)

    return normalized


def normalize_exercise_numeric_fields(exercises: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Convert float values to integers for exercise fields."""
    exercises = ensure_exercises_are_dicts(exercises)

    for exercise in exercises:
        for field in ['sets', 'reps', 'rest_seconds', 'duration_seconds', 'hold_seconds',
                      'superset_group', 'superset_order', 'drop_set_count', 'drop_set_percentage',
                      'difficulty_num']:
            if field in exercise and exercise[field] is not None:
                try:
                    exercise[field] = int(exercise[field])
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to convert {field} to int: {e}")

        if 'set_targets' in exercise and exercise['set_targets']:
            for target in exercise['set_targets']:
                if not isinstance(target, dict):
                    continue
                for field in ['set_number', 'target_reps', 'target_rpe', 'target_rir']:
                    if field in target and target[field] is not None:
                        try:
                            target[field] = int(target[field])
                        except (ValueError, TypeError) as e:
                            logger.debug(f"Failed to convert target {field} to int: {e}")

            # Schema clarification fix (validation harness 2026-05-08): the `sets`
            # field was inconsistent — sometimes counted total (warmup + working),
            # sometimes only working. Pin the contract: `sets` = WORKING SET
            # COUNT (excludes warmup). Downstream consumers (UI rep counters,
            # set tracking, analytics) all expect this. Also expose
            # `total_sets_count` for callers that need warmup-inclusive count.
            st = exercise['set_targets']
            working_types = {"working", "drop", "failure", "amrap"}
            working_count = sum(
                1 for t in st
                if isinstance(t, dict) and t.get("set_type", "working") in working_types
            )
            total_count = sum(1 for t in st if isinstance(t, dict))
            if working_count >= 1:
                exercise['sets'] = working_count
                exercise['total_sets_count'] = total_count

    return exercises
