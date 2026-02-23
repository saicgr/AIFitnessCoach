"""
Activity feed API endpoints.

This module handles activity feed operations:
- GET /feed/{user_id} - Get activity feed for a user
- POST /feed - Create a new activity
- DELETE /feed/{activity_id} - Delete an activity
- POST /feed/{activity_id}/pin - Pin an activity (admin only)
- DELETE /feed/{activity_id}/pin - Unpin an activity (admin only)
- POST /images/presign - Get pre-signed URL for direct S3 upload
- POST /images/upload - Upload image for social post
"""
import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException, Query, UploadFile, File, Form
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from core.config import get_settings
from models.social import (
    ActivityFeedItem, ActivityFeedItemCreate, ActivityFeedResponse, ActivityType,
)
from services.social_rag_service import get_social_rag_service
from services.admin_service import get_admin_service
from .utils import get_supabase_client

router = APIRouter()


# ============================================================================
# S3 Upload Helper for Social Posts
# ============================================================================

_s3_client = None


def get_s3_client():
    """Get S3 client with configured credentials (singleton)."""
    global _s3_client
    if _s3_client is None:
        import boto3
        settings = get_settings()
        _s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_default_region,
        )
    return _s3_client


@router.post("/images/presign")
async def get_presigned_upload_url(
    user_id: str = Query(..., description="User ID requesting upload"),
    file_extension: str = Query("jpg", description="File extension"),
    content_type: str = Query("image/jpeg", description="Content type"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get a pre-signed URL for direct image upload to S3.
    Client uploads directly to S3 -- zero bytes through the API server.
    """
    allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    if content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid content type. Allowed: {', '.join(allowed_types)}"
        )

    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    storage_key = f"social_posts/{user_id}/{timestamp}_{uuid.uuid4().hex[:8]}.{file_extension}"

    try:
        s3 = get_s3_client()
        settings = get_settings()

        presigned_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': settings.s3_bucket_name,
                'Key': storage_key,
                'ContentType': content_type,
            },
            ExpiresIn=600,  # 10 minutes
        )

        public_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{storage_key}"

        return {
            "upload_url": presigned_url,
            "storage_key": storage_key,
            "public_url": public_url,
        }
    except Exception as e:
        print(f"[Social] Error generating presigned URL: {e}")
        raise safe_internal_error(e, "feed_presign_url")


@router.post("/images/upload")
async def upload_post_image(
    user_id: str = Form(...),
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Upload an image for a social post to S3.

    Args:
        user_id: User ID uploading the image
        file: Image file

    Returns:
        dict with image_url and storage_key
    """
    # Validate file type
    allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(allowed_types)}"
        )

    # Generate unique storage key
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    ext = file.filename.split('.')[-1] if file.filename else 'jpg'
    storage_key = f"social_posts/{user_id}/{timestamp}_{uuid.uuid4().hex[:8]}.{ext}"

    try:
        # Upload to S3
        s3 = get_s3_client()
        contents = await file.read()

        # Safety limit: reject files > 10MB
        if len(contents) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=413,
                detail="File too large. Maximum size is 10MB. Use /images/presign for client-side upload."
            )

        settings = get_settings()
        s3.put_object(
            Bucket=settings.s3_bucket_name,
            Key=storage_key,
            Body=contents,
            ContentType=file.content_type or 'image/jpeg',
        )

        # Generate public URL
        image_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{storage_key}"

        print(f"[Social] Image uploaded: {storage_key}")
        return {
            "image_url": image_url,
            "storage_key": storage_key,
        }

    except Exception as e:
        print(f"[Social] Error uploading image to S3: {e}")
        raise safe_internal_error(e, "feed_image_upload")


@router.get("/feed/{user_id}")
async def get_activity_feed(
    user_id: str,
    page: int = 1,
    page_size: int = 20,
    activity_type: Optional[ActivityType] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get activity feed for a user (their activities + friends' activities).

    Args:
        user_id: User ID
        page: Page number (1-indexed)
        page_size: Items per page
        activity_type: Optional filter by activity type

    Returns:
        Paginated activity feed
    """
    try:
        supabase = get_supabase_client()
    except Exception as e:
        print(f"[Social] Error getting supabase client: {e}")
        raise safe_internal_error(e, "feed_db_connection")

    offset = (page - 1) * page_size

    # Single RPC call replaces following_ids fetch + unbounded IN clause
    try:
        feed_result = supabase.rpc("get_feed_for_user", {
            "p_user_id": user_id,
            "p_activity_type": activity_type.value if activity_type else None,
            "p_limit": page_size,
            "p_offset": offset,
        }).execute()
    except Exception as e:
        print(f"[Social] Error fetching feed: {e}")
        raise safe_internal_error(e, "feed_fetch")

    # Extract total_count from the window function (same on every row)
    total_count = 0
    if feed_result.data:
        total_count = feed_result.data[0].get("total_count", 0)

    # Parse activities
    activities = []
    for row in feed_result.data:
        try:
            row_data = {
                **row,
                "is_pinned": row.get("is_pinned", False),
                "pinned_at": row.get("pinned_at"),
                "pinned_by": row.get("pinned_by"),
            }
            # Remove window-function column before model parsing
            row_data.pop("total_count", None)
            # Remove nested 'users' if present
            users_data = row_data.pop("users", None)

            activity = ActivityFeedItem(**row_data)
            if users_data:
                activity.user_name = users_data.get("name")
                activity.user_avatar = users_data.get("avatar_url")
                activity.is_support_user = users_data.get("is_support_user", False)
            activities.append(activity)
        except Exception as parse_error:
            print(f"[Social] Error parsing activity row: {parse_error}, row: {row}")
            continue

    return {
        "items": [a.model_dump() for a in activities],
        "total_count": total_count,
        "page": page,
        "page_size": page_size,
        "has_more": offset + page_size < total_count,
    }


def _bg_index_activity(activity_id: str, user_id: str, activity_type: str, activity_data: dict, visibility: str, created_at):
    """Background task: index activity in ChromaDB for AI context."""
    try:
        supabase = get_supabase_client()
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"

        social_rag = get_social_rag_service()
        social_rag.add_activity_to_rag(
            activity_id=activity_id,
            user_id=user_id,
            user_name=user_name,
            activity_type=activity_type,
            activity_data=activity_data,
            visibility=visibility,
            created_at=created_at,
        )
        print(f"[Social] Activity {activity_id} indexed in ChromaDB")
    except Exception as e:
        print(f"[Social] Failed to index activity in ChromaDB: {e}")


def _bg_remove_activity(activity_id: str):
    """Background task: remove activity from ChromaDB."""
    try:
        social_rag = get_social_rag_service()
        social_rag.delete_activity_from_rag(activity_id)
    except Exception as e:
        print(f"[Social] Failed to remove activity from ChromaDB: {e}")


@router.post("/feed", response_model=ActivityFeedItem)
async def create_activity(
    user_id: str,
    activity: ActivityFeedItemCreate,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new activity feed item.

    Args:
        user_id: User ID
        activity: Activity details

    Returns:
        Created activity
    """
    supabase = get_supabase_client()

    result = supabase.table("activity_feed").insert({
        "user_id": user_id,
        "activity_type": activity.activity_type.value,
        "activity_data": activity.activity_data,
        "visibility": activity.visibility.value,
        "workout_log_id": activity.workout_log_id,
        "achievement_id": activity.achievement_id,
        "pr_id": activity.pr_id,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create activity")

    activity_item = ActivityFeedItem(**result.data[0])

    # Store in ChromaDB in background - non-blocking
    background_tasks.add_task(
        _bg_index_activity,
        activity_id=activity_item.id,
        user_id=user_id,
        activity_type=activity.activity_type.value,
        activity_data=activity.activity_data,
        visibility=activity.visibility.value,
        created_at=activity_item.created_at,
    )

    return activity_item


@router.delete("/feed/{activity_id}")
async def delete_activity(
    user_id: str,
    activity_id: str,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Delete an activity (user can only delete their own).

    Args:
        user_id: User ID
        activity_id: Activity ID

    Returns:
        Success message
    """
    supabase = get_supabase_client()

    # Verify ownership
    check = supabase.table("activity_feed").select("user_id").eq("id", activity_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Activity not found")
    if check.data[0]["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this activity")

    result = supabase.table("activity_feed").delete().eq("id", activity_id).execute()

    # Remove from ChromaDB in background - non-blocking
    background_tasks.add_task(_bg_remove_activity, activity_id)

    return {"message": "Activity deleted successfully"}


@router.post("/feed/{activity_id}/pin")
async def pin_activity(
    user_id: str,
    activity_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Pin an activity to the top of the feed (admin only).

    Args:
        user_id: User ID making the request (must be admin)
        activity_id: Activity ID to pin

    Returns:
        Success message

    Raises:
        403: If user is not an admin
        404: If activity not found
    """
    supabase = get_supabase_client()
    admin_service = get_admin_service()

    # Check if user is admin
    if not await admin_service.is_admin(user_id):
        raise HTTPException(
            status_code=403,
            detail="Only admins can pin posts"
        )

    # Verify activity exists
    check = supabase.table("activity_feed").select("id").eq("id", activity_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Activity not found")

    # Pin the activity
    result = supabase.table("activity_feed").update({
        "is_pinned": True,
        "pinned_at": datetime.now(timezone.utc).isoformat(),
        "pinned_by": user_id,
    }).eq("id", activity_id).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to pin activity")

    return {"message": "Activity pinned successfully"}


@router.delete("/feed/{activity_id}/pin")
async def unpin_activity(
    user_id: str,
    activity_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Unpin an activity from the top of the feed (admin only).

    Args:
        user_id: User ID making the request (must be admin)
        activity_id: Activity ID to unpin

    Returns:
        Success message

    Raises:
        403: If user is not an admin
        404: If activity not found
    """
    supabase = get_supabase_client()
    admin_service = get_admin_service()

    # Check if user is admin
    if not await admin_service.is_admin(user_id):
        raise HTTPException(
            status_code=403,
            detail="Only admins can unpin posts"
        )

    # Verify activity exists
    check = supabase.table("activity_feed").select("id").eq("id", activity_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Activity not found")

    # Unpin the activity
    result = supabase.table("activity_feed").update({
        "is_pinned": False,
        "pinned_at": None,
        "pinned_by": None,
    }).eq("id", activity_id).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to unpin activity")

    return {"message": "Activity unpinned successfully"}
