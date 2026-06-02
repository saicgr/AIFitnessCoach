"""Node implementations for the Recommendation (synthesis) Agent — Gap 7 Part B.

ONE node: assemble the user's whole picture via `build_holistic_context`, render
it into a grounded prompt, and produce a single cross-domain recommendation.

Grounding/safety (per CLAUDE.md + feedback_no_llm_for_safety_classification):
- Only cite signals actually present — never invent macros, paces, or load.
- The HARD dietary rule (vegan/allergy) is enforced from structured prefs, not
  inferred from chat.
- Hard safety (injuries, recovery tier) is deferred to deterministic resolvers
  that already shaped the context; the LLM only synthesizes on top.
- No medical claims — the medical disclaimer is shown by the UI.
"""
from typing import Dict, Any, List

from .state import RecommendationAgentState
from ..personality import build_personality_prompt, sanitize_coach_name
from models.chat import AISettings
from services.gemini_service import GeminiService
from core.logger import get_logger
from core.locale import locale_system_suffix as _locale_system_suffix

logger = get_logger(__name__)


RECOMMENDATION_BASE_PROMPT_TEMPLATE = """You are {coach_name}, an AI health coach giving ONE clear, cross-domain recommendation.

You reason across the user's WHOLE picture at once — what they have eaten today, today's workout, their training load, recovery/sleep, injuries, and their dietary preferences — and connect them. The signature of a great answer is a connection the user would not have made alone, e.g. "you are vegan and ran in your peak zone today, so lean on plant-based fats and a little extra protein to help recovery — and keep tomorrow's session easy."

HOW TO ANSWER:
- Lead with the recommendation, then one sentence of WHY grounded in the data below.
- Connect at least two domains when the data supports it (food + training, training + recovery, recovery + food).
- Be specific and realistic (real foods, normal portions; concrete session changes).
- Keep it to 2-4 short sentences. No headers, no bullet dumps.

HARD RULES:
- Use ONLY the numbers and facts in CONTEXT. If a signal is absent, do not invent it and do not mention its absence.
- NEVER recommend a food that violates the dietary constraints below — not even as an example.
- Respect active-injury directives exactly; never suggest training a hard-avoid area.
- No medical diagnosis or claims.
"""


def get_recommendation_system_prompt(ai_settings: Dict[str, Any] = None, locale: str = "en") -> str:
    """Build the personalized system prompt for the recommendation agent."""
    settings_obj = AISettings(**ai_settings) if ai_settings else None
    coach_name = (
        sanitize_coach_name(settings_obj.coach_name, default="Coach")
        if settings_obj and settings_obj.coach_name
        else "Coach"
    )
    base_prompt = RECOMMENDATION_BASE_PROMPT_TEMPLATE.format(coach_name=coach_name)
    personality = build_personality_prompt(
        ai_settings=settings_obj,
        agent_name="Coach",
        agent_specialty="holistic cross-domain health coaching",
    )
    return f"{base_prompt}\n\n{personality}"


def _render_holistic_context(ctx: Dict[str, Any]) -> str:
    """Render build_holistic_context output into grounded CONTEXT lines.

    Order is salience-first: the HARD dietary rule leads, then what-we-know
    (memory/injuries), training load, recovery, and today's nutrition.
    """
    lines: List[str] = []
    if not ctx:
        return ""

    dietary = ctx.get("dietary") or {}
    if dietary.get("hard_rule"):
        lines.append(f"⛔ {dietary['hard_rule']}")
    elif dietary.get("summary_line"):
        lines.append(dietary["summary_line"])

    memory_block = ctx.get("memory_block")
    if memory_block:
        lines.append("What I know about you:\n" + str(memory_block).strip())

    cardio_block = ctx.get("cardio_block")
    if cardio_block:
        lines.append("Training load / cardio:\n" + str(cardio_block).strip())

    health_block = ctx.get("health_block")
    if health_block:
        lines.append("Recovery / sleep / activity:\n" + str(health_block).strip())

    nutrition = ctx.get("nutrition") or {}
    if nutrition:
        cal_t = nutrition.get("target_calories")
        cal_c = nutrition.get("total_calories")
        cal_r = nutrition.get("net_calorie_remainder")
        if cal_r is None:
            cal_r = nutrition.get("calorie_remainder")
        macros_rem = nutrition.get("macros_remaining") or {}
        bits: List[str] = []
        if cal_t is not None:
            if cal_r is not None:
                bits.append(f"calories {int(round(cal_c or 0))}/{int(round(cal_t))} ({int(round(cal_r))} left)")
            else:
                bits.append(f"calorie target {int(round(cal_t))}")
        if macros_rem.get("protein_g") is not None:
            bits.append(f"{int(round(macros_rem['protein_g']))}g protein left")
        if macros_rem.get("carbs_g") is not None:
            bits.append(f"{int(round(macros_rem['carbs_g']))}g carbs left")
        if macros_rem.get("fat_g") is not None:
            bits.append(f"{int(round(macros_rem['fat_g']))}g fat left")
        wo = nutrition.get("meal_types_logged")
        if wo:
            bits.append(f"meals logged: {', '.join(wo)}")
        if bits:
            lines.append("Today's nutrition: " + "; ".join(bits))

    return "\n\n".join(lines)


async def recommendation_node(state: RecommendationAgentState) -> Dict[str, Any]:
    """Assemble holistic context + produce one grounded cross-domain rec."""
    logger.info("[Recommendation] Building holistic context for synthesis...")

    user_id = str(state.get("user_id"))
    user_tz = state.get("user_tz") or "UTC"

    # Assemble the whole picture (best-effort per block — never breaks the turn).
    ctx: Dict[str, Any] = state.get("holistic_context") or {}
    if not ctx:
        try:
            from services.coach.holistic_context import build_holistic_context
            ctx = await build_holistic_context(
                user_id,
                timezone_str=user_tz,
                current_message=state.get("user_message"),
                include_nutrition=True,
            )
        except Exception as e:
            logger.warning(f"[Recommendation] holistic context failed for {user_id[:8]}: {e}")
            ctx = {}

    context_block = _render_holistic_context(ctx)

    ai_settings = state.get("ai_settings")
    base_system_prompt = get_recommendation_system_prompt(
        ai_settings, locale=state.get("locale") or "en"
    )

    if context_block:
        context_section = f"CONTEXT (the user's current picture — cite ONLY this):\n{context_block}"
    else:
        # No data at all — answer generally, never invent numbers.
        context_section = (
            "CONTEXT: No personal data is available right now. Give general, "
            "safe guidance and explicitly invite the user to log a meal or "
            "connect a wearable so you can tailor it. Never invent numbers."
        )

    system_prompt = (
        f"{base_system_prompt}\n\n{context_section}"
        + _locale_system_suffix(state.get("locale") or "en")
    )

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    gemini_service = GeminiService()
    response = await gemini_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Recommendation] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
        "holistic_context": ctx,
    }
