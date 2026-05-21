"""
Health Coaching Content Engine (Phase C1)
=========================================
Turns the deterministic health snapshot from Phase B1
(``services/user_context/health_activity.py``) into three kinds of *proactive*
coaching messages:

  1. ``build_daily_briefing``   — the morning readiness briefing. Adapts to a
     good vs poor night, the recovery tier, and today's scheduled workout.
  2. ``build_health_anomaly``   — a resting-HR anomaly alert (informs, never
     diagnoses).
  3. ``build_activity_nudge``   — an activity / step-goal nudge (behind, almost
     there, or goal met).

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
) -> Dict[str, Any]:
    """Build the morning readiness briefing from a Phase-B1 health snapshot.

    Args:
        snapshot: the dict from ``get_health_activity_snapshot``.
        today_workout: today's scheduled workout row (``{name, type, ...}``) or
            None for a rest day.
        day: the date to seed variant choice with (defaults to today UTC).

    Returns:
        ``{"has_message": True, "type": "daily_briefing", "pattern": ...,
        "message": str, "facts": {...}}`` — or ``_no_message(reason)`` when
        there is no usable data (no wearable / no consent).

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
        return {
            "has_message": True,
            "type": "daily_briefing",
            "pattern": "no_sleep",
            "message": message,
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
        return {
            "has_message": True,
            "type": "daily_briefing",
            "pattern": "good_night",
            "message": message,
            "facts": {
                "sleep_minutes": total,
                "recovery_score": recovery_score,
                "workout": workout_phrase,
            },
        }

    # --- poor night ----------------------------------------------------------
    # Short sleep OR a low recovery score -> trim-the-session briefing.
    # Build the workout sentence from the recovery adjustment so the briefing
    # names a concrete change, not just "go easy".
    if adjustment and recovery_score is not None and recovery_score <= 60:
        workout_sentence = (
            f"For {workout_phrase}, expect a lighter session today."
        )
    else:
        workout_sentence = (
            f"Take {workout_phrase} at a comfortable effort and stop early "
            f"if you need to."
        )
    safe_adjustment = adjustment or "keep today's effort easy and rest longer"
    template = _pick(_BRIEFING_POOR_NIGHT, seed, salt=1)
    message = template.format(
        sleep_h=sleep_h,
        sleep_m=sleep_m,
        recovery=recovery_score if recovery_score is not None else _poor_recovery_fallback(total),
        adjustment=safe_adjustment,
        workout_sentence=workout_sentence,
    )
    return {
        "has_message": True,
        "type": "daily_briefing",
        "pattern": "poor_night",
        "message": message,
        "facts": {
            "sleep_minutes": total,
            "recovery_score": recovery_score,
            "adjustment": safe_adjustment,
            "workout": workout_phrase,
        },
    }


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
