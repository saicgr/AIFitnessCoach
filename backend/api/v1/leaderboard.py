"""
API endpoints for leaderboard system.

Endpoints:
- GET /leaderboard - Get leaderboard data
- GET /rank - Get user's rank
- GET /unlock-status - Check if user has unlocked leaderboard
- GET /stats - Get overall leaderboard statistics
- POST /async-challenge - Create async "Beat Their Best" challenge
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from datetime import datetime, timezone, timedelta

from models.leaderboard import (
    GetLeaderboardRequest, GetUserRankRequest,
    LeaderboardEntry, UserRank, LeaderboardResponse,
    LeaderboardUnlockStatus, LeaderboardStats,
    AsyncChallengeRequest, AsyncChallengeResponse,
    LeaderboardType, LeaderboardFilter,
)
from utils.supabase_client import get_supabase_client
from services.social_rag_service import get_social_rag_service

router = APIRouter(prefix="/leaderboard")


# ============================================================
# GET LEADERBOARD
# ============================================================

@router.get("/", response_model=LeaderboardResponse)
async def get_leaderboard(
    user_id: str,
    leaderboard_type: LeaderboardType = Query(LeaderboardType.challenge_masters),
    filter_type: LeaderboardFilter = Query(LeaderboardFilter.global_lb),
    country_code: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    """
    Get leaderboard data with filtering and pagination.

    Args:
        user_id: Requesting user ID (for friend filtering and rank display)
        leaderboard_type: Type of leaderboard (challenge_masters, volume_kings, etc.)
        filter_type: Filter (global, country, friends)
        country_code: ISO country code (required if filter=country)
        limit: Number of entries to return
        offset: Offset for pagination

    Returns:
        Leaderboard data with user's rank
    """
    supabase = get_supabase_client()

    # Check if user has unlocked global leaderboard
    unlock_result = supabase.rpc("check_leaderboard_unlock", {"p_user_id": user_id}).execute()
    unlock_status = unlock_result.data[0] if unlock_result.data else {}
    is_unlocked = unlock_status.get("is_unlocked", False)

    # If global leaderboard not unlocked, only allow friends filter
    if filter_type == LeaderboardFilter.global_lb and not is_unlocked:
        raise HTTPException(
            status_code=403,
            detail=f"Complete {unlock_status.get('workouts_needed', 10)} more workouts to unlock global leaderboard"
        )

    # Select appropriate materialized view
    view_name = {
        LeaderboardType.challenge_masters: "leaderboard_challenge_masters",
        LeaderboardType.volume_kings: "leaderboard_volume_kings",
        LeaderboardType.streaks: "leaderboard_streaks",
        LeaderboardType.weekly_challenges: "leaderboard_weekly_challenges",
    }[leaderboard_type]

    # Build query based on filter type
    if filter_type == LeaderboardFilter.friends:
        # Get user's friends
        friends_result = supabase.table("connections").select("friend_id").eq(
            "user_id", user_id
        ).eq("status", "accepted").execute()
        friend_ids = [f["friend_id"] for f in friends_result.data] if friends_result.data else []

        if not friend_ids:
            # No friends, return empty leaderboard
            return LeaderboardResponse(
                leaderboard_type=leaderboard_type,
                filter_type=filter_type,
                entries=[],
                total_entries=0,
                limit=limit,
                offset=offset,
                has_more=False,
                last_updated=datetime.now(timezone.utc),
            )

        # Query friends only
        query = supabase.table(view_name).select("*").in_("user_id", friend_ids)

    elif filter_type == LeaderboardFilter.country:
        # Validate country_code
        if not country_code:
            raise HTTPException(status_code=400, detail="country_code required for country filter")

        # Query specific country
        query = supabase.table(view_name).select("*").eq("country_code", country_code)

    else:  # Global
        # Query all users
        query = supabase.table(view_name).select("*")

    # Get total count
    count_result = query.execute()
    total_entries = len(count_result.data) if count_result.data else 0

    # Apply pagination and ordering
    entries_result = query.order(
        _get_order_column(leaderboard_type), desc=True
    ).range(offset, offset + limit - 1).execute()

    entries_data = entries_result.data if entries_result.data else []

    # Get friend IDs for is_friend flag
    friends_result = supabase.table("connections").select("friend_id").eq(
        "user_id", user_id
    ).eq("status", "accepted").execute()
    friend_ids_set = set([f["friend_id"] for f in friends_result.data]) if friends_result.data else set()

    # Convert to LeaderboardEntry models
    entries = []
    for idx, entry in enumerate(entries_data):
        rank = offset + idx + 1
        is_friend = entry["user_id"] in friend_ids_set
        is_current_user = entry["user_id"] == user_id

        entries.append(_build_leaderboard_entry(
            entry, rank, leaderboard_type, is_friend, is_current_user
        ))

    # Get user's rank
    user_rank = await _get_user_rank(
        user_id, leaderboard_type, country_code if filter_type == LeaderboardFilter.country else None
    )

    # Calculate refresh time
    last_updated = entries_data[0]["last_updated"] if entries_data else datetime.now(timezone.utc)
    if isinstance(last_updated, str):
        last_updated = datetime.fromisoformat(last_updated.replace("Z", "+00:00"))

    refreshes_in = _calculate_refresh_time(last_updated)

    return LeaderboardResponse(
        leaderboard_type=leaderboard_type,
        filter_type=filter_type,
        country_code=country_code,
        entries=entries,
        total_entries=total_entries,
        limit=limit,
        offset=offset,
        has_more=(offset + limit) < total_entries,
        user_rank=user_rank,
        last_updated=last_updated,
        refreshes_in=refreshes_in,
    )


# ============================================================
# GET USER RANK
# ============================================================

@router.get("/rank", response_model=UserRank)
async def get_user_rank(
    user_id: str,
    leaderboard_type: LeaderboardType = Query(LeaderboardType.challenge_masters),
    country_filter: Optional[str] = Query(None),
):
    """
    Get user's rank in specified leaderboard.

    Args:
        user_id: User ID
        leaderboard_type: Type of leaderboard
        country_filter: Optional country filter

    Returns:
        User's rank and stats
    """
    return await _get_user_rank(user_id, leaderboard_type, country_filter)


async def _get_user_rank(
    user_id: str,
    leaderboard_type: LeaderboardType,
    country_filter: Optional[str] = None,
) -> Optional[UserRank]:
    """Internal helper to get user rank."""
    supabase = get_supabase_client()

    # Call database function
    rank_result = supabase.rpc("get_user_leaderboard_rank", {
        "p_user_id": user_id,
        "p_leaderboard_type": leaderboard_type.value,
        "p_country_filter": country_filter,
    }).execute()

    if not rank_result.data:
        return None

    rank_data = rank_result.data[0]

    # Get user's stats from appropriate view
    view_name = {
        LeaderboardType.challenge_masters: "leaderboard_challenge_masters",
        LeaderboardType.volume_kings: "leaderboard_volume_kings",
        LeaderboardType.streaks: "leaderboard_streaks",
        LeaderboardType.weekly_challenges: "leaderboard_weekly_challenges",
    }[leaderboard_type]

    user_stats_result = supabase.table(view_name).select("*").eq("user_id", user_id).execute()
    user_stats_data = user_stats_result.data[0] if user_stats_result.data else None

    if not user_stats_data:
        return None

    # Build user stats entry
    user_stats = _build_leaderboard_entry(
        user_stats_data, rank_data["rank"], leaderboard_type, False, True
    )

    return UserRank(
        user_id=user_id,
        rank=rank_data["rank"],
        total_users=rank_data["total_users"],
        percentile=rank_data["percentile"],
        user_stats=user_stats,
    )


# ============================================================
# GET UNLOCK STATUS
# ============================================================

@router.get("/unlock-status", response_model=LeaderboardUnlockStatus)
async def get_unlock_status(user_id: str):
    """
    Check if user has unlocked global leaderboard.

    Args:
        user_id: User ID

    Returns:
        Unlock status and progress
    """
    supabase = get_supabase_client()

    result = supabase.rpc("check_leaderboard_unlock", {"p_user_id": user_id}).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")

    data = result.data[0]

    is_unlocked = data["is_unlocked"]
    workouts_completed = data["workouts_completed"]
    workouts_needed = data["workouts_needed"]
    days_active = data["days_active"]

    # Create unlock message
    if is_unlocked:
        unlock_message = "🏆 Global leaderboard unlocked!"
    elif workouts_needed > 0:
        unlock_message = f"Complete {workouts_needed} more workout{'s' if workouts_needed > 1 else ''} to unlock global leaderboard!"
    else:
        unlock_message = "Keep going! Almost there!"

    # Calculate progress percentage
    progress = min((workouts_completed / 10) * 100, 100)

    return LeaderboardUnlockStatus(
        is_unlocked=is_unlocked,
        workouts_completed=workouts_completed,
        workouts_needed=workouts_needed,
        days_active=days_active,
        unlock_message=unlock_message,
        progress_percentage=round(progress, 1),
    )


# ============================================================
# GET LEADERBOARD STATS
# ============================================================

@router.get("/stats", response_model=LeaderboardStats)
async def get_leaderboard_stats():
    """
    Get overall leaderboard statistics.

    Returns:
        Aggregate stats across all leaderboards
    """
    supabase = get_supabase_client()

    # Get stats from different views
    masters_result = supabase.table("leaderboard_challenge_masters").select("country_code, first_wins").execute()
    volume_result = supabase.table("leaderboard_volume_kings").select("total_volume_lbs").execute()
    streaks_result = supabase.table("leaderboard_streaks").select("best_streak").execute()

    masters_data = masters_result.data if masters_result.data else []
    volume_data = volume_result.data if volume_result.data else []
    streaks_data = streaks_result.data if streaks_result.data else []

    # Calculate stats
    total_users = len(masters_data)
    countries = set(entry["country_code"] for entry in masters_data if entry.get("country_code"))
    total_countries = len(countries)

    # Top country (most users)
    country_counts = {}
    for entry in masters_data:
        cc = entry.get("country_code")
        if cc:
            country_counts[cc] = country_counts.get(cc, 0) + 1

    top_country = max(country_counts.items(), key=lambda x: x[1])[0] if country_counts else None

    # Average wins
    total_wins = sum(entry.get("first_wins", 0) for entry in masters_data)
    average_wins = (total_wins / total_users) if total_users > 0 else 0

    # Highest streak
    highest_streak = max((entry.get("best_streak", 0) for entry in streaks_data), default=0)

    # Total volume
    total_volume = sum(entry.get("total_volume_lbs", 0) for entry in volume_data)

    return LeaderboardStats(
        total_users=total_users,
        total_countries=total_countries,
        top_country=top_country,
        average_wins=round(average_wins, 1),
        highest_streak=highest_streak,
        total_volume_lifted=round(total_volume, 0),
    )


# ============================================================
# CREATE ASYNC CHALLENGE (Beat Their Best)
# ============================================================

@router.post("/async-challenge", response_model=AsyncChallengeResponse)
async def create_async_challenge(
    user_id: str,
    request: AsyncChallengeRequest,
):
    """
    Create async 'Beat Their Best' challenge from leaderboard.

    This creates a challenge WITHOUT notifying the target user.
    They only get notified IF you beat their record.

    Args:
        user_id: Challenging user ID
        request: Challenge details

    Returns:
        Challenge created confirmation
    """
    supabase = get_supabase_client()
    social_rag = get_social_rag_service()

    # Get target user info
    target_user_result = supabase.table("users").select("name").eq("id", request.target_user_id).execute()
    if not target_user_result.data:
        raise HTTPException(status_code=404, detail="Target user not found")

    target_user_name = target_user_result.data[0]["name"]

    # Get their best workout (if workout_log_id not specified, find their best)
    if request.workout_log_id:
        workout_result = supabase.table("workout_logs").select("*").eq(
            "id", request.workout_log_id
        ).eq("user_id", request.target_user_id).execute()

        if not workout_result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout_data = workout_result.data[0]
    else:
        # Find their best workout (highest total volume)
        best_workout_result = supabase.table("workout_logs").select("*").eq(
            "user_id", request.target_user_id
        ).order("performance_data->total_volume", desc=True).limit(1).execute()

        if not best_workout_result.data:
            raise HTTPException(status_code=404, detail="No workouts found for this user")

        workout_data = best_workout_result.data[0]

    # Extract workout stats
    performance_data = workout_data.get("performance_data", {})
    target_stats = {
        "duration_minutes": performance_data.get("duration_minutes", 0),
        "total_volume": performance_data.get("total_volume", 0),
        "exercises_count": performance_data.get("exercises_count", 0),
    }

    # Create challenge (marked as async, no notification yet)
    challenge_data = {
        "from_user_id": user_id,
        "to_user_id": request.target_user_id,
        "workout_log_id": workout_data["id"],
        "workout_name": workout_data.get("workout_name", "Their Best Workout"),
        "workout_data": target_stats,
        "challenge_message": request.challenge_message,
        "status": "accepted",  # Auto-accept (async challenge)
        "accepted_at": datetime.now(timezone.utc).isoformat(),
        "challenger_stats": target_stats,  # Their stats
    }

    challenge_result = supabase.table("workout_challenges").insert(challenge_data).execute()

    if not challenge_result.data:
        raise HTTPException(status_code=500, detail="Failed to create challenge")

    challenge_id = challenge_result.data[0]["id"]

    # Log to ChromaDB (async challenge, different from normal challenges)
    try:
        challenger_result = supabase.table("users").select("name").eq("id", user_id).execute()
        challenger_name = challenger_result.data[0]["name"] if challenger_result.data else "User"

        collection = social_rag.get_social_collection()
        collection.add(
            documents=[f"{challenger_name} is attempting to BEAT {target_user_name}'s best workout '{workout_data.get('workout_name')}' (ASYNC challenge)"],
            metadatas=[{
                "from_user_id": user_id,
                "to_user_id": request.target_user_id,
                "challenge_id": challenge_id,
                "interaction_type": "async_challenge_created",
                "workout_name": workout_data.get("workout_name"),
                "is_async": True,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }],
            ids=[f"async_challenge_{challenge_id}"],
        )
        print(f"🏆 [Leaderboard] Async challenge logged: {challenger_name} vs {target_user_name}")
    except Exception as e:
        print(f"⚠️ [Leaderboard] Failed to log to ChromaDB: {e}")

    return AsyncChallengeResponse(
        message="Challenge created! Beat their record and they'll be notified!",
        challenge_created=True,
        target_user_name=target_user_name,
        workout_name=workout_data.get("workout_name", "Their Best Workout"),
        target_stats=target_stats,
        notification_sent=False,  # Only notified if you beat it
    )


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def _get_order_column(leaderboard_type: LeaderboardType) -> str:
    """Get the primary ordering column for leaderboard type."""
    return {
        LeaderboardType.challenge_masters: "first_wins",
        LeaderboardType.volume_kings: "total_volume_lbs",
        LeaderboardType.streaks: "best_streak",
        LeaderboardType.weekly_challenges: "weekly_wins",
    }[leaderboard_type]


def _build_leaderboard_entry(
    data: dict,
    rank: int,
    leaderboard_type: LeaderboardType,
    is_friend: bool,
    is_current_user: bool,
) -> LeaderboardEntry:
    """Build LeaderboardEntry from database row."""
    entry = LeaderboardEntry(
        rank=rank,
        user_id=data["user_id"],
        user_name=data["user_name"],
        avatar_url=data.get("avatar_url"),
        country_code=data.get("country_code"),
        is_friend=is_friend,
        is_current_user=is_current_user,
    )

    # Add type-specific stats
    if leaderboard_type == LeaderboardType.challenge_masters:
        entry.first_wins = data.get("first_wins", 0)
        entry.win_rate = data.get("win_rate", 0.0)
        entry.total_completed = data.get("total_completed", 0)
    elif leaderboard_type == LeaderboardType.volume_kings:
        entry.total_volume_lbs = data.get("total_volume_lbs", 0.0)
        entry.total_workouts = data.get("total_workouts", 0)
        entry.avg_volume_per_workout = data.get("avg_volume_per_workout", 0.0)
    elif leaderboard_type == LeaderboardType.streaks:
        entry.current_streak = data.get("current_streak", 0)
        entry.best_streak = data.get("best_streak", 0)
        entry.last_workout_date = data.get("last_workout_date")
    elif leaderboard_type == LeaderboardType.weekly_challenges:
        entry.weekly_wins = data.get("weekly_wins", 0)
        entry.weekly_completed = data.get("weekly_completed", 0)
        entry.weekly_win_rate = data.get("weekly_win_rate", 0.0)

    return entry


def _calculate_refresh_time(last_updated: datetime) -> str:
    """Calculate when leaderboard refreshes next."""
    # Leaderboards refresh every hour
    next_refresh = last_updated + timedelta(hours=1)
    now = datetime.now(timezone.utc)
    delta = next_refresh - now

    if delta.total_seconds() < 60:
        return f"{int(delta.total_seconds())} seconds"
    elif delta.total_seconds() < 3600:
        return f"{int(delta.total_seconds() / 60)} minutes"
    else:
        return f"{int(delta.total_seconds() / 3600)} hours"
