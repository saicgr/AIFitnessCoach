"""
Node implementations for the Fitness Coach LangGraph agent.

Uses proper LangGraph tool calling - the LLM decides which tools to use.
"""
import json
from datetime import datetime
from typing import Dict, Any, Literal

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, ToolMessage

from .state import FitnessCoachState
from .tools import ALL_TOOLS
from models.chat import CoachIntent
from services.openai_service import OpenAIService
from services.rag_service import RAGService
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()


async def intent_extractor_node(state: FitnessCoachState) -> Dict[str, Any]:
    """
    Extract intent from user message using OpenAI.
    """
    logger.info(f"[Intent Node] Extracting intent from: {state['user_message'][:50]}...")

    openai_service = OpenAIService()
    extraction = await openai_service.extract_intent(state['user_message'])

    logger.info(f"[Intent Node] Detected intent: {extraction.intent.value}")
    if extraction.exercises:
        logger.info(f"[Intent Node] Exercises: {extraction.exercises}")

    return {
        "intent": extraction.intent,
        "extracted_exercises": extraction.exercises,
        "extracted_muscle_groups": extraction.muscle_groups,
        "modification": extraction.modification,
        "body_part": extraction.body_part,
        "setting_name": extraction.setting_name,
        "setting_value": extraction.setting_value,
        "destination": extraction.destination,
        "hydration_amount": extraction.hydration_amount,
    }


async def rag_context_node(state: FitnessCoachState) -> Dict[str, Any]:
    """
    Retrieve similar past conversations using RAG.
    """
    logger.info("[RAG Node] Retrieving similar conversations...")

    openai_service = OpenAIService()
    rag_service = RAGService(openai_service=openai_service)

    similar_docs = await rag_service.find_similar(
        query=state['user_message'],
        user_id=state['user_id'],
        n_results=3
    )

    formatted_context = rag_service.format_context(similar_docs)

    logger.info(f"[RAG Node] Found {len(similar_docs)} similar conversations")

    return {
        "rag_documents": similar_docs,
        "rag_context_formatted": formatted_context,
        "rag_context_used": len(similar_docs) > 0,
        "similar_questions": [
            doc.get("metadata", {}).get("question", "")
            for doc in similar_docs[:3]
        ],
    }


def should_use_tools(state: FitnessCoachState) -> Literal["agent", "respond"]:
    """
    Determine if we should use tools or just respond.

    Routes to agent (with tools) if:
    - There's a workout context (for workout modifications)
    - There's an image (for food analysis)
    - The intent is nutrition-related
    - The intent is injury-related (needs injury management tools)

    Routes to respond (no tools) for:
    - App settings changes (handled via action_data)
    - General questions

    This is the proper LangGraph way - let the LLM with bound tools decide.
    """
    has_workout = state.get("current_workout") is not None
    has_image = state.get("image_base64") is not None
    intent = state.get("intent")

    # Check for app control intents - don't need tools, just action_data
    if intent == CoachIntent.CHANGE_SETTING:
        logger.info("[Router] Change setting intent -> respond (no tools needed)")
        return "respond"

    if intent == CoachIntent.NAVIGATE:
        logger.info("[Router] Navigate intent -> respond (no tools needed)")
        return "respond"

    # Workout action intents - don't need tools, handled via action_data
    if intent == CoachIntent.START_WORKOUT:
        logger.info("[Router] Start workout intent -> respond (no tools needed)")
        return "respond"

    if intent == CoachIntent.COMPLETE_WORKOUT:
        logger.info("[Router] Complete workout intent -> respond (no tools needed)")
        return "respond"

    # Quick logging intents - don't need tools, handled via action_data
    if intent == CoachIntent.LOG_HYDRATION:
        logger.info("[Router] Log hydration intent -> respond (no tools needed)")
        return "respond"

    # Check for nutrition-related intents
    nutrition_intents = [
        CoachIntent.ANALYZE_FOOD,
        CoachIntent.NUTRITION_SUMMARY,
        CoachIntent.RECENT_MEALS,
    ]
    is_nutrition_intent = intent in nutrition_intents

    # Check for injury-related intents (needs tools to record/update injuries)
    injury_intents = [
        CoachIntent.REPORT_INJURY,
    ]
    is_injury_intent = intent in injury_intents

    if has_image:
        logger.info("[Router] Image present -> agent (food analysis)")
        return "agent"
    elif has_workout:
        logger.info("[Router] Workout present -> agent (let LLM with tools decide)")
        return "agent"
    elif is_nutrition_intent:
        logger.info(f"[Router] Nutrition intent ({intent}) -> agent (nutrition tools)")
        return "agent"
    elif is_injury_intent:
        logger.info(f"[Router] Injury intent ({intent}) -> agent (injury management tools)")
        return "agent"
    else:
        logger.info("[Router] No workout/image -> respond (simple response)")
        return "respond"


def format_date_with_day(date_str: str) -> str:
    """Format a date string to include the day of the week.

    Args:
        date_str: Date string in format YYYY-MM-DD or with time component

    Returns:
        Formatted string like "Friday, 2025-11-28"
    """
    if not date_str:
        return ""
    # Extract just the date part if it's a full datetime
    if "T" in date_str:
        date_str = date_str.split("T")[0]
    try:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d")
        day_name = date_obj.strftime("%A")  # Full day name (Monday, Tuesday, etc.)
        return f"{day_name}, {date_str}"
    except ValueError:
        return date_str


def format_workout_schedule_context(schedule: Dict[str, Any]) -> str:
    """Format workout schedule for AI context with workout IDs for modification."""
    if not schedule:
        return ""

    parts = ["\nWORKOUT SCHEDULE (use these workout_ids when modifying):"]
    parts.append("IMPORTANT: When mentioning dates in your response, ALWAYS include the day of the week (e.g., 'Friday, 2025-11-28' not just '2025-11-28').")

    def format_workout_with_id(w: Dict[str, Any], label: str) -> str:
        if not w:
            return f"- {label}: No workout scheduled"
        exercises = w.get("exercises", [])
        exercise_count = len(exercises)
        exercise_names = [e.get("name", "Unknown") for e in exercises[:3]]
        status = "COMPLETED" if w.get("is_completed") else "scheduled"
        workout_id = w.get("id", "N/A")
        scheduled_date = w.get("scheduled_date", "")
        date_display = format_date_with_day(scheduled_date) if scheduled_date else ""
        date_info = f" ({date_display})" if date_display else ""
        return f"- {label}{date_info} (ID: {workout_id}): \"{w.get('name', 'Unknown')}\" - {exercise_count} exercises ({', '.join(exercise_names)}{'...' if exercise_count > 3 else ''}) - {status}"

    parts.append(format_workout_with_id(schedule.get("yesterday"), "Yesterday"))
    parts.append(format_workout_with_id(schedule.get("today"), "Today"))
    parts.append(format_workout_with_id(schedule.get("tomorrow"), "Tomorrow"))

    this_week = schedule.get("thisWeek", [])
    if this_week:
        parts.append("\nTHIS WEEK'S WORKOUTS:")
        for w in this_week:
            scheduled = w.get("scheduled_date", "")
            formatted_date = format_date_with_day(scheduled)
            status = "COMPLETED" if w.get("is_completed") else "scheduled"
            parts.append(f"  - ID {w.get('id')}: \"{w.get('name', 'Unknown')}\" on {formatted_date} ({status})")

    recent = schedule.get("recentCompleted", [])
    if recent:
        recent_info = [f"{w.get('name', 'Unknown')} (ID: {w.get('id')})" for w in recent[:3]]
        parts.append(f"\nRecently completed: {', '.join(recent_info)}")

    return "\n".join(parts)


async def agent_node(state: FitnessCoachState) -> Dict[str, Any]:
    """
    The main agent node - uses LLM with bound tools.

    The LLM will decide which tools to call based on the user's request.
    This is the PROPER LangGraph way to handle tool calling.
    """
    logger.info("[Agent Node] LLM deciding which tools to use...")

    # Get workout context (handle None explicitly)
    workout = state.get("current_workout") or {}
    workout_id = workout.get("id")
    exercises = workout.get("exercises", []) or []
    exercise_names = [e.get("name", "Unknown") for e in exercises]

    # Build context for LLM
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

    # Add workout schedule context
    if state.get("workout_schedule"):
        context_parts.append(format_workout_schedule_context(state["workout_schedule"]))

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    # Create LLM with tools bound
    llm = ChatOpenAI(
        model=settings.openai_model,
        api_key=settings.openai_api_key,
        temperature=0.7,
    )
    llm_with_tools = llm.bind_tools(ALL_TOOLS)

    # Build messages
    system_message = SystemMessage(content=f"""You are an expert AI fitness coach. You help users modify their workouts and manage injuries.

CONTEXT:
{context}

CRITICAL TOOL INSTRUCTIONS - SELECTING THE RIGHT WORKOUT:
1. The user may want to modify ANY workout from the schedule above, not just today's.
2. When the user mentions a specific day (e.g., "tomorrow's workout", "Tuesday workout", "leg day"), look up the correct workout_id from the WORKOUT SCHEDULE above.
3. If the user doesn't specify a day, default to TODAY's workout (ID: {workout_id}).
4. Look at the workout names to match requests like "modify the leg day" or "change my push workout".

AVAILABLE WORKOUT TOOLS:
- add_exercise_to_workout(workout_id=X, exercise_names=[...]) - Add exercises to a workout
- remove_exercise_from_workout(workout_id=X, exercise_names=[...]) - Remove exercises from a workout
- replace_all_exercises(workout_id=X, muscle_group="back|chest|legs|shoulders|arms|core", num_exercises=5) - Replace ALL exercises with exercises targeting a specific muscle group. Use this when user wants to completely change their workout focus (e.g., "change to back exercises", "make it a leg day")
- modify_workout_intensity(workout_id=X, modification="easier|harder|shorter|longer") - Change intensity
- reschedule_workout(workout_id=X, new_date="YYYY-MM-DD", reason="...") - Move workout to a different date
- delete_workout(workout_id=X, reason="...") - Delete/cancel a workout (use when user wants to skip or cancel)

INJURY MANAGEMENT TOOLS:
- report_injury(user_id, body_part, severity="mild|moderate|severe", duration_weeks=N, pain_level=1-10, notes="...") - Report a new injury
  * Supported body parts: back, shoulder, knee, hip, ankle, wrist, elbow, neck
  * Default severity is "moderate" (3 weeks recovery)
  * severity durations: mild=2 weeks, moderate=3 weeks, severe=5 weeks
  * User can override duration with duration_weeks parameter
- clear_injury(user_id, body_part="...", injury_id=N, user_feedback="...") - Mark an injury as healed/recovered
- get_active_injuries(user_id) - Get user's current active injuries with recovery status
- update_injury_status(user_id, body_part="...", pain_level=N, improvement_notes="...") - Update pain level or add notes

INJURY HANDLING INSTRUCTIONS:
1. When a user reports an injury (e.g., "I hurt my back", "my shoulder is sore"):
   - Ask them to rate the severity (mild/moderate/severe) if not specified
   - Ask about pain level (1-10) to track progress
   - Use report_injury tool to record it - this automatically modifies upcoming workouts!
2. The system will automatically:
   - Remove exercises that stress the injured area
   - Add appropriate rehab exercises based on recovery phase
   - Track recovery progress over time
3. When user says they're recovered (e.g., "my back feels better", "I'm healed"):
   - Use clear_injury to restore full exercise capability
   - Ask for feedback about their recovery
4. Recovery phases (automatically determined by days since injury):
   - Acute (Week 1): Rest only - no exercises for injured area
   - Subacute (Week 2): Light stretches and mobility only
   - Recovery (Week 3): Gentle strengthening exercises
   - Healed (After 3 weeks): Full capability restored

EXAMPLES:
- "Add pull-ups to tomorrow's workout" → Use the workout_id for tomorrow from the schedule
- "Make leg day easier" → Find the leg workout in the schedule and use its ID
- "Remove squats from today's workout" → Use ID {workout_id}
- "Replace all exercises with back exercises" / "Make it a back workout" → Use replace_all_exercises(workout_id={workout_id}, muscle_group="back")
- "Change to leg exercises" / "I want a leg day instead" → Use replace_all_exercises(workout_id={workout_id}, muscle_group="legs")
- "Move Thursday's workout to Friday" → Use reschedule_workout with the Thursday workout ID
- "Delete today's workout" / "Cancel my workout" / "Skip today" → Use delete_workout with today's workout ID and reason
- "I hurt my back" → Ask about severity, then use report_injury(user_id={state['user_id']}, body_part="back", ...)
- "My knee is better now" → Use clear_injury(user_id={state['user_id']}, body_part="knee")
- "How's my injury recovery going?" → Use get_active_injuries(user_id={state['user_id']})

NUTRITION TRACKING TOOLS:
- analyze_food_image(user_id="{state['user_id']}", image_base64="...", user_message="...") - Analyze food image to log calories and macros
  * IMPORTANT: When user sends a food image, you MUST call this tool
  * The image_base64 is provided in the HAS_IMAGE indicator below
  * After analysis, provide encouragement and dietary feedback
- get_nutrition_summary(user_id="{state['user_id']}", date="YYYY-MM-DD", period="day|week") - Get nutrition totals
- get_recent_meals(user_id="{state['user_id']}", limit=5) - Get recent meal logs

FOOD IMAGE HANDLING:
{f'HAS_IMAGE: true - The user has sent a food image. Call analyze_food_image with the image_base64 provided.' if state.get('image_base64') else 'HAS_IMAGE: false - No image attached.'}
{f'IMAGE_BASE64: {state["image_base64"][:100]}...' if state.get('image_base64') else ''}

NUTRITION EXAMPLES:
- User sends food image → Use analyze_food_image(user_id="{state['user_id']}", image_base64="<the image>", user_message="<user's message>")
- "What did I eat today?" → Use get_nutrition_summary(user_id="{state['user_id']}", period="day")
- "Show my recent meals" → Use get_recent_meals(user_id="{state['user_id']}")

You can call MULTIPLE tools in a single response if the user asks for multiple changes.

Always be helpful, empathetic about injuries, provide encouraging nutrition feedback, and explain what you're doing.""")

    # Include conversation history
    messages = [system_message]
    for msg in state.get("conversation_history", []):
        if msg.get("role") == "user":
            messages.append(HumanMessage(content=msg["content"]))
        elif msg.get("role") == "assistant":
            messages.append(AIMessage(content=msg["content"]))

    messages.append(HumanMessage(content=state["user_message"]))

    # Call LLM - it will decide which tools to use
    response = await llm_with_tools.ainvoke(messages)

    logger.info(f"[Agent Node] LLM response type: {type(response)}")

    # Check if LLM wants to call tools
    if hasattr(response, 'tool_calls') and response.tool_calls:
        logger.info(f"[Agent Node] LLM wants to call {len(response.tool_calls)} tools")
        for tc in response.tool_calls:
            logger.info(f"[Agent Node] Tool: {tc['name']} with args: {tc['args']}")

        return {
            "messages": messages + [response],
            "tool_calls": response.tool_calls,
            "ai_response": response.content or "",
        }
    else:
        logger.info("[Agent Node] LLM chose not to use tools")
        return {
            "messages": messages + [response],
            "tool_calls": [],
            "ai_response": response.content or "",
            "final_response": response.content or "",
        }


async def tool_executor_node(state: FitnessCoachState) -> Dict[str, Any]:
    """
    Execute the tools that the LLM decided to call.

    The AI can now modify ANY workout, not just the current one.
    We trust the AI's workout_id selection since the prompt provides the full schedule.
    """
    logger.info("[Tool Executor] Executing tools...")

    tool_calls = state.get("tool_calls", [])
    tool_results = []
    tool_messages = []

    # Get current workout info for reference (but don't force override)
    current_workout = state.get("current_workout", {})
    current_workout_id = current_workout.get("id") if current_workout else None

    # Build a set of valid workout IDs from the schedule for validation
    valid_workout_ids = set()
    if current_workout_id:
        valid_workout_ids.add(current_workout_id)
    workout_schedule = state.get("workout_schedule") or {}
    for key in ["yesterday", "today", "tomorrow"]:
        w = workout_schedule.get(key)
        if w and w.get("id"):
            valid_workout_ids.add(w.get("id"))
    for w in workout_schedule.get("thisWeek", []) or []:
        if w and w.get("id"):
            valid_workout_ids.add(w.get("id"))
    for w in workout_schedule.get("recentCompleted", []) or []:
        if w and w.get("id"):
            valid_workout_ids.add(w.get("id"))

    # Create a map of tool names to tool functions
    tools_map = {tool.name: tool for tool in ALL_TOOLS}

    for tool_call in tool_calls:
        tool_name = tool_call.get("name")
        tool_args = tool_call.get("args", {}).copy()  # Copy to avoid mutating original
        tool_id = tool_call.get("id", tool_name)

        # If AI provided a workout_id, validate it's in the user's schedule
        # If invalid or missing, fall back to current workout
        if "workout_id" in tool_args:
            ai_workout_id = tool_args["workout_id"]
            if ai_workout_id in valid_workout_ids:
                logger.info(f"[Tool Executor] Using AI-selected workout_id: {ai_workout_id}")
            elif current_workout_id is not None:
                logger.warning(f"[Tool Executor] AI workout_id {ai_workout_id} not in schedule, falling back to current: {current_workout_id}")
                tool_args["workout_id"] = current_workout_id
            # else: let it fail with the invalid ID so the error is clear

        if tool_name in tools_map:
            logger.info(f"[Tool Executor] Running: {tool_name} with args: {tool_args}")
            try:
                tool_fn = tools_map[tool_name]
                result = tool_fn.invoke(tool_args)
                tool_results.append(result)

                # Create ToolMessage for the LLM
                tool_messages.append(ToolMessage(
                    content=json.dumps(result),
                    tool_call_id=tool_id,
                ))

                logger.info(f"[Tool Executor] Result: {result.get('message', 'Done')}")
            except Exception as e:
                logger.error(f"[Tool Executor] Error: {e}")
                error_result = {"success": False, "error": str(e)}
                tool_results.append(error_result)
                tool_messages.append(ToolMessage(
                    content=json.dumps(error_result),
                    tool_call_id=tool_id,
                ))
        else:
            logger.warning(f"[Tool Executor] Unknown tool: {tool_name}")

    return {
        "tool_results": tool_results,
        "tool_messages": tool_messages,
    }


async def response_after_tools_node(state: FitnessCoachState) -> Dict[str, Any]:
    """
    Generate final response after tools have been executed.
    Ensures the response is natural and conversational, not technical.
    """
    logger.info("[Response After Tools] Generating final response...")

    openai_service = OpenAIService()

    # Build context from state for natural response
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append("USER PROFILE:")
        context_parts.append(f"- Name: {profile.get('name', 'User')}")
        context_parts.append(f"- Fitness Level: {profile.get('fitness_level', 'beginner')}")

    if state.get("current_workout"):
        workout = state["current_workout"]
        context_parts.append("")
        context_parts.append(f"WORKOUT BEING MODIFIED: {workout.get('name', 'Current Workout')}")

    # Summarize tool results for context
    if state.get("tool_results"):
        context_parts.append("")
        context_parts.append("ACTIONS COMPLETED:")
        for result in state.get("tool_results", []):
            if isinstance(result, dict):
                if result.get("success"):
                    action = result.get("action", "modification")
                    context_parts.append(f"- Successfully {action}")
                    if "exercises_added" in result:
                        context_parts.append(f"  Added: {', '.join(result['exercises_added'])}")
                    if "exercises_removed" in result:
                        context_parts.append(f"  Removed: {', '.join(result['exercises_removed'])}")

    full_context = "\n".join(context_parts)

    # Get proper system prompt with instructions for natural response
    base_prompt = openai_service.get_coach_system_prompt(full_context)
    system_prompt = base_prompt + """

CRITICAL RESPONSE INSTRUCTIONS:
- The workout modifications have been completed successfully.
- Respond naturally as a supportive fitness coach explaining what was done.
- NEVER mention tool names, function calls, API calls, or technical details.
- NEVER use phrases like "Call remove_exercise_from_workout" or show code/JSON.
- Instead, say things like "I've updated your workout! I removed X and added Y because..."
- Be warm, encouraging, and explain WHY the changes help the user.
- If exercises were removed due to injury, show empathy and explain how new exercises are safer."""

    # Get the messages including tool results
    messages = state.get("messages", [])
    tool_messages = state.get("tool_messages", [])

    # Build messages with system prompt at the beginning
    messages_with_system = [SystemMessage(content=system_prompt)] + messages + tool_messages

    # Call LLM to generate natural response
    llm = ChatOpenAI(
        model=settings.openai_model,
        api_key=settings.openai_api_key,
        temperature=0.7,
    )

    response = await llm.ainvoke(messages_with_system)

    logger.info(f"[Response After Tools] Final response: {response.content[:100]}...")

    return {
        "ai_response": response.content,
        "final_response": response.content,
    }


async def simple_response_node(state: FitnessCoachState) -> Dict[str, Any]:
    """
    Generate response without tools (for questions, etc.)
    """
    logger.info("[Simple Response] Generating response without tools...")

    openai_service = OpenAIService()

    # Build context
    context_parts = []

    # Add current date/time context
    from datetime import datetime
    import pytz
    # Use Pacific time (adjust if user timezone is available)
    pacific = pytz.timezone('America/Los_Angeles')
    now = datetime.now(pacific)
    context_parts.append(f"CURRENT DATE/TIME: {now.strftime('%A, %B %d, %Y at %I:%M %p')} (Pacific Time)")
    context_parts.append("")

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append("USER PROFILE:")
        context_parts.append(f"- Fitness Level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"- Goals: {', '.join(profile.get('goals', []))}")

    if state.get("current_workout"):
        workout = state["current_workout"]
        exercises = workout.get("exercises", [])
        exercise_names = [e.get("name", "Unknown") for e in exercises]
        context_parts.append("")
        context_parts.append("CURRENT WORKOUT:")
        context_parts.append(f"- Name: {workout.get('name', 'Unknown')}")
        context_parts.append(f"- Exercises: {', '.join(exercise_names)}")

    # Add workout schedule context (crucial for answering about past/future workouts)
    if state.get("workout_schedule"):
        context_parts.append(format_workout_schedule_context(state["workout_schedule"]))

    if state.get("rag_context_formatted"):
        context_parts.append("")
        context_parts.append(state["rag_context_formatted"])

    full_context = "\n".join(context_parts)

    # Get intent for action acknowledgment
    intent = state.get("intent")
    intent_str = None
    if intent:
        intent_str = intent.value if hasattr(intent, "value") else str(intent)

    # Build action context for the prompt
    action_context = None
    if intent_str in ["change_setting", "navigate", "start_workout", "complete_workout", "log_hydration"]:
        action_context = {
            "setting_name": state.get("setting_name"),
            "setting_value": state.get("setting_value"),
            "destination": state.get("destination"),
            "hydration_amount": state.get("hydration_amount"),
        }
        logger.info(f"[Simple Response] Action intent detected: {intent_str}, context: {action_context}")

    system_prompt = openai_service.get_coach_system_prompt(full_context, intent=intent_str, action_context=action_context)

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await openai_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Simple Response] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
    }


async def storage_node(state: FitnessCoachState) -> Dict[str, Any]:
    """
    Store the Q&A pair in RAG for future context.
    """
    logger.info("[Storage Node] Storing Q&A in RAG...")

    openai_service = OpenAIService()
    rag_service = RAGService(openai_service=openai_service)

    intent_value = state.get("intent")
    if intent_value and hasattr(intent_value, "value"):
        intent_value = intent_value.value
    else:
        intent_value = "question"

    await rag_service.add_qa_pair(
        question=state["user_message"],
        answer=state.get("final_response", ""),
        intent=intent_value,
        user_id=state["user_id"],
        metadata={
            "exercises": json.dumps(state.get("extracted_exercises", [])),
            "muscle_groups": json.dumps(state.get("extracted_muscle_groups", [])),
        }
    )

    logger.info("[Storage Node] Q&A stored successfully")
    # Must return at least one field for LangGraph
    return {"rag_context_used": state.get("rag_context_used", False)}


async def build_action_data_node(state: FitnessCoachState) -> Dict[str, Any]:
    """
    Build action_data for the frontend based on tool results.
    Now supports actions on any workout, not just the current one.
    Also supports injury management actions.
    """
    intent = state.get("intent")
    current_workout = state.get("current_workout")
    tool_results = state.get("tool_results", [])

    # Build action data from tool results
    action_data = None

    for result in tool_results:
        action = result.get("action")
        # Use the workout_id from the tool result, which may be different from current workout
        result_workout_id = result.get("workout_id")

        if action == "add_exercise":
            action_data = {
                "action": "add_exercise",
                "workout_id": result_workout_id,
                "exercise_names": result.get("exercises_added", []),
            }
        elif action == "remove_exercise":
            action_data = {
                "action": "remove_exercise",
                "workout_id": result_workout_id,
                "exercise_names": result.get("exercises_removed", []),
            }
        elif action == "modify_intensity":
            action_data = {
                "action": "modify_intensity",
                "workout_id": result_workout_id,
                "modification": result.get("modification", ""),
            }
        elif action == "reschedule":
            action_data = {
                "action": "reschedule",
                "workout_id": result_workout_id,
                "old_date": result.get("old_date"),
                "new_date": result.get("new_date"),
                "swapped_with": result.get("swapped_with"),
                "success": result.get("success", False),
            }
        elif action == "delete_workout":
            action_data = {
                "action": "delete_workout",
                "workout_id": result_workout_id,
                "workout_name": result.get("workout_name"),
                "scheduled_date": result.get("scheduled_date"),
                "reason": result.get("reason"),
                "success": result.get("success", False),
            }
        # Injury management actions
        elif action == "report_injury":
            action_data = {
                "action": "report_injury",
                "injury_id": result.get("injury_id"),
                "user_id": result.get("user_id"),
                "body_part": result.get("body_part"),
                "severity": result.get("severity"),
                "recovery_weeks": result.get("recovery_weeks"),
                "expected_recovery_date": result.get("expected_recovery_date"),
                "current_phase": result.get("current_phase"),
                "workouts_modified": result.get("workouts_modified"),
                "exercises_removed": result.get("exercises_removed", []),
                "rehab_exercises": result.get("rehab_exercises", []),
                "success": result.get("success", False),
            }
        elif action == "clear_injury":
            action_data = {
                "action": "clear_injury",
                "injury_id": result.get("injury_id"),
                "user_id": result.get("user_id"),
                "body_part": result.get("body_part"),
                "recovery_duration_days": result.get("recovery_duration_days"),
                "recovery_status": result.get("recovery_status"),
                "success": result.get("success", False),
            }
        elif action == "get_active_injuries":
            action_data = {
                "action": "get_active_injuries",
                "user_id": result.get("user_id"),
                "injuries": result.get("injuries", []),
                "count": result.get("count", 0),
                "success": result.get("success", False),
            }
        elif action == "update_injury_status":
            action_data = {
                "action": "update_injury_status",
                "injury_id": result.get("injury_id"),
                "body_part": result.get("body_part"),
                "pain_level": result.get("pain_level"),
                "success": result.get("success", False),
            }

    # If no tool results, use intent (fallback to current workout if available)
    if not action_data and intent:
        # Handle app settings changes (no tools needed)
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
                logger.info(f"[Action Data] Setting change: {setting_name}={setting_value}")
        # Handle navigation (no tools needed)
        elif intent == CoachIntent.NAVIGATE:
            destination = state.get("destination")
            if destination:
                action_data = {
                    "action": "navigate",
                    "destination": destination,
                    "success": True,
                }
                logger.info(f"[Action Data] Navigation: {destination}")
        # Handle start workout (no tools needed)
        elif intent == CoachIntent.START_WORKOUT:
            workout_id = current_workout.get("id") if current_workout else None
            action_data = {
                "action": "start_workout",
                "workout_id": workout_id,
                "success": True,
            }
            logger.info(f"[Action Data] Start workout: {workout_id}")
        # Handle complete workout (no tools needed)
        elif intent == CoachIntent.COMPLETE_WORKOUT:
            workout_id = current_workout.get("id") if current_workout else None
            action_data = {
                "action": "complete_workout",
                "workout_id": workout_id,
                "success": True,
            }
            logger.info(f"[Action Data] Complete workout: {workout_id}")
        # Handle hydration logging (no tools needed)
        elif intent == CoachIntent.LOG_HYDRATION:
            hydration_amount = state.get("hydration_amount") or 1
            action_data = {
                "action": "log_hydration",
                "amount": hydration_amount,
                "success": True,
            }
            logger.info(f"[Action Data] Log hydration: {hydration_amount} glasses")
        elif current_workout:
            workout_id = current_workout.get("id")
            if intent == CoachIntent.ADD_EXERCISE:
                action_data = {
                    "action": "add_exercise",
                    "workout_id": workout_id,
                    "exercise_names": state.get("extracted_exercises", []),
                }
            elif intent == CoachIntent.REMOVE_EXERCISE:
                action_data = {
                    "action": "remove_exercise",
                    "workout_id": workout_id,
                    "exercise_names": state.get("extracted_exercises", []),
                }

    return {"action_data": action_data}
