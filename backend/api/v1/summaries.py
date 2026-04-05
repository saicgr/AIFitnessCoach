"""
Weekly Summary API endpoints.

Generates AI-powered weekly workout summaries with:
- Stats and progress tracking
- Personalized AI encouragement
- Tips for the next week
"""
from core.db import get_supabase_db

from fastapi import APIRouter, Depends, HTTPException, Request
from typing import List, Optional
from datetime import datetime, date, timedelta
import json

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.auth import get_current_user
from core.rate_limiter import limiter
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone, get_user_today
from services.gemini_service import GeminiService
from models.schemas import (
    WeeklySummary, WeeklySummaryCreate,
    NotificationPreferences, NotificationPreferencesUpdate
)

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Weekly Summary Endpoints
# ============================================

@router.post("/generate/{user_id}", response_model=WeeklySummary)
@limiter.limit("5/minute")
async def generate_weekly_summary(user_id: str, request: Request, week_start: Optional[str] = None, current_user: dict = Depends(get_current_user)):
    """
    Generate a weekly summary for a user.

    If week_start is not provided, generates for the previous week.
    The summary includes AI-generated content with highlights and encouragement.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Generating weekly summary for user: {user_id}")

    try:
        db = get_supabase_db()
        gemini_service = GeminiService()
        user_tz = resolve_timezone(request, db, user_id)

        # Determine week dates
        if week_start:
            start_date = date.fromisoformat(week_start)
        else:
            # Default to last week (Monday to Sunday)
            today = date.fromisoformat(get_user_today(user_tz))
            days_since_monday = today.weekday()
            last_monday = today - timedelta(days=days_since_monday + 7)
            start_date = last_monday

        end_date = start_date + timedelta(days=6)

        # Check if summary already exists
        existing = db.client.table("weekly_summaries").select("*").eq(
            "user_id", user_id
        ).eq("week_start", str(start_date)).execute()

        if existing.data:
            # Return existing summary
            ws = existing.data[0]
            return _build_weekly_summary_response(ws)

        # Gather stats for the week
        stats = await _gather_week_stats(db, user_id, start_date, end_date)

        # Get user info for personalization
        user = db.get_user(user_id)
        user_name = user.get("name", "there") if user else "there"

        # Generate AI content
        ai_content = await _generate_ai_summary(
            gemini_service, user_name, stats, start_date, end_date
        )

        # Create the summary record
        summary_data = {
            "user_id": user_id,
            "week_start": str(start_date),
            "week_end": str(end_date),
            "workouts_completed": stats["workouts_completed"],
            "workouts_scheduled": stats["workouts_scheduled"],
            "total_exercises": stats["total_exercises"],
            "total_sets": stats["total_sets"],
            "total_time_minutes": stats["total_time_minutes"],
            "calories_burned_estimate": stats["calories_burned_estimate"],
            "current_streak": stats["current_streak"],
            "streak_status": stats["streak_status"],
            "prs_achieved": stats["prs_achieved"],
            "pr_details": json.dumps(stats["pr_details"]) if stats["pr_details"] else None,
            "ai_summary": ai_content["summary"],
            "ai_highlights": json.dumps(ai_content["highlights"]),
            "ai_encouragement": ai_content["encouragement"],
            "ai_next_week_tips": json.dumps(ai_content["next_week_tips"]),
            "ai_generated_at": datetime.utcnow().isoformat()
        }

        result = db.client.table("weekly_summaries").upsert(
            summary_data, on_conflict="user_id,week_start"
        ).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create weekly summary")

        return _build_weekly_summary_response(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate weekly summary: {e}")
        raise safe_internal_error(e, "generate_weekly_summary")


@router.get("/user/{user_id}", response_model=List[WeeklySummary])
@limiter.limit("5/minute")
async def get_user_summaries(user_id: str, request: Request, limit: int = 12, current_user: dict = Depends(get_current_user)):
    """Get weekly summaries for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting summaries for user: {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("weekly_summaries").select("*").eq(
            "user_id", user_id
        ).order("week_start", desc=True).limit(limit).execute()

        return [_build_weekly_summary_response(ws) for ws in result.data]

    except Exception as e:
        logger.error(f"Failed to get user summaries: {e}")
        raise safe_internal_error(e, "get_user_summaries")


@router.get("/user/{user_id}/latest", response_model=Optional[WeeklySummary])
async def get_latest_summary(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get the most recent weekly summary for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting latest summary for user: {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("weekly_summaries").select("*").eq(
            "user_id", user_id
        ).order("week_start", desc=True).limit(1).execute()

        if result.data:
            return _build_weekly_summary_response(result.data[0])
        return None

    except Exception as e:
        logger.error(f"Failed to get latest summary: {e}")
        raise safe_internal_error(e, "get_latest_summary")


# ============================================
# Notification Preferences Endpoints
# ============================================

@router.get("/preferences/{user_id}", response_model=NotificationPreferences)
async def get_notification_preferences(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get notification preferences for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting notification preferences for user: {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("notification_preferences").select("*").eq(
            "user_id", user_id
        ).execute()

        if result.data:
            np = result.data[0]
            return NotificationPreferences(
                id=str(np["id"]),
                user_id=np["user_id"],
                weekly_summary_enabled=np.get("weekly_summary_enabled", True),
                weekly_summary_day=np.get("weekly_summary_day", "sunday"),
                weekly_summary_time=np.get("weekly_summary_time", "09:00"),
                email_notifications_enabled=np.get("email_notifications_enabled", True),
                email_workout_reminders=np.get("email_workout_reminders", True),
                email_achievement_alerts=np.get("email_achievement_alerts", True),
                email_weekly_summary=np.get("email_weekly_summary", True),
                email_motivation_messages=np.get("email_motivation_messages", False),
                push_notifications_enabled=np.get("push_notifications_enabled", False),
                push_workout_reminders=np.get("push_workout_reminders", True),
                push_achievement_alerts=np.get("push_achievement_alerts", True),
                push_weekly_summary=np.get("push_weekly_summary", False),
                push_hydration_reminders=np.get("push_hydration_reminders", False),
                quiet_hours_start=np.get("quiet_hours_start", "22:00"),
                quiet_hours_end=np.get("quiet_hours_end", "07:00"),
                timezone=np.get("timezone", "America/New_York")
            )

        # Return defaults if no preferences exist
        return NotificationPreferences(user_id=user_id)

    except Exception as e:
        logger.error(f"Failed to get notification preferences: {e}")
        raise safe_internal_error(e, "get_notification_preferences")


@router.put("/preferences/{user_id}", response_model=NotificationPreferences)
async def update_notification_preferences(user_id: str, prefs: NotificationPreferencesUpdate, current_user: dict = Depends(get_current_user)):
    """Update notification preferences for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating notification preferences for user: {user_id}")

    try:
        db = get_supabase_db()

        # Build update dict (only non-None values)
        update_data = {k: v for k, v in prefs.dict().items() if v is not None}
        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing = db.client.table("notification_preferences").select("id").eq(
            "user_id", user_id
        ).execute()

        if existing.data:
            result = db.client.table("notification_preferences").update(
                update_data
            ).eq("user_id", user_id).execute()
        else:
            update_data["user_id"] = user_id
            result = db.client.table("notification_preferences").insert(
                update_data
            ).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update preferences")

        np = result.data[0]
        return NotificationPreferences(
            id=str(np["id"]),
            user_id=np["user_id"],
            weekly_summary_enabled=np.get("weekly_summary_enabled", True),
            weekly_summary_day=np.get("weekly_summary_day", "sunday"),
            weekly_summary_time=np.get("weekly_summary_time", "09:00"),
            email_notifications_enabled=np.get("email_notifications_enabled", True),
            email_workout_reminders=np.get("email_workout_reminders", True),
            email_achievement_alerts=np.get("email_achievement_alerts", True),
            email_weekly_summary=np.get("email_weekly_summary", True),
            email_motivation_messages=np.get("email_motivation_messages", False),
            push_notifications_enabled=np.get("push_notifications_enabled", False),
            push_workout_reminders=np.get("push_workout_reminders", True),
            push_achievement_alerts=np.get("push_achievement_alerts", True),
            push_weekly_summary=np.get("push_weekly_summary", False),
            push_hydration_reminders=np.get("push_hydration_reminders", False),
            quiet_hours_start=np.get("quiet_hours_start", "22:00"),
            quiet_hours_end=np.get("quiet_hours_end", "07:00"),
            timezone=np.get("timezone", "America/New_York")
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update notification preferences: {e}")
        raise safe_internal_error(e, "update_notification_preferences")


# ============================================
# Helper Functions
# ============================================

def _build_weekly_summary_response(ws: dict) -> WeeklySummary:
    """Build WeeklySummary response from database row."""
    # Parse JSON fields
    pr_details = None
    if ws.get("pr_details"):
        try:
            pr_details = json.loads(ws["pr_details"]) if isinstance(ws["pr_details"], str) else ws["pr_details"]
        except Exception as e:
            logger.debug(f"Failed to parse pr_details: {e}")
            pr_details = None

    ai_highlights = None
    if ws.get("ai_highlights"):
        try:
            ai_highlights = json.loads(ws["ai_highlights"]) if isinstance(ws["ai_highlights"], str) else ws["ai_highlights"]
        except Exception as e:
            logger.debug(f"Failed to parse ai_highlights: {e}")
            ai_highlights = None

    ai_next_week_tips = None
    if ws.get("ai_next_week_tips"):
        try:
            ai_next_week_tips = json.loads(ws["ai_next_week_tips"]) if isinstance(ws["ai_next_week_tips"], str) else ws["ai_next_week_tips"]
        except Exception as e:
            logger.debug(f"Failed to parse ai_next_week_tips: {e}")
            ai_next_week_tips = None

    return WeeklySummary(
        id=str(ws["id"]),
        user_id=ws["user_id"],
        week_start=str(ws["week_start"]),
        week_end=str(ws["week_end"]),
        workouts_completed=ws.get("workouts_completed", 0),
        workouts_scheduled=ws.get("workouts_scheduled", 0),
        total_exercises=ws.get("total_exercises", 0),
        total_sets=ws.get("total_sets", 0),
        total_time_minutes=ws.get("total_time_minutes", 0),
        calories_burned_estimate=ws.get("calories_burned_estimate", 0),
        current_streak=ws.get("current_streak", 0),
        streak_status=ws.get("streak_status"),
        prs_achieved=ws.get("prs_achieved", 0),
        pr_details=pr_details,
        ai_summary=ws.get("ai_summary"),
        ai_highlights=ai_highlights,
        ai_encouragement=ws.get("ai_encouragement"),
        ai_next_week_tips=ai_next_week_tips,
        ai_generated_at=ws.get("ai_generated_at"),
        email_sent=ws.get("email_sent", False),
        push_sent=ws.get("push_sent", False),
        created_at=ws.get("created_at") or datetime.utcnow()
    )


async def _gather_week_stats(db, user_id: str, start_date: date, end_date: date) -> dict:
    """Gather workout statistics for a week."""

    # Get workouts for the week
    workouts_result = db.client.table("workouts").select("*").eq(
        "user_id", user_id
    ).gte("scheduled_date", str(start_date)).lte(
        "scheduled_date", str(end_date) + "T23:59:59"
    ).execute()

    workouts = workouts_result.data
    total_scheduled = len(workouts)
    completed = [w for w in workouts if w.get("is_completed")]
    completed_count = len(completed)

    # Calculate totals
    total_exercises = 0
    total_sets = 0
    total_time = 0

    for w in completed:
        total_time += w.get("duration_minutes", 0)
        exercises_json = w.get("exercises_json", "[]")
        try:
            exercises = json.loads(exercises_json) if isinstance(exercises_json, str) else exercises_json
            total_exercises += len(exercises)
            for ex in exercises:
                total_sets += ex.get("sets", 3)
        except Exception as e:
            logger.debug(f"Failed to parse exercises JSON: {e}")

    # Estimate calories: use stored per-workout values when available, MET-based fallback
    calories_estimate = 0
    for w in completed:
        stored_cal = w.get("estimated_calories")
        if stored_cal and stored_cal > 0:
            calories_estimate += stored_cal
        else:
            dur = w.get("estimated_duration_minutes") or w.get("duration_minutes", 0)
            calories_estimate += round(3.5 * 70.0 * (dur / 60.0))

    # Get streak info
    streak_result = db.client.table("user_streaks").select("*").eq(
        "user_id", user_id
    ).eq("streak_type", "workout").execute()

    current_streak = 0
    streak_status = "maintained"
    if streak_result.data:
        streak = streak_result.data[0]
        current_streak = streak.get("current_streak", 0)
        last_activity = streak.get("last_activity_date")
        if last_activity:
            last_date = date.fromisoformat(str(last_activity))
            if last_date < end_date:
                streak_status = "broken"
            elif current_streak > 0:
                streak_status = "growing"

    # Get PRs from the week
    prs_result = db.client.table("personal_records").select("*").eq(
        "user_id", user_id
    ).gte("achieved_at", str(start_date)).lte(
        "achieved_at", str(end_date) + "T23:59:59"
    ).execute()

    prs_achieved = len(prs_result.data)
    pr_details = [
        {
            "exercise_name": pr["exercise_name"],
            "old_value": pr.get("previous_value"),
            "new_value": pr["record_value"],
            "unit": pr["record_unit"]
        }
        for pr in prs_result.data
    ]

    # --- Nutrition adherence ---
    nutrition_adherence_pct = None
    try:
        from services.adherence_tracking_service import get_adherence_tracking_service
        adherence_svc = get_adherence_tracking_service()
        weekly_adherence = await adherence_svc.get_weekly_summary(user_id, str(start_date), str(end_date))
        if weekly_adherence:
            nutrition_adherence_pct = weekly_adherence.get("avg_calorie_adherence") or weekly_adherence.get("overall_adherence_pct")
    except Exception as e:
        logger.debug(f"Failed to get nutrition adherence: {e}")

    # --- Readiness scores ---
    avg_readiness_score = None
    readiness_trend = "stable"
    mood_distribution = {}
    try:
        readiness_result = db.client.table("readiness_scores").select(
            "readiness_score, mood, mood_emoji, measured_at"
        ).eq("user_id", user_id).gte(
            "measured_at", str(start_date)
        ).lte("measured_at", str(end_date) + "T23:59:59").order("measured_at").execute()

        readiness_data = readiness_result.data or []
        if readiness_data:
            scores = [r["readiness_score"] for r in readiness_data if r.get("readiness_score")]
            if scores:
                avg_readiness_score = round(sum(scores) / len(scores))
                # Trend: compare first half vs second half
                mid = len(scores) // 2
                if mid > 0:
                    first_half_avg = sum(scores[:mid]) / mid
                    second_half_avg = sum(scores[mid:]) / len(scores[mid:])
                    if second_half_avg > first_half_avg + 5:
                        readiness_trend = "improving"
                    elif second_half_avg < first_half_avg - 5:
                        readiness_trend = "declining"

            # Mood distribution
            for r in readiness_data:
                mood = r.get("mood_emoji") or r.get("mood") or "unknown"
                mood_distribution[mood] = mood_distribution.get(mood, 0) + 1
    except Exception as e:
        logger.debug(f"Failed to get readiness scores: {e}")

    # --- Body measurement changes ---
    measurement_changes = {}
    try:
        measurements_result = db.client.table("body_measurements").select(
            "weight_kg, body_fat_percent, measured_at"
        ).eq("user_id", user_id).order("measured_at", desc=True).limit(4).execute()

        measurements = measurements_result.data or []
        if len(measurements) >= 2:
            latest = measurements[0]
            previous = measurements[1]
            if latest.get("weight_kg") and previous.get("weight_kg"):
                measurement_changes["weight_change_kg"] = round(latest["weight_kg"] - previous["weight_kg"], 1)
            if latest.get("body_fat_percent") and previous.get("body_fat_percent"):
                measurement_changes["body_fat_change"] = round(latest["body_fat_percent"] - previous["body_fat_percent"], 1)
    except Exception as e:
        logger.debug(f"Failed to get measurement changes: {e}")

    return {
        "workouts_completed": completed_count,
        "workouts_scheduled": total_scheduled,
        "total_exercises": total_exercises,
        "total_sets": total_sets,
        "total_time_minutes": total_time,
        "calories_burned_estimate": calories_estimate,
        "current_streak": current_streak,
        "streak_status": streak_status,
        "prs_achieved": prs_achieved,
        "pr_details": pr_details if pr_details else None,
        "nutrition_adherence_pct": nutrition_adherence_pct,
        "avg_readiness_score": avg_readiness_score,
        "readiness_trend": readiness_trend,
        "measurement_changes": measurement_changes,
        "mood_distribution": mood_distribution,
    }


async def _generate_ai_summary(
    gemini_service, user_name: str, stats: dict, start_date: date, end_date: date,
    period_label: str = "weekly"
) -> dict:
    """Generate AI-powered summary content for any time period."""

    # Build context for AI
    completion_rate = (stats["workouts_completed"] / stats["workouts_scheduled"] * 100) if stats["workouts_scheduled"] > 0 else 0
    period_days = (end_date - start_date).days + 1

    prompt = f"""You are a supportive AI fitness coach generating a {period_label} summary for {user_name}.

Period: {start_date.strftime('%B %d')} - {end_date.strftime('%B %d, %Y')} ({period_days} days)

Stats:
- Workouts completed: {stats['workouts_completed']} / {stats['workouts_scheduled']} ({completion_rate:.0f}%)
- Total exercises: {stats['total_exercises']}
- Total sets: {stats['total_sets']}
- Time spent: {stats['total_time_minutes']} minutes
- Estimated calories burned: {stats['calories_burned_estimate']}
- Current streak: {stats['current_streak']} days
- PRs achieved: {stats['prs_achieved']}
- Nutrition adherence: {f"{stats['nutrition_adherence_pct']:.0f}%" if stats.get('nutrition_adherence_pct') else "Not tracked"}
- Average readiness score: {stats.get('avg_readiness_score') or "Not tracked"}/100
- Readiness trend: {stats.get('readiness_trend', 'stable')}
- Body changes: {json.dumps(stats.get('measurement_changes', {})) if stats.get('measurement_changes') else "No measurements"}
- Mood distribution: {json.dumps(stats.get('mood_distribution', {})) if stats.get('mood_distribution') else "Not tracked"}

Generate a JSON response with:
1. "summary": A 2-3 sentence personalized {period_label} summary covering workouts, nutrition, and recovery
2. "highlights": An array of 2-3 key highlights/accomplishments for this period
3. "encouragement": A motivational message (1-2 sentences)
4. "next_period_tips": An array of 2-3 actionable tips for the next period based on their data

Be warm, encouraging, and specific. Celebrate wins, acknowledge challenges.
Reference their nutrition adherence and readiness data when available.
If they missed workouts, be supportive not critical.
Scale your analysis to the {period_label} timeframe — look for trends and patterns, not just individual events.

Respond ONLY with valid JSON, no markdown."""

    try:
        content = await gemini_service.chat(
            user_message=prompt,
            system_prompt="You are a supportive AI fitness coach. Respond with valid JSON only.",
        )

        # Parse JSON response
        import re
        # Extract JSON if wrapped in code blocks
        json_match = re.search(r'\{[\s\S]*\}', content)
        if json_match:
            ai_response = json.loads(json_match.group())
            return {
                "summary": ai_response.get("summary", "Great job this period!"),
                "highlights": ai_response.get("highlights", ["Stayed consistent"]),
                "encouragement": ai_response.get("encouragement", "Keep up the great work!"),
                "next_week_tips": ai_response.get("next_period_tips") or ai_response.get("next_week_tips", ["Stay hydrated"])
            }

    except Exception as e:
        logger.error(f"Failed to generate AI summary: {e}")

    # Fallback content
    return {
        "summary": f"You completed {stats['workouts_completed']} workouts this week, spending {stats['total_time_minutes']} minutes training. {'Great job hitting your goals!' if completion_rate >= 80 else 'Keep pushing forward!'}",
        "highlights": [
            f"Completed {stats['workouts_completed']} workouts",
            f"Burned approximately {stats['calories_burned_estimate']} calories"
        ] + ([f"Set {stats['prs_achieved']} new personal records!"] if stats['prs_achieved'] > 0 else []),
        "encouragement": "Every workout counts. Keep showing up and the results will follow!",
        "next_week_tips": [
            "Stay consistent with your schedule",
            "Remember to hydrate throughout the day",
            "Get enough sleep for optimal recovery"
        ]
    }


# ============================================
# Filtered Report Endpoint
# ============================================

@router.get("/user/{user_id}/report")
@limiter.limit("10/minute")
async def get_filtered_report(
    user_id: str,
    request: Request,
    start_date: str,
    end_date: str,
    group_by: str = "week",
    muscle_group: Optional[str] = None,
    mood_filter: Optional[str] = None,
    include: str = "all",
    current_user: dict = Depends(get_current_user),
):
    """
    Get aggregated report data for an arbitrary date range.

    Args:
        start_date: YYYY-MM-DD
        end_date: YYYY-MM-DD
        group_by: "day" | "week" | "month"
        muscle_group: Filter by specific muscle group
        mood_filter: Filter days by mood value
        include: Comma-separated sections: "workouts,nutrition,readiness,measurements,muscles" or "all"
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    db = get_supabase_db()
    include_set = set(include.split(",")) if include != "all" else {"workouts", "nutrition", "readiness", "measurements", "muscles"}

    try:
        start = date.fromisoformat(start_date)
        end = date.fromisoformat(end_date)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")

    if (end - start).days > 365:
        raise HTTPException(status_code=400, detail="Maximum date range is 365 days.")

    # Generate date intervals based on group_by
    intervals = []
    current = start
    if group_by == "day":
        while current <= end:
            intervals.append((current, current))
            current += timedelta(days=1)
    elif group_by == "month":
        while current <= end:
            month_end = (current.replace(day=28) + timedelta(days=4)).replace(day=1) - timedelta(days=1)
            month_end = min(month_end, end)
            intervals.append((current, month_end))
            current = month_end + timedelta(days=1)
    else:  # week
        while current <= end:
            week_end = min(current + timedelta(days=6 - current.weekday()), end)
            intervals.append((current, week_end))
            current = week_end + timedelta(days=1)

    # Gather data for each interval
    groups = []
    for interval_start, interval_end in intervals:
        group_data = {
            "period_start": str(interval_start),
            "period_end": str(interval_end),
        }

        if "workouts" in include_set:
            stats = await _gather_week_stats(db, user_id, interval_start, interval_end)
            group_data["workouts"] = {
                "completed": stats["workouts_completed"],
                "scheduled": stats["workouts_scheduled"],
                "exercises": stats["total_exercises"],
                "time_minutes": stats["total_time_minutes"],
                "calories": stats["calories_burned_estimate"],
                "streak": stats["current_streak"],
                "prs": stats["prs_achieved"],
            }
            # Include enhanced data from _gather_week_stats
            if "nutrition" in include_set and stats.get("nutrition_adherence_pct") is not None:
                group_data["nutrition"] = {"adherence_pct": stats["nutrition_adherence_pct"]}
            if "readiness" in include_set and stats.get("avg_readiness_score") is not None:
                group_data["readiness"] = {
                    "avg_score": stats["avg_readiness_score"],
                    "trend": stats["readiness_trend"],
                    "mood_distribution": stats.get("mood_distribution", {}),
                }
            if "measurements" in include_set and stats.get("measurement_changes"):
                group_data["measurements"] = stats["measurement_changes"]
        else:
            # Gather individual sections without full workout stats
            if "nutrition" in include_set:
                try:
                    from services.adherence_tracking_service import get_adherence_tracking_service
                    adherence_svc = get_adherence_tracking_service()
                    weekly_adherence = await adherence_svc.get_weekly_summary(user_id, str(interval_start), str(interval_end))
                    if weekly_adherence:
                        group_data["nutrition"] = {"adherence_pct": weekly_adherence.get("avg_calorie_adherence")}
                except Exception:
                    pass

        # Apply mood filter
        if mood_filter and group_data.get("readiness", {}).get("mood_distribution"):
            mood_dist = group_data["readiness"]["mood_distribution"]
            if mood_filter not in mood_dist:
                continue  # Skip this interval if mood not present

        groups.append(group_data)

    # Compute totals across all groups
    totals = _compute_totals(groups)

    # Compute previous period totals for trend comparison
    previous_totals = None
    try:
        period_duration = (end - start).days
        prev_end = start - timedelta(days=1)
        prev_start = prev_end - timedelta(days=period_duration)
        prev_stats = await _gather_week_stats(db, user_id, prev_start, prev_end)
        previous_totals = {
            "workouts_completed": prev_stats["workouts_completed"],
            "workouts_scheduled": prev_stats["workouts_scheduled"],
            "total_time_minutes": prev_stats["total_time_minutes"],
            "total_calories": prev_stats["calories_burned_estimate"],
            "total_exercises": prev_stats["total_exercises"],
            "max_streak": prev_stats["current_streak"],
            "total_prs": prev_stats["prs_achieved"],
            "avg_nutrition_adherence": prev_stats.get("nutrition_adherence_pct"),
            "avg_readiness": prev_stats.get("avg_readiness_score"),
            "mood_distribution": prev_stats.get("mood_distribution"),
            "weight_change_kg": prev_stats.get("measurement_changes", {}).get("weight_change_kg"),
            "body_fat_change": prev_stats.get("measurement_changes", {}).get("body_fat_change"),
        }
    except Exception as e:
        logger.debug(f"Failed to compute previous period totals: {e}")

    return {
        "user_id": user_id,
        "start_date": start_date,
        "end_date": end_date,
        "group_by": group_by,
        "filters": {
            "muscle_group": muscle_group,
            "mood_filter": mood_filter,
        },
        "groups": groups,
        "totals": totals,
        "previous_totals": previous_totals,
    }


def _compute_totals(groups: list) -> dict:
    """Aggregate totals across all period groups."""
    totals = {
        "workouts_completed": 0,
        "workouts_scheduled": 0,
        "total_time_minutes": 0,
        "total_calories": 0,
        "total_exercises": 0,
        "max_streak": 0,
        "total_prs": 0,
        "avg_nutrition_adherence": None,
        "avg_readiness": None,
        "mood_distribution": {},
        "weight_change_kg": None,
        "body_fat_change": None,
    }

    nutrition_values = []
    readiness_values = []

    for g in groups:
        if "workouts" in g:
            w = g["workouts"]
            totals["workouts_completed"] += w.get("completed", 0)
            totals["workouts_scheduled"] += w.get("scheduled", 0)
            totals["total_time_minutes"] += w.get("time_minutes", 0)
            totals["total_calories"] += w.get("calories", 0)
            totals["total_exercises"] += w.get("exercises", 0)
            totals["max_streak"] = max(totals["max_streak"], w.get("streak", 0))
            totals["total_prs"] += w.get("prs", 0)

        if "nutrition" in g and g["nutrition"].get("adherence_pct") is not None:
            nutrition_values.append(g["nutrition"]["adherence_pct"])

        if "readiness" in g:
            r = g["readiness"]
            if r.get("avg_score") is not None:
                readiness_values.append(r["avg_score"])
            if r.get("mood_distribution"):
                for emoji, count in r["mood_distribution"].items():
                    totals["mood_distribution"][emoji] = totals["mood_distribution"].get(emoji, 0) + count

        if "measurements" in g:
            m = g["measurements"]
            if m.get("weight_change_kg") is not None:
                totals["weight_change_kg"] = (totals["weight_change_kg"] or 0) + m["weight_change_kg"]
            if m.get("body_fat_change") is not None:
                totals["body_fat_change"] = (totals["body_fat_change"] or 0) + m["body_fat_change"]

    if nutrition_values:
        totals["avg_nutrition_adherence"] = round(sum(nutrition_values) / len(nutrition_values), 1)
    if readiness_values:
        totals["avg_readiness"] = round(sum(readiness_values) / len(readiness_values))

    return totals


# ============================================
# On-Demand Insight Generation (any period)
# ============================================

@router.post("/user/{user_id}/generate-insight")
@limiter.limit("5/minute")
async def generate_period_insight(
    user_id: str,
    request: Request,
    start_date: str,
    end_date: str,
    period_label: str = "monthly",
    current_user: dict = Depends(get_current_user),
):
    """
    Generate an AI-powered insight for an arbitrary date range.

    Unlike weekly summaries, these are not persisted — they're generated on-demand.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    try:
        start = date.fromisoformat(start_date)
        end = date.fromisoformat(end_date)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")

    if (end - start).days > 365:
        raise HTTPException(status_code=400, detail="Maximum date range is 365 days.")

    try:
        db = get_supabase_db()
        gemini_service = GeminiService()

        # Get user info for personalization
        user = db.get_user(user_id)
        user_name = user.get("name", "there") if user else "there"

        # Gather stats for the full range
        stats = await _gather_week_stats(db, user_id, start, end)

        # Generate AI content with the period label
        ai_content = await _generate_ai_summary(
            gemini_service, user_name, stats, start, end,
            period_label=period_label,
        )

        return {
            "user_id": user_id,
            "start_date": start_date,
            "end_date": end_date,
            "period_label": period_label,
            "summary": ai_content["summary"],
            "highlights": ai_content["highlights"],
            "encouragement": ai_content["encouragement"],
            "tips": ai_content.get("next_week_tips", []),
            "stats": {
                "workouts_completed": stats["workouts_completed"],
                "workouts_scheduled": stats["workouts_scheduled"],
                "total_exercises": stats["total_exercises"],
                "total_time_minutes": stats["total_time_minutes"],
                "calories_burned_estimate": stats["calories_burned_estimate"],
                "current_streak": stats["current_streak"],
                "prs_achieved": stats["prs_achieved"],
                "nutrition_adherence_pct": stats.get("nutrition_adherence_pct"),
                "avg_readiness_score": stats.get("avg_readiness_score"),
                "readiness_trend": stats.get("readiness_trend"),
                "measurement_changes": stats.get("measurement_changes"),
                "mood_distribution": stats.get("mood_distribution"),
            },
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate period insight: {e}")
        raise safe_internal_error(e, "generate_period_insight")
