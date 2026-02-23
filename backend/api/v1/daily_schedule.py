"""
API endpoints for Daily Schedule Planner.

Combines workouts, activities, meals, fasting windows, and habits into
a unified daily timeline with Google Calendar integration.

Endpoints:
- POST   /{user_id}/items                    - Create schedule item
- GET    /{user_id}/items                    - List items (date filter)
- GET    /{user_id}/items/{item_id}          - Get single item
- PUT    /{user_id}/items/{item_id}          - Update item
- DELETE /{user_id}/items/{item_id}          - Delete item
- GET    /{user_id}/daily?date=YYYY-MM-DD   - Full day schedule with summary
- GET    /{user_id}/up-next?limit=3          - Next upcoming items
- POST   /{user_id}/items/{item_id}/complete - Mark item complete
- POST   /{user_id}/auto-populate            - Auto-create from workouts/habits/fasting
- POST   /{user_id}/gcal/connect             - Connect Google Calendar
- GET    /{user_id}/gcal/busy-times?date=    - Get busy blocks from Google Calendar
- POST   /{user_id}/gcal/push-event          - Push item to Google Calendar
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from datetime import datetime, date, timezone
from typing import Optional, List

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from models.daily_schedule import (
    ScheduleItemCreate, ScheduleItemUpdate, ScheduleItemResponse,
    DailyScheduleResponse, UpNextResponse,
    AutoPopulateRequest,
    GoogleCalendarConnectRequest, GoogleCalendarBusyTime, GoogleCalendarPushRequest,
)

router = APIRouter()
logger = get_logger(__name__)

TABLE = "schedule_items"


# ============================================================================
# SCHEDULE ITEM CRUD
# ============================================================================

@router.post("/{user_id}/items", response_model=ScheduleItemResponse)
async def create_schedule_item(user_id: str, item: ScheduleItemCreate, current_user: dict = Depends(get_current_user)):
    """
    Create a new schedule item.

    Args:
        user_id: User ID
        item: Schedule item creation data

    Returns:
        Created schedule item
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Creating schedule item: user={user_id}, title={item.title}, type={item.item_type}")

    try:
        db = get_supabase_db()

        item_data = {
            "user_id": user_id,
            "title": item.title,
            "item_type": item.item_type,
            "scheduled_date": item.scheduled_date.isoformat(),
            "start_time": item.start_time,
            "end_time": item.end_time,
            "duration_minutes": item.duration_minutes,
            "description": item.description,
            "status": "scheduled",
            "workout_id": str(item.workout_id) if item.workout_id else None,
            "habit_id": str(item.habit_id) if item.habit_id else None,
            "fasting_record_id": str(item.fasting_record_id) if item.fasting_record_id else None,
            "activity_type": item.activity_type,
            "activity_target": item.activity_target,
            "activity_icon": item.activity_icon,
            "activity_color": item.activity_color,
            "meal_type": item.meal_type,
            "is_recurring": item.is_recurring,
            "recurrence_rule": item.recurrence_rule,
            "notify_before_minutes": item.notify_before_minutes,
            "sync_to_google_calendar": item.sync_to_google_calendar,
        }

        result = db.client.table(TABLE).insert(item_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create schedule item")

        created = result.data[0]

        log_user_activity(user_id, "schedule_item_created", metadata={
            "item_id": created["id"],
            "item_type": item.item_type,
            "title": item.title,
        })

        logger.info(f"Created schedule item: id={created['id']}, title={item.title}")
        return created

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating schedule item: {e}")
        log_user_error(user_id, "create_schedule_item", str(e))
        raise safe_internal_error(e, "daily_schedule")


@router.get("/{user_id}/items", response_model=List[ScheduleItemResponse])
async def list_schedule_items(
    user_id: str,
    scheduled_date: Optional[date] = Query(None, description="Filter by date (YYYY-MM-DD)"),
    item_type: Optional[str] = Query(None, description="Filter by item type"),
    status: Optional[str] = Query(None, description="Filter by status"),
    current_user: dict = Depends(get_current_user),
):
    """
    List schedule items for a user, optionally filtered by date, type, or status.

    Args:
        user_id: User ID
        scheduled_date: Optional date filter
        item_type: Optional type filter
        status: Optional status filter

    Returns:
        List of schedule items
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Listing schedule items: user={user_id}, date={scheduled_date}, type={item_type}")

    try:
        db = get_supabase_db()

        query = db.client.table(TABLE).select("*").eq("user_id", user_id)

        if scheduled_date:
            query = query.eq("scheduled_date", scheduled_date.isoformat())
        if item_type:
            query = query.eq("item_type", item_type)
        if status:
            query = query.eq("status", status)

        query = query.order("start_time", desc=False)

        result = query.execute()

        logger.info(f"Found {len(result.data)} schedule items for user={user_id}")
        return result.data

    except Exception as e:
        logger.error(f"Error listing schedule items: {e}")
        log_user_error(user_id, "list_schedule_items", str(e))
        raise safe_internal_error(e, "daily_schedule")


@router.get("/{user_id}/items/{item_id}", response_model=ScheduleItemResponse)
async def get_schedule_item(user_id: str, item_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get a single schedule item by ID.

    Args:
        user_id: User ID
        item_id: Schedule item ID

    Returns:
        Schedule item
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting schedule item: user={user_id}, item_id={item_id}")

    try:
        db = get_supabase_db()

        result = db.client.table(TABLE).select("*").eq(
            "id", item_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Schedule item not found")

        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting schedule item: {e}")
        log_user_error(user_id, "get_schedule_item", str(e))
        raise safe_internal_error(e, "daily_schedule")


@router.put("/{user_id}/items/{item_id}", response_model=ScheduleItemResponse)
async def update_schedule_item(user_id: str, item_id: str, item: ScheduleItemUpdate, current_user: dict = Depends(get_current_user)):
    """
    Update an existing schedule item.

    Args:
        user_id: User ID
        item_id: Schedule item ID
        item: Updated fields

    Returns:
        Updated schedule item
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating schedule item: user={user_id}, item_id={item_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table(TABLE).select("id").eq(
            "id", item_id
        ).eq("user_id", user_id).execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Schedule item not found")

        # Build update data from non-None fields
        update_data = {}
        for field_name, value in item.model_dump(exclude_none=True).items():
            if field_name in ("workout_id", "habit_id", "fasting_record_id") and value is not None:
                update_data[field_name] = str(value)
            elif field_name == "scheduled_date" and value is not None:
                update_data[field_name] = value.isoformat()
            else:
                update_data[field_name] = value

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = db.client.table(TABLE).update(update_data).eq(
            "id", item_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update schedule item")

        logger.info(f"Updated schedule item: id={item_id}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating schedule item: {e}")
        log_user_error(user_id, "update_schedule_item", str(e))
        raise safe_internal_error(e, "daily_schedule")


@router.delete("/{user_id}/items/{item_id}")
async def delete_schedule_item(user_id: str, item_id: str, current_user: dict = Depends(get_current_user)):
    """
    Delete a schedule item.

    Args:
        user_id: User ID
        item_id: Schedule item ID

    Returns:
        Success message
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Deleting schedule item: user={user_id}, item_id={item_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table(TABLE).select("id, title").eq(
            "id", item_id
        ).eq("user_id", user_id).execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Schedule item not found")

        title = existing.data[0].get("title", "Unknown")

        db.client.table(TABLE).delete().eq(
            "id", item_id
        ).eq("user_id", user_id).execute()

        log_user_activity(user_id, "schedule_item_deleted", metadata={
            "item_id": item_id,
            "title": title,
        })

        logger.info(f"Deleted schedule item: id={item_id}, title={title}")
        return {"message": f"Schedule item '{title}' deleted"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting schedule item: {e}")
        log_user_error(user_id, "delete_schedule_item", str(e))
        raise safe_internal_error(e, "daily_schedule")


# ============================================================================
# DAILY VIEW & UP NEXT
# ============================================================================

@router.get("/{user_id}/daily", response_model=DailyScheduleResponse)
async def get_daily_schedule(
    user_id: str,
    date: date = Query(..., description="Date to get schedule for (YYYY-MM-DD)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get the full daily schedule with items and summary stats.

    Args:
        user_id: User ID
        date: Date to query

    Returns:
        DailyScheduleResponse with items and summary
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting daily schedule: user={user_id}, date={date}")

    try:
        db = get_supabase_db()

        result = db.client.table(TABLE).select("*").eq(
            "user_id", user_id
        ).eq(
            "scheduled_date", date.isoformat()
        ).order("start_time", desc=False).execute()

        items = result.data or []

        now = datetime.now(timezone.utc)
        now_time = now.strftime("%H:%M")

        total_items = len(items)
        completed = sum(1 for i in items if i.get("status") == "completed")
        upcoming = sum(
            1 for i in items
            if i.get("status") in ("scheduled", "in_progress") and i.get("start_time", "") >= now_time
        )

        logger.info(f"Daily schedule: {total_items} items, {completed} completed, {upcoming} upcoming")
        return DailyScheduleResponse(
            date=date,
            items=items,
            summary={
                "total_items": total_items,
                "completed": completed,
                "upcoming": upcoming,
            },
        )

    except Exception as e:
        logger.error(f"Error getting daily schedule: {e}")
        log_user_error(user_id, "get_daily_schedule", str(e))
        raise safe_internal_error(e, "daily_schedule")


@router.get("/{user_id}/up-next", response_model=UpNextResponse)
async def get_up_next(
    user_id: str,
    limit: int = Query(3, ge=1, le=20, description="Max items to return"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get the next upcoming schedule items from now.

    Args:
        user_id: User ID
        limit: Maximum number of items (default 3)

    Returns:
        UpNextResponse with upcoming items
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting up-next: user={user_id}, limit={limit}")

    try:
        db = get_supabase_db()
        now = datetime.now(timezone.utc)
        today = now.date()
        now_time = now.strftime("%H:%M")

        # Get today's items that are still upcoming
        result = db.client.table(TABLE).select("*").eq(
            "user_id", user_id
        ).eq(
            "scheduled_date", today.isoformat()
        ).in_(
            "status", ["scheduled", "in_progress"]
        ).gte(
            "start_time", now_time
        ).order(
            "start_time", desc=False
        ).limit(limit).execute()

        items = result.data or []

        logger.info(f"Up-next: {len(items)} items for user={user_id}")
        return UpNextResponse(
            items=items,
            as_of=now,
        )

    except Exception as e:
        logger.error(f"Error getting up-next: {e}")
        log_user_error(user_id, "get_up_next", str(e))
        raise safe_internal_error(e, "daily_schedule")


# ============================================================================
# STATUS UPDATES
# ============================================================================

@router.post("/{user_id}/items/{item_id}/complete", response_model=ScheduleItemResponse)
async def complete_schedule_item(user_id: str, item_id: str, current_user: dict = Depends(get_current_user)):
    """
    Mark a schedule item as completed.

    Args:
        user_id: User ID
        item_id: Schedule item ID

    Returns:
        Updated schedule item
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Completing schedule item: user={user_id}, item_id={item_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table(TABLE).select("id, title").eq(
            "id", item_id
        ).eq("user_id", user_id).execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Schedule item not found")

        result = db.client.table(TABLE).update({
            "status": "completed",
        }).eq(
            "id", item_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to complete schedule item")

        title = existing.data[0].get("title", "Unknown")
        log_user_activity(user_id, "schedule_item_completed", metadata={
            "item_id": item_id,
            "title": title,
        })

        logger.info(f"Completed schedule item: id={item_id}, title={title}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error completing schedule item: {e}")
        log_user_error(user_id, "complete_schedule_item", str(e))
        raise safe_internal_error(e, "daily_schedule")


# ============================================================================
# AUTO-POPULATE
# ============================================================================

@router.post("/{user_id}/auto-populate", response_model=List[ScheduleItemResponse])
async def auto_populate_schedule(user_id: str, request: AutoPopulateRequest, current_user: dict = Depends(get_current_user)):
    """
    Auto-populate schedule items from existing workouts, habits, and fasting records.

    Queries the user's scheduled workouts, active habits, and active fasting windows
    for the given date, then creates schedule_items entries for each.

    Args:
        user_id: User ID
        request: Auto-populate configuration

    Returns:
        List of created schedule items
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(
        f"Auto-populating schedule: user={user_id}, date={request.date}, "
        f"workouts={request.include_workouts}, habits={request.include_habits}, "
        f"fasting={request.include_fasting}"
    )

    try:
        db = get_supabase_db()
        created_items = []
        target_date = request.date.isoformat()

        # --- Include Workouts ---
        if request.include_workouts:
            workouts = db.client.table("workout_plans").select(
                "id, title, scheduled_date, duration_minutes"
            ).eq("user_id", user_id).eq(
                "scheduled_date", target_date
            ).execute()

            for w in workouts.data or []:
                item_data = {
                    "user_id": user_id,
                    "title": w.get("title", "Workout"),
                    "item_type": "workout",
                    "scheduled_date": target_date,
                    "start_time": "09:00",
                    "duration_minutes": w.get("duration_minutes", 60),
                    "status": "scheduled",
                    "workout_id": w["id"],
                }
                result = db.client.table(TABLE).insert(item_data).execute()
                if result.data:
                    created_items.append(result.data[0])

        # --- Include Habits ---
        if request.include_habits:
            habits = db.client.table("habits").select(
                "id, name, icon, color, reminder_time"
            ).eq("user_id", user_id).eq("is_active", True).execute()

            for h in habits.data or []:
                reminder_time = h.get("reminder_time")
                start_time = reminder_time if reminder_time else "08:00"
                # Ensure HH:MM format
                if isinstance(start_time, str) and len(start_time) > 5:
                    start_time = start_time[:5]

                item_data = {
                    "user_id": user_id,
                    "title": h.get("name", "Habit"),
                    "item_type": "habit",
                    "scheduled_date": target_date,
                    "start_time": start_time,
                    "duration_minutes": 5,
                    "status": "scheduled",
                    "habit_id": h["id"],
                    "activity_icon": h.get("icon"),
                    "activity_color": h.get("color"),
                }
                result = db.client.table(TABLE).insert(item_data).execute()
                if result.data:
                    created_items.append(result.data[0])

        # --- Include Fasting ---
        if request.include_fasting:
            fasting_records = db.client.table("fasting_records").select(
                "id, fast_type, target_hours, start_time"
            ).eq("user_id", user_id).eq("is_active", True).execute()

            for f in fasting_records.data or []:
                start_time_raw = f.get("start_time", "")
                fasting_start = "20:00"
                if start_time_raw and isinstance(start_time_raw, str):
                    fasting_start = start_time_raw[:5] if len(start_time_raw) >= 5 else start_time_raw

                target_hours = f.get("target_hours", 16)

                item_data = {
                    "user_id": user_id,
                    "title": f"Fasting ({f.get('fast_type', 'Intermittent')})",
                    "item_type": "fasting",
                    "scheduled_date": target_date,
                    "start_time": fasting_start,
                    "duration_minutes": target_hours * 60,
                    "status": "scheduled",
                    "fasting_record_id": f["id"],
                }
                result = db.client.table(TABLE).insert(item_data).execute()
                if result.data:
                    created_items.append(result.data[0])

        log_user_activity(user_id, "schedule_auto_populated", metadata={
            "date": target_date,
            "items_created": len(created_items),
        })

        logger.info(f"Auto-populated {len(created_items)} items for user={user_id}")
        return created_items

    except Exception as e:
        logger.error(f"Error auto-populating schedule: {e}")
        log_user_error(user_id, "auto_populate_schedule", str(e))
        raise safe_internal_error(e, "daily_schedule")


# ============================================================================
# GOOGLE CALENDAR INTEGRATION
# ============================================================================

@router.post("/{user_id}/gcal/connect")
async def connect_google_calendar(user_id: str, request: GoogleCalendarConnectRequest, current_user: dict = Depends(get_current_user)):
    """
    Connect Google Calendar by exchanging an OAuth authorization code.

    Args:
        user_id: User ID
        request: Google Calendar connect request with auth_code

    Returns:
        Connection result
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Connecting Google Calendar: user={user_id}")

    try:
        from services.google_calendar_service import google_calendar_service

        connection = await google_calendar_service.exchange_auth_code(
            user_id=user_id,
            auth_code=request.auth_code,
            calendar_id=request.calendar_id,
        )

        log_user_activity(user_id, "gcal_connected", metadata={
            "calendar_id": request.calendar_id or "primary",
        })

        logger.info(f"Connected Google Calendar for user={user_id}")
        return {"message": "Google Calendar connected successfully", "connection": connection}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error connecting Google Calendar: {e}")
        log_user_error(user_id, "connect_google_calendar", str(e))
        raise safe_internal_error(e, "daily_schedule")


@router.get("/{user_id}/gcal/busy-times", response_model=List[GoogleCalendarBusyTime])
async def get_gcal_busy_times(
    user_id: str,
    date: str = Query(..., description="Date to get busy times for (YYYY-MM-DD)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get busy time blocks from user's Google Calendar for a date.

    Args:
        user_id: User ID
        date: Date string (YYYY-MM-DD)

    Returns:
        List of busy time blocks
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting Google Calendar busy times: user={user_id}, date={date}")

    try:
        from services.google_calendar_service import google_calendar_service

        busy_times = await google_calendar_service.get_busy_times(
            user_id=user_id,
            target_date=date,
        )

        logger.info(f"Found {len(busy_times)} busy blocks for user={user_id}")
        return busy_times

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting busy times: {e}")
        log_user_error(user_id, "get_gcal_busy_times", str(e))
        raise safe_internal_error(e, "daily_schedule")


@router.post("/{user_id}/gcal/push-event")
async def push_to_google_calendar(user_id: str, request: GoogleCalendarPushRequest, current_user: dict = Depends(get_current_user)):
    """
    Push a schedule item to Google Calendar as an event.

    Args:
        user_id: User ID
        request: Push request with item_id

    Returns:
        Created Google Calendar event info
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Pushing to Google Calendar: user={user_id}, item_id={request.item_id}")

    try:
        db = get_supabase_db()

        # Get the schedule item
        item_result = db.client.table(TABLE).select("*").eq(
            "id", str(request.item_id)
        ).eq("user_id", user_id).execute()

        if not item_result.data:
            raise HTTPException(status_code=404, detail="Schedule item not found")

        item = item_result.data[0]

        from services.google_calendar_service import google_calendar_service

        event = await google_calendar_service.create_event(
            user_id=user_id,
            item=item,
        )

        # Update the schedule item with the Google Calendar event ID
        db.client.table(TABLE).update({
            "google_calendar_event_id": event.get("id"),
            "google_calendar_synced_at": datetime.now(timezone.utc).isoformat(),
            "sync_to_google_calendar": True,
        }).eq("id", str(request.item_id)).eq("user_id", user_id).execute()

        log_user_activity(user_id, "gcal_event_pushed", metadata={
            "item_id": str(request.item_id),
            "gcal_event_id": event.get("id"),
        })

        logger.info(f"Pushed to Google Calendar: event_id={event.get('id')}")
        return {"message": "Event pushed to Google Calendar", "event": event}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error pushing to Google Calendar: {e}")
        log_user_error(user_id, "push_to_google_calendar", str(e))
        raise safe_internal_error(e, "daily_schedule")
