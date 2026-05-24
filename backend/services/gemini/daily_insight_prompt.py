"""
Daily Insight Prompt — system + user message builders for the
home-screen daily-coach insight and the Ask-Coach pillar-stat insight.

Surfaces (passed as `source`):
    source="home"                     → daily score insight, hero card single-line.
    source="pillar_stat"              → Ask-Coach context insight keyed off a
                                        pillar stat label (plan §6c).
    source="morning_brief"            → 5–10 AM expanded brief, multi-line.
    source="evening_recap"            → 20–22 evening recap, multi-line.
    source="morning_brief_onboarding" → low-history degrade variant (plan §1e).
    source="nutrition_card_morning"   → 1-line breakfast suggestion.
    source="workout_card"             → 1-line workout-card mode body.

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
    /chat            : open Ask-Coach chat (use as primary for most home insights)
    /home            : return to the home dashboard
    /workouts        : open the workouts list (today's session lives here)
    /nutrition       : open the nutrition tab (food log + macros)
    /neat            : open NEAT / steps / activity dashboard
    /health/sleep    : open the sleep detail screen
    /fasting         : open the fasting timer / log
    /pillar/train    : open the Train pillar detail (score + 7-day trend)
    /pillar/nourish  : open the Nourish pillar detail
    /pillar/move     : open the Move pillar detail

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


# ──────────────────────────────────────────────────────────────────────
# Multi-line surfaces — morning brief, evening recap, onboarding.
# These produce bullet-formatted bodies (separator: "\n• ") so the
# coach hero card can render them as a real brief instead of a single
# sentence. Chip lists (suggested actions) ride in the cta arrays
# extended to 3-4 entries.
# ──────────────────────────────────────────────────────────────────────
_MORNING_BRIEF_BRANCH_INSTRUCTION = """SOURCE = morning_brief (rich daily kickoff)
You are writing the EXPANDED morning brief shown on the home coach hero
card between 05:00 and 10:59 local time. The user has at least 3 days of
history (the snapshot includes yesterday's session + last 7 days of
patterns + RAG-pulled context). Produce:

- headline: a short greeting that uses first_name (e.g. "Morning, Sai.").
  At most 6 words.
- body: 3 to 4 lines separated by "\\n". The FIRST line is a 1-sentence
  yesterday recap referencing real numbers from the snapshot
  (workout name, protein g, sleep hours, steps — whichever are present).
  Then exactly 3 bullet lines, each prefixed with "• " and each a
  concrete action for the morning. End with one optional "Watch:" line
  if the patterns block surfaces a streak risk (e.g. skipped breakfast
  4 of last 7). Keep total body ≤ 5 lines.
- cta_primary + cta_secondary + up to 2 additional chips inside the
  response under "chips" (a list of {label, route_or_action} objects).
  Provide 3 to 4 chips total combining cta_primary, cta_secondary, and
  chips. Chip action kinds must come from MORNING_ACTION_KINDS below
  (route or action). When emitting an action chip set route to ""
  and put the kind under "action" key.

MORNING_ACTION_KINDS (use as action on chip entries):
- log_water_now           : 8oz water log
- log_breakfast           : open log meal sheet, prefilled "Breakfast"
- plan_tomorrow_meals     : open the nutrition planner
- start_wind_down         : (evening only) flip the wind-down state
- start_workout_now       : open today's workout
"""

_EVENING_RECAP_BRANCH_INSTRUCTION = """SOURCE = evening_recap (end-of-day recap)
You are writing the EVENING RECAP shown on the home coach hero card
between 20:00 and 21:59 local time. Body is 3 lines separated by "\\n":
  line 1: "Today: " 1-sentence today recap with real numbers.
  line 2: "This week: " 1-sentence rollup (counts only).
  line 3: "Tonight: " concrete sleep / wind-down ask.
Headline is at most 6 words. Provide exactly 3 chips combining
cta_primary + cta_secondary + 1 entry in the "chips" list.
Allowed action kinds: plan_tomorrow_meals, start_wind_down,
log_water_now, start_workout_now.
"""

_MORNING_ONBOARDING_BRANCH_INSTRUCTION = """SOURCE = morning_brief_onboarding (low-history fallback)
The user has FEWER than 3 days of usable history. Skip recap. Skip
motivational fluff. Produce a concrete onboarding ask:

- headline: short greeting with first_name. At most 6 words.
- body: ONE intro line, then exactly 3 bullet lines (each "• ") that
  name the three setup steps the user must complete to unlock real
  coaching. Setup steps:
    - Connect Health (sleep + recovery)
    - Set nutrition targets (calories + protein)
    - Build the first week's plan
  Close with one line that promises real coaching once the setup is
  done. Keep ≤ 5 lines.
- Provide exactly 3 chips. Allowed action kinds:
  connect_health, set_nutrition_targets, build_first_plan.
"""

_NUTRITION_CARD_MORNING_BRANCH_INSTRUCTION = """SOURCE = nutrition_card_morning (single-line breakfast suggestion)
You are writing the small breakfast-suggestion line shown inside the
nutrition card morning slot. Output a SINGLE-line body (1 sentence,
no bullets). If history_rag returns a typical breakfast for this user
(e.g. "oats + eggs"), name it. Otherwise give a generic
"30g protein + 50g carbs" target. headline ≤ 6 words.
Provide 1 cta (log meal). No additional chips needed.
"""

_WORKOUT_CARD_BRANCH_INSTRUCTION = """SOURCE = workout_card (body line under hero workout card)
You are writing the BODY LINE shown under the hero workout card when it
renders in a non-default mode (windDown, recoveryLighter, bonus, etc.).
mode_context (from the user payload) tells you which mode the resolver
picked. Output a SINGLE-line body (1 sentence) that justifies the mode
using snapshot numbers. headline ≤ 6 words. cta_primary is the mode's
primary action (e.g. "Switch to lighter") — route can be empty when
action is set. Allowed action kinds on cta_primary / cta_secondary:
swap_to_lighter_variant, swap_to_bodyweight_variant,
reschedule_to_tomorrow, start_workout_now, add_bonus_workout,
mark_rest_day, log_pre_workout_snack, log_post_workout_meal,
delay_workout_until_fast_ends, accept_pr_target.
"""


# Cycle-phase guidance — appended to the system instruction when the
# snapshot carries a cycle_phase value. Subtle phase awareness across
# every surface. Per CLAUDE.md no numeric fabrication — guidance is
# qualitative; the number guardrail still rejects fabricated stats.
_CYCLE_PHASE_GUIDANCE = {
    "menstrual": (
        "\n\nCYCLE PHASE: menstrual. Lower energy is normal. Bias to "
        "gentle movement, iron-rich foods, extra hydration. Avoid "
        "framing today as a push day. No fabricated cycle stats."
    ),
    "follicular": (
        "\n\nCYCLE PHASE: follicular. Energy and recovery typically peak. "
        "Good window for harder training and skill work. Reference this "
        "qualitatively only."
    ),
    "ovulation": (
        "\n\nCYCLE PHASE: ovulation. Peak strength window for many users. "
        "PR attempts and intensity are well-tolerated. Hydration matters. "
        "Reference qualitatively only."
    ),
    "luteal": (
        "\n\nCYCLE PHASE: luteal. Rising progesterone. Slightly more carbs "
        "are OK. Prefer lower-impact training. Expect higher RHR and lower "
        "HRV than baseline; do not flag them as a problem. No fabricated "
        "cycle stats."
    ),
}


# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------

def _build_system_instruction(source: str, cycle_phase: str | None = None) -> str:
    """Return the source-specific system instruction.

    `cycle_phase` ∈ {menstrual, follicular, ovulation, luteal, None}.
    When present we append qualitative phase guidance so headlines and
    bodies across every surface read cycle-aware. Per plan §10 +
    `feedback_no_llm_for_safety_classification`: the guidance is
    QUALITATIVE only — the number guardrail in the caller still rejects
    any fabricated cycle stats.
    """
    if source == "pillar_stat":
        branch = _PILLAR_STAT_BRANCH_INSTRUCTION
    elif source == "morning_brief":
        branch = _MORNING_BRIEF_BRANCH_INSTRUCTION
    elif source == "evening_recap":
        branch = _EVENING_RECAP_BRANCH_INSTRUCTION
    elif source == "morning_brief_onboarding":
        branch = _MORNING_ONBOARDING_BRANCH_INSTRUCTION
    elif source == "nutrition_card_morning":
        branch = _NUTRITION_CARD_MORNING_BRANCH_INSTRUCTION
    elif source == "workout_card":
        branch = _WORKOUT_CARD_BRANCH_INSTRUCTION
    else:
        # Default to home for any unknown source — keeps the contract safe
        # rather than throwing inside a hot Gemini call.
        branch = _HOME_BRANCH_INSTRUCTION

    base = (
        "You are Zealova, the user's fitness coach. You write short, "
        "specific daily insights for a fitness app. Tone is warm, direct, "
        "and respects the user's time. You never sound like a marketing "
        "email and you never sound like a robot.\n\n"
        f"{branch}\n"
        f"{_SHARED_RULES}\n"
        f"{_TIME_OF_DAY_GUIDANCE}"
    )

    if cycle_phase and cycle_phase in _CYCLE_PHASE_GUIDANCE:
        base += _CYCLE_PHASE_GUIDANCE[cycle_phase]

    return base


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
        # Plan §10 — cycle phase is included on every surface; the system
        # instruction wraps phase-specific guidance when this is set.
        "cycle_phase": context.get("cycle_phase"),
    }
    if source == "pillar_stat":
        payload["pillar_stat_context"] = context.get("pillar_stat_context")
    # Rich-history surfaces (morning + evening) get the additional
    # history snapshot + RAG context wired by upstream agents. Edge case:
    # both may be absent (low-history user) — payload key omitted so the
    # prompt doesn't show a "history_snapshot: null" line that would
    # tempt the model to invent numbers.
    history = context.get("history_snapshot")
    if history:
        payload["history_snapshot"] = history
    rag = context.get("history_rag")
    if rag:
        payload["history_rag"] = rag
    # Workout-card surface needs the resolver mode (windDown / etc.).
    mode = context.get("mode_context")
    if mode:
        payload["mode_context"] = mode

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
    system_instruction = _build_system_instruction(
        source, cycle_phase=context.get("cycle_phase")
    )
    user_message = _build_user_message(context, source)
    return system_instruction, user_message
