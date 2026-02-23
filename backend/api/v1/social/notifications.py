"""
Social Notifications API endpoints.

This module handles social notification operations:
- GET /notifications - Get notifications for a user
- GET /notifications/unread-count - Get unread notification count
- PUT /notifications/{notification_id}/read - Mark notification as read
- PUT /notifications/read-all - Mark all notifications as read
- DELETE /notifications/{notification_id} - Delete a notification
- DELETE /notifications/clear-all - Clear all notifications
"""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from models.friend_request import (
    SocialNotification, SocialNotificationsList, SocialNotificationType,
    SocialPrivacySettings, SocialPrivacySettingsUpdate,
)
from .utils import get_supabase_client

router = APIRouter(prefix="/notifications")


@router.get("", response_model=SocialNotificationsList)
async def get_notifications(
    user_id: str = Query(..., description="Current user ID"),
    unread_only: bool = Query(False, description="Only return unread notifications"),
    notification_type: Optional[SocialNotificationType] = Query(None, description="Filter by type"),
    limit: int = Query(50, ge=1, le=100, description="Maximum notifications to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get social notifications for the current user.

    Args:
        user_id: Current user's ID
        unread_only: Whether to only return unread notifications
        notification_type: Optional type filter
        limit: Maximum number of notifications to return
        offset: Pagination offset

    Returns:
        List of notifications with unread count
    """
    supabase = get_supabase_client()

    # Build query for notifications
    query = supabase.table("social_notifications").select("*").eq("user_id", user_id)

    if unread_only:
        query = query.eq("is_read", False)

    if notification_type:
        query = query.eq("type", notification_type.value)

    query = query.order("created_at", desc=True).range(offset, offset + limit - 1)
    result = query.execute()

    # Get unread count
    unread_result = supabase.table("social_notifications").select(
        "id", count="exact"
    ).eq("user_id", user_id).eq("is_read", False).execute()

    # Get total count
    total_result = supabase.table("social_notifications").select(
        "id", count="exact"
    ).eq("user_id", user_id).execute()

    notifications = [SocialNotification(**n) for n in result.data]

    return SocialNotificationsList(
        notifications=notifications,
        unread_count=unread_result.count or 0,
        total_count=total_result.count or 0,
    )


@router.get("/unread-count")
async def get_unread_count(
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get count of unread social notifications.

    Args:
        user_id: Current user's ID

    Returns:
        Count of unread notifications
    """
    supabase = get_supabase_client()

    result = supabase.table("social_notifications").select(
        "id", count="exact"
    ).eq("user_id", user_id).eq("is_read", False).execute()

    return {"count": result.count or 0}


@router.put("/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Mark a notification as read.

    Args:
        notification_id: ID of the notification to mark as read
        user_id: Current user's ID

    Returns:
        Success message

    Raises:
        404: If notification not found or doesn't belong to user
    """
    supabase = get_supabase_client()

    # Verify notification exists and belongs to user
    check = supabase.table("social_notifications").select("id").eq(
        "id", notification_id
    ).eq("user_id", user_id).execute()

    if not check.data:
        raise HTTPException(status_code=404, detail="Notification not found")

    # Update notification
    supabase.table("social_notifications").update({
        "is_read": True
    }).eq("id", notification_id).execute()

    return {"message": "Notification marked as read"}


@router.put("/read-all")
async def mark_all_notifications_read(
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Mark all notifications as read for the current user.

    Args:
        user_id: Current user's ID

    Returns:
        Success message with count of updated notifications
    """
    supabase = get_supabase_client()

    result = supabase.table("social_notifications").update({
        "is_read": True
    }).eq("user_id", user_id).eq("is_read", False).execute()

    count = len(result.data) if result.data else 0

    return {"message": f"Marked {count} notifications as read", "count": count}


@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: str,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a notification.

    Args:
        notification_id: ID of the notification to delete
        user_id: Current user's ID

    Returns:
        Success message

    Raises:
        404: If notification not found or doesn't belong to user
    """
    supabase = get_supabase_client()

    # Verify notification exists and belongs to user
    check = supabase.table("social_notifications").select("id").eq(
        "id", notification_id
    ).eq("user_id", user_id).execute()

    if not check.data:
        raise HTTPException(status_code=404, detail="Notification not found")

    # Delete notification
    supabase.table("social_notifications").delete().eq("id", notification_id).execute()

    return {"message": "Notification deleted"}


@router.delete("/clear-all")
async def clear_all_notifications(
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Delete all notifications for the current user.

    Args:
        user_id: Current user's ID

    Returns:
        Success message with count of deleted notifications
    """
    supabase = get_supabase_client()

    result = supabase.table("social_notifications").delete().eq(
        "user_id", user_id
    ).execute()

    count = len(result.data) if result.data else 0

    return {"message": f"Deleted {count} notifications", "count": count}


# ============================================================
# SOCIAL PRIVACY SETTINGS ENDPOINTS
# ============================================================

@router.get("/settings", response_model=SocialPrivacySettings)
async def get_social_settings(
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get social and notification privacy settings for the user.

    Args:
        user_id: Current user's ID

    Returns:
        Social privacy settings
    """
    supabase = get_supabase_client()

    result = supabase.table("user_privacy_settings").select("*").eq(
        "user_id", user_id
    ).execute()

    if not result.data:
        # Return defaults if no settings exist
        return SocialPrivacySettings()

    settings = result.data[0]

    return SocialPrivacySettings(
        notify_friend_requests=settings.get("notify_friend_requests", True),
        notify_reactions=settings.get("notify_reactions", True),
        notify_comments=settings.get("notify_comments", True),
        notify_challenge_invites=settings.get("notify_challenge_invites", True),
        notify_friend_activity=settings.get("notify_friend_activity", True),
        require_follow_approval=settings.get("require_follow_approval", False),
        allow_friend_requests=settings.get("allow_friend_requests", True),
        allow_challenge_invites=settings.get("allow_challenge_invites", True),
        show_on_leaderboards=settings.get("show_on_leaderboards", True),
    )


@router.put("/settings", response_model=SocialPrivacySettings)
async def update_social_settings(
    user_id: str = Query(..., description="Current user ID"),
    settings: SocialPrivacySettingsUpdate = ...,
    current_user: dict = Depends(get_current_user),
):
    """
    Update social and notification privacy settings.

    Args:
        user_id: Current user's ID
        settings: Settings to update

    Returns:
        Updated social privacy settings
    """
    supabase = get_supabase_client()

    # Check if settings exist
    existing = supabase.table("user_privacy_settings").select("id").eq(
        "user_id", user_id
    ).execute()

    # Build update data (only include non-None values)
    update_data = {}
    if settings.notify_friend_requests is not None:
        update_data["notify_friend_requests"] = settings.notify_friend_requests
    if settings.notify_reactions is not None:
        update_data["notify_reactions"] = settings.notify_reactions
    if settings.notify_comments is not None:
        update_data["notify_comments"] = settings.notify_comments
    if settings.notify_challenge_invites is not None:
        update_data["notify_challenge_invites"] = settings.notify_challenge_invites
    if settings.notify_friend_activity is not None:
        update_data["notify_friend_activity"] = settings.notify_friend_activity
    if settings.require_follow_approval is not None:
        update_data["require_follow_approval"] = settings.require_follow_approval

    if existing.data:
        # Update existing settings
        supabase.table("user_privacy_settings").update(update_data).eq(
            "user_id", user_id
        ).execute()
    else:
        # Create new settings row
        update_data["user_id"] = user_id
        supabase.table("user_privacy_settings").insert(update_data).execute()

    # Return updated settings
    return await get_social_settings(user_id)
