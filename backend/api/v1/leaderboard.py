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
from services.leaderboard_service import LeaderboardService

router = APIRouter(prefix="/leaderboard")
leaderboard_service = LeaderboardService()


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
    # Check unlock status (global leaderboard requires 10 workouts)
    unlock_status = leaderboard_service.check_unlock_status(user_id)
    is_unlocked = unlock_status.get("is_unlocked", False)

    if filter_type == LeaderboardFilter.global_lb and not is_unlocked:
        raise HTTPException(
            status_code=403,
            detail=f"Complete {unlock_status.get('workouts_needed', 10)} more workouts to unlock global leaderboard"
        )

    # Validate country filter
    if filter_type == LeaderboardFilter.country and not country_code:
        raise HTTPException(status_code=400, detail="country_code required for country filter")

    # Get leaderboard entries from service
    result = leaderboard_service.get_leaderboard_entries(
        leaderboard_type=leaderboard_type,
        filter_type=filter_type,
        user_id=user_id,
        country_code=country_code,
        limit=limit,
        offset=offset,
    )

    entries_data = result["entries"]
    total_entries = result["total"]

    # Handle empty results
    if not entries_data:
        return LeaderboardResponse(
            leaderboard_type=leaderboard_type,
            filter_type=filter_type,
            country_code=country_code,
            entries=[],
            total_entries=0,
            limit=limit,
            offset=offset,
            has_more=False,
            last_updated=datetime.now(timezone.utc),
        )

    # Get friend IDs for flags
    friend_ids_set = set(leaderboard_service._get_friend_ids(user_id))

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
    user_rank_data = leaderboard_service.get_user_rank(
        user_id=user_id,
        leaderboard_type=leaderboard_type,
        country_filter=country_code if filter_type == LeaderboardFilter.country else None,
    )

    user_rank = None
    if user_rank_data:
        rank_info = user_rank_data["rank_info"]
        stats = user_rank_data["stats"]
        user_stats = _build_leaderboard_entry(stats, rank_info["rank"], leaderboard_type, False, True)
        user_rank = UserRank(
            user_id=user_id,
            rank=rank_info["rank"],
            total_users=rank_info["total_users"],
            percentile=rank_info["percentile"],
            user_stats=user_stats,
        )

    # Calculate refresh time
    last_updated = entries_data[0].get("last_updated", datetime.now(timezone.utc))
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
    result = leaderboard_service.get_user_rank(
        user_id=user_id,
        leaderboard_type=leaderboard_type,
        country_filter=country_filter,
    )

    if not result:
        raise HTTPException(status_code=404, detail="User rank not found")

    rank_info = result["rank_info"]
    stats = result["stats"]

    user_stats = _build_leaderboard_entry(
        stats, rank_info["rank"], leaderboard_type, False, True
    )

    return UserRank(
        user_id=user_id,
        rank=rank_info["rank"],
        total_users=rank_info["total_users"],
        percentile=rank_info["percentile"],
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
    data = leaderboard_service.check_unlock_status(user_id)

    is_unlocked = data["is_unlocked"]
    workouts_completed = data["workouts_completed"]
    workouts_needed = data["workouts_needed"]
    days_active = data.get("days_active", 0)

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
    stats = leaderboard_service.get_leaderboard_stats()

    return LeaderboardStats(
        total_users=stats["total_users"],
        total_countries=stats["total_countries"],
        top_country=stats["top_country"],
        average_wins=stats["average_wins"],
        highest_streak=stats["highest_streak"],
        total_volume_lifted=stats["total_volume_lifted"],
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
    try:
        result = leaderboard_service.create_async_challenge(
            user_id=user_id,
            target_user_id=request.target_user_id,
            workout_log_id=request.workout_log_id,
            challenge_message=request.challenge_message,
        )

        return AsyncChallengeResponse(
            message="Challenge created! Beat their record and they'll be notified!",
            challenge_created=True,
            target_user_name=result["target_user_name"],
            workout_name=result["workout_name"],
            target_stats=result["target_stats"],
            notification_sent=False,  # Only notified if you beat it
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create challenge: {str(e)}")


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
