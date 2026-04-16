"""
Node implementations for the Nutrition Agent.

The nutrition agent can:
1. Use tools (analyze food, get summaries, get meals)
2. Respond autonomously with dietary advice without tools
"""
import json
from typing import Dict, Any, Literal
from datetime import datetime

from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, ToolMessage

from core.gemini_client import get_langchain_llm, sanitize_messages_for_response
from .state import NutritionAgentState
from ..tools import analyze_food_image, analyze_multi_food_images, parse_app_screenshot, parse_nutrition_label, get_nutrition_summary, get_recent_meals, log_food_from_text
from ..tools.nutrition_tools import get_calorie_remainder, get_favorite_foods, get_todays_workout_for_meal, build_grocery_list
from ..personality import build_personality_prompt, sanitize_coach_name
from models.chat import AISettings
from services.gemini_service import GeminiService
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()

# Nutrition agent tools
NUTRITION_TOOLS = [
    analyze_food_image,
    analyze_multi_food_images,
    parse_app_screenshot,
    parse_nutrition_label,
    get_nutrition_summary,
    get_recent_meals,
    log_food_from_text,
    get_calorie_remainder,
    get_favorite_foods,
    get_todays_workout_for_meal,
    build_grocery_list,
]

# Nutrition expertise base prompt template (coach name is inserted dynamically)
NUTRITION_BASE_PROMPT_TEMPLATE = """You are {coach_name}, an expert AI nutritionist and dietary coach. You specialize in:
- Analyzing food and estimating calories/macros
- Providing personalized dietary advice based on fitness goals
- Explaining nutrition concepts (macros, micros, meal timing)
- Suggesting healthy meal alternatives
- Helping users make better food choices

CAPABILITIES:
1. **With Tools**: Analyze food images, log meals, get nutrition summaries
2. **Without Tools**: Answer nutrition questions, explain concepts, suggest meals, provide dietary guidance

When you DON'T need tools:
- General nutrition questions ("Is chicken healthier than beef?")
- Meal suggestions ("What should I eat before a workout?")
- Nutrition education ("What are macros?")
- Dietary advice ("How can I eat more protein?")

When you DO need tools:
- User sends a food image
- User asks about their logged meals
- User wants a nutrition summary

STYLE RULES for meal picks:
- Always use TODAY'S CONTEXT (remaining calories, macros, logged meals, workout) when it's present. Tailor the pick so it actually fits what's left of the day.
- Never refuse a "fast food" / chain-food request. If asked, name the specific chain and the exact order string (e.g. "Chipotle: chicken burrito bowl, brown rice, black beans, fajita veg, salsa — skip queso"), with calories + macros and one line on why it fits. Prefer healthier picks from the same chain, but don't dodge the question.
- Return ONE concrete pick unless the user explicitly asks for options.
"""


def format_day_context_block(state: Dict[str, Any]) -> str:
    """Render the pre-fetched day-context fields as a compact prompt block.

    Reads from NutritionAgentState fields populated by _build_agent_state:
    daily_nutrition_context, current_workout, recent_favorites, context_partial.
    Returns an empty string when none of those fields are populated, so the
    prompt stays lean for agents that aren't about "today's meal".
    """
    dnc = state.get("daily_nutrition_context") or {}
    workout = state.get("current_workout") or {}
    favs = state.get("recent_favorites") or []
    partial = bool(state.get("context_partial"))

    if not dnc and not workout and not favs:
        return ""

    lines = ["TODAY'S CONTEXT (use when relevant; do NOT narrate it):"]

    if dnc:
        cal_target = dnc.get("target_calories")
        cal_consumed = dnc.get("total_calories", 0)
        cal_remainder = dnc.get("calorie_remainder")
        if cal_target:
            lines.append(
                f"• Calories: {cal_consumed}/{cal_target} kcal"
                f" ({cal_remainder:+d} remaining)"
            )
        elif cal_consumed:
            lines.append(f"• Calories today: {cal_consumed} kcal (no daily target set)")
        else:
            lines.append("• No calories logged yet today.")

        mr = dnc.get("macros_remaining") or {}
        macro_parts = []
        for key, label in (("protein_g", "P"), ("carbs_g", "C"), ("fat_g", "F")):
            val = mr.get(key)
            if val is not None:
                macro_parts.append(f"{label} {val:+.0f}g")
        if macro_parts:
            lines.append(f"• Macros remaining: {', '.join(macro_parts)}")

        mtypes = dnc.get("meal_types_logged") or []
        if mtypes:
            lines.append(f"• Meals logged today: {', '.join(mtypes)}")
        else:
            lines.append("• No meals logged yet today.")

        upc = dnc.get("ultra_processed_count_today")
        if upc is not None:
            lines.append(f"• Ultra-processed items today: {upc} (soft cap 2)")

        if dnc.get("over_budget"):
            lines.append("• ⚠️ User is OVER the calorie budget today — prefer low-cal swaps.")

    if workout:
        sched = workout.get("scheduled_time_local") or ""
        muscles = ", ".join(workout.get("primary_muscles") or []) if workout.get("primary_muscles") else ""
        status = "completed" if workout.get("is_completed") else "not yet done"
        parts = [f"• Today's workout: {workout.get('name', 'Workout')}"]
        if workout.get("type"):
            parts[0] += f" ({workout.get('type')})"
        if sched:
            parts[0] += f" at {sched}"
        parts[0] += f" — {status}"
        if muscles:
            parts[0] += f"; muscles: {muscles}"
        lines.append(parts[0])
    else:
        lines.append("• Today is a rest day (no scheduled workout).")

    if favs:
        fav_names = [f.get("name") for f in favs[:5] if f.get("name")]
        if fav_names:
            lines.append(f"• User favorites ({len(fav_names)}): {', '.join(fav_names)}")

    if partial:
        lines.append(
            "• PARTIAL CONTEXT: some data couldn't be loaded; prefer general advice."
        )

    # Style nudge for the "ask from meal-log" popup flow. Keeps the answer
    # punchy and coach-like instead of a dry macro breakdown.
    lines.append("")
    lines.append(
        "REPLY STYLE (meal-log context): motivating, casual coach tone — short "
        "punchy sentences, everyday slang (e.g. 'solid', 'let's go', 'quick "
        "hit'), zero disclaimers. Max ONE emoji if it genuinely fits. NO "
        "bullet lists unless the user explicitly asks. Open with a verb or "
        "hook, not 'Sure!'. Under 60 words."
    )

    return "\n".join(lines)


def get_nutrition_system_prompt(ai_settings: Dict[str, Any] = None) -> str:
    """Build the full system prompt with personality customization."""
    # Convert dict to AISettings if provided
    settings_obj = AISettings(**ai_settings) if ai_settings else None

    # Get the coach name from settings or use default (sanitized)
    coach_name = sanitize_coach_name(settings_obj.coach_name, default="Nutri") if settings_obj and settings_obj.coach_name else "Nutri"

    # Build the base prompt with the coach name
    base_prompt = NUTRITION_BASE_PROMPT_TEMPLATE.format(coach_name=coach_name)

    personality = build_personality_prompt(
        ai_settings=settings_obj,
        agent_name="Nutri",  # Fallback agent name if coach_name not set
        agent_specialty="nutrition and dietary coaching"
    )
    return f"{base_prompt}\n\n{personality}"


def should_use_tools(state: NutritionAgentState) -> Literal["agent", "respond"]:
    """
    Determine if we should use tools or respond autonomously.

    Routes to tools if:
    - There's an image (for food analysis)
    - User describes food they ate (for logging)
    - User asks about their logged data (summaries, recent meals)

    Routes to autonomous response for:
    - General nutrition questions
    - Dietary advice
    - Meal suggestions
    """
    has_image = state.get("image_base64") is not None
    has_multi_images = bool(state.get("media_refs"))
    intent = state.get("intent")
    message = state.get("user_message", "").lower()

    # Multi-image analysis requires tool
    if has_multi_images:
        logger.info("[Nutrition Router] Multi-images present -> agent (multi-food analysis)")
        return "agent"

    # Food image analysis requires tool
    if has_image:
        logger.info("[Nutrition Router] Image present -> agent (food analysis)")
        return "agent"

    # Check for media_content_type from classifier
    media_content_type = state.get("media_content_type")
    if media_content_type in ("app_screenshot", "nutrition_label", "food_menu", "food_buffet", "food_plate"):
        logger.info(f"[Nutrition Router] media_content_type={media_content_type} -> agent")
        return "agent"

    # Check for food logging intent (user describing what they ate)
    food_logging_patterns = [
        "i ate", "i had", "i just ate", "i just had",
        "ate for", "had for", "eating", "just finished eating",
        "had some", "ate some", "had a", "ate a",
        "for breakfast", "for lunch", "for dinner", "for snack",
        "my breakfast", "my lunch", "my dinner",
        "log this", "log my", "track this",
    ]
    for pattern in food_logging_patterns:
        if pattern in message:
            logger.info(f"[Nutrition Router] Food logging intent detected: '{pattern}' -> agent")
            return "agent"

    # Check for data queries that need tools
    data_keywords = [
        "what did i eat", "my meals", "show meals", "recent meals",
        "nutrition summary", "how many calories", "today's nutrition",
        "weekly summary", "my macros today", "what i've eaten"
    ]
    for keyword in data_keywords:
        if keyword in message:
            logger.info(f"[Nutrition Router] Data query detected: {keyword} -> agent")
            return "agent"

    # Default: autonomous response for questions/advice
    logger.info("[Nutrition Router] General nutrition query -> respond (no tools)")
    return "respond"


async def nutrition_agent_node(state: NutritionAgentState) -> Dict[str, Any]:
    """
    The nutrition agent node with bound tools.
    Uses LLM to decide which tools to call.
    """
    logger.info("[Nutrition Agent] Processing with tools...")

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_nutrition_system_prompt(ai_settings)

    # Build context
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"User goals: {', '.join(profile.get('goals', []))}")
        if profile.get("daily_calorie_target"):
            context_parts.append(f"Daily calorie target: {profile['daily_calorie_target']} kcal")

    # Day-context block from pre-fetched state (calorie remainder, workout, favorites)
    day_ctx = format_day_context_block(state)
    if day_ctx:
        context_parts.append("\n" + day_ctx)

    # Include calculated nutrition metrics from RAG
    if state.get("nutrition_profile_context"):
        context_parts.append(f"\n{state['nutrition_profile_context']}")
    else:
        # Try to fetch from RAG service
        try:
            from services.nutrition_rag_service import get_user_nutrition_profile_service
            profile_service = get_user_nutrition_profile_service()
            nutrition_context = profile_service.get_user_profile_context(state["user_id"])
            if nutrition_context:
                context_parts.append(f"\n{nutrition_context}")
        except Exception as e:
            logger.debug(f"Could not fetch nutrition profile from RAG: {e}")

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    # Create LLM with nutrition tools bound
    llm = get_langchain_llm(temperature=0.7)
    llm_with_tools = llm.bind_tools(NUTRITION_TOOLS)

    # Resolve user timezone from profile
    _tz = (state.get("user_profile") or {}).get("timezone") or "UTC"

    # Build system message
    tool_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

AVAILABLE TOOLS:
- log_food_from_text(user_id, food_description, meal_type, timezone_str) - Log food from text description
  * IMPORTANT: When user describes food they ate (e.g., "I ate biryani", "had eggs for breakfast"), call this tool
  * food_description: the food the user mentioned
  * meal_type: optional (breakfast/lunch/dinner/snack), auto-detected if not provided
  * timezone_str: ALWAYS pass "{_tz}"
- analyze_food_image(user_id, image_base64, user_message) - Analyze a single food image to log calories and macros
- analyze_multi_food_images(user_id, s3_keys, mime_types, user_message, analysis_mode, timezone_str) - Analyze multiple food images (plates, buffets, menus)
  * s3_keys: list of S3 object keys from media_refs
  * mime_types: list of MIME types from media_refs
  * analysis_mode: "auto" (let AI detect), "plate", "buffet", or "menu"
  * timezone_str: ALWAYS pass "{_tz}"
- parse_app_screenshot(user_id, s3_keys, mime_types, image_base64, user_message, timezone_str)
  * Parse a nutrition app screenshot to extract and log food entries
  * timezone_str: ALWAYS pass "{_tz}"
- parse_nutrition_label(user_id, s3_keys, mime_types, image_base64, servings_consumed, user_message, timezone_str)
  * Read a nutrition facts label and log the food entry
  * timezone_str: ALWAYS pass "{_tz}"
- get_nutrition_summary(user_id, date, period, timezone_str) - Get nutrition totals for a day or week
  * timezone_str: ALWAYS pass "{_tz}"
- get_recent_meals(user_id, limit) - Get recent meal logs

IMPORTANT: For ALL tool calls that accept timezone_str, you MUST pass timezone_str="{_tz}".

EXAMPLES:
- "I ate thalapakattu mutton biryani" → Call log_food_from_text(user_id="{state['user_id']}", food_description="thalapakattu mutton biryani", timezone_str="{_tz}")
- "Had 2 eggs for breakfast" → Call log_food_from_text(user_id="{state['user_id']}", food_description="2 eggs", meal_type="breakfast", timezone_str="{_tz}")

{f'HAS_MULTI_IMAGES: true - User sent multiple food images via media_refs. Call analyze_multi_food_images with the s3_keys and mime_types from the media_refs.' if state.get('media_refs') else ''}
{f'MEDIA_REFS: {json.dumps([{"s3_key": r.get("s3_key"), "mime_type": r.get("mime_type"), "media_type": r.get("media_type")} for r in state.get("media_refs", [])])}' if state.get('media_refs') else ''}
{f'HAS_IMAGE: true - User sent a food image. Call analyze_food_image.' if state.get('image_base64') and not state.get('media_refs') else 'HAS_IMAGE: false'}
{f'IMAGE_BASE64: {state["image_base64"][:100]}...' if state.get('image_base64') and not state.get('media_refs') else ''}

{f'MEDIA_CONTENT_TYPE: {state.get("media_content_type")}' if state.get('media_content_type') else 'MEDIA_CONTENT_TYPE: none'}
{f'ACTION REQUIRED: This is an app screenshot. Call parse_app_screenshot with the s3_keys and mime_types from media_refs.' if state.get('media_content_type') == 'app_screenshot' else ''}
{f'ACTION REQUIRED: This is a nutrition label. Call parse_nutrition_label with the s3_keys and mime_types from media_refs.' if state.get('media_content_type') == 'nutrition_label' else ''}
{f'ACTION REQUIRED: This is a restaurant menu. Call analyze_multi_food_images with s3_keys and mime_types from media_refs and analysis_mode="menu".' if state.get('media_content_type') == 'food_menu' and state.get('media_refs') else ''}
{f'ACTION REQUIRED: This is a restaurant menu image. Call analyze_food_image with the image_base64. Set user_message to "Analyze this restaurant menu and list all dishes with estimated nutrition".' if state.get('media_content_type') == 'food_menu' and not state.get('media_refs') and state.get('image_base64') else ''}
{f'ACTION REQUIRED: This is a buffet spread. Call analyze_multi_food_images with s3_keys and mime_types from media_refs and analysis_mode="buffet".' if state.get('media_content_type') == 'food_buffet' and state.get('media_refs') else ''}
{f'ACTION REQUIRED: This is a buffet spread image. Call analyze_food_image with the image_base64. Set user_message to "Analyze this buffet and identify all visible dishes with estimated nutrition".' if state.get('media_content_type') == 'food_buffet' and not state.get('media_refs') and state.get('image_base64') else ''}

USER_ID: {state['user_id']}
USER_TIMEZONE: {_tz}"""

    system_message = SystemMessage(content=tool_prompt)

    # Include conversation history
    messages = [system_message]
    for msg in state.get("conversation_history", []):
        if msg.get("role") == "user":
            messages.append(HumanMessage(content=msg["content"]))
        elif msg.get("role") == "assistant":
            messages.append(AIMessage(content=msg["content"]))

    messages.append(HumanMessage(content=state["user_message"]))

    # Call LLM with thought_signature retry handling
    try:
        response = await llm_with_tools.ainvoke(messages)
    except Exception as e:
        if "thought_signature" in str(e).lower():
            logger.warning(f"Thought signature error, retrying: {e}", exc_info=True)
            llm_retry = get_langchain_llm(temperature=0.7)
            response = await llm_retry.bind_tools(NUTRITION_TOOLS).ainvoke(messages)
        else:
            raise

    logger.info(f"[Nutrition Agent] LLM response type: {type(response)}")

    # Check if LLM wants to call tools
    if hasattr(response, 'tool_calls') and response.tool_calls:
        logger.info(f"[Nutrition Agent] Calling {len(response.tool_calls)} tools")
        for tc in response.tool_calls:
            logger.info(f"[Nutrition Agent] Tool: {tc['name']}")

        return {
            "messages": messages + [response],
            "tool_calls": response.tool_calls,
            "ai_response": response.content or "",
        }
    else:
        logger.info("[Nutrition Agent] No tools needed")
        return {
            "messages": messages + [response],
            "tool_calls": [],
            "ai_response": response.content or "",
            "final_response": response.content or "",
        }


async def nutrition_tool_executor_node(state: NutritionAgentState) -> Dict[str, Any]:
    """Execute the nutrition tools that the LLM decided to call."""
    logger.info("[Nutrition Tool Executor] Executing tools...")

    tool_calls = state.get("tool_calls", [])
    tool_results = []
    tool_messages = []

    tools_map = {tool.name: tool for tool in NUTRITION_TOOLS}

    for tool_call in tool_calls:
        tool_name = tool_call.get("name")
        tool_args = tool_call.get("args", {}).copy()
        tool_id = tool_call.get("id", tool_name)

        # Inject user_id if not provided
        if "user_id" not in tool_args:
            tool_args["user_id"] = state["user_id"]

        # Inject timezone_str from user profile if not provided by LLM
        if "timezone_str" not in tool_args:
            _tz = (state.get("user_profile") or {}).get("timezone") or "UTC"
            tool_args["timezone_str"] = _tz

        # Inject image if analyzing food
        if tool_name == "analyze_food_image" and state.get("image_base64"):
            tool_args["image_base64"] = state["image_base64"]

        # Inject media for app screenshot and nutrition label tools
        if tool_name in ("parse_app_screenshot", "parse_nutrition_label"):
            if state.get("media_refs"):
                refs = state["media_refs"]
                tool_args.setdefault("s3_keys", [r.get("s3_key") for r in refs])
                tool_args.setdefault("mime_types", [r.get("mime_type", "image/jpeg") for r in refs])
            if state.get("image_base64"):
                tool_args.setdefault("image_base64", state["image_base64"])

        if tool_name in tools_map:
            logger.info(f"[Nutrition Tool Executor] Running: {tool_name}")
            try:
                tool_fn = tools_map[tool_name]
                result = await tool_fn.ainvoke(tool_args)
                tool_results.append(result)

                tool_messages.append(ToolMessage(
                    content=json.dumps(result),
                    tool_call_id=tool_id,
                ))

                logger.info(f"[Nutrition Tool Executor] Result: {result.get('message', 'Done')[:100]}")
            except Exception as e:
                logger.error(f"[Nutrition Tool Executor] Error: {e}", exc_info=True)
                error_result = {"success": False, "error": str(e)}
                tool_results.append(error_result)
                tool_messages.append(ToolMessage(
                    content=json.dumps(error_result),
                    tool_call_id=tool_id,
                ))
        else:
            logger.warning(f"[Nutrition Tool Executor] Unknown tool: {tool_name}")

    return {
        "tool_results": tool_results,
        "tool_messages": tool_messages,
    }


async def nutrition_response_node(state: NutritionAgentState) -> Dict[str, Any]:
    """Generate final response after tools have been executed."""
    logger.info("[Nutrition Response] Generating final response...")

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_nutrition_system_prompt(ai_settings)

    # Build context from tool results
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"Goals: {', '.join(profile.get('goals', []))}")

    day_ctx = format_day_context_block(state)
    if day_ctx:
        context_parts.append("\n" + day_ctx)

    if state.get("tool_results"):
        context_parts.append("\nACTIONS COMPLETED:")
        for result in state.get("tool_results", []):
            if isinstance(result, dict) and result.get("success"):
                context_parts.append(f"- {result.get('message', 'Action completed')[:200]}")

    context = "\n".join(context_parts)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

IMPORTANT:
- The nutrition actions have been completed successfully
- Respond naturally based on your personality settings
- NEVER mention tool names or technical details
- If a food analysis tool returned "no food items identified" or failed:
  * Acknowledge you received the image but couldn't identify specific items
  * Suggest the image may be unclear, too dark, or an unusual angle
  * Offer to help if the user describes what's in the image or retakes the photo
  * Do NOT claim "the image didn't load" — it loaded fine, the AI just couldn't identify items"""

    messages = state.get("messages", [])
    tool_messages = state.get("tool_messages", [])

    # Sanitize: remove AIMessages with tool_calls and ToolMessages to avoid
    # Gemini thought_signature round-trip errors
    clean_messages = sanitize_messages_for_response(messages + tool_messages)

    # Add tool results as a HumanMessage so the LLM has context to respond to
    tool_results_summary = []
    for result in state.get("tool_results", []):
        if isinstance(result, dict):
            msg = result.get("message", "")
            if msg:
                tool_results_summary.append(msg[:500])
    if tool_results_summary:
        clean_messages.append(HumanMessage(
            content="[SYSTEM: The following actions were completed]\n" + "\n".join(tool_results_summary)
        ))

    messages_with_system = [SystemMessage(content=system_prompt)] + clean_messages

    llm = get_langchain_llm(temperature=0.7)

    response = await llm.ainvoke(messages_with_system)

    logger.info(f"[Nutrition Response] Final: {response.content[:100]}...")

    return {
        "ai_response": response.content,
        "final_response": response.content,
    }


async def nutrition_autonomous_node(state: NutritionAgentState) -> Dict[str, Any]:
    """
    Generate response WITHOUT tools for general nutrition questions.
    This is the autonomous reasoning capability.
    """
    logger.info("[Nutrition Autonomous] Generating response without tools...")

    gemini_service = GeminiService()

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_nutrition_system_prompt(ai_settings)

    # Build context
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"User goals: {', '.join(profile.get('goals', []))}")
        if profile.get("daily_calorie_target"):
            context_parts.append(f"Daily calorie target: {profile['daily_calorie_target']} kcal")

    # Day-context block from pre-fetched state (calorie remainder, workout, favorites)
    day_ctx = format_day_context_block(state)
    if day_ctx:
        context_parts.append("\n" + day_ctx)

    # Include calculated nutrition metrics from RAG
    if state.get("nutrition_profile_context"):
        context_parts.append(f"\n{state['nutrition_profile_context']}")
    else:
        # Try to fetch from RAG service
        try:
            from services.nutrition_rag_service import get_user_nutrition_profile_service
            profile_service = get_user_nutrition_profile_service()
            nutrition_context = profile_service.get_user_profile_context(state["user_id"])
            if nutrition_context:
                context_parts.append(f"\n{nutrition_context}")
        except Exception as e:
            logger.debug(f"Could not fetch nutrition profile from RAG: {e}")

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

You are responding to a general nutrition question. Provide helpful, personalized advice based on the user's goals and fitness level."""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await gemini_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Nutrition Autonomous] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
    }


async def nutrition_action_data_node(state: NutritionAgentState) -> Dict[str, Any]:
    """Build action_data for the frontend based on tool results."""
    tool_results = state.get("tool_results", [])
    action_data = None

    for result in tool_results:
        action = result.get("action")

        if action in ("analyze_food_image", "analyze_multi_food_images"):
            # Determine analysis type
            analysis_type = result.get("analysis_type", "plate")
            if action == "analyze_multi_food_images":
                analysis_type = result.get("analysis_type", result.get("result", {}).get("analysis_type", "plate"))

            # Get food items - could be in result directly or nested in result.result
            food_items = result.get("food_items", [])
            if not food_items and isinstance(result.get("result"), dict):
                food_items = result["result"].get("food_items", [])
                # Also check for dishes (buffet/menu format)
                if not food_items:
                    food_items = result["result"].get("dishes", [])

            action_data = {
                "action": "food_analysis",
                "analysis_type": analysis_type,
                "food_items": food_items,
                "total_calories": result.get("total_calories", 0),
                "protein_g": result.get("protein_g", 0),
                "carbs_g": result.get("carbs_g", 0),
                "fat_g": result.get("fat_g", 0),
                "fiber_g": result.get("fiber_g", 0),
                "health_score": result.get("health_score"),
                "ai_feedback": result.get("ai_feedback", ""),
                "meal_type": result.get("meal_type", "snack"),
                "success": result.get("success", False),
            }
        elif action in ("parse_app_screenshot", "parse_nutrition_label", "log_food_from_text"):
            # All three persist a food_log row. Surface a 'food_logged'
            # action_data so the chat bubble can render a "View logged
            # meal" affordance that deep-links into the Nutrition tab.
            food_items_raw = result.get("food_items") or []
            action_data = {
                "action": "food_logged",
                "food_log_id": result.get("food_log_id"),
                "meal_type": result.get("meal_type"),
                "total_calories": result.get("total_calories"),
                "protein_g": result.get("protein_g"),
                "carbs_g": result.get("carbs_g"),
                "fat_g": result.get("fat_g"),
                "food_item_count": len(food_items_raw) if isinstance(food_items_raw, list) else 0,
                "source_type": action,
                "success": result.get("success", False),
            }
        elif action == "get_nutrition_summary":
            action_data = {
                "action": "nutrition_summary",
                "period": result.get("period"),
                "summary": result.get("summary") or result.get("daily_summaries"),
                "success": result.get("success", False),
            }
        elif action == "get_recent_meals":
            action_data = {
                "action": "recent_meals",
                "meals": result.get("meals"),
                "count": result.get("count"),
                "success": result.get("success", False),
            }

    return {"action_data": action_data}


def check_for_tool_calls(state: NutritionAgentState) -> str:
    """After agent node, check if tools were called."""
    tool_calls = state.get("tool_calls", [])
    if tool_calls:
        return "execute_tools"
    else:
        return "finalize"
