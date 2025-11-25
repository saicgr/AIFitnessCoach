"""
Exercise API endpoints with DuckDB.

ENDPOINTS:
- POST /api/v1/exercises/ - Create a new exercise
- GET  /api/v1/exercises/ - List exercises with filters
- GET  /api/v1/exercises/{id} - Get exercise by ID
- GET  /api/v1/exercises/external/{external_id} - Get exercise by external ID
- DELETE /api/v1/exercises/{id} - Delete exercise
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional

from core.duckdb_database import get_db
from models.schemas import Exercise, ExerciseCreate

router = APIRouter()


def row_to_exercise(row) -> Exercise:
    """Convert a database row to Exercise model."""
    return Exercise(
        id=row[0],
        external_id=row[1],
        name=row[2],
        category=row[3],
        subcategory=row[4],
        difficulty_level=row[5],
        primary_muscle=row[6],
        secondary_muscles=row[7],
        equipment_required=row[8],
        body_part=row[9],
        equipment=row[10],
        target=row[11],
        default_sets=row[12],
        default_reps=row[13],
        default_duration_seconds=row[14],
        default_rest_seconds=row[15],
        min_weight_kg=row[16],
        calories_per_minute=row[17],
        instructions=row[18],
        tips=row[19],
        contraindicated_injuries=row[20],
        gif_url=row[21],
        video_url=row[22],
        is_compound=row[23],
        is_unilateral=row[24],
        tags=row[25],
        is_custom=row[26],
        created_by_user_id=row[27],
        created_at=row[28],
    )


EXERCISE_COLUMNS = """
    id, external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required, body_part,
    equipment, target, default_sets, default_reps, default_duration_seconds,
    default_rest_seconds, min_weight_kg, calories_per_minute, instructions,
    tips, contraindicated_injuries, gif_url, video_url, is_compound,
    is_unilateral, tags, is_custom, created_by_user_id, created_at
"""


@router.post("/", response_model=Exercise)
async def create_exercise(exercise: ExerciseCreate):
    """Create a new exercise."""
    try:
        db = get_db()

        # Get next ID
        result = db.conn.execute("SELECT nextval('exercises_id_seq')").fetchone()
        exercise_id = result[0]

        # Insert exercise
        db.conn.execute("""
            INSERT INTO exercises (
                id, external_id, name, category, subcategory, difficulty_level,
                primary_muscle, secondary_muscles, equipment_required, body_part,
                equipment, target, default_sets, default_reps, default_duration_seconds,
                default_rest_seconds, min_weight_kg, calories_per_minute, instructions,
                tips, contraindicated_injuries, gif_url, video_url, is_compound,
                is_unilateral, tags, is_custom, created_by_user_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            exercise_id, exercise.external_id, exercise.name, exercise.category,
            exercise.subcategory, exercise.difficulty_level, exercise.primary_muscle,
            exercise.secondary_muscles, exercise.equipment_required, exercise.body_part,
            exercise.equipment, exercise.target, exercise.default_sets, exercise.default_reps,
            exercise.default_duration_seconds, exercise.default_rest_seconds,
            exercise.min_weight_kg, exercise.calories_per_minute, exercise.instructions,
            exercise.tips, exercise.contraindicated_injuries, exercise.gif_url,
            exercise.video_url, exercise.is_compound, exercise.is_unilateral,
            exercise.tags, exercise.is_custom, exercise.created_by_user_id,
        ])

        # Fetch created exercise
        row = db.conn.execute(f"SELECT {EXERCISE_COLUMNS} FROM exercises WHERE id = ?", [exercise_id]).fetchone()
        return row_to_exercise(row)

    except Exception as e:
        print(f"❌ Error creating exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/", response_model=List[Exercise])
async def list_exercises(
    category: Optional[str] = None,
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    difficulty_level: Optional[int] = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    """List exercises with optional filters."""
    try:
        db = get_db()

        query = f"SELECT {EXERCISE_COLUMNS} FROM exercises WHERE 1=1"
        params = []

        if category:
            query += " AND category = ?"
            params.append(category)
        if body_part:
            query += " AND body_part = ?"
            params.append(body_part)
        if equipment:
            query += " AND equipment = ?"
            params.append(equipment)
        if difficulty_level:
            query += " AND difficulty_level = ?"
            params.append(difficulty_level)

        query += " ORDER BY name LIMIT ? OFFSET ?"
        params.extend([limit, offset])

        rows = db.conn.execute(query, params).fetchall()
        return [row_to_exercise(row) for row in rows]

    except Exception as e:
        print(f"❌ Error listing exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{exercise_id}", response_model=Exercise)
async def get_exercise(exercise_id: int):
    """Get an exercise by ID."""
    try:
        db = get_db()

        row = db.conn.execute(f"SELECT {EXERCISE_COLUMNS} FROM exercises WHERE id = ?", [exercise_id]).fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Exercise not found")

        return row_to_exercise(row)

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error getting exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/external/{external_id}", response_model=Exercise)
async def get_exercise_by_external_id(external_id: str):
    """Get an exercise by external ID."""
    try:
        db = get_db()

        row = db.conn.execute(f"SELECT {EXERCISE_COLUMNS} FROM exercises WHERE external_id = ?", [external_id]).fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Exercise not found")

        return row_to_exercise(row)

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error getting exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{exercise_id}")
async def delete_exercise(exercise_id: int):
    """Delete an exercise."""
    try:
        db = get_db()

        existing = db.conn.execute("SELECT id FROM exercises WHERE id = ?", [exercise_id]).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="Exercise not found")

        db.conn.execute("DELETE FROM exercises WHERE id = ?", [exercise_id])

        return {"message": "Exercise deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error deleting exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))
