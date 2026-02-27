"""Social features Pydantic models."""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


# ============================================================
# ENUMS
# ============================================================

class ConnectionType(str, Enum):
    """User connection types."""
    FOLLOWING = "following"
    FRIEND = "friend"  # Mutual connection
    FAMILY = "family"


class ConnectionStatus(str, Enum):
    """Connection status."""
    ACTIVE = "active"
    BLOCKED = "blocked"
    MUTED = "muted"


class ActivityType(str, Enum):
    """Activity feed item types."""
    WORKOUT_COMPLETED = "workout_completed"
    WORKOUT_SHARED = "workout_shared"
    ACHIEVEMENT_EARNED = "achievement_earned"
    PERSONAL_RECORD = "personal_record"
    WEIGHT_MILESTONE = "weight_milestone"
    STREAK_MILESTONE = "streak_milestone"
    MANUAL_POST = "manual_post"


class Visibility(str, Enum):
    """Content visibility levels."""
    PUBLIC = "public"
    FRIENDS = "friends"
    FAMILY = "family"
    PRIVATE = "private"


class ReactionType(str, Enum):
    """Reaction types."""
    CHEER = "cheer"
    FIRE = "fire"
    STRONG = "strong"
    CLAP = "clap"
    HEART = "heart"


class ChallengeType(str, Enum):
    """Challenge types."""
    WORKOUT_COUNT = "workout_count"
    WORKOUT_STREAK = "workout_streak"
    TOTAL_VOLUME = "total_volume"
    WEIGHT_LOSS = "weight_loss"
    STEP_COUNT = "step_count"
    CUSTOM = "custom"


class ChallengeStatus(str, Enum):
    """Challenge participation status."""
    ACTIVE = "active"
    COMPLETED = "completed"
    FAILED = "failed"
    QUIT = "quit"


# ============================================================
# USER CONNECTIONS
# ============================================================

class UserConnection(BaseModel):
    """User connection (friend/following)."""
    id: str
    follower_id: str
    following_id: str
    connection_type: ConnectionType = ConnectionType.FOLLOWING
    status: ConnectionStatus = ConnectionStatus.ACTIVE
    created_at: datetime


class UserConnectionCreate(BaseModel):
    """Request to create a connection."""
    following_id: str = Field(..., max_length=100)
    connection_type: ConnectionType = ConnectionType.FOLLOWING


class UserProfile(BaseModel):
    """Basic user profile for social features."""
    id: str = Field(..., max_length=100)
    name: str = Field(..., max_length=200)
    avatar_url: Optional[str] = Field(default=None, max_length=500)
    bio: Optional[str] = Field(default=None, max_length=1000)
    total_workouts: int = Field(default=0, ge=0)
    current_streak: int = Field(default=0, ge=0)
    total_achievements: int = Field(default=0, ge=0)


class UserConnectionWithProfile(UserConnection):
    """Connection with user profile data."""
    user_profile: Optional[UserProfile] = None


# ============================================================
# ACTIVITY FEED
# ============================================================

class ActivityFeedItem(BaseModel):
    """Activity feed item."""
    id: str
    user_id: str
    activity_type: ActivityType
    activity_data: Dict[str, Any] = Field(default_factory=dict)
    visibility: Visibility = Visibility.FRIENDS
    reaction_count: int = 0
    comment_count: int = 0
    created_at: datetime

    # Optional references
    workout_log_id: Optional[str] = None
    achievement_id: Optional[str] = None
    pr_id: Optional[str] = None

    # Joined user data
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None
    is_support_user: bool = False  # Whether the post author is the support account

    # Pinned post fields (admin feature)
    is_pinned: bool = False
    pinned_at: Optional[datetime] = None
    pinned_by: Optional[str] = None


class ActivityFeedItemCreate(BaseModel):
    """Request to create activity feed item."""
    activity_type: ActivityType
    activity_data: Dict[str, Any]
    visibility: Visibility = Visibility.FRIENDS
    workout_log_id: Optional[str] = None
    achievement_id: Optional[str] = None
    pr_id: Optional[str] = None


class ActivityFeedResponse(BaseModel):
    """Activity feed response with pagination."""
    items: List[ActivityFeedItem]
    total_count: int
    page: int
    page_size: int
    has_more: bool


# ============================================================
# REACTIONS
# ============================================================

class ActivityReaction(BaseModel):
    """Reaction to an activity."""
    id: str
    activity_id: str
    user_id: str
    reaction_type: ReactionType
    created_at: datetime

    # Joined user data
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None


class ActivityReactionCreate(BaseModel):
    """Request to create a reaction."""
    activity_id: str = Field(..., max_length=100)
    reaction_type: ReactionType


class ReactionsSummary(BaseModel):
    """Summary of reactions on an activity."""
    activity_id: str
    total_count: int
    reactions_by_type: Dict[str, int] = Field(default_factory=dict)  # {reaction_type: count}
    user_reaction: Optional[ReactionType] = None  # Current user's reaction


# ============================================================
# COMMENTS
# ============================================================

class ActivityComment(BaseModel):
    """Comment on an activity."""
    id: str
    activity_id: str
    user_id: str
    comment_text: str
    parent_comment_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    # Joined user data
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None

    # Reply count (for parent comments)
    reply_count: Optional[int] = 0


class ActivityCommentCreate(BaseModel):
    """Request to create a comment."""
    activity_id: str = Field(..., max_length=100)
    comment_text: str = Field(..., min_length=1, max_length=2000)
    parent_comment_id: Optional[str] = Field(default=None, max_length=100)


class ActivityCommentUpdate(BaseModel):
    """Request to update a comment."""
    comment_text: str = Field(..., min_length=1, max_length=2000)


class CommentsResponse(BaseModel):
    """Comments response with pagination."""
    comments: List[ActivityComment]
    total_count: int
    page: int
    page_size: int


# ============================================================
# CHALLENGES
# ============================================================

class Challenge(BaseModel):
    """Fitness challenge."""
    id: str
    title: str
    description: Optional[str] = None
    challenge_type: ChallengeType
    goal_value: float
    goal_unit: Optional[str] = None
    start_date: datetime
    end_date: datetime
    created_by: Optional[str] = None
    is_public: bool = False
    participant_count: int = 0
    created_at: datetime

    # Joined creator data
    creator_name: Optional[str] = None
    creator_avatar: Optional[str] = None


class ChallengeCreate(BaseModel):
    """Request to create a challenge."""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=2000)
    challenge_type: ChallengeType
    goal_value: float = Field(..., ge=0)
    goal_unit: Optional[str] = Field(default=None, max_length=50)
    start_date: datetime
    end_date: datetime
    is_public: bool = False


class ChallengeParticipant(BaseModel):
    """Challenge participant."""
    id: str
    challenge_id: str
    user_id: str
    current_value: float = 0
    progress_percentage: float = 0
    status: ChallengeStatus = ChallengeStatus.ACTIVE
    completed_at: Optional[datetime] = None
    joined_at: datetime

    # Joined user data
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None


class ChallengeParticipantCreate(BaseModel):
    """Request to join a challenge."""
    challenge_id: str = Field(..., max_length=100)


class ChallengeParticipantUpdate(BaseModel):
    """Request to update challenge progress."""
    current_value: float = Field(..., ge=0)


class ChallengeWithParticipation(Challenge):
    """Challenge with user's participation data."""
    user_participation: Optional[ChallengeParticipant] = None
    top_participants: List[ChallengeParticipant] = Field(default_factory=list)


class ChallengeLeaderboardEntry(BaseModel):
    """Leaderboard entry for a challenge."""
    rank: int
    user_id: str
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None
    current_value: float
    progress_percentage: float
    status: ChallengeStatus


class ChallengeLeaderboard(BaseModel):
    """Challenge leaderboard."""
    challenge_id: str
    challenge_title: str
    goal_value: float
    goal_unit: Optional[str] = None
    entries: List[ChallengeLeaderboardEntry]
    user_rank: Optional[int] = None


# ============================================================
# PRIVACY SETTINGS
# ============================================================

class UserPrivacySettings(BaseModel):
    """User privacy settings."""
    user_id: str
    profile_visibility: Visibility = Visibility.FRIENDS
    show_workouts: bool = True
    show_achievements: bool = True
    show_weight_progress: bool = False
    show_personal_records: bool = True
    allow_friend_requests: bool = True
    allow_challenge_invites: bool = True
    show_on_leaderboards: bool = True
    updated_at: datetime


class UserPrivacySettingsUpdate(BaseModel):
    """Request to update privacy settings."""
    profile_visibility: Optional[Visibility] = None
    show_workouts: Optional[bool] = None
    show_achievements: Optional[bool] = None
    show_weight_progress: Optional[bool] = None
    show_personal_records: Optional[bool] = None
    allow_friend_requests: Optional[bool] = None
    allow_challenge_invites: Optional[bool] = None
    show_on_leaderboards: Optional[bool] = None


# ============================================================
# SOCIAL SUMMARY
# ============================================================

class SocialStats(BaseModel):
    """User's social statistics."""
    followers_count: int = 0
    following_count: int = 0
    friends_count: int = 0
    active_challenges: int = 0
    completed_challenges: int = 0


class SocialFeedSummary(BaseModel):
    """Summary of social feed for user."""
    activity_feed: List[ActivityFeedItem]
    suggested_challenges: List[Challenge]
    friend_suggestions: List[UserProfile]
    social_stats: SocialStats


# ============================================================
# SENIOR MODE MODELS
# ============================================================

class SimplifiedActivityItem(BaseModel):
    """Simplified activity item for senior mode."""
    id: str
    user_name: str
    user_avatar: Optional[str] = None
    activity_type: ActivityType
    summary_text: str  # "John completed Upper Body Workout"
    created_at: datetime
    can_cheer: bool = True
    has_cheered: bool = False


class SimplifiedChallenge(BaseModel):
    """Simplified challenge for senior mode."""
    id: str
    title: str
    simple_description: str  # "Complete 10 workouts this month"
    your_progress: str  # "5 out of 10 workouts"
    progress_percentage: float
    days_remaining: int


class SeniorSocialSummary(BaseModel):
    """Social summary optimized for senior mode."""
    recent_activities: List[SimplifiedActivityItem]
    your_challenges: List[SimplifiedChallenge]
    family_members: List[UserProfile]
    encouragement_count: int = 0  # How many cheers they received


# ============================================================
# DIRECT MESSAGES
# ============================================================

class DirectMessage(BaseModel):
    """Direct message between users."""
    id: str
    conversation_id: str
    sender_id: str
    content: str
    is_system_message: bool = False
    created_at: datetime
    edited_at: Optional[datetime] = None

    # Joined sender data
    sender_name: Optional[str] = None
    sender_avatar: Optional[str] = None
    sender_is_support: bool = False


class DirectMessageCreate(BaseModel):
    """Request to send a direct message."""
    recipient_id: str = Field(..., max_length=100)
    content: str = Field(..., min_length=1, max_length=5000)
    conversation_id: Optional[str] = Field(default=None, max_length=100)


class Conversation(BaseModel):
    """Conversation between users."""
    id: str
    last_message_at: datetime
    created_at: datetime

    # Participants info
    participants: List["ConversationParticipant"] = Field(default_factory=list)

    # Latest message preview
    last_message: Optional[DirectMessage] = None
    unread_count: int = 0


class ConversationParticipant(BaseModel):
    """Conversation participant."""
    user_id: str
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None
    is_support_user: bool = False
    last_read_at: Optional[datetime] = None
    is_muted: bool = False


class ConversationsResponse(BaseModel):
    """Conversations list response."""
    conversations: List[Conversation]
    total_count: int


class MessagesResponse(BaseModel):
    """Messages list response with pagination."""
    messages: List[DirectMessage]
    conversation_id: str
    total_count: int
    page: int
    page_size: int
    has_more: bool
