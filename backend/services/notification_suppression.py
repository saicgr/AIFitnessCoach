"""Centralized suppression gate for push + email notifications.

Two user states drive suppression:

1. Vacation mode — user has manually paused the app. Suppresses ALL notifications
   except a critical whitelist (billing, live chat, subscription lifecycle).
   Fields on users table: in_vacation_mode, vacation_start_date, vacation_end_date.

2. Comeback mode — user is returning from a break. ComebackService manages the
   in_comeback_mode flag. We suppress guilt/shame/missed-workout nudges during
   comeback to avoid punishing users who are already doing the right thing.

Usage:

    from services.notification_suppression import should_suppress_notification

    reason = should_suppress_notification(user, "morning_workout", channel="push")
    if reason:
        logger.debug(f"Skipping push for {user['id']}: {reason}")
        continue

Returns None when the notification should proceed.
"""
from __future__ import annotations

import os
from datetime import date, datetime
from typing import Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


# Master kill-switch for dormancy-band suppression (Goal 1). Default OFF =
# exact current behavior. Mirrors push_nudge_cron._DORMANCY_TAPER_ENABLED so
# the band branch below is a no-op until the env var is flipped. FAIL OPEN.
_DORMANCY_TAPER_ENABLED = os.getenv("DORMANCY_TAPER_ENABLED", "false").strip().lower() == "true"

# Win-back taper nudge types (re-engagement ladder fired at day 3/7/14/30 of
# inactivity). Progress-affirming/playful, never shame — these REPLACE the old
# escalating guilt tiers. Always allowed in non-active bands.
WINBACK_NUDGE_TYPES: frozenset = frozenset({
    "winback_day3",
    "winback_day7",
    "winback_day14",
    "winback_day30",
})

# Health-data-grounded "gift" nudges — the highest-value, lowest-spam category.
# As routine reminders are cut for quiet users, ONE of these may substitute in
# (the rolling weekly cap enforces the "one" part). They tell the user
# something they couldn't know themselves, so they earn the re-open.
HEALTH_INSIGHT_NUDGE_TYPES: frozenset = frozenset({
    "sleep_score",
    "daily_readiness",
    "morning_recovery",
    "health_anomaly",
    "activity_goal",
    "rhr_trend",
    "sleep_debt",
    "evening_recap",
})

# Per-band ALLOW-LISTS. Any push not in the band's allow-list (and not critical)
# is suppressed. Volume strictly decreases as inactivity grows: routine
# reminders survive only in 'cooling' (down-weighted), die from 'lapsed' on;
# only the win-back ladder (+ a health insight while still warm) remains.
_BAND_ALLOWED = {
    "cooling": frozenset({"morning_workout", "streak_at_risk"})
    | WINBACK_NUDGE_TYPES
    | HEALTH_INSIGHT_NUDGE_TYPES,
    "lapsed": WINBACK_NUDGE_TYPES | HEALTH_INSIGHT_NUDGE_TYPES,
    "dormant": WINBACK_NUDGE_TYPES,
    "deep_dormant": WINBACK_NUDGE_TYPES,
}


# Push types that bypass vacation mode.
# Live chat = ongoing support conversation, billing = money/legal, test = dev tooling.
CRITICAL_PUSH_TYPES: frozenset = frozenset({
    "live_chat_message",
    "live_chat_connected",
    "live_chat_ended",
    "billing_reminder",
    "test",
})

# Email types that bypass vacation mode. Subscription lifecycle emails are legal/billing
# and must reach the user regardless of vacation status.
CRITICAL_EMAIL_TYPES: frozenset = frozenset({
    "trial_ending",
    "cancel_grace",
    "cancel_expired",
    "cancel_offer_7d",
    "cancel_offer_14d",
    "cancel_offer_60d",
    "cancel_sunset",
})

# Push nudge types suppressed while in_comeback_mode. Guilt nudges and missed-workout
# reminders punish users who are already following a structured recovery plan.
COMEBACK_SUPPRESSED_PUSH: frozenset = frozenset({
    "guilt_day1",
    "guilt_day2",
    "guilt_day3",
    "guilt_day5",
    "guilt_day7",
    "guilt_day14",
    # Win-back taper types (replace the retired guilt tiers) — a user already in
    # structured comeback mode should not also get the dormancy win-back ladder.
    "winback_day3",
    "winback_day7",
    "winback_day14",
    "winback_day30",
    "streak_at_risk",
    "missed_workout",
})

# Email types suppressed during comeback. Same reasoning: don't re-engage someone
# who is already re-engaged via the structured comeback protocol.
COMEBACK_SUPPRESSED_EMAIL: frozenset = frozenset({
    "streak_at_risk",
    "idle_nudge",
    "one_workout_wonder",
    "win_back_30",
    "premium_idle",
})


def _safe_zone(tz_str: Optional[str]) -> ZoneInfo:
    try:
        return ZoneInfo(tz_str or "UTC")
    except (ZoneInfoNotFoundError, KeyError, TypeError):
        return ZoneInfo("UTC")


def _parse_iso_date(value) -> Optional[date]:
    """Accept date, datetime, or ISO string. Return None on anything else."""
    if value is None or value == "":
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    try:
        return date.fromisoformat(str(value)[:10])
    except (ValueError, TypeError):
        return None


def is_user_on_vacation(user: dict) -> bool:
    """Return True when the user is currently on vacation in their local timezone.

    Requires the user dict to have: in_vacation_mode, vacation_start_date,
    vacation_end_date, timezone. Start/end can be NULL — open-ended vacations
    (e.g. "off until I come back") are valid.

    The vacation window is [start, end] inclusive, evaluated against today in
    the user's local timezone. If start is in the future, vacation is scheduled
    but not yet active. If end is past, vacation has concluded — callers may
    choose to clear the flag lazily.
    """
    if not user.get("in_vacation_mode"):
        return False

    tz = _safe_zone(user.get("timezone"))
    today = datetime.now(tz).date()

    start = _parse_iso_date(user.get("vacation_start_date"))
    end = _parse_iso_date(user.get("vacation_end_date"))

    if start is not None and today < start:
        return False
    if end is not None and today > end:
        return False
    return True


def is_user_in_comeback(user: dict) -> bool:
    """Return True when ComebackService has flagged the user as in comeback mode."""
    return bool(user.get("in_comeback_mode"))


def should_suppress_notification(
    user: dict,
    nudge_type: str,
    channel: str = "push",
    dormancy_band: Optional[str] = None,
) -> Optional[str]:
    """Central gate — call before sending any nudge/email.

    Returns:
        A reason code string if the notification should be suppressed
        ("vacation", "comeback", or "dormancy_<band>"), or None to proceed.

    Args:
        user: dict with in_vacation_mode, vacation_start_date, vacation_end_date,
              in_comeback_mode, timezone. Missing keys are treated as unset.
        nudge_type: Job identifier (e.g. 'morning_workout', 'winback_day3',
                    'streak_at_risk'). Compared against the channel-specific
                    critical + comeback-blocked sets.
        channel: 'push' or 'email'. Selects which whitelist/blocklist applies.
        dormancy_band: optional 'active'|'cooling'|'lapsed'|'dormant'|
                    'deep_dormant' from push_nudge_cron._dormancy_band. When
                    omitted (e.g. email paths) or 'active', band suppression is
                    skipped — backward compatible. Only enforced when the
                    DORMANCY_TAPER_ENABLED flag is on (fail-open otherwise).
    """
    if channel == "push":
        critical = CRITICAL_PUSH_TYPES
        comeback_blocked = COMEBACK_SUPPRESSED_PUSH
    elif channel == "email":
        critical = CRITICAL_EMAIL_TYPES
        comeback_blocked = COMEBACK_SUPPRESSED_EMAIL
    else:
        # Unknown channel — apply the strictest rules (treat like push).
        critical = CRITICAL_PUSH_TYPES
        comeback_blocked = COMEBACK_SUPPRESSED_PUSH

    # Vacation takes precedence — suppress everything except the critical whitelist.
    if nudge_type not in critical and is_user_on_vacation(user):
        return "vacation"

    # Comeback only suppresses specific job types that would punish recovery.
    if nudge_type in comeback_blocked and is_user_in_comeback(user):
        return "comeback"

    # Dormancy taper — for quiet users, suppress routine reminders and allow only
    # the band's allow-list (win-back ladder + a health insight while warm).
    # Critical types always pass. Flag-gated + fail-open: when the flag is off or
    # the band is 'active'/None/unknown, nothing is suppressed here.
    if (
        _DORMANCY_TAPER_ENABLED
        and dormancy_band
        and dormancy_band != "active"
        and nudge_type not in critical
    ):
        allowed = _BAND_ALLOWED.get(dormancy_band)
        # Unknown band → fail open (allow). Known band → suppress anything not
        # explicitly allowed for that band.
        if allowed is not None and nudge_type not in allowed:
            return f"dormancy_{dormancy_band}"

    return None
