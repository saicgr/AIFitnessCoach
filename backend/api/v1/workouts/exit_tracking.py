"""
Workout exit/quit tracking API endpoints.

This module handles tracking when users exit workouts early:
- POST /{workout_id}/exit - Log a workout exit
- GET /{workout_id}/exits - Get exit records for a workout
- GET /user/{user_id}/exit-stats - Get exit statistics for a user
"""
from typing import List

from fastapi import APIRouter, HTTPException

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import WorkoutExit, WorkoutExitCreate

from .utils import log_workout_change

router = APIRouter()
logger = get_logger(__name__)


@router.post("/{workout_id}/exit", response_model=WorkoutExit)
async def log_workout_exit(workout_id: str, exit_data: WorkoutExitCreate):
    """
    Log a workout exit/quit event with reason and progress tracking.

    This endpoint records when a user exits a workout before completing it,
    including the reason for quitting and how much progress they made.

    Exit reasons:
    - completed: Successfully finished the workout
    - too_tired: User felt too fatigued to continue
    - out_of_time: User ran out of time
    - not_feeling_well: User felt unwell (illness, dizziness, etc.)
    - equipment_unavailable: Required equipment was not available
    - injury: User experienced pain or injury
    - other: Any other reason (should include notes)
    """
    logger.info(f"Logging workout exit: workout_id={workout_id}, reason={exit_data.exit_reason}")

    try:
        db = get_supabase_db()

        # Verify the workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Ensure workout_id matches
        if exit_data.workout_id != workout_id:
            exit_data.workout_id = workout_id

        # Create the workout exit record
        exit_record = {
            "user_id": exit_data.user_id,
            "workout_id": workout_id,
            "exit_reason": exit_data.exit_reason,
            "exit_notes": exit_data.exit_notes,
            "exercises_completed": exit_data.exercises_completed,
            "total_exercises": exit_data.total_exercises,
            "sets_completed": exit_data.sets_completed,
            "time_spent_seconds": exit_data.time_spent_seconds,
            "progress_percentage": exit_data.progress_percentage,
        }

        # Insert into workout_exits table
        result = db.client.table("workout_exits").insert(exit_record).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create workout exit record")

        created = result.data[0]
        logger.info(f"Workout exit logged: id={created['id']}, reason={exit_data.exit_reason}")

        # Log the change for audit trail
        log_workout_change(
            workout_id=workout_id,
            user_id=exit_data.user_id,
            change_type="exited",
            field_changed="exit_reason",
            new_value={
                "reason": exit_data.exit_reason,
                "progress": exit_data.progress_percentage,
                "sets_completed": exit_data.sets_completed
            },
            change_source="user",
            change_reason=exit_data.exit_notes
        )

        return WorkoutExit(
            id=str(created["id"]),
            user_id=created["user_id"],
            workout_id=created["workout_id"],
            exit_reason=created["exit_reason"],
            exit_notes=created.get("exit_notes"),
            exercises_completed=created["exercises_completed"],
            total_exercises=created["total_exercises"],
            sets_completed=created["sets_completed"],
            time_spent_seconds=created["time_spent_seconds"],
            progress_percentage=created["progress_percentage"],
            exited_at=created.get("exited_at") or created.get("created_at")
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log workout exit: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{workout_id}/exits", response_model=List[WorkoutExit])
async def get_workout_exits(workout_id: str):
    """Get all exit records for a workout."""
    logger.info(f"Getting exit records for workout {workout_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("workout_exits").select("*").eq("workout_id", workout_id).order("exited_at", desc=True).execute()

        return [
            WorkoutExit(
                id=str(row["id"]),
                user_id=row["user_id"],
                workout_id=row["workout_id"],
                exit_reason=row["exit_reason"],
                exit_notes=row.get("exit_notes"),
                exercises_completed=row["exercises_completed"],
                total_exercises=row["total_exercises"],
                sets_completed=row["sets_completed"],
                time_spent_seconds=row["time_spent_seconds"],
                progress_percentage=row["progress_percentage"],
                exited_at=row.get("exited_at") or row.get("created_at")
            )
            for row in result.data
        ]

    except Exception as e:
        logger.error(f"Failed to get workout exits: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/exit-stats")
async def get_user_exit_stats(user_id: str):
    """Get exit statistics for a user - helpful for understanding workout completion patterns."""
    logger.info(f"Getting exit stats for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("workout_exits").select("*").eq("user_id", user_id).execute()

        if not result.data:
            return {
                "total_exits": 0,
                "exits_by_reason": {},
                "avg_progress_at_exit": 0,
                "total_time_spent_seconds": 0
            }

        exits = result.data
        total_exits = len(exits)

        # Group by reason
        exits_by_reason = {}
        for exit in exits:
            reason = exit["exit_reason"]
            exits_by_reason[reason] = exits_by_reason.get(reason, 0) + 1

        # Calculate averages
        avg_progress = sum(e["progress_percentage"] for e in exits) / total_exits if total_exits > 0 else 0
        total_time = sum(e["time_spent_seconds"] for e in exits)

        return {
            "total_exits": total_exits,
            "exits_by_reason": exits_by_reason,
            "avg_progress_at_exit": round(avg_progress, 1),
            "total_time_spent_seconds": total_time
        }

    except Exception as e:
        logger.error(f"Failed to get user exit stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))
