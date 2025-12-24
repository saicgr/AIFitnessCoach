"""
Workout CRUD API endpoints.

This module handles basic create, read, update, delete operations for workouts:
- POST / - Create a new workout
- GET / - List workouts for a user
- GET /{id} - Get workout by ID
- PUT /{id} - Update workout
- DELETE /{id} - Delete workout
- POST /{id}/complete - Mark workout as completed
"""
import json
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Query

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import Workout, WorkoutCreate, WorkoutUpdate

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
)

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=Workout)
async def create_workout(workout: WorkoutCreate):
    """Create a new workout."""
    logger.info(f"Creating workout for user {workout.user_id}: {workout.name}")
    try:
        db = get_supabase_db()

        exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json

        workout_data = {
            "user_id": workout.user_id,
            "name": workout.name,
            "type": workout.type,
            "difficulty": workout.difficulty,
            "scheduled_date": str(workout.scheduled_date),
            "exercises_json": exercises,
            "duration_minutes": workout.duration_minutes,
            "generation_method": workout.generation_method,
            "generation_source": workout.generation_source,
            "generation_metadata": workout.generation_metadata,
        }

        created = db.create_workout(workout_data)
        logger.info(f"Workout created: id={created['id']}")

        log_workout_change(
            workout_id=created['id'],
            user_id=workout.user_id,
            change_type="created",
            change_source=workout.generation_source or "api",
            new_value={"name": workout.name, "type": workout.type, "exercises_count": len(exercises)}
        )

        created_workout = row_to_workout(created)
        await index_workout_to_rag(created_workout)

        return created_workout

    except Exception as e:
        logger.error(f"Failed to create workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/", response_model=List[Workout])
async def list_workouts(
    user_id: str,
    is_completed: Optional[bool] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    """List workouts for a user with optional filters."""
    logger.info(f"Listing workouts for user {user_id}")
    try:
        db = get_supabase_db()
        rows = db.list_workouts(
            user_id=user_id,
            is_completed=is_completed,
            from_date=str(from_date) if from_date else None,
            to_date=str(to_date) if to_date else None,
            limit=limit,
            offset=offset,
        )
        logger.info(f"Found {len(rows)} workouts for user {user_id}")
        return [row_to_workout(row) for row in rows]

    except Exception as e:
        logger.error(f"Failed to list workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{workout_id}", response_model=Workout)
async def get_workout(workout_id: str):
    """Get a workout by ID."""
    logger.debug(f"Fetching workout: id={workout_id}")
    try:
        db = get_supabase_db()
        row = db.get_workout(workout_id)

        if not row:
            logger.warning(f"Workout not found: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        return row_to_workout(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{workout_id}", response_model=Workout)
async def update_workout(workout_id: str, workout: WorkoutUpdate):
    """Update a workout."""
    logger.info(f"Updating workout: id={workout_id}")
    try:
        db = get_supabase_db()

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found for update: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        update_data = {}
        if workout.name is not None:
            update_data["name"] = workout.name
        if workout.type is not None:
            update_data["type"] = workout.type
        if workout.difficulty is not None:
            update_data["difficulty"] = workout.difficulty
        if workout.scheduled_date is not None:
            update_data["scheduled_date"] = str(workout.scheduled_date)
        if workout.is_completed is not None:
            update_data["is_completed"] = workout.is_completed
        if workout.exercises_json is not None:
            exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json
            update_data["exercises"] = exercises
        if workout.last_modified_method is not None:
            update_data["last_modified_method"] = workout.last_modified_method

        if update_data:
            update_data["last_modified_at"] = datetime.now().isoformat()
            updated = db.update_workout(workout_id, update_data)
            logger.debug(f"Updated {len(update_data)} fields for workout {workout_id}")
        else:
            updated = existing

        # Log field changes
        current_workout = row_to_workout(existing)
        if workout.name is not None and workout.name != current_workout.name:
            log_workout_change(workout_id, current_workout.user_id, "updated", "name", current_workout.name, workout.name)
        if workout.exercises_json is not None:
            log_workout_change(workout_id, current_workout.user_id, "updated", "exercises", None, {"updated": True})

        updated_workout = row_to_workout(updated)
        logger.info(f"Workout updated: id={workout_id}")
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{workout_id}")
async def delete_workout(workout_id: str):
    """Delete a workout and all related records."""
    logger.info(f"Deleting workout: id={workout_id}")
    try:
        db = get_supabase_db()

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found for deletion: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        # Delete related records first
        db.delete_workout_changes_by_workout(workout_id)
        db.delete_workout_logs_by_workout(workout_id)
        db.delete_workout(workout_id)

        logger.info(f"Workout deleted: id={workout_id}")
        return {"message": "Workout deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{workout_id}/complete", response_model=Workout)
async def complete_workout(workout_id: str):
    """Mark a workout as completed."""
    logger.info(f"Completing workout: id={workout_id}")
    try:
        db = get_supabase_db()

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        update_data = {
            "is_completed": True,
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "completed",
        }
        updated = db.update_workout(workout_id, update_data)
        workout = row_to_workout(updated)

        logger.info(f"Workout completed: id={workout_id}")

        log_workout_change(
            workout_id=workout_id,
            user_id=workout.user_id,
            change_type="completed",
            field_changed="is_completed",
            old_value=False,
            new_value=True,
            change_source="user"
        )

        await index_workout_to_rag(workout)
        return workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))
