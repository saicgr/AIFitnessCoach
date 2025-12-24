"""
Exercise filtering utilities for equipment, injuries, and similarity detection.
"""

import re
from typing import List, Dict, Any, Optional, Set

from core.logger import get_logger

logger = get_logger(__name__)


# Full gym equipment list
FULL_GYM_EQUIPMENT = [
    "barbell", "dumbbell", "dumbbells", "cable", "cable machine",
    "machine", "kettlebell", "bench", "ez bar", "smith machine",
    "lat pulldown", "leg press", "pull-up bar", "pullup bar",
    "resistance band", "medicine ball", "stability ball", "trx",
    "body weight", "bodyweight", "none"
]

# Home gym equipment list
HOME_GYM_EQUIPMENT = [
    "dumbbell", "dumbbells", "kettlebell", "resistance band",
    "pull-up bar", "pullup bar", "bench", "stability ball",
    "body weight", "bodyweight", "none"
]

# Injury contraindications mapping
INJURY_CONTRAINDICATIONS = {
    # Leg/Knee injuries
    "leg": ["squat", "lunge", "leg press", "leg extension", "leg curl", "step-up",
            "box jump", "jump squat", "burpee", "mountain climber", "deadlift",
            "romanian deadlift", "calf raise", "hack squat", "pistol squat",
            "leg drive", "split squat", "jump", "hop", "sprint"],
    "knee": ["squat", "lunge", "leg press", "leg extension", "leg curl", "step-up",
             "box jump", "jump squat", "burpee", "mountain climber", "deadlift",
             "pistol squat", "split squat", "jump", "hop"],

    # Back injuries
    "back": ["deadlift", "romanian deadlift", "good morning", "bent-over row",
             "squat", "leg press", "overhead press", "military press",
             "sit-up", "crunch", "superman", "hyperextension", "back extension"],
    "spine": ["deadlift", "romanian deadlift", "good morning", "squat",
              "overhead press", "sit-up", "crunch", "hyperextension"],
    "lower back": ["deadlift", "romanian deadlift", "good morning", "bent-over row",
                   "squat", "leg press", "sit-up", "crunch", "hyperextension",
                   "back extension", "superman"],

    # Shoulder injuries
    "shoulder": ["overhead press", "military press", "arnold press", "shoulder press",
                 "lateral raise", "upright row", "behind neck", "dip", "bench press",
                 "incline press", "fly", "pullover"],
    "rotator": ["overhead press", "lateral raise", "upright row", "behind neck",
                "dip", "fly", "pullover"],

    # Wrist/Hand injuries
    "wrist": ["push-up", "pushup", "plank", "handstand", "clean", "snatch",
              "front squat", "overhead squat", "bench press"],
    "hand": ["push-up", "pushup", "plank", "handstand", "clean", "deadlift"],

    # Hip injuries
    "hip": ["squat", "lunge", "hip thrust", "leg press", "deadlift", "step-up",
            "glute bridge", "romanian deadlift", "sumo deadlift"],

    # Neck injuries
    "neck": ["shrug", "upright row", "sit-up", "crunch", "neck curl",
             "neck extension", "behind neck press"],

    # Elbow/Arm injuries
    "elbow": ["curl", "tricep extension", "skull crusher", "close grip",
              "diamond push-up", "dip"],
    "arm": ["curl", "tricep extension", "skull crusher", "overhead extension"],

    # Ankle injuries
    "ankle": ["calf raise", "jump", "hop", "skip", "run", "sprint",
              "box jump", "jump squat", "burpee", "lunge"],
}


def get_base_exercise_name(name: str) -> str:
    """
    Extract the normalized base exercise name for deduplication.

    Removes version suffixes, gender variants, and normalizes the name.

    Examples:
        "Push-up (version 2)" -> "push up"
        "Squat variation 3" -> "squat"
        "Air Bike_female" -> "air bike"

    Args:
        name: The exercise name

    Returns:
        Normalized base name for comparison
    """
    # Lowercase for comparison
    name = name.lower()

    # Remove "_female" or "_Female" suffix
    name = re.sub(r'[_\s]female$', '', name, flags=re.IGNORECASE)

    # Remove "(version X)" suffix
    name = re.sub(r'\s*\(version\s*\d+\)\s*', '', name, flags=re.IGNORECASE)

    # Remove "version X" suffix without parentheses
    name = re.sub(r'\s+version\s*\d+\s*', '', name, flags=re.IGNORECASE)

    # Remove "variation X" suffix
    name = re.sub(r'\s*\(variation\s*\d+\)\s*', '', name, flags=re.IGNORECASE)
    name = re.sub(r'\s+variation\s*\d+\s*', '', name, flags=re.IGNORECASE)

    # Remove "v2", "v3" etc suffix
    name = re.sub(r'\s+v\d+\s*', '', name, flags=re.IGNORECASE)

    # Remove common filler words
    filler_words = ['with', 'and', 'the', 'a', 'an', 'on', 'in', 'to', 'for']
    words = name.split()
    words = [w for w in words if w not in filler_words]
    name = ' '.join(words)

    # Normalize hyphens, underscores and multiple spaces
    name = name.replace('-', ' ')
    name = name.replace('_', ' ')
    name = re.sub(r'\s+', ' ', name)

    return name.strip()


def is_similar_exercise(name1: str, name2: str) -> bool:
    """
    Check if two exercise names are similar enough to be considered duplicates.

    Uses word overlap to detect similar exercises like:
    - "Squat" and "Bodyweight Squat"
    - "Bicep Curl" and "Dumbbell Bicep Curl"

    Args:
        name1: First exercise name
        name2: Second exercise name

    Returns:
        True if exercises are similar
    """
    base1 = get_base_exercise_name(name1)
    base2 = get_base_exercise_name(name2)

    # Exact match after normalization
    if base1 == base2:
        return True

    # Check word overlap
    words1 = set(base1.split())
    words2 = set(base2.split())

    # If smaller set is fully contained in larger set
    if words1.issubset(words2) or words2.issubset(words1):
        return True

    # High overlap (80%+ of smaller set matches)
    smaller = words1 if len(words1) < len(words2) else words2
    larger = words2 if len(words1) < len(words2) else words1
    overlap = len(smaller & larger)
    if len(smaller) > 0 and overlap / len(smaller) >= 0.8:
        return True

    return False


def filter_by_equipment(
    ex_equipment: str,
    user_equipment: List[str],
    exercise_name: str,
) -> bool:
    """
    Check if exercise equipment matches user's available equipment.

    Args:
        ex_equipment: Exercise's required equipment
        user_equipment: User's available equipment
        exercise_name: Exercise name (for additional matching)

    Returns:
        True if exercise is compatible with user's equipment
    """
    equipment_lower = [eq.lower() for eq in user_equipment]

    # Expand general equipment options
    if "full gym" in equipment_lower:
        equipment_lower = FULL_GYM_EQUIPMENT
    elif "home gym" in equipment_lower:
        equipment_lower = HOME_GYM_EQUIPMENT
    elif "bodyweight only" in equipment_lower:
        equipment_lower = ["body weight", "bodyweight", "none"]
    else:
        # Always include bodyweight as an option
        equipment_lower = equipment_lower + ["body weight", "bodyweight", "none"]

    ex_equipment_lower = ex_equipment.lower() if ex_equipment else ""

    # Check if exercise equipment matches user's equipment
    equipment_match = False
    for eq in equipment_lower:
        if eq and ex_equipment_lower and (eq in ex_equipment_lower or ex_equipment_lower in eq):
            equipment_match = True
            break

    if not equipment_match:
        # Also check exercise name for equipment clues
        exercise_name_lower = exercise_name.lower() if exercise_name else ""
        for eq in equipment_lower:
            if eq and eq in exercise_name_lower:
                equipment_match = True
                break

    return equipment_match


def pre_filter_by_injuries(
    candidates: List[Dict],
    injuries: List[str],
) -> List[Dict]:
    """
    Pre-filter exercises that are contraindicated for user's injuries.

    This is a safety net to catch dangerous exercises before AI selection.

    Args:
        candidates: List of exercise candidates
        injuries: List of user's injuries

    Returns:
        Filtered list of safe candidates
    """
    # Determine which injury categories apply
    active_patterns: Set[str] = set()
    injuries_lower = [inj.lower() for inj in injuries]

    for injury in injuries_lower:
        for key, patterns in INJURY_CONTRAINDICATIONS.items():
            if key in injury:
                active_patterns.update(patterns)

    if not active_patterns:
        logger.info("No specific contraindication patterns found for injuries")
        return candidates

    logger.info(f"Filtering out exercises matching: {active_patterns}")

    # Filter candidates
    safe_candidates = []
    for candidate in candidates:
        exercise_name = candidate.get("name", "").lower()
        target_muscle = candidate.get("target_muscle", "").lower()
        body_part = candidate.get("body_part", "").lower()

        # Check if exercise matches any contraindicated pattern
        is_unsafe = False
        for pattern in active_patterns:
            if pattern in exercise_name or pattern in target_muscle or pattern in body_part:
                logger.debug(f"Filtering out '{candidate.get('name')}' (matches '{pattern}')")
                is_unsafe = True
                break

        if not is_unsafe:
            safe_candidates.append(candidate)

    return safe_candidates
