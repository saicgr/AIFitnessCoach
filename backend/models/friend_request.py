"""
Friend Request Models for Social Features.

Provides models for:
- Friend request creation and management
- Social notifications
- User search results
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime
from enum import Enum


# ============================================================
# ENUMS
# ============================================================

class FriendRequestStatus(str, Enum):
    """Status of a friend request."""
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"


class SocialNotificationType(str, Enum):
    """Types of social notifications."""
    FRIEND_REQUEST = "friend_request"
    FRIEND_ACCEPTED = "friend_accepted"
    REACTION = "reaction"
    COMMENT = "comment"
    CHALLENGE_INVITE = "challenge_invite"
    CHALLENGE_ACCEPTED = "challenge_accepted"
    CHALLENGE_COMPLETED = "challenge_completed"
    WORKOUT_SHARED = "workout_shared"
    ACHIEVEMENT_EARNED = "achievement_earned"


# ============================================================
# FRIEND REQUEST MODELS
# ============================================================

class FriendRequestCreate(BaseModel):
    """Request to create a friend request."""
    to_user_id: str = Field(..., description="ID of the user to send request to")
    message: Optional[str] = Field(None, max_length=500, description="Optional message with the request")


class FriendRequest(BaseModel):
    """Friend request model."""
    id: str
    from_user_id: str
    to_user_id: str
    status: FriendRequestStatus = FriendRequestStatus.PENDING
    message: Optional[str] = None
    created_at: datetime
    responded_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class FriendRequestWithUser(FriendRequest):
    """Friend request with user profile information."""
    from_user_name: Optional[str] = None
    from_user_avatar: Optional[str] = None
    to_user_name: Optional[str] = None
    to_user_avatar: Optional[str] = None


# ============================================================
# USER SEARCH MODELS
# ============================================================

class UserSearchResult(BaseModel):
    """User search result with relationship info."""
    id: str
    name: str
    username: Optional[str] = None  # Unique username for search/mention
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    total_workouts: int = 0
    current_streak: int = 0
    is_following: bool = False
    is_follower: bool = False
    is_friend: bool = False
    has_pending_request: bool = False
    pending_request_id: Optional[str] = None
    requires_approval: bool = False  # Whether this user requires follow approval


class UserSuggestion(UserSearchResult):
    """User suggestion with reason for suggestion."""
    suggestion_reason: Optional[str] = None  # "Mutual friends", "Similar workouts", etc.
    mutual_friends_count: int = 0


# ============================================================
# SOCIAL NOTIFICATION MODELS
# ============================================================

class SocialNotificationCreate(BaseModel):
    """Request to create a social notification."""
    user_id: str = Field(..., description="ID of the user to notify")
    type: SocialNotificationType
    from_user_id: Optional[str] = None
    from_user_name: Optional[str] = None
    from_user_avatar: Optional[str] = None
    reference_id: Optional[str] = None
    reference_type: Optional[str] = None
    title: str
    body: str
    data: Optional[dict] = Field(default_factory=dict)


class SocialNotification(BaseModel):
    """Social notification model."""
    id: str
    user_id: str
    type: SocialNotificationType
    from_user_id: Optional[str] = None
    from_user_name: Optional[str] = None
    from_user_avatar: Optional[str] = None
    reference_id: Optional[str] = None
    reference_type: Optional[str] = None
    title: str
    body: str
    data: dict = Field(default_factory=dict)
    is_read: bool = False
    created_at: datetime

    class Config:
        from_attributes = True


class SocialNotificationsList(BaseModel):
    """List of social notifications with metadata."""
    notifications: List[SocialNotification]
    unread_count: int
    total_count: int


# ============================================================
# PRIVACY SETTINGS UPDATE
# ============================================================

class SocialPrivacySettingsUpdate(BaseModel):
    """Update social privacy and notification settings."""
    # Notification toggles
    notify_friend_requests: Optional[bool] = None
    notify_reactions: Optional[bool] = None
    notify_comments: Optional[bool] = None
    notify_challenge_invites: Optional[bool] = None
    notify_friend_activity: Optional[bool] = None

    # Privacy settings
    require_follow_approval: Optional[bool] = None


class SocialPrivacySettings(BaseModel):
    """Full social privacy settings."""
    # Notification toggles
    notify_friend_requests: bool = True
    notify_reactions: bool = True
    notify_comments: bool = True
    notify_challenge_invites: bool = True
    notify_friend_activity: bool = True

    # Privacy settings
    require_follow_approval: bool = False

    # Existing settings from user_privacy_settings
    allow_friend_requests: bool = True
    allow_challenge_invites: bool = True
    show_on_leaderboards: bool = True
