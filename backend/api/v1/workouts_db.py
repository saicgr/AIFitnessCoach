"""
Workout CRUD API endpoints with Supabase.

ENDPOINTS:
- POST /api/v1/workouts-db/ - Create a new workout
- GET  /api/v1/workouts-db/ - List workouts for a user
- GET  /api/v1/workouts-db/{id} - Get workout by ID
- PUT  /api/v1/workouts-db/{id} - Update workout
- DELETE /api/v1/workouts-db/{id} - Delete workout
- POST /api/v1/workouts-db/{id}/complete - Mark workout as completed
- POST /api/v1/workouts-db/update-program - Update program preferences, delete future workouts

RATE LIMITS:
- /generate: 5 requests/minute (AI-intensive)
- /regenerate: 5 requests/minute (AI-intensive)
- /suggest: 5 requests/minute (AI-intensive)
- Other endpoints: default global limit
"""
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional
from datetime import datetime
import json

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity
from models.schemas import (
    Workout, WorkoutCreate, WorkoutUpdate,
    SwapWorkoutsRequest, SwapExerciseRequest,
)
from services.exercise_library_service import get_exercise_library_service

# Re-export helpers for backward compatibility
from .workouts_db_helpers import (  # noqa: F401
    ensure_workout_data_dict,
    parse_json_field,
    normalize_goals_list,
    get_recently_used_exercises,
    index_workout_to_rag,
    log_workout_change,
    row_to_workout,
    get_workout_focus,
    get_workout_rag_service,
    WorkoutSuggestionRequest,
    WorkoutSuggestion,
    WorkoutSuggestionsResponse,
    build_exercise_reasoning,
    build_workout_reasoning,
)

# Import sub-routers
from .workouts_db_generation import router as generation_router
from .workouts_db_versioning import router as versioning_router

# Shared generation cache (see core/generation_cache.py)
from core.generation_cache import generation_cache_key, get_cached_generation, set_cached_generation  # noqa: F401

router = APIRouter()
logger = get_logger(__name__)

# Include sub-routers
router.include_router(generation_router)
router.include_router(versioning_router)


@router.post("/", response_model=Workout)
async def create_workout(workout: WorkoutCreate,
    current_user: dict = Depends(get_current_user),
):
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
        logger.error(f"Failed to create workout: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.get("/", response_model=List[Workout])
async def list_workouts(
    user_id: str,
    is_completed: Optional[bool] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: dict = Depends(get_current_user),
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
        logger.error(f"Failed to list workouts: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.get("/{workout_id}", response_model=Workout)
async def get_workout(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
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
        logger.error(f"Failed to get workout: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.put("/{workout_id}", response_model=Workout)
async def update_workout(workout_id: str, workout: WorkoutUpdate,
    current_user: dict = Depends(get_current_user),
):
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
        raise safe_internal_error(e, "workouts_db")


@router.delete("/{workout_id}")
async def delete_workout(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a workout and all related records."""
    logger.info(f"Deleting workout: id={workout_id}")
    try:
        db = get_supabase_db()

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found for deletion: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        db.delete_workout_changes_by_workout(workout_id)
        db.delete_workout_logs_by_workout(workout_id)
        db.delete_workout(workout_id)

        logger.info(f"Workout deleted: id={workout_id}")
        return {"message": "Workout deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete workout: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.post("/{workout_id}/complete", response_model=Workout)
async def complete_workout(workout_id: str, background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
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

        async def _bg_log_completion():
            try:
                await log_user_activity(
                    user_id=workout.user_id,
                    action="workout_completed",
                    endpoint=f"/api/v1/workouts-db/{workout_id}/complete",
                    message=f"Completed workout: {workout.name}",
                    metadata={
                        "workout_id": workout_id,
                        "workout_name": workout.name,
                        "workout_type": workout.type,
                    },
                    status_code=200
                )
            except Exception as e:
                logger.warning(f"Background: Failed to log workout completion: {e}", exc_info=True)

        async def _bg_index_rag():
            try:
                await index_workout_to_rag(workout)
            except Exception as e:
                logger.warning(f"Background: Failed to index workout to RAG: {e}", exc_info=True)

        background_tasks.add_task(_bg_log_completion)
        background_tasks.add_task(_bg_index_rag)

        return workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete workout: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.post("/swap")
async def swap_workout_date(body: SwapWorkoutsRequest,
    current_user: dict = Depends(get_current_user),
):
    """Move a workout to a new date, swapping if another workout exists there."""
    logger.info(f"Swapping workout {body.workout_id} to {body.new_date}")
    try:
        db = get_supabase_db()

        workout = db.get_workout(body.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        old_date = workout.get("scheduled_date")
        user_id = workout.get("user_id")

        existing_workouts = db.get_workouts_by_date_range(user_id, body.new_date, body.new_date)

        if existing_workouts:
            existing = existing_workouts[0]
            db.update_workout(existing["id"], {"scheduled_date": old_date, "last_modified_method": "date_swap"})
            log_workout_change(existing["id"], user_id, "date_swap", "scheduled_date", body.new_date, old_date)

        db.update_workout(body.workout_id, {"scheduled_date": body.new_date, "last_modified_method": "date_swap"})
        log_workout_change(body.workout_id, user_id, "date_swap", "scheduled_date", old_date, body.new_date)

        return {"success": True, "old_date": old_date, "new_date": body.new_date}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap workout: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")


@router.post("/swap-exercise", response_model=Workout)
async def swap_exercise_in_workout(request: SwapExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
    """Swap an exercise within a workout with a new exercise from the library."""
    logger.info(f"Swapping exercise '{request.old_exercise_name}' with '{request.new_exercise_name}' in workout {request.workout_id}")
    try:
        db = get_supabase_db()

        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises_json = workout.get("exercises_json", "[]")
        if isinstance(exercises_json, str):
            exercises = json.loads(exercises_json)
        else:
            exercises = exercises_json

        exercise_found = False
        for i, exercise in enumerate(exercises):
            if exercise.get("name", "").lower() == request.old_exercise_name.lower():
                exercise_found = True

                exercise_lib = get_exercise_library_service()
                new_exercise_data = exercise_lib.search_exercises(request.new_exercise_name, limit=1)

                if new_exercise_data:
                    new_ex = new_exercise_data[0]
                    exercises[i] = {
                        **exercise,
                        "name": new_ex.get("name", request.new_exercise_name),
                        "muscle_group": new_ex.get("target_muscle") or new_ex.get("body_part") or exercise.get("muscle_group"),
                        "equipment": new_ex.get("equipment") or exercise.get("equipment"),
                        "notes": new_ex.get("instructions") or exercise.get("notes", ""),
                        "gif_url": new_ex.get("gif_url") or new_ex.get("video_url"),
                        "video_url": new_ex.get("video_url") or new_ex.get("gif_url"),
                        "library_id": new_ex.get("id"),
                    }
                else:
                    exercises[i]["name"] = request.new_exercise_name
                break

        if not exercise_found:
            raise HTTPException(status_code=404, detail=f"Exercise '{request.old_exercise_name}' not found in workout")

        update_data = {
            "exercises_json": json.dumps(exercises),
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "exercise_swap"
        }

        updated = db.update_workout(request.workout_id, update_data)
        if not updated:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        log_workout_change(
            request.workout_id,
            workout.get("user_id"),
            "exercise_swap",
            "exercises_json",
            request.old_exercise_name,
            request.new_exercise_name
        )

        updated_workout = row_to_workout(updated)
        logger.info(f"Exercise swapped successfully in workout {request.workout_id}")
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "workouts_db")
