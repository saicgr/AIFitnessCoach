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


def _resolve_canonical_exercise(db, exercise_name: str, exercise_id):
    """Resolve a Quick-Add/picker name against `exercise_library_cleaned`.

    The UI displays a title-cased/cleaned name while the library stores
    exercise_name inconsistently cased (e.g. "barbell bench press"), so an
    exact-match write silently persists `exercise_id: null` — the favorite
    can never be matched back to a real exercise at generation time.
    `exercise_library_cleaned` unions `exercise_library` with
    `exercise_library_manual` and exposes the already-cleaned display name
    the Quick-Add chips show (e.g. "Lat Pulldown", "Leg Press" only exist
    under this cleaned name, sourced from `exercise_library_manual`, not the
    raw `exercise_library` table). `ilike` with no wildcards is a
    case-insensitive equality check, so this resolves the same row
    regardless of casing without over-matching. If the caller already
    supplied an exercise_id (picked from the library, already canonical) it
    is trusted as-is. Falls back to the name/id as given when no library row
    matches, so a genuinely-missing name still saves instead of failing the
    request.
    """
    if exercise_id:
        return exercise_id, exercise_name
    if not exercise_name:
        return exercise_id, exercise_name
    try:
        match = db.client.table("exercise_library_cleaned").select(
            "id, name"
        ).ilike("name", exercise_name).limit(1).execute()
        if match.data:
            row = match.data[0]
            return row["id"], row["name"]
    except Exception as e:
        logger.warning(f"Canonical exercise lookup failed for '{exercise_name}': {e}")
    return exercise_id, exercise_name


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

        # Resolve to the canonical library row (case-insensitive) so the
        # favorite carries a real exercise_id instead of a name-only entry
        # the generator can never match (see rows 187/233).
        resolved_id, resolved_name = _resolve_canonical_exercise(
            db, request.exercise_name, request.exercise_id
        )

        # Check if already favorited
        existing = db.client.table("favorite_exercises").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", resolved_name).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="Exercise is already in favorites"
            )

        # Add to favorites
        result = db.client.table("favorite_exercises").insert({
            "user_id": user_id,
            "exercise_name": resolved_name,
            "exercise_id": resolved_id,
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

    Returns active (not expired, not used) exercises, PLUS spent exercises
    (`used_at` set) whose destination workout hasn't happened yet — the
    "added to upcoming" set (row 280). An item whose destination workout is
    already completed (or no longer resolvable) is dropped entirely rather
    than lingering as history.
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

        # "Added to upcoming": spent items whose destination workout hasn't
        # happened yet, so the tab can show where each one actually landed
        # instead of either hiding it or leaving it rendered as pending.
        try:
            used_result = db.client.table("exercise_queue").select("*").eq(
                "user_id", user_id
            ).not_.is_("used_at", "null").not_.is_(
                "used_in_workout_id", "null"
            ).order("used_at", desc=True).limit(50).execute()
            used_rows = used_result.data or []
        except Exception as ue:
            logger.warning(f"Could not fetch spent queue items: {ue}")
            used_rows = []

        if used_rows:
            workout_ids = list({r["used_in_workout_id"] for r in used_rows})
            try:
                workouts_resp = db.client.table("workouts").select(
                    "id, name, scheduled_date, is_completed"
                ).in_("id", workout_ids).execute()
                workouts_by_id = {str(w["id"]): w for w in (workouts_resp.data or [])}
            except Exception as we:
                logger.warning(f"Could not resolve destination workouts: {we}")
                workouts_by_id = {}

            for row in used_rows:
                workout = workouts_by_id.get(str(row["used_in_workout_id"]))
                if not workout or workout.get("is_completed"):
                    continue
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
                    used_in_workout_id=str(row["used_in_workout_id"]),
                    used_in_workout_name=workout.get("name"),
                    used_in_workout_date=workout.get("scheduled_date"),
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

        # Check whether this queue entry was already consumed by the workout
        # generator BEFORE deleting — the client's "won't be included in your
        # next workout" confirmation can only be true for a row that hasn't
        # been used yet. Once `used_at` is set, the exercise has already been
        # written into a real workout and deleting this bookkeeping row does
        # not pull it back out, so the caller needs to know that happened.
        existing = db.client.table("exercise_queue").select(
            "used_at"
        ).eq("user_id", user_id).eq("exercise_name", decoded_name).execute()
        already_used = any(row.get("used_at") for row in (existing.data or []))

        # Delete from queue
        result = db.client.table("exercise_queue").delete().eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found in queue")

        logger.info(f"Removed from queue: {decoded_name} for user {user_id}")

        return {
            "message": "Removed from queue successfully",
            "exercise_name": decoded_name,
            "already_used": already_used,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove from exercise queue: {e}", exc_info=True)
        raise safe_internal_error(e, "users")
