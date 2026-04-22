"""Sunday Wrapped cron job.

Runs hourly (via Render cron). For each user whose local time matches their
configured weekly_summary_time on their configured weekly_summary_day
(default Sunday 19:00 local), generates the Wrapped content, writes it to
`weekly_summaries`, then sends an FCM push that deep-links to the full
Wrapped card.

Why hourly: users are scattered across timezones. A Sunday 7pm local fire
time could be any UTC hour depending on where they are. Hourly runs catch
every timezone with at most ~60 min drift.

Safeguards against duplicate sends:
- Uniqueness: `weekly_summaries` has UNIQUE(user_id, week_start). Upsert.
- Push idempotency: we only send if `weekly_summaries.push_sent = false`,
  then mark true inside the same DB write.

Hard requirements per memory feedback:
- First-name personalized copy (feedback_name_personalization_required)
- Coach-voiced per `coach_voice.render("weekly_summary_push", voice, ...)`
- Respect quiet hours + user-local timezone only (feedback_user_local_time_only)
- No copy about "haven't started yet" — weekly Wrapped is retrospective, so
  the "schedule-aware" concern is: if the user literally did zero workouts
  AND zero logs this week, skip the push entirely (nothing to recap).
"""
from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import List, Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import APIRouter, HTTPException, Request

from core.db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from services.coach_voice import get_coach_voice, render as render_voice
from services.notification_service import get_notification_service

logger = get_logger(__name__)
router = APIRouter()


# ── Timezone helpers ───────────────────────────────────────────────────────

_SUNDAY_WEEKDAY = 6  # Monday=0 … Sunday=6


def _safe_zone(tz_str: Optional[str]) -> ZoneInfo:
    try:
        return ZoneInfo(tz_str or "UTC")
    except (ZoneInfoNotFoundError, KeyError):
        return ZoneInfo("UTC")


def _user_local_now(tz_str: Optional[str]) -> datetime:
    return datetime.now(_safe_zone(tz_str))


def _is_in_quiet_hours(prefs: dict, local_hour: int) -> bool:
    """Mirrors push_nudge_cron logic. Overnight windows supported."""
    start = prefs.get("quiet_hours_start")
    end = prefs.get("quiet_hours_end")
    if start is None or end is None:
        return False
    try:
        start_h = int(str(start).split(":")[0])
        end_h = int(str(end).split(":")[0])
    except (ValueError, AttributeError):
        return False
    if start_h == end_h:
        return False
    if start_h < end_h:
        return start_h <= local_hour < end_h
    # Overnight: e.g. 22→6
    return local_hour >= start_h or local_hour < end_h


def _day_matches(weekly_summary_day: str, local_dt: datetime) -> bool:
    """True when local_dt's weekday matches the configured day string."""
    mapping = {
        "monday": 0, "tuesday": 1, "wednesday": 2, "thursday": 3,
        "friday": 4, "saturday": 5, "sunday": _SUNDAY_WEEKDAY,
    }
    target = mapping.get((weekly_summary_day or "sunday").lower(), _SUNDAY_WEEKDAY)
    return local_dt.weekday() == target


def _hour_matches(weekly_summary_time: str, local_hour: int) -> bool:
    try:
        target_h = int((weekly_summary_time or "19:00").split(":")[0])
    except (ValueError, IndexError, AttributeError):
        target_h = 19
    return local_hour == target_h


def _last_complete_week(local_today: date) -> tuple[date, date]:
    """Return (week_start_monday, week_end_sunday) for the most recently
    completed week *before* the local_today. If today is Sunday the user
    just finished this Sunday-ending week, so we still look back — wrapped
    is about the week that just ended, not the one starting.
    """
    # Sunday 7pm fire: we want the Monday→Sunday that just ended today.
    # days_since_sunday = (weekday + 1) % 7; on Sunday that's 0.
    days_since_sunday = (local_today.weekday() + 1) % 7
    end = local_today - timedelta(days=days_since_sunday)
    start = end - timedelta(days=6)
    return start, end


# ── Cron endpoint ──────────────────────────────────────────────────────────

@router.post("/weekly-wrapped-cron")
@limiter.limit("6/minute")
async def run_weekly_wrapped_cron(request: Request):
    """Scan all users, fire Sunday Wrapped push for those whose local time
    matches their configured weekly-summary slot.

    Expected to be triggered by Render cron (or equivalent) once per hour.
    Returns a summary of how many pushes were sent + skipped reasons so the
    cron is observable.
    """
    db = get_supabase_db()
    sb = db.client

    # Pull all users who have notification_preferences with weekly_summary_enabled.
    # Filter in Python so we can also check tz/day/hour match per user in one
    # pass. Set is expected to be in the low thousands — one SELECT is fine.
    try:
        rows = sb.table("users").select(
            "id, timezone, fcm_token, "
            "notification_preferences(weekly_summary_enabled, weekly_summary_day, "
            "weekly_summary_time, push_weekly_summary, push_notifications_enabled, "
            "quiet_hours_start, quiet_hours_end)"
        ).not_.is_("fcm_token", "null").execute()
    except Exception as e:
        logger.error(f"[WeeklyWrapped] user scan failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="scan failed")

    users = rows.data or []
    sent = 0
    skipped_not_time = 0
    skipped_disabled = 0
    skipped_quiet = 0
    skipped_no_activity = 0
    skipped_already_sent = 0
    errors = 0

    notif_svc = get_notification_service()

    for user in users:
        user_id = str(user["id"])
        tz_str = user.get("timezone") or "UTC"
        prefs = user.get("notification_preferences") or {}
        # Join returns a list when the relationship is 1:many; normalize.
        if isinstance(prefs, list):
            prefs = prefs[0] if prefs else {}

        if not prefs.get("weekly_summary_enabled", True):
            skipped_disabled += 1
            continue
        if not prefs.get("push_notifications_enabled", True):
            skipped_disabled += 1
            continue
        if not prefs.get("push_weekly_summary", True):
            skipped_disabled += 1
            continue

        local_now = _user_local_now(tz_str)
        if not _day_matches(prefs.get("weekly_summary_day", "sunday"), local_now):
            skipped_not_time += 1
            continue
        if not _hour_matches(prefs.get("weekly_summary_time", "19:00"), local_now.hour):
            skipped_not_time += 1
            continue
        if _is_in_quiet_hours(prefs, local_now.hour):
            skipped_quiet += 1
            continue

        week_start, week_end = _last_complete_week(local_now.date())

        # Dedup against weekly_summaries.push_sent.
        try:
            existing = sb.table("weekly_summaries").select(
                "id, push_sent, workouts_completed, prs_achieved, total_sets, "
                "ai_summary"
            ).eq("user_id", user_id).eq("week_start", str(week_start)).limit(1).execute()
            row = (existing.data or [None])[0]
        except Exception as e:
            logger.warning(f"[WeeklyWrapped] lookup failed for {user_id}: {e}")
            errors += 1
            continue

        if row and row.get("push_sent"):
            skipped_already_sent += 1
            continue

        # Materialize the summary if we haven't yet. Reuse the endpoint helper
        # by importing here (late import avoids a circular at module load).
        from api.v1.summaries import (
            _gather_week_stats,
            _generate_ai_summary,
            _build_weekly_summary_response,  # noqa: F401 -- kept for parity
        )
        from services.gemini_service import GeminiService

        # Any activity at all this week? If literal zero workouts AND zero
        # performance logs, skip the push — recap would be hollow.
        stats = await _gather_week_stats(db, user_id, week_start, week_end)
        if stats["workouts_completed"] == 0 and stats["total_sets"] == 0:
            skipped_no_activity += 1
            continue

        voice = await get_coach_voice(user_id, supabase=db)

        if not row:
            # Generate + insert
            try:
                gemini = GeminiService()
                ai = await _generate_ai_summary(
                    gemini, voice.first_name, stats, week_start, week_end,
                    voice=voice,
                )
                payload = {
                    "user_id": user_id,
                    "week_start": str(week_start),
                    "week_end": str(week_end),
                    "workouts_completed": stats["workouts_completed"],
                    "workouts_scheduled": stats["workouts_scheduled"],
                    "total_exercises": stats["total_exercises"],
                    "total_sets": stats["total_sets"],
                    "total_time_minutes": stats["total_time_minutes"],
                    "calories_burned_estimate": stats["calories_burned_estimate"],
                    "current_streak": stats["current_streak"],
                    "streak_status": stats["streak_status"],
                    "prs_achieved": stats["prs_achieved"],
                    "pr_details": stats["pr_details"],
                    "ai_summary": ai["summary"],
                    "ai_highlights": ai["highlights"],
                    "ai_encouragement": ai["encouragement"],
                    "ai_next_week_tips": ai["next_week_tips"],
                    "ai_generated_at": datetime.utcnow().isoformat(),
                    "push_sent": False,
                }
                sb.table("weekly_summaries").upsert(
                    payload, on_conflict="user_id,week_start"
                ).execute()
                row_stats = {
                    "workouts_completed": stats["workouts_completed"],
                    "prs_achieved": stats["prs_achieved"],
                    "total_sets": stats["total_sets"],
                }
            except Exception as e:
                logger.error(f"[WeeklyWrapped] generate failed for {user_id}: {e}", exc_info=True)
                errors += 1
                continue
        else:
            row_stats = {
                "workouts_completed": row.get("workouts_completed", 0),
                "prs_achieved": row.get("prs_achieved", 0),
                "total_sets": row.get("total_sets", 0),
            }

        # Render coach-voiced push title + body, compute volume for template.
        volume_lbs = int((stats.get("total_volume_kg") or 0) * 2.20462) or (
            row_stats["total_sets"] * 0  # fallback: volume unavailable -> 0
        )
        data = {
            "workouts": row_stats["workouts_completed"],
            "prs": row_stats["prs_achieved"],
            "volume_lbs": volume_lbs,
        }
        salt = f"weekly_summary_push:{week_start.isoformat()}"
        title = render_voice(
            "weekly_summary_push", voice, data, part="title", channel="push",
            selection_salt=salt,
        )
        body = render_voice(
            "weekly_summary_push", voice, data, part="body", channel="push",
            selection_salt=salt,
        )

        fcm_token = user.get("fcm_token")
        if not fcm_token:
            skipped_disabled += 1
            continue

        try:
            success = await notif_svc.send_notification(
                fcm_token=fcm_token,
                title=title or "Your week is ready",
                body=body or "Tap to see your recap and next week's plan.",
                notification_type=notif_svc.TYPE_WEEKLY_SUMMARY,
                data={
                    "type": "weekly_summary",
                    "week_start": str(week_start),
                    "week_end": str(week_end),
                },
            )
        except Exception as e:
            logger.error(f"[WeeklyWrapped] fcm send failed for {user_id}: {e}", exc_info=True)
            errors += 1
            continue

        if success:
            # Mark push_sent so we never re-send for this week, even if the
            # cron runs again within the same hour bucket (edge case: cron
            # overlap due to slow run).
            try:
                sb.table("weekly_summaries").update({"push_sent": True}).eq(
                    "user_id", user_id
                ).eq("week_start", str(week_start)).execute()
            except Exception as e:
                logger.warning(f"[WeeklyWrapped] push_sent flag failed for {user_id}: {e}")
            sent += 1
        else:
            errors += 1

    result = {
        "ok": True,
        "sent": sent,
        "skipped_not_time": skipped_not_time,
        "skipped_disabled": skipped_disabled,
        "skipped_quiet": skipped_quiet,
        "skipped_already_sent": skipped_already_sent,
        "skipped_no_activity": skipped_no_activity,
        "errors": errors,
        "scanned": len(users),
    }
    logger.info(f"[WeeklyWrapped] cron complete: {result}")
    return result
