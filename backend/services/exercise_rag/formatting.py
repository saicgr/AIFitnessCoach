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

from .utils import clean_exercise_name_for_display, infer_equipment_from_name
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
    exercise_name = exercise.get("name", "Unknown")

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

    # Generate set_targets
    set_targets = _build_set_targets(
        sets=sets, reps=reps, starting_weight=starting_weight,
        exercise_type=exercise_type, equipment_type=equipment_type,
        equipment=equipment, exercise_name=exercise_name,
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
        "notes": exercise.get("instructions", "Focus on proper form"),
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
) -> List[Dict]:
    """Build the set_targets array with warmup + working sets."""
    set_targets = []
    is_bodyweight = equipment_type == "bodyweight" or equipment.lower() in ["bodyweight", "body weight", "none", ""]
    is_compound = exercise_type in ["compound_upper", "compound_lower"]

    def _get_working_set_rir(set_number: int, total_sets: int, is_compound_ex: bool) -> int:
        """Universal RIR progression: 2 -> 1 -> 0-1."""
        if set_number == 1:
            return 2
        elif set_number == 2:
            return 1
        else:
            return 1 if is_compound_ex else 0

    def _get_weight_for_rir(base_weight: float, target_rir: int, eq_type: str) -> float:
        """Calculate weight based on RIR target."""
        if base_weight <= 0:
            return 0
        rir_multipliers = {2: 1.00, 1: 1.05, 0: 1.10}
        multiplier = rir_multipliers.get(target_rir, 1.0)
        raw_weight = base_weight * multiplier

        increment = {
            "dumbbell": 2.5, "dumbbells": 2.5, "barbell": 2.5,
            "machine": 5.0, "cable": 2.5, "kettlebell": 4.0,
            "smith_machine": 2.5, "ez_bar": 2.5,
        }.get(eq_type.lower() if eq_type else "barbell", 2.5)

        return round(raw_weight / increment) * increment

    for set_num in range(1, sets + 1):
        # WARMUP SET: First set for compound exercises with weights
        if set_num == 1 and is_compound and not is_bodyweight and starting_weight > 0:
            set_targets.append({
                "set_number": set_num,
                "set_type": "warmup",
                "target_reps": min(reps + 2, 15),
                "target_weight_kg": round(starting_weight * 0.5, 1),
                "target_rpe": 5,
                "target_rir": 5,
            })
        else:
            adjusted_set_num = set_num - 1 if (is_compound and not is_bodyweight and starting_weight > 0) else set_num
            target_rir = _get_working_set_rir(adjusted_set_num, sets, is_compound)
            set_weight = _get_weight_for_rir(starting_weight, target_rir, equipment_type)
            target_rpe = 10 - target_rir

            if target_rir == 0:
                set_type = "failure"
            else:
                set_type = "working"

            set_targets.append({
                "set_number": set_num,
                "set_type": set_type,
                "target_reps": reps,
                "target_weight_kg": set_weight if not is_bodyweight else 0,
                "target_rpe": target_rpe,
                "target_rir": target_rir,
            })

    logger.debug(f"Generated {len(set_targets)} set_targets for {exercise_name}")
    return set_targets


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
