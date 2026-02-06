"""
Today's Workout API endpoint.

Provides a quick-start experience by returning today's scheduled workout
or the next upcoming workout.

IMPORTANT: The hero card should ALWAYS show a workout. If no workouts exist,
this endpoint will auto-generate them. There is never a scenario where
the hero card is empty.

NOTE: Workouts are filtered by active gym profile. Users only see workouts
belonging to the currently active gym profile.
"""
from datetime import datetime, date, timedelta
from typing import Optional, List
import json

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.user_context_service import user_context_service

from .utils import parse_json_field


def _get_active_gym_profile_id(db, user_id: str) -> Optional[str]:
    """Get the active gym profile ID for a user.

    Returns None if no gym profiles exist (user hasn't set up profiles yet).
    """
    try:
        result = db.client.table("gym_profiles") \
            .select("id, name") \
            .eq("user_id", user_id) \
            .eq("is_active", True) \
            .single() \
            .execute()
        if result.data:
            from core.logger import get_logger
            logger = get_logger(__name__)
            logger.info(f"[GYM PROFILE] Active profile for user {user_id}: {result.data.get('name')} ({result.data.get('id')})")
            return result.data.get("id")
    except Exception:
        # No active profile found (single() raises if no match)
        pass
    return None

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
    # Completed workout info (if user already completed today's workout)
    completed_today: bool = False
    completed_workout: Optional[TodayWorkoutSummary] = None
    # Generation status fields
    is_generating: bool = False
    generation_message: Optional[str] = None
    # Auto-generation trigger fields
    needs_generation: bool = False
    next_workout_date: Optional[str] = None  # YYYY-MM-DD format for frontend to generate
    # Gym profile context
    gym_profile_id: Optional[str] = None  # Active gym profile ID used for filtering


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
    raw_exercises = row.get("exercises") or row.get("exercises_json")
    logger.info(f"[_row_to_summary] workout_id={row.get('id')}, exercises_type={type(raw_exercises)}, "
                f"exercises_len={len(raw_exercises) if raw_exercises else 0}")

    exercises = raw_exercises or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, TypeError):
            logger.warning(f"[_row_to_summary] Failed to parse exercises JSON for workout {row.get('id')}")
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
    """Extract user's workout days from preferences.

    Flutter stores days as 1-indexed (Mon=1..Sun=7).
    Python's date.weekday() uses 0-indexed (Mon=0..Sun=6).
    This function normalizes to 0-indexed for Python compatibility.
    """
    preferences = parse_json_field(user.get("preferences"), {})
    # Try workout_days first (new format), fall back to selected_days (old format)
    selected_days = preferences.get("workout_days") or preferences.get("selected_days") or [0, 2, 4]

    if not selected_days or not isinstance(selected_days, list):
        selected_days = [0, 2, 4]  # Default: Mon, Wed, Fri

    # Convert from 1-indexed (Flutter: Mon=1..Sun=7) to 0-indexed (Python: Mon=0..Sun=6)
    if any(d > 6 for d in selected_days):
        selected_days = [d - 1 for d in selected_days if d > 0]

    return selected_days


def _calculate_next_workout_date(selected_days: List[int]) -> str:
    """Calculate the next workout date based on user's selected days.

    Returns the date in YYYY-MM-DD format.
    If today is a workout day, returns today.
    Otherwise returns the next upcoming workout day.
    """
    today = date.today()
    today_weekday = today.weekday()

    # If today is a workout day, return today
    if today_weekday in selected_days:
        return today.isoformat()

    # Find the next workout day
    for days_ahead in range(1, 8):  # Check next 7 days
        future_date = today + timedelta(days=days_ahead)
        if future_date.weekday() in selected_days:
            return future_date.isoformat()

    # Fallback to today (shouldn't happen if selected_days is valid)
    return today.isoformat()


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

        # Get active gym profile for filtering
        active_profile_id = _get_active_gym_profile_id(db, user_id)
        if active_profile_id:
            logger.info(f"[GYM PROFILE] Filtering workouts by active profile: {active_profile_id}")
        else:
            logger.info(f"[GYM PROFILE] No active profile - showing all workouts for user {user_id}")

        selected_days = _get_user_workout_days(user)

        day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        today_day_name = day_names[date.today().weekday()]
        is_today_workout_day = _is_today_a_workout_day(selected_days)

        # Enhanced user context logging for debugging
        user_preferences = parse_json_field(user.get("preferences"), {})
        user_timezone = user.get("timezone") or user_preferences.get("timezone") or "Not set"
        user_created_at = user.get("created_at", "Unknown")
        onboarding_completed = user.get("onboarding_completed", False)
        onboarding_completed_at = user.get("onboarding_completed_at", "Not recorded")
        user_name = user.get("name") or user.get("username") or "Unknown"

        logger.info(f"[USER CONTEXT] user_id={user_id}, name={user_name}")
        logger.info(f"[USER CONTEXT] timezone={user_timezone}, created_at={user_created_at}")
        logger.info(f"[USER CONTEXT] onboarding_completed={onboarding_completed}, onboarding_at={onboarding_completed_at}")
        logger.info(f"[TODAY DEBUG] server_date={today_str}, server_weekday={date.today().weekday()} ({today_day_name})")
        logger.info(f"[TODAY DEBUG] selected_days={selected_days} ({[day_names[d] for d in selected_days if 0 <= d < 7]}), is_workout_day={is_today_workout_day}")

        # Get today's workout (not completed) - filtered by active gym profile
        today_rows = db.list_workouts(
            user_id=user_id,
            from_date=today_str,
            to_date=today_str,
            is_completed=False,
            limit=1,
            gym_profile_id=active_profile_id,
        )

        # Debug: log query result and all user workouts if none found today
        logger.info(f"[TODAY DEBUG] Query result: {len(today_rows)} workout(s) for today ({today_str})")
        if not today_rows:
            all_user_workouts = db.list_workouts(user_id=user_id, from_date=None, to_date=None, limit=5, gym_profile_id=active_profile_id)
            dates = [w.get('scheduled_date', 'N/A')[:10] if w.get('scheduled_date') else 'N/A' for w in all_user_workouts]
            logger.info(f"[TODAY DEBUG] No workout for today (profile: {active_profile_id}). User's first 5 workout dates: {dates}")

        today_workout: Optional[TodayWorkoutSummary] = None
        next_workout: Optional[TodayWorkoutSummary] = None
        has_workout_today = False
        is_generating = False
        generation_message: Optional[str] = None
        days_until_next: Optional[int] = None

        if today_rows:
            today_workout = _row_to_summary(today_rows[0])
            has_workout_today = True
            logger.info(f"[TODAY DEBUG] Found today's workout: {today_workout.name}, scheduled_date={today_workout.scheduled_date}")

        # Always look for next upcoming workout (for "Your Next Workout" label)
        # Filtered by active gym profile
        tomorrow_str = (date.today() + timedelta(days=1)).isoformat()
        future_end = (date.today() + timedelta(days=30)).isoformat()

        future_rows = db.list_workouts(
            user_id=user_id,
            from_date=tomorrow_str,
            to_date=future_end,
            is_completed=False,
            limit=1,
            order_asc=True,  # Get earliest upcoming workout first
            gym_profile_id=active_profile_id,
        )

        if future_rows:
            next_workout = _row_to_summary(future_rows[0])
            next_date = datetime.strptime(next_workout.scheduled_date, "%Y-%m-%d").date()
            days_until_next = (next_date - date.today()).days
            next_weekday = next_date.weekday()
            logger.info(f"[TODAY DEBUG] Found next workout: {next_workout.name}, date={next_workout.scheduled_date} ({day_names[next_weekday]}), in {days_until_next} days")

        # JIT Generation Safety Net: If no workouts exist, trigger generation automatically
        # This ensures a workout ALWAYS exists for the user
        # BUT: Don't generate if today's workout was already completed (user already did their workout!)

        # Check if a completed workout exists for today - filtered by active profile
        completed_today_rows = db.list_workouts(
            user_id=user_id,
            from_date=today_str,
            to_date=today_str,
            is_completed=True,
            limit=1,
            gym_profile_id=active_profile_id,
        )
        has_completed_workout_today = len(completed_today_rows) > 0

        if has_completed_workout_today:
            logger.info(f"[JIT Safety Net] User {user_id} already completed today's workout. Skipping auto-generation.")

        # Check if today is a scheduled workout day
        is_today_workout_day = _is_today_a_workout_day(selected_days)

        # Determine if generation is needed
        # If no today_workout AND no next_workout, frontend should auto-generate
        needs_generation = False
        next_workout_date: Optional[str] = None

        if not today_workout and not next_workout and not has_completed_workout_today:
            needs_generation = True
            next_workout_date = _calculate_next_workout_date(selected_days)
            logger.info(f"[AUTO-GEN] No workouts found for user {user_id}. Signaling generation needed for {next_workout_date}")

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

        # Build completed workout summary if user completed today's workout
        completed_workout_summary: Optional[TodayWorkoutSummary] = None
        if has_completed_workout_today:
            completed_workout_summary = _row_to_summary(completed_today_rows[0])
            logger.info(f"User completed today's workout: {completed_workout_summary.name}")

        return TodayWorkoutResponse(
            has_workout_today=has_workout_today,
            today_workout=today_workout,
            next_workout=next_workout,
            days_until_next=days_until_next,
            completed_today=has_completed_workout_today,
            completed_workout=completed_workout_summary,
            is_generating=is_generating,
            generation_message=generation_message,
            needs_generation=needs_generation,
            next_workout_date=next_workout_date,
            gym_profile_id=active_profile_id,
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
