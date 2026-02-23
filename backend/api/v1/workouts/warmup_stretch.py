"""
Warmup and stretch API endpoints.

This module handles warmup and cool-down stretch operations:
- GET /{workout_id}/warmup - Get warmup exercises
- GET /{workout_id}/stretches - Get cool-down stretches
- POST /{workout_id}/warmup - Create warmup exercises
- POST /{workout_id}/stretches - Create cool-down stretches
- POST /{workout_id}/warmup-and-stretches - Create both
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.warmup_stretch_service import get_warmup_stretch_service

from .utils import parse_json_field

router = APIRouter()
logger = get_logger(__name__)

# Default durations for warmup and stretch (in minutes)
DEFAULT_WARMUP_DURATION = 5
DEFAULT_STRETCH_DURATION = 5


def get_user_warmup_stretch_preferences(user_id: str) -> tuple[int, int]:
    """
    Get user's preferred warmup and stretch durations from their preferences.

    Args:
        user_id: The user's ID

    Returns:
        Tuple of (warmup_duration_minutes, stretch_duration_minutes)
    """
    try:
        db = get_supabase_db()
        user = db.get_user(user_id)

        if not user:
            return DEFAULT_WARMUP_DURATION, DEFAULT_STRETCH_DURATION

        # Parse preferences JSON
        preferences = parse_json_field(user.get("preferences"), {})

        warmup_duration = preferences.get("warmup_duration_minutes", DEFAULT_WARMUP_DURATION)
        stretch_duration = preferences.get("stretch_duration_minutes", DEFAULT_STRETCH_DURATION)

        # Validate ranges (1-15 minutes)
        warmup_duration = max(1, min(15, int(warmup_duration)))
        stretch_duration = max(1, min(15, int(stretch_duration)))

        return warmup_duration, stretch_duration

    except Exception as e:
        logger.warning(f"Error reading user preferences for warmup/stretch duration: {e}")
        return DEFAULT_WARMUP_DURATION, DEFAULT_STRETCH_DURATION


@router.get("/{workout_id}/warmup")
async def get_workout_warmup(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "warmup_stretch")


@router.get("/{workout_id}/stretches")
async def get_workout_stretches(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "warmup_stretch")


@router.post("/{workout_id}/warmup")
async def create_workout_warmup(workout_id: str, duration_minutes: Optional[int] = None,
    current_user: dict = Depends(get_current_user),
):
    """Generate and create warmup exercises for an existing workout with variety tracking.

    If duration_minutes is not provided, uses the user's preference or default (5 minutes).
    """
    logger.info(f"Creating warmup for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises and user_id
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        # Use provided duration or get from user preferences
        if duration_minutes is None and user_id:
            warmup_pref, _ = get_user_warmup_stretch_preferences(user_id)
            duration_minutes = warmup_pref
        elif duration_minutes is None:
            duration_minutes = DEFAULT_WARMUP_DURATION

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
        raise safe_internal_error(e, "warmup_stretch")


@router.post("/{workout_id}/stretches")
async def create_workout_stretches(workout_id: str, duration_minutes: Optional[int] = None,
    current_user: dict = Depends(get_current_user),
):
    """Generate and create cool-down stretches for an existing workout with variety tracking.

    If duration_minutes is not provided, uses the user's preference or default (5 minutes).
    """
    logger.info(f"Creating stretches for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises and user_id
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        # Use provided duration or get from user preferences
        if duration_minutes is None and user_id:
            _, stretch_pref = get_user_warmup_stretch_preferences(user_id)
            duration_minutes = stretch_pref
        elif duration_minutes is None:
            duration_minutes = DEFAULT_STRETCH_DURATION

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
        raise safe_internal_error(e, "warmup_stretch")


@router.post("/{workout_id}/warmup-and-stretches")
async def create_workout_warmup_and_stretches(
    workout_id: str,
    warmup_duration: Optional[int] = None,
    stretch_duration: Optional[int] = None,
    current_user: dict = Depends(get_current_user),
):
    """Generate and create both warmup and stretches for an existing workout with variety tracking.

    If warmup_duration or stretch_duration is not provided, uses the user's preference or defaults.
    """
    logger.info(f"Creating warmup and stretches for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises and user_id
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])
        user_id = workout.get("user_id")

        # Use provided durations or get from user preferences
        if (warmup_duration is None or stretch_duration is None) and user_id:
            warmup_pref, stretch_pref = get_user_warmup_stretch_preferences(user_id)
            if warmup_duration is None:
                warmup_duration = warmup_pref
            if stretch_duration is None:
                stretch_duration = stretch_pref
        else:
            if warmup_duration is None:
                warmup_duration = DEFAULT_WARMUP_DURATION
            if stretch_duration is None:
                stretch_duration = DEFAULT_STRETCH_DURATION

        service = get_warmup_stretch_service()
        result = await service.generate_warmup_and_stretches_for_workout(
            workout_id, exercises, warmup_duration, stretch_duration, user_id=user_id
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create warmup and stretches: {e}")
        raise safe_internal_error(e, "warmup_stretch")
