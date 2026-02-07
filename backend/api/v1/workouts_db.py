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
from fastapi import APIRouter, HTTPException, Query, BackgroundTasks, Request
from fastapi.responses import StreamingResponse
from typing import List, Optional, AsyncGenerator
from datetime import datetime, timedelta
import hashlib
import json
import asyncio
import threading

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from models.gemini_schemas import WorkoutSuggestionsResponse
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import (
    Workout, WorkoutCreate, WorkoutUpdate, GenerateWorkoutRequest,
    SwapWorkoutsRequest, SwapExerciseRequest,
    RegenerateWorkoutRequest, RevertWorkoutRequest, WorkoutVersionInfo,
    UpdateWorkoutExercisesRequest, UpdateWarmupExercisesRequest, UpdateStretchExercisesRequest,
    WorkoutExitCreate, WorkoutExit,
    UpdateProgramRequest, UpdateProgramResponse
)
from services.gemini_service import GeminiService
from services.rag_service import WorkoutRAGService
from services.langgraph_agents.workout_insights.graph import generate_workout_insights
from services.exercise_library_service import get_exercise_library_service
from services.exercise_rag_service import get_exercise_rag_service
from services.warmup_stretch_service import get_warmup_stretch_service

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# In-Memory TTL Cache for Workout Generation
# =============================================================================
# Prevents duplicate AI generation calls when a user retries with identical
# parameters within a short window (e.g., double-tap, network retry).
# Cache entries expire after 5 minutes.

_generation_cache: dict = {}
_CACHE_TTL = timedelta(minutes=5)
_cache_lock = threading.Lock()


def _generation_cache_key(user_id: str, params: dict) -> str:
    """Create a deterministic cache key from user_id and generation parameters."""
    param_str = json.dumps(params, sort_keys=True, default=str)
    return hashlib.md5(f"{user_id}:{param_str}".encode()).hexdigest()


def _get_cached_generation(key: str):
    """Get a cached generation result if still valid. Returns None on miss."""
    with _cache_lock:
        if key in _generation_cache:
            cached_at, result = _generation_cache[key]
            if datetime.now() - cached_at < _CACHE_TTL:
                logger.info(f"Cache HIT for workout generation key={key[:8]}")
                return result
            else:
                # Expired entry - clean it up
                del _generation_cache[key]
                logger.debug(f"Cache EXPIRED for key={key[:8]}")
    return None


def _set_cached_generation(key: str, result):
    """Store a successful generation result in the cache."""
    with _cache_lock:
        _generation_cache[key] = (datetime.now(), result)
        logger.info(f"Cache SET for workout generation key={key[:8]}")
        # Periodic cleanup: remove expired entries when cache grows
        if len(_generation_cache) > 100:
            _cleanup_expired_cache()


def _cleanup_expired_cache():
    """Remove all expired entries from the generation cache. Must hold _cache_lock."""
    now = datetime.now()
    expired_keys = [
        k for k, (cached_at, _) in _generation_cache.items()
        if now - cached_at >= _CACHE_TTL
    ]
    for k in expired_keys:
        del _generation_cache[k]
    if expired_keys:
        logger.debug(f"Cache cleanup: removed {len(expired_keys)} expired entries")


async def get_recently_used_exercises(user_id: str, days: int = 7) -> List[str]:
    """
    Get list of exercise names used by user in recent workouts.

    This ensures variety by avoiding exercises the user has done recently.

    Args:
        user_id: The user's ID
        days: Number of days to look back (default 7)

    Returns:
        List of exercise names to avoid
    """
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        # Get recent workouts for this user
        response = db.client.table("workouts").select(
            "exercises_json"
        ).eq("user_id", user_id).gte(
            "scheduled_date", cutoff_date
        ).execute()

        if not response.data:
            return []

        # Extract all exercise names from recent workouts
        recent_exercises = set()
        for workout in response.data:
            exercises_json = workout.get("exercises_json", [])
            if isinstance(exercises_json, str):
                try:
                    exercises_json = json.loads(exercises_json)
                except json.JSONDecodeError:
                    continue

            for exercise in exercises_json:
                if isinstance(exercise, dict):
                    name = exercise.get("name") or exercise.get("exercise_name")
                    if name:
                        recent_exercises.add(name)

        logger.info(f"🔄 Found {len(recent_exercises)} recently used exercises for user {user_id} (last {days} days)")
        return list(recent_exercises)

    except Exception as e:
        logger.error(f"Error getting recently used exercises: {e}")
        return []


def parse_json_field(value, default):
    """Parse a field that could be a JSON string or already parsed."""
    if value is None:
        return default
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return default
    return value if isinstance(value, (list, dict)) else default


def normalize_goals_list(goals) -> List[str]:
    """
    Normalize goals to a list of strings.

    Goals can come in various formats from the database:
    - List of strings: ["weight_loss", "muscle_gain"]
    - List of dicts: [{"name": "weight_loss"}, {"goal": "muscle_gain"}]
    - JSON string: '["weight_loss"]'
    - Single string: "weight_loss"
    - None

    This function handles all cases and returns a clean list of strings.

    Args:
        goals: Raw goals data from database or API

    Returns:
        List of goal strings
    """
    if goals is None:
        return []

    # Parse JSON string if needed
    if isinstance(goals, str):
        try:
            goals = json.loads(goals)
        except json.JSONDecodeError:
            # Single goal string
            return [goals] if goals.strip() else []

    # Not a list - return empty
    if not isinstance(goals, list):
        return []

    # Normalize each item in the list
    result = []
    for item in goals:
        if isinstance(item, str):
            if item.strip():
                result.append(item.strip())
        elif isinstance(item, dict):
            # Try common dict keys for goal name
            goal_name = (
                item.get("name") or
                item.get("goal") or
                item.get("title") or
                item.get("value") or
                item.get("id") or
                str(item)  # Fallback to string representation
            )
            if goal_name and isinstance(goal_name, str):
                result.append(goal_name.strip())
        # Skip other types (int, float, etc.)

    return result


# Initialize workout RAG service (lazy loading)
_workout_rag_service: Optional[WorkoutRAGService] = None


def get_workout_rag_service() -> WorkoutRAGService:
    """Get or create the workout RAG service instance."""
    global _workout_rag_service
    if _workout_rag_service is None:
        gemini_service = GeminiService()
        _workout_rag_service = WorkoutRAGService(gemini_service)
    return _workout_rag_service


async def index_workout_to_rag(workout: Workout):
    """Index a workout to RAG for retrieval (fire-and-forget)."""
    try:
        rag_service = get_workout_rag_service()
        exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json
        scheduled_date = workout.scheduled_date
        if hasattr(scheduled_date, 'isoformat'):
            scheduled_date = scheduled_date.isoformat()
        await rag_service.index_workout(
            workout_id=workout.id,
            user_id=workout.user_id,
            name=workout.name,
            workout_type=workout.type,
            difficulty=workout.difficulty,
            exercises=exercises,
            scheduled_date=str(scheduled_date),
            is_completed=workout.is_completed,
            generation_method=workout.generation_method,
        )
    except Exception as e:
        logger.error(f"Failed to index workout to RAG: {e}")


def log_workout_change(
    workout_id: str,
    user_id: str,
    change_type: str,
    field_changed: str = None,
    old_value=None,
    new_value=None,
    change_source: str = "api",
    change_reason: str = None
):
    """Log a change to a workout for audit trail."""
    try:
        db = get_supabase_db()
        change_data = {
            "workout_id": workout_id,
            "user_id": user_id,
            "change_type": change_type,
            "field_changed": field_changed,
            "old_value": json.dumps(old_value) if old_value is not None else None,
            "new_value": json.dumps(new_value) if new_value is not None else None,
            "change_source": change_source,
            "change_reason": change_reason,
        }
        db.create_workout_change(change_data)
        logger.debug(f"Logged workout change: workout_id={workout_id}, type={change_type}")
    except Exception as e:
        logger.error(f"Failed to log workout change: {e}")


def row_to_workout(row: dict) -> Workout:
    """Convert a Supabase row dict to Workout model."""
    exercises_json = row.get("exercises_json") or row.get("exercises")
    if isinstance(exercises_json, list):
        exercises_json = json.dumps(exercises_json)
    elif exercises_json is None:
        exercises_json = "[]"

    # Convert dict/list fields to JSON strings
    generation_metadata = row.get("generation_metadata")
    if isinstance(generation_metadata, (dict, list)):
        generation_metadata = json.dumps(generation_metadata)

    modification_history = row.get("modification_history")
    if isinstance(modification_history, (dict, list)):
        modification_history = json.dumps(modification_history)

    return Workout(
        id=str(row.get("id")),  # Ensure string for UUID
        user_id=str(row.get("user_id")),
        name=row.get("name"),
        type=row.get("type"),
        difficulty=row.get("difficulty"),
        scheduled_date=row.get("scheduled_date"),
        is_completed=row.get("is_completed", False),
        exercises_json=exercises_json,
        duration_minutes=row.get("duration_minutes", 45),
        created_at=row.get("created_at"),
        generation_method=row.get("generation_method"),
        generation_source=row.get("generation_source"),
        generation_metadata=generation_metadata,
        generated_at=row.get("generated_at"),
        last_modified_method=row.get("last_modified_method"),
        last_modified_at=row.get("last_modified_at"),
        modification_history=modification_history,
        # SCD2 versioning fields
        version_number=row.get("version_number", 1),
        is_current=row.get("is_current", True),
        valid_from=row.get("valid_from"),
        valid_to=row.get("valid_to"),
        parent_workout_id=row.get("parent_workout_id"),
        superseded_by=row.get("superseded_by"),
    )


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
async def complete_workout(workout_id: str, background_tasks: BackgroundTasks):
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

        # Move non-critical logging and RAG indexing to background
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
                logger.warning(f"Background: Failed to log workout completion: {e}")

        background_tasks.add_task(_bg_log_completion)
        background_tasks.add_task(_background_index_rag, workout)

        return workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def _background_log_generation(user_id: str, workout_id: str, workout_name: str, workout_type: str, exercises_count: int, duration_minutes: int):
    """Background task: Log workout generation analytics (non-critical)."""
    try:
        await log_user_activity(
            user_id=user_id,
            action="workout_generation",
            endpoint="/api/v1/workouts-db/generate",
            message=f"Generated workout: {workout_name}",
            metadata={
                "workout_id": workout_id,
                "workout_type": workout_type,
                "exercises_count": exercises_count,
                "duration_minutes": duration_minutes,
            },
            status_code=200
        )
    except Exception as e:
        logger.warning(f"Background: Failed to log generation activity: {e}")


async def _background_index_rag(workout: Workout):
    """Background task: Index workout to RAG (non-critical)."""
    try:
        await index_workout_to_rag(workout)
    except Exception as e:
        logger.warning(f"Background: Failed to index workout to RAG: {e}")


@router.post("/generate", response_model=Workout)
@limiter.limit("5/minute")
async def generate_workout(http_request: Request, request: GenerateWorkoutRequest, background_tasks: BackgroundTasks):
    """Generate a new workout for a user based on their preferences."""
    logger.info(f"Generating workout for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Initialize training customization fields
        primary_goal = None
        muscle_focus_points = None

        if request.fitness_level and request.goals and request.equipment:
            fitness_level = request.fitness_level
            goals = request.goals
            equipment = request.equipment
        else:
            user = db.get_user(request.user_id)
            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            fitness_level = request.fitness_level or user.get("fitness_level")
            goals = request.goals or user.get("goals", [])
            equipment = request.equipment or user.get("equipment", [])
            primary_goal = user.get("primary_goal")
            muscle_focus_points = user.get("muscle_focus_points")

        # Check in-memory cache for identical generation parameters
        cache_params = {
            "fitness_level": fitness_level,
            "goals": goals if isinstance(goals, list) else [],
            "equipment": equipment if isinstance(equipment, list) else [],
            "duration_minutes": request.duration_minutes or 45,
            "focus_areas": request.focus_areas,
            "workout_type": request.workout_type,
            "primary_goal": primary_goal,
            "muscle_focus_points": muscle_focus_points,
        }
        cache_key = _generation_cache_key(request.user_id, cache_params)
        cached_workout_data = _get_cached_generation(cache_key)

        if cached_workout_data:
            # Cache hit - reuse previously generated workout data
            exercises = cached_workout_data.get("exercises", [])
            workout_name = cached_workout_data.get("name", "Generated Workout")
            workout_type = cached_workout_data.get("type", request.workout_type or "strength")
            difficulty = cached_workout_data.get("difficulty", "medium")
            logger.info(f"Using cached workout generation for user {request.user_id}")
        else:
            # Cache miss - generate via AI
            gemini_service = GeminiService()

            try:
                workout_data = await gemini_service.generate_workout_plan(
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    equipment=equipment if isinstance(equipment, list) else [],
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=request.focus_areas,
                    primary_goal=primary_goal,
                    muscle_focus_points=muscle_focus_points,
                )

                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", "Generated Workout")
                workout_type = workout_data.get("type", request.workout_type or "strength")
                difficulty = workout_data.get("difficulty", "medium")

                # Cache the successful generation result
                _set_cached_generation(cache_key, workout_data)

            except Exception as ai_error:
                logger.error(f"AI workout generation failed: {ai_error}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to generate workout: {str(ai_error)}"
                )

        workout_db_data = {
            "user_id": request.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": datetime.now().isoformat(),
            "exercises_json": exercises,
            "duration_minutes": request.duration_minutes or 45,
            "generation_method": "ai",
            "generation_source": "gemini_generation",
        }

        created = db.create_workout(workout_db_data)
        logger.info(f"Workout generated: id={created['id']}")

        # Log workout change synchronously (quick local write, important for audit)
        log_workout_change(
            workout_id=created['id'],
            user_id=request.user_id,
            change_type="generated",
            change_source="ai_generation",
            new_value={"name": workout_name, "exercises_count": len(exercises)}
        )

        generated_workout = row_to_workout(created)

        # Move non-critical operations to background tasks
        background_tasks.add_task(
            _background_index_rag, generated_workout
        )
        background_tasks.add_task(
            _background_log_generation,
            user_id=request.user_id,
            workout_id=created['id'],
            workout_name=workout_name,
            workout_type=workout_type,
            exercises_count=len(exercises),
            duration_minutes=request.duration_minutes or 45,
        )

        return generated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout: {e}")
        # Log error (still inline since we need it for error tracking)
        await log_user_error(
            user_id=request.user_id,
            action="workout_generation",
            error=e,
            endpoint="/api/v1/workouts-db/generate",
            metadata={"workout_type": request.workout_type},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-stream")
@limiter.limit("5/minute")
async def generate_workout_streaming(http_request: Request, request: GenerateWorkoutRequest):
    """
    Generate a workout with streaming response for faster perceived performance.

    Returns Server-Sent Events (SSE) stream:
    - 'chunk' events with partial JSON as it generates
    - 'done' event with the complete workout object when finished
    - 'error' event if something fails

    The client can start displaying exercises as they arrive instead of
    waiting for the full response (3-8 seconds faster perceived time).
    """
    logger.info(f"[Streaming] Generating workout for user {request.user_id}")

    async def generate_sse() -> AsyncGenerator[str, None]:
        try:
            db = get_supabase_db()

            # Get user data if not provided
            if request.fitness_level and request.goals and request.equipment:
                fitness_level = request.fitness_level
                goals = request.goals
                equipment = request.equipment
            else:
                user = db.get_user(request.user_id)
                if not user:
                    yield f"event: error\ndata: {json.dumps({'error': 'User not found'})}\n\n"
                    return

                fitness_level = request.fitness_level or user.get("fitness_level")
                goals = request.goals or user.get("goals", [])
                equipment = request.equipment or user.get("equipment", [])

            gemini_service = GeminiService()
            full_content = ""

            # Stream the generation
            async for chunk in gemini_service.generate_workout_plan_streaming(
                fitness_level=fitness_level or "intermediate",
                goals=goals if isinstance(goals, list) else [],
                equipment=equipment if isinstance(equipment, list) else [],
                duration_minutes=request.duration_minutes or 45,
                focus_areas=request.focus_areas
            ):
                full_content += chunk
                # Send chunk event
                yield f"event: chunk\ndata: {json.dumps({'chunk': chunk})}\n\n"

            # Parse the complete response
            content = full_content.strip()
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            workout_data = json.loads(content.strip())

            if "exercises" not in workout_data or not workout_data["exercises"]:
                yield f"event: error\ndata: {json.dumps({'error': 'AI response missing exercises'})}\n\n"
                return

            # Save to database
            workout_db_data = {
                "user_id": request.user_id,
                "name": workout_data.get("name", "Generated Workout"),
                "type": workout_data.get("type", request.workout_type or "strength"),
                "difficulty": workout_data.get("difficulty", "medium"),
                "scheduled_date": datetime.now().isoformat(),
                "exercises_json": workout_data.get("exercises", []),
                "duration_minutes": request.duration_minutes or 45,
                "generation_method": "ai",
                "generation_source": "gemini_streaming",
            }

            created = db.create_workout(workout_db_data)
            logger.info(f"[Streaming] Workout generated: id={created['id']}")

            log_workout_change(
                workout_id=created['id'],
                user_id=request.user_id,
                change_type="generated",
                change_source="ai_streaming",
                new_value={"name": workout_data.get("name"), "exercises_count": len(workout_data.get("exercises", []))}
            )

            # Index to RAG in background (don't await)
            generated_workout = row_to_workout(created)
            asyncio.create_task(index_workout_to_rag(generated_workout))

            # Send final workout
            workout_response = {
                "id": created["id"],
                "user_id": created["user_id"],
                "name": created["name"],
                "type": created["type"],
                "difficulty": created["difficulty"],
                "scheduled_date": created["scheduled_date"],
                "exercises_json": created.get("exercises_json"),
                "duration_minutes": created.get("duration_minutes"),
                "is_completed": created.get("is_completed", False),
            }
            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except json.JSONDecodeError as e:
            logger.error(f"[Streaming] JSON parse error: {e}")
            yield f"event: error\ndata: {json.dumps({'error': f'Failed to parse AI response: {str(e)}'})}\n\n"
        except Exception as e:
            logger.error(f"[Streaming] Error: {e}")
            yield f"event: error\ndata: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # Disable nginx buffering
        }
    )


@router.post("/swap")
async def swap_workout_date(request: SwapWorkoutsRequest):
    """Move a workout to a new date, swapping if another workout exists there."""
    logger.info(f"Swapping workout {request.workout_id} to {request.new_date}")
    try:
        db = get_supabase_db()

        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        old_date = workout.get("scheduled_date")
        user_id = workout.get("user_id")

        # Check for existing workout on new date
        existing_workouts = db.get_workouts_by_date_range(user_id, request.new_date, request.new_date)

        if existing_workouts:
            existing = existing_workouts[0]
            db.update_workout(existing["id"], {"scheduled_date": old_date, "last_modified_method": "date_swap"})
            log_workout_change(existing["id"], user_id, "date_swap", "scheduled_date", request.new_date, old_date)

        db.update_workout(request.workout_id, {"scheduled_date": request.new_date, "last_modified_method": "date_swap"})
        log_workout_change(request.workout_id, user_id, "date_swap", "scheduled_date", old_date, request.new_date)

        return {"success": True, "old_date": old_date, "new_date": request.new_date}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/swap-exercise", response_model=Workout)
async def swap_exercise_in_workout(request: SwapExerciseRequest):
    """Swap an exercise within a workout with a new exercise from the library."""
    logger.info(f"Swapping exercise '{request.old_exercise_name}' with '{request.new_exercise_name}' in workout {request.workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout
        workout = db.get_workout(request.workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Parse exercises
        exercises_json = workout.get("exercises_json", "[]")
        if isinstance(exercises_json, str):
            exercises = json.loads(exercises_json)
        else:
            exercises = exercises_json

        # Find and replace the exercise
        exercise_found = False
        for i, exercise in enumerate(exercises):
            if exercise.get("name", "").lower() == request.old_exercise_name.lower():
                exercise_found = True

                # Get new exercise details from library
                exercise_lib = get_exercise_library_service()
                new_exercise_data = exercise_lib.search_exercises(request.new_exercise_name, limit=1)

                if new_exercise_data:
                    new_ex = new_exercise_data[0]
                    # Preserve sets/reps from old exercise, update other fields
                    exercises[i] = {
                        **exercise,  # Keep original sets, reps, rest_seconds
                        "name": new_ex.get("name", request.new_exercise_name),
                        "muscle_group": new_ex.get("target_muscle") or new_ex.get("body_part") or exercise.get("muscle_group"),
                        "equipment": new_ex.get("equipment") or exercise.get("equipment"),
                        "notes": new_ex.get("instructions") or exercise.get("notes", ""),
                        "gif_url": new_ex.get("gif_url") or new_ex.get("video_url"),
                        "video_url": new_ex.get("video_url") or new_ex.get("gif_url"),
                        "library_id": new_ex.get("id"),
                    }
                else:
                    # Just update the name if exercise not found in library
                    exercises[i]["name"] = request.new_exercise_name
                break

        if not exercise_found:
            raise HTTPException(status_code=404, detail=f"Exercise '{request.old_exercise_name}' not found in workout")

        # Update the workout
        update_data = {
            "exercises_json": json.dumps(exercises),
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "exercise_swap"
        }

        updated = db.update_workout(request.workout_id, update_data)
        if not updated:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        # Log the change
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

        # Re-index to RAG
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def get_workout_focus(split: str, selected_days: List[int]) -> dict:
    """Return workout focus for each day based on training split.

    For full_body split, we rotate through different emphasis areas to ensure variety
    while still targeting the whole body.
    """
    num_days = len(selected_days)

    if split == "full_body":
        # Rotate emphasis to ensure variety even in full-body workouts
        # Each still targets full body but with different primary focus
        full_body_emphases = [
            "full_body_push",   # Emphasis on pushing movements (chest, shoulders, triceps)
            "full_body_pull",   # Emphasis on pulling movements (back, biceps)
            "full_body_legs",   # Emphasis on lower body (legs, glutes)
            "full_body_core",   # Emphasis on core and stability
            "full_body_upper",  # Upper body focused full-body
            "full_body_lower",  # Lower body focused full-body
            "full_body_power",  # Power/explosive movements
        ]
        return {day: full_body_emphases[i % len(full_body_emphases)] for i, day in enumerate(selected_days)}
    elif split == "upper_lower":
        focuses = ["upper", "lower"] * (num_days // 2 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}
    elif split == "push_pull_legs":
        focuses = ["push", "pull", "legs"] * (num_days // 3 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}
    elif split == "body_part":
        body_parts = ["chest", "back", "shoulders", "legs", "arms", "core"]
        return {day: body_parts[i % len(body_parts)] for i, day in enumerate(selected_days)}
    elif split == "dont_know" or split is None:
        # User selected "Don't know" - auto-pick best split based on days per week
        if num_days <= 3:
            full_body_emphases = ["full_body_push", "full_body_pull", "full_body_legs"]
            return {day: full_body_emphases[i % len(full_body_emphases)] for i, day in enumerate(selected_days)}
        elif num_days == 4:
            focuses = ["upper", "lower", "upper", "lower"]
            return {day: focuses[i] for i, day in enumerate(selected_days)}
        elif num_days <= 6:
            focuses = ["push", "pull", "legs"] * 2
            return {day: focuses[i] for i, day in enumerate(selected_days)}
        else:
            return {day: "full_body" for day in selected_days}

    return {day: "full_body" for day in selected_days}


# ==================== WORKOUT VERSIONING (SCD2) ENDPOINTS ====================

@router.post("/regenerate", response_model=Workout)
@limiter.limit("5/minute")
async def regenerate_workout(http_request: Request, request: RegenerateWorkoutRequest, background_tasks: BackgroundTasks):
    """
    Regenerate a workout with new settings while preserving version history (SCD2).

    This endpoint:
    1. Gets the existing workout
    2. Generates a new workout using AI based on provided settings
    3. Creates a new version, marking the old one as superseded
    4. Returns the new version

    The old workout is NOT deleted - it's kept for history/revert.
    """
    logger.info(f"Regenerating workout {request.workout_id} for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Get existing workout
        existing = db.get_workout(request.workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get user data for generation
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Determine generation parameters
        # Use user-selected settings if provided, otherwise fall back to user profile
        fitness_level = request.fitness_level or user.get("fitness_level") or "intermediate"
        # IMPORTANT: Use explicit None check so empty list [] is respected
        equipment = request.equipment if request.equipment is not None else parse_json_field(user.get("equipment"), [])
        goals = normalize_goals_list(user.get("goals"))
        preferences = parse_json_field(user.get("preferences"), {})
        # Get equipment counts - use request if provided, otherwise fall back to user preferences
        dumbbell_count = request.dumbbell_count if request.dumbbell_count is not None else preferences.get("dumbbell_count", 2)
        kettlebell_count = request.kettlebell_count if request.kettlebell_count is not None else preferences.get("kettlebell_count", 1)

        # Get age and activity level for personalized workouts
        user_age = user.get("age")
        user_activity_level = user.get("activity_level")

        # Get user-selected difficulty (easy/medium/hard) - will override AI-generated difficulty
        user_difficulty = request.difficulty

        # Get injuries from request (user-selected) or fall back to user profile
        injuries = request.injuries or []
        if not injuries:
            # Check user's active injuries from profile
            user_injuries = parse_json_field(user.get("active_injuries"), [])
            if user_injuries:
                injuries = user_injuries

        if injuries:
            logger.info(f"🩹 Regenerating workout avoiding exercises for injuries: {injuries}")

        # Get workout type from request
        workout_type_override = request.workout_type
        if workout_type_override:
            logger.info(f"🏋️ Regenerating with workout type override: {workout_type_override}")

        # Determine focus area from existing workout or request
        focus_areas = request.focus_areas or []

        logger.info(f"🎯 Regenerating workout with: fitness_level={fitness_level}")
        logger.info(f"  - equipment={equipment} (from request: {request.equipment})")
        logger.info(f"  - dumbbell_count={dumbbell_count} (from request: {request.dumbbell_count})")
        logger.info(f"  - kettlebell_count={kettlebell_count} (from request: {request.kettlebell_count})")
        logger.info(f"  - difficulty={user_difficulty}")
        logger.info(f"  - workout_type={workout_type_override}")
        logger.info(f"  - duration_minutes={request.duration_minutes}")
        logger.info(f"  - injuries={injuries}")
        logger.info(f"  - focus_areas={focus_areas}")

        gemini_service = GeminiService()
        exercise_rag = get_exercise_rag_service()
        if not focus_areas:
            # Try to determine focus from existing workout's target muscles
            existing_exercises = parse_json_field(existing.get("exercises_json") or existing.get("exercises"), [])
            if existing_exercises:
                target_muscles = set()
                for ex in existing_exercises:
                    if isinstance(ex, dict) and ex.get("target_muscles"):
                        muscles = ex.get("target_muscles")
                        if isinstance(muscles, list):
                            target_muscles.update(muscles)
                        elif isinstance(muscles, str):
                            target_muscles.add(muscles)
                if target_muscles:
                    focus_areas = list(target_muscles)[:2]  # Use up to 2 main muscles

        focus_area = focus_areas[0] if focus_areas else "full_body"

        # Calculate exercise count based on duration
        # Rule: ~7 minutes per exercise (including rest) for a balanced workout
        # Shorter workouts = fewer exercises, longer workouts = more exercises
        target_duration = request.duration_minutes or 45
        exercise_count = max(3, min(10, target_duration // 7))  # 3-10 exercises
        logger.info(f"🎯 Target duration: {target_duration} mins -> {exercise_count} exercises")

        try:
            # Use RAG to intelligently select exercises from ChromaDB/Supabase
            # Pass injuries to filter out contraindicated exercises
            rag_exercises = await exercise_rag.select_exercises_for_workout(
                focus_area=focus_area,
                equipment=equipment if isinstance(equipment, list) else [],
                fitness_level=fitness_level,
                goals=goals if isinstance(goals, list) else [],
                count=exercise_count,  # Dynamic count based on duration
                avoid_exercises=[],  # Don't avoid any since we're regenerating
                injuries=injuries if injuries else None,
                dumbbell_count=dumbbell_count,
                kettlebell_count=kettlebell_count,
            )

            if rag_exercises:
                # Use RAG-selected exercises with real videos
                logger.info(f"RAG selected {len(rag_exercises)} exercises for regeneration")
                workout_data = await gemini_service.generate_workout_from_library(
                    exercises=rag_exercises,
                    fitness_level=fitness_level,
                    goals=goals if isinstance(goals, list) else [],
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=focus_areas if focus_areas else [focus_area],
                    age=user_age,
                    activity_level=user_activity_level
                )
            else:
                # No fallback - RAG must return exercises
                logger.error("RAG returned no exercises for regeneration")
                raise ValueError(f"RAG returned no exercises for focus_area={focus_area}")

            exercises = workout_data.get("exercises", [])
            # Use provided workout_name if specified (e.g., from AI suggestion), otherwise use AI-generated name
            workout_name = request.workout_name or workout_data.get("name", "Regenerated Workout")
            # Use user-selected workout type if provided, otherwise use AI-generated or existing
            workout_type = workout_type_override or workout_data.get("type", existing.get("type", "strength"))
            # Use user-selected difficulty if provided, otherwise use AI-generated or default
            difficulty = user_difficulty or workout_data.get("difficulty", "medium")

        except Exception as ai_error:
            logger.error(f"AI workout regeneration failed: {ai_error}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate new workout: {str(ai_error)}"
            )

        # Track if RAG was used for metadata
        used_rag = rag_exercises is not None and len(rag_exercises) > 0

        # Prepare new workout data for the SCD2 supersede operation
        new_workout_data = {
            "user_id": request.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": existing.get("scheduled_date"),  # Keep same date
            "exercises_json": exercises,
            "duration_minutes": request.duration_minutes or 45,
            "equipment": json.dumps(equipment) if equipment else "[]",  # Store user-selected equipment
            "is_completed": False,  # Reset completion on regenerate
            "generation_method": "rag_regenerate" if used_rag else "ai_regenerate",
            "generation_source": "regenerate_endpoint",
            "generation_metadata": json.dumps({
                "regenerated_from": request.workout_id,
                "previous_version": existing.get("version_number", 1),
                "fitness_level": fitness_level,
                "equipment": equipment,
                "difficulty": difficulty,
                "workout_type": workout_type,
                "workout_type_override": workout_type_override,
                "used_rag": used_rag,
                "focus_area": focus_area,
                "injuries_considered": injuries if injuries else [],
            }),
        }

        # Use SCD2 supersede to create new version
        new_workout = db.supersede_workout(request.workout_id, new_workout_data)
        logger.info(f"Workout regenerated: old_id={request.workout_id}, new_id={new_workout['id']}, version={new_workout.get('version_number')}")

        log_workout_change(
            workout_id=new_workout["id"],
            user_id=request.user_id,
            change_type="regenerated",
            change_source="regenerate_endpoint",
            new_value={
                "name": workout_name,
                "exercises_count": len(exercises),
                "previous_workout_id": request.workout_id
            }
        )

        regenerated = row_to_workout(new_workout)

        # Move non-critical operations to background tasks
        # RAG indexing is not critical for the response
        background_tasks.add_task(_background_index_rag, regenerated)

        # Record regeneration analytics in the background (non-critical)
        async def _bg_record_regeneration_analytics():
            try:
                # Extract custom inputs (focus area/injury typed in "Other" field)
                custom_focus_area = None
                custom_injury = None

                # Check if focus_areas contains a custom entry (not from predefined list)
                predefined_focus_areas = [
                    "full_body", "upper_body", "lower_body", "core", "back", "chest",
                    "shoulders", "arms", "legs", "glutes", "cardio", "flexibility"
                ]
                if focus_areas:
                    for fa in focus_areas:
                        if fa and fa.lower() not in [p.lower() for p in predefined_focus_areas]:
                            custom_focus_area = fa
                            break

                # Check if injuries contains a custom entry
                predefined_injuries = [
                    "shoulder", "knee", "back", "wrist", "ankle", "hip", "neck", "elbow"
                ]
                if injuries:
                    for inj in injuries:
                        if inj and inj.lower() not in [p.lower() for p in predefined_injuries]:
                            custom_injury = inj
                            break

                db.record_workout_regeneration(
                    user_id=request.user_id,
                    original_workout_id=request.workout_id,
                    new_workout_id=new_workout["id"],
                    difficulty=user_difficulty,
                    duration_minutes=request.duration_minutes,
                    workout_type=workout_type_override,
                    equipment=equipment if isinstance(equipment, list) else [],
                    focus_areas=focus_areas if focus_areas else [],
                    injuries=injuries if injuries else [],
                    custom_focus_area=custom_focus_area,
                    custom_injury=custom_injury,
                    generation_method="rag_regenerate" if used_rag else "ai_regenerate",
                    used_rag=used_rag,
                    generation_time_ms=None,
                )
                logger.info(f"Background: Recorded regeneration analytics for workout {new_workout['id']}")

                # Index custom inputs to ChromaDB for AI retrieval
                if custom_focus_area or custom_injury:
                    try:
                        from services.custom_inputs_rag_service import get_custom_inputs_rag_service
                        custom_rag = get_custom_inputs_rag_service()

                        if custom_focus_area:
                            await custom_rag.index_custom_input(
                                input_type="focus_area",
                                input_value=custom_focus_area,
                                user_id=request.user_id,
                            )
                            logger.info(f"Background: Indexed custom focus area to ChromaDB: {custom_focus_area}")

                        if custom_injury:
                            await custom_rag.index_custom_input(
                                input_type="injury",
                                input_value=custom_injury,
                                user_id=request.user_id,
                            )
                            logger.info(f"Background: Indexed custom injury to ChromaDB: {custom_injury}")
                    except Exception as chroma_error:
                        logger.warning(f"Background: Failed to index custom inputs to ChromaDB: {chroma_error}")
            except Exception as analytics_error:
                logger.warning(f"Background: Failed to record regeneration analytics: {analytics_error}")

        background_tasks.add_task(_bg_record_regeneration_analytics)

        # Log workout regeneration activity in the background (non-critical)
        async def _bg_log_regeneration():
            try:
                await log_user_activity(
                    user_id=request.user_id,
                    action="workout_regeneration",
                    endpoint="/api/v1/workouts-db/regenerate",
                    message=f"Regenerated workout: {workout_name}",
                    metadata={
                        "original_workout_id": request.workout_id,
                        "new_workout_id": new_workout["id"],
                        "difficulty": user_difficulty,
                        "duration_minutes": request.duration_minutes,
                        "workout_type": workout_type_override,
                        "exercises_count": len(exercises),
                        "used_rag": used_rag,
                    },
                    status_code=200
                )
            except Exception as e:
                logger.warning(f"Background: Failed to log regeneration activity: {e}")

        background_tasks.add_task(_bg_log_regeneration)

        return regenerated

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to regenerate workout: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="workout_regeneration",
            error=e,
            endpoint="/api/v1/workouts-db/regenerate",
            metadata={"workout_id": request.workout_id},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# ==================== AI WORKOUT SUGGESTIONS ====================

from pydantic import BaseModel

class WorkoutSuggestionRequest(BaseModel):
    """Request for AI workout suggestions."""
    workout_id: str
    user_id: str
    current_workout_type: Optional[str] = None
    prompt: Optional[str] = None


class WorkoutSuggestion(BaseModel):
    """A single workout suggestion."""
    name: str
    type: str
    difficulty: str
    duration_minutes: int
    description: str
    focus_areas: List[str]
    sample_exercises: List[str] = []  # Preview of exercises included


class WorkoutSuggestionsResponse(BaseModel):
    """Response with workout suggestions."""
    suggestions: List[WorkoutSuggestion]


@router.post("/suggest", response_model=WorkoutSuggestionsResponse)
@limiter.limit("5/minute")
async def get_workout_suggestions(http_request: Request, request: WorkoutSuggestionRequest):
    """
    Get AI-powered workout suggestions for regeneration.

    Returns 3-5 workout suggestions based on:
    - Current workout context
    - User's fitness profile
    - Optional natural language prompt from user
    """
    logger.info(f"Getting workout suggestions for workout {request.workout_id}")

    try:
        db = get_supabase_db()

        # Get existing workout
        existing = db.get_workout(request.workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get user data
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get user context
        fitness_level = user.get("fitness_level") or "intermediate"
        goals = normalize_goals_list(user.get("goals"))
        equipment = parse_json_field(user.get("equipment"), [])
        injuries = parse_json_field(user.get("active_injuries"), [])

        # Get current workout info
        current_type = request.current_workout_type or existing.get("type") or "Strength"
        current_duration = existing.get("duration_minutes") or 45

        # Build prompt for AI
        # Note: User's explicit prompt takes priority over profile equipment
        system_prompt = f"""You are a fitness expert helping a user find alternative workout ideas.

USER PROFILE (for context only):
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Default Equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
- Injuries/Limitations: {', '.join(injuries) if injuries else 'None'}

CURRENT WORKOUT:
- Type: {current_type}
- Duration: {current_duration} minutes

IMPORTANT RULES:
1. If the user mentions specific equipment in their request (e.g., "dumbbells", "barbell", "kettlebell"), use ONLY that equipment - ignore the default equipment from their profile
2. If the user mentions a duration (e.g., "30 minutes", "1 hour"), use that duration
3. If the user mentions a sport or activity (e.g., "boxing", "cricket", "swimming"), create workouts that train for that sport
4. Always respect injuries/limitations
5. Match the user's fitness level

Generate 4 different workout suggestions that:
1. Vary in workout type (e.g., Strength, HIIT, Cardio, Flexibility)
2. Follow the user's specific requests if any
3. Consider injuries and fitness level

Return a JSON object with a "suggestions" array containing exactly 4 suggestions, each containing:
- name: Creative workout name that reflects the equipment/sport if specified (e.g., "Dumbbell Power Circuit", "Cricket Athlete Conditioning")
- type: One of [Strength, HIIT, Cardio, Flexibility, Full Body, Upper Body, Lower Body, Core]
- difficulty: One of [easy, medium, hard]
- duration_minutes: Integer between 15-90 (use user's requested duration if specified)
- description: 1-2 sentence description mentioning the specific equipment/focus
- focus_areas: Array of 1-3 body areas targeted
- sample_exercises: Array of 4-5 exercise names that would be included (e.g., ["Bench Press", "Rows", "Squats"])

Example format: {{"suggestions": [...]}}"""

        user_prompt = request.prompt if request.prompt else "Give me some workout alternatives"

        from google import genai
        from google.genai import types
        from core.config import get_settings
        settings = get_settings()

        client = genai.Client(api_key=settings.gemini_api_key)
        response = await client.aio.models.generate_content(
            model=settings.gemini_model,
            contents=f"{system_prompt}\n\nUser request: {user_prompt}",
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=WorkoutSuggestionsResponse,
                temperature=0.7,
                max_output_tokens=4000,  # Increased for thinking models
            ),
        )

        content = response.text.strip()
        data = json.loads(content)
        suggestions_data = data.get("suggestions", [])

        # Validate and convert to response format
        suggestions = []
        for s in suggestions_data[:5]:  # Limit to 5
            suggestions.append(WorkoutSuggestion(
                name=s.get("name", "Custom Workout"),
                type=s.get("type", "Strength"),
                difficulty=s.get("difficulty", "medium").lower(),
                duration_minutes=min(max(int(s.get("duration_minutes", 45)), 15), 90),
                description=s.get("description", ""),
                focus_areas=s.get("focus_areas", [])[:3],
                sample_exercises=s.get("sample_exercises", [])[:5],  # Limit to 5 exercises
            ))

        logger.info(f"Generated {len(suggestions)} workout suggestions")
        return WorkoutSuggestionsResponse(suggestions=suggestions)

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse AI response: {e}")
        # Return default suggestions on parse error
        return WorkoutSuggestionsResponse(suggestions=[
            WorkoutSuggestion(
                name="Power Strength",
                type="Strength",
                difficulty="medium",
                duration_minutes=45,
                description="A balanced strength workout targeting major muscle groups.",
                focus_areas=["Full Body"],
                sample_exercises=["Squats", "Bench Press", "Rows", "Shoulder Press", "Lunges"]
            ),
            WorkoutSuggestion(
                name="Quick HIIT Blast",
                type="HIIT",
                difficulty="hard",
                duration_minutes=30,
                description="High-intensity interval training for maximum calorie burn.",
                focus_areas=["Full Body", "Cardio"],
                sample_exercises=["Burpees", "Mountain Climbers", "Jump Squats", "High Knees"]
            ),
            WorkoutSuggestion(
                name="Mobility Flow",
                type="Flexibility",
                difficulty="easy",
                duration_minutes=30,
                description="Gentle stretching and mobility work for recovery.",
                focus_areas=["Full Body"],
                sample_exercises=["Cat-Cow", "Hip Flexor Stretch", "Thread the Needle", "Pigeon Pose"]
            ),
        ])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout suggestions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{workout_id}/versions", response_model=List[WorkoutVersionInfo])
async def get_workout_versions(workout_id: str):
    """
    Get all versions of a workout (version history).

    Returns a list of version info objects ordered by version number (newest first).
    """
    logger.info(f"Getting versions for workout {workout_id}")

    try:
        db = get_supabase_db()
        versions = db.get_workout_versions(workout_id)

        if not versions:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Convert to version info objects
        version_infos = []
        for v in versions:
            exercises = v.get("exercises_json", [])
            if isinstance(exercises, str):
                try:
                    exercises = json.loads(exercises)
                except:
                    exercises = []

            version_infos.append(WorkoutVersionInfo(
                id=str(v.get("id")),
                version_number=v.get("version_number", 1),
                name=v.get("name", ""),
                is_current=v.get("is_current", False),
                valid_from=v.get("valid_from"),
                valid_to=v.get("valid_to"),
                generation_method=v.get("generation_method"),
                exercises_count=len(exercises) if isinstance(exercises, list) else 0
            ))

        return version_infos

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout versions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/revert", response_model=Workout)
async def revert_workout(request: RevertWorkoutRequest):
    """
    Revert a workout to a previous version.

    This creates a NEW version with the content of the target version,
    preserving the full history (SCD2 style).
    """
    logger.info(f"Reverting workout {request.workout_id} to version {request.target_version}")

    try:
        db = get_supabase_db()

        # Use the SCD2 revert method
        reverted = db.revert_workout(request.workout_id, request.target_version)

        logger.info(f"Workout reverted: workout_id={request.workout_id}, target_version={request.target_version}, new_id={reverted['id']}")

        log_workout_change(
            workout_id=reverted["id"],
            user_id=reverted.get("user_id"),
            change_type="reverted",
            change_source="revert_endpoint",
            new_value={
                "reverted_to_version": request.target_version,
                "original_workout_id": request.workout_id
            }
        )

        reverted_workout = row_to_workout(reverted)
        await index_workout_to_rag(reverted_workout)

        return reverted_workout

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to revert workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== AI SUMMARY ENDPOINT ====================

@router.get("/{workout_id}/summary")
async def get_workout_ai_summary(workout_id: str, force_regenerate: bool = False):
    """
    Generate an AI summary/description of a workout explaining the intention and benefits.

    Summaries are cached in Supabase per workout per user. Use force_regenerate=true to
    bypass the cache and generate a fresh summary.
    """
    logger.info(f"Getting AI summary for workout {workout_id} (force_regenerate={force_regenerate})")
    try:
        db = get_supabase_db()

        # Get the workout
        result = db.client.table("workouts").select("*").eq("id", workout_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout_data = result.data[0]
        user_id = workout_data.get("user_id")

        # Check for cached summary first (unless force_regenerate)
        if not force_regenerate:
            cached = db.client.table("workout_summaries").select("summary").eq(
                "workout_id", workout_id
            ).eq("user_id", user_id).execute()

            if cached.data:
                logger.info(f"Returning cached summary for workout {workout_id}")
                return {"summary": cached.data[0]["summary"], "cached": True}

        # Parse exercises
        exercises = parse_json_field(workout_data.get("exercises_json"), [])
        target_muscles = parse_json_field(workout_data.get("target_muscles"), [])

        # Get user info for goals and fitness level
        user_result = db.client.table("users").select("goals, fitness_level").eq("id", user_id).execute()

        user_goals = []
        fitness_level = "intermediate"
        if user_result.data:
            user_goals = normalize_goals_list(user_result.data[0].get("goals"))
            fitness_level = user_result.data[0].get("fitness_level", "intermediate")

        # Generate the AI summary using LangGraph agent
        import time
        start_time = time.time()

        summary = await generate_workout_insights(
            workout_id=workout_id,
            workout_name=workout_data.get("name", "Workout"),
            exercises=exercises,
            duration_minutes=workout_data.get("duration_minutes", 45),
            workout_type=workout_data.get("type"),
            difficulty=workout_data.get("difficulty"),
            user_goals=user_goals,
            fitness_level=fitness_level,
        )

        generation_time_ms = int((time.time() - start_time) * 1000)

        # Calculate workout metadata for storage
        duration_minutes = workout_data.get("duration_minutes", 0)
        calories_estimate = duration_minutes * 6 if duration_minutes else len(exercises) * 5

        # Store the summary in Supabase (upsert)
        summary_record = {
            "workout_id": workout_id,
            "user_id": user_id,
            "summary": summary,
            "workout_name": workout_data.get("name"),
            "workout_type": workout_data.get("type"),
            "exercise_count": len(exercises),
            "duration_minutes": duration_minutes,
            "calories_estimate": calories_estimate,
            "model_used": "gpt-4o-mini",
            "generation_time_ms": generation_time_ms,
            "generated_at": datetime.utcnow().isoformat()
        }

        try:
            # Try to upsert (insert or update on conflict)
            existing = db.client.table("workout_summaries").select("id").eq(
                "workout_id", workout_id
            ).eq("user_id", user_id).execute()

            if existing.data:
                db.client.table("workout_summaries").update(summary_record).eq(
                    "id", existing.data[0]["id"]
                ).execute()
                logger.info(f"Updated cached summary for workout {workout_id}")
            else:
                db.client.table("workout_summaries").insert(summary_record).execute()
                logger.info(f"Stored new summary for workout {workout_id}")
        except Exception as store_error:
            # Don't fail the request if storage fails, just log it
            logger.warning(f"Failed to store workout summary: {store_error}")

        return {"summary": summary, "cached": False}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== WARMUP & STRETCHES ENDPOINTS ====================

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


# ============================================
# Background Workout Generation
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


# ============================================
# Program Customization Endpoints
# ============================================


@router.post("/update-program", response_model=UpdateProgramResponse)
@limiter.limit("5/minute")
async def update_program(http_request: Request, request: UpdateProgramRequest):
    """
    Update user's program preferences and delete future incomplete workouts.

    This endpoint:
    1. Updates the user's preferences in the database
    2. Deletes only future incomplete workouts (is_completed=false AND scheduled_date >= today)
    3. Records the changes for analytics
    4. Returns count of deleted workouts for regeneration

    SAFETY: Never deletes completed workouts or past workouts.
    The frontend should trigger workout regeneration after this succeeds.
    """
    logger.info(f"Updating program for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get current preferences
        current_prefs = user.get("preferences", {})
        if isinstance(current_prefs, str):
            try:
                current_prefs = json.loads(current_prefs)
            except json.JSONDecodeError:
                current_prefs = {}

        # Build updated preferences
        updated_prefs = dict(current_prefs)

        if request.difficulty is not None:
            updated_prefs["intensity_preference"] = request.difficulty
        if request.duration_minutes is not None:
            updated_prefs["workout_duration"] = request.duration_minutes
        if request.workout_type is not None:
            updated_prefs["training_split"] = request.workout_type
        if request.workout_days is not None:
            # Store both days_per_week and selected_days
            updated_prefs["days_per_week"] = len(request.workout_days)
            # Convert day names to indices (Mon=0, Tue=1, etc.)
            day_map = {"Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6}
            selected_indices = [day_map.get(d, 0) for d in request.workout_days]
            updated_prefs["selected_days"] = sorted(selected_indices)
        if request.dumbbell_count is not None:
            updated_prefs["dumbbell_count"] = request.dumbbell_count
        if request.kettlebell_count is not None:
            updated_prefs["kettlebell_count"] = request.kettlebell_count

        # Update user preferences and equipment/injuries
        update_data = {"preferences": updated_prefs}

        if request.equipment is not None:
            update_data["equipment"] = request.equipment
        if request.injuries is not None:
            update_data["active_injuries"] = request.injuries

        db.update_user(request.user_id, update_data)
        logger.info(f"Updated preferences for user {request.user_id}")

        # Delete only future incomplete workouts
        # CRITICAL: Never delete completed workouts or past workouts
        from datetime import date
        today = date.today().isoformat()

        # Get all workouts for user
        all_workouts = db.list_workouts(request.user_id, limit=1000)

        # Filter to only future incomplete workouts
        workouts_to_delete = []
        for w in all_workouts:
            scheduled_date = w.get("scheduled_date")
            is_completed = w.get("is_completed", False)

            # Convert scheduled_date to string for comparison
            if hasattr(scheduled_date, 'isoformat'):
                scheduled_date = scheduled_date.isoformat()
            elif hasattr(scheduled_date, 'strftime'):
                scheduled_date = scheduled_date.strftime('%Y-%m-%d')

            # Only delete if: not completed AND scheduled for today or future
            if not is_completed and scheduled_date and scheduled_date >= today:
                workouts_to_delete.append(w)

        logger.info(f"Found {len(workouts_to_delete)} future incomplete workouts to delete")

        # Delete workout changes first (FK constraint)
        for w in workouts_to_delete:
            try:
                db.delete_workout_changes_by_workout(w["id"])
            except Exception as e:
                logger.warning(f"Could not delete workout changes for {w['id']}: {e}")

        # Delete the workouts
        deleted_count = 0
        for w in workouts_to_delete:
            try:
                db.delete_workout(w["id"])
                deleted_count += 1
            except Exception as e:
                logger.error(f"Failed to delete workout {w['id']}: {e}")

        logger.info(f"Deleted {deleted_count} future incomplete workouts for user {request.user_id}")

        # Index preference changes to RAG for AI context
        try:
            rag_service = get_workout_rag_service()
            await rag_service.index_program_preferences(
                user_id=request.user_id,
                difficulty=request.difficulty,
                duration_minutes=request.duration_minutes,
                workout_type=request.workout_type,
                workout_days=request.workout_days,
                equipment=request.equipment,
                focus_areas=request.focus_areas,
                injuries=request.injuries,
                workout_environment=request.workout_environment,
                change_reason="program_customization",
            )
            logger.info(f"Indexed program preferences to RAG for user {request.user_id}")
        except Exception as e:
            logger.warning(f"Could not index preferences to RAG: {e}")

        # Log program customization
        await log_user_activity(
            user_id=request.user_id,
            action="program_customization",
            endpoint="/api/v1/workouts-db/update-program",
            message=f"Updated program, deleted {deleted_count} future workouts",
            metadata={
                "difficulty": request.difficulty,
                "duration_minutes": request.duration_minutes,
                "workout_type": request.workout_type,
                "workout_days": request.workout_days,
                "workouts_deleted": deleted_count,
            },
            status_code=200
        )

        return UpdateProgramResponse(
            success=True,
            message=f"Program updated. {deleted_count} future workouts deleted for regeneration.",
            workouts_deleted=deleted_count,
            preferences_updated=True
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update program: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="program_customization",
            error=e,
            endpoint="/api/v1/workouts-db/update-program",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# ==================== WORKOUT GENERATION PARAMETERS ENDPOINT ====================

@router.get("/{workout_id}/generation-params")
async def get_workout_generation_params(workout_id: str):
    """
    Get the generation parameters and AI reasoning for a workout.

    This endpoint returns:
    - User profile parameters used to generate the workout
    - AI reasoning for exercise selection
    - Equipment, goals, and fitness level context
    """
    logger.info(f"Getting generation parameters for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout
        result = db.client.table("workouts").select("*").eq("id", workout_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout_data = result.data[0]
        user_id = workout_data.get("user_id")

        # Get user profile for context
        user_result = db.client.table("users").select(
            "fitness_level, goals, equipment, active_injuries, age, weight_kg, height_cm, gender"
        ).eq("id", user_id).execute()

        user_profile = {}
        if user_result.data:
            user_data = user_result.data[0]
            user_profile = {
                "fitness_level": user_data.get("fitness_level", "intermediate"),
                "goals": normalize_goals_list(user_data.get("goals")),
                "equipment": parse_json_field(user_data.get("equipment"), []),
                "injuries": parse_json_field(user_data.get("active_injuries"), []),
                "age": user_data.get("age"),
                "weight_kg": user_data.get("weight_kg"),
                "height_cm": user_data.get("height_cm"),
                "gender": user_data.get("gender"),
            }

        # Get program preferences from workout_regenerations (most recent user selections)
        program_preferences = {}
        try:
            regen_result = db.client.table("workout_regenerations").select("*").eq(
                "user_id", user_id
            ).order("created_at", desc=True).limit(1).execute()

            if regen_result.data:
                regen = regen_result.data[0]
                program_preferences = {
                    "difficulty": regen.get("selected_difficulty"),
                    "duration_minutes": regen.get("selected_duration_minutes"),
                    "workout_type": regen.get("selected_workout_type"),
                    "training_split": regen.get("selected_training_split"),
                    "workout_days": parse_json_field(regen.get("selected_workout_days"), []),
                    "focus_areas": parse_json_field(regen.get("selected_focus_areas"), []),
                    "equipment": parse_json_field(regen.get("selected_equipment"), []),
                }
        except Exception as e:
            logger.warning(f"Could not fetch program preferences: {e}")

        # Parse workout exercises
        exercises = parse_json_field(workout_data.get("exercises_json"), [])

        # Build AI reasoning based on the workout parameters
        workout_type = workout_data.get("type", "strength")
        difficulty = workout_data.get("difficulty", "intermediate")
        target_muscles = parse_json_field(workout_data.get("target_muscles"), [])
        workout_name = workout_data.get("name", "Workout")

        # Try AI-powered reasoning first, fall back to static if it fails
        exercise_reasoning = []
        workout_reasoning = ""

        try:
            # Import and use the Gemini service for AI-powered reasoning
            from services.gemini_service import GeminiService
            gemini = GeminiService()

            ai_reasoning = await gemini.generate_exercise_reasoning(
                workout_name=workout_name,
                exercises=exercises,
                user_profile=user_profile,
                program_preferences=program_preferences,
                workout_type=workout_type,
                difficulty=difficulty,
            )

            # Check if AI returned valid reasoning
            if ai_reasoning.get("workout_reasoning") and ai_reasoning.get("exercise_reasoning"):
                workout_reasoning = ai_reasoning["workout_reasoning"]
                logger.info(f"✅ AI-generated workout reasoning for {workout_id}")

                # Map AI reasoning to exercises (match by name)
                ai_exercise_map = {
                    r.get("exercise_name", "").lower(): r.get("reasoning", "")
                    for r in ai_reasoning.get("exercise_reasoning", [])
                }

                for i, ex in enumerate(exercises):
                    ex_name = ex.get("name", f"Exercise {i+1}")
                    muscle_group = ex.get("muscle_group") or ex.get("primary_muscle") or ex.get("body_part", "general")
                    equipment = ex.get("equipment", "bodyweight")

                    # Use AI reasoning if available, otherwise fall back to static
                    ai_reason = ai_exercise_map.get(ex_name.lower(), "")
                    if ai_reason:
                        reasoning = ai_reason
                    else:
                        # Fall back to static reasoning for this exercise
                        reasoning = _build_exercise_reasoning(
                            exercise_name=ex_name,
                            muscle_group=muscle_group,
                            equipment=equipment,
                            sets=ex.get("sets", 3),
                            reps=ex.get("reps", "8-12"),
                            workout_type=workout_type,
                            difficulty=difficulty,
                            user_goals=user_profile.get("goals", []),
                            user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                            user_equipment=user_profile.get("equipment", []),
                        )

                    exercise_reasoning.append({
                        "exercise_name": ex_name,
                        "reasoning": reasoning,
                        "muscle_group": muscle_group,
                        "equipment": equipment,
                    })
            else:
                # AI returned empty - use static fallback
                raise ValueError("AI returned empty reasoning")

        except Exception as ai_error:
            logger.warning(f"⚠️ AI reasoning failed, using static fallback: {ai_error}")

            # Fall back to static reasoning generation
            for i, ex in enumerate(exercises):
                ex_name = ex.get("name", f"Exercise {i+1}")
                muscle_group = ex.get("muscle_group") or ex.get("primary_muscle") or ex.get("body_part", "general")
                equipment = ex.get("equipment", "bodyweight")
                sets = ex.get("sets", 3)
                reps = ex.get("reps", "8-12")

                reasoning = _build_exercise_reasoning(
                    exercise_name=ex_name,
                    muscle_group=muscle_group,
                    equipment=equipment,
                    sets=sets,
                    reps=reps,
                    workout_type=workout_type,
                    difficulty=difficulty,
                    user_goals=user_profile.get("goals", []),
                    user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                    user_equipment=user_profile.get("equipment", []),
                )
                exercise_reasoning.append({
                    "exercise_name": ex_name,
                    "reasoning": reasoning,
                    "muscle_group": muscle_group,
                    "equipment": equipment,
                })

            # Build static workout reasoning
            workout_reasoning = _build_workout_reasoning(
                workout_name=workout_name,
                workout_type=workout_type,
                difficulty=difficulty,
                target_muscles=target_muscles,
                exercise_count=len(exercises),
                duration_minutes=workout_data.get("duration_minutes", 45),
                user_goals=user_profile.get("goals", []),
                user_fitness_level=user_profile.get("fitness_level", "intermediate"),
                training_split=program_preferences.get("training_split"),
            )

        return {
            "workout_id": workout_id,
            "workout_name": workout_data.get("name"),
            "workout_type": workout_type,
            "difficulty": difficulty,
            "duration_minutes": workout_data.get("duration_minutes"),
            "generation_method": workout_data.get("generation_method", "ai"),
            "user_profile": user_profile,
            "program_preferences": program_preferences,
            "workout_reasoning": workout_reasoning,
            "exercise_reasoning": exercise_reasoning,
            "target_muscles": target_muscles,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout generation params: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _build_exercise_reasoning(
    exercise_name: str,
    muscle_group: str,
    equipment: str,
    sets: int,
    reps: str,
    workout_type: str,
    difficulty: str,
    user_goals: list,
    user_fitness_level: str,
    user_equipment: list,
) -> str:
    """Build reasoning explanation for why an exercise was selected."""
    reasons = []

    # Muscle targeting
    if muscle_group:
        reasons.append(f"Targets {muscle_group} effectively")

    # Equipment match
    if equipment:
        equipment_lower = equipment.lower()
        if equipment_lower in ["bodyweight", "none", "body weight"]:
            reasons.append("Requires no equipment - great for home workouts")
        elif user_equipment and any(eq.lower() in equipment_lower for eq in user_equipment):
            reasons.append(f"Matches your available equipment ({equipment})")
        else:
            reasons.append(f"Uses {equipment}")

    # Goal alignment
    goal_map = {
        "muscle_gain": ["compound movement for muscle growth", "builds strength and size"],
        "weight_loss": ["burns calories efficiently", "elevates heart rate"],
        "strength": ["develops maximal strength", "progressive overload focused"],
        "endurance": ["builds muscular endurance", "higher rep scheme"],
        "flexibility": ["improves range of motion", "dynamic movement"],
        "general_fitness": ["well-rounded exercise", "functional movement pattern"],
    }
    for goal in user_goals:
        if goal.lower().replace(" ", "_") in goal_map:
            reasons.append(goal_map[goal.lower().replace(" ", "_")][0])
            break

    # Set/rep scheme reasoning
    if isinstance(reps, str) and "-" in reps:
        reasons.append(f"{sets} sets of {reps} reps for optimal stimulus")
    elif isinstance(reps, int) or (isinstance(reps, str) and reps.isdigit()):
        reps_int = int(reps) if isinstance(reps, str) else reps
        if reps_int <= 5:
            reasons.append(f"Low rep range ({sets}x{reps}) for strength focus")
        elif reps_int <= 12:
            reasons.append(f"{sets}x{reps} in hypertrophy range for muscle growth")
        else:
            reasons.append(f"Higher reps ({sets}x{reps}) for endurance and conditioning")

    # Difficulty appropriateness
    if difficulty:
        difficulty_lower = difficulty.lower()
        if difficulty_lower == "beginner":
            reasons.append("Beginner-friendly movement pattern")
        elif difficulty_lower == "advanced":
            reasons.append("Challenging variation for advanced trainees")

    return ". ".join(reasons) if reasons else "Selected to complement your workout program"


def _build_workout_reasoning(
    workout_name: str,
    workout_type: str,
    difficulty: str,
    target_muscles: list,
    exercise_count: int,
    duration_minutes: int,
    user_goals: list,
    user_fitness_level: str,
    training_split: str = None,
) -> str:
    """Build overall reasoning for the workout design."""
    parts = []

    # Workout type explanation
    type_explanations = {
        "strength": "This strength-focused workout emphasizes compound movements and progressive overload",
        "hypertrophy": "This hypertrophy workout is designed to maximize muscle growth through optimal volume",
        "cardio": "This cardio session elevates heart rate for cardiovascular health and calorie burn",
        "hiit": "This high-intensity interval training alternates intense bursts with recovery periods",
        "endurance": "This endurance workout builds stamina and muscular endurance",
        "flexibility": "This flexibility session improves mobility and range of motion",
        "full_body": "This full-body workout hits all major muscle groups in one session",
        "upper_body": "This upper body session targets chest, back, shoulders, and arms",
        "lower_body": "This lower body workout focuses on quads, hamstrings, glutes, and calves",
        "push": "This push workout targets chest, shoulders, and triceps",
        "pull": "This pull workout targets back, biceps, and rear delts",
        "legs": "This leg day focuses on quadriceps, hamstrings, glutes, and calves",
    }
    workout_type_lower = workout_type.lower().replace(" ", "_")
    if workout_type_lower in type_explanations:
        parts.append(type_explanations[workout_type_lower])
    else:
        parts.append(f"This {workout_type} workout is designed for balanced training")

    # Training split context
    if training_split:
        split_names = {
            "full_body": "full body split (training all muscles each session)",
            "upper_lower": "upper/lower split (alternating focus)",
            "push_pull_legs": "push/pull/legs split (organized by movement pattern)",
            "bro_split": "body part split (one muscle group per day)",
        }
        split_lower = training_split.lower().replace(" ", "_")
        if split_lower in split_names:
            parts.append(f"Following your {split_names[split_lower]}")

    # Target muscles
    if target_muscles:
        muscles_str = ", ".join(target_muscles[:3])
        if len(target_muscles) > 3:
            muscles_str += f" and {len(target_muscles) - 3} more"
        parts.append(f"Primary targets: {muscles_str}")

    # Goal alignment
    if user_goals:
        goals_str = ", ".join(user_goals[:2])
        parts.append(f"Aligned with your goals: {goals_str}")

    # Volume and duration
    parts.append(f"{exercise_count} exercises in approximately {duration_minutes} minutes")

    # Fitness level appropriateness
    if user_fitness_level:
        level_lower = user_fitness_level.lower()
        if level_lower == "beginner":
            parts.append("Designed for beginners with fundamental movements")
        elif level_lower == "intermediate":
            parts.append("Intermediate difficulty with progressive challenges")
        elif level_lower == "advanced":
            parts.append("Advanced training with complex movements and higher intensity")

    return ". ".join(parts) + "."
