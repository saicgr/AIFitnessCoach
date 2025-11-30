"""
Node implementations for the Onboarding LangGraph agent.

AI-driven onboarding - no hardcoded questions!
"""
import json
from typing import Dict, Any

from langchain_openai import ChatOpenAI
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

logger = get_logger(__name__)
settings = get_settings()


async def check_completion_node(state: OnboardingState) -> Dict[str, Any]:
    """
    Check if onboarding is complete by examining collected data.

    Returns:
        - is_complete: True if all required fields are collected
        - missing_fields: List of fields still needed
    """
    logger.info("[Check Completion] Checking if onboarding is complete...")

    collected = state.get("collected_data", {})
    missing = []

    for field in REQUIRED_FIELDS:
        value = collected.get(field)
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
    messages.append(HumanMessage(content=state["user_message"]))

    # Call LLM to generate next question
    llm = ChatOpenAI(
        model="gpt-4-turbo",  # Use GPT-4 for better conversation quality
        api_key=settings.openai_api_key,
        temperature=0.8,  # Slightly higher for more natural conversation
    )

    response = await llm.ainvoke(messages)

    logger.info(f"[Onboarding Agent] AI question: {response.content[:100]}...")

    # Determine if we should show quick replies
    quick_replies = None
    component = None

    # Smart detection: analyze what the AI is actually asking about
    question_lower = response.content.lower()

    # Check if AI is asking about specific days (not just "how many days")
    is_asking_specific_days = any(keyword in question_lower for keyword in [
        "which days", "what days", "which day", "select days", "choose days",
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
    is_asking_equipment = any(keyword in question_lower for keyword in [
        "equipment", "gym", "access to", "have available", "tools", "machines"
    ])

    # Check if AI is asking about goals
    is_asking_goals = any(keyword in question_lower for keyword in [
        "goal", "goals", "looking to", "want to achieve", "fitness objective"
    ])

    # Check if AI is asking about fitness level
    is_asking_fitness_level = any(keyword in question_lower for keyword in [
        "fitness level", "experience", "describe your fitness", "how fit", "beginner", "intermediate", "advanced"
    ])

    # Check if AI is giving a completion/wrap-up message
    is_completion_message = any(keyword in question_lower for keyword in [
        "get started", "let's go", "ready to", "put together a plan", "create your plan",
        "fitness journey", "all set", "got everything", "thanks for sharing"
    ])

    # Multi-select fields (lists that allow multiple selections)
    multi_select_fields = ["goals", "equipment"]
    is_multi_select = False

    # Smart quick reply detection based on missing fields and question content
    # Sort missing fields by FIELD_ORDER to ensure we ask questions in the correct sequence
    if missing:
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

        # PRIORITY 0: If AI sent a completion-like message, don't show any quick replies
        # This prevents showing wrong quick replies when AI thinks it's done
        if is_completion_message:
            logger.info(f"[Onboarding Agent] ⚠️ AI sent completion message but still missing fields: {missing} - no quick replies")
            # Don't set any quick_replies - let the frontend handle the completion flow

        # PRIORITY 1: If AI is asking about specific days and we have days_per_week, show day picker
        elif is_asking_specific_days and "selected_days" in missing and "days_per_week" not in missing:
            component = "day_picker"
            days_count = collected.get("days_per_week", 3)
            logger.info(f"[Onboarding Agent] ✅ Triggering day picker component for {days_count} days")

        # PRIORITY 2: If AI is asking about specific days but we don't have days_per_week yet,
        # don't show any quick replies - let the AI handle it conversationally
        elif is_asking_specific_days:
            logger.info(f"[Onboarding Agent] ⚠️ AI asking about specific days but days_per_week not collected yet - no quick replies")

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

        # PRIORITY 4: Fall back to next_field from FIELD_ORDER
        elif next_field in QUICK_REPLIES:
            quick_replies = QUICK_REPLIES[next_field]
            is_multi_select = next_field in multi_select_fields
            logger.info(f"[Onboarding Agent] ✅ Adding quick replies for: {next_field} (from FIELD_ORDER, multi_select={is_multi_select})")

    return {
        "messages": messages + [response],
        "next_question": response.content,
        "final_response": response.content,
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

    user_message = state["user_message"]
    collected_data = state.get("collected_data", {})
    missing = state.get("missing_fields", [])

    # PRE-PROCESSING: Handle common simple patterns before AI extraction
    extracted = {}

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

    # If we found simple patterns, skip AI extraction for those fields
    if extracted:
        merged = collected_data.copy()
        merged.update(extracted)
        logger.info(f"[Extract Data] 🎯 Used pre-processing, skipping AI for simple numeric response")
        return {
            "collected_data": merged,
            "validation_errors": {},
        }

    # Otherwise, continue with AI extraction as normal...

    # Build extraction prompt
    extraction_prompt = DATA_EXTRACTION_SYSTEM_PROMPT.format(
        user_message=user_message,
        collected_data=json.dumps(collected_data, indent=2) if collected_data else "{}",
    )

    # Call GPT-4 for extraction
    llm = ChatOpenAI(
        model="gpt-4-turbo",
        api_key=settings.openai_api_key,
        temperature=0.3,  # Lower temperature for more consistent extraction
    )

    response = await llm.ainvoke([
        SystemMessage(content="You are a data extraction expert. Extract structured fitness data from user messages."),
        HumanMessage(content=extraction_prompt)
    ])

    # Parse JSON from response
    try:
        # Clean response - remove markdown code blocks if present
        content = response.content.strip()
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
