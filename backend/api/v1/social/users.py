"""
User search and discovery API endpoints.

This module handles user search and suggestions:
- GET /users/search - Search users by name
- GET /users/suggestions - Get friend suggestions
- GET /users/{user_id}/profile - Get user profile for social display
"""
import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error

from models.friend_request import UserSearchResult, UserSuggestion
from .utils import get_supabase_client

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users")


def _get_blocked_user_ids(supabase, user_id: str) -> set:
    """Get all user IDs that are blocked by or have blocked the given user."""
    try:
        # Users I blocked
        blocker_result = supabase.table("user_blocks").select(
            "blocked_id"
        ).eq("blocker_id", user_id).execute()
        blocked_ids = {r["blocked_id"] for r in (blocker_result.data or [])}

        # Users who blocked me
        blocked_by_result = supabase.table("user_blocks").select(
            "blocker_id"
        ).eq("blocked_id", user_id).execute()
        blocked_ids.update(r["blocker_id"] for r in (blocked_by_result.data or []))

        return blocked_ids
    except Exception as e:
        logger.warning(f"[UserSearch] Failed to fetch blocked users: {e}", exc_info=True)
        return set()


@router.get("/search")
async def search_users(
    user_id: str = Query(..., description="Current user ID"),
    query: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(20, ge=1, le=50, description="Maximum results to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    current_user: dict = Depends(get_current_user),
):
    """
    Search users by name or username.

    Args:
        user_id: Current user's ID (to exclude from results)
        query: Search query string (searches name and username)
        limit: Maximum number of results
        offset: Offset for pagination

    Returns:
        Paginated list of matching users with relationship status
    """
    verify_user_ownership(current_user, user_id)
    if not query.strip():
        return {"results": [], "total_count": 0, "has_more": False}

    try:
        supabase = get_supabase_client()
        logger.info(f"🔍 [UserSearch] Searching for query='{query}' by user={user_id}")

        # Get blocked user IDs (F9)
        blocked_ids = _get_blocked_user_ids(supabase, user_id)

        # Search users by name OR username (case-insensitive)
        # Include bio in select fields (F6)
        result = supabase.table("users").select(
            "id, name, username, avatar_url, bio", count="exact"
        ).or_(f"name.ilike.%{query}%,username.ilike.%{query}%").range(
            offset, offset + limit - 1
        ).execute()

        total_count = result.count or 0

        logger.info(f"✅ [UserSearch] Found {len(result.data) if result.data else 0} users matching '{query}'")

        if not result.data:
            return {"results": [], "total_count": 0, "has_more": False}

        # Filter out blocked users
        filtered_data = [u for u in result.data if u["id"] not in blocked_ids]

        # Get current user's connections to determine relationship status
        user_ids = [u["id"] for u in filtered_data]

        if not user_ids:
            return {"results": [], "total_count": 0, "has_more": False}

        # Get connections where current user is follower
        following_result = supabase.table("user_connections").select(
            "following_id"
        ).eq("follower_id", user_id).in_("following_id", user_ids).execute()
        following_ids = {c["following_id"] for c in following_result.data}

        # Get connections where current user is being followed
        followers_result = supabase.table("user_connections").select(
            "follower_id"
        ).eq("following_id", user_id).in_("follower_id", user_ids).execute()
        follower_ids = {c["follower_id"] for c in followers_result.data}

        # Get pending friend requests
        pending_sent = supabase.table("friend_requests").select(
            "id, to_user_id"
        ).eq("from_user_id", user_id).eq("status", "pending").in_("to_user_id", user_ids).execute()
        pending_sent_map = {r["to_user_id"]: r["id"] for r in pending_sent.data}

        pending_received = supabase.table("friend_requests").select(
            "id, from_user_id"
        ).eq("to_user_id", user_id).eq("status", "pending").in_("from_user_id", user_ids).execute()
        pending_received_map = {r["from_user_id"]: r["id"] for r in pending_received.data}

        # Get privacy settings for users to check if they require approval
        privacy_result = supabase.table("user_privacy_settings").select(
            "user_id, require_follow_approval"
        ).in_("user_id", user_ids).execute()
        requires_approval = {p["user_id"]: p.get("require_follow_approval", False) for p in privacy_result.data}

        # Get workout counts per user using batch RPC
        counts_result = supabase.rpc("get_workout_counts", {"p_user_ids": user_ids}).execute()
        workout_counts = {row["user_id"]: row["workout_count"] for row in (counts_result.data or [])}

        # Build results - put self first if found
        results = []
        self_result = None
        for user in filtered_data:
            uid = user["id"]
            is_self = uid == user_id
            is_following = uid in following_ids
            is_follower = uid in follower_ids
            is_friend = is_following and is_follower

            # Check for pending requests in either direction
            has_pending = uid in pending_sent_map or uid in pending_received_map
            pending_id = pending_sent_map.get(uid) or pending_received_map.get(uid)

            search_result = UserSearchResult(
                id=uid,
                name=user.get("name", "Unknown"),
                username=user.get("username"),
                avatar_url=user.get("avatar_url"),
                bio=user.get("bio"),
                total_workouts=workout_counts.get(uid, 0),
                current_streak=0,  # Would need separate query for streak calculation
                is_following=is_following,
                is_follower=is_follower,
                is_friend=is_friend,
                is_self=is_self,
                has_pending_request=has_pending,
                pending_request_id=pending_id,
                requires_approval=requires_approval.get(uid, False),
            )

            if is_self:
                self_result = search_result
            else:
                results.append(search_result)

        # Put self at the beginning if found
        if self_result:
            results.insert(0, self_result)

        return {
            "results": [r.model_dump() if hasattr(r, 'model_dump') else r.dict() for r in results],
            "total_count": total_count,
            "has_more": offset + limit < total_count,
        }
    except Exception as e:
        logger.error(f"❌ [UserSearch] Error searching users for query '{query}': {e}", exc_info=True)
        # Return empty list but log the full error for debugging
        return {"results": [], "total_count": 0, "has_more": False}


@router.get("/suggestions")
async def get_friend_suggestions(
    user_id: str = Query(..., description="Current user ID"),
    limit: int = Query(10, ge=1, le=20, description="Maximum suggestions to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get friend suggestions based on mutual connections and activity.

    Args:
        user_id: Current user's ID
        limit: Maximum number of suggestions
        offset: Offset for pagination

    Returns:
        Paginated list of suggested users with reasons
    """
    verify_user_ownership(current_user, user_id)
    try:
        supabase = get_supabase_client()

        # Get blocked user IDs (F9)
        blocked_ids = _get_blocked_user_ids(supabase, user_id)

        # Get current user's following list
        following = supabase.table("user_connections").select(
            "following_id"
        ).eq("follower_id", user_id).execute()
        following_ids = {c["following_id"] for c in following.data}

        # Store original following ids (without self) for pending request check
        original_following_ids = following_ids.copy()
        following_ids.add(user_id)  # Exclude self from suggestions

        # Combine blocked + following for exclusion
        exclude_ids = following_ids | blocked_ids

        suggestions = []

        # Try to get suggestions based on mutual connections
        if original_following_ids:  # Only if user actually follows someone
            # Use RPC to get friend suggestions with mutual counts (server-side)
            suggestions_result = supabase.rpc("get_friend_suggestions_rpc", {
                "p_user_id": user_id,
                "p_limit": limit + len(blocked_ids) + offset  # fetch extra to account for filtering + offset
            }).execute()

            if suggestions_result.data:
                # Filter out blocked users
                filtered_suggestions = [
                    s for s in suggestions_result.data
                    if s["suggested_user_id"] not in blocked_ids
                ]

                # Apply pagination
                paginated = filtered_suggestions[offset:offset + limit]
                total_available = len(filtered_suggestions)

                suggestion_ids = [s["suggested_user_id"] for s in paginated]
                mutual_map = {s["suggested_user_id"]: s["mutual_count"] for s in paginated}

                if suggestion_ids:
                    # Get user profiles with bio (F6)
                    users = supabase.table("users").select(
                        "id, name, avatar_url, bio"
                    ).in_("id", suggestion_ids).execute()

                    # Get workout counts per user using batch RPC
                    counts_result = supabase.rpc("get_workout_counts", {"p_user_ids": suggestion_ids}).execute()
                    workout_counts = {row["user_id"]: row["workout_count"] for row in (counts_result.data or [])}

                    # Get privacy settings
                    privacy = supabase.table("user_privacy_settings").select(
                        "user_id, require_follow_approval"
                    ).in_("user_id", suggestion_ids).execute()
                    requires_approval = {p["user_id"]: p.get("require_follow_approval", False) for p in privacy.data}

                    # Get pending friend requests to these users
                    pending_sent = supabase.table("friend_requests").select(
                        "id, to_user_id"
                    ).eq("from_user_id", user_id).eq("status", "pending").in_("to_user_id", suggestion_ids).execute()
                    pending_sent_map = {r["to_user_id"]: r["id"] for r in pending_sent.data}

                    # Build user map for quick lookup
                    user_map = {u["id"]: u for u in users.data}

                    for uid in suggestion_ids:
                        if uid in user_map:
                            user = user_map[uid]
                            mutual_count = mutual_map.get(uid, 0)
                            has_pending = uid in pending_sent_map
                            suggestions.append(UserSuggestion(
                                id=uid,
                                name=user.get("name", "Unknown"),
                                avatar_url=user.get("avatar_url"),
                                bio=user.get("bio"),
                                total_workouts=workout_counts.get(uid, 0),
                                current_streak=0,
                                is_following=False,
                                is_follower=False,
                                is_friend=False,
                                has_pending_request=has_pending,
                                pending_request_id=pending_sent_map.get(uid),
                                requires_approval=requires_approval.get(uid, False),
                                suggestion_reason=f"{mutual_count} mutual friends",
                                mutual_friends_count=mutual_count,
                            ))

                    return {
                        "results": [s.model_dump() if hasattr(s, 'model_dump') else s.dict() for s in suggestions],
                        "total_count": total_available,
                        "has_more": offset + limit < total_available,
                    }

        # Fallback: Get active users if no mutual connections
        active_users = supabase.table("users").select(
            "id, name, avatar_url, bio"
        ).neq("id", user_id).limit(limit + offset + len(blocked_ids)).execute()

        if not active_users.data:
            return {"results": [], "total_count": 0, "has_more": False}

        # Filter out users already being followed and blocked users
        filtered_users = [u for u in active_users.data if u["id"] not in exclude_ids]
        total_available = len(filtered_users)

        # Apply pagination
        paginated_users = filtered_users[offset:offset + limit]

        if not paginated_users:
            return {"results": [], "total_count": 0, "has_more": False}

        user_ids = [u["id"] for u in paginated_users]

        # Get privacy settings (only if we have users)
        privacy = supabase.table("user_privacy_settings").select(
            "user_id, require_follow_approval"
        ).in_("user_id", user_ids).execute()
        requires_approval = {p["user_id"]: p.get("require_follow_approval", False) for p in privacy.data}

        # Get pending friend requests
        pending_sent = supabase.table("friend_requests").select(
            "id, to_user_id"
        ).eq("from_user_id", user_id).eq("status", "pending").in_("to_user_id", user_ids).execute()
        pending_sent_map = {r["to_user_id"]: r["id"] for r in pending_sent.data}

        # Get workout counts per user using batch RPC
        counts_result = supabase.rpc("get_workout_counts", {"p_user_ids": user_ids}).execute()
        workout_counts = {row["user_id"]: row["workout_count"] for row in (counts_result.data or [])}

        results = [
            UserSuggestion(
                id=u["id"],
                name=u.get("name", "Unknown"),
                avatar_url=u.get("avatar_url"),
                bio=u.get("bio"),
                total_workouts=workout_counts.get(u["id"], 0),
                current_streak=0,
                is_following=False,
                is_follower=False,
                is_friend=False,
                has_pending_request=u["id"] in pending_sent_map,
                pending_request_id=pending_sent_map.get(u["id"]),
                requires_approval=requires_approval.get(u["id"], False),
                suggestion_reason="Active on FitWiz",
                mutual_friends_count=0,
            )
            for u in paginated_users
        ]

        return {
            "results": [r.model_dump() if hasattr(r, 'model_dump') else r.dict() for r in results],
            "total_count": total_available,
            "has_more": offset + limit < total_available,
        }
    except Exception as e:
        # Log the error for debugging
        logger.error(f"Error getting friend suggestions for user {user_id}: {e}", exc_info=True)
        # Return empty list instead of failing
        return {"results": [], "total_count": 0, "has_more": False}


@router.get("/{target_user_id}/profile", response_model=UserSearchResult)
async def get_user_profile(
    target_user_id: str,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get a user's profile for social display.

    Args:
        target_user_id: ID of user to get profile for
        user_id: Current user's ID (to determine relationship)

    Returns:
        User profile with relationship status
    """
    verify_user_ownership(current_user, user_id)
    supabase = get_supabase_client()

    # Get user profile with bio (F6)
    result = supabase.table("users").select(
        "id, name, avatar_url, bio"
    ).eq("id", target_user_id).single().execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = result.data

    # Get relationship status
    is_following = False
    is_follower = False

    following_check = supabase.table("user_connections").select("id").eq(
        "follower_id", user_id
    ).eq("following_id", target_user_id).execute()
    is_following = bool(following_check.data)

    follower_check = supabase.table("user_connections").select("id").eq(
        "follower_id", target_user_id
    ).eq("following_id", user_id).execute()
    is_follower = bool(follower_check.data)

    # Check for pending requests
    pending_sent = supabase.table("friend_requests").select("id").eq(
        "from_user_id", user_id
    ).eq("to_user_id", target_user_id).eq("status", "pending").execute()

    pending_received = supabase.table("friend_requests").select("id").eq(
        "from_user_id", target_user_id
    ).eq("to_user_id", user_id).eq("status", "pending").execute()

    has_pending = bool(pending_sent.data) or bool(pending_received.data)
    pending_id = None
    if pending_sent.data:
        pending_id = pending_sent.data[0]["id"]
    elif pending_received.data:
        pending_id = pending_received.data[0]["id"]

    # Get privacy settings
    privacy = supabase.table("user_privacy_settings").select(
        "require_follow_approval"
    ).eq("user_id", target_user_id).execute()
    requires_approval = privacy.data[0].get("require_follow_approval", False) if privacy.data else False

    # Get workout count
    workout_count = supabase.table("workout_logs").select(
        "id", count="exact"
    ).eq("user_id", target_user_id).execute()

    return UserSearchResult(
        id=user["id"],
        name=user.get("name", "Unknown"),
        avatar_url=user.get("avatar_url"),
        bio=user.get("bio"),
        total_workouts=workout_count.count or 0,
        current_streak=0,
        is_following=is_following,
        is_follower=is_follower,
        is_friend=is_following and is_follower,
        has_pending_request=has_pending,
        pending_request_id=pending_id,
        requires_approval=requires_approval,
    )
