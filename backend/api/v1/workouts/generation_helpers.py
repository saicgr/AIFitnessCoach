"""
Shared helper functions for workout generation endpoints.

These are generation-specific utilities that don't belong in the general utils
module. They handle Gemini response parsing, MET estimation, and exercise
normalization.
"""
import json
import asyncio
import re
from typing import List, Dict, Any, Optional

from fastapi import HTTPException

from core.logger import get_logger
from services.exercise_rag.filters import BODYWEIGHT_TOKENS

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Phase G — workout-type inference from free-text ai_prompt.
#
# The 2026-05-08 sweep found 7 cases where the user explicitly asked for a
# cardio / mobility / 5K / marathon session via `ai_prompt`, but the output
# was strength because /regenerate-stream never inferred type from the
# prompt — it inherited the source workout's type. This deterministic
# keyword classifier (no LLM, per `feedback_no_llm_for_safety_classification`)
# fixes that gap. Returns None when no signal is found, in which case the
# caller falls back to the source workout type.
# ---------------------------------------------------------------------------

_TYPE_KEYWORDS: List[tuple] = [
    # (workout_type, keyword_patterns) — first matching wins (order matters).
    # Mobility is declared BEFORE cardio so prompts that explicitly say
    # "mobility focus" don't get hijacked by an incidental "cycle" keyword
    # (sweep idx 305: "cycle day 1, cramps, mobility focus" → must be mobility).
    ("hiit", [
        r"\bhiit\b", r"\bcircuit\b", r"\bmetcon\b", r"\bamrap\b",
        r"\btabata\b", r"\bemom\b", r"\bcrossfit\b",
    ]),
    ("mobility", [
        r"\bmobility\b", r"\bstretch(ing)?\b", r"\bfoam\s*roll\b",
        r"\brecovery\b", r"\byoga\b", r"\bunwind\b",
        r"\bcooldown\b", r"\bcool\s*down\b",
    ]),
    ("cardio", [
        r"\bcardio\b", r"\b5\s*k\b", r"\b10\s*k\b", r"\bmarathon\b",
        r"\brun(ning)?\b", r"\bjog(ging)?\b",
        # `cycl(e|ing)` removed — collides with menstrual "cycle day". Use
        # explicit "biking"/"cycling workout" terms instead.
        r"\bcycling\s*(workout|session|ride)\b",
        r"\bbike\b", r"\brow(ing)?\b", r"\bsweat\b",
        r"\bzone\s*2\b", r"\bsteady\s*state\b",
    ]),
    ("strength", [
        # hypertrophy/strength explicit
        r"\bhypertrophy\b", r"\bpump\b", r"\bmuscle\s*mass\b", r"\bbodybuilding\b",
        r"\bstrength\b", r"\bheavy\b", r"\bone\s*rep\s*max\b", r"\bORM\b",
        r"\bharder\b",
        # power/explosive
        r"\bpower\b", r"\bexplosive\b", r"\bolympic\b", r"\bsnatch\b",
        r"\bclean\s*(and|&)\s*jerk\b", r"\bplyo(metric)?\b",
    ]),
]


def infer_workout_type_from_prompt(ai_prompt: Optional[str]) -> Optional[str]:
    """Return a workout type ('cardio'|'mobility'|'strength'|'hiit') inferred
    from free-text user prompt, or None if no signal is detected.

    Deterministic keyword scan — no LLM. Multi-language: only English
    keywords for v1 (the sweep showed Spanish/Japanese/Chinese/Russian/Hindi
    prompts already collapse to safety mode for unrelated reasons; once the
    safety_mode bug is fixed, those will inherit type from the source workout
    until we add localized keyword tables).
    """
    if not ai_prompt:
        return None
    text = ai_prompt.lower()
    for workout_type, patterns in _TYPE_KEYWORDS:
        for pat in patterns:
            if re.search(pat, text):
                return workout_type
    return None


def normalize_request_equipment(
    request_equipment: Optional[List[str]],
    profile_equipment: List[str],
) -> List[str]:
    """Phase G — distinguish request-level None (inherit profile) from
    request-level [] (explicit bodyweight-only).

    The pre-fix code used `if body.equipment is not None` which technically
    distinguishes the two, but downstream `if equipment:` checks treat the
    empty list as "no preference" and fall back to the unfiltered pool.
    Sweep idx 207: `equipment=[]` (BW) returned barbell + kettlebell exercises.

    Returns:
      - profile_equipment when request_equipment is None
      - ["bodyweight"] when request_equipment is explicitly []
      - request_equipment unchanged otherwise
    """
    if request_equipment is None:
        return profile_equipment or []
    if request_equipment == []:
        return ["bodyweight"]
    return request_equipment


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


def post_filter_equipment_violations(
    exercises: List[Dict[str, Any]],
    user_equipment: Optional[List[str]],
    goals: Optional[List[str]] = None,
) -> List[Dict[str, Any]]:
    """Drop exercises whose equipment isn't compatible with the user's set.

    Belt-and-suspenders for the RAG filter: validation harness 2026-05-09
    found Gemini hallucinated 4 kettlebell exercises into a workout where
    `equipment=['bench','dumbbells','resistance_bands']`, and 5 kettlebell
    exercises into a request with `equipment=[]` (bodyweight-only). The
    upstream RAG filter caught the candidates but Gemini still emitted these
    in its prose. We re-run the same `filter_by_equipment` predicate against
    each persisted exercise's `equipment` field as the last line of defense.

    `user_equipment=None` (i.e. caller didn't pass equipment at all) skips
    the filter — only an empty list `[]` triggers strict bodyweight gating.
    """
    if user_equipment is None or not exercises:
        return exercises
    from services.exercise_rag.filters import filter_by_equipment
    keep: List[Dict[str, Any]] = []
    dropped: List[str] = []
    for ex in exercises:
        ex_equipment = (ex.get("equipment") or "").strip()
        ex_name = ex.get("name", "") or ""
        # If exercise has no equipment field, infer from name as a best-effort
        # backstop (Gemini sometimes omits `equipment` while the name says
        # "Kettlebell …" or "Barbell …").
        if not ex_equipment:
            name_lc = ex_name.lower()
            for needle in ("kettlebell", "barbell", "dumbbell", "cable",
                           "machine", "smith", "trx", "medicine ball", "band"):
                if needle in name_lc:
                    ex_equipment = needle.replace(" ", "_")
                    break
        if filter_by_equipment(ex_equipment, user_equipment, ex_name, goals=goals):
            keep.append(ex)
        else:
            dropped.append(ex_name)
    if dropped:
        logger.warning(
            f"⚠️ [PostGenEquipment] Dropped {len(dropped)} equipment-incompatible "
            f"exercises (user_equipment={user_equipment}): {dropped[:5]}"
        )
    return keep


def post_filter_excluded_exercises(
    exercises: List[Dict[str, Any]],
    exclude_list: Optional[List[str]],
    adjacent_list: Optional[List[str]] = None,
) -> List[Dict[str, Any]]:
    """Drop exercises whose canonicalized name matches the exclude/adjacent set.

    Hardens the existing substring filter in /generate-stream. Validation
    harness 2026-05-09 idx 248 requested `exclude_exercises=['burpee',
    'jump squat','box jump']` and the workout still contained `Burpee`.
    Substring match is correct in principle ("burpee" ⊂ "Burpee".lower()) but
    fails on alias collapses; canonical comparison eliminates the alias gap.
    """
    forbidden_raw = list(exclude_list or []) + list(adjacent_list or [])
    if not forbidden_raw or not exercises:
        return exercises
    try:
        from services.exercise_rag.utils import canonicalize_exercise_name
    except Exception:
        canonicalize_exercise_name = lambda s: (s or "").strip().lower()  # type: ignore
    forbidden_canon = {canonicalize_exercise_name(s).lower() for s in forbidden_raw if s}
    forbidden_canon.discard("")
    forbidden_substr = {(s or "").lower().strip() for s in forbidden_raw if s}
    forbidden_substr.discard("")
    keep: List[Dict[str, Any]] = []
    dropped: List[str] = []
    for ex in exercises:
        name = ex.get("name", "") or ""
        canon = canonicalize_exercise_name(name).lower()
        name_lc = name.lower()
        if canon in forbidden_canon or any(f in name_lc for f in forbidden_substr):
            dropped.append(name)
            continue
        keep.append(ex)
    if dropped:
        logger.warning(
            f"⚠️ [PostGenExclude] Dropped {len(dropped)} excluded exercises: {dropped[:5]}"
        )
    return keep


def coerce_workout_type_from_focus(
    workout_type: Optional[str],
    focus_areas: Optional[List[str]],
    goals: Optional[List[str]] = None,
) -> Optional[str]:
    """Last-mile type coercion based on focus_areas → expected workout_type.

    Validation harness 2026-05-09 found 68 rows where focus∈{cardio, mobility,
    endurance, hiit} but workout_type persisted as `strength`. Existing
    overrides at line 700-711 only catch `mobility` and exact `cardio` —
    `endurance` and `hiit` focus values escape. This is the final coercion
    immediately before save.

    Returns the (possibly coerced) workout_type. Pass-through for any focus
    not in the table.
    """
    if not focus_areas:
        return workout_type
    primary = (focus_areas[0] or "").lower().strip()
    expected_table = {
        "cardio":     "cardio",
        "endurance":  "cardio",
        "hiit":       "cardio",
        "mobility":   "mobility",
        "stretching": "mobility",
        "stretch":    "mobility",
        "recovery":   "recovery",
    }
    expected = expected_table.get(primary)
    wt_lc = (workout_type or "").lower()
    # Only coerce if the existing type contradicts (don't downgrade hybrid/circuit).
    if expected and wt_lc in {"strength", "hypertrophy", "power"}:
        if expected != wt_lc:
            logger.info(
                f"🔧 [TypeCoerce] focus={primary!r} → type {workout_type!r} → {expected!r}"
            )
            return expected
    return workout_type


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
