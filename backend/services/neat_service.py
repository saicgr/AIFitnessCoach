"""
NEAT (Non-Exercise Activity Thermogenesis) Service

Comprehensive service for tracking and optimizing daily activity levels
beyond structured exercise. Manages step goals, hourly activity tracking,
NEAT scoring, streaks, achievements, and movement reminders.

NEAT represents all the calories burned through daily activities like
walking, standing, fidgeting, and general movement throughout the day.

Key Features:
- Progressive step goal management based on user history
- Hourly activity tracking with sedentary detection
- NEAT score calculation (0-100) combining active hours and steps
- Streak tracking for consistent activity
- Achievement system with milestone rewards
- Smart movement reminders respecting user preferences
- AI context generation for personalized coaching

Research-backed approach:
- Sedentary threshold: 250 steps/hour (Bassett et al., 2017)
- Active hours target: 10-12 hours/day for optimal NEAT
- Progressive goal increases: 500-1000 steps/week for behavior change
"""

from .neat_service_helpers import (  # noqa: F401
    NEATService,
    get_neat_service,
)

from dataclasses import dataclass, field
from datetime import datetime, timedelta, date, time
from typing import Optional, Dict, List, Any, Tuple
from enum import Enum
import logging

from core.db import get_supabase_db

logger = logging.getLogger(__name__)


# =============================================================================
# Constants and Enums
# =============================================================================

class StreakType(str, Enum):
    """Types of streaks tracked for NEAT."""
    DAILY_GOAL = "daily_goal"          # Consecutive days meeting step goal
    ACTIVE_HOURS = "active_hours"       # Consecutive days with 8+ active hours
    NEAT_SCORE = "neat_score"           # Consecutive days with NEAT score >= 70
    MOVEMENT_BREAKS = "movement_breaks" # Consecutive days avoiding 2+ hour sedentary periods


class AchievementCategory(str, Enum):
    """Categories of NEAT achievements."""
    STEP_MILESTONES = "step_milestones"
    CONSISTENCY = "consistency"
    NEAT_SCORE = "neat_score"
    ACTIVE_HOURS = "active_hours"
    WEEKLY = "weekly"


# Sedentary threshold in steps per hour (research-backed)
SEDENTARY_THRESHOLD_STEPS = 250

# Default waking hours (6 AM - 10 PM = 16 hours)
DEFAULT_WAKING_HOURS = 16

# Progressive goal increase amounts
GOAL_INCREASE_MIN = 500
GOAL_INCREASE_MAX = 1000

# Achievement definitions
ACHIEVEMENT_DEFINITIONS = {
    # Step milestones
    "first_1000": {
        "name": "First Steps",
        "description": "Walk 1,000 steps in a day",
        "category": AchievementCategory.STEP_MILESTONES,
        "threshold": 1000,
        "icon": "footsteps",
        "points": 10,
    },
    "first_2500": {
        "name": "Getting Active",
        "description": "Walk 2,500 steps in a day",
        "category": AchievementCategory.STEP_MILESTONES,
        "threshold": 2500,
        "icon": "walking",
        "points": 15,
    },
    "first_5000": {
        "name": "Half Way There",
        "description": "Walk 5,000 steps in a day",
        "category": AchievementCategory.STEP_MILESTONES,
        "threshold": 5000,
        "icon": "runner",
        "points": 25,
    },
    "first_7500": {
        "name": "Power Walker",
        "description": "Walk 7,500 steps in a day",
        "category": AchievementCategory.STEP_MILESTONES,
        "threshold": 7500,
        "icon": "sprint",
        "points": 35,
    },
    "first_10000": {
        "name": "Ten Thousand Club",
        "description": "Walk 10,000 steps in a day",
        "category": AchievementCategory.STEP_MILESTONES,
        "threshold": 10000,
        "icon": "trophy_gold",
        "points": 50,
    },
    # Consistency achievements
    "streak_3": {
        "name": "Getting Started",
        "description": "Meet your step goal 3 days in a row",
        "category": AchievementCategory.CONSISTENCY,
        "threshold": 3,
        "icon": "fire",
        "points": 20,
    },
    "streak_7": {
        "name": "Week Warrior",
        "description": "Meet your step goal 7 days in a row",
        "category": AchievementCategory.CONSISTENCY,
        "threshold": 7,
        "icon": "fire_double",
        "points": 50,
    },
    "streak_14": {
        "name": "Two Week Champion",
        "description": "Meet your step goal 14 days in a row",
        "category": AchievementCategory.CONSISTENCY,
        "threshold": 14,
        "icon": "fire_triple",
        "points": 100,
    },
    "streak_30": {
        "name": "Monthly Master",
        "description": "Meet your step goal 30 days in a row",
        "category": AchievementCategory.CONSISTENCY,
        "threshold": 30,
        "icon": "crown",
        "points": 200,
    },
    # NEAT score achievements
    "neat_50": {
        "name": "NEAT Novice",
        "description": "Achieve a NEAT score of 50+",
        "category": AchievementCategory.NEAT_SCORE,
        "threshold": 50,
        "icon": "chart_up",
        "points": 15,
    },
    "neat_75": {
        "name": "NEAT Pro",
        "description": "Achieve a NEAT score of 75+",
        "category": AchievementCategory.NEAT_SCORE,
        "threshold": 75,
        "icon": "chart_star",
        "points": 30,
    },
    "neat_90": {
        "name": "NEAT Master",
        "description": "Achieve a NEAT score of 90+",
        "category": AchievementCategory.NEAT_SCORE,
        "threshold": 90,
        "icon": "star_gold",
        "points": 50,
    },
    # Active hours achievements
    "active_8": {
        "name": "Active Day",
        "description": "Have 8+ active hours in a day",
        "category": AchievementCategory.ACTIVE_HOURS,
        "threshold": 8,
        "icon": "clock_active",
        "points": 20,
    },
    "active_10": {
        "name": "Super Active",
        "description": "Have 10+ active hours in a day",
        "category": AchievementCategory.ACTIVE_HOURS,
        "threshold": 10,
        "icon": "clock_gold",
        "points": 35,
    },
    "active_12": {
        "name": "Movement Enthusiast",
        "description": "Have 12+ active hours in a day",
        "category": AchievementCategory.ACTIVE_HOURS,
        "threshold": 12,
        "icon": "lightning",
        "points": 50,
    },
    # Weekly achievements
    "week_5_7": {
        "name": "Weekday Warrior",
        "description": "Meet your goal 5 out of 7 days in a week",
        "category": AchievementCategory.WEEKLY,
        "threshold": 5,
        "icon": "calendar_check",
        "points": 40,
    },
    "week_7_7": {
        "name": "Perfect Week",
        "description": "Meet your goal all 7 days in a week",
        "category": AchievementCategory.WEEKLY,
        "threshold": 7,
        "icon": "calendar_star",
        "points": 75,
    },
}


# =============================================================================
# Data Classes
# =============================================================================

@dataclass
class NEATGoal:
    """User's current NEAT step goal with progress."""
    user_id: str
    current_goal: int
    baseline_steps: int
    today_steps: int
    progress_percentage: float
    goal_met: bool
    week_number: int  # Current week of progressive program
    last_updated: Optional[datetime] = None

    @property
    def remaining_steps(self) -> int:
        """Steps remaining to meet goal."""
        return max(0, self.current_goal - self.today_steps)


@dataclass
class HourlyActivity:
    """Activity data for a single hour."""
    hour: int  # 0-23
    steps: int
    is_active: bool  # > SEDENTARY_THRESHOLD_STEPS
    source: str  # 'apple_health', 'google_fit', 'manual'
    recorded_at: datetime


@dataclass
class DailyNEATData:
    """Complete NEAT data for a day."""
    user_id: str
    date: date
    total_steps: int
    step_goal: int
    goal_met: bool
    active_hours: int
    sedentary_hours: int
    hourly_breakdown: List[HourlyActivity]
    neat_score: float
    longest_sedentary_period: int  # in hours
    calories_from_neat: Optional[int] = None


@dataclass
class NEATScore:
    """Calculated NEAT score with breakdown."""
    total_score: float  # 0-100
    active_hours_component: float  # 0-50
    steps_component: float  # 0-50
    active_hours: int
    total_steps: int
    step_goal: int
    rating: str  # 'excellent', 'good', 'fair', 'needs_improvement'


@dataclass
class UserStreaks:
    """All streak data for a user."""
    daily_goal_streak: int
    longest_daily_goal_streak: int
    active_hours_streak: int
    longest_active_hours_streak: int
    neat_score_streak: int
    longest_neat_score_streak: int
    movement_breaks_streak: int


@dataclass
class Achievement:
    """A single achievement."""
    id: str
    name: str
    description: str
    category: str
    threshold: int
    icon: str
    points: int
    achieved: bool = False
    achieved_at: Optional[datetime] = None
    current_value: Optional[float] = None
    progress_percentage: Optional[float] = None


@dataclass
class ReminderPreferences:
    """User's movement reminder preferences."""
    enabled: bool
    interval_minutes: int  # How often to check (typically 60)
    quiet_hours_start: time  # e.g., 22:00
    quiet_hours_end: time    # e.g., 07:00
    work_hours_only: bool
    work_hours_start: time   # e.g., 09:00
    work_hours_end: time     # e.g., 17:00
    min_sedentary_hours: int # Trigger after N sedentary hours
    exclude_weekends: bool


@dataclass
class AIContextData:
    """Context data for AI/Gemini prompts."""
    current_goal: int
    today_progress: int
    progress_percentage: float
    recent_trend: str  # 'improving', 'stable', 'declining'
    sedentary_pattern: str  # Description of sedentary patterns
    achievements_summary: str
    streak_info: str
    recommendations: List[str]


# =============================================================================
# NEAT Service
# =============================================================================

