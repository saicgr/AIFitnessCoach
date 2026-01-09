"""
Today's Workout API endpoint.

Provides a quick-start experience by returning today's scheduled workout
or the next upcoming workout.

IMPORTANT: The hero card should ALWAYS show a workout. If no workouts exist,
this endpoint will auto-generate them. There is never a scenario where
the hero card is empty.
"""
from datetime import datetime, date, timedelta
from typing import Optional, List
import json

from fastapi import APIRouter, HTTPException, Query, BackgroundTasks
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.user_context_service import user_context_service

from .utils import parse_json_field

router = APIRouter()
logger = get_logger(__name__)


class TodayWorkoutSummary(BaseModel):
    """Summary info for quick display on home screen."""
    id: str
    name: str
    type: str
    difficulty: str
    duration_minutes: int
    exercise_count: int
    primary_muscles: List[str]
    scheduled_date: str
    is_today: bool
    is_completed: bool
    exercises: List[dict] = []  # Full exercise data for hero card preview


class TodayWorkoutResponse(BaseModel):
    """Response for today's workout endpoint."""
    has_workout_today: bool
    today_workout: Optional[TodayWorkoutSummary] = None
    next_workout: Optional[TodayWorkoutSummary] = None
    days_until_next: Optional[int] = None
    # Generation status fields
    is_generating: bool = False
    generation_message: Optional[str] = None


def _extract_primary_muscles(exercises: list) -> List[str]:
    """Extract unique primary muscle groups from exercises."""
    muscles = set()
    for exercise in exercises:
        if isinstance(exercise, dict):
            # Check various field names for muscle info
            muscle = (
                exercise.get("primary_muscle") or
                exercise.get("primaryMuscle") or
                exercise.get("muscle_group") or
                exercise.get("muscleGroup") or
                exercise.get("target_muscle") or
                ""
            )
            if muscle:
                muscles.add(muscle.title())
    return list(muscles)[:4]  # Limit to top 4


def _row_to_summary(row: dict) -> TodayWorkoutSummary:
    """Convert a database row to TodayWorkoutSummary."""
    # Parse exercises
    exercises = row.get("exercises") or row.get("exercises_json") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, TypeError):
            exercises = []

    # Get scheduled date
    scheduled_date = row.get("scheduled_date", "")
    if scheduled_date:
        scheduled_date = str(scheduled_date)[:10]  # Get YYYY-MM-DD part

    # Check if today
    today_str = date.today().isoformat()
    is_today = scheduled_date == today_str

    return TodayWorkoutSummary(
        id=row.get("id", ""),
        name=row.get("name", "Workout"),
        type=row.get("type", "strength"),
        difficulty=row.get("difficulty", "medium"),
        duration_minutes=row.get("duration_minutes", 45),
        exercise_count=len(exercises) if isinstance(exercises, list) else 0,
        primary_muscles=_extract_primary_muscles(exercises) if isinstance(exercises, list) else [],
        scheduled_date=scheduled_date,
        is_today=is_today,
        is_completed=row.get("is_completed", False),
        exercises=exercises if isinstance(exercises, list) else [],
    )


def _is_today_a_workout_day(selected_days: List[int]) -> bool:
    """Check if today is a scheduled workout day for the user."""
    # Python's weekday(): Monday=0, Sunday=6 - matches our selected_days format
    today_weekday = date.today().weekday()
    return today_weekday in selected_days


def _get_user_workout_days(user: dict) -> List[int]:
    """Extract user's workout days from preferences."""
    preferences = parse_json_field(user.get("preferences"), {})
    # Try workout_days first (new format), fall back to selected_days (old format)
    selected_days = preferences.get("workout_days") or preferences.get("selected_days") or [0, 2, 4]

    if not selected_days or not isinstance(selected_days, list):
        selected_days = [0, 2, 4]  # Default: Mon, Wed, Fri

    return selected_days


@router.get("/today", response_model=TodayWorkoutResponse)
async def get_today_workout(
    user_id: str = Query(..., description="User ID"),
) -> TodayWorkoutResponse:
    """
    Get today's scheduled workout or the next upcoming workout.

    Returns:
    - today_workout: Today's workout if scheduled and not completed
    - next_workout: Next upcoming workout (always populated if no today workout)
    - days_until_next: Number of days until next workout
    - is_generating: True if workout is being generated in background
    - generation_message: Message about generation status

    IMPORTANT: The hero card should ALWAYS show a workout. If no workouts exist,
    this endpoint will trigger auto-generation. There is never a scenario where
    the hero card is empty.

    This endpoint is optimized for the Quick Start widget on the home screen.
    """
    logger.info(f"Fetching today's workout for user {user_id}")

    try:
        db = get_supabase_db()
        today_str = date.today().isoformat()

        # Get user to check their workout days
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        selected_days = _get_user_workout_days(user)

        day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        today_day_name = day_names[date.today().weekday()]
        logger.info(f"Today is {today_day_name} (weekday={date.today().weekday()}), workout days: {[day_names[d] for d in selected_days]}")

        # Get today's workout (not completed)
        today_rows = db.list_workouts(
            user_id=user_id,
            from_date=today_str,
            to_date=today_str,
            is_completed=False,
            limit=1,
        )

        today_workout: Optional[TodayWorkoutSummary] = None
        next_workout: Optional[TodayWorkoutSummary] = None
        has_workout_today = False
        is_generating = False
        generation_message: Optional[str] = None
        days_until_next: Optional[int] = None

        if today_rows:
            today_workout = _row_to_summary(today_rows[0])
            has_workout_today = True
            logger.info(f"Found today's workout: {today_workout.name}")

        # Always look for next upcoming workout (for "Your Next Workout" label)
        tomorrow_str = (date.today() + timedelta(days=1)).isoformat()
        future_end = (date.today() + timedelta(days=30)).isoformat()

        future_rows = db.list_workouts(
            user_id=user_id,
            from_date=tomorrow_str,
            to_date=future_end,
            is_completed=False,
            limit=1,
            order_asc=True,  # Get earliest upcoming workout first
        )

        if future_rows:
            next_workout = _row_to_summary(future_rows[0])
            next_date = datetime.strptime(next_workout.scheduled_date, "%Y-%m-%d").date()
            days_until_next = (next_date - date.today()).days
            logger.info(f"Found next workout in {days_until_next} days: {next_workout.name}")

        # No auto-generation here. Users can manually generate workouts from the Workouts tab.
        # If no workouts exist, the frontend will show the "Ready to Start?" empty state card
        # which navigates to the Workouts tab where users can generate more.
        if not has_workout_today and next_workout is None:
            logger.info(f"No workouts exist for user {user_id}. User should navigate to Workouts tab to generate.")

        # Log analytics event for quick start view
        try:
            await user_context_service.log_event(
                user_id=user_id,
                event_type="quick_start_viewed",
                event_data={
                    "has_workout_today": has_workout_today,
                    "workout_id": today_workout.id if today_workout else None,
                    "next_workout_id": next_workout.id if next_workout else None,
                    "days_until_next": days_until_next,
                    "is_generating": is_generating,
                },
            )
        except Exception as log_error:
            logger.warning(f"Failed to log quick_start_viewed event: {log_error}")

        return TodayWorkoutResponse(
            has_workout_today=has_workout_today,
            today_workout=today_workout,
            next_workout=next_workout,
            days_until_next=days_until_next,
            is_generating=is_generating,
            generation_message=generation_message,
        )

    except Exception as e:
        logger.error(f"Failed to get today's workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/today/start")
async def log_quick_start(
    user_id: str = Query(..., description="User ID"),
    workout_id: str = Query(..., description="Workout ID being started"),
) -> dict:
    """
    Log when user taps 'Start Today's Workout' for analytics.

    This helps track:
    - Quick start usage patterns
    - Conversion from home screen to active workout
    - Time of day preferences
    """
    logger.info(f"Logging quick start for user {user_id}, workout {workout_id}")

    try:
        await user_context_service.log_event(
            user_id=user_id,
            event_type="quick_start_tapped",
            event_data={
                "workout_id": workout_id,
                "source": "quick_start_widget",
                "timestamp": datetime.now().isoformat(),
            },
        )

        return {
            "success": True,
            "message": "Quick start logged",
        }

    except Exception as e:
        logger.warning(f"Failed to log quick start: {e}")
        # Don't fail the request - logging is non-critical
        return {
            "success": False,
            "message": "Logging failed but operation continues",
        }
