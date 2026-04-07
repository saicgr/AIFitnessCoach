"""Helper functions extracted from neat_service.
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
from __future__ import annotations
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta, date
import logging
import time
from core.db import get_supabase_db
from models.neat import NEATGoal
from services.neat_service_helpers_part2 import NEATServicePart2

logger = logging.getLogger(__name__)


class NEATService(NEATServicePart2):
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

            from services.neat_service import SEDENTARY_THRESHOLD_STEPS  # lazy
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
            from services.neat_service import HourlyActivity, SEDENTARY_THRESHOLD_STEPS  # lazy
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
            from services.neat_service import SEDENTARY_THRESHOLD_STEPS  # lazy
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



# Singleton instance
_neatservice_instance: Optional[NEATService] = None


def get_neat_service() -> NEATService:
    """Get or create the singleton NEATService instance."""
    global _neatservice_instance
    if _neatservice_instance is None:
        _neatservice_instance = NEATService()
    return _neatservice_instance
