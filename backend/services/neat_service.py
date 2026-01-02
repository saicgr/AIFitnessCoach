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

class NEATService:
    """
    Comprehensive NEAT (Non-Exercise Activity Thermogenesis) Service.

    Manages all aspects of daily activity tracking beyond structured workouts,
    including step goals, hourly tracking, scoring, streaks, and achievements.
    """

    def __init__(self):
        """Initialize the NEAT service."""
        pass

    # =========================================================================
    # 1. Progressive Step Goal Management
    # =========================================================================

    async def get_user_neat_goal(self, user_id: str) -> NEATGoal:
        """
        Get the user's current NEAT step goal with today's progress.

        Args:
            user_id: User ID

        Returns:
            NEATGoal with current goal and progress
        """
        try:
            db = get_supabase_db()
            today = date.today().isoformat()

            # Get user's NEAT settings
            result = db.client.table("user_neat_settings").select("*").eq(
                "user_id", user_id
            ).execute()

            if not result.data:
                # Create default settings
                baseline = await self._calculate_baseline_steps(user_id)
                initial_goal = baseline + 500 if baseline > 0 else 5000

                db.client.table("user_neat_settings").insert({
                    "user_id": user_id,
                    "current_goal": initial_goal,
                    "baseline_steps": baseline,
                    "week_number": 1,
                    "created_at": datetime.now().isoformat(),
                }).execute()

                settings = {
                    "current_goal": initial_goal,
                    "baseline_steps": baseline,
                    "week_number": 1,
                }
            else:
                settings = result.data[0]

            # Get today's steps
            today_steps = await self._get_steps_for_date(user_id, today)
            current_goal = settings.get("current_goal", 5000)

            progress_pct = min(100.0, (today_steps / current_goal) * 100) if current_goal > 0 else 0

            return NEATGoal(
                user_id=user_id,
                current_goal=current_goal,
                baseline_steps=settings.get("baseline_steps", 0),
                today_steps=today_steps,
                progress_percentage=round(progress_pct, 1),
                goal_met=today_steps >= current_goal,
                week_number=settings.get("week_number", 1),
                last_updated=settings.get("updated_at"),
            )

        except Exception as e:
            logger.error(f"Error getting NEAT goal for user {user_id}: {e}")
            return NEATGoal(
                user_id=user_id,
                current_goal=5000,
                baseline_steps=0,
                today_steps=0,
                progress_percentage=0.0,
                goal_met=False,
                week_number=1,
            )

    async def update_step_goal(self, user_id: str, new_goal: int) -> bool:
        """
        Manually update the user's step goal.

        Args:
            user_id: User ID
            new_goal: New step goal (must be positive)

        Returns:
            True if successful
        """
        try:
            if new_goal <= 0:
                logger.warning(f"Invalid step goal {new_goal} for user {user_id}")
                return False

            db = get_supabase_db()

            db.client.table("user_neat_settings").upsert({
                "user_id": user_id,
                "current_goal": new_goal,
                "updated_at": datetime.now().isoformat(),
            }, on_conflict="user_id").execute()

            logger.info(f"Updated step goal for user {user_id} to {new_goal}")
            return True

        except Exception as e:
            logger.error(f"Error updating step goal: {e}")
            return False

    async def calculate_progressive_goal(self, user_id: str) -> int:
        """
        Calculate the next progressive step goal based on user history.

        Algorithm:
        - Start sedentary users at 7-day average + 500 steps
        - Increase goal by 500-1000 steps weekly if consistently achieved
        - Cap increases if user is struggling

        Args:
            user_id: User ID

        Returns:
            Recommended new step goal
        """
        try:
            db = get_supabase_db()

            # Get current settings
            settings_result = db.client.table("user_neat_settings").select("*").eq(
                "user_id", user_id
            ).execute()

            current_goal = 5000
            week_number = 1

            if settings_result.data:
                current_goal = settings_result.data[0].get("current_goal", 5000)
                week_number = settings_result.data[0].get("week_number", 1)

            # Get last 7 days of step data
            seven_days_ago = (date.today() - timedelta(days=7)).isoformat()
            daily_result = db.client.table("daily_neat_activity").select(
                "total_steps, goal_met"
            ).eq("user_id", user_id).gte(
                "activity_date", seven_days_ago
            ).execute()

            if not daily_result.data or len(daily_result.data) < 3:
                # Not enough data, keep current goal
                return current_goal

            # Calculate achievement rate
            days_met = sum(1 for d in daily_result.data if d.get("goal_met", False))
            achievement_rate = days_met / len(daily_result.data)

            # Calculate average steps
            total_steps = sum(d.get("total_steps", 0) for d in daily_result.data)
            avg_steps = total_steps / len(daily_result.data)

            # Determine goal adjustment
            if achievement_rate >= 0.8:
                # Achieving 80%+ of days - increase by 750-1000
                increase = GOAL_INCREASE_MAX if achievement_rate >= 0.9 else 750
                new_goal = current_goal + increase

            elif achievement_rate >= 0.6:
                # Achieving 60-80% - small increase of 500
                new_goal = current_goal + GOAL_INCREASE_MIN

            elif achievement_rate >= 0.4:
                # Struggling - keep current goal
                new_goal = current_goal

            else:
                # Really struggling - decrease goal slightly
                new_goal = max(int(avg_steps + 500), current_goal - 500)

            # Apply sensible limits
            new_goal = max(2000, min(20000, new_goal))

            # Update settings if goal changed
            if new_goal != current_goal:
                db.client.table("user_neat_settings").upsert({
                    "user_id": user_id,
                    "current_goal": new_goal,
                    "week_number": week_number + 1,
                    "updated_at": datetime.now().isoformat(),
                }, on_conflict="user_id").execute()

                logger.info(
                    f"Progressive goal update for {user_id}: {current_goal} -> {new_goal} "
                    f"(achievement rate: {achievement_rate:.0%})"
                )

            return new_goal

        except Exception as e:
            logger.error(f"Error calculating progressive goal: {e}")
            return 5000

    async def _calculate_baseline_steps(self, user_id: str) -> int:
        """Calculate baseline steps from last 7 days of data."""
        try:
            db = get_supabase_db()
            seven_days_ago = (date.today() - timedelta(days=7)).isoformat()

            result = db.client.table("daily_neat_activity").select("total_steps").eq(
                "user_id", user_id
            ).gte("activity_date", seven_days_ago).execute()

            if not result.data:
                return 0

            total = sum(d.get("total_steps", 0) for d in result.data)
            return int(total / len(result.data))

        except Exception as e:
            logger.error(f"Error calculating baseline steps: {e}")
            return 0

    async def _get_steps_for_date(self, user_id: str, activity_date: str) -> int:
        """Get total steps for a specific date."""
        try:
            db = get_supabase_db()

            result = db.client.table("daily_neat_activity").select(
                "total_steps"
            ).eq("user_id", user_id).eq("activity_date", activity_date).execute()

            if result.data:
                return result.data[0].get("total_steps", 0)
            return 0

        except Exception as e:
            logger.error(f"Error getting steps for date: {e}")
            return 0

    # =========================================================================
    # 2. Hourly Activity Tracking
    # =========================================================================

    async def record_hourly_activity(
        self,
        user_id: str,
        hour: int,
        steps: int,
        source: str = "apple_health",
        activity_date: Optional[str] = None,
    ) -> bool:
        """
        Record hourly step activity.

        Args:
            user_id: User ID
            hour: Hour of day (0-23)
            steps: Number of steps for that hour
            source: Data source ('apple_health', 'google_fit', 'manual')
            activity_date: Optional date (defaults to today)

        Returns:
            True if successful
        """
        try:
            if not 0 <= hour <= 23:
                logger.warning(f"Invalid hour {hour} for user {user_id}")
                return False

            db = get_supabase_db()
            act_date = activity_date or date.today().isoformat()
            is_active = steps >= SEDENTARY_THRESHOLD_STEPS

            # Upsert hourly data
            db.client.table("hourly_neat_activity").upsert({
                "user_id": user_id,
                "activity_date": act_date,
                "hour": hour,
                "steps": steps,
                "is_active": is_active,
                "source": source,
                "recorded_at": datetime.now().isoformat(),
            }, on_conflict="user_id,activity_date,hour").execute()

            # Update daily summary
            await self._update_daily_summary(user_id, act_date)

            return True

        except Exception as e:
            logger.error(f"Error recording hourly activity: {e}")
            return False

    async def get_hourly_breakdown(
        self,
        user_id: str,
        activity_date: str,
    ) -> List[HourlyActivity]:
        """
        Get hourly step breakdown for a specific day.

        Args:
            user_id: User ID
            activity_date: Date string (YYYY-MM-DD)

        Returns:
            List of HourlyActivity for each hour with data
        """
        try:
            db = get_supabase_db()

            result = db.client.table("hourly_neat_activity").select("*").eq(
                "user_id", user_id
            ).eq("activity_date", activity_date).order("hour").execute()

            activities = []
            for row in result.data:
                activities.append(HourlyActivity(
                    hour=row["hour"],
                    steps=row["steps"],
                    is_active=row.get("is_active", row["steps"] >= SEDENTARY_THRESHOLD_STEPS),
                    source=row.get("source", "unknown"),
                    recorded_at=datetime.fromisoformat(row["recorded_at"].replace("Z", "+00:00"))
                    if row.get("recorded_at") else datetime.now(),
                ))

            return activities

        except Exception as e:
            logger.error(f"Error getting hourly breakdown: {e}")
            return []

    async def detect_sedentary_hours(
        self,
        user_id: str,
        activity_date: str,
    ) -> List[int]:
        """
        Identify hours with insufficient activity (< 250 steps).

        Args:
            user_id: User ID
            activity_date: Date string (YYYY-MM-DD)

        Returns:
            List of hour numbers (0-23) that were sedentary
        """
        try:
            db = get_supabase_db()

            result = db.client.table("hourly_neat_activity").select(
                "hour, steps"
            ).eq("user_id", user_id).eq("activity_date", activity_date).execute()

            sedentary_hours = []
            for row in result.data:
                if row["steps"] < SEDENTARY_THRESHOLD_STEPS:
                    sedentary_hours.append(row["hour"])

            return sorted(sedentary_hours)

        except Exception as e:
            logger.error(f"Error detecting sedentary hours: {e}")
            return []

    async def get_current_hour_status(self, user_id: str) -> Dict[str, Any]:
        """
        Get the user's activity status for the current hour.

        Args:
            user_id: User ID

        Returns:
            Dict with current hour status and recommendations
        """
        try:
            current_hour = datetime.now().hour
            today = date.today().isoformat()

            hourly_data = await self.get_hourly_breakdown(user_id, today)

            current_hour_data = None
            for h in hourly_data:
                if h.hour == current_hour:
                    current_hour_data = h
                    break

            # Count consecutive sedentary hours
            sedentary_streak = 0
            for h in reversed(hourly_data):
                if h.hour < current_hour and not h.is_active:
                    sedentary_streak += 1
                elif h.hour < current_hour:
                    break

            is_sedentary = current_hour_data is None or not current_hour_data.is_active
            steps_this_hour = current_hour_data.steps if current_hour_data else 0

            return {
                "current_hour": current_hour,
                "steps_this_hour": steps_this_hour,
                "is_sedentary": is_sedentary,
                "sedentary_streak_hours": sedentary_streak,
                "needs_movement": is_sedentary and sedentary_streak >= 1,
                "recommendation": self._get_movement_recommendation(
                    sedentary_streak, steps_this_hour
                ),
            }

        except Exception as e:
            logger.error(f"Error getting current hour status: {e}")
            return {
                "current_hour": datetime.now().hour,
                "steps_this_hour": 0,
                "is_sedentary": True,
                "sedentary_streak_hours": 0,
                "needs_movement": False,
                "recommendation": "",
            }

    def _get_movement_recommendation(self, sedentary_hours: int, current_steps: int) -> str:
        """Generate a movement recommendation based on sedentary time."""
        if sedentary_hours == 0:
            return "Great job staying active!"
        elif sedentary_hours == 1:
            return "Time for a quick stretch! Stand up and move for 2-3 minutes."
        elif sedentary_hours == 2:
            return "You've been sitting for 2 hours. Take a 5-minute walk break."
        elif sedentary_hours >= 3:
            return f"Alert: {sedentary_hours} sedentary hours! Take a 10-minute activity break now."
        return ""

    async def _update_daily_summary(self, user_id: str, activity_date: str) -> None:
        """Update the daily NEAT summary from hourly data."""
        try:
            db = get_supabase_db()

            # Get all hourly data for the day
            hourly = await self.get_hourly_breakdown(user_id, activity_date)

            if not hourly:
                return

            total_steps = sum(h.steps for h in hourly)
            active_hours = sum(1 for h in hourly if h.is_active)
            sedentary_hours = len(hourly) - active_hours

            # Get current goal
            goal_result = db.client.table("user_neat_settings").select(
                "current_goal"
            ).eq("user_id", user_id).execute()

            current_goal = goal_result.data[0].get("current_goal", 5000) if goal_result.data else 5000
            goal_met = total_steps >= current_goal

            # Calculate longest sedentary period
            longest_sedentary = self._calculate_longest_sedentary_period(hourly)

            # Calculate NEAT score
            neat_score = self._calculate_neat_score_value(active_hours, total_steps, current_goal)

            # Upsert daily summary
            db.client.table("daily_neat_activity").upsert({
                "user_id": user_id,
                "activity_date": activity_date,
                "total_steps": total_steps,
                "step_goal": current_goal,
                "goal_met": goal_met,
                "active_hours": active_hours,
                "sedentary_hours": sedentary_hours,
                "neat_score": neat_score,
                "longest_sedentary_period": longest_sedentary,
                "updated_at": datetime.now().isoformat(),
            }, on_conflict="user_id,activity_date").execute()

        except Exception as e:
            logger.error(f"Error updating daily summary: {e}")

    def _calculate_longest_sedentary_period(self, hourly: List[HourlyActivity]) -> int:
        """Calculate the longest consecutive sedentary period in hours."""
        if not hourly:
            return 0

        # Sort by hour
        sorted_hourly = sorted(hourly, key=lambda x: x.hour)

        max_streak = 0
        current_streak = 0

        for h in sorted_hourly:
            if not h.is_active:
                current_streak += 1
                max_streak = max(max_streak, current_streak)
            else:
                current_streak = 0

        return max_streak

    # =========================================================================
    # 3. NEAT Score Calculation
    # =========================================================================

    async def calculate_neat_score(self, user_id: str, activity_date: str) -> NEATScore:
        """
        Calculate the NEAT score for a specific day.

        Formula: (active_hours / 16 * 50) + (steps / goal * 50), capped at 100

        Args:
            user_id: User ID
            activity_date: Date string (YYYY-MM-DD)

        Returns:
            NEATScore with detailed breakdown
        """
        try:
            db = get_supabase_db()

            # Get daily data
            result = db.client.table("daily_neat_activity").select("*").eq(
                "user_id", user_id
            ).eq("activity_date", activity_date).execute()

            if not result.data:
                # No data for this day, calculate from hourly if available
                hourly = await self.get_hourly_breakdown(user_id, activity_date)
                if hourly:
                    await self._update_daily_summary(user_id, activity_date)
                    result = db.client.table("daily_neat_activity").select("*").eq(
                        "user_id", user_id
                    ).eq("activity_date", activity_date).execute()

            if not result.data:
                return NEATScore(
                    total_score=0,
                    active_hours_component=0,
                    steps_component=0,
                    active_hours=0,
                    total_steps=0,
                    step_goal=5000,
                    rating="needs_improvement",
                )

            data = result.data[0]
            active_hours = data.get("active_hours", 0)
            total_steps = data.get("total_steps", 0)
            step_goal = data.get("step_goal", 5000)

            # Calculate components
            active_hours_component = min(50, (active_hours / DEFAULT_WAKING_HOURS) * 50)
            steps_component = min(50, (total_steps / step_goal) * 50) if step_goal > 0 else 0

            total_score = min(100, active_hours_component + steps_component)

            # Determine rating
            if total_score >= 90:
                rating = "excellent"
            elif total_score >= 70:
                rating = "good"
            elif total_score >= 50:
                rating = "fair"
            else:
                rating = "needs_improvement"

            return NEATScore(
                total_score=round(total_score, 1),
                active_hours_component=round(active_hours_component, 1),
                steps_component=round(steps_component, 1),
                active_hours=active_hours,
                total_steps=total_steps,
                step_goal=step_goal,
                rating=rating,
            )

        except Exception as e:
            logger.error(f"Error calculating NEAT score: {e}")
            return NEATScore(
                total_score=0,
                active_hours_component=0,
                steps_component=0,
                active_hours=0,
                total_steps=0,
                step_goal=5000,
                rating="needs_improvement",
            )

    def _calculate_neat_score_value(
        self,
        active_hours: int,
        total_steps: int,
        step_goal: int,
    ) -> float:
        """Calculate raw NEAT score value."""
        active_component = min(50, (active_hours / DEFAULT_WAKING_HOURS) * 50)
        steps_component = min(50, (total_steps / step_goal) * 50) if step_goal > 0 else 0
        return min(100, round(active_component + steps_component, 1))

    async def get_neat_score_trend(
        self,
        user_id: str,
        days: int = 7,
    ) -> List[Dict[str, Any]]:
        """
        Get NEAT score trend over the specified number of days.

        Args:
            user_id: User ID
            days: Number of days to include (default 7)

        Returns:
            List of daily scores with dates
        """
        try:
            db = get_supabase_db()
            start_date = (date.today() - timedelta(days=days - 1)).isoformat()

            result = db.client.table("daily_neat_activity").select(
                "activity_date, neat_score, total_steps, active_hours, goal_met"
            ).eq("user_id", user_id).gte(
                "activity_date", start_date
            ).order("activity_date", desc=True).execute()

            trend = []
            for row in result.data:
                trend.append({
                    "date": row["activity_date"],
                    "neat_score": row.get("neat_score", 0),
                    "total_steps": row.get("total_steps", 0),
                    "active_hours": row.get("active_hours", 0),
                    "goal_met": row.get("goal_met", False),
                })

            return trend

        except Exception as e:
            logger.error(f"Error getting NEAT score trend: {e}")
            return []

    async def save_daily_neat_score(self, user_id: str, activity_date: str) -> bool:
        """
        Persist the calculated NEAT score for a day.

        This is called at the end of the day or when syncing historical data.

        Args:
            user_id: User ID
            activity_date: Date string (YYYY-MM-DD)

        Returns:
            True if successful
        """
        try:
            # Calculate fresh score
            score = await self.calculate_neat_score(user_id, activity_date)

            db = get_supabase_db()

            # Update the daily record
            db.client.table("daily_neat_activity").update({
                "neat_score": score.total_score,
                "updated_at": datetime.now().isoformat(),
            }).eq("user_id", user_id).eq("activity_date", activity_date).execute()

            logger.info(f"Saved NEAT score {score.total_score} for user {user_id} on {activity_date}")
            return True

        except Exception as e:
            logger.error(f"Error saving NEAT score: {e}")
            return False

    # =========================================================================
    # 4. Streak Management
    # =========================================================================

    async def update_streak(self, user_id: str, streak_type: StreakType) -> int:
        """
        Update the specified streak for a user.

        Args:
            user_id: User ID
            streak_type: Type of streak to update

        Returns:
            Updated streak count
        """
        try:
            db = get_supabase_db()
            today = date.today()
            yesterday = (today - timedelta(days=1)).isoformat()

            # Get yesterday's data to check continuity
            yesterday_result = db.client.table("daily_neat_activity").select("*").eq(
                "user_id", user_id
            ).eq("activity_date", yesterday).execute()

            # Get current streak data
            streak_result = db.client.table("user_neat_streaks").select("*").eq(
                "user_id", user_id
            ).eq("streak_type", streak_type.value).execute()

            current_streak = 0
            longest_streak = 0

            if streak_result.data:
                current_streak = streak_result.data[0].get("current_streak", 0)
                longest_streak = streak_result.data[0].get("longest_streak", 0)

            # Check if streak continues based on yesterday's data
            streak_continues = False
            if yesterday_result.data:
                y_data = yesterday_result.data[0]
                if streak_type == StreakType.DAILY_GOAL:
                    streak_continues = y_data.get("goal_met", False)
                elif streak_type == StreakType.ACTIVE_HOURS:
                    streak_continues = y_data.get("active_hours", 0) >= 8
                elif streak_type == StreakType.NEAT_SCORE:
                    streak_continues = y_data.get("neat_score", 0) >= 70
                elif streak_type == StreakType.MOVEMENT_BREAKS:
                    streak_continues = y_data.get("longest_sedentary_period", 0) < 2

            if streak_continues:
                current_streak += 1
                longest_streak = max(longest_streak, current_streak)
            else:
                current_streak = 0

            # Update streak data
            db.client.table("user_neat_streaks").upsert({
                "user_id": user_id,
                "streak_type": streak_type.value,
                "current_streak": current_streak,
                "longest_streak": longest_streak,
                "last_updated": datetime.now().isoformat(),
            }, on_conflict="user_id,streak_type").execute()

            return current_streak

        except Exception as e:
            logger.error(f"Error updating streak: {e}")
            return 0

    async def get_user_streaks(self, user_id: str) -> UserStreaks:
        """
        Get all streak data for a user.

        Args:
            user_id: User ID

        Returns:
            UserStreaks with all streak types
        """
        try:
            db = get_supabase_db()

            result = db.client.table("user_neat_streaks").select("*").eq(
                "user_id", user_id
            ).execute()

            streaks = UserStreaks(
                daily_goal_streak=0,
                longest_daily_goal_streak=0,
                active_hours_streak=0,
                longest_active_hours_streak=0,
                neat_score_streak=0,
                longest_neat_score_streak=0,
                movement_breaks_streak=0,
            )

            for row in result.data:
                streak_type = row.get("streak_type")
                current = row.get("current_streak", 0)
                longest = row.get("longest_streak", 0)

                if streak_type == StreakType.DAILY_GOAL.value:
                    streaks.daily_goal_streak = current
                    streaks.longest_daily_goal_streak = longest
                elif streak_type == StreakType.ACTIVE_HOURS.value:
                    streaks.active_hours_streak = current
                    streaks.longest_active_hours_streak = longest
                elif streak_type == StreakType.NEAT_SCORE.value:
                    streaks.neat_score_streak = current
                    streaks.longest_neat_score_streak = longest
                elif streak_type == StreakType.MOVEMENT_BREAKS.value:
                    streaks.movement_breaks_streak = current

            return streaks

        except Exception as e:
            logger.error(f"Error getting user streaks: {e}")
            return UserStreaks(
                daily_goal_streak=0,
                longest_daily_goal_streak=0,
                active_hours_streak=0,
                longest_active_hours_streak=0,
                neat_score_streak=0,
                longest_neat_score_streak=0,
                movement_breaks_streak=0,
            )

    async def check_streak_milestones(self, user_id: str) -> List[str]:
        """
        Check if any streak milestones have been achieved.

        Args:
            user_id: User ID

        Returns:
            List of achievement IDs that were unlocked
        """
        try:
            streaks = await self.get_user_streaks(user_id)
            unlocked = []

            # Check consistency achievements
            streak_thresholds = [3, 7, 14, 30]

            for threshold in streak_thresholds:
                achievement_id = f"streak_{threshold}"
                if streaks.daily_goal_streak >= threshold:
                    # Check if already achieved
                    already_achieved = await self._has_achievement(user_id, achievement_id)
                    if not already_achieved:
                        await self._award_achievement(user_id, achievement_id, streaks.daily_goal_streak)
                        unlocked.append(achievement_id)

            return unlocked

        except Exception as e:
            logger.error(f"Error checking streak milestones: {e}")
            return []

    # =========================================================================
    # 5. Achievement System
    # =========================================================================

    async def check_and_award_achievements(self, user_id: str) -> List[Achievement]:
        """
        Check all achievement conditions and award any earned.

        Args:
            user_id: User ID

        Returns:
            List of newly awarded achievements
        """
        try:
            new_achievements = []

            # Get today's data
            today = date.today().isoformat()
            score = await self.calculate_neat_score(user_id, today)
            streaks = await self.get_user_streaks(user_id)

            # Check step milestones
            step_milestones = [
                ("first_1000", 1000),
                ("first_2500", 2500),
                ("first_5000", 5000),
                ("first_7500", 7500),
                ("first_10000", 10000),
            ]

            for ach_id, threshold in step_milestones:
                if score.total_steps >= threshold:
                    if not await self._has_achievement(user_id, ach_id):
                        await self._award_achievement(user_id, ach_id, score.total_steps)
                        new_achievements.append(self._get_achievement(ach_id, True))

            # Check NEAT score achievements
            neat_thresholds = [
                ("neat_50", 50),
                ("neat_75", 75),
                ("neat_90", 90),
            ]

            for ach_id, threshold in neat_thresholds:
                if score.total_score >= threshold:
                    if not await self._has_achievement(user_id, ach_id):
                        await self._award_achievement(user_id, ach_id, score.total_score)
                        new_achievements.append(self._get_achievement(ach_id, True))

            # Check active hours achievements
            active_thresholds = [
                ("active_8", 8),
                ("active_10", 10),
                ("active_12", 12),
            ]

            for ach_id, threshold in active_thresholds:
                if score.active_hours >= threshold:
                    if not await self._has_achievement(user_id, ach_id):
                        await self._award_achievement(user_id, ach_id, score.active_hours)
                        new_achievements.append(self._get_achievement(ach_id, True))

            # Check streak achievements
            streak_thresholds = [
                ("streak_3", 3),
                ("streak_7", 7),
                ("streak_14", 14),
                ("streak_30", 30),
            ]

            for ach_id, threshold in streak_thresholds:
                if streaks.daily_goal_streak >= threshold:
                    if not await self._has_achievement(user_id, ach_id):
                        await self._award_achievement(user_id, ach_id, streaks.daily_goal_streak)
                        new_achievements.append(self._get_achievement(ach_id, True))

            # Check weekly achievements
            week_achievements = await self._check_weekly_achievements(user_id)
            new_achievements.extend(week_achievements)

            if new_achievements:
                logger.info(f"User {user_id} earned {len(new_achievements)} new achievements")

            return new_achievements

        except Exception as e:
            logger.error(f"Error checking achievements: {e}")
            return []

    async def get_user_achievements(self, user_id: str) -> List[Achievement]:
        """
        Get all achievements earned by the user.

        Args:
            user_id: User ID

        Returns:
            List of earned achievements
        """
        try:
            db = get_supabase_db()

            result = db.client.table("user_neat_achievements").select("*").eq(
                "user_id", user_id
            ).order("achieved_at", desc=True).execute()

            achievements = []
            for row in result.data:
                ach_id = row.get("achievement_id")
                if ach_id in ACHIEVEMENT_DEFINITIONS:
                    ach_def = ACHIEVEMENT_DEFINITIONS[ach_id]
                    achievements.append(Achievement(
                        id=ach_id,
                        name=ach_def["name"],
                        description=ach_def["description"],
                        category=ach_def["category"].value,
                        threshold=ach_def["threshold"],
                        icon=ach_def["icon"],
                        points=ach_def["points"],
                        achieved=True,
                        achieved_at=datetime.fromisoformat(
                            row["achieved_at"].replace("Z", "+00:00")
                        ) if row.get("achieved_at") else None,
                        current_value=row.get("trigger_value"),
                        progress_percentage=100.0,
                    ))

            return achievements

        except Exception as e:
            logger.error(f"Error getting user achievements: {e}")
            return []

    async def get_available_achievements(self, user_id: str) -> List[Achievement]:
        """
        Get all unearned achievements with progress.

        Args:
            user_id: User ID

        Returns:
            List of unearned achievements with current progress
        """
        try:
            # Get earned achievement IDs
            earned = await self.get_user_achievements(user_id)
            earned_ids = {a.id for a in earned}

            # Get current stats for progress calculation
            today = date.today().isoformat()
            score = await self.calculate_neat_score(user_id, today)
            streaks = await self.get_user_streaks(user_id)
            week_days_met = await self._get_week_days_met(user_id)

            available = []

            for ach_id, ach_def in ACHIEVEMENT_DEFINITIONS.items():
                if ach_id in earned_ids:
                    continue

                # Calculate current value and progress
                current_value = 0.0
                threshold = ach_def["threshold"]

                category = ach_def["category"]
                if category == AchievementCategory.STEP_MILESTONES:
                    current_value = score.total_steps
                elif category == AchievementCategory.NEAT_SCORE:
                    current_value = score.total_score
                elif category == AchievementCategory.ACTIVE_HOURS:
                    current_value = score.active_hours
                elif category == AchievementCategory.CONSISTENCY:
                    current_value = streaks.daily_goal_streak
                elif category == AchievementCategory.WEEKLY:
                    current_value = week_days_met

                progress_pct = min(100.0, (current_value / threshold) * 100) if threshold > 0 else 0

                available.append(Achievement(
                    id=ach_id,
                    name=ach_def["name"],
                    description=ach_def["description"],
                    category=category.value,
                    threshold=threshold,
                    icon=ach_def["icon"],
                    points=ach_def["points"],
                    achieved=False,
                    current_value=current_value,
                    progress_percentage=round(progress_pct, 1),
                ))

            # Sort by progress (closest to completion first)
            available.sort(key=lambda x: x.progress_percentage or 0, reverse=True)

            return available

        except Exception as e:
            logger.error(f"Error getting available achievements: {e}")
            return []

    async def _has_achievement(self, user_id: str, achievement_id: str) -> bool:
        """Check if user has already earned an achievement."""
        try:
            db = get_supabase_db()

            result = db.client.table("user_neat_achievements").select("id").eq(
                "user_id", user_id
            ).eq("achievement_id", achievement_id).execute()

            return len(result.data) > 0

        except Exception as e:
            logger.error(f"Error checking achievement: {e}")
            return False

    async def _award_achievement(
        self,
        user_id: str,
        achievement_id: str,
        trigger_value: float,
    ) -> None:
        """Award an achievement to a user."""
        try:
            db = get_supabase_db()

            db.client.table("user_neat_achievements").insert({
                "user_id": user_id,
                "achievement_id": achievement_id,
                "trigger_value": trigger_value,
                "achieved_at": datetime.now().isoformat(),
            }).execute()

            logger.info(f"Awarded achievement {achievement_id} to user {user_id}")

        except Exception as e:
            logger.error(f"Error awarding achievement: {e}")

    def _get_achievement(self, achievement_id: str, achieved: bool = False) -> Achievement:
        """Get an achievement by ID."""
        ach_def = ACHIEVEMENT_DEFINITIONS.get(achievement_id, {})
        return Achievement(
            id=achievement_id,
            name=ach_def.get("name", "Unknown"),
            description=ach_def.get("description", ""),
            category=ach_def.get("category", AchievementCategory.STEP_MILESTONES).value,
            threshold=ach_def.get("threshold", 0),
            icon=ach_def.get("icon", "trophy"),
            points=ach_def.get("points", 0),
            achieved=achieved,
            achieved_at=datetime.now() if achieved else None,
        )

    async def _check_weekly_achievements(self, user_id: str) -> List[Achievement]:
        """Check and award weekly achievements."""
        try:
            days_met = await self._get_week_days_met(user_id)
            new_achievements = []

            if days_met >= 5:
                if not await self._has_achievement(user_id, "week_5_7"):
                    await self._award_achievement(user_id, "week_5_7", days_met)
                    new_achievements.append(self._get_achievement("week_5_7", True))

            if days_met >= 7:
                if not await self._has_achievement(user_id, "week_7_7"):
                    await self._award_achievement(user_id, "week_7_7", days_met)
                    new_achievements.append(self._get_achievement("week_7_7", True))

            return new_achievements

        except Exception as e:
            logger.error(f"Error checking weekly achievements: {e}")
            return []

    async def _get_week_days_met(self, user_id: str) -> int:
        """Get number of days goal was met this week."""
        try:
            db = get_supabase_db()
            today = date.today()
            week_start = today - timedelta(days=today.weekday())

            result = db.client.table("daily_neat_activity").select(
                "goal_met"
            ).eq("user_id", user_id).gte(
                "activity_date", week_start.isoformat()
            ).eq("goal_met", True).execute()

            return len(result.data)

        except Exception as e:
            logger.error(f"Error getting week days met: {e}")
            return 0

    # =========================================================================
    # 6. Movement Reminder Logic
    # =========================================================================

    async def should_send_reminder(self, user_id: str) -> bool:
        """
        Determine if a movement reminder should be sent now.

        Considers:
        - User's reminder preferences
        - Current hour status (sedentary streak)
        - Quiet hours
        - Work hours settings

        Args:
            user_id: User ID

        Returns:
            True if reminder should be sent
        """
        try:
            prefs = await self.get_reminder_preferences(user_id)

            if not prefs.enabled:
                return False

            now = datetime.now()
            current_time = now.time()

            # Check quiet hours
            if prefs.quiet_hours_start <= prefs.quiet_hours_end:
                # Normal case: quiet hours don't span midnight
                if prefs.quiet_hours_start <= current_time <= prefs.quiet_hours_end:
                    return False
            else:
                # Quiet hours span midnight
                if current_time >= prefs.quiet_hours_start or current_time <= prefs.quiet_hours_end:
                    return False

            # Check work hours if enabled
            if prefs.work_hours_only:
                if not (prefs.work_hours_start <= current_time <= prefs.work_hours_end):
                    return False

            # Check weekends if excluded
            if prefs.exclude_weekends and now.weekday() >= 5:
                return False

            # Get current hour status
            status = await self.get_current_hour_status(user_id)

            # Send reminder if sedentary for min_sedentary_hours
            if status["sedentary_streak_hours"] >= prefs.min_sedentary_hours:
                return True

            return False

        except Exception as e:
            logger.error(f"Error checking if reminder should be sent: {e}")
            return False

    async def get_reminder_preferences(self, user_id: str) -> ReminderPreferences:
        """
        Get user's movement reminder preferences.

        Args:
            user_id: User ID

        Returns:
            ReminderPreferences
        """
        try:
            db = get_supabase_db()

            result = db.client.table("user_neat_settings").select(
                "reminder_enabled, reminder_interval_minutes, quiet_hours_start, "
                "quiet_hours_end, work_hours_only, work_hours_start, work_hours_end, "
                "min_sedentary_hours, exclude_weekends"
            ).eq("user_id", user_id).execute()

            if not result.data:
                # Return defaults
                return ReminderPreferences(
                    enabled=True,
                    interval_minutes=60,
                    quiet_hours_start=time(22, 0),
                    quiet_hours_end=time(7, 0),
                    work_hours_only=False,
                    work_hours_start=time(9, 0),
                    work_hours_end=time(17, 0),
                    min_sedentary_hours=2,
                    exclude_weekends=False,
                )

            data = result.data[0]

            return ReminderPreferences(
                enabled=data.get("reminder_enabled", True),
                interval_minutes=data.get("reminder_interval_minutes", 60),
                quiet_hours_start=self._parse_time(data.get("quiet_hours_start", "22:00")),
                quiet_hours_end=self._parse_time(data.get("quiet_hours_end", "07:00")),
                work_hours_only=data.get("work_hours_only", False),
                work_hours_start=self._parse_time(data.get("work_hours_start", "09:00")),
                work_hours_end=self._parse_time(data.get("work_hours_end", "17:00")),
                min_sedentary_hours=data.get("min_sedentary_hours", 2),
                exclude_weekends=data.get("exclude_weekends", False),
            )

        except Exception as e:
            logger.error(f"Error getting reminder preferences: {e}")
            return ReminderPreferences(
                enabled=True,
                interval_minutes=60,
                quiet_hours_start=time(22, 0),
                quiet_hours_end=time(7, 0),
                work_hours_only=False,
                work_hours_start=time(9, 0),
                work_hours_end=time(17, 0),
                min_sedentary_hours=2,
                exclude_weekends=False,
            )

    async def update_reminder_preferences(
        self,
        user_id: str,
        prefs: Dict[str, Any],
    ) -> bool:
        """
        Update user's movement reminder preferences.

        Args:
            user_id: User ID
            prefs: Dictionary of preference updates

        Returns:
            True if successful
        """
        try:
            db = get_supabase_db()

            update_data = {}

            if "enabled" in prefs:
                update_data["reminder_enabled"] = prefs["enabled"]
            if "interval_minutes" in prefs:
                update_data["reminder_interval_minutes"] = prefs["interval_minutes"]
            if "quiet_hours_start" in prefs:
                update_data["quiet_hours_start"] = prefs["quiet_hours_start"]
            if "quiet_hours_end" in prefs:
                update_data["quiet_hours_end"] = prefs["quiet_hours_end"]
            if "work_hours_only" in prefs:
                update_data["work_hours_only"] = prefs["work_hours_only"]
            if "work_hours_start" in prefs:
                update_data["work_hours_start"] = prefs["work_hours_start"]
            if "work_hours_end" in prefs:
                update_data["work_hours_end"] = prefs["work_hours_end"]
            if "min_sedentary_hours" in prefs:
                update_data["min_sedentary_hours"] = prefs["min_sedentary_hours"]
            if "exclude_weekends" in prefs:
                update_data["exclude_weekends"] = prefs["exclude_weekends"]

            if update_data:
                update_data["updated_at"] = datetime.now().isoformat()

                db.client.table("user_neat_settings").upsert({
                    "user_id": user_id,
                    **update_data,
                }, on_conflict="user_id").execute()

                logger.info(f"Updated reminder preferences for user {user_id}")

            return True

        except Exception as e:
            logger.error(f"Error updating reminder preferences: {e}")
            return False

    def _parse_time(self, time_str: str) -> time:
        """Parse a time string to a time object."""
        try:
            if isinstance(time_str, time):
                return time_str
            parts = time_str.split(":")
            return time(int(parts[0]), int(parts[1]) if len(parts) > 1 else 0)
        except Exception:
            return time(0, 0)

    # =========================================================================
    # 7. AI Context for Gemini
    # =========================================================================

    async def get_neat_context_for_ai(self, user_id: str) -> str:
        """
        Generate a context string for AI/Gemini prompts about user's NEAT activity.

        Includes current goals, trends, patterns, and achievements.

        Args:
            user_id: User ID

        Returns:
            Formatted context string for AI prompts
        """
        try:
            # Gather all relevant data
            goal = await self.get_user_neat_goal(user_id)
            today = date.today().isoformat()
            score = await self.calculate_neat_score(user_id, today)
            trend = await self.get_neat_score_trend(user_id, 7)
            streaks = await self.get_user_streaks(user_id)
            achievements = await self.get_user_achievements(user_id)
            sedentary_hours = await self.detect_sedentary_hours(user_id, today)

            # Calculate trend direction
            trend_direction = "stable"
            if len(trend) >= 3:
                recent_avg = sum(t["neat_score"] for t in trend[:3]) / 3
                older_avg = sum(t["neat_score"] for t in trend[3:]) / max(1, len(trend) - 3)
                if recent_avg > older_avg * 1.1:
                    trend_direction = "improving"
                elif recent_avg < older_avg * 0.9:
                    trend_direction = "declining"

            # Build sedentary pattern description
            if not sedentary_hours:
                sedentary_pattern = "No significant sedentary periods today."
            elif len(sedentary_hours) <= 3:
                sedentary_pattern = f"Minor sedentary periods at hours: {', '.join(map(str, sedentary_hours))}."
            else:
                sedentary_pattern = f"Multiple sedentary hours detected ({len(sedentary_hours)} hours). Consider more frequent movement breaks."

            # Build achievements summary
            recent_achievements = achievements[:3] if achievements else []
            if recent_achievements:
                ach_names = [a.name for a in recent_achievements]
                achievements_summary = f"Recent achievements: {', '.join(ach_names)}."
            else:
                achievements_summary = "No achievements yet. Encourage first milestone."

            # Build streak info
            if streaks.daily_goal_streak > 0:
                streak_info = f"Current streak: {streaks.daily_goal_streak} days. Longest: {streaks.longest_daily_goal_streak} days."
            else:
                streak_info = "No active streak. Encourage starting a new streak."

            # Generate recommendations
            recommendations = self._generate_ai_recommendations(goal, score, streaks, sedentary_hours)

            # Build context string
            context_parts = [
                "## NEAT Activity Context",
                "",
                "### Current Status",
                f"- Step Goal: {goal.current_goal:,} steps/day (Week {goal.week_number} of progressive program)",
                f"- Today's Progress: {goal.today_steps:,} / {goal.current_goal:,} ({goal.progress_percentage:.0f}%)",
                f"- Goal Met Today: {'Yes' if goal.goal_met else 'No'}",
                f"- NEAT Score: {score.total_score}/100 ({score.rating})",
                f"- Active Hours: {score.active_hours} hours",
                "",
                "### Trends and Patterns",
                f"- 7-Day Trend: {trend_direction.title()}",
                f"- {sedentary_pattern}",
                "",
                "### Achievements and Streaks",
                f"- {streak_info}",
                f"- {achievements_summary}",
                "",
                "### Recommendations",
            ]

            for rec in recommendations:
                context_parts.append(f"- {rec}")

            return "\n".join(context_parts)

        except Exception as e:
            logger.error(f"Error generating AI context: {e}")
            return "## NEAT Activity Context\nUnable to retrieve activity data."

    def _generate_ai_recommendations(
        self,
        goal: NEATGoal,
        score: NEATScore,
        streaks: UserStreaks,
        sedentary_hours: List[int],
    ) -> List[str]:
        """Generate personalized recommendations for AI context."""
        recommendations = []

        # Progress-based recommendations
        if goal.progress_percentage < 50:
            recommendations.append(
                f"User is behind on daily goal ({goal.remaining_steps:,} steps remaining). "
                "Suggest accessible ways to add movement."
            )
        elif goal.progress_percentage >= 100:
            recommendations.append(
                "Daily goal achieved! Celebrate success and encourage maintaining the habit."
            )

        # NEAT score recommendations
        if score.rating == "needs_improvement":
            recommendations.append(
                "NEAT score is low. Focus on increasing both active hours and step count."
            )
        elif score.rating == "excellent":
            recommendations.append(
                "Excellent NEAT score! User is very active today."
            )

        # Sedentary pattern recommendations
        if len(sedentary_hours) >= 3:
            recommendations.append(
                "Multiple sedentary hours detected. Suggest hourly movement breaks."
            )

        # Streak recommendations
        if streaks.daily_goal_streak == 0:
            recommendations.append(
                "No active streak. Encourage starting a new streak with achievable goals."
            )
        elif streaks.daily_goal_streak == 6:
            recommendations.append(
                "User is one day away from a 7-day streak! Strong motivation opportunity."
            )
        elif streaks.daily_goal_streak >= 7:
            recommendations.append(
                f"Impressive {streaks.daily_goal_streak}-day streak! Acknowledge consistency."
            )

        return recommendations


# =============================================================================
# Singleton and Factory
# =============================================================================

# Singleton instance
_neat_service: Optional[NEATService] = None


def get_neat_service() -> NEATService:
    """
    Get the singleton NEATService instance.

    Returns:
        NEATService instance
    """
    global _neat_service
    if _neat_service is None:
        _neat_service = NEATService()
    return _neat_service
