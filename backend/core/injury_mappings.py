"""
Injury-related mappings for exercise adaptation.

This module contains injury contraindications used across services.
"""
from typing import Dict, List, Optional
from core.exercise_data import EXERCISE_SUBSTITUTES

# Exercises to avoid per injury type
INJURY_CONTRAINDICATIONS: Dict[str, List[str]] = {
    "shoulder": ["overhead press", "lateral raise", "bench press", "dip"],
    "lower back": ["deadlift", "barbell row", "good morning", "squat"],
    "knee": ["squat", "leg press", "lunges", "leg extension"],
    "elbow": ["tricep pushdown", "skull crushers", "curl"],
    "wrist": ["bench press", "curl", "push-ups"],
}

# Patterns to avoid in substitute exercises per injury
SUBSTITUTE_CONTRAINDICATIONS: Dict[str, List[str]] = {
    "shoulder": ["press", "raise", "dip"],
    "lower back": ["deadlift", "row", "good morning"],
    "knee": ["squat", "lunge", "leg"],
    "elbow": ["curl", "pushdown", "extension"],
}


def is_exercise_contraindicated(exercise_name: str, injury: str) -> bool:
    """Check if an exercise is contraindicated for an injury."""
    injury_lower = injury.lower()
    contraindicated = INJURY_CONTRAINDICATIONS.get(injury_lower, [])
    exercise_lower = exercise_name.lower()

    return any(c in exercise_lower for c in contraindicated)


def find_safe_substitute(exercise_name: str, injury: str) -> Optional[str]:
    """Find a substitute exercise that's safe for the injury."""
    name_lower = exercise_name.lower()
    injury_lower = injury.lower()

    # Get potential substitutes
    substitutes = []
    for key, subs in EXERCISE_SUBSTITUTES.items():
        if key in name_lower:
            substitutes.extend(subs)

    if not substitutes:
        return None

    # Filter out unsafe substitutes
    bad_patterns = SUBSTITUTE_CONTRAINDICATIONS.get(injury_lower, [])

    for sub in substitutes:
        sub_lower = sub.lower()
        is_safe = not any(bad in sub_lower for bad in bad_patterns)
        if is_safe:
            return sub

    return None
