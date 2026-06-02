"""Race-goal periodization (Gap 11).

Deterministic mesocycle phase + daily training recommendation for a user with a
dated race/event goal (5K, 10K, half, marathon, triathlon, powerlifting meet,
etc.). The reviewer in the source video was marathon training — this is the
"periodized plan that auto-adjusts day to day from load + recovery" the Google
Health coach implied.

Design:
- PHASE is a pure function of weeks-until-race (base → build → peak → taper →
  race-week → recovery-after). No LLM — periodization is a deterministic sport-
  science schedule (feedback_no_llm_for_safety_classification).
- The DAILY recommendation starts from the phase's intent, then a deterministic
  override layer (recovery tier + ACWR state) can downgrade it to active
  recovery — high load or poor recovery always wins over "it's a build day".
- The coach LAYERS its voice on top of this grounded output; it never invents
  the schedule.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Optional


@dataclass
class RacePhase:
    phase: str                 # base | build | peak | taper | race_week | race_day | post_race | no_date
    weeks_to_race: Optional[float]
    days_to_race: Optional[int]
    weekly_focus: str          # one-line focus for the week
    today_recommendation: str  # today's session intent (post override)
    intensity_ceiling: str     # easy | moderate | hard — the hardest allowed today
    adjusted_for: Optional[str]  # None | "recovery" | "load" — why today was downgraded


# Phase boundaries by weeks-to-race. Tuned for an endurance build; the same
# shape (long base, focused build, short sharpening peak, taper, race week)
# generalizes to most dated goals.
def _phase_for_weeks(weeks: float) -> str:
    if weeks <= 0:
        return "race_day"
    if weeks < 1:
        return "race_week"
    if weeks < 3:
        return "taper"
    if weeks < 6:
        return "peak"
    if weeks < 12:
        return "build"
    return "base"


_PHASE_FOCUS = {
    "base": (
        "Base — build aerobic volume at conversational effort; mostly easy "
        "mileage, one light quality day.",
        "moderate",
    ),
    "build": (
        "Build — add structured quality (tempo + threshold) on top of the base; "
        "keep easy days truly easy.",
        "hard",
    ),
    "peak": (
        "Peak — sharpen with race-pace and VO2 work; volume holds, intensity is "
        "highest of the cycle.",
        "hard",
    ),
    "taper": (
        "Taper — cut volume ~30-50%, keep a little intensity to stay sharp, "
        "prioritize sleep and fuel.",
        "moderate",
    ),
    "race_week": (
        "Race week — minimal volume, short race-pace primers, carb-load late "
        "week, protect recovery.",
        "easy",
    ),
    "race_day": (
        "Race day — execute your plan, fuel early and often, negative-split if "
        "you can.",
        "hard",
    ),
    "post_race": (
        "Recovery — easy movement only for now; let the adaptations land before "
        "the next block.",
        "easy",
    ),
    "no_date": (
        "No event date set — train general fitness; add a race date to unlock a "
        "periodized plan.",
        "moderate",
    ),
}

_INTENSITY_RANK = {"easy": 0, "moderate": 1, "hard": 2}


def compute_race_phase(
    event_date: Optional[date],
    today: date,
    *,
    recovery_tier: Optional[str] = None,
    load_state: Optional[str] = None,
) -> RacePhase:
    """Phase + today's recommendation for a dated goal.

    `recovery_tier` ∈ {optimal, good, moderate, compromised, low} (from the
    readiness tier mapper). `load_state` ∈ {detraining, balanced, loading,
    overreaching, calibration}. Either can downgrade today's ceiling to easy.
    """
    if event_date is None:
        focus, ceiling = _PHASE_FOCUS["no_date"]
        return RacePhase("no_date", None, None, focus, focus, ceiling, None)

    days = (event_date - today).days
    weeks = days / 7.0

    if days < 0:
        # Post-race recovery window (two weeks of easy after the event).
        if days >= -14:
            focus, ceiling = _PHASE_FOCUS["post_race"]
            return RacePhase("post_race", weeks, days, focus, focus, ceiling, None)
        # More than 2 weeks past — treat as no active event.
        focus, ceiling = _PHASE_FOCUS["no_date"]
        return RacePhase("no_date", None, None, focus, focus, ceiling, None)

    phase = _phase_for_weeks(weeks)
    focus, ceiling = _PHASE_FOCUS[phase]
    recommendation = focus
    adjusted_for: Optional[str] = None

    # --- deterministic override: recovery / load can only DOWNGRADE today. ----
    # Race day itself is never downgraded (the user races regardless), but every
    # training day defers to recovery + load — overreaching/poor recovery always
    # wins over "it's a build day".
    if phase not in ("race_day",):
        low_recovery = recovery_tier in ("compromised", "low")
        high_load = load_state == "overreaching"
        if low_recovery or high_load:
            ceiling = "easy"
            reason = "recovery" if low_recovery else "load"
            adjusted_for = reason
            why = (
                "recovery is short" if low_recovery else "training load is spiking"
            )
            recommendation = (
                f"Planned: {focus.split(' — ')[0]}. But {why} today — make it "
                "active recovery (easy movement or mobility) and protect the "
                "bigger sessions later this week."
            )
        elif recovery_tier == "moderate" and _INTENSITY_RANK[ceiling] == 2:
            # Slightly under-recovered on a hard-ceiling day: cap at moderate.
            ceiling = "moderate"
            adjusted_for = "recovery"
            recommendation = (
                f"{focus} Dial the quality back a notch today — recovery is only "
                "moderate, so hit the volume but ease the intensity."
            )

    return RacePhase(phase, round(weeks, 1), days, focus, recommendation, ceiling, adjusted_for)


def format_race_context_for_ai(rp: RacePhase, event_name: Optional[str] = None) -> str:
    """One compact grounded block for the coach prompt. Empty when no event."""
    if rp.phase in ("no_date",):
        return ""
    name = event_name or "your event"
    head = f"RACE GOAL: {name}"
    if rp.days_to_race is not None and rp.days_to_race >= 0:
        head += f" in {rp.days_to_race} day(s)"
    elif rp.phase == "post_race":
        head += " (just finished — recovery window)"
    lines = [
        head + f" · phase: {rp.phase.replace('_', ' ')}.",
        f"This week: {rp.weekly_focus}",
        f"Today: {rp.today_recommendation}",
    ]
    if rp.adjusted_for:
        lines.append(
            f"(Today was auto-adjusted down for {rp.adjusted_for} — respect that.)"
        )
    return "\n".join(lines)
