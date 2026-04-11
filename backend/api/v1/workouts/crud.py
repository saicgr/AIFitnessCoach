"""
Workout CRUD API endpoints.

This module handles basic create, read, update, delete operations for workouts:
- POST / - Create a new workout
- GET / - List workouts for a user
- GET /{id} - Get workout by ID
- PUT /{id} - Update workout
- DELETE /{id} - Delete workout
- POST /{id}/complete - (in crud_completion.py)
- POST /{id}/uncomplete - (in crud_completion.py)
- GET /{id}/completion-summary - (in crud_completion.py)
- PATCH /{id}/exercise-sets - (in crud_completion.py)

Models are in crud_models.py, background tasks in crud_background_tasks.py.
Completion endpoints are in crud_completion.py.
"""
import json
from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks, Request
from core.auth import get_current_user, verify_user_ownership, verify_resource_ownership
from core.exceptions import safe_internal_error
from core.timezone_utils import user_today_date

from core.supabase_db import get_supabase_db
from core.db import get_supabase_db as get_db
from core.logger import get_logger
from models.schemas import Workout, WorkoutCreate, WorkoutUpdate

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
)
from .today import invalidate_today_workout_cache

# Re-export models for backward compatibility
from .crud_models import (
    PersonalRecordInfo,
    ExerciseComparisonInfo,
    WorkoutComparisonInfo,
    PerformanceComparisonInfo,
    WorkoutCompletionResponse,
    SetLogInfo,
    WorkoutSummaryResponse,
    UpdateExerciseSetsRequest,
)

# Completion endpoints are in crud_completion.py sub-router
from .crud_completion import router as completion_router

router = APIRouter()
logger = get_logger(__name__)

# Include completion sub-router (complete, uncomplete, completion-summary, exercise-sets)
router.include_router(completion_router)


@router.post("/", response_model=Workout)
async def create_workout(workout: WorkoutCreate,
    current_user: dict = Depends(get_current_user),
):
    """Create a new workout."""
    logger.info(f"Creating workout for user {workout.user_id}: {workout.name}")
    try:
        db = get_supabase_db()

        exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json

        # Override user_id with authenticated user to prevent IDOR
        workout.user_id = current_user["id"]

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
        logger.error(f"Failed to create workout: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


@router.get("/", response_model=List[Workout])
async def list_workouts(
    user_id: str = Query(..., description="User ID"),
    is_completed: Optional[bool] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    gym_profile_id: Optional[str] = Query(default=None, description="Filter by gym profile ID"),
    allow_multiple_per_date: bool = Query(default=False, description="Skip per-date deduplication"),
    current_user: dict = Depends(get_current_user),
):
    """List workouts for a user with optional filters."""
    verify_user_ownership(current_user, user_id)
    logger.info(f"Listing workouts for user {user_id}, gym_profile_id={gym_profile_id}")
    try:
        db = get_supabase_db()

        profile_filter = gym_profile_id
        if not profile_filter:
            try:
                active_result = db.client.table("gym_profiles") \
                    .select("id") \
                    .eq("user_id", user_id) \
                    .eq("is_active", True) \
                    .single() \
                    .execute()
                if active_result.data:
                    profile_filter = active_result.data.get("id")
                    logger.info(f"[GYM PROFILE] Using active profile {profile_filter} for workout list")
            except Exception:
                pass

        rows = db.list_workouts(
            user_id=user_id,
            is_completed=is_completed,
            from_date=str(from_date) if from_date else None,
            to_date=str(to_date) if to_date else None,
            limit=limit,
            offset=offset,
            gym_profile_id=profile_filter,
            allow_multiple_per_date=allow_multiple_per_date,
        )
        logger.info(f"Found {len(rows)} workouts for user {user_id} (profile: {profile_filter})")
        return [row_to_workout(row) for row in rows]

    except Exception as e:
        logger.error(f"Failed to list workouts: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


@router.get("/{workout_id}", response_model=Workout)
async def get_workout(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a workout by ID."""
    logger.debug(f"Fetching workout: id={workout_id}")
    try:
        db = get_supabase_db()
        row = db.get_workout(workout_id)
        verify_resource_ownership(current_user, row, "Workout")
        return row_to_workout(row)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


@router.put("/{workout_id}", response_model=Workout)
async def update_workout(workout_id: str, workout: WorkoutUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update a workout."""
    logger.info(f"Updating workout: id={workout_id}")
    try:
        db = get_supabase_db()

        existing = db.get_workout(workout_id)
        verify_resource_ownership(current_user, existing, "Workout")

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
        logger.error(f"Failed to update workout: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


@router.patch("/{workout_id}/favorite")
async def toggle_workout_favorite(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Toggle the favorite status of a workout."""
    user_id = current_user["id"]
    logger.info(f"Toggling favorite for workout: id={workout_id}, user={user_id}")
    try:
        db = get_supabase_db()
        existing = db.get_workout(workout_id)
        verify_resource_ownership(current_user, existing, "Workout")

        current_favorite = existing.get("is_favorite", False)
        new_favorite = not current_favorite

        db.client.table("workouts").update(
            {"is_favorite": new_favorite}
        ).eq("id", workout_id).execute()

        logger.info(f"Workout {workout_id} favorite: {new_favorite}")
        return {"workout_id": workout_id, "is_favorite": new_favorite}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to toggle workout favorite: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


@router.delete("/{workout_id}")
async def delete_workout(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a workout and all related records."""
    logger.info(f"Deleting workout: id={workout_id}")
    try:
        db = get_supabase_db()
        existing = db.get_workout(workout_id)
        verify_resource_ownership(current_user, existing, "Workout")

        # Extract info for cache invalidation before deleting
        scheduled_date = str(existing.get("scheduled_date", ""))[:10] or None
        gym_profile_id = existing.get("gym_profile_id")
        del_user_id = existing.get("user_id")

        db.delete_workout_changes_by_workout(workout_id)
        db.delete_workout_logs_by_workout(workout_id)
        db.delete_workout(workout_id)

        # Invalidate /today cache so next poll reflects the deletion
        await invalidate_today_workout_cache(del_user_id, gym_profile_id, scheduled_date)

        logger.info(f"Workout deleted: id={workout_id}")
        return {"message": "Workout deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete workout: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


@router.delete("/cleanup/{user_id}")
async def cleanup_old_workouts(
    request: Request,
    user_id: str,
    keep_count: int = Query(default=1, ge=1, le=10, description="Number of future workouts to keep"),
    current_user: dict = Depends(get_current_user),
):
    """Clean up old workouts for a user, keeping only the specified number of upcoming workouts."""
    verify_user_ownership(current_user, user_id)
    logger.info(f"[Cleanup] Starting cleanup for user {user_id}, keeping {keep_count} workout(s)")

    try:
        db = get_supabase_db()

        today = user_today_date(request, db, user_id).isoformat()
        all_workouts = db.client.table("workouts") \
            .select("id, scheduled_date, is_completed, name") \
            .eq("user_id", user_id) \
            .order("scheduled_date", desc=True) \
            .execute()

        if not all_workouts.data:
            return {"message": "No workouts to clean up", "deleted_count": 0}

        completed = []
        incomplete_future = []
        incomplete_past = []

        for w in all_workouts.data:
            sched = w.get("scheduled_date", "")[:10] if w.get("scheduled_date") else ""
            if w.get("is_completed"):
                completed.append(w)
            elif sched >= today:
                incomplete_future.append(w)
            else:
                incomplete_past.append(w)

        incomplete_future.sort(key=lambda x: x.get("scheduled_date", ""))
        workouts_to_keep = incomplete_future[:keep_count]
        workouts_to_delete = incomplete_future[keep_count:] + incomplete_past

        deleted_count = 0
        deleted_names = []

        for workout in workouts_to_delete:
            wid = workout["id"]
            try:
                db.delete_workout_changes_by_workout(wid)
                db.delete_workout_logs_by_workout(wid)
                db.delete_workout(wid)
                deleted_count += 1
                deleted_names.append(workout.get("name", "Unknown"))
            except Exception as e:
                logger.error(f"[Cleanup] Failed to delete workout {wid}: {e}", exc_info=True)

        logger.info(f"[Cleanup] Completed for user {user_id}: deleted {deleted_count}, kept {len(workouts_to_keep)} upcoming + {len(completed)} completed")

        return {
            "message": f"Cleanup complete. Deleted {deleted_count} workout(s).",
            "deleted_count": deleted_count,
            "deleted_names": deleted_names[:10],
            "kept_upcoming": len(workouts_to_keep),
            "kept_completed": len(completed),
        }

    except Exception as e:
        logger.error(f"[Cleanup] Failed: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")
