"""
Core utilities and shared data.

Import from here for clean access to shared constants and functions.
"""
from core.exercise_data import (
    COMPOUND_LOWER,
    COMPOUND_UPPER,
    PROGRESSION_INCREMENTS,
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

__all__ = [
    # Exercise data
    "COMPOUND_LOWER",
    "COMPOUND_UPPER",
    "PROGRESSION_INCREMENTS",
    "EXERCISE_SUBSTITUTES",
    "EXERCISE_TIME_ESTIMATES",
    "get_exercise_type",
    "get_exercise_priority",
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
