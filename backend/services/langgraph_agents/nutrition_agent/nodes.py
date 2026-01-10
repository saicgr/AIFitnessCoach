"""
Node implementations for the Nutrition Agent.

The nutrition agent can:
1. Use tools (analyze food, get summaries, get meals)
2. Respond autonomously with dietary advice without tools
"""
import json
from typing import Dict, Any, Literal
from datetime import datetime

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, ToolMessage

from .state import NutritionAgentState
from ..tools import analyze_food_image, get_nutrition_summary, get_recent_meals
from ..personality import build_personality_prompt
from models.chat import AISettings
from services.gemini_service import GeminiService
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()

# Nutrition agent tools
NUTRITION_TOOLS = [
    analyze_food_image,
    get_nutrition_summary,
    get_recent_meals,
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
"""


def get_nutrition_system_prompt(ai_settings: Dict[str, Any] = None) -> str:
    """Build the full system prompt with personality customization."""
    # Convert dict to AISettings if provided
    settings_obj = AISettings(**ai_settings) if ai_settings else None

    # Get the coach name from settings or use default
    coach_name = settings_obj.coach_name if settings_obj and settings_obj.coach_name else "Nutri"

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
    - User asks about their logged data (summaries, recent meals)

    Routes to autonomous response for:
    - General nutrition questions
    - Dietary advice
    - Meal suggestions
    """
    has_image = state.get("image_base64") is not None
    intent = state.get("intent")
    message = state.get("user_message", "").lower()

    # Food image analysis requires tool
    if has_image:
        logger.info("[Nutrition Router] Image present -> agent (food analysis)")
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
    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        google_api_key=settings.gemini_api_key,
        temperature=0.7,
    )
    llm_with_tools = llm.bind_tools(NUTRITION_TOOLS)

    # Build system message
    tool_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

AVAILABLE TOOLS:
- analyze_food_image(user_id, image_base64, user_message) - Analyze food image to log calories and macros
- get_nutrition_summary(user_id, date, period) - Get nutrition totals for a day or week
- get_recent_meals(user_id, limit) - Get recent meal logs

{f'HAS_IMAGE: true - User sent a food image. Call analyze_food_image.' if state.get('image_base64') else 'HAS_IMAGE: false'}
{f'IMAGE_BASE64: {state["image_base64"][:100]}...' if state.get('image_base64') else ''}

USER_ID: {state['user_id']}"""

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

        # Inject image if analyzing food
        if tool_name == "analyze_food_image" and state.get("image_base64"):
            tool_args["image_base64"] = state["image_base64"]

        if tool_name in tools_map:
            logger.info(f"[Nutrition Tool Executor] Running: {tool_name}")
            try:
                tool_fn = tools_map[tool_name]
                result = tool_fn.invoke(tool_args)
                tool_results.append(result)

                tool_messages.append(ToolMessage(
                    content=json.dumps(result),
                    tool_call_id=tool_id,
                ))

                logger.info(f"[Nutrition Tool Executor] Result: {result.get('message', 'Done')[:100]}")
            except Exception as e:
                logger.error(f"[Nutrition Tool Executor] Error: {e}")
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
        context_parts.append(f"User: {profile.get('name', 'User')}")
        context_parts.append(f"Goals: {', '.join(profile.get('goals', []))}")

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
- NEVER mention tool names or technical details"""

    messages = state.get("messages", [])
    tool_messages = state.get("tool_messages", [])

    messages_with_system = [SystemMessage(content=system_prompt)] + messages + tool_messages

    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        google_api_key=settings.gemini_api_key,
        temperature=0.7,
    )

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

        if action == "analyze_food_image":
            action_data = {
                "action": "food_logged",
                "food_log_id": result.get("food_log_id"),
                "meal_type": result.get("meal_type"),
                "total_calories": result.get("total_calories"),
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
