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
from typing import Optional, List, Set
import asyncio
from concurrent.futures import ThreadPoolExecutor
import json

from fastapi import APIRouter, HTTPException, Query, BackgroundTasks
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.user_context_service import user_context_service

from .utils import parse_json_field


# Thread pool for running synchronous DB calls concurrently
_db_executor = ThreadPoolExecutor(max_workers=4)


# =============================================================================
# Background auto-generation tracking
# =============================================================================
# Tracks in-flight background generation tasks to prevent duplicate calls.
# Key: "user_id:date_str", Value: True while generating.
_active_background_generations: Set[str] = set()


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

    Returns an empty list if no workout days are configured, so that
    auto-generation does NOT trigger on arbitrary default days.
    """
    preferences = parse_json_field(user.get("preferences"), {})
    # Try workout_days first (new format), fall back to selected_days (old format)
    selected_days = preferences.get("workout_days") or preferences.get("selected_days")

    if not selected_days or not isinstance(selected_days, list):
        logger.warning(f"[WORKOUT DAYS] No workout_days found in user preferences, returning empty list")
        return []

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


def _get_upcoming_dates_needing_generation(
    db,
    user_id: str,
    selected_days: List[int],
    active_profile_id: Optional[str],
    max_dates: int = 3,
) -> List[date]:
    """Find up to `max_dates` upcoming scheduled workout days that have no workout generated.

    Scans the next 8 calendar days and returns dates that:
    1. Fall on one of the user's selected workout days
    2. Are today or in the future
    3. Don't already have a workout (completed or not) in the database

    Uses a single DB query to fetch all workouts in the date range instead of
    one query per day.
    """
    today_date = date.today()
    end_date = today_date + timedelta(days=8)

    # Single query for ALL workouts in the next 8 days
    existing_workouts = db.list_workouts(
        user_id=user_id,
        from_date=today_date.isoformat(),
        to_date=end_date.isoformat(),
        limit=20,
        gym_profile_id=active_profile_id,
    )

    # Build set of dates that already have workouts
    existing_dates = set()
    for w in existing_workouts:
        sd = w.get("scheduled_date", "")
        if sd:
            existing_dates.add(sd[:10])

    # Find scheduled days without workouts
    results: List[date] = []
    for days_ahead in range(0, 8):
        check_date = today_date + timedelta(days=days_ahead)
        if check_date.weekday() not in selected_days:
            continue
        if check_date.isoformat() not in existing_dates:
            results.append(check_date)
            if len(results) >= max_dates:
                break

    return results


async def auto_generate_workout(user_id: str, target_date: date, gym_profile_id: Optional[str] = None) -> None:
    """Background task: generate a workout for a specific date.

    Safety guarantees:
    - Checks if a workout already exists for the date (race-condition prevention)
    - Tracks in-flight generations to prevent duplicate calls
    - Catches all exceptions so background tasks never crash the server
    """
    generation_key = f"{user_id}:{target_date.isoformat()}"

    # Prevent duplicate in-flight generation for same user+date
    if generation_key in _active_background_generations:
        logger.info(f"[BG-GEN] Already generating for {generation_key}, skipping")
        return

    _active_background_generations.add(generation_key)
    logger.info(f"[BG-GEN] Starting background generation for user={user_id}, date={target_date.isoformat()}")

    try:
        db = get_supabase_db()

        # Double-check: workout may have been created between the /today check and now
        existing = db.list_workouts(
            user_id=user_id,
            from_date=target_date.isoformat(),
            to_date=target_date.isoformat(),
            limit=1,
            gym_profile_id=gym_profile_id,
        )
        if existing:
            logger.info(f"[BG-GEN] Workout already exists for {generation_key}, skipping generation")
            return

        # Also check for a workout with status='generating' (another request may have started it)
        try:
            generating_check = db.client.table("workouts").select("id").eq(
                "user_id", user_id
            ).eq(
                "scheduled_date", target_date.isoformat()
            ).eq(
                "status", "generating"
            ).execute()
            if generating_check.data:
                logger.info(f"[BG-GEN] Workout already being generated for {generation_key}, skipping")
                return
        except Exception:
            pass  # Non-critical check, proceed with generation

        # Import the generation function (local import to avoid circular dependency)
        from .generation import generate_workout
        from models.schemas import GenerateWorkoutRequest

        request = GenerateWorkoutRequest(
            user_id=user_id,
            scheduled_date=target_date.isoformat(),
            gym_profile_id=gym_profile_id,
        )

        # Use the existing non-streaming generate_workout function
        # It handles all user preferences, gym profiles, AI generation, etc.
        result = await generate_workout(request, background_tasks=BackgroundTasks())
        logger.info(f"[BG-GEN] Successfully generated workout for {generation_key}: {result.name if result else 'unknown'}")

    except Exception as e:
        logger.error(f"[BG-GEN] Failed to generate workout for {generation_key}: {e}")
    finally:
        _active_background_generations.discard(generation_key)


@router.get("/today", response_model=TodayWorkoutResponse)
async def get_today_workout(
    user_id: str = Query(..., description="User ID"),
    background_tasks: BackgroundTasks = BackgroundTasks(),
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
        logger.debug(f"[GYM PROFILE] Active profile for user {user_id}: {active_profile_id}")

        selected_days = _get_user_workout_days(user)

        day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        is_today_workout_day = _is_today_a_workout_day(selected_days)

        # Enhanced user context logging for debugging (downgraded to debug)
        user_preferences = parse_json_field(user.get("preferences"), {})
        user_timezone = user.get("timezone") or user_preferences.get("timezone") or "Not set"
        logger.debug(f"[USER CONTEXT] user_id={user_id}, timezone={user_timezone}, "
                     f"onboarding_completed={user.get('onboarding_completed', False)}")
        logger.debug(f"[TODAY DEBUG] server_date={today_str}, selected_days={selected_days}, "
                     f"is_workout_day={is_today_workout_day}")

        # Compute date range strings before parallel queries
        tomorrow_str = (date.today() + timedelta(days=1)).isoformat()
        future_end = (date.today() + timedelta(days=30)).isoformat()

        # Run 3 independent DB queries in parallel using thread pool
        # (db.list_workouts is synchronous, so we use run_in_executor)
        loop = asyncio.get_event_loop()
        today_rows, future_rows, completed_today_rows = await asyncio.gather(
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id, from_date=today_str, to_date=today_str,
                is_completed=False, limit=1, gym_profile_id=active_profile_id,
            )),
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id, from_date=tomorrow_str, to_date=future_end,
                is_completed=False, limit=1, order_asc=True, gym_profile_id=active_profile_id,
            )),
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id, from_date=today_str, to_date=today_str,
                is_completed=True, limit=1, gym_profile_id=active_profile_id,
            )),
        )

        if not today_rows:
            logger.debug(f"[TODAY DEBUG] No workout found for today ({today_str}), profile={active_profile_id}")

        today_workout: Optional[TodayWorkoutSummary] = None
        next_workout: Optional[TodayWorkoutSummary] = None
        has_workout_today = False
        is_generating = False
        generation_message: Optional[str] = None
        days_until_next: Optional[int] = None

        if today_rows:
            today_workout = _row_to_summary(today_rows[0])
            has_workout_today = True
            logger.debug(f"[TODAY DEBUG] Found today's workout: {today_workout.name}")

        if future_rows:
            next_workout = _row_to_summary(future_rows[0])
            next_date = datetime.strptime(next_workout.scheduled_date, "%Y-%m-%d").date()
            days_until_next = (next_date - date.today()).days
            logger.debug(f"[TODAY DEBUG] Found next workout: {next_workout.name}, in {days_until_next} days")

        has_completed_workout_today = len(completed_today_rows) > 0

        if has_completed_workout_today:
            logger.debug(f"[JIT Safety Net] User {user_id} already completed today's workout. Skipping auto-generation.")

        # Check if today is a scheduled workout day
        is_today_workout_day = _is_today_a_workout_day(selected_days)

        # Determine if generation is needed
        # Case 1: No today_workout AND no next_workout => generate for next scheduled day
        # Case 2: Next scheduled workout day has no workout (even if a later day does)
        #         e.g., on Friday with workout days Tue/Thu/Sat/Sun: if Saturday has no
        #         workout but Sunday does, we should still signal generation for Saturday
        needs_generation = False
        next_workout_date: Optional[str] = None

        if not today_workout and not has_completed_workout_today:
            nearest_scheduled_date_str = _calculate_next_workout_date(selected_days)
            if not next_workout:
                # Case 1: No workouts at all - generate for the next scheduled day
                needs_generation = True
                next_workout_date = nearest_scheduled_date_str
                logger.info(f"[AUTO-GEN] No workouts found for user {user_id}. Signaling generation needed for {next_workout_date}")
            elif next_workout and nearest_scheduled_date_str != next_workout.scheduled_date:
                # Case 2: The nearest scheduled day doesn't match the next existing workout
                # This means there's a gap - the nearest day needs generation
                # e.g., nearest scheduled is Saturday but next existing workout is Sunday
                needs_generation = True
                next_workout_date = nearest_scheduled_date_str
                logger.info(f"[AUTO-GEN] Nearest scheduled day {nearest_scheduled_date_str} has no workout "
                           f"(next existing is {next_workout.scheduled_date}). "
                           f"Signaling generation for {next_workout_date}")

        # Log analytics event for quick start view (non-blocking)
        background_tasks.add_task(
            user_context_service.log_event,
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

        # Build completed workout summary if user completed today's workout
        completed_workout_summary: Optional[TodayWorkoutSummary] = None
        if has_completed_workout_today:
            completed_workout_summary = _row_to_summary(completed_today_rows[0])
            logger.info(f"User completed today's workout: {completed_workout_summary.name}")

        # ================================================================
        # Proactive Background Generation (Fix 1 + Fix 3)
        # ================================================================
        # When workouts are missing, auto-generate them in the background.
        # This covers the immediate next day AND up to 3 upcoming days.
        # The user sees needs_generation=true on first call, but on next
        # poll/refresh the workout will already exist.
        if needs_generation and not has_completed_workout_today:
            upcoming_missing = _get_upcoming_dates_needing_generation(
                db=db,
                user_id=user_id,
                selected_days=selected_days,
                active_profile_id=active_profile_id,
                max_dates=3,
            )
            if upcoming_missing:
                logger.info(f"[BG-GEN] Scheduling background generation for {len(upcoming_missing)} dates: "
                           f"{[d.isoformat() for d in upcoming_missing]}")
                for gen_date in upcoming_missing:
                    background_tasks.add_task(
                        auto_generate_workout,
                        user_id=user_id,
                        target_date=gen_date,
                        gym_profile_id=active_profile_id,
                    )

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
