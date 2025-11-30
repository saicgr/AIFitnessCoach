"""
Exercise API endpoints with Supabase.

ENDPOINTS:
- POST /api/v1/exercises/ - Create a new exercise
- GET  /api/v1/exercises/ - List exercises with filters
- GET  /api/v1/exercises/{id} - Get exercise by ID
- GET  /api/v1/exercises/external/{external_id} - Get exercise by external ID
- DELETE /api/v1/exercises/{id} - Delete exercise
- POST /api/v1/exercises/index - Index all exercises for RAG search
- GET  /api/v1/exercises/rag/stats - Get RAG index statistics
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import Exercise, ExerciseCreate
from services.exercise_rag_service import get_exercise_rag_service

router = APIRouter()
logger = get_logger(__name__)


def row_to_exercise(row: dict) -> Exercise:
    """Convert a Supabase row dict to Exercise model."""
    return Exercise(
        id=row.get("id"),
        external_id=row.get("external_id"),
        name=row.get("name"),
        category=row.get("category"),
        subcategory=row.get("subcategory"),
        difficulty_level=row.get("difficulty_level"),
        primary_muscle=row.get("primary_muscle"),
        secondary_muscles=row.get("secondary_muscles"),
        equipment_required=row.get("equipment_required"),
        body_part=row.get("body_part"),
        equipment=row.get("equipment"),
        target=row.get("target"),
        default_sets=row.get("default_sets"),
        default_reps=row.get("default_reps"),
        default_duration_seconds=row.get("default_duration_seconds"),
        default_rest_seconds=row.get("default_rest_seconds"),
        min_weight_kg=row.get("min_weight_kg"),
        calories_per_minute=row.get("calories_per_minute"),
        instructions=row.get("instructions"),
        tips=row.get("tips"),
        contraindicated_injuries=row.get("contraindicated_injuries"),
        gif_url=row.get("gif_url"),
        video_url=row.get("video_url"),
        is_compound=row.get("is_compound"),
        is_unilateral=row.get("is_unilateral"),
        tags=row.get("tags"),
        is_custom=row.get("is_custom"),
        created_by_user_id=row.get("created_by_user_id"),
        created_at=row.get("created_at"),
    )


@router.post("/", response_model=Exercise)
async def create_exercise(exercise: ExerciseCreate):
    """Create a new exercise."""
    try:
        db = get_supabase_db()

        exercise_data = {
            "external_id": exercise.external_id,
            "name": exercise.name,
            "category": exercise.category,
            "subcategory": exercise.subcategory,
            "difficulty_level": exercise.difficulty_level,
            "primary_muscle": exercise.primary_muscle,
            "secondary_muscles": exercise.secondary_muscles,
            "equipment_required": exercise.equipment_required,
            "body_part": exercise.body_part,
            "equipment": exercise.equipment,
            "target": exercise.target,
            "default_sets": exercise.default_sets,
            "default_reps": exercise.default_reps,
            "default_duration_seconds": exercise.default_duration_seconds,
            "default_rest_seconds": exercise.default_rest_seconds,
            "min_weight_kg": exercise.min_weight_kg,
            "calories_per_minute": exercise.calories_per_minute,
            "instructions": exercise.instructions,
            "tips": exercise.tips,
            "contraindicated_injuries": exercise.contraindicated_injuries,
            "gif_url": exercise.gif_url,
            "video_url": exercise.video_url,
            "is_compound": exercise.is_compound,
            "is_unilateral": exercise.is_unilateral,
            "tags": exercise.tags,
            "is_custom": exercise.is_custom,
            "created_by_user_id": exercise.created_by_user_id,
        }

        created = db.create_exercise(exercise_data)
        logger.info(f"Exercise created: id={created['id']}, name={exercise.name}")
        return row_to_exercise(created)

    except Exception as e:
        logger.error(f"Error creating exercise: {e}")
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
        db = get_supabase_db()
        rows = db.list_exercises(
            category=category,
            body_part=body_part,
            equipment=equipment,
            difficulty_level=difficulty_level,
            limit=limit,
            offset=offset,
        )
        logger.info(f"Listed {len(rows)} exercises")
        return [row_to_exercise(row) for row in rows]

    except Exception as e:
        logger.error(f"Error listing exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{exercise_id}", response_model=Exercise)
async def get_exercise(exercise_id: int):
    """Get an exercise by ID."""
    try:
        db = get_supabase_db()
        row = db.get_exercise(exercise_id)

        if not row:
            raise HTTPException(status_code=404, detail="Exercise not found")

        return row_to_exercise(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/external/{external_id}", response_model=Exercise)
async def get_exercise_by_external_id(external_id: str):
    """Get an exercise by external ID."""
    try:
        db = get_supabase_db()
        row = db.get_exercise_by_external_id(external_id)

        if not row:
            raise HTTPException(status_code=404, detail="Exercise not found")

        return row_to_exercise(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{exercise_id}")
async def delete_exercise(exercise_id: int):
    """Delete an exercise."""
    try:
        db = get_supabase_db()

        existing = db.get_exercise(exercise_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Exercise not found")

        db.delete_exercise(exercise_id)
        logger.info(f"Exercise deleted: id={exercise_id}")

        return {"message": "Exercise deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/index")
async def index_exercises_for_rag():
    """
    Index all exercises from exercise_library into the RAG vector store.

    This endpoint should be called once to populate the vector store,
    or periodically to update it with new exercises.

    Returns:
        Number of exercises indexed
    """
    logger.info("🔄 Starting exercise library indexing for RAG...")
    try:
        rag_service = get_exercise_rag_service()
        indexed_count = await rag_service.index_all_exercises()

        logger.info(f"✅ Indexed {indexed_count} exercises for RAG")
        return {
            "success": True,
            "message": f"Successfully indexed {indexed_count} exercises",
            "indexed_count": indexed_count,
        }

    except Exception as e:
        logger.error(f"❌ Failed to index exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/rag/stats")
async def get_rag_stats():
    """
    Get statistics about the exercise RAG index.

    Returns:
        Current stats including total indexed exercises
    """
    try:
        rag_service = get_exercise_rag_service()
        stats = rag_service.get_stats()

        return {
            "success": True,
            "stats": stats,
        }

    except Exception as e:
        logger.error(f"Error getting RAG stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))
