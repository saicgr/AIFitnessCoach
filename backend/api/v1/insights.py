"""
User Insights API - AI-generated personalized micro-insights
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from db.supabase_db import get_supabase_db
from services.openai_service import OpenAIService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/insights", tags=["insights"])


# ==================== MODELS ====================

class UserInsight(BaseModel):
    id: Optional[str] = None
    user_id: str
    insight_type: str  # 'performance', 'consistency', 'motivation', 'tip', 'milestone'
    message: str
    emoji: Optional[str] = None
    priority: int = 1
    is_active: bool = True
    generated_at: Optional[str] = None


class WeeklyProgress(BaseModel):
    id: Optional[str] = None
    user_id: str
    week_start_date: str
    planned_workouts: int = 0
    completed_workouts: int = 0
    total_duration_minutes: int = 0
    total_calories_burned: int = 0
    target_workouts: Optional[int] = None
    goals_met: bool = False


class InsightsResponse(BaseModel):
    insights: List[UserInsight]
    weekly_progress: Optional[WeeklyProgress] = None


# ==================== ENDPOINTS ====================

@router.get("/{user_id}")
async def get_user_insights(
    user_id: str,
    limit: int = Query(default=5, ge=1, le=20),
    include_expired: bool = False
):
    """
    Get AI-generated micro-insights for a user.
    Returns active insights and current weekly progress.
    """
    logger.info(f"Fetching insights for user {user_id}")

    try:
        db = get_supabase_db()

        # Get active insights
        query = db.client.table("user_insights").select("*").eq("user_id", user_id).eq("is_active", True)

        if not include_expired:
            # Filter out expired insights
            now = datetime.utcnow().isoformat()
            query = query.or_(f"expires_at.is.null,expires_at.gt.{now}")

        result = query.order("priority", desc=True).order("generated_at", desc=True).limit(limit).execute()
        insights = result.data if result.data else []

        # Get current week's progress
        today = datetime.now().date()
        week_start = today - timedelta(days=today.weekday())  # Monday

        progress_result = db.client.table("weekly_program_progress").select("*").eq(
            "user_id", user_id
        ).eq("week_start_date", week_start.isoformat()).execute()

        weekly_progress = progress_result.data[0] if progress_result.data else None

        return {
            "insights": insights,
            "weekly_progress": weekly_progress
        }

    except Exception as e:
        logger.error(f"Failed to fetch insights: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/generate")
async def generate_insights(user_id: str, force_refresh: bool = False):
    """
    Generate new AI micro-insights for a user based on their workout history.
    Insights are cached and only regenerated if stale or force_refresh=True.
    """
    logger.info(f"Generating insights for user {user_id} (force={force_refresh})")

    try:
        db = get_supabase_db()

        # Check for recent insights (within last 24 hours)
        if not force_refresh:
            yesterday = (datetime.utcnow() - timedelta(hours=24)).isoformat()
            recent = db.client.table("user_insights").select("id").eq(
                "user_id", user_id
            ).gt("generated_at", yesterday).limit(1).execute()

            if recent.data:
                logger.info(f"Recent insights exist for user {user_id}, skipping generation")
                return {"message": "Insights are up to date", "generated": False}

        # Gather user data for insight generation
        user_result = db.client.table("users").select("*").eq("id", user_id).execute()
        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = user_result.data[0]

        # Get workout history (last 30 days)
        thirty_days_ago = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")
        workouts_result = db.client.table("workouts").select("*").eq(
            "user_id", user_id
        ).gte("scheduled_date", thirty_days_ago).execute()

        workouts = workouts_result.data if workouts_result.data else []
        completed_workouts = [w for w in workouts if w.get("is_completed")]

        # Calculate stats
        total_completed = len(completed_workouts)
        total_duration = sum(w.get("duration_minutes", 0) for w in completed_workouts)

        # Calculate streak
        from collections import defaultdict
        completed_dates = set()
        for w in completed_workouts:
            if w.get("scheduled_date"):
                completed_dates.add(w["scheduled_date"][:10])

        today = datetime.now().date()
        streak = 0
        check_date = today
        while check_date.isoformat() in completed_dates or (check_date == today and len(completed_dates) > 0):
            if check_date.isoformat() in completed_dates:
                streak += 1
            check_date -= timedelta(days=1)
            if check_date.isoformat() not in completed_dates:
                break

        # Workout type distribution
        type_counts = defaultdict(int)
        for w in completed_workouts:
            wtype = w.get("type", "general")
            type_counts[wtype] += 1

        # Generate insights using AI
        insights_to_create = []

        # 1. Performance insight
        if total_completed > 0:
            avg_duration = total_duration // total_completed if total_completed > 0 else 0
            insights_to_create.append({
                "user_id": user_id,
                "insight_type": "performance",
                "message": f"You've completed {total_completed} workouts in the last 30 days, averaging {avg_duration} minutes each. Keep it up!",
                "emoji": "💪",
                "priority": 2,
                "context_data": {"total": total_completed, "avg_duration": avg_duration}
            })

        # 2. Streak insight
        if streak > 0:
            streak_message = {
                1: "Day 1 of your streak! Every journey starts with a single step.",
                2: "2 days strong! You're building momentum.",
                3: "3-day streak! You're forming a habit.",
            }.get(streak, f"🔥 {streak}-day streak! You're on fire!")

            insights_to_create.append({
                "user_id": user_id,
                "insight_type": "consistency",
                "message": streak_message,
                "emoji": "🔥" if streak >= 3 else "⭐",
                "priority": 3 if streak >= 3 else 2,
                "context_data": {"streak": streak}
            })

        # 3. Motivational tip based on workout types
        most_common_type = max(type_counts.items(), key=lambda x: x[1])[0] if type_counts else "general"
        tips = {
            "strength": "Remember to progressively increase weights to keep challenging your muscles.",
            "cardio": "Mix up your cardio intensity - try intervals for better results.",
            "hiit": "HIIT is great for burning calories. Make sure you're resting enough between sessions.",
            "flexibility": "Flexibility work improves recovery. Consider adding it after strength days.",
            "full_body": "Full body workouts are efficient! Focus on compound movements.",
        }
        tip = tips.get(most_common_type, "Consistency beats intensity. Keep showing up!")

        insights_to_create.append({
            "user_id": user_id,
            "insight_type": "tip",
            "message": tip,
            "emoji": "💡",
            "priority": 1,
            "context_data": {"favorite_type": most_common_type}
        })

        # 4. Milestone insight (if applicable)
        milestones = [10, 25, 50, 100, 200, 500]
        for milestone in milestones:
            if total_completed >= milestone and total_completed < milestone + 5:
                insights_to_create.append({
                    "user_id": user_id,
                    "insight_type": "milestone",
                    "message": f"🎉 Milestone reached: {milestone} workouts completed! You're crushing it!",
                    "emoji": "🏆",
                    "priority": 5,
                    "context_data": {"milestone": milestone}
                })
                break

        # Deactivate old insights
        db.client.table("user_insights").update({
            "is_active": False
        }).eq("user_id", user_id).execute()

        # Insert new insights
        for insight in insights_to_create:
            insight["generated_at"] = datetime.utcnow().isoformat()
            insight["expires_at"] = (datetime.utcnow() + timedelta(days=7)).isoformat()
            db.client.table("user_insights").insert(insight).execute()

        logger.info(f"Generated {len(insights_to_create)} insights for user {user_id}")

        return {
            "message": f"Generated {len(insights_to_create)} insights",
            "generated": True,
            "insights_count": len(insights_to_create)
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate insights: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/dismiss/{insight_id}")
async def dismiss_insight(user_id: str, insight_id: str):
    """Dismiss (hide) an insight."""
    try:
        db = get_supabase_db()

        result = db.client.table("user_insights").update({
            "is_active": False
        }).eq("id", insight_id).eq("user_id", user_id).execute()

        return {"message": "Insight dismissed"}

    except Exception as e:
        logger.error(f"Failed to dismiss insight: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/weekly-progress")
async def get_weekly_progress(user_id: str, weeks: int = Query(default=4, ge=1, le=12)):
    """Get weekly progress history for a user."""
    try:
        db = get_supabase_db()

        result = db.client.table("weekly_program_progress").select("*").eq(
            "user_id", user_id
        ).order("week_start_date", desc=True).limit(weeks).execute()

        return {"weeks": result.data if result.data else []}

    except Exception as e:
        logger.error(f"Failed to get weekly progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/update-weekly-progress")
async def update_weekly_progress(user_id: str):
    """
    Calculate and update the current week's progress.
    Called after workout completion or on HomeScreen load.
    """
    try:
        db = get_supabase_db()

        # Get current week bounds
        today = datetime.now().date()
        week_start = today - timedelta(days=today.weekday())  # Monday
        week_end = week_start + timedelta(days=6)  # Sunday

        # Get user preferences for target
        user_result = db.client.table("users").select("preferences").eq("id", user_id).execute()
        target_workouts = 4  # Default
        if user_result.data and user_result.data[0].get("preferences"):
            prefs = user_result.data[0]["preferences"]
            if isinstance(prefs, dict):
                target_workouts = prefs.get("days_per_week", 4)

        # Get workouts for this week
        workouts_result = db.client.table("workouts").select("*").eq("user_id", user_id).gte(
            "scheduled_date", week_start.isoformat()
        ).lte("scheduled_date", week_end.isoformat()).execute()

        workouts = workouts_result.data if workouts_result.data else []
        completed = [w for w in workouts if w.get("is_completed")]

        # Calculate stats
        planned_count = len(workouts)
        completed_count = len(completed)
        total_duration = sum(w.get("duration_minutes", 0) for w in completed)
        total_calories = total_duration * 6  # Estimate

        # Workout types breakdown
        type_counts = {}
        for w in completed:
            wtype = w.get("type", "general")
            type_counts[wtype] = type_counts.get(wtype, 0) + 1

        # Upsert progress
        progress_data = {
            "user_id": user_id,
            "week_start_date": week_start.isoformat(),
            "year": today.year,
            "week_number": today.isocalendar()[1],
            "planned_workouts": planned_count,
            "completed_workouts": completed_count,
            "total_duration_minutes": total_duration,
            "total_calories_burned": total_calories,
            "workout_types_completed": type_counts,
            "target_workouts": target_workouts,
            "goals_met": completed_count >= target_workouts,
            "updated_at": datetime.utcnow().isoformat()
        }

        # Check if exists
        existing = db.client.table("weekly_program_progress").select("id").eq(
            "user_id", user_id
        ).eq("week_start_date", week_start.isoformat()).execute()

        if existing.data:
            db.client.table("weekly_program_progress").update(progress_data).eq(
                "id", existing.data[0]["id"]
            ).execute()
        else:
            db.client.table("weekly_program_progress").insert(progress_data).execute()

        return {
            "message": "Weekly progress updated",
            "progress": progress_data
        }

    except Exception as e:
        logger.error(f"Failed to update weekly progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))
