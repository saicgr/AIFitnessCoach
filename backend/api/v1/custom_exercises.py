"""
Custom Exercises API - User-defined exercises for equipment not in the library.

This module allows users to:
1. Create custom exercises for any equipment
2. Upload images/videos for custom exercises
3. Mark exercises as suitable for warmup/stretch/cooldown
4. Share exercises publicly with other users
5. Search both library and custom exercises
"""
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from pydantic import BaseModel, Field, model_validator
from typing import List, Optional, Dict, Any
from datetime import datetime
import base64
import json
import logging
import uuid

from google.genai import types

from core.auth import get_current_user
from core.config import get_settings
from core.exceptions import safe_internal_error
from services.gemini.constants import gemini_generate_with_retry
from services.custom_exercise_media_service import get_custom_exercise_media_service
from services.ai_exercise_extractor import get_ai_exercise_extractor
from services.exercise_rag.service import get_exercise_rag_service
from services.media_job_service import get_media_job_service
from services.media_job_runner import run_media_job
import asyncio

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/custom-exercises", tags=["Custom Exercises"])


# =============================================================================
# Request/Response Models
# =============================================================================

class CustomExerciseCreate(BaseModel):
    """Request to create a custom exercise."""
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=1000)
    instructions: Optional[str] = Field(default=None, max_length=2000)

    # Classification
    body_part: Optional[str] = None  # 'chest', 'back', 'legs', 'cardio', etc.
    target_muscles: Optional[List[str]] = None  # ['quadriceps', 'glutes']
    secondary_muscles: Optional[List[str]] = None
    equipment: str = Field(..., min_length=1, max_length=100)
    exercise_type: str = Field(default="strength")  # 'strength', 'cardio', 'warmup', 'stretch'
    movement_type: str = Field(default="dynamic")  # 'static', 'dynamic', 'isometric'
    difficulty_level: str = Field(default="intermediate")  # 'beginner', 'intermediate', 'advanced'

    # Defaults
    default_sets: Optional[int] = Field(default=3, ge=1, le=10)
    default_reps: Optional[int] = Field(default=None, ge=1, le=100)  # NULL for time-based
    default_duration_seconds: Optional[int] = Field(default=None, ge=1, le=3600)  # NULL for rep-based
    default_rest_seconds: Optional[int] = Field(default=60, ge=0, le=600)

    # Categorization
    is_warmup_suitable: bool = False
    is_stretch_suitable: bool = False
    is_cooldown_suitable: bool = False

    # Visibility
    is_public: bool = False


class CustomExerciseUpdate(BaseModel):
    """Request to update a custom exercise."""
    name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    description: Optional[str] = None
    instructions: Optional[str] = None
    body_part: Optional[str] = None
    target_muscles: Optional[List[str]] = None
    secondary_muscles: Optional[List[str]] = None
    equipment: Optional[str] = None
    exercise_type: Optional[str] = None
    movement_type: Optional[str] = None
    difficulty_level: Optional[str] = None
    default_sets: Optional[int] = None
    default_reps: Optional[int] = None
    default_duration_seconds: Optional[int] = None
    default_rest_seconds: Optional[int] = None
    is_warmup_suitable: Optional[bool] = None
    is_stretch_suitable: Optional[bool] = None
    is_cooldown_suitable: Optional[bool] = None
    is_public: Optional[bool] = None
    image_url: Optional[str] = None
    video_url: Optional[str] = None
    thumbnail_url: Optional[str] = None


class CustomExerciseResponse(BaseModel):
    """Response for a custom exercise."""
    id: str
    user_id: str
    name: str
    description: Optional[str] = None
    instructions: Optional[str] = None
    body_part: Optional[str] = None
    target_muscles: Optional[List[str]] = None
    secondary_muscles: Optional[List[str]] = None
    equipment: str
    exercise_type: str
    movement_type: str
    difficulty_level: str
    default_sets: Optional[int] = None
    default_reps: Optional[int] = None
    default_duration_seconds: Optional[int] = None
    default_rest_seconds: Optional[int] = None
    image_url: Optional[str] = None
    video_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    is_warmup_suitable: bool = False
    is_stretch_suitable: bool = False
    is_cooldown_suitable: bool = False
    is_public: bool = False
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ExerciseSearchResult(BaseModel):
    """Combined search result from library and custom exercises."""
    id: str
    name: str
    body_part: Optional[str] = None
    target_muscle: Optional[str] = None
    equipment: Optional[str] = None
    difficulty_level: Optional[str] = None
    image_url: Optional[str] = None
    is_custom: bool = False
    owner_user_id: Optional[str] = None


class AnalyzePhotoRequest(BaseModel):
    """Request to analyze an exercise/equipment photo with Gemini Vision."""
    image_base64: str = Field(..., description="Base64 encoded image data (without data:image prefix)")


class AnalyzePhotoResponse(BaseModel):
    """Response from Gemini Vision exercise photo analysis."""
    name: str = Field(..., description="Name of the exercise or equipment")
    primary_muscle: str = Field(..., description="Primary muscle group targeted")
    equipment: str = Field(..., description="Equipment type used")
    is_compound: bool = Field(..., description="Whether the exercise is a compound movement")
    instructions: str = Field(..., description="Step-by-step instructions for the exercise")
    secondary_muscles: List[str] = Field(default_factory=list, description="Secondary muscle groups involved")


class ImportExerciseRequest(BaseModel):
    """
    Request body for POST /custom-exercises/{user_id}/import.

    Exactly one `source` must be supplied, with the appropriate payload key:
      - source='photo' → s3_key required
      - source='video' → s3_key required (processed async — returns job_id)
      - source='text'  → raw_text required
    """
    source: str = Field(..., description="'photo' | 'video' | 'text'")
    s3_key: Optional[str] = Field(default=None, description="S3 key for photo/video")
    raw_text: Optional[str] = Field(default=None, description="Description for text source")
    user_hint: Optional[str] = Field(default=None, description="Optional name hint for disambiguation")

    @model_validator(mode="after")
    def _check_source_payload(self) -> "ImportExerciseRequest":
        s = (self.source or "").lower().strip()
        if s not in ("photo", "video", "text"):
            raise ValueError("source must be one of: photo, video, text")
        self.source = s
        if s in ("photo", "video") and not self.s3_key:
            raise ValueError(f"s3_key is required when source='{s}'")
        if s == "text" and not (self.raw_text and self.raw_text.strip()):
            raise ValueError("raw_text is required when source='text'")
        return self


class ImportExerciseResponse(BaseModel):
    """Response from POST /custom-exercises/{user_id}/import."""
    exercise: Optional[CustomExerciseResponse] = None
    rag_indexed: bool = False
    job_id: Optional[str] = None
    status: Optional[str] = None
    duplicate: bool = False


class PresignedUploadResponse(BaseModel):
    """Response with presigned URL for direct S3 upload."""
    upload_url: str
    s3_key: str
    expires_in: int = 300


class MediaUploadResponse(BaseModel):
    """Response after successful media upload."""
    s3_key: str
    public_url: Optional[str] = None
    message: str


# =============================================================================
# API Endpoints
# =============================================================================

@router.get("/{user_id}", response_model=List[CustomExerciseResponse])
async def get_user_custom_exercises(
    user_id: str,
    equipment: Optional[str] = Query(default=None, description="Filter by equipment"),
    exercise_type: Optional[str] = Query(default=None, description="Filter by type"),
    include_public: bool = Query(default=False, description="Include public exercises from others"),
    current_user: dict = Depends(get_current_user),
):
    """Get all custom exercises for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        query = db.client.table("custom_exercises").select("*")

        if include_public:
            # User's exercises OR public exercises
            query = query.or_(f"user_id.eq.{user_id},is_public.eq.true")
        else:
            # Only user's exercises
            query = query.eq("user_id", user_id)

        if equipment:
            query = query.eq("equipment", equipment)

        if exercise_type:
            query = query.eq("exercise_type", exercise_type)

        result = query.order("created_at", desc=True).execute()

        return [CustomExerciseResponse(**ex) for ex in result.data] if result.data else []

    except Exception as e:
        logger.error(f"❌ Failed to get custom exercises for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.get("/{user_id}/{exercise_id}", response_model=CustomExerciseResponse)
async def get_custom_exercise(user_id: str, exercise_id: str, current_user: dict = Depends(get_current_user)):
    """Get a specific custom exercise."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        result = db.client.table("custom_exercises").select("*").eq(
            "id", exercise_id
        ).limit(1).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        exercise = result.data[0]

        # Check access: user owns it OR it's public
        if exercise["user_id"] != user_id and not exercise.get("is_public"):
            raise HTTPException(status_code=403, detail="Access denied")

        return CustomExerciseResponse(**exercise)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to get custom exercise {exercise_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.post("/{user_id}", response_model=CustomExerciseResponse)
async def create_custom_exercise(user_id: str, request: CustomExerciseCreate, current_user: dict = Depends(get_current_user)):
    """Create a new custom exercise."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Build insert data
        insert_data = {
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "instructions": request.instructions,
            "body_part": request.body_part,
            "target_muscles": request.target_muscles,
            "secondary_muscles": request.secondary_muscles,
            "equipment": request.equipment,
            "exercise_type": request.exercise_type,
            "movement_type": request.movement_type,
            "difficulty_level": request.difficulty_level,
            "default_sets": request.default_sets,
            "default_reps": request.default_reps,
            "default_duration_seconds": request.default_duration_seconds,
            "default_rest_seconds": request.default_rest_seconds,
            "is_warmup_suitable": request.is_warmup_suitable,
            "is_stretch_suitable": request.is_stretch_suitable,
            "is_cooldown_suitable": request.is_cooldown_suitable,
            "is_public": request.is_public,
        }

        result = db.client.table("custom_exercises").insert(insert_data).execute()

        if result.data:
            row = result.data[0]
            logger.info(f"🏋️ Created custom exercise '{request.name}' for user {user_id}")
            # Best-effort RAG indexing — non-fatal on failure.
            try:
                rag_service = get_exercise_rag_service()
                indexed = await rag_service.index_custom_exercise(row)
                if indexed:
                    logger.info(f"✅ RAG indexed custom exercise {row.get('id')}")
                else:
                    logger.warning(f"⚠️ RAG indexing returned False for custom exercise {row.get('id')}")
            except Exception as rag_err:
                logger.warning(
                    f"⚠️ RAG indexing failed (non-fatal) for custom exercise {row.get('id')}: {rag_err}",
                    exc_info=True,
                )
            return CustomExerciseResponse(**row)
        else:
            raise safe_internal_error(ValueError("Failed to create exercise"), "custom_exercises")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to create custom exercise: {e}", exc_info=True)
        # Check for unique constraint violation
        if "duplicate key" in str(e).lower() or "unique" in str(e).lower():
            raise HTTPException(status_code=400, detail="Exercise with this name already exists")
        raise safe_internal_error(e, "custom_exercises")


@router.put("/{user_id}/{exercise_id}", response_model=CustomExerciseResponse)
async def update_custom_exercise(user_id: str, exercise_id: str, request: CustomExerciseUpdate, current_user: dict = Depends(get_current_user)):
    """Update a custom exercise."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Check ownership
        check = db.client.table("custom_exercises").select("user_id").eq(
            "id", exercise_id
        ).limit(1).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Build update data (only non-None values)
        update_data = {}
        for field, value in request.model_dump().items():
            if value is not None:
                update_data[field] = value

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = db.client.table("custom_exercises").update(update_data).eq(
            "id", exercise_id
        ).execute()

        if result.data:
            row = result.data[0]
            logger.info(f"🏋️ Updated custom exercise {exercise_id}")
            # Best-effort RAG re-index (non-fatal).
            try:
                rag_service = get_exercise_rag_service()
                await rag_service.update_custom_exercise_index(row)
            except Exception as rag_err:
                logger.warning(
                    f"⚠️ RAG re-index failed (non-fatal) for custom exercise {exercise_id}: {rag_err}",
                    exc_info=True,
                )
            return CustomExerciseResponse(**row)
        else:
            raise safe_internal_error(ValueError("Failed to update exercise"), "custom_exercises")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to update custom exercise {exercise_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.delete("/{user_id}/{exercise_id}")
async def delete_custom_exercise(user_id: str, exercise_id: str, current_user: dict = Depends(get_current_user)):
    """Delete a custom exercise and its associated media."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Check ownership
        check = db.client.table("custom_exercises").select("user_id, name").eq(
            "id", exercise_id
        ).limit(1).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        exercise_name = check.data[0]["name"]

        # Remove from ChromaDB custom collection first (non-fatal).
        try:
            rag_service = get_exercise_rag_service()
            await rag_service.delete_custom_exercise_index(exercise_id)
        except Exception as rag_err:
            logger.warning(
                f"⚠️ RAG delete failed (non-fatal) for custom exercise {exercise_id}: {rag_err}",
                exc_info=True,
            )

        # Delete media from S3
        media_service = get_custom_exercise_media_service()
        await media_service.delete_media(user_id, exercise_id)

        # Delete from database
        db.client.table("custom_exercises").delete().eq("id", exercise_id).execute()

        logger.info(f"🏋️ Deleted custom exercise '{exercise_name}' for user {user_id}")
        return {"message": f"Deleted exercise: {exercise_name}"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to delete custom exercise {exercise_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.get("/{user_id}/search/combined", response_model=List[ExerciseSearchResult])
async def search_combined_exercises(
    user_id: str,
    query: str = Query(..., min_length=1, description="Search query"),
    equipment: Optional[str] = Query(default=None, description="Filter by equipment"),
    limit: int = Query(default=20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """Search both exercise library and custom exercises."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        results = []
        query_lower = query.lower()

        # Search exercise library
        lib_query = db.client.table("exercise_library_cleaned").select(
            "id, name, body_part, target_muscle, equipment, difficulty_level, gif_url"
        ).ilike("name", f"%{query}%").limit(limit)

        if equipment:
            lib_query = lib_query.eq("equipment", equipment)

        lib_result = lib_query.execute()

        for ex in lib_result.data or []:
            results.append(ExerciseSearchResult(
                id=str(ex["id"]),
                name=ex["name"],
                body_part=ex.get("body_part"),
                target_muscle=ex.get("target_muscle"),
                equipment=ex.get("equipment"),
                difficulty_level=ex.get("difficulty_level"),
                image_url=ex.get("gif_url"),
                is_custom=False,
            ))

        # Search custom exercises (user's + public)
        custom_query = db.client.table("custom_exercises").select(
            "id, name, body_part, target_muscles, equipment, difficulty_level, image_url, user_id"
        ).or_(f"user_id.eq.{user_id},is_public.eq.true").ilike("name", f"%{query}%").limit(limit)

        if equipment:
            custom_query = custom_query.eq("equipment", equipment)

        custom_result = custom_query.execute()

        for ex in custom_result.data or []:
            results.append(ExerciseSearchResult(
                id=str(ex["id"]),
                name=ex["name"],
                body_part=ex.get("body_part"),
                target_muscle=ex["target_muscles"][0] if ex.get("target_muscles") else None,
                equipment=ex.get("equipment"),
                difficulty_level=ex.get("difficulty_level"),
                image_url=ex.get("image_url"),
                is_custom=True,
                owner_user_id=ex.get("user_id"),
            ))

        # Sort by relevance (exact match first, then contains)
        results.sort(key=lambda x: (
            0 if x.name.lower() == query_lower else
            1 if x.name.lower().startswith(query_lower) else
            2
        ))

        return results[:limit]

    except Exception as e:
        logger.error(f"❌ Failed to search exercises: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.get("/equipment/list")
async def list_equipment_with_exercises(current_user: dict = Depends(get_current_user)):
    """List all equipment types that have exercises (library or custom)."""
    db = get_supabase_db()

    try:
        # Get equipment from library
        lib_result = db.client.table("exercise_library").select("equipment").execute()
        lib_equipment = set(ex["equipment"] for ex in lib_result.data if ex.get("equipment"))

        # Get equipment from custom exercises (public only)
        custom_result = db.client.table("custom_exercises").select("equipment").eq(
            "is_public", True
        ).execute()
        custom_equipment = set(ex["equipment"] for ex in custom_result.data if ex.get("equipment"))

        # Combine and sort
        all_equipment = sorted(lib_equipment | custom_equipment)

        return {
            "equipment": all_equipment,
            "count": len(all_equipment)
        }

    except Exception as e:
        logger.error(f"❌ Failed to list equipment: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


# =============================================================================
# Photo Analysis Endpoint (Gemini Vision)
# =============================================================================

VALID_MUSCLE_GROUPS = [
    "chest", "back", "shoulders", "biceps", "triceps", "forearms",
    "abs", "core", "quadriceps", "hamstrings", "glutes", "calves", "full body",
]

VALID_EQUIPMENT = [
    "bodyweight", "dumbbell", "barbell", "kettlebell", "cable",
    "machine", "resistance band", "medicine ball", "slam ball", "other",
]


@router.post("/{user_id}/analyze-photo", response_model=AnalyzePhotoResponse)
async def analyze_exercise_photo(
    user_id: str,
    request: AnalyzePhotoRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Analyze a photo of an exercise or gym equipment using Gemini Vision.

    Returns structured exercise details including name, target muscles,
    equipment type, whether it's compound, and instructions.

    NOTE: This endpoint is preserved for backward compat. Internally it now
    delegates to `AiExerciseExtractor.extract_from_photo()` and projects the
    result down to the narrower legacy `AnalyzePhotoResponse` shape.
    New clients should call `POST /{user_id}/import` instead.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    try:
        logger.info(f"🤖 Analyzing exercise photo for user {user_id} (legacy analyze-photo)")

        try:
            image_bytes = base64.b64decode(request.image_base64)
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid base64 image data")

        extractor = get_ai_exercise_extractor()
        payload = await extractor.extract_from_photo(
            image_bytes=image_bytes,
            mime_type="image/jpeg",
            user_hint=None,
        )

        # Project payload down to the legacy response model.
        target_muscles = payload.get("target_muscles") or []
        primary = target_muscles[0] if target_muscles else "full body"
        if primary not in VALID_MUSCLE_GROUPS:
            primary = "full body"

        equipment = payload.get("equipment") or "other"
        if equipment not in VALID_EQUIPMENT:
            equipment = "other"

        secondary = [
            m for m in (payload.get("secondary_muscles") or [])
            if isinstance(m, str) and m in VALID_MUSCLE_GROUPS
        ]

        # Compound heuristic: more than one target or secondary muscle.
        is_compound = (len(target_muscles) + len(secondary)) > 1

        instructions_field = payload.get("instructions") or "No instructions available."

        analysis = AnalyzePhotoResponse(
            name=payload.get("name") or "Unknown Exercise",
            primary_muscle=primary,
            equipment=equipment,
            is_compound=is_compound,
            instructions=instructions_field,
            secondary_muscles=secondary,
        )

        logger.info(
            f"✅ Exercise photo analyzed: '{analysis.name}' "
            f"(primary: {analysis.primary_muscle}, equipment: {analysis.equipment})"
        )
        return analysis

    except HTTPException:
        raise
    except ValueError as ve:
        # AI returned unparseable response etc.
        raise HTTPException(status_code=502, detail=str(ve))
    except Exception as e:
        logger.error(f"❌ Failed to analyze exercise photo: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


# =============================================================================
# Unified Import Endpoint
# =============================================================================

async def _save_imported_exercise(
    db,
    user_id: str,
    payload: Dict[str, Any],
) -> tuple[Dict[str, Any], bool, bool]:
    """
    Persist an AI-extracted exercise payload.

    Handles duplicate detection by `(user_id, name)`:
      - if a row with the same (user_id, name) already exists → return it with duplicate=True
      - else insert, then best-effort RAG-index.

    Returns: (row, rag_indexed, duplicate)
    """
    name = (payload.get("name") or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Extracted exercise has no name")

    # Duplicate detection — case-insensitive compare.
    try:
        existing = (
            db.client.table("custom_exercises")
            .select("*")
            .eq("user_id", user_id)
            .ilike("name", name)
            .limit(1)
            .execute()
        )
    except Exception as e:
        logger.warning(f"⚠️ Duplicate-check query failed (continuing with insert): {e}", exc_info=True)
        existing = None

    if existing and existing.data:
        row = existing.data[0]
        logger.info(f"🏋️ Duplicate import detected for '{name}' — returning existing row {row.get('id')}")
        return row, False, True

    # Strip non-column keys before insert (e.g. keyframe_confidences from video merge).
    allowed_keys = set(CustomExerciseCreate.model_fields.keys())
    insert_data = {k: v for k, v in payload.items() if k in allowed_keys}
    insert_data["user_id"] = user_id
    # is_public default to False unless explicitly provided.
    insert_data.setdefault("is_public", False)

    result = db.client.table("custom_exercises").insert(insert_data).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to persist imported exercise")

    row = result.data[0]
    logger.info(f"🏋️ Imported custom exercise '{name}' for user {user_id} (id={row.get('id')})")

    # Best-effort RAG indexing.
    rag_indexed = False
    try:
        rag_service = get_exercise_rag_service()
        rag_indexed = await rag_service.index_custom_exercise(row)
    except Exception as rag_err:
        logger.warning(
            f"⚠️ RAG indexing failed (non-fatal) for imported exercise {row.get('id')}: {rag_err}",
            exc_info=True,
        )

    return row, rag_indexed, False


@router.post("/{user_id}/import", response_model=ImportExerciseResponse, status_code=200)
async def import_custom_exercise(
    user_id: str,
    request: ImportExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Import a custom exercise from a photo, short video, or text description.

    Photo / text paths run synchronously and return the persisted exercise +
    RAG-indexed flag. Video path enqueues a `custom_exercise_import` media job
    and returns `{job_id, status: 'pending'}`; poll `GET /api/v1/media-jobs/{job_id}`.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    source = request.source
    db = get_supabase_db()

    try:
        if source == "photo":
            extractor = get_ai_exercise_extractor()
            payload = await extractor.extract_from_photo(
                s3_key=request.s3_key,
                user_hint=request.user_hint,
            )
            row, rag_indexed, duplicate = await _save_imported_exercise(db, user_id, payload)
            return ImportExerciseResponse(
                exercise=CustomExerciseResponse(**row),
                rag_indexed=rag_indexed,
                job_id=None,
                status="completed",
                duplicate=duplicate,
            )

        elif source == "text":
            extractor = get_ai_exercise_extractor()
            payload = await extractor.extract_from_text(
                raw_text=request.raw_text or "",
                user_hint=request.user_hint,
            )
            row, rag_indexed, duplicate = await _save_imported_exercise(db, user_id, payload)
            return ImportExerciseResponse(
                exercise=CustomExerciseResponse(**row),
                rag_indexed=rag_indexed,
                job_id=None,
                status="completed",
                duplicate=duplicate,
            )

        elif source == "video":
            # Enqueue async job. Actual extraction + persist happens in runner.
            media_job_service = get_media_job_service()
            job_id = media_job_service.create_job(
                user_id=user_id,
                job_type="custom_exercise_import",
                s3_keys=[request.s3_key or ""],
                mime_types=["video/mp4"],
                media_types=["video"],
                params={
                    "user_id": user_id,
                    "user_hint": request.user_hint,
                    "source": "video",
                },
            )
            asyncio.create_task(run_media_job(job_id))
            logger.info(f"🎬 Enqueued custom_exercise_import job {job_id} for user {user_id}")
            return ImportExerciseResponse(
                exercise=None,
                rag_indexed=False,
                job_id=job_id,
                status="pending",
                duplicate=False,
            )

        else:
            raise HTTPException(status_code=400, detail=f"Unknown source: {source}")

    except HTTPException:
        raise
    except ValueError as ve:
        logger.warning(f"⚠️ Import validation failure: {ve}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"❌ Failed to import custom exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


# =============================================================================
# Media Upload Endpoints (S3)
# =============================================================================

@router.post("/{user_id}/{exercise_id}/upload/presigned")
async def get_presigned_upload_url(
    user_id: str,
    exercise_id: str,
    media_type: str = Query(..., description="'image' or 'video'"),
    content_type: str = Query(..., description="MIME type (e.g., 'image/jpeg', 'video/mp4')"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get a presigned URL for direct client upload to S3.

    This allows the Flutter app to upload directly to S3 without going through the backend.
    After upload, call the update endpoint to save the S3 key.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Verify ownership
        check = db.client.table("custom_exercises").select("user_id").eq(
            "id", exercise_id
        ).limit(1).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Generate presigned URL
        media_service = get_custom_exercise_media_service()
        upload_url, s3_key, error = media_service.generate_presigned_upload_url(
            user_id=user_id,
            exercise_id=exercise_id,
            media_type=media_type,
            content_type=content_type,
        )

        if error:
            raise HTTPException(status_code=400, detail=error)

        return PresignedUploadResponse(
            upload_url=upload_url,
            s3_key=s3_key,
            expires_in=300
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to generate presigned URL: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.post("/{user_id}/{exercise_id}/upload/image", response_model=MediaUploadResponse)
async def upload_exercise_image(
    user_id: str,
    exercise_id: str,
    file: UploadFile = File(..., description="Image file (JPEG, PNG, GIF, WebP)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Upload an image for a custom exercise via the backend.

    For large files or better performance, use the presigned URL endpoint instead.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Verify ownership
        check = db.client.table("custom_exercises").select("user_id").eq(
            "id", exercise_id
        ).limit(1).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Read file content
        content = await file.read()
        content_type = file.content_type or "image/jpeg"

        # Upload to S3
        media_service = get_custom_exercise_media_service()
        s3_key, error = await media_service.upload_image(
            user_id=user_id,
            exercise_id=exercise_id,
            image_bytes=content,
            content_type=content_type,
        )

        if error:
            raise HTTPException(status_code=400, detail=error)

        # Update exercise with public image URL (not raw s3_key — clients render this directly)
        public_url = media_service.get_public_url(s3_key)
        db.client.table("custom_exercises").update({
            "image_url": public_url
        }).eq("id", exercise_id).execute()

        logger.info(f"✅ Uploaded image for exercise {exercise_id}")

        return MediaUploadResponse(
            s3_key=s3_key,
            public_url=public_url,
            message="Image uploaded successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to upload image: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.post("/{user_id}/{exercise_id}/upload/video", response_model=MediaUploadResponse)
async def upload_exercise_video(
    user_id: str,
    exercise_id: str,
    file: UploadFile = File(..., description="Video file (MP4, MOV, WebM)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Upload a video for a custom exercise via the backend.

    Note: For videos >10MB, use the presigned URL endpoint instead.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Verify ownership
        check = db.client.table("custom_exercises").select("user_id").eq(
            "id", exercise_id
        ).limit(1).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Read file content
        content = await file.read()
        content_type = file.content_type or "video/mp4"

        # Upload to S3
        media_service = get_custom_exercise_media_service()
        s3_key, error = await media_service.upload_video(
            user_id=user_id,
            exercise_id=exercise_id,
            video_bytes=content,
            content_type=content_type,
        )

        if error:
            raise HTTPException(status_code=400, detail=error)

        # Update exercise with video URL
        public_url = media_service.get_public_url(s3_key)
        db.client.table("custom_exercises").update({
            "video_url": s3_key
        }).eq("id", exercise_id).execute()

        logger.info(f"✅ Uploaded video for exercise {exercise_id}")

        return MediaUploadResponse(
            s3_key=s3_key,
            public_url=public_url,
            message="Video uploaded successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to upload video: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.delete("/{user_id}/{exercise_id}/media")
async def delete_exercise_media(user_id: str, exercise_id: str, current_user: dict = Depends(get_current_user)):
    """Delete all media (image, video, thumbnail) for a custom exercise."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Verify ownership
        check = db.client.table("custom_exercises").select("user_id").eq(
            "id", exercise_id
        ).limit(1).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Delete from S3
        media_service = get_custom_exercise_media_service()
        await media_service.delete_media(user_id, exercise_id)

        # Clear URLs in database
        db.client.table("custom_exercises").update({
            "image_url": None,
            "video_url": None,
            "thumbnail_url": None,
        }).eq("id", exercise_id).execute()

        logger.info(f"✅ Deleted media for exercise {exercise_id}")

        return {"message": "Media deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to delete media: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")


@router.post("/{user_id}/{exercise_id}/confirm-upload")
async def confirm_presigned_upload(
    user_id: str,
    exercise_id: str,
    s3_key: str = Query(..., description="S3 key from presigned upload"),
    media_type: str = Query(..., description="'image' or 'video'"),
    current_user: dict = Depends(get_current_user),
):
    """
    Confirm a presigned upload was successful and update the exercise record.

    Call this after uploading via presigned URL to save the S3 key to the database.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Verify ownership
        check = db.client.table("custom_exercises").select("user_id").eq(
            "id", exercise_id
        ).limit(1).execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Verify the S3 key belongs to this exercise
        expected_prefix = f"custom-exercises/{user_id}/{exercise_id}/"
        if not s3_key.startswith(expected_prefix):
            raise HTTPException(status_code=400, detail="Invalid S3 key for this exercise")

        # Compute public URL and store that (not raw s3_key) so clients can render directly
        media_service = get_custom_exercise_media_service()
        public_url = media_service.get_public_url(s3_key)
        update_field = "image_url" if media_type == "image" else "video_url"
        db.client.table("custom_exercises").update({
            update_field: public_url
        }).eq("id", exercise_id).execute()

        logger.info(f"✅ Confirmed {media_type} upload for exercise {exercise_id}")

        return {
            "message": f"{media_type.capitalize()} upload confirmed",
            "s3_key": s3_key,
            "public_url": public_url,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to confirm upload: {e}", exc_info=True)
        raise safe_internal_error(e, "custom_exercises")
