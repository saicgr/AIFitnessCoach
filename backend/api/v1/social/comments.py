"""
Comments API endpoints.

This module handles comment operations:
- POST /comments - Add a comment
- PUT /comments/{comment_id} - Update a comment
- DELETE /comments/{comment_id} - Delete a comment
- GET /comments/{activity_id} - Get comments for an activity
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from models.social import (
    ActivityComment, ActivityCommentCreate, ActivityCommentUpdate, CommentsResponse,
)
from .utils import get_supabase_client

router = APIRouter()


@router.post("/comments", response_model=ActivityComment)
async def add_comment(
    user_id: str,
    comment: ActivityCommentCreate,
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
    supabase = get_supabase_client()

    result = supabase.table("activity_comments").insert({
        "activity_id": comment.activity_id,
        "user_id": user_id,
        "comment_text": comment.comment_text,
        "parent_comment_id": comment.parent_comment_id,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to add comment")

    return ActivityComment(**result.data[0])


@router.put("/comments/{comment_id}", response_model=ActivityComment)
async def update_comment(
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
        raise HTTPException(status_code=500, detail="Failed to update comment")

    return ActivityComment(**result.data[0])


@router.delete("/comments/{comment_id}")
async def delete_comment(
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
