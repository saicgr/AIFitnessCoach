"""
AI agent node for onboarding.

Contains the node that generates natural, human-like questions for onboarding.
"""

import json
import time
from typing import Dict, Any, Optional, Tuple

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

from ..state import OnboardingState
from ..prompts import ONBOARDING_AGENT_SYSTEM_PROMPT, FIELD_ORDER, QUICK_REPLIES
from .utils import ensure_string, detect_field_from_response
from ...personality import build_personality_prompt
from models.chat import AISettings
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()

# Valid field types that AI can return
VALID_FIELD_TYPES = {
    "workout_duration", "target_weight_kg", "past_programs",
    "focus_areas", "workout_variety", "biggest_obstacle",
    "selected_days", "completion"
}


def parse_ai_response(response_content: str) -> Tuple[str, Optional[str]]:
    """
    Parse AI response to extract question text and field_type.

    The AI should return JSON like:
    {"question": "How long per workout?", "field_type": "workout_duration"}

    Args:
        response_content: Raw response from Gemini

    Returns:
        Tuple of (question_text, field_type)
        If parsing fails, returns (response_content, None)
    """
    try:
        # Try to parse as JSON
        parsed = json.loads(response_content)
        question_text = parsed.get("question", "")
        field_type = parsed.get("field_type")

        # Validate field_type
        if field_type and field_type not in VALID_FIELD_TYPES:
            logger.warning(f"[parse_ai_response] Unknown field_type: {field_type}")
            field_type = None

        if question_text:
            logger.info(f"[parse_ai_response] Parsed JSON - question: {question_text[:50]}..., field_type: {field_type}")
            return question_text, field_type
        else:
            logger.warning("[parse_ai_response] JSON parsed but no question field")
            return response_content, None

    except json.JSONDecodeError as e:
        logger.warning(f"[parse_ai_response] JSON parse failed: {e}, using raw response")
        return response_content, None


async def onboarding_agent_node(state: OnboardingState) -> Dict[str, Any]:
    """
    AI generates natural, human-like questions for onboarding.

    The AI creates conversational responses that feel like a real fitness coach,
    adapting to the user's name and previous answers.

    Args:
        state: The current onboarding state

    Returns:
        Updated state with AI response and quick replies
    """
    start_time = time.time()
    logger.info("=" * 60)
    logger.info("[Onboarding Agent] STARTING AI QUESTION GENERATION")
    logger.info("=" * 60)

    collected = state.get("collected_data", {})
    missing = state.get("missing_fields", [])
    history = state.get("conversation_history", [])
    ai_settings_dict = state.get("ai_settings")

    logger.info(f"[Onboarding Agent] Collected fields: {list(collected.keys())}")
    logger.info(f"[Onboarding Agent] Missing fields: {missing}")
    logger.info(f"[Onboarding Agent] History length: {len(history)}")
    logger.info(f"[Onboarding Agent] AI Settings: {ai_settings_dict is not None}")

    # Ensure user_message is a string
    user_message = ensure_string(state.get("user_message", ""))

    # Build base system prompt with context
    base_system_prompt = ONBOARDING_AGENT_SYSTEM_PROMPT.format(
        collected_data=json.dumps(collected, indent=2) if collected else "{}",
        missing_fields=", ".join(missing) if missing else "Nothing - ready to complete!",
    )

    # Build personality prompt from AI settings
    personality_prompt = ""
    if ai_settings_dict:
        try:
            # Get coach name from settings
            coach_name = ai_settings_dict.get("coach_name", "Coach")

            # Create AISettings model from dict
            ai_settings_model = AISettings(
                coach_persona_id=ai_settings_dict.get("coach_persona_id"),
                coach_name=ai_settings_dict.get("coach_name"),
                coaching_style=ai_settings_dict.get("coaching_style", "motivational"),
                communication_tone=ai_settings_dict.get("communication_tone", "encouraging"),
                encouragement_level=ai_settings_dict.get("encouragement_level", 0.7),
                response_length=ai_settings_dict.get("response_length", "balanced"),
                use_emojis=ai_settings_dict.get("use_emojis", True),
                include_tips=ai_settings_dict.get("include_tips", True),
                form_reminders=ai_settings_dict.get("form_reminders", True),
                rest_day_suggestions=ai_settings_dict.get("rest_day_suggestions", True),
                nutrition_mentions=ai_settings_dict.get("nutrition_mentions", True),
                injury_sensitivity=ai_settings_dict.get("injury_sensitivity", True),
            )

            personality_prompt = build_personality_prompt(
                ai_settings=ai_settings_model,
                agent_name=coach_name if coach_name else "Coach",
                agent_specialty="onboarding and fitness planning"
            )
            logger.info(f"[Onboarding Agent] Applied personality: {ai_settings_dict.get('coaching_style')} + {ai_settings_dict.get('communication_tone')}")
        except Exception as e:
            logger.warning(f"[Onboarding Agent] Could not build personality prompt: {e}")

    # Combine base prompt with personality
    system_prompt = base_system_prompt
    if personality_prompt:
        system_prompt = f"{base_system_prompt}\n\n{personality_prompt}"

    # Log the full prompt for debugging
    logger.info("=" * 60)
    logger.info("[Onboarding Agent] FULL SYSTEM PROMPT:")
    logger.info("=" * 60)
    logger.info(system_prompt)
    logger.info("=" * 60)

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

    # Call LLM to generate next question with retry logic
    # Use JSON mode to get structured output with explicit field_type
    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        google_api_key=settings.gemini_api_key,
        temperature=0.5,
        timeout=60,
        model_kwargs={"response_mime_type": "application/json"},
    )

    # Retry with exponential backoff
    max_retries = 3
    response = None
    last_error = None

    for attempt in range(max_retries):
        try:
            logger.info(f"[Onboarding Agent] Calling Gemini API - attempt {attempt + 1}/{max_retries}...")
            llm_start = time.time()
            response = await llm.ainvoke(messages)
            llm_elapsed = time.time() - llm_start
            logger.info(f"[Onboarding Agent] Gemini API responded in {llm_elapsed:.2f}s")
            break
        except Exception as e:
            last_error = e
            logger.warning(f"[Onboarding Agent] Attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt
                logger.info(f"[Onboarding Agent] Retrying in {wait_time}s...")
                import asyncio
                await asyncio.sleep(wait_time)

    if response is None:
        logger.error(f"[Onboarding Agent] All {max_retries} attempts failed: {last_error}")
        return {
            "messages": messages,
            "next_question": "I'm having a moment - could you repeat that?",
            "final_response": "I'm having a moment - could you repeat that?",
            "quick_replies": None,
            "multi_select": False,
            "component": None,
        }

    # Handle various Gemini response.content formats
    response_content = response.content
    logger.info(f"[Onboarding Agent] Raw response.content type: {type(response_content)}")

    if isinstance(response_content, dict):
        logger.warning(f"[Onboarding Agent] response.content was a dict")
        response_content = response_content.get("text", str(response_content))
    elif isinstance(response_content, list):
        logger.warning(f"[Onboarding Agent] response.content was a list")
        parts = []
        for item in response_content:
            if isinstance(item, dict):
                parts.append(item.get("text", str(item)))
            else:
                parts.append(str(item))
        response_content = " ".join(parts) if parts else ""
    elif not isinstance(response_content, str):
        logger.warning(f"[Onboarding Agent] response.content was {type(response_content)}")
        response_content = str(response_content) if response_content else ""

    logger.info(f"[Onboarding Agent] Raw AI response: {response_content[:200]}...")

    # Parse JSON response to extract question and field_type
    question_text, field_type = parse_ai_response(response_content)
    logger.info(f"[Onboarding Agent] Parsed - question: {question_text[:100]}..., field_type: {field_type}")

    # If JSON parsing failed or field_type is None, fall back to keyword detection
    if field_type is None:
        logger.info("[Onboarding Agent] No field_type from JSON, falling back to keyword detection")
        field_type = detect_field_from_response(question_text)
        logger.info(f"[Onboarding Agent] Keyword detection result: {field_type}")

    # Determine quick replies and component
    quick_replies = None
    component = None

    # Multi-select fields
    multi_select_fields = ["goals", "equipment"]
    is_multi_select = False

    # Free text fields
    free_text_fields = ["name", "age", "gender", "heightCm", "weightKg"]

    # CRITICAL: selected_days check takes priority over everything
    # Even if AI says "building your plan", we still need to collect selected_days
    if "selected_days" in missing and collected.get("days_per_week"):
        component = "day_picker"
        logger.info(f"[Onboarding Agent] selected_days missing - showing day_picker")
    elif field_type == "completion":
        # Completion message - NO quick replies, let user proceed
        logger.info(f"[Onboarding Agent] Completion field_type - no quick replies")
    elif field_type:
        # Use field_type directly to determine quick replies and component
        logger.info(f"[Onboarding Agent] Using field_type: {field_type}")

        if field_type == "selected_days":
            component = "day_picker"
        elif field_type == "target_weight_kg":
            component = "weight_goal_input"
            logger.info(f"[Onboarding Agent] target_weight_kg - showing weight goal input")
        elif field_type in free_text_fields:
            logger.info(f"[Onboarding Agent] Free text field ({field_type})")
        elif field_type in QUICK_REPLIES:
            quick_replies = QUICK_REPLIES[field_type]
            is_multi_select = field_type in multi_select_fields
    else:
        # No field_type detected - check for completion phrases as last resort
        response_lower = question_text.lower()
        completion_phrases = [
            "ready to crush it", "here's what i'm building", "let's do this",
            "you're all set", "we're ready", "i'm building your", "your plan is ready",
            "let's get started", "ready to get started", "got everything i need",
            "i've got everything", "all set to build", "ready to create your",
            "ready to build your", "let's crush it", "building your", "plan now",
        ]
        is_completion_message = any(phrase in response_lower for phrase in completion_phrases)

        if is_completion_message:
            logger.info(f"[Onboarding Agent] Completion phrase detected - no quick replies")
        elif missing:
            # Fallback to first missing field (last resort)
            logger.warning(f"[Onboarding Agent] No field_type, using first missing field as fallback")
            quiz_fields = [
                "goals", "equipment", "fitness_level", "days_per_week",
                "motivation", "workoutDays", "selectedDays", "selected_days",
                "training_experience", "workout_environment"
            ]
            prefilled_quiz_fields = [f for f in quiz_fields if f in collected and collected[f]]
            if collected.get("workoutDays") or collected.get("selectedDays"):
                if "selected_days" not in prefilled_quiz_fields:
                    prefilled_quiz_fields.append("selected_days")

            next_field = None
            for field in FIELD_ORDER:
                if field in missing and field not in prefilled_quiz_fields:
                    next_field = field
                    break

            if next_field:
                logger.info(f"[Onboarding Agent] Fallback to missing field: {next_field}")
                if next_field == "selected_days":
                    component = "day_picker"
                elif next_field == "target_weight_kg":
                    component = "weight_goal_input"
                elif next_field not in free_text_fields and next_field in QUICK_REPLIES:
                    quick_replies = QUICK_REPLIES[next_field]
                    is_multi_select = next_field in multi_select_fields

    total_elapsed = time.time() - start_time
    logger.info("=" * 60)
    logger.info(f"[Onboarding Agent] COMPLETED in {total_elapsed:.2f}s")
    logger.info(f"[Onboarding Agent] Question: {question_text[:100]}...")
    logger.info(f"[Onboarding Agent] Field type: {field_type}")
    logger.info(f"[Onboarding Agent] Quick replies: {quick_replies is not None}")
    logger.info(f"[Onboarding Agent] Component: {component}")
    logger.info("=" * 60)

    return {
        "messages": messages + [response],
        "next_question": question_text,
        "final_response": question_text,
        "quick_replies": quick_replies,
        "multi_select": is_multi_select,
        "component": component,
    }
