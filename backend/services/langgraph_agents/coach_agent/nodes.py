"""
Node implementations for the Coach Agent.

The coach agent is autonomous - it handles:
1. General fitness questions
2. Motivation and greetings
3. App settings and navigation (via action_data)
"""
from typing import Dict, Any, Literal
from datetime import datetime
import pytz

from .state import CoachAgentState
from ..personality import build_personality_prompt
from models.chat import AISettings, CoachIntent
from services.gemini_service import GeminiService
from core.logger import get_logger

logger = get_logger(__name__)

# Coach expertise base prompt (personality is added dynamically)
COACH_BASE_PROMPT = """You are Coach, a friendly and knowledgeable AI fitness coach. You are the main point of contact for users and handle:
- General fitness questions and advice
- Motivation and encouragement
- App navigation guidance
- Overall wellness tips

PERSONALITY:
- Friendly and approachable
- Motivating but not overbearing
- Knowledgeable about general fitness
- Helpful with app navigation

CAPABILITIES:
1. **General Fitness**: Answer questions about training, rest, recovery
2. **Motivation**: Provide encouragement and support
3. **App Control**: Help users navigate the app and change settings
4. **Wellness**: Tips on sleep, stress, and overall health

WHEN TO DEFER:
If a question is very specific to a domain, you might suggest the user ask:
- @nutrition for detailed dietary advice
- @workout for exercise-specific questions
- @injury for pain/recovery questions
- @hydration for water intake questions

But YOU can still answer general questions in these areas!
"""


def get_coach_system_prompt(ai_settings: Dict[str, Any] = None) -> str:
    """Build the full system prompt with personality customization."""
    settings_obj = AISettings(**ai_settings) if ai_settings else None
    personality = build_personality_prompt(
        ai_settings=settings_obj,
        agent_name="Coach",
        agent_specialty="fitness coaching and wellness guidance"
    )
    return f"{COACH_BASE_PROMPT}\n\n{personality}"


def format_workout_context(schedule: Dict[str, Any]) -> str:
    """Format workout schedule for context."""
    if not schedule:
        return ""

    parts = ["\nWORKOUT OVERVIEW:"]

    def format_date(date_str: str) -> str:
        if not date_str:
            return ""
        if "T" in date_str:
            date_str = date_str.split("T")[0]
        try:
            date_obj = datetime.strptime(date_str, "%Y-%m-%d")
            return date_obj.strftime("%A, %B %d")
        except ValueError:
            return date_str

    today = schedule.get("today")
    if today:
        status = "COMPLETED" if today.get("is_completed") else "scheduled"
        parts.append(f"- Today: {today.get('name', 'Unknown')} ({status})")

    tomorrow = schedule.get("tomorrow")
    if tomorrow:
        parts.append(f"- Tomorrow: {tomorrow.get('name', 'Unknown')}")

    this_week = schedule.get("thisWeek", [])
    completed_count = sum(1 for w in this_week if w.get("is_completed"))
    total_count = len(this_week)
    if total_count > 0:
        parts.append(f"- This week: {completed_count}/{total_count} workouts completed")

    return "\n".join(parts)


def should_handle_action(state: CoachAgentState) -> Literal["action", "respond"]:
    """
    Determine if this is an action request or general question.

    Routes to action if:
    - User wants to change settings
    - User wants to navigate somewhere
    - User wants to start/complete a workout

    Routes to respond for:
    - General questions
    - Greetings
    - Motivation requests
    """
    intent = state.get("intent")

    action_intents = [
        CoachIntent.CHANGE_SETTING,
        CoachIntent.NAVIGATE,
        CoachIntent.START_WORKOUT,
        CoachIntent.COMPLETE_WORKOUT,
    ]

    if intent in action_intents:
        logger.info(f"[Coach Router] Action intent: {intent} -> action")
        return "action"

    # Default: respond with coaching
    logger.info("[Coach Router] General query -> respond")
    return "respond"


async def coach_action_node(state: CoachAgentState) -> Dict[str, Any]:
    """
    Handle app actions (settings, navigation, workout control).
    """
    logger.info("[Coach Action] Processing app action...")

    intent = state.get("intent")
    gemini_service = GeminiService()

    action_data = None
    action_context = None

    if intent == CoachIntent.CHANGE_SETTING:
        setting_name = state.get("setting_name")
        setting_value = state.get("setting_value")
        if setting_name is not None:
            action_data = {
                "action": "change_setting",
                "setting_name": setting_name,
                "setting_value": setting_value,
                "success": True,
            }
            action_context = f"Changed setting '{setting_name}' to {setting_value}"

    elif intent == CoachIntent.NAVIGATE:
        destination = state.get("destination")
        if destination:
            action_data = {
                "action": "navigate",
                "destination": destination,
                "success": True,
            }
            action_context = f"Navigating to {destination}"

    elif intent == CoachIntent.START_WORKOUT:
        workout = state.get("current_workout")
        workout_id = workout.get("id") if workout else None
        action_data = {
            "action": "start_workout",
            "workout_id": workout_id,
            "success": True,
        }
        action_context = f"Starting workout: {workout.get('name') if workout else 'your workout'}"

    elif intent == CoachIntent.COMPLETE_WORKOUT:
        workout = state.get("current_workout")
        workout_id = workout.get("id") if workout else None
        action_data = {
            "action": "complete_workout",
            "workout_id": workout_id,
            "success": True,
        }
        action_context = f"Completing workout: {workout.get('name') if workout else 'your workout'}"

    # Generate a natural response for the action
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User: {profile.get('name', 'User')}")

    if action_context:
        context_parts.append(f"\nACTION: {action_context}")

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_coach_system_prompt(ai_settings)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

You just performed an app action for the user. Acknowledge it naturally and briefly.
Be friendly and helpful!"""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await gemini_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Coach Action] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
        "action_data": action_data,
    }


async def coach_response_node(state: CoachAgentState) -> Dict[str, Any]:
    """
    Handle general coaching responses.
    This is the main autonomous response node.
    """
    logger.info("[Coach Response] Generating coaching response...")

    gemini_service = GeminiService()

    context_parts = []

    # Add current date/time
    pacific = pytz.timezone('America/Los_Angeles')
    now = datetime.now(pacific)
    context_parts.append(f"CURRENT DATE/TIME: {now.strftime('%A, %B %d, %Y at %I:%M %p')} (Pacific Time)")

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"\nUSER PROFILE:")
        context_parts.append(f"- Name: {profile.get('name', 'User')}")
        context_parts.append(f"- Fitness Level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"- Goals: {', '.join(profile.get('goals', []))}")

    if state.get("workout_schedule"):
        context_parts.append(format_workout_context(state["workout_schedule"]))

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_coach_system_prompt(ai_settings)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

Respond to the user's message with friendly, helpful coaching advice.
Be personable, encouraging, and adapt to their fitness level!"""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await gemini_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Coach Response] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
    }
