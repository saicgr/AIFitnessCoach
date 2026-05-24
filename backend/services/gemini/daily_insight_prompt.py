"""
Daily Insight Prompt — system + user message builders for the
home-screen daily-coach insight and the Ask-Coach pillar-stat insight.

Two sources:
    source="home"         → daily score insight rendered on the home card.
    source="pillar_stat"  → Ask-Coach context-aware insight keyed off a
                            pillar stat label the user tapped (see plan §6c).

Hard rules enforced in the system instruction:
    - headline ≤ 8 words
    - body ≤ 2 sentences
    - first_name and (when relevant) workout name substitution required
    - NEVER use em dashes ("—") or en dashes ("–"); use periods/commas
    - NEVER use scare quotes around ordinary words
    - plain JSON output, no markdown fences
    - time-of-day branching in user-local tz
      (morning / midday / afternoon / evening / late / quiet)

Output schema (parsed by the caller):
    {
      "headline": str,                 # ≤ 8 words
      "body": str,                     # ≤ 2 sentences
      "cta_primary":   {"label": str, "route": str},
      "cta_secondary": {"label": str, "route": str},
      "leading_pillar": "train" | "nourish" | "move" | "sleep" | "all_done"
    }

Public API:
    build_daily_insight_prompt(context: dict, source: str)
        -> tuple[system_instruction: str, user_message: str]
"""

from __future__ import annotations

import json
from typing import Tuple


# ---------------------------------------------------------------------------
# Shared constraints block — enforced for BOTH sources.
# Kept verbatim across branches so style stays consistent.
# ---------------------------------------------------------------------------
_SHARED_RULES = """STYLE RULES (HARD, violations are rejected):
- headline: at most 8 words. No trailing punctuation other than "!" or ".".
- body: at most 2 sentences. Plain prose. No bullet lists, no markdown.
- Use the user's first_name naturally (never "Hi there", never "User").
- When referencing today's workout, use its exact name verbatim.
- Numbers (calories, protein g, steps, sleep hours, score) must match the
  snapshot EXACTLY. Do not round, do not invent, do not extrapolate.
- NEVER use an em dash (the character U+2014, "—") or en dash (U+2013, "–").
  Use a period or a comma instead. This is a brand voice rule.
- NEVER wrap an ordinary word in scare quotes (e.g. do NOT write 'crush' it,
  'consistency', etc). Quotes are reserved for literal user-spoken text.
- No emoji. No stage directions. No "as an AI" disclaimers.
- Output PLAIN JSON only. No ```json fences. No commentary before/after.

ROUTE WHITELIST (cta_primary.route / cta_secondary.route must be one of):
    /workouts/today  : open today's scheduled workout
    /log/food        : open the food log entry surface
    /move            : open the Move pillar (steps / active minutes)
    /sleep           : open the Sleep pillar / last night detail
    /chat            : open Ask-Coach chat
    /home            : return to the home dashboard
    /history         : open workout/log history

LEADING_PILLAR RULES:
- "train"     when today's workout is incomplete and it is past morning.
- "nourish"   when calorie/protein gap is the largest unmet reach.
- "move"      when steps/active-minutes are the weakest pillar today.
- "sleep"     when last night's sleep is the weakest signal AND it is
              still morning (sleep advice past noon is stale).
- "all_done"  when every applicable pillar's reach is met for today.
"""


_TIME_OF_DAY_GUIDANCE = """TIME-OF-DAY GUIDANCE (branch on time_of_day_bucket):
- morning   (05:00 to 10:59): forward-looking. Frame today's priority.
- midday    (11:00 to 13:59): nudge toward the unmet pillar with most runway.
- afternoon (14:00 to 17:59): concrete next action before the window closes.
- evening   (18:00 to 21:59): reflect on progress, suggest one closing rep.
- late      (22:00 to 23:59): wind-down tone. Bias toward sleep if unmet.
- quiet     (00:00 to 04:59): minimal nudge. Suggest rest, no new tasks.
"""


_HOME_BRANCH_INSTRUCTION = """SOURCE = home (daily score insight)
You are writing the single headline plus a 1 to 2 sentence body that renders on
the home-screen daily-score card. Speak to the user's overall day in the
user's local timezone. Pick ONE concrete unmet (or impressively-met)
pillar to anchor the body. Give a clear CTA that takes them to the
pillar's action surface. cta_secondary is optional but should still be a
valid route (use /chat as the fallback secondary).
"""


_PILLAR_STAT_BRANCH_INSTRUCTION = """SOURCE = pillar_stat (Ask-Coach context insight)
You are writing the inline coach explanation shown when the user taps a
specific pillar stat in Ask-Coach. pillar_stat_context is the human label
of the stat the user tapped (e.g. "Protein 38g / 140g", "Steps 4,200 /
8,000", "Sleep 6h12m"). The headline names the stat plainly. The body
explains WHY this number matters today, given today's goals and the rest
of the snapshot. cta_primary should route the user to the surface where
they can act on this specific stat.
"""


# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------

def _build_system_instruction(source: str) -> str:
    """Return the source-specific system instruction."""
    if source == "pillar_stat":
        branch = _PILLAR_STAT_BRANCH_INSTRUCTION
    else:
        # Default to home for any unknown source — keeps the contract safe
        # rather than throwing inside a hot Gemini call.
        branch = _HOME_BRANCH_INSTRUCTION

    return (
        "You are Zealova, the user's fitness coach. You write short, "
        "specific daily insights for a fitness app. Tone is warm, direct, "
        "and respects the user's time. You never sound like a marketing "
        "email and you never sound like a robot.\n\n"
        f"{branch}\n"
        f"{_SHARED_RULES}\n"
        f"{_TIME_OF_DAY_GUIDANCE}"
    )


def _build_user_message(context: dict, source: str) -> str:
    """Pack the request context into the user-turn payload."""
    # Keep the payload small and deterministic so prompt caching can hit
    # on the shape. default=str handles date/datetime/Decimal safely.
    payload = {
        "source": source,
        "first_name": context.get("first_name"),
        "user_local_tz": context.get("user_local_tz"),
        "time_of_day_bucket": context.get("time_of_day_bucket"),
        "goals": context.get("goals"),
        "today_score_snapshot": context.get("today_score_snapshot"),
        "next_workout": context.get("next_workout"),
    }
    if source == "pillar_stat":
        payload["pillar_stat_context"] = context.get("pillar_stat_context")

    return (
        "Generate the JSON insight for the context below.\n\n"
        f"CONTEXT:\n{json.dumps(payload, default=str, indent=2)}\n\n"
        "Return ONLY the JSON object. No prose, no code fence."
    )


def build_daily_insight_prompt(
    context: dict,
    source: str,
) -> Tuple[str, str]:
    """Build (system_instruction, user_message) for the daily insight call.

    Args:
        context: dict containing first_name, today_score_snapshot,
            next_workout, goals, user_local_tz, time_of_day_bucket,
            and (when source="pillar_stat") pillar_stat_context.
        source: "home" or "pillar_stat".

    Returns:
        (system_instruction, user_message) tuple.
    """
    system_instruction = _build_system_instruction(source)
    user_message = _build_user_message(context, source)
    return system_instruction, user_message
