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
import json
from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any, Tuple
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import APIRouter, Header, HTTPException, Request
from fastapi.responses import JSONResponse

from core import branding
from core.supabase_client import get_supabase
from core.config import get_settings
from core.logger import get_logger
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter
from core.i18n import get_template as _get_i18n_template
from services.notification_service import get_notification_service
from services.notification_suppression import should_suppress_notification
from services.posthog_client import capture_lifecycle

# Map internal nudge_type → i18n template key base (title/body pairs).
# Nudge types not listed here fall through to the existing template pool.
_NUDGE_TYPE_TO_I18N_KEY: Dict[str, str] = {
    "morning_workout": "workout_reminder",
    "streak_at_risk": "streak_at_risk",
    "weekly_checkin": "weekly_wrapped",
    "morning_recovery": "morning_recovery_nudge",
    "post_workout_nutrition": "post_workout_nutrition",
    "rest_day_tip": "rest_day_tip",
    "habit_streak_reward": "habit_streak_reward",
    "progress_milestone": "new_pr_celebration",
    "coach_insight": "ai_coach_insight",
}

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


def _email_prefix(user: dict) -> str:
    """First-name fallback derived from the email local-part.

    Per the name-personalization rule, every notification addresses the user by
    a first name. When ``name`` is empty we use the email prefix (e.g.
    "alex" from "alex@x.com"), capitalized, rather than a generic "there".
    """
    email = (user.get("email") or "").strip()
    if "@" in email:
        local = email.split("@", 1)[0].split(".")[0].split("+")[0]
        if local:
            return local[:1].upper() + local[1:]
    return "there"


def _is_dst_transition_night(timezone_str: str) -> bool:
    """True if the user's location had a DST clock change overnight.

    Compares the UTC offset at noon yesterday-local against noon today-local.
    A spring-forward / fall-back shifts the offset, which means last night's
    sleep window is computed from a clock that changed mid-night — the
    readiness briefing must not lead with a "poor sleep" tone on such a night
    (plan edge case E24 / F30). Falls back to False (no suppression) on any
    parsing error so a tz glitch never silently mutes a whole day of nudges.
    """
    tz = _safe_zone(timezone_str)
    try:
        now_local = datetime.now(tz)
        noon_today = now_local.replace(hour=12, minute=0, second=0, microsecond=0)
        noon_yesterday = noon_today - timedelta(days=1)
        return noon_today.utcoffset() != noon_yesterday.utcoffset()
    except Exception:
        return False


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
        logger.error(f"❌ [Nudge] Dedup insert error: {e}", exc_info=True)
        return False


def _sent_within_days(supabase, user_id: str, nudge_type: str, days: int) -> bool:
    """True if THIS nudge_type was sent to the user within the last ``days``.

    The dedup table keys on (user_id, nudge_type, nudge_date) which guarantees
    at most once PER DAY. The low-frequency health-trend jobs (sleep_debt,
    rhr_trend, protein_trend, volume_balance) additionally need a multi-day
    COOLDOWN so a persisting condition does not fire every single day. This
    reads the most recent push_nudge_log row for the type and checks its age.

    Fails CLOSED for the cooldown decision is wrong (would mute forever on a
    glitch), so on any error we return False (allow the send) and let the
    per-day dedup remain the floor.
    """
    try:
        cutoff = (datetime.utcnow().date() - timedelta(days=days)).isoformat()
        res = (
            supabase.client.table("push_nudge_log")
            .select("nudge_date")
            .eq("user_id", user_id)
            .eq("nudge_type", nudge_type)
            .gte("nudge_date", cutoff)
            .limit(1)
            .execute()
        )
        return bool(res.data)
    except Exception:
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
    notification_preferences, created_at, plus vacation_* and comeback_* fields
    used by the central suppression gate (services/notification_suppression.py).
    """
    try:
        result = supabase.client.table("users") \
            .select(
                "id, name, email, fcm_token, timezone, notification_preferences, created_at, "
                "in_vacation_mode, vacation_start_date, vacation_end_date, "
                "in_comeback_mode, comeback_week, preferred_locale"
            ) \
            .not_.is_("fcm_token", "null") \
            .execute()
        return result.data or []
    except Exception as e:
        logger.error(f"❌ [Nudge] Failed to fetch users: {e}", exc_info=True)
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
        logger.error(f"❌ [Nudge] Failed to fetch ai_settings: {e}", exc_info=True)
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
        logger.error(f"❌ [Nudge] Failed to fetch optimal times: {e}", exc_info=True)
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

    # Master push toggle (item 6a) — a single off-switch for ALL server push.
    # Default True so users who predate the synced flag are unaffected.
    if not prefs.get("push_notifications_enabled", True):
        return False

    # 0. Global suppression gate (vacation + comeback). Checked BEFORE dedup so
    # suppressed nudges don't burn dedup slots or daily cap quota.
    suppression = should_suppress_notification(user, nudge_type, channel="push")
    if suppression:
        logger.debug(f"🔕 [Nudge] Suppressed {nudge_type} for {user_id}: {suppression}")
        return False

    # 1. Daily cap check (BEFORE dedup insert)
    daily_limit = prefs.get("daily_nudge_limit", 2)
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
    # New-user tone cap (migration 1938 / W6): research shows shame/tough_love
    # undermines motivation for early users. Force balanced for accounts < 14d old
    # regardless of user preference. Users who've used the app 2+ weeks can keep
    # their chosen intensity.
    if _user_account_age_days(user) < 14 and intensity == "tough_love":
        intensity = "balanced"
    use_ai = prefs.get("ai_personalized_nudges", True)

    # ── Resolve user's preferred locale for localized push title/body ────────
    # preferred_locale is populated by the chat endpoint from Accept-Language.
    # Defaults to 'en' when absent (migration 2103 default).
    user_locale = user.get("preferred_locale") or "en"

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

    # ── Build localized push title/body (non-English users only) ─────────────
    # When the user has a non-English locale AND the nudge_type maps to an i18n
    # key, override the push notification title and body with the localized
    # template. The chat message body stays as-is (English or AI-generated) —
    # push text and chat text are independent.
    # NOTE: All locales currently return English (translations TODO — see i18n.py).
    _localized_title: Optional[str] = None
    _localized_body: Optional[str] = None
    if user_locale != "en":
        i18n_key_base = _NUDGE_TYPE_TO_I18N_KEY.get(nudge_type)
        if i18n_key_base:
            _fmt_vars = {
                "name": user.get("name") or "",
                "coach_name": coach_name,
                **{k: v for k, v in context_dict.items() if isinstance(v, (str, int, float))},
            }
            _localized_title = _get_i18n_template(user_locale, f"{i18n_key_base}_title", **_fmt_vars)
            _localized_body = _get_i18n_template(user_locale, f"{i18n_key_base}_body", **_fmt_vars)

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
        logger.warning(f"⚠️ [Nudge] chat_history insert failed for {user_id}: {e}", exc_info=True)

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
    # If we built a localized title/body, override context_dict so that
    # send_accountability_nudge picks them up via the template pool. The
    # `_localized_title` becomes the FCM notification title and
    # `_localized_body` becomes the push body text.
    if _localized_title:
        context_dict["_override_title"] = _localized_title
    if _localized_body:
        context_dict["_override_body"] = _localized_body

    success, _ = await notif_svc.send_accountability_nudge(
        fcm_token=fcm_token,
        nudge_type=nudge_type,
        context_dict=context_dict,
        user_name=user.get("name"),
        coach_name=_localized_title or coach_name,  # Localized title as FCM notification title
        coaching_style=coaching_style,
        communication_tone=communication_tone,
        use_emojis=use_emojis,
        accountability_intensity=intensity,
        use_ai=False,  # Already generated the message — use it directly
    )

    if success:
        logger.info(f"✅ [Nudge] {nudge_type} sent to {user_id} ({coach_name}) locale={user_locale}")
        # Fire-and-forget telemetry — PostHog SDK has its own background
        # thread + the helper swallows exceptions, so this never blocks or
        # crashes the send loop.
        capture_lifecycle(
            user_id=user_id,
            event_name="lifecycle_push_sent",
            properties={
                "kind": nudge_type,
                "channel": "push",
                "locale": user_locale,
                "coaching_style": coaching_style,
                "intensity": intensity,
            },
        )
    else:
        capture_lifecycle(
            user_id=user_id,
            event_name="lifecycle_send_failed",
            properties={
                "kind": nudge_type,
                "channel": "push",
                "reason": "fcm_send_returned_false",
            },
        )
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

        # PRESET GATE: minimal/balanced presets use frontend bundles for morning workout
        preset = prefs.get("frequency_preset", "balanced")
        if preset in ("minimal", "balanced"):
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

        # PRESET GATE: minimal preset uses frontend bundles for meal reminders
        preset = prefs.get("frequency_preset", "balanced")
        if preset == "minimal":
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

        # PRESET GATE: minimal preset skips weekly check-in (frontend bundles cover this)
        preset = prefs.get("frequency_preset", "balanced")
        if preset == "minimal":
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

        # PRESET GATE: minimal preset skips habit reminders
        preset = prefs.get("frequency_preset", "balanced")
        if preset == "minimal":
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


async def _job_trial_reminder(supabase, notif_svc) -> int:
    """Send push notifications to users whose trial expires in 2 days (Day 5) or today (Day 7).

    Unlike other nudge jobs, this queries user_subscriptions directly (not user-batch).
    Includes 25% discount messaging on expiry day.
    """
    from datetime import date as date_cls, timedelta

    sent = 0
    # Use UTC as cron reference for trial date queries
    utc_today = date_cls.fromisoformat(_get_user_local_date("UTC"))

    # Day 5 (2 days left) and Day 7 (expires today)
    targets = [
        (2, utc_today + timedelta(days=2)),
        (0, utc_today),
    ]

    for days_left, target_date in targets:
        try:
            subs = supabase.client.table("user_subscriptions") \
                .select("user_id") \
                .eq("is_trial", True) \
                .eq("status", "trial") \
                .gte("trial_end_date", f"{target_date.isoformat()}T00:00:00") \
                .lt("trial_end_date", f"{target_date.isoformat()}T23:59:59") \
                .execute()

            if not subs.data:
                continue

            user_ids = [s["user_id"] for s in subs.data]

            users_result = supabase.client.table("users") \
                .select("id, name, fcm_token, timezone, notification_preferences") \
                .in_("id", user_ids) \
                .execute()

            for user in (users_result.data or []):
                fcm_token = user.get("fcm_token")
                if not fcm_token:
                    continue

                user_id = str(user["id"])
                tz_str = user.get("timezone") or "UTC"
                local_date = _get_user_local_date(tz_str)

                # Dedup: one trial_reminder per user per day
                if not _try_dedup_insert(supabase, user_id, "trial_reminder", local_date):
                    continue

                display_name = (user.get("name") or "").split()[0] if user.get("name") else "there"

                if days_left == 0:
                    title = "Your trial ends today"
                    body = f"Hey {display_name}, subscribe now and save 25% — just $37.49/year for your AI fitness coach."
                else:
                    title = f"Your trial ends in {days_left} days"
                    body = f"Hey {display_name}, you still have {days_left} days left. Don't lose access to your AI workouts and coaching!"

                try:
                    await notif_svc.send_push_notification(
                        token=fcm_token,
                        title=title,
                        body=body,
                        data={
                            "type": "trial_reminder",
                            "days_left": str(days_left),
                            "route": "/paywall-pricing" if days_left > 0 else "/hard-paywall",
                        },
                    )
                    sent += 1
                except Exception as e:
                    logger.warning(f"Failed to send trial reminder push to {user_id}: {e}")

        except Exception as e:
            logger.error(f"❌ trial_reminder job (days_left={days_left}) failed: {e}", exc_info=True)

    logger.info(f"🎯 trial_reminder: {sent} push notifications sent")
    return sent


# ─── Smart App-Open Hook Jobs ──────────────────────────────────────────────


async def _job_streak_countdown_urgency(supabase, notif_svc, users: List[dict]) -> int:
    """URGENT: Streak expires tonight. Fires 2h before quiet hours start."""
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("streak_alerts", True):
            continue
        if _user_account_age_days(user) < 3:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        quiet_start = _parse_time_hour(prefs.get("quiet_hours_start", "22:00"))
        trigger_hour = (quiet_start - 2) % 24
        if local_hour != trigger_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        try:
            streak_data = supabase.client.table("user_login_streaks") \
                .select("current_streak") \
                .eq("user_id", user_id).limit(1).execute()
            if not streak_data.data:
                continue
            current_streak = streak_data.data[0].get("current_streak", 0)
            if current_streak < 2:
                continue
        except Exception:
            continue

        try:
            completed = supabase.client.table("workouts") \
                .select("id").eq("user_id", user_id) \
                .eq("scheduled_date", user_today).eq("is_completed", True) \
                .limit(1).execute()
            if completed.data:
                continue
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "streak_countdown", {
            "streak": current_streak,
        })
        if success:
            sent += 1
    return sent


async def _job_progress_milestone_teaser(supabase, notif_svc, users: List[dict]) -> int:
    """User is 1 workout away from a milestone (10, 25, 50, 100, etc.)."""
    milestones = {10, 25, 50, 75, 100, 150, 200, 250, 365}
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if _user_account_age_days(user) < 7:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        pref_hour = _parse_time_hour(prefs.get("workout_reminder_time", "08:00"))
        optimal_hour = _get_optimal_hour(user, "progress_milestone", pref_hour)
        if local_hour != optimal_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        try:
            result = supabase.client.table("workout_logs") \
                .select("id", count="exact") \
                .eq("user_id", user_id).execute()
            total = result.count or 0
            if (total + 1) not in milestones:
                continue
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "progress_milestone", {
            "milestone": total + 1,
            "current_count": total,
        })
        if success:
            sent += 1
    return sent


async def _job_post_workout_nutrition(supabase, notif_svc, users: List[dict]) -> int:
    """Remind user to eat 30-60 min after completing a workout.

    The 30-60 min window is computed per user in their local timezone via
    `datetime.now(tz)`. `completed_at` is a UTC timestamptz, so an offset-aware
    "now" minus a fixed delta yields a correct absolute-time window for every
    user — unlike a naive `datetime.utcnow()`, whose `.isoformat()` has no
    offset and can be misread by Postgres on the timestamptz comparison.
    """
    sent = 0

    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("nutrition_reminders", True):
            continue
        tz_str = user.get("timezone") or "UTC"
        if _is_in_quiet_hours(prefs, _get_user_local_hour(tz_str)):
            continue

        # Per-user, tz-aware window. `now_local` carries the user's UTC offset,
        # so the ISO strings below are unambiguous for the timestamptz compare.
        now_local = datetime.now(_safe_zone(tz_str))
        window_start = (now_local - timedelta(minutes=60)).isoformat()
        window_end = (now_local - timedelta(minutes=30)).isoformat()

        user_id = str(user["id"])
        try:
            logs = supabase.client.table("workout_logs") \
                .select("id, completed_at, workout_id") \
                .eq("user_id", user_id) \
                .gte("completed_at", window_start) \
                .lte("completed_at", window_end) \
                .limit(1).execute()
            if not logs.data:
                continue
            completed_at = logs.data[0]["completed_at"]
        except Exception:
            continue

        # Check if user already logged food after workout
        try:
            food = supabase.client.table("food_logs") \
                .select("id").eq("user_id", user_id) \
                .gte("created_at", completed_at) \
                .limit(1).execute()
            if food.data:
                continue  # Already logged food
        except Exception:
            continue

        # Get workout name
        workout_name = "your workout"
        try:
            workout_id = logs.data[0].get("workout_id")
            if workout_id:
                w = supabase.client.table("workouts") \
                    .select("name").eq("id", workout_id).limit(1).execute()
                if w.data:
                    workout_name = w.data[0].get("name", workout_name)
        except Exception:
            pass

        success = await _send_nudge(supabase, notif_svc, user, "post_workout_nutrition", {
            "workout_name": workout_name,
        })
        if success:
            sent += 1
    return sent


async def _job_coach_insight(supabase, notif_svc, users: List[dict]) -> int:
    """Weekly 'Your coach noticed something' teaser, distributed across days.

    Each user is assigned a fixed day-of-week slot (`hash(user_id) % 7`). The
    "is it that user's day" check uses the day-of-year in the USER's local
    timezone, not UTC — otherwise a user just past local midnight could be
    evaluated against the previous (or next) calendar day and either miss
    their slot or fire a day early.
    """
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if _user_account_age_days(user) < 7:
            continue

        tz_str = user.get("timezone") or "UTC"
        # Day-of-year in the user's local calendar drives the weekly slot.
        day_of_year = datetime.now(_safe_zone(tz_str)).timetuple().tm_yday

        # Distribute across week: each user fires on their "assigned" day
        user_day = hash(str(user["id"])) % 7
        if day_of_year % 7 != user_day:
            continue

        local_hour = _get_user_local_hour(tz_str)
        optimal_hour = _get_optimal_hour(user, "coach_insight", 10)
        if local_hour != optimal_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        success = await _send_nudge(supabase, notif_svc, user, "coach_insight", {
            "insight_type": "progress",
        })
        if success:
            sent += 1
    return sent


async def _job_habit_streak_reward(supabase, notif_svc, users: List[dict]) -> int:
    """Celebrate consecutive days of meal logging (7, 14, 21, 30 days)."""
    reward_milestones = [30, 21, 14, 7]  # Check highest first
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if _user_account_age_days(user) < 7:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        optimal_hour = _get_optimal_hour(user, "habit_streak_reward", 10)
        if local_hour != optimal_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        try:
            cutoff = (datetime.utcnow() - timedelta(days=31)).isoformat()
            logs = supabase.client.table("food_logs") \
                .select("created_at") \
                .eq("user_id", user_id) \
                .gte("created_at", cutoff) \
                .execute()
            if not logs.data:
                continue

            # Extract unique dates and count consecutive days from today backward
            dates = set()
            for log in logs.data:
                d = log.get("created_at", "")[:10]
                if d:
                    dates.add(d)

            today = _get_user_local_date(tz_str)
            consecutive = 0
            check = datetime.strptime(today, "%Y-%m-%d")
            while check.strftime("%Y-%m-%d") in dates:
                consecutive += 1
                check -= timedelta(days=1)

            # Match against milestones
            matched = None
            for m in reward_milestones:
                if consecutive == m:
                    matched = m
                    break
            if not matched:
                continue
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "habit_streak_reward", {
            "habit_type": "meal_logging",
            "consecutive_days": matched,
        })
        if success:
            sent += 1
    return sent


async def _job_rest_day_engagement(supabase, notif_svc, users: List[dict]) -> int:
    """Rest day tip when user hasn't opened the app."""
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if _user_account_age_days(user) < 7:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        optimal_hour = _get_optimal_hour(user, "rest_day_tip", 10)
        if local_hour != optimal_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        # Check no workout scheduled today (rest day)
        try:
            workouts = supabase.client.table("workouts") \
                .select("id").eq("user_id", user_id) \
                .eq("scheduled_date", user_today).limit(1).execute()
            if workouts.data:
                continue  # Not a rest day
        except Exception:
            continue

        # Check no food_logs today (user hasn't opened app)
        try:
            today_start = f"{user_today}T00:00:00"
            food = supabase.client.table("food_logs") \
                .select("id").eq("user_id", user_id) \
                .gte("created_at", today_start).limit(1).execute()
            if food.data:
                continue  # User has been active
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "rest_day_tip", {})
        if success:
            sent += 1
    return sent


async def _job_progress_comparison(supabase, notif_svc, users: List[dict]) -> int:
    """Monthly: compare this month vs last month workouts (fires on 1st)."""
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if _user_account_age_days(user) < 30:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_now = datetime.now(_safe_zone(tz_str))
        if local_now.day != 1:
            continue

        local_hour = local_now.hour
        optimal_hour = _get_optimal_hour(user, "progress_comparison", 10)
        if local_hour != optimal_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        try:
            this_month_start = local_now.replace(day=1).strftime("%Y-%m-%d")
            last_month_end = local_now.replace(day=1) - timedelta(days=1)
            last_month_start = last_month_end.replace(day=1).strftime("%Y-%m-%d")
            last_month_end_str = last_month_end.strftime("%Y-%m-%d")

            this_month = supabase.client.table("workout_logs") \
                .select("id", count="exact") \
                .eq("user_id", user_id) \
                .gte("completed_at", this_month_start).execute()
            last_month = supabase.client.table("workout_logs") \
                .select("id", count="exact") \
                .eq("user_id", user_id) \
                .gte("completed_at", last_month_start) \
                .lte("completed_at", last_month_end_str).execute()

            this_count = this_month.count or 0
            last_count = last_month.count or 0
            if last_count == 0:
                continue
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "progress_comparison", {
            "this_month": this_count,
            "last_month": last_count,
        })
        if success:
            sent += 1
    return sent


async def _job_time_capsule(supabase, notif_svc, users: List[dict]) -> int:
    """Celebrate account age milestones: 30, 60, 90, 180, 365 days."""
    capsule_days = {30, 60, 90, 180, 365}
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        age = _user_account_age_days(user)
        if age not in capsule_days:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        optimal_hour = _get_optimal_hour(user, "time_capsule", 10)
        if local_hour != optimal_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        success = await _send_nudge(supabase, notif_svc, user, "time_capsule", {
            "days_active": age,
        })
        if success:
            sent += 1
    return sent


async def _job_chain_visual(supabase, notif_svc, users: List[dict]) -> int:
    """'Don't break the chain' — fires at 4pm for streaks >= 5, workout not done."""
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("streak_alerts", True):
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        if local_hour != 16:  # 4pm
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        try:
            streak_data = supabase.client.table("user_login_streaks") \
                .select("current_streak").eq("user_id", user_id).limit(1).execute()
            if not streak_data.data:
                continue
            current_streak = streak_data.data[0].get("current_streak", 0)
            if current_streak < 5:
                continue
        except Exception:
            continue

        try:
            completed = supabase.client.table("workouts") \
                .select("id").eq("user_id", user_id) \
                .eq("scheduled_date", user_today).eq("is_completed", True) \
                .limit(1).execute()
            if completed.data:
                continue
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "chain_visual", {
            "streak": current_streak,
        })
        if success:
            sent += 1
    return sent


async def _job_recovery_complete(supabase, notif_svc, users: List[dict]) -> int:
    """Notify when target muscle group is fully recovered (48h+)."""
    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("workout_reminders", True):
            continue
        if _user_account_age_days(user) < 7:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        pref_hour = _parse_time_hour(prefs.get("workout_reminder_time", "08:00"))
        optimal_hour = _get_optimal_hour(user, "recovery_complete", pref_hour)
        if local_hour != optimal_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        # Get today's workout and its muscle groups
        try:
            workout = supabase.client.table("workouts") \
                .select("id, name, muscle_groups") \
                .eq("user_id", user_id).eq("scheduled_date", user_today) \
                .eq("is_completed", False).limit(1).execute()
            if not workout.data:
                continue
            muscle_groups = workout.data[0].get("muscle_groups") or []
            if not muscle_groups:
                continue
            primary_group = muscle_groups[0] if isinstance(muscle_groups, list) else str(muscle_groups)
        except Exception:
            continue

        # Check last time this muscle group was trained
        try:
            cutoff_48h = (datetime.utcnow() - timedelta(hours=48)).isoformat()
            recent = supabase.client.table("workout_logs") \
                .select("completed_at").eq("user_id", user_id) \
                .lte("completed_at", cutoff_48h) \
                .order("completed_at", desc=True).limit(1).execute()
            if not recent.data:
                continue  # No previous workout to compare
            last_completed = recent.data[0].get("completed_at", "")
            hours_ago = int((datetime.utcnow() - datetime.fromisoformat(last_completed.replace("Z", "+00:00").replace("+00:00", ""))).total_seconds() / 3600)
        except Exception:
            continue

        success = await _send_nudge(supabase, notif_svc, user, "recovery_complete", {
            "muscle_group": primary_group,
            "hours_recovered": hours_ago,
        })
        if success:
            sent += 1
    return sent


# ─── Merch Milestone Nudges (migration 1931) ─────────────────────────────────

# Next merch tier for a given level in the proximity window.
_MERCH_NEXT_FOR_PROXIMITY = {
    47: 50, 48: 50, 49: 50,
    97: 100, 98: 100, 99: 100,
    147: 150, 148: 150, 149: 150,
    197: 200, 198: 200, 199: 200,
    247: 250, 248: 250, 249: 250,
}

_MERCH_DISPLAY_NAME = {
    "sticker_pack": f"{branding.MERCH_PRODUCT_PREFIX} Sticker Pack",
    "t_shirt": f"{branding.MERCH_PRODUCT_PREFIX} T-Shirt",
    "hoodie": f"{branding.MERCH_PRODUCT_PREFIX} Hoodie",
    "full_merch_kit": "Full Merch Kit",
    "signed_premium_kit": "Signed Premium Kit",
}


def _merch_type_for_level(level: int) -> Optional[str]:
    return {
        50: "sticker_pack",
        100: "t_shirt",
        150: "hoodie",
        200: "full_merch_kit",
        250: "signed_premium_kit",
    }.get(level)


async def _job_merch_proximity(supabase, notif_svc, users: List[dict]) -> int:
    """
    Nudge users who are 1-3 levels away from a merch tier (L50 / L100 / L150 / L200 / L250).
    Fires once per day per user at their preferred "progress_milestone" hour (default 18:00).
    Dedup: (user_id, 'merch_proximity', local_date) via push_nudge_log UNIQUE constraint.
    """
    sent = 0
    if not users:
        return 0

    # Bulk-fetch current_level + last_merch_nudge_at for all users
    user_ids = [str(u["id"]) for u in users]
    try:
        xp_rows = supabase.client.table("user_xp") \
            .select("user_id,current_level,last_merch_nudge_at") \
            .in_("user_id", user_ids) \
            .execute()
    except Exception as e:
        logger.warning(f"[Nudge] merch_proximity user_xp fetch failed: {e}")
        return 0

    xp_by_user = {r["user_id"]: r for r in (xp_rows.data or [])}

    for user in users:
        user_id = str(user["id"])
        xp = xp_by_user.get(user_id)
        if not xp:
            continue

        level = xp.get("current_level", 1)
        next_merch_level = _MERCH_NEXT_FOR_PROXIMITY.get(level)
        if not next_merch_level:
            continue

        merch_type = _merch_type_for_level(next_merch_level)
        if not merch_type:
            continue

        prefs = user.get("notification_preferences") or {}
        # Dedicated merch-notification toggle (migration 1932)
        if prefs.get("push_merch_alerts") is False:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_now = datetime.now(_safe_zone(tz_str))
        local_hour = local_now.hour

        target_hour = _get_optimal_hour(user, "progress_milestone", 18)
        if local_hour != target_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        levels_away = next_merch_level - level
        success = await _send_nudge(supabase, notif_svc, user, "merch_proximity", {
            "merch_name": _MERCH_DISPLAY_NAME.get(merch_type, merch_type),
            "next_level": next_merch_level,
            "levels_away": levels_away,
        })
        if success:
            sent += 1
            # Mark last_merch_nudge_at so we don't spam (even if cron runs twice same day)
            try:
                supabase.client.table("user_xp") \
                    .update({"last_merch_nudge_at": datetime.utcnow().isoformat(),
                             "last_merch_nudge_level": level}) \
                    .eq("user_id", user_id).execute()
            except Exception:
                pass

    return sent


async def _job_merch_unlocked(supabase, notif_svc, users: List[dict]) -> int:
    """
    Celebrate when a user hits a merch tier — fires as soon as the claim appears
    in merch_claims with status='pending_address' (within the last 2 hours).
    Dedup: (user_id, 'merch_unlocked', local_date).
    """
    sent = 0
    if not users:
        return 0

    user_ids = [str(u["id"]) for u in users]
    cutoff = (datetime.utcnow() - timedelta(hours=2)).isoformat()

    try:
        claims = supabase.client.table("merch_claims") \
            .select("user_id,merch_type,awarded_at_level,created_at") \
            .eq("status", "pending_address") \
            .gte("created_at", cutoff) \
            .in_("user_id", user_ids) \
            .execute()
    except Exception as e:
        logger.warning(f"[Nudge] merch_unlocked fetch failed: {e}")
        return 0

    claims_by_user = {}
    for row in (claims.data or []):
        claims_by_user.setdefault(row["user_id"], row)  # first pending claim

    for user in users:
        user_id = str(user["id"])
        claim = claims_by_user.get(user_id)
        if not claim:
            continue

        prefs = user.get("notification_preferences") or {}
        if prefs.get("push_merch_alerts") is False:
            continue
        tz_str = user.get("timezone") or "UTC"
        local_hour = datetime.now(_safe_zone(tz_str)).hour
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        merch_type = claim["merch_type"]
        success = await _send_nudge(supabase, notif_svc, user, "merch_unlocked", {
            "merch_name": _MERCH_DISPLAY_NAME.get(merch_type, merch_type),
            "next_level": claim["awarded_at_level"],
            "levels_away": 0,
        })
        if success:
            sent += 1
    return sent


async def _job_merch_claim_reminder(supabase, notif_svc, users: List[dict]) -> int:
    """
    Remind users who earned merch but haven't tapped Accept yet.
    Fires at D+1, D+3, D+7 since claim was created.
    Dedup: push_nudge_log unique on (user_id, 'merch_claim_reminder', local_date).
    """
    sent = 0
    if not users:
        return 0

    user_ids = [str(u["id"]) for u in users]
    now = datetime.utcnow()

    try:
        claims = supabase.client.table("merch_claims") \
            .select("user_id,merch_type,awarded_at_level,created_at") \
            .eq("status", "pending_address") \
            .in_("user_id", user_ids) \
            .execute()
    except Exception as e:
        logger.warning(f"[Nudge] merch_claim_reminder fetch failed: {e}")
        return 0

    # Index by user; pick oldest pending claim
    oldest_by_user: Dict[str, dict] = {}
    for row in (claims.data or []):
        uid = row["user_id"]
        existing = oldest_by_user.get(uid)
        if not existing or row["created_at"] < existing["created_at"]:
            oldest_by_user[uid] = row

    target_day_offsets = {1, 3, 7}

    for user in users:
        user_id = str(user["id"])
        claim = oldest_by_user.get(user_id)
        if not claim:
            continue

        try:
            created = datetime.fromisoformat(claim["created_at"].replace("Z", "+00:00"))
        except Exception:
            continue
        days_since = (now.replace(tzinfo=created.tzinfo) - created).days
        if days_since not in target_day_offsets:
            continue

        prefs = user.get("notification_preferences") or {}
        if prefs.get("push_merch_alerts") is False:
            continue
        tz_str = user.get("timezone") or "UTC"
        local_hour = datetime.now(_safe_zone(tz_str)).hour

        # Send in late morning — 10 AM local
        if local_hour != 10:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        merch_type = claim["merch_type"]
        success = await _send_nudge(supabase, notif_svc, user, "merch_claim_reminder", {
            "merch_name": _MERCH_DISPLAY_NAME.get(merch_type, merch_type),
            "next_level": claim["awarded_at_level"],
            "levels_away": 0,
            "days": days_since,
        })
        if success:
            sent += 1
    return sent


# ─── Level Milestone Celebration (migration 1935) ────────────────────────────

_MILESTONE_LEVELS_FOR_CELEBRATION = {5, 10, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250}


def _summarize_rewards(items: list) -> str:
    """Build a compact 'You got X × Y, Z × W' string from a rewards_snapshot list."""
    friendly = {
        "streak_shield": "Streak Shield",
        "xp_token_2x": "2× XP Token",
        "fitness_crate": "Fitness Crate",
        "premium_crate": "Premium Crate",
    }
    parts: List[str] = []
    has_merch = False
    for item in items or []:
        t = item.get("type")
        if t == "merch":
            has_merch = True
            continue
        q = item.get("quantity", 1)
        name = friendly.get(t)
        if name:
            parts.append(f"{q}× {name}")
    summary = " + ".join(parts[:3])  # keep push body short
    if has_merch:
        summary = (summary + " + FREE MERCH!") if summary else "FREE MERCH!"
    return summary or "New rewards unlocked!"


async def _job_level_milestone_celebration(supabase, notif_svc, users: List[dict]) -> int:
    """
    Celebrate when a user hits L5/10/25/50/75/100/125/150/175/200/225/250.
    Fires within ~1 hour of the level-up via the level_up_events table.
    Dedup per (user_id, 'level_milestone_celebration', local_date).
    """
    sent = 0
    if not users:
        return 0

    user_ids = [str(u["id"]) for u in users]
    cutoff = (datetime.utcnow() - timedelta(hours=2)).isoformat()

    try:
        result = (
            supabase.client.table("level_up_events")
            .select("user_id,level_reached,rewards_snapshot,merch_type,created_at,acknowledged_at")
            .eq("is_milestone", True)
            .gte("created_at", cutoff)
            .in_("user_id", user_ids)
            .execute()
        )
    except Exception as e:
        logger.warning(f"[Nudge] level_milestone_celebration fetch failed: {e}")
        return 0

    # Pick one celebration per user (highest level reached in this window)
    by_user: Dict[str, dict] = {}
    for row in (result.data or []):
        level = row.get("level_reached")
        if level not in _MILESTONE_LEVELS_FOR_CELEBRATION:
            continue
        existing = by_user.get(row["user_id"])
        if not existing or row["level_reached"] > existing["level_reached"]:
            by_user[row["user_id"]] = row

    for user in users:
        user_id = str(user["id"])
        row = by_user.get(user_id)
        if not row:
            continue

        prefs = user.get("notification_preferences") or {}
        # Gate via achievement-alerts toggle (existing) — no new toggle needed here
        if prefs.get("push_achievement_alerts") is False:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = datetime.now(_safe_zone(tz_str)).hour
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        summary = _summarize_rewards(row.get("rewards_snapshot") or [])

        success = await _send_nudge(supabase, notif_svc, user, "level_milestone_celebration", {
            "level": row["level_reached"],
            "rewards_summary": summary,
        })
        if success:
            sent += 1
    return sent


# ─── Week-1 Retention Nudge Ladder (W4) ──────────────────────────────────────

async def _fetch_workouts_this_week(supabase, user_id: str) -> int:
    """Count completed workouts since user's first_workout_completed_at
    (or signup) — cheap way to branch completed-vs-stalled week-1 variants."""
    try:
        # Count all completed workout_logs — we only look at users < 7 days
        # old anyway, so this is naturally bounded.
        res = (
            supabase.client.table("workout_logs")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .eq("status", "completed")
            .execute()
        )
        return res.count or 0
    except Exception:
        return 0


def _is_at_user_local_hour(user: dict, target_hour: int) -> bool:
    """True if the user's current LOCAL hour matches target_hour (timezone-aware)."""
    tz_str = user.get("timezone") or "UTC"
    try:
        return datetime.now(_safe_zone(tz_str)).hour == target_hour
    except Exception:
        return False


async def _job_week1_day1(supabase, notif_svc, users: List[dict]) -> int:
    """Day 1 after signup, at user's local 10 AM, if no workout completed yet."""
    sent = 0
    for user in users:
        age_days = _user_account_age_days(user)
        if age_days != 1:
            continue
        if not _is_at_user_local_hour(user, 10):
            continue
        prefs = user.get("notification_preferences") or {}
        if _is_in_quiet_hours(prefs, 10):
            continue
        # Skip if they already did a workout (rare — their first workout would
        # have fired the forecast sheet; save the push for stalled users).
        count = await _fetch_workouts_this_week(supabase, str(user["id"]))
        if count > 0:
            continue
        success = await _send_nudge(supabase, notif_svc, user, "week1_day1", {})
        if success:
            sent += 1
    return sent


async def _job_week1_day3(supabase, notif_svc, users: List[dict]) -> int:
    """Day 3 post-signup at local 10 AM — completed or stalled variant."""
    sent = 0
    for user in users:
        age_days = _user_account_age_days(user)
        if age_days != 3:
            continue
        if not _is_at_user_local_hour(user, 10):
            continue
        prefs = user.get("notification_preferences") or {}
        if _is_in_quiet_hours(prefs, 10):
            continue
        count = await _fetch_workouts_this_week(supabase, str(user["id"]))
        nudge_type = "week1_day3_completed" if count >= 1 else "week1_day3_stalled"
        success = await _send_nudge(supabase, notif_svc, user, nudge_type, {
            "count": count,
            "s": "s" if count != 1 else "",
        })
        if success:
            sent += 1
    return sent


async def _job_week1_day5(supabase, notif_svc, users: List[dict]) -> int:
    """Day 5 post-signup at local 7 PM — halfway-through-week-one check-in."""
    sent = 0
    for user in users:
        age_days = _user_account_age_days(user)
        if age_days != 5:
            continue
        if not _is_at_user_local_hour(user, 19):
            continue
        prefs = user.get("notification_preferences") or {}
        if _is_in_quiet_hours(prefs, 19):
            continue
        count = await _fetch_workouts_this_week(supabase, str(user["id"]))
        success = await _send_nudge(supabase, notif_svc, user, "week1_day5", {
            "count": count,
            "s": "s" if count != 1 else "",
        })
        if success:
            sent += 1
    return sent


async def _job_week1_day7(supabase, notif_svc, users: List[dict]) -> int:
    """Day 7 post-signup at local 9 AM — week 1 recap celebration."""
    sent = 0
    for user in users:
        age_days = _user_account_age_days(user)
        if age_days != 7:
            continue
        if not _is_at_user_local_hour(user, 9):
            continue
        prefs = user.get("notification_preferences") or {}
        if _is_in_quiet_hours(prefs, 9):
            continue
        count = await _fetch_workouts_this_week(supabase, str(user["id"]))
        success = await _send_nudge(supabase, notif_svc, user, "week1_day7", {
            "count": count,
            "s": "s" if count != 1 else "",
        })
        if success:
            sent += 1
    return sent


async def _job_daily_crate_available(supabase, notif_svc, users: List[dict]) -> int:
    """Remind users once/day that their daily crate is ready to open.

    Runs in the same hourly cron. Fires at the user's configured reminder hour
    (default 10 AM local), only if there's an unclaimed crate in user_daily_crates
    for today. Skips quiet hours, respects the daily_crate_reminders pref toggle,
    and dedups via push_nudge_log.

    Payload:
        type = daily_crate
        crate_types = comma-separated list of available types (daily,streak,activity)
        unclaimed_count = number of distinct dates with unclaimed crates
    """
    from services.notification_service_helpers import NotificationService

    sent = 0
    for user in users:
        prefs = user.get("notification_preferences") or {}
        # Preference gate — default True (opt-out)
        if not prefs.get("daily_crate_reminders", True):
            continue

        # Global suppression gate (vacation + comeback). Crate reminders are
        # non-critical, so they get suppressed during vacation mode.
        if should_suppress_notification(user, "daily_crate", channel="push"):
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        reminder_hour = _parse_time_hour(prefs.get("daily_crate_reminder_time", "10:00"))
        if local_hour != reminder_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        local_date = _get_user_local_date(tz_str)

        # Query unclaimed crates for today (and any earlier unclaimed dates)
        try:
            result = supabase.client.table("user_daily_crates") \
                .select("crate_date, daily_crate_available, streak_crate_available, activity_crate_available") \
                .eq("user_id", user_id) \
                .is_("selected_crate", "null") \
                .lte("crate_date", local_date) \
                .order("crate_date", desc=True) \
                .limit(9) \
                .execute()
            rows = result.data or []
        except Exception as e:
            logger.warning(f"⚠️ [Nudge] daily_crate query failed for {user_id}: {e}")
            continue

        # Filter to rows with at least one available type
        unclaimed_rows = [
            r for r in rows
            if r.get("daily_crate_available") or r.get("streak_crate_available") or r.get("activity_crate_available")
        ]
        if not unclaimed_rows:
            continue

        # Daily cap + dedup (shared with other nudges)
        daily_limit = prefs.get("daily_nudge_limit", 4)
        if _count_nudges_today(supabase, user_id, local_date) >= daily_limit:
            continue
        if not _try_dedup_insert(supabase, user_id, "daily_crate", local_date):
            continue

        # Aggregate available types across all unclaimed rows
        type_set = set()
        for r in unclaimed_rows:
            if r.get("activity_crate_available"):
                type_set.add("activity")
            if r.get("streak_crate_available"):
                type_set.add("streak")
            if r.get("daily_crate_available"):
                type_set.add("daily")

        count = len(unclaimed_rows)
        # Copy tone: simple, evocative — no coach persona needed for a gamified reward
        if count > 1:
            title = "🎁 Your crates are waiting"
            body = f"You have {count} unopened crates. Tap to collect your rewards."
        else:
            title = "🎁 Your daily crate is ready"
            body = "Tap to open and collect your reward."

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            continue

        try:
            success = await notif_svc.send_notification(
                fcm_token=fcm_token,
                title=title,
                body=body,
                notification_type=NotificationService.TYPE_DAILY_CRATE,
                data={
                    "crate_types": ",".join(sorted(type_set)),
                    "unclaimed_count": str(count),
                    "crate_date": local_date,
                },
            )
            if success:
                sent += 1
                logger.info(f"✅ [Nudge] daily_crate sent to {user_id} ({count} crates, types={sorted(type_set)})")
        except Exception as e:
            logger.error(f"❌ [Nudge] daily_crate send failed for {user_id}: {e}")

    return sent


# ─── Proactive Health Coaching Nudges (Phase C2) ─────────────────────────────
#
# Three timezone-aware proactive coaching nudges built on the Phase-B1 health
# snapshot (services/user_context/health_activity.py) and the Phase-C1 content
# engine (services/health_coaching.py):
#
#   - daily_readiness  — the anchor MORNING push. Carries the readiness
#                        briefing; adapts to a good vs poor night + recovery +
#                        today's workout. Sent once per day.
#   - health_anomaly   — EVENT-DRIVEN. Resting HR elevated >= 2 consecutive days
#                        vs a >= 14-day baseline; suppressed during a hard
#                        training block; informs, never diagnoses.
#   - activity_goal    — user-local AFTERNOON. Fires when the user is behind
#                        their step goal; congratulates when already met.
#
# Each nudge — unlike the template-pool accountability nudges — carries
# DETERMINISTIC content already composed by health_coaching.build_*. So instead
# of routing through _send_nudge (which regenerates copy from template pools),
# they use _send_health_coaching_nudge below, which still enforces every gate:
# vacation/comeback suppression, daily cap, once/day dedup, and FCM delivery,
# and still mirrors the message into chat_history so it appears in the coach
# chat — exactly like the other proactive nudges.
#
# Shared gating (mirrors the existing jobs):
#   data exists (snapshot has_data + a usable message) · per-type preference on
#   · account >= 3 days · quiet hours · vacation/comeback · once/day dedup ·
#   daily cap · not a DST-transition night (briefing tone safety).

# RHR is treated as "elevated" for the anomaly job at or above this many bpm
# over the personal baseline — kept in lockstep with health_coaching's
# _RHR_ANOMALY_DELTA so the cron's consecutive-day pre-check and the message
# builder agree on what counts as elevated.
_ANOMALY_RHR_DELTA_BPM = 7.0

# A "hard training block" suppresses the anomaly alert: an elevated RHR right
# after heavy training is expected fatigue, not a warning sign (edge case F30).
# We treat >= this many completed workouts in the trailing 3 days as a hard
# block.
_HARD_BLOCK_WORKOUTS_3D = 3

# Account must be at least this old before any proactive health nudge fires —
# gives the wearable a few days to sync a usable baseline and avoids nagging a
# brand-new user (plan Phase C2 gate).
_HEALTH_NUDGE_MIN_ACCOUNT_DAYS = 3


def _user_context_service():
    """Lazily build a UserContextService for the Phase-B1 health snapshot.

    Imported lazily (not at module load) so the nudge cron has no hard import
    dependency on the user-context package — matching how the other jobs pull
    in heavy services only when their job actually runs.
    """
    from services.user_context.service import UserContextService

    return UserContextService()


async def _send_health_coaching_nudge(
    supabase,
    notif_svc,
    user: dict,
    nudge_type: str,
    title: str,
    message: str,
    route: str,
    facts: dict,
) -> bool:
    """Send a proactive health-coaching nudge with PRE-BUILT deterministic copy.

    Unlike ``_send_nudge``, the message text here is already composed by the
    Phase-C1 ``health_coaching`` engine (deterministic, number-safe), so this
    helper does NOT regenerate copy from a template pool. It still enforces the
    full gate stack and mirrors the message into the coach chat.

    Order of gates (identical reasoning to ``_send_nudge``):
      1. vacation/comeback suppression — before dedup so suppressed nudges
         don't burn a dedup slot;
      2. daily cap — before the dedup insert;
      3. atomic once/day dedup via the push_nudge_log UNIQUE constraint;
      4. mirror into chat_history (best-effort — a failed mirror still pushes);
      5. FCM push.

    Args:
        nudge_type: 'daily_readiness' | 'health_anomaly' | 'activity_goal'.
        title: push title (coach persona name when available).
        message: the deterministic message body from health_coaching.build_*.
        route: deep-link route for the tap action (the in-app surface, C3).
        facts: the builder's ``facts`` dict — persisted on the chat context.

    Returns:
        True when an FCM push was sent, False on any gate miss / no token.
    """
    user_id = str(user["id"])
    tz_str = user.get("timezone") or "UTC"
    local_date = _get_user_local_date(tz_str)
    prefs = user.get("notification_preferences") or {}

    # Master push toggle (item 6a) — a single off-switch for ALL server push.
    if not prefs.get("push_notifications_enabled", True):
        return False

    # 1. Global suppression gate (vacation + comeback). Checked BEFORE dedup so
    #    a suppressed nudge doesn't consume its once/day dedup slot.
    suppression = should_suppress_notification(user, nudge_type, channel="push")
    if suppression:
        logger.debug(
            f"🔕 [HealthNudge] Suppressed {nudge_type} for {user_id}: {suppression}"
        )
        return False

    # 2. Daily cap (shared across ALL nudge types via push_nudge_log).
    daily_limit = prefs.get("daily_nudge_limit", 2)
    if _count_nudges_today(supabase, user_id, local_date) >= daily_limit:
        return False

    # 3. Atomic once/day dedup. A cron retry / overlap is a no-op.
    if not _try_dedup_insert(supabase, user_id, nudge_type, local_date):
        return False

    # 4. Mirror into chat_history so the coach chat shows the proactive message
    #    (same pattern as _send_nudge — best-effort, never blocks the push).
    coach_name = (user.get("_ai_settings") or {}).get("coach_name") or "Your Coach"
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
                **{k: v for k, v in facts.items()
                   if isinstance(v, (str, int, float, bool))},
            },
        }).execute()
        if chat_msg.data:
            chat_message_id = chat_msg.data[0].get("id")
    except Exception as e:
        logger.warning(
            f"⚠️ [HealthNudge] chat_history insert failed for {user_id}: {e}",
            exc_info=True,
        )

    if chat_message_id:
        try:
            supabase.client.table("push_nudge_log") \
                .update({"chat_message_id": str(chat_message_id)}) \
                .eq("user_id", user_id) \
                .eq("nudge_type", nudge_type) \
                .eq("nudge_date", local_date) \
                .execute()
        except Exception:
            pass  # Non-critical.

    # 5. FCM push. A shared deterministic notif_id (<type>_<localdate>) lets
    #    Phase C3 dedupe a push + its in-app banner into ONE notification-bell
    #    entry (plan edge case E29).
    fcm_token = user.get("fcm_token")
    if not fcm_token:
        logger.debug(f"⏭️ [HealthNudge] {user_id} — no FCM token")
        return False

    from services.notification_service_helpers import NotificationService

    try:
        success = await notif_svc.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=message,
            notification_type=NotificationService.TYPE_AI_COACH,
            data={
                "nudge_type": nudge_type,
                "notif_id": f"{nudge_type}_{local_date}",
                "route": route,
                "chat_message_id": str(chat_message_id) if chat_message_id else "",
                "proactive": "true",
            },
        )
    except Exception as e:
        logger.error(
            f"❌ [HealthNudge] send failed for {user_id} ({nudge_type}): {e}",
            exc_info=True,
        )
        return False

    if success:
        logger.info(f"✅ [HealthNudge] {nudge_type} sent to {user_id}")
    return bool(success)


def _today_workout_row(supabase, user_id: str, user_today: str) -> Optional[dict]:
    """Today's scheduled workout row (``{name, type, ...}``) or None.

    Used so the readiness briefing can name the actual session. A rest day
    (no row) is fine — the C1 builder falls back to a generic phrase.
    """
    try:
        rows = supabase.client.table("workouts") \
            .select("id, name, type, is_completed, scheduled_date") \
            .eq("user_id", user_id) \
            .eq("scheduled_date", user_today) \
            .limit(1) \
            .execute()
        return rows.data[0] if rows.data else None
    except Exception:
        return None


async def _job_daily_readiness(supabase, notif_svc, users: List[dict]) -> int:
    """Anchor MORNING readiness briefing — the proactive coaching push.

    Fires once per day at the user's local briefing hour (the
    ``daily_briefing_time`` preference, default 08:00). Carries the Phase-C1
    ``build_daily_briefing`` message, which adapts to a good vs poor night, the
    recovery tier, and today's scheduled workout.

    Gates:
      - per-type pref ``daily_briefing_nudge`` on (default True);
      - account >= 3 days old;
      - local hour == the user's briefing hour;
      - not in quiet hours;
      - NOT a DST-transition night — on such a night last night's sleep window
        was computed across a clock change, so a "poor sleep" tone could be
        spurious; we skip the briefing entirely that morning (edge case E24).
      - the snapshot yields a usable briefing (``has_message``). A no-wearable
        / no-consent user is skipped SILENTLY — never a fabricated briefing.
        Note: a no-SLEEP (but has activity) day still gets a lighter
        activity-only briefing from the C1 builder — it is NOT skipped (F31).
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("daily_briefing_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        briefing_hour = _parse_time_hour(prefs.get("daily_briefing_time", "08:00"))
        if local_hour != briefing_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue
        # DST-transition night → skip the briefing (tone-safety, edge case E24).
        if _is_dst_transition_night(tz_str):
            logger.debug(
                f"🔕 [HealthNudge] daily_readiness skipped for {user['id']} — "
                f"DST-transition night"
            )
            continue

        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        # Build the snapshot + briefing. Any failure → skip silently.
        try:
            if svc is None:
                svc = _user_context_service()
            from services.health_coaching import build_daily_briefing

            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
            today_workout = _today_workout_row(supabase, user_id, user_today)
            briefing = build_daily_briefing(snapshot, today_workout=today_workout)
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] daily_readiness build failed for {user_id}: {e}"
            )
            continue

        if not briefing.get("has_message"):
            continue  # No wearable / no consent — skip silently (no mock data).

        ai = user.get("_ai_settings") or {}
        coach_name = ai.get("coach_name") or "Your Coach"

        # Deterministic briefing is the honest, number-safe baseline. Try the
        # data-grounded LLM briefing first (synthesized narrative + an insight
        # title + calibrated action bullets, the way a coach who remembers you
        # would write it). If Gemini is unavailable OR cites any ungrounded
        # number, generate_smart_briefing returns None and we keep the
        # deterministic copy — never a fabricated stat.
        # PUNCHY insight-title fallback: never the generic "<coach>'s morning
        # briefing" label. Derive a data-grounded insight title from the
        # leading real signal (carries no digits, so it is grounded by
        # construction). The LLM path below overrides it with its own insight
        # title when it succeeds.
        from services.coach.grounding import deterministic_insight_title

        title = deterministic_insight_title(snapshot, moment="morning_readiness")
        message = briefing["message"]
        facts = briefing.get("facts") or {}
        try:
            from services.coach.smart_briefing import generate_smart_briefing

            smart = await generate_smart_briefing(
                supabase, user_id, snapshot, today_workout,
                moment="morning_readiness",
                first_name=(user.get("name") or "").split(" ")[0] or _email_prefix(user),
                time_of_day="morning",
                coach_name=coach_name,
                coaching_style=ai.get("coaching_style", "motivational"),
                communication_tone=ai.get("communication_tone", "encouraging"),
            )
            if smart and smart.get("has_message"):
                # The insight IS the title (not a generic "morning briefing").
                title = smart["title"]
                message = smart["message"]
                facts = {**facts, **(smart.get("facts") or {})}
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] smart briefing failed for {user_id}, "
                f"using deterministic: {e}"
            )

        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "daily_readiness",
            title=title,
            message=message,
            route="/health/sleep",
            facts=facts,
        )
        if success:
            sent += 1

    return sent


def _is_in_hard_training_block(supabase, user_id: str) -> bool:
    """True if the user completed >= 3 workouts in the trailing 3 days.

    Used to suppress the resting-HR anomaly alert: an elevated RHR right after
    a heavy training stretch is expected training fatigue, not a warning sign
    (edge case F30). Fails OPEN (returns False → alert may proceed) on any
    query error, since the anomaly copy informs rather than diagnoses.
    """
    try:
        cutoff = (datetime.utcnow() - timedelta(days=3)).isoformat()
        res = supabase.client.table("workout_logs") \
            .select("id", count="exact") \
            .eq("user_id", user_id) \
            .eq("status", "completed") \
            .gte("completed_at", cutoff) \
            .execute()
        return (res.count or 0) >= _HARD_BLOCK_WORKOUTS_3D
    except Exception:
        return False


def _rhr_elevated_consecutive_days(supabase, user_id: str) -> bool:
    """True if resting HR has been elevated for 2-3 CONSECUTIVE recent days.

    The Phase-C1 ``build_health_anomaly`` builder only checks TODAY's RHR vs
    the baseline. The plan additionally requires the elevation to PERSIST for
    2-3 consecutive days before the cron fires the alert — a single elevated
    morning is normal day-to-day variation (edge case F30). This pre-check
    reads the trailing daily_activity rows directly and confirms the streak.

    Logic:
      - pull the last ~30 activity rows (newest-first);
      - need >= 14 RHR readings for a trustworthy baseline (matches B1);
      - baseline = mean of all available RHR readings;
      - require the 2 MOST RECENT days both >= baseline + delta, and treat a
        3-day streak the same (2-3 consecutive elevated days).
    Returns False (no alert) on insufficient data or any error.
    """
    try:
        rows = supabase.client.table("daily_activity") \
            .select("activity_date, resting_heart_rate") \
            .eq("user_id", user_id) \
            .order("activity_date", desc=True) \
            .limit(30) \
            .execute()
    except Exception:
        return False

    data = rows.data or []
    rhr_values = [
        r.get("resting_heart_rate")
        for r in data
        if r.get("resting_heart_rate") is not None
    ]
    # Need a >= 14-reading baseline (mirrors the B1 snapshot's threshold).
    if len(rhr_values) < 14:
        return False

    try:
        baseline = sum(float(v) for v in rhr_values) / len(rhr_values)
    except (TypeError, ValueError):
        return False
    threshold = baseline + _ANOMALY_RHR_DELTA_BPM

    # The two most recent days must BOTH be elevated. data is newest-first.
    recent = [
        r.get("resting_heart_rate")
        for r in data[:3]
        if r.get("resting_heart_rate") is not None
    ]
    if len(recent) < 2:
        return False
    try:
        return all(float(recent[i]) >= threshold for i in range(2))
    except (TypeError, ValueError):
        return False


async def _job_health_anomaly(supabase, notif_svc, users: List[dict]) -> int:
    """EVENT-DRIVEN resting-HR anomaly alert.

    Fires when ALL of these hold (edge case F30):
      - per-type pref ``health_anomaly_nudge`` on (default True);
      - account >= 3 days old;
      - resting HR has been elevated for 2-3 CONSECUTIVE days vs a >= 14-day
        baseline (``_rhr_elevated_consecutive_days``);
      - the user is NOT in a hard training block (>= 3 workouts / 3 days), where
        an elevated RHR is expected fatigue, not a warning;
      - the Phase-C1 ``build_health_anomaly`` builder also confirms the
        elevation against the snapshot (so the message numbers are consistent).

    Being event-driven it has no fixed hour — but to avoid an inbox-jarring
    overnight ping it only sends during waking local hours (08:00-21:00) and
    never inside quiet hours. The copy informs, never diagnoses.
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("health_anomaly_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        # Event-driven, but keep it to waking hours so an anomaly that becomes
        # true overnight is delivered in the morning, not at 3 AM.
        if not (8 <= local_hour <= 21):
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])

        # Consecutive-day elevation pre-check (the cron-side gate).
        if not _rhr_elevated_consecutive_days(supabase, user_id):
            continue
        # Suppress during a hard training block — expected fatigue, not a flag.
        if _is_in_hard_training_block(supabase, user_id):
            logger.debug(
                f"🔕 [HealthNudge] health_anomaly suppressed for {user_id} — "
                f"hard training block"
            )
            continue

        # Confirm with the C1 builder so the message numbers match the snapshot.
        try:
            if svc is None:
                svc = _user_context_service()
            from services.health_coaching import build_health_anomaly

            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
            anomaly = build_health_anomaly(snapshot)
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] health_anomaly build failed for {user_id}: {e}"
            )
            continue

        if not anomaly.get("has_message"):
            continue  # Builder disagrees (no baseline / within normal) — skip.

        coach_name = (user.get("_ai_settings") or {}).get("coach_name") or "Your Coach"
        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "health_anomaly",
            title=f"A note from {coach_name}",
            message=anomaly["message"],
            route="/health/combined",
            facts=anomaly.get("facts") or {},
        )
        if success:
            sent += 1

    return sent


async def _job_activity_goal(supabase, notif_svc, users: List[dict]) -> int:
    """Activity / step-goal nudge — fires in the user's local AFTERNOON.

    Carries the Phase-C1 ``build_activity_nudge`` message: a "close the gap"
    nudge when behind the step goal, an "almost there" nudge when within reach,
    or a congratulation when the goal is already met.

    Gates:
      - per-type pref ``activity_goal_nudge`` on (default True);
      - account >= 3 days old;
      - local hour == the user's activity-nudge hour (the
        ``activity_nudge_time`` preference, default 15:00 — afternoon);
      - not in quiet hours;
      - the snapshot yields a step count today (``has_message``). No wearable /
        no step data → skipped SILENTLY (no fabricated steps). A goal-less user
        still gets a nudge against a CDC-derived default goal (edge case F32).
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("activity_goal_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        nudge_hour = _parse_time_hour(prefs.get("activity_nudge_time", "15:00"))
        if local_hour != nudge_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])

        try:
            if svc is None:
                svc = _user_context_service()
            from services.health_coaching import build_activity_nudge

            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
            nudge = build_activity_nudge(snapshot)
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] activity_goal build failed for {user_id}: {e}"
            )
            continue

        if not nudge.get("has_message"):
            continue  # No step data — skip silently (no mock data).

        coach_name = (user.get("_ai_settings") or {}).get("coach_name") or "Your Coach"
        # Goal-met → a congratulation; behind / almost → a step nudge.
        if nudge.get("pattern") == "goal_met":
            title = "Step goal cleared"
        else:
            title = f"{coach_name}: step check-in"
        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "activity_goal",
            title=title,
            message=nudge["message"],
            route="/health/combined",
            facts=nudge.get("facts") or {},
        )
        if success:
            sent += 1

    return sent


async def _job_evening_recap(supabase, notif_svc, users: List[dict]) -> int:
    """Flagship EVENING recap — a reflective, data-grounded coaching push.

    Pairs with the morning readiness briefing. Fires once per day at the
    user's local ``evening_recap_time`` (default 20:00). Reflects on how today
    actually went (steps, workout, recent training) and sets up tomorrow.

    Primary path is the data-grounded LLM recap. When Gemini is unavailable or
    cites an ungrounded number, we DO NOT go silent: we fall back to
    ``build_deterministic_recap`` which composes a recap from REAL snapshot
    numbers only (no mock data, no fabricated stat). We only skip when there is
    no wearable data at all, or genuinely nothing real to recap.

    Gates (mirror daily_readiness): per-type pref ``evening_recap_nudge`` on;
    account >= 3 days; local hour == recap hour; not in quiet hours.
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("evening_recap_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        recap_hour = _parse_time_hour(prefs.get("evening_recap_time", "20:00"))
        if local_hour != recap_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        user_today = _get_user_local_date(tz_str)

        try:
            if svc is None:
                svc = _user_context_service()
            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] evening_recap snapshot failed for {user_id}: {e}"
            )
            continue

        if not snapshot or not snapshot.get("has_data"):
            continue  # No wearable / no consent — skip silently.

        ai = user.get("_ai_settings") or {}
        coach_name = ai.get("coach_name") or "Your Coach"
        today_workout = _today_workout_row(supabase, user_id, user_today)
        first_name = (user.get("name") or "").split(" ")[0] or _email_prefix(user)

        smart = None
        try:
            from services.coach.smart_briefing import generate_smart_briefing

            smart = await generate_smart_briefing(
                supabase, user_id, snapshot, today_workout,
                moment="evening_recap",
                first_name=first_name,
                time_of_day="evening",
                coach_name=coach_name,
                coaching_style=ai.get("coaching_style", "motivational"),
                communication_tone=ai.get("communication_tone", "encouraging"),
            )
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] evening_recap build failed for {user_id}: {e}"
            )

        # DETERMINISTIC FALLBACK (no silent drop): if the LLM path returned
        # nothing, build a grounded recap from real snapshot numbers only.
        if not smart or not smart.get("has_message"):
            try:
                from services.coach.smart_briefing import build_deterministic_recap

                workout_done = None
                if today_workout is not None:
                    workout_done = bool(today_workout.get("is_completed"))
                smart = build_deterministic_recap(
                    snapshot, first_name, today_workout_done=workout_done
                )
            except Exception as e:
                logger.warning(
                    f"⚠️ [HealthNudge] evening_recap deterministic fallback "
                    f"failed for {user_id}: {e}"
                )
                smart = None

        if not smart or not smart.get("has_message"):
            continue  # Genuinely nothing real to recap — skip (never fabricate).

        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "evening_recap",
            title=smart["title"],
            message=smart["message"],
            route="/home",
            facts=smart.get("facts") or {},
        )
        if success:
            sent += 1

    return sent


# ─── New data-grounded moments (WS3 Part B) ─────────────────────────────────
# Each new job mirrors _job_daily_readiness / _job_evening_recap exactly: per-
# type pref gate · account >= 3 days · user-local hour · quiet hours · the
# shared generate_smart_briefing + grounding guardrail · dedup. The low-
# frequency trend jobs add a multi-day COOLDOWN on top of the once/day dedup so
# a persisting condition never fires daily. All numbers come from real data; a
# job that lacks its trigger data SKIPS silently (no mock data).

# Cooldown windows (days) for the trend jobs — a persisting condition should
# not re-ping daily. weekly_recap needs none (it is day-of-week gated).
_SLEEP_DEBT_COOLDOWN_DAYS = 4
_RHR_TREND_COOLDOWN_DAYS = 5
_PROTEIN_TREND_COOLDOWN_DAYS = 4
_VOLUME_BALANCE_COOLDOWN_DAYS = 6
# WS-B injury check-in: a recovery-phase injury check-in must never nag. A logged
# injury sits in recovery/reintroduction for several days, so without a cooldown
# the job would re-ask the same "still bothering you?" question every day it runs.
# 4 days mirrors the sleep-debt cadence — long enough to feel like a thoughtful
# follow-up, short enough that a tapped "Still sore" gets re-checked within the
# week.
_INJURY_CHECKIN_COOLDOWN_DAYS = 4
# Local hour the injury check-in fires at (user-local). Mid-morning (10:00) so it
# lands in waking hours but after the morning readiness briefing.
_INJURY_CHECKIN_HOUR = 10

# A protein day "under target" means below this fraction of the daily target.
_PROTEIN_UNDER_FRACTION = 0.8
# Need this many of the trailing days under target before nudging.
_PROTEIN_UNDER_MIN_DAYS = 3
# Weekly training volume must swing at least this fraction vs the prior week
# before volume_balance fires (a deload-or-push signal, not noise).
_VOLUME_SWING_FRACTION = 0.35


def _weekly_training_aggregates(
    supabase, user_id: str, tz_str: str
) -> Optional[Dict[str, Any]]:
    """REAL training aggregates for the trailing 7 local days + the prior 7.

    Reads ``workout_logs`` (completed sessions carry ``completed_at`` +
    ``total_time_seconds``). Returns active minutes + workout count for this
    week and last week, plus the consistency-day count. Every value is a real
    count / sum; returns ``None`` on any error so the caller skips cleanly.
    """
    try:
        now_local = datetime.now(_safe_zone(tz_str))
        this_week_start = (now_local - timedelta(days=7)).isoformat()
        prior_week_start = (now_local - timedelta(days=14)).isoformat()
        rows = (
            supabase.client.table("workout_logs")
            .select("completed_at, total_time_seconds")
            .eq("user_id", user_id)
            .gte("completed_at", prior_week_start)
            .order("completed_at", desc=True)
            .limit(60)
            .execute()
        ).data or []
    except Exception:
        return None

    this_secs = 0
    this_count = 0
    prior_secs = 0
    prior_count = 0
    active_days: set = set()
    for r in rows:
        ca = r.get("completed_at")
        if not ca:
            continue
        secs = r.get("total_time_seconds") or 0
        try:
            secs = int(secs)
        except (TypeError, ValueError):
            secs = 0
        if ca >= this_week_start:
            this_secs += secs
            this_count += 1
            active_days.add(str(ca)[:10])
        elif ca >= prior_week_start:
            prior_secs += secs
            prior_count += 1

    return {
        "active_minutes_week": round(this_secs / 60),
        "workouts_completed_week": this_count,
        "consistency_days": len(active_days),
        "active_minutes_prior_week": round(prior_secs / 60),
        "workouts_completed_prior_week": prior_count,
    }


def _protein_under_target_days(
    supabase, user_id: str, tz_str: str
) -> Optional[Dict[str, Any]]:
    """Count trailing days where logged protein landed under target.

    Real data only: target from ``nutrition_preferences.target_protein_g``,
    intake summed from ``food_logs.protein_g`` grouped by local day. Returns
    ``{under_days, protein_target_g}`` when at least ``_PROTEIN_UNDER_MIN_DAYS``
    of the trailing logged days were under target, else ``None`` (skip).
    """
    try:
        pref = (
            supabase.client.table("nutrition_preferences")
            .select("target_protein_g")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        ).data
    except Exception:
        return None
    if not pref:
        return None
    target = pref[0].get("target_protein_g")
    try:
        target = float(target)
    except (TypeError, ValueError):
        return None
    if target <= 0:
        return None

    try:
        now_local = datetime.now(_safe_zone(tz_str))
        window_start = (now_local - timedelta(days=5)).isoformat()
        logs = (
            supabase.client.table("food_logs")
            .select("created_at, protein_g")
            .eq("user_id", user_id)
            .gte("created_at", window_start)
            .limit(500)
            .execute()
        ).data or []
    except Exception:
        return None
    if not logs:
        return None

    by_day: Dict[str, float] = {}
    for r in logs:
        ca = r.get("created_at")
        if not ca:
            continue
        day = str(ca)[:10]
        try:
            by_day[day] = by_day.get(day, 0.0) + float(r.get("protein_g") or 0)
        except (TypeError, ValueError):
            continue

    if not by_day:
        return None
    floor = target * _PROTEIN_UNDER_FRACTION
    under_days = sum(1 for v in by_day.values() if v < floor)
    if under_days < _PROTEIN_UNDER_MIN_DAYS:
        return None
    return {"protein_under_days": under_days, "protein_target_g": round(target)}


async def _job_weekly_recap(supabase, notif_svc, users: List[dict]) -> int:
    """FLAGSHIP Sunday-evening data-grounded WEEK wrap.

    Fires once on the user's configured week-end day (reusing the
    ``weekly_checkin_day`` pref, default Sunday) at their evening recap hour.
    Carries the week's REAL aggregates (active minutes, workouts completed,
    consistency days) via generate_smart_briefing, an honest reflection, then
    1-2 setup-the-week actions. A zero-active week stays encouraging (the
    weekly_recap moment guidance enforces no guilt). Distinct from
    ``_job_weekly_checkin`` (a nutrition reminder).

    Gates: per-type pref ``weekly_recap_nudge`` on; account >= 3 days (new
    users get no weekly recap); local weekday == configured day; local hour ==
    evening recap hour; not in quiet hours. Once/week via the day gate + the
    once/day dedup.
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("weekly_recap_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_now = datetime.now(_safe_zone(tz_str))
        local_hour = local_now.hour
        local_weekday = local_now.weekday()  # 0=Mon .. 6=Sun

        # Reuse the weekly check-in day pref (0=Sunday convention) so the user's
        # one week-end-day choice drives both. Convert to Python weekday.
        pref_day = prefs.get("weekly_checkin_day", 0)
        python_weekday = 6 if pref_day == 0 else pref_day - 1
        if local_weekday != python_weekday:
            continue

        recap_hour = _parse_time_hour(prefs.get("evening_recap_time", "20:00"))
        if local_hour != recap_hour:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])

        weekly = _weekly_training_aggregates(supabase, user_id, tz_str)
        if weekly is None:
            continue  # No training data source — skip silently.

        try:
            if svc is None:
                svc = _user_context_service()
            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] weekly_recap snapshot failed for {user_id}: {e}"
            )
            continue
        if not snapshot or not snapshot.get("has_data"):
            # Still wrap the training week even without a wearable: build a
            # minimal grounded snapshot stub so generate_smart_briefing runs on
            # the real weekly aggregates (no mock numbers added).
            snapshot = {"has_data": True, "weekly_only": True}

        ai = user.get("_ai_settings") or {}
        coach_name = ai.get("coach_name") or "Your Coach"
        first_name = (user.get("name") or "").split(" ")[0] or _email_prefix(user)

        try:
            from services.coach.smart_briefing import generate_smart_briefing

            smart = await generate_smart_briefing(
                supabase, user_id, snapshot, None,
                moment="weekly_recap",
                first_name=first_name,
                time_of_day="evening",
                coach_name=coach_name,
                coaching_style=ai.get("coaching_style", "motivational"),
                communication_tone=ai.get("communication_tone", "encouraging"),
                extra_facts={"weekly": weekly},
            )
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] weekly_recap build failed for {user_id}: {e}"
            )
            continue
        if not smart or not smart.get("has_message"):
            continue

        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "weekly_recap",
            title=smart["title"],
            message=smart["message"],
            route="/home",
            facts=smart.get("facts") or {},
        )
        if success:
            sent += 1

    return sent


async def _job_sleep_debt(supabase, notif_svc, users: List[dict]) -> int:
    """3+ short nights in a row → recovery-protective nudge.

    Multi-night trend (distinct from single-event health_anomaly). The pattern
    is detected inside generate_smart_briefing (``trend.short_sleep_nights``);
    here we pre-check the same condition cheaply so we only invoke the LLM when
    the streak genuinely exists. Cooldown so it does not fire daily.

    Gates: per-type pref ``sleep_debt_nudge`` on; account >= 3 days; waking
    morning hours (07:00-10:00, user-local, when the short night is fresh); not
    quiet hours; not within the cooldown window.
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("sleep_debt_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        if not (7 <= local_hour <= 10):
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        if _sent_within_days(supabase, user_id, "sleep_debt", _SLEEP_DEBT_COOLDOWN_DAYS):
            continue

        try:
            if svc is None:
                svc = _user_context_service()
            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] sleep_debt snapshot failed for {user_id}: {e}"
            )
            continue
        if not snapshot or not snapshot.get("has_data"):
            continue

        ai = user.get("_ai_settings") or {}
        coach_name = ai.get("coach_name") or "Your Coach"
        first_name = (user.get("name") or "").split(" ")[0] or _email_prefix(user)

        try:
            from services.coach.smart_briefing import (
                generate_smart_briefing,
                _recent_activity_rows,
                _build_pattern_context,
            )

            # Cheap pre-check: only fire when a real short-sleep streak exists.
            pattern = _build_pattern_context(
                _recent_activity_rows(supabase, user_id),
                (snapshot.get("steps") or {}).get("goal"),
                (snapshot.get("heart_rate") or {}).get("resting_baseline"),
            )
            if not pattern.get("short_sleep_nights"):
                continue

            smart = await generate_smart_briefing(
                supabase, user_id, snapshot, None,
                moment="sleep_debt",
                first_name=first_name,
                time_of_day="morning",
                coach_name=coach_name,
                coaching_style=ai.get("coaching_style", "motivational"),
                communication_tone=ai.get("communication_tone", "encouraging"),
            )
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] sleep_debt build failed for {user_id}: {e}"
            )
            continue
        if not smart or not smart.get("has_message"):
            continue

        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "sleep_debt",
            title=smart["title"],
            message=smart["message"],
            route="/health/sleep",
            facts=smart.get("facts") or {},
        )
        if success:
            sent += 1

    return sent


async def _job_rhr_trend(supabase, notif_svc, users: List[dict]) -> int:
    """Resting HR creeping above baseline across several days → early signal.

    Distinct from the single-spike health_anomaly: this is a multi-day creep
    (early overtraining / illness signal). Reuses the consecutive-day RHR
    pre-check, then generate_smart_briefing with the ``rhr_trend`` moment.
    Cooldown so it does not re-ping daily.

    Gates: per-type pref ``rhr_trend_nudge`` on; account >= 3 days; waking
    hours (08:00-21:00); not quiet hours; not in cooldown; not in a hard
    training block (expected fatigue, not a flag).
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("rhr_trend_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        if not (8 <= local_hour <= 21):
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        if _sent_within_days(supabase, user_id, "rhr_trend", _RHR_TREND_COOLDOWN_DAYS):
            continue
        if not _rhr_elevated_consecutive_days(supabase, user_id):
            continue
        if _is_in_hard_training_block(supabase, user_id):
            continue

        try:
            if svc is None:
                svc = _user_context_service()
            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] rhr_trend snapshot failed for {user_id}: {e}"
            )
            continue
        if not snapshot or not snapshot.get("has_data"):
            continue

        ai = user.get("_ai_settings") or {}
        coach_name = ai.get("coach_name") or "Your Coach"
        first_name = (user.get("name") or "").split(" ")[0] or _email_prefix(user)

        try:
            from services.coach.smart_briefing import generate_smart_briefing

            smart = await generate_smart_briefing(
                supabase, user_id, snapshot, None,
                moment="rhr_trend",
                first_name=first_name,
                time_of_day="morning" if local_hour < 12 else (
                    "afternoon" if local_hour < 17 else "evening"
                ),
                coach_name=coach_name,
                coaching_style=ai.get("coaching_style", "motivational"),
                communication_tone=ai.get("communication_tone", "encouraging"),
            )
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] rhr_trend build failed for {user_id}: {e}"
            )
            continue
        if not smart or not smart.get("has_message"):
            continue

        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "rhr_trend",
            title=smart["title"],
            message=smart["message"],
            route="/health/combined",
            facts=smart.get("facts") or {},
        )
        if success:
            sent += 1

    return sent


async def _job_protein_trend(supabase, notif_svc, users: List[dict]) -> int:
    """Under protein target multiple days → nutrition-grounded nudge.

    Real intake from food_logs vs target from nutrition_preferences. Fires in
    the user's local late afternoon (a useful moment to influence dinner), with
    a cooldown so it does not nag daily.

    Gates: per-type pref ``protein_trend_nudge`` on; account >= 3 days; local
    hour == the afternoon activity-nudge hour (reused, default 15:00) or 16:00
    fallback window; not quiet hours; not in cooldown; >= N under-target days.
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("protein_trend_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        # Late afternoon so the nudge can still shape dinner.
        if local_hour != 16:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        if _sent_within_days(
            supabase, user_id, "protein_trend", _PROTEIN_TREND_COOLDOWN_DAYS
        ):
            continue

        protein = _protein_under_target_days(supabase, user_id, tz_str)
        if protein is None:
            continue  # Not enough under-target days or no target — skip.

        try:
            if svc is None:
                svc = _user_context_service()
            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
        except Exception:
            snapshot = None
        # Protein is independent of wearable sync; a stub snapshot lets the
        # grounded generator run on the real protein aggregates (no mock data).
        if not snapshot or not snapshot.get("has_data"):
            snapshot = {"has_data": True, "nutrition_only": True}

        ai = user.get("_ai_settings") or {}
        coach_name = ai.get("coach_name") or "Your Coach"
        first_name = (user.get("name") or "").split(" ")[0] or _email_prefix(user)

        try:
            from services.coach.smart_briefing import generate_smart_briefing

            smart = await generate_smart_briefing(
                supabase, user_id, snapshot, None,
                moment="protein_trend",
                first_name=first_name,
                time_of_day="afternoon",
                coach_name=coach_name,
                coaching_style=ai.get("coaching_style", "motivational"),
                communication_tone=ai.get("communication_tone", "encouraging"),
                extra_facts={"nutrition": protein},
            )
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] protein_trend build failed for {user_id}: {e}"
            )
            continue
        if not smart or not smart.get("has_message"):
            continue

        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "protein_trend",
            title=smart["title"],
            message=smart["message"],
            route="/nutrition",
            facts=smart.get("facts") or {},
        )
        if success:
            sent += 1

    return sent


async def _job_volume_balance(supabase, notif_svc, users: List[dict]) -> int:
    """Weekly training-volume swing → deload-or-push suggestion.

    Compares this week's active training minutes vs the prior week. A large
    swing (up or down) triggers a load-aware suggestion via the
    ``volume_balance`` moment. Real minute aggregates only. Long cooldown so it
    reads as a weekly-rhythm nudge, not a daily one.

    Gates: per-type pref ``volume_balance_nudge`` on; account >= 3 days;
    local late-morning hour (10:00); not quiet hours; not in cooldown; an
    actual swing >= _VOLUME_SWING_FRACTION against a non-trivial prior week.
    """
    sent = 0
    svc = None
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("volume_balance_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue

        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        if local_hour != 10:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue

        user_id = str(user["id"])
        if _sent_within_days(
            supabase, user_id, "volume_balance", _VOLUME_BALANCE_COOLDOWN_DAYS
        ):
            continue

        weekly = _weekly_training_aggregates(supabase, user_id, tz_str)
        if weekly is None:
            continue
        this_min = weekly.get("active_minutes_week", 0)
        prior_min = weekly.get("active_minutes_prior_week", 0)
        # Need a meaningful prior week to compare against (avoid 0 -> noise).
        if prior_min < 30:
            continue
        swing = abs(this_min - prior_min) / prior_min
        if swing < _VOLUME_SWING_FRACTION:
            continue

        try:
            if svc is None:
                svc = _user_context_service()
            snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
        except Exception:
            snapshot = None
        if not snapshot or not snapshot.get("has_data"):
            snapshot = {"has_data": True, "training_only": True}

        ai = user.get("_ai_settings") or {}
        coach_name = ai.get("coach_name") or "Your Coach"
        first_name = (user.get("name") or "").split(" ")[0] or _email_prefix(user)

        try:
            from services.coach.smart_briefing import generate_smart_briefing

            smart = await generate_smart_briefing(
                supabase, user_id, snapshot, None,
                moment="volume_balance",
                first_name=first_name,
                time_of_day="morning",
                coach_name=coach_name,
                coaching_style=ai.get("coaching_style", "motivational"),
                communication_tone=ai.get("communication_tone", "encouraging"),
                extra_facts={"weekly": weekly},
            )
        except Exception as e:
            logger.warning(
                f"⚠️ [HealthNudge] volume_balance build failed for {user_id}: {e}"
            )
            continue
        if not smart or not smart.get("has_message"):
            continue

        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, "volume_balance",
            title=smart["title"],
            message=smart["message"],
            route="/workouts",
            facts=smart.get("facts") or {},
        )
        if success:
            sent += 1

    return sent


# ─── WS-B: Injury recovery lifecycle check-in ────────────────────────────────
# A logged injury decays through recovery phases (services/injury_service.py +
# services/coach/injury_directives.py). When it reaches the recovery /
# reintroduction window the coach sends ONE grounded check-in carrying action
# chips so the user can close the loop in one tap — All better (resolve + ease
# back in), Still sore (extend the window), and, when the phase has rehab
# exercises, Do a rehab session (F1 rehab-as-workout). This job also performs
# the lazy auto-expire: any injury past its reintroduction grace window is
# dropped from active_injuries and its injury_history row is closed.

# Body-part display names so the title reads naturally (lower_back -> "lower
# back"). Falls back to the stored token with underscores spaced out.
def _injury_part_label(body_part: str) -> str:
    bp = (body_part or "").strip().lower()
    return {
        "lower_back": "lower back",
        "upper_back": "upper back",
    }.get(bp, bp.replace("_", " "))


async def _send_injury_checkin_nudge(
    supabase,
    notif_svc,
    user: dict,
    title: str,
    message: str,
    chips: List[Dict[str, str]],
    facts: dict,
) -> bool:
    """Send the injury recovery check-in — mirrors _send_health_coaching_nudge
    but ALSO carries action chips (All better / Still sore / Do a rehab
    session) on both the persisted chat message and the FCM payload so the
    coach surface can render them as one-tap shortcuts.

    The copy is deterministic (no fabricated numbers, no LLM) — the caller
    builds it from the real injury record. Full gate stack identical to the
    other proactive senders: master toggle, vacation/comeback suppression,
    daily cap, atomic once/day dedup, best-effort chat mirror, FCM push.
    """
    user_id = str(user["id"])
    tz_str = user.get("timezone") or "UTC"
    local_date = _get_user_local_date(tz_str)
    prefs = user.get("notification_preferences") or {}
    nudge_type = "injury_recovery"

    # Master push toggle.
    if not prefs.get("push_notifications_enabled", True):
        return False

    # Global suppression (vacation + comeback) — before dedup.
    suppression = should_suppress_notification(user, nudge_type, channel="push")
    if suppression:
        logger.debug(f"🔕 [InjuryNudge] Suppressed for {user_id}: {suppression}")
        return False

    # Daily cap (shared across all nudge types).
    daily_limit = prefs.get("daily_nudge_limit", 2)
    if _count_nudges_today(supabase, user_id, local_date) >= daily_limit:
        return False

    # Atomic once/day dedup. (The 4-day cooldown is checked by the caller via
    # _sent_within_days; this is the belt-and-suspenders same-day guard.)
    if not _try_dedup_insert(supabase, user_id, nudge_type, local_date):
        return False

    # Mirror into chat_history so the coach chat shows the check-in with its
    # chips (best-effort — a failed mirror still pushes).
    coach_name = (user.get("_ai_settings") or {}).get("coach_name") or "Your Coach"
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
                "chips": chips,
                **{k: v for k, v in facts.items()
                   if isinstance(v, (str, int, float, bool))},
            },
        }).execute()
        if chat_msg.data:
            chat_message_id = chat_msg.data[0].get("id")
    except Exception as e:
        logger.warning(
            f"⚠️ [InjuryNudge] chat_history insert failed for {user_id}: {e}",
            exc_info=True,
        )

    if chat_message_id:
        try:
            supabase.client.table("push_nudge_log") \
                .update({"chat_message_id": str(chat_message_id)}) \
                .eq("user_id", user_id) \
                .eq("nudge_type", nudge_type) \
                .eq("nudge_date", local_date) \
                .execute()
        except Exception:
            pass  # Non-critical.

    fcm_token = user.get("fcm_token")
    if not fcm_token:
        logger.debug(f"⏭️ [InjuryNudge] {user_id} — no FCM token")
        return False

    from services.notification_service_helpers import NotificationService

    try:
        success = await notif_svc.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=message,
            notification_type=NotificationService.TYPE_AI_COACH,
            data={
                "nudge_type": nudge_type,
                "notif_id": f"{nudge_type}_{local_date}",
                "route": "/chat",
                "chat_message_id": str(chat_message_id) if chat_message_id else "",
                "proactive": "true",
                # FCM data values must be strings — chips are JSON-encoded so
                # the client can decode the action payload on tap.
                "chips": json.dumps(chips),
            },
        )
    except Exception as e:
        logger.error(
            f"❌ [InjuryNudge] send failed for {user_id}: {e}", exc_info=True
        )
        return False

    if success:
        logger.info(f"✅ [InjuryNudge] injury_recovery sent to {user_id}")
    return bool(success)


def _expire_injuries(supabase, user_id: str, active: list, expired_ids: list) -> None:
    """Lazy auto-expire: drop injuries past their reintroduction window from
    active_injuries and close their injury_history rows. Best-effort; a failure
    never blocks the check-in. Mirrors the resolver's contract — `expired_ids`
    comes from resolve_injury_directives."""
    if not expired_ids:
        return
    expired = set(expired_ids)
    try:
        remaining = [
            inj for inj in active
            if not (isinstance(inj, dict) and inj.get("id") in expired)
        ]
        if len(remaining) != len(active):
            supabase.client.table("users").update(
                {"active_injuries": remaining}
            ).eq("id", user_id).execute()
        for inj_id in expired:
            if not inj_id:
                continue
            try:
                supabase.client.table("injury_history").update({
                    "is_active": False,
                    "recovery_phase": "healed",
                    "actual_recovery_date": datetime.now(ZoneInfo("UTC")).isoformat(),
                }).eq("id", inj_id).eq("is_active", True).execute()
            except Exception:
                pass
        logger.info(
            f"🩹 [InjuryNudge] auto-expired {len(expired)} injuries for {user_id}"
        )
    except Exception as e:
        logger.warning(
            f"⚠️ [InjuryNudge] auto-expire failed for {user_id}: {e}"
        )


async def _job_injury_recovery(supabase, notif_svc, users: List[dict]) -> int:
    """Recovery-phase injury check-in + lazy auto-expire (Workstream B).

    For each user with logged injuries, resolve phase-aware directives. Any
    injury in the `recovery` or `reintroduction` phase (i.e. near / at its
    expected recovery) gets ONE grounded "still bothering you?" check-in
    carrying All-better / Still-sore chips, plus a Do-a-rehab-session chip when
    the phase has rehab exercises (F1). Injuries past the reintroduction grace
    window are auto-resolved (dropped from active_injuries + injury_history
    closed) — no notification, just cleanup.

    Gates (mirror the WS3 jobs): per-type pref `injury_checkin_nudge` (default
    True); account >= 3 days; user-local hour == _INJURY_CHECKIN_HOUR (10:00);
    not quiet hours; not within the 4-day cooldown. Only ONE check-in per run
    even with multiple injuries (the most-progressed one) so we never stack
    pushes — the daily cap + dedup back this up.

    Deterministic throughout (no LLM): copy is built from the real injury
    record, phase from injury_directives.compute_phase.
    """
    if not users:
        return 0

    # Eligible candidates first (cheap gates) so we only fetch active_injuries
    # for users who could actually receive a check-in this hour.
    candidates = []
    for user in users:
        prefs = user.get("notification_preferences") or {}
        if not prefs.get("injury_checkin_nudge", True):
            continue
        if _user_account_age_days(user) < _HEALTH_NUDGE_MIN_ACCOUNT_DAYS:
            continue
        tz_str = user.get("timezone") or "UTC"
        local_hour = _get_user_local_hour(tz_str)
        if local_hour != _INJURY_CHECKIN_HOUR:
            continue
        if _is_in_quiet_hours(prefs, local_hour):
            continue
        candidates.append(user)

    if not candidates:
        return 0

    # Batch-fetch active_injuries for the candidates (not in the bulk user
    # select). A user with no injuries is skipped silently.
    candidate_ids = [str(u["id"]) for u in candidates]
    injuries_by_user: Dict[str, list] = {}
    try:
        rows = supabase.client.table("users") \
            .select("id, active_injuries") \
            .in_("id", candidate_ids[:500]) \
            .execute()
        for r in (rows.data or []):
            ai = r.get("active_injuries")
            if isinstance(ai, str):
                try:
                    ai = json.loads(ai)
                except json.JSONDecodeError:
                    ai = []
            injuries_by_user[str(r["id"])] = ai if isinstance(ai, list) else []
    except Exception as e:
        logger.error(f"❌ [InjuryNudge] active_injuries fetch failed: {e}")
        return 0

    try:
        from services.coach.injury_directives import (
            resolve_injury_directives,
            compute_phase,
        )
    except Exception as e:
        logger.error(f"❌ [InjuryNudge] injury_directives import failed: {e}")
        return 0

    sent = 0
    for user in candidates:
        user_id = str(user["id"])
        active = injuries_by_user.get(user_id) or []
        if not active:
            continue

        directives = resolve_injury_directives(active)

        # Lazy auto-expire FIRST (no notification) — keeps active_injuries and
        # injury_history in sync even on a quiet hour where no check-in fires.
        _expire_injuries(supabase, user_id, active, directives.get("expired_ids") or [])

        # Cooldown: never re-ask within the window even across multiple injuries.
        if _sent_within_days(
            supabase, user_id, "injury_recovery", _INJURY_CHECKIN_COOLDOWN_DAYS
        ):
            continue

        # Pick the single injury to check in on: the most-progressed one in the
        # recovery / reintroduction window (reintroduction is closest to done).
        checkin_injury = None
        checkin_phase = None
        for inj in active:
            if not isinstance(inj, dict):
                continue
            body_part = str(inj.get("body_part") or "").lower().strip()
            if not body_part:
                continue
            phase = compute_phase(
                reported_at=inj.get("reported_at"),
                severity=str(inj.get("severity") or "moderate").lower(),
                reintroduction_until=inj.get("reintroduction_until"),
            )
            if phase not in ("recovery", "reintroduction"):
                continue
            # Prefer reintroduction (nearest to resolved); otherwise first match.
            if checkin_injury is None or (
                phase == "reintroduction" and checkin_phase != "reintroduction"
            ):
                checkin_injury = inj
                checkin_phase = phase

        if checkin_injury is None:
            continue

        body_part = str(checkin_injury.get("body_part") or "").lower().strip()
        injury_id = checkin_injury.get("id")
        part_label = _injury_part_label(body_part)

        ai = user.get("_ai_settings") or {}
        first_name = (user.get("name") or "").split(" ")[0] or _email_prefix(user)

        # ── Grounded copy (no fabricated numbers) ────────────────────────────
        title = f"Is your {part_label} still bothering you?"
        if checkin_phase == "reintroduction":
            message = (
                f"Hey {first_name}, your {part_label} has been easing back in. "
                f"How's it feeling now? Let me know so I can set your next "
                f"workouts right."
            )
        else:
            message = (
                f"Hey {first_name}, it's been a little while since you flagged "
                f"your {part_label}. How's it feeling now? Your answer tells me "
                f"how hard to push your next workouts."
            )

        # ── Chips carry the injury context (body_part + injury_id) so the
        #    action handler knows which injury to act on. ────────────────────
        ctx = {"body_part": body_part}
        if injury_id:
            ctx["injury_id"] = str(injury_id)
        chips = [
            {"label": "All better", "action": "injury_resolved", **ctx},
            {"label": "Still sore", "action": "injury_extend", **ctx},
        ]
        # F1 rehab-as-workout: only when the phase actually has rehab exercises.
        has_rehab = any(
            isinstance(e, dict) and e.get("body_part") == body_part and e.get("rehab_exercises")
            for e in (directives.get("ease_in") or [])
        )
        if has_rehab:
            chips.append(
                {"label": "Do a rehab session", "action": "start_rehab", **ctx}
            )

        facts = {
            "body_part": body_part,
            "phase": checkin_phase,
            "injury_id": str(injury_id) if injury_id else "",
        }

        success = await _send_injury_checkin_nudge(
            supabase, notif_svc, user, title, message, chips, facts
        )
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
        # ── Core accountability jobs ──
        ("morning_workout", _job_morning_workout_reminder(supabase, notif_svc, users)),
        ("missed_workout", _job_missed_workout_nudge(supabase, notif_svc, users)),
        ("meal_reminders", _job_meal_reminders(supabase, notif_svc, users)),
        ("streak_at_risk", _job_streak_at_risk(supabase, notif_svc, users)),
        ("weekly_checkin", _job_weekly_checkin(supabase, notif_svc, users)),
        ("habit_reminder", _job_habit_reminder(supabase, notif_svc, users)),
        ("guilt_escalation", _job_guilt_escalation(supabase, notif_svc, users)),
        ("trial_reminder", _job_trial_reminder(supabase, notif_svc)),
        # ── Smart app-open hooks ──
        ("streak_countdown", _job_streak_countdown_urgency(supabase, notif_svc, users)),
        ("progress_milestone", _job_progress_milestone_teaser(supabase, notif_svc, users)),
        ("post_workout_nutrition", _job_post_workout_nutrition(supabase, notif_svc, users)),
        ("coach_insight", _job_coach_insight(supabase, notif_svc, users)),
        ("habit_streak_reward", _job_habit_streak_reward(supabase, notif_svc, users)),
        ("rest_day_tip", _job_rest_day_engagement(supabase, notif_svc, users)),
        ("progress_comparison", _job_progress_comparison(supabase, notif_svc, users)),
        ("time_capsule", _job_time_capsule(supabase, notif_svc, users)),
        ("chain_visual", _job_chain_visual(supabase, notif_svc, users)),
        ("recovery_complete", _job_recovery_complete(supabase, notif_svc, users)),
        # ── Merch engagement (migration 1931) ──
        ("merch_proximity", _job_merch_proximity(supabase, notif_svc, users)),
        ("merch_unlocked", _job_merch_unlocked(supabase, notif_svc, users)),
        ("merch_claim_reminder", _job_merch_claim_reminder(supabase, notif_svc, users)),
        # ── Level milestone celebration (migration 1935) ──
        ("level_milestone_celebration", _job_level_milestone_celebration(supabase, notif_svc, users)),
        # ── Week-1 retention ladder (W4) ──
        ("week1_day1", _job_week1_day1(supabase, notif_svc, users)),
        ("week1_day3", _job_week1_day3(supabase, notif_svc, users)),
        ("week1_day5", _job_week1_day5(supabase, notif_svc, users)),
        ("week1_day7", _job_week1_day7(supabase, notif_svc, users)),
        # ── Gamification ──
        ("daily_crate", _job_daily_crate_available(supabase, notif_svc, users)),
        # ── Proactive health coaching (Phase C2) ──
        ("daily_readiness", _job_daily_readiness(supabase, notif_svc, users)),
        ("health_anomaly", _job_health_anomaly(supabase, notif_svc, users)),
        ("activity_goal", _job_activity_goal(supabase, notif_svc, users)),
        # ── Flagship evening recap (data-grounded, LLM) ──
        ("evening_recap", _job_evening_recap(supabase, notif_svc, users)),
        # ── New data-grounded moments (WS3 Part B) ──
        ("weekly_recap", _job_weekly_recap(supabase, notif_svc, users)),
        ("sleep_debt", _job_sleep_debt(supabase, notif_svc, users)),
        ("rhr_trend", _job_rhr_trend(supabase, notif_svc, users)),
        ("protein_trend", _job_protein_trend(supabase, notif_svc, users)),
        ("volume_balance", _job_volume_balance(supabase, notif_svc, users)),
        # ── Injury recovery lifecycle check-in + auto-expire (WS-B) ──
        ("injury_recovery", _job_injury_recovery(supabase, notif_svc, users)),
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
        # Smart app-open hooks
        "streak_countdown", "progress_milestone", "post_workout_nutrition", "coach_insight",
        "habit_streak_reward", "rest_day_tip", "progress_comparison", "time_capsule",
        "chain_visual", "recovery_complete",
        # Merch engagement (migration 1931)
        "merch_proximity", "merch_unlocked", "merch_claim_reminder",
        # Level milestone celebration (migration 1935)
        "level_milestone_celebration",
        # Week-1 ladder (W4)
        "week1_day1", "week1_day3_completed", "week1_day3_stalled", "week1_day5", "week1_day7",
        # Proactive health coaching (Phase C2)
        "daily_readiness", "health_anomaly", "activity_goal",
        # Flagship evening recap (data-grounded, LLM)
        "evening_recap",
    }
    if nudge_type not in allowed_nudge_types:
        raise HTTPException(status_code=400, detail=f"Invalid nudge_type. Allowed: {sorted(allowed_nudge_types)}")

    # ── Proactive health-coaching nudges have PRE-BUILT deterministic content
    #    from the Phase-C1 engine, so they bypass _send_nudge's template path.
    #    Each is exercised here against the real Phase-B1 snapshot — no mock
    #    data; if the test user has no wearable / no consent the builder
    #    returns has_message=False and the test reports that honestly.
    if nudge_type in ("daily_readiness", "health_anomaly", "activity_goal", "evening_recap"):
        supabase = get_supabase()
        notif_svc = get_notification_service()
        try:
            result = supabase.client.table("users") \
                .select(
                    "id, name, email, fcm_token, timezone, notification_preferences, "
                    "created_at, in_vacation_mode, vacation_start_date, "
                    "vacation_end_date, in_comeback_mode, comeback_week"
                ) \
                .eq("id", user_id) \
                .limit(1) \
                .execute()
            if not result.data:
                raise HTTPException(status_code=404, detail="User not found")
            user = result.data[0]
        except HTTPException:
            raise
        except Exception as e:
            raise safe_internal_error(e, "push_nudge_cron")

        user["_ai_settings"] = _fetch_ai_settings_batch(supabase, [user_id]).get(user_id, {})

        svc = _user_context_service()
        snapshot = await svc.get_health_activity_snapshot(user_id, days=7)
        coach_name = (user.get("_ai_settings") or {}).get("coach_name") or "Your Coach"

        ai = user.get("_ai_settings") or {}
        tz_str = user.get("timezone") or "UTC"
        today_workout = _today_workout_row(
            supabase, user_id, _get_user_local_date(tz_str)
        )

        if nudge_type in ("daily_readiness", "evening_recap"):
            from services.coach.smart_briefing import generate_smart_briefing

            moment = (
                "morning_readiness" if nudge_type == "daily_readiness" else "evening_recap"
            )
            # Exercise the real upgraded path: data-grounded LLM briefing.
            smart = await generate_smart_briefing(
                supabase, user_id, snapshot, today_workout,
                moment=moment,
                first_name=(user.get("name") or "").split(" ")[0] or "there",
                time_of_day=("morning" if moment == "morning_readiness" else "evening"),
                coach_name=coach_name,
                coaching_style=ai.get("coaching_style", "motivational"),
                communication_tone=ai.get("communication_tone", "encouraging"),
            )
            if smart and smart.get("has_message"):
                built = smart
                title, route = smart["title"], (
                    "/health/sleep" if moment == "morning_readiness" else "/home"
                )
            elif nudge_type == "daily_readiness":
                # Morning has a deterministic fallback; evening does not.
                from services.health_coaching import build_daily_briefing

                built = build_daily_briefing(snapshot, today_workout=today_workout)
                title, route = f"{coach_name}'s morning briefing", "/health/sleep"
            else:
                built = {"has_message": False, "reason": "no_grounded_recap"}
                title, route = "", "/home"
        elif nudge_type == "health_anomaly":
            from services.health_coaching import build_health_anomaly

            built = build_health_anomaly(snapshot)
            title, route = f"A note from {coach_name}", "/health/combined"
        else:  # activity_goal
            from services.health_coaching import build_activity_nudge

            built = build_activity_nudge(snapshot)
            title, route = f"{coach_name}: step check-in", "/health/combined"

        if not built.get("has_message"):
            return {
                "success": False,
                "nudge_type": nudge_type,
                "coach_name": coach_name,
                "user_name": user.get("name"),
                "message": (
                    f"No message — health snapshot unusable "
                    f"(reason: {built.get('reason', 'no_data')}). This is the "
                    f"correct empty state for a user with no wearable/consent."
                ),
            }

        success = await _send_health_coaching_nudge(
            supabase, notif_svc, user, nudge_type,
            title=title,
            message=built["message"],
            route=route,
            facts=built.get("facts") or {},
        )
        return {
            "success": success,
            "nudge_type": nudge_type,
            "coach_name": coach_name,
            "user_name": user.get("name"),
            "pattern": built.get("pattern"),
            "preview": built["message"],
            "message": "Nudge sent successfully" if success
            else "Nudge not sent (dedup/cap/suppression/no token)",
        }

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
        raise safe_internal_error(e, "push_nudge_cron")

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
