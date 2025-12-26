"""
Pydantic models for AI goal suggestions, shared goals, and goal invites.
"""
from datetime import datetime, date
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, field_validator


class SuggestionType(str, Enum):
    """Type of goal suggestion."""
    PERFORMANCE_BASED = "performance_based"
    SCHEDULE_BASED = "schedule_based"
    POPULAR_WITH_FRIENDS = "popular_with_friends"
    NEW_CHALLENGE = "new_challenge"


class SuggestionCategory(str, Enum):
    """Display category for suggestions."""
    BEAT_YOUR_RECORDS = "beat_your_records"
    POPULAR_WITH_FRIENDS = "popular_with_friends"
    NEW_CHALLENGES = "new_challenges"


class GoalType(str, Enum):
    """Type of personal goal."""
    SINGLE_MAX = "single_max"
    WEEKLY_VOLUME = "weekly_volume"


class GoalVisibility(str, Enum):
    """Visibility setting for goals."""
    PRIVATE = "private"
    FRIENDS = "friends"
    PUBLIC = "public"


class InviteStatus(str, Enum):
    """Status of a goal invite."""
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    EXPIRED = "expired"


class SharedGoalStatus(str, Enum):
    """Status of a shared goal."""
    ACTIVE = "active"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


# ============================================================================
# Friend Preview Models
# ============================================================================

class FriendPreview(BaseModel):
    """Basic friend info for display."""
    user_id: str
    name: str
    avatar_url: Optional[str] = None


class FriendGoalProgress(BaseModel):
    """Friend's progress on a goal for leaderboard display."""
    user_id: str
    name: str
    avatar_url: Optional[str] = None
    current_value: int
    target_value: int
    progress_percentage: float
    is_pr_beaten: bool = False
    rank: int = 0


# ============================================================================
# Goal Suggestion Models
# ============================================================================

class GoalSuggestionBase(BaseModel):
    """Base model for goal suggestion."""
    exercise_name: str = Field(..., min_length=1, max_length=255)
    goal_type: GoalType
    suggested_target: int = Field(..., gt=0, le=10000)
    reasoning: str = Field(..., min_length=1)


class GoalSuggestionCreate(GoalSuggestionBase):
    """Model for creating a goal suggestion (internal use)."""
    suggestion_type: SuggestionType
    category: SuggestionCategory
    confidence_score: float = Field(default=0.8, ge=0, le=1)
    source_data: Optional[Dict[str, Any]] = None
    priority_rank: int = 0


class GoalSuggestionItem(GoalSuggestionBase):
    """Individual goal suggestion for API response."""
    id: str
    suggestion_type: SuggestionType
    category: SuggestionCategory
    confidence_score: float
    source_data: Optional[Dict[str, Any]] = None
    friends_on_goal: Optional[List[FriendPreview]] = None
    friends_count: int = 0
    created_at: datetime
    expires_at: datetime

    class Config:
        from_attributes = True


class SuggestionCategoryGroup(BaseModel):
    """A category of suggestions for display."""
    category_id: str
    category_title: str
    category_icon: str
    accent_color: str
    suggestions: List[GoalSuggestionItem]


class GoalSuggestionsResponse(BaseModel):
    """Response containing all goal suggestions organized by category."""
    categories: List[SuggestionCategoryGroup]
    generated_at: datetime
    expires_at: datetime
    total_suggestions: int


class DismissSuggestionRequest(BaseModel):
    """Request to dismiss a suggestion."""
    reason: Optional[str] = None


class AcceptSuggestionRequest(BaseModel):
    """Request to accept a suggestion and create a goal."""
    target_override: Optional[int] = Field(None, gt=0, le=10000)
    visibility: GoalVisibility = GoalVisibility.FRIENDS


# ============================================================================
# Shared Goal Models
# ============================================================================

class SharedGoalBase(BaseModel):
    """Base model for shared goals."""
    original_goal_id: str
    source_user_id: str
    joined_user_id: str


class SharedGoalCreate(SharedGoalBase):
    """Model for creating a shared goal record."""
    joined_goal_id: Optional[str] = None


class SharedGoal(SharedGoalBase):
    """Full shared goal model."""
    id: str
    joined_goal_id: Optional[str] = None
    status: SharedGoalStatus = SharedGoalStatus.ACTIVE
    joined_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Goal Invite Models
# ============================================================================

class GoalInviteBase(BaseModel):
    """Base model for goal invites."""
    goal_id: str
    invitee_id: str
    message: Optional[str] = Field(None, max_length=500)


class GoalInviteCreate(GoalInviteBase):
    """Request to create a goal invite."""
    pass


class GoalInvite(BaseModel):
    """Full goal invite model."""
    id: str
    goal_id: str
    inviter_id: str
    invitee_id: str
    status: InviteStatus = InviteStatus.PENDING
    message: Optional[str] = None
    created_at: datetime
    responded_at: Optional[datetime] = None
    expires_at: datetime

    class Config:
        from_attributes = True


class GoalInviteWithDetails(GoalInvite):
    """Goal invite with expanded goal and user details."""
    goal_exercise_name: str
    goal_type: GoalType
    goal_target_value: int
    inviter_name: str
    inviter_avatar_url: Optional[str] = None
    inviter_current_value: int = 0
    inviter_progress_percentage: float = 0


class InviteResponseRequest(BaseModel):
    """Request to respond to a goal invite."""
    accept: bool


class GoalInviteResponse(BaseModel):
    """Response after handling invite."""
    invite: GoalInvite
    created_goal_id: Optional[str] = None  # If accepted, the new goal created


# ============================================================================
# Goal Friends Models
# ============================================================================

class GoalFriendsRequest(BaseModel):
    """Request parameters for getting friends on a goal."""
    exercise_name: str
    goal_type: GoalType


class GoalFriendsResponse(BaseModel):
    """Response with friends doing the same goal."""
    goal_id: str
    exercise_name: str
    goal_type: GoalType
    week_start: date
    friend_entries: List[FriendGoalProgress]
    total_friends_count: int
    user_rank: int = 0
    user_progress_percentage: float = 0


# ============================================================================
# Goal Leaderboard Models
# ============================================================================

class GoalLeaderboardEntry(BaseModel):
    """Single entry in goal leaderboard."""
    rank: int
    user_id: str
    name: str
    avatar_url: Optional[str] = None
    current_value: int
    target_value: int
    progress_percentage: float
    is_pr_beaten: bool = False
    is_current_user: bool = False


class GoalLeaderboardResponse(BaseModel):
    """Full leaderboard for a goal."""
    exercise_name: str
    goal_type: GoalType
    week_start: date
    entries: List[GoalLeaderboardEntry]
    total_participants: int
    current_user_rank: Optional[int] = None


# ============================================================================
# Summary Models
# ============================================================================

class GoalSuggestionsSummary(BaseModel):
    """Quick summary of available suggestions."""
    total_suggestions: int
    categories_with_suggestions: int
    has_friend_suggestions: bool
    suggestions_expire_at: Optional[datetime] = None


class PendingInvitesSummary(BaseModel):
    """Summary of pending goal invites."""
    pending_count: int
    oldest_invite_at: Optional[datetime] = None
    expires_soon_count: int  # Expiring in 24 hours
