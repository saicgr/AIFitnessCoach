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
from datetime import datetime, timedelta, date
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, Header, HTTPException, Request
from fastapi.responses import JSONResponse

from core.supabase_client import get_supabase
from core.config import get_settings
from core.logger import get_logger
from core.rate_limiter import limiter
from services.email_service import get_email_service

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


# ─── Deduplication ──────────────────────────────────────────────────────────

def _was_recently_sent(supabase, user_id: str, email_type: str, cooldown_days: int = DEFAULT_COOLDOWN_DAYS) -> bool:
    """Return True if this email_type was sent to user_id within cooldown_days."""
    cutoff = (datetime.utcnow() - timedelta(days=cooldown_days)).isoformat()
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
    Called daily at 6 AM UTC by Render Cron Job.
    """
    _verify_cron_secret(request, x_cron_secret)

    supabase = get_supabase()
    email_svc = get_email_service()
    today = date.today()
    is_monday = today.weekday() == 0

    results: Dict[str, int] = {}
    total_sent = 0

    # Run all daily jobs
    jobs = [
        ("streak_at_risk", _job_streak_at_risk(supabase, email_svc)),
        ("day3_activation", _job_day3_activation(supabase, email_svc)),
        ("trial_ending", _job_trial_ending(supabase, email_svc)),
        ("win_back_30", _job_win_back_30(supabase, email_svc)),
        ("14day_upsell", _job_14day_upsell(supabase, email_svc)),
        ("onboarding_incomplete", _job_onboarding_incomplete(supabase, email_svc)),
    ]

    if is_monday:
        jobs.append(("weekly_summary", _job_weekly_summary(supabase, email_svc)))

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
        cutoff_30 = (datetime.utcnow() - timedelta(days=30)).isoformat()
        active_30 = supabase.client.table("workout_logs") \
            .select("user_id") \
            .gte("completed_at", cutoff_30) \
            .execute()
        active_30_ids = list({row["user_id"] for row in (active_30.data or [])})
        if not active_30_ids:
            return 0

        # Get users who DID log in last 3 days (to exclude them)
        cutoff_3 = (datetime.utcnow() - timedelta(days=3)).isoformat()
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
                .select("id, email, name") \
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

                # Compute streak (count consecutive days from most recent log)
                streak = _get_user_streak(supabase, uid)
                if streak < 2:
                    continue  # Only send if they had a real streak going

                # Get next scheduled workout name
                next_workout = _get_next_workout_name(supabase, uid)

                result = await email_svc.send_streak_at_risk(
                    to_email=user["email"],
                    user_name=user.get("name", ""),
                    current_streak=streak,
                    next_workout_name=next_workout,
                )
                if result.get("success"):
                    _log_email_sent(supabase, uid, email_type)
                    sent += 1

    except Exception as e:
        logger.error(f"❌ streak_at_risk job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 streak_at_risk: {sent} emails sent")
    return sent


# ─── Job: Day-3 Activation ──────────────────────────────────────────────────

async def _job_day3_activation(supabase, email_svc) -> int:
    """
    Send activation email to users who signed up 3 days ago
    but have never logged a workout.
    Gate: workout_reminders preference.
    Cooldown: 7 days.
    """
    email_type = "day3_activation"
    sent = 0

    try:
        # Users created exactly 3 days ago (same calendar date)
        target_date = (date.today() - timedelta(days=3)).isoformat()
        users_result = supabase.client.table("users") \
            .select("id, email, name") \
            .gte("created_at", f"{target_date}T00:00:00") \
            .lt("created_at", f"{target_date}T23:59:59") \
            .execute()

        if not users_result.data:
            return 0

        user_ids = [u["id"] for u in users_result.data]

        # Get users who have ANY completed workout
        logs_result = supabase.client.table("workout_logs") \
            .select("user_id") \
            .in_("user_id", user_ids) \
            .execute()
        has_logged = {row["user_id"] for row in (logs_result.data or [])}

        # Email prefs
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
            if _was_recently_sent(supabase, uid, email_type):
                continue

            # Get their first scheduled workout
            workout_name, exercises, goal = _get_first_workout(supabase, uid)

            result = await email_svc.send_day3_activation(
                to_email=user["email"],
                user_name=user.get("name", ""),
                workout_name=workout_name,
                exercises=exercises,
                goal=goal,
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type)
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
        today = date.today()
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
                .select("id, email, name") \
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

                # Count workouts during trial
                trial_start = sub.get("trial_start_date") or (
                    datetime.utcnow() - timedelta(days=14)).isoformat()
                workout_count = _count_workouts_since(supabase, uid, trial_start)
                days_rem = (date.fromisoformat(target_date) - today).days

                trial_end_str = target_date  # already ISO date string

                result = await email_svc.send_trial_ending(
                    to_email=user["email"],
                    user_name=user.get("name", ""),
                    days_remaining=days_rem,
                    tier=sub.get("tier", "premium"),
                    workouts_during_trial=workout_count,
                    trial_end_date=trial_end_str,
                    discount_percent=25,
                )
                if result.get("success"):
                    _log_email_sent(supabase, uid, email_type)
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
        cutoff_start = (datetime.utcnow() - timedelta(days=32)).isoformat()
        cutoff_end = (datetime.utcnow() - timedelta(days=28)).isoformat()

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
            .select("id, email, name") \
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

            workout_count = _count_workouts_since(supabase, uid, "2020-01-01")

            result = await email_svc.send_win_back(
                to_email=user["email"],
                user_name=user.get("name", ""),
                days_since_expiry=30,
                workouts_completed=workout_count,
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
        target_date = (date.today() - timedelta(days=14)).isoformat()
        users_result = supabase.client.table("users") \
            .select("id, email, name") \
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

            workout_count = _count_workouts_since(supabase, uid, "2020-01-01")
            if workout_count < 3:
                continue

            result = await email_svc.send_14day_upsell(
                to_email=user["email"],
                user_name=user.get("name", ""),
                workouts_completed=workout_count,
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
        cutoff_start = (datetime.utcnow() - timedelta(hours=48)).isoformat()
        cutoff_end = (datetime.utcnow() - timedelta(hours=24)).isoformat()

        users_result = supabase.client.table("users") \
            .select("id, email, name") \
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

            result = await email_svc.send_onboarding_incomplete(
                to_email=user["email"],
                user_name=user.get("name", ""),
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
    Gate: weekly_summary preference.
    Cooldown: 7 days.
    """
    email_type = "weekly_summary"
    sent = 0

    try:
        cutoff = (datetime.utcnow() - timedelta(days=7)).isoformat()
        logs_result = supabase.client.table("workout_logs") \
            .select("user_id, completed_at") \
            .gte("completed_at", cutoff) \
            .execute()

        if not logs_result.data:
            return 0

        # Group by user_id
        user_log_counts: Dict[str, int] = {}
        for row in logs_result.data:
            uid = row["user_id"]
            user_log_counts[uid] = user_log_counts.get(uid, 0) + 1

        active_user_ids = list(user_log_counts.keys())
        if not active_user_ids:
            return 0

        users_result = supabase.client.table("users") \
            .select("id, email, name") \
            .in_("id", active_user_ids) \
            .execute()
        users_map = {u["id"]: u for u in (users_result.data or [])}

        prefs_result = supabase.client.table("email_preferences") \
            .select("user_id, weekly_summary") \
            .in_("user_id", active_user_ids) \
            .execute()
        prefs_map = {p["user_id"]: p for p in (prefs_result.data or [])}

        for uid, workout_count in user_log_counts.items():
            user = users_map.get(uid)
            if not user:
                continue
            pref = prefs_map.get(uid, {})
            if pref.get("weekly_summary") is False:
                continue
            if _was_recently_sent(supabase, uid, email_type):
                continue

            result = await email_svc.send_weekly_summary(
                to_email=user["email"],
                user_name=user.get("name", ""),
                completed_workouts=workout_count,
                total_workouts=max(workout_count, 3),  # estimate
                total_volume_kg=0.0,  # simplified
                top_exercises=[],
            )
            if result.get("success"):
                _log_email_sent(supabase, uid, email_type)
                sent += 1

    except Exception as e:
        logger.error(f"❌ weekly_summary job failed: {e}", exc_info=True)
        raise

    logger.info(f"🎯 weekly_summary: {sent} emails sent")
    return sent


# ─── Helpers ────────────────────────────────────────────────────────────────

def _get_user_streak(supabase, user_id: str) -> int:
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
        check_date = date.today()
        while check_date in days_with_workout:
            streak += 1
            check_date -= timedelta(days=1)
        return streak
    except Exception:
        return 0


def _get_next_workout_name(supabase, user_id: str) -> str:
    """Get the name of the user's next scheduled workout."""
    try:
        today = date.today().isoformat()
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


def _get_first_workout(supabase, user_id: str):
    """Get name, exercise list, and goal for user's first upcoming workout."""
    workout_name = "Your First Workout"
    exercises = ["Warm-up", "Main workout", "Cool-down"]
    goal = "fitness"
    try:
        today = date.today().isoformat()
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
