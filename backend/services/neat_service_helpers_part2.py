"""Second part of neat_service_helpers.py (auto-split for size)."""
from __future__ import annotations
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta, date
import logging
from core.db import get_supabase_db

logger = logging.getLogger(__name__)


def _get_neat_types():
    """Lazy import to avoid circular dependency with neat_service.py."""
    from services.neat_service import Achievement, AchievementCategory, UserStreaks, StreakType, ACHIEVEMENT_DEFINITIONS
    return Achievement, AchievementCategory, UserStreaks, StreakType, ACHIEVEMENT_DEFINITIONS


class NEATServicePart2:
    """Second half of NEATService methods. Use as mixin."""

    async def get_user_streaks(self, user_id: str):
        """
        Get all streak data for a user.

        Args:
            user_id: User ID

        Returns:
            UserStreaks with all streak types
        """
        Achievement, AchievementCategory, UserStreaks, StreakType, ACHIEVEMENT_DEFINITIONS = _get_neat_types()
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
        Achievement, AchievementCategory, _, _, ACHIEVEMENT_DEFINITIONS = _get_neat_types()
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
        Achievement, AchievementCategory, _, _, ACHIEVEMENT_DEFINITIONS = _get_neat_types()
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
        Achievement, AchievementCategory, _, _, ACHIEVEMENT_DEFINITIONS = _get_neat_types()
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
        Achievement, AchievementCategory, _, _, ACHIEVEMENT_DEFINITIONS = _get_neat_types()
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
        Achievement, _, _, _, _ = _get_neat_types()
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
