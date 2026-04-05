"""
Stories API endpoints (F11).

This module handles story operations:
- POST /presign - Get S3 presigned URL for story upload
- POST / - Create a story record
- GET /feed - Get friends' active stories
- GET /{story_id}/views - Get viewer list for own story
- DELETE /{story_id} - Soft delete story
"""
from typing import List, Optional
import uuid
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from starlette.requests import Request
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter
from core.config import get_settings
from core.logger import get_logger

from .utils import get_supabase_client

logger = get_logger(__name__)

router = APIRouter()


# Reuse the S3 client singleton from feed
_s3_client = None


def _get_s3_client():
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


@router.post("/presign")
@limiter.limit("5/minute")
async def get_story_presigned_url(
    request: Request,
    user_id: str = Query(..., description="User ID requesting upload"),
    file_extension: str = Query("jpg", description="File extension"),
    content_type: str = Query("image/jpeg", description="Content type"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get a pre-signed URL for direct story upload to S3.
    """
    verify_user_ownership(current_user, user_id)
    allowed_types = [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'video/mp4', 'video/quicktime',
    ]
    if content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid content type. Allowed: {', '.join(allowed_types)}"
        )

    timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
    storage_key = f"stories/{user_id}/{timestamp}_{uuid.uuid4().hex[:8]}.{file_extension}"

    try:
        s3 = _get_s3_client()
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
        logger.error(f"[Stories] Error generating presigned URL: {e}")
        raise safe_internal_error(e, "stories_presign")


@router.post("/")
@limiter.limit("5/minute")
async def create_story(
    request: Request,
    user_id: str = Query(..., description="User ID"),
    media_url: str = Query(..., description="Media URL"),
    media_type: str = Query("image", description="Media type (image or video)"),
    storage_key: str = Query(None, description="S3 storage key"),
    caption: str = Query(None, description="Optional caption"),
    current_user: dict = Depends(get_current_user),
):
    """
    Create a story record.

    Stories expire after 24 hours.

    Args:
        user_id: User ID
        media_url: URL of uploaded media
        media_type: Type of media (image/video)
        storage_key: Optional S3 storage key
        caption: Optional caption (max 500 chars)

    Returns:
        Created story record
    """
    verify_user_ownership(current_user, user_id)
    if caption and len(caption) > 500:
        raise HTTPException(status_code=400, detail="Caption must be 500 characters or less")

    try:
        supabase = get_supabase_client()

        now = datetime.now(timezone.utc)
        story_data = {
            "user_id": user_id,
            "media_url": media_url,
            "media_type": media_type,
            "created_at": now.isoformat(),
            "expires_at": (now + timedelta(hours=24)).isoformat(),
        }

        if storage_key:
            story_data["storage_key"] = storage_key
        if caption:
            story_data["caption"] = caption

        result = supabase.table("stories").insert(story_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create story")

        logger.info(f"[Stories] Story created by user {user_id}: {result.data[0]['id']}")

        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Stories] Error creating story: {e}")
        raise safe_internal_error(e, "stories")


@router.get("/feed")
async def get_stories_feed(
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get friends' active (not expired, not deleted) stories grouped by user.

    Includes a `has_viewed` flag for each story.

    Returns:
        List of story groups, each containing a user and their active stories
    """
    verify_user_ownership(current_user, user_id)
    try:
        supabase = get_supabase_client()

        # Get user's friend IDs (mutual connections)
        following = supabase.table("user_connections").select(
            "following_id"
        ).eq("follower_id", user_id).execute()
        following_ids = {c["following_id"] for c in (following.data or [])}

        followers = supabase.table("user_connections").select(
            "follower_id"
        ).eq("following_id", user_id).execute()
        follower_ids = {c["follower_id"] for c in (followers.data or [])}

        # Friends = mutual connections + self
        friend_ids = list(following_ids & follower_ids)
        friend_ids.append(user_id)  # Include own stories

        if not friend_ids:
            return {"story_groups": []}

        # Get active stories (not expired, not deleted)
        now = datetime.now(timezone.utc).isoformat()
        stories_result = supabase.table("stories").select(
            "id, user_id, media_url, media_type, caption, created_at, expires_at"
        ).in_("user_id", friend_ids).gt(
            "expires_at", now
        ).is_("deleted_at", "null").order("created_at", desc=True).execute()

        if not stories_result.data:
            return {"story_groups": []}

        # Get user info for story owners
        story_user_ids = list({s["user_id"] for s in stories_result.data})
        users_result = supabase.table("users").select(
            "id, name, avatar_url"
        ).in_("id", story_user_ids).execute()
        user_map = {u["id"]: u for u in (users_result.data or [])}

        # Get story views by current user
        story_ids = [s["id"] for s in stories_result.data]
        views_result = supabase.table("story_views").select(
            "story_id"
        ).eq("viewer_id", user_id).in_("story_id", story_ids).execute()
        viewed_story_ids = {v["story_id"] for v in (views_result.data or [])}

        # Group stories by user
        groups = {}
        for story in stories_result.data:
            uid = story["user_id"]
            if uid not in groups:
                user_info = user_map.get(uid, {})
                groups[uid] = {
                    "user_id": uid,
                    "user_name": user_info.get("name", "Unknown"),
                    "user_avatar": user_info.get("avatar_url"),
                    "stories": [],
                    "has_unviewed": False,
                }

            has_viewed = story["id"] in viewed_story_ids
            groups[uid]["stories"].append({
                **story,
                "has_viewed": has_viewed,
            })

            if not has_viewed:
                groups[uid]["has_unviewed"] = True

        # Sort groups: unviewed first, then by most recent story
        story_groups = sorted(
            groups.values(),
            key=lambda g: (not g["has_unviewed"], g["stories"][0]["created_at"]),
            reverse=True,
        )

        return {"story_groups": story_groups}

    except Exception as e:
        logger.error(f"[Stories] Error getting stories feed: {e}")
        raise safe_internal_error(e, "stories")


@router.get("/{story_id}/views")
async def get_story_views(
    story_id: str,
    user_id: str = Query(..., description="Current user ID (must be story owner)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get viewer list for own story.

    Only the story owner can see who viewed their story.

    Args:
        story_id: Story ID
        user_id: Current user's ID (must be the story owner)

    Returns:
        List of viewers with timestamps
    """
    verify_user_ownership(current_user, user_id)
    try:
        supabase = get_supabase_client()

        # Verify story exists and user owns it
        story_check = supabase.table("stories").select(
            "user_id"
        ).eq("id", story_id).execute()

        if not story_check.data:
            raise HTTPException(status_code=404, detail="Story not found")

        if story_check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Only the story owner can view this")

        # Get viewers
        views_result = supabase.table("story_views").select(
            "viewer_id, viewed_at"
        ).eq("story_id", story_id).order("viewed_at", desc=True).execute()

        if not views_result.data:
            return {"viewers": [], "view_count": 0}

        # Get viewer profiles
        viewer_ids = [v["viewer_id"] for v in views_result.data]
        users_result = supabase.table("users").select(
            "id, name, avatar_url"
        ).in_("id", viewer_ids).execute()
        user_map = {u["id"]: u for u in (users_result.data or [])}

        viewers = []
        for view in views_result.data:
            user_info = user_map.get(view["viewer_id"], {})
            viewers.append({
                "user_id": view["viewer_id"],
                "name": user_info.get("name", "Unknown"),
                "avatar_url": user_info.get("avatar_url"),
                "viewed_at": view["viewed_at"],
            })

        return {"viewers": viewers, "view_count": len(viewers)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Stories] Error getting story views: {e}")
        raise safe_internal_error(e, "stories")


@router.delete("/{story_id}")
async def delete_story(
    story_id: str,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Soft delete a story (set deleted_at).

    Args:
        story_id: Story ID
        user_id: Current user's ID (must be the story owner)

    Returns:
        Success message
    """
    verify_user_ownership(current_user, user_id)
    try:
        supabase = get_supabase_client()

        # Verify story exists and user owns it
        story_check = supabase.table("stories").select(
            "user_id"
        ).eq("id", story_id).execute()

        if not story_check.data:
            raise HTTPException(status_code=404, detail="Story not found")

        if story_check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this story")

        # Soft delete
        supabase.table("stories").update({
            "deleted_at": datetime.now(timezone.utc).isoformat(),
        }).eq("id", story_id).execute()

        logger.info(f"[Stories] Story {story_id} soft-deleted by user {user_id}")

        return {"message": "Story deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Stories] Error deleting story: {e}")
        raise safe_internal_error(e, "stories")
