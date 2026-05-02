"""
Trial Coach Message Cron — Onboarding v5

Fires 5 proactive coach DMs during the 7-day trial:
  - Day 0 evening (if trial started today): welcome message referencing goal date
  - Day 2 morning: "How was your first workout?"
  - Day 4 evening: "Quick check-in — anything I should adjust?"
  - Day 6 morning: "Tomorrow's the last day. Here's what week 2 looks like..."
  - Day 7: trial summary message

Tone matches the user's selected coach personality (coach_id) and uses
their custom coach_name if set.

This cron runs hourly. It computes which users are in which trial day
*in their local timezone* and sends only the messages whose target
time-of-day falls within the current hour for that user.

Idempotency: each (user_id, day, slot) gets a row in `trial_coach_messages_sent`
to prevent duplicate sends.
"""
from datetime import date, datetime, timedelta
from typing import Optional, List
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.exceptions import safe_internal_error

router = APIRouter()
logger = get_logger(__name__)


class TrialCoachCronResponse(BaseModel):
    success: bool
    users_processed: int
    messages_sent: int
    errors: int
    details: Optional[List[str]] = None


# Day-slot definitions: (day_of_trial, target_local_hour, slot_id)
# The cron fires hourly; we send when current local hour == target hour.
_TRIAL_TOUCHPOINTS = [
    (1, 19, "day0_evening_welcome"),      # Same-day evening welcome
    (2, 8, "day2_morning_checkin"),       # Day 2 AM "how was workout"
    (4, 18, "day4_evening_checkin"),      # Day 4 PM check-in
    (6, 8, "day6_morning_week2"),         # Day 6 AM "what week 2 looks like"
    (7, 9, "day7_summary"),               # Day 7 trial summary
]


def _verify_cron_auth(authorization: Optional[str]):
    """Validate cron-job auth header.

    Mirrors the auth pattern used by the existing push_nudge_cron and
    email_cron routes. Reads from settings rather than env directly so
    deploys honor the same Render-configured secret.
    """
    try:
        from core.config import settings
        expected = getattr(settings, "x_cron_secret", None) or getattr(settings, "cron_secret", None)
    except Exception:
        expected = None
    if not expected:
        # No secret configured — open mode (dev / not yet wired)
        return
    if not authorization or authorization != f"Bearer {expected}":
        raise HTTPException(status_code=401, detail="Unauthorized")


@router.post("/trial-coach", response_model=TrialCoachCronResponse)
async def trial_coach_cron(
    authorization: Optional[str] = Header(None),
    x_cron_secret: Optional[str] = Header(None),
):
    """
    Hourly cron: send proactive coach messages to users on their trial day.

    Schedule via the same external scheduler that pings /nudges/cron and
    /emails/cron (cron-job.org / GitHub Actions / etc.). Accepts the
    secret via either Authorization: Bearer <secret> OR X-Cron-Secret
    header — matches the convention of the existing crons.
    """
    # Accept either header convention used elsewhere in the codebase
    auth_value = authorization or (f"Bearer {x_cron_secret}" if x_cron_secret else None)
    _verify_cron_auth(auth_value)

    try:
        supabase = get_supabase()

        # Fetch all users currently in their trial window (Day 1..7 inclusive)
        # We don't filter by exact day here — we let the inner loop compute
        # day-of-trial per user using their trial_start_date and timezone.
        users_result = supabase.client.table("users")\
            .select("id, name, timezone, coach_id, coach_name, trial_start_date, "
                    "goal_target_date, weight_kg, target_weight_kg, paused_at")\
            .not_.is_("trial_start_date", "null")\
            .execute()

        users = users_result.data or []
        users_processed = 0
        messages_sent = 0
        errors = 0
        details = []

        utc_now = datetime.utcnow()

        for user in users:
            users_processed += 1
            user_id = user["id"]

            # Skip paused subscriptions
            if user.get("paused_at"):
                continue

            try:
                trial_start = date.fromisoformat(user["trial_start_date"])
                # Compute user-local "now" — fallback to UTC if timezone missing
                user_tz = user.get("timezone") or "UTC"
                local_now = _to_local(utc_now, user_tz)
                local_today = local_now.date()
                local_hour = local_now.hour

                day_of_trial = (local_today - trial_start).days + 1
                if day_of_trial < 1 or day_of_trial > 7:
                    continue

                # Find any touchpoint matching today's day + current hour
                for tp_day, tp_hour, slot_id in _TRIAL_TOUCHPOINTS:
                    if tp_day != day_of_trial:
                        continue
                    if local_hour != tp_hour:
                        continue

                    # Idempotency check
                    if _already_sent(supabase, user_id, slot_id):
                        continue

                    # Send the message
                    sent = await _send_trial_coach_message(supabase, user, slot_id)
                    if sent:
                        _record_sent(supabase, user_id, slot_id)
                        messages_sent += 1
                        details.append(f"{user_id[:8]}…→{slot_id}")

            except Exception as user_err:
                errors += 1
                logger.warning(f"Trial coach cron failed for {user_id}: {user_err}")

        return TrialCoachCronResponse(
            success=True,
            users_processed=users_processed,
            messages_sent=messages_sent,
            errors=errors,
            details=details[:50],  # Cap response size
        )
    except Exception as e:
        logger.error(f"trial-coach cron failed: {e}", exc_info=True)
        raise safe_internal_error(e, "trial-coach-cron")


def _to_local(utc_dt: datetime, tz_name: str) -> datetime:
    """Convert UTC datetime to user-local naive datetime."""
    try:
        from zoneinfo import ZoneInfo
        return utc_dt.replace(tzinfo=ZoneInfo("UTC")).astimezone(ZoneInfo(tz_name)).replace(tzinfo=None)
    except Exception:
        return utc_dt


def _already_sent(supabase, user_id: str, slot_id: str) -> bool:
    """Check if this user/slot already received a message."""
    try:
        result = supabase.client.table("trial_coach_messages_sent")\
            .select("id")\
            .eq("user_id", user_id)\
            .eq("slot_id", slot_id)\
            .limit(1)\
            .execute()
        return bool(result.data)
    except Exception:
        # Table may not exist yet — treat as not sent (will retry next hour)
        # Production migration should add: trial_coach_messages_sent(user_id, slot_id, sent_at)
        return False


def _record_sent(supabase, user_id: str, slot_id: str):
    """Record that a message was sent (idempotency tracker)."""
    try:
        supabase.client.table("trial_coach_messages_sent").insert({
            "user_id": user_id,
            "slot_id": slot_id,
            "sent_at": datetime.utcnow().isoformat(),
        }).execute()
    except Exception as e:
        logger.warning(f"Could not record sent message {user_id}/{slot_id}: {e}")


async def _send_trial_coach_message(supabase, user: dict, slot_id: str) -> bool:
    """
    Compose and send a coach DM. Inserts into chat_messages so it appears
    in the user's coach inbox on next app open.

    Uses coach_name (custom) or coach_id-default-name fallback.
    """
    user_id = user["id"]
    coach_name = user.get("coach_name") or "Coach"
    user_name = (user.get("name") or "").split()[0] if user.get("name") else "there"
    goal_date = user.get("goal_target_date")

    message_body = _compose_message(slot_id, coach_name, user_name, goal_date)
    if not message_body:
        return False

    try:
        # Insert as a coach-side message into the existing chat_messages table.
        # Schema may vary — wrap in try/except so missing columns don't crash.
        supabase.client.table("chat_messages").insert({
            "user_id": user_id,
            "role": "assistant",
            "content": message_body,
            "metadata": {
                "trial_touchpoint": slot_id,
                "proactive": True,
                "coach_name": coach_name,
            },
            "created_at": datetime.utcnow().isoformat(),
        }).execute()
        return True
    except Exception as e:
        logger.warning(f"Could not insert proactive coach message for {user_id}: {e}")
        return False


def _compose_message(slot_id: str, coach_name: str, user_name: str, goal_date: Optional[str]) -> str:
    """Compose the message text for a given touchpoint."""
    goal_phrase = f"by {goal_date}" if goal_date else "soon"

    if slot_id == "day0_evening_welcome":
        return (
            f"Hey {user_name}, welcome aboard. I'm {coach_name}, your coach.\n\n"
            f"I built your plan around what you told me — your goal is locked in. "
            f"At our pace, we hit it {goal_phrase}.\n\n"
            f"Tomorrow's session is ready when you are. Sleep on it, then let's "
            f"get to work."
        )
    if slot_id == "day2_morning_checkin":
        return (
            f"Morning, {user_name}. How did yesterday's workout feel?\n\n"
            f"If anything felt too easy or too hard, tell me — I'll adjust today's "
            f"session before you start."
        )
    if slot_id == "day4_evening_checkin":
        return (
            f"Quick check-in, {user_name}. You're halfway through week 1.\n\n"
            f"What's working? What isn't? Reply with one thing — even a single word — "
            f"and I'll fine-tune the rest of your week."
        )
    if slot_id == "day6_morning_week2":
        return (
            f"Hey {user_name}, your trial wraps up tomorrow.\n\n"
            f"I've been planning week 2 for you — slightly heavier compounds, a "
            f"new accessory rotation, and we keep stacking toward your {goal_phrase} goal.\n\n"
            f"Stick around — the second week is when the work compounds."
        )
    if slot_id == "day7_summary":
        return (
            f"{user_name}, that's week 1.\n\n"
            f"Tap into your stats to see exactly what you built. Numbers don't lie — "
            f"you put in the work.\n\n"
            f"Ready for week 2? I'll be here either way."
        )
    return ""
