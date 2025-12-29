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

CUSTOM EXERCISE ENDPOINTS:
- GET  /api/v1/exercises/custom/{user_id} - Get user's custom exercises
- POST /api/v1/exercises/custom/{user_id} - Create a custom exercise for user
- DELETE /api/v1/exercises/custom/{user_id}/{exercise_id} - Delete user's custom exercise
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from pydantic import BaseModel, Field
import uuid

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


@router.get("/library/by-name/{name}")
async def get_exercise_from_library_by_name(name: str):
    """
    Get full exercise details from exercise_library by name (case-insensitive fuzzy match).

    This is useful for fetching full instructions for exercises that may have
    been stored with truncated notes.
    """
    try:
        db = get_supabase_db()

        # First try exact match (case-insensitive)
        # Note: exercise_library uses 'exercise_name' column, not 'name'
        result = db.client.table("exercise_library").select("*").ilike("exercise_name", name).limit(1).execute()

        if not result.data:
            # Try fuzzy match - search for name containing the search term
            result = db.client.table("exercise_library").select("*").ilike("exercise_name", f"%{name}%").limit(1).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found in library")

        exercise = result.data[0]

        # Map exercise_library columns to expected response format
        # Columns: id, exercise_name, body_part, equipment, target_muscle, secondary_muscles,
        #          instructions, difficulty_level, category, gif_url, video_s3_path, raw_data, created_at
        return {
            "id": exercise.get("id"),
            "name": exercise.get("exercise_name"),
            "instructions": exercise.get("instructions"),
            "muscle_group": exercise.get("target_muscle") or exercise.get("body_part"),
            "equipment": exercise.get("equipment"),
            "video_url": exercise.get("video_s3_path") or exercise.get("gif_url"),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting exercise from library: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# CUSTOM EXERCISE ENDPOINTS
# ============================================================================

class CustomExerciseCreate(BaseModel):
    """Simplified model for creating a custom exercise."""
    name: str = Field(..., min_length=1, max_length=200)
    primary_muscle: str = Field(..., max_length=100)  # e.g., "chest", "back", "legs"
    equipment: str = Field(default="bodyweight", max_length=200)  # e.g., "dumbbell", "barbell", "none"
    instructions: str = Field(default="", max_length=5000)  # Optional instructions
    default_sets: int = Field(default=3, ge=1, le=10)
    default_reps: Optional[int] = Field(default=10, ge=1, le=100)
    is_compound: bool = Field(default=False)  # Targets multiple muscle groups?


class CustomExerciseResponse(BaseModel):
    """Response model for custom exercises."""
    id: str
    name: str
    primary_muscle: str
    equipment: str
    instructions: str
    default_sets: int
    default_reps: Optional[int]
    is_compound: bool
    created_at: str


@router.get("/custom/{user_id}", response_model=List[CustomExerciseResponse])
async def get_user_custom_exercises(user_id: str):
    """Get all custom exercises created by a user."""
    logger.info(f"🏋️ [Custom Exercises] GET request - Fetching custom exercises for user: {user_id}")
    try:
        db = get_supabase_db()

        # Query exercises where is_custom=true and created_by_user_id=user_id
        result = db.client.table("exercises").select("*").eq(
            "is_custom", True
        ).eq(
            "created_by_user_id", user_id
        ).order("created_at", desc=True).execute()

        exercises = []
        for row in result.data:
            exercises.append(CustomExerciseResponse(
                id=row["id"],
                name=row["name"],
                primary_muscle=row["primary_muscle"],
                equipment=row["equipment"],
                instructions=row.get("instructions", ""),
                default_sets=row.get("default_sets", 3),
                default_reps=row.get("default_reps"),
                is_compound=row.get("is_compound", False),
                created_at=row["created_at"],
            ))

        logger.info(f"✅ [Custom Exercises] Found {len(exercises)} custom exercises for user {user_id}")
        if exercises:
            exercise_names = [ex.name for ex in exercises]
            logger.info(f"🏋️ [Custom Exercises] Exercise names: {exercise_names}")
        return exercises

    except Exception as e:
        logger.error(f"❌ [Custom Exercises] Error getting custom exercises for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/custom/{user_id}", response_model=CustomExerciseResponse)
async def create_custom_exercise(user_id: str, exercise: CustomExerciseCreate):
    """Create a new custom exercise for a user."""
    logger.info(f"🏋️ [Custom Exercises] POST request - Creating custom exercise for user: {user_id}")
    logger.info(f"🏋️ [Custom Exercises] Exercise details - name: {exercise.name}, muscle: {exercise.primary_muscle}, equipment: {exercise.equipment}")
    logger.info(f"🏋️ [Custom Exercises] Exercise params - sets: {exercise.default_sets}, reps: {exercise.default_reps}, compound: {exercise.is_compound}")

    try:
        db = get_supabase_db()

        # Generate a unique external_id for the custom exercise
        external_id = f"custom_{user_id[:8]}_{uuid.uuid4().hex[:8]}"
        logger.info(f"🏋️ [Custom Exercises] Generated external_id: {external_id}")

        # Map primary_muscle to body_part
        muscle_to_body_part = {
            "chest": "chest",
            "back": "back",
            "shoulders": "shoulders",
            "biceps": "upper arms",
            "triceps": "upper arms",
            "forearms": "lower arms",
            "abs": "waist",
            "core": "waist",
            "quadriceps": "upper legs",
            "quads": "upper legs",
            "hamstrings": "upper legs",
            "glutes": "upper legs",
            "calves": "lower legs",
            "legs": "upper legs",
            "full body": "full body",
        }
        body_part = muscle_to_body_part.get(
            exercise.primary_muscle.lower(), exercise.primary_muscle.lower()
        )
        logger.info(f"🏋️ [Custom Exercises] Mapped body_part: {body_part}")

        exercise_data = {
            "external_id": external_id,
            "name": exercise.name,
            "category": "strength",
            "subcategory": "compound" if exercise.is_compound else "isolation",
            "difficulty_level": 5,  # Default medium difficulty
            "primary_muscle": exercise.primary_muscle,
            "secondary_muscles": "[]",
            "equipment_required": f'["{exercise.equipment}"]' if exercise.equipment != "bodyweight" else "[]",
            "body_part": body_part,
            "equipment": exercise.equipment,
            "target": exercise.primary_muscle,
            "default_sets": exercise.default_sets,
            "default_reps": exercise.default_reps,
            "default_rest_seconds": 60,
            "calories_per_minute": 5.0,
            "instructions": exercise.instructions or f"Perform {exercise.name} with proper form.",
            "tips": "[]",
            "contraindicated_injuries": "[]",
            "is_compound": exercise.is_compound,
            "is_unilateral": False,
            "tags": '["custom"]',
            "is_custom": True,
            "created_by_user_id": user_id,
        }

        # Insert into exercises table
        logger.info(f"🏋️ [Custom Exercises] Inserting exercise into database...")
        result = db.client.table("exercises").insert(exercise_data).execute()

        if not result.data:
            logger.error(f"❌ [Custom Exercises] Database insert returned no data")
            raise HTTPException(status_code=500, detail="Failed to create exercise")

        created = result.data[0]
        logger.info(f"✅ [Custom Exercises] Created custom exercise '{exercise.name}' (ID: {created['id']}) for user {user_id}")

        return CustomExerciseResponse(
            id=created["id"],
            name=created["name"],
            primary_muscle=created["primary_muscle"],
            equipment=created["equipment"],
            instructions=created.get("instructions", ""),
            default_sets=created.get("default_sets", 3),
            default_reps=created.get("default_reps"),
            is_compound=created.get("is_compound", False),
            created_at=created["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [Custom Exercises] Error creating custom exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/custom/{user_id}/{exercise_id}")
async def delete_custom_exercise(user_id: str, exercise_id: str):
    """Delete a user's custom exercise."""
    logger.info(f"🏋️ [Custom Exercises] DELETE request - Deleting exercise {exercise_id} for user: {user_id}")

    try:
        db = get_supabase_db()

        # Verify the exercise exists and belongs to this user
        logger.info(f"🏋️ [Custom Exercises] Verifying exercise ownership...")
        result = db.client.table("exercises").select("*").eq(
            "id", exercise_id
        ).eq(
            "created_by_user_id", user_id
        ).eq(
            "is_custom", True
        ).execute()

        if not result.data:
            logger.warning(f"⚠️ [Custom Exercises] Exercise {exercise_id} not found or doesn't belong to user {user_id}")
            raise HTTPException(
                status_code=404,
                detail="Custom exercise not found or doesn't belong to this user"
            )

        exercise_name = result.data[0].get("name", "Unknown")
        logger.info(f"🏋️ [Custom Exercises] Found exercise: '{exercise_name}' - proceeding with deletion")

        # Delete the exercise
        db.client.table("exercises").delete().eq("id", exercise_id).execute()
        logger.info(f"✅ [Custom Exercises] Deleted custom exercise '{exercise_name}' (ID: {exercise_id}) for user {user_id}")

        return {"message": "Custom exercise deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [Custom Exercises] Error deleting custom exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))
