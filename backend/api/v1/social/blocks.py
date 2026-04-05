"""
User Blocks API endpoints (F9).

This module handles user blocking operations:
- POST / - Block a user
- DELETE /{blocked_id} - Unblock a user
- GET / - Get list of blocked users
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger

from .utils import get_supabase_client

logger = get_logger(__name__)

router = APIRouter()


@router.post("/")
async def block_user(
    user_id: str = Query(..., description="Current user ID"),
    blocked_id: str = Query(..., description="User ID to block"),
    reason: str = Query(None, description="Optional reason for blocking"),
    current_user: dict = Depends(get_current_user),
):
    """
    Block a user.

    Also removes any mutual friend connections and pending friend requests
    between the two users.

    Args:
        user_id: Current user's ID (blocker)
        blocked_id: User ID to block
        reason: Optional reason for blocking

    Returns:
        Success message
    """
    if user_id == blocked_id:
        raise HTTPException(status_code=400, detail="Cannot block yourself")

    try:
        supabase = get_supabase_client()

        # Insert block record (upsert to avoid duplicates)
        block_data = {
            "blocker_id": user_id,
            "blocked_id": blocked_id,
        }
        if reason:
            block_data["reason"] = reason

        supabase.table("user_blocks").upsert(
            block_data,
            on_conflict="blocker_id,blocked_id",
        ).execute()

        # Remove mutual friend connections (both directions)
        try:
            supabase.table("user_connections").delete().eq(
                "follower_id", user_id
            ).eq("following_id", blocked_id).execute()

            supabase.table("user_connections").delete().eq(
                "follower_id", blocked_id
            ).eq("following_id", user_id).execute()
        except Exception as e:
            logger.warning(f"[Blocks] Failed to remove connections on block: {e}")

        # Remove pending friend requests (both directions)
        try:
            supabase.table("friend_requests").delete().eq(
                "from_user_id", user_id
            ).eq("to_user_id", blocked_id).eq("status", "pending").execute()

            supabase.table("friend_requests").delete().eq(
                "from_user_id", blocked_id
            ).eq("to_user_id", user_id).eq("status", "pending").execute()
        except Exception as e:
            logger.warning(f"[Blocks] Failed to remove friend requests on block: {e}")

        logger.info(f"[Blocks] User {user_id} blocked user {blocked_id}")

        return {"message": "User blocked successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Blocks] Error blocking user: {e}")
        raise safe_internal_error(e, "blocks")


@router.delete("/{blocked_id}")
async def unblock_user(
    blocked_id: str,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Unblock a user.

    Args:
        blocked_id: User ID to unblock
        user_id: Current user's ID

    Returns:
        Success message
    """
    try:
        supabase = get_supabase_client()

        result = supabase.table("user_blocks").delete().eq(
            "blocker_id", user_id
        ).eq("blocked_id", blocked_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Block not found")

        logger.info(f"[Blocks] User {user_id} unblocked user {blocked_id}")

        return {"message": "User unblocked successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Blocks] Error unblocking user: {e}")
        raise safe_internal_error(e, "blocks")


@router.get("/")
async def get_blocked_users(
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get list of blocked users.

    Args:
        user_id: Current user's ID

    Returns:
        List of blocked users with basic profile info
    """
    try:
        supabase = get_supabase_client()

        result = supabase.table("user_blocks").select(
            "blocked_id, reason, created_at"
        ).eq("blocker_id", user_id).order("created_at", desc=True).execute()

        if not result.data:
            return {"blocked_users": []}

        # Get user profiles for blocked users
        blocked_ids = [r["blocked_id"] for r in result.data]
        users_result = supabase.table("users").select(
            "id, name, username, avatar_url"
        ).in_("id", blocked_ids).execute()

        user_map = {u["id"]: u for u in (users_result.data or [])}

        blocked_users = []
        for block in result.data:
            user = user_map.get(block["blocked_id"], {})
            blocked_users.append({
                "id": block["blocked_id"],
                "name": user.get("name", "Unknown"),
                "username": user.get("username"),
                "avatar_url": user.get("avatar_url"),
                "reason": block.get("reason"),
                "blocked_at": block["created_at"],
            })

        return {"blocked_users": blocked_users}

    except Exception as e:
        logger.error(f"[Blocks] Error getting blocked users: {e}")
        raise safe_internal_error(e, "blocks")
