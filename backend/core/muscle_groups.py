"""
Muscle group mappings and volume targets.

This module contains all muscle-related constants used across services.
"""
from typing import Dict, List, Tuple

# Target weekly sets per muscle group (research-based ranges)
WEEKLY_SET_TARGETS: Dict[str, Tuple[int, int]] = {
    "chest": (10, 20),
    "back": (10, 20),
    "shoulders": (8, 16),
    "biceps": (6, 14),
    "triceps": (6, 14),
    "quadriceps": (10, 20),
    "hamstrings": (8, 16),
    "glutes": (8, 16),
    "calves": (6, 12),
    "core": (6, 12),
}

# Muscle group to exercise mapping
MUSCLE_TO_EXERCISES: Dict[str, List[str]] = {
    "chest": ["bench press", "dumbbell press", "push-ups", "cable fly", "incline press"],
    "back": ["barbell row", "pull-ups", "lat pulldown", "cable row", "deadlift"],
    "shoulders": ["overhead press", "lateral raise", "face pulls", "reverse fly"],
    "biceps": ["barbell curl", "dumbbell curl", "hammer curl", "preacher curl"],
    "triceps": ["tricep pushdown", "skull crushers", "tricep dips", "close grip bench"],
    "quadriceps": ["squat", "leg press", "leg extension", "lunges", "hack squat"],
    "hamstrings": ["romanian deadlift", "leg curl", "good morning", "stiff leg deadlift"],
    "glutes": ["hip thrust", "glute bridge", "cable kickback", "squat"],
    "calves": ["calf raise", "seated calf raise", "donkey calf raise"],
    "core": ["plank", "crunches", "hanging leg raise", "cable woodchop"],
}

# Exercise to muscle groups mapping (simplified)
EXERCISE_TO_MUSCLES: Dict[str, List[str]] = {
    "bench": ["chest", "triceps", "shoulders"],
    "push-up": ["chest", "triceps", "shoulders"],
    "fly": ["chest", "triceps", "shoulders"],
    "row": ["back", "biceps"],
    "pull": ["back", "biceps"],
    "squat": ["quadriceps", "glutes"],
    "leg press": ["quadriceps", "glutes"],
    "deadlift": ["hamstrings", "glutes", "back"],
    "curl": ["biceps"],
    "tricep": ["triceps"],
    "pushdown": ["triceps"],
    "shoulder": ["shoulders"],
    "press": ["shoulders"],
    "calf": ["calves"],
    "crunch": ["core"],
    "plank": ["core"],
}


def get_muscle_groups(exercise_name: str) -> List[str]:
    """Get muscle groups worked by an exercise."""
    name_lower = exercise_name.lower()

    for pattern, muscles in EXERCISE_TO_MUSCLES.items():
        if pattern in name_lower:
            return muscles

    return ["unknown"]


def get_target_sets(muscle_group: str) -> int:
    """Get target weekly sets for a muscle group."""
    target_range = WEEKLY_SET_TARGETS.get(muscle_group, (8, 16))
    return (target_range[0] + target_range[1]) // 2


def get_recovery_status(muscle: str, actual_sets: int) -> str:
    """Determine recovery status based on volume."""
    target_range = WEEKLY_SET_TARGETS.get(muscle, (8, 16))

    if actual_sets > target_range[1] * 1.2:
        return "overtrained"
    elif actual_sets < target_range[0] * 0.8:
        return "undertrained"
    return "recovered"
