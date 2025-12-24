"""
Pydantic models for leaderboard system.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class LeaderboardType(str, Enum):
    """Leaderboard type enum."""
    challenge_masters = "challenge_masters"  # Most challenge victories
    volume_kings = "volume_kings"  # Total weight lifted
    streaks = "streaks"  # Longest workout streaks
    weekly_challenges = "weekly_challenges"  # Challenges won this week


class LeaderboardFilter(str, Enum):
    """Leaderboard filter enum."""
    global_lb = "global"  # All users worldwide
    country = "country"  # Users in specific country
    friends = "friends"  # User's friends only


# ============================================================
# REQUEST MODELS
# ============================================================

class GetLeaderboardRequest(BaseModel):
    """Request to get leaderboard data."""
    leaderboard_type: LeaderboardType = Field(LeaderboardType.challenge_masters, description="Type of leaderboard")
    filter_type: LeaderboardFilter = Field(LeaderboardFilter.global_lb, description="Filter: global, country, or friends")
    country_code: Optional[str] = Field(None, max_length=10, description="ISO country code (e.g., US, GB, CA) - required if filter=country")
    limit: int = Field(100, ge=1, le=500, description="Number of entries to return (max 500)")
    offset: int = Field(0, ge=0, description="Offset for pagination")


class GetUserRankRequest(BaseModel):
    """Request to get user's rank in leaderboard."""
    leaderboard_type: LeaderboardType = Field(LeaderboardType.challenge_masters, description="Type of leaderboard")
    country_filter: Optional[str] = Field(None, max_length=10, description="Optional country filter")


# ============================================================
# RESPONSE MODELS
# ============================================================

class LeaderboardEntry(BaseModel):
    """Single entry in leaderboard."""
    rank: int
    user_id: str
    user_name: str
    avatar_url: Optional[str] = None
    country_code: Optional[str] = None

    # Stats (vary by leaderboard type)
    # Challenge Masters
    first_wins: Optional[int] = None
    win_rate: Optional[float] = None
    total_completed: Optional[int] = None

    # Volume Kings
    total_volume_lbs: Optional[float] = None
    total_workouts: Optional[int] = None
    avg_volume_per_workout: Optional[float] = None

    # Streaks
    current_streak: Optional[int] = None
    best_streak: Optional[int] = None
    last_workout_date: Optional[datetime] = None

    # Weekly Challenges
    weekly_wins: Optional[int] = None
    weekly_completed: Optional[int] = None
    weekly_win_rate: Optional[float] = None

    # Metadata
    is_friend: bool = False  # Is this user in requester's friends list?
    is_current_user: bool = False  # Is this the requesting user?

    class Config:
        from_attributes = True


class UserRank(BaseModel):
    """User's rank information."""
    user_id: str
    rank: int
    total_users: int
    percentile: float  # Top X% (e.g., 5.2 = top 5.2%)

    # User's stats for this leaderboard
    user_stats: LeaderboardEntry

    # Rank movement (if available)
    rank_change: Optional[int] = None  # +12 = moved up 12 ranks, -5 = moved down
    rank_change_period: Optional[str] = None  # "this week", "this month"


class LeaderboardResponse(BaseModel):
    """Response containing leaderboard data."""
    leaderboard_type: LeaderboardType
    filter_type: LeaderboardFilter
    country_code: Optional[str] = None

    # Entries
    entries: List[LeaderboardEntry]
    total_entries: int

    # Pagination
    limit: int
    offset: int
    has_more: bool

    # User's rank (if authenticated)
    user_rank: Optional[UserRank] = None

    # Metadata
    last_updated: datetime
    refreshes_in: Optional[str] = None  # "23 minutes", "1 hour"


class LeaderboardUnlockStatus(BaseModel):
    """User's leaderboard unlock status."""
    is_unlocked: bool
    workouts_completed: int
    workouts_needed: int
    days_active: int

    # Messages
    unlock_message: str  # "Complete 3 more workouts to unlock global leaderboard!"
    progress_percentage: float  # 70.0 = 70% progress


class LeaderboardStats(BaseModel):
    """Overall leaderboard statistics."""
    total_users: int
    total_countries: int
    top_country: Optional[str] = None  # Country with most users
    average_wins: float
    highest_streak: int
    total_volume_lifted: float  # Total across all users


# ============================================================
# CHALLENGE FROM LEADERBOARD
# ============================================================

class AsyncChallengeRequest(BaseModel):
    """Request to create async 'Beat Their Best' challenge from leaderboard."""
    target_user_id: str = Field(..., max_length=100, description="User to challenge")
    workout_log_id: Optional[str] = Field(None, max_length=100, description="Specific workout to beat (their best)")
    challenge_message: Optional[str] = Field("I'm coming for your record!", max_length=500, description="Challenge message")


class AsyncChallengeResponse(BaseModel):
    """Response after creating async challenge."""
    message: str
    challenge_created: bool
    target_user_name: str
    workout_name: str
    target_stats: dict  # Their stats to beat
    notification_sent: bool  # False for async (they only get notified if you beat it)
