"""
Today's Workout API endpoint.

Provides a quick-start experience by returning today's scheduled workout
or the next upcoming workout if today is a rest day.
"""
from datetime import datetime, date, timedelta
from typing import Optional, List
import json

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.user_context_service import user_context_service

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


class TodayWorkoutResponse(BaseModel):
    """Response for today's workout endpoint."""
    has_workout_today: bool
    today_workout: Optional[TodayWorkoutSummary] = None
    next_workout: Optional[TodayWorkoutSummary] = None
    rest_day_message: Optional[str] = None
    days_until_next: Optional[int] = None


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
    )


@router.get("/today", response_model=TodayWorkoutResponse)
async def get_today_workout(
    user_id: str = Query(..., description="User ID"),
) -> TodayWorkoutResponse:
    """
    Get today's scheduled workout for quick-start experience.

    Returns:
    - today_workout: Today's workout if scheduled and not completed
    - next_workout: Next upcoming workout (if today is a rest day)
    - rest_day_message: Friendly message for rest days
    - days_until_next: Number of days until next workout

    This endpoint is optimized for the Quick Start widget on the home screen.
    """
    logger.info(f"Fetching today's workout for user {user_id}")

    try:
        db = get_supabase_db()
        today_str = date.today().isoformat()

        # Get today's workout (not completed)
        today_rows = db.list_workouts(
            user_id=user_id,
            from_date=today_str,
            to_date=today_str,
            is_completed=False,
            limit=1,
        )

        today_workout: Optional[TodayWorkoutSummary] = None
        has_workout_today = False

        if today_rows:
            today_workout = _row_to_summary(today_rows[0])
            has_workout_today = True
            logger.info(f"Found today's workout: {today_workout.name}")

        # Get next upcoming workout (future dates, not completed)
        next_workout: Optional[TodayWorkoutSummary] = None
        days_until_next: Optional[int] = None
        rest_day_message: Optional[str] = None

        if not has_workout_today:
            # Find next upcoming workout
            tomorrow_str = (date.today() + timedelta(days=1)).isoformat()
            future_end = (date.today() + timedelta(days=30)).isoformat()

            future_rows = db.list_workouts(
                user_id=user_id,
                from_date=tomorrow_str,
                to_date=future_end,
                is_completed=False,
                limit=1,
            )

            if future_rows:
                next_workout = _row_to_summary(future_rows[0])

                # Calculate days until next workout
                next_date = datetime.strptime(next_workout.scheduled_date, "%Y-%m-%d").date()
                days_until_next = (next_date - date.today()).days

                logger.info(f"Found next workout in {days_until_next} days: {next_workout.name}")

                # Generate rest day message
                if days_until_next == 1:
                    rest_day_message = "Rest day today. Your next workout is tomorrow!"
                else:
                    rest_day_message = f"Rest day today. Next workout in {days_until_next} days."
            else:
                rest_day_message = "No upcoming workouts scheduled. Time to plan your week!"
                logger.info("No upcoming workouts found")

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
                },
            )
        except Exception as log_error:
            logger.warning(f"Failed to log quick_start_viewed event: {log_error}")

        return TodayWorkoutResponse(
            has_workout_today=has_workout_today,
            today_workout=today_workout,
            next_workout=next_workout,
            rest_day_message=rest_day_message,
            days_until_next=days_until_next,
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
