"""
Smart Scheduling API endpoints.

Handles missed workout detection, rescheduling, skipping, and AI suggestions
for optimal workout scheduling.

ENDPOINTS:
- GET  /api/v1/scheduling/missed - Get missed workouts from past 7 days
- POST /api/v1/scheduling/reschedule - Reschedule a missed workout
- POST /api/v1/scheduling/skip - Skip a workout with optional reason
- GET  /api/v1/scheduling/suggestions - Get AI suggestions for rescheduling
- GET  /api/v1/scheduling/skip-reasons - Get available skip reason categories
- POST /api/v1/scheduling/detect-missed - Trigger missed workout detection
- GET  /api/v1/scheduling/preferences - Get user scheduling preferences
- PUT  /api/v1/scheduling/preferences - Update user scheduling preferences
- GET  /api/v1/scheduling/history - Get scheduling action history
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime, date, timedelta
from pydantic import BaseModel, Field
import json

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Request/Response Models
# ============================================

class MissedWorkout(BaseModel):
    """A workout that was missed (not completed by scheduled date)."""
    id: str
    name: str
    type: str
    difficulty: str
    scheduled_date: datetime
    original_scheduled_date: Optional[datetime] = None
    duration_minutes: int
    days_missed: int
    can_reschedule: bool
    reschedule_count: int = 0
    exercises_count: int = 0


class MissedWorkoutsResponse(BaseModel):
    """Response containing missed workouts."""
    missed_workouts: List[MissedWorkout]
    total_count: int
    oldest_date: Optional[str] = None
    newest_date: Optional[str] = None


class RescheduleRequest(BaseModel):
    """Request to reschedule a missed workout."""
    workout_id: str = Field(..., description="ID of the workout to reschedule")
    new_date: str = Field(..., description="New date in YYYY-MM-DD format")
    swap_with_workout_id: Optional[str] = Field(
        None,
        description="If provided, swap dates with this workout"
    )
    reason: Optional[str] = Field(
        None,
        max_length=500,
        description="Reason for rescheduling"
    )


class RescheduleResponse(BaseModel):
    """Response after rescheduling a workout."""
    success: bool
    message: str
    workout_id: str
    new_date: str
    swapped_with: Optional[str] = None
    swapped_workout_name: Optional[str] = None


class SkipRequest(BaseModel):
    """Request to skip a workout."""
    workout_id: str = Field(..., description="ID of the workout to skip")
    reason_category: Optional[str] = Field(
        None,
        description="Category of skip reason (too_busy, feeling_unwell, need_rest, travel, injury, other)"
    )
    reason_text: Optional[str] = Field(
        None,
        max_length=500,
        description="Custom reason text"
    )


class SkipResponse(BaseModel):
    """Response after skipping a workout."""
    success: bool
    message: str
    workout_id: str


class SkipReasonCategory(BaseModel):
    """A skip reason category."""
    id: str
    display_name: str
    emoji: Optional[str] = None


class SchedulingSuggestion(BaseModel):
    """AI-generated scheduling suggestion."""
    suggestion_type: str  # 'reschedule_today', 'reschedule_tomorrow', 'swap', 'skip'
    title: str
    description: str
    recommended_date: Optional[str] = None
    swap_workout_id: Optional[str] = None
    swap_workout_name: Optional[str] = None
    confidence_score: float = 0.8
    reason: str


class SchedulingSuggestionsResponse(BaseModel):
    """Response with scheduling suggestions."""
    workout_id: str
    workout_name: str
    suggestions: List[SchedulingSuggestion]
    ai_insight: Optional[str] = None


class SchedulingPreferences(BaseModel):
    """User scheduling preferences."""
    auto_detect_missed: bool = True
    missed_notification_enabled: bool = True
    max_reschedule_days: int = 3
    allow_same_day_swap: bool = True
    prefer_swap_similar_type: bool = True
    track_skip_patterns: bool = True


class SchedulingHistoryItem(BaseModel):
    """A scheduling history entry."""
    id: str
    workout_id: str
    workout_name: Optional[str] = None
    action_type: str  # reschedule, skip, restore, auto_missed
    original_date: str
    new_date: Optional[str] = None
    reason: Optional[str] = None
    reason_category: Optional[str] = None
    created_at: datetime


class SchedulingHistoryResponse(BaseModel):
    """Response with scheduling history."""
    history: List[SchedulingHistoryItem]
    total_count: int
    skip_count: int
    reschedule_count: int


# ============================================
# Endpoints
# ============================================

@router.get("/missed", response_model=MissedWorkoutsResponse)
async def get_missed_workouts(
    user_id: str = Query(..., description="User ID"),
    days_back: int = Query(7, ge=1, le=30, description="Days to look back"),
    include_scheduled: bool = Query(True, description="Include past scheduled workouts not yet marked missed")
):
    """
    Get list of missed workouts from the past N days.

    Returns workouts that:
    - Have status 'missed' OR
    - Have scheduled_date in the past and status 'scheduled' (not yet detected as missed)

    Also triggers missed workout detection for the user.
    """
    logger.info(f"Getting missed workouts for user {user_id}, days_back={days_back}")

    try:
        db = get_supabase_db()

        # First, detect and mark any newly missed workouts
        try:
            db.client.rpc('mark_missed_workouts', {'p_user_id': user_id}).execute()
        except Exception as e:
            logger.warning(f"Could not run mark_missed_workouts function: {e}")
            # Function might not exist yet, continue without it

        # Calculate date range
        cutoff_date = (datetime.now() - timedelta(days=days_back)).date()
        today = datetime.now().date()

        # Build query for missed workouts
        query = db.client.table("workouts").select(
            "id, name, type, difficulty, scheduled_date, duration_minutes, "
            "original_scheduled_date, reschedule_count, status, exercises_json"
        ).eq("user_id", user_id).eq("is_completed", False)

        # Filter by status and date
        if include_scheduled:
            # Include both 'missed' status and past 'scheduled' workouts
            query = query.or_(
                f"status.eq.missed,and(status.eq.scheduled,scheduled_date.lt.{today.isoformat()})"
            )
        else:
            query = query.eq("status", "missed")

        # Filter by date range
        query = query.gte("scheduled_date", cutoff_date.isoformat())
        query = query.lt("scheduled_date", today.isoformat())

        # Order by most recent first
        query = query.order("scheduled_date", desc=True)

        response = query.execute()

        missed_workouts = []
        for row in response.data or []:
            scheduled_date = datetime.fromisoformat(row["scheduled_date"].replace("Z", "+00:00"))
            days_missed = (today - scheduled_date.date()).days

            # Count exercises
            exercises_json = row.get("exercises_json", [])
            if isinstance(exercises_json, str):
                try:
                    exercises_json = json.loads(exercises_json)
                except:
                    exercises_json = []
            exercises_count = len(exercises_json) if isinstance(exercises_json, list) else 0

            missed_workouts.append(MissedWorkout(
                id=str(row["id"]),
                name=row["name"],
                type=row["type"],
                difficulty=row["difficulty"],
                scheduled_date=scheduled_date,
                original_scheduled_date=datetime.fromisoformat(
                    row["original_scheduled_date"]
                ) if row.get("original_scheduled_date") else None,
                duration_minutes=row.get("duration_minutes", 45),
                days_missed=days_missed,
                can_reschedule=days_missed <= 7,
                reschedule_count=row.get("reschedule_count", 0),
                exercises_count=exercises_count,
            ))

        # Calculate summary
        oldest_date = min(w.scheduled_date for w in missed_workouts).date().isoformat() if missed_workouts else None
        newest_date = max(w.scheduled_date for w in missed_workouts).date().isoformat() if missed_workouts else None

        logger.info(f"Found {len(missed_workouts)} missed workouts for user {user_id}")

        return MissedWorkoutsResponse(
            missed_workouts=missed_workouts,
            total_count=len(missed_workouts),
            oldest_date=oldest_date,
            newest_date=newest_date,
        )

    except Exception as e:
        logger.error(f"Error getting missed workouts: {e}")
        log_user_error(user_id, "get_missed_workouts", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reschedule", response_model=RescheduleResponse)
async def reschedule_workout(request: RescheduleRequest):
    """
    Reschedule a missed or scheduled workout to a new date.

    Optionally swap with another workout if `swap_with_workout_id` is provided.
    """
    logger.info(f"Rescheduling workout {request.workout_id} to {request.new_date}")

    try:
        db = get_supabase_db()

        # Validate new date
        try:
            new_date = datetime.strptime(request.new_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

        # New date must be today or in the future
        if new_date < date.today():
            raise HTTPException(status_code=400, detail="Cannot reschedule to a past date")

        # Get the workout
        workout_response = db.client.table("workouts").select("*").eq(
            "id", request.workout_id
        ).single().execute()

        if not workout_response.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout = workout_response.data

        # Check if completed
        if workout.get("is_completed"):
            raise HTTPException(status_code=400, detail="Cannot reschedule a completed workout")

        user_id = workout["user_id"]
        original_date = datetime.fromisoformat(
            workout["scheduled_date"].replace("Z", "+00:00")
        ).date()

        swapped_workout_name = None

        # If swapping with another workout
        if request.swap_with_workout_id:
            swap_response = db.client.table("workouts").select("*").eq(
                "id", request.swap_with_workout_id
            ).single().execute()

            if not swap_response.data:
                raise HTTPException(status_code=404, detail="Swap workout not found")

            swap_workout = swap_response.data

            if swap_workout.get("is_completed"):
                raise HTTPException(status_code=400, detail="Cannot swap with a completed workout")

            swapped_workout_name = swap_workout["name"]

            # Swap the dates
            db.client.table("workouts").update({
                "scheduled_date": f"{original_date}T00:00:00Z",
                "last_modified_at": datetime.utcnow().isoformat(),
                "last_modified_method": "reschedule_swap",
            }).eq("id", request.swap_with_workout_id).execute()

        # Update the main workout
        update_data = {
            "scheduled_date": f"{new_date}T00:00:00Z",
            "status": "rescheduled",
            "reschedule_count": workout.get("reschedule_count", 0) + 1,
            "last_modified_at": datetime.utcnow().isoformat(),
            "last_modified_method": "user_reschedule",
        }

        # Store original date if first reschedule
        if not workout.get("original_scheduled_date"):
            update_data["original_scheduled_date"] = original_date.isoformat()

        db.client.table("workouts").update(update_data).eq(
            "id", request.workout_id
        ).execute()

        # Log the action
        history_record = {
            "user_id": user_id,
            "workout_id": request.workout_id,
            "action_type": "reschedule",
            "original_date": original_date.isoformat(),
            "new_date": new_date.isoformat(),
            "reason": request.reason,
            "swapped_workout_id": request.swap_with_workout_id,
            "swapped_workout_name": swapped_workout_name,
            "day_of_week": original_date.weekday(),
            "week_number": original_date.isocalendar()[1],
        }

        try:
            db.client.table("workout_scheduling_history").insert(history_record).execute()
        except Exception as e:
            logger.warning(f"Could not log scheduling history: {e}")

        # Log activity
        log_user_activity(
            user_id,
            "workout_rescheduled",
            {"workout_id": request.workout_id, "new_date": new_date.isoformat()}
        )

        logger.info(f"Successfully rescheduled workout {request.workout_id} to {new_date}")

        return RescheduleResponse(
            success=True,
            message=f"Workout rescheduled to {new_date.strftime('%A, %B %d')}",
            workout_id=request.workout_id,
            new_date=new_date.isoformat(),
            swapped_with=request.swap_with_workout_id,
            swapped_workout_name=swapped_workout_name,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error rescheduling workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/skip", response_model=SkipResponse)
async def skip_workout(request: SkipRequest):
    """
    Mark a workout as skipped with an optional reason.

    Skipped workouts are not deleted - they're marked for tracking patterns.
    """
    logger.info(f"Skipping workout {request.workout_id}")

    try:
        db = get_supabase_db()

        # Get the workout
        workout_response = db.client.table("workouts").select("*").eq(
            "id", request.workout_id
        ).single().execute()

        if not workout_response.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout = workout_response.data

        # Check if completed
        if workout.get("is_completed"):
            raise HTTPException(status_code=400, detail="Cannot skip a completed workout")

        user_id = workout["user_id"]
        original_date = datetime.fromisoformat(
            workout["scheduled_date"].replace("Z", "+00:00")
        ).date()

        # Build skip reason
        skip_reason = request.reason_text or request.reason_category

        # Update the workout
        db.client.table("workouts").update({
            "status": "skipped",
            "skip_reason": skip_reason,
            "last_modified_at": datetime.utcnow().isoformat(),
            "last_modified_method": "user_skip",
        }).eq("id", request.workout_id).execute()

        # Log the action
        history_record = {
            "user_id": user_id,
            "workout_id": request.workout_id,
            "action_type": "skip",
            "original_date": original_date.isoformat(),
            "reason": request.reason_text,
            "reason_category": request.reason_category,
            "day_of_week": original_date.weekday(),
            "week_number": original_date.isocalendar()[1],
        }

        try:
            db.client.table("workout_scheduling_history").insert(history_record).execute()
        except Exception as e:
            logger.warning(f"Could not log scheduling history: {e}")

        # Log activity
        log_user_activity(
            user_id,
            "workout_skipped",
            {"workout_id": request.workout_id, "reason_category": request.reason_category}
        )

        logger.info(f"Successfully skipped workout {request.workout_id}")

        return SkipResponse(
            success=True,
            message="Workout skipped",
            workout_id=request.workout_id,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error skipping workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/suggestions", response_model=SchedulingSuggestionsResponse)
async def get_scheduling_suggestions(
    workout_id: str = Query(..., description="ID of the missed workout"),
    user_id: str = Query(..., description="User ID"),
):
    """
    Get AI-generated suggestions for rescheduling a missed workout.

    Analyzes user patterns, upcoming schedule, and workout type to suggest:
    - Best day to reschedule
    - Whether to swap with an upcoming workout
    - Whether to skip (if too many similar workouts coming up)
    """
    logger.info(f"Getting scheduling suggestions for workout {workout_id}")

    try:
        db = get_supabase_db()

        # Get the missed workout
        workout_response = db.client.table("workouts").select("*").eq(
            "id", workout_id
        ).single().execute()

        if not workout_response.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        missed_workout = workout_response.data
        workout_name = missed_workout["name"]
        workout_type = missed_workout["type"]

        suggestions = []

        # Get upcoming workouts for this user (next 7 days)
        today = date.today()
        week_ahead = today + timedelta(days=7)

        upcoming_response = db.client.table("workouts").select(
            "id, name, type, difficulty, scheduled_date"
        ).eq("user_id", user_id).eq("is_completed", False).eq(
            "status", "scheduled"
        ).gte("scheduled_date", today.isoformat()).lte(
            "scheduled_date", week_ahead.isoformat()
        ).order("scheduled_date").execute()

        upcoming_workouts = upcoming_response.data or []

        # Get today's workout if exists
        todays_workout = None
        for w in upcoming_workouts:
            w_date = datetime.fromisoformat(w["scheduled_date"].replace("Z", "+00:00")).date()
            if w_date == today:
                todays_workout = w
                break

        # Suggestion 1: Do it today (if no workout scheduled today)
        if not todays_workout:
            suggestions.append(SchedulingSuggestion(
                suggestion_type="reschedule_today",
                title="Do it today",
                description=f"Get your {workout_type} workout done today",
                recommended_date=today.isoformat(),
                confidence_score=0.9,
                reason="No workout scheduled for today - great opportunity to catch up!"
            ))
        else:
            # Suggestion: Swap with today's workout
            suggestions.append(SchedulingSuggestion(
                suggestion_type="swap",
                title=f"Swap with today's workout",
                description=f"Do {workout_name} today, move {todays_workout['name']} to another day",
                recommended_date=today.isoformat(),
                swap_workout_id=todays_workout["id"],
                swap_workout_name=todays_workout["name"],
                confidence_score=0.75,
                reason=f"You can do {workout_name} now and reschedule {todays_workout['name']}"
            ))

        # Suggestion 2: Tomorrow (if not too much workload)
        tomorrow = today + timedelta(days=1)
        tomorrows_workout = None
        for w in upcoming_workouts:
            w_date = datetime.fromisoformat(w["scheduled_date"].replace("Z", "+00:00")).date()
            if w_date == tomorrow:
                tomorrows_workout = w
                break

        if not tomorrows_workout:
            suggestions.append(SchedulingSuggestion(
                suggestion_type="reschedule_tomorrow",
                title="Reschedule to tomorrow",
                description=f"Add {workout_name} to tomorrow's schedule",
                recommended_date=tomorrow.isoformat(),
                confidence_score=0.85,
                reason="Tomorrow is free - a good day to catch up"
            ))

        # Suggestion 3: Find next available day
        next_free_day = None
        for days_ahead in range(2, 8):
            check_date = today + timedelta(days=days_ahead)
            has_workout = any(
                datetime.fromisoformat(w["scheduled_date"].replace("Z", "+00:00")).date() == check_date
                for w in upcoming_workouts
            )
            if not has_workout:
                next_free_day = check_date
                break

        if next_free_day:
            suggestions.append(SchedulingSuggestion(
                suggestion_type="reschedule_free_day",
                title=f"Reschedule to {next_free_day.strftime('%A')}",
                description=f"Your next free day for a {workout_type} workout",
                recommended_date=next_free_day.isoformat(),
                confidence_score=0.7,
                reason=f"{next_free_day.strftime('%A, %B %d')} has no scheduled workouts"
            ))

        # Suggestion 4: Skip (always offer as an option)
        suggestions.append(SchedulingSuggestion(
            suggestion_type="skip",
            title="Skip this workout",
            description="It's okay to skip sometimes. Your program will adapt.",
            confidence_score=0.5,
            reason="Sometimes rest is more important. Your body will thank you."
        ))

        # Build AI insight based on patterns
        ai_insight = None
        try:
            # Check skip patterns
            history_response = db.client.table("workout_scheduling_history").select(
                "action_type, reason_category"
            ).eq("user_id", user_id).order("created_at", desc=True).limit(20).execute()

            skip_count = sum(1 for h in (history_response.data or []) if h["action_type"] == "skip")
            if skip_count >= 3:
                ai_insight = (
                    f"I've noticed you've skipped {skip_count} workouts recently. "
                    "Consider reducing your workout frequency or choosing shorter sessions. "
                    "Consistency beats intensity!"
                )
            elif skip_count == 0:
                ai_insight = (
                    "Great job staying consistent! "
                    "Missing one workout won't affect your progress. "
                    "Choose what works best for your schedule."
                )
        except Exception as e:
            logger.warning(f"Could not analyze patterns: {e}")

        logger.info(f"Generated {len(suggestions)} suggestions for workout {workout_id}")

        return SchedulingSuggestionsResponse(
            workout_id=workout_id,
            workout_name=workout_name,
            suggestions=suggestions,
            ai_insight=ai_insight,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting scheduling suggestions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/skip-reasons", response_model=List[SkipReasonCategory])
async def get_skip_reasons():
    """
    Get available skip reason categories.
    """
    try:
        db = get_supabase_db()

        try:
            response = db.client.table("skip_reason_categories").select(
                "id, display_name, emoji"
            ).eq("is_active", True).order("sort_order").execute()

            return [
                SkipReasonCategory(
                    id=row["id"],
                    display_name=row["display_name"],
                    emoji=row.get("emoji"),
                )
                for row in response.data or []
            ]
        except Exception:
            # If table doesn't exist, return defaults
            return [
                SkipReasonCategory(id="too_busy", display_name="Too Busy", emoji="📅"),
                SkipReasonCategory(id="feeling_unwell", display_name="Feeling Unwell", emoji="🤒"),
                SkipReasonCategory(id="need_rest", display_name="Need Rest", emoji="😴"),
                SkipReasonCategory(id="travel", display_name="Traveling", emoji="✈️"),
                SkipReasonCategory(id="injury", display_name="Injury/Pain", emoji="🤕"),
                SkipReasonCategory(id="other", display_name="Other", emoji="💭"),
            ]

    except Exception as e:
        logger.error(f"Error getting skip reasons: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/detect-missed")
async def detect_missed_workouts(user_id: str = Query(..., description="User ID")):
    """
    Trigger missed workout detection for a user.

    Marks any past 'scheduled' workouts as 'missed'.
    Called on app launch or when viewing home screen.
    """
    logger.info(f"Detecting missed workouts for user {user_id}")

    try:
        db = get_supabase_db()
        today = date.today()

        # Find and mark missed workouts
        response = db.client.table("workouts").select("id").eq(
            "user_id", user_id
        ).eq("is_completed", False).eq("status", "scheduled").lt(
            "scheduled_date", today.isoformat()
        ).execute()

        missed_ids = [row["id"] for row in response.data or []]

        if missed_ids:
            db.client.table("workouts").update({
                "status": "missed",
                "last_modified_at": datetime.utcnow().isoformat(),
                "last_modified_method": "auto_missed",
            }).in_("id", missed_ids).execute()

            logger.info(f"Marked {len(missed_ids)} workouts as missed for user {user_id}")

        return {
            "success": True,
            "marked_missed": len(missed_ids),
            "workout_ids": missed_ids,
        }

    except Exception as e:
        logger.error(f"Error detecting missed workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/preferences", response_model=SchedulingPreferences)
async def get_scheduling_preferences(user_id: str = Query(..., description="User ID")):
    """
    Get user's scheduling preferences.
    """
    try:
        db = get_supabase_db()

        try:
            response = db.client.table("user_scheduling_preferences").select(
                "*"
            ).eq("user_id", user_id).single().execute()

            if response.data:
                return SchedulingPreferences(
                    auto_detect_missed=response.data.get("auto_detect_missed", True),
                    missed_notification_enabled=response.data.get("missed_notification_enabled", True),
                    max_reschedule_days=response.data.get("max_reschedule_days", 3),
                    allow_same_day_swap=response.data.get("allow_same_day_swap", True),
                    prefer_swap_similar_type=response.data.get("prefer_swap_similar_type", True),
                    track_skip_patterns=response.data.get("track_skip_patterns", True),
                )
        except Exception:
            pass

        # Return defaults if not found
        return SchedulingPreferences()

    except Exception as e:
        logger.error(f"Error getting scheduling preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/preferences", response_model=SchedulingPreferences)
async def update_scheduling_preferences(
    user_id: str = Query(..., description="User ID"),
    preferences: SchedulingPreferences = None,
):
    """
    Update user's scheduling preferences.
    """
    try:
        db = get_supabase_db()

        prefs_data = {
            "user_id": user_id,
            "auto_detect_missed": preferences.auto_detect_missed,
            "missed_notification_enabled": preferences.missed_notification_enabled,
            "max_reschedule_days": preferences.max_reschedule_days,
            "allow_same_day_swap": preferences.allow_same_day_swap,
            "prefer_swap_similar_type": preferences.prefer_swap_similar_type,
            "track_skip_patterns": preferences.track_skip_patterns,
            "updated_at": datetime.utcnow().isoformat(),
        }

        try:
            # Try upsert
            db.client.table("user_scheduling_preferences").upsert(
                prefs_data, on_conflict="user_id"
            ).execute()
        except Exception as e:
            logger.warning(f"Could not save preferences (table may not exist): {e}")

        return preferences

    except Exception as e:
        logger.error(f"Error updating scheduling preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/history", response_model=SchedulingHistoryResponse)
async def get_scheduling_history(
    user_id: str = Query(..., description="User ID"),
    limit: int = Query(20, ge=1, le=100, description="Number of records to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
):
    """
    Get scheduling action history for a user.
    """
    try:
        db = get_supabase_db()

        try:
            # Get history with workout names
            response = db.client.table("workout_scheduling_history").select(
                "*, workouts(name)"
            ).eq("user_id", user_id).order(
                "created_at", desc=True
            ).range(offset, offset + limit - 1).execute()

            history = []
            skip_count = 0
            reschedule_count = 0

            for row in response.data or []:
                workout_name = None
                if isinstance(row.get("workouts"), dict):
                    workout_name = row["workouts"].get("name")

                history.append(SchedulingHistoryItem(
                    id=str(row["id"]),
                    workout_id=str(row["workout_id"]),
                    workout_name=workout_name,
                    action_type=row["action_type"],
                    original_date=row["original_date"],
                    new_date=row.get("new_date"),
                    reason=row.get("reason"),
                    reason_category=row.get("reason_category"),
                    created_at=datetime.fromisoformat(
                        row["created_at"].replace("Z", "+00:00")
                    ),
                ))

                if row["action_type"] == "skip":
                    skip_count += 1
                elif row["action_type"] == "reschedule":
                    reschedule_count += 1

            # Get total count
            count_response = db.client.table("workout_scheduling_history").select(
                "id", count="exact"
            ).eq("user_id", user_id).execute()

            total_count = count_response.count or len(history)

            return SchedulingHistoryResponse(
                history=history,
                total_count=total_count,
                skip_count=skip_count,
                reschedule_count=reschedule_count,
            )

        except Exception as e:
            logger.warning(f"Could not get history (table may not exist): {e}")
            return SchedulingHistoryResponse(
                history=[],
                total_count=0,
                skip_count=0,
                reschedule_count=0,
            )

    except Exception as e:
        logger.error(f"Error getting scheduling history: {e}")
        raise HTTPException(status_code=500, detail=str(e))
