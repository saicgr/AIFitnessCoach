"""
Adaptive Workout Service - Calculates workout parameters based on user history.

This service analyzes user's recent workout performance to determine optimal:
- Sets per exercise
- Reps per exercise
- Rest time between sets
- Workout intensity

Key factors considered:
- Difficulty feedback from recent workouts (too easy, just right, too hard)
- Completion rate (did they finish all sets?)
- Time taken vs expected
- Recent PRs and volume trends
- Age-based intensity caps for safety
"""

from .adaptive_workout_service_helpers import (  # noqa: F401
    AdaptiveWorkoutService,
    get_user_set_type_preferences,
    build_set_type_context,
    get_adaptive_workout_service,
)
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


# =============================================================================
# AGE-BASED WORKOUT ADJUSTMENTS
# =============================================================================
# These adjustments ensure workout safety and appropriateness across age groups.
# Older users get reduced volume, longer rest periods, and lower intensity ceilings.

AGE_ADJUSTMENTS = {
    "young_adult": {  # Under 30
        "max_reps_per_exercise": 25,
        "max_sets_per_exercise": 6,
        "rest_multiplier": 1.0,
        "intensity_ceiling": 1.0,
        "description": "Full intensity - no age-based restrictions",
    },
    "adult": {  # 30-44
        "max_reps_per_exercise": 20,
        "max_sets_per_exercise": 5,
        "rest_multiplier": 1.1,
        "intensity_ceiling": 0.95,
        "description": "Slightly reduced intensity with modestly longer rest",
    },
    "middle_aged": {  # 45-59
        "max_reps_per_exercise": 16,
        "max_sets_per_exercise": 4,
        "rest_multiplier": 1.25,
        "intensity_ceiling": 0.85,
        "description": "Moderate intensity with focus on joint health and recovery",
    },
    "senior": {  # 60-74
        "max_reps_per_exercise": 12,
        "max_sets_per_exercise": 3,
        "rest_multiplier": 1.5,
        "intensity_ceiling": 0.75,
        "description": "Reduced volume, prioritize safety and recovery",
    },
    "elderly": {  # 75+
        "max_reps_per_exercise": 10,
        "max_sets_per_exercise": 3,
        "rest_multiplier": 2.0,
        "intensity_ceiling": 0.65,
        "description": "Low volume, extended rest, focus on mobility and balance",
    },
}


def get_age_bracket(age: int) -> str:
    """
    Determine the age bracket for a given age.

    Args:
        age: User's age in years

    Returns:
        Age bracket string (young_adult, adult, middle_aged, senior, elderly)
    """
    if age < 30:
        return "young_adult"
    elif age < 45:
        return "adult"
    elif age < 60:
        return "middle_aged"
    elif age < 75:
        return "senior"
    else:
        return "elderly"


def get_age_adjustments(age: int) -> Dict[str, Any]:
    """
    Get age-based workout adjustments for a user.

    Args:
        age: User's age in years

    Returns:
        Dict with max_reps_per_exercise, max_sets_per_exercise,
        rest_multiplier, intensity_ceiling, description
    """
    bracket = get_age_bracket(age)
    return AGE_ADJUSTMENTS[bracket]


def apply_age_caps(exercises: List[Dict], age: int) -> List[Dict]:
    """
    Apply age-based caps to generated exercises.

    This is a safety layer that ensures workout parameters are appropriate
    for the user's age, even if the AI generates higher values.

    Adjustments made:
    - Cap reps at age-appropriate maximum
    - Cap sets at age-appropriate maximum
    - Increase rest time based on age multiplier
    - Reduce weight recommendations based on intensity ceiling

    Args:
        exercises: List of exercise dicts from workout generation
        age: User's age in years

    Returns:
        List of exercises with age-appropriate caps applied
    """
    if not age or age < 18:
        # Don't apply caps for minors (different considerations) or missing age
        return exercises

    bracket = get_age_bracket(age)
    limits = AGE_ADJUSTMENTS[bracket]

    logger.info(f"[Age Caps] Applying {bracket} limits (age {age}) to {len(exercises)} exercises")

    modified_count = 0
    for ex in exercises:
        original = ex.copy()

        # Cap reps
        if ex.get("reps") and ex["reps"] > limits["max_reps_per_exercise"]:
            ex["reps"] = limits["max_reps_per_exercise"]

        # Cap sets
        if ex.get("sets") and ex["sets"] > limits["max_sets_per_exercise"]:
            ex["sets"] = limits["max_sets_per_exercise"]

        # Adjust rest time (increase for older users)
        if ex.get("rest_seconds"):
            ex["rest_seconds"] = int(ex["rest_seconds"] * limits["rest_multiplier"])

        # Reduce weight for intensity ceiling (if weight is specified)
        if ex.get("weight_kg") and limits["intensity_ceiling"] < 1.0:
            ex["weight_kg"] = round(ex["weight_kg"] * limits["intensity_ceiling"], 1)

        # Check if any modifications were made
        if original != ex:
            modified_count += 1
            logger.debug(
                f"[Age Caps] Modified {ex.get('name', 'unknown')}: "
                f"reps {original.get('reps')}->{ex.get('reps')}, "
                f"sets {original.get('sets')}->{ex.get('sets')}, "
                f"rest {original.get('rest_seconds')}->{ex.get('rest_seconds')}s"
            )

    if modified_count > 0:
        logger.info(f"[Age Caps] Modified {modified_count}/{len(exercises)} exercises for {bracket} user")

    return exercises


def get_senior_workout_prompt_additions(age: int) -> Optional[Dict[str, Any]]:
    """
    Get additional prompt instructions for senior users (60+).

    Returns None for users under 60, otherwise returns a dict with:
    - critical_instructions: String to add to Gemini prompt
    - max_reps: Maximum reps per exercise
    - max_sets: Maximum sets per exercise
    - extra_rest_percent: Percentage increase for rest periods
    - movement_priorities: List of movement types to prioritize
    - movements_to_avoid: List of movements to avoid

    Args:
        age: User's age in years

    Returns:
        Dict with senior-specific prompt additions, or None if under 60
    """
    if not age or age < 60:
        return None

    limits = get_age_adjustments(age)
    bracket = get_age_bracket(age)
    extra_rest_percent = int((limits["rest_multiplier"] - 1.0) * 100)

    # Build critical instructions for Gemini prompt
    critical_instructions = f"""
CRITICAL FOR SENIOR USER (age {age}):
- Maximum {limits['max_reps_per_exercise']} reps per exercise (NO EXCEPTIONS)
- Maximum {limits['max_sets_per_exercise']} sets per exercise
- Include {extra_rest_percent}% longer rest periods between sets
- Prioritize: seated exercises, supported movements, balance work
- AVOID: high-impact jumps, heavy lifts, explosive plyometrics
- Include extra mobility/warm-up exercises
- Focus on controlled, deliberate movements
- Ensure all exercises have modifications for limited mobility
"""

    movement_priorities = [
        "seated exercises",
        "supported movements",
        "balance work",
        "controlled tempo",
        "low-impact cardio",
        "flexibility work",
        "functional movements",
    ]

    movements_to_avoid = [
        "box jumps",
        "burpees",
        "heavy deadlifts",
        "jump squats",
        "explosive plyometrics",
        "high-impact running",
        "heavy overhead pressing",
    ]

    # Stricter for elderly (75+)
    if bracket == "elderly":
        movements_to_avoid.extend([
            "barbell exercises",
            "standing single-leg work without support",
            "floor-based exercises requiring getting up/down quickly",
        ])
        movement_priorities.extend([
            "chair-based exercises",
            "resistance band work",
            "walking",
        ])

    return {
        "critical_instructions": critical_instructions,
        "max_reps": limits["max_reps_per_exercise"],
        "max_sets": limits["max_sets_per_exercise"],
        "extra_rest_percent": extra_rest_percent,
        "intensity_ceiling": limits["intensity_ceiling"],
        "movement_priorities": movement_priorities,
        "movements_to_avoid": movements_to_avoid,
        "age_bracket": bracket,
    }


