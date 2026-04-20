"""
Email cron job endpoint — secured, daily-triggered lifecycle emails.

POST /api/v1/emails/cron

Security: X-Cron-Secret header (compare against settings.cron_secret using hmac.compare_digest)

Render Cron Job: 0 6 * * *
curl -s -X POST https://aifitnesscoach-zqi3.onrender.com/api/v1/emails/cron \
  -H "X-Cron-Secret: $CRON_SECRET" \
  -H "Content-Type: application/json" -d "{}"
"""
import asyncio
import hmac
from datetime import datetime, timedelta, date, timezone
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, Header, HTTPException, Request
from fastapi.responses import JSONResponse

from core.supabase_client import get_supabase
from core.config import get_settings
from core.logger import get_logger
from core.rate_limiter import limiter
from core.timezone_utils import get_user_today
from services.email_service import get_email_service
from services.email_helpers import first_name, time_band
from services.notification_suppression import should_suppress_notification
from models.email import UserStats, ScheduleState, TimeBand, CoachStyle

logger = get_logger(__name__)
router = APIRouter()

BATCH_SIZE = 50
DEFAULT_COOLDOWN_DAYS = 7
BILLING_COOLDOWN_DAYS = 1


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
        logger.warning("Cron endpoint called with invalid secret")
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


# ─── Suppression cache (vacation + comeback) ────────────────────────────────

# Per-process cache of user suppression state. Cleared lazily via TTL so we
# don't hit the DB 24× per user per cron run. TTL is short enough that a user
# toggling vacation mode sees effect on the next cron run.
_SUPPRESSION_CACHE: Dict[str, Dict[str, Any]] = {}
_SUPPRESSION_CACHE_AT: Optional[datetime] = None
_SUPPRESSION_CACHE_TTL_SECONDS = 300  # 5 minutes


def _get_user_suppression_state(supabase, user_id: str) -> Dict[str, Any]:
    """Fetch vacation/comeback/timezone fields for one user, memoized per cron run.

    Cache is per-process and TTL-bounded. Missing users return {} which the
    suppression helper treats as "no suppression" — safe default.
    """
    global _SUPPRESSION_CACHE, _SUPPRESSION_CACHE_AT

    now = datetime.now(timezone.utc)
    if (
        _SUPPRESSION_CACHE_AT is None
        or (now - _SUPPRESSION_CACHE_AT).total_seconds() > _SUPPRESSION_CACHE_TTL_SECONDS
    ):
        _SUPPRESSION_CACHE = {}
        _SUPPRESSION_CACHE_AT = now

    cached = _SUPPRESSION_CACHE.get(user_id)
    if cached is not None:
        return cached

    try:
        r = supabase.client.table("users") \
            .select(
                "id, timezone, in_vacation_mode, vacation_start_date, vacation_end_date, "
                "in_comeback_mode, comeback_week"
            ) \
            .eq("id", user_id) \
            .limit(1) \
            .execute()
        state = r.data[0] if r.data else {}
    except Exception as e:
        # On lookup failure, fall open (don't block sends). The state is cached
        # as empty so we don't retry on every call this cron run.
        logger.warning(f"⚠️ [Email] suppression state lookup failed for {user_id}: {e}")
        state = {}

    _SUPPRESSION_CACHE[user_id] = state
    return state


def _is_email_suppressed(supabase, user_id: str, email_type: str) -> bool:
    """Return True if vacation/comeback state should block this email.

    The critical-email whitelist (billing, cancel lifecycle, trial_ending) is
    enforced inside `should_suppress_notification` — those types always pass
    through regardless of vacation state.
    """
    state = _get_user_suppression_state(supabase, user_id)
    reason = should_suppress_notification(state, email_type, channel="email")
    if reason:
        logger.debug(f"🔕 [Email] Suppressed {email_type} for {user_id}: {reason}")
        return True
    return False


# ─── Deduplication ──────────────────────────────────────────────────────────

def _was_recently_sent(supabase, user_id: str, email_type: str, cooldown_days: int = DEFAULT_COOLDOWN_DAYS) -> bool:
    """Return True if this email should be skipped for this user.

    "Skipped" combines two reasons into one gate — all ~24 email jobs already
    use this as `if _was_recently_sent(...): continue`, so adding vacation +
    comeback suppression here covers every job with zero callsite changes:

      1. Vacation mode is active (unless email_type is in CRITICAL_EMAIL_TYPES)
      2. User is in comeback mode and email_type is in COMEBACK_SUPPRESSED_EMAIL
      3. This email_type was sent to this user within cooldown_days (dedup)
    """
    # 1 + 2. Global suppression (vacation + comeback). Cached per run.
    if _is_email_suppressed(supabase, user_id, email_type):
        return True

    # 3. Dedup window
    cutoff = (datetime.now(timezone.utc) - timedelta(days=cooldown_days)).isoformat()
    result = supabase.client.table("email_send_log") \
        .select("id") \
        .eq("user_id", user_id) \
        .eq("email_type", email_type) \
        .gte("sent_at", cutoff) \
        .limit(1) \
        .execute()
    return bool(result.data)


def _log_email_sent(supabase, user_id: str, email_type: str, metadata: Dict = None):
    """Record a successfully sent email for deduplication."""
    try:
        supabase.client.table("email_send_log").insert({
            "user_id": user_id,
            "email_type": email_type,
            "metadata": metadata or {}
        }).execute()
    except Exception as e:
        logger.error(f"❌ Failed to log email send: {e}", exc_info=True)


# ─── Main Endpoint ──────────────────────────────────────────────────────────

@router.post("/cron")
@limiter.limit("5/minute")
async def run_email_cron(
    request: Request,
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
):
    """
    Run all scheduled email jobs.

    Intended to be invoked hourly (Render Cron `0 * * * *`). Each job filters
    per-user by time-band in the user's local timezone, so a single hourly run
    reaches every timezone at the right local moment without needing separate
    cron entries per region.
    """
    _verify_cron_secret(request, x_cron_secret)

    supabase = get_supabase()
    email_svc = get_email_service()

    results: Dict[str, int] = {}
    total_sent = 0

    # All jobs are safe to run hourly — each filters to the right time band
    # for the user's local timezone, so users only see messages during their
    # appropriate window (morning/evening/quiet-hours-respected).
    jobs = [
        ("streak_at_risk", _job_streak_at_risk(supabase, email_svc)),
        ("day3_activation", _job_day3_activation(supabase, email_svc)),
        ("trial_ending", _job_trial_ending(supabase, email_svc)),
        ("win_back_30", _job_win_back_30(supabase, email_svc)),
        ("14day_upsell", _job_14day_upsell(supabase, email_svc)),
        ("onboarding_incomplete", _job_onboarding_incomplete(supabase, email_svc)),
        ("weekly_summary", _job_weekly_summary(supabase, email_svc)),
        ("comeback", _job_comeback(supabase, email_svc)),
        ("idle_nudge", _job_idle_nudge(supabase, email_svc)),
        ("one_workout_wonder", _job_one_workout_wonder(supabase, email_svc)),
        ("premium_idle", _job_premium_idle(supabase, email_svc)),
        # Post-cancel ladder — each runs in its own day-bucket job
        ("cancel_grace", _job_cancel_grace(supabase, email_svc)),
        ("cancel_expired", _job_cancel_expired(supabase, email_svc)),
        ("cancel_offer_7d", _job_cancel_offer(supabase, email_svc, days=7, discount=10)),
        ("cancel_offer_14d", _job_cancel_offer(supabase, email_svc, days=14, discount=20)),
        ("cancel_offer_60d", _job_cancel_offer(supabase, email_svc, days=60, discount=30)),
        ("cancel_sunset", _job_cancel_sunset(supabase, email_svc)),
        # Merch milestone engagement (migration 1931)
        ("merch_proximity", _job_merch_proximity_email(supabase, email_svc)),
        ("merch_unlocked", _job_merch_unlocked_email(supabase, email_svc)),
        ("merch_claim_reminder", _job_merch_claim_reminder_email(supabase, email_svc)),
        ("level_milestone_celebration", _job_level_milestone_celebration_email(supabase, email_svc)),
        # Week-1 ladder (W4)
        ("week1_day1", _job_week1_day1_email(supabase, email_svc)),
        ("week1_day3", _job_week1_day3_email(supabase, email_svc)),
        ("week1_day5", _job_week1_day5_email(supabase, email_svc)),
        ("week1_day7", _job_week1_day7_email(supabase, email_svc)),
    ]

    # Run all jobs concurrently
    job_names = [j[0] for j in jobs]
    job_coros = [j[1] for j in jobs]
    counts = await asyncio.gather(*job_coros, return_exceptions=True)

    for name, count in zip(job_names, counts):
        if isinstance(count, Exception):
            logger.error(f"❌ Cron job '{name}' failed: {count}")
            results[name] = 0
        else:
            results[name] = count
            total_sent += count

    logger.info(f"✅ Email cron complete: {total_sent} emails sent — {results}")
    return {"jobs_run": job_names, "results": results, "emails_sent": total_sent}


# ─── Job: Streak At Risk ────────────────────────────────────────────────────

async def _job_streak_at_risk(supabase, email_svc) -> int:
    """
    Send streak-at-risk email to users who haven't logged a workout in 3 days
    but were active in the past 30 days (meaning they have a streak to lose).
    Gate: workout_reminders preference.
    Cooldown: 7 days.
    """
    email_type = "streak_at_risk"
    sent = 0

    try:
        # Get users active in last 30 days
        cutoff_30 = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
        active_30 = supabase.client.table("workout_logs") \
            .select("user_id") \
            .gte("completed_at", cutoff_30) \
            .execute()
        active_30_ids = list({row["user_id"] for row in (active_30.data or [])})
        if not active_30_ids:
            return 0

        # Get users who DID log in last 3 days (to exclude them)
        cutoff_3 = (datetime.now(timezone.utc) - timedelta(days=3)).isoformat()
        active_3 = supabase.client.table("workout_logs") \
            .select("user_id") \
            .gte("completed_at", cutoff_3) \
            .execute()
        active_3_ids = {row["user_id"] for row in (active_3.data or [])}

        # At-risk = active in 30d but NOT active in 3d
        at_risk_ids = [uid for uid in active_30_ids if uid not in active_3_ids]
        if not at_risk_ids:
            return 0

        # Process in batches
        for i in range(0, len(at_risk_ids), BATCH_SIZE):
            batch_ids = at_risk_ids[i:i + BATCH_SIZE]

            # Fetch user data + email prefs
            users_result = supabase.client.table("users") \
                .select("id, email, name, timezone") \
                .in_("id", batch_ids) \
                .execute()

            prefs_result = supabase.client.table("email_preferences") \
                .select("user_id, workout_reminders") \
                .in_("user_id", batch_ids) \
                .execute()
            prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

            for user in (users_result.data or []):
                uid = user["id"]
                pref = prefs_map.get(uid, {})
                if pref.get("workout_reminders") is False:
                    continue
                if _was_recently_sent(supabase, uid, email_type):
                    continue

                # Build full stats (includes streak, last workout, next workout,
                # nutrition, persona, time band — one call, template picks what
                # it needs from the populated UserStats.)
                stats = _get_user_stats(supabase, user)

                # Only send if they had a real streak going — <2 days isn't
                # worth a guilt trip, it's not a streak.
                if stats.current_streak_days < 2:
                    continue

                # Send in the user's evening band (sharp urgency, end of day);
                # hourly cron reaches each user at their local 18-21 window.
                if stats.time_band != TimeBand.EVENING:
                    continue

                result = await email_svc.send_streak_at_risk(
                    to_email=user["email"],
                    first_name_value=first_name(user),
                    stats=stats,
                )
                if result.get("success"):
                    _log_email_sent(supabase, uid, email_type, {
                        "streak": stats.current_streak_days,
                    })
                    sent += 1

    except Exception as e:
        logger.error(f"❌ streak_at_risk job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 streak_at_risk: {sent} emails sent")
    return sent


# ─── Job: Day-3 Activation ──────────────────────────────────────────────────

async def _job_day3_activation(supabase, email_svc) -> int:
    """
    Send the activation email to users whose first scheduled workout is today
    (LAUNCHES_TODAY — anticipatory tone) or overdue with no completions
    (OVERDUE — guilt tone).

    Key change from the old version: we no longer assume "signed up 3 days ago
    and zero workouts == neglectful." Users whose plan is scheduled to start
    today are on plan, not behind. The email copy adapts per schedule state.

    Filter cascade:
      1. Users created in last 14 days (widen from the old 3-day hard filter —
         schedule drift means day-of-plan can be day-3, day-5, or day-10 from signup).
      2. No workout ever logged.
      3. email_preferences.workout_reminders != false.
      4. Cooldown (14 days).
      5. Schedule state ∈ {LAUNCHES_TODAY, OVERDUE} — anything else skipped.
      6. Time band == MORNING (send once, early in their local day).
    """
    email_type = "day3_activation"
    sent = 0

    try:
        # Pool of candidates: signed up in last 14 days (not a strict day-3 bucket).
        cutoff_str = (datetime.now(timezone.utc) - timedelta(days=14)).isoformat()
        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .gte("created_at", cutoff_str) \
            .execute()

        if not users_result.data:
            return 0

        user_ids = [u["id"] for u in users_result.data]

        # Exclude anyone who's ever logged a workout
        logs_result = supabase.client.table("workout_logs") \
            .select("user_id") \
            .in_("user_id", user_ids) \
            .execute()
        has_logged = {row["user_id"] for row in (logs_result.data or [])}

        # Email prefs map
        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, workout_reminders") \
            .in_("user_id", user_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for user in users_result.data:
            uid = user["id"]

            if uid in has_logged:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get("workout_reminders") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type, cooldown_days=14):
                continue

            # Build full stats (drives voice variant, persona, time band, etc.)
            stats = _get_user_stats(supabase, user)

            # Only fire for states where an activation nudge makes sense.
            if stats.schedule_state not in (
                ScheduleState.LAUNCHES_TODAY,
                ScheduleState.OVERDUE,
            ):
                continue

            # Morning-band send window (user-local). Skips everyone outside their
            # 06-11 local window; hourly cron will reach them when they enter it.
            if stats.time_band != TimeBand.MORNING:
                continue

            result = await email_svc.send_day3_activation(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type, {
                    "schedule_state": stats.schedule_state.value,
                    "days_overdue": stats.days_overdue,
                })
                sent += 1

    except Exception as e:
        logger.error(f"❌ day3_activation job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 day3_activation: {sent} emails sent")
    return sent


# ─── Job: Trial Ending ──────────────────────────────────────────────────────

async def _job_trial_ending(supabase, email_svc) -> int:
    """
    Send trial-ending warning to users whose trial expires in exactly 2 or 0 days (Day 5 and Day 7).
    Includes 25% discount offer. Gate: product_updates preference.
    Cooldown: 1 day (so Day 5 and Day 7 both trigger).
    """
    email_type = "trial_ending"
    sent = 0

    try:
        today = date.fromisoformat(get_user_today("UTC"))
        target_dates = [
            (today + timedelta(days=2)).isoformat(),  # Day 5 of trial (2 days left)
            today.isoformat(),                         # Day 7 of trial (expires today)
        ]

        for target_date in target_dates:
            subs_result = supabase.client.table("user_subscriptions") \
                .select("user_id, tier, trial_end_date") \
                .eq("is_trial", True) \
                .eq("status", "trial") \
                .gte("trial_end_date", f"{target_date}T00:00:00") \
                .lt("trial_end_date", f"{target_date}T23:59:59") \
                .execute()

            if not subs_result.data:
                continue

            user_ids = [s["user_id"] for s in subs_result.data]
            users_result = supabase.client.table("users") \
                .select("id, email, name, timezone") \
                .in_("id", user_ids) \
                .execute()
            users_map = {u["id"]: u for u in (users_result.data or [])}

            prefs_result = supabase.client.table("email_preferences") \
                .select("user_id, product_updates") \
                .in_("user_id", user_ids) \
                .execute()
            prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

            for sub in subs_result.data:
                uid = sub["user_id"]
                user = users_map.get(uid)
                if not user:
                    continue
                pref = prefs_map.get(uid, {})
                if pref.get("product_updates") is False:
                    continue
                if _was_recently_sent(supabase, uid, email_type, cooldown_days=1):
                    continue

                stats = _get_user_stats(supabase, user)

                # Fire once per day during morning band for billing urgency.
                if stats.time_band != TimeBand.MORNING:
                    continue

                days_rem = (date.fromisoformat(target_date) - today).days
                trial_end_str = target_date  # ISO date string

                result = await email_svc.send_trial_ending(
                    to_email=user["email"],
                    first_name_value=first_name(user),
                    stats=stats,
                    days_remaining=days_rem,
                    trial_end_date=trial_end_str,
                    discount_percent=25,
                )
                if result.get("success"):
                    _log_email_sent(supabase, uid, email_type, {"days_remaining": days_rem})
                    sent += 1

    except Exception as e:
        logger.error(f"❌ trial_ending job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 trial_ending: {sent} emails sent")
    return sent


# ─── Job: Win-back (30 days post-expiry) ───────────────────────────────────

async def _job_win_back_30(supabase, email_svc) -> int:
    """
    Send win-back email to users who expired ~30 days ago and are still free tier.
    Gate: promotional preference.
    Cooldown: 30 days.
    """
    email_type = "win_back_30"
    sent = 0

    try:
        cutoff_start = (datetime.now(timezone.utc) - timedelta(days=32)).isoformat()
        cutoff_end = (datetime.now(timezone.utc) - timedelta(days=28)).isoformat()

        subs_result = supabase.client.table("user_subscriptions") \
            .select("user_id") \
            .eq("tier", "free") \
            .eq("status", "expired") \
            .gte("updated_at", cutoff_start) \
            .lt("updated_at", cutoff_end) \
            .execute()

        if not subs_result.data:
            return 0

        user_ids = [s["user_id"] for s in subs_result.data]
        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .in_("id", user_ids) \
            .execute()
        users_map = {u["id"]: u for u in (users_result.data or [])}

        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, promotional") \
            .in_("user_id", user_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for sub in subs_result.data:
            uid = sub["user_id"]
            user = users_map.get(uid)
            if not user:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get("promotional") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type, cooldown_days=30):
                continue

            stats = _get_user_stats(supabase, user)

            # Fire once during morning band for the lapsed user's local time.
            if stats.time_band != TimeBand.MORNING:
                continue

            result = await email_svc.send_win_back(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
                days_since_expiry=30,
                discount_percent=25,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type)
                sent += 1

    except Exception as e:
        logger.error(f"❌ win_back_30 job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 win_back_30: {sent} emails sent")
    return sent


# ─── Job: 14-day Free Upsell ────────────────────────────────────────────────

async def _job_14day_upsell(supabase, email_svc) -> int:
    """
    Send upsell email to free-tier users who signed up 14 days ago
    and have completed 3+ workouts.
    Gate: product_updates preference.
    Cooldown: 7 days.
    """
    email_type = "14day_upsell"
    sent = 0

    try:
        target_date = (date.fromisoformat(get_user_today("UTC")) - timedelta(days=14)).isoformat()
        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .gte("created_at", f"{target_date}T00:00:00") \
            .lt("created_at", f"{target_date}T23:59:59") \
            .execute()

        if not users_result.data:
            return 0

        user_ids = [u["id"] for u in users_result.data]

        # Only free-tier users
        subs_result = supabase.client.table("user_subscriptions") \
            .select("user_id, tier") \
            .in_("user_id", user_ids) \
            .eq("tier", "free") \
            .execute()
        free_user_ids = {s["user_id"] for s in (subs_result.data or [])}
        # Users with no subscription row are also free tier
        subbed_ids = {s["user_id"] for s in (subs_result.data or [])}
        all_sub_ids = set()
        all_subs = supabase.client.table("user_subscriptions") \
            .select("user_id") \
            .in_("user_id", user_ids) \
            .execute()
        all_sub_ids = {s["user_id"] for s in (all_subs.data or [])}
        # Free = in free_user_ids OR not in all_sub_ids at all
        eligible_ids = free_user_ids | (set(user_ids) - all_sub_ids)

        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, product_updates") \
            .in_("user_id", user_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}
        users_map = {u["id"]: u for u in users_result.data}

        for uid in eligible_ids:
            user = users_map.get(uid)
            if not user:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get("product_updates") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type):
                continue

            stats = _get_user_stats(supabase, user)

            if stats.workouts_total < 3:
                continue
            if stats.time_band != TimeBand.MORNING:
                continue

            result = await email_svc.send_14day_upsell(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
                free_workouts_remaining=0,  # caller may refine once subscription helpers expose this
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type)
                sent += 1

    except Exception as e:
        logger.error(f"❌ 14day_upsell job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 14day_upsell: {sent} emails sent")
    return sent


# ─── Job: Onboarding Incomplete ──────────────────────────────────────────────

async def _job_onboarding_incomplete(supabase, email_svc) -> int:
    """
    Send reminder to users who created account 24+ hours ago
    but have onboarding_completed = false.
    Gate: workout_reminders preference.
    Cooldown: 7 days.
    """
    email_type = "onboarding_incomplete"
    sent = 0

    try:
        # Users created >24h ago but <48h ago with incomplete onboarding
        cutoff_start = (datetime.now(timezone.utc) - timedelta(hours=48)).isoformat()
        cutoff_end = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()

        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .eq("onboarding_completed", False) \
            .gte("created_at", cutoff_start) \
            .lt("created_at", cutoff_end) \
            .execute()

        if not users_result.data:
            return 0

        user_ids = [u["id"] for u in users_result.data]
        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, workout_reminders") \
            .in_("user_id", user_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for user in users_result.data:
            uid = user["id"]
            pref = prefs_map.get(uid, {})
            if pref.get("workout_reminders") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type):
                continue

            stats = _get_user_stats(supabase, user)

            # Morning / midday bands only — onboarding nudges are time-sensitive
            # but not urgent enough for evening/late.
            if stats.time_band not in (TimeBand.MORNING, TimeBand.MIDDAY):
                continue

            result = await email_svc.send_onboarding_incomplete(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type)
                sent += 1

    except Exception as e:
        logger.error(f"❌ onboarding_incomplete job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 onboarding_incomplete: {sent} emails sent")
    return sent


# ─── Job: Weekly Summary (Mondays only) ─────────────────────────────────────

async def _job_weekly_summary(supabase, email_svc) -> int:
    """
    Send weekly summary to users who completed at least 1 workout in the past 7 days.
    Only sends if it's Monday in the user's timezone.
    Gate: weekly_summary preference.
    Cooldown: 7 days.
    """
    email_type = "weekly_summary"
    sent = 0

    try:
        # Pool: everyone who's opted into weekly summary (we send even to quiet weeks
        # now — the email tells them "your week was empty, coach wants to talk").
        # Restrict via preference + send window (morning band, Mondays).
        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, weekly_summary") \
            .eq("weekly_summary", True) \
            .execute()
        opted_in_ids = [p["user_id"] for p in (prefs_result.data or [])]
        if not opted_in_ids:
            return 0

        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .in_("id", opted_in_ids) \
            .execute()

        for user in (users_result.data or []):
            uid = user["id"]
            user_tz = user.get("timezone") or "UTC"

            # Send only on Monday (user-local) — weekly cadence.
            user_today = date.fromisoformat(get_user_today(user_tz))
            if user_today.weekday() != 0:
                continue

            if _was_recently_sent(supabase, uid, email_type):
                continue

            stats = _get_user_stats(supabase, user)

            # Morning band only (09:00-ish send window).
            if stats.time_band != TimeBand.MORNING:
                continue

            # W5: compute percentile via migration 1939 RPC. Falls back to
            # None on any error so the email still sends without social proof.
            percentile_val: Optional[float] = None
            percentile_tier: Optional[str] = None
            try:
                # Week-start Monday (today's user-local Monday is today since we
                # only send Monday mornings per line 701).
                week_start_str = user_today.isoformat()
                rpc = supabase.client.rpc(
                    "compute_user_percentile",
                    {
                        "p_user_id": uid,
                        "p_week_start": week_start_str,
                        "p_board_type": "xp",
                    },
                ).execute()
                pdata = rpc.data[0] if isinstance(rpc.data, list) and rpc.data else (rpc.data or {})
                if pdata:
                    percentile_val = float(pdata.get("percentile") or 0)
                    percentile_tier = pdata.get("tier")
            except Exception as e:
                logger.warning(f"[W5] compute_user_percentile failed for {uid}: {e}")

            result = await email_svc.send_weekly_summary(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
                percentile=percentile_val,
                percentile_tier=percentile_tier,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type, {
                    "workouts_this_week": stats.workouts_this_week,
                    "meals_this_week": stats.nutrition_days_logged_this_week,
                    "percentile": percentile_val,
                })
                sent += 1

    except Exception as e:
        logger.error(f"❌ weekly_summary job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 weekly_summary: {sent} emails sent")
    return sent


# ─── Job: Comeback Celebration (N3) ─────────────────────────────────────────

async def _job_comeback(supabase, email_svc) -> int:
    """
    Send a comeback email to users who returned after a ≥7-day gap and logged
    a workout today. One-shot per 30-day window so users don't get spammed on
    a flappy pattern.

    Detection: order workout_logs desc, compare last vs second-to-last. If
    last is today in user-local, second-to-last is ≥7 days earlier → comeback.
    """
    email_type = "comeback"
    sent = 0

    try:
        # Broad candidate pool: anyone who logged a workout today (UTC-ish).
        today_cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
        today_logs = supabase.client.table("workout_logs") \
            .select("user_id, completed_at") \
            .gte("completed_at", today_cutoff) \
            .execute()
        if not today_logs.data:
            return 0

        user_ids = list({r["user_id"] for r in today_logs.data})

        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .in_("id", user_ids) \
            .execute()
        users_map = {u["id"]: u for u in (users_result.data or [])}

        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, coach_tips") \
            .in_("user_id", user_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for uid in user_ids:
            user = users_map.get(uid)
            if not user:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get("coach_tips") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type, cooldown_days=30):
                continue

            # Pull two most recent logs to detect gap
            recent = supabase.client.table("workout_logs") \
                .select("completed_at") \
                .eq("user_id", uid) \
                .order("completed_at", desc=True) \
                .limit(2) \
                .execute()
            if not recent.data or len(recent.data) < 2:
                continue
            try:
                latest = datetime.fromisoformat(recent.data[0]["completed_at"].replace("Z", "+00:00"))
                prev = datetime.fromisoformat(recent.data[1]["completed_at"].replace("Z", "+00:00"))
            except Exception:
                continue
            gap_days = (latest - prev).days
            if gap_days < 7:
                continue  # Not a real comeback

            stats = _get_user_stats(supabase, user)

            # Fire in evening band so it's the last message of their return day.
            if stats.time_band != TimeBand.EVENING:
                continue

            result = await email_svc.send_comeback(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
                days_gone=gap_days,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type, {"gap_days": gap_days})
                sent += 1
    except Exception as e:
        logger.error(f"❌ comeback job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 comeback: {sent} emails sent")
    return sent


# ─── Job: Idle Nudge (day 7 / day 14 of silence) ────────────────────────────

async def _job_idle_nudge(supabase, email_svc) -> int:
    """
    Mid-gap nudges for users who've been silent 7 or 14 days. Fills the
    window between streak-at-risk (3 days) and win-back (30 days).

    Fires per-user on the 7th or 14th day since their most recent workout_log.
    Only one send per gap-bucket (7d cooldown), so 14d users don't get a 7d
    email three days later — the job picks the highest applicable tier.
    """
    email_type = "idle_nudge"
    sent = 0

    try:
        # Pool: users with a last log between 6 and 15 days ago. We read the
        # most-recent log per user and bucket client-side.
        cutoff_15 = (datetime.now(timezone.utc) - timedelta(days=15)).isoformat()
        cutoff_6 = (datetime.now(timezone.utc) - timedelta(days=6)).isoformat()

        # Latest-log subquery pattern: pull recent logs, group in Python.
        recent = supabase.client.table("workout_logs") \
            .select("user_id, completed_at") \
            .gte("completed_at", cutoff_15) \
            .order("completed_at", desc=True) \
            .execute()
        if not recent.data:
            return 0

        last_log_per_user: Dict[str, str] = {}
        for row in recent.data:
            uid = row["user_id"]
            if uid not in last_log_per_user:
                last_log_per_user[uid] = row["completed_at"]

        # Filter: last log is older than 6 days (no active users)
        candidates: Dict[str, int] = {}  # uid → days_idle
        for uid, ts in last_log_per_user.items():
            if ts > cutoff_6:
                continue
            try:
                dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            except Exception:
                continue
            days_idle = (datetime.now(timezone.utc) - dt).days
            if days_idle in (7, 14):  # Only fire on day-boundary buckets
                candidates[uid] = days_idle
        if not candidates:
            return 0

        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .in_("id", list(candidates.keys())) \
            .execute()
        users_map = {u["id"]: u for u in (users_result.data or [])}
        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, coach_tips") \
            .in_("user_id", list(candidates.keys())) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for uid, days_idle in candidates.items():
            user = users_map.get(uid)
            if not user:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get("coach_tips") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type, cooldown_days=6):
                continue

            stats = _get_user_stats(supabase, user)
            if stats.time_band != TimeBand.EVENING:
                continue

            result = await email_svc.send_idle_nudge(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
                days_idle=days_idle,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type, {"days_idle": days_idle})
                sent += 1
    except Exception as e:
        logger.error(f"❌ idle_nudge job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 idle_nudge: {sent} emails sent")
    return sent


# ─── Job: One-Workout-Wonder (7d after first and only workout) ──────────────

async def _job_one_workout_wonder(supabase, email_svc) -> int:
    """
    7 days after a user's single lifetime workout, nudge them with a
    one-shot "what stopped you?" email. Cooldown = 365 days (effectively
    one-shot) since this is a permanent state once they log workout #2.
    """
    email_type = "one_workout_wonder"
    sent = 0

    try:
        # Pool: users whose single log was exactly 7 days ago (±1 day window)
        cutoff_8 = (datetime.now(timezone.utc) - timedelta(days=8)).isoformat()
        cutoff_6 = (datetime.now(timezone.utc) - timedelta(days=6)).isoformat()

        # Anyone who has a log in the [8d, 6d] window
        window = supabase.client.table("workout_logs") \
            .select("user_id") \
            .gte("completed_at", cutoff_8) \
            .lt("completed_at", cutoff_6) \
            .execute()
        if not window.data:
            return 0
        candidate_ids = list({r["user_id"] for r in window.data})

        # Require exactly 1 total log per candidate
        total = supabase.client.table("workout_logs") \
            .select("user_id, id") \
            .in_("user_id", candidate_ids) \
            .execute()
        counts: Dict[str, int] = {}
        for r in (total.data or []):
            counts[r["user_id"]] = counts.get(r["user_id"], 0) + 1
        one_only_ids = [uid for uid, c in counts.items() if c == 1]
        if not one_only_ids:
            return 0

        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .in_("id", one_only_ids) \
            .execute()
        users_map = {u["id"]: u for u in (users_result.data or [])}
        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, coach_tips") \
            .in_("user_id", one_only_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for uid in one_only_ids:
            user = users_map.get(uid)
            if not user:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get("coach_tips") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type, cooldown_days=365):
                continue
            stats = _get_user_stats(supabase, user)
            if stats.time_band != TimeBand.MORNING:
                continue

            result = await email_svc.send_one_workout_wonder(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type)
                sent += 1
    except Exception as e:
        logger.error(f"❌ one_workout_wonder job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 one_workout_wonder: {sent} emails sent")
    return sent


# ─── Job: Premium Idle (paid users inactive 14+ days) ───────────────────────

async def _job_premium_idle(supabase, email_svc) -> int:
    """
    Refund-risk mitigation: users on an active Premium plan who haven't
    logged in 14+ days. Gentle nudge to actually use what they're paying for.
    """
    email_type = "premium_idle"
    sent = 0

    try:
        subs_result = supabase.client.table("user_subscriptions") \
            .select("user_id, tier, status") \
            .in_("status", ["active", "trial"]) \
            .neq("tier", "free") \
            .execute()
        if not subs_result.data:
            return 0
        premium_ids = [s["user_id"] for s in subs_result.data]

        cutoff_14 = (datetime.now(timezone.utc) - timedelta(days=14)).isoformat()
        recent = supabase.client.table("workout_logs") \
            .select("user_id") \
            .in_("user_id", premium_ids) \
            .gte("completed_at", cutoff_14) \
            .execute()
        recently_active = {r["user_id"] for r in (recent.data or [])}
        idle_ids = [uid for uid in premium_ids if uid not in recently_active]
        if not idle_ids:
            return 0

        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .in_("id", idle_ids) \
            .execute()
        users_map = {u["id"]: u for u in (users_result.data or [])}
        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, coach_tips") \
            .in_("user_id", idle_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for uid in idle_ids:
            user = users_map.get(uid)
            if not user:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get("coach_tips") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type, cooldown_days=14):
                continue
            stats = _get_user_stats(supabase, user)
            if stats.time_band != TimeBand.MORNING:
                continue

            result = await email_svc.send_premium_idle(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type)
                sent += 1
    except Exception as e:
        logger.error(f"❌ premium_idle job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 premium_idle: {sent} emails sent")
    return sent


# ─── Post-Cancel Ladder Jobs (C1-C7) ────────────────────────────────────────
#
# Each stage is gated by days-since-cancellation from user_subscriptions.
# The schema varies slightly per environment — we read cancel_at_period_end,
# ends_at, and status. Any missing column falls back to "skip this user."

async def _job_cancel_grace(supabase, email_svc) -> int:
    """C1. 1 day after cancel, access still active."""
    email_type = "cancel_grace"
    return await _run_cancel_job(
        supabase, email_svc, email_type, days_since=1, access_active=True,
        send_fn_name="send_grace_period", extra_kwargs={"days_until_expiry": 14},
        band=TimeBand.MORNING, cooldown=30,
    )


async def _job_cancel_expired(supabase, email_svc) -> int:
    """C2. The day access actually ends."""
    return await _run_cancel_job(
        supabase, email_svc, "cancel_expired", days_since=0, access_active=False,
        send_fn_name="send_access_expired", extra_kwargs={},
        band=TimeBand.MORNING, cooldown=60,
    )


def _job_cancel_offer(supabase, email_svc, *, days: int, discount: int):
    """Returns a coroutine — curried by days / discount so we can add multiple
    offer-jobs to the dispatcher table."""
    async def _inner():
        return await _run_cancel_job(
            supabase, email_svc, f"cancel_offer_{days}d", days_since=days,
            access_active=False, send_fn_name="send_post_cancel_offer",
            extra_kwargs={"days_since_expiry": days, "discount_percent": discount},
            band=TimeBand.MORNING, cooldown=7, require_pref="promotional",
        )
    return _inner()


async def _job_cancel_sunset(supabase, email_svc) -> int:
    """C7. 90 days post-expiry — final marketing email."""
    return await _run_cancel_job(
        supabase, email_svc, "cancel_sunset", days_since=90, access_active=False,
        send_fn_name="send_sunset", extra_kwargs={},
        band=TimeBand.MORNING, cooldown=3650,  # ~10 years, effectively one-shot
    )


async def _run_cancel_job(
    supabase, email_svc, email_type: str, *, days_since: int,
    access_active: bool, send_fn_name: str, extra_kwargs: Dict[str, Any],
    band: TimeBand, cooldown: int, require_pref: str = "coach_tips",
) -> int:
    """Shared implementation for C1-C7. Finds users who cancelled the right
    number of days ago and fires the right send_* method."""
    sent = 0
    try:
        # Target window: users where `cancelled_at` is days_since days ago (±1)
        target_start = (datetime.now(timezone.utc) - timedelta(days=days_since + 1)).isoformat()
        target_end = (datetime.now(timezone.utc) - timedelta(days=days_since - 1)).isoformat()

        status_filter = "canceled" if access_active else "expired"
        subs_result = supabase.client.table("user_subscriptions") \
            .select("user_id") \
            .eq("status", status_filter) \
            .gte("updated_at", target_start) \
            .lt("updated_at", target_end) \
            .execute()
        if not subs_result.data:
            return 0
        user_ids = [s["user_id"] for s in subs_result.data]

        users_result = supabase.client.table("users") \
            .select("id, email, name, timezone") \
            .in_("id", user_ids) \
            .execute()
        users_map = {u["id"]: u for u in (users_result.data or [])}

        prefs_result = supabase.client.table("email_preferences") \
            .select(f"user_id, {require_pref}") \
            .in_("user_id", user_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for uid in user_ids:
            user = users_map.get(uid)
            if not user:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get(require_pref) is False:
                continue
            if _was_recently_sent(supabase, uid, email_type, cooldown_days=cooldown):
                continue
            stats = _get_user_stats(supabase, user)
            if stats.time_band != band:
                continue

            send_fn = getattr(email_svc, send_fn_name)
            result = await send_fn(
                to_email=user["email"],
                first_name_value=first_name(user),
                stats=stats,
                **extra_kwargs,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type)
                sent += 1
    except Exception as e:
        logger.error(f"❌ {email_type} job failed: {e}", exc_info=True)

    logger.info(f"🎯 {email_type}: {sent} emails sent")
    return sent


# ─── Helpers ────────────────────────────────────────────────────────────────

def _get_user_streak(supabase, user_id: str, user_tz: str = "UTC") -> int:
    """Compute current workout streak (consecutive calendar days with a log)."""
    try:
        result = supabase.client.table("workout_logs") \
            .select("completed_at") \
            .eq("user_id", user_id) \
            .order("completed_at", desc=True) \
            .limit(60) \
            .execute()
        if not result.data:
            return 0

        days_with_workout = set()
        for row in result.data:
            try:
                dt = datetime.fromisoformat(row["completed_at"].replace("Z", "+00:00"))
                days_with_workout.add(dt.date())
            except Exception:
                pass

        streak = 0
        check_date = date.fromisoformat(get_user_today(user_tz))
        while check_date in days_with_workout:
            streak += 1
            check_date -= timedelta(days=1)
        return streak
    except Exception:
        return 0


def _get_next_workout_name(supabase, user_id: str, user_tz: str = "UTC") -> str:
    """Get the name of the user's next scheduled workout."""
    try:
        today = get_user_today(user_tz)
        result = supabase.client.table("workouts") \
            .select("name") \
            .eq("user_id", user_id) \
            .gte("scheduled_date", today) \
            .order("scheduled_date", desc=False) \
            .limit(1) \
            .execute()
        if result.data:
            return result.data[0].get("name", "Your Next Workout")
    except Exception:
        pass
    return "Your Next Workout"


def _get_first_workout(supabase, user_id: str, user_tz: str = "UTC"):
    """Get name, exercise list, and goal for user's first upcoming workout."""
    workout_name = "Your First Workout"
    exercises = ["Warm-up", "Main workout", "Cool-down"]
    goal = "fitness"
    try:
        today = get_user_today(user_tz)
        result = supabase.client.table("workouts") \
            .select("name, workout_type") \
            .eq("user_id", user_id) \
            .gte("scheduled_date", today) \
            .order("scheduled_date", desc=False) \
            .limit(1) \
            .execute()
        if result.data:
            workout_name = result.data[0].get("name", workout_name)
            goal = result.data[0].get("workout_type", goal).replace("_", " ")
    except Exception:
        pass
    return workout_name, exercises, goal


def _count_workouts_since(supabase, user_id: str, since_date: str) -> int:
    """Count completed workouts since a given date string."""
    try:
        result = supabase.client.table("workout_logs") \
            .select("id") \
            .eq("user_id", user_id) \
            .gte("completed_at", since_date) \
            .execute()
        return len(result.data or [])
    except Exception:
        return 0


# ─── UserStats orchestrator (personalization for every email) ───────────────
#
# The idea: one function fills every field of `UserStats` so templates can
# reference any of workout/nutrition/XP/weight/persona without every job
# re-inventing its own queries. All queries are best-effort — if one fails the
# field stays at its safe default and the email still renders.
#
# Performance: we use sync Supabase client (same as the rest of this file).
# Each job touches one user at a time so this doesn't need to be optimized for
# bulk; hourly cron + per-user call is fine. If bulk becomes a bottleneck,
# swap to `asyncio.gather` + the async client.


def _get_coach_persona(supabase, user_id: str) -> tuple[str, CoachStyle, bool]:
    """Resolve coach persona from `user_ai_settings`.

    Returns (coach_name, coach_style, use_emojis). Falls back to
    ("Your Coach", CoachStyle.BALANCED, True) when the row is missing or
    the query fails — never blocks email sending.

    Mirrors `_fetch_ai_settings_batch` in `push_nudge_cron.py` so the two
    channels read the same persona for a given user.
    """
    try:
        result = supabase.client.table("user_ai_settings") \
            .select("coach_name, coaching_style, use_emojis") \
            .eq("user_id", user_id) \
            .limit(1) \
            .execute()
        if result.data:
            row = result.data[0]
            name = (row.get("coach_name") or "").strip() or "Your Coach"
            raw_style = (row.get("coaching_style") or "balanced").strip().lower()
            # Map any of the known push-system values onto our CoachStyle enum.
            try:
                style = CoachStyle(raw_style)
            except ValueError:
                style = CoachStyle.BALANCED
            use_emojis = bool(row.get("use_emojis", True))
            return (name, style, use_emojis)
    except Exception as e:
        logger.warning(f"[stats] persona lookup failed for {user_id}: {e}")
    return ("Your Coach", CoachStyle.BALANCED, True)


def _schedule_state(
    supabase, user_id: str, user_tz: str = "UTC"
) -> tuple[ScheduleState, Optional[int], Optional[int]]:
    """Classify the user's workout plan schedule relative to today (user-local).

    Returns (state, days_until_first, days_overdue).
    - days_until_first is set when state == LAUNCHES_FUTURE
    - days_overdue is set when state == OVERDUE

    Why this matters: sending "you haven't started yet" when the user's plan
    actually starts today is a critical bug in the old code. Every lifecycle
    email branches on this.
    """
    try:
        today_str = get_user_today(user_tz)
        today_d = date.fromisoformat(today_str)

        # Earliest scheduled workout ever (regardless of completion)
        earliest_res = supabase.client.table("workouts") \
            .select("scheduled_date") \
            .eq("user_id", user_id) \
            .order("scheduled_date", desc=False) \
            .limit(1) \
            .execute()
        if not earliest_res.data:
            return (ScheduleState.NO_PLAN, None, None)

        earliest_str = earliest_res.data[0].get("scheduled_date")
        if not earliest_str:
            return (ScheduleState.NO_PLAN, None, None)
        earliest_d = date.fromisoformat(earliest_str.split("T")[0])

        if earliest_d == today_d:
            return (ScheduleState.LAUNCHES_TODAY, 0, 0)
        if earliest_d > today_d:
            return (ScheduleState.LAUNCHES_FUTURE, (earliest_d - today_d).days, None)

        # Past scheduled date — is there a completion on or after earliest date?
        completions = supabase.client.table("workout_logs") \
            .select("id") \
            .eq("user_id", user_id) \
            .gte("completed_at", f"{earliest_str.split('T')[0]}T00:00:00") \
            .limit(1) \
            .execute()
        if completions.data:
            return (ScheduleState.ON_TRACK, None, None)
        return (ScheduleState.OVERDUE, None, (today_d - earliest_d).days)
    except Exception as e:
        logger.warning(f"[stats] schedule_state failed for {user_id}: {e}")
        return (ScheduleState.NO_PLAN, None, None)


def _get_user_stats(supabase, user: Dict[str, Any]) -> UserStats:
    """Build a fully-populated `UserStats` for the given user row.

    `user` must include at minimum `id` and `email`. Other fields (name,
    timezone) are read with graceful fallbacks. This is the single entry
    point for personalization data — every cron job calls it before invoking
    `send_*`.

    Best-effort: any individual query failure logs a warning and falls back
    to the default so the email can still render.
    """
    user_id = user["id"]
    user_tz = user.get("timezone") or "UTC"

    # Persona
    coach_name, coach_style, use_emojis = _get_coach_persona(supabase, user_id)

    # Schedule state (includes whether user has a plan at all)
    sched_state, days_until, days_overdue = _schedule_state(supabase, user_id, user_tz)

    # Next scheduled workout (name + goal)
    next_name = "Your Next Workout"
    next_goal = "fitness"
    try:
        today_str = get_user_today(user_tz)
        r = supabase.client.table("workouts") \
            .select("name, workout_type") \
            .eq("user_id", user_id) \
            .gte("scheduled_date", today_str) \
            .order("scheduled_date", desc=False) \
            .limit(1) \
            .execute()
        if r.data:
            next_name = r.data[0].get("name") or next_name
            next_goal = (r.data[0].get("workout_type") or next_goal).replace("_", " ")
    except Exception:
        pass

    # Workout counts
    streak = _get_user_streak(supabase, user_id, user_tz)
    workouts_total = 0
    workouts_this_week = 0
    last_name = None
    last_days_ago = None
    try:
        week_cutoff = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
        all_logs = supabase.client.table("workout_logs") \
            .select("id, completed_at, workout_id") \
            .eq("user_id", user_id) \
            .order("completed_at", desc=True) \
            .limit(500) \
            .execute()
        data = all_logs.data or []
        workouts_total = len(data)
        workouts_this_week = sum(
            1 for r in data if (r.get("completed_at") or "") >= week_cutoff
        )
        if data:
            # Last workout name requires a join-ish lookup; single row fetch is fine
            latest = data[0]
            try:
                last_dt = datetime.fromisoformat(
                    latest["completed_at"].replace("Z", "+00:00")
                )
                last_days_ago = (datetime.now(timezone.utc) - last_dt).days
            except Exception:
                pass
            wid = latest.get("workout_id")
            if wid:
                try:
                    wname = supabase.client.table("workouts") \
                        .select("name") \
                        .eq("id", wid) \
                        .limit(1) \
                        .execute()
                    if wname.data:
                        last_name = wname.data[0].get("name")
                except Exception:
                    pass
    except Exception as e:
        logger.warning(f"[stats] workout counts failed for {user_id}: {e}")

    # Nutrition — last 7 days
    nut_days_logged = 0
    nut_avg_cal: Optional[int] = None
    nut_avg_protein: Optional[int] = None
    nut_today = False
    try:
        week_cutoff = (datetime.now(timezone.utc) - timedelta(days=7)).date().isoformat()
        today_str = get_user_today(user_tz)
        nr = supabase.client.table("food_logs") \
            .select("logged_at, total_calories, protein_g") \
            .eq("user_id", user_id) \
            .gte("logged_at", f"{week_cutoff}T00:00:00") \
            .execute()
        rows = nr.data or []
        if rows:
            days = set()
            total_cal = 0
            total_prot = 0
            cal_count = 0
            prot_count = 0
            for r in rows:
                la = r.get("logged_at") or ""
                if la:
                    days.add(la.split("T")[0])
                    if la.startswith(today_str):
                        nut_today = True
                c = r.get("total_calories")
                if c is not None:
                    total_cal += int(c)
                    cal_count += 1
                p = r.get("protein_g")
                if p is not None:
                    total_prot += int(p)
                    prot_count += 1
            nut_days_logged = len(days)
            if cal_count:
                nut_avg_cal = round(total_cal / 7)  # avg across the week (including zero days)
            if prot_count:
                nut_avg_protein = round(total_prot / 7)
    except Exception as e:
        logger.warning(f"[stats] nutrition aggregate failed for {user_id}: {e}")

    # XP — total and level (level calc mirrors xp.py's logic at a coarse grain)
    xp_total = 0
    xp_level = 1
    xp_to_next = 0
    try:
        xr = supabase.client.table("user_xp") \
            .select("total_xp") \
            .eq("user_id", user_id) \
            .limit(1) \
            .execute()
        if xr.data:
            xp_total = int(xr.data[0].get("total_xp") or 0)
            # Level = 1 + floor(sqrt(total_xp / 100)); same shape as gamified level curves.
            # Exact formula may live in backend/api/v1/xp.py — this is a safe approximation
            # for email copy. Replace with a direct helper import if/when one is public.
            import math
            xp_level = 1 + int(math.sqrt(max(xp_total, 0) / 100))
            xp_next_level_threshold = ((xp_level) ** 2) * 100
            xp_to_next = max(0, xp_next_level_threshold - xp_total)
    except Exception as e:
        logger.warning(f"[stats] xp lookup failed for {user_id}: {e}")

    # Achievements — latest unlocked
    latest_ach: Optional[str] = None
    try:
        ar = supabase.client.table("user_achievements") \
            .select("achievement_name, earned_at") \
            .eq("user_id", user_id) \
            .order("earned_at", desc=True) \
            .limit(1) \
            .execute()
        if ar.data:
            latest_ach = ar.data[0].get("achievement_name")
    except Exception:
        # Achievements table may not exist in all environments — silent skip.
        pass

    # Weight — first and most recent
    w_start: Optional[float] = None
    w_curr: Optional[float] = None
    w_delta: Optional[float] = None
    try:
        # Latest
        wr = supabase.client.table("weight_logs") \
            .select("weight_lbs, logged_at") \
            .eq("user_id", user_id) \
            .order("logged_at", desc=True) \
            .limit(1) \
            .execute()
        if wr.data and wr.data[0].get("weight_lbs") is not None:
            w_curr = float(wr.data[0]["weight_lbs"])
        # Earliest
        wr0 = supabase.client.table("weight_logs") \
            .select("weight_lbs, logged_at") \
            .eq("user_id", user_id) \
            .order("logged_at", desc=False) \
            .limit(1) \
            .execute()
        if wr0.data and wr0.data[0].get("weight_lbs") is not None:
            w_start = float(wr0.data[0]["weight_lbs"])
        if w_start is not None and w_curr is not None:
            w_delta = round(w_curr - w_start, 1)
    except Exception:
        # weight_logs may use weight_kg in some envs — skip silently if schema differs.
        pass

    # Time band (user-local, quiet hours default 22→06 until unified prefs ship)
    band = time_band(user_tz)

    return UserStats(
        workouts_total=workouts_total,
        workouts_this_week=workouts_this_week,
        current_streak_days=streak,
        longest_streak_days=streak,  # TODO: compute true longest once tracked
        total_volume_lbs=0,          # TODO: sum weight*reps from set logs (future)
        last_workout_name=last_name,
        last_workout_days_ago=last_days_ago,
        next_workout_name=next_name,
        next_workout_goal=next_goal,
        schedule_state=sched_state,
        days_until_first_workout=days_until,
        days_overdue=days_overdue,
        nutrition_days_logged_this_week=nut_days_logged,
        nutrition_avg_calories_week=nut_avg_cal,
        nutrition_avg_protein_g_week=nut_avg_protein,
        nutrition_logged_today=nut_today,
        xp_total=xp_total,
        xp_level=xp_level,
        xp_to_next_level=xp_to_next,
        latest_achievement=latest_ach,
        weight_start_lbs=w_start,
        weight_current_lbs=w_curr,
        weight_delta_lbs=w_delta,
        coach_name=coach_name,
        coach_style=coach_style,
        use_emojis=use_emojis,
        time_band=band,
        user_tz=user_tz,
        has_any_activity=(workouts_total > 0 or nut_days_logged > 0),
    )


# ─── Week-1 Retention Email Jobs (W4) ───────────────────────────────────────

async def _week1_count_workouts(supabase, user_id: str) -> int:
    """Total completed workouts for a new user (bounded by account age < 7 days)."""
    try:
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


def _days_since_signup(created_at: Any) -> int:
    try:
        if isinstance(created_at, str):
            created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
        else:
            created = created_at
        return (datetime.now(timezone.utc) - created).days
    except Exception:
        return -1


async def _job_week1_email(
    supabase, email_svc, day_target: int,
) -> int:
    """
    Generic week-1 email sender for a specific day offset (1, 3, 5, 7).
    Uses user's morning band (8-10 AM local) for Days 1/3/5, 9 AM for Day 7 recap.
    Dedup via email_send_log with email_type = week1_day{N}.
    """
    day_to_type = {1: "week1_day1", 3: "week1_day3", 5: "week1_day5", 7: "week1_day7"}
    email_type_base = day_to_type.get(day_target)
    if email_type_base is None:
        return 0

    sent = 0
    try:
        # Target users created exactly `day_target` days ago (range: start-of-day window)
        window_start = (datetime.now(timezone.utc) - timedelta(days=day_target + 1)).isoformat()
        window_end = (datetime.now(timezone.utc) - timedelta(days=day_target)).isoformat()

        users_res = (
            supabase.client.table("users")
            .select("id,email,name,timezone,created_at")
            .gte("created_at", window_start)
            .lt("created_at", window_end)
            .execute()
        )
        for user in (users_res.data or []):
            uid = user["id"]
            # Gate: workout_reminders for day 1/3/5, achievement_emails for day 7
            prefs_res = (
                supabase.client.table("email_preferences")
                .select("workout_reminders,achievement_emails")
                .eq("user_id", uid).limit(1).execute()
            )
            pref = (prefs_res.data or [{}])[0]
            if day_target == 7:
                if pref.get("achievement_emails") is False:
                    continue
            else:
                if pref.get("workout_reminders") is False:
                    continue

            count = await _week1_count_workouts(supabase, uid)
            # Day 3 branches into completed vs stalled based on count
            if day_target == 3:
                email_type = "week1_day3_completed" if count >= 1 else "week1_day3_stalled"
            else:
                email_type = email_type_base

            if _was_recently_sent(supabase, uid, email_type, cooldown_days=14):
                continue

            stats = _get_user_stats(supabase, user)

            # Time band check — only send during the user's morning (TimeBand.MORNING)
            # or evening for day 5 specifically (per plan, local 7 PM).
            if day_target == 5:
                if stats.time_band != TimeBand.EVENING:
                    continue
            else:
                if stats.time_band != TimeBand.MORNING:
                    continue

            if day_target == 1:
                result = await email_svc.send_week1_day1(
                    to_email=user["email"], first_name_value=first_name(user), stats=stats,
                )
            elif day_target == 3:
                if count >= 1:
                    result = await email_svc.send_week1_day3_completed(
                        to_email=user["email"], first_name_value=first_name(user),
                        stats=stats, workouts_count=count,
                    )
                else:
                    result = await email_svc.send_week1_day3_stalled(
                        to_email=user["email"], first_name_value=first_name(user), stats=stats,
                    )
            elif day_target == 5:
                result = await email_svc.send_week1_day5(
                    to_email=user["email"], first_name_value=first_name(user),
                    stats=stats, workouts_count=count,
                )
            elif day_target == 7:
                result = await email_svc.send_week1_day7(
                    to_email=user["email"], first_name_value=first_name(user),
                    stats=stats, workouts_count=count,
                )
            else:
                continue

            if result.get("success"):
                _log_email_sent(supabase, uid, email_type, {"count": count, "day": day_target})
                sent += 1
    except Exception as e:
        logger.error(f"❌ week1 day{day_target} email job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 week1_day{day_target}: {sent} emails sent")
    return sent


async def _job_week1_day1_email(supabase, email_svc):
    return await _job_week1_email(supabase, email_svc, 1)


async def _job_week1_day3_email(supabase, email_svc):
    return await _job_week1_email(supabase, email_svc, 3)


async def _job_week1_day5_email(supabase, email_svc):
    return await _job_week1_email(supabase, email_svc, 5)


async def _job_week1_day7_email(supabase, email_svc):
    return await _job_week1_email(supabase, email_svc, 7)


# ─── Merch Milestone Email Jobs (migration 1931) ────────────────────────────

_MERCH_PROXIMITY_LEVELS = {47, 48, 49, 97, 98, 99, 147, 148, 149, 197, 198, 199, 247, 248, 249}
_MERCH_NEXT_FOR_PROXIMITY = {
    47: 50, 48: 50, 49: 50,
    97: 100, 98: 100, 99: 100,
    147: 150, 148: 150, 149: 150,
    197: 200, 198: 200, 199: 200,
    247: 250, 248: 250, 249: 250,
}


def _merch_type_for_level(level: int) -> Optional[str]:
    return {
        50: "sticker_pack", 100: "t_shirt", 150: "hoodie",
        200: "full_merch_kit", 250: "signed_premium_kit",
    }.get(level)


async def _job_merch_proximity_email(supabase, email_svc) -> int:
    """
    Email users who are 1-3 levels away from a merch tier.
    Cooldown: 7 days (don't spam the same user every day for 3 days).
    Gate: email_preferences.achievement_emails (default True).
    """
    email_type = "merch_proximity"
    sent = 0

    try:
        rows = supabase.client.table("user_xp") \
            .select("user_id,current_level") \
            .in_("current_level", list(_MERCH_PROXIMITY_LEVELS)) \
            .execute()
        if not rows.data:
            return 0

        by_user = {r["user_id"]: r["current_level"] for r in rows.data}
        user_ids = list(by_user.keys())

        for i in range(0, len(user_ids), BATCH_SIZE):
            batch = user_ids[i:i + BATCH_SIZE]
            users_result = supabase.client.table("users") \
                .select("id,email,name,timezone") \
                .in_("id", batch).execute()

            prefs_result = supabase.client.table("email_preferences") \
                .select("user_id,merch_emails") \
                .in_("user_id", batch).execute()
            prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

            for user in (users_result.data or []):
                uid = user["id"]
                pref = prefs_map.get(uid, {})
                if pref.get("merch_emails") is False:
                    continue
                if _was_recently_sent(supabase, uid, email_type, cooldown_days=7):
                    continue

                level = by_user.get(uid)
                next_merch = _MERCH_NEXT_FOR_PROXIMITY.get(level)
                if not next_merch:
                    continue
                merch_type = _merch_type_for_level(next_merch)
                if not merch_type:
                    continue

                stats = _get_user_stats(supabase, user)
                if stats.time_band not in (TimeBand.MORNING, TimeBand.EVENING):
                    continue  # only at coherent times

                result = await email_svc.send_merch_proximity(
                    to_email=user["email"],
                    first_name_value=first_name(user),
                    stats=stats,
                    merch_type=merch_type,
                    next_level=next_merch,
                    levels_away=next_merch - level,
                )
                if result.get("success"):
                    _log_email_sent(supabase, uid, email_type, {
                        "current_level": level,
                        "merch_type": merch_type,
                    })
                    sent += 1

    except Exception as e:
        logger.error(f"❌ merch_proximity job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 merch_proximity: {sent} emails sent")
    return sent


async def _job_merch_unlocked_email(supabase, email_svc) -> int:
    """
    Email users whose merch claim was created in the last ~24h and is still pending_address.
    Cooldown: 1 day per claim (use metadata).
    """
    email_type = "merch_unlocked"
    sent = 0

    try:
        cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
        claims = supabase.client.table("merch_claims") \
            .select("id,user_id,merch_type,awarded_at_level,created_at") \
            .eq("status", "pending_address") \
            .gte("created_at", cutoff) \
            .execute()
        if not claims.data:
            return 0

        by_user: Dict[str, Dict[str, Any]] = {}
        for c in claims.data:
            by_user.setdefault(c["user_id"], c)

        user_ids = list(by_user.keys())
        for i in range(0, len(user_ids), BATCH_SIZE):
            batch = user_ids[i:i + BATCH_SIZE]
            users_result = supabase.client.table("users") \
                .select("id,email,name,timezone") \
                .in_("id", batch).execute()
            prefs_result = supabase.client.table("email_preferences") \
                .select("user_id,merch_emails") \
                .in_("user_id", batch).execute()
            prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

            for user in (users_result.data or []):
                uid = user["id"]
                pref = prefs_map.get(uid, {})
                if pref.get("merch_emails") is False:
                    continue
                if _was_recently_sent(supabase, uid, email_type, cooldown_days=1):
                    continue

                claim = by_user[uid]
                stats = _get_user_stats(supabase, user)

                result = await email_svc.send_merch_unlocked(
                    to_email=user["email"],
                    first_name_value=first_name(user),
                    stats=stats,
                    merch_type=claim["merch_type"],
                    awarded_at_level=claim["awarded_at_level"],
                )
                if result.get("success"):
                    _log_email_sent(supabase, uid, email_type, {
                        "claim_id": claim["id"],
                        "merch_type": claim["merch_type"],
                    })
                    sent += 1

    except Exception as e:
        logger.error(f"❌ merch_unlocked job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 merch_unlocked: {sent} emails sent")
    return sent


async def _job_level_milestone_celebration_email(supabase, email_svc) -> int:
    """
    Email users who hit a major XP milestone (L5/10/25/50/75/100/...) in the last 24h.
    Cooldown: 1 day per user. Gate: email_preferences.achievement_emails != false.
    Uses level_up_events (migration 1935) as the source of truth.
    """
    email_type = "level_milestone_celebration"
    sent = 0
    milestone_levels = {5, 10, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250}

    try:
        cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
        events = (
            supabase.client.table("level_up_events")
            .select("user_id,level_reached,rewards_snapshot,merch_type,created_at")
            .eq("is_milestone", True)
            .gte("created_at", cutoff)
            .execute()
        )
        if not events.data:
            return 0

        # Highest-level event per user in the window
        top_by_user: Dict[str, Dict[str, Any]] = {}
        for row in events.data:
            level = row.get("level_reached")
            if level not in milestone_levels:
                continue
            existing = top_by_user.get(row["user_id"])
            if not existing or level > existing["level_reached"]:
                top_by_user[row["user_id"]] = row

        if not top_by_user:
            return 0

        user_ids = list(top_by_user.keys())
        friendly = {
            "streak_shield": "Streak Shield",
            "xp_token_2x": "2× XP Token",
            "fitness_crate": "Fitness Crate",
            "premium_crate": "Premium Crate",
        }

        for i in range(0, len(user_ids), BATCH_SIZE):
            batch = user_ids[i:i + BATCH_SIZE]
            users_result = supabase.client.table("users") \
                .select("id,email,name,timezone").in_("id", batch).execute()
            prefs_result = supabase.client.table("email_preferences") \
                .select("user_id,achievement_emails").in_("user_id", batch).execute()
            prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

            for user in (users_result.data or []):
                uid = user["id"]
                pref = prefs_map.get(uid, {})
                if pref.get("achievement_emails") is False:
                    continue
                if _was_recently_sent(supabase, uid, email_type, cooldown_days=1):
                    continue

                row = top_by_user[uid]
                items = row.get("rewards_snapshot") or []
                parts: List[str] = []
                has_merch = False
                for item in items:
                    if item.get("type") == "merch":
                        has_merch = True
                        continue
                    name = friendly.get(item.get("type"))
                    if name:
                        parts.append(f"{item.get('quantity', 1)}× {name}")
                summary = " + ".join(parts[:4])
                if has_merch:
                    summary = (summary + " + a FREE physical reward!") if summary else "a FREE physical reward!"

                stats = _get_user_stats(supabase, user)

                result = await email_svc.send_level_milestone_celebration(
                    to_email=user["email"],
                    first_name_value=first_name(user),
                    stats=stats,
                    level_reached=row["level_reached"],
                    rewards_summary=summary or "New rewards in your inventory.",
                    has_merch=has_merch,
                )
                if result.get("success"):
                    _log_email_sent(supabase, uid, email_type, {
                        "level": row["level_reached"],
                        "has_merch": has_merch,
                    })
                    sent += 1

    except Exception as e:
        logger.error(f"❌ level_milestone_celebration job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 level_milestone_celebration: {sent} emails sent")
    return sent


async def _job_merch_claim_reminder_email(supabase, email_svc) -> int:
    """
    Email users who have an unaccepted merch claim at D+2 / D+7 / D+14.
    Cooldown: 3 days (prevent double-sends).
    """
    email_type = "merch_claim_reminder"
    sent = 0

    try:
        now = datetime.now(timezone.utc)
        target_days = {2, 7, 14}

        claims = supabase.client.table("merch_claims") \
            .select("id,user_id,merch_type,awarded_at_level,created_at") \
            .eq("status", "pending_address") \
            .execute()
        if not claims.data:
            return 0

        oldest_by_user: Dict[str, Dict[str, Any]] = {}
        for c in claims.data:
            uid = c["user_id"]
            if uid not in oldest_by_user or c["created_at"] < oldest_by_user[uid]["created_at"]:
                oldest_by_user[uid] = c

        # Filter to users whose days_waiting hits a target bucket
        reminders: Dict[str, Dict[str, Any]] = {}
        for uid, claim in oldest_by_user.items():
            try:
                created = datetime.fromisoformat(claim["created_at"].replace("Z", "+00:00"))
            except Exception:
                continue
            days = (now - created).days
            if days in target_days:
                reminders[uid] = {**claim, "days_waiting": days}

        if not reminders:
            return 0

        user_ids = list(reminders.keys())
        for i in range(0, len(user_ids), BATCH_SIZE):
            batch = user_ids[i:i + BATCH_SIZE]
            users_result = supabase.client.table("users") \
                .select("id,email,name,timezone") \
                .in_("id", batch).execute()
            prefs_result = supabase.client.table("email_preferences") \
                .select("user_id,merch_emails") \
                .in_("user_id", batch).execute()
            prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

            for user in (users_result.data or []):
                uid = user["id"]
                pref = prefs_map.get(uid, {})
                if pref.get("merch_emails") is False:
                    continue
                if _was_recently_sent(supabase, uid, email_type, cooldown_days=3):
                    continue

                claim = reminders[uid]
                stats = _get_user_stats(supabase, user)

                result = await email_svc.send_merch_claim_reminder(
                    to_email=user["email"],
                    first_name_value=first_name(user),
                    stats=stats,
                    merch_type=claim["merch_type"],
                    awarded_at_level=claim["awarded_at_level"],
                    days_waiting=claim["days_waiting"],
                )
                if result.get("success"):
                    _log_email_sent(supabase, uid, email_type, {
                        "claim_id": claim["id"],
                        "days_waiting": claim["days_waiting"],
                    })
                    sent += 1

    except Exception as e:
        logger.error(f"❌ merch_claim_reminder job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 merch_claim_reminder: {sent} emails sent")
    return sent

