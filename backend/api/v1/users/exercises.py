"""
Favorite exercises and exercise queue endpoints.
"""
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from typing import List

from core.logger import get_logger

from api.v1.users.models import (
    FavoriteExerciseRequest,
    FavoriteExercise,
    QueueExerciseRequest,
    QueuedExercise,
    QueueExerciseUpdateRequest,
)

router = APIRouter()
logger = get_logger(__name__)


@router.get("/{user_id}/favorite-exercises", response_model=List[FavoriteExercise])
async def get_favorite_exercises(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get all favorite exercises for a user.

    Used by the workout generation system to prioritize exercises
    the user prefers. Addresses competitor feedback about favoriting
    exercises not helping with AI selection.
    """
    logger.info(f"Getting favorite exercises for user: {user_id}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get favorites
        result = db.client.table("favorite_exercises").select("*").eq(
            "user_id", user_id
        ).order("added_at", desc=True).execute()

        favorites = []
        for row in result.data:
            favorites.append(FavoriteExercise(
                id=row["id"],
                user_id=row["user_id"],
                exercise_name=row["exercise_name"],
                exercise_id=row.get("exercise_id"),
                added_at=row["added_at"],
            ))

        logger.info(f"Found {len(favorites)} favorite exercises for user {user_id}")
        return favorites

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get favorite exercises: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/favorite-exercises", response_model=FavoriteExercise)
async def add_favorite_exercise(user_id: str, request: FavoriteExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
    """Add an exercise to user's favorites.

    Favorited exercises get a 50% boost in similarity score during
    workout generation, making them more likely to be selected.
    """
    logger.info(f"Adding favorite exercise for user {user_id}: {request.exercise_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Check if already favorited
        existing = db.client.table("favorite_exercises").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="Exercise is already in favorites"
            )

        # Add to favorites
        result = db.client.table("favorite_exercises").insert({
            "user_id": user_id,
            "exercise_name": request.exercise_name,
            "exercise_id": request.exercise_id,
        }).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to add favorite"), "users")

        row = result.data[0]
        logger.info(f"Added favorite exercise: {request.exercise_name} for user {user_id}")

        return FavoriteExercise(
            id=row["id"],
            user_id=row["user_id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            added_at=row["added_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add favorite exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/favorite-exercises/{exercise_name}")
async def remove_favorite_exercise(user_id: str, exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
    """Remove an exercise from user's favorites.

    The exercise_name is URL-encoded, so spaces become %20.
    """
    # URL decode the exercise name
    from urllib.parse import unquote
    decoded_name = unquote(exercise_name)

    logger.info(f"Removing favorite exercise for user {user_id}: {decoded_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Delete the favorite
        result = db.client.table("favorite_exercises").delete().eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Favorite not found")

        logger.info(f"Removed favorite exercise: {decoded_name} for user {user_id}")

        return {"message": "Favorite removed successfully", "exercise_name": decoded_name}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove favorite exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


# =============================================================================
# EXERCISE QUEUE ENDPOINTS
# =============================================================================


@router.get("/{user_id}/exercise-queue", response_model=List[QueuedExercise])
async def get_exercise_queue(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get all queued exercises for a user.

    Only returns active (not expired, not used) exercises.
    Used by the workout generation system to include queued exercises.
    """
    logger.info(f"Getting exercise queue for user: {user_id}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get active queue items (not expired, not used)
        from datetime import datetime
        now = datetime.now().isoformat()

        result = db.client.table("exercise_queue").select("*").eq(
            "user_id", user_id
        ).is_("used_at", "null").gte(
            "expires_at", now
        ).order("priority", desc=False).order("added_at", desc=False).execute()

        queue = []
        for row in result.data:
            queue.append(QueuedExercise(
                id=row["id"],
                user_id=row["user_id"],
                exercise_name=row["exercise_name"],
                exercise_id=row.get("exercise_id"),
                priority=row.get("priority", 0),
                target_muscle_group=row.get("target_muscle_group"),
                added_at=row["added_at"],
                expires_at=row["expires_at"],
                used_at=row.get("used_at"),
            ))

        logger.info(f"Found {len(queue)} queued exercises for user {user_id}")
        return queue

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get exercise queue: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/exercise-queue")
async def add_to_exercise_queue(user_id: str, request: QueueExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
    """Add an exercise to user's workout queue.

    Queued exercises are included in the next matching workout.
    """
    logger.info(f"Adding to exercise queue for user {user_id}: {request.exercise_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Check if already queued
        existing = db.client.table("exercise_queue").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).is_("used_at", "null").execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="Exercise is already in queue"
            )

        # Add to queue
        result = db.client.table("exercise_queue").insert({
            "user_id": user_id,
            "exercise_name": request.exercise_name,
            "exercise_id": request.exercise_id,
            "priority": request.priority or 0,
            "target_muscle_group": request.target_muscle_group,
        }).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to add to queue"), "users")

        row = result.data[0]
        logger.info(f"Added to queue: {request.exercise_name} for user {user_id}")

        # Inject queued exercise into next workout using rule-based engine
        from api.v1.workouts.preference_engine import inject_queued_exercise_into_next_workout
        engine_result = await inject_queued_exercise_into_next_workout(
            db, user_id, request.exercise_name, row["id"]
        )
        logger.info(f"Queue injection result: {engine_result.get('message', '')}")

        response = QueuedExercise(
            id=row["id"],
            user_id=row["user_id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            priority=row.get("priority", 0),
            target_muscle_group=row.get("target_muscle_group"),
            added_at=row["added_at"],
            expires_at=row["expires_at"],
            used_at=row.get("used_at"),
        )
        # Return as dict with injection details
        result = response.model_dump()
        result["changes"] = engine_result.get("changes", [])
        result["engine_message"] = engine_result.get("message", "")
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add to exercise queue: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.put("/{user_id}/exercise-queue/{exercise_name}")
async def update_exercise_queue_item(user_id: str, exercise_name: str,
    request: QueueExerciseUpdateRequest,
    current_user: dict = Depends(get_current_user),
):
    """Update a queued exercise's priority or target muscle group."""
    from urllib.parse import unquote
    decoded_name = unquote(exercise_name)

    logger.info(f"Updating exercise queue item for user {user_id}: {decoded_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Build update data from non-None fields
        update_data = {}
        if request.priority is not None:
            update_data["priority"] = request.priority
        if request.target_muscle_group is not None:
            update_data["target_muscle_group"] = request.target_muscle_group

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = db.client.table("exercise_queue").update(update_data).eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).is_("used_at", "null").execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found in queue")

        row = result.data[0]
        logger.info(f"Updated queue item: {decoded_name} for user {user_id}")

        return QueuedExercise(
            id=row["id"],
            user_id=row["user_id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            priority=row.get("priority", 0),
            target_muscle_group=row.get("target_muscle_group"),
            added_at=row["added_at"],
            expires_at=row["expires_at"],
            used_at=row.get("used_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update exercise queue item: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/exercise-queue/{exercise_name}")
async def remove_from_exercise_queue(user_id: str, exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
    """Remove an exercise from user's workout queue."""
    from urllib.parse import unquote
    decoded_name = unquote(exercise_name)

    logger.info(f"Removing from exercise queue for user {user_id}: {decoded_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Delete from queue
        result = db.client.table("exercise_queue").delete().eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found in queue")

        logger.info(f"Removed from queue: {decoded_name} for user {user_id}")

        return {"message": "Removed from queue successfully", "exercise_name": decoded_name}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove from exercise queue: {e}", exc_info=True)
        raise safe_internal_error(e, "users")
