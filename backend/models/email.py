"""Shared models for the email / notification personalization system.

Types here are consumed by:
- `backend/services/email_helpers.py` (pure rendering helpers)
- `backend/api/v1/email_cron.py` (data-fetch orchestrator + cron jobs)
- `backend/services/email_lifecycle.py` and `email_marketing.py` (email templates)

Design intent: every email-send function takes a `UserStats` so personalization
data flows from one place, and adding a new email type doesn't mean another
round of query-building.
"""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum
from typing import Optional


class ScheduleState(str, Enum):
    """State of the user's workout plan schedule relative to today (user-local).

    This drives whether a lifecycle email fires at all, and if so which voice
    variant — "today's the day" vs guilt vs skip.
    """
    LAUNCHES_TODAY = "launches_today"     # earliest scheduled workout == today
    LAUNCHES_FUTURE = "launches_future"   # earliest scheduled workout > today
    OVERDUE = "overdue"                    # past scheduled date with no completion
    ON_TRACK = "on_track"                  # user has completed all past scheduled
    NO_PLAN = "no_plan"                    # no workouts scheduled yet (onboarding incomplete)


class TimeBand(str, Enum):
    """Time-of-day band in the user's local timezone.

    Quiet wins even during morning/evening clock hours — if the user's
    configured quiet window covers the current moment, `QUIET` is returned
    regardless of the clock hour.
    """
    MORNING = "morning"        # 06-11
    MIDDAY = "midday"          # 11-14
    AFTERNOON = "afternoon"    # 14-18
    EVENING = "evening"        # 18-21
    LATE = "late"              # 21-22:30
    QUIET = "quiet"            # user's quiet window (default 22:30-06)


class CoachStyle(str, Enum):
    """Mirrors `user_ai_settings.coaching_style` used by the push system.

    Drives template-pool selection for motivational emails:
    - gentle: soft copy, no passive-aggressive variants
    - balanced: Duolingo-style default (guilt + celebration)
    - tough_love: harder copy, all-caps, aggressive emoji
    Same daily/weekly volume caps across all three — tone changes, not frequency.
    """
    GENTLE = "gentle"
    BALANCED = "balanced"          # default
    TOUGH_LOVE = "tough_love"


@dataclass
class UserStats:
    """Personalization data for every email/push. All fields NULL-safe.

    Populated by `_get_user_stats()` in `email_cron.py` via parallel queries,
    consumed by render helpers in `email_helpers.py` and every `send_*` method.

    Adding a field:
    1. Add it here with a safe default.
    2. Populate it in `_get_user_stats()` (add a query or reuse one).
    3. Reference it from templates via `stats.field_name`.
    """
    # ── Workouts ──
    workouts_total: int = 0
    workouts_this_week: int = 0
    current_streak_days: int = 0
    longest_streak_days: int = 0
    total_volume_lbs: int = 0
    last_workout_name: Optional[str] = None
    last_workout_days_ago: Optional[int] = None
    next_workout_name: Optional[str] = None
    next_workout_goal: str = "fitness"  # workout_type e.g. "strength", "cardio"

    # ── Schedule (drives tone) ──
    schedule_state: ScheduleState = ScheduleState.NO_PLAN
    days_until_first_workout: Optional[int] = None  # set when LAUNCHES_FUTURE
    days_overdue: Optional[int] = None               # set when OVERDUE

    # ── Nutrition ──
    nutrition_days_logged_this_week: int = 0
    nutrition_avg_calories_week: Optional[int] = None
    nutrition_avg_protein_g_week: Optional[int] = None
    nutrition_logged_today: bool = False

    # ── Gamification ──
    xp_total: int = 0
    xp_level: int = 1
    xp_to_next_level: int = 0
    latest_achievement: Optional[str] = None

    # ── Weight / body ──
    weight_start_lbs: Optional[float] = None
    weight_current_lbs: Optional[float] = None
    weight_delta_lbs: Optional[float] = None  # negative = lost weight

    # ── Persona (from user_ai_settings; fallbacks when row missing) ──
    coach_name: str = "Your Coach"
    coach_style: CoachStyle = CoachStyle.BALANCED
    use_emojis: bool = True

    # ── Time context (in user's local timezone) ──
    time_band: TimeBand = TimeBand.MORNING
    user_tz: str = "UTC"

    # ── Convenience flags ──
    has_any_activity: bool = False  # true if ever logged workout or meal
