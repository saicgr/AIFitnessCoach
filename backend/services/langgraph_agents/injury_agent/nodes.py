"""
Node implementations for the Injury Agent.

The injury agent can:
1. Use tools (report injuries, clear injuries, get status)
2. Respond autonomously with recovery advice without tools
"""
import json
from typing import Dict, Any, Literal

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, ToolMessage

from .state import InjuryAgentState
from ..tools import (
    report_injury,
    clear_injury,
    get_active_injuries,
    update_injury_status,
)
from ..personality import build_personality_prompt
from models.chat import AISettings
from services.gemini_service import GeminiService
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()

# Injury agent tools
INJURY_TOOLS = [
    report_injury,
    clear_injury,
    get_active_injuries,
    update_injury_status,
]

# Injury expertise base prompt template (coach name is inserted dynamically)
INJURY_BASE_PROMPT_TEMPLATE = """You are {coach_name}, an expert AI sports medicine specialist and injury recovery coach. You specialize in:
- Helping users report and track injuries
- Providing evidence-based recovery guidance
- Suggesting appropriate rehab exercises
- Advising on safe return to training
- Injury prevention strategies

PERSONALITY:
- Empathetic and caring about user's pain
- Cautious and safety-focused
- Knowledgeable about anatomy and recovery
- Encouraging but realistic about timelines

CAPABILITIES:
1. **With Tools**: Report injuries, clear recovered injuries, track recovery progress
2. **Without Tools**: Explain recovery phases, suggest prevention strategies, answer pain/injury questions

When you DON'T need tools:
- "How do I prevent shoulder injuries?"
- "What's the difference between a strain and a sprain?"
- "How long does a muscle pull usually take to heal?"
- "Should I ice or heat my injury?"
- "What stretches help prevent lower back pain?"

When you DO need tools:
- "I hurt my back"
- "My shoulder is better now"
- "How's my injury recovery going?"
- "Update my pain level to 3"

INJURY SEVERITY GUIDE:
- Mild: Minor discomfort, doesn't affect daily activities (2 week recovery)
- Moderate: Noticeable pain, some activity limitation (3 week recovery)
- Severe: Significant pain, major activity limitation (5 week recovery)

RECOVERY PHASES:
1. Acute (Week 1): Rest, ice, compression, elevation
2. Subacute (Week 2): Light stretches and mobility
3. Recovery (Week 3): Gentle strengthening
4. Healed: Full capability restored

IMPORTANT: Always encourage users to see a medical professional for serious injuries.
"""


def get_injury_system_prompt(ai_settings: Dict[str, Any] = None) -> str:
    """Build the full system prompt with personality customization."""
    settings_obj = AISettings(**ai_settings) if ai_settings else None

    # Get the coach name from settings or use default
    coach_name = settings_obj.coach_name if settings_obj and settings_obj.coach_name else "Recovery"

    # Build the base prompt with the coach name
    base_prompt = INJURY_BASE_PROMPT_TEMPLATE.format(coach_name=coach_name)

    personality = build_personality_prompt(
        ai_settings=settings_obj,
        agent_name="Recovery",  # Fallback agent name if coach_name not set
        agent_specialty="sports medicine and injury recovery coaching"
    )
    return f"{base_prompt}\n\n{personality}"


def should_use_tools(state: InjuryAgentState) -> Literal["agent", "respond"]:
    """
    Determine if we should use tools or respond autonomously.

    Routes to tools if:
    - User reports a new injury
    - User says they're recovered
    - User asks about their injury status

    Routes to autonomous response for:
    - General injury prevention advice
    - Recovery questions
    - Pain management tips
    """
    message = state.get("user_message", "").lower()

    # Injury reporting keywords
    injury_report_keywords = [
        "i hurt", "i injured", "i pulled", "i strained", "i sprained",
        "my back hurts", "my shoulder hurts", "my knee hurts",
        "pain in my", "sore ", "tweaked my", "threw out my"
    ]

    # Recovery/clearing keywords
    recovery_keywords = [
        "feeling better", "recovered", "healed", "no more pain",
        "pain is gone", "back to normal", "cleared up"
    ]

    # Status check keywords
    status_keywords = [
        "how's my injury", "my recovery", "injury status",
        "when can i", "how much longer", "update pain"
    ]

    for keyword in injury_report_keywords:
        if keyword in message:
            logger.info(f"[Injury Router] Injury report detected: {keyword} -> agent")
            return "agent"

    for keyword in recovery_keywords:
        if keyword in message:
            logger.info(f"[Injury Router] Recovery detected: {keyword} -> agent")
            return "agent"

    for keyword in status_keywords:
        if keyword in message:
            logger.info(f"[Injury Router] Status check detected: {keyword} -> agent")
            return "agent"

    # Default: autonomous response for questions/advice
    logger.info("[Injury Router] General injury query -> respond (no tools)")
    return "respond"


async def injury_agent_node(state: InjuryAgentState) -> Dict[str, Any]:
    """
    The injury agent node with bound tools.
    Uses LLM to decide which tools to call.
    """
    logger.info("[Injury Agent] Processing with tools...")

    # Build context
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        if profile.get("active_injuries"):
            context_parts.append(f"Current injuries: {', '.join(profile['active_injuries'])}")

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    # Create LLM with injury tools bound
    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        api_key=settings.gemini_api_key,
        temperature=0.7,
    )
    llm_with_tools = llm.bind_tools(INJURY_TOOLS)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_injury_system_prompt(ai_settings)

    # Build system message
    tool_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

USER_ID: {state['user_id']}

AVAILABLE TOOLS:
- report_injury(user_id, body_part, severity, duration_weeks, pain_level, notes) - Report a new injury
  * Supported body parts: back, shoulder, knee, hip, ankle, wrist, elbow, neck
  * Severity: mild (2 weeks), moderate (3 weeks), severe (5 weeks)
- clear_injury(user_id, body_part, injury_id, user_feedback) - Mark an injury as healed
- get_active_injuries(user_id) - Get user's current active injuries
- update_injury_status(user_id, injury_id, body_part, pain_level, improvement_notes) - Update pain level

When reporting an injury:
1. Extract the body part from the user's message
2. If severity is not specified, ask OR default to "moderate"
3. If pain level is mentioned (e.g., "really hurts" = 7-8, "slight pain" = 3-4), include it

Be empathetic, caring, and always suggest seeing a doctor for serious injuries!"""

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
            logger.warning(f"Thought signature error, retrying: {e}")
            llm_retry = ChatGoogleGenerativeAI(
                model=settings.gemini_model,
                api_key=settings.gemini_api_key,
                temperature=0.7,
            )
            response = await llm_retry.bind_tools(INJURY_TOOLS).ainvoke(messages)
        else:
            raise

    logger.info(f"[Injury Agent] LLM response type: {type(response)}")

    if hasattr(response, 'tool_calls') and response.tool_calls:
        logger.info(f"[Injury Agent] Calling {len(response.tool_calls)} tools")
        for tc in response.tool_calls:
            logger.info(f"[Injury Agent] Tool: {tc['name']}")

        return {
            "messages": messages + [response],
            "tool_calls": response.tool_calls,
            "ai_response": response.content or "",
        }
    else:
        logger.info("[Injury Agent] No tools needed")
        return {
            "messages": messages + [response],
            "tool_calls": [],
            "ai_response": response.content or "",
            "final_response": response.content or "",
        }


async def injury_tool_executor_node(state: InjuryAgentState) -> Dict[str, Any]:
    """Execute the injury tools that the LLM decided to call."""
    logger.info("[Injury Tool Executor] Executing tools...")

    tool_calls = state.get("tool_calls", [])
    tool_results = []
    tool_messages = []

    tools_map = {tool.name: tool for tool in INJURY_TOOLS}

    for tool_call in tool_calls:
        tool_name = tool_call.get("name")
        tool_args = tool_call.get("args", {}).copy()
        tool_id = tool_call.get("id", tool_name)

        # Inject user_id if not provided
        if "user_id" not in tool_args:
            tool_args["user_id"] = state["user_id"]

        if tool_name in tools_map:
            logger.info(f"[Injury Tool Executor] Running: {tool_name}")
            try:
                tool_fn = tools_map[tool_name]
                result = tool_fn.invoke(tool_args)
                tool_results.append(result)

                tool_messages.append(ToolMessage(
                    content=json.dumps(result),
                    tool_call_id=tool_id,
                ))

                logger.info(f"[Injury Tool Executor] Result: {result.get('message', 'Done')[:100]}")
            except Exception as e:
                logger.error(f"[Injury Tool Executor] Error: {e}")
                error_result = {"success": False, "error": str(e)}
                tool_results.append(error_result)
                tool_messages.append(ToolMessage(
                    content=json.dumps(error_result),
                    tool_call_id=tool_id,
                ))
        else:
            logger.warning(f"[Injury Tool Executor] Unknown tool: {tool_name}")

    return {
        "tool_results": tool_results,
        "tool_messages": tool_messages,
    }


async def injury_response_node(state: InjuryAgentState) -> Dict[str, Any]:
    """Generate final response after tools have been executed."""
    logger.info("[Injury Response] Generating final response...")

    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User: {profile.get('name', 'User')}")

    if state.get("tool_results"):
        context_parts.append("\nACTIONS COMPLETED:")
        for result in state.get("tool_results", []):
            if isinstance(result, dict) and result.get("success"):
                context_parts.append(f"- {result.get('message', 'Action completed')[:200]}")

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_injury_system_prompt(ai_settings)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

IMPORTANT:
- The injury actions have been completed successfully
- Respond naturally as a caring sports medicine specialist
- Show empathy for the user's pain
- Provide helpful recovery guidance
- Suggest seeing a doctor if the injury sounds serious
- NEVER mention tool names or technical details"""

    messages = state.get("messages", [])
    tool_messages = state.get("tool_messages", [])

    messages_with_system = [SystemMessage(content=system_prompt)] + messages + tool_messages

    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        api_key=settings.gemini_api_key,
        temperature=0.7,
    )

    response = await llm.ainvoke(messages_with_system)

    logger.info(f"[Injury Response] Final: {response.content[:100]}...")

    return {
        "ai_response": response.content,
        "final_response": response.content,
    }


async def injury_autonomous_node(state: InjuryAgentState) -> Dict[str, Any]:
    """
    Generate response WITHOUT tools for general injury questions.
    This is the autonomous reasoning capability.
    """
    logger.info("[Injury Autonomous] Generating response without tools...")

    gemini_service = GeminiService()

    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        if profile.get("active_injuries"):
            context_parts.append(f"Current injuries: {', '.join(profile['active_injuries'])}")

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_injury_system_prompt(ai_settings)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

You are responding to a general injury/recovery question. Provide expert advice about:
- Injury prevention strategies
- Recovery timelines and phases
- Safe return to training
- When to see a medical professional

Be empathetic, cautious, and caring!"""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await gemini_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Injury Autonomous] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
    }


async def injury_action_data_node(state: InjuryAgentState) -> Dict[str, Any]:
    """Build action_data for the frontend based on tool results."""
    tool_results = state.get("tool_results", [])
    action_data = None

    for result in tool_results:
        action = result.get("action")

        if action == "report_injury":
            action_data = {
                "action": "report_injury",
                "injury_id": result.get("injury_id"),
                "body_part": result.get("body_part"),
                "severity": result.get("severity"),
                "recovery_weeks": result.get("recovery_weeks"),
                "expected_recovery_date": result.get("expected_recovery_date"),
                "workouts_modified": result.get("workouts_modified"),
                "success": result.get("success", False),
            }
        elif action == "clear_injury":
            action_data = {
                "action": "clear_injury",
                "injury_id": result.get("injury_id"),
                "body_part": result.get("body_part"),
                "recovery_duration_days": result.get("recovery_duration_days"),
                "success": result.get("success", False),
            }
        elif action == "get_active_injuries":
            action_data = {
                "action": "get_active_injuries",
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

    return {"action_data": action_data}


def check_for_tool_calls(state: InjuryAgentState) -> str:
    """After agent node, check if tools were called."""
    tool_calls = state.get("tool_calls", [])
    if tool_calls:
        return "execute_tools"
    else:
        return "finalize"
