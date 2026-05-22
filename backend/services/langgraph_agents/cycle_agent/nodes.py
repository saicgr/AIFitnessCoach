"""
Node implementations for the Cycle Agent.

The cycle agent is a focused menstrual-health coach. It can:
1. Use tools (log symptoms, log period events, set sync preferences, fetch
   status / history / symptoms, give phase-based suggestions)
2. Respond autonomously for general cycle-education questions

It answers from the user's own logged data (the `cycle_context` block) so
replies cite her real numbers and have continuity.

SAFETY GUARDRAILS (enforced in the system prompt):
- Never give contraceptive / birth-control advice — this keeps the feature a
  general-wellness tool, not an FDA-regulated medical device.
- Never diagnose a medical condition.
- Flag red-flag patterns (cycle <21 or >45 days, very heavy bleeding, severe
  pain, unexplained missed periods) with a gentle "see a clinician" nudge.
- Always frame predictions as estimates with a confidence level.
- Be PCOS-aware: irregular cycles are common, not a failure.
"""
import json
from typing import Dict, Any, Literal

from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, ToolMessage

from core.gemini_client import get_langchain_llm
from .state import CycleAgentState
from ..tools.cycle_tools import CYCLE_TOOLS
from ..personality import build_personality_prompt, sanitize_coach_name
from models.chat import AISettings
from services.gemini_service import GeminiService
from core.logger import get_logger

logger = get_logger(__name__)

# Cycle agent tools
CYCLE_AGENT_TOOLS = CYCLE_TOOLS

# Menstrual-health expertise base prompt (coach name inserted dynamically).
CYCLE_BASE_PROMPT_TEMPLATE = """You are {coach_name}, a knowledgeable and warm AI menstrual-health and cycle coach. You help the user understand and work with their menstrual cycle. You specialize in:
- Explaining the four cycle phases (menstrual, follicular, ovulation, luteal) and what to expect
- Helping the user log periods, symptoms, mood, energy, sleep and BBT
- Reading the user's own logged data and prediction back to her with continuity
- Phase-aware workout and nutrition guidance
- Cycle, ovulation and fertile-window understanding (general wellness, not contraception)

PERSONALITY:
- Warm, supportive, and matter-of-fact about periods — never squeamish
- Validating: cramps, fatigue, mood shifts and irregular cycles are real and common
- Practical: small, doable suggestions tied to her actual data
- Honest about uncertainty — predictions are estimates

NON-NEGOTIABLE SAFETY GUARDRAILS:
1. NEVER give contraceptive or birth-control advice, and never present cycle
   predictions as a way to prevent or plan pregnancy as a method. If asked,
   say this app is a wellness tracker, not a contraceptive method, and to talk
   to a clinician about birth control. The fertile-window estimate is for
   awareness only.
2. NEVER diagnose a medical condition (PCOS, endometriosis, thyroid disorders,
   pregnancy, infection, etc.). You can describe what a pattern *may* relate to
   in general terms, then point to a clinician.
3. RED-FLAG PATTERNS — when any of these appear in her data or message, gently
   and clearly recommend she see a doctor or gynecologist, without alarm:
   - average or observed cycle length shorter than 21 days or longer than 45 days
   - very heavy bleeding (soaking through protection hourly, large clots)
   - severe or disabling period pain
   - an unexplained missed period (when not expected from a known cause)
   - bleeding between periods or after intercourse
   Frame it as "worth getting checked", not a diagnosis.
4. ALWAYS frame phase, ovulation, fertile-window and next-period dates as
   ESTIMATES, and mention the confidence level when it is low.
5. BE PCOS-AWARE AND IRREGULARITY-AWARE: roughly half of people who menstruate
   have cycles that vary by 5+ days. Irregular is common, not a personal
   failing. For PCOS or irregular cycles, predictions are wider and less
   certain — say so plainly and never imply she is doing something wrong.

CAPABILITIES:
1. **With Tools**: log symptoms / period start & end, set cycle-sync
   preferences, fetch live status / history / recent symptoms, and give
   phase-based workout or meal suggestions.
2. **Without Tools**: explain cycle phases, symptoms, and general cycle
   education questions.

When you DO use tools:
- "My period started today" -> log_period_event
- "I've been cramping" / "feeling low energy" -> log_cycle_symptom
- "Where am I in my cycle?" / "when is my period due?" -> get_cycle_status
- "Is my cycle regular?" -> get_cycle_history
- "Why have I been so tired?" -> get_recent_symptoms
- "Sync my workouts to my cycle" -> set_cycle_sync_preference
- "What workout should I do today?" -> suggest_phase_workout
- "What should I eat this week?" -> suggest_phase_meals

When you DON'T need tools:
- "What is the luteal phase?"
- "Why do I get cramps?"
- "What does ovulation feel like?"

Always ground answers in her real logged numbers when the cycle context
provides them. Speak in plain, kind language."""


def get_cycle_system_prompt(ai_settings: Dict[str, Any] = None) -> str:
    """Build the full system prompt with personality customization."""
    settings_obj = AISettings(**ai_settings) if ai_settings else None

    coach_name = (
        sanitize_coach_name(settings_obj.coach_name, default="Luna")
        if settings_obj and settings_obj.coach_name
        else "Luna"
    )

    base_prompt = CYCLE_BASE_PROMPT_TEMPLATE.format(coach_name=coach_name)

    personality = build_personality_prompt(
        ai_settings=settings_obj,
        agent_name="Luna",
        agent_specialty="menstrual-health and cycle coaching",
    )
    return f"{base_prompt}\n\n{personality}"


def _format_cycle_context_block(state: CycleAgentState) -> str:
    """Render the assembled cycle context into a prompt block.

    The agent gets the FULL context (summary, prediction, recent-log digest,
    red flags) — this stays inside Zealova's backend.
    """
    ctx = state.get("cycle_context")
    if not ctx or not ctx.get("available"):
        return ("CYCLE DATA: no cycle predictions available yet — she may not "
                "have logged a period. Encourage gentle first logging.")

    lines = ["HER CURRENT CYCLE DATA (estimates — never a contraceptive method):"]
    if ctx.get("summary"):
        lines.append(ctx["summary"])

    pred = ctx.get("prediction") or {}
    if pred.get("predictions_available"):
        lines.append(
            f"- Phase: {pred.get('current_phase')} | cycle day "
            f"{pred.get('current_cycle_day')} | confidence "
            f"{pred.get('confidence')}"
        )
        if pred.get("next_period_date"):
            lines.append(
                f"- Next period estimate: {pred.get('next_period_date')} "
                f"(window {pred.get('next_period_window_start')} to "
                f"{pred.get('next_period_window_end')})"
            )
        if pred.get("ovulation_date"):
            lines.append(
                f"- Ovulation estimate: {pred.get('ovulation_date')} "
                f"({pred.get('ovulation_status')})"
            )
        stats = pred.get("stats") or {}
        if stats.get("avg_cycle_length"):
            lines.append(
                f"- Cycle stats: avg {stats.get('avg_cycle_length')}d, "
                f"regularity {stats.get('regularity')}, "
                f"{stats.get('periods_logged')} periods logged"
            )

    rl = ctx.get("recent_logs") or {}
    if rl.get("days_logged"):
        lines.append(
            f"- Recent logs ({rl['days_logged']} days): avg energy "
            f"{rl.get('avg_energy')}, avg sleep {rl.get('avg_sleep_quality')}"
        )
        top = rl.get("top_symptoms") or []
        if top:
            lines.append(
                "- Frequent symptoms: "
                + ", ".join(f"{t['symptom']} ({t['days']}d)" for t in top)
            )

    red_flags = ctx.get("red_flags") or []
    if red_flags:
        lines.append(
            "RED-FLAG SIGNALS PRESENT — gently recommend she see a clinician "
            "(do not diagnose): " + "; ".join(red_flags)
        )

    return "\n".join(lines)


def should_use_tools(state: CycleAgentState) -> Literal["agent", "respond"]:
    """Route to the tool-using agent for logging / status / action requests,
    or to the autonomous node for general cycle-education questions."""
    message = state.get("user_message", "").lower()

    # Logging keywords
    log_keywords = [
        "my period started", "period started", "started bleeding",
        "started my period", "period is over", "period ended",
        "i'm cramping", "i've been cramping", "i am cramping",
        "log my", "log symptom", "feeling bloated", "i'm spotting",
    ]
    # Status / data keywords
    status_keywords = [
        "where am i in my cycle", "my cycle", "when is my period",
        "when's my period", "period due", "am i ovulating", "ovulation",
        "fertile", "is my cycle regular", "my cycle history",
        "why am i so tired", "why have i been", "cycle day",
        "what phase", "which phase",
    ]
    # Action / preference keywords
    action_keywords = [
        "sync my workout", "sync my nutrition", "cycle sync",
        "workout for my phase", "what should i eat today",
        "phase workout", "phase meal",
    ]

    for kw in log_keywords + status_keywords + action_keywords:
        if kw in message:
            logger.info(f"[Cycle Router] tool-worthy keyword: {kw} -> agent")
            return "agent"

    logger.info("[Cycle Router] general cycle question -> respond (no tools)")
    return "respond"


async def cycle_agent_node(state: CycleAgentState) -> Dict[str, Any]:
    """The cycle agent node with bound tools. The LLM decides which to call."""
    logger.info("[Cycle Agent] Processing with tools...")

    context = _format_cycle_context_block(state)

    if state.get("rag_context_formatted"):
        context += f"\n\nPrevious context:\n{state['rag_context_formatted']}"

    llm = get_langchain_llm(temperature=0.6)
    llm_with_tools = llm.bind_tools(CYCLE_AGENT_TOOLS)

    ai_settings = state.get("ai_settings")
    base_system_prompt = get_cycle_system_prompt(ai_settings)

    tool_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

USER_ID: {state['user_id']}

AVAILABLE TOOLS:
- get_cycle_status(user_id) - current phase, cycle day, next-period & fertile estimates
- get_cycle_history(user_id, limit) - recent logged periods + cycle stats
- get_recent_symptoms(user_id, days) - digest of recent symptoms/mood/energy/BBT
- log_cycle_symptom(user_id, symptoms, mood, energy_level, sleep_quality, period_flow, notes, log_date) - log a daily entry
- log_period_event(user_id, event, event_date) - event="start" or "end"
- set_cycle_sync_preference(user_id, sync_workouts, sync_nutrition) - toggle cycle-sync flags
- suggest_phase_workout(user_id, phase) - phase-appropriate workout guidance
- suggest_phase_meals(user_id, phase) - phase-appropriate nutrition guidance

When the user reports a symptom, log it AND offer a small piece of help.
When the user reports their period started/ended, log the event.
Always pass user_id explicitly. Honor every safety guardrail above."""

    system_message = SystemMessage(content=tool_prompt)

    messages = [system_message]
    for msg in state.get("conversation_history", []):
        if msg.get("role") == "user":
            messages.append(HumanMessage(content=msg["content"]))
        elif msg.get("role") == "assistant":
            messages.append(AIMessage(content=msg["content"]))
    messages.append(HumanMessage(content=state["user_message"]))

    try:
        response = await llm_with_tools.ainvoke(messages)
    except Exception as e:
        if "thought_signature" in str(e).lower():
            logger.warning(f"Thought signature error, retrying: {e}", exc_info=True)
            llm_retry = get_langchain_llm(temperature=0.6)
            response = await llm_retry.bind_tools(CYCLE_AGENT_TOOLS).ainvoke(messages)
        else:
            raise

    if hasattr(response, "tool_calls") and response.tool_calls:
        logger.info(f"[Cycle Agent] Calling {len(response.tool_calls)} tools")
        return {
            "messages": messages + [response],
            "tool_calls": response.tool_calls,
            "ai_response": response.content or "",
        }

    logger.info("[Cycle Agent] No tools needed")
    return {
        "messages": messages + [response],
        "tool_calls": [],
        "ai_response": response.content or "",
        "final_response": response.content or "",
    }


async def cycle_tool_executor_node(state: CycleAgentState) -> Dict[str, Any]:
    """Execute the cycle tools the LLM decided to call."""
    logger.info("[Cycle Tool Executor] Executing tools...")

    tool_calls = state.get("tool_calls", [])
    tool_results = []
    tool_messages = []

    tools_map = {tool.name: tool for tool in CYCLE_AGENT_TOOLS}

    for tool_call in tool_calls:
        tool_name = tool_call.get("name")
        tool_args = tool_call.get("args", {}).copy()
        tool_id = tool_call.get("id", tool_name)

        # Inject user_id if the LLM omitted it.
        if "user_id" not in tool_args:
            tool_args["user_id"] = state["user_id"]

        if tool_name in tools_map:
            logger.info(f"[Cycle Tool Executor] Running: {tool_name}")
            try:
                result = tools_map[tool_name].invoke(tool_args)
                tool_results.append(result)
                tool_messages.append(ToolMessage(
                    content=json.dumps(result, default=str),
                    tool_call_id=tool_id,
                ))
            except Exception as e:
                logger.error(f"[Cycle Tool Executor] Error: {e}", exc_info=True)
                error_result = {"success": False, "error": str(e)}
                tool_results.append(error_result)
                tool_messages.append(ToolMessage(
                    content=json.dumps(error_result),
                    tool_call_id=tool_id,
                ))
        else:
            logger.warning(f"[Cycle Tool Executor] Unknown tool: {tool_name}")

    return {"tool_results": tool_results, "tool_messages": tool_messages}


async def cycle_response_node(state: CycleAgentState) -> Dict[str, Any]:
    """Generate the final response after tools have run."""
    logger.info("[Cycle Response] Generating final response...")

    ai_settings = state.get("ai_settings")
    base_system_prompt = get_cycle_system_prompt(ai_settings)
    context = _format_cycle_context_block(state)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

IMPORTANT:
- The cycle action(s) have been completed successfully.
- Respond warmly and naturally as a menstrual-health coach.
- Cite her real numbers from the context when relevant.
- If a red-flag signal is present, gently suggest seeing a clinician.
- Frame all predictions as estimates.
- NEVER mention tool names or technical details."""

    messages = state.get("messages", [])
    tool_messages = state.get("tool_messages", [])

    from core.gemini_client import sanitize_messages_for_response
    clean_messages = sanitize_messages_for_response(messages + tool_messages)

    tool_results_summary = []
    for result in state.get("tool_results", []):
        if isinstance(result, dict):
            msg = result.get("message") or result.get("error") or ""
            if msg:
                tool_results_summary.append(msg[:500])
    if tool_results_summary:
        clean_messages.append(HumanMessage(
            content="[SYSTEM: The following actions were completed]\n"
                    + "\n".join(tool_results_summary)
        ))

    messages_with_system = [SystemMessage(content=system_prompt)] + clean_messages

    llm = get_langchain_llm(temperature=0.6)
    response = await llm.ainvoke(messages_with_system)

    return {
        "ai_response": response.content,
        "final_response": response.content,
    }


async def cycle_autonomous_node(state: CycleAgentState) -> Dict[str, Any]:
    """Generate a response WITHOUT tools for general cycle-education questions."""
    logger.info("[Cycle Autonomous] Generating response without tools...")

    gemini_service = GeminiService()

    context = _format_cycle_context_block(state)
    if state.get("rag_context_formatted"):
        context += f"\n\nPrevious context:\n{state['rag_context_formatted']}"

    ai_settings = state.get("ai_settings")
    base_system_prompt = get_cycle_system_prompt(ai_settings)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

You are answering a general menstrual-cycle question. Provide clear, warm,
evidence-informed education. Ground it in her data when the context supplies
numbers. Honor every safety guardrail — no contraceptive advice, no diagnosis,
flag red-flag patterns, frame predictions as estimates."""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await gemini_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    return {
        "ai_response": response,
        "final_response": response,
    }


async def cycle_action_data_node(state: CycleAgentState) -> Dict[str, Any]:
    """Build action_data for the frontend from the cycle tool results."""
    tool_results = state.get("tool_results", [])
    action_data = None

    for result in tool_results:
        if not isinstance(result, dict):
            continue
        action = result.get("action")

        if action == "log_cycle_symptom":
            action_data = {
                "action": "log_cycle_symptom",
                "log_id": result.get("log_id"),
                "log_date": result.get("log_date"),
                "symptoms": result.get("symptoms", []),
                "mood": result.get("mood"),
                "energy_level": result.get("energy_level"),
                "sleep_quality": result.get("sleep_quality"),
                "period_flow": result.get("period_flow"),
                "success": result.get("success", False),
            }
        elif action == "log_period_event":
            action_data = {
                "action": "log_period_event",
                "event": result.get("event"),
                "period_id": result.get("period_id"),
                "start_date": result.get("start_date"),
                "end_date": result.get("end_date"),
                "success": result.get("success", False),
            }
        elif action == "set_cycle_sync_preference":
            action_data = {
                "action": "set_cycle_sync_preference",
                "cycle_sync_workouts": result.get("cycle_sync_workouts"),
                "cycle_sync_nutrition": result.get("cycle_sync_nutrition"),
                "success": result.get("success", False),
            }
        elif action == "suggest_phase_workout":
            action_data = {
                "action": "suggest_phase_workout",
                "phase": result.get("phase"),
                "recommended_intensity": result.get("recommended_intensity"),
                "focus": result.get("focus"),
                "success": result.get("success", False),
            }
        elif action == "suggest_phase_meals":
            action_data = {
                "action": "suggest_phase_meals",
                "phase": result.get("phase"),
                "nutrition_focus": result.get("nutrition_focus"),
                "success": result.get("success", False),
            }
        elif action == "get_cycle_status":
            action_data = {
                "action": "get_cycle_status",
                "current_phase": result.get("current_phase"),
                "current_cycle_day": result.get("current_cycle_day"),
                "next_period_date": result.get("next_period_date"),
                "days_until_next_period": result.get("days_until_next_period"),
                "fertile_window_start": result.get("fertile_window_start"),
                "fertile_window_end": result.get("fertile_window_end"),
                "confidence": result.get("confidence"),
                "success": result.get("success", False),
            }
        elif action == "get_cycle_history":
            action_data = {
                "action": "get_cycle_history",
                "period_count": result.get("period_count"),
                "stats": result.get("stats", {}),
                "success": result.get("success", False),
            }
        elif action == "get_recent_symptoms":
            action_data = {
                "action": "get_recent_symptoms",
                "days_logged": result.get("days_logged"),
                "top_symptoms": result.get("top_symptoms", []),
                "success": result.get("success", False),
            }

    return {"action_data": action_data}


def check_for_tool_calls(state: CycleAgentState) -> str:
    """After the agent node, branch on whether tools were requested."""
    return "execute_tools" if state.get("tool_calls") else "finalize"
