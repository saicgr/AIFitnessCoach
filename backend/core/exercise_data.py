"""
Shared exercise data and categorizations.

This module contains all exercise-related constants used across services.
"""
from typing import Dict, List, Tuple

# Exercise categorization for progression
# Verified against 2,078 exercises in exercise_library_lookup.json
# Uses specific press variants to avoid false-positives (pressdown, Tate press, Svend press)
COMPOUND_LOWER = [
    # Squat variants (155 exercises)
    "squat", "pistol",
    # Deadlift variants (40 exercises)
    "deadlift", "rack pull",
    # Hip hinge (44 exercises)
    "hip thrust", "glute bridge", "good morning",
    # Lunge variants (81 exercises)
    "lunge", "split squat", "step-up", "step up",
    # Machine compounds
    "leg press", "hack squat",
    # Olympic lifts (hip-driven compound movements)
    "clean", "snatch", "jerk", "thruster",
]
COMPOUND_UPPER = [
    # Bench/chest press variants (specific to avoid matching "pressdown")
    "bench press", "chest press", "floor press", "spoto press",
    "incline press", "decline press", "hammer press", "squeeze press",
    "close grip press", "neutral grip press",
    # Catch word-order variants: "Press Flat", "Press Incline", "Press Decline"
    "press flat", "press incline", "press decline",
    # Shoulder press variants (including plural "shoulders press" found in library)
    "overhead press", "shoulder press", "shoulders press", "military press",
    "push press", "arnold press", "z press", "strict press",
    "seesaw press", "behind neck press",
    # Generic single-arm/alternate press (compound movements, not isolation)
    "one arm press", "alternate press", "single arm press",
    "palms in press", "palms back press", "palms-back press",
    "side press",
    # Machine/smith/cable press variants
    "smith machine press", "machine press", "landmine press",
    "cable resistance band press", "bench seated press", "press under",
    # Row variants (100+ exercises)
    "row",
    # Pull variants
    "pull-up", "pull up", "pullup", "chin-up", "chin up", "chinup",
    "pulldown", "pull-down", "pull down", "muscle-up", "muscle up",
    # Push variants
    "push-up", "push up", "pushup",
    # Dip variants (19 exercises)
    "dip",
    # Other compound upper
    "farmer",
]

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
    "medicine_ball": 2.0, # kg (4-5 lb) - Standard medicine ball jumps
    "medicine ball": 2.0, # kg - Alias with space
    "slam_ball": 2.0,     # kg (4-5 lb) - Standard slam ball jumps
    "slam ball": 2.0,     # kg - Alias with space
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

    bodyweight = ["plank", "crunch", "sit-up", "situp", "burpee",
                  "bear crawl", "box jump", "jumping jack", "mountain climber",
                  "flutter kick", "leg raise", "dead bug", "bird dog"]
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
