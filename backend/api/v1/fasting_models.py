"""Pydantic models for fasting."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class StartFastRequest(BaseModel):
    """Request to start a new fast."""
    user_id: str
    protocol: str = Field(description="Protocol ID like '16:8', '18:6', '5:2'")
    protocol_type: str = Field(description="Type: 'tre', 'modified', 'extended', 'custom'")
    goal_duration_minutes: int = Field(ge=60, le=10080, description="Goal in minutes (1h to 7 days)")
    started_at: Optional[str] = Field(None, description="Custom start time in ISO format (for backdating)")
    mood_before: Optional[str] = None
    notes: Optional[str] = None


class EndFastRequest(BaseModel):
    """Request to end a fast."""
    user_id: str
    notes: Optional[str] = None
    mood_after: Optional[str] = None
    energy_level: Optional[int] = Field(None, ge=1, le=5)


class CancelFastRequest(BaseModel):
    """Request to cancel a fast."""
    user_id: str


class UpdateFastRequest(BaseModel):
    """Request to update a fast record."""
    user_id: str
    notes: Optional[str] = None
    mood_before: Optional[str] = None
    mood_after: Optional[str] = None
    energy_level: Optional[int] = Field(None, ge=1, le=5)


class FastingPreferencesRequest(BaseModel):
    """Fasting preferences update request."""
    user_id: str
    default_protocol: Optional[str] = "16:8"
    custom_fasting_hours: Optional[int] = None
    custom_eating_hours: Optional[int] = None
    typical_fast_start_hour: Optional[int] = Field(None, ge=0, le=23)
    typical_eating_start_hour: Optional[int] = Field(None, ge=0, le=23)
    fasting_days: Optional[List[str]] = None  # For 5:2: ['monday', 'thursday']
    notifications_enabled: Optional[bool] = True
    notify_zone_transitions: Optional[bool] = True
    notify_goal_reached: Optional[bool] = True
    notify_eating_window_end: Optional[bool] = True
    notify_fast_start_reminder: Optional[bool] = True
    is_keto_adapted: Optional[bool] = False
    # Meal reminders (new)
    meal_reminders_enabled: Optional[bool] = True
    lunch_reminder_hour: Optional[int] = Field(None, ge=0, le=23)
    dinner_reminder_hour: Optional[int] = Field(None, ge=0, le=23)
    extended_protocol_acknowledged: Optional[bool] = False
    safety_responses: Optional[dict] = None


class CompleteOnboardingRequest(BaseModel):
    """Complete fasting onboarding request."""
    user_id: str
    preferences: dict
    safety_acknowledgments: List[str]


class SafetyScreeningRequest(BaseModel):
    """Save safety screening responses."""
    user_id: str
    responses: dict  # Question key -> bool answer


# ==================== Response Models ====================

class FastingRecordResponse(BaseModel):
    """Fasting record response."""
    id: str
    user_id: str
    start_time: str
    end_time: Optional[str] = None
    goal_duration_minutes: int
    actual_duration_minutes: Optional[int] = None
    protocol: str
    protocol_type: str
    status: str  # 'active', 'completed', 'cancelled'
    completed_goal: bool
    completion_percentage: Optional[float] = None
    zones_reached: Optional[List[dict]] = None
    notes: Optional[str] = None
    mood_before: Optional[str] = None
    mood_after: Optional[str] = None
    energy_level: Optional[int] = None
    created_at: str
    updated_at: Optional[str] = None


class FastEndResultResponse(BaseModel):
    """Result of ending a fast."""
    record: FastingRecordResponse
    actual_minutes: int
    goal_minutes: int
    completion_percent: float
    streak_maintained: bool
    message: str
    streak_info: Optional[dict] = None


class FastingPreferencesResponse(BaseModel):
    """Fasting preferences response."""
    id: str
    user_id: str
    default_protocol: str
    custom_fasting_hours: Optional[int] = None
    custom_eating_hours: Optional[int] = None
    typical_fast_start_hour: Optional[int] = None
    typical_eating_start_hour: Optional[int] = None
    fasting_days: Optional[List[str]] = None
    notifications_enabled: bool
    notify_zone_transitions: bool
    notify_goal_reached: bool
    notify_eating_window_end: bool
    notify_fast_start_reminder: Optional[bool] = True
    is_keto_adapted: bool
    # Meal reminders (new)
    meal_reminders_enabled: Optional[bool] = True
    lunch_reminder_hour: Optional[int] = None
    dinner_reminder_hour: Optional[int] = None
    extended_protocol_acknowledged: Optional[bool] = False
    safety_responses: Optional[dict] = None
    safety_screening_completed: bool
    safety_warnings_acknowledged: Optional[List[str]] = None
    has_medical_conditions: Optional[bool] = False
    fasting_onboarding_completed: bool
    onboarding_completed_at: Optional[str] = None
    created_at: str
    updated_at: Optional[str] = None


class FastingStreakResponse(BaseModel):
    """Fasting streak response."""
    user_id: str
    current_streak: int
    longest_streak: int
    total_fasts_completed: int
    total_fasting_hours: int
    last_fast_date: Optional[str] = None
    streak_start_date: Optional[str] = None
    fasts_this_week: int
    freezes_available: Optional[int] = 2
    freezes_used_this_week: Optional[int] = 0


class FastingStatsResponse(BaseModel):
    """Fasting statistics response."""
    user_id: str
    period: str
    total_fasts: int
    completed_fasts: int
    cancelled_fasts: int
    total_fasting_hours: float
    average_fast_duration_hours: float
    longest_fast_hours: float
    completion_rate: float
    most_common_protocol: Optional[str] = None
    zones_reached: dict  # zone_name -> count


class SafetyCheckResponse(BaseModel):
    """Safety eligibility check response."""
    can_use_fasting: bool
    requires_warning: bool
    warnings: List[str]
    blocked_reasons: List[str]


# ==================== Fasting Score Models ====================

class FastingScoreCreateRequest(BaseModel):
    """Request to save/update a fasting score."""
    user_id: str
    score: int = Field(ge=0, le=100)
    completion_component: float = 0
    streak_component: float = 0
    duration_component: float = 0
    weekly_component: float = 0
    protocol_component: float = 0
    current_streak: int = 0
    fasts_this_week: int = 0
    weekly_goal: int = 5
    completion_rate: float = 0
    avg_duration_minutes: int = 0


class FastingScoreResponse(BaseModel):
    """Response for a single fasting score."""
    id: str
    user_id: str
    score: int
    completion_component: float
    streak_component: float
    duration_component: float
    weekly_component: float
    protocol_component: float
    current_streak: int
    fasts_this_week: int
    weekly_goal: int
    completion_rate: float
    avg_duration_minutes: int
    recorded_at: str
    score_date: str


class FastingScoreTrendResponse(BaseModel):
    """Response for score trend data."""
    current_score: int
    previous_score: int
    score_change: int
    trend: str  # 'up', 'down', 'stable'


# ==================== Helper Functions ====================

class LogFastingContextRequest(BaseModel):
    """Request to log fasting context for AI coaching."""
    user_id: str
    fasting_record_id: Optional[str] = None
    context_type: str  # 'fast_started', 'zone_entered', 'fast_ended', 'fast_cancelled', 'note_added', 'mood_logged'
    zone_name: Optional[str] = None
    mood: Optional[str] = None
    energy_level: Optional[int] = Field(None, ge=1, le=5)
    note: Optional[str] = None
    protocol: Optional[str] = None
    protocol_type: Optional[str] = None
    is_dangerous_protocol: Optional[bool] = False
    elapsed_minutes: Optional[int] = None
    goal_minutes: Optional[int] = None


