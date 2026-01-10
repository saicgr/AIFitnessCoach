"""
Background workout generation API endpoints.

This module handles background job management for workout generation:
- POST /schedule-background-generation - Schedule background generation
- GET /generation-status/{user_id} - Get generation status
- POST /ensure-workouts-generated - Ensure workouts exist, generate if needed
- POST /check-and-regenerate/{user_id} - Auto-regenerate if running low on workouts
"""
from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter, HTTPException, Query, BackgroundTasks

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import (
    GenerateMonthlyRequest, PendingWorkoutGenerationStatus,
    ScheduleBackgroundGenerationRequest,
)
from services.job_queue_service import get_job_queue_service

from .utils import parse_json_field
from .generation import generate_remaining_workouts

router = APIRouter()
logger = get_logger(__name__)


async def _run_background_generation(
    job_id: str,
    user_id: str,
    month_start_date: str,
    duration_minutes: int,
    selected_days: List[int],
    weeks: int
):
    """Background task to generate remaining workouts with database-backed job tracking."""
    logger.info(f"Starting background generation for user {user_id} (job {job_id})")

    job_queue = get_job_queue_service()

    try:
        # Update job status to in_progress
        job_queue.update_job_status(job_id, "in_progress")

        # Create the request and call the existing generate_remaining_workouts logic
        request = GenerateMonthlyRequest(
            user_id=user_id,
            month_start_date=month_start_date,
            duration_minutes=duration_minutes,
            selected_days=selected_days,
            weeks=weeks
        )

        # Call the synchronous generation
        result = await generate_remaining_workouts(request)

        # Update job as completed
        job_queue.update_job_status(
            job_id,
            "completed",
            total_generated=result.total_generated
        )

        logger.info(f"Background generation completed for user {user_id}: {result.total_generated} workouts")

    except Exception as e:
        logger.error(f"Background generation failed for user {user_id}: {e}")
        job_queue.update_job_status(
            job_id,
            "failed",
            error_message=str(e)
        )


@router.post("/schedule-background-generation")
async def schedule_background_generation(
    request: ScheduleBackgroundGenerationRequest,
    background_tasks: BackgroundTasks
):
    """
    Schedule workout generation to run in the background on the server.

    This endpoint returns immediately after scheduling the task.
    Use GET /generation-status/{user_id} to check progress.

    Jobs are persisted to database for reliability across server restarts.
    """
    logger.info(f"Scheduling background generation for user {request.user_id}")

    job_queue = get_job_queue_service()

    # Check if already generating
    existing_job = job_queue.get_user_pending_job(request.user_id)
    if existing_job and existing_job.get("status") == "in_progress":
        return {
            "success": True,
            "message": "Generation already in progress",
            "status": "in_progress",
            "job_id": existing_job.get("id")
        }

    # Create a new job in the database
    job_id = job_queue.create_job(
        user_id=request.user_id,
        month_start_date=request.month_start_date,
        duration_minutes=request.duration_minutes,
        selected_days=request.selected_days,
        weeks=request.weeks
    )

    # Schedule the background task with job_id
    background_tasks.add_task(
        _run_background_generation,
        job_id,
        request.user_id,
        request.month_start_date,
        request.duration_minutes,
        request.selected_days,
        request.weeks
    )

    return {
        "success": True,
        "message": "Workout generation scheduled",
        "status": "pending",
        "job_id": job_id
    }


@router.get("/generation-status/{user_id}", response_model=PendingWorkoutGenerationStatus)
async def get_generation_status(user_id: str):
    """Get the status of background workout generation for a user."""
    job_queue = get_job_queue_service()

    # Check for any pending/in-progress job first
    job = job_queue.get_user_pending_job(user_id)

    if not job:
        # Check the latest completed job
        job = job_queue.get_latest_job_for_user(user_id)

    if not job:
        # No job found - check if user has sufficient workouts
        db = get_supabase_db()
        workouts = db.list_workouts(user_id, limit=50)

        return PendingWorkoutGenerationStatus(
            user_id=user_id,
            status="none",
            total_expected=0,
            total_generated=len(workouts) if workouts else 0,
            error_message=None
        )

    return PendingWorkoutGenerationStatus(
        user_id=user_id,
        status=job.get("status", "unknown"),
        total_expected=job.get("total_expected", 0),
        total_generated=job.get("total_generated", 0),
        error_message=job.get("error_message")
    )


@router.post("/ensure-workouts-generated")
async def ensure_workouts_generated(
    request: ScheduleBackgroundGenerationRequest,
    background_tasks: BackgroundTasks
):
    """
    Check if user has sufficient workouts, and trigger generation if not.

    This is meant to be called when the Home page loads to ensure workouts
    exist even if the initial onboarding generation failed.

    Jobs are persisted to database for reliability across server restarts.
    """
    db = get_supabase_db()
    job_queue = get_job_queue_service()

    # Get user's workout count
    workouts = db.list_workouts(request.user_id, limit=100)
    workout_count = len(workouts) if workouts else 0

    # Calculate expected minimum workouts (at least 2 weeks worth)
    min_expected = 2 * len(request.selected_days)

    if workout_count >= min_expected:
        return {
            "success": True,
            "message": "Sufficient workouts exist",
            "workout_count": workout_count,
            "needs_generation": False
        }

    # Check if already generating
    existing_job = job_queue.get_user_pending_job(request.user_id)
    if existing_job and existing_job.get("status") == "in_progress":
        return {
            "success": True,
            "message": "Generation already in progress",
            "workout_count": workout_count,
            "needs_generation": True,
            "status": "in_progress",
            "job_id": existing_job.get("id")
        }

    # Need to generate more workouts
    logger.info(f"User {request.user_id} has only {workout_count} workouts, triggering generation")

    # Create a new job in the database
    job_id = job_queue.create_job(
        user_id=request.user_id,
        month_start_date=request.month_start_date,
        duration_minutes=request.duration_minutes,
        selected_days=request.selected_days,
        weeks=request.weeks
    )

    # Schedule the background task with job_id
    background_tasks.add_task(
        _run_background_generation,
        job_id,
        request.user_id,
        request.month_start_date,
        request.duration_minutes,
        request.selected_days,
        request.weeks
    )

    return {
        "success": True,
        "message": "Workout generation scheduled",
        "workout_count": workout_count,
        "needs_generation": True,
        "status": "pending",
        "job_id": job_id
    }


@router.post("/check-and-regenerate/{user_id}")
async def check_and_regenerate_workouts(
    user_id: str,
    background_tasks: BackgroundTasks,
    threshold_days: int = Query(default=3, description="Generate if less than this many days of workouts remain")
):
    """
    Check if user has enough upcoming workouts and auto-regenerate if running low.

    This endpoint is designed to be called on home screen load to ensure users
    always have upcoming workouts scheduled. It:
    1. Fetches user's workout preferences from their profile
    2. Checks how many upcoming (incomplete) workouts exist
    3. If less than threshold_days worth of workouts remain, generates next 2 weeks

    Returns immediately - generation happens in background if needed.
    """
    logger.info(f"Checking workout status for user {user_id}")

    try:
        db = get_supabase_db()
        job_queue = get_job_queue_service()

        # Get user data including preferences
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get user preferences for workout days
        preferences = parse_json_field(user.get("preferences"), {})
        # Try workout_days first (new format), fall back to selected_days (old format)
        selected_days = preferences.get("workout_days") or preferences.get("selected_days") or [0, 2, 4]
        duration_minutes = preferences.get("workout_duration", 45)

        # Log fitness level for context - important for debugging beginner issues
        raw_fitness_level = user.get("fitness_level")
        fitness_level = raw_fitness_level or "intermediate"
        if not raw_fitness_level:
            logger.warning(f"[Auto-Regen] User {user_id} has no fitness_level in DB, will default to intermediate during generation")
        else:
            logger.info(f"[Auto-Regen] User {user_id} fitness_level: {fitness_level}")

        # Log the day mapping for debugging
        day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        selected_day_names = [day_names[d] for d in selected_days if 0 <= d < 7]
        logger.info(f"[Auto-Regen] User {user_id} workout_days: {selected_days} = {selected_day_names} (0=Mon, 6=Sun)")

        # If no workout days configured, use defaults
        if not selected_days or not isinstance(selected_days, list):
            selected_days = [0, 2, 4]
            logger.warning(f"User {user_id} has no workout_days configured, using defaults: {selected_days}")

        # Get upcoming incomplete workouts
        today = datetime.now().date()
        future_date = today + timedelta(days=30)  # Look ahead 30 days

        workouts = db.get_workouts_by_date_range(
            user_id,
            str(today),
            str(future_date)
        )

        # Filter to only incomplete, future workouts
        upcoming_workouts = [
            w for w in workouts
            if not w.get("is_completed", False)
            and w.get("scheduled_date")
        ]

        # Count unique upcoming workout days
        upcoming_dates = set()
        for w in upcoming_workouts:
            sched_date = w.get("scheduled_date", "")
            if sched_date:
                date_str = str(sched_date)[:10]
                upcoming_dates.add(date_str)

        upcoming_count = len(upcoming_dates)
        logger.info(f"User {user_id} has {upcoming_count} upcoming workout days (threshold: {threshold_days})")

        # Check if generation is needed
        # Always generate if user has 0 workouts (critical for new users after onboarding)
        # Otherwise, generate if below threshold
        if upcoming_count > 0 and upcoming_count >= threshold_days:
            return {
                "success": True,
                "needs_generation": False,
                "upcoming_workout_days": upcoming_count,
                "message": f"User has sufficient workouts ({upcoming_count} days)"
            }

        # Check if already generating
        existing_job = job_queue.get_user_pending_job(user_id)
        if existing_job and existing_job.get("status") in ["pending", "in_progress"]:
            return {
                "success": True,
                "needs_generation": False,  # Don't show banner for existing jobs - prevents perpetual banner
                "already_generating": True,  # Separate flag for "job already in progress"
                "upcoming_workout_days": upcoming_count,
                "message": "Generation already in progress",
                "status": existing_job.get("status"),
                "job_id": existing_job.get("id"),
                "start_date": str(existing_job.get("month_start_date", ""))[:10] if existing_job.get("month_start_date") else None,
                "weeks": existing_job.get("weeks", 4),
                "total_expected": existing_job.get("total_expected", 0),
                "total_generated": existing_job.get("total_generated", 0),
            }

        # Need to generate more workouts
        logger.info(f"User {user_id} needs workout generation: only {upcoming_count} days available")

        # Find the appropriate start date for generation
        # Cap at 4 weeks from today to prevent runaway generation into the far future
        max_horizon = today + timedelta(days=28)

        if upcoming_workouts:
            # Get the latest scheduled date
            latest_date = max(
                datetime.fromisoformat(str(w.get("scheduled_date"))[:10]).date()
                for w in upcoming_workouts
            )

            # If latest workout is already beyond our 4-week horizon, don't generate more
            if latest_date >= max_horizon:
                logger.info(f"User {user_id} has workouts scheduled until {latest_date}, beyond 4-week horizon. Skipping generation.")
                return {
                    "success": True,
                    "needs_generation": False,
                    "upcoming_workout_days": upcoming_count,
                    "message": f"Workouts already scheduled through {latest_date}"
                }

            # Start from the day after the latest workout, but not before today
            next_day = latest_date + timedelta(days=1)
            start_date = str(max(next_day, today))
        else:
            # No upcoming workouts, start from today
            start_date = str(today)

        # Create a new job in the database
        # Generate 2 weeks at a time for more adaptive workout planning
        generation_weeks = 2
        job_id = job_queue.create_job(
            user_id=user_id,
            month_start_date=start_date,
            duration_minutes=duration_minutes,
            selected_days=selected_days,
            weeks=generation_weeks
        )

        # Schedule the background task
        background_tasks.add_task(
            _run_background_generation,
            job_id,
            user_id,
            start_date,
            duration_minutes,
            selected_days,
            generation_weeks
        )

        logger.info(f"Scheduled workout generation for user {user_id} starting from {start_date} ({generation_weeks} weeks)")

        return {
            "success": True,
            "needs_generation": True,
            "upcoming_workout_days": upcoming_count,
            "message": "Workout generation scheduled",
            "status": "pending",
            "job_id": job_id,
            "start_date": start_date,
            "weeks": generation_weeks,
            "selected_days": selected_days
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to check/regenerate workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-next/{user_id}")
async def generate_next_workout(
    user_id: str,
    background_tasks: BackgroundTasks
):
    """
    Generate just the NEXT single workout for a user.

    Called after workout completion to generate only the next workout day.
    This enables one-at-a-time workout generation instead of batch generation.

    Returns immediately - generation happens in background.
    """
    logger.info(f"[Generate-Next] Generating next workout for user {user_id}")

    try:
        db = get_supabase_db()
        job_queue = get_job_queue_service()

        # Get user data including preferences
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get user preferences for workout days
        preferences = parse_json_field(user.get("preferences"), {})
        selected_days = preferences.get("workout_days") or preferences.get("selected_days") or [0, 2, 4]
        duration_minutes = preferences.get("workout_duration", 45)

        # Check if already generating
        existing_job = job_queue.get_user_pending_job(user_id)
        if existing_job and existing_job.get("status") in ["pending", "in_progress"]:
            return {
                "success": True,
                "message": "Generation already in progress",
                "already_generating": True,
                "job_id": existing_job.get("id")
            }

        # Find the latest scheduled workout date
        today = datetime.now().date()
        future_date = today + timedelta(days=60)

        workouts = db.get_workouts_by_date_range(user_id, str(today), str(future_date))

        # Find the latest scheduled date
        latest_date = None
        if workouts:
            for w in workouts:
                sched_date = w.get("scheduled_date", "")
                if sched_date:
                    try:
                        workout_date = datetime.fromisoformat(str(sched_date)[:10]).date()
                        if latest_date is None or workout_date > latest_date:
                            latest_date = workout_date
                    except ValueError:
                        pass

        # Calculate next workout day based on selected_days
        # If no workouts exist yet, start searching from today (not tomorrow)
        # If workouts exist, start from the day after the latest scheduled workout
        if latest_date is None:
            search_date = today  # No workouts yet - include today as a candidate
        else:
            search_date = latest_date + timedelta(days=1)  # Start after last workout

        # Find the next day that matches user's workout days (limit search to 14 days)
        next_workout_date = None
        for i in range(14):
            check_date = search_date + timedelta(days=i)
            # Python weekday: Monday=0, Sunday=6 (matches our format)
            if check_date.weekday() in selected_days:
                next_workout_date = check_date
                break

        if not next_workout_date:
            logger.warning(f"[Generate-Next] Could not find next workout day for user {user_id}")
            return {
                "success": False,
                "message": "Could not determine next workout day",
                "needs_generation": False
            }

        logger.info(f"[Generate-Next] Next workout date for user {user_id}: {next_workout_date}")

        # Check if a workout already exists for this date
        existing_for_date = [
            w for w in workouts
            if str(w.get("scheduled_date", ""))[:10] == str(next_workout_date)
        ]

        if existing_for_date:
            logger.info(f"[Generate-Next] Workout already exists for {next_workout_date}")
            return {
                "success": True,
                "message": "Workout already exists for next scheduled day",
                "needs_generation": False,
                "next_workout_date": str(next_workout_date)
            }

        # Create a job to generate just 1 workout
        # Use weeks=1 and start from the exact next workout date
        job_id = job_queue.create_job(
            user_id=user_id,
            month_start_date=str(next_workout_date),
            duration_minutes=duration_minutes,
            selected_days=selected_days,
            weeks=1  # Only 1 week window - will generate just 1 workout
        )

        # Schedule the background task
        background_tasks.add_task(
            _run_background_generation,
            job_id,
            user_id,
            str(next_workout_date),
            duration_minutes,
            selected_days,
            1  # 1 week
        )

        logger.info(f"[Generate-Next] Scheduled single workout generation for {next_workout_date}")

        return {
            "success": True,
            "message": "Next workout generation scheduled",
            "needs_generation": True,
            "job_id": job_id,
            "next_workout_date": str(next_workout_date)
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Generate-Next] Failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-more/{user_id}")
async def generate_more_workouts(
    user_id: str,
    background_tasks: BackgroundTasks,
    max_workouts: int = Query(default=4, description="Maximum number of workouts to generate")
):
    """
    Generate up to max_workouts additional workouts for a user.

    This is a simplified endpoint designed to be called manually from the Workouts tab.
    It generates workouts starting from the day after the last scheduled workout,
    limited to max_workouts (default 4).

    Returns immediately - generation happens in background.
    """
    logger.info(f"[Generate-More] Generating up to {max_workouts} workouts for user {user_id}")

    try:
        db = get_supabase_db()
        job_queue = get_job_queue_service()

        # Get user data including preferences
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get user preferences for workout days
        preferences = parse_json_field(user.get("preferences"), {})
        selected_days = preferences.get("workout_days") or preferences.get("selected_days") or [0, 2, 4]
        duration_minutes = preferences.get("workout_duration", 45)

        # Check if already generating
        existing_job = job_queue.get_user_pending_job(user_id)
        if existing_job and existing_job.get("status") in ["pending", "in_progress"]:
            return {
                "success": True,
                "message": "Generation already in progress",
                "already_generating": True,
                "job_id": existing_job.get("id")
            }

        # Get existing workouts to find the latest scheduled date
        today = datetime.now().date()
        future_date = today + timedelta(days=60)

        workouts = db.get_workouts_by_date_range(user_id, str(today), str(future_date))

        # Find the latest scheduled workout date
        latest_date = today
        if workouts:
            for w in workouts:
                sched_date = w.get("scheduled_date", "")
                if sched_date:
                    try:
                        workout_date = datetime.fromisoformat(str(sched_date)[:10]).date()
                        if workout_date > latest_date:
                            latest_date = workout_date
                    except ValueError:
                        pass

        # Always generate max_workouts (default 4) new workouts
        workouts_needed = max_workouts

        # Calculate the number of weeks needed to generate workouts_needed
        # Based on workout days per week
        workouts_per_week = len(selected_days) if selected_days else 3
        weeks_needed = max(1, (workouts_needed + workouts_per_week - 1) // workouts_per_week)

        # Start from the day after the latest scheduled workout
        start_date = str(latest_date + timedelta(days=1))

        logger.info(f"[Generate-More] User {user_id}: generating {workouts_needed} workouts ({weeks_needed} weeks starting {start_date})")

        # Create a job
        job_id = job_queue.create_job(
            user_id=user_id,
            month_start_date=start_date,
            duration_minutes=duration_minutes,
            selected_days=selected_days,
            weeks=weeks_needed
        )

        # Schedule the background task
        background_tasks.add_task(
            _run_background_generation,
            job_id,
            user_id,
            start_date,
            duration_minutes,
            selected_days,
            weeks_needed
        )

        return {
            "success": True,
            "message": f"Generating {workouts_needed} more workouts",
            "needs_generation": True,
            "job_id": job_id,
            "start_date": start_date,
            "workouts_to_generate": workouts_needed,
            "weeks": weeks_needed
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Generate-More] Failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
