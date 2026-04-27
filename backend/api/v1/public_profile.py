"""
Public profile pages — zealova.com/u/{username}.

Anonymous-readable. Reads `public_users_v` for header data, then aggregates
the user's currently-public workout shares and plan shares as a feed.

Followers/following are not exposed here (zero until social ships); the web
page renders 0/0 with a "Coming soon" tooltip.
"""
from typing import Any, Dict, List

from fastapi import APIRouter, HTTPException, Path, Query

from core.db import get_supabase_db
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


def _safe_select(query):
    """Wrap supabase-py .execute() so empty/missing results don't 500."""
    try:
        return query.execute()
    except Exception as exc:
        logger.warning("public_profile query failed: %s", exc)
        return None


@router.get("/{username}")
async def get_public_profile(
    username: str = Path(..., min_length=1, max_length=64),
    limit: int = Query(20, ge=1, le=100, description="Max recent shares to return"),
) -> Dict[str, Any]:
    """Return the public profile header + recent public shares feed."""
    db = get_supabase_db()

    profile_row = _safe_select(
        db.client.table("public_users_v")
        .select("*")
        .eq("username", username)
        .maybe_single()
    )
    profile = profile_row.data if profile_row else None
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    user_row = _safe_select(
        db.client.table("users")
        .select("id")
        .eq("username", username)
        .maybe_single()
    )
    user = user_row.data if user_row else None
    if not user:
        raise HTTPException(status_code=404, detail="Profile not found")

    user_id = user["id"]

    # Recent public single-workout shares
    workout_shares: List[Dict[str, Any]] = []
    w_rows = _safe_select(
        db.client.table("workouts")
        .select(
            "id,name,share_token,duration_minutes,estimated_calories,completed_at,scheduled_date"
        )
        .eq("user_id", user_id)
        .eq("is_completed", True)
        .not_.is_("share_token", "null")
        .order("completed_at", desc=True)
        .limit(limit)
    )
    for r in (w_rows.data or []) if w_rows else []:
        workout_shares.append(
            {
                "kind": "workout",
                "token": r["share_token"],
                "url_path": f"/w/{r['share_token']}",
                "name": r.get("name"),
                "duration_minutes": r.get("duration_minutes"),
                "estimated_calories": r.get("estimated_calories"),
                "completed_at": r.get("completed_at"),
                "scheduled_date": r.get("scheduled_date"),
            }
        )

    # Recent public plan/period shares
    plan_shares: List[Dict[str, Any]] = []
    p_rows = _safe_select(
        db.client.table("shared_plans")
        .select("share_token,scope,period,start_date,end_date,created_at")
        .eq("user_id", user_id)
        .is_("revoked_at", "null")
        .order("created_at", desc=True)
        .limit(limit)
    )
    for r in (p_rows.data or []) if p_rows else []:
        plan_shares.append(
            {
                "kind": "plan",
                "token": r["share_token"],
                "url_path": f"/p/{r['share_token']}",
                "scope": r.get("scope"),
                "period": r.get("period"),
                "start_date": r.get("start_date"),
                "end_date": r.get("end_date"),
                "created_at": r.get("created_at"),
            }
        )

    # Merge feed by recency. Workouts use completed_at; plans use created_at.
    feed = sorted(
        workout_shares + plan_shares,
        key=lambda x: x.get("completed_at") or x.get("created_at") or "",
        reverse=True,
    )[:limit]

    return {
        "username": profile["username"],
        "display_name": profile.get("display_name"),
        "avatar_url": profile.get("avatar_url"),
        "bio": profile.get("bio"),
        "joined_at": profile.get("joined_at"),
        "public_workout_count": profile.get("public_workout_count", 0),
        "public_plan_count": profile.get("public_plan_count", 0),
        # Static placeholders until social ships — frontend renders "Coming soon"
        "followers": 0,
        "following": 0,
        "feed": feed,
    }
