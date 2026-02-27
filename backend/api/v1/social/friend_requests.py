"""
Friend Request API endpoints.

This module handles friend request operations:
- POST /friend-requests - Send a friend request
- GET /friend-requests/received - Get received friend requests
- GET /friend-requests/sent - Get sent friend requests
- POST /friend-requests/{request_id}/accept - Accept a friend request
- POST /friend-requests/{request_id}/decline - Decline a friend request
- DELETE /friend-requests/{request_id} - Cancel a sent friend request
"""
from typing import List, Optional
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from models.friend_request import (
    FriendRequest, FriendRequestCreate, FriendRequestWithUser,
    FriendRequestStatus, SocialNotificationType,
)
from core.logger import get_logger
from .utils import get_supabase_client

logger = get_logger(__name__)

router = APIRouter(prefix="/friend-requests")


async def create_social_notification(
    supabase,
    user_id: str,
    notification_type: SocialNotificationType,
    from_user_id: str,
    from_user_name: str,
    from_user_avatar: Optional[str],
    reference_id: str,
    reference_type: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
):
    """Helper to create a social notification."""
    try:
        # Check if user has this notification type enabled
        privacy = supabase.table("user_privacy_settings").select(
            "notify_friend_requests"
        ).eq("user_id", user_id).execute()

        # Default to enabled if no settings exist
        should_notify = True
        if privacy.data:
            if notification_type == SocialNotificationType.FRIEND_REQUEST:
                should_notify = privacy.data[0].get("notify_friend_requests", True)
            elif notification_type == SocialNotificationType.FRIEND_ACCEPTED:
                should_notify = privacy.data[0].get("notify_friend_requests", True)

        if should_notify:
            supabase.table("social_notifications").insert({
                "user_id": user_id,
                "type": notification_type.value,
                "from_user_id": from_user_id,
                "from_user_name": from_user_name,
                "from_user_avatar": from_user_avatar,
                "reference_id": reference_id,
                "reference_type": reference_type,
                "title": title,
                "body": body,
                "data": data or {},
                "is_read": False,
            }).execute()
    except Exception as e:
        # Don't fail the request if notification fails
        logger.error(f"Failed to create notification: {e}")


@router.post("", response_model=FriendRequest)
async def send_friend_request(
    user_id: str = Query(..., description="Current user ID"),
    request: FriendRequestCreate = ...,
    current_user: dict = Depends(get_current_user),
):
    """
    Send a friend request to another user.

    Args:
        user_id: ID of the user sending the request
        request: Friend request details

    Returns:
        Created friend request

    Raises:
        400: If trying to send request to self or duplicate request
        404: If target user not found
    """
    supabase = get_supabase_client()

    # Prevent self-requests
    if user_id == request.to_user_id:
        raise HTTPException(status_code=400, detail="Cannot send friend request to yourself")

    # Check if target user exists
    target_user = supabase.table("users").select("id, name, avatar_url").eq(
        "id", request.to_user_id
    ).single().execute()

    if not target_user.data:
        raise HTTPException(status_code=404, detail="User not found")

    # Check for existing request in either direction
    existing = supabase.table("friend_requests").select("id, status").or_(
        f"and(from_user_id.eq.{user_id},to_user_id.eq.{request.to_user_id}),"
        f"and(from_user_id.eq.{request.to_user_id},to_user_id.eq.{user_id})"
    ).execute()

    if existing.data:
        existing_request = existing.data[0]
        if existing_request["status"] == "pending":
            raise HTTPException(status_code=400, detail="A pending friend request already exists")
        elif existing_request["status"] == "accepted":
            raise HTTPException(status_code=400, detail="You are already friends with this user")

    # Check if already following (for non-approval required accounts)
    already_connected = supabase.table("user_connections").select("id").eq(
        "follower_id", user_id
    ).eq("following_id", request.to_user_id).execute()

    if already_connected.data:
        raise HTTPException(status_code=400, detail="You are already following this user")

    # Create the friend request
    result = supabase.table("friend_requests").insert({
        "from_user_id": user_id,
        "to_user_id": request.to_user_id,
        "status": FriendRequestStatus.PENDING.value,
        "message": request.message,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create friend request")

    friend_request = result.data[0]

    # Get sender's profile for notification
    sender = supabase.table("users").select("name, avatar_url").eq("id", user_id).single().execute()
    sender_name = sender.data.get("name", "Someone") if sender.data else "Someone"
    sender_avatar = sender.data.get("avatar_url") if sender.data else None

    # Create notification for recipient
    await create_social_notification(
        supabase=supabase,
        user_id=request.to_user_id,
        notification_type=SocialNotificationType.FRIEND_REQUEST,
        from_user_id=user_id,
        from_user_name=sender_name,
        from_user_avatar=sender_avatar,
        reference_id=friend_request["id"],
        reference_type="friend_request",
        title="New Friend Request",
        body=f"{sender_name} sent you a friend request",
        data={"message": request.message} if request.message else None,
    )

    return FriendRequest(**friend_request)


@router.get("/received", response_model=List[FriendRequestWithUser])
async def get_received_requests(
    user_id: str = Query(..., description="Current user ID"),
    status: Optional[FriendRequestStatus] = Query(None, description="Filter by status"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get friend requests received by the current user.

    Args:
        user_id: Current user's ID
        status: Optional status filter (default: all)

    Returns:
        List of friend requests with sender profiles
    """
    supabase = get_supabase_client()

    query = supabase.table("friend_requests").select(
        "*, users!friend_requests_from_user_id_fkey(id, name, avatar_url)"
    ).eq("to_user_id", user_id)

    if status:
        query = query.eq("status", status.value)

    query = query.order("created_at", desc=True).limit(50)
    result = query.execute()

    requests = []
    for row in result.data:
        request = FriendRequestWithUser(
            id=row["id"],
            from_user_id=row["from_user_id"],
            to_user_id=row["to_user_id"],
            status=FriendRequestStatus(row["status"]),
            message=row.get("message"),
            created_at=row["created_at"],
            responded_at=row.get("responded_at"),
        )

        if row.get("users"):
            request.from_user_name = row["users"].get("name")
            request.from_user_avatar = row["users"].get("avatar_url")

        requests.append(request)

    return requests


@router.get("/sent", response_model=List[FriendRequestWithUser])
async def get_sent_requests(
    user_id: str = Query(..., description="Current user ID"),
    status: Optional[FriendRequestStatus] = Query(None, description="Filter by status"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get friend requests sent by the current user.

    Args:
        user_id: Current user's ID
        status: Optional status filter (default: all)

    Returns:
        List of friend requests with recipient profiles
    """
    supabase = get_supabase_client()

    query = supabase.table("friend_requests").select(
        "*, users!friend_requests_to_user_id_fkey(id, name, avatar_url)"
    ).eq("from_user_id", user_id)

    if status:
        query = query.eq("status", status.value)

    query = query.order("created_at", desc=True).limit(50)
    result = query.execute()

    requests = []
    for row in result.data:
        request = FriendRequestWithUser(
            id=row["id"],
            from_user_id=row["from_user_id"],
            to_user_id=row["to_user_id"],
            status=FriendRequestStatus(row["status"]),
            message=row.get("message"),
            created_at=row["created_at"],
            responded_at=row.get("responded_at"),
        )

        if row.get("users"):
            request.to_user_name = row["users"].get("name")
            request.to_user_avatar = row["users"].get("avatar_url")

        requests.append(request)

    return requests


@router.get("/pending-count")
async def get_pending_count(
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get count of pending friend requests for current user.

    Args:
        user_id: Current user's ID

    Returns:
        Count of pending requests
    """
    supabase = get_supabase_client()

    result = supabase.table("friend_requests").select(
        "id", count="exact"
    ).eq("to_user_id", user_id).eq("status", "pending").execute()

    return {"count": result.count or 0}


@router.post("/{request_id}/accept")
async def accept_friend_request(
    request_id: str,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Accept a friend request.

    Args:
        request_id: ID of the friend request to accept
        user_id: Current user's ID (must be the recipient)

    Returns:
        Success message and created connection

    Raises:
        403: If user is not the recipient
        404: If request not found or not pending
    """
    supabase = get_supabase_client()

    # Get the friend request
    result = supabase.table("friend_requests").select("*").eq(
        "id", request_id
    ).single().execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Friend request not found")

    request = result.data

    # Verify the current user is the recipient
    if request["to_user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Only the recipient can accept this request")

    # Check if request is pending
    if request["status"] != "pending":
        raise HTTPException(status_code=400, detail=f"Request is already {request['status']}")

    # Update the request status
    now = datetime.now(timezone.utc).isoformat()
    supabase.table("friend_requests").update({
        "status": FriendRequestStatus.ACCEPTED.value,
        "responded_at": now,
    }).eq("id", request_id).execute()

    # Create bidirectional connections (mutual friends)
    from_user_id = request["from_user_id"]
    to_user_id = request["to_user_id"]

    # Create connection: requester follows recipient
    try:
        supabase.table("user_connections").insert({
            "follower_id": from_user_id,
            "following_id": to_user_id,
            "connection_type": "friend",
            "status": "active",
        }).execute()
    except Exception as e:
        logger.debug(f"Connection may already exist: {e}")

    # Create connection: recipient follows requester
    try:
        supabase.table("user_connections").insert({
            "follower_id": to_user_id,
            "following_id": from_user_id,
            "connection_type": "friend",
            "status": "active",
        }).execute()
    except Exception as e:
        logger.debug(f"Connection may already exist: {e}")

    # Get recipient's profile for notification
    recipient = supabase.table("users").select("name, avatar_url").eq("id", user_id).single().execute()
    recipient_name = recipient.data.get("name", "Someone") if recipient.data else "Someone"
    recipient_avatar = recipient.data.get("avatar_url") if recipient.data else None

    # Notify the original sender that their request was accepted
    await create_social_notification(
        supabase=supabase,
        user_id=from_user_id,
        notification_type=SocialNotificationType.FRIEND_ACCEPTED,
        from_user_id=user_id,
        from_user_name=recipient_name,
        from_user_avatar=recipient_avatar,
        reference_id=request_id,
        reference_type="friend_request",
        title="Friend Request Accepted",
        body=f"{recipient_name} accepted your friend request",
    )

    return {
        "message": "Friend request accepted",
        "connection_created": True,
    }


@router.post("/{request_id}/decline")
async def decline_friend_request(
    request_id: str,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Decline a friend request.

    Args:
        request_id: ID of the friend request to decline
        user_id: Current user's ID (must be the recipient)

    Returns:
        Success message

    Raises:
        403: If user is not the recipient
        404: If request not found or not pending
    """
    supabase = get_supabase_client()

    # Get the friend request
    result = supabase.table("friend_requests").select("*").eq(
        "id", request_id
    ).single().execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Friend request not found")

    request = result.data

    # Verify the current user is the recipient
    if request["to_user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Only the recipient can decline this request")

    # Check if request is pending
    if request["status"] != "pending":
        raise HTTPException(status_code=400, detail=f"Request is already {request['status']}")

    # Update the request status
    now = datetime.now(timezone.utc).isoformat()
    supabase.table("friend_requests").update({
        "status": FriendRequestStatus.DECLINED.value,
        "responded_at": now,
    }).eq("id", request_id).execute()

    return {"message": "Friend request declined"}


@router.delete("/{request_id}")
async def cancel_friend_request(
    request_id: str,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Cancel a sent friend request.

    Args:
        request_id: ID of the friend request to cancel
        user_id: Current user's ID (must be the sender)

    Returns:
        Success message

    Raises:
        403: If user is not the sender
        404: If request not found
    """
    supabase = get_supabase_client()

    # Get the friend request
    result = supabase.table("friend_requests").select("*").eq(
        "id", request_id
    ).single().execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Friend request not found")

    request = result.data

    # Verify the current user is the sender
    if request["from_user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Only the sender can cancel this request")

    # Check if request is pending
    if request["status"] != "pending":
        raise HTTPException(status_code=400, detail="Can only cancel pending requests")

    # Delete the request
    supabase.table("friend_requests").delete().eq("id", request_id).execute()

    # Also delete any associated notification
    supabase.table("social_notifications").delete().eq(
        "reference_id", request_id
    ).eq("reference_type", "friend_request").execute()

    return {"message": "Friend request cancelled"}
