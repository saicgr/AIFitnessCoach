"""
Warmup and stretch API endpoints.

This module handles warmup and cool-down stretch operations:
- GET /{workout_id}/warmup - Get warmup exercises
- GET /{workout_id}/stretches - Get cool-down stretches
- POST /{workout_id}/warmup - Create warmup exercises
- POST /{workout_id}/stretches - Create cool-down stretches
- POST /{workout_id}/warmup-and-stretches - Create both
"""
from fastapi import APIRouter, HTTPException

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.warmup_stretch_service import get_warmup_stretch_service

from .utils import parse_json_field

router = APIRouter()
logger = get_logger(__name__)


@router.get("/{workout_id}/warmup")
async def get_workout_warmup(workout_id: str):
    """Get warmup exercises for a workout."""
    logger.info(f"Getting warmup for workout {workout_id}")
    try:
        service = get_warmup_stretch_service()
        warmup = service.get_warmup_for_workout(workout_id)

        if not warmup:
            raise HTTPException(status_code=404, detail="Warmup not found for this workout")

        return warmup

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get warmup: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{workout_id}/stretches")
async def get_workout_stretches(workout_id: str):
    """Get cool-down stretches for a workout."""
    logger.info(f"Getting stretches for workout {workout_id}")
    try:
        service = get_warmup_stretch_service()
        stretches = service.get_stretches_for_workout(workout_id)

        if not stretches:
            raise HTTPException(status_code=404, detail="Stretches not found for this workout")

        return stretches

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get stretches: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{workout_id}/warmup")
async def create_workout_warmup(workout_id: str, duration_minutes: int = 5):
    """Generate and create warmup exercises for an existing workout with variety tracking."""
    logger.info(f"Creating warmup for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises and user_id
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        service = get_warmup_stretch_service()
        warmup = await service.create_warmup_for_workout(
            workout_id, exercises, duration_minutes, user_id=user_id
        )

        if not warmup:
            raise HTTPException(status_code=500, detail="Failed to create warmup")

        return warmup

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create warmup: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{workout_id}/stretches")
async def create_workout_stretches(workout_id: str, duration_minutes: int = 5):
    """Generate and create cool-down stretches for an existing workout with variety tracking."""
    logger.info(f"Creating stretches for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises and user_id
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        service = get_warmup_stretch_service()
        stretches = await service.create_stretches_for_workout(
            workout_id, exercises, duration_minutes, user_id=user_id
        )

        if not stretches:
            raise HTTPException(status_code=500, detail="Failed to create stretches")

        return stretches

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create stretches: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{workout_id}/warmup-and-stretches")
async def create_workout_warmup_and_stretches(
    workout_id: str,
    warmup_duration: int = 5,
    stretch_duration: int = 5
):
    """Generate and create both warmup and stretches for an existing workout with variety tracking."""
    logger.info(f"Creating warmup and stretches for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises and user_id
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        service = get_warmup_stretch_service()
        result = await service.generate_warmup_and_stretches_for_workout(
            workout_id, exercises, warmup_duration, stretch_duration, user_id=user_id
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create warmup and stretches: {e}")
        raise HTTPException(status_code=500, detail=str(e))
