"""
Consistency Analytics Models
============================
Pydantic models for consistency tracking, streak analysis, and workout patterns.
"""

from datetime import datetime, date
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from enum import Enum


# ============================================================================
# Enums
# ============================================================================

class DayOfWeek(int, Enum):
    """Day of week (0=Sunday, 6=Saturday - matching SQL EXTRACT(DOW))."""
    SUNDAY = 0
    MONDAY = 1
    TUESDAY = 2
    WEDNESDAY = 3
    THURSDAY = 4
    FRIDAY = 5
    SATURDAY = 6

    @property
    def display_name(self) -> str:
        """Get human-readable name."""
        names = {
            0: "Sunday",
            1: "Monday",
            2: "Tuesday",
            3: "Wednesday",
            4: "Thursday",
            5: "Friday",
            6: "Saturday",
        }
        return names.get(self.value, "Unknown")

    @property
    def short_name(self) -> str:
        """Get abbreviated name."""
        names = {
            0: "Sun",
            1: "Mon",
            2: "Tue",
            3: "Wed",
            4: "Thu",
            5: "Fri",
            6: "Sat",
        }
        return names.get(self.value, "?")


class TimeOfDay(str, Enum):
    """Time of day preference for workouts."""
    EARLY_MORNING = "early_morning"  # 5-8 AM
    MORNING = "morning"  # 8-11 AM
    MIDDAY = "midday"  # 11 AM - 2 PM
    AFTERNOON = "afternoon"  # 2-5 PM
    EVENING = "evening"  # 5-8 PM
    NIGHT = "night"  # 8-11 PM

    @classmethod
    def from_hour(cls, hour: int) -> "TimeOfDay":
        """Convert hour (0-23) to TimeOfDay."""
        if 5 <= hour < 8:
            return cls.EARLY_MORNING
        elif 8 <= hour < 11:
            return cls.MORNING
        elif 11 <= hour < 14:
            return cls.MIDDAY
        elif 14 <= hour < 17:
            return cls.AFTERNOON
        elif 17 <= hour < 20:
            return cls.EVENING
        else:
            return cls.NIGHT


class StreakEndReason(str, Enum):
    """Reason why a streak ended."""
    MISSED_WORKOUT = "missed_workout"
    MANUAL_RESET = "manual_reset"
    PROGRAM_CHANGE = "program_change"
    ACCOUNT_ISSUE = "account_issue"


class RecoveryType(str, Enum):
    """Type of streak recovery workout."""
    STANDARD = "standard"
    QUICK_RECOVERY = "quick_recovery"  # Shorter, easier workout
    CUSTOM = "custom"


# ============================================================================
# Streak Models
# ============================================================================

class StreakHistoryRecord(BaseModel):
    """A historical streak record."""
    id: str
    user_id: str
    streak_length: int = Field(..., ge=0)
    started_at: datetime
    ended_at: datetime
    end_reason: Optional[str] = StreakEndReason.MISSED_WORKOUT.value
    created_at: datetime


class StreakRecoveryAttempt(BaseModel):
    """A streak recovery attempt record."""
    id: str
    user_id: str
    previous_streak_length: int = Field(default=0, ge=0)
    days_since_last_workout: int = Field(default=1, ge=0)
    recovery_workout_id: Optional[str] = None
    recovery_type: str = RecoveryType.STANDARD.value
    motivation_message: Optional[str] = None
    was_successful: Optional[bool] = None
    created_at: datetime
    completed_at: Optional[datetime] = None


class StreakRecoveryRequest(BaseModel):
    """Request to start a streak recovery."""
    user_id: str
    recovery_type: str = Field(default=RecoveryType.STANDARD.value)


class StreakRecoveryResponse(BaseModel):
    """Response after initiating streak recovery."""
    success: bool
    attempt_id: str
    message: str
    motivation_quote: Optional[str] = None
    suggested_workout_type: Optional[str] = None
    suggested_duration_minutes: Optional[int] = None


# ============================================================================
# Time Pattern Models
# ============================================================================

class WorkoutTimePattern(BaseModel):
    """Workout completion pattern for a specific day/hour."""
    id: Optional[str] = None
    user_id: str
    day_of_week: int = Field(..., ge=0, le=6)
    hour_of_day: int = Field(..., ge=0, le=23)
    completion_count: int = Field(default=0, ge=0)
    skip_count: int = Field(default=0, ge=0)
    updated_at: Optional[datetime] = None

    @property
    def total_attempts(self) -> int:
        """Total scheduled workouts at this time."""
        return self.completion_count + self.skip_count

    @property
    def completion_rate(self) -> float:
        """Completion rate as percentage (0-100)."""
        if self.total_attempts == 0:
            return 0.0
        return round((self.completion_count / self.total_attempts) * 100, 1)

    @property
    def day_name(self) -> str:
        """Human-readable day name."""
        return DayOfWeek(self.day_of_week).display_name

    @property
    def time_of_day(self) -> TimeOfDay:
        """Time of day category."""
        return TimeOfDay.from_hour(self.hour_of_day)


class DayPattern(BaseModel):
    """Aggregated pattern for a single day of the week."""
    day_of_week: int = Field(..., ge=0, le=6)
    day_name: str
    total_completions: int = 0
    total_skips: int = 0
    completion_rate: float = 0.0
    is_best_day: bool = False
    is_worst_day: bool = False


class TimeOfDayPattern(BaseModel):
    """Aggregated pattern for a time of day."""
    time_of_day: str
    display_name: str
    total_completions: int = 0
    total_skips: int = 0
    completion_rate: float = 0.0
    is_preferred: bool = False


# ============================================================================
# Daily Metrics Models
# ============================================================================

class DailyConsistencyMetric(BaseModel):
    """Daily consistency metrics record."""
    id: Optional[str] = None
    user_id: str
    metric_date: date
    workouts_scheduled: int = Field(default=0, ge=0)
    workouts_completed: int = Field(default=0, ge=0)
    workouts_skipped: int = Field(default=0, ge=0)
    total_workout_minutes: int = Field(default=0, ge=0)
    streak_day: int = Field(default=0, ge=0)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    @property
    def completion_rate(self) -> float:
        """Daily completion rate."""
        if self.workouts_scheduled == 0:
            return 100.0 if self.workouts_completed > 0 else 0.0
        return round((self.workouts_completed / self.workouts_scheduled) * 100, 1)


class WeeklyConsistencyMetric(BaseModel):
    """Aggregated weekly consistency metrics."""
    week_start: date
    week_end: date
    workouts_scheduled: int = 0
    workouts_completed: int = 0
    workouts_skipped: int = 0
    completion_rate: float = 0.0
    total_workout_minutes: int = 0
    average_session_minutes: float = 0.0


# ============================================================================
# Insights Response Models
# ============================================================================

class ConsistencyInsights(BaseModel):
    """Comprehensive consistency insights for a user."""
    user_id: str

    # Current state
    current_streak: int = Field(default=0, ge=0)
    longest_streak: int = Field(default=0, ge=0)
    is_streak_active: bool = False

    # Day patterns
    best_day: Optional[DayPattern] = None
    worst_day: Optional[DayPattern] = None
    day_patterns: List[DayPattern] = Field(default_factory=list)

    # Time preferences
    preferred_time: Optional[str] = None  # TimeOfDay value
    time_patterns: List[TimeOfDayPattern] = Field(default_factory=list)

    # Monthly stats
    month_workouts_completed: int = 0
    month_workouts_scheduled: int = 0
    month_completion_rate: float = 0.0
    month_display: str = ""  # "12 of 16 workouts"

    # Weekly stats (last 4 weeks)
    weekly_completion_rates: List[WeeklyConsistencyMetric] = Field(default_factory=list)
    average_weekly_rate: float = 0.0
    weekly_trend: str = "stable"  # improving, stable, declining

    # Streak recovery suggestion (if streak broken)
    needs_recovery: bool = False
    recovery_suggestion: Optional[str] = None
    days_since_last_workout: int = 0

    # Computed timestamps
    last_workout_date: Optional[date] = None
    calculated_at: datetime = Field(default_factory=datetime.now)


class ConsistencyPatterns(BaseModel):
    """Detailed consistency patterns analysis."""
    user_id: str

    # Time of day patterns
    time_patterns: List[TimeOfDayPattern] = Field(default_factory=list)
    preferred_time: Optional[str] = None

    # Day of week patterns
    day_patterns: List[DayPattern] = Field(default_factory=list)
    most_consistent_day: Optional[str] = None
    least_consistent_day: Optional[str] = None

    # Seasonal patterns (if enough data)
    has_seasonal_data: bool = False
    seasonal_notes: Optional[str] = None

    # Skip reasons breakdown (if tracked)
    skip_reasons: Dict[str, int] = Field(default_factory=dict)
    most_common_skip_reason: Optional[str] = None

    # Historical streaks
    streak_history: List[StreakHistoryRecord] = Field(default_factory=list)
    average_streak_length: float = 0.0
    streak_count: int = 0

    calculated_at: datetime = Field(default_factory=datetime.now)


# ============================================================================
# Request/Response Models for API
# ============================================================================

class ConsistencyInsightsRequest(BaseModel):
    """Request parameters for consistency insights."""
    user_id: str
    include_patterns: bool = Field(default=False)
    days_back: int = Field(default=90, ge=7, le=365)


class ConsistencyPatternsRequest(BaseModel):
    """Request parameters for detailed patterns."""
    user_id: str
    days_back: int = Field(default=180, ge=30, le=365)


class RecordWorkoutPatternRequest(BaseModel):
    """Request to record a workout pattern update."""
    user_id: str
    completed_at: datetime
    is_completed: bool


class CalendarHeatmapData(BaseModel):
    """Data for the weekly calendar heatmap visualization."""
    date: date
    day_of_week: int
    status: str  # "completed", "missed", "rest", "future"
    workout_name: Optional[str] = None


class CalendarHeatmapResponse(BaseModel):
    """Response containing calendar heatmap data."""
    user_id: str
    start_date: date
    end_date: date
    data: List[CalendarHeatmapData] = Field(default_factory=list)
    total_completed: int = 0
    total_missed: int = 0
    total_rest_days: int = 0
