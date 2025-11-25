"""
Workout CRUD API endpoints with DuckDB.

ENDPOINTS:
- POST /api/v1/workouts-db/ - Create a new workout
- GET  /api/v1/workouts-db/ - List workouts for a user
- GET  /api/v1/workouts-db/{id} - Get workout by ID
- PUT  /api/v1/workouts-db/{id} - Update workout
- DELETE /api/v1/workouts-db/{id} - Delete workout
- POST /api/v1/workouts-db/{id}/complete - Mark workout as completed
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime
import json

from core.duckdb_database import get_db
from core.logger import get_logger
from models.schemas import Workout, WorkoutCreate, WorkoutUpdate, GenerateWorkoutRequest, SwapWorkoutsRequest, GenerateWeeklyRequest, GenerateWeeklyResponse, GenerateMonthlyRequest, GenerateMonthlyResponse
from services.openai_service import OpenAIService
from services.rag_service import WorkoutRAGService

router = APIRouter()
logger = get_logger(__name__)

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
        exercises = json.loads(workout.exercises_json)
        await rag_service.index_workout(
            workout_id=workout.id,
            user_id=workout.user_id,
            name=workout.name,
            workout_type=workout.type,
            difficulty=workout.difficulty,
            exercises=exercises,
            scheduled_date=workout.scheduled_date.isoformat(),
            is_completed=workout.is_completed,
            generation_method=workout.generation_method,
        )
    except Exception as e:
        logger.error(f"Failed to index workout to RAG: {e}")
        # Don't raise - RAG indexing failure shouldn't break the main operation


def log_workout_change(
    workout_id: int,
    user_id: int,
    change_type: str,
    field_changed: str = None,
    old_value = None,
    new_value = None,
    change_source: str = "api",
    change_reason: str = None
):
    """Log a change to a workout for audit trail and RAG."""
    try:
        db = get_db()
        # Use MAX(id) + 1 to avoid sequence conflicts with existing data
        result = db.conn.execute("SELECT COALESCE(MAX(id), 0) + 1 FROM workout_changes").fetchone()
        change_id = result[0]

        db.conn.execute("""
            INSERT INTO workout_changes
            (id, workout_id, user_id, change_type, field_changed, old_value, new_value, change_source, change_reason)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            change_id,
            workout_id,
            user_id,
            change_type,
            field_changed,
            json.dumps(old_value) if old_value is not None else None,
            json.dumps(new_value) if new_value is not None else None,
            change_source,
            change_reason
        ])
        logger.debug(f"Logged workout change: workout_id={workout_id}, type={change_type}, field={field_changed}")
    except Exception as e:
        logger.error(f"Failed to log workout change: {e}")
        # Don't raise - logging failure shouldn't break the main operation


def row_to_workout(row) -> Workout:
    """Convert a database row to Workout model."""
    return Workout(
        id=row[0],
        user_id=row[1],
        name=row[2],
        type=row[3],
        difficulty=row[4],
        scheduled_date=row[5],
        is_completed=row[6],
        exercises_json=row[7],
        created_at=row[8],
        generation_method=row[9],
        generation_source=row[10],
        generation_metadata=row[11],
        generated_at=row[12],
        last_modified_method=row[13],
        last_modified_at=row[14],
        modification_history=row[15],
    )


WORKOUT_COLUMNS = """
    id, user_id, name, type, difficulty, scheduled_date, is_completed,
    exercises_json, created_at, generation_method, generation_source,
    generation_metadata, generated_at, last_modified_method, last_modified_at,
    modification_history
"""


@router.post("/", response_model=Workout)
async def create_workout(workout: WorkoutCreate):
    """Create a new workout."""
    logger.info(f"Creating workout for user {workout.user_id}: {workout.name}")
    try:
        db = get_db()

        # Get next ID
        result = db.conn.execute("SELECT nextval('workouts_id_seq')").fetchone()
        workout_id = result[0]

        # Insert workout
        db.conn.execute("""
            INSERT INTO workouts (
                id, user_id, name, type, difficulty, scheduled_date,
                exercises_json, generation_method, generation_source, generation_metadata
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            workout_id, workout.user_id, workout.name, workout.type,
            workout.difficulty, workout.scheduled_date, workout.exercises_json,
            workout.generation_method, workout.generation_source, workout.generation_metadata,
        ])

        # Fetch created workout
        row = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()
        logger.info(f"Workout created: id={workout_id}")

        # Log the creation
        log_workout_change(
            workout_id=workout_id,
            user_id=workout.user_id,
            change_type="created",
            change_source=workout.generation_source or "api",
            new_value={"name": workout.name, "type": workout.type, "exercises_count": len(json.loads(workout.exercises_json))}
        )

        created_workout = row_to_workout(row)

        # Index to RAG for AI context
        await index_workout_to_rag(created_workout)

        return created_workout

    except Exception as e:
        logger.error(f"Failed to create workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/", response_model=List[Workout])
async def list_workouts(
    user_id: int,
    is_completed: Optional[bool] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    """List workouts for a user with optional filters."""
    logger.info(f"Listing workouts for user {user_id}")
    try:
        db = get_db()

        query = f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE user_id = ?"
        params = [user_id]

        if is_completed is not None:
            query += " AND is_completed = ?"
            params.append(is_completed)
        if from_date:
            query += " AND scheduled_date >= ?"
            params.append(from_date)
        if to_date:
            query += " AND scheduled_date <= ?"
            params.append(to_date)

        query += " ORDER BY scheduled_date DESC LIMIT ? OFFSET ?"
        params.extend([limit, offset])

        rows = db.conn.execute(query, params).fetchall()
        logger.info(f"Found {len(rows)} workouts for user {user_id}")
        return [row_to_workout(row) for row in rows]

    except Exception as e:
        logger.error(f"Failed to list workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{workout_id}", response_model=Workout)
async def get_workout(workout_id: int):
    """Get a workout by ID."""
    logger.debug(f"Fetching workout: id={workout_id}")
    try:
        db = get_db()

        row = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()

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
async def update_workout(workout_id: int, workout: WorkoutUpdate):
    """Update a workout."""
    logger.info(f"Updating workout: id={workout_id}")
    try:
        db = get_db()

        # Check if workout exists
        existing = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()
        if not existing:
            logger.warning(f"Workout not found for update: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        # Build update query
        updates = []
        values = []

        if workout.name is not None:
            updates.append("name = ?")
            values.append(workout.name)
        if workout.type is not None:
            updates.append("type = ?")
            values.append(workout.type)
        if workout.difficulty is not None:
            updates.append("difficulty = ?")
            values.append(workout.difficulty)
        if workout.scheduled_date is not None:
            updates.append("scheduled_date = ?")
            values.append(workout.scheduled_date)
        if workout.is_completed is not None:
            updates.append("is_completed = ?")
            values.append(workout.is_completed)
        if workout.exercises_json is not None:
            updates.append("exercises_json = ?")
            values.append(workout.exercises_json)
        if workout.last_modified_method is not None:
            updates.append("last_modified_method = ?")
            values.append(workout.last_modified_method)

        if updates:
            # Always update last_modified_at
            updates.append("last_modified_at = ?")
            values.append(datetime.now())

            # Update modification history
            current_workout = row_to_workout(existing)
            history = json.loads(current_workout.modification_history or "[]")
            history.append({
                "method": workout.last_modified_method or "api",
                "timestamp": datetime.now().isoformat(),
            })
            updates.append("modification_history = ?")
            values.append(json.dumps(history))

            values.append(workout_id)
            db.conn.execute(f"""
                UPDATE workouts SET {', '.join(updates)} WHERE id = ?
            """, values)
            logger.debug(f"Updated {len(updates)} fields for workout {workout_id}")

        # Fetch updated workout
        row = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()
        updated_workout = row_to_workout(row)
        logger.info(f"Workout updated: id={workout_id}")

        # Log all field changes
        current_workout = row_to_workout(existing)
        if workout.name is not None and workout.name != current_workout.name:
            log_workout_change(workout_id, current_workout.user_id, "updated", "name", current_workout.name, workout.name, workout.last_modified_method or "api")
        if workout.type is not None and workout.type != current_workout.type:
            log_workout_change(workout_id, current_workout.user_id, "updated", "type", current_workout.type, workout.type, workout.last_modified_method or "api")
        if workout.difficulty is not None and workout.difficulty != current_workout.difficulty:
            log_workout_change(workout_id, current_workout.user_id, "updated", "difficulty", current_workout.difficulty, workout.difficulty, workout.last_modified_method or "api")
        if workout.exercises_json is not None and workout.exercises_json != current_workout.exercises_json:
            log_workout_change(workout_id, current_workout.user_id, "updated", "exercises", None, {"exercises_count": len(json.loads(workout.exercises_json))}, workout.last_modified_method or "api")

        # Re-index to RAG with updated data
        await index_workout_to_rag(updated_workout)

        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{workout_id}")
async def delete_workout(workout_id: int):
    """Delete a workout and all related records (cascade delete)."""
    logger.info(f"Deleting workout: id={workout_id}")
    try:
        db = get_db()

        # Get full workout info before deletion for audit log
        existing = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()
        if not existing:
            logger.warning(f"Workout not found for deletion: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        workout = row_to_workout(existing)

        # Cascade delete related records first (to avoid FK constraint errors)
        # 1. Delete performance_logs that reference workout_logs for this workout
        db.conn.execute("""
            DELETE FROM performance_logs
            WHERE workout_log_id IN (SELECT id FROM workout_logs WHERE workout_id = ?)
        """, [workout_id])
        logger.debug(f"Deleted performance_logs for workout {workout_id}")

        # 2. Delete workout_logs for this workout
        db.conn.execute("DELETE FROM workout_logs WHERE workout_id = ?", [workout_id])
        logger.debug(f"Deleted workout_logs for workout {workout_id}")

        # 3. Delete workout_changes for this workout
        db.conn.execute("DELETE FROM workout_changes WHERE workout_id = ?", [workout_id])
        logger.debug(f"Deleted workout_changes for workout {workout_id}")

        # 4. Finally delete the workout itself
        db.conn.execute("DELETE FROM workouts WHERE id = ?", [workout_id])
        logger.info(f"Workout deleted: id={workout_id}")

        return {"message": "Workout deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{workout_id}/complete", response_model=Workout)
async def complete_workout(workout_id: int):
    """Mark a workout as completed."""
    logger.info(f"Completing workout: id={workout_id}")
    try:
        db = get_db()

        existing = db.conn.execute("SELECT id, name FROM workouts WHERE id = ?", [workout_id]).fetchone()
        if not existing:
            logger.warning(f"Workout not found: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        db.conn.execute("""
            UPDATE workouts SET is_completed = TRUE, last_modified_at = ?, last_modified_method = 'completed'
            WHERE id = ?
        """, [datetime.now(), workout_id])

        row = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()
        workout = row_to_workout(row)
        logger.info(f"Workout completed: id={workout_id}, name={existing[1]}")

        # Log the completion
        log_workout_change(
            workout_id=workout_id,
            user_id=workout.user_id,
            change_type="completed",
            field_changed="is_completed",
            old_value=False,
            new_value=True,
            change_source="user"
        )

        # Re-index with completed status
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
    logger.info(f"Generating workout for user {request.user_id}: type={request.workout_type or 'strength'}, duration={request.duration_minutes}min")

    try:
        db = get_db()

        # Check if request provides overrides, otherwise fetch from user profile
        if request.fitness_level and request.goals and request.equipment:
            # Use provided values from the modal
            fitness_level = request.fitness_level
            goals = request.goals
            equipment = request.equipment
            logger.debug(f"Using provided preferences: level={fitness_level}, goals={goals}, equipment={equipment}")
        else:
            # Fetch user data to personalize workout
            user_row = db.conn.execute(
                "SELECT fitness_level, goals, equipment FROM users WHERE id = ?",
                [request.user_id]
            ).fetchone()

            if not user_row:
                logger.warning(f"User not found: id={request.user_id}")
                raise HTTPException(status_code=404, detail="User not found")

            fitness_level = request.fitness_level or user_row[0]
            goals = request.goals or json.loads(user_row[1] or "[]")
            equipment = request.equipment or json.loads(user_row[2] or "[]")
            logger.debug(f"User profile: level={fitness_level}, goals={goals}, equipment={equipment}")

        # Use AI to generate personalized workout
        logger.info(f"Generating AI-powered workout for user {request.user_id}")
        openai_service = OpenAIService()

        try:
            workout_data = await openai_service.generate_workout_plan(
                fitness_level=fitness_level or "intermediate",
                goals=goals,
                equipment=equipment,
                duration_minutes=request.duration_minutes or 45,
                focus_areas=request.focus_areas
            )

            # Extract AI-generated data
            exercises = workout_data.get("exercises", [])
            workout_name = workout_data.get("name", f"{goals[0] if goals else 'General'} Workout")
            workout_type = workout_data.get("type", request.workout_type or "strength")
            difficulty = workout_data.get("difficulty", "medium")
            workout_notes = workout_data.get("notes", "")

            logger.info(f"AI generated workout: {workout_name} with {len(exercises)} exercises")

        except Exception as ai_error:
            logger.error(f"AI workout generation failed, falling back to template: {ai_error}")
            # Fallback to simple template if AI fails
            workout_type = request.workout_type or "strength"
            difficulty = "medium" if fitness_level == "intermediate" else ("hard" if fitness_level == "advanced" else "easy")
            exercises = [
                {"name": "Push-ups", "sets": 3, "reps": 12, "rest_seconds": 60, "equipment": "bodyweight"},
                {"name": "Squats", "sets": 3, "reps": 15, "rest_seconds": 60, "equipment": "bodyweight"},
                {"name": "Plank", "sets": 3, "reps": 30, "rest_seconds": 45, "equipment": "bodyweight"},
                {"name": "Lunges", "sets": 3, "reps": 10, "rest_seconds": 60, "equipment": "bodyweight"},
                {"name": "Mountain Climbers", "sets": 3, "reps": 20, "rest_seconds": 45, "equipment": "bodyweight"},
            ]
            workout_name = f"{goals[0] if goals else 'General'} Workout"
            workout_notes = ""

        # Get next ID
        result = db.conn.execute("SELECT nextval('workouts_id_seq')").fetchone()
        workout_id = result[0]

        now = datetime.now()

        # Insert workout
        db.conn.execute("""
            INSERT INTO workouts (
                id, user_id, name, type, difficulty, scheduled_date,
                exercises_json, generation_method, generation_source, generation_metadata
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            workout_id,
            request.user_id,
            workout_name,
            workout_type,
            difficulty,
            now,
            json.dumps(exercises),
            "ai",
            "openai_generation",
            json.dumps({
                "duration_minutes": request.duration_minutes,
                "focus_areas": request.focus_areas or [],
                "user_fitness_level": fitness_level,
            }),
        ])

        # Fetch created workout
        row = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()

        exercise_names = [e['name'] for e in exercises]
        logger.info(f"Workout generated: id={workout_id}, name={workout_name}, exercises={len(exercises)}")
        logger.debug(f"Exercise list: {exercise_names}")

        # Log the AI generation
        log_workout_change(
            workout_id=workout_id,
            user_id=request.user_id,
            change_type="generated",
            change_source="ai_generation",
            new_value={
                "name": workout_name,
                "type": workout_type,
                "exercises_count": len(exercises),
                "duration_minutes": request.duration_minutes,
                "focus_areas": request.focus_areas or [],
            }
        )

        generated_workout = row_to_workout(row)

        # Index to RAG for AI context
        await index_workout_to_rag(generated_workout)

        return generated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/swap")
async def swap_workout_date(request: SwapWorkoutsRequest):
    """
    Move a workout to a new date, swapping if another workout exists there.

    1. Get the workout being moved
    2. Check if another workout exists on new_date
    3. If yes: swap their dates
    4. If no: just update the moved workout's date
    5. Log the swap reason
    """
    logger.info(f"Swapping workout {request.workout_id} to {request.new_date}")
    try:
        db = get_db()

        # Get moved workout
        moved_workout = db.conn.execute(
            "SELECT id, user_id, scheduled_date FROM workouts WHERE id = ?",
            [request.workout_id]
        ).fetchone()

        if not moved_workout:
            logger.warning(f"Workout not found for swap: id={request.workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        old_date = moved_workout[2]
        user_id = moved_workout[1]

        logger.debug(f"Moving workout {request.workout_id} from {old_date} to {request.new_date}")

        # Check for existing workout on new date
        existing = db.conn.execute(
            "SELECT id FROM workouts WHERE user_id = ? AND scheduled_date >= ? AND scheduled_date < ?",
            [user_id, request.new_date, request.new_date + " 23:59:59"]
        ).fetchone()

        if existing:
            # Swap dates
            logger.info(f"Swapping dates: workout {existing[0]} will move to {old_date}")
            db.conn.execute(
                "UPDATE workouts SET scheduled_date = ?, last_modified_at = ?, last_modified_method = 'date_swap' WHERE id = ?",
                [old_date, datetime.now(), existing[0]]
            )

            # Log the swap for the existing workout
            log_workout_change(
                workout_id=existing[0],
                user_id=user_id,
                change_type="date_swap",
                field_changed="scheduled_date",
                old_value=request.new_date,
                new_value=old_date.isoformat() if hasattr(old_date, 'isoformat') else str(old_date),
                change_source="user_drag_drop",
                change_reason=f"Swapped with workout {request.workout_id}"
            )

        # Update moved workout
        db.conn.execute(
            "UPDATE workouts SET scheduled_date = ?, last_modified_at = ?, last_modified_method = 'date_swap' WHERE id = ?",
            [request.new_date, datetime.now(), request.workout_id]
        )

        # Log the swap reason
        log_workout_change(
            workout_id=request.workout_id,
            user_id=user_id,
            change_type="date_swap",
            field_changed="scheduled_date",
            old_value=old_date.isoformat() if hasattr(old_date, 'isoformat') else str(old_date),
            new_value=request.new_date,
            change_source="user_drag_drop",
            change_reason=request.reason or "User moved workout via drag and drop"
        )

        logger.info(f"Workout swap completed: {request.workout_id} moved to {request.new_date}")

        return {
            "success": True,
            "old_date": old_date.isoformat() if hasattr(old_date, 'isoformat') else str(old_date),
            "new_date": request.new_date,
            "swapped_with": existing[0] if existing else None
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to swap workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def get_workout_focus(split: str, selected_days: List[int]) -> dict:
    """
    Return workout focus for each day based on training split.

    Args:
        split: Training split type (full_body, upper_lower, push_pull_legs, body_part)
        selected_days: List of day indices (0=Mon, 1=Tue, etc.)

    Returns:
        Dict mapping day index to workout focus string
    """
    num_days = len(selected_days)

    if split == "full_body":
        return {day: "full_body" for day in selected_days}

    elif split == "upper_lower":
        focuses = ["upper", "lower"] * (num_days // 2 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}

    elif split == "push_pull_legs":
        focuses = ["push", "pull", "legs"] * (num_days // 3 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}

    elif split == "body_part":
        body_parts = ["chest", "back", "shoulders", "legs", "arms", "core"]
        return {day: body_parts[i % len(body_parts)] for i, day in enumerate(selected_days)}

    # Default to full_body for unknown splits
    return {day: "full_body" for day in selected_days}


def calculate_workout_date(week_start_date: str, day_index: int) -> datetime:
    """
    Calculate the actual date for a workout based on week start and day index.

    Args:
        week_start_date: ISO date string for Monday (e.g., "2024-11-25")
        day_index: Day of week (0=Mon, 1=Tue, ..., 6=Sun)

    Returns:
        datetime object for the workout date
    """
    from datetime import timedelta
    base_date = datetime.fromisoformat(week_start_date)
    return base_date + timedelta(days=day_index)


@router.post("/generate-weekly", response_model=GenerateWeeklyResponse)
async def generate_weekly_workouts(request: GenerateWeeklyRequest):
    """
    Generate workouts for multiple days in a week.

    1. Get user profile (including preferences with days_per_week, training_split, etc.)
    2. For each selected day:
       - Generate workout appropriate for that day based on split
       - Save to database with scheduled_date
    3. Return all generated workouts
    """
    logger.info(f"Generating weekly workouts for user {request.user_id}: {len(request.selected_days)} days")

    try:
        db = get_db()

        # Get user and their preferences
        user_row = db.conn.execute(
            "SELECT fitness_level, goals, equipment, preferences FROM users WHERE id = ?",
            [request.user_id]
        ).fetchone()

        if not user_row:
            logger.warning(f"User not found: id={request.user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user_row[0]
        goals = json.loads(user_row[1] or "[]")
        equipment = json.loads(user_row[2] or "[]")
        preferences = json.loads(user_row[3] or "{}")

        training_split = preferences.get("training_split", "full_body")
        logger.debug(f"User profile: level={fitness_level}, split={training_split}, goals={goals}")

        # Determine workout focus for each day based on split
        workout_focus_map = get_workout_focus(training_split, request.selected_days)
        logger.debug(f"Workout focus map: {workout_focus_map}")

        # Generate workouts for each selected day
        generated_workouts = []
        openai_service = OpenAIService()

        for day_index in request.selected_days:
            workout_date = calculate_workout_date(request.week_start_date, day_index)
            focus = workout_focus_map[day_index]

            logger.info(f"Generating {focus} workout for day {day_index} ({workout_date.date()})")

            try:
                # Generate workout with specific focus
                workout_data = await openai_service.generate_workout_plan(
                    fitness_level=fitness_level or "intermediate",
                    goals=goals,
                    equipment=equipment,
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=[focus],
                    workout_date=workout_date.isoformat()  # For holiday theming
                )

                # Extract AI-generated data
                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", f"{focus.title()} Workout")
                workout_type = workout_data.get("type", "strength")
                difficulty = workout_data.get("difficulty", "medium")

                logger.info(f"AI generated {workout_name} with {len(exercises)} exercises")

            except Exception as ai_error:
                logger.error(f"AI workout generation failed for day {day_index}, using fallback: {ai_error}")
                # Fallback to simple template if AI fails
                difficulty = "medium" if fitness_level == "intermediate" else ("hard" if fitness_level == "advanced" else "easy")
                exercises = [
                    {"name": "Push-ups", "sets": 3, "reps": 12, "rest_seconds": 60, "equipment": "bodyweight"},
                    {"name": "Squats", "sets": 3, "reps": 15, "rest_seconds": 60, "equipment": "bodyweight"},
                    {"name": "Plank", "sets": 3, "reps": 30, "rest_seconds": 45, "equipment": "bodyweight"},
                ]
                workout_name = f"{focus.title()} Workout"
                workout_type = "strength"

            # Get next workout ID
            result = db.conn.execute("SELECT nextval('workouts_id_seq')").fetchone()
            workout_id = result[0]

            # Insert workout
            db.conn.execute("""
                INSERT INTO workouts (
                    id, user_id, name, type, difficulty, scheduled_date,
                    exercises_json, generation_method, generation_source, generation_metadata
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                workout_id,
                request.user_id,
                workout_name,
                workout_type,
                difficulty,
                workout_date,
                json.dumps(exercises),
                "ai",
                "weekly_generation",
                json.dumps({
                    "duration_minutes": request.duration_minutes,
                    "focus": focus,
                    "training_split": training_split,
                    "day_index": day_index,
                }),
            ])

            # Fetch created workout
            row = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()
            workout = row_to_workout(row)

            logger.info(f"Workout created: id={workout_id}, name={workout_name}, date={workout_date.date()}")

            # Log the generation
            log_workout_change(
                workout_id=workout_id,
                user_id=request.user_id,
                change_type="generated",
                change_source="weekly_generation",
                new_value={
                    "name": workout_name,
                    "focus": focus,
                    "exercises_count": len(exercises),
                }
            )

            # Index to RAG for AI context
            await index_workout_to_rag(workout)

            generated_workouts.append(workout)

        logger.info(f"Weekly generation complete: {len(generated_workouts)} workouts created")
        return GenerateWeeklyResponse(workouts=generated_workouts)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate weekly workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def calculate_monthly_dates(month_start_date: str, selected_days: List[int]) -> List[datetime]:
    """
    Calculate workout dates for 30 days from the start date based on selected days.

    Args:
        month_start_date: ISO date string for the start date (e.g., "2024-11-25")
        selected_days: List of day indices (0=Mon, 1=Tue, ..., 6=Sun)

    Returns:
        List of datetime objects for all workout days in the 30-day period
    """
    from datetime import timedelta

    base_date = datetime.fromisoformat(month_start_date)

    # Generate workouts for 30 days from the start date
    end_date = base_date + timedelta(days=30)

    workout_dates = []
    current_date = base_date

    while current_date < end_date:
        # Get the weekday (0=Mon, 1=Tue, ..., 6=Sun)
        weekday = current_date.weekday()
        if weekday in selected_days:
            workout_dates.append(current_date)
        current_date += timedelta(days=1)

    return workout_dates


def extract_name_words(workout_name: str) -> List[str]:
    """
    Extract significant words from a workout name to avoid repetition.
    Filters out common words and keeps action/power words.
    """
    import re
    # Common words to ignore
    ignore_words = {
        'the', 'a', 'an', 'of', 'for', 'and', 'or', 'to', 'in', 'on', 'with',
        'workout', 'session', 'training', 'day', 'routine', 'program',
        'push', 'pull', 'legs', 'upper', 'lower', 'full', 'body', 'core',
        'chest', 'back', 'arms', 'shoulders'
    }
    # Extract words (3+ chars, alphabetic)
    words = re.findall(r'[A-Za-z]{3,}', workout_name.lower())
    return [w for w in words if w not in ignore_words]


@router.post("/generate-monthly", response_model=GenerateMonthlyResponse)
async def generate_monthly_workouts(request: GenerateMonthlyRequest):
    """
    Generate workouts for a full month based on user's selected workout days.
    Uses parallel batch generation for speed and tracks used name words for variety.
    """
    import asyncio

    logger.info(f"Generating monthly workouts for user {request.user_id}: days={request.selected_days}, starting {request.month_start_date}")

    try:
        db = get_db()

        # Get user and their preferences
        user_row = db.conn.execute(
            "SELECT fitness_level, goals, equipment, preferences FROM users WHERE id = ?",
            [request.user_id]
        ).fetchone()

        if not user_row:
            logger.warning(f"User not found: id={request.user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user_row[0]
        goals = json.loads(user_row[1] or "[]")
        equipment = json.loads(user_row[2] or "[]")
        preferences = json.loads(user_row[3] or "{}")

        training_split = preferences.get("training_split", "full_body")
        logger.debug(f"User profile: level={fitness_level}, split={training_split}")

        # Calculate all workout dates for the month
        workout_dates = calculate_monthly_dates(request.month_start_date, request.selected_days)
        logger.info(f"Will generate {len(workout_dates)} workouts for the month")

        # Determine workout focus for each day based on split
        workout_focus_map = get_workout_focus(training_split, request.selected_days)
        logger.debug(f"Workout focus map: {workout_focus_map}")

        # Track used name words to avoid repetition
        used_name_words: List[str] = []
        generated_workouts = []
        openai_service = OpenAIService()

        # Parallel batch generation (4 at a time to respect rate limits)
        BATCH_SIZE = 4

        async def generate_single_workout(workout_date: datetime, index: int, current_avoid_words: List[str]):
            """Generate a single workout with the given parameters."""
            weekday = workout_date.weekday()
            focus = workout_focus_map.get(weekday, "full_body")

            logger.info(f"Generating {focus} workout for {workout_date.date()} ({index+1}/{len(workout_dates)})")

            try:
                # Generate workout with specific focus and avoid repeated names
                workout_data = await openai_service.generate_workout_plan(
                    fitness_level=fitness_level or "intermediate",
                    goals=goals,
                    equipment=equipment,
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=[focus],
                    avoid_name_words=current_avoid_words[:20],  # Limit to last 20 words
                    workout_date=workout_date.isoformat()  # For holiday theming
                )

                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", f"{focus.replace('_', ' ').title()} Workout")
                workout_type = workout_data.get("type", "strength")
                difficulty = workout_data.get("difficulty", "medium")

                logger.info(f"AI generated '{workout_name}' with {len(exercises)} exercises")

                return {
                    "success": True,
                    "workout_date": workout_date,
                    "index": index,
                    "focus": focus,
                    "name": workout_name,
                    "type": workout_type,
                    "difficulty": difficulty,
                    "exercises": exercises,
                }

            except Exception as ai_error:
                logger.error(f"AI workout generation failed for {workout_date.date()}: {ai_error}")
                # Fallback
                difficulty = "medium" if fitness_level == "intermediate" else ("hard" if fitness_level == "advanced" else "easy")
                return {
                    "success": False,
                    "workout_date": workout_date,
                    "index": index,
                    "focus": focus,
                    "name": f"{focus.replace('_', ' ').title()} Workout",
                    "type": "strength",
                    "difficulty": difficulty,
                    "exercises": [
                        {"name": "Push-ups", "sets": 3, "reps": 12, "rest_seconds": 60, "equipment": "bodyweight"},
                        {"name": "Squats", "sets": 3, "reps": 15, "rest_seconds": 60, "equipment": "bodyweight"},
                        {"name": "Plank", "sets": 3, "reps": 30, "rest_seconds": 45, "equipment": "bodyweight"},
                        {"name": "Lunges", "sets": 3, "reps": 10, "rest_seconds": 60, "equipment": "bodyweight"},
                    ],
                }

        # Process in batches for parallel generation
        for batch_start in range(0, len(workout_dates), BATCH_SIZE):
            batch_end = min(batch_start + BATCH_SIZE, len(workout_dates))
            batch_dates = workout_dates[batch_start:batch_end]

            logger.info(f"Generating batch {batch_start//BATCH_SIZE + 1}: workouts {batch_start+1}-{batch_end}")

            # Create tasks for parallel execution
            tasks = [
                generate_single_workout(date, batch_start + i, used_name_words.copy())
                for i, date in enumerate(batch_dates)
            ]

            # Execute batch in parallel
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)

            # Process results and save to database
            for result in batch_results:
                if isinstance(result, Exception):
                    logger.error(f"Batch task failed: {result}")
                    continue

                # Extract name words and add to avoid list
                name_words = extract_name_words(result["name"])
                used_name_words.extend(name_words)

                # Get next workout ID
                id_result = db.conn.execute("SELECT nextval('workouts_id_seq')").fetchone()
                workout_id = id_result[0]

                # Insert workout
                db.conn.execute("""
                    INSERT INTO workouts (
                        id, user_id, name, type, difficulty, scheduled_date,
                        exercises_json, generation_method, generation_source, generation_metadata
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, [
                    workout_id,
                    request.user_id,
                    result["name"],
                    result["type"],
                    result["difficulty"],
                    result["workout_date"],
                    json.dumps(result["exercises"]),
                    "ai",
                    "monthly_generation",
                    json.dumps({
                        "duration_minutes": request.duration_minutes,
                        "focus": result["focus"],
                        "training_split": training_split,
                        "workout_index": result["index"],
                        "month_start": request.month_start_date,
                    }),
                ])

                # Fetch created workout
                row = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()
                workout = row_to_workout(row)

                logger.debug(f"Workout created: id={workout_id}, name={result['name']}, date={result['workout_date'].date()}")

                # Log the generation
                log_workout_change(
                    workout_id=workout_id,
                    user_id=request.user_id,
                    change_type="generated",
                    change_source="monthly_generation",
                    new_value={
                        "name": result["name"],
                        "focus": result["focus"],
                        "exercises_count": len(result["exercises"]),
                    }
                )

                # Index to RAG for AI context
                await index_workout_to_rag(workout)

                generated_workouts.append(workout)

        logger.info(f"Monthly generation complete: {len(generated_workouts)} workouts created for user {request.user_id}")
        return GenerateMonthlyResponse(workouts=generated_workouts, total_generated=len(generated_workouts))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate monthly workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-remaining", response_model=GenerateMonthlyResponse)
async def generate_remaining_workouts(request: GenerateMonthlyRequest):
    """
    Generate remaining workouts for the month, skipping dates that already have workouts.
    Used for background generation after onboarding creates the first workout.
    """
    import asyncio

    logger.info(f"Generating remaining workouts for user {request.user_id}: days={request.selected_days}, starting {request.month_start_date}")

    try:
        db = get_db()

        # Get user and their preferences
        user_row = db.conn.execute(
            "SELECT fitness_level, goals, equipment, preferences FROM users WHERE id = ?",
            [request.user_id]
        ).fetchone()

        if not user_row:
            logger.warning(f"User not found: id={request.user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        fitness_level = user_row[0]
        goals = json.loads(user_row[1] or "[]")
        equipment = json.loads(user_row[2] or "[]")
        preferences = json.loads(user_row[3] or "{}")

        training_split = preferences.get("training_split", "full_body")
        logger.debug(f"User profile: level={fitness_level}, split={training_split}")

        # Calculate all workout dates for the month
        all_workout_dates = calculate_monthly_dates(request.month_start_date, request.selected_days)

        # Get existing workout dates for this user in the month
        # Use strftime for DuckDB compatibility (no DATE function)
        # Calculate the actual last day of the month
        from calendar import monthrange
        year = int(request.month_start_date[:4])
        month = int(request.month_start_date[5:7])
        last_day = monthrange(year, month)[1]

        existing_rows = db.conn.execute("""
            SELECT strftime(scheduled_date, '%Y-%m-%d') FROM workouts
            WHERE user_id = ? AND scheduled_date >= ? AND scheduled_date < ?
        """, [
            request.user_id,
            request.month_start_date,
            f"{request.month_start_date[:7]}-{last_day:02d} 23:59:59"
        ]).fetchall()

        existing_dates = {row[0] for row in existing_rows if row[0]}
        logger.info(f"Found {len(existing_dates)} existing workouts in the month")

        # Filter to only dates that don't have workouts yet
        workout_dates = [d for d in all_workout_dates if str(d.date()) not in existing_dates]
        logger.info(f"Will generate {len(workout_dates)} remaining workouts (skipping {len(existing_dates)} existing)")

        if not workout_dates:
            logger.info("No remaining workouts to generate")
            return GenerateMonthlyResponse(workouts=[], total_generated=0)

        # Get existing workout names to avoid repetition
        existing_names = db.conn.execute("""
            SELECT name FROM workouts WHERE user_id = ?
        """, [request.user_id]).fetchall()

        used_name_words: List[str] = []
        for row in existing_names:
            used_name_words.extend(extract_name_words(row[0]))

        # Determine workout focus for each day based on split
        workout_focus_map = get_workout_focus(training_split, request.selected_days)
        logger.debug(f"Workout focus map: {workout_focus_map}")

        generated_workouts = []
        openai_service = OpenAIService()

        # Parallel batch generation (4 at a time)
        BATCH_SIZE = 4

        async def generate_single_workout(workout_date: datetime, index: int, current_avoid_words: List[str]):
            """Generate a single workout with the given parameters."""
            weekday = workout_date.weekday()
            focus = workout_focus_map.get(weekday, "full_body")

            logger.info(f"Generating {focus} workout for {workout_date.date()} ({index+1}/{len(workout_dates)})")

            try:
                workout_data = await openai_service.generate_workout_plan(
                    fitness_level=fitness_level or "intermediate",
                    goals=goals,
                    equipment=equipment,
                    duration_minutes=request.duration_minutes or 45,
                    focus_areas=[focus],
                    avoid_name_words=current_avoid_words[:20],
                    workout_date=workout_date.isoformat()  # For holiday theming
                )

                exercises = workout_data.get("exercises", [])
                workout_name = workout_data.get("name", f"{focus.replace('_', ' ').title()} Workout")
                workout_type = workout_data.get("type", "strength")
                difficulty = workout_data.get("difficulty", "medium")

                logger.info(f"AI generated '{workout_name}' with {len(exercises)} exercises")

                return {
                    "success": True,
                    "workout_date": workout_date,
                    "index": index,
                    "focus": focus,
                    "name": workout_name,
                    "type": workout_type,
                    "difficulty": difficulty,
                    "exercises": exercises,
                }

            except Exception as ai_error:
                logger.error(f"AI workout generation failed for {workout_date.date()}: {ai_error}")
                difficulty = "medium" if fitness_level == "intermediate" else ("hard" if fitness_level == "advanced" else "easy")
                return {
                    "success": False,
                    "workout_date": workout_date,
                    "index": index,
                    "focus": focus,
                    "name": f"{focus.replace('_', ' ').title()} Workout",
                    "type": "strength",
                    "difficulty": difficulty,
                    "exercises": [
                        {"name": "Push-ups", "sets": 3, "reps": 12, "rest_seconds": 60, "equipment": "bodyweight"},
                        {"name": "Squats", "sets": 3, "reps": 15, "rest_seconds": 60, "equipment": "bodyweight"},
                        {"name": "Plank", "sets": 3, "reps": 30, "rest_seconds": 45, "equipment": "bodyweight"},
                        {"name": "Lunges", "sets": 3, "reps": 10, "rest_seconds": 60, "equipment": "bodyweight"},
                    ],
                }

        # Process in batches for parallel generation
        for batch_start in range(0, len(workout_dates), BATCH_SIZE):
            batch_end = min(batch_start + BATCH_SIZE, len(workout_dates))
            batch_dates = workout_dates[batch_start:batch_end]

            logger.info(f"Generating batch {batch_start//BATCH_SIZE + 1}: workouts {batch_start+1}-{batch_end}")

            tasks = [
                generate_single_workout(date, batch_start + i, used_name_words.copy())
                for i, date in enumerate(batch_dates)
            ]

            batch_results = await asyncio.gather(*tasks, return_exceptions=True)

            for result in batch_results:
                if isinstance(result, Exception):
                    logger.error(f"Batch task failed: {result}")
                    continue

                name_words = extract_name_words(result["name"])
                used_name_words.extend(name_words)

                id_result = db.conn.execute("SELECT nextval('workouts_id_seq')").fetchone()
                workout_id = id_result[0]

                db.conn.execute("""
                    INSERT INTO workouts (
                        id, user_id, name, type, difficulty, scheduled_date,
                        exercises_json, generation_method, generation_source, generation_metadata
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, [
                    workout_id,
                    request.user_id,
                    result["name"],
                    result["type"],
                    result["difficulty"],
                    result["workout_date"],
                    json.dumps(result["exercises"]),
                    "ai",
                    "background_generation",
                    json.dumps({
                        "duration_minutes": request.duration_minutes,
                        "focus": result["focus"],
                        "training_split": training_split,
                        "workout_index": result["index"],
                        "month_start": request.month_start_date,
                    }),
                ])

                row = db.conn.execute(f"SELECT {WORKOUT_COLUMNS} FROM workouts WHERE id = ?", [workout_id]).fetchone()
                workout = row_to_workout(row)

                logger.debug(f"Workout created: id={workout_id}, name={result['name']}, date={result['workout_date'].date()}")

                log_workout_change(
                    workout_id=workout_id,
                    user_id=request.user_id,
                    change_type="generated",
                    change_source="background_generation",
                    new_value={
                        "name": result["name"],
                        "focus": result["focus"],
                        "exercises_count": len(result["exercises"]),
                    }
                )

                await index_workout_to_rag(workout)
                generated_workouts.append(workout)

        logger.info(f"Background generation complete: {len(generated_workouts)} workouts created for user {request.user_id}")
        return GenerateMonthlyResponse(workouts=generated_workouts, total_generated=len(generated_workouts))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate remaining workouts: {e}")
        raise HTTPException(status_code=500, detail=str(e))
