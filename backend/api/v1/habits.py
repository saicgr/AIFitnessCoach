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
from core.db import get_supabase_db
from .habits_endpoints import router as _endpoints_router


from fastapi import APIRouter, HTTPException, Query, Request, Depends
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
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error

router = APIRouter()
logger = get_logger(__name__)


# ============================================================================
# HABIT CRUD OPERATIONS
# ============================================================================

@router.get("/{user_id}", response_model=List[Habit])
async def get_habits(
    user_id: str,
    is_active: bool = Query(True, description="Filter by active status"),
    category: Optional[str] = Query(None, description="Filter by category"),
    current_user: dict = Depends(get_current_user),
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
        verify_user_ownership(current_user, user_id)
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
        logger.error(f"❌ Error getting habits: {e}", exc_info=True)
        await log_user_error(user_id, "get_habits", str(e))
        raise safe_internal_error(e, "endpoint")


@router.get("/{user_id}/today", response_model=TodayHabitsResponse)
async def get_today_habits(
    user_id: str, request: Request,
    current_user: dict = Depends(get_current_user),
):
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
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

        # Get habits with today's status from view
        result = db.client.table("today_habits_view").select("*").eq(
            "user_id", user_id
        ).order("sort_order", desc=False).execute()

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
        logger.error(f"❌ Error getting today's habits: {e}", exc_info=True)
        await log_user_error(user_id, "get_today_habits", str(e))
        raise safe_internal_error(e, "endpoint")


@router.post("/{user_id}", response_model=Habit)
async def create_habit(
    user_id: str, habit: HabitCreate,
    current_user: dict = Depends(get_current_user),
):
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
        verify_user_ownership(current_user, user_id)
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
            raise safe_internal_error(e, "endpoint")

        created_habit = result.data[0]

        # Log activity
        await log_user_activity(user_id, "habit_created", {
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
        logger.error(f"❌ Error creating habit: {e}", exc_info=True)
        await log_user_error(user_id, "create_habit", str(e))
        raise safe_internal_error(e, "endpoint")


@router.put("/{user_id}/{habit_id}", response_model=Habit)
async def update_habit(
    user_id: str, habit_id: str, habit: HabitUpdate,
    current_user: dict = Depends(get_current_user),
):
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
        verify_user_ownership(current_user, user_id)
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
            raise safe_internal_error(e, "endpoint")

        logger.info(f"✅ Updated habit: id={habit_id}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error updating habit: {e}", exc_info=True)
        await log_user_error(user_id, "update_habit", str(e))
        raise safe_internal_error(e, "endpoint")


@router.delete("/{user_id}/{habit_id}")
async def delete_habit(
    user_id: str, habit_id: str, hard_delete: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
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
        verify_user_ownership(current_user, user_id)
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

        await log_user_activity(user_id, "habit_deleted", {
            "habit_id": habit_id,
            "habit_name": habit_name,
            "hard_delete": hard_delete,
        })

        logger.info(f"✅ {message}")
        return {"message": message}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error deleting habit: {e}", exc_info=True)
        await log_user_error(user_id, "delete_habit", str(e))
        raise safe_internal_error(e, "endpoint")


@router.post("/{user_id}/{habit_id}/archive")
async def archive_habit(
    user_id: str, habit_id: str,
    current_user: dict = Depends(get_current_user),
):
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
async def log_habit(
    user_id: str, log: HabitLogCreate, request: Request = None,
    current_user: dict = Depends(get_current_user),
):
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
        verify_user_ownership(current_user, user_id)
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
            raise safe_internal_error(e, "endpoint")

        log_entry = result.data[0]

        # Log activity
        await log_user_activity(user_id, "habit_logged", {
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
        logger.error(f"❌ Error logging habit: {e}", exc_info=True)
        await log_user_error(user_id, "log_habit", str(e))
        raise safe_internal_error(e, "endpoint")


@router.put("/{user_id}/log/{log_id}", response_model=HabitLog)
async def update_habit_log(
    user_id: str, log_id: str, log: HabitLogUpdate,
    current_user: dict = Depends(get_current_user),
):
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
        verify_user_ownership(current_user, user_id)
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
            raise safe_internal_error(e, "endpoint")

        logger.info(f"✅ Updated habit log: id={log_id}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error updating habit log: {e}", exc_info=True)
        await log_user_error(user_id, "update_habit_log", str(e))
        raise safe_internal_error(e, "endpoint")


@router.get("/{user_id}/{habit_id}/logs", response_model=List[HabitLog])
async def get_habit_logs(
    user_id: str,
    habit_id: str,
    request: Request,
    start_date: Optional[date] = Query(None, description="Start date (default: 30 days ago)"),
    end_date: Optional[date] = Query(None, description="End date (default: today)"),
    current_user: dict = Depends(get_current_user),
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
        verify_user_ownership(current_user, user_id)
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
        logger.error(f"❌ Error getting habit logs: {e}", exc_info=True)
        await log_user_error(user_id, "get_habit_logs", str(e))
        raise safe_internal_error(e, "endpoint")



# Include secondary endpoints
router.include_router(_endpoints_router)
