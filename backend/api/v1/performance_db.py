"""
Performance logging API endpoints with Supabase.

ENDPOINTS:
- POST /api/v1/performance-db/logs - Create performance log
- GET  /api/v1/performance-db/logs - List performance logs
- POST /api/v1/performance-db/workout-logs - Create workout log
- GET  /api/v1/performance-db/workout-logs - List workout logs
- GET  /api/v1/performance-db/strength-records - Get strength records
- GET  /api/v1/performance-db/weekly-volume - Get weekly volume
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date, timedelta

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import (
    PerformanceLog, PerformanceLogCreate,
    WorkoutLog, WorkoutLogCreate,
    StrengthRecord, StrengthRecordCreate,
    WeeklyVolume, WeeklyVolumeCreate,
)

router = APIRouter()
logger = get_logger(__name__)


def row_to_performance_log(row: dict) -> PerformanceLog:
    """Convert a Supabase row dict to PerformanceLog model."""
    return PerformanceLog(
        id=row.get("id"),
        workout_log_id=row.get("workout_log_id"),
        user_id=row.get("user_id"),
        exercise_id=row.get("exercise_id"),
        exercise_name=row.get("exercise_name"),
        set_number=row.get("set_number"),
        reps_completed=row.get("reps_completed"),
        weight_kg=row.get("weight_kg"),
        set_type=row.get("set_type"),
        rpe=row.get("rpe"),
        rir=row.get("rir"),
        tempo=row.get("tempo"),
        is_completed=row.get("is_completed"),
        failed_at_rep=row.get("failed_at_rep"),
        notes=row.get("notes"),
        recorded_at=row.get("recorded_at"),
    )


def row_to_workout_log(row: dict) -> WorkoutLog:
    """Convert a Supabase row dict to WorkoutLog model."""
    return WorkoutLog(
        id=row.get("id"),
        workout_id=row.get("workout_id"),
        user_id=row.get("user_id"),
        sets_json=row.get("sets_json"),
        completed_at=row.get("completed_at"),
        total_time_seconds=row.get("total_time_seconds"),
    )


def row_to_strength_record(row: dict) -> StrengthRecord:
    """Convert a Supabase row dict to StrengthRecord model."""
    return StrengthRecord(
        id=row.get("id"),
        user_id=row.get("user_id"),
        exercise_id=row.get("exercise_id"),
        exercise_name=row.get("exercise_name"),
        weight_kg=row.get("weight_kg"),
        reps=row.get("reps"),
        estimated_1rm=row.get("estimated_1rm"),
        rpe=row.get("rpe"),
        is_pr=row.get("is_pr"),
        achieved_at=row.get("achieved_at"),
    )


def row_to_weekly_volume(row: dict) -> WeeklyVolume:
    """Convert a Supabase row dict to WeeklyVolume model."""
    return WeeklyVolume(
        id=row.get("id"),
        user_id=row.get("user_id"),
        muscle_group=row.get("muscle_group"),
        week_number=row.get("week_number"),
        year=row.get("year"),
        total_sets=row.get("total_sets"),
        total_reps=row.get("total_reps"),
        total_volume_kg=row.get("total_volume_kg"),
        frequency=row.get("frequency"),
        target_sets=row.get("target_sets"),
        recovery_status=row.get("recovery_status"),
        updated_at=row.get("updated_at"),
    )


# ============ Performance Logs ============

@router.post("/logs", response_model=PerformanceLog)
async def create_performance_log(log: PerformanceLogCreate):
    """Create a performance log entry."""
    try:
        db = get_supabase_db()

        log_data = {
            "workout_log_id": log.workout_log_id,
            "user_id": log.user_id,
            "exercise_id": log.exercise_id,
            "exercise_name": log.exercise_name,
            "set_number": log.set_number,
            "reps_completed": log.reps_completed,
            "weight_kg": log.weight_kg,
            "set_type": log.set_type,
            "rpe": log.rpe,
            "rir": log.rir,
            "tempo": log.tempo,
            "is_completed": log.is_completed,
            "failed_at_rep": log.failed_at_rep,
            "notes": log.notes,
        }

        created = db.create_performance_log(log_data)
        logger.info(f"Performance log created: id={created['id']}, user_id={log.user_id}")
        return row_to_performance_log(created)

    except Exception as e:
        logger.error(f"Error creating performance log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/logs", response_model=List[PerformanceLog])
async def list_performance_logs(
    user_id: str,
    exercise_id: Optional[str] = None,
    limit: int = Query(default=50, ge=1, le=200),
):
    """List performance logs for a user."""
    try:
        db = get_supabase_db()
        rows = db.list_performance_logs(
            user_id=user_id,
            exercise_id=exercise_id,
            limit=limit,
        )
        logger.info(f"Listed {len(rows)} performance logs for user {user_id}")
        return [row_to_performance_log(row) for row in rows]

    except Exception as e:
        logger.error(f"Error listing performance logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Workout Logs ============

@router.post("/workout-logs", response_model=WorkoutLog)
async def create_workout_log(log: WorkoutLogCreate):
    """Create a workout log entry."""
    try:
        db = get_supabase_db()

        log_data = {
            "workout_id": log.workout_id,
            "user_id": log.user_id,
            "sets_json": log.sets_json,
            "total_time_seconds": log.total_time_seconds,
        }

        created = db.create_workout_log(log_data)
        logger.info(f"Workout log created: id={created['id']}, user_id={log.user_id}")
        return row_to_workout_log(created)

    except Exception as e:
        logger.error(f"Error creating workout log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/workout-logs", response_model=List[WorkoutLog])
async def list_workout_logs(
    user_id: str,
    limit: int = Query(default=50, ge=1, le=200),
):
    """List workout logs for a user."""
    try:
        db = get_supabase_db()
        rows = db.list_workout_logs(user_id=user_id, limit=limit)
        logger.info(f"Listed {len(rows)} workout logs for user {user_id}")
        return [row_to_workout_log(row) for row in rows]

    except Exception as e:
        logger.error(f"Error listing workout logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Strength Records ============

@router.post("/strength-records", response_model=StrengthRecord)
async def create_strength_record(record: StrengthRecordCreate):
    """Create a strength record entry."""
    try:
        db = get_supabase_db()

        record_data = {
            "user_id": record.user_id,
            "exercise_id": record.exercise_id,
            "exercise_name": record.exercise_name,
            "weight_kg": record.weight_kg,
            "reps": record.reps,
            "estimated_1rm": record.estimated_1rm,
            "rpe": record.rpe,
            "is_pr": record.is_pr,
        }

        created = db.create_strength_record(record_data)
        logger.info(f"Strength record created: id={created['id']}, user_id={record.user_id}")
        return row_to_strength_record(created)

    except Exception as e:
        logger.error(f"Error creating strength record: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/strength-records", response_model=List[StrengthRecord])
async def list_strength_records(
    user_id: str,
    exercise_id: Optional[str] = None,
    prs_only: bool = False,
    limit: int = Query(default=50, ge=1, le=200),
):
    """List strength records for a user."""
    try:
        db = get_supabase_db()
        rows = db.list_strength_records(
            user_id=user_id,
            exercise_id=exercise_id,
            prs_only=prs_only,
            limit=limit,
        )
        logger.info(f"Listed {len(rows)} strength records for user {user_id}")
        return [row_to_strength_record(row) for row in rows]

    except Exception as e:
        logger.error(f"Error listing strength records: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Weekly Volume ============

@router.post("/weekly-volume", response_model=WeeklyVolume)
async def upsert_weekly_volume(volume: WeeklyVolumeCreate):
    """Create or update weekly volume entry."""
    try:
        db = get_supabase_db()

        volume_data = {
            "user_id": volume.user_id,
            "muscle_group": volume.muscle_group,
            "week_number": volume.week_number,
            "year": volume.year,
            "total_sets": volume.total_sets,
            "total_reps": volume.total_reps,
            "total_volume_kg": volume.total_volume_kg,
            "frequency": volume.frequency,
            "target_sets": volume.target_sets,
            "recovery_status": volume.recovery_status,
        }

        created = db.upsert_weekly_volume(volume_data)
        logger.info(f"Weekly volume upserted: id={created['id']}, user_id={volume.user_id}")
        return row_to_weekly_volume(created)

    except Exception as e:
        logger.error(f"Error upserting weekly volume: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/weekly-volume", response_model=List[WeeklyVolume])
async def list_weekly_volumes(
    user_id: str,
    week_number: Optional[int] = None,
    year: Optional[int] = None,
):
    """List weekly volumes for a user."""
    try:
        db = get_supabase_db()
        rows = db.list_weekly_volumes(
            user_id=user_id,
            week_number=week_number,
            year=year,
        )
        logger.info(f"Listed {len(rows)} weekly volumes for user {user_id}")
        return [row_to_weekly_volume(row) for row in rows]

    except Exception as e:
        logger.error(f"Error listing weekly volumes: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Streaks ============

class StreakResponse(BaseModel):
    """Response model for workout streaks."""
    current_streak: int  # Current consecutive days
    longest_streak: int  # Best ever streak
    last_workout_date: Optional[str] = None  # ISO date string
    is_active_today: bool  # Did user workout today?
    streak_at_risk: bool  # Will lose streak if no workout today?


@router.get("/streak/{user_id}", response_model=StreakResponse)
async def get_user_streak(user_id: str):
    """
    Get workout streak information for a user.

    Streak is calculated based on consecutive days with completed workouts.
    A day counts if any workout was completed on that date.
    """
    try:
        db = get_supabase_db()

        # Get all workout logs for the user, ordered by completion date
        rows = db.list_workout_logs(user_id=user_id, limit=500)

        if not rows:
            return StreakResponse(
                current_streak=0,
                longest_streak=0,
                last_workout_date=None,
                is_active_today=False,
                streak_at_risk=False,
            )

        # Extract unique dates when workouts were completed
        workout_dates: set = set()
        for row in rows:
            completed_at = row.get("completed_at")
            if completed_at:
                # Parse ISO datetime and extract date
                if isinstance(completed_at, str):
                    dt = datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
                    workout_dates.add(dt.date())
                elif isinstance(completed_at, datetime):
                    workout_dates.add(completed_at.date())

        if not workout_dates:
            return StreakResponse(
                current_streak=0,
                longest_streak=0,
                last_workout_date=None,
                is_active_today=False,
                streak_at_risk=False,
            )

        # Sort dates in descending order (most recent first)
        sorted_dates = sorted(workout_dates, reverse=True)
        last_workout = sorted_dates[0]
        today = date.today()
        yesterday = today - timedelta(days=1)

        # Calculate current streak
        current_streak = 0
        check_date = today

        # Start counting from today or yesterday
        if last_workout == today:
            current_streak = 1
            check_date = today - timedelta(days=1)
        elif last_workout == yesterday:
            current_streak = 1
            check_date = yesterday - timedelta(days=1)
        else:
            # Streak is broken - last workout was more than 1 day ago
            current_streak = 0
            check_date = None

        # Count consecutive days going backwards
        if check_date:
            while check_date in workout_dates:
                current_streak += 1
                check_date -= timedelta(days=1)

        # Calculate longest streak ever
        longest_streak = 0
        sorted_asc = sorted(workout_dates)

        if sorted_asc:
            streak = 1
            for i in range(1, len(sorted_asc)):
                if sorted_asc[i] - sorted_asc[i-1] == timedelta(days=1):
                    streak += 1
                else:
                    longest_streak = max(longest_streak, streak)
                    streak = 1
            longest_streak = max(longest_streak, streak)

        # Ensure current streak is considered for longest
        longest_streak = max(longest_streak, current_streak)

        is_active_today = last_workout == today
        streak_at_risk = (current_streak > 0 and not is_active_today)

        logger.info(f"Streak for user {user_id}: current={current_streak}, longest={longest_streak}")

        return StreakResponse(
            current_streak=current_streak,
            longest_streak=longest_streak,
            last_workout_date=last_workout.isoformat(),
            is_active_today=is_active_today,
            streak_at_risk=streak_at_risk,
        )

    except Exception as e:
        logger.error(f"Error calculating streak: {e}")
        raise HTTPException(status_code=500, detail=str(e))
