"""
Fasting Tracking API endpoints.

ENDPOINTS:
Fasting Records:
- POST /api/v1/fasting/start - Start a new fast
- POST /api/v1/fasting/{fast_id}/end - End an active fast
- POST /api/v1/fasting/{fast_id}/cancel - Cancel a fast (no credit)
- GET  /api/v1/fasting/active/{user_id} - Get current active fast
- GET  /api/v1/fasting/history/{user_id} - Get fasting history
- PUT  /api/v1/fasting/{fast_id} - Update a fast record

Fasting Preferences:
- GET  /api/v1/fasting/preferences/{user_id} - Get fasting preferences
- PUT  /api/v1/fasting/preferences/{user_id} - Update fasting preferences
- POST /api/v1/fasting/onboarding/complete - Complete fasting onboarding

Streaks & Stats:
- GET  /api/v1/fasting/streak/{user_id} - Get fasting streak
- GET  /api/v1/fasting/stats/{user_id} - Get fasting statistics

Safety:
- GET  /api/v1/fasting/safety-check/{user_id} - Check safety eligibility
- POST /api/v1/fasting/safety-screening - Save safety screening

Fasting Scores:
- POST /api/v1/fasting/score - Save/upsert a fasting score
- GET  /api/v1/fasting/score/history/{user_id} - Get historical scores
- GET  /api/v1/fasting/score/{user_id}/current - Get current/latest score
- GET  /api/v1/fasting/score/trend/{user_id} - Get score trend vs last week
"""
from core.db import get_supabase_db

from .fasting_models import *  # noqa: F401, F403
from .fasting_endpoints import router as _endpoints_router

from fastapi import APIRouter, HTTPException, Query, Request, Depends
from typing import Any, List, Optional
from datetime import datetime, date, timedelta
from decimal import Decimal
import uuid

from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.timezone_utils import resolve_timezone, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error

router = APIRouter()
logger = get_logger(__name__)


# ==================== Pydantic Models ====================

class StartFastRequest(BaseModel):
    """Request to start a new fast."""
    user_id: str
    protocol: str = Field(description="Protocol ID like '16:8', '18:6', '5:2'")
    protocol_type: str = Field(description="Type: 'tre', 'modified', 'extended', 'custom'")
    goal_duration_minutes: int = Field(ge=60, le=10080, description="Goal in minutes (1h to 7 days)")
    started_at: Optional[str] = Field(None, description="Custom start time in ISO format (for backdating)")
    mood_before: Optional[str] = None
    notes: Optional[str] = None


class EndFastRequest(BaseModel):
    """Request to end a fast."""
    user_id: str
    notes: Optional[str] = None
    mood_after: Optional[str] = None
    energy_level: Optional[int] = Field(None, ge=1, le=5)


class CancelFastRequest(BaseModel):
    """Request to cancel a fast."""
    user_id: str


class UpdateFastRequest(BaseModel):
    """Request to update a fast record."""
    user_id: str
    notes: Optional[str] = None
    mood_before: Optional[str] = None
    mood_after: Optional[str] = None
    energy_level: Optional[int] = Field(None, ge=1, le=5)


class FastingPreferencesRequest(BaseModel):
    """Fasting preferences update request."""
    user_id: str
    default_protocol: Optional[str] = "16:8"
    custom_fasting_hours: Optional[int] = None
    custom_eating_hours: Optional[int] = None
    typical_fast_start_hour: Optional[int] = Field(None, ge=0, le=23)
    typical_eating_start_hour: Optional[int] = Field(None, ge=0, le=23)
    fasting_days: Optional[List[str]] = None  # For 5:2: ['monday', 'thursday']
    notifications_enabled: Optional[bool] = True
    notify_zone_transitions: Optional[bool] = True
    notify_goal_reached: Optional[bool] = True
    notify_eating_window_end: Optional[bool] = True
    notify_fast_start_reminder: Optional[bool] = True
    is_keto_adapted: Optional[bool] = False
    # Meal reminders (new)
    meal_reminders_enabled: Optional[bool] = True
    lunch_reminder_hour: Optional[int] = Field(None, ge=0, le=23)
    dinner_reminder_hour: Optional[int] = Field(None, ge=0, le=23)
    extended_protocol_acknowledged: Optional[bool] = False
    safety_responses: Optional[dict] = None


class CompleteOnboardingRequest(BaseModel):
    """Complete fasting onboarding request."""
    user_id: str
    preferences: dict
    safety_acknowledgments: List[str]


class SafetyScreeningRequest(BaseModel):
    """Save safety screening responses."""
    user_id: str
    responses: dict  # Question key -> bool answer


# ==================== Response Models ====================

class FastingRecordResponse(BaseModel):
    """Fasting record response."""
    id: str
    user_id: str
    start_time: str
    end_time: Optional[str] = None
    goal_duration_minutes: int
    actual_duration_minutes: Optional[int] = None
    protocol: str
    protocol_type: str
    status: str  # 'active', 'completed', 'cancelled'
    completed_goal: bool
    completion_percentage: Optional[float] = None
    zones_reached: Optional[List[dict]] = None
    notes: Optional[str] = None
    mood_before: Optional[str] = None
    mood_after: Optional[str] = None
    energy_level: Optional[int] = None
    created_at: str
    updated_at: Optional[str] = None


class FastEndResultResponse(BaseModel):
    """Result of ending a fast."""
    record: FastingRecordResponse
    actual_minutes: int
    goal_minutes: int
    completion_percent: float
    streak_maintained: bool
    message: str
    streak_info: Optional[dict] = None


class FastingPreferencesResponse(BaseModel):
    """Fasting preferences response."""
    id: str
    user_id: str
    default_protocol: str
    custom_fasting_hours: Optional[int] = None
    custom_eating_hours: Optional[int] = None
    typical_fast_start_hour: Optional[int] = None
    typical_eating_start_hour: Optional[int] = None
    fasting_days: Optional[List[str]] = None
    notifications_enabled: bool
    notify_zone_transitions: bool
    notify_goal_reached: bool
    notify_eating_window_end: bool
    notify_fast_start_reminder: Optional[bool] = True
    is_keto_adapted: bool
    # Meal reminders (new)
    meal_reminders_enabled: Optional[bool] = True
    lunch_reminder_hour: Optional[int] = None
    dinner_reminder_hour: Optional[int] = None
    extended_protocol_acknowledged: Optional[bool] = False
    safety_responses: Optional[dict] = None
    safety_screening_completed: bool
    safety_warnings_acknowledged: Optional[List[str]] = None
    has_medical_conditions: Optional[bool] = False
    fasting_onboarding_completed: bool
    onboarding_completed_at: Optional[str] = None
    created_at: str
    updated_at: Optional[str] = None


class FastingStreakResponse(BaseModel):
    """Fasting streak response."""
    user_id: str
    current_streak: int
    longest_streak: int
    total_fasts_completed: int
    total_fasting_hours: int
    last_fast_date: Optional[str] = None
    streak_start_date: Optional[str] = None
    fasts_this_week: int
    freezes_available: Optional[int] = 2
    freezes_used_this_week: Optional[int] = 0


class FastingStatsResponse(BaseModel):
    """Fasting statistics response."""
    user_id: str
    period: str
    total_fasts: int
    completed_fasts: int
    cancelled_fasts: int
    total_fasting_hours: float
    average_fast_duration_hours: float
    longest_fast_hours: float
    completion_rate: float
    most_common_protocol: Optional[str] = None
    zones_reached: dict  # zone_name -> count


class SafetyCheckResponse(BaseModel):
    """Safety eligibility check response."""
    can_use_fasting: bool
    requires_warning: bool
    warnings: List[str]
    blocked_reasons: List[str]


# ==================== Fasting Score Models ====================

class FastingScoreCreateRequest(BaseModel):
    """Request to save/update a fasting score."""
    user_id: str
    score: int = Field(ge=0, le=100)
    completion_component: float = 0
    streak_component: float = 0
    duration_component: float = 0
    weekly_component: float = 0
    protocol_component: float = 0
    current_streak: int = 0
    fasts_this_week: int = 0
    weekly_goal: int = 5
    completion_rate: float = 0
    avg_duration_minutes: int = 0


class FastingScoreResponse(BaseModel):
    """Response for a single fasting score."""
    id: str
    user_id: str
    score: int
    completion_component: float
    streak_component: float
    duration_component: float
    weekly_component: float
    protocol_component: float
    current_streak: int
    fasts_this_week: int
    weekly_goal: int
    completion_rate: float
    avg_duration_minutes: int
    recorded_at: str
    score_date: str


class FastingScoreTrendResponse(BaseModel):
    """Response for score trend data."""
    current_score: int
    previous_score: int
    score_change: int
    trend: str  # 'up', 'down', 'stable'


# ==================== Helper Functions ====================

def row_to_fasting_record(row: dict) -> FastingRecordResponse:
    """Convert a Supabase row to FastingRecordResponse."""
    return FastingRecordResponse(
        id=row.get("id"),
        user_id=row.get("user_id"),
        start_time=row.get("start_time"),
        end_time=row.get("end_time"),
        goal_duration_minutes=row.get("goal_duration_minutes"),
        actual_duration_minutes=row.get("actual_duration_minutes"),
        protocol=row.get("protocol"),
        protocol_type=row.get("protocol_type"),
        status=row.get("status", "active"),
        completed_goal=row.get("completed_goal", False),
        completion_percentage=float(row.get("completion_percentage") or 0),
        zones_reached=row.get("zones_reached"),
        notes=row.get("notes"),
        mood_before=row.get("mood_before"),
        mood_after=row.get("mood_after"),
        energy_level=row.get("energy_level"),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


def row_to_preferences(row: dict) -> FastingPreferencesResponse:
    """Convert a Supabase row to FastingPreferencesResponse."""
    return FastingPreferencesResponse(
        id=row.get("id"),
        user_id=row.get("user_id"),
        default_protocol=row.get("default_protocol", "16:8"),
        custom_fasting_hours=row.get("custom_fasting_hours"),
        custom_eating_hours=row.get("custom_eating_hours"),
        typical_fast_start_hour=row.get("typical_fast_start_hour"),
        typical_eating_start_hour=row.get("typical_eating_start_hour"),
        fasting_days=row.get("fasting_days"),
        notifications_enabled=row.get("notifications_enabled", True),
        notify_zone_transitions=row.get("notify_zone_transitions", True),
        notify_goal_reached=row.get("notify_goal_reached", True),
        notify_eating_window_end=row.get("notify_eating_window_end", True),
        notify_fast_start_reminder=row.get("notify_fast_start_reminder", True),
        is_keto_adapted=row.get("is_keto_adapted", False),
        # Meal reminders
        meal_reminders_enabled=row.get("meal_reminders_enabled", True),
        lunch_reminder_hour=row.get("lunch_reminder_hour"),
        dinner_reminder_hour=row.get("dinner_reminder_hour"),
        extended_protocol_acknowledged=row.get("extended_protocol_acknowledged", False),
        safety_responses=row.get("safety_responses"),
        safety_screening_completed=row.get("safety_screening_completed", False),
        safety_warnings_acknowledged=row.get("safety_warnings_acknowledged"),
        has_medical_conditions=row.get("has_medical_conditions", False),
        fasting_onboarding_completed=row.get("fasting_onboarding_completed", False),
        onboarding_completed_at=row.get("onboarding_completed_at"),
        created_at=row.get("created_at"),
        updated_at=row.get("updated_at"),
    )


def calculate_completion_percentage(actual_minutes: int, goal_minutes: int) -> float:
    """Calculate completion percentage."""
    if goal_minutes <= 0:
        return 0.0
    return min(100.0, round((actual_minutes / goal_minutes) * 100, 2))


def get_encouraging_message(completion_percent: float, goal_hours: int) -> str:
    """Get an encouraging message based on completion."""
    if completion_percent >= 100:
        return f"Excellent! You completed your {goal_hours}h fast!"
    elif completion_percent >= 80:
        return f"Great job! You completed {completion_percent:.0f}% of your goal."
    elif completion_percent >= 50:
        return f"Good effort! You fasted for {completion_percent:.0f}% of your goal."
    else:
        return f"No problem! Every fast counts. You made progress today."


async def update_streak(user_id: str, completed_goal: bool, completion_percentage: float, user_tz: str = "UTC") -> dict:
    """Update user's fasting streak after completing a fast."""
    db = get_supabase_db()
    today = date.fromisoformat(get_user_today(user_tz))

    # Get or create streak record
    result = db.client.table("fasting_streaks").select("*").eq("user_id", user_id).execute()

    streak_data = result.data[0] if result.data else None

    # Determine if streak continues (>= 80% completion counts)
    streak_maintained = completion_percentage >= 80

    if streak_data:
        last_fast_date = streak_data.get("last_fast_date")
        current_streak = streak_data.get("current_streak", 0)
        longest_streak = streak_data.get("longest_streak", 0)
        total_fasts = streak_data.get("total_fasts_completed", 0)
        total_hours = streak_data.get("total_fasting_hours", 0)

        # Check if this is a new day or same day
        if last_fast_date:
            last_date = datetime.fromisoformat(last_fast_date).date() if isinstance(last_fast_date, str) else last_fast_date
            days_diff = (today - last_date).days

            if days_diff == 0:
                # Same day, just increment totals
                pass
            elif days_diff == 1:
                # Consecutive day, streak continues
                if streak_maintained:
                    current_streak += 1
            else:
                # Streak broken
                current_streak = 1 if streak_maintained else 0
        else:
            current_streak = 1 if streak_maintained else 0

        # Update longest streak
        longest_streak = max(longest_streak, current_streak)

        # Update record
        update_data = {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "total_fasts_completed": total_fasts + 1,
            "last_fast_date": today.isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }

        db.client.table("fasting_streaks").update(update_data).eq("user_id", user_id).execute()

        return {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "streak_maintained": streak_maintained,
        }
    else:
        # Create new streak record
        new_streak = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "current_streak": 1 if streak_maintained else 0,
            "longest_streak": 1 if streak_maintained else 0,
            "total_fasts_completed": 1,
            "total_fasting_hours": 0,
            "last_fast_date": today.isoformat(),
            "streak_start_date": today.isoformat() if streak_maintained else None,
            "fasts_this_week": 1,
            "week_start_date": (today - timedelta(days=today.weekday())).isoformat(),
            "created_at": datetime.utcnow().isoformat(),
        }

        db.client.table("fasting_streaks").insert(new_streak).execute()

        return {
            "current_streak": new_streak["current_streak"],
            "longest_streak": new_streak["longest_streak"],
            "streak_maintained": streak_maintained,
        }


# ==================== Fasting Records Endpoints ====================

@router.post("/start", response_model=FastingRecordResponse)
async def start_fast(data: StartFastRequest, current_user: dict = Depends(get_current_user)):
    """
    Start a new fast.

    Protocol options:
    - TRE (Time-Restricted Eating): '12:12', '14:10', '16:8', '18:6', '20:4', 'OMAD'
    - Modified: '5:2', 'ADF' (Alternate Day Fasting)
    - Extended: '24h', '36h', '48h'
    - Custom: Any duration
    """
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Starting fast for user {data.user_id} with protocol {data.protocol}")

    try:
        db = get_supabase_db()

        # Check for existing active fast
        existing = db.client.table("fasting_records").select("id").eq(
            "user_id", data.user_id
        ).eq("status", "active").execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="You already have an active fast. End it before starting a new one."
            )

        # Determine start time (custom or now)
        start_time = data.started_at if data.started_at else datetime.utcnow().isoformat()

        # Create new fast record
        fast_data = {
            "id": str(uuid.uuid4()),
            "user_id": data.user_id,
            "start_time": start_time,
            "goal_duration_minutes": data.goal_duration_minutes,
            "protocol": data.protocol,
            "protocol_type": data.protocol_type,
            "status": "active",
            "completed_goal": False,
            "zones_reached": [],
            "mood_before": data.mood_before,
            "notes": data.notes,
            "created_at": datetime.utcnow().isoformat(),
        }

        result = db.client.table("fasting_records").insert(fast_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create fasting record")

        # Log activity
        await log_user_activity(
            user_id=data.user_id,
            action="fast_started",
            endpoint="/api/v1/fasting/start",
            message=f"Started {data.protocol} fast ({data.goal_duration_minutes // 60}h goal)",
            metadata={
                "protocol": data.protocol,
                "goal_hours": data.goal_duration_minutes // 60,
            },
            status_code=200
        )

        return row_to_fasting_record(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error starting fast: {e}", exc_info=True)
        await log_user_error(
            user_id=data.user_id,
            action="fast_started",
            error=e,
            endpoint="/api/v1/fasting/start",
            status_code=500
        )
        raise safe_internal_error(e, "start_fast")


@router.post("/{fast_id}/end", response_model=FastEndResultResponse)
async def end_fast(fast_id: str, data: EndFastRequest, http_request: Request, current_user: dict = Depends(get_current_user)):
    """End an active fast and calculate results."""
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Ending fast {fast_id} for user {data.user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, data.user_id)

        # Get the fast record
        result = db.client.table("fasting_records").select("*").eq(
            "id", fast_id
        ).eq("user_id", data.user_id).eq("status", "active").execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Active fast not found")

        fast = result.data[0]

        # Calculate duration - ensure both datetimes are timezone-aware
        start_time = datetime.fromisoformat(fast["start_time"].replace("Z", "+00:00"))
        end_time = datetime.now(start_time.tzinfo)  # Use same timezone as start_time
        actual_minutes = int((end_time - start_time).total_seconds() / 60)
        goal_minutes = fast["goal_duration_minutes"]

        # Calculate completion
        completion_percent = calculate_completion_percentage(actual_minutes, goal_minutes)
        completed_goal = completion_percent >= 100

        # Update the record
        update_data = {
            "end_time": end_time.isoformat(),
            "actual_duration_minutes": actual_minutes,
            "status": "completed",
            "completed_goal": completed_goal,
            "completion_percentage": completion_percent,
            "notes": data.notes or fast.get("notes"),
            "mood_after": data.mood_after,
            "energy_level": data.energy_level,
            "updated_at": end_time.isoformat(),  # Use same timezone-aware datetime
        }

        db.client.table("fasting_records").update(update_data).eq("id", fast_id).execute()

        # Update streak
        streak_info = await update_streak(data.user_id, completed_goal, completion_percent, user_tz)

        # Get updated record
        updated = db.client.table("fasting_records").select("*").eq("id", fast_id).execute()
        record = row_to_fasting_record(updated.data[0])

        # Log activity
        await log_user_activity(
            user_id=data.user_id,
            action="fast_ended",
            endpoint=f"/api/v1/fasting/{fast_id}/end",
            message=f"Completed {actual_minutes // 60}h {actual_minutes % 60}m fast ({completion_percent:.0f}%)",
            metadata={
                "fast_id": fast_id,
                "actual_hours": actual_minutes / 60,
                "completion_percent": completion_percent,
            },
            status_code=200
        )

        return FastEndResultResponse(
            record=record,
            actual_minutes=actual_minutes,
            goal_minutes=goal_minutes,
            completion_percent=completion_percent,
            streak_maintained=streak_info["streak_maintained"],
            message=get_encouraging_message(completion_percent, goal_minutes // 60),
            streak_info=streak_info,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error ending fast: {e}", exc_info=True)
        await log_user_error(
            user_id=data.user_id,
            action="fast_ended",
            error=e,
            endpoint=f"/api/v1/fasting/{fast_id}/end",
            status_code=500
        )
        raise safe_internal_error(e, "end_fast")


@router.post("/{fast_id}/cancel")
async def cancel_fast(fast_id: str, data: CancelFastRequest, current_user: dict = Depends(get_current_user)):
    """Cancel an active fast without credit."""
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Cancelling fast {fast_id} for user {data.user_id}")

    try:
        db = get_supabase_db()

        # Update status to cancelled
        result = db.client.table("fasting_records").update({
            "status": "cancelled",
            "end_time": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }).eq("id", fast_id).eq("user_id", data.user_id).eq("status", "active").execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Active fast not found")

        return {"status": "cancelled", "fast_id": fast_id}

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "cancel_fast")


@router.get("/active/{user_id}", response_model=Optional[FastingRecordResponse])
async def get_active_fast(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get the current active fast for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting active fast for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("fasting_records").select("*").eq(
            "user_id", user_id
        ).eq("status", "active").execute()

        if not result.data:
            return None

        return row_to_fasting_record(result.data[0])

    except Exception as e:
        raise safe_internal_error(e, "get_active_fast")


@router.get("/history/{user_id}", response_model=List[FastingRecordResponse])
async def get_fasting_history(
    user_id: str,
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    from_date: Optional[str] = Query(None, description="Start date YYYY-MM-DD"),
    to_date: Optional[str] = Query(None, description="End date YYYY-MM-DD"),
):
    """Get fasting history for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting history for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("fasting_records").select("*").eq(
            "user_id", user_id
        ).neq("status", "active")

        if from_date:
            query = query.gte("start_time", from_date)
        if to_date:
            query = query.lte("start_time", to_date + "T23:59:59")

        result = query.order("start_time", desc=True).range(offset, offset + limit - 1).execute()

        return [row_to_fasting_record(row) for row in (result.data or [])]

    except Exception as e:
        raise safe_internal_error(e, "get_fasting_history")


@router.put("/{fast_id}", response_model=FastingRecordResponse)
async def update_fast_record(fast_id: str, data: UpdateFastRequest, current_user: dict = Depends(get_current_user)):
    """Update a fasting record (notes, mood, etc.)."""
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating fast {fast_id}")

    try:
        db = get_supabase_db()

        update_data = {"updated_at": datetime.utcnow().isoformat()}
        if data.notes is not None:
            update_data["notes"] = data.notes
        if data.mood_before is not None:
            update_data["mood_before"] = data.mood_before
        if data.mood_after is not None:
            update_data["mood_after"] = data.mood_after
        if data.energy_level is not None:
            update_data["energy_level"] = data.energy_level

        result = db.client.table("fasting_records").update(update_data).eq(
            "id", fast_id
        ).eq("user_id", data.user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Fast record not found")

        return row_to_fasting_record(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "update_fast_record")


# ==================== Fasting Preferences Endpoints ====================

@router.get("/preferences/{user_id}", response_model=Optional[FastingPreferencesResponse])
async def get_preferences(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get user's fasting preferences."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting preferences for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("fasting_preferences").select("*").eq(
            "user_id", user_id
        ).execute()

        if not result.data:
            return None

        return row_to_preferences(result.data[0])

    except Exception as e:
        raise safe_internal_error(e, "get_preferences")


@router.put("/preferences/{user_id}", response_model=FastingPreferencesResponse)
async def update_preferences(user_id: str, data: FastingPreferencesRequest, current_user: dict = Depends(get_current_user)):
    """Update fasting preferences (upsert)."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating fasting preferences for user {user_id}")

    try:
        db = get_supabase_db()

        prefs_data = {
            "user_id": user_id,
            "default_protocol": data.default_protocol,
            "custom_fasting_hours": data.custom_fasting_hours,
            "custom_eating_hours": data.custom_eating_hours,
            "typical_fast_start_hour": data.typical_fast_start_hour,
            "typical_eating_start_hour": data.typical_eating_start_hour,
            "fasting_days": data.fasting_days,
            "notifications_enabled": data.notifications_enabled,
            "notify_zone_transitions": data.notify_zone_transitions,
            "notify_goal_reached": data.notify_goal_reached,
            "notify_eating_window_end": data.notify_eating_window_end,
            "is_keto_adapted": data.is_keto_adapted,
            "updated_at": datetime.utcnow().isoformat(),
        }

        # Check if exists
        existing = db.client.table("fasting_preferences").select("id").eq(
            "user_id", user_id
        ).execute()

        if existing.data:
            # Update
            result = db.client.table("fasting_preferences").update(prefs_data).eq(
                "user_id", user_id
            ).execute()
        else:
            # Insert
            prefs_data["id"] = str(uuid.uuid4())
            prefs_data["created_at"] = datetime.utcnow().isoformat()
            result = db.client.table("fasting_preferences").insert(prefs_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save preferences")

        return row_to_preferences(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "update_preferences")


@router.post("/onboarding/complete")
async def complete_onboarding(data: CompleteOnboardingRequest, current_user: dict = Depends(get_current_user)):
    """Complete fasting onboarding."""
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Completing fasting onboarding for user {data.user_id}")

    try:
        db = get_supabase_db()

        # Get or create preferences
        existing = db.client.table("fasting_preferences").select("id").eq(
            "user_id", data.user_id
        ).execute()

        prefs_data = {
            "user_id": data.user_id,
            **data.preferences,
            "safety_screening_completed": True,
            "safety_warnings_acknowledged": data.safety_acknowledgments,
            "fasting_onboarding_completed": True,
            "onboarding_completed_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }

        if existing.data:
            db.client.table("fasting_preferences").update(prefs_data).eq(
                "user_id", data.user_id
            ).execute()
        else:
            prefs_data["id"] = str(uuid.uuid4())
            prefs_data["created_at"] = datetime.utcnow().isoformat()
            db.client.table("fasting_preferences").insert(prefs_data).execute()

        # Log activity
        await log_user_activity(
            user_id=data.user_id,
            action="fasting_onboarding_completed",
            endpoint="/api/v1/fasting/onboarding/complete",
            message="Completed fasting onboarding",
            metadata={"protocol": data.preferences.get("default_protocol")},
            status_code=200
        )

        return {"status": "completed", "user_id": data.user_id}

    except Exception as e:
        raise safe_internal_error(e, "complete_onboarding")


# ==================== Streak & Stats Endpoints ====================


# Include secondary endpoints
router.include_router(_endpoints_router)
