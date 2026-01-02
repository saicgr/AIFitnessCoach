"""
Habit Tracking System Models.

Pydantic models for habit tracking, logging, streaks, and insights.

These models support:
- Habit CRUD operations (create, read, update, delete)
- Daily habit logging with completion tracking
- Streak tracking for habit consistency
- Habit templates for quick habit creation
- Summary and insight generation
- AI-powered habit suggestions
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import date, time, datetime
from enum import Enum
from uuid import UUID


# ============================================================================
# Enums
# ============================================================================

class HabitCategory(str, Enum):
    """Category of habit for grouping and filtering."""
    NUTRITION = "nutrition"
    ACTIVITY = "activity"
    HEALTH = "health"
    LIFESTYLE = "lifestyle"
    GENERAL = "general"


class HabitType(str, Enum):
    """Type of habit behavior."""
    POSITIVE = "positive"  # Do something (e.g., drink water, exercise)
    NEGATIVE = "negative"  # Avoid something (e.g., no sugary drinks, no smoking)


class HabitFrequency(str, Enum):
    """Frequency pattern for habit tracking."""
    DAILY = "daily"
    WEEKLY = "weekly"
    SPECIFIC_DAYS = "specific_days"


# ============================================================================
# Request Models - Habit CRUD
# ============================================================================

class HabitCreate(BaseModel):
    """Request to create a new habit."""
    name: str = Field(..., min_length=1, max_length=255, description="Name of the habit")
    description: Optional[str] = Field(None, max_length=1000, description="Optional description")
    category: HabitCategory = Field(default=HabitCategory.GENERAL, description="Habit category")
    habit_type: HabitType = Field(default=HabitType.POSITIVE, description="Positive or negative habit")
    frequency: HabitFrequency = Field(default=HabitFrequency.DAILY, description="How often to track")
    target_days: Optional[List[int]] = Field(
        None,
        description="Days to track (0=Sunday, 6=Saturday). Required for SPECIFIC_DAYS frequency."
    )
    target_count: int = Field(default=1, ge=1, le=100, description="Target count per day/session")
    unit: Optional[str] = Field(None, max_length=50, description="Unit of measurement (e.g., 'glasses', 'minutes')")
    icon: str = Field(default="check_circle", max_length=100, description="Icon name for display")
    color: str = Field(default="#4CAF50", max_length=20, description="Hex color code for display")
    reminder_time: Optional[time] = Field(None, description="Time for daily reminder")
    reminder_enabled: bool = Field(default=False, description="Whether reminders are enabled")

    class Config:
        use_enum_values = True


class HabitUpdate(BaseModel):
    """Request to update an existing habit."""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    category: Optional[HabitCategory] = None
    habit_type: Optional[HabitType] = None
    frequency: Optional[HabitFrequency] = None
    target_days: Optional[List[int]] = None
    target_count: Optional[int] = Field(None, ge=1, le=100)
    unit: Optional[str] = Field(None, max_length=50)
    icon: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=20)
    reminder_time: Optional[time] = None
    reminder_enabled: Optional[bool] = None
    is_active: Optional[bool] = None

    class Config:
        use_enum_values = True


# ============================================================================
# Response Models - Habit
# ============================================================================

class Habit(BaseModel):
    """Complete habit record from database."""
    id: UUID
    user_id: UUID
    name: str
    description: Optional[str] = None
    category: HabitCategory
    habit_type: HabitType
    frequency: HabitFrequency
    target_days: Optional[List[int]] = None
    target_count: int
    unit: Optional[str] = None
    icon: str
    color: str
    reminder_time: Optional[time] = None
    reminder_enabled: bool
    is_active: bool
    is_suggested: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
        use_enum_values = True


# ============================================================================
# Request Models - Habit Log
# ============================================================================

class HabitLogCreate(BaseModel):
    """Request to log a habit completion for a specific date."""
    habit_id: UUID = Field(..., description="ID of the habit to log")
    log_date: date = Field(..., description="Date of the log entry")
    completed: bool = Field(default=False, description="Whether the habit was completed")
    value: Optional[float] = Field(None, ge=0, description="Numeric value if tracking quantity")
    notes: Optional[str] = Field(None, max_length=500, description="Optional notes about the log")
    skipped: bool = Field(default=False, description="Whether the habit was intentionally skipped")
    skip_reason: Optional[str] = Field(None, max_length=255, description="Reason for skipping")


class HabitLogUpdate(BaseModel):
    """Request to update an existing habit log."""
    completed: Optional[bool] = None
    value: Optional[float] = Field(None, ge=0)
    notes: Optional[str] = Field(None, max_length=500)
    skipped: Optional[bool] = None
    skip_reason: Optional[str] = Field(None, max_length=255)


# ============================================================================
# Response Models - Habit Log
# ============================================================================

class HabitLog(BaseModel):
    """Complete habit log record from database."""
    id: UUID
    habit_id: UUID
    user_id: UUID
    log_date: date
    completed: bool
    value: Optional[float] = None
    notes: Optional[str] = None
    skipped: bool
    skip_reason: Optional[str] = None
    completed_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Streak Models
# ============================================================================

class HabitStreak(BaseModel):
    """Streak tracking for a specific habit."""
    id: UUID
    habit_id: UUID
    user_id: UUID
    current_streak: int = Field(default=0, ge=0, description="Current consecutive days completed")
    longest_streak: int = Field(default=0, ge=0, description="All-time longest streak")
    last_completed_date: Optional[date] = Field(None, description="Last date habit was completed")
    streak_start_date: Optional[date] = Field(None, description="Start date of current streak")
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Template Models
# ============================================================================

class HabitTemplate(BaseModel):
    """Pre-defined habit template for quick habit creation."""
    id: UUID
    name: str
    description: Optional[str] = None
    category: HabitCategory
    habit_type: HabitType
    suggested_target: int = Field(default=1, ge=1, description="Suggested daily target")
    unit: Optional[str] = None
    icon: str
    color: str
    is_active: bool
    sort_order: int = 0

    class Config:
        from_attributes = True
        use_enum_values = True


# ============================================================================
# Enhanced Response Models
# ============================================================================

class HabitWithStatus(Habit):
    """Habit with today's completion status and streak info."""
    today_completed: bool = Field(default=False, description="Whether habit is completed today")
    today_value: Optional[float] = Field(None, description="Today's logged value if any")
    current_streak: int = Field(default=0, ge=0, description="Current streak length")
    longest_streak: int = Field(default=0, ge=0, description="All-time longest streak")
    completion_rate_7d: float = Field(
        default=0.0,
        ge=0.0,
        le=100.0,
        description="Completion rate over last 7 days (0-100)"
    )


class TodayHabitsResponse(BaseModel):
    """Response containing today's habits with status."""
    habits: List[HabitWithStatus]
    total_habits: int = Field(default=0, ge=0)
    completed_today: int = Field(default=0, ge=0)
    completion_percentage: float = Field(default=0.0, ge=0.0, le=100.0)


class HabitWeeklySummary(BaseModel):
    """Weekly summary for a specific habit."""
    habit_id: UUID
    habit_name: str
    week_start: date
    days_completed: int = Field(default=0, ge=0, le=7)
    days_scheduled: int = Field(default=0, ge=0, le=7)
    completion_rate: float = Field(default=0.0, ge=0.0, le=100.0)
    current_streak: int = Field(default=0, ge=0)


class HabitsSummary(BaseModel):
    """Overall habits summary for dashboard display."""
    total_active_habits: int = Field(default=0, ge=0)
    completed_today: int = Field(default=0, ge=0)
    completion_rate_today: float = Field(default=0.0, ge=0.0, le=100.0)
    average_streak: float = Field(default=0.0, ge=0.0)
    longest_current_streak: int = Field(default=0, ge=0)
    best_habit_name: Optional[str] = Field(None, description="Habit with highest completion rate")
    needs_attention: List[str] = Field(
        default_factory=list,
        description="List of habit names with low completion rates"
    )


class HabitInsights(BaseModel):
    """AI-generated insights about habit performance."""
    summary: str = Field(..., description="Overall summary of habit performance")
    best_performing_habits: List[str] = Field(
        default_factory=list,
        description="Names of habits with high completion rates"
    )
    needs_improvement: List[str] = Field(
        default_factory=list,
        description="Names of habits that need more attention"
    )
    suggestions: List[str] = Field(
        default_factory=list,
        description="Actionable suggestions for improvement"
    )
    streak_analysis: str = Field(
        default="",
        description="Analysis of streak patterns and trends"
    )


# ============================================================================
# AI Suggestion Models
# ============================================================================

class HabitSuggestionRequest(BaseModel):
    """Request for AI-powered habit suggestions."""
    goals: Optional[List[str]] = Field(
        None,
        description="User's fitness goals (e.g., 'lose weight', 'build muscle')"
    )
    current_habits: Optional[List[str]] = Field(
        None,
        description="Names of habits user already tracks"
    )
    preferences: Optional[Dict[str, Any]] = Field(
        None,
        description="User preferences for habit suggestions"
    )


class HabitSuggestionResponse(BaseModel):
    """Response containing AI-suggested habits."""
    suggested_habits: List[HabitTemplate] = Field(
        default_factory=list,
        description="List of suggested habit templates"
    )
    reasoning: str = Field(
        default="",
        description="AI reasoning for the suggestions"
    )


# ============================================================================
# Bulk Operation Models
# ============================================================================

class BulkHabitLogCreate(BaseModel):
    """Request to log multiple habits at once."""
    logs: List[HabitLogCreate] = Field(..., description="List of habit logs to create")


class BulkHabitLogResponse(BaseModel):
    """Response from bulk habit logging."""
    created_count: int = Field(default=0, ge=0)
    failed_count: int = Field(default=0, ge=0)
    results: List[Dict[str, Any]] = Field(default_factory=list)


# ============================================================================
# History and Analytics Models
# ============================================================================

class HabitHistoryRequest(BaseModel):
    """Request for habit history data."""
    habit_id: UUID
    start_date: date
    end_date: date


class HabitHistoryEntry(BaseModel):
    """Single entry in habit history."""
    log_date: date
    completed: bool
    value: Optional[float] = None
    skipped: bool = False


class HabitHistoryResponse(BaseModel):
    """Response containing habit history."""
    habit_id: UUID
    habit_name: str
    entries: List[HabitHistoryEntry] = Field(default_factory=list)
    total_days: int = 0
    days_completed: int = 0
    days_skipped: int = 0
    completion_rate: float = 0.0


class HabitCalendarData(BaseModel):
    """Data for calendar view of habit completion."""
    date: date
    status: str  # "completed", "missed", "skipped", "not_scheduled", "future"
    value: Optional[float] = None


class HabitCalendarResponse(BaseModel):
    """Response containing calendar data for a habit."""
    habit_id: UUID
    habit_name: str
    start_date: date
    end_date: date
    data: List[HabitCalendarData] = Field(default_factory=list)
    streak_info: Optional[HabitStreak] = None


# ============================================================================
# Reminder Models
# ============================================================================

class HabitReminderUpdate(BaseModel):
    """Request to update habit reminder settings."""
    reminder_time: Optional[time] = None
    reminder_enabled: Optional[bool] = None


class PendingHabitReminder(BaseModel):
    """A pending habit reminder to be sent."""
    habit_id: UUID
    habit_name: str
    user_id: UUID
    reminder_time: time
    category: HabitCategory
    icon: str


class SendRemindersResponse(BaseModel):
    """Response from sending habit reminders."""
    reminders_sent: int = 0
    reminders_skipped: int = 0
    errors: int = 0
