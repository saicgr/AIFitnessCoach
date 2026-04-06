"""
Weight Utilities - Equipment-aware weight rounding and recommendations.

This module provides utilities for:
1. Rounding weights to realistic gym increments based on equipment type
2. Snapping to available standard weights (dumbbells, kettlebells)
3. Detecting equipment type from exercise names
4. Getting appropriate starting weights based on fitness level

Industry Standard Weight Increments:
- Dumbbells: 2.5 kg (5 lb) minimum jumps
- Barbells: 2.5 kg (5 lb) - smallest common plates
- Machines: 5.0 kg (10 lb) - pin-select increments
- Kettlebells: 4.0 kg (8 lb) - standard KB progression
"""

from typing import List, Optional

from core.exercise_data import (
    EQUIPMENT_INCREMENTS,
    KG_TO_LBS_GYM,
    LBS_TO_KG_GYM,
    STANDARD_DUMBBELL_WEIGHTS,
    STANDARD_KETTLEBELL_WEIGHTS,
)

# =====================================================
# EQUIPMENT BASELINE WEIGHTS (Minimum Practical Starting Weight)
# =====================================================
# These represent the minimum weight possible for each equipment type.
# For example, a barbell alone weighs 20kg - you can't lift less than that.
EQUIPMENT_BASELINES = {
    "barbell": 20.0,       # Standard Olympic barbell = 20kg (45 lbs)
    "ez_bar": 10.0,        # EZ curl bar = ~10kg (22 lbs)
    "ez bar": 10.0,        # Alias
    "smith_machine": 10.0, # Smith bar is counterbalanced, starts ~10kg
    "smith machine": 10.0, # Alias
    "dumbbell": 2.5,       # Lightest dumbbell in most gyms = 2.5kg (5 lbs)
    "dumbbells": 2.5,      # Alias
    "kettlebell": 4.0,     # Lightest kettlebell = 4kg (8 lbs)
    "kettlebells": 4.0,    # Alias
    "cable": 5.0,          # Minimum cable stack = 5kg (10 lbs)
    "machine": 10.0,       # Minimum machine weight = 10kg (20 lbs)
    "bodyweight": 0.0,     # No external weight
    "resistance_band": 0.0, # Variable resistance
}


def get_equipment_increment(equipment_type: str) -> float:
    """
    Get the minimum weight increment for a given equipment type.

    Args:
        equipment_type: Equipment name (e.g., 'dumbbell', 'barbell', 'machine')

    Returns:
        Minimum increment in kg (default: 2.5 for unknown equipment)
    """
    if not equipment_type:
        return 2.5

    # Normalize equipment type
    eq_lower = equipment_type.lower().strip()

    # Direct lookup
    if eq_lower in EQUIPMENT_INCREMENTS:
        return EQUIPMENT_INCREMENTS[eq_lower]

    # Check for partial matches
    for key, increment in EQUIPMENT_INCREMENTS.items():
        if key in eq_lower or eq_lower in key:
            return increment

    # Default to 2.5 kg (most conservative)
    return 2.5


def round_to_equipment_increment(weight_kg: float, equipment_type: str) -> float:
    """
    Round weight to the nearest realistic gym increment for the equipment type.

    This ensures weights like 17.3 kg become 17.5 kg for dumbbells,
    or 20 kg for machines (which use 5 kg increments).

    Args:
        weight_kg: Weight in kilograms
        equipment_type: Equipment name (e.g., 'dumbbell', 'barbell', 'machine')

    Returns:
        Weight rounded to nearest valid increment
    """
    increment = get_equipment_increment(equipment_type)

    if increment == 0:
        return 0.0

    # Round to nearest increment
    rounded = round(weight_kg / increment) * increment

    # Ensure minimum weight (avoid 0 for weighted exercises)
    if rounded < increment and weight_kg > 0:
        return increment

    return round(rounded, 1)


def snap_to_available_weights(weight_kg: float, equipment_type: str) -> float:
    """
    Snap weight to the nearest available standard weight for the equipment type.

    For dumbbells and kettlebells, this finds the closest weight that actually
    exists on a standard gym rack. For other equipment, it rounds to increment.

    Args:
        weight_kg: Desired weight in kilograms
        equipment_type: Equipment name

    Returns:
        Nearest available standard weight in kg
    """
    if not equipment_type:
        return round_to_equipment_increment(weight_kg, "dumbbell")

    eq_lower = equipment_type.lower().strip()

    # Snap to standard dumbbell weights
    if "dumbbell" in eq_lower or "db" in eq_lower:
        if weight_kg <= 0:
            return STANDARD_DUMBBELL_WEIGHTS[0]  # 2.5 kg
        return min(STANDARD_DUMBBELL_WEIGHTS, key=lambda x: abs(x - weight_kg))

    # Snap to standard kettlebell weights
    if "kettlebell" in eq_lower or "kb" in eq_lower:
        if weight_kg <= 0:
            return STANDARD_KETTLEBELL_WEIGHTS[0]  # 4 kg
        return min(STANDARD_KETTLEBELL_WEIGHTS, key=lambda x: abs(x - weight_kg))

    # For other equipment, just round to increment
    return round_to_equipment_increment(weight_kg, equipment_type)


def get_next_weight(current_weight: float, equipment_type: str) -> float:
    """
    Get the next progressive weight based on equipment constraints.

    This is used for progression recommendations - adding one increment
    to the current weight based on equipment type.

    Args:
        current_weight: Current weight in kg
        equipment_type: Equipment name

    Returns:
        Next weight in kg (current + one increment)
    """
    increment = get_equipment_increment(equipment_type)
    next_weight = current_weight + increment

    # Snap to standard weights for dumbbells/kettlebells
    return snap_to_available_weights(next_weight, equipment_type)


def detect_equipment_type(
    exercise_name: str,
    equipment_list: Optional[List[str]] = None
) -> str:
    """
    Detect equipment type from exercise name or user's available equipment.

    Analyzes the exercise name for equipment keywords (e.g., 'Dumbbell Bench Press')
    and falls back to checking the user's equipment list.

    Args:
        exercise_name: Name of the exercise
        equipment_list: Optional list of user's available equipment

    Returns:
        Equipment type string (e.g., 'dumbbell', 'barbell', 'machine')
    """
    if not exercise_name:
        return "dumbbell"  # Default to most conservative

    name_lower = exercise_name.lower()

    # Check for specific equipment keywords in exercise name
    equipment_keywords = [
        ("dumbbell", "dumbbell"),
        ("db ", "dumbbell"),
        ("db-", "dumbbell"),
        (" db", "dumbbell"),
        ("barbell", "barbell"),
        ("bb ", "barbell"),
        ("bb-", "barbell"),
        (" bb", "barbell"),
        ("kettlebell", "kettlebell"),
        ("kb ", "kettlebell"),
        ("kb-", "kettlebell"),
        (" kb", "kettlebell"),
        ("cable", "cable"),
        ("machine", "machine"),
        ("smith", "smith_machine"),
        ("ez bar", "ez_bar"),
        ("ez-bar", "ez_bar"),
        ("trap bar", "trap_bar"),
        ("resistance band", "resistance_band"),
        ("band", "resistance_band"),
        ("trx", "trx"),
        ("suspension", "trx"),
        ("medicine ball", "medicine_ball"),
        ("med ball", "medicine_ball"),
        ("slam ball", "slam_ball"),
        ("battle rope", "battle_ropes"),
        ("pull-up bar", "pull_up_bar"),
        ("pull up bar", "pull_up_bar"),
        ("dip station", "dip_station"),
        ("gymnastic ring", "gymnastic_rings"),
        ("ring dip", "gymnastic_rings"),
        ("ring row", "gymnastic_rings"),
        ("foam roller", "foam_roller"),
        ("yoga mat", "yoga_mat"),
        ("ab wheel", "ab_wheel"),
        ("ab roller", "ab_wheel"),
        ("landmine", "landmine"),
        ("sandbag", "sandbag"),
        ("bosu", "bosu_ball"),
        ("exercise ball", "exercise_ball"),
        ("stability ball", "exercise_ball"),
    ]

    for keyword, equipment_type in equipment_keywords:
        if keyword in name_lower:
            return equipment_type

    # Check for machine-like exercises (often have 'press' without other qualifiers)
    machine_indicators = ["leg press", "chest press machine", "shoulder press machine",
                          "lat pulldown", "cable fly", "cable crossover", "cable row",
                          "pec deck", "seated row machine"]
    for indicator in machine_indicators:
        if indicator in name_lower:
            return "machine"

    # Check user's available equipment as fallback
    if equipment_list:
        eq_lower = [eq.lower() for eq in equipment_list]

        if "dumbbells" in eq_lower or "dumbbell" in eq_lower:
            return "dumbbell"
        elif "barbell" in eq_lower:
            return "barbell"
        elif "kettlebells" in eq_lower or "kettlebell" in eq_lower:
            return "kettlebell"

    # Default to dumbbell (most conservative - 2.5 kg increments)
    return "dumbbell"


def get_equipment_baseline(equipment_type: str) -> float:
    """
    Get the minimum practical starting weight for an equipment type.

    For example, a barbell weighs 20kg - you can't lift less than the bar.

    Args:
        equipment_type: Equipment name (e.g., 'barbell', 'dumbbell')

    Returns:
        Minimum weight in kg for this equipment type
    """
    if not equipment_type:
        return 0.0

    eq_lower = equipment_type.lower().strip()

    # Direct lookup
    if eq_lower in EQUIPMENT_BASELINES:
        return EQUIPMENT_BASELINES[eq_lower]

    # Partial match
    for key, baseline in EQUIPMENT_BASELINES.items():
        if key in eq_lower or eq_lower in key:
            return baseline

    return 0.0


def get_starting_weight(
    exercise_name: str,
    equipment_type: str,
    fitness_level: str
) -> float:
    """
    Get an appropriate starting weight based on exercise, equipment, and fitness level.

    This provides intelligent weight recommendations that consider:
    1. Equipment baseline (barbell = 20kg minimum, the bar itself)
    2. Fitness level (beginners start lighter)
    3. Exercise type (compound vs isolation)

    Args:
        exercise_name: Name of the exercise
        equipment_type: Equipment type (e.g., 'dumbbell', 'barbell')
        fitness_level: User's fitness level ('beginner', 'intermediate', 'advanced')

    Returns:
        Recommended starting weight in kg
    """
    if not exercise_name:
        exercise_name = ""

    name_lower = exercise_name.lower()
    eq_lower = (equipment_type or "").lower()

    # Determine if this is a compound or isolation exercise
    compound_indicators = [
        "squat", "deadlift", "bench", "press", "row", "pull-up", "chin-up",
        "lunge", "hip thrust", "clean", "snatch", "dip",
        "pulldown", "pull down", "lat pull", "cable row", "seated row",
        "leg curl", "leg extension", "chest fly", "face pull",
    ]
    is_compound = any(indicator in name_lower for indicator in compound_indicators)

    # Normalize fitness level
    level = (fitness_level or "beginner").lower()
    if level not in ["beginner", "intermediate", "advanced"]:
        level = "beginner"

    # Get equipment baseline (minimum possible weight)
    baseline = get_equipment_baseline(equipment_type)

    # =====================================================
    # BARBELL: Special handling - add plates on top of bar
    # =====================================================
    if "barbell" in eq_lower:
        # Barbell bar = 20kg, then add plates based on fitness level
        if is_compound:
            # Compound barbell exercises (squat, deadlift, bench, etc.)
            plate_additions = {
                "beginner": 0.0,    # Just the bar (20kg) - learn form
                "intermediate": 10.0,  # Bar + 5kg each side (30kg total)
                "advanced": 30.0,   # Bar + 15kg each side (50kg total)
            }
        else:
            # Isolation barbell exercises (curls, etc.)
            plate_additions = {
                "beginner": 0.0,    # Just the bar (20kg)
                "intermediate": 5.0,   # Bar + 2.5kg each side (25kg)
                "advanced": 10.0,   # Bar + 5kg each side (30kg)
            }
        return baseline + plate_additions.get(level, 0.0)

    # =====================================================
    # EZ BAR: Similar to barbell but lighter bar
    # =====================================================
    if "ez" in eq_lower and "bar" in eq_lower:
        # EZ bar = 10kg
        plate_additions = {
            "beginner": 0.0,    # Just the bar (10kg)
            "intermediate": 5.0,   # Bar + 2.5kg each side (15kg)
            "advanced": 10.0,   # Bar + 5kg each side (20kg)
        }
        return baseline + plate_additions.get(level, 0.0)

    # =====================================================
    # OTHER EQUIPMENT: Use base weights with adjustments
    # =====================================================
    base_weights = {
        "beginner": {
            "compound": 10.0,   # Light weight to focus on form
            "isolation": 7.5,   # Reasonable starting weight for isolation
        },
        "intermediate": {
            "compound": 20.0,   # Moderate weight
            "isolation": 10.0,  # Light-moderate for isolation
        },
        "advanced": {
            "compound": 40.0,   # Challenging weight
            "isolation": 15.0,  # Moderate for isolation
        },
    }

    exercise_type = "compound" if is_compound else "isolation"
    base_weight = base_weights[level][exercise_type]

    # Kettlebells typically start lighter
    if "kettlebell" in eq_lower:
        base_weight = base_weight * 0.6

    # Machines and cables often allow heavier starting weights
    if "machine" in eq_lower or "cable" in eq_lower:
        base_weight = base_weight * 1.5

    # Ensure we don't go below equipment baseline
    final_weight = max(base_weight, baseline)

    # Apply exercise-specific minimum weight floors
    exercise_min_weights = {
        "lat pulldown": 15.0,
        "pull down": 15.0,
        "pulldown": 15.0,
        "cable row": 15.0,
        "seated row": 15.0,
        "leg press": 40.0,
        "leg curl": 10.0,
        "leg extension": 10.0,
        "chest press": 10.0,
        "shoulder press": 10.0,
    }
    for key, min_w in exercise_min_weights.items():
        if key in name_lower:
            final_weight = max(final_weight, min_w)
            break

    # Snap to valid weight for the equipment
    return snap_to_available_weights(final_weight, equipment_type)


def kg_to_lbs_gym(weight_kg: float) -> float:
    """
    Convert kg to gym-standard lbs using a researched lookup dictionary.

    Unlike raw math (kg × 2.205), this returns the lbs value a gym-goer
    would recognize: 60 kg → 135 lbs (not 132.3), 100 kg → 225 lbs (not 220.5).

    For weights not in the lookup, finds the nearest entry and interpolates.
    """
    if weight_kg <= 0:
        return 0
    # Round to nearest 0.5 kg for lookup
    key = round(weight_kg * 2) / 2
    if key in KG_TO_LBS_GYM:
        return KG_TO_LBS_GYM[key]
    # Find nearest keys and use the closest match
    keys = sorted(KG_TO_LBS_GYM.keys())
    if key <= keys[0]:
        return KG_TO_LBS_GYM[keys[0]]
    if key >= keys[-1]:
        # Beyond the table — fall back to round-to-5
        return round(weight_kg * 2.20462 / 5) * 5
    # Binary search for nearest key
    import bisect
    idx = bisect.bisect_left(keys, key)
    lo, hi = keys[idx - 1], keys[idx]
    # Pick the closer one
    if abs(key - lo) <= abs(key - hi):
        return KG_TO_LBS_GYM[lo]
    return KG_TO_LBS_GYM[hi]


def lbs_to_kg_gym(weight_lbs: float) -> float:
    """
    Convert lbs to gym-standard kg using a researched lookup dictionary.

    Unlike raw math (lbs / 2.205), this returns the kg value that matches
    real gym equipment: 135 lbs → 60 kg, 225 lbs → 100 kg.

    For weights not in the lookup, finds the nearest entry.
    """
    if weight_lbs <= 0:
        return 0
    # Round to nearest integer for lookup
    key = round(weight_lbs)
    if key in LBS_TO_KG_GYM:
        return LBS_TO_KG_GYM[key]
    # Find nearest
    keys = sorted(LBS_TO_KG_GYM.keys())
    if key <= keys[0]:
        return LBS_TO_KG_GYM[keys[0]]
    if key >= keys[-1]:
        return round(weight_lbs / 2.20462 / 2.5) * 2.5
    import bisect
    idx = bisect.bisect_left(keys, key)
    lo, hi = keys[idx - 1], keys[idx]
    if abs(key - lo) <= abs(key - hi):
        return LBS_TO_KG_GYM[lo]
    return LBS_TO_KG_GYM[hi]


def validate_weight_recommendation(
    weight_kg: float,
    equipment_type: str
) -> tuple[float, bool]:
    """
    Validate a weight recommendation and correct if needed.

    Checks if the weight is realistic for the equipment type and
    snaps to the nearest valid weight if not.

    Args:
        weight_kg: Recommended weight in kg
        equipment_type: Equipment type

    Returns:
        Tuple of (corrected_weight, was_valid)
    """
    corrected = snap_to_available_weights(weight_kg, equipment_type)
    was_valid = abs(corrected - weight_kg) < 0.01  # Allow tiny floating point differences

    return corrected, was_valid
