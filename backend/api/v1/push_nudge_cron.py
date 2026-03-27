"""
Push Nudge Accountability Cron — Hourly timezone-aware accountability notifications.

POST /api/v1/nudges/cron
POST /api/v1/nudges/test/{user_id}

This module implements the proactive AI Accountability Coach. It sends push
notifications that mimic a personal trainer following up with their client:
- "Your Chest & Triceps is waiting!"
- "You haven't logged lunch yet!"
- "Your 12-day streak ends tonight!"

Notifications are sent as FCM push AND saved to chat_messages so the coach's
message appears in the AI chat. When a user taps the notification, it opens
the chat with the message already there — they can respond naturally.

Schedule: Render Cron Job at `0 * * * *` (every hour, on the hour)
Security: X-Cron-Secret header (HMAC compare_digest)

Architecture:
    - Groups users by IANA timezone to compute local hours efficiently
    - Each nudge job checks: preference gate → quiet hours → dedup → daily cap
    - Messages use the user's selected coach persona (name, style, tone)
    - Gemini AI personalizes messages when enabled, with template pool fallback
    - All messages saved to chat_messages before sending push (for chat integration)
    - Deduplication via UNIQUE(user_id, nudge_type, nudge_date) in push_nudge_log

Edge cases handled:
    - New users (< 3 days): only workout reminders, no meal/habit/guilt nudges
    - Feature not adopted: skip meal reminders if user never logged a meal
    - Rest days: skip workout reminders if no workout scheduled today
    - Active workout session: skip missed workout if workout is in progress
    - Already completed: skip missed workout if today's workout is done
    - No FCM token: skip gracefully
    - No ai_settings: fall back to "Your Coach" name and default style
    - Quiet hours: never send during user's configured quiet window
    - Daily cap: configurable max nudges per day (default 4)
    - Cron retry/overlap: UNIQUE index prevents duplicate sends
"""
import asyncio
import hmac
from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any, Tuple
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import APIRouter, Header, HTTPException, Request
from fastapi.responses import JSONResponse

from core.supabase_client import get_supabase
from core.config import get_settings
from core.logger import get_logger
from core.rate_limiter import limiter
from services.notification_service import get_notification_service

logger = get_logger(__name__)
router = APIRouter()

BATCH_SIZE = 50


# ─── Security ───────────────────────────────────────────────────────────────

def _verify_cron_secret(request: Request, x_cron_secret: Optional[str] = None):
    """Raise 401/403 if the X-Cron-Secret header is missing/wrong or IP is not allowed."""
    settings = get_settings()
    cron_secret = settings.cron_secret
    if not cron_secret:
        raise HTTPException(status_code=503, detail="Cron not configured — set CRON_SECRET env var")
    if len(cron_secret) < 32:
        logger.warning("⚠️ CRON_SECRET is shorter than 32 characters — consider using a stronger secret")
    if not x_cron_secret or not hmac.compare_digest(x_cron_secret, cron_secret):
        logger.warning("Nudge cron endpoint called with invalid secret")
        raise HTTPException(status_code=401, detail="Invalid cron secret")

    # IP allowlist check
    allowed_ips_str = settings.cron_allowed_ips
    if allowed_ips_str:
        allowed_ips = [ip.strip() for ip in allowed_ips_str.split(",") if ip.strip()]
        # Prefer X-Forwarded-For (first hop) for proxied environments, fall back to direct client IP
        forwarded_for = request.headers.get("X-Forwarded-For")
        client_ip = forwarded_for.split(",")[0].strip() if forwarded_for else (request.client.host if request.client else None)
        if not client_ip or client_ip not in allowed_ips:
            logger.warning(f"Cron endpoint called from disallowed IP: {client_ip}")
            raise HTTPException(status_code=403, detail="IP not allowed")


# ─── Timezone Helpers ────────────────────────────────────────────────────────

def _safe_zone(tz_str: str) -> ZoneInfo:
    """Return a ZoneInfo, falling back to UTC on invalid input."""
    try:
        return ZoneInfo(tz_str)
    except (ZoneInfoNotFoundError, KeyError):
        return ZoneInfo("UTC")


def _get_user_local_hour(timezone_str: str) -> int:
    """Get the current local hour for a timezone."""
    tz = _safe_zone(timezone_str)
    return datetime.now(tz).hour


def _get_user_local_date(timezone_str: str) -> str:
    """Get today's date string in the user's timezone (YYYY-MM-DD)."""
    tz = _safe_zone(timezone_str)
    return datetime.now(tz).strftime("%Y-%m-%d")


def _parse_time_hour(time_str: str) -> int:
    """Parse 'HH:MM' string and return the hour. Falls back to 8 on error."""
    try:
        return int(time_str.split(":")[0])
    except (ValueError, IndexError, AttributeError):
        return 8


def _is_in_quiet_hours(prefs: dict, local_hour: int) -> bool:
    """Check if local_hour falls within user's quiet hours.

    EDGE CASE: Quiet hours that wrap midnight (e.g., 22:00-08:00)
    are handled correctly.
    """
    start = _parse_time_hour(prefs.get("quiet_hours_start", "22:00"))
    end = _parse_time_hour(prefs.get("quiet_hours_end", "08:00"))
    if start > end:  # Wraps midnight (e.g., 22-08)
        return local_hour >= start or local_hour < end
    return start <= local_hour < end


def _get_optimal_hour(user: dict, nudge_type: str, fallback_hour: int) -> int:
    """Return optimal send hour for this user/nudge type, falling back to preference.

    Uses pre-calculated optimal times from user_optimal_send_times table
    (populated daily by optimal_time_service.recalculate_all_optimal_times).
    Only overrides user preference when confidence > 0.5.
    """
    optimal_times = user.get("_optimal_times") or {}
    confidence = optimal_times.get("confidence_score", 0)
    if confidence < 0.5:
        return fallback_hour

    hour_key = {
        "morning_workout": "workout_reminder_hour",
        "missed_workout": "workout_reminder_hour",
        "meal_reminder": "nutrition_reminder_hour",
        "streak_alert": "general_optimal_hour",
        "readiness_checkin": "general_optimal_hour",
        "habit_reminder": "general_optimal_hour",
        "weekly_goals": "general_optimal_hour",
    }.get(nudge_type, "general_optimal_hour")

    optimal_hour = optimal_times.get(hour_key)
    if optimal_hour is not None:
        return optimal_hour
    return fallback_hour


def _user_account_age_days(user: dict) -> int:
    """Return the number of days since user account creation.

    EDGE CASE: Returns 999 if created_at is missing (treat as old account).
    """
    created_at = user.get("created_at")
    if not created_at:
        return 999
    try:
        if isinstance(created_at, str):
            created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
        else:
            created = created_at
        return (datetime.now(ZoneInfo("UTC")) - created).days
    except Exception:
        return 999


# ─── Deduplication ───────────────────────────────────────────────────────────

def _try_dedup_insert(supabase, user_id: str, nudge_type: str, nudge_date: str,
                      chat_message_id: Optional[str] = None) -> bool:
    """Attempt to insert a dedup record. Returns True if successful (not a duplicate).

    Uses the UNIQUE index on (user_id, nudge_type, nudge_date) for atomic dedup.
    If the insert fails with a conflict, the nudge was already sent today.
    """
    try:
        row = {
            "user_id": user_id,
            "nudge_type": nudge_type,
            "nudge_date": nudge_date,
        }
        if chat_message_id:
            row["chat_message_id"] = chat_message_id
        supabase.client.table("push_nudge_log").insert(row).execute()
        return True
    except Exception as e:
        # EDGE CASE: UNIQUE constraint violation = already sent today
        if "duplicate" in str(e).lower() or "unique" in str(e).lower() or "23505" in str(e):
            return False
        logger.error(f"❌ [Nudge] Dedup insert error: {e}")
        return False


def _count_nudges_today(supabase, user_id: str, nudge_date: str) -> int:
    """Count how many nudges were sent to this user today (for daily cap)."""
    try:
        result = supabase.client.table("push_nudge_log") \
            .select("id", count="exact") \
            .eq("user_id", user_id) \
            .eq("nudge_date", nudge_date) \
            .execute()
        return result.count or 0
    except Exception:
        return 0


# ─── User Data Fetching ─────────────────────────────────────────────────────

def _fetch_nudge_eligible_users(supabase) -> List[dict]:
    """Fetch all users who have FCM tokens and notification preferences.

    Returns a list of user dicts with: id, name, email, fcm_token, timezone,
    notification_preferences, created_at.
    """
    try:
        result = supabase.client.table("users") \
            .select("id, name, email, fcm_token, timezone, notification_preferences, created_at") \
            .not_.is_("fcm_token", "null") \
            .execute()
        return result.data or []
    except Exception as e:
        logger.error(f"❌ [Nudge] Failed to fetch users: {e}")
        return []


def _fetch_ai_settings_batch(supabase, user_ids: List[str]) -> Dict[str, dict]:
    """Batch-fetch ai_settings for a list of user IDs.

    Returns a dict mapping user_id → ai_settings row.
    EDGE CASE: Users without ai_settings get an empty dict (default coach persona).
    """
    if not user_ids:
        return {}
    try:
        result = supabase.client.table("user_ai_settings") \
            .select("user_id, coach_name, coaching_style, communication_tone, use_emojis, encouragement_level") \
            .in_("user_id", user_ids[:500]) \
            .execute()
        return {row["user_id"]: row for row in (result.data or [])}
    except Exception as e:
        logger.error(f"❌ [Nudge] Failed to fetch ai_settings: {e}")
        return {}


def _fetch_optimal_times_batch(supabase, user_ids: List[str]) -> Dict[str, dict]:
    """Batch-fetch pre-calculated optimal send times for users.

    Returns a dict mapping user_id → optimal times row.
    Populated daily by optimal_time_service.recalculate_all_optimal_times().
    """
    if not user_ids:
        return {}
    try:
        result = supabase.client.table("user_optimal_send_times") \
            .select("user_id, workout_reminder_hour, nutrition_reminder_hour, general_optimal_hour, confidence_score") \
            .in_("user_id", user_ids[:500]) \
            .execute()
        return {row["user_id"]: row for row in (result.data or [])}
    except Exception as e:
        logger.error(f"❌ [Nudge] Failed to fetch optimal times: {e}")
        return {}


# ─── Core Nudge Sender ──────────────────────────────────────────────────────

async def _send_nudge(
    supabase, notif_svc, user: dict, nudge_type: str, context_dict: dict
) -> bool:
    """Generate persona-aware message, save to chat, send FCM push.

    This is the core function called by all nudge jobs. It:
    1. Checks daily cap
    2. Inserts dedup record (atomic via UNIQUE constraint)
    3. Gets coach persona from user's ai_settings
    4. Generates personalized message (Gemini or template fallback)
    5. Saves message to chat_messages table (AI-initiated, proactive)
    6. Sends FCM push notification with coach name as title

    Args:
        supabase: Supabase client
        notif_svc: NotificationService instance
        user: User dict with id, name, fcm_token, timezone, notification_preferences, _ai_settings
        nudge_type: Type of nudge (e.g., 'morning_workout', 'guilt_day3')
        context_dict: Context for message generation (workout_name, streak, days, etc.)

    Returns:
        True if nudge was sent successfully, False otherwise.

    Notes:
        - EDGE CASE: If chat_messages insert fails, still sends push (message just won't be in chat)
        - EDGE CASE: If FCM send fails, the chat message and dedup record still exist
        - EDGE CASE: Daily cap checked BEFORE dedup insert to avoid wasting dedup slots
    """
    user_id = str(user["id"])
    tz_str = user.get("timezone") or "UTC"
    local_date = _get_user_local_date(tz_str)
    prefs = user.get("notification_preferences") or {}

    # 1. Daily cap check (BEFORE dedup insert)
    daily_limit = prefs.get("daily_nudge_limit", 4)
    if _count_nudges_today(supabase, user_id, local_date) >= daily_limit:
        return False

    # 2. Dedup check (atomic via UNIQUE constraint)
    if not _try_dedup_insert(supabase, user_id, nudge_type, local_date):
        return False

    # 3. Get coach persona
    ai_settings = user.get("_ai_settings") or {}
    coach_name = ai_settings.get("coach_name") or "Your Coach"
    coaching_style = ai_settings.get("coaching_style", "motivational")
    communication_tone = ai_settings.get("communication_tone", "encouraging")
    use_emojis = ai_settings.get("use_emojis", True)
    intensity = prefs.get("accountability_intensity", "balanced")
    use_ai = prefs.get("ai_personalized_nudges", True)

    # 4. Generate message
    message = await notif_svc.generate_accountability_message(
        nudge_type=nudge_type,
        context_dict=context_dict,
        user_name=user.get("name"),
        coach_name=coach_name,
        coaching_style=coaching_style,
        communication_tone=communication_tone,
        use_emojis=use_emojis,
        accountability_intensity=intensity,
        use_ai=use_ai,
    )

    # 5. Save to chat_history (AI-initiated, proactive)
    chat_message_id = None
    try:
        chat_msg = supabase.client.table("chat_history").insert({
            "user_id": user_id,
            "user_message": "",
            "ai_response": message,
            "context_json": {
                "nudge_type": nudge_type,
                "proactive": True,
                "coach_name": coach_name,
                "coaching_style": coaching_style,
                **{k: v for k, v in context_dict.items() if isinstance(v, (str, int, float, bool))},
            }
        }).execute()
        if chat_msg.data:
            chat_message_id = chat_msg.data[0].get("id")
    except Exception as e:
        # EDGE CASE: Chat save failed — still send push, just no chat history
        logger.warning(f"⚠️ [Nudge] chat_history insert failed for {user_id}: {e}")

    # Update dedup record with chat_message_id if available
    if chat_message_id:
        try:
            supabase.client.table("push_nudge_log") \
                .update({"chat_message_id": str(chat_message_id)}) \
                .eq("user_id", user_id) \
                .eq("nudge_type", nudge_type) \
                .eq("nudge_date", local_date) \
                .execute()
        except Exception:
            pass  # Non-critical

    # 6. Send FCM push
    fcm_token = user.get("fcm_token")
    if not fcm_token:
        logger.debug(f"⏭️ [Nudge] Skipping {user_id} — no FCM token registered")
        return False

    context_dict["chat_message_id"] = str(chat_message_id) if chat_message_id else ""
    success, _ = await notif_svc.send_accountability_nudge(
        fcm_token=fcm_token,
        nudge_type=nudge_type,
        context_dict=context_dict,
        user_name=user.get("name"),
        coach_name=coach_name,
        coaching_style=coaching_style,
        communication_tone=communication_tone,
        use_emojis=use_emojis,
        accountability_intensity=intensity,
        use_ai=False,  # Already generated the message — use it directly
    )

    if success:
        logger.info(f"✅ [Nudge] {nudge_type} sent to {user_id} ({coach_name})")
    return success


# ─── Nudge Jobs ──────────────────────────────────────────────────────────────

async def _job_morning_workout_reminder(supabase, notif_svc, users: List[dict]) -> int:
    """Send morning workout reminders to users whose local hour matches their preferred time.

    EDGE CASE: Skip if no workout scheduled today (rest day)
    EDGE CASE: Skip if workout already completed today
    EDGE CASE: Skip first 0 days (send from day 1 — workout reminders are always on)
    """
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("workout_reminders", True):
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        pref_hour = _parse_time_hour(prefs.get("workout_reminder_time", "08:00"))
        reminder_hour = _get_optimal_hour(user, "morning_workout", pref_hour)

        if local_hour != reminder_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        # Check if user has an uncompleted workout today
        user_today = _get_user_local_date(tz_str)
        try:
            workouts = supabase.client.table("workouts") \
                .select("id, name") \
                .eq("user_id", str(user["id"])) \
                .eq("scheduled_date", user_today) \
                .eq("is_completed", False) \
                .limit(1) \
                .execute()
            if not workouts.data:
                continue  # EDGE CASE: No workout today (rest day) or already completed
            workout_name = workouts.data[0].get("name", "your workout")
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "morning_workout", {
            "workout_name": workout_name,
        })
        if success:
            sent += 1

    return sent


async def _job_missed_workout_nudge(supabase, notif_svc, users: List[dict]) -> int:
    """Send evening nudge if user hasn't completed today's workout.

    EDGE CASE: Skip if workout already completed
    EDGE CASE: Skip if no workout scheduled (rest day)
    EDGE CASE: Skip new users (< 3 days old) — gradual onboarding
    EDGE CASE: Skip if user has active workout session (started but not completed)
    """
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("missed_workout_nudge", True):
            continue

        # EDGE CASE: Gradual onboarding — no missed workout nudges for first 3 days
        if _user_account_age_days(user) < 3:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        pref_hour = _parse_time_hour(prefs.get("missed_workout_time", "19:00"))
        nudge_hour = _get_optimal_hour(user, "missed_workout", pref_hour)

        if local_hour != nudge_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_today = _get_user_local_date(tz_str)
        try:
            workouts = supabase.client.table("workouts") \
                .select("id, name, is_completed") \
                .eq("user_id", str(user["id"])) \
                .eq("scheduled_date", user_today) \
                .limit(1) \
                .execute()
            if not workouts.data:
                continue  # EDGE CASE: No workout scheduled (rest day)
            workout = workouts.data[0]
            if workout.get("is_completed", False):
                continue  # EDGE CASE: Already completed
            workout_name = workout.get("name", "your workout")
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "missed_workout", {
            "workout_name": workout_name,
        })
        if success:
            sent += 1

    return sent


async def _job_meal_reminders(supabase, notif_svc, users: List[dict]) -> int:
    """Send meal logging reminders at breakfast/lunch/dinner times.

    EDGE CASE: Skip if user has NEVER logged a meal (feature not adopted)
    EDGE CASE: Skip if meal already logged for this meal type today
    EDGE CASE: Skip new users (< 4 days old) — gradual onboarding
    """
    sent = 0
    meal_config = [
        ("breakfast", "nutrition_breakfast_time", "08:00"),
        ("lunch", "nutrition_lunch_time", "12:00"),
        ("dinner", "nutrition_dinner_time", "18:00"),
    ]

    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("nutrition_reminders", True):
            continue

        # EDGE CASE: Gradual onboarding — no meal nudges for first 4 days
        if _user_account_age_days(user) < 4:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        for meal_type, pref_key, default_time in meal_config:
            pref_meal_hour = _parse_time_hour(prefs.get(pref_key, default_time))
            meal_hour = _get_optimal_hour(user, "meal_reminder", pref_meal_hour)
            if local_hour != meal_hour:
                continue
            if _is_in_quiet_hours(prefs, local_hour):
                continue

            # EDGE CASE: Check if user has ever logged a meal (feature adoption)
            try:
                ever_logged = supabase.client.table("food_logs") \
                    .select("id") \
                    .eq("user_id", user_id) \
                    .limit(1) \
                    .execute()
                if not ever_logged.data:
                    continue  # User has never used meal logging
            except Exception:
                continue

            # Check if meal already logged today
            try:
                today_meal = supabase.client.table("food_logs") \
                    .select("id") \
                    .eq("user_id", user_id) \
                    .eq("meal_type", meal_type) \
                    .gte("logged_at", f"{user_today}T00:00:00") \
                    .lte("logged_at", f"{user_today}T23:59:59") \
                    .limit(1) \
                    .execute()
                if today_meal.data:
                    continue  # EDGE CASE: Already logged this meal today
            except Exception:
                continue

            success = await _send_nudge(supabase, notif_svc, user, f"meal_{meal_type}", {
                "meal_type": meal_type.capitalize(),
            })
            if success:
                sent += 1

    return sent


async def _job_streak_at_risk(supabase, notif_svc, users: List[dict]) -> int:
    """Send streak-at-risk push if streak would break at midnight.

    EDGE CASE: Only send if streak >= 2 (a 1-day streak isn't worth saving)
    EDGE CASE: Skip if workout already completed today
    EDGE CASE: Skip rest days — if no workout is scheduled, the streak can't break
    """
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("streak_alerts", True):
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        pref_hour = _parse_time_hour(prefs.get("streak_alert_time", "20:00"))
        alert_hour = _get_optimal_hour(user, "streak_alert", pref_hour)

        if local_hour != alert_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        # Check streak status
        try:
            streak_data = supabase.client.table("user_login_streaks") \
                .select("current_streak") \
                .eq("user_id", user_id) \
                .limit(1) \
                .execute()
            if not streak_data.data:
                continue
            current_streak = streak_data.data[0].get("current_streak", 0)
            if current_streak < 2:
                continue  # EDGE CASE: 1-day streak not worth saving
        except Exception:
            continue

        # Check if workout already completed today
        try:
            completed = supabase.client.table("workouts") \
                .select("id") \
                .eq("user_id", user_id) \
                .eq("scheduled_date", user_today) \
                .eq("is_completed", True) \
                .limit(1) \
                .execute()
            if completed.data:
                continue  # EDGE CASE: Already completed today
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "streak_at_risk", {
            "streak": current_streak,
        })
        if success:
            sent += 1

    return sent


async def _job_weekly_checkin(supabase, notif_svc, users: List[dict]) -> int:
    """Send weekly nutrition check-in reminder.

    EDGE CASE: Only send on the user's configured check-in day (default Sunday)
    EDGE CASE: Skip if user doesn't use nutrition features
    """
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("weekly_checkin_reminder", True):
            continue

        tz_str = user.get("timezone") or "UTC"
        local_now = datetime.now(_safe_zone(tz_str))
        local_hour = local_now.hour
        local_weekday = local_now.weekday()  # 0=Monday, 6=Sunday

        # Convert user's preference (0=Sunday) to Python weekday (6=Sunday)
        pref_day = prefs.get("weekly_checkin_day", 0)
        python_weekday = 6 if pref_day == 0 else pref_day - 1

        if local_weekday != python_weekday:
            continue

        pref_checkin_hour = _parse_time_hour(prefs.get("weekly_checkin_time", "09:00"))
        checkin_hour = _get_optimal_hour(user, "readiness_checkin", pref_checkin_hour)
        if local_hour != checkin_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        success = await _send_nudge(supabase, notif_svc, user, "weekly_checkin", {})
        if success:
            sent += 1

    return sent


async def _job_habit_reminder(supabase, notif_svc, users: List[dict]) -> int:
    """Send habit completion reminder in the evening.

    EDGE CASE: Skip if no active habits exist for user
    EDGE CASE: Skip if all habits already completed today
    EDGE CASE: Skip new users (< 7 days old) — gradual onboarding
    """
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("habit_reminders", True):
            continue

        # EDGE CASE: Gradual onboarding — no habit nudges for first 7 days
        if _user_account_age_days(user) < 7:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        pref_hour = _parse_time_hour(prefs.get("habit_reminder_time", "20:00"))
        reminder_hour = _get_optimal_hour(user, "habit_reminder", pref_hour)

        if local_hour != reminder_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        # Check for active habits with incomplete logs today
        try:
            habits = supabase.client.table("habits") \
                .select("id") \
                .eq("user_id", user_id) \
                .eq("is_active", True) \
                .execute()
            if not habits.data:
                continue  # EDGE CASE: No active habits

            habit_ids = [h["id"] for h in habits.data]
            total_habits = len(habit_ids)

            # Count completed habit logs for today
            completed_logs = supabase.client.table("habit_logs") \
                .select("id", count="exact") \
                .eq("user_id", user_id) \
                .eq("log_date", user_today) \
                .eq("completed", True) \
                .execute()
            completed_count = completed_logs.count or 0
            incomplete_count = total_habits - completed_count

            if incomplete_count <= 0:
                continue  # EDGE CASE: All habits completed today
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "habit_reminder", {
            "incomplete_count": incomplete_count,
        })
        if success:
            sent += 1

    return sent


async def _job_guilt_escalation(supabase, notif_svc, users: List[dict]) -> int:
    """Send Duolingo-style escalating guilt notifications based on days inactive.

    Tiers: 1, 2, 3, 5, 7, 14+ days without a workout.
    Each tier has its own dedup key (guilt_day1, guilt_day2, etc.) so the user
    gets exactly one notification per tier as days accumulate.

    EDGE CASE: Skip if accountability_intensity is "off"
    EDGE CASE: Skip if guilt_notifications is false
    EDGE CASE: Skip new users (< 3 days old)
    EDGE CASE: 14+ tier uses 14 as the key regardless of actual days
    """
    sent = 0
    tiers = [1, 2, 3, 5, 7, 14]

    for user in users:
        prefs = user.get("notification_preferences") or {}

        # Check preference gates
        intensity = prefs.get("accountability_intensity", "balanced")
        if intensity == "off":
            continue
        if not prefs.get("guilt_notifications", True):
            continue

        # EDGE CASE: No guilt for brand new accounts
        if _user_account_age_days(user) < 3:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)

        # Send guilt at 10:00 local time
        if local_hour != 10:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])

        # Calculate days since last workout
        try:
            last_workout = supabase.client.table("workout_logs") \
                .select("completed_at") \
                .eq("user_id", user_id) \
                .order("completed_at", desc=True) \
                .limit(1) \
                .execute()

            if not last_workout.data:
                # EDGE CASE: User has NEVER completed a workout — skip guilt
                # (they should get day3_activation email instead)
                continue

            completed_at = last_workout.data[0].get("completed_at")
            if not completed_at:
                continue

            if isinstance(completed_at, str):
                last_date = datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
            else:
                last_date = completed_at

            days_inactive = (datetime.now(ZoneInfo("UTC")) - last_date).days
        except Exception:
            continue

        if days_inactive < 1:
            continue  # Worked out today or yesterday

        # Find the appropriate tier
        # EDGE CASE: 14+ tier catches all long absences
        tier = 14
        for t in tiers:
            if days_inactive <= t:
                tier = t
                break

        nudge_type = f"guilt_day{tier}"

        success = await _send_nudge(supabase, notif_svc, user, nudge_type, {
            "days": days_inactive,
        })
        if success:
            sent += 1

    return sent


# ─── Main Cron Endpoint ─────────────────────────────────────────────────────

@router.post("/cron")
@limiter.limit("5/minute")
async def run_push_nudge_cron(
    request: Request,
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
):
    """
    Hourly cron: send timezone-aware accountability push notifications.

    Called every hour by Render Cron Job (`0 * * * *`).
    Each run processes all users, filtering by their local hour to determine
    which nudge jobs apply to them at this moment.

    Returns:
        JSON with job results, total sent count, and execution time.
    """
    _verify_cron_secret(request, x_cron_secret)

    start_time = datetime.utcnow()
    supabase = get_supabase()
    notif_svc = get_notification_service()

    # Fetch all eligible users (with FCM tokens)
    users = _fetch_nudge_eligible_users(supabase)
    if not users:
        return {"jobs_run": [], "results": {}, "nudges_sent": 0, "users_checked": 0}

    # Batch-fetch ai_settings and optimal send times for all users (parallel queries)
    user_ids = [str(u["id"]) for u in users]
    ai_map = _fetch_ai_settings_batch(supabase, user_ids)
    optimal_map = _fetch_optimal_times_batch(supabase, user_ids)

    # Attach ai_settings and optimal times to user dicts
    for user in users:
        user["_ai_settings"] = ai_map.get(str(user["id"]), {})
        user["_optimal_times"] = optimal_map.get(str(user["id"]), {})

    # Run all nudge jobs concurrently
    jobs = [
        ("morning_workout", _job_morning_workout_reminder(supabase, notif_svc, users)),
        ("missed_workout", _job_missed_workout_nudge(supabase, notif_svc, users)),
        ("meal_reminders", _job_meal_reminders(supabase, notif_svc, users)),
        ("streak_at_risk", _job_streak_at_risk(supabase, notif_svc, users)),
        ("weekly_checkin", _job_weekly_checkin(supabase, notif_svc, users)),
        ("habit_reminder", _job_habit_reminder(supabase, notif_svc, users)),
        ("guilt_escalation", _job_guilt_escalation(supabase, notif_svc, users)),
    ]

    job_names = [j[0] for j in jobs]
    job_coros = [j[1] for j in jobs]
    counts = await asyncio.gather(*job_coros, return_exceptions=True)

    results = {}
    total_sent = 0
    for name, count in zip(job_names, counts):
        if isinstance(count, Exception):
            logger.error(f"❌ [Nudge] Job '{name}' failed: {count}")
            results[name] = 0
        else:
            results[name] = count
            total_sent += count

    elapsed_ms = int((datetime.utcnow() - start_time).total_seconds() * 1000)
    logger.info(f"✅ [Nudge] Cron complete: {total_sent} nudges sent in {elapsed_ms}ms — {results}")

    return {
        "jobs_run": job_names,
        "results": results,
        "nudges_sent": total_sent,
        "users_checked": len(users),
        "elapsed_ms": elapsed_ms,
    }


# ─── Test Endpoint (Development) ────────────────────────────────────────────

@router.post("/test/{user_id}")
@limiter.limit("5/minute")
async def test_nudge(
    request: Request,
    user_id: str,
    nudge_type: str = "morning_workout",
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
):
    """Send a test accountability nudge to a specific user.

    **Security**: Requires X-Cron-Secret header (server-side env var).
    This endpoint is for development/testing only and should be called
    from server-side tooling, never from client apps.

    Args:
        user_id: Target user's UUID (validated format)
        nudge_type: Type of nudge to send (default: morning_workout)
        x_cron_secret: Cron secret for authentication

    Returns:
        JSON with success status and sent message details.
    """
    _verify_cron_secret(request, x_cron_secret)

    # SECURITY: Validate user_id is a valid UUID format to prevent injection
    import re
    if not re.match(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', user_id, re.IGNORECASE):
        raise HTTPException(status_code=400, detail="Invalid user_id format — must be a UUID")

    # SECURITY: Validate nudge_type against allowed values
    allowed_nudge_types = {
        "morning_workout", "missed_workout", "meal_breakfast", "meal_lunch", "meal_dinner",
        "streak_at_risk", "weekly_checkin", "habit_reminder", "post_workout_meal",
        "guilt_day1", "guilt_day2", "guilt_day3", "guilt_day5", "guilt_day7", "guilt_day14",
    }
    if nudge_type not in allowed_nudge_types:
        raise HTTPException(status_code=400, detail=f"Invalid nudge_type. Allowed: {sorted(allowed_nudge_types)}")

    logger.info(f"🧪 [Nudge Test] Sending {nudge_type} to {user_id}")

    supabase = get_supabase()
    notif_svc = get_notification_service()

    # Fetch user
    try:
        result = supabase.client.table("users") \
            .select("id, name, email, fcm_token, timezone, notification_preferences, created_at") \
            .eq("id", user_id) \
            .limit(1) \
            .execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")
        user = result.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to fetch user")

    # Fetch ai_settings
    ai_map = _fetch_ai_settings_batch(supabase, [user_id])
    user["_ai_settings"] = ai_map.get(user_id, {})

    # Build test context based on nudge type
    context = {}
    if nudge_type in ("morning_workout", "missed_workout"):
        context["workout_name"] = "Upper Body Strength"
    elif nudge_type.startswith("meal_"):
        context["meal_type"] = nudge_type.replace("meal_", "").capitalize()
    elif nudge_type == "streak_at_risk":
        context["streak"] = 7
    elif nudge_type.startswith("guilt_day"):
        context["days"] = int(nudge_type.replace("guilt_day", ""))
    elif nudge_type == "habit_reminder":
        context["incomplete_count"] = 3
    elif nudge_type == "post_workout_meal":
        context["workout_name"] = "Upper Body Strength"

    success = await _send_nudge(supabase, notif_svc, user, nudge_type, context)

    coach_name = (user.get("_ai_settings") or {}).get("coach_name", "Your Coach")
    return {
        "success": success,
        "nudge_type": nudge_type,
        "coach_name": coach_name,
        "user_name": user.get("name"),
        "message": "Nudge sent successfully" if success else "Nudge not sent (dedup/cap/no token)",
    }
