"""
WearOS Watch Logging Mixin
===========================
Watch activity context, sync events, and AI context generation.
"""

from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import logging

from core.db import get_supabase_db
from services.user_context.models import EventType

logger = logging.getLogger(__name__)


class WatchLoggingMixin:
    """Mixin for WearOS watch event logging and context."""

    async def get_watch_activity_context(
        self,
        user_id: str,
        days: int = 7,
    ) -> Dict[str, Any]:
        """Get WearOS watch activity context for AI personalization."""
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            sync_response = db.client.table("wearos_sync_events").select(
                "sync_type, items_synced, synced_at"
            ).eq("user_id", user_id).gte("synced_at", cutoff).order("synced_at", desc=True).execute()

            sync_events = sync_response.data or []

            workout_logs_response = db.client.table("workout_logs").select(
                "id, logged_at"
            ).eq("user_id", user_id).eq("device_source", "watch").gte("logged_at", cutoff).execute()

            watch_workout_logs = workout_logs_response.data or []

            food_logs_response = db.client.table("food_logs").select(
                "id, logged_at"
            ).eq("user_id", user_id).eq("device_source", "watch").gte("logged_at", cutoff).execute()

            watch_food_logs = food_logs_response.data or []

            activity_response = db.client.table("daily_activity").select(
                "steps, active_minutes, calories_burned, activity_date"
            ).eq("user_id", user_id).eq("source", "watch").gte(
                "activity_date", cutoff[:10]
            ).order("activity_date", desc=True).limit(1).execute()

            today_activity = activity_response.data[0] if activity_response.data else None

            total_syncs = len(sync_events)
            last_sync = sync_events[0]["synced_at"] if sync_events else None
            workouts_logged_on_watch = len(watch_workout_logs)
            foods_logged_on_watch = len(watch_food_logs)

            watch_active = total_syncs >= 3 or workouts_logged_on_watch >= 1

            return {
                "watch_connected": watch_active,
                "last_watch_sync": last_sync,
                "total_syncs_this_week": total_syncs,
                "workouts_logged_on_watch": workouts_logged_on_watch,
                "foods_logged_on_watch": foods_logged_on_watch,
                "watch_step_count": today_activity["steps"] if today_activity else None,
                "watch_active_minutes": today_activity["active_minutes"] if today_activity else None,
                "watch_calories_burned": today_activity["calories_burned"] if today_activity else None,
            }

        except Exception as e:
            logger.error(f"Error getting watch activity context: {e}")
            return {
                "watch_connected": False,
                "last_watch_sync": None,
                "total_syncs_this_week": 0,
                "workouts_logged_on_watch": 0,
                "foods_logged_on_watch": 0,
            }

    async def get_watch_context_for_ai(
        self,
        user_id: str,
        days: int = 7,
    ) -> str:
        """Get formatted WearOS watch context string for AI prompts."""
        context = await self.get_watch_activity_context(user_id, days)

        if not context.get("watch_connected"):
            return ""

        parts = []
        parts.append("User has a WearOS smartwatch connected.")

        if context.get("last_watch_sync"):
            parts.append(f"Last sync: {context['last_watch_sync']}")

        if context.get("workouts_logged_on_watch", 0) > 0:
            parts.append(
                f"They have logged {context['workouts_logged_on_watch']} workout(s) "
                "directly from their watch this week."
            )

        if context.get("foods_logged_on_watch", 0) > 0:
            parts.append(
                f"They have logged {context['foods_logged_on_watch']} food item(s) "
                "via voice input on their watch."
            )

        if context.get("watch_step_count"):
            parts.append(
                f"Today's step count from watch: {context['watch_step_count']:,} steps."
            )

        if context.get("watch_active_minutes"):
            parts.append(
                f"Today's active minutes: {context['watch_active_minutes']} minutes."
            )

        return " ".join(parts)

    async def log_watch_workout_logged(
        self,
        user_id: str,
        workout_id: Optional[str],
        session_id: str,
        sets_count: int,
        total_volume_kg: Optional[float] = None,
        device_id: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a workout is logged from WearOS watch."""
        event_data = {
            "workout_id": workout_id,
            "session_id": session_id,
            "sets_count": sets_count,
            "total_volume_kg": total_volume_kg,
            "device_id": device_id,
            "logged_at": datetime.now().isoformat(),
        }

        context = self._build_context(device="wearos")

        logger.info(f"[Watch Workout Logged] User {user_id}, sets: {sets_count}")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WATCH_WORKOUT_LOGGED,
            event_data=event_data,
            context=context,
        )

    async def log_watch_food_logged(
        self,
        user_id: str,
        food_name: str,
        calories: int,
        input_type: str,
        meal_type: str,
        device_id: Optional[str] = None,
    ) -> Optional[str]:
        """Log when food is logged from WearOS watch via voice or manual input."""
        event_data = {
            "food_name": food_name,
            "calories": calories,
            "input_type": input_type,
            "meal_type": meal_type,
            "device_id": device_id,
            "logged_at": datetime.now().isoformat(),
        }

        context = self._build_context(device="wearos")

        logger.info(
            f"[Watch Food Logged] User {user_id}, "
            f"food: {food_name}, calories: {calories}, input: {input_type}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WATCH_FOOD_LOGGED,
            event_data=event_data,
            context=context,
        )

    async def log_watch_activity_synced(
        self,
        user_id: str,
        steps: int,
        calories_burned: int,
        active_minutes: int,
        hr_samples_count: int = 0,
        device_id: Optional[str] = None,
    ) -> Optional[str]:
        """Log when activity data is synced from WearOS watch."""
        event_data = {
            "steps": steps,
            "calories_burned": calories_burned,
            "active_minutes": active_minutes,
            "hr_samples_count": hr_samples_count,
            "device_id": device_id,
            "synced_at": datetime.now().isoformat(),
        }

        context = self._build_context(device="wearos")

        logger.info(
            f"[Watch Activity Synced] User {user_id}, "
            f"steps: {steps}, active_minutes: {active_minutes}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WATCH_ACTIVITY_SYNCED,
            event_data=event_data,
            context=context,
        )
