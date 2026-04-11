"""
NEAT Gamification Logging Mixin
================================
NEAT (Non-Exercise Activity Thermogenesis) event logging,
patterns analysis, and AI context generation.
"""

from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
import logging

from core.db import get_supabase_db
from core.timezone_utils import get_user_today
from services.user_context.models import EventType, NeatPatterns

logger = logging.getLogger(__name__)


class NeatLoggingMixin:
    """Mixin for NEAT gamification event logging and analytics."""

    async def log_neat_event(
        self,
        user_id: str,
        event_type: EventType,
        event_data: Dict[str, Any],
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Generic method to log NEAT-related events with consistent structure."""
        context = self._build_context(
            device=device,
            app_version=app_version,
            screen_name="neat",
            extra_context={
                "neat_tracking_version": "1.0",
                "is_neat_event": True,
            },
        )

        logger.info(
            f"[NEAT Event] User {user_id}: {event_type.value} - data={event_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=event_data,
            context=context,
        )

    async def log_step_goal_set(
        self,
        user_id: str,
        new_goal: int,
        previous_goal: Optional[int] = None,
        is_progressive: bool = False,
        source: str = "manual",
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user sets or changes their step goal."""
        event_data = {
            "new_goal": new_goal,
            "previous_goal": previous_goal,
            "is_progressive": is_progressive,
            "source": source,
            "goal_change": new_goal - previous_goal if previous_goal else None,
            "set_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Step Goal Set] User {user_id}: {previous_goal or 'none'} -> {new_goal} "
            f"(progressive={is_progressive}, source={source})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_STEP_GOAL_SET,
            event_data=event_data,
            device=device,
        )

    async def log_step_goal_achieved(
        self,
        user_id: str,
        goal: int,
        actual_steps: int,
        active_hours: int,
        streak_days: int,
        xp_earned: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user achieves their daily step goal."""
        event_data = {
            "goal": goal,
            "actual_steps": actual_steps,
            "steps_over_goal": actual_steps - goal,
            "completion_percentage": round((actual_steps / goal) * 100, 1) if goal > 0 else 0,
            "active_hours": active_hours,
            "streak_days": streak_days,
            "xp_earned": xp_earned,
            "achieved_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Goal Achieved] User {user_id}: {actual_steps}/{goal} steps, "
            f"streak={streak_days} days, +{xp_earned} XP"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_STEP_GOAL_ACHIEVED,
            event_data=event_data,
            device=device,
        )

    async def log_sedentary_alert_received(
        self,
        user_id: str,
        sedentary_minutes: int,
        time_of_day: str,
        day_of_week: str,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user receives a sedentary/movement reminder."""
        event_data = {
            "sedentary_minutes": sedentary_minutes,
            "time_of_day": time_of_day,
            "day_of_week": day_of_week,
            "received_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Sedentary Alert] User {user_id}: {sedentary_minutes} min sedentary "
            f"({time_of_day}, {day_of_week})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_SEDENTARY_ALERT_RECEIVED,
            event_data=event_data,
            device=device,
        )

    async def log_sedentary_alert_acted_on(
        self,
        user_id: str,
        response_time_seconds: int,
        steps_after_alert: int,
        active_minutes: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user responds to a sedentary alert by moving."""
        event_data = {
            "response_time_seconds": response_time_seconds,
            "response_time_minutes": round(response_time_seconds / 60, 1),
            "steps_after_alert": steps_after_alert,
            "active_minutes": active_minutes,
            "acted_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Alert Acted On] User {user_id}: responded in "
            f"{response_time_seconds}s, {steps_after_alert} steps"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_SEDENTARY_ALERT_ACTED_ON,
            event_data=event_data,
            device=device,
        )

    async def log_neat_score_calculated(
        self,
        user_id: str,
        score: int,
        steps: int,
        active_hours: int,
        sedentary_breaks: int,
        bonus_activities: Optional[List[str]] = None,
        device: Optional[str] = None,
        timezone_str: str = "UTC",
    ) -> Optional[str]:
        """Log daily NEAT score calculation."""
        event_data = {
            "score": score,
            "steps": steps,
            "active_hours": active_hours,
            "sedentary_breaks": sedentary_breaks,
            "bonus_activities": bonus_activities or [],
            "calculated_at": datetime.now().isoformat(),
            "date": get_user_today(timezone_str),
        }

        logger.info(
            f"[NEAT Score] User {user_id}: score={score}, steps={steps}, "
            f"active_hrs={active_hours}"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_SCORE_CALCULATED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_achievement_earned(
        self,
        user_id: str,
        achievement_id: str,
        achievement_name: str,
        achievement_type: str,
        xp_earned: int,
        description: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user earns a NEAT achievement."""
        event_data = {
            "achievement_id": achievement_id,
            "achievement_name": achievement_name,
            "achievement_type": achievement_type,
            "xp_earned": xp_earned,
            "description": description,
            "earned_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Achievement] User {user_id}: {achievement_name} "
            f"(type={achievement_type}, +{xp_earned} XP)"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_ACHIEVEMENT_EARNED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_streak_milestone(
        self,
        user_id: str,
        streak_days: int,
        milestone_name: str,
        xp_earned: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user hits a streak milestone."""
        event_data = {
            "streak_days": streak_days,
            "milestone_name": milestone_name,
            "xp_earned": xp_earned,
            "achieved_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Streak Milestone] User {user_id}: {streak_days} days - {milestone_name}"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_STREAK_MILESTONE,
            event_data=event_data,
            device=device,
        )

    async def log_progressive_goal_increased(
        self,
        user_id: str,
        old_goal: int,
        new_goal: int,
        increase_amount: int,
        reason: str,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when system automatically increases user's step goal."""
        event_data = {
            "old_goal": old_goal,
            "new_goal": new_goal,
            "increase_amount": increase_amount,
            "increase_percentage": round((increase_amount / old_goal) * 100, 1) if old_goal > 0 else 0,
            "reason": reason,
            "increased_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Goal Increased] User {user_id}: {old_goal} -> {new_goal} "
            f"(+{increase_amount}, reason={reason})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_PROGRESSIVE_GOAL_INCREASED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_challenge_accepted(
        self,
        user_id: str,
        challenge_id: str,
        challenge_name: str,
        target_value: int,
        unit: str,
        xp_reward: int,
        expires_at: datetime,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user accepts a daily NEAT challenge."""
        event_data = {
            "challenge_id": challenge_id,
            "challenge_name": challenge_name,
            "target_value": target_value,
            "unit": unit,
            "xp_reward": xp_reward,
            "expires_at": expires_at.isoformat(),
            "accepted_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Challenge Accepted] User {user_id}: {challenge_name} "
            f"(target={target_value} {unit})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_CHALLENGE_ACCEPTED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_challenge_completed(
        self,
        user_id: str,
        challenge_id: str,
        challenge_name: str,
        target_value: int,
        actual_value: int,
        unit: str,
        xp_earned: int,
        time_to_complete_minutes: Optional[int] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user completes a NEAT challenge."""
        event_data = {
            "challenge_id": challenge_id,
            "challenge_name": challenge_name,
            "target_value": target_value,
            "actual_value": actual_value,
            "unit": unit,
            "completion_percentage": round((actual_value / target_value) * 100, 1) if target_value > 0 else 0,
            "xp_earned": xp_earned,
            "time_to_complete_minutes": time_to_complete_minutes,
            "completed_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Challenge Completed] User {user_id}: {challenge_name} "
            f"({actual_value}/{target_value} {unit}, +{xp_earned} XP)"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_CHALLENGE_COMPLETED,
            event_data=event_data,
            device=device,
        )

    async def log_neat_level_up(
        self,
        user_id: str,
        old_level: str,
        new_level: str,
        old_xp: int,
        new_xp: int,
        total_xp: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user levels up in the NEAT gamification system."""
        event_data = {
            "old_level": old_level,
            "new_level": new_level,
            "old_xp": old_xp,
            "new_xp": new_xp,
            "total_xp": total_xp,
            "leveled_up_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[NEAT Level Up] User {user_id}: {old_level} -> {new_level} "
            f"(total XP: {total_xp})"
        )

        return await self.log_neat_event(
            user_id=user_id,
            event_type=EventType.NEAT_LEVEL_UP,
            event_data=event_data,
            device=device,
        )

    async def get_neat_patterns(
        self,
        user_id: str,
        days: int = 30,
        timezone_str: str = "UTC",
    ) -> NeatPatterns:
        """Analyze user's NEAT activity patterns from context logs."""
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()
            week_cutoff = (datetime.now() - timedelta(days=7)).isoformat()
            last_week_start = (datetime.now() - timedelta(days=14)).isoformat()

            neat_event_types = [
                EventType.NEAT_STEP_GOAL_SET.value,
                EventType.NEAT_STEP_GOAL_ACHIEVED.value,
                EventType.NEAT_SEDENTARY_ALERT_RECEIVED.value,
                EventType.NEAT_SEDENTARY_ALERT_ACTED_ON.value,
                EventType.NEAT_SCORE_CALCULATED.value,
                EventType.NEAT_ACHIEVEMENT_EARNED.value,
                EventType.NEAT_STREAK_MILESTONE.value,
                EventType.NEAT_PROGRESSIVE_GOAL_INCREASED.value,
                EventType.NEAT_LEVEL_UP.value,
            ]

            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", neat_event_types
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=True
            ).execute()

            events = response.data or []

            patterns = NeatPatterns()

            if not events:
                return patterns

            # Get most recent step goal
            goal_events = [e for e in events if e["event_type"] == EventType.NEAT_STEP_GOAL_SET.value]
            if goal_events:
                latest_goal = goal_events[0]["event_data"]
                patterns.current_step_goal = latest_goal.get("new_goal", 7500)
                patterns.is_progressive_goal = latest_goal.get("is_progressive", False)
                if len(goal_events) > 1:
                    patterns.initial_step_goal = goal_events[-1]["event_data"].get("new_goal", 3000)

            # Analyze score events
            score_events = [e for e in events if e["event_type"] == EventType.NEAT_SCORE_CALCULATED.value]

            this_week_scores = [
                e["event_data"].get("score", 0)
                for e in score_events
                if e["created_at"] >= week_cutoff
            ]

            last_week_scores = [
                e["event_data"].get("score", 0)
                for e in score_events
                if last_week_start <= e["created_at"] < week_cutoff
            ]

            if this_week_scores:
                patterns.week_avg_neat_score = sum(this_week_scores) / len(this_week_scores)
                patterns.today_neat_score = this_week_scores[0] if this_week_scores else 0

            if last_week_scores:
                patterns.last_week_avg_neat_score = sum(last_week_scores) / len(last_week_scores)

            # Determine trend
            if patterns.week_avg_neat_score > patterns.last_week_avg_neat_score + 5:
                patterns.neat_score_trend = "improving"
            elif patterns.week_avg_neat_score < patterns.last_week_avg_neat_score - 5:
                patterns.neat_score_trend = "declining"
            else:
                patterns.neat_score_trend = "stable"

            # Get weekly step totals
            patterns.weekly_step_totals = [
                e["event_data"].get("steps", 0)
                for e in score_events
                if e["created_at"] >= week_cutoff
            ][:7]

            patterns.weekly_active_hours = [
                e["event_data"].get("active_hours", 0)
                for e in score_events
                if e["created_at"] >= week_cutoff
            ][:7]

            # Get today's data
            today = get_user_today(timezone_str)
            today_scores = [
                e for e in score_events
                if e["event_data"].get("date") == today
            ]
            if today_scores:
                today_data = today_scores[0]["event_data"]
                patterns.today_steps = today_data.get("steps", 0)
                patterns.today_active_hours = today_data.get("active_hours", 0)
                if patterns.current_step_goal > 0:
                    patterns.today_step_percentage = (
                        patterns.today_steps / patterns.current_step_goal
                    ) * 100

            # Analyze streaks from goal achieved events
            goal_achieved_events = [
                e for e in events
                if e["event_type"] == EventType.NEAT_STEP_GOAL_ACHIEVED.value
            ]
            if goal_achieved_events:
                latest_streak = goal_achieved_events[0]["event_data"].get("streak_days", 0)
                patterns.current_streak_days = latest_streak
                patterns.longest_streak_days = max(
                    e["event_data"].get("streak_days", 0)
                    for e in goal_achieved_events
                )

            # Analyze sedentary patterns
            sedentary_alerts = [
                e for e in events
                if e["event_type"] == EventType.NEAT_SEDENTARY_ALERT_RECEIVED.value
            ]
            sedentary_acted = [
                e for e in events
                if e["event_type"] == EventType.NEAT_SEDENTARY_ALERT_ACTED_ON.value
            ]

            today_alerts = [
                a for a in sedentary_alerts
                if a["created_at"][:10] == today
            ]
            patterns.sedentary_alert_count_today = len(today_alerts)
            patterns.sedentary_alerts_acted_on = len([
                a for a in sedentary_acted
                if a["created_at"][:10] == today
            ])

            # Find most sedentary period
            if sedentary_alerts:
                time_counts: Dict[str, int] = {}
                for alert in sedentary_alerts:
                    time_of_day = alert["event_data"].get("time_of_day", "")
                    day_of_week = alert["event_data"].get("day_of_week", "")
                    key = f"{time_of_day} {day_of_week}s"
                    time_counts[key] = time_counts.get(key, 0) + 1

                if time_counts:
                    patterns.most_sedentary_period = max(
                        time_counts.keys(),
                        key=lambda k: time_counts[k]
                    )

            # Get level and XP from most recent level up event
            level_up_events = [e for e in events if e["event_type"] == EventType.NEAT_LEVEL_UP.value]
            if level_up_events:
                latest_level = level_up_events[0]["event_data"]
                patterns.current_level = latest_level.get("new_level", "Couch Potato")
                patterns.current_xp = latest_level.get("total_xp", 0)

            # Get badges earned
            achievement_events = [
                e for e in events
                if e["event_type"] == EventType.NEAT_ACHIEVEMENT_EARNED.value
            ]
            patterns.badges_earned = [
                e["event_data"].get("achievement_name", "")
                for e in achievement_events
            ]

            return patterns

        except Exception as e:
            logger.error(f"Failed to get NEAT patterns: {e}", exc_info=True)
            return NeatPatterns()

    async def get_neat_context_for_ai(
        self,
        user_id: str,
        days: int = 30,
        timezone_str: str = "UTC",
    ) -> str:
        """Get formatted NEAT context string for AI prompts."""
        patterns = await self.get_neat_patterns(user_id, days, timezone_str)
        return patterns.get_ai_context()

    async def get_neat_analytics(
        self,
        user_id: str,
        days: int = 30,
        timezone_str: str = "UTC",
    ) -> Dict[str, Any]:
        """Get comprehensive NEAT analytics for a user."""
        patterns = await self.get_neat_patterns(user_id, days, timezone_str)

        return {
            "user_id": user_id,
            "period_days": days,
            "patterns": patterns.to_dict(),
            "ai_context": patterns.get_ai_context(),
            "generated_at": datetime.now().isoformat(),
        }
