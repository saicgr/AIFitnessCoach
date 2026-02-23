"""
Workout exercise modification API endpoints.

This module handles exercise modifications within workouts:
- PUT /{workout_id}/exercises - Update workout exercises
- PUT /{workout_id}/warmup/exercises - Update warmup exercises
- PUT /{workout_id}/stretches/exercises - Update stretch exercises
"""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import (
    Workout,
    UpdateWorkoutExercisesRequest,
    UpdateWarmupExercisesRequest,
    UpdateStretchExercisesRequest,
)

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
)

router = APIRouter()
logger = get_logger(__name__)


@router.put("/{workout_id}/exercises", response_model=Workout)
async def update_workout_exercises(workout_id: str, request: UpdateWorkoutExercisesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the exercises in a workout (add, remove, reorder).

    This updates the exercises_json field and re-indexes to RAG.
    """
    logger.info(f"Updating exercises for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get existing workout
        existing = db.get_workout(workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Convert exercises to dict list
        exercises_list = [ex.model_dump() for ex in request.exercises]

        # Update workout
        update_data = {
            "exercises_json": exercises_list,
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "manual_edit"
        }

        updated = db.update_workout(workout_id, update_data)

        # Log the change
        log_workout_change(
            workout_id=workout_id,
            user_id=existing.get("user_id"),
            change_type="exercises_updated",
            field_changed="exercises_json",
            change_source="manual_edit",
            new_value={"exercises_count": len(exercises_list)}
        )

        # Re-index to RAG
        updated_workout = row_to_workout(updated)
        await index_workout_to_rag(updated_workout)

        logger.info(f"Workout exercises updated: id={workout_id}, count={len(exercises_list)}")
        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update workout exercises: {e}")
        raise safe_internal_error(e, "exercises")


@router.put("/{workout_id}/warmup/exercises")
async def update_warmup_exercises(workout_id: str, request: UpdateWarmupExercisesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the warmup exercises for a workout.
    """
    logger.info(f"Updating warmup exercises for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Check workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get existing warmup
        result = db.client.table("warmups").select("*").eq("workout_id", workout_id).eq("is_current", True).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Warmup not found for this workout")

        warmup = result.data[0]

        # Convert exercises to dict list
        exercises_list = [ex.model_dump() for ex in request.exercises]

        # Update warmup
        db.client.table("warmups").update({
            "exercises_json": exercises_list,
            "updated_at": datetime.now().isoformat()
        }).eq("id", warmup["id"]).execute()

        logger.info(f"Warmup exercises updated: workout_id={workout_id}, count={len(exercises_list)}")
        return {"success": True, "exercises_count": len(exercises_list)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update warmup exercises: {e}")
        raise safe_internal_error(e, "exercises")


@router.put("/{workout_id}/stretches/exercises")
async def update_stretch_exercises(workout_id: str, request: UpdateStretchExercisesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the stretch exercises for a workout.
    """
    logger.info(f"Updating stretch exercises for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Check workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get existing stretches
        result = db.client.table("stretches").select("*").eq("workout_id", workout_id).eq("is_current", True).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Stretches not found for this workout")

        stretches = result.data[0]

        # Convert exercises to dict list
        exercises_list = [ex.model_dump() for ex in request.exercises]

        # Update stretches
        db.client.table("stretches").update({
            "exercises_json": exercises_list,
            "updated_at": datetime.now().isoformat()
        }).eq("id", stretches["id"]).execute()

        logger.info(f"Stretch exercises updated: workout_id={workout_id}, count={len(exercises_list)}")
        return {"success": True, "exercises_count": len(exercises_list)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update stretch exercises: {e}")
        raise safe_internal_error(e, "exercises")
