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
"""
from fastapi import APIRouter, HTTPException, Query, BackgroundTasks
from typing import List, Optional
from datetime import datetime, timedelta
import json
import asyncio

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import (
    Workout, WorkoutCreate, WorkoutUpdate, GenerateWorkoutRequest,
    SwapWorkoutsRequest, GenerateWeeklyRequest, GenerateWeeklyResponse,
    GenerateMonthlyRequest, GenerateMonthlyResponse,
    RegenerateWorkoutRequest, RevertWorkoutRequest, WorkoutVersionInfo,
    PendingWorkoutGenerationStatus, ScheduleBackgroundGenerationRequest,
    UpdateWorkoutExercisesRequest, UpdateWarmupExercisesRequest, UpdateStretchExercisesRequest,
    WorkoutExitCreate, WorkoutExit,
    UpdateProgramRequest, UpdateProgramResponse
)
from services.openai_service import OpenAIService
from services.rag_service import WorkoutRAGService
from services.langgraph_agents.workout_insights.graph import generate_workout_insights
from services.exercise_library_service import get_exercise_library_service
from services.exercise_rag_service import get_exercise_rag_service
from services.warmup_stretch_service import get_warmup_stretch_service

router = APIRouter()
logger = get_logger(__name__)


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

# Initialize workout RAG service (lazy loading)
_workout_rag_service: Optional[WorkoutRAGService] = None


def get_workout_rag_service() -> WorkoutRAGService:
    """Get or create the workout RAG service instance."""
    global _workout_rag_service
    if _workout_rag_service is None:
        openai_service = OpenAIService()
        _workout_rag_service = WorkoutRAGService(openai_service)
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


@router.post("/generate", response_model=Workout)
async def generate_workout(request: GenerateWorkoutRequest):
    """Generate a new workout for a user based on their preferences."""
    logger.info(f"Generating workout for user {request.user_id}")

    try:
        db = get_supabase_db()

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

        openai_service = OpenAIService()

        try:
            workout_data = await openai_service.generate_workout_plan(
                fitness_level=fitness_level or "intermediate",
                goals=goals if isinstance(goals, list) else [],
                equipment=equipment if isinstance(equipment, list) else [],
                duration_minutes=request.duration_minutes or 45,
                focus_areas=request.focus_areas
            )

            exercises = workout_data.get("exercises", [])
            workout_name = workout_data.get("name", "Generated Workout")
            workout_type = workout_data.get("type", request.workout_type or "strength")
            difficulty = workout_data.get("difficulty", "medium")

        except Exception as ai_error:
            logger.error(f"AI workout generation failed: {ai_error}")
            exercises = [
                {"name": "Push-ups", "sets": 3, "reps": 12, "rest_seconds": 60},
                {"name": "Squats", "sets": 3, "reps": 15, "rest_seconds": 60},
                {"name": "Plank", "sets": 3, "reps": 30, "rest_seconds": 45},
            ]
            workout_name = "Fallback Workout"
            workout_type = "strength"
            difficulty = "medium"

        workout_db_data = {
            "user_id": request.user_id,
            "name": workout_name,
            "type": workout_type,
            "difficulty": difficulty,
            "scheduled_date": datetime.now().isoformat(),
            "exercises_json": exercises,
            "duration_minutes": request.duration_minutes or 45,
            "generation_method": "ai",
            "generation_source": "openai_generation",
        }

        created = db.create_workout(workout_db_data)
        logger.info(f"Workout generated: id={created['id']}")

        log_workout_change(
            workout_id=created['id'],
            user_id=request.user_id,
            change_type="generated",
            change_source="ai_generation",
            new_value={"name": workout_name, "exercises_count": len(exercises)}
        )

        generated_workout = row_to_workout(created)
        await index_workout_to_rag(generated_workout)

        return generated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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

    return {day: "full_body" for day in selected_days}


def calculate_workout_date(week_start_date: str, day_index: int) -> datetime:
    """Calculate the actual date for a workout based on week start and day index."""
    base_date = datetime.fromisoformat(week_start_date)
    return base_date + timedelta(days=day_index)


@router.post("/generate-weekly", response_model=GenerateWeeklyResponse)
async def generate_weekly_workouts(request: GenerateWeeklyRequest):
    """Generate workouts for multiple days in a week."""
    logger.info(f"Generating weekly workouts for user {request.user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level") or "intermediate"
        goals = parse_json_field(user.get("goals"), [])
        equipment = parse_json_field(user.get("equipment"), [])
        preferences = parse_json_field(user.get("preferences"), {})
        training_split = preferences.get("training_split", "full_body")
        # Get age and activity level for personalized workouts
        user_age = user.get("age")
        user_activity_level = user.get("activity_level")

        workout_focus_map = get_workout_focus(training_split, request.selected_days)
        generated_workouts = []
        openai_service = OpenAIService()
        exercise_rag = get_exercise_rag_service()
        used_exercises: List[str] = []

        for day_index in request.selected_days:
            workout_date = calculate_workout_date(request.week_start_date, day_index)
            focus = workout_focus_map[day_index]

            try:
                # Use RAG to intelligently select exercises
                rag_exercises = await exercise_rag.select_exercises_for_workout(
                    focus_area=focus,
                    equipment=equipment if isinstance(equipment, list) else [],
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    count=6,
                    avoid_exercises=used_exercises,
                )

                if rag_exercises:
                    used_exercises.extend([ex.get("name", "") for ex in rag_exercises])
                    workout_data = await openai_service.generate_workout_from_library(
                        exercises=rag_exercises,
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level
                    )
                else:
                    workout_data = await openai_service.generate_workout_plan(
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        equipment=equipment if isinstance(equipment, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level
                    )

                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", f"{focus.title()} Workout")
                workout_type = workout_data.get("type", "strength")
                difficulty = workout_data.get("difficulty", "medium")

            except Exception as e:
                logger.error(f"Error generating workout: {e}")
                exercises = [{"name": "Push-ups", "sets": 3, "reps": 12}, {"name": "Squats", "sets": 3, "reps": 15}]
                workout_name = f"{focus.title()} Workout"
                workout_type = "strength"
                difficulty = "medium"

            workout_db_data = {
                "user_id": request.user_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "scheduled_date": workout_date.isoformat(),
                "exercises_json": exercises,
                "duration_minutes": request.duration_minutes or 45,
                "generation_method": "ai",
                "generation_source": "weekly_generation",
            }

            created = db.create_workout(workout_db_data)
            workout = row_to_workout(created)
            await index_workout_to_rag(workout)
            generated_workouts.append(workout)

        return GenerateWeeklyResponse(workouts=generated_workouts)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate weekly workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def calculate_monthly_dates(month_start_date: str, selected_days: List[int], weeks: int = 12) -> List[datetime]:
    """Calculate workout dates for specified number of weeks from the start date."""
    base_date = datetime.fromisoformat(month_start_date)
    end_date = base_date + timedelta(days=weeks * 7)

    workout_dates = []
    current_date = base_date

    while current_date < end_date:
        weekday = current_date.weekday()
        if weekday in selected_days:
            workout_dates.append(current_date)
        current_date += timedelta(days=1)

    return workout_dates


def extract_name_words(workout_name: str) -> List[str]:
    """Extract significant words from a workout name."""
    import re
    ignore_words = {'the', 'a', 'an', 'of', 'for', 'and', 'or', 'to', 'workout', 'session'}
    words = re.findall(r'[A-Za-z]{3,}', workout_name.lower())
    return [w for w in words if w not in ignore_words]


@router.post("/generate-monthly", response_model=GenerateMonthlyResponse)
async def generate_monthly_workouts(request: GenerateMonthlyRequest):
    """Generate workouts for a full month."""
    import asyncio

    logger.info(f"Generating monthly workouts for user {request.user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level") or "intermediate"
        goals = parse_json_field(user.get("goals"), [])
        equipment = parse_json_field(user.get("equipment"), [])
        preferences = parse_json_field(user.get("preferences"), {})
        training_split = preferences.get("training_split", "full_body")

        # Get injuries and health conditions for workout safety
        active_injuries = parse_json_field(user.get("active_injuries"), [])
        health_conditions = preferences.get("health_conditions", [])

        # Get age and activity level for personalized workouts
        user_age = user.get("age")
        user_activity_level = user.get("activity_level")

        logger.info(f"User data - fitness_level: {fitness_level}, goals: {goals}, equipment: {equipment}")
        if active_injuries or health_conditions:
            logger.info(f"User health info - injuries: {active_injuries}, conditions: {health_conditions}")

        weeks = request.weeks or 12
        workout_dates = calculate_monthly_dates(request.month_start_date, request.selected_days, weeks)
        logger.info(f"Calculated {len(workout_dates)} workout dates for {weeks} weeks on days {request.selected_days}")

        if not workout_dates:
            logger.warning("No workout dates calculated - returning empty response")
            return GenerateMonthlyResponse(workouts=[], total_generated=0)

        workout_focus_map = get_workout_focus(training_split, request.selected_days)

        used_name_words: List[str] = []
        generated_workouts = []
        openai_service = OpenAIService()

        BATCH_SIZE = 4

        # Get exercise RAG service for intelligent selection
        exercise_rag = get_exercise_rag_service()

        # Track used exercises for variety - use a thread-safe approach
        # by passing a copy of the list and collecting results
        used_exercises: List[str] = []

        async def generate_single_workout(
            workout_date: datetime,
            index: int,
            avoid_words: List[str],
            exercises_to_avoid: List[str]  # Pass a snapshot to avoid race conditions
        ):
            weekday = workout_date.weekday()
            focus = workout_focus_map.get(weekday, "full_body")

            try:
                # Use RAG to intelligently select exercises
                # Pass injuries to filter out contraindicated exercises
                rag_exercises = await exercise_rag.select_exercises_for_workout(
                    focus_area=focus,
                    equipment=equipment if isinstance(equipment, list) else [],
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    count=6,
                    avoid_exercises=exercises_to_avoid,  # Use passed-in list for variety
                    injuries=active_injuries if active_injuries else None,
                )

                # Return the exercises used so they can be tracked after batch completes
                exercises_used = []
                if rag_exercises:
                    exercises_used = [ex.get("name", "") for ex in rag_exercises]

                    # Use AI to create a creative workout name
                    workout_data = await openai_service.generate_workout_from_library(
                        exercises=rag_exercises,
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        avoid_name_words=avoid_words[:20],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level
                    )
                else:
                    # Fallback to direct AI generation if RAG fails
                    logger.warning(f"RAG returned no exercises for {focus}, falling back to AI generation")
                    workout_data = await openai_service.generate_workout_plan(
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        equipment=equipment if isinstance(equipment, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        avoid_name_words=avoid_words[:20],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level
                    )

                return {
                    "success": True,
                    "workout_date": workout_date,
                    "focus": focus,
                    "name": workout_data.get("name", f"{focus.title()} Workout"),
                    "type": workout_data.get("type", "strength"),
                    "difficulty": workout_data.get("difficulty", "medium"),
                    "exercises": workout_data.get("exercises", []),
                    "exercises_used": exercises_used,  # Return used exercises for tracking
                }

            except Exception as e:
                logger.error(f"Error generating workout for {workout_date}: {e}")
                return {
                    "success": False,
                    "workout_date": workout_date,
                    "focus": focus,
                    "name": f"{focus.title()} Workout",
                    "type": "strength",
                    "difficulty": "medium",
                    "exercises": [{"name": "Push-ups", "sets": 3, "reps": 12}],
                    "exercises_used": ["Push-ups"],
                }

        for batch_start in range(0, len(workout_dates), BATCH_SIZE):
            batch_end = min(batch_start + BATCH_SIZE, len(workout_dates))
            batch_dates = workout_dates[batch_start:batch_end]

            # Create unique avoid lists for each workout in the batch
            # Each workout in a batch should avoid exercises from previous batches PLUS
            # exercises from earlier workouts in the same batch (using index offset)
            tasks = []
            for i, date in enumerate(batch_dates):
                # For variety within a batch, offset the avoid list by adding index-based seeds
                # so each workout in the same batch gets slightly different avoid lists
                avoid_list = used_exercises[-30:].copy() if used_exercises else []
                tasks.append(generate_single_workout(
                    date,
                    batch_start + i,
                    used_name_words.copy(),
                    avoid_list
                ))
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)

            for result in batch_results:
                if isinstance(result, Exception):
                    continue

                name_words = extract_name_words(result["name"])
                used_name_words.extend(name_words)

                # Track used exercises for variety in next batches
                exercises_used_in_workout = result.get("exercises_used", [])
                if exercises_used_in_workout:
                    used_exercises.extend(exercises_used_in_workout)
                    logger.debug(f"Added {len(exercises_used_in_workout)} exercises to avoid list. Total: {len(used_exercises)}")

                workout_db_data = {
                    "user_id": request.user_id,
                    "name": result["name"],
                    "type": result["type"],
                    "difficulty": result["difficulty"],
                    "scheduled_date": result["workout_date"].isoformat(),
                    "exercises_json": result["exercises"],
                    "duration_minutes": request.duration_minutes or 45,
                    "generation_method": "ai",
                    "generation_source": "monthly_generation",
                }

                created = db.create_workout(workout_db_data)
                workout = row_to_workout(created)
                await index_workout_to_rag(workout)
                generated_workouts.append(workout)

                # Generate warmup and stretches alongside workout (with injury awareness)
                try:
                    warmup_stretch_service = get_warmup_stretch_service()
                    exercises = result["exercises"]

                    # Generate and save warmup (create_warmup_for_workout generates + saves)
                    await warmup_stretch_service.create_warmup_for_workout(
                        workout_id=workout.id,
                        exercises=exercises,
                        duration_minutes=5,
                        injuries=active_injuries if active_injuries else None
                    )

                    # Generate and save stretches (create_stretches_for_workout generates + saves)
                    await warmup_stretch_service.create_stretches_for_workout(
                        workout_id=workout.id,
                        exercises=exercises,
                        duration_minutes=5,
                        injuries=active_injuries if active_injuries else None
                    )
                    logger.info(f"✅ Generated warmup and stretches for workout {workout.id}")
                except Exception as ws_error:
                    logger.warning(f"⚠️ Failed to generate warmup/stretches for workout {workout.id}: {ws_error}")

        return GenerateMonthlyResponse(workouts=generated_workouts, total_generated=len(generated_workouts))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate monthly workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-remaining", response_model=GenerateMonthlyResponse)
async def generate_remaining_workouts(request: GenerateMonthlyRequest):
    """Generate remaining workouts for the month, skipping existing ones."""
    import asyncio

    logger.info(f"Generating remaining workouts for user {request.user_id}")

    try:
        db = get_supabase_db()

        user = db.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user.get("fitness_level") or "intermediate"
        goals = parse_json_field(user.get("goals"), [])
        equipment = parse_json_field(user.get("equipment"), [])
        preferences = parse_json_field(user.get("preferences"), {})
        training_split = preferences.get("training_split", "full_body")

        # Get age and activity level for personalized workouts
        user_age = user.get("age")
        user_activity_level = user.get("activity_level")

        # Extract active injuries for safety filtering
        injuries_data = parse_json_field(user.get("injuries"), [])
        active_injuries = [
            inj.get("type", "") for inj in injuries_data
            if inj.get("status") == "active" and inj.get("type")
        ]
        if active_injuries:
            logger.info(f"🩹 User has active injuries for remaining workouts: {active_injuries}")

        all_workout_dates = calculate_monthly_dates(request.month_start_date, request.selected_days)

        # Get existing workout dates
        from calendar import monthrange
        year = int(request.month_start_date[:4])
        month = int(request.month_start_date[5:7])
        last_day = monthrange(year, month)[1]

        existing_workouts = db.get_workouts_by_date_range(
            request.user_id,
            request.month_start_date,
            f"{request.month_start_date[:7]}-{last_day:02d}"
        )
        existing_dates = {str(w.get("scheduled_date", ""))[:10] for w in existing_workouts}

        workout_dates = [d for d in all_workout_dates if str(d.date()) not in existing_dates]

        if not workout_dates:
            return GenerateMonthlyResponse(workouts=[], total_generated=0)

        workout_focus_map = get_workout_focus(training_split, request.selected_days)

        # Get existing workout names for variety
        existing_names = [w.get("name", "") for w in existing_workouts]
        used_name_words: List[str] = []
        for name in existing_names:
            used_name_words.extend(extract_name_words(name))

        generated_workouts = []
        openai_service = OpenAIService()
        exercise_rag = get_exercise_rag_service()
        used_exercises: List[str] = []

        BATCH_SIZE = 4

        async def generate_single_workout(
            workout_date: datetime,
            avoid_words: List[str],
            exercises_to_avoid: List[str]  # Pass a snapshot to avoid race conditions
        ):
            weekday = workout_date.weekday()
            focus = workout_focus_map.get(weekday, "full_body")

            try:
                # Use RAG to intelligently select exercises (with injury awareness)
                rag_exercises = await exercise_rag.select_exercises_for_workout(
                    focus_area=focus,
                    equipment=equipment if isinstance(equipment, list) else [],
                    fitness_level=fitness_level or "intermediate",
                    goals=goals if isinstance(goals, list) else [],
                    count=6,
                    avoid_exercises=exercises_to_avoid,  # Use passed-in list for variety
                    injuries=active_injuries if active_injuries else None,
                )

                exercises_used = []
                if rag_exercises:
                    exercises_used = [ex.get("name", "") for ex in rag_exercises]
                    workout_data = await openai_service.generate_workout_from_library(
                        exercises=rag_exercises,
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        avoid_name_words=avoid_words[:20],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level
                    )
                else:
                    workout_data = await openai_service.generate_workout_plan(
                        fitness_level=fitness_level or "intermediate",
                        goals=goals if isinstance(goals, list) else [],
                        equipment=equipment if isinstance(equipment, list) else [],
                        duration_minutes=request.duration_minutes or 45,
                        focus_areas=[focus],
                        avoid_name_words=avoid_words[:20],
                        workout_date=workout_date.isoformat(),
                        age=user_age,
                        activity_level=user_activity_level
                    )

                return {
                    "workout_date": workout_date,
                    "focus": focus,
                    "name": workout_data.get("name", f"{focus.title()} Workout"),
                    "type": workout_data.get("type", "strength"),
                    "difficulty": workout_data.get("difficulty", "medium"),
                    "exercises": workout_data.get("exercises", []),
                    "exercises_used": exercises_used,  # Return used exercises for tracking
                }

            except Exception as e:
                logger.error(f"Error generating remaining workout: {e}")
                return {
                    "workout_date": workout_date,
                    "focus": focus,
                    "name": f"{focus.title()} Workout",
                    "type": "strength",
                    "difficulty": "medium",
                    "exercises": [{"name": "Push-ups", "sets": 3, "reps": 12}],
                    "exercises_used": ["Push-ups"],
                }

        for batch_start in range(0, len(workout_dates), BATCH_SIZE):
            batch_end = min(batch_start + BATCH_SIZE, len(workout_dates))
            batch_dates = workout_dates[batch_start:batch_end]

            # Create unique avoid lists for each workout in the batch
            tasks = []
            for date in batch_dates:
                avoid_list = used_exercises[-30:].copy() if used_exercises else []
                tasks.append(generate_single_workout(
                    date,
                    used_name_words.copy(),
                    avoid_list
                ))
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)

            for result in batch_results:
                if isinstance(result, Exception):
                    continue

                name_words = extract_name_words(result["name"])
                used_name_words.extend(name_words)

                # Track used exercises for variety in next batches
                exercises_used_in_workout = result.get("exercises_used", [])
                if exercises_used_in_workout:
                    used_exercises.extend(exercises_used_in_workout)

                workout_db_data = {
                    "user_id": request.user_id,
                    "name": result["name"],
                    "type": result["type"],
                    "difficulty": result["difficulty"],
                    "scheduled_date": result["workout_date"].isoformat(),
                    "exercises_json": result["exercises"],
                    "duration_minutes": request.duration_minutes or 45,
                    "generation_method": "ai",
                    "generation_source": "background_generation",
                }

                created = db.create_workout(workout_db_data)
                workout = row_to_workout(created)
                await index_workout_to_rag(workout)

                # Generate warmup and stretches alongside workout (with injury awareness)
                try:
                    warmup_stretch_service = get_warmup_stretch_service()
                    exercises = result["exercises"]

                    # Generate and save warmup (create_warmup_for_workout generates + saves)
                    await warmup_stretch_service.create_warmup_for_workout(
                        workout_id=workout.id,
                        exercises=exercises,
                        duration_minutes=5,
                        injuries=active_injuries if active_injuries else None
                    )

                    # Generate and save stretches (create_stretches_for_workout generates + saves)
                    await warmup_stretch_service.create_stretches_for_workout(
                        workout_id=workout.id,
                        exercises=exercises,
                        duration_minutes=5,
                        injuries=active_injuries if active_injuries else None
                    )
                    logger.info(f"✅ Generated warmup and stretches for remaining workout {workout.id}")
                except Exception as ws_error:
                    logger.warning(f"⚠️ Failed to generate warmup/stretches for remaining workout {workout.id}: {ws_error}")

                generated_workouts.append(workout)

        return GenerateMonthlyResponse(workouts=generated_workouts, total_generated=len(generated_workouts))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate remaining workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== WORKOUT VERSIONING (SCD2) ENDPOINTS ====================

@router.post("/regenerate", response_model=Workout)
async def regenerate_workout(request: RegenerateWorkoutRequest):
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
        goals = parse_json_field(user.get("goals"), [])

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

        logger.info(f"🎯 Regenerating workout with: fitness_level={fitness_level}")
        logger.info(f"  - equipment={equipment} (from request: {request.equipment})")
        logger.info(f"  - difficulty={user_difficulty}")
        logger.info(f"  - workout_type={workout_type_override}")
        logger.info(f"  - duration_minutes={request.duration_minutes}")
        logger.info(f"  - injuries={injuries}")
        logger.info(f"  - focus_areas={focus_areas}")

        openai_service = OpenAIService()
        exercise_rag = get_exercise_rag_service()

        # Determine focus area from existing workout or request
        focus_areas = request.focus_areas or []
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
            )

            if rag_exercises:
                # Use RAG-selected exercises with real videos
                logger.info(f"RAG selected {len(rag_exercises)} exercises for regeneration")
                workout_data = await openai_service.generate_workout_from_library(
                    exercises=rag_exercises,
                    fitness_level=fitness_level,
                    goals=goals if isinstance(goals, list) else [],
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=focus_areas if focus_areas else [focus_area],
                    age=user_age,
                    activity_level=user_activity_level
                )
            else:
                # Fallback to direct generation if RAG fails
                logger.warning("RAG returned no exercises, falling back to direct generation")
                workout_data = await openai_service.generate_workout_plan(
                    fitness_level=fitness_level,
                    goals=goals if isinstance(goals, list) else [],
                    equipment=equipment if isinstance(equipment, list) else [],
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=focus_areas if focus_areas else None,
                    age=user_age,
                    activity_level=user_activity_level
                )

            exercises = workout_data.get("exercises", [])
            workout_name = workout_data.get("name", "Regenerated Workout")
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
        await index_workout_to_rag(regenerated)

        # Record regeneration analytics for tracking user customization patterns
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

            import time
            generation_end_time = time.time()
            generation_time_ms = int((generation_end_time - time.time()) * 1000) if 'generation_start_time' not in dir() else None

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
                generation_time_ms=generation_time_ms,
            )
            logger.info(f"📊 Recorded regeneration analytics for workout {new_workout['id']}")

            # Index custom inputs to ChromaDB for AI retrieval (fire-and-forget)
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
                        logger.info(f"🔍 Indexed custom focus area to ChromaDB: {custom_focus_area}")

                    if custom_injury:
                        await custom_rag.index_custom_input(
                            input_type="injury",
                            input_value=custom_injury,
                            user_id=request.user_id,
                        )
                        logger.info(f"🔍 Indexed custom injury to ChromaDB: {custom_injury}")
                except Exception as chroma_error:
                    logger.warning(f"⚠️ Failed to index custom inputs to ChromaDB: {chroma_error}")
        except Exception as analytics_error:
            # Don't fail the regeneration if analytics recording fails
            logger.warning(f"⚠️ Failed to record regeneration analytics: {analytics_error}")

        return regenerated

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to regenerate workout: {e}")
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


class WorkoutSuggestionsResponse(BaseModel):
    """Response with workout suggestions."""
    suggestions: List[WorkoutSuggestion]


@router.post("/suggest", response_model=WorkoutSuggestionsResponse)
async def get_workout_suggestions(request: WorkoutSuggestionRequest):
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
        goals = parse_json_field(user.get("goals"), [])
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

Return a JSON array with exactly 4 suggestions, each containing:
- name: Creative workout name that reflects the equipment/sport if specified (e.g., "Dumbbell Power Circuit", "Cricket Athlete Conditioning")
- type: One of [Strength, HIIT, Cardio, Flexibility, Full Body, Upper Body, Lower Body, Core]
- difficulty: One of [easy, medium, hard]
- duration_minutes: Integer between 15-90 (use user's requested duration if specified)
- description: 1-2 sentence description mentioning the specific equipment/focus
- focus_areas: Array of 1-3 body areas targeted

IMPORTANT: Return ONLY the JSON array, no markdown or explanations."""

        user_prompt = request.prompt if request.prompt else "Give me some workout alternatives"

        openai_service = OpenAIService()
        response = await openai_service.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.7,
            max_tokens=1500,
        )

        content = response.choices[0].message.content.strip()

        # Parse JSON response
        if "```" in content:
            # Extract from code block
            parts = content.split("```")
            for part in parts:
                part = part.strip()
                if part.startswith("json"):
                    part = part[4:].strip()
                if part.startswith("["):
                    content = part
                    break

        # Find JSON array
        start_idx = content.find("[")
        end_idx = content.rfind("]") + 1
        if start_idx != -1 and end_idx > start_idx:
            content = content[start_idx:end_idx]

        suggestions_data = json.loads(content)

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
                focus_areas=["Full Body"]
            ),
            WorkoutSuggestion(
                name="Quick HIIT Blast",
                type="HIIT",
                difficulty="hard",
                duration_minutes=30,
                description="High-intensity interval training for maximum calorie burn.",
                focus_areas=["Full Body", "Cardio"]
            ),
            WorkoutSuggestion(
                name="Mobility Flow",
                type="Flexibility",
                difficulty="easy",
                duration_minutes=30,
                description="Gentle stretching and mobility work for recovery.",
                focus_areas=["Full Body"]
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
            user_goals = parse_json_field(user_result.data[0].get("goals"), [])
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
    """Generate and create warmup exercises for an existing workout."""
    logger.info(f"Creating warmup for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])

        service = get_warmup_stretch_service()
        warmup = await service.create_warmup_for_workout(workout_id, exercises, duration_minutes)

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
    """Generate and create cool-down stretches for an existing workout."""
    logger.info(f"Creating stretches for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])

        service = get_warmup_stretch_service()
        stretches = await service.create_stretches_for_workout(workout_id, exercises, duration_minutes)

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
    """Generate and create both warmup and stretches for an existing workout."""
    logger.info(f"Creating warmup and stretches for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get the workout to extract exercises
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = parse_json_field(workout.get("exercises_json") or workout.get("exercises"), [])

        service = get_warmup_stretch_service()
        result = await service.generate_warmup_and_stretches_for_workout(
            workout_id, exercises, warmup_duration, stretch_duration
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create warmup and stretches: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Background Workout Generation
# ============================================

from services.job_queue_service import get_job_queue_service


async def _run_background_generation(
    job_id: str,
    user_id: str,
    month_start_date: str,
    duration_minutes: int,
    selected_days: List[int],
    weeks: int
):
    """Background task to generate remaining workouts with database-backed job tracking."""
    logger.info(f"🔄 Starting background generation for user {user_id} (job {job_id})")

    job_queue = get_job_queue_service()

    try:
        # Update job status to in_progress
        job_queue.update_job_status(job_id, "in_progress")

        # Create the request and call the existing generate_remaining_workouts logic
        request = GenerateMonthlyRequest(
            user_id=user_id,
            month_start_date=month_start_date,
            duration_minutes=duration_minutes,
            selected_days=selected_days,
            weeks=weeks
        )

        # Call the synchronous generation
        result = await generate_remaining_workouts(request)

        # Update job as completed
        job_queue.update_job_status(
            job_id,
            "completed",
            total_generated=result.total_generated
        )

        logger.info(f"✅ Background generation completed for user {user_id}: {result.total_generated} workouts")

    except Exception as e:
        logger.error(f"❌ Background generation failed for user {user_id}: {e}")
        job_queue.update_job_status(
            job_id,
            "failed",
            error_message=str(e)
        )


@router.post("/schedule-background-generation")
async def schedule_background_generation(
    request: ScheduleBackgroundGenerationRequest,
    background_tasks: BackgroundTasks
):
    """
    Schedule workout generation to run in the background on the server.

    This endpoint returns immediately after scheduling the task.
    Use GET /generation-status/{user_id} to check progress.

    Jobs are persisted to database for reliability across server restarts.
    """
    logger.info(f"📅 Scheduling background generation for user {request.user_id}")

    job_queue = get_job_queue_service()

    # Check if already generating
    existing_job = job_queue.get_user_pending_job(request.user_id)
    if existing_job and existing_job.get("status") == "in_progress":
        return {
            "success": True,
            "message": "Generation already in progress",
            "status": "in_progress",
            "job_id": existing_job.get("id")
        }

    # Create a new job in the database
    job_id = job_queue.create_job(
        user_id=request.user_id,
        month_start_date=request.month_start_date,
        duration_minutes=request.duration_minutes,
        selected_days=request.selected_days,
        weeks=request.weeks
    )

    # Schedule the background task with job_id
    background_tasks.add_task(
        _run_background_generation,
        job_id,
        request.user_id,
        request.month_start_date,
        request.duration_minutes,
        request.selected_days,
        request.weeks
    )

    return {
        "success": True,
        "message": "Workout generation scheduled",
        "status": "pending",
        "job_id": job_id
    }


@router.get("/generation-status/{user_id}", response_model=PendingWorkoutGenerationStatus)
async def get_generation_status(user_id: str):
    """Get the status of background workout generation for a user."""
    job_queue = get_job_queue_service()

    # Check for any pending/in-progress job first
    job = job_queue.get_user_pending_job(user_id)

    if not job:
        # Check the latest completed job
        job = job_queue.get_latest_job_for_user(user_id)

    if not job:
        # No job found - check if user has sufficient workouts
        db = get_supabase_db()
        workouts = db.list_workouts(user_id, limit=50)

        return PendingWorkoutGenerationStatus(
            user_id=user_id,
            status="none",
            total_expected=0,
            total_generated=len(workouts) if workouts else 0,
            error_message=None
        )

    return PendingWorkoutGenerationStatus(
        user_id=user_id,
        status=job.get("status", "unknown"),
        total_expected=job.get("total_expected", 0),
        total_generated=job.get("total_generated", 0),
        error_message=job.get("error_message")
    )


@router.post("/ensure-workouts-generated")
async def ensure_workouts_generated(
    request: ScheduleBackgroundGenerationRequest,
    background_tasks: BackgroundTasks
):
    """
    Check if user has sufficient workouts, and trigger generation if not.

    This is meant to be called when the Home page loads to ensure workouts
    exist even if the initial onboarding generation failed.

    Jobs are persisted to database for reliability across server restarts.
    """
    db = get_supabase_db()
    job_queue = get_job_queue_service()

    # Get user's workout count
    workouts = db.list_workouts(request.user_id, limit=100)
    workout_count = len(workouts) if workouts else 0

    # Calculate expected minimum workouts (at least 2 weeks worth)
    min_expected = 2 * len(request.selected_days)

    if workout_count >= min_expected:
        return {
            "success": True,
            "message": "Sufficient workouts exist",
            "workout_count": workout_count,
            "needs_generation": False
        }

    # Check if already generating
    existing_job = job_queue.get_user_pending_job(request.user_id)
    if existing_job and existing_job.get("status") == "in_progress":
        return {
            "success": True,
            "message": "Generation already in progress",
            "workout_count": workout_count,
            "needs_generation": True,
            "status": "in_progress",
            "job_id": existing_job.get("id")
        }

    # Need to generate more workouts
    logger.info(f"⚠️ User {request.user_id} has only {workout_count} workouts, triggering generation")

    # Create a new job in the database
    job_id = job_queue.create_job(
        user_id=request.user_id,
        month_start_date=request.month_start_date,
        duration_minutes=request.duration_minutes,
        selected_days=request.selected_days,
        weeks=request.weeks
    )

    # Schedule the background task with job_id
    background_tasks.add_task(
        _run_background_generation,
        job_id,
        request.user_id,
        request.month_start_date,
        request.duration_minutes,
        request.selected_days,
        request.weeks
    )

    return {
        "success": True,
        "message": "Workout generation scheduled",
        "workout_count": workout_count,
        "needs_generation": True,
        "status": "pending",
        "job_id": job_id
    }


# ============================================
# Workout Exercise Modification Endpoints
# ============================================

@router.put("/{workout_id}/exercises", response_model=Workout)
async def update_workout_exercises(workout_id: str, request: UpdateWorkoutExercisesRequest):
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
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{workout_id}/warmup/exercises")
async def update_warmup_exercises(workout_id: str, request: UpdateWarmupExercisesRequest):
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
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{workout_id}/stretches/exercises")
async def update_stretch_exercises(workout_id: str, request: UpdateStretchExercisesRequest):
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
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Workout Exit / Quit Tracking
# ============================================

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


@router.post("/check-and-regenerate/{user_id}")
async def check_and_regenerate_workouts(
    user_id: str,
    background_tasks: BackgroundTasks,
    threshold_days: int = Query(default=3, description="Generate if less than this many days of workouts remain")
):
    """
    Check if user has enough upcoming workouts and auto-regenerate if running low.

    This endpoint is designed to be called on home screen load to ensure users
    always have upcoming workouts scheduled. It:
    1. Fetches user's workout preferences from their profile
    2. Checks how many upcoming (incomplete) workouts exist
    3. If less than threshold_days worth of workouts remain, generates next 2 weeks

    Returns immediately - generation happens in background if needed.
    """
    logger.info(f"🔍 Checking workout status for user {user_id}")

    try:
        db = get_supabase_db()
        job_queue = get_job_queue_service()

        # Get user data including preferences
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get user preferences for workout days
        preferences = parse_json_field(user.get("preferences"), {})
        selected_days = preferences.get("workout_days", [0, 2, 4])  # Default Mon/Wed/Fri
        duration_minutes = preferences.get("workout_duration", 45)

        # If no workout days configured, use defaults
        if not selected_days or not isinstance(selected_days, list):
            selected_days = [0, 2, 4]
            logger.warning(f"User {user_id} has no workout_days configured, using defaults: {selected_days}")

        # Get upcoming incomplete workouts
        today = datetime.now().date()
        future_date = today + timedelta(days=30)  # Look ahead 30 days

        workouts = db.get_workouts_by_date_range(
            user_id,
            str(today),
            str(future_date)
        )

        # Filter to only incomplete, future workouts
        upcoming_workouts = [
            w for w in workouts
            if not w.get("is_completed", False)
            and w.get("scheduled_date")
        ]

        # Count unique upcoming workout days
        upcoming_dates = set()
        for w in upcoming_workouts:
            sched_date = w.get("scheduled_date", "")
            if sched_date:
                date_str = str(sched_date)[:10]
                upcoming_dates.add(date_str)

        upcoming_count = len(upcoming_dates)
        logger.info(f"User {user_id} has {upcoming_count} upcoming workout days (threshold: {threshold_days})")

        # Check if generation is needed
        if upcoming_count >= threshold_days:
            return {
                "success": True,
                "needs_generation": False,
                "upcoming_workout_days": upcoming_count,
                "message": f"User has sufficient workouts ({upcoming_count} days)"
            }

        # Check if already generating
        existing_job = job_queue.get_user_pending_job(user_id)
        if existing_job and existing_job.get("status") in ["pending", "in_progress"]:
            return {
                "success": True,
                "needs_generation": True,
                "upcoming_workout_days": upcoming_count,
                "message": "Generation already in progress",
                "status": existing_job.get("status"),
                "job_id": existing_job.get("id")
            }

        # Need to generate more workouts
        logger.info(f"⚠️ User {user_id} needs workout generation: only {upcoming_count} days available")

        # Find the last workout date to start generation from
        if upcoming_workouts:
            # Get the latest scheduled date and start from the day after
            latest_date = max(
                datetime.fromisoformat(str(w.get("scheduled_date"))[:10])
                for w in upcoming_workouts
            )
            start_date = (latest_date + timedelta(days=1)).strftime("%Y-%m-%d")
        else:
            # No upcoming workouts, start from today
            start_date = str(today)

        # Create a new job in the database
        job_id = job_queue.create_job(
            user_id=user_id,
            month_start_date=start_date,
            duration_minutes=duration_minutes,
            selected_days=selected_days,
            weeks=4  # Generate 4 weeks (monthly)
        )

        # Schedule the background task
        background_tasks.add_task(
            _run_background_generation,
            job_id,
            user_id,
            start_date,
            duration_minutes,
            selected_days,
            4  # 4 weeks (monthly)
        )

        logger.info(f"✅ Scheduled workout generation for user {user_id} starting from {start_date}")

        return {
            "success": True,
            "needs_generation": True,
            "upcoming_workout_days": upcoming_count,
            "message": "Workout generation scheduled",
            "status": "pending",
            "job_id": job_id,
            "start_date": start_date,
            "weeks": 4,
            "selected_days": selected_days
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to check/regenerate workouts: {e}")
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


# ============================================
# Program Customization Endpoints
# ============================================


@router.post("/update-program", response_model=UpdateProgramResponse)
async def update_program(request: UpdateProgramRequest):
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
                change_reason="program_customization",
            )
            logger.info(f"Indexed program preferences to RAG for user {request.user_id}")
        except Exception as e:
            logger.warning(f"Could not index preferences to RAG: {e}")

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
        raise HTTPException(status_code=500, detail=str(e))
