"""
Workout Gallery API Endpoints

Handles shareable workout recap images - upload, list, delete, and share to feed.
"""
import base64
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from core.supabase_db import get_supabase_db
from models.workout_gallery import (
    DeleteImageResponse,
    ShareToFeedRequest,
    ShareToFeedResponse,
    TemplateType,
    UploadImageRequest,
    UploadImageResponse,
    WorkoutGalleryImage,
    WorkoutGalleryImageList,
)

router = APIRouter()


@router.post("/upload", response_model=UploadImageResponse)
async def upload_gallery_image(
    user_id: str = Query(..., description="User ID"),
    request: UploadImageRequest = ...,
    current_user: dict = Depends(get_current_user),
):
    """
    Upload a workout recap image to the gallery.

    The image is stored in Supabase Storage and metadata is saved to the database.
    """
    try:
        supabase = get_supabase_db()

        # Validate base64 image
        try:
            image_bytes = base64.b64decode(request.image_base64)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid base64 image: {e}")

        # Store image as base64 data URL (works without Supabase Storage)
        # This ensures images are always accessible
        image_url = f"data:image/png;base64,{request.image_base64}"

        # Handle optional user photo - also store as data URL
        user_photo_url = None
        if request.user_photo_base64:
            try:
                base64.b64decode(request.user_photo_base64)  # Validate
                user_photo_url = f"data:image/png;base64,{request.user_photo_base64}"
            except Exception as e:
                print(f"User photo validation warning: {e}")

        # Insert into database
        gallery_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "workout_log_id": request.workout_log_id,
            "image_url": image_url,
            "template_type": request.template_type.value,
            "workout_name": request.workout_snapshot.workout_name,
            "duration_seconds": request.workout_snapshot.duration_seconds,
            "calories": request.workout_snapshot.calories,
            "total_volume_kg": request.workout_snapshot.total_volume_kg,
            "total_sets": request.workout_snapshot.total_sets,
            "total_reps": request.workout_snapshot.total_reps,
            "exercises_count": request.workout_snapshot.exercises_count,
            "user_photo_url": user_photo_url,
            "prs_data": request.prs_data,
            "achievements_data": request.achievements_data,
        }

        result = supabase.client.table("workout_gallery_images").insert(gallery_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save gallery image")

        image = WorkoutGalleryImage(**result.data[0])

        return UploadImageResponse(
            success=True,
            image=image,
            message="Image uploaded successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error uploading gallery image: {e}")
        raise safe_internal_error(e, "workout_gallery")


@router.get("/{user_id}", response_model=WorkoutGalleryImageList)
async def list_gallery_images(
    user_id: str,
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=50, description="Items per page"),
    template_type: Optional[TemplateType] = Query(None, description="Filter by template type"),
    current_user: dict = Depends(get_current_user),
):
    """
    List gallery images for a user with pagination.
    """
    try:
        supabase = get_supabase_db()

        # Build query
        query = supabase.client.table("workout_gallery_images") \
            .select("*", count="exact") \
            .eq("user_id", user_id) \
            .is_("deleted_at", "null") \
            .order("created_at", desc=True)

        if template_type:
            query = query.eq("template_type", template_type.value)

        # Calculate offset
        offset = (page - 1) * page_size

        # Execute with pagination
        result = query.range(offset, offset + page_size - 1).execute()

        images = [WorkoutGalleryImage(**row) for row in result.data]
        total = result.count or 0

        return WorkoutGalleryImageList(
            images=images,
            total=total,
            page=page,
            page_size=page_size,
            has_more=(offset + len(images)) < total
        )

    except Exception as e:
        print(f"Error listing gallery images: {e}")
        raise safe_internal_error(e, "workout_gallery")


@router.get("/{user_id}/{image_id}", response_model=WorkoutGalleryImage)
async def get_gallery_image(
    user_id: str,
    image_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get a specific gallery image by ID.
    """
    try:
        supabase = get_supabase_db()

        result = supabase.client.table("workout_gallery_images") \
            .select("*") \
            .eq("id", image_id) \
            .eq("user_id", user_id) \
            .is_("deleted_at", "null") \
            .single() \
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Image not found")

        return WorkoutGalleryImage(**result.data)

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error getting gallery image: {e}")
        raise safe_internal_error(e, "workout_gallery")


@router.delete("/{image_id}", response_model=DeleteImageResponse)
async def delete_gallery_image(
    image_id: str,
    user_id: str = Query(..., description="User ID for authorization"),
    current_user: dict = Depends(get_current_user),
):
    """
    Soft delete a gallery image.
    """
    try:
        supabase = get_supabase_db()

        # Verify ownership
        check = supabase.client.table("workout_gallery_images") \
            .select("id") \
            .eq("id", image_id) \
            .eq("user_id", user_id) \
            .is_("deleted_at", "null") \
            .single() \
            .execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Image not found or already deleted")

        # Soft delete
        result = supabase.client.table("workout_gallery_images") \
            .update({"deleted_at": datetime.now().isoformat()}) \
            .eq("id", image_id) \
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to delete image")

        return DeleteImageResponse(
            success=True,
            message="Image deleted successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error deleting gallery image: {e}")
        raise safe_internal_error(e, "workout_gallery")


@router.post("/{image_id}/share-to-feed", response_model=ShareToFeedResponse)
async def share_image_to_feed(
    image_id: str,
    user_id: str = Query(..., description="User ID"),
    request: ShareToFeedRequest = ShareToFeedRequest(),
    current_user: dict = Depends(get_current_user),
):
    """
    Share a gallery image to the social feed.

    Creates a new activity in the social feed with the gallery image.
    """
    try:
        supabase = get_supabase_db()

        # Get the gallery image
        image_result = supabase.client.table("workout_gallery_images") \
            .select("*") \
            .eq("id", image_id) \
            .eq("user_id", user_id) \
            .is_("deleted_at", "null") \
            .single() \
            .execute()

        if not image_result.data:
            raise HTTPException(status_code=404, detail="Image not found")

        image_data = image_result.data

        # Create social activity
        activity_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "activity_type": "workout_recap_shared",
            "activity_data": {
                "image_url": image_data["image_url"],
                "template_type": image_data["template_type"],
                "workout_name": image_data["workout_name"],
                "duration_seconds": image_data["duration_seconds"],
                "calories": image_data["calories"],
                "total_volume_kg": image_data["total_volume_kg"],
                "total_sets": image_data["total_sets"],
                "total_reps": image_data["total_reps"],
                "exercises_count": image_data["exercises_count"],
                "caption": request.caption,
                "gallery_image_id": image_id,
            },
            "visibility": request.visibility,
            "workout_log_id": image_data.get("workout_log_id"),
        }

        activity_result = supabase.client.table("activity_feed").insert(activity_data).execute()

        if not activity_result.data:
            raise HTTPException(status_code=500, detail="Failed to create social activity")

        # Update gallery image to mark as shared
        supabase.client.table("workout_gallery_images") \
            .update({"shared_to_feed": True}) \
            .eq("id", image_id) \
            .execute()

        return ShareToFeedResponse(
            success=True,
            activity_id=activity_result.data[0]["id"],
            message="Image shared to feed successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error sharing to feed: {e}")
        raise safe_internal_error(e, "workout_gallery")


@router.put("/{image_id}/track-external-share")
async def track_external_share(
    image_id: str,
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Track when a user shares an image to external platforms.

    Increments the external_shares_count and sets shared_externally to true.
    """
    try:
        supabase = get_supabase_db()

        # Get current count
        image = supabase.client.table("workout_gallery_images") \
            .select("external_shares_count") \
            .eq("id", image_id) \
            .eq("user_id", user_id) \
            .single() \
            .execute()

        if not image.data:
            raise HTTPException(status_code=404, detail="Image not found")

        current_count = image.data.get("external_shares_count", 0)

        # Update
        result = supabase.client.table("workout_gallery_images") \
            .update({
                "shared_externally": True,
                "external_shares_count": current_count + 1
            }) \
            .eq("id", image_id) \
            .execute()

        return {
            "success": True,
            "external_shares_count": current_count + 1,
            "message": "External share tracked"
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error tracking external share: {e}")
        raise safe_internal_error(e, "workout_gallery")
