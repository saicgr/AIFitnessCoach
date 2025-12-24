"""Achievements and milestones Pydantic models."""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class AchievementType(BaseModel):
    """Achievement definition."""
    id: str
    name: str
    description: str
    category: str  # 'strength', 'consistency', 'weight', 'cardio', 'habit'
    icon: str
    tier: str  # 'bronze', 'silver', 'gold', 'platinum'
    points: int
    threshold_value: Optional[float] = None
    threshold_unit: Optional[str] = None
    is_repeatable: bool = False


class UserAchievement(BaseModel):
    """User's earned achievement."""
    id: str
    user_id: str
    achievement_id: str
    earned_at: datetime
    trigger_value: Optional[float] = None
    trigger_details: Optional[dict] = None
    is_notified: bool = False
    # Joined achievement info (from achievement_types table)
    achievement: Optional[AchievementType] = None
    achievement_name: Optional[str] = None
    achievement_icon: Optional[str] = None
    achievement_category: Optional[str] = None


class UserStreak(BaseModel):
    """User's streak tracking."""
    id: str
    user_id: str
    streak_type: str  # 'workout', 'hydration', 'protein', 'sleep'
    current_streak: int = 0
    longest_streak: int = 0
    last_activity_date: Optional[str] = None  # ISO date
    streak_start_date: Optional[str] = None  # ISO date


class PersonalRecord(BaseModel):
    """Personal record entry."""
    id: str
    user_id: str
    exercise_name: str
    record_type: str  # 'weight', 'reps', 'time', 'distance'
    record_value: float
    record_unit: str  # 'lbs', 'kg', 'reps', 'seconds', 'km', 'miles'
    previous_value: Optional[float] = None
    improvement_percentage: Optional[float] = None
    workout_id: Optional[str] = None
    achieved_at: datetime


class AchievementsSummary(BaseModel):
    """Summary of user's achievements and progress."""
    total_points: int = 0
    total_achievements: int = 0
    recent_achievements: List[UserAchievement] = []
    current_streaks: List[UserStreak] = []
    personal_records: List[PersonalRecord] = []
    achievements_by_category: dict = {}  # {category: count}


class NewAchievementNotification(BaseModel):
    """Notification for a newly earned achievement."""
    achievement: AchievementType
    earned_at: datetime
    trigger_value: Optional[float] = None
    trigger_details: Optional[dict] = None
    is_first_time: bool = True
