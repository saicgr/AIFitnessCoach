"""
Comments API endpoints.

This module handles comment operations:
- POST /comments - Add a comment
- PUT /comments/{comment_id} - Update a comment
- DELETE /comments/{comment_id} - Delete a comment
- GET /comments/{activity_id} - Get comments for an activity
"""
import asyncio
from datetime import datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from starlette.requests import Request
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter
from core.logger import get_logger

from models.social import (
    ActivityComment, ActivityCommentCreate, ActivityCommentUpdate, CommentsResponse,
)
from .utils import get_supabase_client

logger = get_logger(__name__)

router = APIRouter()


def _bg_notify_comment(activity_id: str, commenter_id: str, comment_text: str):
    """Background task: send push notification for a new comment."""
    try:
        supabase = get_supabase_client()

        # Get activity owner
        activity_result = supabase.table("activity_feed").select("user_id").eq("id", activity_id).execute()
        if not activity_result.data:
            return
        owner_id = activity_result.data[0]["user_id"]

        # Skip if commenter == owner
        if owner_id == commenter_id:
            return

        # Check privacy settings
        privacy_result = supabase.table("user_privacy_settings").select(
            "notify_comments"
        ).eq("user_id", owner_id).execute()
        if privacy_result.data and not privacy_result.data[0].get("notify_comments", True):
            return

        # Get commenter name
        commenter_result = supabase.table("users").select("name").eq("id", commenter_id).execute()
        commenter_name = commenter_result.data[0]["name"] if commenter_result.data else "Someone"

        # Truncate comment for notification
        preview = comment_text[:100] + "..." if len(comment_text) > 100 else comment_text

        # Create social_notifications row (upsert by from_user_id + reference_id + type for dedup)
        supabase.table("social_notifications").upsert({
            "user_id": owner_id,
            "from_user_id": commenter_id,
            "type": "comment",
            "title": f"{commenter_name} commented on your post",
            "body": preview,
            "reference_id": activity_id,
            "is_read": False,
        }, on_conflict="from_user_id,reference_id,type").execute()

        # Try to send push notification
        try:
            owner_result = supabase.table("users").select("fcm_token").eq("id", owner_id).execute()
            if owner_result.data and owner_result.data[0].get("fcm_token"):
                import asyncio
                from services.notification_service import NotificationService
                ns = NotificationService()
                asyncio.get_event_loop().run_until_complete(
                    ns.send_notification(
                        fcm_token=owner_result.data[0]["fcm_token"],
                        title=f"{commenter_name} commented on your post",
                        body=preview,
                        data={"type": "comment", "activity_id": activity_id},
                    )
                )
        except Exception:
            pass  # Push notification is best-effort

    except Exception as e:
        logger.error(f"[Social] Failed to notify comment: {e}", exc_info=True)


@router.post("/comments", response_model=ActivityComment)
@limiter.limit("20/minute")
async def add_comment(
    request: Request,
    user_id: str,
    comment: ActivityCommentCreate,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Add a comment to an activity.

    Args:
        user_id: User ID
        comment: Comment details

    Returns:
        Created comment
    """
    verify_user_ownership(current_user, user_id)
    supabase = get_supabase_client()

    result = supabase.table("activity_comments").insert({
        "activity_id": comment.activity_id,
        "user_id": user_id,
        "comment_text": comment.comment_text,
        "parent_comment_id": comment.parent_comment_id,
    }).execute()

    if not result.data:
        raise safe_internal_error(ValueError("Failed to add comment"), "social")

    # Send push notification for comment (F5)
    background_tasks.add_task(
        _bg_notify_comment,
        activity_id=comment.activity_id,
        commenter_id=user_id,
        comment_text=comment.comment_text,
    )

    return ActivityComment(**result.data[0])


@router.put("/comments/{comment_id}", response_model=ActivityComment)
@limiter.limit("20/minute")
async def update_comment(
    request: Request,
    user_id: str,
    comment_id: str,
    update: ActivityCommentUpdate,
    current_user: dict = Depends(get_current_user),
):
    """
    Update a comment (user can only update their own).

    Args:
        user_id: User ID
        comment_id: Comment ID
        update: Updated comment text

    Returns:
        Updated comment
    """
    verify_user_ownership(current_user, user_id)
    supabase = get_supabase_client()

    # Verify ownership
    check = supabase.table("activity_comments").select("user_id").eq("id", comment_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Comment not found")
    if check.data[0]["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this comment")

    result = supabase.table("activity_comments").update({
        "comment_text": update.comment_text,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", comment_id).execute()

    if not result.data:
        raise safe_internal_error(ValueError("Failed to update comment"), "social")

    return ActivityComment(**result.data[0])


@router.delete("/comments/{comment_id}")
@limiter.limit("10/minute")
async def delete_comment(
    request: Request,
    user_id: str,
    comment_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a comment (user can only delete their own).

    Args:
        user_id: User ID
        comment_id: Comment ID

    Returns:
        Success message
    """
    verify_user_ownership(current_user, user_id)
    supabase = get_supabase_client()

    # Verify ownership
    check = supabase.table("activity_comments").select("user_id").eq("id", comment_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Comment not found")
    if check.data[0]["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this comment")

    result = supabase.table("activity_comments").delete().eq("id", comment_id).execute()

    return {"message": "Comment deleted successfully"}


@router.get("/comments/{activity_id}", response_model=CommentsResponse)
async def get_comments(
    activity_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """
    Get comments for an activity.

    Args:
        activity_id: Activity ID
        page: Page number
        page_size: Items per page

    Returns:
        Paginated comments
    """
    supabase = get_supabase_client()

    offset = (page - 1) * page_size

    result = supabase.table("activity_comments").select(
        "*, users(name, avatar_url)",
        count="exact"
    ).eq("activity_id", activity_id).is_("parent_comment_id", "null").order(
        "created_at", desc=True
    ).range(offset, offset + page_size - 1).execute()

    comments = []
    for row in result.data:
        comment = ActivityComment(**row)
        if row.get("users"):
            comment.user_name = row["users"].get("name")
            comment.user_avatar = row["users"].get("avatar_url")
        comments.append(comment)

    total_count = result.count or 0

    return CommentsResponse(
        comments=comments,
        total_count=total_count,
        page=page,
        page_size=page_size,
    )
