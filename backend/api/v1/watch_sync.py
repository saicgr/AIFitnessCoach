"""
WearOS Watch Sync API Router.

Provides endpoints for batch syncing data from WearOS watch to backend.
Supports workout logs, nutrition, fasting, and activity data with Gemini integration.
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.gemini_service import get_gemini_service
from services.user_context_service import UserContextService

router = APIRouter(prefix="/watch-sync", tags=["Watch Sync"])
logger = get_logger(__name__)


# ==================== Request Models ====================

class SetLogRequest(BaseModel):
    """Workout set logged on watch."""
    session_id: str
    exercise_id: str
    exercise_name: str
    set_number: int = Field(ge=1)
    actual_reps: int = Field(ge=0)
    weight_kg: Optional[float] = Field(None, ge=0)
    rpe: Optional[int] = Field(None, ge=1, le=10)
    rir: Optional[int] = Field(None, ge=0, le=5)
    logged_at: int  # Unix timestamp ms


class WorkoutCompletionRequest(BaseModel):
    """Workout completed on watch."""
    session_id: str
    workout_id: Optional[str] = None
    started_at: int  # Unix timestamp ms
    ended_at: int  # Unix timestamp ms
    total_sets: int = Field(ge=0)
    total_reps: int = Field(ge=0)
    total_volume_kg: Optional[float] = Field(None, ge=0)
    avg_heart_rate: Optional[int] = Field(None, ge=30, le=250)
    max_heart_rate: Optional[int] = Field(None, ge=30, le=250)
    calories_burned: Optional[int] = Field(None, ge=0)


class FoodLogRequest(BaseModel):
    """Food logged on watch (voice input)."""
    input_type: str = "VOICE"  # VOICE, MANUAL
    raw_input: str  # Original voice/text input
    food_name: Optional[str] = None  # If pre-parsed on watch
    calories: Optional[int] = Field(None, ge=0)
    protein_g: Optional[float] = Field(None, ge=0)
    carbs_g: Optional[float] = Field(None, ge=0)
    fat_g: Optional[float] = Field(None, ge=0)
    meal_type: str = "SNACK"  # BREAKFAST, LUNCH, DINNER, SNACK
    logged_at: int  # Unix timestamp ms


class FastingEventRequest(BaseModel):
    """Fasting event from watch."""
    session_id: Optional[str] = None
    event_type: str  # START, END, PAUSE, RESUME
    protocol: str = "16:8"  # 16:8, 18:6, 20:4, OMAD, 5:2
    target_duration_minutes: int = Field(ge=0)
    elapsed_minutes: int = Field(ge=0)
    event_at: int  # Unix timestamp ms


class ActivitySyncRequest(BaseModel):
    """Activity/health data from watch."""
    date: str  # YYYY-MM-DD
    steps: int = Field(ge=0)
    calories_burned: int = Field(ge=0)
    distance_meters: float = Field(ge=0)
    active_minutes: int = Field(ge=0)
    heart_rate_samples: Optional[List[dict]] = None  # [{timestamp, bpm}]


class WatchSyncRequest(BaseModel):
    """Batch sync request from WearOS watch."""
    user_id: str
    device_source: str = "watch"  # Always "watch" for WearOS
    device_id: Optional[str] = None
    workout_sets: Optional[List[SetLogRequest]] = None
    workout_completions: Optional[List[WorkoutCompletionRequest]] = None
    food_logs: Optional[List[FoodLogRequest]] = None
    fasting_events: Optional[List[FastingEventRequest]] = None
    activity: Optional[ActivitySyncRequest] = None


# ==================== Response Models ====================

class WatchSyncResponse(BaseModel):
    """Response for batch sync."""
    success: bool
    synced_items: int
    failed_items: int
    errors: Optional[List[str]] = None
    sync_id: Optional[str] = None


class ActivityGoalsResponse(BaseModel):
    """User's activity goals for watch display."""
    steps_goal: int = 10000
    active_minutes_goal: int = 30
    calories_burned_goal: int = 500
    water_ml_goal: int = 2000


# ==================== Endpoints ====================

@router.post("/sync", response_model=WatchSyncResponse)
async def sync_watch_data(request: WatchSyncRequest):
    """
    Batch sync all pending data from WearOS watch.

    Processes workout sets, completions, food logs (via Gemini),
    fasting events, and activity data in a single request.
    """
    logger.info(f"Watch sync request from user {request.user_id}")

    db = get_supabase_db()
    synced = 0
    failed = 0
    errors = []

    try:
        # Log sync event
        sync_record = db.table("wearos_sync_events").insert({
            "user_id": request.user_id,
            "device_id": request.device_id,
            "sync_type": "bulk",
            "synced_at": datetime.utcnow().isoformat()
        }).execute()
        sync_id = sync_record.data[0]["id"] if sync_record.data else None
    except Exception as e:
        logger.warning(f"Failed to create sync record: {e}")
        sync_id = None

    # Process workout sets
    if request.workout_sets:
        for set_log in request.workout_sets:
            try:
                await _log_workout_set(db, request.user_id, set_log, request.device_source)
                synced += 1
            except Exception as e:
                failed += 1
                errors.append(f"Set log failed: {str(e)}")
                logger.error(f"Failed to log set: {e}")

    # Process workout completions
    if request.workout_completions:
        for completion in request.workout_completions:
            try:
                await _complete_workout(db, request.user_id, completion, request.device_source)
                synced += 1
            except Exception as e:
                failed += 1
                errors.append(f"Workout completion failed: {str(e)}")
                logger.error(f"Failed to complete workout: {e}")

    # Process food logs with Gemini
    if request.food_logs:
        for food_log in request.food_logs:
            try:
                await _log_food_with_gemini(db, request.user_id, food_log, request.device_source)
                synced += 1
            except Exception as e:
                failed += 1
                errors.append(f"Food log failed: {str(e)}")
                logger.error(f"Failed to log food: {e}")

    # Process fasting events
    if request.fasting_events:
        for fasting_event in request.fasting_events:
            try:
                await _log_fasting_event(db, request.user_id, fasting_event, request.device_source)
                synced += 1
            except Exception as e:
                failed += 1
                errors.append(f"Fasting event failed: {str(e)}")
                logger.error(f"Failed to log fasting event: {e}")

    # Process activity data
    if request.activity:
        try:
            await _sync_activity(db, request.user_id, request.activity, request.device_source)
            synced += 1
        except Exception as e:
            failed += 1
            errors.append(f"Activity sync failed: {str(e)}")
            logger.error(f"Failed to sync activity: {e}")

    # Update sync record with results
    if sync_id:
        try:
            db.table("wearos_sync_events").update({
                "items_synced": synced,
                "items_failed": failed,
                "error_message": "; ".join(errors) if errors else None
            }).eq("id", sync_id).execute()
        except Exception as e:
            logger.warning(f"Failed to update sync record: {e}")

    # Log to user context
    try:
        context_service = UserContextService()
        await context_service.log_event(
            user_id=request.user_id,
            event_type="watch_sync",
            event_data={
                "synced_items": synced,
                "failed_items": failed,
                "device_source": request.device_source,
                "device_id": request.device_id,
                "workout_sets_count": len(request.workout_sets) if request.workout_sets else 0,
                "food_logs_count": len(request.food_logs) if request.food_logs else 0,
                "fasting_events_count": len(request.fasting_events) if request.fasting_events else 0,
            },
            context={"device": "wearos", "sync_type": "bulk"}
        )
    except Exception as e:
        logger.warning(f"Failed to log context: {e}")

    logger.info(f"Watch sync complete: {synced} synced, {failed} failed")

    return WatchSyncResponse(
        success=failed == 0,
        synced_items=synced,
        failed_items=failed,
        errors=errors if errors else None,
        sync_id=sync_id
    )


@router.get("/goals/{user_id}", response_model=ActivityGoalsResponse)
async def get_activity_goals(user_id: str):
    """
    Get user's activity goals for watch display.

    Returns step goal, active minutes goal, calorie goal, and water goal.
    """
    logger.info(f"Getting activity goals for user {user_id}")

    db = get_supabase_db()

    try:
        # Get user's goals from various tables
        # Check NEAT settings for step goal
        neat_result = db.table("neat_settings").select("*").eq("user_id", user_id).maybe_single().execute()

        # Get user profile for other goals
        user_result = db.table("users").select("*").eq("id", user_id).maybe_single().execute()

        steps_goal = 10000  # Default
        active_minutes_goal = 30
        calories_burned_goal = 500
        water_ml_goal = 2000

        if neat_result.data:
            steps_goal = neat_result.data.get("daily_step_goal", 10000)

        if user_result.data:
            # Could get water goal from nutrition preferences
            pass

        # Check hydration settings
        hydration_result = db.table("hydration_settings").select("*").eq("user_id", user_id).maybe_single().execute()
        if hydration_result.data:
            water_ml_goal = hydration_result.data.get("daily_goal_ml", 2000)

        return ActivityGoalsResponse(
            steps_goal=steps_goal,
            active_minutes_goal=active_minutes_goal,
            calories_burned_goal=calories_burned_goal,
            water_ml_goal=water_ml_goal
        )

    except Exception as e:
        logger.error(f"Error getting activity goals: {e}")
        # Return defaults on error
        return ActivityGoalsResponse()


# ==================== Helper Functions ====================

async def _log_workout_set(db, user_id: str, set_log: SetLogRequest, device_source: str):
    """Log a single workout set from watch."""
    logged_at = datetime.fromtimestamp(set_log.logged_at / 1000)

    db.table("workout_logs").insert({
        "user_id": user_id,
        "session_id": set_log.session_id,
        "exercise_id": set_log.exercise_id,
        "exercise_name": set_log.exercise_name,
        "set_number": set_log.set_number,
        "actual_reps": set_log.actual_reps,
        "weight_kg": set_log.weight_kg,
        "rpe": set_log.rpe,
        "rir": set_log.rir,
        "device_source": device_source,
        "logged_at": logged_at.isoformat()
    }).execute()

    logger.debug(f"Logged set {set_log.set_number} for exercise {set_log.exercise_name}")


async def _complete_workout(db, user_id: str, completion: WorkoutCompletionRequest, device_source: str):
    """Mark a workout as completed from watch."""
    started_at = datetime.fromtimestamp(completion.started_at / 1000)
    ended_at = datetime.fromtimestamp(completion.ended_at / 1000)
    duration_minutes = int((ended_at - started_at).total_seconds() / 60)

    # Update workout status
    if completion.workout_id:
        db.table("workouts").update({
            "is_completed": True,
            "completed_at": ended_at.isoformat(),
            "actual_duration_minutes": duration_minutes,
            "device_source": device_source
        }).eq("id", completion.workout_id).execute()

    # Log completion event
    db.table("workout_completions").insert({
        "user_id": user_id,
        "session_id": completion.session_id,
        "workout_id": completion.workout_id,
        "started_at": started_at.isoformat(),
        "ended_at": ended_at.isoformat(),
        "duration_minutes": duration_minutes,
        "total_sets": completion.total_sets,
        "total_reps": completion.total_reps,
        "total_volume_kg": completion.total_volume_kg,
        "avg_heart_rate": completion.avg_heart_rate,
        "max_heart_rate": completion.max_heart_rate,
        "calories_burned": completion.calories_burned,
        "device_source": device_source
    }).execute()

    logger.info(f"Completed workout {completion.workout_id or completion.session_id} from watch")


async def _log_food_with_gemini(db, user_id: str, food_log: FoodLogRequest, device_source: str):
    """Log food from watch, using Gemini for nutrition analysis if needed."""
    logged_at = datetime.fromtimestamp(food_log.logged_at / 1000)

    # If watch didn't provide nutrition info, use Gemini to analyze
    if food_log.calories is None and food_log.raw_input:
        try:
            gemini = get_gemini_service()
            analysis = await gemini.analyze_food(food_log.raw_input)

            food_name = analysis.get("food_name", food_log.raw_input)
            calories = analysis.get("calories", 0)
            protein_g = analysis.get("protein_g", 0)
            carbs_g = analysis.get("carbs_g", 0)
            fat_g = analysis.get("fat_g", 0)

            logger.info(f"Gemini analyzed food '{food_log.raw_input}': {calories} cal")
        except Exception as e:
            logger.error(f"Gemini food analysis failed: {e}")
            # Fall back to watch's local parsing
            food_name = food_log.food_name or food_log.raw_input
            calories = food_log.calories or 0
            protein_g = food_log.protein_g or 0
            carbs_g = food_log.carbs_g or 0
            fat_g = food_log.fat_g or 0
    else:
        food_name = food_log.food_name or food_log.raw_input
        calories = food_log.calories or 0
        protein_g = food_log.protein_g or 0
        carbs_g = food_log.carbs_g or 0
        fat_g = food_log.fat_g or 0

    # Insert food log
    db.table("food_logs").insert({
        "user_id": user_id,
        "food_name": food_name,
        "raw_input": food_log.raw_input,
        "input_type": food_log.input_type,
        "calories": calories,
        "protein_g": protein_g,
        "carbs_g": carbs_g,
        "fat_g": fat_g,
        "meal_type": food_log.meal_type.lower(),
        "device_source": device_source,
        "logged_at": logged_at.isoformat()
    }).execute()

    # Log to user context with watch-specific tracking
    context_service = UserContextService()
    await context_service.log_watch_food_logged(
        user_id=user_id,
        food_name=food_name,
        calories=calories,
        input_type=food_log.input_type,
        meal_type=food_log.meal_type,
    )

    logger.info(f"Logged food '{food_name}' from watch")


async def _log_fasting_event(db, user_id: str, event: FastingEventRequest, device_source: str):
    """Log fasting event from watch."""
    event_at = datetime.fromtimestamp(event.event_at / 1000)

    if event.event_type == "START":
        # Create new fasting session
        db.table("fasting_sessions").insert({
            "user_id": user_id,
            "protocol": event.protocol,
            "target_duration_minutes": event.target_duration_minutes,
            "started_at": event_at.isoformat(),
            "status": "active",
            "device_source": device_source
        }).execute()
    elif event.event_type == "END" and event.session_id:
        # End existing session
        db.table("fasting_sessions").update({
            "ended_at": event_at.isoformat(),
            "actual_duration_minutes": event.elapsed_minutes,
            "status": "completed"
        }).eq("id", event.session_id).execute()

    logger.info(f"Logged fasting event {event.event_type} from watch")


async def _sync_activity(db, user_id: str, activity: ActivitySyncRequest, device_source: str):
    """Sync daily activity from watch."""

    # Upsert daily activity
    db.table("daily_activity").upsert({
        "user_id": user_id,
        "activity_date": activity.date,
        "steps": activity.steps,
        "calories_burned": activity.calories_burned,
        "distance_meters": activity.distance_meters,
        "active_minutes": activity.active_minutes,
        "source": device_source,
        "synced_at": datetime.utcnow().isoformat()
    }, on_conflict="user_id,activity_date").execute()

    # Store heart rate samples if provided
    hr_samples_count = 0
    if activity.heart_rate_samples:
        for sample in activity.heart_rate_samples:
            try:
                db.table("heart_rate_samples").insert({
                    "user_id": user_id,
                    "timestamp": datetime.fromtimestamp(sample["timestamp"] / 1000).isoformat(),
                    "bpm": sample["bpm"],
                    "source": device_source
                }).execute()
                hr_samples_count += 1
            except Exception as e:
                logger.warning(f"Failed to insert HR sample: {e}")

    # Log to user context with watch-specific tracking
    context_service = UserContextService()
    await context_service.log_watch_activity_synced(
        user_id=user_id,
        steps=activity.steps,
        calories_burned=activity.calories_burned,
        active_minutes=activity.active_minutes,
        hr_samples_count=hr_samples_count,
    )

    logger.info(f"Synced activity for {activity.date}: {activity.steps} steps")
