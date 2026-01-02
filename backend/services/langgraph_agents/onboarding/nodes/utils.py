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

    # Fields that have multiple valid keys (pre-quiz uses different names)
    # selected_days can also be stored as workoutDays from pre-quiz
    field_aliases = {
        "selected_days": ["selectedDays", "workoutDays"],
        "selectedDays": ["selected_days", "workoutDays"],
    }

    # Try the field as-is first
    value = collected.get(field)

    # If not found or empty, try the alternative case
    if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
        alt_field = snake_to_camel.get(field) or camel_to_snake.get(field)
        if alt_field:
            value = collected.get(alt_field)

    # If still not found, check aliases (e.g., workoutDays for selected_days)
    if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
        aliases = field_aliases.get(field, [])
        for alias in aliases:
            value = collected.get(alias)
            if value is not None and value != "" and not (isinstance(value, list) and len(value) == 0):
                break

    return value


def detect_field_from_response(response: str) -> Optional[str]:
    """
    Detect which field the AI is asking about from response keywords.

    This function must be coach-agnostic - it should detect fields regardless
    of which coach persona is speaking (Coach Mike, Dr. Sarah, Sergeant Max, etc.)

    Args:
        response: The AI response text

    Returns:
        The detected field name, or None if not detected
    """
    response_lower = response.lower()
    logger.info(f"[detect_field] Checking response: {response_lower[:100]}...")

    # Map keywords to fields - order matters (more specific patterns first)
    # NOTE: Put more specific multi-word patterns before generic single words
    # IMPORTANT: These patterns must work for ALL coach personalities
    field_patterns = {
        # Training experience / history - check FIRST (most specific)
        # Coach variations: "How long have you been lifting?", "What's your training history?",
        # "Been at this long?", "Training background?", "How many years?"
        "training_experience": [
            "how long have you been", "been lifting", "been training", "training history",
            "training background", "lifting experience", "gym experience", "workout experience",
            "years of training", "years of lifting", "how many years", "experience with weights",
            "new to lifting", "new to the gym", "new to training", "been at this",
            "fitness journey", "training journey", "how experienced are you",
        ],
        # Past programs - what they've DONE before
        # Coach variations: "Ever tried PPL?", "What programs have you followed?", "Done any structured programs?"
        "past_programs": [
            "ever followed a program", "followed a program", "programs have you", "tried before",
            "done before", "what have you tried", "workout routine before", "ppl", "bro split",
            "starting strength", "stronglifts", "5x5", "push pull legs", "structured program",
            "followed any", "routine have you", "programs before",
        ],
        # Selected days - which specific days
        "selected_days": [
            "which days", "what days", "pick your days", "choose your days", "select days",
            "days work for you", "days of the week", "prefer to train", "workout days",
        ],
        # Workout duration - only match when specifically asking about duration
        # Coach variations: "How long per session?", "30, 45, 60, or 90?", "Session length?"
        "workout_duration": [
            "how long per workout", "how long are your workouts", "workout length",
            "session length", "30, 45, 60", "30, 45, 60, 90", "per session",
            "minutes per workout", "time per workout", "how long do you want",
            "how much time", "duration", "workout time",
        ],
        # Target weight - ask about goal/target weight (check BEFORE focus_areas since "target" could conflict)
        # Coach variations: "Any weight goal?", "Target weight in mind?", "Happy where you are?"
        "target_weight_kg": [
            "target weight", "goal weight", "want to weigh", "want to be at", "drop to",
            "gain to", "happy where you are", "any target weight", "weight goal",
            "lose some weight", "gain some weight", "ideal weight", "weight in mind",
            "pounds to lose", "pounds to gain", "kg to lose", "kg to gain",
        ],
        # Workout variety - check BEFORE focus_areas because AI may say "full-body" when asking about variety
        # Coach variations: "Same exercises or mix it up?", "Prefer consistency?", "Like variety?"
        "workout_variety": [
            "same exercises", "mix it up", "for some variety", "stick with the same",
            "consistent routine", "fresh each week", "each week or", "variety or consistency",
            "consistent or varied", "routine variety", "exercise variety", "switch things up",
            "keep it fresh", "same workout", "different workouts",
        ],
        # Focus areas - use specific patterns, NOT just "full body" which can appear in other contexts
        # Coach variations: "Any muscles to prioritize?", "Focus areas?", "Target any muscle groups?"
        # Sergeant Max: "which muscles need work", "hit specific muscle"
        # Dr. Sarah: "muscle groups to emphasize", "target areas"
        # Hype Danny: "what we hitting", "areas you want to focus"
        "focus_areas": [
            "muscles you'd like to prioritize", "muscles you want to prioritize", "prioritize",
            "focus area", "target muscle", "muscle group", "any muscles to", "focus on which",
            "areas to focus", "body parts", "muscle to work", "emphasize", "priority muscle",
            "want to hit", "want to target", "full-body focus", "full body focus",
            "muscles to work on", "specific muscles", "any particular muscle",
            "muscles need work", "need to hit", "which muscles", "what muscles",
            "target areas", "areas you want", "muscle focus", "specific areas",
            "full-body or", "specific focus",
        ],
        # Biggest obstacle - barriers to consistency
        # Coach variations: "What's been holding you back?", "Biggest challenge?", "What stops you?"
        "biggest_obstacle": [
            "obstacle", "barrier", "holding you back", "struggle", "challenge", "biggest",
            "stops you", "gets in the way", "hard time with", "difficulty with",
            "trouble with", "issue with", "problem with",
        ],
        # Equipment
        "equipment": [
            "equipment", "gym access", "what do you have", "access to", "what gear",
            "tools available", "what's available",
        ],
        # Goals
        "goals": [
            "goal", "achieve", "want to", "looking to", "aiming for", "objective",
        ],
        # Fitness level
        "fitness_level": [
            "experience level", "fitness level", "beginner", "intermediate", "advanced",
            "how experienced", "skill level",
        ],
    }

    for field, keywords in field_patterns.items():
        for kw in keywords:
            if kw in response_lower:
                logger.info(f"[detect_field] MATCHED: field={field}, keyword='{kw}'")
                return field
    logger.info(f"[detect_field] No field detected from response")
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
