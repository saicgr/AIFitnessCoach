"""
Shared exercise data and categorizations.

This module contains all exercise-related constants used across services.
"""
from typing import Dict, List, Tuple

# Exercise categorization for progression
COMPOUND_LOWER = ["squat", "deadlift", "leg press", "romanian deadlift", "hip thrust"]
COMPOUND_UPPER = ["bench press", "overhead press", "row", "pull-up", "chin-up", "dip"]

# =====================================================
# EQUIPMENT-AWARE WEIGHT INCREMENTS (Industry Standard)
# =====================================================
# These represent the minimum practical weight increment for each equipment type
# in a standard gym environment. Used for realistic weight recommendations.

EQUIPMENT_INCREMENTS: Dict[str, float] = {
    "dumbbell": 2.5,      # kg (5 lb) - Standard dumbbell jumps in most gyms
    "dumbbells": 2.5,     # kg (5 lb) - Alias for dumbbell
    "barbell": 2.5,       # kg (5 lb) - Smallest common plates (1.25kg each side)
    "machine": 5.0,       # kg (10 lb) - Pin-select machine increments
    "cable": 2.5,         # kg (5 lb) - Cable stack increments
    "kettlebell": 4.0,    # kg (8 lb) - Standard KB progression (4,8,12,16,20...)
    "bodyweight": 0,      # No external weight
    "smith_machine": 2.5, # kg - Same as barbell
    "smith machine": 2.5, # kg - Alias with space
    "ez_bar": 2.5,        # kg - Same as barbell
    "ez bar": 2.5,        # kg - Alias with space
    "resistance_band": 0, # Variable resistance, no fixed increment
    "resistance band": 0, # Alias with space
}

# Standard dumbbell weights available in most commercial gyms (kg)
# These are the actual weights you'll find on a dumbbell rack
STANDARD_DUMBBELL_WEIGHTS: List[float] = [
    2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20, 22.5, 25,
    27.5, 30, 32.5, 35, 37.5, 40, 42.5, 45, 47.5, 50
]

# Standard kettlebell weights (kg) - follows traditional 4kg progression
STANDARD_KETTLEBELL_WEIGHTS: List[float] = [
    4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48
]

# Standard barbell plate combinations - common weights you can load (kg per side)
# Note: Barbell increments are 2.5kg minimum (1.25kg each side)
STANDARD_BARBELL_PLATES: List[float] = [
    1.25, 2.5, 5, 10, 15, 20, 25  # Individual plate weights
]

# =====================================================
# LEGACY: Weight increment based on exercise type (in kg)
# DEPRECATED: Use EQUIPMENT_INCREMENTS instead for realistic weights
# =====================================================
PROGRESSION_INCREMENTS: Dict[str, float] = {
    "compound_upper": 2.5,
    "compound_lower": 5.0,
    "isolation": 2.5,  # Changed from 1.25 to 2.5 (realistic for dumbbells)
    "bodyweight": 0,
}

# =====================================================
# REP LIMITS BY EXERCISE TYPE
# =====================================================
# Sensible rep ranges to prevent rep creep (e.g., doing 20+ reps)
# When reps hit the ceiling, weight should increase and reps reset.
# Format: (min_reps, max_reps)

REP_LIMITS: Dict[str, Tuple[int, int]] = {
    "compound_upper": (6, 12),   # Bench press, rows, overhead press - heavy focus
    "compound_lower": (6, 12),   # Squats, deadlifts, leg press - heavy focus
    "isolation": (8, 15),        # Curls, extensions, raises - higher rep range
    "bodyweight": (5, 20),       # Push-ups, pull-ups, dips - wider range acceptable
}


def get_rep_limits(exercise_type: str) -> Tuple[int, int]:
    """Get min/max rep limits for an exercise type."""
    return REP_LIMITS.get(exercise_type, (8, 15))

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
