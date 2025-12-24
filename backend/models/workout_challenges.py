"""
Pydantic models for workout challenges (friend-to-friend).
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class ChallengeStatus(str, Enum):
    """Challenge status enum."""
    pending = "pending"
    accepted = "accepted"
    declined = "declined"
    completed = "completed"
    expired = "expired"
    abandoned = "abandoned"  # Quit midway through workout


class NotificationType(str, Enum):
    """Challenge notification types."""
    challenge_received = "challenge_received"
    challenge_accepted = "challenge_accepted"
    challenge_completed = "challenge_completed"
    challenge_beaten = "challenge_beaten"
    challenge_abandoned = "challenge_abandoned"  # Opponent quit


# ============================================================
# REQUEST MODELS
# ============================================================

class SendChallengeRequest(BaseModel):
    """Request to send a workout challenge to friends."""
    to_user_ids: List[str] = Field(..., max_length=20, description="List of user IDs to challenge (max 20)")
    workout_log_id: Optional[str] = Field(None, max_length=100, description="Workout log ID (if from completed workout)")
    activity_id: Optional[str] = Field(None, max_length=100, description="Activity ID (if from social feed)")
    workout_name: str = Field(..., max_length=200, description="Name of the workout")
    workout_data: dict = Field(..., description="Workout stats to beat (duration, volume, exercises)")
    challenge_message: Optional[str] = Field(None, max_length=500, description="Personal challenge message")
    is_retry: bool = Field(False, description="Whether this is a retry of a previous challenge")
    retried_from_challenge_id: Optional[str] = Field(None, max_length=100, description="Original challenge ID if this is a retry")


class AcceptChallengeRequest(BaseModel):
    """Request to accept a challenge."""
    challenge_id: str = Field(..., max_length=100)


class DeclineChallengeRequest(BaseModel):
    """Request to decline a challenge."""
    challenge_id: str = Field(..., max_length=100)
    reason: Optional[str] = Field(None, max_length=500)


class CompleteChallengeRequest(BaseModel):
    """Request to mark challenge as completed with results."""
    challenge_id: str = Field(..., max_length=100)
    workout_log_id: str = Field(..., max_length=100)  # The workout they just completed
    challenged_stats: dict  # Their stats (duration, volume, etc.)


class AbandonChallengeRequest(BaseModel):
    """Request to abandon/quit a challenge midway through workout."""
    challenge_id: str = Field(..., max_length=100)
    quit_reason: str = Field(..., max_length=500, description="Reason for quitting (shown to challenger)")
    partial_stats: Optional[dict] = Field(None, description="Partial workout stats before quitting")


# ============================================================
# RESPONSE MODELS
# ============================================================

class WorkoutChallenge(BaseModel):
    """Workout challenge model."""
    id: str
    from_user_id: str
    to_user_id: str
    workout_log_id: Optional[str] = None
    activity_id: Optional[str] = None
    workout_name: str
    workout_data: dict
    challenge_message: Optional[str] = None
    status: ChallengeStatus
    accepted_at: Optional[datetime] = None
    declined_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    abandoned_at: Optional[datetime] = None
    quit_reason: Optional[str] = None  # Why they quit (shown to challenger)
    partial_stats: Optional[dict] = None  # Stats before quitting
    challenger_stats: Optional[dict] = None
    challenged_stats: Optional[dict] = None
    did_beat: Optional[bool] = None
    is_retry: bool = False  # Whether this is a retry
    retried_from_challenge_id: Optional[str] = None  # Original challenge ID
    retry_count: int = 0  # Number of times this has been retried
    created_at: datetime
    expires_at: datetime

    # Optional joined user data
    from_user_name: Optional[str] = None
    from_user_avatar: Optional[str] = None
    to_user_name: Optional[str] = None
    to_user_avatar: Optional[str] = None

    class Config:
        from_attributes = True


class ChallengesResponse(BaseModel):
    """Response with list of challenges."""
    challenges: List[WorkoutChallenge]
    total: int
    page: int
    page_size: int


class ChallengeNotification(BaseModel):
    """Challenge notification model."""
    id: str
    challenge_id: str
    user_id: str
    notification_type: NotificationType
    is_read: bool
    read_at: Optional[datetime] = None
    created_at: datetime

    # Optional joined challenge data
    challenge: Optional[WorkoutChallenge] = None

    class Config:
        from_attributes = True


class NotificationsResponse(BaseModel):
    """Response with list of notifications."""
    notifications: List[ChallengeNotification]
    total: int
    unread_count: int


class ChallengeStats(BaseModel):
    """User's challenge statistics."""
    user_id: str
    challenges_sent: int
    challenges_received: int
    challenges_accepted: int
    challenges_declined: int
    challenges_won: int
    challenges_lost: int
    challenges_abandoned: int
    win_rate: float  # Percentage of challenges won
    total_retries: int  # How many retries this user has attempted
    retries_won: int  # How many retries resulted in wins
    retry_win_rate: float  # Percentage of retries won
    most_retried_workout: Optional[str] = None  # Workout they retry most often


class SendChallengeResponse(BaseModel):
    """Response after sending challenges."""
    message: str
    challenges_sent: int
    challenge_ids: List[str]
