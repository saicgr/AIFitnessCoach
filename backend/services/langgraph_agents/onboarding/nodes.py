"""
Node implementations for the Onboarding LangGraph agent.

AI-driven onboarding - no hardcoded questions!
"""
import json
from typing import Dict, Any, Optional, Union, List

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

from .state import OnboardingState
from .prompts import (
    ONBOARDING_AGENT_SYSTEM_PROMPT,
    DATA_EXTRACTION_SYSTEM_PROMPT,
    REQUIRED_FIELDS,
    FIELD_ORDER,
    QUICK_REPLIES,
)
from core.config import get_settings
from core.logger import get_logger
from services.training_program_service import get_training_program_map_sync

logger = get_logger(__name__)
settings = get_settings()


def ensure_string(value: Any) -> str:
    """
    Ensure a value is a string.

    LangGraph state can sometimes accumulate values into lists.
    This helper ensures we always work with a string.
    """
    if isinstance(value, list):
        logger.warning(f"[ensure_string] Value was a list: {value}")
        return " ".join(str(item) for item in value) if value else ""
    elif not isinstance(value, str):
        logger.warning(f"[ensure_string] Value was {type(value)}: {value}")
        return str(value) if value else ""
    return value


# Non-gym activity patterns - activities that don't require gym workouts
NON_GYM_ACTIVITIES = {
    # Walking/Steps
    'walk': {'activity': 'walking', 'complement': 'lower body strength and stretching'},
    'walking': {'activity': 'walking', 'complement': 'lower body strength and stretching'},
    'steps': {'activity': 'step counting', 'complement': 'lower body strength and stretching'},
    '10k steps': {'activity': 'step counting', 'complement': 'lower body strength and stretching'},
    '10000 steps': {'activity': 'step counting', 'complement': 'lower body strength and stretching'},
    'daily steps': {'activity': 'step counting', 'complement': 'lower body strength and stretching'},

    # Outdoor Cycling (not spin class)
    'cycling outdoors': {'activity': 'outdoor cycling', 'complement': 'core and upper body strength'},
    'bike outdoors': {'activity': 'outdoor cycling', 'complement': 'core and upper body strength'},
    'road cycling': {'activity': 'outdoor cycling', 'complement': 'core and upper body strength'},
    'mountain biking': {'activity': 'mountain biking', 'complement': 'core and upper body strength'},

    # Outdoor Running (as primary, not training for)
    'jogging': {'activity': 'jogging', 'complement': 'leg strength and mobility'},
    'jog': {'activity': 'jogging', 'complement': 'leg strength and mobility'},
    'just run': {'activity': 'running', 'complement': 'leg strength and mobility'},
    'just running': {'activity': 'running', 'complement': 'leg strength and mobility'},

    # Meditation/Mindfulness only
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


def detect_non_gym_activity(user_message) -> Optional[Dict[str, str]]:
    """
    Detect if user's goal is a non-gym activity.

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
    import re
    step_pattern = r'\b(\d+k?)\s*(steps?|walking)\b'
    if re.search(step_pattern, user_lower):
        logger.info(f"[Non-Gym Detection] Detected step goal in message")
        return {'activity': 'step counting', 'complement': 'lower body strength and stretching'}

    return None


def get_field_value(collected: Dict[str, Any], field: str) -> Any:
    """
    Get a field value from collected data, checking both snake_case and camelCase.

    The frontend stores data in camelCase but backend uses snake_case.
    This helper checks both variants to ensure we don't miss collected data.
    """
    # Map of snake_case fields to their camelCase equivalents
    snake_to_camel = {
        "days_per_week": "daysPerWeek",
        "selected_days": "selectedDays",
        "workout_duration": "workoutDuration",
        "fitness_level": "fitnessLevel",
        "height_cm": "heightCm",
        "weight_kg": "weightKg",
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


async def check_completion_node(state: OnboardingState) -> Dict[str, Any]:
    """
    Check if onboarding is complete by examining collected data.

    IMPORTANT: Handles both snake_case (backend) and camelCase (frontend) keys!
    Frontend stores data in camelCase but backend expects snake_case.

    Returns:
        - is_complete: True if all required fields are collected
        - missing_fields: List of fields still needed
    """
    logger.info("[Check Completion] Checking if onboarding is complete...")

    collected = state.get("collected_data", {})
    missing = []

    logger.info(f"[Check Completion] Collected data keys: {list(collected.keys())}")

    for field in REQUIRED_FIELDS:
        # Use helper to check both snake_case and camelCase
        value = get_field_value(collected, field)

        # Check if field is missing or empty
        if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
            missing.append(field)

    is_complete = len(missing) == 0

    logger.info(f"[Check Completion] Complete: {is_complete}, Missing: {missing}")

    return {
        "is_complete": is_complete,
        "missing_fields": missing,
    }


async def onboarding_agent_node(state: OnboardingState) -> Dict[str, Any]:
    """
    AI decides what question to ask next (NO HARDCODED QUESTIONS).

    The AI generates natural, context-aware questions based on:
    - What data has been collected
    - What's still missing
    - The user's last message

    Can ask clarifying questions if user is vague.
    """
    logger.info("[Onboarding Agent] AI generating next question...")

    collected = state.get("collected_data", {})
    missing = state.get("missing_fields", [])
    history = state.get("conversation_history", [])

    # Ensure user_message is a string (LangGraph state might accumulate to list)
    user_message = ensure_string(state.get("user_message", ""))

    # Build system prompt with context
    system_prompt = ONBOARDING_AGENT_SYSTEM_PROMPT.format(
        collected_data=json.dumps(collected, indent=2) if collected else "{}",
        missing_fields=", ".join(missing) if missing else "Nothing - ready to complete!",
    )

    # Build messages
    messages = [SystemMessage(content=system_prompt)]

    # Add conversation history
    for msg in history:
        if msg.get("role") == "user":
            messages.append(HumanMessage(content=msg["content"]))
        elif msg.get("role") == "assistant":
            messages.append(AIMessage(content=msg["content"]))

    # Add current user message
    messages.append(HumanMessage(content=user_message))

    # Call LLM to generate next question
    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        google_api_key=settings.gemini_api_key,
        temperature=0.8,  # Slightly higher for more natural conversation
    )

    response = await llm.ainvoke(messages)

    # Handle various Gemini response.content formats:
    # - string: "Hello!" (normal case)
    # - list of strings: ["Hello", "World"]
    # - list of dicts: [{"type": "text", "text": "Hello!"}]
    # - dict: {"type": "text", "text": "Hello!"}
    response_content = response.content
    logger.info(f"[Onboarding Agent] Raw response.content type: {type(response_content)}")

    if isinstance(response_content, dict):
        # Single dict with 'text' field
        logger.warning(f"[Onboarding Agent] response.content was a dict: {str(response_content)[:200]}")
        response_content = response_content.get("text", str(response_content))
    elif isinstance(response_content, list):
        # List of parts - could be strings or dicts
        logger.warning(f"[Onboarding Agent] response.content was a list: {str(response_content)[:200]}")
        parts = []
        for item in response_content:
            if isinstance(item, dict):
                parts.append(item.get("text", str(item)))
            else:
                parts.append(str(item))
        response_content = " ".join(parts) if parts else ""
    elif not isinstance(response_content, str):
        logger.warning(f"[Onboarding Agent] response.content was {type(response_content)}: {response_content}")
        response_content = str(response_content) if response_content else ""

    logger.info(f"[Onboarding Agent] AI question: {response_content[:100]}...")

    # Determine if we should show quick replies
    quick_replies = None
    component = None

    # Smart detection: analyze what the AI is actually asking about
    question_lower = response_content.lower()

    # Check if AI is asking about specific days (not just "how many days")
    is_asking_specific_days = any(keyword in question_lower for keyword in [
        "which days", "what days", "which day", "what day", "select days", "choose days",
        "day of the week", "days of the week", "works best for you",
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
    ])

    # Check if AI is asking about workout duration
    is_asking_duration = any(keyword in question_lower for keyword in [
        "how long", "duration", "minutes", "each workout", "workout to be"
    ])

    # Check if AI is asking about how many days per week
    is_asking_days_per_week = any(keyword in question_lower for keyword in [
        "how many days", "days per week", "times per week", "times a week"
    ])

    # Check if AI is asking about equipment
    # Note: Be more specific to avoid false positives from acknowledgment phrases like "full gym"
    # Only match if the question is specifically ASKING about equipment
    is_asking_equipment = any(keyword in question_lower for keyword in [
        "what equipment", "which equipment", "equipment do you", "equipment available",
        "access to a gym", "what tools", "what machines"
    ]) or (
        # Also check for generic "equipment?" at the end of a sentence
        "equipment?" in question_lower or
        "gym?" in question_lower
    )

    # Check if AI is asking about goals
    # Note: Be more specific to avoid false positives from acknowledgment phrases like "your goals"
    # Only match if the question is specifically ASKING about goals
    is_asking_goals = any(keyword in question_lower for keyword in [
        "what are your goals", "your goals?", "fitness goals?", "main goals",
        "what goals", "which goals", "looking to achieve?", "want to achieve?"
    ]) or "goals?" in question_lower

    # Check if AI is asking about fitness level
    # Note: Be specific - "fitness level" is the key phrase, not generic words like "experience"
    is_asking_fitness_level = any(keyword in question_lower for keyword in [
        "fitness level", "describe your fitness", "how fit are you",
        "fitness level?", "your level?"
    ]) or (
        # Also match questions ending with fitness level related options
        "?" in question_lower and any(word in question_lower for word in ["beginner", "intermediate", "advanced"])
    )

    # Check if AI is giving a completion/wrap-up message
    is_completion_message = any(keyword in question_lower for keyword in [
        "get started", "let's go", "ready to", "put together a plan", "create your plan",
        "fitness journey", "all set", "got everything", "thanks for sharing"
    ])

    # Check if AI is asking for FREE TEXT input (no quick replies needed)
    # These fields should let the user type their answer
    is_asking_name = any(keyword in question_lower for keyword in [
        "your name", "what's your name", "what is your name", "name?",
        "share your name", "tell me your name", "call you"
    ])
    is_asking_age = any(keyword in question_lower for keyword in [
        "how old", "your age", "age?"
    ])
    is_asking_height = any(keyword in question_lower for keyword in [
        "how tall", "your height", "height?"
    ])
    is_asking_weight = any(keyword in question_lower for keyword in [
        "how much do you weigh", "your weight", "weight?"
    ])

    # If asking for free text input, don't show any quick replies
    is_free_text_question = is_asking_name or is_asking_age or is_asking_height or is_asking_weight

    # Multi-select fields (lists that allow multiple selections)
    multi_select_fields = ["goals", "equipment"]
    is_multi_select = False

    # Smart quick reply detection based on missing fields and question content
    # Sort missing fields by FIELD_ORDER to ensure we ask questions in the correct sequence

    # PRIORITY -1: If AI is asking for free text input (name, age, etc.), skip quick replies entirely
    if is_free_text_question:
        logger.info(f"[Onboarding Agent] 📝 Free text question detected, no quick replies")
        # Don't show any quick replies - let user type their answer

    elif missing:
        # Get next field based on FIELD_ORDER
        next_field = None
        for field in FIELD_ORDER:
            if field in missing:
                next_field = field
                break

        if not next_field:
            next_field = missing[0]  # Fallback to first missing if not in FIELD_ORDER

        # DEBUG LOGGING
        logger.info(f"[Onboarding Agent] 🔍 DEBUG: next_field = {next_field}")
        logger.info(f"[Onboarding Agent] 🔍 DEBUG: is_asking_specific_days = {is_asking_specific_days}")
        logger.info(f"[Onboarding Agent] 🔍 DEBUG: is_asking_duration = {is_asking_duration}")
        logger.info(f"[Onboarding Agent] 🔍 DEBUG: is_asking_days_per_week = {is_asking_days_per_week}")
        logger.info(f"[Onboarding Agent] 🔍 DEBUG: is_asking_equipment = {is_asking_equipment}")
        logger.info(f"[Onboarding Agent] 🔍 DEBUG: is_asking_goals = {is_asking_goals}")
        logger.info(f"[Onboarding Agent] 🔍 DEBUG: is_completion_message = {is_completion_message}")

        # PRIORITY 0: If AI sent a completion-like message but fields are still missing,
        # OVERRIDE the AI response and ask for the next missing field
        if is_completion_message:
            logger.info(f"[Onboarding Agent] ⚠️ AI sent completion message but still missing fields: {missing}")

            # Override AI response - ask for next missing field
            if "days_per_week" in missing:
                response_content = "Almost there! How many days per week would you like to work out?"
                quick_replies = QUICK_REPLIES.get("days_per_week")
                logger.info(f"[Onboarding Agent] ✅ Overriding AI: asking for days_per_week")
            elif "selected_days" in missing:
                response_content = "Great! Which specific days work best for you?"
                component = "day_picker"
                logger.info(f"[Onboarding Agent] ✅ Overriding AI: showing day_picker")
            elif "workout_duration" in missing:
                response_content = "How long would you like each workout to be?"
                quick_replies = QUICK_REPLIES.get("workout_duration")
                logger.info(f"[Onboarding Agent] ✅ Overriding AI: asking for workout_duration")
            elif next_field in QUICK_REPLIES:
                # Convert field names to human-readable text
                field_display_names = {
                    "weightKg": "weight",
                    "heightCm": "height",
                    "fitness_level": "fitness level",
                    "days_per_week": "workout schedule (how many days per week)",
                    "selected_days": "preferred workout days",
                    "workout_duration": "workout duration",
                }
                display_name = field_display_names.get(next_field, next_field.replace('_', ' '))
                response_content = f"One more thing - please tell me about your {display_name}."
                quick_replies = QUICK_REPLIES[next_field]
                is_multi_select = next_field in multi_select_fields
                logger.info(f"[Onboarding Agent] ✅ Overriding AI: asking for {next_field}")

        # PRIORITY 1: If AI is asking about specific days and we have days_per_week, show quick replies for days
        # Note: missing list uses snake_case field names from REQUIRED_FIELDS
        # We check if days_per_week is NOT missing (i.e., already collected)
        elif is_asking_specific_days and "selected_days" in missing and "days_per_week" not in missing:
            quick_replies = QUICK_REPLIES["selected_days"]
            is_multi_select = True  # Days is multi-select
            logger.info(f"[Onboarding Agent] ✅ Adding quick replies for: selected_days (multi_select=True)")

        # PRIORITY 2: If AI is asking about specific days but we don't have days_per_week yet,
        # show quick replies anyway - user might be skipping ahead
        elif is_asking_specific_days and "selected_days" in missing:
            quick_replies = QUICK_REPLIES["selected_days"]
            is_multi_select = True
            logger.info(f"[Onboarding Agent] ✅ Adding quick replies for: selected_days (days_per_week not yet collected, multi_select=True)")

        # PRIORITY 3: Match quick replies based on what AI is actually asking about
        elif is_asking_equipment and "equipment" in missing:
            quick_replies = QUICK_REPLIES["equipment"]
            is_multi_select = True  # Equipment is multi-select
            logger.info(f"[Onboarding Agent] ✅ Adding quick replies for: equipment (detected from question, multi_select=True)")

        elif is_asking_goals and "goals" in missing:
            quick_replies = QUICK_REPLIES["goals"]
            is_multi_select = True  # Goals is multi-select
            logger.info(f"[Onboarding Agent] ✅ Adding quick replies for: goals (detected from question, multi_select=True)")

        elif is_asking_fitness_level and "fitness_level" in missing:
            quick_replies = QUICK_REPLIES["fitness_level"]
            logger.info(f"[Onboarding Agent] ✅ Adding quick replies for: fitness_level (detected from question)")

        elif is_asking_duration and "workout_duration" in QUICK_REPLIES:
            quick_replies = QUICK_REPLIES["workout_duration"]
            logger.info(f"[Onboarding Agent] ✅ Adding quick replies for: workout_duration (detected from question)")

        elif is_asking_days_per_week and "days_per_week" in QUICK_REPLIES:
            quick_replies = QUICK_REPLIES["days_per_week"]
            logger.info(f"[Onboarding Agent] ✅ Adding quick replies for: days_per_week (detected from question)")

        # NOTE: We removed PRIORITY 4 (fallback to next_field) because it caused mismatched quick replies.
        # Quick replies should ONLY appear when we specifically detect what the AI is asking about.
        # If the AI asks about something we don't recognize (like name), no quick replies is the correct behavior.
        else:
            logger.info(f"[Onboarding Agent] ℹ️ No matching quick reply detected for this question")

    return {
        "messages": messages + [response],
        "next_question": response_content,
        "final_response": response_content,
        "quick_replies": quick_replies,
        "multi_select": is_multi_select,
        "component": component,
    }


async def extract_data_node(state: OnboardingState) -> Dict[str, Any]:
    """
    Extract structured data from user's message using AI.

    Uses GPT-4 with structured prompting to extract:
    - Personal info (name, age, gender, height, weight)
    - Fitness data (goals, equipment, fitness level)
    - Schedule (days per week, selected days, duration)
    - Health (injuries, conditions)

    Smart inference:
    - "bench press" → goals: Build Muscle, Increase Strength
    - "home workouts" → equipment: Bodyweight Only
    - "5'10, 150 lbs" → heightCm: 177.8, weightKg: 68.0
    """
    logger.info("[Extract Data] Extracting data from user message...")

    # Ensure user_message is a string (LangGraph state might accumulate to list)
    user_message = ensure_string(state.get("user_message", ""))

    collected_data = state.get("collected_data", {})

    # Calculate what's missing based on collected_data (missing_fields may not be set yet)
    # Use get_field_value helper to check both snake_case and camelCase keys
    from .prompts import REQUIRED_FIELDS
    missing = []
    for field in REQUIRED_FIELDS:
        value = get_field_value(collected_data, field)
        if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
            missing.append(field)

    logger.info(f"[Extract Data] Collected data keys: {list(collected_data.keys())}")
    logger.info(f"[Extract Data] Current missing fields: {missing}")
    logger.info(f"[Extract Data] User message: {user_message}")

    # NON-GYM ACTIVITY DETECTION: If user mentions walking/steps/etc, auto-set complementary goals
    if "goals" in missing:
        non_gym_info = detect_non_gym_activity(user_message)
        if non_gym_info:
            # Map activity to appropriate complementary workout goals
            activity_goals = {
                'walking': ["General Fitness", "Flexibility", "Improve Endurance"],
                'step counting': ["General Fitness", "Flexibility", "Improve Endurance"],
                'outdoor cycling': ["General Fitness", "Increase Strength", "Improve Endurance"],
                'mountain biking': ["General Fitness", "Increase Strength", "Improve Endurance"],
                'jogging': ["General Fitness", "Flexibility", "Improve Endurance"],
                'running': ["General Fitness", "Flexibility", "Improve Endurance"],
                'meditation': ["General Fitness", "Flexibility"],
                'recreational sports': ["General Fitness", "Flexibility"],
                'stretching': ["General Fitness", "Flexibility"],
            }
            goals = activity_goals.get(non_gym_info['activity'], ["General Fitness", "Flexibility"])
            logger.info(f"[Extract Data] Non-gym activity '{non_gym_info['activity']}' detected, setting complementary goals: {goals}")
            return {
                "collected_data": {
                    **collected_data,
                    "goals": goals,
                },
                "validation_errors": {},
            }

    # PRE-PROCESSING: Handle common simple patterns before AI extraction
    extracted = {}

    # If missing name and user provides it
    if "name" in missing:
        import re
        user_lower = user_message.lower().strip()

        # Pattern: "My name is X" or "I'm X" or "I am X" or "call me X" or just a single word/name
        name_patterns = [
            r"(?:my name is|i'm|i am|call me|it's|im)\s+([a-zA-Z][a-zA-Z\s'-]*?)(?:,|\.|\!|$|\s+i'm|\s+i am|\s+and)",
            r"^([a-zA-Z][a-zA-Z'-]*?)(?:,|\.|\!|$)",  # Just a name at the start
        ]

        for pattern in name_patterns:
            match = re.search(pattern, user_lower, re.IGNORECASE)
            if match:
                name = match.group(1).strip().title()
                # Validate it's a reasonable name (not too long, not a common word)
                common_words = {'the', 'and', 'or', 'but', 'if', 'then', 'yes', 'no', 'ok', 'okay', 'hi', 'hey', 'what', 'how', 'when', 'where', 'why'}
                if len(name) <= 30 and name.lower() not in common_words:
                    extracted["name"] = name
                    logger.info(f"[Extract Data] ✅ Pre-processed: name = {extracted['name']}")
                    break

    # If missing age and user provides it
    if "age" in missing:
        import re
        # Pattern: "25 years old" or "I'm 25" or "age 25" or just "25" when context is about age
        age_patterns = [
            r"(?:i'm|i am|age|aged)\s*(\d{1,3})\s*(?:years?\s*old)?",
            r"(\d{1,3})\s*years?\s*old",
            r"^(\d{1,3})$",  # Just a number
        ]

        for pattern in age_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                age = int(match.group(1))
                if 13 <= age <= 100:
                    extracted["age"] = age
                    logger.info(f"[Extract Data] ✅ Pre-processed: age = {extracted['age']}")
                    break

    # If missing gender and user provides it
    if "gender" in missing:
        user_lower = user_message.lower()
        if 'male' in user_lower and 'female' not in user_lower:
            extracted["gender"] = "male"
            logger.info(f"[Extract Data] ✅ Pre-processed: gender = male")
        elif 'female' in user_lower:
            extracted["gender"] = "female"
            logger.info(f"[Extract Data] ✅ Pre-processed: gender = female")
        elif user_lower.strip() in ['m', 'man', 'guy', 'boy']:
            extracted["gender"] = "male"
            logger.info(f"[Extract Data] ✅ Pre-processed: gender = male")
        elif user_lower.strip() in ['f', 'woman', 'girl', 'lady']:
            extracted["gender"] = "female"
            logger.info(f"[Extract Data] ✅ Pre-processed: gender = female")

    # If missing height and user provides it
    if "heightCm" in missing:
        import re
        user_lower = user_message.lower()

        # Pattern: "170cm" or "170 cm" or "1.70m" or "5'10" or "5 feet 10 inches"
        cm_match = re.search(r'(\d{2,3})\s*(?:cm|centimeters?)', user_lower)
        m_match = re.search(r'(\d+)[.,](\d+)\s*(?:m|meters?)', user_lower)
        ft_in_match = re.search(r"(\d+)['\s]*(?:feet?|ft)?['\s]*(\d+)?[\"]*(?:\s*(?:inches?|in))?", user_lower)

        if cm_match:
            height = int(cm_match.group(1))
            if 100 <= height <= 250:
                extracted["heightCm"] = height
                logger.info(f"[Extract Data] ✅ Pre-processed: heightCm = {height}")
        elif m_match:
            meters = float(f"{m_match.group(1)}.{m_match.group(2)}")
            height = int(meters * 100)
            if 100 <= height <= 250:
                extracted["heightCm"] = height
                logger.info(f"[Extract Data] ✅ Pre-processed: heightCm = {height}")
        elif ft_in_match:
            feet = int(ft_in_match.group(1))
            inches = int(ft_in_match.group(2)) if ft_in_match.group(2) else 0
            height = int((feet * 12 + inches) * 2.54)
            if 100 <= height <= 250:
                extracted["heightCm"] = height
                logger.info(f"[Extract Data] ✅ Pre-processed: heightCm = {height}")

    # If missing weight and user provides it
    if "weightKg" in missing:
        import re
        user_lower = user_message.lower()

        # Pattern: "70kg" or "70 kg" or "100.5kg" or "154lbs" or "154 lbs"
        # Supports decimals like "100.0kg" or "100.5kg"
        kg_match = re.search(r'(\d{2,3}(?:\.\d+)?)\s*(?:kg|kilograms?|kilos?)', user_lower)
        lbs_match = re.search(r'(\d{2,3}(?:\.\d+)?)\s*(?:lbs?|pounds?)', user_lower)

        # Also match "weigh X" pattern like "weigh 100.0kg" or "weigh 150"
        weigh_match = re.search(r'weigh\s+(\d{2,3}(?:\.\d+)?)\s*(?:kg|kilograms?|kilos?)?', user_lower)

        if kg_match:
            weight = float(kg_match.group(1))
            if 30 <= weight <= 300:
                extracted["weightKg"] = round(weight, 1)
                logger.info(f"[Extract Data] ✅ Pre-processed: weightKg = {extracted['weightKg']}")
        elif weigh_match:
            weight = float(weigh_match.group(1))
            if 30 <= weight <= 300:
                extracted["weightKg"] = round(weight, 1)
                logger.info(f"[Extract Data] ✅ Pre-processed: weightKg = {extracted['weightKg']} (from 'weigh' pattern)")
        elif lbs_match:
            lbs = int(lbs_match.group(1))
            weight = round(lbs * 0.453592)
            if 30 <= weight <= 300:
                extracted["weightKg"] = weight
                logger.info(f"[Extract Data] ✅ Pre-processed: weightKg = {weight}")

    # If missing days_per_week and user says a number 1-7
    if "days_per_week" in missing:
        if user_message.strip() in ["1", "2", "3", "4", "5", "6", "7"]:
            extracted["days_per_week"] = int(user_message.strip())
            logger.info(f"[Extract Data] ✅ Pre-processed: days_per_week = {extracted['days_per_week']}")
        elif user_message.strip().lower() in ["1 day", "2 days", "3 days", "4 days", "5 days", "6 days", "7 days"]:
            extracted["days_per_week"] = int(user_message.split()[0])
            logger.info(f"[Extract Data] ✅ Pre-processed: days_per_week = {extracted['days_per_week']}")

    # If missing workout_duration and user says a number
    if "workout_duration" in missing:
        if user_message.strip() in ["30", "45", "60", "90"]:
            extracted["workout_duration"] = int(user_message.strip())
            logger.info(f"[Extract Data] ✅ Pre-processed: workout_duration = {extracted['workout_duration']}")
        elif user_message.strip().lower() in ["30 min", "45 min", "60 min", "90 min"]:
            extracted["workout_duration"] = int(user_message.split()[0])
            logger.info(f"[Extract Data] ✅ Pre-processed: workout_duration = {extracted['workout_duration']}")

    # If missing selected_days and user says day names
    if "selected_days" in missing:
        day_name_to_index = {
            'monday': 0, 'tuesday': 1, 'wednesday': 2, 'thursday': 3,
            'friday': 4, 'saturday': 5, 'sunday': 6,
            'mon': 0, 'tue': 1, 'wed': 2, 'thu': 3, 'fri': 4, 'sat': 5, 'sun': 6
        }
        user_lower = user_message.strip().lower()

        # Check for single day or comma-separated days
        selected_indices = []
        for day_name, idx in day_name_to_index.items():
            if day_name in user_lower:
                if idx not in selected_indices:
                    selected_indices.append(idx)

        if selected_indices:
            selected_indices.sort()
            extracted["selected_days"] = selected_indices
            logger.info(f"[Extract Data] ✅ Pre-processed: selected_days = {extracted['selected_days']}")

    # If missing equipment and user sends equipment value
    if "equipment" in missing:
        # Map user input (case-insensitive) to valid equipment values
        equipment_map = {
            'full gym': 'Full Gym',
            'dumbbells': 'Dumbbells',
            'dumbbell': 'Dumbbells',
            'resistance bands': 'Resistance Bands',
            'resistance band': 'Resistance Bands',
            'bands': 'Resistance Bands',
            'bodyweight only': 'Bodyweight Only',
            'bodyweight': 'Bodyweight Only',
            'barbell': 'Barbell',
            'kettlebell': 'Kettlebell',
            'kettlebells': 'Kettlebell',
            'cable machine': 'Cable Machine',
            'cable': 'Cable Machine',
            'pull-up bar': 'Pull-up Bar',
            'pull up bar': 'Pull-up Bar',
            'bench': 'Bench',
        }
        user_lower = user_message.strip().lower()
        matched_equipment = []

        # Check for exact match first
        if user_lower in equipment_map:
            matched_equipment.append(equipment_map[user_lower])
        else:
            # Check for partial matches
            for key, value in equipment_map.items():
                if key in user_lower:
                    if value not in matched_equipment:
                        matched_equipment.append(value)

        if matched_equipment:
            # Merge with existing equipment if any
            existing = collected_data.get("equipment", [])
            merged_equipment = list(set(existing + matched_equipment))
            extracted["equipment"] = merged_equipment
            logger.info(f"[Extract Data] ✅ Pre-processed: equipment = {extracted['equipment']}")

    # If missing goals and user sends goals value
    if "goals" in missing:
        # Map user input (case-insensitive) to valid goal values
        goals_map = {
            'build muscle': 'Build Muscle',
            'muscle': 'Build Muscle',
            'lose weight': 'Lose Weight',
            'weight loss': 'Lose Weight',
            'fat loss': 'Lose Weight',
            'increase strength': 'Increase Strength',
            'get stronger': 'Increase Strength',
            'strength': 'Increase Strength',
            'improve endurance': 'Improve Endurance',
            'endurance': 'Improve Endurance',
            'cardio': 'Improve Endurance',
            'general fitness': 'General Fitness',
            'stay fit': 'General Fitness',
            'stay healthy': 'General Fitness',
            'tone': 'General Fitness',
            'toning': 'General Fitness',
        }

        # Get training program map dynamically from database/cache
        training_program_map = get_training_program_map_sync()

        user_lower = user_message.strip().lower()
        matched_goals = []

        # Check for exact match in goals_map first
        if user_lower in goals_map:
            matched_goals.append(goals_map[user_lower])
        else:
            # Check for partial matches in goals_map
            for key, value in goals_map.items():
                if key in user_lower:
                    if value not in matched_goals:
                        matched_goals.append(value)

        # Also check training program map for specialized programs
        for key, goals_list in training_program_map.items():
            if key in user_lower:
                for goal in goals_list:
                    if goal not in matched_goals:
                        matched_goals.append(goal)

        if matched_goals:
            # Merge with existing goals if any
            existing = collected_data.get("goals", [])
            merged_goals = list(set(existing + matched_goals))
            extracted["goals"] = merged_goals
            logger.info(f"[Extract Data] ✅ Pre-processed: goals = {extracted['goals']}")

    # If missing fitness_level and user sends fitness level value
    if "fitness_level" in missing:
        fitness_level_map = {
            'beginner': 'beginner',
            'newbie': 'beginner',
            'new': 'beginner',
            'intermediate': 'intermediate',
            'medium': 'intermediate',
            'advanced': 'advanced',
            'expert': 'advanced',
            'pro': 'advanced',
        }
        user_lower = user_message.strip().lower()

        if user_lower in fitness_level_map:
            extracted["fitness_level"] = fitness_level_map[user_lower]
            logger.info(f"[Extract Data] ✅ Pre-processed: fitness_level = {extracted['fitness_level']}")

    # If we found data via pre-processing, use it
    if extracted:
        merged = collected_data.copy()
        merged.update(extracted)
        logger.info(f"[Extract Data] 🎯 Pre-processed: {list(extracted.keys())}")

        # Calculate how many fields we still need after pre-processing
        # Use get_field_value helper to check both snake_case and camelCase keys
        remaining_missing = []
        for field in REQUIRED_FIELDS:
            value = get_field_value(merged, field)
            if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
                remaining_missing.append(field)

        # If we extracted most/all expected data from a multi-info message, skip AI
        # Otherwise, let AI try to extract remaining data
        if len(extracted) >= 3 or len(remaining_missing) == 0:
            logger.info(f"[Extract Data] ✅ Pre-processing extracted {len(extracted)} fields, skipping AI")
            return {
                "collected_data": merged,
                "validation_errors": {},
            }
        else:
            # Continue to AI extraction with merged data as base
            collected_data = merged
            logger.info(f"[Extract Data] ℹ️ Pre-processing got {len(extracted)} fields, trying AI for remaining: {remaining_missing}")

    # Continue with AI extraction for complex messages or remaining fields...

    # Build extraction prompt
    extraction_prompt = DATA_EXTRACTION_SYSTEM_PROMPT.format(
        user_message=user_message,
        collected_data=json.dumps(collected_data, indent=2) if collected_data else "{}",
    )

    # Call Gemini for extraction
    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        google_api_key=settings.gemini_api_key,
        temperature=0.3,  # Lower temperature for more consistent extraction
    )

    response = await llm.ainvoke([
        SystemMessage(content="You are a data extraction expert. Extract structured fitness data from user messages."),
        HumanMessage(content=extraction_prompt)
    ])

    # Parse JSON from response
    try:
        # Handle various Gemini response.content formats
        content = response.content
        logger.info(f"[Extract Data] Raw response.content type: {type(content)}")

        if isinstance(content, dict):
            logger.warning(f"[Extract Data] response.content was a dict: {str(content)[:200]}")
            content = content.get("text", str(content))
        elif isinstance(content, list):
            logger.warning(f"[Extract Data] response.content was a list: {str(content)[:200]}")
            parts = []
            for item in content:
                if isinstance(item, dict):
                    parts.append(item.get("text", str(item)))
                else:
                    parts.append(str(item))
            content = " ".join(parts) if parts else ""
        elif not isinstance(content, str):
            logger.warning(f"[Extract Data] response.content was {type(content)}: {content}")
            content = str(content) if content else ""
        content = content.strip()
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()

        extracted = json.loads(content)
        logger.info(f"[Extract Data] 🔍 DEBUG: Extracted from user message: {extracted}")

        # Merge with collected data
        # For lists (goals, equipment), merge instead of replace
        merged = collected_data.copy()
        for key, value in extracted.items():
            if key in ["goals", "equipment", "active_injuries", "health_conditions"]:
                # Merge lists
                existing = merged.get(key, [])
                if isinstance(value, list):
                    merged[key] = list(set(existing + value))  # Remove duplicates
                else:
                    merged[key] = existing + [value]
            else:
                # Replace value
                merged[key] = value

        logger.info(f"[Extract Data] Merged data: {merged}")

        return {
            "collected_data": merged,
            "validation_errors": {},  # TODO: Add validation
        }

    except json.JSONDecodeError as e:
        logger.error(f"[Extract Data] JSON parse error: {e}")
        logger.error(f"[Extract Data] Response was: {response.content}")

        # If extraction fails, just return existing data
        return {
            "collected_data": collected_data,
            "validation_errors": {},
        }


def determine_next_step(state: OnboardingState) -> str:
    """
    Determine what to do next after checking completion.

    Returns:
        - "ask_question" if still missing data
        - "complete" if onboarding is done
    """
    is_complete = state.get("is_complete", False)

    if is_complete:
        logger.info("[Router] Onboarding complete!")
        return "complete"
    else:
        logger.info("[Router] Still need more data, continuing conversation")
        return "ask_question"
