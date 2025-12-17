"""
Weekly Summary API endpoints.

Generates AI-powered weekly workout summaries with:
- Stats and progress tracking
- Personalized AI encouragement
- Tips for the next week
"""

from fastapi import APIRouter, HTTPException
from typing import List, Optional
from datetime import datetime, date, timedelta
import json

from core.supabase_db import get_supabase_db
from core.logger import get_logger
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
async def generate_weekly_summary(user_id: str, week_start: Optional[str] = None):
    """
    Generate a weekly summary for a user.

    If week_start is not provided, generates for the previous week.
    The summary includes AI-generated content with highlights and encouragement.
    """
    logger.info(f"Generating weekly summary for user: {user_id}")

    try:
        db = get_supabase_db()
        gemini_service = GeminiService()

        # Determine week dates
        if week_start:
            start_date = date.fromisoformat(week_start)
        else:
            # Default to last week (Monday to Sunday)
            today = date.today()
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

        result = db.client.table("weekly_summaries").insert(summary_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create weekly summary")

        return _build_weekly_summary_response(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate weekly summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}", response_model=List[WeeklySummary])
async def get_user_summaries(user_id: str, limit: int = 12):
    """Get weekly summaries for a user."""
    logger.info(f"Getting summaries for user: {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("weekly_summaries").select("*").eq(
            "user_id", user_id
        ).order("week_start", desc=True).limit(limit).execute()

        return [_build_weekly_summary_response(ws) for ws in result.data]

    except Exception as e:
        logger.error(f"Failed to get user summaries: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/latest", response_model=Optional[WeeklySummary])
async def get_latest_summary(user_id: str):
    """Get the most recent weekly summary for a user."""
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
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Notification Preferences Endpoints
# ============================================

@router.get("/preferences/{user_id}", response_model=NotificationPreferences)
async def get_notification_preferences(user_id: str):
    """Get notification preferences for a user."""
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
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/preferences/{user_id}", response_model=NotificationPreferences)
async def update_notification_preferences(user_id: str, prefs: NotificationPreferencesUpdate):
    """Update notification preferences for a user."""
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
        raise HTTPException(status_code=500, detail=str(e))


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
        except:
            pr_details = None

    ai_highlights = None
    if ws.get("ai_highlights"):
        try:
            ai_highlights = json.loads(ws["ai_highlights"]) if isinstance(ws["ai_highlights"], str) else ws["ai_highlights"]
        except:
            ai_highlights = None

    ai_next_week_tips = None
    if ws.get("ai_next_week_tips"):
        try:
            ai_next_week_tips = json.loads(ws["ai_next_week_tips"]) if isinstance(ws["ai_next_week_tips"], str) else ws["ai_next_week_tips"]
        except:
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
        except:
            pass

    # Estimate calories (rough: 5-8 cal/min for strength training)
    calories_estimate = total_time * 6

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
        "pr_details": pr_details if pr_details else None
    }


async def _generate_ai_summary(
    gemini_service, user_name: str, stats: dict, start_date: date, end_date: date
) -> dict:
    """Generate AI-powered summary content."""

    # Build context for AI
    completion_rate = (stats["workouts_completed"] / stats["workouts_scheduled"] * 100) if stats["workouts_scheduled"] > 0 else 0

    prompt = f"""You are a supportive AI fitness coach generating a weekly summary for {user_name}.

Week: {start_date.strftime('%B %d')} - {end_date.strftime('%B %d, %Y')}

Stats:
- Workouts completed: {stats['workouts_completed']} / {stats['workouts_scheduled']} ({completion_rate:.0f}%)
- Total exercises: {stats['total_exercises']}
- Total sets: {stats['total_sets']}
- Time spent: {stats['total_time_minutes']} minutes
- Estimated calories burned: {stats['calories_burned_estimate']}
- Current streak: {stats['current_streak']} days
- PRs achieved: {stats['prs_achieved']}

Generate a JSON response with:
1. "summary": A 2-3 sentence personalized summary of their week
2. "highlights": An array of 2-3 key highlights/accomplishments
3. "encouragement": A motivational message (1-2 sentences)
4. "next_week_tips": An array of 2-3 tips for next week

Be warm, encouraging, and specific. Celebrate wins, acknowledge challenges.
If they missed workouts, be supportive not critical.

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
                "summary": ai_response.get("summary", "Great job this week!"),
                "highlights": ai_response.get("highlights", ["Stayed consistent"]),
                "encouragement": ai_response.get("encouragement", "Keep up the great work!"),
                "next_week_tips": ai_response.get("next_week_tips", ["Stay hydrated"])
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
