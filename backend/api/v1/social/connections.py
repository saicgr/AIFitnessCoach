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

from fastapi import APIRouter, HTTPException

from models.social import (
    UserConnection, UserConnectionCreate, UserConnectionWithProfile, UserProfile,
    ConnectionType,
)
from .utils import get_supabase_client

router = APIRouter()


@router.post("/connections", response_model=UserConnection)
async def create_connection(
    user_id: str,
    connection: UserConnectionCreate,
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
):
    """
    Delete a connection (unfollow someone).

    Args:
        user_id: ID of the user (follower)
        following_id: ID of the user to unfollow

    Returns:
        Success message
    """
    supabase = get_supabase_client()

    result = supabase.table("user_connections").delete().eq(
        "follower_id", user_id
    ).eq("following_id", following_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Connection not found")

    return {"message": "Connection deleted successfully"}


@router.get("/connections/followers/{user_id}", response_model=List[UserConnectionWithProfile])
async def get_followers(
    user_id: str,
    connection_type: Optional[ConnectionType] = None,
):
    """
    Get all followers for a user.

    Args:
        user_id: User ID
        connection_type: Optional filter by connection type

    Returns:
        List of followers with profile data
    """
    supabase = get_supabase_client()

    query = supabase.table("user_connections").select(
        "*, users!user_connections_follower_id_fkey(id, name, avatar_url)"
    ).eq("following_id", user_id).eq("status", "active")

    if connection_type:
        query = query.eq("connection_type", connection_type.value)

    result = query.execute()

    connections = []
    for row in result.data:
        conn = UserConnectionWithProfile(**row)
        if row.get("users"):
            conn.user_profile = UserProfile(
                id=row["users"]["id"],
                name=row["users"].get("name", "Unknown"),
                avatar_url=row["users"].get("avatar_url"),
            )
        connections.append(conn)

    return connections


@router.get("/connections/following/{user_id}", response_model=List[UserConnectionWithProfile])
async def get_following(
    user_id: str,
    connection_type: Optional[ConnectionType] = None,
):
    """
    Get all users that a user is following.

    Args:
        user_id: User ID
        connection_type: Optional filter by connection type

    Returns:
        List of following connections with profile data
    """
    supabase = get_supabase_client()

    query = supabase.table("user_connections").select(
        "*, users!user_connections_following_id_fkey(id, name, avatar_url)"
    ).eq("follower_id", user_id).eq("status", "active")

    if connection_type:
        query = query.eq("connection_type", connection_type.value)

    result = query.execute()

    connections = []
    for row in result.data:
        conn = UserConnectionWithProfile(**row)
        if row.get("users"):
            conn.user_profile = UserProfile(
                id=row["users"]["id"],
                name=row["users"].get("name", "Unknown"),
                avatar_url=row["users"].get("avatar_url"),
            )
        connections.append(conn)

    return connections


@router.get("/connections/friends/{user_id}", response_model=List[UserProfile])
async def get_friends(user_id: str):
    """
    Get mutual friends (users who follow each other).

    Args:
        user_id: User ID

    Returns:
        List of friend profiles
    """
    supabase = get_supabase_client()

    # Use the user_friends view created in migration
    result = supabase.table("user_friends").select(
        "friend_id, users!user_friends_friend_id_fkey(id, name, avatar_url)"
    ).eq("user_id", user_id).execute()

    friends = []
    for row in result.data:
        if row.get("users"):
            friends.append(UserProfile(
                id=row["users"]["id"],
                name=row["users"].get("name", "Unknown"),
                avatar_url=row["users"].get("avatar_url"),
            ))

    return friends
