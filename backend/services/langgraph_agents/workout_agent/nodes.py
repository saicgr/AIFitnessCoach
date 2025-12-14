"""
Node implementations for the Workout Agent.

The workout agent can:
1. Use tools (add/remove exercises, modify intensity, reschedule)
2. Respond autonomously with exercise advice without tools
"""
import json
from typing import Dict, Any, Literal
from datetime import datetime

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, ToolMessage

from .state import WorkoutAgentState
from ..tools import (
    add_exercise_to_workout,
    remove_exercise_from_workout,
    replace_all_exercises,
    modify_workout_intensity,
    reschedule_workout,
    delete_workout,
)
from services.openai_service import OpenAIService
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()

# Workout agent tools
WORKOUT_TOOLS = [
    add_exercise_to_workout,
    remove_exercise_from_workout,
    replace_all_exercises,
    modify_workout_intensity,
    reschedule_workout,
    delete_workout,
]

# Workout expertise system prompt
WORKOUT_SYSTEM_PROMPT = """You are Flex, an expert AI personal trainer and workout coach. You specialize in:
- Creating and modifying workout plans
- Explaining proper exercise form and technique
- Providing exercise alternatives and progressions
- Helping users schedule and organize their training
- Motivating and pushing users to reach their potential

PERSONALITY:
- Energetic and motivating
- Knowledgeable about exercise science
- Safety-conscious - always emphasize proper form
- Adaptable - adjusts recommendations based on user level

CAPABILITIES:
1. **With Tools**: Modify workouts, add/remove exercises, change intensity, reschedule
2. **Without Tools**: Explain exercises, suggest progressions, answer form questions, provide workout advice

When you DON'T need tools:
- "How do I do a proper squat?"
- "What muscles does bench press work?"
- "What's a good replacement for pull-ups?"
- "Should I train legs twice a week?"
- "What's the difference between strength and hypertrophy training?"

When you DO need tools:
- "Add squats to my workout"
- "Remove bench press"
- "Make my workout harder"
- "Move tomorrow's workout to Friday"
- "Change this to a back workout"
"""


def format_workout_schedule_context(schedule: Dict[str, Any]) -> str:
    """Format workout schedule for AI context with workout IDs."""
    if not schedule:
        return ""

    parts = ["\nWORKOUT SCHEDULE (use these workout_ids when modifying):"]

    def format_date_with_day(date_str: str) -> str:
        if not date_str:
            return ""
        if "T" in date_str:
            date_str = date_str.split("T")[0]
        try:
            date_obj = datetime.strptime(date_str, "%Y-%m-%d")
            day_name = date_obj.strftime("%A")
            return f"{day_name}, {date_str}"
        except ValueError:
            return date_str

    def format_workout(w: Dict[str, Any], label: str) -> str:
        if not w:
            return f"- {label}: No workout scheduled"
        exercises = w.get("exercises", [])
        exercise_count = len(exercises)
        exercise_names = [e.get("name", "Unknown") for e in exercises[:3]]
        status = "COMPLETED" if w.get("is_completed") else "scheduled"
        workout_id = w.get("id", "N/A")
        scheduled_date = w.get("scheduled_date", "")
        date_display = format_date_with_day(scheduled_date)
        return f"- {label} ({date_display}) (ID: {workout_id}): \"{w.get('name', 'Unknown')}\" - {exercise_count} exercises ({', '.join(exercise_names)}) - {status}"

    parts.append(format_workout(schedule.get("yesterday"), "Yesterday"))
    parts.append(format_workout(schedule.get("today"), "Today"))
    parts.append(format_workout(schedule.get("tomorrow"), "Tomorrow"))

    this_week = schedule.get("thisWeek", [])
    if this_week:
        parts.append("\nTHIS WEEK'S WORKOUTS:")
        for w in this_week:
            scheduled = w.get("scheduled_date", "")
            formatted_date = format_date_with_day(scheduled)
            status = "COMPLETED" if w.get("is_completed") else "scheduled"
            parts.append(f"  - ID {w.get('id')}: \"{w.get('name', 'Unknown')}\" on {formatted_date} ({status})")

    return "\n".join(parts)


def should_use_tools(state: WorkoutAgentState) -> Literal["agent", "respond"]:
    """
    Determine if we should use tools or respond autonomously.

    Routes to tools if:
    - There's a workout context AND user wants modifications
    - User explicitly asks to change/add/remove something

    Routes to autonomous response for:
    - Exercise questions
    - Form advice
    - General workout guidance
    """
    has_workout = state.get("current_workout") is not None
    intent = state.get("intent")
    message = state.get("user_message", "").lower()

    # Modification keywords that require tools
    modification_keywords = [
        "add ", "remove ", "delete ", "change ", "make it ", "swap ",
        "replace ", "move ", "reschedule", "skip ", "cancel",
        "easier", "harder", "shorter", "longer", "to a ", "into a "
    ]

    for keyword in modification_keywords:
        if keyword in message:
            if has_workout or "workout" in message:
                logger.info(f"[Workout Router] Modification keyword: {keyword} -> agent")
                return "agent"

    # If there's no workout context, we likely can't modify anything
    if not has_workout and any(kw in message for kw in modification_keywords):
        logger.info("[Workout Router] Modification requested but no workout -> respond (explain)")
        return "respond"

    # Default: autonomous response for questions/advice
    logger.info("[Workout Router] General workout query -> respond (no tools)")
    return "respond"


async def workout_agent_node(state: WorkoutAgentState) -> Dict[str, Any]:
    """
    The workout agent node with bound tools.
    Uses LLM to decide which tools to call.
    """
    logger.info("[Workout Agent] Processing with tools...")

    # Get workout context
    workout = state.get("current_workout") or {}
    workout_id = workout.get("id")
    exercises = workout.get("exercises", []) or []
    exercise_names = [e.get("name", "Unknown") for e in exercises]

    # Build context
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"User goals: {', '.join(profile.get('goals', []))}")
        if profile.get("active_injuries"):
            context_parts.append(f"User injuries: {', '.join(profile['active_injuries'])}")

    context_parts.append(f"\nCurrent workout ID: {workout_id}")
    context_parts.append(f"Current workout name: {workout.get('name', 'Unknown')}")
    context_parts.append(f"Current exercises: {', '.join(exercise_names)}")

    if state.get("workout_schedule"):
        context_parts.append(format_workout_schedule_context(state["workout_schedule"]))

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    # Create LLM with workout tools bound
    llm = ChatOpenAI(
        model=settings.openai_model,
        api_key=settings.openai_api_key,
        temperature=0.7,
    )
    llm_with_tools = llm.bind_tools(WORKOUT_TOOLS)

    # Build system message
    tool_prompt = f"""{WORKOUT_SYSTEM_PROMPT}

CONTEXT:
{context}

AVAILABLE TOOLS:
- add_exercise_to_workout(workout_id, exercise_names) - Add exercises to a workout
- remove_exercise_from_workout(workout_id, exercise_names) - Remove exercises from a workout
- replace_all_exercises(workout_id, muscle_group, num_exercises) - Replace ALL exercises with new ones targeting a muscle group
- modify_workout_intensity(workout_id, modification) - Change intensity (easier/harder/shorter/longer)
- reschedule_workout(workout_id, new_date, reason) - Move workout to a different date
- delete_workout(workout_id, reason) - Delete/cancel a workout

CRITICAL: When modifying workouts, use the correct workout_id from the schedule above.
Default to today's workout (ID: {workout_id}) if not specified.

Be energetic, motivating, and explain what changes you're making!"""

    system_message = SystemMessage(content=tool_prompt)

    # Include conversation history
    messages = [system_message]
    for msg in state.get("conversation_history", []):
        if msg.get("role") == "user":
            messages.append(HumanMessage(content=msg["content"]))
        elif msg.get("role") == "assistant":
            messages.append(AIMessage(content=msg["content"]))

    messages.append(HumanMessage(content=state["user_message"]))

    # Call LLM
    response = await llm_with_tools.ainvoke(messages)

    logger.info(f"[Workout Agent] LLM response type: {type(response)}")

    if hasattr(response, 'tool_calls') and response.tool_calls:
        logger.info(f"[Workout Agent] Calling {len(response.tool_calls)} tools")
        for tc in response.tool_calls:
            logger.info(f"[Workout Agent] Tool: {tc['name']}")

        return {
            "messages": messages + [response],
            "tool_calls": response.tool_calls,
            "ai_response": response.content or "",
        }
    else:
        logger.info("[Workout Agent] No tools needed")
        return {
            "messages": messages + [response],
            "tool_calls": [],
            "ai_response": response.content or "",
            "final_response": response.content or "",
        }


async def workout_tool_executor_node(state: WorkoutAgentState) -> Dict[str, Any]:
    """Execute the workout tools that the LLM decided to call."""
    logger.info("[Workout Tool Executor] Executing tools...")

    tool_calls = state.get("tool_calls", [])
    tool_results = []
    tool_messages = []

    # Get current workout info for fallback
    current_workout = state.get("current_workout", {})
    current_workout_id = current_workout.get("id") if current_workout else None

    # Build valid workout IDs from schedule
    valid_workout_ids = set()
    if current_workout_id:
        valid_workout_ids.add(current_workout_id)
    schedule = state.get("workout_schedule") or {}
    for key in ["yesterday", "today", "tomorrow"]:
        w = schedule.get(key)
        if w and w.get("id"):
            valid_workout_ids.add(w.get("id"))
    for w in schedule.get("thisWeek", []) or []:
        if w and w.get("id"):
            valid_workout_ids.add(w.get("id"))

    tools_map = {tool.name: tool for tool in WORKOUT_TOOLS}

    for tool_call in tool_calls:
        tool_name = tool_call.get("name")
        tool_args = tool_call.get("args", {}).copy()
        tool_id = tool_call.get("id", tool_name)

        # Validate/inject workout_id
        if "workout_id" in tool_args:
            ai_workout_id = tool_args["workout_id"]
            if ai_workout_id not in valid_workout_ids and current_workout_id:
                logger.warning(f"[Workout Tool Executor] Invalid workout_id {ai_workout_id}, using {current_workout_id}")
                tool_args["workout_id"] = current_workout_id
        elif current_workout_id:
            tool_args["workout_id"] = current_workout_id

        if tool_name in tools_map:
            logger.info(f"[Workout Tool Executor] Running: {tool_name} with args: {tool_args}")
            try:
                tool_fn = tools_map[tool_name]
                result = tool_fn.invoke(tool_args)
                tool_results.append(result)

                tool_messages.append(ToolMessage(
                    content=json.dumps(result),
                    tool_call_id=tool_id,
                ))

                logger.info(f"[Workout Tool Executor] Result: {result.get('message', 'Done')}")
            except Exception as e:
                logger.error(f"[Workout Tool Executor] Error: {e}")
                error_result = {"success": False, "error": str(e)}
                tool_results.append(error_result)
                tool_messages.append(ToolMessage(
                    content=json.dumps(error_result),
                    tool_call_id=tool_id,
                ))
        else:
            logger.warning(f"[Workout Tool Executor] Unknown tool: {tool_name}")

    return {
        "tool_results": tool_results,
        "tool_messages": tool_messages,
    }


async def workout_response_node(state: WorkoutAgentState) -> Dict[str, Any]:
    """Generate final response after tools have been executed."""
    logger.info("[Workout Response] Generating final response...")

    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User: {profile.get('name', 'User')}")
        context_parts.append(f"Fitness Level: {profile.get('fitness_level', 'beginner')}")

    if state.get("current_workout"):
        workout = state["current_workout"]
        context_parts.append(f"\nWorkout: {workout.get('name', 'Current Workout')}")

    if state.get("tool_results"):
        context_parts.append("\nACTIONS COMPLETED:")
        for result in state.get("tool_results", []):
            if isinstance(result, dict) and result.get("success"):
                action = result.get("action", "modification")
                context_parts.append(f"- Successfully {action}")
                if "exercises_added" in result:
                    context_parts.append(f"  Added: {', '.join(result['exercises_added'])}")
                if "exercises_removed" in result:
                    context_parts.append(f"  Removed: {', '.join(result['exercises_removed'])}")

    context = "\n".join(context_parts)

    system_prompt = f"""{WORKOUT_SYSTEM_PROMPT}

CONTEXT:
{context}

IMPORTANT:
- The workout modifications have been completed successfully
- Respond naturally as an energetic personal trainer
- Explain what was changed and WHY it helps
- Be motivating and encouraging
- NEVER mention tool names or technical details"""

    messages = state.get("messages", [])
    tool_messages = state.get("tool_messages", [])

    messages_with_system = [SystemMessage(content=system_prompt)] + messages + tool_messages

    llm = ChatOpenAI(
        model=settings.openai_model,
        api_key=settings.openai_api_key,
        temperature=0.7,
    )

    response = await llm.ainvoke(messages_with_system)

    logger.info(f"[Workout Response] Final: {response.content[:100]}...")

    return {
        "ai_response": response.content,
        "final_response": response.content,
    }


async def workout_autonomous_node(state: WorkoutAgentState) -> Dict[str, Any]:
    """
    Generate response WITHOUT tools for general workout questions.
    This is the autonomous reasoning capability.
    """
    logger.info("[Workout Autonomous] Generating response without tools...")

    openai_service = OpenAIService()

    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"User goals: {', '.join(profile.get('goals', []))}")
        if profile.get("active_injuries"):
            context_parts.append(f"User injuries: {', '.join(profile['active_injuries'])}")

    if state.get("current_workout"):
        workout = state["current_workout"]
        exercises = workout.get("exercises", [])
        exercise_names = [e.get("name", "Unknown") for e in exercises]
        context_parts.append(f"\nCurrent workout: {workout.get('name', 'Unknown')}")
        context_parts.append(f"Exercises: {', '.join(exercise_names)}")

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    system_prompt = f"""{WORKOUT_SYSTEM_PROMPT}

CONTEXT:
{context}

You are responding to a general workout/exercise question. Provide expert advice about:
- Exercise form and technique
- Training principles
- Workout structure and programming
- Exercise alternatives and progressions

Be energetic, motivating, and safety-conscious!"""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await openai_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Workout Autonomous] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
    }


async def workout_action_data_node(state: WorkoutAgentState) -> Dict[str, Any]:
    """Build action_data for the frontend based on tool results."""
    tool_results = state.get("tool_results", [])
    action_data = None

    for result in tool_results:
        action = result.get("action")
        workout_id = result.get("workout_id")

        if action == "add_exercise":
            action_data = {
                "action": "add_exercise",
                "workout_id": workout_id,
                "exercise_names": result.get("exercises_added", []),
            }
        elif action == "remove_exercise":
            action_data = {
                "action": "remove_exercise",
                "workout_id": workout_id,
                "exercise_names": result.get("exercises_removed", []),
            }
        elif action == "replace_all_exercises":
            action_data = {
                "action": "replace_all_exercises",
                "workout_id": workout_id,
                "muscle_group": result.get("muscle_group"),
                "exercises_added": result.get("exercises_added", []),
                "exercises_removed": result.get("exercises_removed", []),
            }
        elif action == "modify_intensity":
            action_data = {
                "action": "modify_intensity",
                "workout_id": workout_id,
                "modification": result.get("modification"),
            }
        elif action == "reschedule":
            action_data = {
                "action": "reschedule",
                "workout_id": workout_id,
                "old_date": result.get("old_date"),
                "new_date": result.get("new_date"),
                "swapped_with": result.get("swapped_with"),
            }
        elif action == "delete_workout":
            action_data = {
                "action": "delete_workout",
                "workout_id": workout_id,
                "workout_name": result.get("workout_name"),
                "scheduled_date": result.get("scheduled_date"),
            }

    return {"action_data": action_data}


def check_for_tool_calls(state: WorkoutAgentState) -> str:
    """After agent node, check if tools were called."""
    tool_calls = state.get("tool_calls", [])
    if tool_calls:
        return "execute_tools"
    else:
        return "finalize"
