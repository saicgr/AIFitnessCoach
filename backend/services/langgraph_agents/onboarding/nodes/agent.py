"""
AI agent node for onboarding.

Contains the node that generates natural, human-like questions for onboarding.
"""

import json
import time
from typing import Dict, Any

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
    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        google_api_key=settings.gemini_api_key,
        temperature=0.5,
        timeout=60,
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

    logger.info(f"[Onboarding Agent] AI question: {response_content[:100]}...")

    # Determine quick replies and component
    quick_replies = None
    component = None

    # Multi-select fields
    multi_select_fields = ["goals", "equipment"]
    is_multi_select = False

    # Free text fields
    free_text_fields = ["name", "age", "gender", "heightCm", "weightKg"]

    # Quiz fields that may be pre-filled
    quiz_fields = [
        "goals", "equipment", "fitness_level", "days_per_week",
        "motivation", "workoutDays", "training_experience", "workout_environment"
    ]
    prefilled_quiz_fields = [f for f in quiz_fields if f in collected and collected[f]]
    logger.info(f"[Onboarding Agent] Pre-filled quiz fields: {prefilled_quiz_fields}")

    # Check for completion message
    response_lower = response_content.lower()
    completion_phrases = [
        "ready to crush it", "here's what i'm building", "let's do this",
        "you're all set", "we're ready", "i'm building your", "your plan is ready",
        "let's get started", "ready to get started", "got everything i need",
        "i've got everything", "all set to build", "ready to create your",
        "ready to build your", "let's crush it", "building your", "plan now",
    ]
    is_completion_message = any(phrase in response_lower for phrase in completion_phrases)

    # CRITICAL: selected_days check takes priority over completion message
    # Even if AI says "building your plan", we still need to collect selected_days
    if "selected_days" in missing and collected.get("days_per_week"):
        component = "day_picker"
        logger.info(f"[Onboarding Agent] selected_days missing - showing day_picker")
    elif is_completion_message:
        # Completion message detected - NO quick replies, let user proceed
        logger.info(f"[Onboarding Agent] Completion message detected - no quick replies (missing: {missing})")
    else:
        # Detect field from AI response
        detected_field = detect_field_from_response(response_content)

        if detected_field:
            logger.info(f"[Onboarding Agent] Detected field: {detected_field}")

            if detected_field == "selected_days":
                component = "day_picker"
            elif detected_field == "target_weight_kg":
                component = "weight_goal_input"
                logger.info(f"[Onboarding Agent] target_weight_kg - showing weight goal input")
            elif detected_field in free_text_fields:
                logger.info(f"[Onboarding Agent] Free text field ({detected_field})")
            elif detected_field in QUICK_REPLIES:
                quick_replies = QUICK_REPLIES[detected_field]
                is_multi_select = detected_field in multi_select_fields
        elif missing:
            # Fallback to first non-prefilled missing field
            next_field = None
            for field in FIELD_ORDER:
                if field in missing and field not in prefilled_quiz_fields:
                    next_field = field
                    break

            if not next_field:
                for field in missing:
                    if field not in prefilled_quiz_fields:
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
    logger.info(f"[Onboarding Agent] Quick replies: {quick_replies is not None}")
    logger.info(f"[Onboarding Agent] Component: {component}")
    logger.info("=" * 60)

    return {
        "messages": messages + [response],
        "next_question": response_content,
        "final_response": response_content,
        "quick_replies": quick_replies,
        "multi_select": is_multi_select,
        "component": component,
    }
