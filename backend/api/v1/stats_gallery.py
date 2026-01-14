"""
Stats Gallery API Endpoints

Handles shareable stats images - upload, list, delete, and share to feed.
"""
import base64
import uuid
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from core.supabase_db import get_supabase_db
from models.stats_gallery import (
    DeleteStatsImageResponse,
    ShareStatsToFeedRequest,
    ShareStatsToFeedResponse,
    StatsTemplateType,
    UploadStatsImageRequest,
    UploadStatsImageResponse,
    StatsGalleryImage,
    StatsGalleryImageList,
)
from services.user_context_service import user_context_service, EventType

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/upload", response_model=UploadStatsImageResponse)
async def upload_stats_image(
    user_id: str = Query(..., description="User ID"),
    request: UploadStatsImageRequest = ...,
):
    """
    Upload a stats image to the gallery.

    The image is stored as a base64 data URL and metadata is saved to the database.
    """
    try:
        supabase = get_supabase_db()

        # Validate base64 image
        try:
            image_bytes = base64.b64decode(request.image_base64)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid base64 image: {e}")

        # Store image as base64 data URL
        image_url = f"data:image/png;base64,{request.image_base64}"

        # Build stats snapshot dict
        stats_snapshot_dict = None
        if request.stats_snapshot:
            stats_snapshot_dict = request.stats_snapshot.model_dump(exclude_none=True)

        # Insert into database
        gallery_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "image_url": image_url,
            "template_type": request.template_type.value,
            "stats_snapshot": stats_snapshot_dict,
            "date_range_start": request.date_range_start.isoformat() if request.date_range_start else None,
            "date_range_end": request.date_range_end.isoformat() if request.date_range_end else None,
            "prs_data": request.prs_data,
            "achievements_data": request.achievements_data,
        }

        result = supabase.client.table("stats_gallery").insert(gallery_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save stats image")

        image = StatsGalleryImage(**result.data[0])

        # Log user activity
        try:
            await user_context_service.log_activity(
                user_id=user_id,
                event_type=EventType.SOCIAL_INTERACTION,
                endpoint="/api/v1/stats-gallery/upload",
                message=f"Uploaded stats image with template: {request.template_type.value}",
                metadata={
                    "template_type": request.template_type.value,
                    "image_id": image.id,
                }
            )
        except Exception as log_error:
            logger.warning(f"Failed to log stats upload: {log_error}")

        return UploadStatsImageResponse(
            success=True,
            image=image,
            message="Stats image uploaded successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error uploading stats image: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}", response_model=StatsGalleryImageList)
async def list_stats_images(
    user_id: str,
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=50, description="Items per page"),
    template_type: Optional[StatsTemplateType] = Query(None, description="Filter by template type"),
):
    """
    List stats gallery images for a user with pagination.
    """
    try:
        supabase = get_supabase_db()

        # Build query
        query = supabase.client.table("stats_gallery") \
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

        images = [StatsGalleryImage(**row) for row in result.data]
        total = result.count or 0

        return StatsGalleryImageList(
            images=images,
            total=total,
            page=page,
            page_size=page_size,
            has_more=(offset + len(images)) < total
        )

    except Exception as e:
        logger.error(f"Error listing stats images: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/{image_id}", response_model=StatsGalleryImage)
async def get_stats_image(
    user_id: str,
    image_id: str,
):
    """
    Get a specific stats gallery image by ID.
    """
    try:
        supabase = get_supabase_db()

        result = supabase.client.table("stats_gallery") \
            .select("*") \
            .eq("id", image_id) \
            .eq("user_id", user_id) \
            .is_("deleted_at", "null") \
            .single() \
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Image not found")

        return StatsGalleryImage(**result.data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting stats image: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{image_id}", response_model=DeleteStatsImageResponse)
async def delete_stats_image(
    image_id: str,
    user_id: str = Query(..., description="User ID for authorization"),
):
    """
    Soft delete a stats gallery image.
    """
    try:
        supabase = get_supabase_db()

        # Verify ownership
        check = supabase.client.table("stats_gallery") \
            .select("id") \
            .eq("id", image_id) \
            .eq("user_id", user_id) \
            .is_("deleted_at", "null") \
            .single() \
            .execute()

        if not check.data:
            raise HTTPException(status_code=404, detail="Image not found or already deleted")

        # Soft delete
        result = supabase.client.table("stats_gallery") \
            .update({"deleted_at": datetime.now().isoformat()}) \
            .eq("id", image_id) \
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to delete image")

        return DeleteStatsImageResponse(
            success=True,
            message="Stats image deleted successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting stats image: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{image_id}/share-to-feed", response_model=ShareStatsToFeedResponse)
async def share_stats_to_feed(
    image_id: str,
    user_id: str = Query(..., description="User ID"),
    request: ShareStatsToFeedRequest = ShareStatsToFeedRequest(),
):
    """
    Share a stats image to the social feed.

    Creates a new activity in the social feed with the stats image.
    """
    try:
        supabase = get_supabase_db()

        # Get the gallery image
        image_result = supabase.client.table("stats_gallery") \
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
            "activity_type": "stats_shared",
            "activity_data": {
                "image_url": image_data["image_url"],
                "template_type": image_data["template_type"],
                "stats_snapshot": image_data.get("stats_snapshot"),
                "date_range_start": image_data.get("date_range_start"),
                "date_range_end": image_data.get("date_range_end"),
                "caption": request.caption,
                "gallery_image_id": image_id,
            },
            "visibility": request.visibility,
        }

        activity_result = supabase.client.table("activity_feed").insert(activity_data).execute()

        if not activity_result.data:
            raise HTTPException(status_code=500, detail="Failed to create social activity")

        # Update gallery image to mark as shared
        supabase.client.table("stats_gallery") \
            .update({"shared_to_feed": True}) \
            .eq("id", image_id) \
            .execute()

        # Log user activity
        try:
            await user_context_service.log_activity(
                user_id=user_id,
                event_type=EventType.SOCIAL_INTERACTION,
                endpoint="/api/v1/stats-gallery/share-to-feed",
                message=f"Shared stats to feed: {image_data['template_type']}",
                metadata={
                    "template_type": image_data["template_type"],
                    "image_id": image_id,
                    "activity_id": activity_result.data[0]["id"],
                }
            )
        except Exception as log_error:
            logger.warning(f"Failed to log stats share: {log_error}")

        return ShareStatsToFeedResponse(
            success=True,
            activity_id=activity_result.data[0]["id"],
            message="Stats shared to feed successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sharing stats to feed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{image_id}/track-external-share")
async def track_external_share(
    image_id: str,
    user_id: str = Query(..., description="User ID"),
):
    """
    Track when a user shares a stats image to external platforms.

    Increments the external_shares_count and sets shared_externally to true.
    """
    try:
        supabase = get_supabase_db()

        # Get current count
        image = supabase.client.table("stats_gallery") \
            .select("external_shares_count") \
            .eq("id", image_id) \
            .eq("user_id", user_id) \
            .single() \
            .execute()

        if not image.data:
            raise HTTPException(status_code=404, detail="Image not found")

        current_count = image.data.get("external_shares_count", 0)

        # Update
        result = supabase.client.table("stats_gallery") \
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
        logger.error(f"Error tracking external share: {e}")
        raise HTTPException(status_code=500, detail=str(e))
