"""
Custom Exercises API - User-defined exercises for equipment not in the library.

This module allows users to:
1. Create custom exercises for any equipment
2. Upload images/videos for custom exercises
3. Mark exercises as suitable for warmup/stretch/cooldown
4. Share exercises publicly with other users
5. Search both library and custom exercises
"""
from fastapi import APIRouter, HTTPException, Query, UploadFile, File
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
import logging
import uuid

from core.supabase_db import get_supabase_db
from services.custom_exercise_media_service import get_custom_exercise_media_service

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
):
    """Get all custom exercises for a user."""
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
        logger.error(f"❌ Failed to get custom exercises for {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/{exercise_id}", response_model=CustomExerciseResponse)
async def get_custom_exercise(user_id: str, exercise_id: str):
    """Get a specific custom exercise."""
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
        logger.error(f"❌ Failed to get custom exercise {exercise_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}", response_model=CustomExerciseResponse)
async def create_custom_exercise(user_id: str, request: CustomExerciseCreate):
    """Create a new custom exercise."""
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
            logger.info(f"✅ Created custom exercise '{request.name}' for user {user_id}")
            return CustomExerciseResponse(**result.data[0])
        else:
            raise HTTPException(status_code=500, detail="Failed to create exercise")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to create custom exercise: {e}")
        # Check for unique constraint violation
        if "duplicate key" in str(e).lower() or "unique" in str(e).lower():
            raise HTTPException(status_code=400, detail="Exercise with this name already exists")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{user_id}/{exercise_id}", response_model=CustomExerciseResponse)
async def update_custom_exercise(user_id: str, exercise_id: str, request: CustomExerciseUpdate):
    """Update a custom exercise."""
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
            logger.info(f"✅ Updated custom exercise {exercise_id}")
            return CustomExerciseResponse(**result.data[0])
        else:
            raise HTTPException(status_code=500, detail="Failed to update exercise")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to update custom exercise {exercise_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/{exercise_id}")
async def delete_custom_exercise(user_id: str, exercise_id: str):
    """Delete a custom exercise and its associated media."""
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

        # Delete media from S3
        media_service = get_custom_exercise_media_service()
        await media_service.delete_media(user_id, exercise_id)

        # Delete from database
        db.client.table("custom_exercises").delete().eq("id", exercise_id).execute()

        logger.info(f"✅ Deleted custom exercise '{exercise_name}' for user {user_id}")
        return {"message": f"Deleted exercise: {exercise_name}"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to delete custom exercise {exercise_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/search/combined", response_model=List[ExerciseSearchResult])
async def search_combined_exercises(
    user_id: str,
    query: str = Query(..., min_length=1, description="Search query"),
    equipment: Optional[str] = Query(default=None, description="Filter by equipment"),
    limit: int = Query(default=20, ge=1, le=100),
):
    """Search both exercise library and custom exercises."""
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
        logger.error(f"❌ Failed to search exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/equipment/list")
async def list_equipment_with_exercises():
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
        logger.error(f"❌ Failed to list equipment: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Media Upload Endpoints (S3)
# =============================================================================

@router.post("/{user_id}/{exercise_id}/upload/presigned")
async def get_presigned_upload_url(
    user_id: str,
    exercise_id: str,
    media_type: str = Query(..., description="'image' or 'video'"),
    content_type: str = Query(..., description="MIME type (e.g., 'image/jpeg', 'video/mp4')"),
):
    """
    Get a presigned URL for direct client upload to S3.

    This allows the Flutter app to upload directly to S3 without going through the backend.
    After upload, call the update endpoint to save the S3 key.
    """
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
        logger.error(f"❌ Failed to generate presigned URL: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/{exercise_id}/upload/image", response_model=MediaUploadResponse)
async def upload_exercise_image(
    user_id: str,
    exercise_id: str,
    file: UploadFile = File(..., description="Image file (JPEG, PNG, GIF, WebP)"),
):
    """
    Upload an image for a custom exercise via the backend.

    For large files or better performance, use the presigned URL endpoint instead.
    """
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

        # Update exercise with image URL
        public_url = media_service.get_public_url(s3_key)
        db.client.table("custom_exercises").update({
            "image_url": s3_key
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
        logger.error(f"❌ Failed to upload image: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/{exercise_id}/upload/video", response_model=MediaUploadResponse)
async def upload_exercise_video(
    user_id: str,
    exercise_id: str,
    file: UploadFile = File(..., description="Video file (MP4, MOV, WebM)"),
):
    """
    Upload a video for a custom exercise via the backend.

    Note: For videos >10MB, use the presigned URL endpoint instead.
    """
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
        logger.error(f"❌ Failed to upload video: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/{exercise_id}/media")
async def delete_exercise_media(user_id: str, exercise_id: str):
    """Delete all media (image, video, thumbnail) for a custom exercise."""
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
        logger.error(f"❌ Failed to delete media: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/{exercise_id}/confirm-upload")
async def confirm_presigned_upload(
    user_id: str,
    exercise_id: str,
    s3_key: str = Query(..., description="S3 key from presigned upload"),
    media_type: str = Query(..., description="'image' or 'video'"),
):
    """
    Confirm a presigned upload was successful and update the exercise record.

    Call this after uploading via presigned URL to save the S3 key to the database.
    """
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

        # Update the appropriate field
        update_field = "image_url" if media_type == "image" else "video_url"
        db.client.table("custom_exercises").update({
            update_field: s3_key
        }).eq("id", exercise_id).execute()

        media_service = get_custom_exercise_media_service()
        public_url = media_service.get_public_url(s3_key)

        logger.info(f"✅ Confirmed {media_type} upload for exercise {exercise_id}")

        return {
            "message": f"{media_type.capitalize()} upload confirmed",
            "s3_key": s3_key,
            "public_url": public_url,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to confirm upload: {e}")
        raise HTTPException(status_code=500, detail=str(e))
