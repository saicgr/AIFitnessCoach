"""
User Insights API - AI-generated personalized micro-insights

Includes:
- General insights (performance, consistency, milestones)
- Weight insights (weekly weight trend analysis)
- Daily tips (AI-powered coaching tips)
- Habit suggestions (personalized habit recommendations)
"""
from core.db import get_supabase_db

import logging
import json
import hashlib
from datetime import date, datetime, timedelta
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Query, Depends, Request
from pydantic import BaseModel

from core.activity_logger import log_user_activity, log_user_error
from services.gemini_service import gemini_service
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter
from core.timezone_utils import user_today_date, resolve_timezone

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
    request: Request,
    user_id: str,
    limit: int = Query(default=5, ge=1, le=20),
    include_expired: bool = False,
    start_date: Optional[date] = Query(
        default=None, description="Inclusive lower bound on generated_at (YYYY-MM-DD)"
    ),
    end_date: Optional[date] = Query(
        default=None, description="Inclusive upper bound on generated_at (YYYY-MM-DD)"
    ),
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI-generated micro-insights for a user.
    Returns active insights and current weekly progress.

    Optional ``start_date`` / ``end_date`` clamp the ``generated_at`` window —
    either bound may be supplied independently (plan A3).
    """
    logger.info(
        f"Fetching insights for user {user_id} "
        f"(start={start_date}, end={end_date}, limit={limit})"
    )

    try:
        db = get_supabase_db()

        # Get active insights
        query = db.client.table("user_insights").select("*").eq("user_id", user_id).eq("is_active", True)

        if not include_expired:
            # Filter out expired insights
            now = datetime.utcnow().isoformat()
            query = query.or_(f"expires_at.is.null,expires_at.gt.{now}")

        # Apply generated_at bounds BEFORE order/limit so they actually clamp
        # the row set rather than being silently dropped (plan A3).
        if start_date is not None:
            query = query.gte("generated_at", start_date.isoformat())
        if end_date is not None:
            # End-of-day: include the whole end_date
            end_dt = datetime.combine(end_date, datetime.max.time()).isoformat()
            query = query.lte("generated_at", end_dt)

        result = query.order("priority", desc=True).order("generated_at", desc=True).limit(limit).execute()
        insights = result.data if result.data else []

        # Get current week's progress
        today = user_today_date(request, db, user_id)
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
        logger.error(f"Failed to fetch insights: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.post("/{user_id}/generate")
async def generate_insights(
    request: Request,
    user_id: str, force_refresh: bool = False,
    current_user: dict = Depends(get_current_user),
):
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
        today = user_today_date(request, db, user_id)
        thirty_days_ago = (today - timedelta(days=30)).isoformat()
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
        logger.error(f"Failed to generate insights: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.post("/{user_id}/dismiss/{insight_id}")
async def dismiss_insight(
    user_id: str, insight_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Dismiss (hide) an insight."""
    try:
        db = get_supabase_db()

        result = db.client.table("user_insights").update({
            "is_active": False
        }).eq("id", insight_id).eq("user_id", user_id).execute()

        return {"message": "Insight dismissed"}

    except Exception as e:
        logger.error(f"Failed to dismiss insight: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.get("/{user_id}/weekly-progress")
async def get_weekly_progress(
    user_id: str, weeks: int = Query(default=4, ge=1, le=12),
    current_user: dict = Depends(get_current_user),
):
    """Get weekly progress history for a user."""
    try:
        db = get_supabase_db()

        result = db.client.table("weekly_program_progress").select("*").eq(
            "user_id", user_id
        ).order("week_start_date", desc=True).limit(weeks).execute()

        return {"weeks": result.data if result.data else []}

    except Exception as e:
        logger.error(f"Failed to get weekly progress: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.post("/{user_id}/update-weekly-progress")
async def update_weekly_progress(
    request: Request,
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate and update the current week's progress.
    Called after workout completion or on HomeScreen load.
    """
    try:
        db = get_supabase_db()

        # Get current week bounds
        today = user_today_date(request, db, user_id)
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
        logger.error(f"Failed to update weekly progress: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# ==================== AI-POWERED INSIGHTS ====================

WEIGHT_INSIGHT_PROMPT = """You are a supportive fitness coach AI analyzing a user's weight trend.

## Weight Data (Last 7-14 Days):
{weight_data}

## User Profile:
- Primary Goal: {goal}
- Current Weight: {current_weight} lbs
- Target Weight: {target_weight} lbs (if applicable)
- Weekly Change: {weekly_change} lbs ({direction})

## Task:
Write a brief, encouraging insight (2-3 sentences max) about their weight trend. Include:
1. Acknowledge their progress (positive OR realistic for setbacks)
2. One specific, actionable tip
3. Keep it motivational but honest

## Guidelines:
- Be conversational and supportive
- If losing weight on a fat loss goal, celebrate!
- If gaining on a muscle-building goal, that's good too
- If stalling, suggest small adjustments
- NO medical advice
- NO specific calorie numbers unless mentioned in data

Response (2-3 sentences only):"""

DAILY_TIP_PROMPT = """You are an AI fitness coach providing a personalized daily tip.

## User Context:
- Goals: {goals}
- Last Workout Type: {last_workout_type}
- Days Since Last Workout: {days_since_workout}
- Current Streak: {streak_days} days
- Most Trained Muscle Groups: {favorite_muscles}
- Time of Day: {time_of_day}

## Today's Tip Categories (rotate through these):
- Progressive overload techniques
- Recovery and sleep tips
- Nutrition timing
- Mind-muscle connection
- Form reminders
- Motivation and consistency
- Rest day activities

## Task:
Write ONE concise, actionable tip (1-2 sentences) that's relevant to their current situation.

## Guidelines:
- Be specific and actionable
- Match the tip to their goals and recent activity
- Keep it fresh - avoid generic advice
- Include a specific number or action when possible

Tip:"""

HABIT_SUGGESTION_PROMPT = """You are an AI coach suggesting habits for a user on a {goal} journey.

## Current Habits:
{current_habits}

## User Context:
- Goal: {goal}
- Workout Frequency: {workout_frequency} days/week
- Pain Points: {pain_points}

## Available Habit Templates:
- No DoorDash today
- No eating out
- No sugary drinks
- No late-night snacking
- Cook at home
- No alcohol
- Drink 8 glasses water
- 10k steps
- Stretch for 10 minutes
- Sleep by 11pm
- No processed foods
- Meal prep Sunday
- Track all meals
- Take vitamins

## Task:
Suggest 2-3 NEW habits from the templates (or create custom ones) that would help them reach their goal.
Return as JSON array: [{{"name": "habit name", "reason": "brief why"}}]

Response (JSON only):"""


@router.get("/{user_id}/weight-insight")
async def get_weight_insight(
    request: Request,
    user_id: str, force_refresh: bool = False,
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI-generated insight about the user's weight trend.
    Cached for 24 hours unless force_refresh=True.
    """
    logger.info(f"Getting weight insight for user {user_id}")

    try:
        db = get_supabase_db()

        # Check cache first
        cache_key = f"weight_insight_{user_id}"
        if not force_refresh:
            cached = db.client.table("ai_insight_cache").select("*").eq(
                "cache_key", cache_key
            ).gt("expires_at", datetime.utcnow().isoformat()).limit(1).execute()

            if cached.data:
                logger.info(f"Returning cached weight insight for {user_id}")
                return {"insight": cached.data[0]["insight"], "cached": True}

        # Get user profile
        user_result = db.client.table("users").select("*").eq("id", user_id).execute()
        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")
        user = user_result.data[0]

        # Get weight history (last 14 days)
        today = user_today_date(request, db, user_id)
        fourteen_days_ago = (today - timedelta(days=14)).isoformat()
        weight_result = db.client.table("weight_logs").select("*").eq(
            "user_id", user_id
        ).gte("logged_at", fourteen_days_ago).order("logged_at", desc=True).execute()

        weights = weight_result.data if weight_result.data else []

        if len(weights) < 2:
            return {
                "insight": "Log your weight a few more times to see personalized insights about your progress!",
                "cached": False
            }

        # Calculate trend
        current_weight = weights[0].get("weight_lbs", 0)
        oldest_weight = weights[-1].get("weight_lbs", current_weight)
        weekly_change = current_weight - oldest_weight
        direction = "losing" if weekly_change < -0.1 else "gaining" if weekly_change > 0.1 else "maintaining"

        # Format weight data
        weight_data = "\n".join([
            f"- {w.get('logged_at', 'N/A')[:10]}: {w.get('weight_lbs', 0):.1f} lbs"
            for w in weights[:10]
        ])

        # Get user goal
        goals = user.get("goals", [])
        goal = goals[0] if goals else "general fitness"
        target_weight = user.get("preferences", {}).get("target_weight_lbs", "not set")

        # Generate insight
        prompt = WEIGHT_INSIGHT_PROMPT.format(
            weight_data=weight_data,
            goal=goal,
            current_weight=f"{current_weight:.1f}",
            target_weight=target_weight,
            weekly_change=f"{abs(weekly_change):.1f}",
            direction=direction
        )

        response = await gemini_service.chat(user_message=prompt)

        insight = response if response else _fallback_weight_insight(weekly_change, direction)

        # Cache the result
        _cache_insight(db, cache_key, insight, hours=24)

        return {"insight": insight, "cached": False}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get weight insight: {e}", exc_info=True)
        return {
            "insight": _fallback_weight_insight(0, "maintaining"),
            "cached": False,
            "error": str(e)
        }


@router.get("/{user_id}/daily-tip")
@limiter.limit("10/minute")
async def get_daily_tip(
    request: Request,
    user_id: str, force_refresh: bool = False,
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI-generated daily coaching tip.
    Cached for 24 hours unless force_refresh=True.
    """
    logger.info(f"Getting daily tip for user {user_id}")

    try:
        db = get_supabase_db()

        # Check cache first
        today = user_today_date(request, db, user_id)
        today_str = today.isoformat()
        cache_key = f"daily_tip_{user_id}_{today_str}"

        if not force_refresh:
            cached = db.client.table("ai_insight_cache").select("*").eq(
                "cache_key", cache_key
            ).limit(1).execute()

            if cached.data:
                logger.info(f"Returning cached daily tip for {user_id}")
                return {"tip": cached.data[0]["insight"], "cached": True}

        # Get user profile
        user_result = db.client.table("users").select("*").eq("id", user_id).execute()
        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")
        user = user_result.data[0]

        # Get recent workout data
        seven_days_ago = (today - timedelta(days=7)).isoformat()
        workouts_result = db.client.table("workouts").select("*").eq(
            "user_id", user_id
        ).gte("scheduled_date", seven_days_ago).order("scheduled_date", desc=True).execute()

        workouts = workouts_result.data if workouts_result.data else []
        completed = [w for w in workouts if w.get("is_completed")]

        # Calculate context
        last_workout = completed[0] if completed else None
        days_since = 0
        if last_workout:
            last_date = datetime.strptime(last_workout.get("scheduled_date", today_str)[:10], "%Y-%m-%d").date()
            days_since = (today - last_date).days

        # Time of day (in user's timezone)
        from zoneinfo import ZoneInfo
        user_tz = resolve_timezone(request, db, user_id)
        hour = datetime.now(ZoneInfo(user_tz)).hour
        time_of_day = "morning" if hour < 12 else "afternoon" if hour < 17 else "evening"

        # Get streak
        streak = _calculate_streak(workouts, today)

        # Favorite muscles (from workout types)
        muscle_counts: Dict[str, int] = {}
        for w in completed:
            wtype = w.get("type", "general")
            muscle_counts[wtype] = muscle_counts.get(wtype, 0) + 1
        favorite_muscles = ", ".join(sorted(muscle_counts.keys(), key=lambda x: muscle_counts[x], reverse=True)[:3]) or "general"

        # Generate tip
        prompt = DAILY_TIP_PROMPT.format(
            goals=", ".join(user.get("goals", ["general fitness"])),
            last_workout_type=last_workout.get("type", "none") if last_workout else "none",
            days_since_workout=days_since,
            streak_days=streak,
            favorite_muscles=favorite_muscles,
            time_of_day=time_of_day
        )

        response = await gemini_service.chat(user_message=prompt)

        tip = response if response else _fallback_daily_tip(days_since, time_of_day)

        # Cache the result (expires at midnight)
        _cache_insight(db, cache_key, tip, hours=24)

        return {"tip": tip, "cached": False}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get daily tip: {e}", exc_info=True)
        return {
            "tip": _fallback_daily_tip(0, "morning"),
            "cached": False,
            "error": str(e)
        }


@router.get("/{user_id}/habit-suggestions")
@limiter.limit("10/minute")
async def get_habit_suggestions(
    request: Request,
    user_id: str, force_refresh: bool = False,
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI-generated habit suggestions based on user's goals and current habits.
    """
    logger.info(f"Getting habit suggestions for user {user_id}")

    try:
        db = get_supabase_db()

        # Check cache
        cache_key = f"habit_suggestions_{user_id}"
        if not force_refresh:
            cached = db.client.table("ai_insight_cache").select("*").eq(
                "cache_key", cache_key
            ).gt("expires_at", datetime.utcnow().isoformat()).limit(1).execute()

            if cached.data:
                try:
                    suggestions = json.loads(cached.data[0]["insight"])
                    return {"suggestions": suggestions, "cached": True}
                except json.JSONDecodeError as e:
                    logger.debug(f"Failed to parse cached suggestions: {e}")

        # Get user profile
        user_result = db.client.table("users").select("*").eq("id", user_id).execute()
        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")
        user = user_result.data[0]

        # Get current habits
        habits_result = db.client.table("habits").select("name").eq(
            "user_id", user_id
        ).eq("is_active", True).execute()

        current_habits = [h["name"] for h in (habits_result.data or [])]

        # Get workout frequency
        prefs = user.get("preferences", {})
        workout_frequency = prefs.get("days_per_week", 4) if isinstance(prefs, dict) else 4

        # Primary goal
        goals = user.get("goals", [])
        goal = goals[0] if goals else "general fitness"

        # Generate suggestions
        prompt = HABIT_SUGGESTION_PROMPT.format(
            goal=goal,
            current_habits=", ".join(current_habits) if current_habits else "None yet",
            workout_frequency=workout_frequency,
            pain_points="staying consistent, avoiding junk food"  # Could be personalized later
        )

        response = await gemini_service.chat(user_message=prompt)

        # Parse JSON from response
        suggestions = _parse_habit_suggestions(response if response else "[]")

        # Cache
        _cache_insight(db, cache_key, json.dumps(suggestions), hours=168)  # 1 week

        return {"suggestions": suggestions, "cached": False}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get habit suggestions: {e}", exc_info=True)
        return {
            "suggestions": _fallback_habit_suggestions(),
            "cached": False,
            "error": str(e)
        }


# ==================== TREND ANALYSIS (Custom Trends screen) ====================


class TrendAnalysisSeries(BaseModel):
    """One metric series as displayed on the Custom Trends chart."""
    label: str
    unit: str = ""
    is_primary: bool = False
    # Compact [date(YYYY-MM-DD), value] pairs in chronological order.
    points: List[List[Any]] = []


class TrendAnalysisRequest(BaseModel):
    """POST /insights/{user_id}/trend-analysis body — the exact series the
    Custom Trends screen is currently showing, plus the active range and any
    event overlays the user enabled."""
    range_label: str = ""
    series: List[TrendAnalysisSeries] = []
    # Optional event-overlay counts (workouts / fasting / rest days in window).
    events: Dict[str, int] = {}
    # Pairwise Pearson correlations vs the primary, keyed by overlay label.
    correlations: Dict[str, float] = {}


def _summarize_trend_series(s: TrendAnalysisSeries) -> str:
    """Build a compact textual summary of a single series for the LLM prompt.
    We send aggregates (first/last/min/max/avg/n), never fabricate points."""
    vals = [
        float(p[1])
        for p in s.points
        if isinstance(p, (list, tuple)) and len(p) >= 2 and p[1] is not None
    ]
    if not vals:
        return f"- {s.label}: no data points"
    n = len(vals)
    first, last = vals[0], vals[-1]
    avg = sum(vals) / n
    change = last - first
    pct = (change / first * 100.0) if first else 0.0
    return (
        f"- {s.label} ({s.unit or 'unitless'}{', PRIMARY' if s.is_primary else ''}): "
        f"{n} days logged; start {first:.1f}, latest {last:.1f}, "
        f"min {min(vals):.1f}, max {max(vals):.1f}, avg {avg:.1f}; "
        f"net change {change:+.1f} ({pct:+.1f}%)"
    )


@router.post("/{user_id}/trend-analysis")
@limiter.limit("20/minute")
async def analyze_trends(
    request: Request,
    user_id: str,
    body: TrendAnalysisRequest,
    current_user: dict = Depends(get_current_user),
):
    """Plain-English AI analysis of the metrics currently shown on the Custom
    Trends chart. Pure analysis over client-supplied series — no DB writes.

    Returns `{"insight": str, "cached": bool}`. Never fabricates: when there is
    too little data it says so honestly."""
    try:
        series = [s for s in body.series if s.points]
        if not series:
            return {
                "insight": "Log a few more days of data to unlock a trend "
                "analysis here.",
                "cached": False,
            }

        # Honest low-data guard — the longest series still drives the verdict.
        max_points = max(len(s.points) for s in series)
        if max_points < 3:
            return {
                "insight": "Not enough history yet — keep logging and an "
                "analysis will appear once there are at least a few days "
                "of data.",
                "cached": False,
            }

        # 6h cache keyed on the displayed shape (range + labels + point counts).
        shape = ";".join(
            f"{s.label}:{len(s.points)}:{s.is_primary}" for s in series
        )
        cache_key = (
            f"trend_analysis_{user_id}_"
            + hashlib.sha1(
                f"{body.range_label}|{shape}".encode()
            ).hexdigest()[:16]
        )
        db = get_supabase_db()
        cached = db.client.table("ai_insight_cache").select("*").eq(
            "cache_key", cache_key
        ).gt("expires_at", datetime.utcnow().isoformat()).limit(1).execute()
        if cached.data:
            return {"insight": cached.data[0]["insight"], "cached": True}

        lines = "\n".join(_summarize_trend_series(s) for s in series)
        corr_txt = ""
        if body.correlations:
            corr_txt = "\nCorrelations vs the primary metric:\n" + "\n".join(
                f"- {k}: r={v:+.2f}" for k, v in body.correlations.items()
            )
        ev_txt = ""
        if body.events:
            ev_txt = "\nEvents in this window: " + ", ".join(
                f"{k}: {v}" for k, v in body.events.items() if v
            )

        prompt = (
            "You are a fitness data analyst. In 2-4 short sentences, give a "
            "concise, plain-English read of the trends below. Mention the "
            "overall direction of the primary metric, any notable change, "
            "and — if there are overlay metrics — whether they move together "
            "or oppositely. Be specific with numbers but conversational. Do "
            "not invent data or give medical advice.\n\n"
            f"Time range: {body.range_label}\n"
            f"Metrics:\n{lines}{corr_txt}{ev_txt}"
        )

        response = await gemini_service.chat(user_message=prompt)
        insight = (response or "").strip()
        if not insight:
            raise RuntimeError("empty Gemini response")

        _cache_insight(db, cache_key, insight, hours=6)
        return {"insight": insight, "cached": False}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to analyze trends for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "insights")


# ==================== FASTING ANALYSIS (Fasting screen) ====================


class FastingAnalysisRequest(BaseModel):
    """POST /insights/{user_id}/fasting-analysis body — the user's current
    fasting stats as displayed on the fasting screen. Pure analysis over
    client-supplied stats; no DB writes other than the AI cache."""
    current_streak: int = 0
    longest_streak: int = 0
    completed_fasts: int = 0
    total_fasts: int = 0
    completion_rate: float = 0.0          # percent 0-100
    avg_duration_hours: float = 0.0
    longest_fast_hours: float = 0.0
    fasts_this_week: int = 0
    # Current active fast context (optional — absent when not fasting).
    current_protocol: Optional[str] = None
    elapsed_hours: Optional[float] = None
    goal_hours: Optional[float] = None
    current_stage: Optional[str] = None


@router.post("/{user_id}/fasting-analysis")
@limiter.limit("20/minute")
async def analyze_fasting(
    request: Request,
    user_id: str,
    body: FastingAnalysisRequest,
    current_user: dict = Depends(get_current_user),
):
    """Plain-English AI analysis of the user's fasting patterns (streak,
    completion rate, average duration, and — when fasting — the live stage).

    Returns `{"insight": str, "cached": bool}`. Cached 6h. When there is no
    fasting history it returns an honest empty-state message instead of
    fabricating an analysis."""
    try:
        # Empty-state guard — no completed fasts means nothing to analyze.
        if body.completed_fasts <= 0 and body.total_fasts <= 0:
            return {
                "insight": "Complete a fast to unlock personalized insights "
                "about your fasting patterns.",
                "cached": False,
            }

        # 6h cache keyed on the displayed stats shape.
        shape = (
            f"{body.current_streak}|{body.completed_fasts}|{body.total_fasts}|"
            f"{round(body.completion_rate)}|{round(body.avg_duration_hours, 1)}|"
            f"{body.fasts_this_week}|{body.current_protocol}|{body.current_stage}"
        )
        cache_key = (
            f"fasting_analysis_{user_id}_"
            + hashlib.sha1(shape.encode()).hexdigest()[:16]
        )
        db = get_supabase_db()
        cached = db.client.table("ai_insight_cache").select("*").eq(
            "cache_key", cache_key
        ).gt("expires_at", datetime.utcnow().isoformat()).limit(1).execute()
        if cached.data:
            return {"insight": cached.data[0]["insight"], "cached": True}

        lines = [
            f"- Current streak: {body.current_streak} day(s) "
            f"(longest {body.longest_streak})",
            f"- Fasts completed: {body.completed_fasts} of {body.total_fasts} "
            f"started ({body.completion_rate:.0f}% completion rate)",
            f"- Average fast duration: {body.avg_duration_hours:.1f}h "
            f"(longest {body.longest_fast_hours:.1f}h)",
            f"- Fasts this week: {body.fasts_this_week}",
        ]
        if body.current_protocol and body.elapsed_hours is not None:
            stage_txt = f", in the {body.current_stage} stage" if body.current_stage else ""
            goal_txt = (
                f" toward a {body.goal_hours:.0f}h goal"
                if body.goal_hours else ""
            )
            lines.append(
                f"- Currently fasting on {body.current_protocol}: "
                f"{body.elapsed_hours:.1f}h elapsed{goal_txt}{stage_txt}"
            )

        prompt = (
            "You are a supportive fasting coach. In 2-4 short sentences, give "
            "a concise, plain-English read of this user's fasting patterns. "
            "Acknowledge what's going well, note one realistic area to improve, "
            "and — if they are currently fasting — a brief encouraging word "
            "about their current stage. Be specific with numbers but warm and "
            "conversational. Do not invent data or give medical advice.\n\n"
            "Fasting stats:\n" + "\n".join(lines)
        )

        response = await gemini_service.chat(user_message=prompt)
        insight = (response or "").strip()
        if not insight:
            raise RuntimeError("empty Gemini response")

        _cache_insight(db, cache_key, insight, hours=6)
        return {"insight": insight, "cached": False}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to analyze fasting for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "insights")


# ==================== HELPER FUNCTIONS ====================

def _cache_insight(db, cache_key: str, insight: str, hours: int = 24):
    """Cache an insight in the database."""
    try:
        expires_at = (datetime.utcnow() + timedelta(hours=hours)).isoformat()

        # Upsert
        existing = db.client.table("ai_insight_cache").select("id").eq(
            "cache_key", cache_key
        ).limit(1).execute()

        data = {
            "cache_key": cache_key,
            "insight": insight,
            "expires_at": expires_at,
            "updated_at": datetime.utcnow().isoformat()
        }

        if existing.data:
            db.client.table("ai_insight_cache").update(data).eq(
                "id", existing.data[0]["id"]
            ).execute()
        else:
            db.client.table("ai_insight_cache").insert(data).execute()

    except Exception as e:
        logger.warning(f"Failed to cache insight: {e}", exc_info=True)


def _calculate_streak(workouts: List[Dict], today=None) -> int:
    """Calculate workout streak from workout list."""
    from datetime import date as _date
    completed_dates = set()
    for w in workouts:
        if w.get("is_completed") and w.get("scheduled_date"):
            completed_dates.add(w["scheduled_date"][:10])

    if today is None:
        today = _date.today()
    streak = 0
    check_date = today

    while True:
        if check_date.isoformat() in completed_dates:
            streak += 1
            check_date -= timedelta(days=1)
        else:
            break

    return streak


def _fallback_weight_insight(change: float, direction: str) -> str:
    """Fallback weight insight if AI fails."""
    if direction == "losing":
        return f"You're down {abs(change):.1f} lbs! Keep up the great work with your nutrition and training."
    elif direction == "gaining":
        return f"You've gained {abs(change):.1f} lbs. Review your calorie intake and stay consistent with workouts."
    else:
        return "Your weight is stable. Consider adjusting calories or workout intensity to see more changes."


def _fallback_daily_tip(days_since: int, time_of_day: str) -> str:
    """Fallback daily tip if AI fails."""
    tips = {
        "morning": "Start your day with 10 minutes of stretching to boost energy and flexibility.",
        "afternoon": "Stay hydrated! Aim for at least 8 glasses of water before dinner.",
        "evening": "Wind down with some light mobility work to improve tomorrow's workout."
    }

    if days_since > 3:
        return "It's been a few days since your last workout. Even a 20-minute session helps maintain momentum!"

    return tips.get(time_of_day, tips["morning"])


def _fallback_habit_suggestions() -> List[Dict]:
    """Fallback habit suggestions if AI fails."""
    return [
        {"name": "Drink 8 glasses water", "reason": "Staying hydrated improves workout performance"},
        {"name": "No late-night snacking", "reason": "Helps control daily calorie intake"},
        {"name": "Sleep by 11pm", "reason": "Quality sleep is essential for recovery"}
    ]


def _parse_habit_suggestions(response: str) -> List[Dict]:
    """Parse habit suggestions from AI response."""
    try:
        # Try to extract JSON from response
        start = response.find("[")
        end = response.rfind("]") + 1
        if start >= 0 and end > start:
            json_str = response[start:end]
            return json.loads(json_str)
    except (json.JSONDecodeError, ValueError) as e:
        logger.debug(f"Failed to parse AI habit response: {e}")

    return _fallback_habit_suggestions()
