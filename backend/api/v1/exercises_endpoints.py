"""Secondary endpoints for exercises.  Sub-router included by main module.
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
from typing import List, Optional
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from services.user_context_service import UserContextService, EventType

from .exercises_models import (
    CustomExerciseCreate,
    CustomExerciseResponse,
    ComponentExercise,
    CompositeExerciseCreate,
    CompositeExerciseResponse,
    CustomExerciseFullResponse,
)

router = APIRouter()

@router.get("/custom/{user_id}", response_model=List[CustomExerciseResponse])
async def get_user_custom_exercises(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get all custom exercises created by a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        raise safe_internal_error(e, "exercises")


@router.post("/custom/{user_id}", response_model=CustomExerciseResponse)
async def create_custom_exercise(user_id: str, exercise: CustomExerciseCreate, current_user: dict = Depends(get_current_user)):
    """Create a new custom exercise for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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

        # Log to user context
        try:
            user_context_service = UserContextService()
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.CUSTOM_EXERCISE_CREATED,
                event_data={
                    "exercise_id": created["id"],
                    "exercise_name": exercise.name,
                    "primary_muscle": exercise.primary_muscle,
                    "equipment": exercise.equipment,
                    "is_compound": exercise.is_compound,
                },
            )
        except Exception as log_err:
            logger.warning(f"⚠️ [Custom Exercises] Failed to log user context: {log_err}")

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
        raise safe_internal_error(e, "exercises")


@router.delete("/custom/{user_id}/{exercise_id}")
async def delete_custom_exercise(user_id: str, exercise_id: str, current_user: dict = Depends(get_current_user)):
    """Delete a user's custom exercise."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        is_composite = result.data[0].get("is_composite", False)
        logger.info(f"🏋️ [Custom Exercises] Found exercise: '{exercise_name}' - proceeding with deletion")

        # Delete the exercise
        db.client.table("exercises").delete().eq("id", exercise_id).execute()
        logger.info(f"✅ [Custom Exercises] Deleted custom exercise '{exercise_name}' (ID: {exercise_id}) for user {user_id}")

        # Log to user context
        try:
            user_context_service = UserContextService()
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.CUSTOM_EXERCISE_DELETED,
                event_data={
                    "exercise_id": exercise_id,
                    "exercise_name": exercise_name,
                    "is_composite": is_composite,
                },
            )
        except Exception as log_err:
            logger.warning(f"⚠️ [Custom Exercises] Failed to log user context: {log_err}")

        return {"message": "Custom exercise deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [Custom Exercises] Error deleting custom exercise: {e}")
        raise safe_internal_error(e, "exercises")


# ============================================================================
# COMPOSITE/COMBO EXERCISE ENDPOINTS
# ============================================================================

class ComponentExercise(BaseModel):
    """Model for a component of a composite exercise."""
    name: str = Field(..., min_length=1, max_length=200)
    order: int = Field(default=1, ge=1, le=10)
    reps: Optional[int] = Field(default=None, ge=1, le=100)
    duration_seconds: Optional[int] = Field(default=None, ge=1, le=600)
    transition_note: Optional[str] = Field(default=None, max_length=200)


class CompositeExerciseCreate(BaseModel):
    """Model for creating a composite/combo exercise."""
    name: str = Field(..., min_length=1, max_length=200, description="e.g., 'Dumbbell Bench Press & Chest Fly'")
    primary_muscle: str = Field(..., max_length=100)
    secondary_muscles: List[str] = Field(default=[], description="Additional muscles targeted")
    equipment: str = Field(default="dumbbell", max_length=200)
    combo_type: str = Field(
        default="superset",
        description="Type of combination: superset, compound_set, giant_set, complex, hybrid"
    )
    component_exercises: List[ComponentExercise] = Field(
        ..., min_length=2, max_length=5,
        description="The exercises that make up this combo (2-5 exercises)"
    )
    instructions: Optional[str] = Field(default=None, max_length=5000)
    custom_notes: Optional[str] = Field(default=None, max_length=2000)
    default_sets: int = Field(default=3, ge=1, le=10)
    default_rest_seconds: int = Field(default=60, ge=0, le=300)
    tags: List[str] = Field(default=[])


class CompositeExerciseResponse(BaseModel):
    """Response model for composite exercises."""
    id: str
    name: str
    primary_muscle: str
    secondary_muscles: List[str]
    equipment: str
    combo_type: str
    component_exercises: List[dict]
    instructions: Optional[str]
    custom_notes: Optional[str]
    default_sets: int
    default_rest_seconds: int
    tags: List[str]
    is_composite: bool
    usage_count: int
    created_at: str


class CustomExerciseFullResponse(BaseModel):
    """Full response model for custom exercises including composite."""
    id: str
    name: str
    primary_muscle: str
    secondary_muscles: Optional[List[str]] = None
    equipment: str
    instructions: Optional[str]
    default_sets: int
    default_reps: Optional[int]
    default_rest_seconds: Optional[int]
    is_compound: bool
    is_composite: bool
    combo_type: Optional[str] = None
    component_exercises: Optional[List[dict]] = None
    custom_notes: Optional[str] = None
    tags: List[str]
    usage_count: int
    last_used: Optional[str] = None
    created_at: str


@router.get("/custom/{user_id}/all", response_model=List[CustomExerciseFullResponse])
async def get_all_user_exercises(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get all custom exercises for a user including composite exercises with usage stats."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"🏋️ [Custom Exercises] GET ALL - Fetching all custom exercises for user: {user_id}")
    try:
        db = get_supabase_db()

        # Query all custom exercises
        result = db.client.table("exercises").select("*").eq(
            "is_custom", True
        ).eq(
            "created_by_user_id", user_id
        ).order("created_at", desc=True).execute()

        # Get usage counts for all exercises
        usage_result = db.client.table("custom_exercise_usage").select(
            "exercise_id, id"
        ).eq("user_id", user_id).execute()

        # Build usage count map
        usage_counts = {}
        for usage in usage_result.data:
            ex_id = usage["exercise_id"]
            usage_counts[ex_id] = usage_counts.get(ex_id, 0) + 1

        # Get last used dates
        last_used_result = db.client.rpc(
            "get_custom_exercise_stats", {"p_user_id": user_id}
        ).execute()
        last_used_map = {
            row["exercise_id"]: row.get("last_used")
            for row in (last_used_result.data or [])
        }

        exercises = []
        for row in result.data:
            # Parse component_exercises if it's a string
            component_exercises = row.get("component_exercises", [])
            if isinstance(component_exercises, str):
                import json
                try:
                    component_exercises = json.loads(component_exercises)
                except Exception as e:
                    logger.debug(f"Failed to parse component_exercises JSON: {e}")
                    component_exercises = []

            # Parse secondary_muscles
            secondary_muscles = row.get("secondary_muscles", [])
            if isinstance(secondary_muscles, str):
                import json
                try:
                    secondary_muscles = json.loads(secondary_muscles)
                except Exception as e:
                    logger.debug(f"Failed to parse secondary_muscles JSON: {e}")
                    secondary_muscles = []

            # Parse tags
            tags = row.get("tags", [])
            if isinstance(tags, str):
                import json
                try:
                    tags = json.loads(tags)
                except Exception as e:
                    logger.debug(f"Failed to parse tags JSON: {e}")
                    tags = []

            exercises.append(CustomExerciseFullResponse(
                id=row["id"],
                name=row["name"],
                primary_muscle=row.get("primary_muscle", ""),
                secondary_muscles=secondary_muscles if isinstance(secondary_muscles, list) else [],
                equipment=row.get("equipment", "bodyweight"),
                instructions=row.get("instructions"),
                default_sets=row.get("default_sets", 3),
                default_reps=row.get("default_reps"),
                default_rest_seconds=row.get("default_rest_seconds"),
                is_compound=row.get("is_compound", False),
                is_composite=row.get("is_composite", False),
                combo_type=row.get("combo_type"),
                component_exercises=component_exercises if isinstance(component_exercises, list) else [],
                custom_notes=row.get("custom_notes"),
                tags=tags if isinstance(tags, list) else [],
                usage_count=usage_counts.get(row["id"], 0),
                last_used=last_used_map.get(row["id"]),
                created_at=row["created_at"],
            ))

        logger.info(f"✅ [Custom Exercises] Found {len(exercises)} custom exercises for user {user_id}")
        return exercises

    except Exception as e:
        logger.error(f"❌ [Custom Exercises] Error getting all custom exercises: {e}")
        raise safe_internal_error(e, "exercises")


@router.post("/custom/{user_id}/composite", response_model=CompositeExerciseResponse)
async def create_composite_exercise(user_id: str, exercise: CompositeExerciseCreate, current_user: dict = Depends(get_current_user)):
    """
    Create a new composite/combo exercise for a user.

    Composite exercises combine multiple movements into one, such as:
    - "Dumbbell Bench Press & Chest Fly" (superset)
    - "Squat to Press" (complex)
    - "Burpee with Push-up" (hybrid)
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"🏋️ [Composite Exercise] Creating '{exercise.name}' for user: {user_id}")
    logger.info(f"🏋️ [Composite Exercise] Components: {[c.name for c in exercise.component_exercises]}")

    try:
        db = get_supabase_db()
        import json

        # Validate combo_type
        valid_combo_types = ["superset", "compound_set", "giant_set", "complex", "hybrid"]
        if exercise.combo_type not in valid_combo_types:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid combo_type. Must be one of: {valid_combo_types}"
            )

        # Generate a unique external_id
        external_id = f"combo_{user_id[:8]}_{uuid.uuid4().hex[:8]}"

        # Build component exercises JSON
        component_exercises_json = [
            {
                "name": comp.name,
                "order": comp.order,
                "reps": comp.reps,
                "duration_seconds": comp.duration_seconds,
                "transition_note": comp.transition_note,
            }
            for comp in sorted(exercise.component_exercises, key=lambda x: x.order)
        ]

        # Map primary_muscle to body_part
        muscle_to_body_part = {
            "chest": "chest", "back": "back", "shoulders": "shoulders",
            "biceps": "upper arms", "triceps": "upper arms", "forearms": "lower arms",
            "abs": "waist", "core": "waist", "quadriceps": "upper legs",
            "quads": "upper legs", "hamstrings": "upper legs", "glutes": "upper legs",
            "calves": "lower legs", "legs": "upper legs", "full body": "full body",
        }
        body_part = muscle_to_body_part.get(
            exercise.primary_muscle.lower(), exercise.primary_muscle.lower()
        )

        # Auto-generate instructions if not provided
        if not exercise.instructions:
            component_names = [c.name for c in exercise.component_exercises]
            if exercise.combo_type == "superset":
                instructions = f"Perform {component_names[0]}, then immediately {component_names[1]}. Complete all sets before resting."
            elif exercise.combo_type == "complex":
                instructions = f"Keep hold of the weight throughout. Flow from {' to '.join(component_names)}."
            elif exercise.combo_type == "hybrid":
                instructions = f"Combine {' and '.join(component_names)} into a single fluid movement."
            else:
                instructions = f"Perform in sequence: {', '.join(component_names)}."
        else:
            instructions = exercise.instructions

        # Add custom and combo tags
        tags = list(set(exercise.tags + ["custom", "combo", exercise.combo_type]))

        exercise_data = {
            "external_id": external_id,
            "name": exercise.name,
            "category": "strength",
            "subcategory": exercise.combo_type,
            "difficulty_level": 6,  # Slightly higher difficulty for combos
            "primary_muscle": exercise.primary_muscle,
            "secondary_muscles": json.dumps(exercise.secondary_muscles),
            "equipment_required": json.dumps([exercise.equipment]) if exercise.equipment != "bodyweight" else "[]",
            "body_part": body_part,
            "equipment": exercise.equipment,
            "target": exercise.primary_muscle,
            "default_sets": exercise.default_sets,
            "default_rest_seconds": exercise.default_rest_seconds,
            "calories_per_minute": 7.0,  # Higher calorie burn for combos
            "instructions": instructions,
            "tips": "[]",
            "contraindicated_injuries": "[]",
            "is_compound": True,  # Combos are always compound
            "is_unilateral": False,
            "is_composite": True,
            "combo_type": exercise.combo_type,
            "component_exercises": json.dumps(component_exercises_json),
            "custom_notes": exercise.custom_notes,
            "tags": json.dumps(tags),
            "is_custom": True,
            "created_by_user_id": user_id,
        }

        result = db.client.table("exercises").insert(exercise_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create composite exercise")

        created = result.data[0]
        logger.info(f"✅ [Composite Exercise] Created '{exercise.name}' (ID: {created['id']})")

        # Log to user context
        try:
            user_context_service = UserContextService()
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.COMPOSITE_EXERCISE_CREATED,
                event_data={
                    "exercise_id": created["id"],
                    "exercise_name": exercise.name,
                    "is_composite": True,
                    "combo_type": exercise.combo_type,
                    "component_count": len(exercise.component_exercises),
                    "component_names": [c.name for c in exercise.component_exercises],
                }
            )
        except Exception as ctx_err:
            logger.warning(f"⚠️ Failed to log context: {ctx_err}")

        return CompositeExerciseResponse(
            id=created["id"],
            name=created["name"],
            primary_muscle=created["primary_muscle"],
            secondary_muscles=exercise.secondary_muscles,
            equipment=created["equipment"],
            combo_type=created["combo_type"],
            component_exercises=component_exercises_json,
            instructions=created.get("instructions"),
            custom_notes=created.get("custom_notes"),
            default_sets=created["default_sets"],
            default_rest_seconds=created.get("default_rest_seconds", 60),
            tags=tags,
            is_composite=True,
            usage_count=0,
            created_at=created["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [Composite Exercise] Error creating: {e}")
        raise safe_internal_error(e, "exercises")


@router.put("/custom/{user_id}/{exercise_id}", response_model=CustomExerciseFullResponse)
async def update_custom_exercise(user_id: str, exercise_id: str, updates: dict, current_user: dict = Depends(get_current_user)):
    """Update a custom exercise."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"🏋️ [Custom Exercises] UPDATE - Exercise {exercise_id} for user: {user_id}")

    try:
        db = get_supabase_db()
        import json

        # Verify ownership
        existing = db.client.table("exercises").select("*").eq(
            "id", exercise_id
        ).eq(
            "created_by_user_id", user_id
        ).eq(
            "is_custom", True
        ).execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Exercise not found or doesn't belong to this user")

        # Build update data (only allow certain fields to be updated)
        allowed_fields = [
            "name", "primary_muscle", "secondary_muscles", "equipment",
            "instructions", "default_sets", "default_reps", "default_rest_seconds",
            "combo_type", "component_exercises", "custom_notes", "tags"
        ]

        update_data = {}
        for field in allowed_fields:
            if field in updates:
                value = updates[field]
                # JSON-encode lists/dicts
                if field in ["secondary_muscles", "component_exercises", "tags"] and isinstance(value, (list, dict)):
                    value = json.dumps(value)
                update_data[field] = value

        if not update_data:
            raise HTTPException(status_code=400, detail="No valid fields to update")

        result = db.client.table("exercises").update(update_data).eq("id", exercise_id).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update exercise")

        row = result.data[0]

        # Parse JSON fields
        component_exercises = row.get("component_exercises", [])
        if isinstance(component_exercises, str):
            try:
                component_exercises = json.loads(component_exercises)
            except Exception as e:
                logger.debug(f"Failed to parse component_exercises JSON on update: {e}")
                component_exercises = []

        secondary_muscles = row.get("secondary_muscles", [])
        if isinstance(secondary_muscles, str):
            try:
                secondary_muscles = json.loads(secondary_muscles)
            except Exception as e:
                logger.debug(f"Failed to parse secondary_muscles JSON on update: {e}")
                secondary_muscles = []

        tags = row.get("tags", [])
        if isinstance(tags, str):
            try:
                tags = json.loads(tags)
            except Exception as e:
                logger.debug(f"Failed to parse tags JSON on update: {e}")
                tags = []

        logger.info(f"✅ [Custom Exercises] Updated exercise {exercise_id}")

        return CustomExerciseFullResponse(
            id=row["id"],
            name=row["name"],
            primary_muscle=row.get("primary_muscle", ""),
            secondary_muscles=secondary_muscles if isinstance(secondary_muscles, list) else [],
            equipment=row.get("equipment", "bodyweight"),
            instructions=row.get("instructions"),
            default_sets=row.get("default_sets", 3),
            default_reps=row.get("default_reps"),
            default_rest_seconds=row.get("default_rest_seconds"),
            is_compound=row.get("is_compound", False),
            is_composite=row.get("is_composite", False),
            combo_type=row.get("combo_type"),
            component_exercises=component_exercises if isinstance(component_exercises, list) else [],
            custom_notes=row.get("custom_notes"),
            tags=tags if isinstance(tags, list) else [],
            usage_count=0,
            last_used=None,
            created_at=row["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [Custom Exercises] Error updating: {e}")
        raise safe_internal_error(e, "exercises")


@router.post("/custom/{user_id}/{exercise_id}/log-usage")
async def log_custom_exercise_usage(
    user_id: str,
    exercise_id: str,
    workout_id: Optional[str] = None,
    rating: Optional[int] = None,
    notes: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """Log usage of a custom exercise (called when user completes it in a workout)."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"🏋️ [Custom Exercises] Logging usage of {exercise_id} for user: {user_id}")

    try:
        db = get_supabase_db()

        # Verify the exercise exists and belongs to this user
        existing = db.client.table("exercises").select("name").eq(
            "id", exercise_id
        ).eq(
            "created_by_user_id", user_id
        ).eq(
            "is_custom", True
        ).execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Custom exercise not found")

        exercise_name = existing.data[0]['name']

        usage_data = {
            "user_id": user_id,
            "exercise_id": exercise_id,
            "workout_id": workout_id,
            "rating": rating if rating and 1 <= rating <= 5 else None,
            "performance_notes": notes,
        }

        db.client.table("custom_exercise_usage").insert(usage_data).execute()

        logger.info(f"✅ [Custom Exercises] Logged usage of '{exercise_name}'")

        # Log to user context for analytics
        try:
            user_context_service = UserContextService()
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.CUSTOM_EXERCISE_USED,
                event_data={
                    "exercise_id": exercise_id,
                    "exercise_name": exercise_name,
                    "workout_id": workout_id,
                    "rating": rating,
                }
            )
        except Exception as ctx_err:
            logger.warning(f"⚠️ Failed to log context: {ctx_err}")

        return {"success": True, "message": "Usage logged successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [Custom Exercises] Error logging usage: {e}")
        raise safe_internal_error(e, "exercises")


@router.get("/custom/{user_id}/stats")
async def get_custom_exercise_stats(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get statistics for user's custom exercises."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"🏋️ [Custom Exercises] Getting stats for user: {user_id}")

    try:
        db = get_supabase_db()

        # Get basic counts
        exercises_result = db.client.table("exercises").select(
            "id, is_composite"
        ).eq("created_by_user_id", user_id).eq("is_custom", True).execute()

        total_exercises = len(exercises_result.data)
        composite_count = sum(1 for e in exercises_result.data if e.get("is_composite"))
        simple_count = total_exercises - composite_count

        # Get usage stats
        stats_result = db.client.rpc(
            "get_custom_exercise_stats", {"p_user_id": user_id}
        ).execute()

        most_used = []
        total_uses = 0
        for row in (stats_result.data or [])[:5]:
            most_used.append({
                "exercise_id": row["exercise_id"],
                "name": row["exercise_name"],
                "usage_count": row["usage_count"],
                "avg_rating": float(row["avg_rating"]) if row.get("avg_rating") else None,
            })
            total_uses += row["usage_count"] or 0

        return {
            "total_custom_exercises": total_exercises,
            "simple_exercises": simple_count,
            "composite_exercises": composite_count,
            "total_uses": total_uses,
            "most_used": most_used,
        }

    except Exception as e:
        logger.error(f"❌ [Custom Exercises] Error getting stats: {e}")
        raise safe_internal_error(e, "exercises")


@router.get("/library/search")
async def search_exercise_library(
    query: str = Query(..., min_length=2, max_length=100),
    limit: int = Query(default=20, ge=1, le=50),
    current_user: dict = Depends(get_current_user),
):
    """
    Search the exercise library for exercises to use as combo components.

    This is useful when building a composite exercise and need to find
    existing exercises to combine.
    """
    logger.info(f"🔍 [Exercise Library] Searching for: '{query}'")

    try:
        db = get_supabase_db()

        # Search in exercise_library by name
        result = db.client.table("exercise_library").select(
            "id, exercise_name, body_part, equipment, target_muscle"
        ).ilike(
            "exercise_name", f"%{query}%"
        ).limit(limit).execute()

        exercises = [
            {
                "id": row["id"],
                "name": row["exercise_name"],
                "body_part": row.get("body_part"),
                "equipment": row.get("equipment"),
                "target_muscle": row.get("target_muscle"),
            }
            for row in result.data
        ]

        logger.info(f"✅ [Exercise Library] Found {len(exercises)} exercises matching '{query}'")
        return {"results": exercises, "count": len(exercises)}

    except Exception as e:
        logger.error(f"❌ [Exercise Library] Search error: {e}")
        raise safe_internal_error(e, "exercises")
