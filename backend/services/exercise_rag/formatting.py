"""
Exercise formatting utilities for workout inclusion.

Handles:
- Converting RAG exercise data into workout-ready format
- Equipment-aware weight recommendations
- Set target generation with RPE/RIR
- Unilateral exercise detection
- Challenge exercise selection
"""
from typing import Dict, List, Optional, Any

from core.logger import get_logger
from core.weight_utils import get_starting_weight, detect_equipment_type

from .utils import (
    canonicalize_exercise_name,
    clean_exercise_name_for_display,
    infer_equipment_from_name,
)
from .difficulty import (
    validate_fitness_level,
    get_difficulty_numeric,
    CHALLENGE_DIFFICULTY_RANGE,
)
from .filters import (
    parse_secondary_muscles,
    pre_filter_by_injuries,
)

logger = get_logger(__name__)


def detect_unilateral(exercise_name: str, metadata: dict = None) -> bool:
    """
    Detect if exercise is unilateral (single-arm/leg).

    Used to display "(each side)" in the UI so users know the weight is per side.
    """
    if not exercise_name:
        return False

    name_lower = exercise_name.lower()

    unilateral_keywords = [
        "single arm", "single-arm", "one arm", "one-arm",
        "single leg", "single-leg", "one leg", "one-leg",
        "alternate", "alternating", "unilateral",
        "split squat", "bulgarian split",
        "lunge", "step up", "step-up",
        "pistol squat", "pistol",
        "single dumbbell", "one dumbbell",
    ]

    if any(kw in name_lower for kw in unilateral_keywords):
        return True

    if metadata:
        if metadata.get("is_unilateral", False):
            return True
        if metadata.get("alternating_hands", False):
            return True

    return False


def format_exercise_for_workout(
    exercise: Dict,
    fitness_level: str,
    workout_params: Optional[Dict] = None,
    strength_history: Optional[Dict[str, Dict]] = None,
    progression_pace: str = "medium",
    goals: Optional[List[str]] = None,
) -> Dict:
    """
    Format an exercise for inclusion in a workout.

    Includes equipment-aware starting weight recommendations based on:
    - User's historical strength data (if available) - HIGHEST PRIORITY
    - Exercise type (compound vs isolation)
    - Equipment type (dumbbell, barbell, machine, etc.)
    - User's fitness level
    - Progression pace (affects rep ranges and volume)
    """
    validated_level = validate_fitness_level(fitness_level)
    raw_name = exercise.get("name", "Unknown")
    # Defense-in-depth: even after the DB cleanup migration, runtime
    # canonicalization re-applies the style guide so any cached / re-indexed
    # row that drifted gets normalized. Returns "" for blocklisted anatomy
    # posters — caller must handle skip.
    exercise_name = canonicalize_exercise_name(raw_name) or raw_name

    from core.exercise_data import get_exercise_type, REP_LIMITS

    exercise_type = get_exercise_type(exercise_name)
    min_reps, max_reps = REP_LIMITS.get(exercise_type, (8, 12))

    if workout_params:
        sets = workout_params.get("sets", 3)
        reps = workout_params.get("reps", 12)
        rest = workout_params.get("rest_seconds", 60)
    else:
        if exercise_type in ["compound_upper", "compound_lower"]:
            base_sets = {"beginner": 3, "intermediate": 4, "advanced": 5}
        else:
            base_sets = {"beginner": 3, "intermediate": 3, "advanced": 4}
        sets = base_sets.get(validated_level, 3)

        if validated_level == "beginner":
            reps = max_reps
        elif validated_level == "advanced":
            reps = min_reps
        else:
            reps = (min_reps + max_reps) // 2

        if exercise_type in ["compound_upper", "compound_lower"]:
            rest_map = {"beginner": 120, "intermediate": 90, "advanced": 60}
        else:
            rest_map = {"beginner": 90, "intermediate": 60, "advanced": 45}
        rest = rest_map.get(validated_level, 60)

    # Apply progression pace adjustments
    if progression_pace == "slow":
        reps = min(reps + 2, max_reps)
        rest = min(rest + 15, 150)
    elif progression_pace == "fast":
        reps = max(reps - 2, min_reps)
        rest = max(rest - 15, 30)
        sets = min(sets + 1, 6)

    raw_equipment = exercise.get("equipment", "")
    if not raw_equipment or raw_equipment.lower() in ["bodyweight", "body weight", "none", ""]:
        equipment = infer_equipment_from_name(exercise_name)
    else:
        equipment = raw_equipment

    # Name-vs-equipment override (Fix 11 / H8 from peppy-conjuring-valley.md).
    # Pre-fix audit found 8 cases where the name implied a clear implement
    # (e.g. "Barbell Squat") but the equipment field disagreed. The name is
    # the authoritative signal — override the equipment string.
    name_lower = exercise_name.lower()
    _EQUIPMENT_FROM_NAME = (
        ("barbell", "Barbell"),
        ("dumbbell", "Dumbbells"),
        ("kettlebell", "Kettlebell"),
        ("cable", "Cable Machine"),
        ("smith machine", "Smith Machine"),
        ("trap bar", "Trap Bar"),
        ("ez bar", "EZ Bar"),
        ("landmine", "Landmine"),
    )
    for kw, canonical in _EQUIPMENT_FROM_NAME:
        if kw in name_lower and kw not in equipment.lower():
            logger.debug(
                f"[NameVsEquip] '{exercise_name}' overriding equipment "
                f"{equipment!r} → {canonical!r} based on name keyword"
            )
            equipment = canonical
            break

    equipment_type = detect_equipment_type(exercise_name, [equipment] if equipment else None)

    starting_weight = 0.0
    weight_source = "generic"

    if equipment_type != "bodyweight" and equipment.lower() not in ["bodyweight", "body weight", "none", ""]:
        if strength_history:
            history = strength_history.get(exercise_name)
            if not history:
                for hist_name, hist_data in strength_history.items():
                    if hist_name.lower() == exercise_name.lower():
                        history = hist_data
                        break

            if history and history.get("last_weight_kg", 0) > 0:
                starting_weight = history["last_weight_kg"]
                weight_source = "historical"
                logger.info(f"Using historical weight for {exercise_name}: {starting_weight}kg")

        if starting_weight == 0.0:
            starting_weight = get_starting_weight(
                exercise_name=exercise_name,
                equipment_type=equipment_type,
                fitness_level=validated_level,
            )
            weight_source = "generic"

    # Goal-aware rep / rest overrides (Fix 7 / H4 from
    # peppy-conjuring-valley.md). Without these the engine emits 12-rep
    # working sets for strength goals (the audit found 9 strength workouts
    # with all reps > 10).
    primary_goal = (goals[0] if goals else "").strip().lower() if goals else ""
    if primary_goal == "strength":
        reps = max(3, min(reps, 6))           # 3-6 working reps
        rest = max(rest, 180)                 # ≥ 180s
    elif primary_goal == "power":
        reps = max(1, min(reps, 5))
        rest = max(rest, 180)
    elif primary_goal == "hypertrophy":
        reps = max(8, min(reps, 12))
        rest = max(60, min(rest, 150))
    elif primary_goal == "endurance":
        reps = max(reps, 15)
        rest = min(rest, 60)

    # Generate set_targets
    set_targets = _build_set_targets(
        sets=sets, reps=reps, starting_weight=starting_weight,
        exercise_type=exercise_type, equipment_type=equipment_type,
        equipment=equipment, exercise_name=exercise_name,
        goals=goals,
    )

    is_unilateral = detect_unilateral(exercise_name, exercise)
    is_timed = exercise.get("is_timed", False)
    hold_seconds = exercise.get("default_hold_seconds")

    if is_timed and hold_seconds:
        reps = 1

    return {
        "name": exercise_name,
        "sets": sets,
        "reps": reps,
        "rest_seconds": rest,
        "equipment": equipment,
        "equipment_type": equipment_type,
        "weight_kg": starting_weight,
        "weight_source": weight_source,
        "muscle_group": exercise.get("target_muscle", exercise.get("body_part", "")),
        "body_part": exercise.get("body_part", ""),
        # H9: notes are derived from `instructions`. The library has many
        # rows that share boilerplate first-step text (top note repeated 302×
        # in pre-fix audit). When `instructions` is a list, join lines; when
        # it starts with the boilerplate "1. " step-1 form and is short,
        # keep it but the workout-level dedup post-pass will swap repeats.
        "notes": (
            "\n".join(exercise.get("instructions", []))
            if isinstance(exercise.get("instructions"), list)
            else (exercise.get("instructions") or "Focus on proper form")
        ),
        "gif_url": exercise.get("gif_url", ""),
        "video_url": exercise.get("video_url", ""),
        "image_url": exercise.get("image_url", ""),
        "library_id": exercise.get("id", ""),
        "is_favorite": exercise.get("is_favorite", False),
        "is_staple": exercise.get("is_staple", False),
        "from_queue": exercise.get("from_queue", False),
        "is_unilateral": is_unilateral,
        "is_timed": is_timed,
        "hold_seconds": hold_seconds,
        "set_targets": set_targets,
    }


def _build_set_targets(
    sets: int, reps: int, starting_weight: float,
    exercise_type: str, equipment_type: str, equipment: str,
    exercise_name: str,
    goals: Optional[List[str]] = None,
) -> List[Dict]:
    """Build the set_targets array with warmup + working sets.

    Goal-aware RIR (Fix 7 / D2): rather than the universal mechanical
    2→1→0 ramp (which pushed every workout — including beginner isolation —
    to failure on the last set), the working-set RIR pattern now varies by
    primary goal:

      strength / power : 3, 2, 1            (last set RIR 1, never failure)
      hypertrophy      : 2, 1, 1            (no failure)
      endurance        : 3, 3, 2            (sub-maximal)
      mobility/recovery: skip RIR/RPE       (not a working-set construct)
      default          : 2, 1, 0            (legacy)
    """
    set_targets = []
    is_bodyweight = equipment_type == "bodyweight" or equipment.lower() in ["bodyweight", "body weight", "none", ""]
    is_compound = exercise_type in ["compound_upper", "compound_lower"]
    primary_goal = ""
    if goals:
        primary_goal = (goals[0] or "").strip().lower()
    is_mobility_or_recovery = primary_goal in {"mobility", "recovery"}

    # Goal → working-set RIR ramp. Index = working set ordinal (0-based).
    _RIR_RAMP_BY_GOAL: Dict[str, List[int]] = {
        "strength": [3, 2, 1, 1, 1],
        "power":    [3, 2, 1, 1, 1],
        "hypertrophy": [2, 1, 1, 1, 1],
        "muscle_gain": [2, 1, 1, 1, 1],
        "endurance": [3, 3, 2, 2, 2],
        "fat_loss":  [3, 2, 1, 1, 1],
    }
    _DEFAULT_RAMP = [2, 1, 0, 0, 0]
    rir_ramp = _RIR_RAMP_BY_GOAL.get(primary_goal, _DEFAULT_RAMP)

    def _get_working_set_rir(working_index: int) -> int:
        """working_index is 0-based for working-only sets (warmup excluded)."""
        if working_index >= len(rir_ramp):
            return rir_ramp[-1]
        return rir_ramp[working_index]

    def _get_weight_for_rir(base_weight: float, target_rir: int, eq_type: str) -> float:
        """Calculate weight based on RIR target.

        Lower RIR (closer to failure) → higher weight via multiplier.
        Guarantees at least +1 equipment increment when multiplier > 1.0.
        """
        if base_weight <= 0:
            return 0
        rir_multipliers = {2: 1.00, 1: 1.05, 0: 1.10}
        multiplier = rir_multipliers.get(target_rir, 1.0)
        raw_weight = base_weight * multiplier

        increment = {
            "dumbbell": 2.0, "dumbbells": 2.0, "barbell": 2.5,
            "machine": 5.0, "cable": 2.5, "kettlebell": 4.0,
            "smith_machine": 2.5, "ez_bar": 2.5,
        }.get(eq_type.lower() if eq_type else "barbell", 2.5)

        rounded = round(raw_weight / increment) * increment
        base_rounded = round(base_weight / increment) * increment
        # Minimum increment guarantee: if multiplier intended a weight increase
        # but rounding erased the difference, force at least +1 increment
        if multiplier > 1.0 and rounded <= base_rounded:
            rounded = base_rounded + increment
        return rounded

    # Mobility / recovery: emit straight sets with no RIR/RPE construct.
    if is_mobility_or_recovery:
        for set_num in range(1, sets + 1):
            set_targets.append({
                "set_number": set_num,
                "set_type": "working",
                "target_reps": reps,
                "target_weight_kg": 0,
                "target_rpe": None,
                "target_rir": None,
            })
        return set_targets

    # Always prepend a warmup for compound non-bw lifts with ≥3 working
    # sets. The pre-fix audit found 1499/2204 strength workouts had ZERO
    # warmup. Strength compounds must warmup before the first working set.
    add_warmup = (
        is_compound
        and not is_bodyweight
        and starting_weight > 0
        and sets >= 3
    )
    set_number = 1
    if add_warmup:
        set_targets.append({
            "set_number": set_number,
            "set_type": "warmup",
            "target_reps": min(reps + 2, 15),
            "target_weight_kg": round(starting_weight * 0.5, 1),
            "target_rpe": 5,
            "target_rir": 5,
        })
        set_number += 1
        working_count = sets  # `sets` is now interpreted as working-set count
    else:
        working_count = sets

    for working_index in range(working_count):
        target_rir = _get_working_set_rir(working_index)
        set_weight = _get_weight_for_rir(starting_weight, target_rir, equipment_type)
        target_rpe = max(1, min(10 - target_rir, 10))
        set_type = "failure" if target_rir == 0 else "working"
        set_targets.append({
            "set_number": set_number,
            "set_type": set_type,
            "target_reps": reps,
            "target_weight_kg": set_weight if not is_bodyweight else 0,
            "target_rpe": target_rpe,
            "target_rir": target_rir,
        })
        set_number += 1

    logger.debug(f"Generated {len(set_targets)} set_targets for {exercise_name}")
    return set_targets


def dedupe_workout_notes(exercises: List[Dict]) -> List[Dict]:
    """Replace duplicate `notes` strings within a workout.

    The library has boilerplate first-step instructions that repeat across
    many distinct exercises ("1. Begin by standing..."). Pre-fix audit found
    the top note string repeated 302× across the 462-workout sweep — within
    a single workout this looks like copy-paste laziness.

    Strategy: keep the first occurrence of each notes string; for repeats,
    swap in a templated, exercise-specific cue using `muscle_group`.
    """
    if not exercises:
        return exercises
    seen: Dict[str, int] = {}
    for ex in exercises:
        notes = (ex.get("notes") or "").strip()
        if not notes:
            continue
        # First sentence as the dedup key — boilerplate repeats are usually
        # in the opening sentence; later sentences may differ legitimately.
        first_sentence = notes.split(".", 1)[0][:80].lower()
        seen[first_sentence] = seen.get(first_sentence, 0) + 1

    rewritten = 0
    used: Dict[str, int] = {}
    for ex in exercises:
        notes = (ex.get("notes") or "").strip()
        if not notes:
            continue
        first_sentence = notes.split(".", 1)[0][:80].lower()
        if seen.get(first_sentence, 0) > 1:
            used[first_sentence] = used.get(first_sentence, 0) + 1
            if used[first_sentence] > 1:
                # Replace duplicate occurrences with a per-exercise cue.
                muscle = (ex.get("muscle_group") or ex.get("body_part") or "the target muscle").strip()
                ex["notes"] = (
                    f"Focus on the eccentric and full range of motion for "
                    f"{muscle.lower()}. Maintain neutral spine and steady breathing."
                )
                rewritten += 1
    if rewritten:
        logger.info(f"[NotesDedup] Rewrote {rewritten} duplicate notes within workout")
    return exercises


def is_progression_of(challenge_name: str, main_name: str) -> bool:
    """Check if the challenge exercise is a progression of a main exercise."""
    challenge_lower = challenge_name.lower()
    main_lower = main_name.lower()

    progression_patterns = [
        ("push-up", ["diamond push-up", "decline push-up", "archer push-up", "chest tap push-up", "pike push-up", "clap push-up"]),
        ("push up", ["diamond push up", "decline push up", "archer push up", "chest tap push up", "pike push up", "clap push up"]),
        ("pull-up", ["archer pull-up", "wide grip pull-up", "l-sit pull-up", "muscle-up"]),
        ("pull up", ["archer pull up", "wide grip pull up", "l-sit pull up", "muscle up"]),
        ("squat", ["jump squat", "pistol squat", "shrimp squat", "bulgarian split squat"]),
        ("goblet squat", ["front squat", "barbell squat"]),
        ("row", ["one-arm row", "archer row", "explosive row"]),
        ("plank", ["side plank", "plank to push-up", "commando plank"]),
        ("lunge", ["jump lunge", "walking lunge", "reverse lunge"]),
    ]

    for base_exercise, progressions in progression_patterns:
        if base_exercise in main_lower:
            if any(prog in challenge_lower for prog in progressions):
                return True

    main_words = set(main_lower.split())
    challenge_words = set(challenge_lower.split())
    common_words = main_words & challenge_words

    if len(common_words) >= 2 and challenge_words != main_words:
        return True

    return False
