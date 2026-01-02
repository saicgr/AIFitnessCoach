"""
Milestone and ROI models for tracking user progress and demonstrating value.

These models support:
- Milestone definitions (system-wide milestones)
- User milestone achievements
- ROI metrics (return on investment of time/effort)
- Milestone celebration and sharing
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class MilestoneCategory(str, Enum):
    """Categories of milestones."""
    WORKOUTS = "workouts"
    STREAK = "streak"
    STRENGTH = "strength"
    VOLUME = "volume"
    TIME = "time"
    WEIGHT = "weight"
    PRS = "prs"


class MilestoneTier(str, Enum):
    """Tier levels for milestones (rarity/difficulty)."""
    BRONZE = "bronze"
    SILVER = "silver"
    GOLD = "gold"
    PLATINUM = "platinum"
    DIAMOND = "diamond"


class MilestoneDefinition(BaseModel):
    """Definition of a milestone that users can achieve."""
    id: str
    name: str
    description: Optional[str] = None
    category: MilestoneCategory
    threshold: int  # Value required to achieve (e.g., 10 workouts)
    icon: Optional[str] = None  # Emoji or icon name
    badge_color: str = "cyan"
    tier: MilestoneTier = MilestoneTier.BRONZE
    points: int = 10
    share_message: Optional[str] = None
    is_active: bool = True
    sort_order: int = 0
    created_at: Optional[datetime] = None

    class Config:
        use_enum_values = True


class UserMilestone(BaseModel):
    """A milestone achieved by a user."""
    id: str
    user_id: str
    milestone_id: str
    achieved_at: datetime
    trigger_value: Optional[float] = None
    trigger_context: Optional[Dict[str, Any]] = None
    is_notified: bool = False
    is_celebrated: bool = False
    shared_at: Optional[datetime] = None
    share_platform: Optional[str] = None
    # Joined milestone info
    milestone: Optional[MilestoneDefinition] = None


class MilestoneProgress(BaseModel):
    """Progress toward a milestone (achieved or upcoming)."""
    milestone: MilestoneDefinition
    is_achieved: bool = False
    achieved_at: Optional[datetime] = None
    trigger_value: Optional[float] = None
    is_celebrated: bool = False
    shared_at: Optional[datetime] = None
    # Progress info for upcoming milestones
    current_value: Optional[float] = None
    progress_percentage: Optional[float] = None  # 0-100


class NewMilestoneAchieved(BaseModel):
    """Notification for a newly achieved milestone."""
    milestone_id: str
    milestone_name: str
    milestone_icon: Optional[str] = None
    milestone_tier: MilestoneTier = MilestoneTier.BRONZE
    points: int = 0
    share_message: Optional[str] = None
    achieved_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        use_enum_values = True


class ROIMetrics(BaseModel):
    """
    Return on Investment metrics for a user's fitness journey.

    These metrics help users see the value of their consistency and effort.
    """
    user_id: str
    # Workout metrics
    total_workouts_completed: int = 0
    total_exercises_completed: int = 0
    total_sets_completed: int = 0
    total_reps_completed: int = 0
    # Time metrics
    total_workout_time_seconds: int = 0
    total_workout_time_hours: float = 0  # Computed
    total_active_time_seconds: int = 0
    average_workout_duration_seconds: int = 0
    average_workout_duration_minutes: int = 0  # Computed
    # Volume metrics
    total_weight_lifted_lbs: float = 0
    total_weight_lifted_kg: float = 0
    # Calorie metrics (estimated)
    estimated_calories_burned: int = 0
    # Progress metrics
    strength_increase_percentage: float = 0
    prs_achieved_count: int = 0
    current_streak_days: int = 0
    longest_streak_days: int = 0
    # Journey info
    first_workout_date: Optional[datetime] = None
    last_workout_date: Optional[datetime] = None
    journey_days: int = 0
    # Workout frequency
    workouts_this_week: int = 0
    workouts_this_month: int = 0
    average_workouts_per_week: float = 0
    # Calculated summary strings for UI
    strength_summary: str = ""  # "You're 15% stronger since you started!"
    journey_summary: str = ""  # "127 days of dedication"
    # Last update
    last_calculated_at: Optional[datetime] = None

    def compute_derived_fields(self):
        """Compute derived fields for UI display."""
        self.total_workout_time_hours = round(self.total_workout_time_seconds / 3600, 1)
        self.average_workout_duration_minutes = round(self.average_workout_duration_seconds / 60)

        # Generate summary strings
        if self.strength_increase_percentage > 0:
            self.strength_summary = f"You're {self.strength_increase_percentage:.0f}% stronger since you started!"
        elif self.prs_achieved_count > 0:
            self.strength_summary = f"You've set {self.prs_achieved_count} personal records!"
        else:
            self.strength_summary = "Keep training to track your strength gains!"

        if self.journey_days > 0:
            if self.journey_days == 1:
                self.journey_summary = "Day 1 of your journey!"
            elif self.journey_days < 30:
                self.journey_summary = f"{self.journey_days} days of dedication"
            elif self.journey_days < 365:
                months = self.journey_days // 30
                self.journey_summary = f"{months} month{'s' if months > 1 else ''} of commitment"
            else:
                years = self.journey_days // 365
                self.journey_summary = f"{years} year{'s' if years > 1 else ''} of dedication!"
        else:
            self.journey_summary = "Start your journey today!"

        return self


class ROISummary(BaseModel):
    """
    Compact ROI summary for home screen display.

    Shows key metrics that demonstrate value to the user.
    """
    total_workouts: int = 0
    total_hours_invested: float = 0
    estimated_calories_burned: int = 0
    total_weight_lifted: str = ""  # Formatted string like "15,230 lbs"
    strength_increase_text: str = ""  # "15% stronger"
    prs_count: int = 0
    current_streak: int = 0
    journey_days: int = 0
    # Motivational message
    headline: str = "Your Fitness Journey"
    motivational_message: str = ""


class MilestonesResponse(BaseModel):
    """Response containing all milestone data for a user."""
    achieved: List[MilestoneProgress]
    upcoming: List[MilestoneProgress]
    total_points: int = 0
    total_achieved: int = 0
    next_milestone: Optional[MilestoneProgress] = None
    # Recently achieved (for celebration)
    recently_achieved: List[UserMilestone] = []
    uncelebrated: List[UserMilestone] = []


class MilestoneShareRequest(BaseModel):
    """Request to record a milestone share."""
    milestone_id: str
    platform: str  # 'twitter', 'instagram', 'facebook', 'copy_link', etc.


class MarkMilestoneCelebratedRequest(BaseModel):
    """Request to mark milestones as celebrated."""
    milestone_ids: List[str]


class MilestoneCheckResult(BaseModel):
    """Result of checking for new milestones."""
    new_milestones: List[NewMilestoneAchieved]
    total_new_points: int = 0
    roi_updated: bool = False
