"""
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

from fastapi import APIRouter, HTTPException, Query, Request
from datetime import datetime, date, timedelta, timezone
from typing import Optional, List
from uuid import UUID

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.timezone_utils import resolve_timezone, get_user_today
from models.habits import (
    HabitCreate, HabitUpdate, Habit, HabitWithStatus,
    HabitLogCreate, HabitLogUpdate, HabitLog,
    HabitStreak, HabitTemplate,
    TodayHabitsResponse, HabitsSummary, HabitWeeklySummary, HabitInsights,
    HabitSuggestionRequest, HabitSuggestionResponse,
    BulkHabitLogCreate, BulkHabitLogResponse,
    HabitCalendarData, HabitCalendarResponse,
)

router = APIRouter()
logger = get_logger(__name__)


# ============================================================================
# HABIT CRUD OPERATIONS
# ============================================================================

@router.get("/{user_id}", response_model=List[Habit])
async def get_habits(
    user_id: str,
    is_active: bool = Query(True, description="Filter by active status"),
    category: Optional[str] = Query(None, description="Filter by category")
):
    """
    Get all habits for a user.

    Args:
        user_id: User ID
        is_active: Filter by active status (default: True)
        category: Optional category filter

    Returns:
        List of habits
    """
    logger.info(f"🔍 Getting habits for user={user_id}, is_active={is_active}, category={category}")

    try:
        db = get_supabase_db()

        query = db.client.table("habits").select("*").eq("user_id", user_id)

        if is_active is not None:
            query = query.eq("is_active", is_active)

        if category:
            query = query.eq("category", category)

        query = query.order("created_at", desc=False)

        result = query.execute()

        logger.info(f"✅ Found {len(result.data)} habits for user={user_id}")
        return result.data

    except Exception as e:
        logger.error(f"❌ Error getting habits: {e}")
        log_user_error(user_id, "get_habits", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/today", response_model=TodayHabitsResponse)
async def get_today_habits(user_id: str, request: Request):
    """
    Get today's habits with completion status.

    Uses the today_habits_view for efficient querying.
    Also calculates 7-day completion rate for each habit.

    Args:
        user_id: User ID

    Returns:
        TodayHabitsResponse with habits and completion stats
    """
    logger.info(f"🔍 Getting today's habits for user={user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

        # Get habits with today's status from view
        result = db.client.table("today_habits_view").select("*").eq(
            "user_id", user_id
        ).execute()

        if not result.data:
            return TodayHabitsResponse(
                habits=[],
                total_habits=0,
                completed_today=0,
                completion_percentage=0.0
            )

        # Get 7-day completion rates for each habit
        week_ago = today - timedelta(days=6)
        habits_with_status = []

        for habit_data in result.data:
            habit_id = habit_data["habit_id"]

            # Get 7-day logs for this habit
            logs_result = db.client.table("habit_logs").select("completed").eq(
                "habit_id", habit_id
            ).gte("log_date", week_ago.isoformat()).lte(
                "log_date", today.isoformat()
            ).execute()

            # Calculate 7-day completion rate
            total_days = len(logs_result.data) if logs_result.data else 0
            completed_days = sum(1 for log in (logs_result.data or []) if log.get("completed", False))
            completion_rate_7d = (completed_days / 7) * 100 if total_days > 0 else 0.0

            # Check if habit should be tracked today (for specific_days frequency)
            should_track_today = True
            if habit_data.get("frequency") == "specific_days" and habit_data.get("target_days"):
                # Python weekday: Monday = 0, Sunday = 6
                # But our target_days uses Sunday = 0, Saturday = 6
                today_weekday = (today.weekday() + 1) % 7  # Convert to Sunday = 0 format
                should_track_today = today_weekday in habit_data["target_days"]

            if should_track_today:
                habit_with_status = {
                    "id": habit_id,
                    "user_id": habit_data["user_id"],
                    "name": habit_data["name"],
                    "description": habit_data.get("description"),
                    "category": habit_data["category"],
                    "habit_type": habit_data["habit_type"],
                    "frequency": habit_data["frequency"],
                    "target_days": habit_data.get("target_days"),
                    "target_count": habit_data.get("target_count", 1),
                    "unit": habit_data.get("unit"),
                    "icon": habit_data.get("icon", "check_circle"),
                    "color": habit_data.get("color", "#4CAF50"),
                    "reminder_time": habit_data.get("reminder_time"),
                    "reminder_enabled": habit_data.get("reminder_enabled", False),
                    "is_active": True,
                    "is_suggested": habit_data.get("is_suggested", False),
                    "created_at": habit_data["habit_created_at"],
                    "updated_at": habit_data["habit_created_at"],  # View doesn't have updated_at
                    "today_completed": habit_data.get("completed", False),
                    "today_value": habit_data.get("value"),
                    "current_streak": habit_data.get("current_streak", 0) or 0,
                    "longest_streak": habit_data.get("longest_streak", 0) or 0,
                    "completion_rate_7d": round(completion_rate_7d, 1),
                }
                habits_with_status.append(habit_with_status)

        # Calculate totals
        total_habits = len(habits_with_status)
        completed_today = sum(1 for h in habits_with_status if h["today_completed"])
        completion_percentage = (completed_today / total_habits * 100) if total_habits > 0 else 0.0

        logger.info(f"✅ Today's habits: {completed_today}/{total_habits} completed for user={user_id}")

        return TodayHabitsResponse(
            habits=habits_with_status,
            total_habits=total_habits,
            completed_today=completed_today,
            completion_percentage=round(completion_percentage, 1)
        )

    except Exception as e:
        logger.error(f"❌ Error getting today's habits: {e}")
        log_user_error(user_id, "get_today_habits", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}", response_model=Habit)
async def create_habit(user_id: str, habit: HabitCreate):
    """
    Create a new habit for a user.

    Args:
        user_id: User ID
        habit: Habit creation data

    Returns:
        Created habit
    """
    logger.info(f"🎯 Creating habit: user={user_id}, name={habit.name}, category={habit.category}")

    try:
        db = get_supabase_db()

        # Prepare habit data
        habit_data = {
            "user_id": user_id,
            "name": habit.name,
            "description": habit.description,
            "category": habit.category,
            "habit_type": habit.habit_type,
            "frequency": habit.frequency,
            "target_days": habit.target_days,
            "target_count": habit.target_count,
            "unit": habit.unit,
            "icon": habit.icon,
            "color": habit.color,
            "reminder_time": habit.reminder_time.isoformat() if habit.reminder_time else None,
            "reminder_enabled": habit.reminder_enabled,
            "is_active": True,
            "is_suggested": False,
        }

        result = db.client.table("habits").insert(habit_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create habit")

        created_habit = result.data[0]

        # Log activity
        log_user_activity(user_id, "habit_created", {
            "habit_id": created_habit["id"],
            "habit_name": habit.name,
            "category": habit.category,
            "habit_type": habit.habit_type,
        })

        logger.info(f"✅ Created habit: id={created_habit['id']}, name={habit.name}")
        return created_habit

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error creating habit: {e}")
        log_user_error(user_id, "create_habit", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{user_id}/{habit_id}", response_model=Habit)
async def update_habit(user_id: str, habit_id: str, habit: HabitUpdate):
    """
    Update an existing habit.

    Args:
        user_id: User ID
        habit_id: Habit ID to update
        habit: Updated habit data

    Returns:
        Updated habit
    """
    logger.info(f"🔄 Updating habit: user={user_id}, habit_id={habit_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table("habits").select("id").eq(
            "id", habit_id
        ).eq("user_id", user_id).execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Habit not found")

        # Build update data (only include non-None fields)
        update_data = {}
        if habit.name is not None:
            update_data["name"] = habit.name
        if habit.description is not None:
            update_data["description"] = habit.description
        if habit.category is not None:
            update_data["category"] = habit.category
        if habit.habit_type is not None:
            update_data["habit_type"] = habit.habit_type
        if habit.frequency is not None:
            update_data["frequency"] = habit.frequency
        if habit.target_days is not None:
            update_data["target_days"] = habit.target_days
        if habit.target_count is not None:
            update_data["target_count"] = habit.target_count
        if habit.unit is not None:
            update_data["unit"] = habit.unit
        if habit.icon is not None:
            update_data["icon"] = habit.icon
        if habit.color is not None:
            update_data["color"] = habit.color
        if habit.reminder_time is not None:
            update_data["reminder_time"] = habit.reminder_time.isoformat()
        if habit.reminder_enabled is not None:
            update_data["reminder_enabled"] = habit.reminder_enabled
        if habit.is_active is not None:
            update_data["is_active"] = habit.is_active

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = db.client.table("habits").update(update_data).eq(
            "id", habit_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update habit")

        logger.info(f"✅ Updated habit: id={habit_id}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error updating habit: {e}")
        log_user_error(user_id, "update_habit", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/{habit_id}")
async def delete_habit(user_id: str, habit_id: str, hard_delete: bool = Query(False)):
    """
    Delete a habit (soft delete by default).

    Args:
        user_id: User ID
        habit_id: Habit ID to delete
        hard_delete: If True, permanently delete. Default is soft delete (is_active=False)

    Returns:
        Success message
    """
    logger.info(f"🗑️ Deleting habit: user={user_id}, habit_id={habit_id}, hard={hard_delete}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table("habits").select("id, name").eq(
            "id", habit_id
        ).eq("user_id", user_id).execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Habit not found")

        habit_name = existing.data[0]["name"]

        if hard_delete:
            # Permanently delete
            db.client.table("habits").delete().eq(
                "id", habit_id
            ).eq("user_id", user_id).execute()
            message = f"Habit '{habit_name}' permanently deleted"
        else:
            # Soft delete
            db.client.table("habits").update({"is_active": False}).eq(
                "id", habit_id
            ).eq("user_id", user_id).execute()
            message = f"Habit '{habit_name}' archived"

        log_user_activity(user_id, "habit_deleted", {
            "habit_id": habit_id,
            "habit_name": habit_name,
            "hard_delete": hard_delete,
        })

        logger.info(f"✅ {message}")
        return {"message": message}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error deleting habit: {e}")
        log_user_error(user_id, "delete_habit", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/{habit_id}/archive")
async def archive_habit(user_id: str, habit_id: str):
    """
    Archive a habit (same as soft delete).

    Args:
        user_id: User ID
        habit_id: Habit ID to archive

    Returns:
        Success message
    """
    return await delete_habit(user_id, habit_id, hard_delete=False)


# ============================================================================
# HABIT LOGGING
# ============================================================================

@router.post("/{user_id}/log", response_model=HabitLog)
async def log_habit(user_id: str, log: HabitLogCreate, request: Request = None):
    """
    Log habit completion for a specific date.

    Uses upsert to handle logging the same habit multiple times per day.
    Streak updates are handled by database trigger.

    Args:
        user_id: User ID
        log: Habit log data

    Returns:
        Created/updated habit log
    """
    logger.info(f"📝 Logging habit: user={user_id}, habit_id={log.habit_id}, date={log.log_date}, completed={log.completed}")

    try:
        db = get_supabase_db()

        # Verify habit ownership
        habit = db.client.table("habits").select("id, name").eq(
            "id", str(log.habit_id)
        ).eq("user_id", user_id).execute()

        if not habit.data:
            raise HTTPException(status_code=404, detail="Habit not found")

        # Prevent logging future dates (use user's local today)
        user_tz = resolve_timezone(request, db, user_id) if request else "UTC"
        user_today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        if log.log_date > user_today:
            raise HTTPException(status_code=400, detail="Cannot log habits for future dates")

        # Prepare log data
        log_data = {
            "habit_id": str(log.habit_id),
            "user_id": user_id,
            "log_date": log.log_date.isoformat(),
            "completed": log.completed,
            "value": log.value,
            "notes": log.notes,
            "skipped": log.skipped,
            "skip_reason": log.skip_reason,
            "completed_at": datetime.now(timezone.utc).isoformat() if log.completed else None,
        }

        # Upsert the log (insert or update if exists for same habit+date)
        result = db.client.table("habit_logs").upsert(
            log_data,
            on_conflict="habit_id,log_date"
        ).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to log habit")

        log_entry = result.data[0]

        # Log activity
        log_user_activity(user_id, "habit_logged", {
            "habit_id": str(log.habit_id),
            "habit_name": habit.data[0]["name"],
            "log_date": log.log_date.isoformat(),
            "completed": log.completed,
            "value": log.value,
        })

        logger.info(f"✅ Logged habit: id={log_entry['id']}, completed={log.completed}")
        return log_entry

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error logging habit: {e}")
        log_user_error(user_id, "log_habit", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{user_id}/log/{log_id}", response_model=HabitLog)
async def update_habit_log(user_id: str, log_id: str, log: HabitLogUpdate):
    """
    Update an existing habit log.

    Args:
        user_id: User ID
        log_id: Log ID to update
        log: Updated log data

    Returns:
        Updated habit log
    """
    logger.info(f"🔄 Updating habit log: user={user_id}, log_id={log_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table("habit_logs").select("id").eq(
            "id", log_id
        ).eq("user_id", user_id).execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Habit log not found")

        # Build update data
        update_data = {}
        if log.completed is not None:
            update_data["completed"] = log.completed
            if log.completed:
                update_data["completed_at"] = datetime.now(timezone.utc).isoformat()
            else:
                update_data["completed_at"] = None
        if log.value is not None:
            update_data["value"] = log.value
        if log.notes is not None:
            update_data["notes"] = log.notes
        if log.skipped is not None:
            update_data["skipped"] = log.skipped
        if log.skip_reason is not None:
            update_data["skip_reason"] = log.skip_reason

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = db.client.table("habit_logs").update(update_data).eq(
            "id", log_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update habit log")

        logger.info(f"✅ Updated habit log: id={log_id}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error updating habit log: {e}")
        log_user_error(user_id, "update_habit_log", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/{habit_id}/logs", response_model=List[HabitLog])
async def get_habit_logs(
    user_id: str,
    habit_id: str,
    request: Request,
    start_date: Optional[date] = Query(None, description="Start date (default: 30 days ago)"),
    end_date: Optional[date] = Query(None, description="End date (default: today)")
):
    """
    Get habit logs for a date range.

    Args:
        user_id: User ID
        habit_id: Habit ID
        start_date: Start date (default: 30 days ago)
        end_date: End date (default: today)

    Returns:
        List of habit logs
    """
    logger.info(f"🔍 Getting habit logs: user={user_id}, habit_id={habit_id}")

    try:
        db = get_supabase_db()

        # Default date range (timezone-aware)
        user_tz = resolve_timezone(request, db, user_id)
        if end_date is None:
            end_date = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        if start_date is None:
            start_date = end_date - timedelta(days=30)

        # Verify habit ownership
        habit = db.client.table("habits").select("id").eq(
            "id", habit_id
        ).eq("user_id", user_id).execute()

        if not habit.data:
            raise HTTPException(status_code=404, detail="Habit not found")

        result = db.client.table("habit_logs").select("*").eq(
            "habit_id", habit_id
        ).eq("user_id", user_id).gte(
            "log_date", start_date.isoformat()
        ).lte(
            "log_date", end_date.isoformat()
        ).order("log_date", desc=True).execute()

        logger.info(f"✅ Found {len(result.data)} logs for habit={habit_id}")
        return result.data

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting habit logs: {e}")
        log_user_error(user_id, "get_habit_logs", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/batch-log", response_model=BulkHabitLogResponse)
async def batch_log_habits(user_id: str, request: BulkHabitLogCreate):
    """
    Log multiple habits at once.

    Args:
        user_id: User ID
        request: List of habit logs to create

    Returns:
        Summary of batch operation results
    """
    logger.info(f"📝 Batch logging {len(request.logs)} habits for user={user_id}")

    created_count = 0
    failed_count = 0
    results = []

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
async def get_all_streaks(user_id: str):
    """
    Get streaks for all habits.

    Args:
        user_id: User ID

    Returns:
        List of habit streaks
    """
    logger.info(f"🔥 Getting all streaks for user={user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("habit_streaks").select("*").eq(
            "user_id", user_id
        ).order("current_streak", desc=True).execute()

        logger.info(f"✅ Found {len(result.data)} streaks for user={user_id}")
        return result.data

    except Exception as e:
        logger.error(f"❌ Error getting streaks: {e}")
        log_user_error(user_id, "get_all_streaks", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/{habit_id}/streak", response_model=HabitStreak)
async def get_habit_streak(user_id: str, habit_id: str):
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
        logger.error(f"❌ Error getting streak: {e}")
        log_user_error(user_id, "get_habit_streak", str(e))
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# SUMMARIES & ANALYTICS
# ============================================================================

@router.get("/{user_id}/summary", response_model=HabitsSummary)
async def get_habits_summary(user_id: str, request: Request):
    """
    Get overall habits summary for dashboard.

    Args:
        user_id: User ID

    Returns:
        HabitsSummary with overall stats
    """
    logger.info(f"📊 Getting habits summary for user={user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

        # Get today's habits response
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
        logger.error(f"❌ Error getting habits summary: {e}")
        log_user_error(user_id, "get_habits_summary", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/weekly-summary", response_model=List[HabitWeeklySummary])
async def get_weekly_summary(
    user_id: str,
    request: Request,
    week_start: Optional[date] = Query(None, description="Start of week (Monday)")
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
        logger.error(f"❌ Error getting weekly summary: {e}")
        log_user_error(user_id, "get_weekly_summary", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/calendar", response_model=HabitCalendarResponse)
async def get_habits_calendar(
    user_id: str,
    habit_id: str,
    start_date: date,
    end_date: date,
    request: Request = None,
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
        logger.error(f"❌ Error getting calendar: {e}")
        log_user_error(user_id, "get_habits_calendar", str(e))
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# TEMPLATES & SUGGESTIONS
# ============================================================================

@router.get("/templates/all", response_model=List[HabitTemplate])
async def get_habit_templates(category: Optional[str] = Query(None)):
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
        logger.error(f"❌ Error getting templates: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/from-template", response_model=Habit)
async def create_habit_from_template(user_id: str, template_id: str):
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
        db = get_supabase_db()

        # Get template
        template = db.client.table("habit_templates").select("*").eq(
            "id", template_id
        ).execute()

        if not template.data:
            raise HTTPException(status_code=404, detail="Template not found")

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

        return await create_habit(user_id, habit_create)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error creating from template: {e}")
        log_user_error(user_id, "create_habit_from_template", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/suggestions", response_model=HabitSuggestionResponse)
async def get_ai_suggestions(user_id: str, request: HabitSuggestionRequest):
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
        logger.warning("⚠️ AI suggestion service not available, falling back to templates")
        templates = await get_habit_templates()
        return HabitSuggestionResponse(
            suggested_habits=templates[:5],
            reasoning="Popular habits that can help you build a healthier routine."
        )
    except Exception as e:
        logger.error(f"❌ Error getting AI suggestions: {e}")
        log_user_error(user_id, "get_ai_suggestions", str(e))
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# INSIGHTS
# ============================================================================

@router.get("/{user_id}/insights", response_model=HabitInsights)
async def get_habit_insights(user_id: str):
    """
    Get AI-generated insights about habit performance.

    Args:
        user_id: User ID

    Returns:
        AI-generated insights
    """
    logger.info(f"🤖 Getting habit insights for user={user_id}")

    try:
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
        logger.error(f"❌ Error getting insights: {e}")
        log_user_error(user_id, "get_habit_insights", str(e))
        raise HTTPException(status_code=500, detail=str(e))
