"""
Event Logging Mixin
===================
Core event logging methods: mood, workout, score, nutrition, RIR,
performance comparison, difficulty adjustment, and progression events.
"""

from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
import logging

from core.db import get_supabase_db
from models.cardio_session import CardioType, CardioLocation
from services.user_context.models import (
    EventType,
    UserPatterns,
    CardioPatterns,
)

logger = logging.getLogger(__name__)


class EventLoggingMixin:
    """Mixin for core event logging and user pattern analysis."""

    async def log_mood_checkin(
        self,
        user_id: str,
        mood: str,
        workout_generated: bool = False,
        workout_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log a mood check-in event."""
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
        screen: str,
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
        meal_type: str,
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

    async def log_set_rir_feedback(
        self,
        user_id: str,
        workout_id: str,
        exercise_name: str,
        set_number: int,
        target_rir: int,
        logged_rir: int,
        weight_kg: float,
        reps: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log RIR (Reps in Reserve) feedback after completing a set."""
        rir_diff = logged_rir - target_rir
        feedback_category = "perfect" if rir_diff == 0 else ("easier" if rir_diff > 0 else "harder")

        event_data = {
            "workout_id": workout_id,
            "exercise_name": exercise_name,
            "set_number": set_number,
            "target_rir": target_rir,
            "logged_rir": logged_rir,
            "rir_difference": rir_diff,
            "feedback_category": feedback_category,
            "weight_kg": weight_kg,
            "reps": reps,
        }

        context = self._build_context(device=device)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.SET_RIR_FEEDBACK,
            event_data=event_data,
            context=context,
        )

    async def log_weight_auto_adjusted(
        self,
        user_id: str,
        workout_id: str,
        exercise_name: str,
        set_number: int,
        previous_weight_kg: float,
        new_weight_kg: float,
        adjustment_reason: str,
        logged_rir: int,
        target_rir: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when weight is auto-adjusted based on RIR feedback."""
        weight_change = new_weight_kg - previous_weight_kg
        change_percent = (weight_change / previous_weight_kg * 100) if previous_weight_kg > 0 else 0

        event_data = {
            "workout_id": workout_id,
            "exercise_name": exercise_name,
            "set_number": set_number,
            "previous_weight_kg": previous_weight_kg,
            "new_weight_kg": new_weight_kg,
            "weight_change_kg": weight_change,
            "change_percent": round(change_percent, 1),
            "adjustment_direction": "increase" if weight_change > 0 else "decrease",
            "adjustment_reason": adjustment_reason,
            "logged_rir": logged_rir,
            "target_rir": target_rir,
        }

        context = self._build_context(device=device)

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.WEIGHT_AUTO_ADJUSTED,
            event_data=event_data,
            context=context,
        )

    async def update_mood_workout_completed(
        self,
        user_id: str,
        mood_checkin_id: str,
    ) -> bool:
        """Update mood check-in record to mark workout as completed."""
        try:
            db = get_supabase_db()

            db.client.table("mood_checkins").update({
                "workout_completed": True,
            }).eq("id", mood_checkin_id).eq("user_id", user_id).execute()

            return True

        except Exception as e:
            logger.error(f"Failed to update mood workout completed: {e}")
            return False

    async def get_cardio_patterns(
        self,
        user_id: str,
        days: int = 30,
    ) -> CardioPatterns:
        """Analyze user's cardio activity patterns."""
        try:
            db = get_supabase_db()
            now = datetime.now()
            cutoff_30_days = (now - timedelta(days=days)).isoformat()
            cutoff_7_days = (now - timedelta(days=7)).isoformat()

            # Get all cardio sessions for the analysis period
            cardio_response = db.client.table("cardio_sessions").select("*").eq(
                "user_id", user_id
            ).gte(
                "created_at", cutoff_30_days
            ).order(
                "created_at", desc=True
            ).execute()

            all_sessions = cardio_response.data or []

            if not all_sessions:
                return CardioPatterns()

            # Filter recent sessions (last 7 days)
            recent_sessions = [
                s for s in all_sessions
                if s["created_at"] >= cutoff_7_days
            ]

            # Analyze recent activity
            recent_sessions_count = len(recent_sessions)
            recent_total_duration = sum(s.get("duration_minutes", 0) for s in recent_sessions)
            recent_cardio_types = list(set(s["cardio_type"] for s in recent_sessions))
            recent_locations = list(set(s["location"] for s in recent_sessions))

            # Analyze location preferences
            location_counts: Dict[str, int] = {}
            outdoor_count = 0
            treadmill_count = 0

            for session in all_sessions:
                location = session["location"]
                location_counts[location] = location_counts.get(location, 0) + 1

                # Track outdoor vs treadmill
                if location in [CardioLocation.OUTDOOR.value, CardioLocation.TRAIL.value, CardioLocation.TRACK.value]:
                    outdoor_count += 1
                elif location == CardioLocation.TREADMILL.value:
                    treadmill_count += 1

            total_sessions = len(all_sessions)
            preferred_location = max(location_counts.keys(), key=lambda k: location_counts[k]) if location_counts else None
            is_outdoor_enthusiast = (outdoor_count / total_sessions) > 0.6 if total_sessions > 0 else False
            is_treadmill_user = (treadmill_count / total_sessions) > 0.4 if total_sessions > 0 else False

            # Analyze cardio type preferences
            type_counts: Dict[str, int] = {}
            for session in all_sessions:
                cardio_type = session["cardio_type"]
                type_counts[cardio_type] = type_counts.get(cardio_type, 0) + 1

            primary_cardio_type = max(type_counts.keys(), key=lambda k: type_counts[k]) if type_counts else None

            # Calculate frequency
            weeks = max(1, days / 7)
            avg_cardio_sessions_per_week = total_sessions / weeks

            # Calculate streak (consecutive days with cardio)
            session_dates = sorted(set(
                datetime.fromisoformat(s["created_at"].replace("Z", "+00:00")).date()
                for s in all_sessions
            ), reverse=True)

            cardio_streak_days = 0
            last_cardio_date = session_dates[0] if session_dates else None

            if session_dates:
                today = now.date()
                # Check if there's a session today or yesterday to start counting
                if session_dates[0] >= today - timedelta(days=1):
                    cardio_streak_days = 1
                    for i in range(1, len(session_dates)):
                        expected_date = session_dates[0] - timedelta(days=i)
                        if session_dates[i] == expected_date:
                            cardio_streak_days += 1
                        else:
                            break

            # Calculate cardio to strength ratio
            workout_response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).eq(
                "event_type", "workout_complete"
            ).gte(
                "created_at", cutoff_30_days
            ).execute()

            strength_workouts = len(workout_response.data or [])
            cardio_to_strength_ratio = 0.0
            needs_more_cardio = False
            needs_more_strength = False

            if strength_workouts > 0:
                cardio_to_strength_ratio = total_sessions / strength_workouts
                needs_more_cardio = cardio_to_strength_ratio < 0.3
                needs_more_strength = cardio_to_strength_ratio > 2.0
            elif total_sessions > 0:
                # All cardio, no strength
                needs_more_strength = True
                cardio_to_strength_ratio = float('inf') if total_sessions > 2 else float(total_sessions)
            else:
                # No activity at all
                needs_more_cardio = True

            return CardioPatterns(
                recent_sessions_count=recent_sessions_count,
                recent_total_duration_minutes=recent_total_duration,
                recent_cardio_types=recent_cardio_types,
                recent_locations=recent_locations,
                preferred_location=preferred_location,
                location_frequency=location_counts,
                is_outdoor_enthusiast=is_outdoor_enthusiast,
                is_treadmill_user=is_treadmill_user,
                avg_cardio_sessions_per_week=avg_cardio_sessions_per_week,
                cardio_streak_days=cardio_streak_days,
                last_cardio_date=last_cardio_date,
                primary_cardio_type=primary_cardio_type,
                cardio_type_frequency=type_counts,
                cardio_to_strength_ratio=cardio_to_strength_ratio if cardio_to_strength_ratio != float('inf') else 99.0,
                needs_more_cardio=needs_more_cardio,
                needs_more_strength=needs_more_strength,
            )

        except Exception as e:
            logger.error(f"Failed to get cardio patterns: {e}")
            return CardioPatterns()

    async def get_user_patterns(
        self,
        user_id: str,
        days: int = 30,
    ) -> UserPatterns:
        """Analyze user behavior patterns from context logs."""
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

            # Get cardio patterns
            cardio_patterns = await self.get_cardio_patterns(user_id, days)
            patterns.cardio_patterns = cardio_patterns

            return patterns

        except Exception as e:
            logger.error(f"Failed to get user patterns: {e}")
            return UserPatterns(user_id=user_id)

    async def get_user_patterns_with_cardio_context(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """Get user patterns with AI-ready cardio context."""
        patterns = await self.get_user_patterns(user_id, days)

        ai_context = ""
        if patterns.cardio_patterns:
            ai_context = patterns.cardio_patterns.get_ai_recommendations_context()

        return {
            "patterns": patterns.to_dict(),
            "cardio_ai_context": ai_context,
        }

    async def log_performance_comparison_viewed(
        self,
        user_id: str,
        workout_id: str,
        workout_log_id: str,
        improved_count: int = 0,
        declined_count: int = 0,
        first_time_count: int = 0,
        exercises_compared: int = 0,
        duration_diff_seconds: Optional[int] = None,
        volume_diff_percentage: Optional[float] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user views performance comparison after workout completion."""
        event_data = {
            "workout_id": workout_id,
            "workout_log_id": workout_log_id,
            "improved_count": improved_count,
            "declined_count": declined_count,
            "first_time_count": first_time_count,
            "exercises_compared": exercises_compared,
            "duration_diff_seconds": duration_diff_seconds,
            "volume_diff_percentage": volume_diff_percentage,
        }

        context = self._build_context(device=device, screen_name="workout_complete")

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.PERFORMANCE_COMPARISON_VIEWED,
            event_data=event_data,
            context=context,
        )

    async def log_difficulty_adjustment(
        self,
        user_id: str,
        adjustment: int,
        recommendation: str,
        feedback_counts: Dict[str, int],
        confidence: float,
        workout_type: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a difficulty adjustment is applied during workout generation."""
        event_data = {
            "adjustment": adjustment,
            "recommendation": recommendation,
            "too_easy_count": feedback_counts.get("too_easy_count", 0),
            "just_right_count": feedback_counts.get("just_right_count", 0),
            "too_hard_count": feedback_counts.get("too_hard_count", 0),
            "total_feedback_count": feedback_counts.get("total_feedback_count", 0),
            "confidence": round(confidence, 2),
            "workout_type": workout_type,
        }

        context = self._build_context(
            device=device,
            screen_name="workout_generation",
            extra_context={"feedback_loop_version": "1.0"},
        )

        logger.info(
            f"[Difficulty Adjustment Log] User {user_id}: adjustment={adjustment:+d}, "
            f"confidence={confidence:.2f}, workout_type={workout_type}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.DIFFICULTY_ADJUSTMENT_APPLIED,
            event_data=event_data,
            context=context,
        )

    async def log_user_ready_for_progression(
        self,
        user_id: str,
        exercise_name: str,
        suggested_variant: str,
        consecutive_easy_sessions: int,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user becomes ready for exercise progression."""
        event_data = {
            "exercise_name": exercise_name,
            "suggested_variant": suggested_variant,
            "consecutive_easy_sessions": consecutive_easy_sessions,
        }

        context = self._build_context(
            device=device,
            screen_name="workout_feedback",
            extra_context={"progression_system_version": "1.0"},
        )

        logger.info(
            f"[Progression Ready] User {user_id}: {exercise_name} -> {suggested_variant} "
            f"(easy sessions: {consecutive_easy_sessions})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.USER_READY_FOR_PROGRESSION,
            event_data=event_data,
            context=context,
        )

    async def log_progression_accepted(
        self,
        user_id: str,
        from_exercise: str,
        to_exercise: str,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user accepts a progression suggestion."""
        event_data = {
            "from_exercise": from_exercise,
            "to_exercise": to_exercise,
            "action": "accepted",
        }

        context = self._build_context(
            device=device,
            screen_name="workout_complete",
            extra_context={"progression_system_version": "1.0"},
        )

        logger.info(
            f"[Progression Accepted] User {user_id}: {from_exercise} -> {to_exercise}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.USER_ACCEPTED_PROGRESSION,
            event_data=event_data,
            context=context,
        )

    async def log_progression_declined(
        self,
        user_id: str,
        from_exercise: str,
        to_exercise: str,
        reason: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when a user declines a progression suggestion."""
        event_data = {
            "from_exercise": from_exercise,
            "to_exercise": to_exercise,
            "action": "declined",
            "reason": reason,
        }

        context = self._build_context(
            device=device,
            screen_name="workout_complete",
            extra_context={"progression_system_version": "1.0"},
        )

        logger.info(
            f"[Progression Declined] User {user_id}: {from_exercise} -> {to_exercise} "
            f"(reason: {reason or 'not provided'})"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=EventType.USER_DECLINED_PROGRESSION,
            event_data=event_data,
            context=context,
        )
