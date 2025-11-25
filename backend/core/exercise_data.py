"""
Shared exercise data and categorizations.

This module contains all exercise-related constants used across services.
"""
from typing import Dict, List, Tuple

# Exercise categorization for progression
COMPOUND_LOWER = ["squat", "deadlift", "leg press", "romanian deadlift", "hip thrust"]
COMPOUND_UPPER = ["bench press", "overhead press", "row", "pull-up", "chin-up", "dip"]

# Weight increment based on exercise type (in kg)
PROGRESSION_INCREMENTS: Dict[str, float] = {
    "compound_upper": 2.5,
    "compound_lower": 5.0,
    "isolation": 1.25,
    "bodyweight": 0,
}

# Exercise substitutes for adaptation
EXERCISE_SUBSTITUTES: Dict[str, List[str]] = {
    # Chest
    "bench press": ["dumbbell press", "push-ups", "machine chest press"],
    "dumbbell press": ["bench press", "push-ups", "cable fly"],
    "push-ups": ["bench press", "dumbbell press", "incline push-ups"],
    # Back
    "barbell row": ["dumbbell row", "cable row", "t-bar row"],
    "pull-ups": ["lat pulldown", "assisted pull-ups", "cable pulldown"],
    "lat pulldown": ["pull-ups", "cable pulldown", "machine pulldown"],
    # Shoulders
    "overhead press": ["dumbbell shoulder press", "arnold press", "machine press"],
    "lateral raise": ["cable lateral raise", "machine lateral raise"],
    # Legs
    "squat": ["leg press", "goblet squat", "hack squat"],
    "leg press": ["squat", "hack squat", "leg extension"],
    "deadlift": ["romanian deadlift", "hip thrust", "good morning"],
    # Arms
    "barbell curl": ["dumbbell curl", "cable curl", "hammer curl"],
    "tricep pushdown": ["skull crushers", "tricep dips", "overhead extension"],
}

# Average time per exercise type (minutes)
EXERCISE_TIME_ESTIMATES: Dict[str, int] = {
    "compound": 8,
    "isolation": 5,
    "bodyweight": 4,
}


def get_exercise_type(exercise_name: str) -> str:
    """Categorize exercise for progression increment."""
    name_lower = exercise_name.lower()

    for compound in COMPOUND_LOWER:
        if compound in name_lower:
            return "compound_lower"

    for compound in COMPOUND_UPPER:
        if compound in name_lower:
            return "compound_upper"

    bodyweight = ["push-up", "pull-up", "dip", "plank", "crunch"]
    for indicator in bodyweight:
        if indicator in name_lower:
            return "bodyweight"

    return "isolation"


def get_exercise_priority(exercise_name: str) -> int:
    """Get priority score (higher = more important to keep in workout)."""
    name = exercise_name.lower()

    compounds = ["squat", "deadlift", "bench", "row", "press", "pull-up"]
    for c in compounds:
        if c in name:
            return 100

    secondary = ["lunge", "dip", "chin-up", "hip thrust"]
    for s in secondary:
        if s in name:
            return 75

    return 50
