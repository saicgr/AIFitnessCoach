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

# Patterns to avoid in substitute exercises per injury.
#
# INVARIANT: every key of INJURY_CONTRAINDICATIONS must appear here. This dict
# is the second (broadening) gate in `find_safe_substitute` — it generalises the
# named avoid list into movement patterns (shoulder's "overhead press"/"bench
# press" -> "press"). A missing key silently degrades that gate to a no-op and
# lets an unvetted substitute through, which is why `find_safe_substitute` now
# fails CLOSED when a known injury has no pattern list.
SUBSTITUTE_CONTRAINDICATIONS: Dict[str, List[str]] = {
    "shoulder": ["press", "raise", "dip"],
    "lower back": ["deadlift", "row", "good morning"],
    "knee": ["squat", "lunge", "leg"],
    "elbow": ["curl", "pushdown", "extension"],
    # Loaded pressing, gripping and weight-bearing-on-the-hand movements all
    # load an injured wrist. Generalises the wrist avoid list above
    # ("bench press", "curl", "push-ups") the same way the shoulder entry
    # generalises its own.
    "wrist": ["press", "curl", "push-up", "push up", "pushup", "plank", "dip"],
}


def is_exercise_contraindicated(exercise_name: str, injury: str) -> bool:
    """Check if an exercise is contraindicated for an injury."""
    injury_lower = injury.lower()
    contraindicated = INJURY_CONTRAINDICATIONS.get(injury_lower, [])
    exercise_lower = exercise_name.lower()

    return any(c in exercise_lower for c in contraindicated)


def find_safe_substitute(exercise_name: str, injury: str) -> Optional[str]:
    """Find a substitute exercise that's safe for the injury.

    A candidate must clear BOTH gates:

    1. `is_exercise_contraindicated` — the authoritative per-injury avoid list.
    2. `SUBSTITUTE_CONTRAINDICATIONS` — extra movement patterns that are risky
       as a replacement even when not named on the avoid list.

    Gate 1 used to be missing, which let this function hand back a substitute
    that INJURY_CONTRAINDICATIONS itself forbids (e.g. wrist injury:
    push-ups -> bench press; elbow injury: tricep pushdown -> skull crushers).
    `workout_adaptation_service._substitute_injury_exercises` swaps the
    exercise in on trust, so an injured user was handed another exercise the
    system had already flagged as unsafe for that same injury. When nothing
    clears both gates we return None, and the caller drops the exercise —
    which is the safe outcome.
    """
    name_lower = exercise_name.lower()
    injury_lower = injury.lower()

    # Get potential substitutes
    substitutes = []
    for key, subs in EXERCISE_SUBSTITUTES.items():
        if key in name_lower:
            substitutes.extend(subs)

    if not substitutes:
        return None

    # Filter out unsafe substitutes.
    #
    # Fail CLOSED: a known injury (one with an avoid list) that has no
    # substitute-pattern list cannot be vetted by gate 2, so we refuse to
    # offer a substitute at all rather than hand back an unvetted one. The
    # caller then drops the exercise, which is the safe outcome. Previously
    # this `.get(..., [])` failed OPEN — see the "wrist" gap fixed above.
    if injury_lower in INJURY_CONTRAINDICATIONS and injury_lower not in SUBSTITUTE_CONTRAINDICATIONS:
        return None
    bad_patterns = SUBSTITUTE_CONTRAINDICATIONS.get(injury_lower, [])

    for sub in substitutes:
        sub_lower = sub.lower()
        if is_exercise_contraindicated(sub, injury_lower):
            continue
        is_safe = not any(bad in sub_lower for bad in bad_patterns)
        if is_safe:
            return sub

    return None
