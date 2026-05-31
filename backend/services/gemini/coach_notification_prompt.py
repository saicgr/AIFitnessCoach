"""Prompt builder for the data-grounded coach notification (morning readiness
briefing + evening recap).

This is the prompt behind the "Google Health style" push: a TITLE that states
an insight (not a command), a short narrative BODY that *synthesizes* the
user's real signals (sleep stages + recovery + resting HR + recent training),
and 1-2 calibrated action bullets. Every number the model writes must come
from the DATA block — the caller enforces this with a number guardrail and
falls back to the deterministic builder if the model cites anything ungrounded.

Two moments share the prompt:
  - ``morning_readiness`` — last night + today's plan, forward-looking.
  - ``evening_recap``     — how the day went + a gentle setup for tomorrow.

Design rules (mirrors the daily_insight prompt's discipline):
  - numbers ONLY from DATA; never invent a stat; omit a metric that's absent.
  - no em dashes or en dashes (project marketing/voice rule).
  - first name required; stay in the coach's persona + tone.
  - body <= ~90 words; 1-2 action bullets, each concrete and calibrated.
  - injuries: reference naturally, keep the caution ("keep avoiding bench
    press while your shoulder heals").
  - open loop: optionally weave in ONE brief check-in.
"""
from __future__ import annotations

import json
from typing import Any, Dict, Tuple


_BASE_STYLE = (
    "You are {coach_name}, the user's personal fitness coach. You are writing a "
    "single push notification they will read on their lock screen. Your coaching "
    "style is {style} and your tone is {tone}.\n\n"
    "Write it the way a sharp human coach who remembers this person would: lead "
    "with an INSIGHT about their body, not a command. The title is an "
    "observation (for example 'Your body prioritized deep recovery last night'), "
    "never an instruction like 'Time to work out'. The body is 2 to 4 sentences "
    "that CONNECT the signals into one story (tie sleep to recovery to resting "
    "heart rate to recent training), explains briefly why it matters, then sets "
    "up today. Finish with 1 or 2 short action bullets that are specific and "
    "calibrated to exactly this day.\n\n"
    "HARD RULES:\n"
    "1. You may ONLY state numbers that appear in the DATA block below. Never "
    "invent or estimate a number. If a metric is missing from DATA, do not "
    "mention it at all.\n"
    "2. Address the user by their first name once, naturally.\n"
    "3. No em dashes and no en dashes. Use commas or periods.\n"
    "4. Body under 90 words. Each action bullet under 16 words.\n"
    "5. If an active injury is present, reference it naturally and keep the "
    "relevant caution. Never diagnose; inform and adjust.\n"
    "6. If an open follow-up is provided, you may weave in one brief check-in, "
    "but keep the notification focused.\n"
    "7. Stay completely in character. Output ONLY the JSON object described.\n"
)

_MOMENT_GUIDANCE = {
    "morning_readiness": (
        "MOMENT: This is the MORNING readiness briefing. Reflect on LAST NIGHT's "
        "sleep and recovery, factor in recent training load, and look FORWARD to "
        "today. If recovery is strong, encourage adding a little load; if it is "
        "low, steer toward a lighter day and protect recovery. Name today's "
        "scheduled workout if one is provided."
    ),
    "evening_recap": (
        "MOMENT: This is the EVENING recap. Reflect on how TODAY actually went "
        "(steps, workout done or missed, nutrition if present), acknowledge the "
        "effort honestly, and set up tomorrow with one small intention. Do not "
        "talk about last night's sleep as if it were tonight."
    ),
}

_OUTPUT_SPEC = (
    '\n\nReturn ONLY this JSON object (no markdown, no commentary):\n'
    '{"title": "<insight title, <= 8 words>", '
    '"body": "<2-4 sentence narrative>", '
    '"actions": ["<short calibrated action>", "<optional second action>"]}'
)


def build_briefing_prompt(
    context: Dict[str, Any],
    moment: str,
    coach_name: str = "Coach",
    style: str = "motivational",
    tone: str = "encouraging",
) -> Tuple[str, str]:
    """Return ``(system_instruction, user_message)`` for the briefing call.

    Args:
        context: the grounded data block from ``smart_briefing`` — a JSON-able
            dict with first_name, sleep, recovery, heart_rate, steps,
            recent_training, today_workout, injuries, open_loops, facts, goals.
        moment: ``"morning_readiness"`` | ``"evening_recap"``.
        coach_name / style / tone: the user's coach persona (user_ai_settings).
    """
    moment_guidance = _MOMENT_GUIDANCE.get(moment, _MOMENT_GUIDANCE["morning_readiness"])
    system_instruction = (
        _BASE_STYLE.format(coach_name=coach_name or "Coach", style=style, tone=tone)
        + "\n"
        + moment_guidance
        + _OUTPUT_SPEC
    )
    user_message = (
        "DATA (every number you cite must appear here):\n"
        + json.dumps(context, ensure_ascii=False, default=str)
    )
    return system_instruction, user_message
