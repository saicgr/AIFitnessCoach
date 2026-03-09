"""
Hashtags API endpoints (F10).

This module handles hashtag operations:
- GET /trending - Get top hashtags by post count
- GET /search - Search hashtags by prefix
- GET /{name}/posts - Get paginated public posts with a specific hashtag
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger

from .utils import get_supabase_client

logger = get_logger(__name__)

router = APIRouter()


@router.get("/trending")
async def get_trending_hashtags(
    limit: int = Query(10, ge=1, le=50, description="Number of hashtags to return"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get top hashtags by post count.

    Args:
        limit: Maximum number of hashtags to return

    Returns:
        List of trending hashtags
    """
    try:
        supabase = get_supabase_client()

        result = supabase.table("hashtags").select(
            "id, name, post_count, created_at"
        ).gt("post_count", 0).order(
            "post_count", desc=True
        ).limit(limit).execute()

        return {"hashtags": result.data or []}

    except Exception as e:
        logger.error(f"[Hashtags] Error getting trending hashtags: {e}")
        raise safe_internal_error(e, "hashtags")


@router.get("/search")
async def search_hashtags(
    q: str = Query(..., min_length=1, description="Search prefix"),
    limit: int = Query(20, ge=1, le=50, description="Maximum results"),
    current_user: dict = Depends(get_current_user),
):
    """
    Search hashtags by prefix.

    Args:
        q: Search prefix (e.g., 'fit' matches 'fitness', 'fitfam')
        limit: Maximum number of results

    Returns:
        List of matching hashtags
    """
    try:
        supabase = get_supabase_client()

        # Search by prefix (case-insensitive)
        result = supabase.table("hashtags").select(
            "id, name, post_count"
        ).ilike("name", f"{q.lower()}%").order(
            "post_count", desc=True
        ).limit(limit).execute()

        return {"hashtags": result.data or []}

    except Exception as e:
        logger.error(f"[Hashtags] Error searching hashtags: {e}")
        raise safe_internal_error(e, "hashtags")


@router.get("/{name}/posts")
async def get_posts_by_hashtag(
    name: str,
    limit: int = Query(20, ge=1, le=50),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    """
    Get paginated public posts with a specific hashtag.

    Args:
        name: Hashtag name (without #)
        limit: Maximum posts to return
        offset: Pagination offset

    Returns:
        Paginated list of activity feed items with this hashtag
    """
    try:
        supabase = get_supabase_client()

        # Find the hashtag
        hashtag_result = supabase.table("hashtags").select(
            "id"
        ).eq("name", name.lower()).execute()

        if not hashtag_result.data:
            return {"posts": [], "total_count": 0, "has_more": False}

        hashtag_id = hashtag_result.data[0]["id"]

        # Get activity IDs with this hashtag
        links_result = supabase.table("activity_hashtags").select(
            "activity_id", count="exact"
        ).eq("hashtag_id", hashtag_id).range(offset, offset + limit - 1).execute()

        total_count = links_result.count or 0

        if not links_result.data:
            return {"posts": [], "total_count": total_count, "has_more": False}

        activity_ids = [r["activity_id"] for r in links_result.data]

        # Get activity feed items (public only)
        posts_result = supabase.table("activity_feed").select(
            "*, users:user_id(name, avatar_url)"
        ).in_("id", activity_ids).eq(
            "visibility", "public"
        ).order("created_at", desc=True).execute()

        # Parse results
        posts = []
        for row in (posts_result.data or []):
            user_info = row.pop("users", {}) or {}
            row["user_name"] = user_info.get("name")
            row["user_avatar"] = user_info.get("avatar_url")
            posts.append(row)

        return {
            "posts": posts,
            "total_count": total_count,
            "has_more": offset + limit < total_count,
        }

    except Exception as e:
        logger.error(f"[Hashtags] Error getting posts for hashtag '{name}': {e}")
        raise safe_internal_error(e, "hashtags")
