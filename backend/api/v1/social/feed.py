"""
Activity feed API endpoints.

This module handles activity feed operations:
- GET /feed/{user_id} - Get activity feed for a user
- POST /feed - Create a new activity
- DELETE /feed/{activity_id} - Delete an activity
"""
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from models.social import (
    ActivityFeedItem, ActivityFeedItemCreate, ActivityFeedResponse, ActivityType,
)
from services.social_rag_service import get_social_rag_service
from .utils import get_supabase_client

router = APIRouter()


@router.get("/feed/{user_id}", response_model=ActivityFeedResponse)
async def get_activity_feed(
    user_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    activity_type: Optional[ActivityType] = None,
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
    supabase = get_supabase_client()

    # Get user's following list
    following_result = supabase.table("user_connections").select("following_id").eq(
        "follower_id", user_id
    ).eq("status", "active").execute()

    following_ids = [row["following_id"] for row in following_result.data]
    following_ids.append(user_id)  # Include user's own activities

    # Build query
    query = supabase.table("activity_feed").select(
        "*, users(name, avatar_url)",
        count="exact"
    ).in_("user_id", following_ids).order("created_at", desc=True)

    if activity_type:
        query = query.eq("activity_type", activity_type.value)

    # Apply pagination
    offset = (page - 1) * page_size
    query = query.range(offset, offset + page_size - 1)

    result = query.execute()

    # Parse activities
    activities = []
    for row in result.data:
        activity = ActivityFeedItem(**row)
        if row.get("users"):
            activity.user_name = row["users"].get("name")
            activity.user_avatar = row["users"].get("avatar_url")
        activities.append(activity)

    total_count = result.count or 0

    return ActivityFeedResponse(
        items=activities,
        total_count=total_count,
        page=page,
        page_size=page_size,
        has_more=offset + page_size < total_count,
    )


@router.post("/feed", response_model=ActivityFeedItem)
async def create_activity(
    user_id: str,
    activity: ActivityFeedItemCreate,
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

    # Store in ChromaDB for AI context
    try:
        # Get user name
        user_result = supabase.table("users").select("name").eq("id", user_id).execute()
        user_name = user_result.data[0]["name"] if user_result.data else "User"

        social_rag = get_social_rag_service()
        social_rag.add_activity_to_rag(
            activity_id=activity_item.id,
            user_id=user_id,
            user_name=user_name,
            activity_type=activity.activity_type.value,
            activity_data=activity.activity_data,
            visibility=activity.visibility.value,
            created_at=activity_item.created_at,
        )
        print(f"[Social] Activity {activity_item.id} saved to ChromaDB")
    except Exception as e:
        # Non-critical - don't fail the request if ChromaDB fails
        print(f"[Social] Failed to save activity to ChromaDB: {e}")

    return activity_item


@router.delete("/feed/{activity_id}")
async def delete_activity(
    user_id: str,
    activity_id: str,
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

    # Remove from ChromaDB
    try:
        social_rag = get_social_rag_service()
        social_rag.delete_activity_from_rag(activity_id)
    except Exception as e:
        print(f"[Social] Failed to remove activity from ChromaDB: {e}")

    return {"message": "Activity deleted successfully"}
