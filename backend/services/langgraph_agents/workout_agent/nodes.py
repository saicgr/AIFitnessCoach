"""
Node implementations for the Workout Agent.

The workout agent can:
1. Use tools (add/remove exercises, modify intensity, reschedule)
2. Respond autonomously with exercise advice without tools
"""
import json
from typing import Dict, Any, Literal
from datetime import datetime

from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, ToolMessage

from core.gemini_client import get_langchain_llm
from .state import WorkoutAgentState
from ..tools import (
    add_exercise_to_workout,
    remove_exercise_from_workout,
    replace_all_exercises,
    modify_workout_intensity,
    reschedule_workout,
    delete_workout,
    generate_quick_workout,
    check_exercise_form,
    compare_exercise_form,
)
from ..personality import build_personality_prompt, sanitize_coach_name
from models.chat import AISettings
from services.gemini_service import GeminiService
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
    generate_quick_workout,
    check_exercise_form,
    compare_exercise_form,
]

# Workout expertise base prompt template (coach name is inserted dynamically)
WORKOUT_BASE_PROMPT_TEMPLATE = """You are {coach_name}, an expert AI personal trainer and workout coach. You specialize in:
- Creating and modifying workout plans
- Explaining proper exercise form and technique
- Analyzing exercise form from video/image uploads
- Comparing form across multiple videos to track progression
- Providing exercise alternatives and progressions
- Helping users schedule and organize their training
- Motivating and pushing users to reach their potential

CAPABILITIES:
1. **With Tools**: Modify workouts, add/remove exercises, change intensity, reschedule
2. **Form Analysis**: Analyze uploaded video/image of exercises to check form, count reps, and provide corrections
3. **Form Comparison**: Compare form across multiple videos to track improvements or fatigue
4. **Without Tools**: Explain exercises, suggest progressions, answer form questions, provide workout advice

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
- User sends a video/image -> Use check_exercise_form to analyze
- User sends multiple videos -> Use compare_exercise_form to compare
"""


def get_workout_system_prompt(ai_settings: Dict[str, Any] = None) -> str:
    """Build the full system prompt with personality customization."""
    settings_obj = AISettings(**ai_settings) if ai_settings else None

    # Get the coach name from settings or use default (sanitized)
    coach_name = sanitize_coach_name(settings_obj.coach_name, default="Flex") if settings_obj and settings_obj.coach_name else "Flex"

    # Build the base prompt with the coach name
    base_prompt = WORKOUT_BASE_PROMPT_TEMPLATE.format(coach_name=coach_name)

    personality = build_personality_prompt(
        ai_settings=settings_obj,
        agent_name="Flex",  # Fallback agent name if coach_name not set
        agent_specialty="personal training and workout coaching"
    )
    return f"{base_prompt}\n\n{personality}"


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

    SIMPLE: Always give the LLM access to tools. Let the AI decide.
    The LLM is smart enough to know when to modify workouts vs just answer questions.
    """
    # If media is attached, always route to agent for form analysis tool
    if state.get("media_ref"):
        logger.info("[Workout Router] -> agent (media attached, form analysis)")
        return "agent"

    # If multiple media refs attached, always route to agent for comparison
    if state.get("media_refs"):
        media_refs = state["media_refs"]
        video_refs = [r for r in media_refs if r.get("media_type") == "video"]
        if len(video_refs) > 1:
            logger.info("[Workout Router] -> agent (multi-video, form comparison)")
            return "agent"

    # Always route to agent - let the LLM decide whether to use tools
    logger.info("[Workout Router] -> agent (LLM decides)")
    return "agent"


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

    # Get user_id from profile or state
    user_id = None
    if state.get("user_profile"):
        profile = state["user_profile"]
        user_id = profile.get("id")
        context_parts.append(f"User ID: {user_id}")
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"User goals: {', '.join(profile.get('goals', []))}")
        if profile.get("active_injuries"):
            context_parts.append(f"User injuries: {', '.join(profile['active_injuries'])}")

    if workout_id:
        context_parts.append(f"\nCurrent workout ID: {workout_id}")
        context_parts.append(f"Current workout name: {workout.get('name', 'Unknown')}")
        context_parts.append(f"Current exercises: {', '.join(exercise_names)}")
    else:
        context_parts.append("\nNo workout scheduled for today - a new one can be created.")

    if state.get("workout_schedule"):
        context_parts.append(format_workout_schedule_context(state["workout_schedule"]))

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    # Media context for form analysis (single media)
    media_ref = state.get("media_ref")
    if media_ref:
        media_type = media_ref.get("media_type", "media")
        context_parts.append(f"\nHAS_MEDIA: The user has uploaded a {media_type} for form analysis.")
        context_parts.append(f"S3 key: {media_ref.get('s3_key')}")
        context_parts.append(f"MIME type: {media_ref.get('mime_type')}")
        context_parts.append(f"Media type: {media_type}")
        if media_ref.get("duration_seconds"):
            context_parts.append(f"Duration: {media_ref['duration_seconds']:.1f}s")
        context_parts.append("You MUST call check_exercise_form to analyze their form.")

    # Multi-media context for form comparison
    media_refs = state.get("media_refs")
    has_multi_videos = False
    if media_refs:
        video_refs = [r for r in media_refs if r.get("media_type") == "video"]
        if len(video_refs) > 1:
            has_multi_videos = True
            context_parts.append(f"\nHAS_MULTI_VIDEOS: The user has uploaded {len(video_refs)} videos for form comparison.")
            for i, vref in enumerate(video_refs):
                dur = f" ({vref['duration_seconds']:.1f}s)" if vref.get("duration_seconds") else ""
                context_parts.append(f"  Video {i+1}: s3_key={vref.get('s3_key')}, mime={vref.get('mime_type')}{dur}")
            context_parts.append("You MUST call compare_exercise_form to compare their form across videos.")

    # Beast mode configuration
    beast_config = state.get("beast_mode_config")
    if beast_config and beast_config.get("enabled"):
        beast_parts = ["\nBEAST MODE ACTIVE - User's custom training preferences:"]
        if beast_config.get("target_sets"):
            beast_parts.append(f"- Target sets per exercise: {beast_config['target_sets']}")
        if beast_config.get("target_reps"):
            beast_parts.append(f"- Target reps per set: {beast_config['target_reps']}")
        if beast_config.get("rest_seconds"):
            beast_parts.append(f"- Rest between sets: {beast_config['rest_seconds']}s")
        if beast_config.get("intensity_level"):
            beast_parts.append(f"- Intensity level: {beast_config['intensity_level']}")
        if beast_config.get("preferred_exercises"):
            beast_parts.append(f"- Preferred exercises: {', '.join(beast_config['preferred_exercises'])}")
        if beast_config.get("avoided_exercises"):
            beast_parts.append(f"- Avoided exercises: {', '.join(beast_config['avoided_exercises'])}")
        if beast_config.get("notes"):
            beast_parts.append(f"- Notes: {beast_config['notes']}")
        beast_parts.append("Apply these preferences when creating or modifying workouts.")
        context_parts.extend(beast_parts)

    context = "\n".join(context_parts)

    # Detect if this is a workout CREATION request (not just a question)
    message_lower = state["user_message"].lower()

    # Check for duration + exercise/workout/training pattern
    has_duration = "minute" in message_lower or "min " in message_lower or "min." in message_lower
    has_workout_word = "exercise" in message_lower or "workout" in message_lower or "training" in message_lower

    # Check for creation phrases
    creation_phrases = ["give me", "create", "generate", "make me", "build me", "i want", "i need", "can you"]
    has_creation_phrase = any(phrase in message_lower for phrase in creation_phrases)

    is_workout_creation = (has_duration and has_workout_word) or (has_creation_phrase and has_workout_word)

    logger.info(f"[Workout Agent] Message: {message_lower[:100]}...")
    logger.info(f"[Workout Agent] has_duration={has_duration}, has_workout_word={has_workout_word}, has_creation_phrase={has_creation_phrase}")
    logger.info(f"[Workout Agent] is_workout_creation={is_workout_creation}")

    # Create LLM with workout tools bound
    llm = get_langchain_llm(temperature=0.7)

    # Force tool choice based on context
    if media_ref:
        # Single media attached -> force form analysis
        llm_with_tools = llm.bind_tools(
            WORKOUT_TOOLS,
            tool_choice="check_exercise_form"
        )
    elif has_multi_videos:
        # Multiple videos attached -> force form comparison
        llm_with_tools = llm.bind_tools(
            WORKOUT_TOOLS,
            tool_choice="compare_exercise_form"
        )
    elif is_workout_creation:
        llm_with_tools = llm.bind_tools(
            WORKOUT_TOOLS,
            tool_choice="generate_quick_workout"
        )
    else:
        llm_with_tools = llm.bind_tools(WORKOUT_TOOLS)

    # Build system message
    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_workout_system_prompt(ai_settings)

    tool_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

AVAILABLE TOOLS:
- add_exercise_to_workout(workout_id, exercise_names) - Add exercises to a workout
- remove_exercise_from_workout(workout_id, exercise_names) - Remove exercises from a workout
- replace_all_exercises(workout_id, muscle_group, num_exercises) - Replace ALL exercises with new ones targeting a muscle group
- modify_workout_intensity(workout_id, modification) - Change intensity (easier/harder/shorter/longer)
- reschedule_workout(workout_id, new_date, reason) - Move workout to a different date
- delete_workout(workout_id, reason) - Delete/cancel a workout
- generate_quick_workout(user_id, workout_id, duration_minutes, workout_type, intensity) - Generate a quick workout. ALWAYS pass user_id. If no workout exists, omit workout_id to create a new one.
  workout_type options: "full_body", "upper", "lower", "cardio", "core", "boxing", "hyrox", "crossfit", "martial_arts", "hiit", "strength", "endurance", "flexibility", "mobility", "cricket", "football", "basketball", "tennis"
- check_exercise_form(user_id, s3_key, mime_type, media_type, exercise_name, user_message) - Analyze exercise form from uploaded video/image. Pass the media details from context.
- compare_exercise_form(user_id, s3_keys, mime_types, exercise_name, user_message) - Compare form across multiple videos. Pass comma-separated S3 keys and MIME types from context.

CRITICAL INSTRUCTIONS:
- User ID is: {user_id}
- For generate_quick_workout: ALWAYS pass user_id="{user_id}". Pass workout_id only if a workout exists.
- For sport-specific workouts (boxing, hyrox, crossfit, mma, etc.): Use the appropriate workout_type parameter.
- For other tools: use workout_id from context. Default to today's workout (ID: {workout_id}) if available.

**IMPORTANT - USE TOOLS TO MAKE CHANGES:**
You are a personal coach with the ability to create and modify workouts in real-time.

When the user wants a workout created or modified:
- Use generate_quick_workout to create new workouts
- Use add_exercise_to_workout / remove_exercise_from_workout to modify existing workouts
- Use replace_all_exercises to completely change a workout's focus

When the user just has a question (form, technique, advice):
- Answer naturally without tools

The key principle: If the user wants something DONE to their workout (create it, change it, add/remove exercises),
use the tools so changes are saved to the database and appear on their home screen.
If they just want information or advice, respond conversationally."""

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
    try:
        response = await llm_with_tools.ainvoke(messages)
    except Exception as e:
        if "thought_signature" in str(e).lower():
            logger.warning(f"[Workout Agent] Thought signature error, retrying without tool_choice: {e}")
            # Retry with basic tool binding (no forced tool choice)
            llm_retry = get_langchain_llm(temperature=0.7)
            llm_with_tools_retry = llm_retry.bind_tools(WORKOUT_TOOLS)
            response = await llm_with_tools_retry.ainvoke(messages)
        else:
            raise

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

    # Get media_ref and media_refs for form analysis tool injection
    media_ref = state.get("media_ref")
    media_refs = state.get("media_refs")
    user_id_for_tools = None
    if state.get("user_profile"):
        user_id_for_tools = state["user_profile"].get("id")
    if not user_id_for_tools:
        user_id_for_tools = state.get("user_id")

    tools_map = {tool.name: tool for tool in WORKOUT_TOOLS}

    for tool_call in tool_calls:
        tool_name = tool_call.get("name")
        tool_args = tool_call.get("args", {}).copy()
        tool_id = tool_call.get("id", tool_name)

        # Auto-inject media_ref fields for check_exercise_form
        if tool_name == "check_exercise_form" and media_ref:
            tool_args["s3_key"] = media_ref.get("s3_key", tool_args.get("s3_key", ""))
            tool_args["mime_type"] = media_ref.get("mime_type", tool_args.get("mime_type", ""))
            tool_args["media_type"] = media_ref.get("media_type", tool_args.get("media_type", ""))
            if "user_id" not in tool_args or not tool_args["user_id"]:
                tool_args["user_id"] = str(user_id_for_tools) if user_id_for_tools else ""
            if not tool_args.get("user_message"):
                tool_args["user_message"] = state.get("user_message", "")

        # Auto-inject media_refs fields for compare_exercise_form
        if tool_name == "compare_exercise_form" and media_refs:
            video_refs = [r for r in media_refs if r.get("media_type") == "video"]
            if video_refs:
                tool_args["s3_keys"] = ",".join(r.get("s3_key", "") for r in video_refs)
                tool_args["mime_types"] = ",".join(r.get("mime_type", "") for r in video_refs)
            if "user_id" not in tool_args or not tool_args["user_id"]:
                tool_args["user_id"] = str(user_id_for_tools) if user_id_for_tools else ""
            if not tool_args.get("user_message"):
                tool_args["user_message"] = state.get("user_message", "")

        # Validate/inject workout_id (skip for form analysis tools)
        if "workout_id" in tool_args:
            ai_workout_id = tool_args["workout_id"]
            if ai_workout_id not in valid_workout_ids and current_workout_id:
                logger.warning(f"[Workout Tool Executor] Invalid workout_id {ai_workout_id}, using {current_workout_id}")
                tool_args["workout_id"] = current_workout_id
        elif tool_name not in ("check_exercise_form", "compare_exercise_form") and current_workout_id:
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

                logger.info(f"[Workout Tool Executor] Result: success={result.get('success')}, action={result.get('action')}, workout_id={result.get('workout_id')}")
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

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_workout_system_prompt(ai_settings)

    system_prompt = f"""{base_system_prompt}

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

    # Log message types for debugging thought_signature flow
    logger.debug(f"[Workout Response] Message types: {[type(m).__name__ for m in messages]}")

    messages_with_system = [SystemMessage(content=system_prompt)] + messages + tool_messages

    llm = get_langchain_llm(temperature=0.7)

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

    gemini_service = GeminiService()

    context_parts = []
    has_workout_today = False

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
        has_workout_today = True
    else:
        context_parts.append("\nNo workout scheduled for today - this is a REST DAY.")
        context_parts.append("The user can ask for a quick workout if they want to train anyway.")

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_workout_system_prompt(ai_settings)

    # Add rest day guidance if no workout
    rest_day_guidance = ""
    if not has_workout_today:
        rest_day_guidance = """
IMPORTANT: Today is a REST DAY for this user (no workout scheduled).
- If they ask about today's workout: Kindly let them know it's a rest day
- Mention that rest is important for recovery and muscle growth
- Offer to create a quick workout if they really want to train
- Suggest light activities like stretching, walking, or foam rolling
"""

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}
{rest_day_guidance}
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

    response = await gemini_service.chat(
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

    logger.info(f"[Workout Action Data] Processing {len(tool_results)} tool results")

    for result in tool_results:
        # Only process successful tool results
        if not result.get("success"):
            logger.info(f"[Workout Action Data] Skipping failed result: {result.get('message', 'unknown error')}")
            continue

        action = result.get("action")
        workout_id = result.get("workout_id")

        logger.info(f"[Workout Action Data] Processing action={action}, workout_id={workout_id}")

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
        elif action == "generate_quick_workout":
            action_data = {
                "action": "generate_quick_workout",
                "workout_id": workout_id,
                "workout_name": result.get("workout_name"),
                "duration_minutes": result.get("duration_minutes"),
                "workout_type": result.get("workout_type"),
                "intensity": result.get("intensity"),
                "exercises_added": result.get("exercises_added", []),
                "exercise_count": result.get("exercise_count"),
            }
            logger.info(f"[Workout Action Data] Built generate_quick_workout action_data: workout_id={workout_id}")
        elif action == "check_exercise_form":
            action_data = {
                "action": "check_exercise_form",
                "exercise_identified": result.get("exercise_identified"),
                "form_score": result.get("form_score"),
                "rep_count": result.get("rep_count", 0),
                "overall_assessment": result.get("overall_assessment"),
                "issues": result.get("issues", []),
                "positives": result.get("positives", []),
                "recommendations": result.get("recommendations", []),
                "media_type": result.get("media_type"),
            }
            logger.info(f"[Workout Action Data] Built check_exercise_form action_data: score={result.get('form_score')}")
        elif action == "compare_exercise_form":
            action_data = {
                "action": "compare_exercise_form",
                "exercise_identified": result.get("exercise_identified"),
                "video_count": result.get("video_count", 0),
                "comparison": result.get("comparison", {}),
                "videos": result.get("videos", []),
                "recommendations": result.get("recommendations", []),
            }
            logger.info(f"[Workout Action Data] Built compare_exercise_form action_data: {result.get('video_count')} videos")

    logger.info(f"[Workout Action Data] Final action_data: {action_data}")
    return {"action_data": action_data}


def check_for_tool_calls(state: WorkoutAgentState) -> str:
    """After agent node, check if tools were called."""
    tool_calls = state.get("tool_calls", [])
    if tool_calls:
        return "execute_tools"
    else:
        return "finalize"
