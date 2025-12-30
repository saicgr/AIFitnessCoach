"""
User Context Service
====================
Handles logging and retrieval of user interaction events for analytics,
AI personalization, and improving recommendations.

Event Types:
- mood_checkin: User selected a mood for quick workout
- workout_start: User started a workout
- workout_complete: User completed a workout
- score_view: User viewed the scoring screen
- nutrition_log: User logged food
- feature_interaction: User interacted with a feature
- screen_view: User viewed a screen
- error: Error occurred
"""

from dataclasses import dataclass
from datetime import datetime, timedelta, date
from typing import Optional, List, Dict, Any
from enum import Enum
import logging

from core.db import get_supabase_db

logger = logging.getLogger(__name__)


class EventType(str, Enum):
    """Types of user events to track."""
    MOOD_CHECKIN = "mood_checkin"
    WORKOUT_START = "workout_start"
    WORKOUT_COMPLETE = "workout_complete"
    SCORE_VIEW = "score_view"
    NUTRITION_LOG = "nutrition_log"
    FEATURE_INTERACTION = "feature_interaction"
    SCREEN_VIEW = "screen_view"
    ERROR = "error"
    # Custom exercises
    CUSTOM_EXERCISE_CREATED = "custom_exercise_created"
    CUSTOM_EXERCISE_USED = "custom_exercise_used"
    CUSTOM_EXERCISE_DELETED = "custom_exercise_deleted"
    COMPOSITE_EXERCISE_CREATED = "composite_exercise_created"


@dataclass
class UserPatterns:
    """Analyzed user behavior patterns."""
    user_id: str

    # Mood patterns
    most_common_mood: Optional[str] = None
    mood_frequency: Dict[str, int] = None
    mood_workout_completion_rate: Dict[str, float] = None

    # Time patterns
    preferred_workout_time: Optional[str] = None  # morning/afternoon/evening/night
    most_active_day: Optional[str] = None

    # Activity patterns
    avg_workouts_per_week: float = 0
    total_events_30_days: int = 0
    nutrition_logging_rate: float = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "user_id": self.user_id,
            "most_common_mood": self.most_common_mood,
            "mood_frequency": self.mood_frequency or {},
            "mood_workout_completion_rate": self.mood_workout_completion_rate or {},
            "preferred_workout_time": self.preferred_workout_time,
            "most_active_day": self.most_active_day,
            "avg_workouts_per_week": round(self.avg_workouts_per_week, 1),
            "total_events_30_days": self.total_events_30_days,
            "nutrition_logging_rate": round(self.nutrition_logging_rate, 1),
        }


class UserContextService:
    """Service for logging and analyzing user context."""

    def __init__(self):
        pass

    def _get_time_of_day(self, dt: Optional[datetime] = None) -> str:
        """Get time of day classification."""
        if dt is None:
            dt = datetime.now()
        hour = dt.hour

        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"

    def _build_context(
        self,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
        screen_name: Optional[str] = None,
        session_id: Optional[str] = None,
        extra_context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Build context dictionary with common fields."""
        now = datetime.now()
        context = {
            "time_of_day": self._get_time_of_day(now),
            "day_of_week": now.strftime("%A").lower(),
            "hour": now.hour,
        }

        if device:
            context["device"] = device
        if app_version:
            context["app_version"] = app_version
        if screen_name:
            context["screen_name"] = screen_name
        if session_id:
            context["session_id"] = session_id
        if extra_context:
            context.update(extra_context)

        return context

    async def log_event(
        self,
        user_id: str,
        event_type: EventType,
        event_data: Dict[str, Any],
        context: Optional[Dict[str, Any]] = None,
    ) -> Optional[str]:
        """
        Log a user event to the database.

        Args:
            user_id: User ID
            event_type: Type of event
            event_data: Event-specific data
            context: Contextual information

        Returns:
            Event ID if successful, None otherwise
        """
        try:
            db = get_supabase_db()

            record = {
                "user_id": user_id,
                "event_type": event_type.value,
                "event_data": event_data,
                "context": context or {},
            }

            response = db.client.table("user_context_logs").insert(record).execute()

            if response.data:
                return response.data[0]["id"]
            return None

        except Exception as e:
            logger.error(f"Failed to log event: {e}")
            return None

    async def log_mood_checkin(
        self,
        user_id: str,
        mood: str,
        workout_generated: bool = False,
        workout_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """
        Log a mood check-in event.

        Args:
            user_id: User ID
            mood: Selected mood (great/good/tired/stressed)
            workout_generated: Whether a workout was generated
            workout_id: ID of generated workout (if any)
            device: Device type
            app_version: App version

        Returns:
            Event ID if successful
        """
        event_data = {
            "mood": mood,
            "workout_generated": workout_generated,
            "workout_id": workout_id,
        }

        context = self._build_context(device=device, app_version=app_version)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.MOOD_CHECKIN,
            event_data=event_data,
            context=context,
        )

    async def log_workout_start(
        self,
        user_id: str,
        workout_id: str,
        source: str,  # "mood", "scheduled", "manual"
        mood: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log workout start event."""
        event_data = {
            "workout_id": workout_id,
            "source": source,
            "mood": mood,
        }

        context = self._build_context(device=device)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WORKOUT_START,
            event_data=event_data,
            context=context,
        )

    async def log_workout_complete(
        self,
        user_id: str,
        workout_id: str,
        duration_seconds: int,
        exercises_completed: int,
        exercises_total: int,
        source: str,
        mood_at_start: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log workout completion event."""
        event_data = {
            "workout_id": workout_id,
            "duration_seconds": duration_seconds,
            "exercises_completed": exercises_completed,
            "exercises_total": exercises_total,
            "completion_rate": round(exercises_completed / exercises_total * 100, 1) if exercises_total > 0 else 0,
            "source": source,
            "mood_at_start": mood_at_start,
        }

        context = self._build_context(device=device)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WORKOUT_COMPLETE,
            event_data=event_data,
            context=context,
        )

    async def log_score_view(
        self,
        user_id: str,
        screen: str,  # "home_card", "scoring_screen", "strength_detail", etc.
        duration_ms: Optional[int] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log score view event."""
        event_data = {
            "screen": screen,
            "duration_ms": duration_ms,
        }

        context = self._build_context(device=device, screen_name=screen)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.SCORE_VIEW,
            event_data=event_data,
            context=context,
        )

    async def log_nutrition_log(
        self,
        user_id: str,
        meal_type: str,  # "breakfast", "lunch", "dinner", "snack"
        items_count: int,
        calories: float,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log nutrition logging event."""
        event_data = {
            "meal_type": meal_type,
            "items_count": items_count,
            "calories": calories,
        }

        context = self._build_context(device=device)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.NUTRITION_LOG,
            event_data=event_data,
            context=context,
        )

    async def update_mood_workout_completed(
        self,
        user_id: str,
        mood_checkin_id: str,
    ) -> bool:
        """
        Update mood check-in record to mark workout as completed.

        Args:
            user_id: User ID
            mood_checkin_id: Mood check-in ID

        Returns:
            True if successful
        """
        try:
            db = get_supabase_db()

            db.client.table("mood_checkins").update({
                "workout_completed": True,
            }).eq("id", mood_checkin_id).eq("user_id", user_id).execute()

            return True

        except Exception as e:
            logger.error(f"Failed to update mood workout completed: {e}")
            return False

    async def get_user_patterns(
        self,
        user_id: str,
        days: int = 30,
    ) -> UserPatterns:
        """
        Analyze user behavior patterns from context logs.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            UserPatterns with analyzed data
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Get all events for the period
            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).gte(
                "created_at", cutoff
            ).execute()

            events = response.data or []

            patterns = UserPatterns(
                user_id=user_id,
                total_events_30_days=len(events),
                mood_frequency={},
                mood_workout_completion_rate={},
            )

            if not events:
                return patterns

            # Analyze mood check-ins
            mood_checkins = [e for e in events if e["event_type"] == "mood_checkin"]
            if mood_checkins:
                mood_counts = {}
                mood_completions = {}
                mood_totals = {}

                for checkin in mood_checkins:
                    mood = checkin["event_data"].get("mood")
                    if mood:
                        mood_counts[mood] = mood_counts.get(mood, 0) + 1
                        mood_totals[mood] = mood_totals.get(mood, 0) + 1

                        if checkin["event_data"].get("workout_completed"):
                            mood_completions[mood] = mood_completions.get(mood, 0) + 1

                patterns.mood_frequency = mood_counts
                patterns.most_common_mood = max(mood_counts.keys(), key=lambda k: mood_counts[k]) if mood_counts else None

                # Calculate completion rates
                for mood in mood_totals:
                    if mood_totals[mood] > 0:
                        rate = (mood_completions.get(mood, 0) / mood_totals[mood]) * 100
                        patterns.mood_workout_completion_rate[mood] = round(rate, 1)

            # Analyze workout times
            workout_starts = [e for e in events if e["event_type"] == "workout_start"]
            if workout_starts:
                time_counts = {}
                for ws in workout_starts:
                    time_of_day = ws["context"].get("time_of_day")
                    if time_of_day:
                        time_counts[time_of_day] = time_counts.get(time_of_day, 0) + 1

                if time_counts:
                    patterns.preferred_workout_time = max(time_counts.keys(), key=lambda k: time_counts[k])

            # Calculate workouts per week
            workout_completes = [e for e in events if e["event_type"] == "workout_complete"]
            weeks = max(1, days / 7)
            patterns.avg_workouts_per_week = len(workout_completes) / weeks

            # Calculate nutrition logging rate
            nutrition_logs = [e for e in events if e["event_type"] == "nutrition_log"]
            patterns.nutrition_logging_rate = (len(nutrition_logs) / days) * 100 if days > 0 else 0

            # Analyze most active day
            day_counts = {}
            for event in events:
                day = event["context"].get("day_of_week")
                if day:
                    day_counts[day] = day_counts.get(day, 0) + 1

            if day_counts:
                patterns.most_active_day = max(day_counts.keys(), key=lambda k: day_counts[k])

            return patterns

        except Exception as e:
            logger.error(f"Failed to get user patterns: {e}")
            return UserPatterns(user_id=user_id)

    async def get_mood_workout_correlation(
        self,
        user_id: str,
        days: int = 30,
    ) -> List[Dict[str, Any]]:
        """
        Get correlation between mood selections and workout completion.

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            List of mood correlation data
        """
        try:
            db = get_supabase_db()

            # Use the pre-built view
            response = db.client.from_("mood_workout_correlation").select("*").eq(
                "user_id", user_id
            ).execute()

            return response.data or []

        except Exception as e:
            logger.error(f"Failed to get mood workout correlation: {e}")
            return []


# Singleton instance
user_context_service = UserContextService()
