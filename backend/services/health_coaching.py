"""
Health Coaching Content Engine (Phase C1)
=========================================
Turns the deterministic health snapshot from Phase B1
(``services/user_context/health_activity.py``) into three kinds of *proactive*
coaching messages:

  1. ``build_daily_briefing``   — the morning readiness briefing, upgraded by
     Phase E4 into ONE cross-domain daily game plan. It adapts to a good vs
     poor night and, on a recovery-relevant day, NARRATES today's deterministic
     workout adjustment (``readiness_utils.get_recovery_workout_signal``) AND
     the deterministic nutrition adjustment
     (``sleep_aware_nutrition.adjust_targets_for_recovery``) plus one concrete
     swap suggestion — all in a single connected plan. It produces BOTH a full
     multi-part ``message`` (for the home card) and a brief one-line
     ``brief_message`` (for the notification banner).
  2. ``build_health_anomaly``   — a resting-HR anomaly alert (informs, never
     diagnoses).
  3. ``build_activity_nudge``   — an activity / step-goal nudge (behind, almost
     there, or goal met).

Phase E4 — the cross-domain game plan (edge case G38):
  * The briefing does NOT re-derive the workout or nutrition adjustment — those
    are produced deterministically upstream (Phase B3 + E1). The briefing only
    NARRATES the numbers they already computed.
  * A user missing a domain (no scheduled workout, or no nutrition targets) =>
    the plan covers only the domains with data, with NO empty section.
  * The plan never narrates a prospective workout change for a workout the user
    has already manually started or completed today — it acknowledges it
    instead (the deterministic generation never touched a started workout).

Design rules (per CLAUDE.md + the approved plan + the feedback memory):

  * **Deterministic facts.** Every number in a message comes straight from the
    snapshot — the engine never invents a figure. Pattern *selection* is a pure
    function of the snapshot.
  * **Grounded copy.** Each pattern has >= 4 hand-authored variant templates,
    every one anchored to a public-health source (CDC / Sleep Foundation /
    ACSM). The guidance in the copy is generic best-practice, not medical
    advice.
  * **Day-seeded variety.** The variant is chosen by a date-seeded index so the
    same user sees a stable message within a day but a fresh one across days
    (``feedback_dynamic_copy_not_robotic.md``).
  * **Optional Gemini rephrase.** ``rephrase_with_gemini`` may *only* smooth the
    wording — a post-check rejects any rephrase that drops or alters a number
    that was in the deterministic draft, falling back to the draft on any doubt.
  * **Clean empty output.** No wearable / no consent / stale data => the builder
    returns ``has_message: False`` with a reason — never a fabricated briefing.

Nothing here writes to the DB or sends a push; Phase C2 (the cron) and C3 (the
in-app surfaces) consume these dicts.
"""

from __future__ import annotations

import logging
import re
from datetime import date, datetime
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


# =============================================================================
# Tuning constants — all deterministic, all documented inline.
# =============================================================================

# A night at or above this asleep-minute mark is treated as a "good night" for
# briefing-tone selection. 7h is the CDC / Sleep Foundation adult minimum.
_GOOD_NIGHT_MIN = 420  # 7h

# Below this it is a clearly "poor night" and the briefing leads with recovery.
_POOR_NIGHT_MIN = 360  # 6h

# --- Morning sleep-score push (FEATURE 1) band thresholds --------------------
# A sleep score at or above this is "high" — celebrate it.
_SLEEP_SCORE_HIGH = 80
# A sleep score below this is "poor" — reassure or encourage by recovery tier.
_SLEEP_SCORE_POOR = 60
# The recovery tiers that still count as "recovering well" on a poor-sleep night
# (services/readiness_service.RECOVERY_TIERS). moderate/good => reassuring tone;
# compromised/low (or no tier) => the encouraging "sleep more tonight" tone.
_SLEEP_RECOVERING_TIERS = ("moderate", "good", "optimal")

# Resting-HR anomaly: an elevation of at least this many bpm above the personal
# baseline is "elevated". Sleep Foundation / ACSM note RHR commonly rises ~5-7
# bpm with under-recovery, illness onset, or sleep debt — we use 7 as a
# conservative single-day trigger so a normal day-to-day wobble does not fire.
_RHR_ANOMALY_DELTA = 7.0

# Step-goal nudge bands (fraction of the goal reached at nudge time).
_STEP_ALMOST_THERE_FRAC = 0.80  # >= 80% of goal -> "almost there"
_STEP_BEHIND_FRAC = 0.80        # < 80% of goal  -> "behind" nudge

# Fallback step goal when the user has not set one (CDC general-health figure).
_DEFAULT_STEP_GOAL = 8000


# =============================================================================
# Variant template pools — >= 4 per pattern, each grounded in a public source.
# Templates use ``str.format`` placeholders filled ONLY from snapshot numbers.
# =============================================================================

# --- Daily readiness briefing -------------------------------------------------
# Pattern: good night + optimal/good recovery.
_BRIEFING_GOOD_NIGHT: List[str] = [
    "Solid {sleep_h}h{sleep_m:02d}m of sleep last night and recovery is "
    "{recovery}/100. You're cleared for {workout_phrase} as planned.",
    "{sleep_h}h{sleep_m:02d}m asleep puts you in the CDC's recommended range, "
    "and recovery sits at {recovery}/100 — a green light for {workout_phrase}.",
    "Recovery is {recovery}/100 after {sleep_h}h{sleep_m:02d}m of sleep. Your "
    "body is well rested, so {workout_phrase} at full effort today.",
    "Good news: {sleep_h}h{sleep_m:02d}m of sleep and a {recovery}/100 "
    "recovery score. Train {workout_phrase} as scheduled and push where it "
    "feels right.",
]

# Pattern: poor night (short sleep) + lower recovery -> trim the session.
_BRIEFING_POOR_NIGHT: List[str] = [
    "Only {sleep_h}h{sleep_m:02d}m of sleep last night and recovery is "
    "{recovery}/100. The plan today: {adjustment}. {workout_sentence}",
    "Short night — {sleep_h}h{sleep_m:02d}m asleep — so recovery dropped to "
    "{recovery}/100. We've eased today's load: {adjustment}. {workout_sentence}",
    "{sleep_h}h{sleep_m:02d}m of sleep is below the 7h the Sleep Foundation "
    "recommends, and recovery reflects it at {recovery}/100. Today: "
    "{adjustment}. {workout_sentence}",
    "Recovery came in at {recovery}/100 after a {sleep_h}h{sleep_m:02d}m "
    "night. Rather than skip, we've adjusted: {adjustment}. {workout_sentence}",
]

# Pattern: no sleep data but activity data exists -> lighter activity briefing.
_BRIEFING_NO_SLEEP: List[str] = [
    "No sleep tracked last night, so there's no recovery read today — train "
    "{workout_phrase} by feel and keep an easy off-ramp if energy is low.",
    "We couldn't read last night's sleep, so today's plan stays as scheduled: "
    "{workout_phrase}. Listen to your body and adjust effort as needed.",
    "Last night's sleep didn't sync. Without it we won't second-guess your "
    "plan — go with {workout_phrase} and stop early if it feels off.",
    "No sleep data this morning. Your {workout_phrase} is unchanged; the "
    "Sleep Foundation's advice still holds — aim for 7+ hours tonight.",
]


# --- Morning sleep-score push (FEATURE 1) ------------------------------------
# A separate morning push that names the EXACT 0-100 sleep score the in-app
# Sleep screen shows. Three tone bands (selected deterministically in
# build_sleep_score_briefing):
#   * HIGH (score >= 80)         — celebrate the number.
#   * POOR but still recovering  — reassure (recovery tier moderate/good).
#   * POOR across the board      — encourage + a concrete "sleep more tonight".
# Placeholders: {score} (0-100), {wake_ups} (count), {sleep_h}/{sleep_m}
# (asleep duration). Every variant carries the {score} number verbatim. Copy is
# human-voiced, NO em dashes, >= 4 variants per pool (feedback rules).

# Pattern: a high score — the user got the hours they need with few wake-ups.
_SLEEP_HIGH: List[str] = [
    "High sleep score this morning. Getting the hours of sleep you need and "
    "only a few wake-ups led to a {score}. Nice one.",
    "Strong night. {sleep_h}h{sleep_m:02d}m asleep with minimal interruptions "
    "scored you a {score} out of 100. That is the kind of night your body "
    "rebuilds on.",
    "Your sleep score is {score} today. Solid duration and a settled night "
    "with only a handful of wake-ups did the work here. Carry that energy in.",
    "Sleep score: {score}. You hit the hours that matter and stayed mostly "
    "undisturbed, which is exactly what good recovery looks like.",
    "A {score} sleep score this morning. {sleep_h}h{sleep_m:02d}m of mostly "
    "unbroken sleep is a great base for today, so train with confidence.",
]

# Pattern: a poor score, but the recovery tier says the body is coping
# (recovery tier moderate or good) — reassure, do not alarm.
_SLEEP_POOR_RECOVERING: List[str] = [
    "You had poor sleep, but you are still recovering well. Keep it up by "
    "sleeping more tonight.",
    "Last night scored a {score}, yet your body is holding up better than the "
    "number suggests. Bank a longer night tonight and you will bounce right back.",
    "Sleep score landed at {score} after a short night, but recovery is still "
    "on your side. Aim for more hours tonight and keep the streak going.",
    "A {score} this morning. Not your best sleep, but you are recovering well "
    "all the same. Protect tonight's sleep and you will be back on track.",
    "Rough night, {score} on the sleep score, but your recovery is steady. "
    "One earlier bedtime tonight is all it takes to turn this around.",
]

# Pattern: a poor score AND poor recovery — encourage with a concrete fix.
_SLEEP_POOR_ALL: List[str] = [
    "Your sleep score is {score} this morning after a short, broken night. Go "
    "easy today and make tonight's sleep the priority.",
    "A {score} sleep score, and {wake_ups} wake-ups did not help. Today is a "
    "good day to dial back the effort and get to bed earlier tonight.",
    "Last night scored a {score}. Only {sleep_h}h{sleep_m:02d}m asleep means "
    "your body is short on recovery, so keep today light and sleep more tonight.",
    "Sleep score: {score}. That was a tough night, so listen to your body "
    "today and aim for an earlier, longer night ahead.",
    "Tough night with a {score} sleep score. Be kind to yourself today, "
    "hydrate well, and give tonight's sleep your best shot.",
]


# --- Cross-domain game plan (Phase E4) ---------------------------------------
# These render the SECOND part of a poor-night briefing — the connected
# workout + nutrition plan. The first part (the poor-night sleep readout) still
# comes from _BRIEFING_POOR_NIGHT; this part narrates the two deterministic
# adjustments. {plan_body} is assembled from the per-domain fragments below.
_GAME_PLAN_INTRO: List[str] = [
    "Here's today's plan: {plan_body}",
    "So today's game plan: {plan_body}",
    "Here's how we've adapted today: {plan_body}",
    "Today's adjusted plan: {plan_body}",
]

# Workout-domain fragment — narrates Phase B3's deterministic adjustment.
# {volume_pct} is the integer % volume trimmed (e.g. 30 for a 0.70x multiplier).
_GAME_PLAN_WORKOUT: List[str] = [
    "we've trimmed today's session about {volume_pct}%",
    "today's session is eased by roughly {volume_pct}%",
    "we've pulled today's training volume down ~{volume_pct}%",
    "today's workout is dialed back about {volume_pct}%",
]

# Workout fragment when the session is swapped toward mobility (low tier).
_GAME_PLAN_WORKOUT_MOBILITY: List[str] = [
    "we've swapped today's session toward mobility and light recovery work",
    "today's training leans into mobility and easy recovery movement",
    "we've shifted today to gentle mobility and recovery work",
    "today's plan favors mobility and light, joint-friendly movement",
]

# Nutrition-domain fragment — narrates Phase E1's deterministic target shift.
# {protein_delta} is the grams of protein added.
_GAME_PLAN_NUTRITION: List[str] = [
    "protein is up {protein_delta}g with calories front-loaded earlier in the day",
    "we've added {protein_delta}g of protein and shifted calories toward earlier meals",
    "protein target rises {protein_delta}g and the day's calories lean earlier",
    "today's targets add {protein_delta}g of protein and front-load your calories",
]

# Nutrition fragment when there is no protein target to scale but recovery is
# still low — only the timing guidance applies.
_GAME_PLAN_NUTRITION_TIMING_ONLY: List[str] = [
    "lean on protein and front-load your calories earlier in the day",
    "keep protein high and shift more of the day's food to earlier meals",
    "favor protein and eat the bulk of your calories before mid-afternoon",
    "prioritize protein and push your calories toward breakfast and lunch",
]

# One concrete swap suggestion — the actionable single change. Caffeine-timing
# is the highest-leverage swap on a poor-recovery day (Sleep Foundation).
_GAME_PLAN_SWAP: List[str] = [
    "One easy win: skip the afternoon coffee so tonight's sleep can recover the deficit.",
    "One concrete swap: trade the afternoon caffeine for water — it protects tonight's sleep.",
    "Smallest high-impact change: cut the late-day coffee and let tonight's sleep rebound.",
    "One thing to swap: hold off on afternoon caffeine so you can bank a better night.",
]


# --- Health anomaly alert -----------------------------------------------------
# Pattern: resting HR elevated vs the user's own baseline. Informs, no diagnosis.
_ANOMALY_RHR_ELEVATED: List[str] = [
    "Your resting heart rate is {rhr} bpm this morning, {delta} above your "
    "{baseline} bpm baseline. That can follow short sleep, stress, or a hard "
    "block — an easier day and extra water is a sensible call.",
    "Heads up: resting HR is running {delta} bpm over your usual {baseline} "
    "({rhr} today). The Sleep Foundation links a raised resting HR to "
    "under-recovery — consider dialing today back and prioritizing sleep.",
    "Resting HR sits at {rhr} bpm versus your {baseline} bpm baseline "
    "(+{delta}). It's not a diagnosis, just a signal — hydrate well, keep "
    "intensity moderate, and see if it settles tomorrow.",
    "Your resting heart rate ({rhr} bpm) is {delta} bpm above baseline today. "
    "ACSM recovery guidance treats a sustained rise as a cue to back off "
    "volume — an easy session and a solid night's sleep should help.",
]


# --- Activity / step-goal nudge ----------------------------------------------
# Pattern: behind the step goal with the day still open.
_NUDGE_BEHIND: List[str] = [
    "You're at {steps} steps so far — {remaining} short of your {goal} goal. "
    "A brisk 15-minute walk would close most of that gap.",
    "{steps} steps logged today, {remaining} to go for your {goal} target. "
    "The CDC counts brisk walking toward your weekly activity — a short loop "
    "now keeps the streak alive.",
    "Still {remaining} steps from your {goal} goal ({steps} so far). Even a "
    "couple of short walks before evening gets you there.",
    "Halfway-check: {steps} of {goal} steps. A 10-15 minute walk is the "
    "easiest way to make up the {remaining} you're missing.",
]

# Pattern: almost there — within striking distance of the goal.
_NUDGE_ALMOST_THERE: List[str] = [
    "So close — {steps} steps, just {remaining} from your {goal} goal. One "
    "short walk wraps it up.",
    "You're at {steps} of {goal} steps. Only {remaining} left — a quick lap "
    "around the block does it.",
    "Almost there: {remaining} steps from your {goal} target. Finish strong "
    "with a brief walk before the day's out.",
    "{steps} steps down, {remaining} to your {goal} goal. That's a 5-minute "
    "walk away — go claim it.",
]

# Pattern: goal already met — congratulate, do not nag.
_NUDGE_GOAL_MET: List[str] = [
    "Nice — {steps} steps today, past your {goal} goal. That's a full daily "
    "activity target hit.",
    "Goal cleared: {steps} steps against a {goal} target. The CDC's daily "
    "movement box is well and truly ticked.",
    "{steps} steps and counting — you've already beaten your {goal} goal "
    "today. Anything more is a bonus.",
    "You hit {steps} steps, clear of your {goal} goal. Strong day of "
    "movement — keep it rolling tomorrow.",
]


# =============================================================================
# Helpers
# =============================================================================

def _seed_for_day(day: Optional[date] = None) -> int:
    """Return a stable integer seed for ``day`` (defaults to today, UTC).

    Day-of-epoch — the same value all day, rotating across days. Used to pick a
    variant deterministically so copy is stable within a day yet varied across
    days (``feedback_dynamic_copy_not_robotic.md``).
    """
    d = day or datetime.utcnow().date()
    return (d - date(2020, 1, 1)).days


def _pick(variants: List[str], seed: int, salt: int = 0) -> str:
    """Pick one variant deterministically from ``seed`` (+ a per-pattern salt).

    ``salt`` keeps the three message types from rotating in lockstep — without
    it the briefing, anomaly, and nudge would always land on the same index.
    """
    if not variants:
        return ""
    return variants[(seed + salt) % len(variants)]


def _hm(total_minutes: Optional[int]) -> tuple[int, int]:
    """Split a minute count into (hours, minutes); (0, 0) when None/negative."""
    if total_minutes is None or total_minutes < 0:
        return (0, 0)
    return divmod(int(total_minutes), 60)


def _workout_phrase(workout: Optional[Dict[str, Any]]) -> str:
    """A short noun phrase for today's workout, e.g. 'your upper-body session'.

    Falls back to a generic phrase when no workout is scheduled — the briefing
    must still read naturally for a rest day.
    """
    if not workout:
        return "today's training"
    name = (workout.get("name") or "").strip()
    wtype = (workout.get("type") or "").strip()
    if name:
        return f"your {name} session" if "session" not in name.lower() else f"your {name}"
    if wtype:
        return f"your {wtype} session"
    return "today's training"


def _extract_numbers(text: str) -> List[str]:
    """All digit runs in ``text`` — the rephrase number-integrity check basis."""
    return re.findall(r"\d+", text or "")


def _workout_already_engaged(workout: Optional[Dict[str, Any]]) -> bool:
    """True when today's workout has been manually started or completed.

    Edge case G38 — the briefing must never narrate a *prospective* workout
    change ("we've trimmed today's session") for a workout the user has
    already begun or finished: the deterministic generation never touched it.
    When this is True the briefing acknowledges the workout instead of
    claiming an adjustment to it.
    """
    if not workout:
        return False
    if workout.get("is_completed"):
        return True
    status = str(workout.get("status") or "").strip().lower()
    return status in ("completed", "in_progress")


def _build_game_plan(
    recovery_signal: Optional[Dict[str, Any]],
    nutrition_adjustment: Optional[Dict[str, Any]],
    workout: Optional[Dict[str, Any]],
    seed: int,
) -> Dict[str, Any]:
    """Assemble the Phase-E4 cross-domain game plan from the two deterministic
    upstream adjustments.

    The briefing does NOT compute either adjustment — Phase B3
    (``get_recovery_workout_signal``) and Phase E1
    (``adjust_targets_for_recovery``) already did. This only NARRATES them.

    Edge case G38: a missing domain is simply omitted — no empty section. A
    workout the user already started/completed is acknowledged, never narrated
    as a prospective change.

    Returns:
        ``{"plan_sentence": str, "brief_clauses": [str], "domains": [str],
        "facts": {...}}``. ``plan_sentence`` is the multi-part plan paragraph
        for the home card (empty string when no domain has an adjustment);
        ``brief_clauses`` are the short clauses the one-line banner version
        is built from; ``domains`` lists which domains were narrated.
    """
    workout_engaged = _workout_already_engaged(workout)
    fragments: List[str] = []
    brief_clauses: List[str] = []
    domains: List[str] = []
    facts: Dict[str, Any] = {}

    # --- workout domain ------------------------------------------------------
    # Narrated only when (a) the recovery signal applies AND (b) the user has
    # not already started/completed today's session (edge case G38).
    rs = recovery_signal or {}
    if rs.get("applies") and not workout_engaged:
        adjustment = rs.get("adjustment") or {}
        volume_mult = adjustment.get("volume_multiplier", rs.get("volume_multiplier"))
        swap_to_mobility = bool(adjustment.get("swap_to_mobility"))
        if swap_to_mobility:
            fragments.append(_pick(_GAME_PLAN_WORKOUT_MOBILITY, seed, salt=4))
            brief_clauses.append("mobility-focused day")
        else:
            # volume_pct = how much volume was REMOVED, e.g. 0.70x -> 30%.
            try:
                volume_pct = int(round((1.0 - float(volume_mult)) * 100))
            except (TypeError, ValueError):
                volume_pct = 0
            if volume_pct > 0:
                fragments.append(
                    _pick(_GAME_PLAN_WORKOUT, seed, salt=4).format(
                        volume_pct=volume_pct
                    )
                )
                brief_clauses.append("lighter session planned")
                facts["workout_volume_pct"] = volume_pct
        domains.append("workout")
        facts["recovery_tier"] = rs.get("tier")
    elif rs.get("applies") and workout_engaged:
        # The workout is already underway/done — acknowledge, never re-plan it.
        fragments.append(
            "today's session is already underway, so listen to your body and "
            "keep the effort easy"
        )
        brief_clauses.append("ease back on today's session")
        domains.append("workout")

    # --- nutrition domain ----------------------------------------------------
    na = nutrition_adjustment or {}
    na_reason = na.get("reason")
    if na_reason == "low_recovery":
        protein_delta = na.get("protein_delta_g") or 0
        if na.get("adjusted") and protein_delta > 0:
            fragments.append(
                _pick(_GAME_PLAN_NUTRITION, seed, salt=5).format(
                    protein_delta=protein_delta
                )
            )
            brief_clauses.append(f"protein +{protein_delta}g")
            facts["protein_delta_g"] = protein_delta
        else:
            # Recovery is low but there was no protein target to scale (or a
            # dietary restriction suppressed the bump) — only timing guidance.
            fragments.append(_pick(_GAME_PLAN_NUTRITION_TIMING_ONLY, seed, salt=5))
            brief_clauses.append("front-load your calories")
        domains.append("nutrition")

    if not fragments:
        return {
            "plan_sentence": "",
            "brief_clauses": [],
            "domains": [],
            "facts": facts,
        }

    # Join the per-domain fragments into one natural sentence + the swap line.
    # The fragments carry no terminal punctuation, so the joined plan body is
    # closed with a period before the (already-punctuated) swap line.
    plan_body = _join_clauses(fragments)
    plan_intro = _pick(_GAME_PLAN_INTRO, seed, salt=6).format(plan_body=plan_body)
    plan_intro = plan_intro.rstrip()
    if not plan_intro.endswith((".", "!", "?")):
        plan_intro += "."
    # The concrete swap is appended only when at least one real adjustment was
    # narrated — it is the actionable single change tying the plan together.
    swap = _pick(_GAME_PLAN_SWAP, seed, salt=7)
    plan_sentence = f"{plan_intro} {swap}"

    return {
        "plan_sentence": plan_sentence,
        "brief_clauses": brief_clauses,
        "domains": domains,
        "facts": facts,
    }


def _join_clauses(clauses: List[str]) -> str:
    """Join 1-N clauses into a natural list ("a", "a and b", "a, b and c")."""
    clauses = [c for c in clauses if c]
    if not clauses:
        return ""
    if len(clauses) == 1:
        return clauses[0]
    if len(clauses) == 2:
        return f"{clauses[0]} and {clauses[1]}"
    return ", ".join(clauses[:-1]) + f" and {clauses[-1]}"


# =============================================================================
# Message builders — each returns a dict; ``has_message: False`` is a CLEAN
# empty state, never an error.
# =============================================================================

def _no_message(reason: str) -> Dict[str, Any]:
    """Uniform empty-state result. ``reason`` is a short machine token."""
    return {"has_message": False, "reason": reason}


def build_daily_briefing(
    snapshot: Dict[str, Any],
    today_workout: Optional[Dict[str, Any]] = None,
    day: Optional[date] = None,
    recovery_signal: Optional[Dict[str, Any]] = None,
    nutrition_adjustment: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Build the morning readiness briefing — a cross-domain daily game plan.

    Phase E4: on a poor-recovery day the briefing is ONE connected plan — the
    sleep readout, then today's workout adjustment, the nutrition adjustment,
    and one concrete swap. It NARRATES the two deterministic upstream
    adjustments (``recovery_signal`` from Phase B3, ``nutrition_adjustment``
    from Phase E1); it never re-derives them.

    Args:
        snapshot: the dict from ``get_health_activity_snapshot``.
        today_workout: today's scheduled workout row
            (``{name, type, is_completed, status, ...}``) or None for a rest
            day.
        day: the date to seed variant choice with (defaults to today UTC).
        recovery_signal: the dict from
            ``readiness_utils.get_recovery_workout_signal`` — its ``adjustment``
            payload drives the workout part of the game plan. ``None`` or
            ``{"applies": False}`` => no workout section (edge case G38).
        nutrition_adjustment: the dict from
            ``sleep_aware_nutrition.adjust_targets_for_recovery`` — drives the
            nutrition part. ``None`` or a non-``low_recovery`` reason => no
            nutrition section (edge case G38).

    Returns:
        ``{"has_message": True, "type": "daily_briefing", "pattern": ...,
        "message": str, "brief_message": str, "facts": {...}, "domains":
        [...]}`` — or ``_no_message(reason)`` when there is no usable data
        (no wearable / no consent).

        ``message`` is the full multi-part game plan for the home card;
        ``brief_message`` is a one-line version for the notification banner.
        Both are present for every pattern (for a good night they are the
        same single sentence — there is no game plan to narrate).

    Patterns: ``good_night`` | ``poor_night`` | ``no_sleep`` (edge case F31 —
    a no-sleep day still gets a lighter activity-only briefing, never skipped).
    """
    if not snapshot or not snapshot.get("has_data"):
        return _no_message(snapshot.get("reason", "no_data") if snapshot else "no_data")

    seed = _seed_for_day(day)
    sleep = snapshot.get("last_night_sleep")
    recovery = snapshot.get("recovery") or {}
    workout_phrase = _workout_phrase(today_workout)

    # --- no usable sleep last night -> lighter activity-only briefing --------
    # Stale sleep is treated as "no sleep" for tone (edge case D21 / F31).
    sleep_usable = bool(sleep) and not sleep.get("is_stale") and sleep.get("total_minutes", 0) > 0
    if not sleep_usable:
        template = _pick(_BRIEFING_NO_SLEEP, seed, salt=0)
        message = template.format(workout_phrase=workout_phrase)
        # No sleep => no recovery read => no recovery-driven workout/nutrition
        # adjustment to narrate. The brief version is the same single line.
        return {
            "has_message": True,
            "type": "daily_briefing",
            "pattern": "no_sleep",
            "message": message,
            "brief_message": message,
            "domains": [],
            "facts": {
                "workout": workout_phrase,
                "recovery_score": None,
            },
        }

    total = int(sleep.get("total_minutes") or 0)
    sleep_h, sleep_m = _hm(total)
    recovery_score = recovery.get("score")
    adjustment = recovery.get("adjustment")

    # --- good night ----------------------------------------------------------
    # A good night = >= 7h asleep AND (no recovery score OR recovery not poor).
    # Recovery may be None when sleep can't be fully scored — a long-enough
    # night alone still earns the good-night tone.
    is_poor_recovery = recovery_score is not None and recovery_score <= 60
    if total >= _GOOD_NIGHT_MIN and not is_poor_recovery:
        template = _pick(_BRIEFING_GOOD_NIGHT, seed, salt=1)
        message = template.format(
            sleep_h=sleep_h,
            sleep_m=sleep_m,
            # When recovery is unscored, fall back to a sleep-derived phrasing
            # by reusing the duration — but only the GOOD_NIGHT templates that
            # need {recovery}. Guard with a sane default of the score or 80.
            recovery=recovery_score if recovery_score is not None else 80,
            workout_phrase=workout_phrase,
        )
        # A good night needs no cross-domain adjustment — there is nothing to
        # trim or re-allocate. The brief version is the same single sentence.
        return {
            "has_message": True,
            "type": "daily_briefing",
            "pattern": "good_night",
            "message": message,
            "brief_message": message,
            "domains": [],
            "facts": {
                "sleep_minutes": total,
                "recovery_score": recovery_score,
                "workout": workout_phrase,
            },
        }

    # --- poor night ----------------------------------------------------------
    # Short sleep OR a low recovery score -> trim-the-session briefing.
    safe_adjustment = adjustment or "keep today's effort easy and rest longer"
    recovery_display = (
        recovery_score
        if recovery_score is not None
        else _poor_recovery_fallback(total)
    )

    # --- Phase E4: the cross-domain game plan --------------------------------
    # Narrate today's deterministic workout + nutrition adjustments as ONE
    # connected plan. A domain with no adjustment is simply omitted (G38).
    # Computed BEFORE the sleep readout so the {workout_sentence} placeholder
    # can defer the concrete numbers to the game plan when one will follow.
    game_plan = _build_game_plan(
        recovery_signal=recovery_signal,
        nutrition_adjustment=nutrition_adjustment,
        workout=today_workout,
        seed=seed,
    )

    # Build the workout sentence. When the game plan will narrate a concrete
    # workout adjustment below, keep this a soft lead-in (the numbers come in
    # the plan); otherwise name a lighter session here so the readout stands
    # alone.
    workout_section_in_plan = "workout" in game_plan["domains"]
    nutrition_section_in_plan = "nutrition" in game_plan["domains"]
    if workout_section_in_plan:
        # A soft lead-in — the concrete numbers are narrated in the game plan.
        if nutrition_section_in_plan:
            workout_sentence = (
                f"We've adapted {workout_phrase} and your nutrition to match."
            )
        else:
            workout_sentence = f"We've adapted {workout_phrase} to match."
    elif adjustment and recovery_score is not None and recovery_score <= 60:
        workout_sentence = (
            f"For {workout_phrase}, expect a lighter session today."
        )
    else:
        workout_sentence = (
            f"Take {workout_phrase} at a comfortable effort and stop early "
            f"if you need to."
        )

    template = _pick(_BRIEFING_POOR_NIGHT, seed, salt=1)
    sleep_part = template.format(
        sleep_h=sleep_h,
        sleep_m=sleep_m,
        recovery=recovery_display,
        adjustment=safe_adjustment,
        workout_sentence=workout_sentence,
    )

    facts: Dict[str, Any] = {
        "sleep_minutes": total,
        "recovery_score": recovery_score,
        "adjustment": safe_adjustment,
        "workout": workout_phrase,
    }
    facts.update(game_plan.get("facts") or {})

    if game_plan["plan_sentence"]:
        # Full home-card message: sleep readout + the connected game plan.
        message = f"{sleep_part} {game_plan['plan_sentence']}"
        # Brief one-line banner version: "Recovery 41 — lighter day planned,
        # protein +15g, tap for your plan". Built from the short clauses, so
        # it never just truncates the long copy.
        brief_message = _build_brief_line(
            recovery_display, game_plan["brief_clauses"]
        )
    else:
        # No upstream adjustment to narrate (e.g. recovery scored low from
        # sleep but no wearable recovery signal / no nutrition targets) — the
        # briefing is still the poor-night readout. Brief == full.
        message = sleep_part
        brief_message = sleep_part

    return {
        "has_message": True,
        "type": "daily_briefing",
        "pattern": "poor_night",
        "message": message,
        "brief_message": brief_message,
        "domains": game_plan["domains"],
        "facts": facts,
    }


def build_sleep_score_briefing(
    snapshot: Dict[str, Any],
    day: Optional[date] = None,
) -> Dict[str, Any]:
    """Build the morning SLEEP-SCORE push (FEATURE 1).

    Names the EXACT 0-100 sleep score the in-app Sleep screen shows. The score
    is resolved in this order (no fabrication):
      1. ``snapshot.last_night_sleep['sleep_score']`` — the number the CLIENT
         synced (it has the mid-sleep history the server snapshot lacks, so this
         is the source of truth and matches the Sleep screen exactly);
      2. else the Python port ``compute_sleep_score`` over the snapshot's
         duration / efficiency / deep / REM — a faithful fallback that omits the
         Consistency component just like the app's new-user path.
    A night that yields no score (no asleep minutes) => ``has_message: False``.

    Tone selection (deterministic, by band):
      * score >= 80                       -> HIGH (celebrate).
      * score < 60 + recovery tier
        moderate/good/optimal             -> POOR but recovering (reassure).
      * score < 60 + compromised/low/none -> POOR all (encourage, sleep more).
      * 60 <= score < 80                  -> DEFER. The mid-band is left to the
        daily_readiness briefing so the user gets exactly ONE high-signal
        morning push; ``has_message: False`` with reason ``mid_band_defer``.

    Returns the same dict shape as the other builders, or ``_no_message(reason)``
    for the clean empty states (no data, no_sleep, no_score, mid_band_defer).
    """
    if not snapshot or not snapshot.get("has_data"):
        return _no_message(snapshot.get("reason", "no_data") if snapshot else "no_data")

    sleep = snapshot.get("last_night_sleep")
    # Stale or empty sleep => no honest score to cite.
    if not sleep or sleep.get("is_stale") or (sleep.get("total_minutes") or 0) <= 0:
        return _no_message("no_sleep")

    total = int(sleep.get("total_minutes") or 0)

    # 1) Prefer the client-synced number (matches the Sleep screen exactly).
    score = sleep.get("sleep_score")
    if score is None:
        # 2) Fallback: the Python port over what the snapshot has. Consistency is
        #    omitted and the total renormalised, exactly like the app's no-history
        #    path. Goal comes from the user's health_goals when present (default 8h).
        goals = snapshot.get("goals") or {}
        goal_minutes = goals.get("sleep_duration_goal_minutes") or 480
        from services.sleep_score import compute_sleep_score

        score = compute_sleep_score(
            asleep_minutes=total,
            goal_minutes=goal_minutes,
            efficiency=sleep.get("efficiency"),
            deep_minutes=int(sleep.get("deep_minutes") or 0),
            rem_minutes=int(sleep.get("rem_minutes") or 0),
        )
    if score is None:
        return _no_message("no_score")
    score = int(score)

    # Mid-band defers to the daily_readiness briefing — one morning push only.
    if _SLEEP_SCORE_POOR <= score < _SLEEP_SCORE_HIGH:
        return _no_message("mid_band_defer")

    seed = _seed_for_day(day)
    sleep_h, sleep_m = _hm(total)
    # Wake-up count is synced from the client. When it is absent we have no
    # honest count, so we never fabricate one — the {wake_ups}-citing POOR_ALL
    # variant is only ever PICKED when a real count exists (see below).
    wake_ups_raw = sleep.get("wake_ups")
    has_wake_ups = wake_ups_raw is not None
    wake_ups = int(wake_ups_raw or 0)

    recovery = snapshot.get("recovery") or {}
    tier = recovery.get("tier")

    if score >= _SLEEP_SCORE_HIGH:
        pattern = "high"
        pool = _SLEEP_HIGH
    elif tier in _SLEEP_RECOVERING_TIERS:
        # Poor sleep, but the recovery tier says the body is coping — reassure.
        pattern = "poor_recovering"
        pool = _SLEEP_POOR_RECOVERING
    else:
        # Poor sleep AND poor/unknown recovery — encourage, sleep more tonight.
        pattern = "poor_all"
        pool = _SLEEP_POOR_ALL

    # Pick a variant. If the wake-up count is unknown, drop any variant that
    # cites {wake_ups} so we never print a fabricated "0 wake-ups".
    candidates = pool
    if not has_wake_ups:
        filtered = [t for t in pool if "{wake_ups}" not in t]
        if filtered:
            candidates = filtered
    template = _pick(candidates, seed, salt=8)

    message = template.format(
        score=score,
        wake_ups=wake_ups,
        sleep_h=sleep_h,
        sleep_m=sleep_m,
    )

    return {
        "has_message": True,
        "type": "sleep_score",
        "pattern": pattern,
        "message": message,
        "facts": {
            "sleep_score": score,
            "sleep_minutes": total,
            "wake_ups": wake_ups,
            "recovery_tier": tier,
            "score_source": "synced" if sleep.get("sleep_score") is not None else "fallback",
        },
    }


def _build_brief_line(recovery_display: int, brief_clauses: List[str]) -> str:
    """Build the one-line banner version of the cross-domain game plan.

    e.g. ``"Recovery 41 — lighter session planned, protein +15g. Tap for
    today's plan."`` The clauses come straight from ``_build_game_plan`` so
    the brief line is a real summary, not a truncation of the long copy.
    """
    if not brief_clauses:
        return f"Recovery {recovery_display}. Tap for today's plan."
    body = _join_clauses(brief_clauses)
    return f"Recovery {recovery_display} — {body}. Tap for today's plan."


def _poor_recovery_fallback(total_minutes: int) -> int:
    """A deterministic recovery proxy for a poor-night briefing when the
    snapshot could not score recovery (partial sleep data).

    This is NOT a fabricated wearable number — it is a transparent linear map
    of asleep-minutes onto 0-100 (8h => 100), used only so the poor-night copy
    has a figure. Capped at 60 because this branch only runs for a poor night.
    """
    proxy = int(round(min(100.0, (total_minutes / 480.0) * 100.0)))
    return min(60, max(0, proxy))


def build_health_anomaly(
    snapshot: Dict[str, Any],
    day: Optional[date] = None,
) -> Dict[str, Any]:
    """Build a resting-HR anomaly alert from a Phase-B1 health snapshot.

    Fires only when ALL of these hold (edge case F30):
      * a resting-HR baseline exists (the snapshot only sets it with >= 14
        days of history);
      * today's resting HR is at least ``_RHR_ANOMALY_DELTA`` bpm above it.

    The copy informs and suggests an easier day — it never diagnoses.

    Returns ``{"has_message": True, "type": "health_anomaly", ...}`` or
    ``_no_message(reason)`` (``no_data`` / ``no_baseline`` / ``within_normal``).
    """
    if not snapshot or not snapshot.get("has_data"):
        return _no_message(snapshot.get("reason", "no_data") if snapshot else "no_data")

    hr = snapshot.get("heart_rate") or {}
    resting = hr.get("resting")
    baseline = hr.get("resting_baseline")
    delta = hr.get("resting_vs_baseline")

    # No baseline -> we cannot judge "elevated" honestly (edge case F30 / E25).
    if baseline is None or resting is None or delta is None:
        return _no_message("no_baseline")

    # Not elevated enough -> no alarm. A small wobble is normal.
    if delta < _RHR_ANOMALY_DELTA:
        return _no_message("within_normal")

    seed = _seed_for_day(day)
    template = _pick(_ANOMALY_RHR_ELEVATED, seed, salt=2)
    message = template.format(
        rhr=int(round(resting)),
        baseline=int(round(baseline)),
        delta=int(round(delta)),
    )
    return {
        "has_message": True,
        "type": "health_anomaly",
        "pattern": "rhr_elevated",
        "message": message,
        "facts": {
            "resting_hr": int(round(resting)),
            "baseline": int(round(baseline)),
            "delta": int(round(delta)),
        },
    }


def build_activity_nudge(
    snapshot: Dict[str, Any],
    day: Optional[date] = None,
) -> Dict[str, Any]:
    """Build an activity / step-goal nudge from a Phase-B1 health snapshot.

    Patterns (edge case F32):
      * ``goal_met``     — steps already at/above the goal -> congratulate.
      * ``almost_there`` — within ``_STEP_ALMOST_THERE_FRAC`` of the goal.
      * ``behind``       — below that -> a "close the gap" nudge.

    Uses the user's saved step goal when present, otherwise a CDC-derived
    default of ``_DEFAULT_STEP_GOAL`` so a goal-less user still gets a nudge.

    Returns ``_no_message("no_steps_data")`` when no step count exists today.
    """
    if not snapshot or not snapshot.get("has_data"):
        return _no_message(snapshot.get("reason", "no_data") if snapshot else "no_data")

    steps_info = snapshot.get("steps") or {}
    steps_today = steps_info.get("today")
    if steps_today is None:
        return _no_message("no_steps_data")

    goal = steps_info.get("goal") or _DEFAULT_STEP_GOAL
    if goal <= 0:
        goal = _DEFAULT_STEP_GOAL

    steps_today = int(steps_today)
    remaining = max(0, goal - steps_today)
    frac = steps_today / goal if goal > 0 else 1.0
    seed = _seed_for_day(day)

    if steps_today >= goal:
        pattern = "goal_met"
        template = _pick(_NUDGE_GOAL_MET, seed, salt=3)
        message = template.format(steps=f"{steps_today:,}", goal=f"{goal:,}")
    elif frac >= _STEP_ALMOST_THERE_FRAC:
        pattern = "almost_there"
        template = _pick(_NUDGE_ALMOST_THERE, seed, salt=3)
        message = template.format(
            steps=f"{steps_today:,}", goal=f"{goal:,}", remaining=f"{remaining:,}"
        )
    else:
        pattern = "behind"
        template = _pick(_NUDGE_BEHIND, seed, salt=3)
        message = template.format(
            steps=f"{steps_today:,}", goal=f"{goal:,}", remaining=f"{remaining:,}"
        )

    return {
        "has_message": True,
        "type": "activity_nudge",
        "pattern": pattern,
        "message": message,
        "facts": {
            "steps": steps_today,
            "goal": goal,
            "remaining": remaining,
            "goal_used_default": steps_info.get("goal") is None,
        },
    }


# =============================================================================
# Optional Gemini rephrase — may smooth wording, may NEVER invent/alter numbers.
# =============================================================================

_REPHRASE_PROMPT = (
    "You are a fitness coach editor. Rewrite the message below so it reads "
    "warm, natural, and human, in ONE or TWO short sentences. STRICT RULES:\n"
    "- Keep EVERY number EXACTLY as written. Do not add, remove, round, or "
    "change any number.\n"
    "- Do not add new facts, claims, or medical advice.\n"
    "- Keep it concise and encouraging.\n"
    "Return only the rewritten message.\n\n"
    "Message:\n{draft}"
)


async def rephrase_with_gemini(draft: str, gemini_service: Any) -> str:
    """Optionally smooth ``draft`` via Gemini, with a strict number-integrity
    guard.

    The deterministic draft is always safe to ship. A rephrase is accepted ONLY
    when its multiset of digit runs is identical to the draft's — so the LLM
    can reword but can never invent, drop, or alter a number. Any error, an
    empty response, or a number mismatch falls back to the draft.

    Args:
        draft: the deterministic message from a builder above.
        gemini_service: an object exposing ``async chat(user_message=...)``.

    Returns:
        The rephrased message when it passes the guard, otherwise ``draft``.
    """
    if not draft or not draft.strip():
        return draft
    if gemini_service is None:
        return draft

    try:
        response = await gemini_service.chat(
            user_message=_REPHRASE_PROMPT.format(draft=draft)
        )
    except Exception as e:
        logger.warning(f"health_coaching: Gemini rephrase failed, using draft: {e}")
        return draft

    candidate = (response or "").strip()
    if not candidate:
        return draft

    # Number-integrity guard: the rephrase must carry exactly the same numbers.
    if sorted(_extract_numbers(candidate)) != sorted(_extract_numbers(draft)):
        logger.warning(
            "health_coaching: Gemini rephrase changed the numbers — "
            "rejecting and using the deterministic draft."
        )
        return draft

    return candidate
