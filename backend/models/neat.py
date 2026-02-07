"""
NEAT (Non-Exercise Activity Thermogenesis) Improvement System Models.

NEAT refers to the energy expended for everything we do that is not sleeping,
eating, or sports-like exercise. This includes walking, typing, yard work,
and even fidgeting.

These models support:
- Step goals and progressive goal setting
- Hourly activity tracking from health apps
- NEAT scoring system
- Multiple streak types (steps, active hours, movement)
- Achievement badges for NEAT activities
- Movement reminder preferences
- Dashboard summaries
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date as date_type, time as time_type
from enum import Enum


# ============================================
# Enums
# ============================================

class GoalAdjustmentStrategy(str, Enum):
    """Strategy for progressive goal adjustments."""
    CONSERVATIVE = "conservative"  # Small increments (5%)
    MODERATE = "moderate"  # Medium increments (10%)
    AGGRESSIVE = "aggressive"  # Larger increments (15%)
    ADAPTIVE = "adaptive"  # AI-determined based on performance


class StreakType(str, Enum):
    """Types of NEAT-related streaks."""
    STEP_GOAL = "step_goal"  # Daily step goal achieved
    ACTIVE_HOURS = "active_hours"  # Minimum active hours per day
    MOVEMENT_BREAKS = "movement_breaks"  # Regular movement throughout day
    NEAT_SCORE = "neat_score"  # Minimum NEAT score achieved


class NEATAchievementCategory(str, Enum):
    """Categories of NEAT achievements."""
    STEPS = "steps"
    STREAKS = "streaks"
    CONSISTENCY = "consistency"
    IMPROVEMENT = "improvement"
    SPECIAL = "special"


class AchievementTier(str, Enum):
    """Tier levels for achievements."""
    BRONZE = "bronze"
    SILVER = "silver"
    GOLD = "gold"
    PLATINUM = "platinum"
    DIAMOND = "diamond"


class ReminderFrequency(str, Enum):
    """Frequency options for movement reminders."""
    EVERY_30_MIN = "every_30_min"
    EVERY_45_MIN = "every_45_min"
    EVERY_60_MIN = "every_60_min"
    EVERY_90_MIN = "every_90_min"
    EVERY_120_MIN = "every_120_min"


class DayOfWeek(str, Enum):
    """Days of the week."""
    MONDAY = "monday"
    TUESDAY = "tuesday"
    WEDNESDAY = "wednesday"
    THURSDAY = "thursday"
    FRIDAY = "friday"
    SATURDAY = "saturday"
    SUNDAY = "sunday"


# ============================================
# Goals
# ============================================

class NEATGoal(BaseModel):
    """User's NEAT goals including step target and activity goals."""
    id: Optional[str] = None
    user_id: str
    daily_step_goal: int = Field(default=8000, ge=1000, le=50000)
    active_hours_goal: int = Field(default=8, ge=1, le=16, description="Target active hours per day")
    movement_breaks_goal: int = Field(default=6, ge=1, le=24, description="Target movement breaks per day")
    min_steps_per_hour: int = Field(default=250, ge=50, le=1000, description="Minimum steps per active hour")
    is_progressive: bool = Field(default=True, description="Whether goal auto-adjusts")
    adjustment_strategy: GoalAdjustmentStrategy = GoalAdjustmentStrategy.MODERATE
    last_adjustment_date: Optional[date_type] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        use_enum_values = True


class NEATGoalProgress(BaseModel):
    """Current progress toward NEAT goals for today."""
    goal: NEATGoal
    current_steps: int = 0
    step_progress_percentage: float = 0.0  # 0-100+
    steps_remaining: int = 0
    active_hours_today: int = 0
    active_hours_progress_percentage: float = 0.0
    movement_breaks_today: int = 0
    movement_breaks_progress_percentage: float = 0.0
    is_step_goal_met: bool = False
    is_active_hours_met: bool = False
    is_movement_breaks_met: bool = False
    estimated_steps_by_end_of_day: Optional[int] = None
    on_track_message: str = ""
    last_sync_at: Optional[datetime] = None


class ProgressiveGoalRequest(BaseModel):
    """Request to calculate a progressive goal."""
    user_id: str
    strategy: Optional[GoalAdjustmentStrategy] = GoalAdjustmentStrategy.MODERATE
    look_back_days: int = Field(default=14, ge=7, le=90)

    class Config:
        use_enum_values = True


class ProgressiveGoalResponse(BaseModel):
    """Response with calculated progressive goal."""
    user_id: str
    current_goal: int
    suggested_goal: int
    change_percentage: float
    average_steps_achieved: float
    goal_achievement_rate: float  # Percentage of days goal was met
    reasoning: str
    applied: bool = False


class UpdateGoalRequest(BaseModel):
    """Request to update step goal."""
    daily_step_goal: Optional[int] = Field(None, ge=1000, le=50000)
    active_hours_goal: Optional[int] = Field(None, ge=1, le=16)
    movement_breaks_goal: Optional[int] = Field(None, ge=1, le=24)
    min_steps_per_hour: Optional[int] = Field(None, ge=50, le=1000)
    is_progressive: Optional[bool] = None
    adjustment_strategy: Optional[GoalAdjustmentStrategy] = None

    class Config:
        use_enum_values = True


# ============================================
# Hourly Activity
# ============================================

class HourlyActivityInput(BaseModel):
    """Input for recording hourly activity from health sync."""
    user_id: str
    activity_date: date_type
    hour: int = Field(..., ge=0, le=23)
    steps: int = Field(default=0, ge=0)
    active_minutes: int = Field(default=0, ge=0, le=60)
    distance_meters: float = Field(default=0, ge=0)
    calories: float = Field(default=0, ge=0)
    was_sedentary: Optional[bool] = None  # True if mostly sitting
    source: str = Field(default="health_connect")


class HourlyActivityRecord(BaseModel):
    """Recorded hourly activity data."""
    id: str
    user_id: str
    activity_date: date_type
    hour: int
    steps: int
    active_minutes: int
    distance_meters: float
    calories: float
    was_sedentary: bool
    met_hourly_goal: bool  # True if steps >= min_steps_per_hour
    source: str
    created_at: datetime


class HourlyBreakdown(BaseModel):
    """Hourly breakdown for a single day."""
    user_id: str
    activity_date: date_type
    hours: List[HourlyActivityRecord]
    total_steps: int
    total_active_minutes: int
    total_calories: float
    active_hours_count: int  # Hours with activity above threshold
    sedentary_hours_count: int
    most_active_hour: Optional[int] = None
    least_active_hour: Optional[int] = None
    hourly_average_steps: float


class BatchHourlyActivityInput(BaseModel):
    """Batch input for syncing multiple hours of activity."""
    activities: List[HourlyActivityInput]


class BatchHourlyActivityResponse(BaseModel):
    """Response from batch hourly sync."""
    synced_count: int
    failed_count: int
    results: List[Dict[str, Any]]


# ============================================
# NEAT Score
# ============================================

class NEATScoreComponents(BaseModel):
    """Breakdown of NEAT score components."""
    step_score: float = Field(default=0, ge=0, le=40, description="Score from total steps (max 40)")
    consistency_score: float = Field(default=0, ge=0, le=30, description="Score from hourly consistency (max 30)")
    active_hours_score: float = Field(default=0, ge=0, le=20, description="Score from active hours (max 20)")
    movement_breaks_score: float = Field(default=0, ge=0, le=10, description="Score from breaks taken (max 10)")


class NEATScore(BaseModel):
    """Daily NEAT score with breakdown."""
    id: Optional[str] = None
    user_id: str
    score_date: date_type
    total_score: float = Field(ge=0, le=100)
    components: NEATScoreComponents
    total_steps: int
    active_hours: int
    movement_breaks: int
    step_goal_met: bool
    grade: str = Field(default="C", description="Letter grade A-F")
    percentile: Optional[float] = None  # Compared to user's history
    message: str = ""  # Encouraging message
    calculated_at: datetime


class NEATScoreHistory(BaseModel):
    """History of NEAT scores."""
    user_id: str
    scores: List[NEATScore]
    average_score: float
    highest_score: float
    lowest_score: float
    trend: str  # "improving", "declining", "stable"
    total_days_tracked: int
    days_above_80: int
    grade_distribution: Dict[str, int]  # {"A": 5, "B": 10, ...}


class CalculateScoreRequest(BaseModel):
    """Request to calculate today's NEAT score."""
    user_id: str
    force_recalculate: bool = False


# ============================================
# Streaks
# ============================================

class NEATStreak(BaseModel):
    """A single streak record."""
    id: Optional[str] = None
    user_id: str
    streak_type: StreakType
    current_length: int = 0
    longest_length: int = 0
    last_achieved_date: Optional[date_type] = None
    started_at: Optional[date_type] = None
    is_active: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        use_enum_values = True


class StreaksResponse(BaseModel):
    """Response with all streak types for a user."""
    user_id: str
    streaks: List[NEATStreak]
    best_overall_streak: Optional[NEATStreak] = None
    total_active_streaks: int = 0


class StreakSummary(BaseModel):
    """Compact streak summary for display."""
    user_id: str
    step_goal_streak: int = 0
    active_hours_streak: int = 0
    movement_breaks_streak: int = 0
    neat_score_streak: int = 0
    best_streak_type: Optional[str] = None
    best_streak_value: int = 0
    all_time_best: int = 0
    all_time_best_type: Optional[str] = None
    streak_message: str = ""


# ============================================
# Achievements
# ============================================

class NEATAchievementDefinition(BaseModel):
    """Definition of a NEAT achievement."""
    id: str
    name: str
    description: str
    category: NEATAchievementCategory
    tier: AchievementTier
    threshold: int  # Value required to unlock
    icon: Optional[str] = None
    points: int = 10
    is_active: bool = True
    sort_order: int = 0

    class Config:
        use_enum_values = True


class UserNEATAchievement(BaseModel):
    """Achievement earned by a user."""
    id: str
    user_id: str
    achievement_id: str
    achieved_at: datetime
    trigger_value: Optional[float] = None
    is_notified: bool = False
    is_celebrated: bool = False
    achievement: Optional[NEATAchievementDefinition] = None


class AchievementProgress(BaseModel):
    """Progress toward an achievement."""
    achievement: NEATAchievementDefinition
    is_achieved: bool = False
    achieved_at: Optional[datetime] = None
    current_value: float = 0
    progress_percentage: float = 0  # 0-100


class AchievementsResponse(BaseModel):
    """Response with user's achievements."""
    user_id: str
    earned: List[UserNEATAchievement]
    total_points: int = 0
    total_earned: int = 0
    recently_earned: List[UserNEATAchievement] = []


class AvailableAchievementsResponse(BaseModel):
    """Response with available achievements and progress."""
    user_id: str
    available: List[AchievementProgress]
    closest_to_unlock: Optional[AchievementProgress] = None


class AchievementCheckResult(BaseModel):
    """Result of checking for new achievements."""
    new_achievements: List[UserNEATAchievement]
    total_new_points: int = 0


# ============================================
# Reminder Preferences
# ============================================

class ReminderPreferences(BaseModel):
    """User's movement reminder preferences."""
    id: Optional[str] = None
    user_id: str
    enabled: bool = True
    frequency: ReminderFrequency = ReminderFrequency.EVERY_60_MIN
    start_time: time_type = Field(default_factory=lambda: time_type(8, 0))  # 8 AM
    end_time: time_type = Field(default_factory=lambda: time_type(20, 0))  # 8 PM
    active_days: List[DayOfWeek] = Field(
        default_factory=lambda: [
            DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY,
            DayOfWeek.THURSDAY, DayOfWeek.FRIDAY
        ]
    )
    skip_if_active: bool = True  # Skip reminder if user was recently active
    active_threshold_minutes: int = Field(default=5, ge=1, le=30)
    quiet_during_workout: bool = True  # Don't remind during active workout
    reminder_message_style: str = Field(default="encouraging")  # "encouraging", "factual", "playful"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        use_enum_values = True


class UpdateReminderPreferencesRequest(BaseModel):
    """Request to update reminder preferences."""
    enabled: Optional[bool] = None
    frequency: Optional[ReminderFrequency] = None
    start_time: Optional[time_type] = None
    end_time: Optional[time_type] = None
    active_days: Optional[List[DayOfWeek]] = None
    skip_if_active: Optional[bool] = None
    active_threshold_minutes: Optional[int] = Field(None, ge=1, le=30)
    quiet_during_workout: Optional[bool] = None
    reminder_message_style: Optional[str] = None

    class Config:
        use_enum_values = True


class ShouldRemindResponse(BaseModel):
    """Response for checking if reminder should be sent."""
    should_remind: bool
    reason: str
    next_reminder_at: Optional[datetime] = None
    suggested_message: Optional[str] = None
    last_active_at: Optional[datetime] = None
    minutes_since_activity: Optional[int] = None


# ============================================
# Dashboard
# ============================================

class NEATDashboard(BaseModel):
    """Combined dashboard data for NEAT display."""
    user_id: str
    # Goal and progress
    goal_progress: NEATGoalProgress
    # Today's score
    today_score: Optional[NEATScore] = None
    # Streaks
    streak_summary: StreakSummary
    # Recent achievements
    recent_achievements: List[UserNEATAchievement] = []
    uncelebrated_achievements: List[UserNEATAchievement] = []
    # Hourly breakdown for today
    hourly_breakdown: Optional[HourlyBreakdown] = None
    # Trend info
    weekly_average_score: Optional[float] = None
    weekly_trend: str = "stable"  # "improving", "declining", "stable"
    # Motivation
    motivational_message: str = ""
    next_milestone: Optional[str] = None
    # Last update
    generated_at: datetime


# ============================================
# Scheduler / Cron
# ============================================

class SendRemindersRequest(BaseModel):
    """Request to send movement reminders to sedentary users."""
    dry_run: bool = False  # If true, don't actually send notifications
    max_users: int = Field(default=1000, ge=1, le=10000)


class SendRemindersResponse(BaseModel):
    """Response from sending reminders."""
    users_checked: int
    reminders_sent: int
    skipped_active: int
    skipped_preferences: int
    errors: int
    dry_run: bool


class CalculateDailyScoresRequest(BaseModel):
    """Request to calculate end-of-day scores for users."""
    target_date: Optional[date_type] = None  # Defaults to yesterday
    max_users: int = Field(default=10000, ge=1, le=100000)


class CalculateDailyScoresResponse(BaseModel):
    """Response from calculating daily scores."""
    target_date: date_type
    users_processed: int
    scores_calculated: int
    streaks_updated: int
    errors: int


class AdjustWeeklyGoalsRequest(BaseModel):
    """Request to adjust progressive goals weekly."""
    dry_run: bool = False
    max_users: int = Field(default=10000, ge=1, le=100000)


class AdjustWeeklyGoalsResponse(BaseModel):
    """Response from adjusting weekly goals."""
    users_checked: int
    goals_adjusted: int
    goals_increased: int
    goals_decreased: int
    goals_unchanged: int
    dry_run: bool
