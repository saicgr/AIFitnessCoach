"""
Core utilities and shared data.

Import from here for clean access to shared constants and functions.
"""
from core.exercise_data import (
    COMPOUND_LOWER,
    COMPOUND_UPPER,
    PROGRESSION_INCREMENTS,
    EQUIPMENT_INCREMENTS,
    STANDARD_DUMBBELL_WEIGHTS,
    STANDARD_KETTLEBELL_WEIGHTS,
    STANDARD_BARBELL_PLATES,
    EXERCISE_SUBSTITUTES,
    EXERCISE_TIME_ESTIMATES,
    get_exercise_type,
    get_exercise_priority,
)
from core.muscle_groups import (
    WEEKLY_SET_TARGETS,
    MUSCLE_TO_EXERCISES,
    EXERCISE_TO_MUSCLES,
    get_muscle_groups,
    get_target_sets,
    get_recovery_status,
)
from core.injury_mappings import (
    INJURY_CONTRAINDICATIONS,
    SUBSTITUTE_CONTRAINDICATIONS,
    is_exercise_contraindicated,
    find_safe_substitute,
)
from core.weight_utils import (
    get_equipment_increment,
    round_to_equipment_increment,
    snap_to_available_weights,
    get_next_weight,
    detect_equipment_type,
    get_starting_weight,
    validate_weight_recommendation,
)

__all__ = [
    # Exercise data
    "COMPOUND_LOWER",
    "COMPOUND_UPPER",
    "PROGRESSION_INCREMENTS",
    "EQUIPMENT_INCREMENTS",
    "STANDARD_DUMBBELL_WEIGHTS",
    "STANDARD_KETTLEBELL_WEIGHTS",
    "STANDARD_BARBELL_PLATES",
    "EXERCISE_SUBSTITUTES",
    "EXERCISE_TIME_ESTIMATES",
    "get_exercise_type",
    "get_exercise_priority",
    # Weight utilities
    "get_equipment_increment",
    "round_to_equipment_increment",
    "snap_to_available_weights",
    "get_next_weight",
    "detect_equipment_type",
    "get_starting_weight",
    "validate_weight_recommendation",
    # Muscle groups
    "WEEKLY_SET_TARGETS",
    "MUSCLE_TO_EXERCISES",
    "EXERCISE_TO_MUSCLES",
    "get_muscle_groups",
    "get_target_sets",
    "get_recovery_status",
    # Injuries
    "INJURY_CONTRAINDICATIONS",
    "SUBSTITUTE_CONTRAINDICATIONS",
    "is_exercise_contraindicated",
    "find_safe_substitute",
]
