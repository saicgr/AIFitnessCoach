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

from datetime import date, datetime
from typing import Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


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
) -> Optional[str]:
    """Central gate — call before sending any nudge/email.

    Returns:
        A reason code string if the notification should be suppressed
        ("vacation" or "comeback"), or None to proceed.

    Args:
        user: dict with in_vacation_mode, vacation_start_date, vacation_end_date,
              in_comeback_mode, timezone. Missing keys are treated as unset.
        nudge_type: Job identifier (e.g. 'morning_workout', 'guilt_day3',
                    'streak_at_risk'). Compared against the channel-specific
                    critical + comeback-blocked sets.
        channel: 'push' or 'email'. Selects which whitelist/blocklist applies.
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

    return None
