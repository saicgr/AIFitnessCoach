"""
Utility functions for onboarding nodes.

Contains helper functions for string handling, field detection, and data normalization.
"""

from typing import Any, Dict, Optional
import re

from core.logger import get_logger

logger = get_logger(__name__)


# Non-gym activity patterns - activities that don't require gym workouts
NON_GYM_ACTIVITIES = {
    # Walking/Steps
    'walk': {'activity': 'walking', 'complement': 'lower body strength and stretching'},
    'walking': {'activity': 'walking', 'complement': 'lower body strength and stretching'},
    'steps': {'activity': 'step counting', 'complement': 'lower body strength and stretching'},
    '10k steps': {'activity': 'step counting', 'complement': 'lower body strength and stretching'},
    '10000 steps': {'activity': 'step counting', 'complement': 'lower body strength and stretching'},
    'daily steps': {'activity': 'step counting', 'complement': 'lower body strength and stretching'},

    # Outdoor Cycling
    'cycling outdoors': {'activity': 'outdoor cycling', 'complement': 'core and upper body strength'},
    'bike outdoors': {'activity': 'outdoor cycling', 'complement': 'core and upper body strength'},
    'road cycling': {'activity': 'outdoor cycling', 'complement': 'core and upper body strength'},
    'mountain biking': {'activity': 'mountain biking', 'complement': 'core and upper body strength'},

    # Outdoor Running
    'jogging': {'activity': 'jogging', 'complement': 'leg strength and mobility'},
    'jog': {'activity': 'jogging', 'complement': 'leg strength and mobility'},
    'just run': {'activity': 'running', 'complement': 'leg strength and mobility'},
    'just running': {'activity': 'running', 'complement': 'leg strength and mobility'},

    # Meditation/Mindfulness
    'meditation only': {'activity': 'meditation', 'complement': 'light stretching and mobility'},
    'just meditation': {'activity': 'meditation', 'complement': 'light stretching and mobility'},
    'just meditate': {'activity': 'meditation', 'complement': 'light stretching and mobility'},

    # Sports without gym training
    'just play': {'activity': 'recreational sports', 'complement': 'injury prevention exercises'},
    'casual sports': {'activity': 'recreational sports', 'complement': 'injury prevention exercises'},

    # Stretching only
    'just stretch': {'activity': 'stretching', 'complement': 'light mobility work'},
    'stretching only': {'activity': 'stretching', 'complement': 'light mobility work'},
}


def ensure_string(value: Any) -> str:
    """
    Ensure a value is a string.

    LangGraph state can sometimes accumulate values into lists.
    This helper ensures we always work with a string.

    Args:
        value: The value to convert to string

    Returns:
        String representation of the value
    """
    if isinstance(value, list):
        logger.warning(f"[ensure_string] Value was a list: {value}")
        return " ".join(str(item) for item in value) if value else ""
    elif not isinstance(value, str):
        logger.warning(f"[ensure_string] Value was {type(value)}: {value}")
        return str(value) if value else ""
    return value


def get_field_value(collected: Dict[str, Any], field: str) -> Any:
    """
    Get a field value from collected data, checking both snake_case and camelCase.

    The frontend stores data in camelCase but backend uses snake_case.
    This helper checks both variants to ensure we don't miss collected data.

    Args:
        collected: Dictionary of collected data
        field: Field name to look up

    Returns:
        The field value, or None if not found
    """
    # Map of snake_case fields to their camelCase equivalents
    snake_to_camel = {
        "days_per_week": "daysPerWeek",
        "selected_days": "selectedDays",
        "workout_duration": "workoutDuration",
        "workout_variety": "workoutVariety",
        "fitness_level": "fitnessLevel",
        "height_cm": "heightCm",
        "weight_kg": "weightKg",
        "training_experience": "trainingExperience",
        "workout_environment": "workoutEnvironment",
        "focus_areas": "focusAreas",
        "biggest_obstacle": "biggestObstacle",
        "past_programs": "pastPrograms",
        "target_weight_kg": "targetWeightKg",
        "activity_level": "activityLevel",
    }

    camel_to_snake = {v: k for k, v in snake_to_camel.items()}

    # Try the field as-is first
    value = collected.get(field)

    # If not found or empty, try the alternative case
    if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
        alt_field = snake_to_camel.get(field) or camel_to_snake.get(field)
        if alt_field:
            value = collected.get(alt_field)

    return value


def detect_field_from_response(response: str) -> Optional[str]:
    """
    Detect which field the AI is asking about from response keywords.

    Args:
        response: The AI response text

    Returns:
        The detected field name, or None if not detected
    """
    response_lower = response.lower()

    # Map keywords to fields - order matters (more specific patterns first)
    # NOTE: Put more specific multi-word patterns before generic single words
    field_patterns = {
        # Past programs - check first since AI may reference duration in same message
        "past_programs": ["ever followed a program", "followed a program", "ppl", "bro split", "tried before", "starting strength", "stronglifts", "5x5", "push pull legs"],
        # Selected days
        "selected_days": ["which days", "what days", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "days of the week"],
        # Workout duration - only match when specifically asking about duration
        "workout_duration": ["how long per workout", "how long are your workouts", "workout length", "session length", "30, 45, 60", "30, 45, 60, 90"],
        # Target weight - ask about goal/target weight (check BEFORE focus_areas since "target" could conflict)
        "target_weight_kg": ["target weight", "goal weight", "want to weigh", "want to be at", "drop to", "gain to", "happy where you are", "any target weight"],
        # Workout variety - check BEFORE focus_areas because AI may say "full-body" when asking about variety
        "workout_variety": ["same exercises", "mix it up", "for some variety", "stick with the same", "consistent routine", "fresh each week", "each week or"],
        # Focus areas - use specific patterns, NOT just "full body" which can appear in other contexts
        "focus_areas": ["muscles you'd like to prioritize", "prioritize", "focus area", "target muscle", "muscle group", "any muscles to", "focus on which"],
        # Biggest obstacle
        "biggest_obstacle": ["obstacle", "barrier", "consistency", "struggle", "challenge", "biggest"],
        # Equipment
        "equipment": ["equipment", "gym access", "what do you have", "access to", "what gear"],
        # Goals
        "goals": ["goal", "achieve", "want to", "looking to", "aiming for"],
        # Fitness level
        "fitness_level": ["experience level", "fitness level", "beginner", "intermediate", "advanced", "how experienced"],
    }

    for field, keywords in field_patterns.items():
        if any(kw in response_lower for kw in keywords):
            return field
    return None


def detect_non_gym_activity(user_message: Any) -> Optional[Dict[str, str]]:
    """
    Detect if user's goal is a non-gym activity.

    Args:
        user_message: The user's message

    Returns:
        dict with 'activity' and 'complement' if detected, None otherwise
    """
    # Ensure user_message is a string
    user_message = ensure_string(user_message)
    user_lower = user_message.lower().strip()

    # Check for explicit non-gym phrases
    for pattern, info in NON_GYM_ACTIVITIES.items():
        if pattern in user_lower:
            logger.info(f"[Non-Gym Detection] Detected non-gym activity: {info['activity']}")
            return info

    # Check for step goals with numbers (e.g., "walk 10000 steps", "5k steps daily")
    step_pattern = r'\b(\d+k?)\s*(steps?|walking)\b'
    if re.search(step_pattern, user_lower):
        logger.info(f"[Non-Gym Detection] Detected step goal in message")
        return {'activity': 'step counting', 'complement': 'lower body strength and stretching'}

    return None
