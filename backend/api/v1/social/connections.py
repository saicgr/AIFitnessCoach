"""
User connections API endpoints.

This module handles user connection operations:
- POST /connections - Create a connection (follow someone)
- DELETE /connections/{following_id} - Delete a connection (unfollow)
- GET /connections/followers/{user_id} - Get followers
- GET /connections/following/{user_id} - Get following
- GET /connections/friends/{user_id} - Get mutual friends
"""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from models.social import (
    UserConnection, UserConnectionCreate, UserConnectionWithProfile, UserProfile,
    ConnectionType,
)
from .utils import get_supabase_client
from services.admin_service import get_admin_service

router = APIRouter()


@router.post("/connections", response_model=UserConnection)
async def create_connection(
    user_id: str,
    connection: UserConnectionCreate,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new user connection (follow someone).

    Args:
        user_id: ID of the user creating the connection (follower)
        connection: Connection details (who to follow)

    Returns:
        Created connection

    Raises:
        400: If trying to follow self or already following
        404: If target user not found
    """
    supabase = get_supabase_client()

    # Prevent self-following
    if user_id == connection.following_id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")

    # Check if connection already exists
    existing = supabase.table("user_connections").select("*").eq(
        "follower_id", user_id
    ).eq("following_id", connection.following_id).execute()

    if existing.data:
        raise HTTPException(status_code=400, detail="Already following this user")

    # Create connection
    result = supabase.table("user_connections").insert({
        "follower_id": user_id,
        "following_id": connection.following_id,
        "connection_type": connection.connection_type.value,
        "status": "active",
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create connection")

    return UserConnection(**result.data[0])


@router.delete("/connections/{following_id}")
async def delete_connection(
    user_id: str,
    following_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a connection (unfollow someone).

    Args:
        user_id: ID of the user (follower)
        following_id: ID of the user to unfollow

    Returns:
        Success message

    Raises:
        403: If trying to unfollow the support user
        404: If connection not found
    """
    supabase = get_supabase_client()

    # Check if trying to unfollow the support user
    admin_service = get_admin_service()
    if await admin_service.is_support_user(following_id):
        raise HTTPException(
            status_code=403,
            detail="Cannot remove FitWiz Support from friends. They're here to help!"
        )

    result = supabase.table("user_connections").delete().eq(
        "follower_id", user_id
    ).eq("following_id", following_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Connection not found")

    return {"message": "Connection deleted successfully"}


@router.get("/connections/followers/{user_id}")
async def get_followers(
    user_id: str,
    connection_type: Optional[ConnectionType] = None,
    cursor: Optional[str] = None,
    limit: int = Query(50, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """
    Get followers for a user with cursor-based pagination.

    Args:
        user_id: User ID
        connection_type: Optional filter by connection type
        cursor: Pagination cursor (format: created_at_iso|id)
        limit: Max results per page (1-100, default 50)

    Returns:
        Paginated followers with profile data
    """
    supabase = get_supabase_client()

    query = supabase.table("user_connections").select(
        "*, users!user_connections_follower_id_fkey(id, name, avatar_url)", count="exact"
    ).eq("following_id", user_id).eq("status", "active")

    if connection_type:
        query = query.eq("connection_type", connection_type.value)

    if cursor:
        cursor_ts, cursor_id = cursor.split("|", 1)
        query = query.or_(f"created_at.lt.{cursor_ts},and(created_at.eq.{cursor_ts},id.lt.{cursor_id})")

    query = query.order("created_at", desc=True).limit(limit)
    result = query.execute()

    connections = []
    for row in result.data:
        conn_data = {**row}
        user_profile = None
        if row.get("users"):
            user_profile = {
                "id": row["users"]["id"],
                "name": row["users"].get("name", "Unknown"),
                "avatar_url": row["users"].get("avatar_url"),
            }
        conn_data["user_profile"] = user_profile
        connections.append(conn_data)

    next_cursor = None
    if connections and len(result.data) == limit:
        last = result.data[-1]
        next_cursor = f"{last['created_at']}|{last['id']}"

    return {
        "items": connections,
        "next_cursor": next_cursor,
        "has_more": next_cursor is not None,
        "total_count": result.count or 0,
    }


@router.get("/connections/following/{user_id}")
async def get_following(
    user_id: str,
    connection_type: Optional[ConnectionType] = None,
    cursor: Optional[str] = None,
    limit: int = Query(50, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """
    Get users that a user is following with cursor-based pagination.

    Args:
        user_id: User ID
        connection_type: Optional filter by connection type
        cursor: Pagination cursor (format: created_at_iso|id)
        limit: Max results per page (1-100, default 50)

    Returns:
        Paginated following connections with profile data
    """
    supabase = get_supabase_client()

    query = supabase.table("user_connections").select(
        "*, users!user_connections_following_id_fkey(id, name, avatar_url)", count="exact"
    ).eq("follower_id", user_id).eq("status", "active")

    if connection_type:
        query = query.eq("connection_type", connection_type.value)

    if cursor:
        cursor_ts, cursor_id = cursor.split("|", 1)
        query = query.or_(f"created_at.lt.{cursor_ts},and(created_at.eq.{cursor_ts},id.lt.{cursor_id})")

    query = query.order("created_at", desc=True).limit(limit)
    result = query.execute()

    connections = []
    for row in result.data:
        conn_data = {**row}
        user_profile = None
        if row.get("users"):
            user_profile = {
                "id": row["users"]["id"],
                "name": row["users"].get("name", "Unknown"),
                "avatar_url": row["users"].get("avatar_url"),
            }
        conn_data["user_profile"] = user_profile
        connections.append(conn_data)

    next_cursor = None
    if connections and len(result.data) == limit:
        last = result.data[-1]
        next_cursor = f"{last['created_at']}|{last['id']}"

    return {
        "items": connections,
        "next_cursor": next_cursor,
        "has_more": next_cursor is not None,
        "total_count": result.count or 0,
    }


@router.get("/connections/friends/{user_id}", response_model=List[UserProfile])
async def get_friends(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get mutual friends (users who follow each other).

    Args:
        user_id: User ID

    Returns:
        List of friend profiles
    """
    supabase = get_supabase_client()

    # Get friend IDs from the user_friends view (bounded)
    # Note: Views don't have foreign keys, so we query separately
    friends_result = supabase.table("user_friends").select(
        "friend_id"
    ).eq("user_id", user_id).limit(50).execute()

    if not friends_result.data:
        return []

    friend_ids = [row["friend_id"] for row in friends_result.data]

    # Get user profiles for the friend IDs
    users_result = supabase.table("users").select(
        "id, name, avatar_url"
    ).in_("id", friend_ids).execute()

    friends = []
    for row in users_result.data or []:
        friends.append(UserProfile(
            id=row["id"],
            name=row.get("name", "Unknown"),
            avatar_url=row.get("avatar_url"),
        ))

    return friends
