"""Secondary endpoints for habits.  Sub-router included by main module.
API endpoints for Habit Tracking System.

Enables users to create, track, and manage daily habits:
- CRUD operations for habits
- Daily habit logging with completion tracking
- Streak tracking for habit consistency
- Templates for quick habit creation
- AI-powered habit suggestions and insights

Endpoints:
- GET /{user_id} - Get all habits for a user
- GET /{user_id}/today - Get today's habits with completion status
- POST /{user_id} - Create a new habit
- PUT /{user_id}/{habit_id} - Update an existing habit
- DELETE /{user_id}/{habit_id} - Delete (archive) a habit
- POST /{user_id}/log - Log habit completion
- PUT /{user_id}/log/{log_id} - Update a habit log
- GET /{user_id}/{habit_id}/logs - Get habit logs for date range
- POST /{user_id}/batch-log - Log multiple habits at once
- GET /{user_id}/streaks - Get all habit streaks
- GET /{user_id}/summary - Get overall habits summary
- GET /{user_id}/weekly-summary - Get weekly summary
- GET /templates/all - Get available habit templates
- POST /{user_id}/from-template - Create habit from template
- POST /{user_id}/suggestions - Get AI habit suggestions
- GET /{user_id}/insights - Get AI-generated insights
"""
from typing import List, Optional
from datetime import datetime, timedelta, date
from fastapi import APIRouter, Depends, HTTPException, Query, Request
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.timezone_utils import resolve_timezone, get_user_today
from core.exceptions import safe_internal_error
from models.habits import (
    HabitCreate, HabitUpdate, Habit, HabitWithStatus,
    HabitLogCreate, HabitLogUpdate, HabitLog,
    HabitStreak, HabitTemplate,
    TodayHabitsResponse, HabitsSummary, HabitWeeklySummary, HabitInsights,
    HabitSuggestionRequest, HabitSuggestionResponse,
    BulkHabitLogCreate, BulkHabitLogResponse,
    HabitCalendarData, HabitCalendarResponse,
)
from core.activity_logger import log_user_error

router = APIRouter()
@router.post("/{user_id}/batch-log", response_model=BulkHabitLogResponse)
async def batch_log_habits(
    user_id: str, request: BulkHabitLogCreate,
    current_user: dict = Depends(get_current_user),
):
    """
    Log multiple habits at once.

    Args:
        user_id: User ID
        request: List of habit logs to create

    Returns:
        Summary of batch operation results
    """
    logger.info(f"📝 Batch logging {len(request.logs)} habits for user={user_id}")

    verify_user_ownership(current_user, user_id)

    created_count = 0
    failed_count = 0
    results = []

    from .habits import log_habit
    for log in request.logs:
        try:
            result = await log_habit(user_id, log)
            created_count += 1
            results.append({
                "habit_id": str(log.habit_id),
                "status": "success",
                "log_id": str(result.id)
            })
        except Exception as e:
            failed_count += 1
            results.append({
                "habit_id": str(log.habit_id),
                "status": "failed",
                "error": str(e)
            })

    logger.info(f"✅ Batch log complete: {created_count} success, {failed_count} failed")

    return BulkHabitLogResponse(
        created_count=created_count,
        failed_count=failed_count,
        results=results
    )


# ============================================================================
# STREAKS
# ============================================================================

@router.get("/{user_id}/streaks", response_model=List[HabitStreak])
async def get_all_streaks(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get streaks for all habits.

    Args:
        user_id: User ID

    Returns:
        List of habit streaks
    """
    logger.info(f"🔥 Getting all streaks for user={user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        result = db.client.table("habit_streaks").select("*").eq(
            "user_id", user_id
        ).order("current_streak", desc=True).execute()

        logger.info(f"✅ Found {len(result.data)} streaks for user={user_id}")
        return result.data

    except Exception as e:
        logger.error(f"❌ Error getting streaks: {e}", exc_info=True)
        await log_user_error(user_id, "get_all_streaks", str(e))
        raise safe_internal_error(e, "endpoint")


@router.get("/{user_id}/{habit_id}/streak", response_model=HabitStreak)
async def get_habit_streak(
    user_id: str, habit_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get streak for a specific habit.

    Args:
        user_id: User ID
        habit_id: Habit ID

    Returns:
        Habit streak
    """
    logger.info(f"🔥 Getting streak for habit={habit_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        result = db.client.table("habit_streaks").select("*").eq(
            "habit_id", habit_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Streak not found")

        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting streak: {e}", exc_info=True)
        await log_user_error(user_id, "get_habit_streak", str(e))
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# SUMMARIES & ANALYTICS
# ============================================================================

@router.get("/{user_id}/summary", response_model=HabitsSummary)
async def get_habits_summary(
    user_id: str, request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Get overall habits summary for dashboard.

    Args:
        user_id: User ID

    Returns:
        HabitsSummary with overall stats
    """
    logger.info(f"📊 Getting habits summary for user={user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

        # Get today's habits response
        from .habits import get_today_habits
        today_response = await get_today_habits(user_id, request)

        # Get all streaks to calculate averages
        streaks = db.client.table("habit_streaks").select(
            "current_streak, longest_streak, habit_id"
        ).eq("user_id", user_id).execute()

        # Calculate streak stats
        streak_values = [s.get("current_streak", 0) or 0 for s in streaks.data]
        average_streak = sum(streak_values) / len(streak_values) if streak_values else 0.0
        longest_current = max(streak_values) if streak_values else 0

        # Find best performing habit (highest 7-day completion rate)
        best_habit_name = None
        best_rate = 0.0
        needs_attention = []

        for habit in today_response.habits:
            rate = habit.get("completion_rate_7d", 0)
            if rate > best_rate:
                best_rate = rate
                best_habit_name = habit.get("name")
            if rate < 50:  # Less than 50% completion
                needs_attention.append(habit.get("name"))

        summary = HabitsSummary(
            total_active_habits=today_response.total_habits,
            completed_today=today_response.completed_today,
            completion_rate_today=today_response.completion_percentage,
            average_streak=round(average_streak, 1),
            longest_current_streak=longest_current,
            best_habit_name=best_habit_name,
            needs_attention=needs_attention[:3],  # Top 3 needing attention
        )

        logger.info(f"✅ Summary: {summary.completed_today}/{summary.total_active_habits} today")
        return summary

    except Exception as e:
        logger.error(f"❌ Error getting habits summary: {e}", exc_info=True)
        await log_user_error(user_id, "get_habits_summary", str(e))
        raise safe_internal_error(e, "endpoint")


@router.get("/{user_id}/weekly-summary", response_model=List[HabitWeeklySummary])
async def get_weekly_summary(
    user_id: str,
    request: Request,
    week_start: Optional[date] = Query(None, description="Start of week (Monday)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get weekly summary for all habits.

    Args:
        user_id: User ID
        week_start: Start of week (default: current week)

    Returns:
        List of weekly summaries per habit
    """
    logger.info(f"📊 Getting weekly summary for user={user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        user_today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

        # Use the weekly summary view
        result = db.client.table("habit_weekly_summary_view").select("*").eq(
            "user_id", user_id
        ).execute()

        summaries = []
        for row in result.data:
            summaries.append(HabitWeeklySummary(
                habit_id=row["habit_id"],
                habit_name=row["name"],
                week_start=user_today - timedelta(days=6),
                days_completed=row.get("days_completed", 0) or 0,
                days_scheduled=7,  # Assuming daily for now
                completion_rate=row.get("completion_rate", 0) or 0,
                current_streak=row.get("current_streak", 0) or 0,
            ))

        logger.info(f"✅ Weekly summary: {len(summaries)} habits")
        return summaries

    except Exception as e:
        logger.error(f"❌ Error getting weekly summary: {e}", exc_info=True)
        await log_user_error(user_id, "get_weekly_summary", str(e))
        raise safe_internal_error(e, "endpoint")


@router.get("/{user_id}/calendar", response_model=HabitCalendarResponse)
async def get_habits_calendar(
    user_id: str,
    habit_id: str,
    start_date: date,
    end_date: date,
    request: Request = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get calendar view data for a habit.

    Args:
        user_id: User ID
        habit_id: Habit ID
        start_date: Start date
        end_date: End date

    Returns:
        Calendar data with daily status
    """
    logger.info(f"📅 Getting calendar for habit={habit_id}, {start_date} to {end_date}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id) if request else "UTC"
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

        # Get habit info
        habit = db.client.table("habits").select("name, frequency, target_days").eq(
            "id", habit_id
        ).eq("user_id", user_id).execute()

        if not habit.data:
            raise HTTPException(status_code=404, detail="Habit not found")

        habit_info = habit.data[0]

        # Get logs for date range
        logs = db.client.table("habit_logs").select("*").eq(
            "habit_id", habit_id
        ).gte("log_date", start_date.isoformat()).lte(
            "log_date", end_date.isoformat()
        ).execute()

        # Build log lookup
        log_by_date = {log["log_date"]: log for log in logs.data}

        # Get streak info
        streak = db.client.table("habit_streaks").select("*").eq(
            "habit_id", habit_id
        ).execute()

        # Build calendar data
        calendar_data = []
        current = start_date
        while current <= end_date:
            date_str = current.isoformat()
            log = log_by_date.get(date_str)

            # Determine status
            if current > today:
                status = "future"
            elif log:
                if log.get("completed"):
                    status = "completed"
                elif log.get("skipped"):
                    status = "skipped"
                else:
                    status = "missed"
            else:
                # Check if scheduled for this day
                if habit_info.get("frequency") == "specific_days":
                    day_num = (current.weekday() + 1) % 7
                    if habit_info.get("target_days") and day_num not in habit_info["target_days"]:
                        status = "not_scheduled"
                    else:
                        status = "missed"
                else:
                    status = "missed"

            calendar_data.append(HabitCalendarData(
                date=current,
                status=status,
                value=log.get("value") if log else None
            ))

            current += timedelta(days=1)

        return HabitCalendarResponse(
            habit_id=habit_id,
            habit_name=habit_info["name"],
            start_date=start_date,
            end_date=end_date,
            data=calendar_data,
            streak_info=streak.data[0] if streak.data else None
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting calendar: {e}", exc_info=True)
        await log_user_error(user_id, "get_habits_calendar", str(e))
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# TEMPLATES & SUGGESTIONS
# ============================================================================

@router.get("/templates/all", response_model=List[HabitTemplate])
async def get_habit_templates(
    category: Optional[str] = Query(None),
    current_user: dict = Depends(get_current_user),
):
    """
    Get available habit templates.

    Args:
        category: Optional category filter

    Returns:
        List of habit templates
    """
    logger.info(f"📋 Getting habit templates, category={category}")

    try:
        db = get_supabase_db()

        query = db.client.table("habit_templates").select("*").eq("is_active", True)

        if category:
            query = query.eq("category", category)

        query = query.order("sort_order")

        result = query.execute()

        logger.info(f"✅ Found {len(result.data)} templates")
        return result.data

    except Exception as e:
        logger.error(f"❌ Error getting templates: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.post("/{user_id}/from-template", response_model=Habit)
async def create_habit_from_template(
    user_id: str, template_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a habit from a template.

    Args:
        user_id: User ID
        template_id: Template ID to use

    Returns:
        Created habit
    """
    logger.info(f"📋 Creating habit from template: user={user_id}, template={template_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Get template - try by UUID id first, fall back to name search for slug-style IDs
        import uuid as _uuid
        try:
            _uuid.UUID(template_id)
            is_uuid = True
        except ValueError:
            is_uuid = False

        if is_uuid:
            template = db.client.table("habit_templates").select("*").eq(
                "id", template_id
            ).execute()
        else:
            # Slug-style ID (e.g. 'weigh_in') — search by name case-insensitively
            search_name = template_id.replace("_", " ")
            template = db.client.table("habit_templates").select("*").ilike(
                "name", f"%{search_name}%"
            ).limit(1).execute()

        if not template.data:
            raise HTTPException(status_code=404, detail=f"Template not found: {template_id}")

        t = template.data[0]

        # Create habit from template
        habit_create = HabitCreate(
            name=t["name"],
            description=t.get("description"),
            category=t["category"],
            habit_type=t["habit_type"],
            frequency="daily",  # Templates default to daily
            target_count=t.get("suggested_target", 1),
            unit=t.get("unit"),
            icon=t.get("icon", "check_circle"),
            color=t.get("color", "#4CAF50"),
        )

        from .habits import create_habit
        return await create_habit(user_id, habit_create)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error creating from template: {e}", exc_info=True)
        await log_user_error(user_id, "create_habit_from_template", str(e))
        raise safe_internal_error(e, "endpoint")


@router.post("/{user_id}/suggestions", response_model=HabitSuggestionResponse)
async def get_ai_suggestions(
    user_id: str, request: HabitSuggestionRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI-powered habit suggestions based on user profile.

    Args:
        user_id: User ID
        request: Suggestion request with goals and preferences

    Returns:
        AI-generated habit suggestions
    """
    logger.info(f"🤖 Getting AI habit suggestions for user={user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        # Import here to avoid circular imports
        from services.habit_suggestion_service import HabitSuggestionService

        service = HabitSuggestionService()

        # Get user context
        db = get_supabase_db()
        user_data = db.client.table("users").select(
            "fitness_level, workout_frequency, goals"
        ).eq("id", user_id).execute()

        user_context = user_data.data[0] if user_data.data else {}

        # Get existing habits
        existing = db.client.table("habits").select("name").eq(
            "user_id", user_id
        ).eq("is_active", True).execute()

        current_habits = [h["name"] for h in existing.data] if existing.data else []

        # Get suggestions from AI service
        suggestions = await service.get_personalized_suggestions(
            user_context=user_context,
            current_habits=current_habits,
            goals=request.goals
        )

        return HabitSuggestionResponse(
            suggested_habits=suggestions,
            reasoning="Based on your fitness goals and current habits, these habits would complement your routine."
        )

    except ImportError:
        # Fallback to templates if AI service not available
        logger.warning("⚠️ AI suggestion service not available, falling back to templates", exc_info=True)
        templates = await get_habit_templates()
        return HabitSuggestionResponse(
            suggested_habits=templates[:5],
            reasoning="Popular habits that can help you build a healthier routine."
        )
    except Exception as e:
        logger.error(f"❌ Error getting AI suggestions: {e}", exc_info=True)
        await log_user_error(user_id, "get_ai_suggestions", str(e))
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# INSIGHTS
# ============================================================================

@router.get("/{user_id}/insights", response_model=HabitInsights)
async def get_habit_insights(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI-generated insights about habit performance.

    Args:
        user_id: User ID

    Returns:
        AI-generated insights
    """
    logger.info(f"🤖 Getting habit insights for user={user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Get summary data
        summary = await get_habits_summary(user_id)
        weekly = await get_weekly_summary(user_id)

        # Build insights based on data
        best_performing = []
        needs_improvement = []
        suggestions = []

        for habit in weekly:
            if habit.completion_rate >= 80:
                best_performing.append(habit.habit_name)
            elif habit.completion_rate < 50:
                needs_improvement.append(habit.habit_name)

        # Generate suggestions
        if needs_improvement:
            suggestions.append(f"Focus on improving consistency with: {', '.join(needs_improvement[:2])}")
        if summary.average_streak < 5:
            suggestions.append("Try to build longer streaks by not missing two days in a row")
        if summary.total_active_habits < 3:
            suggestions.append("Consider adding 1-2 more habits to build a well-rounded routine")
        elif summary.total_active_habits > 10:
            suggestions.append("Consider focusing on fewer habits to improve completion rates")

        # Streak analysis
        if summary.longest_current_streak >= 30:
            streak_analysis = f"Excellent! Your longest current streak is {summary.longest_current_streak} days. Keep it up!"
        elif summary.longest_current_streak >= 7:
            streak_analysis = f"Good progress! You have a {summary.longest_current_streak}-day streak. Aim for 30 days!"
        elif summary.longest_current_streak > 0:
            streak_analysis = f"You're building momentum with a {summary.longest_current_streak}-day streak. Stay consistent!"
        else:
            streak_analysis = "Start building your first streak today! Consistency is key."

        # Summary
        if summary.completion_rate_today >= 80:
            overall = "You're doing great with your habits today!"
        elif summary.completion_rate_today >= 50:
            overall = "Good progress today. A few more habits to complete!"
        else:
            overall = "There's still time to work on your habits today. Every small step counts!"

        insights = HabitInsights(
            summary=overall,
            best_performing_habits=best_performing[:3],
            needs_improvement=needs_improvement[:3],
            suggestions=suggestions[:3],
            streak_analysis=streak_analysis
        )

        logger.info(f"✅ Generated insights for user={user_id}")
        return insights

    except Exception as e:
        logger.error(f"❌ Error getting insights: {e}", exc_info=True)
        await log_user_error(user_id, "get_habit_insights", str(e))
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# REORDERING
# ============================================================================

@router.post("/{user_id}/reorder")
async def reorder_habits(
    user_id: str,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Reorder habits by updating their sort_order values.

    Expects JSON body: {"order": {"habit_id": sort_order, ...}}
    """
    logger.info(f"🔄 Reordering habits for user={user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        body = await request.json()
        order_map = body.get("order", {})

        if not order_map:
            raise HTTPException(status_code=400, detail="No order map provided")

        for habit_id, sort_order in order_map.items():
            db.client.table("habits") \
                .update({"sort_order": sort_order}) \
                .eq("id", habit_id) \
                .eq("user_id", user_id) \
                .execute()

        logger.info(f"✅ Reordered {len(order_map)} habits for user={user_id}")
        return {"success": True, "message": f"Reordered {len(order_map)} habits"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error reordering habits: {e}", exc_info=True)
        await log_user_error(user_id, "reorder_habits", str(e))
        raise safe_internal_error(e, "endpoint")
