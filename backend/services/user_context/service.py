"""
User Context Service - Main Orchestrator
=========================================
Core service class with base methods and the main AI context aggregation.
Inherits logging methods from mixin modules.
"""

from datetime import datetime, timedelta, date
from typing import Optional, List, Dict, Any, Union
import logging

from core.db import get_supabase_db
from services.user_context.models import (
    EventType,
    LifetimeMemberContext,
    UserPatterns,
    CardioPatterns,
    DiabetesPatterns,
)
from services.user_context.event_logging import EventLoggingMixin
from services.user_context.trial_logging import TrialLoggingMixin
from services.user_context.feature_logging import FeatureLoggingMixin
from services.user_context.neat_logging import NeatLoggingMixin
from services.user_context.health_logging import HealthLoggingMixin
from services.user_context.nutrition_logging import NutritionLoggingMixin
from services.user_context.watch_logging import WatchLoggingMixin

logger = logging.getLogger(__name__)


class UserContextService(
    EventLoggingMixin,
    TrialLoggingMixin,
    FeatureLoggingMixin,
    NeatLoggingMixin,
    HealthLoggingMixin,
    NutritionLoggingMixin,
    WatchLoggingMixin,
):
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
        event_type: Union[EventType, str],
        event_data: Dict[str, Any],
        context: Optional[Dict[str, Any]] = None,
    ) -> Optional[str]:
        """
        Log a user event to the database.

        Args:
            user_id: User ID
            event_type: Type of event (EventType enum or string)
            event_data: Event-specific data
            context: Contextual information

        Returns:
            Event ID if successful, None otherwise
        """
        try:
            db = get_supabase_db()

            # Handle both EventType enum and string
            event_type_value = event_type.value if hasattr(event_type, 'value') else str(event_type)

            record = {
                "user_id": user_id,
                "event_type": event_type_value,
                "event_data": event_data,
                "context": context or {},
            }

            response = db.client.table("user_context_logs").insert(record).execute()

            if response.data:
                return response.data[0]["id"]
            return None

        except Exception as e:
            logger.error(f"Failed to log event: {e}", exc_info=True)
            return None

    def _calculate_engagement_score(
        self,
        scroll_percentage: float,
        sections_count: int,
        time_spent_seconds: int,
    ) -> float:
        """
        Calculate an engagement score for plan preview viewing.

        Score ranges from 0-100, higher is more engaged.
        """
        # Weight: scroll (40%), sections (30%), time (30%)
        scroll_score = min(scroll_percentage, 100) * 0.4
        sections_score = min(sections_count * 10, 100) * 0.3
        # Optimal time: 30-120 seconds
        if time_spent_seconds < 5:
            time_score = 0
        elif time_spent_seconds < 30:
            time_score = (time_spent_seconds / 30) * 50
        elif time_spent_seconds <= 120:
            time_score = 100
        else:
            # Diminishing returns after 2 minutes
            time_score = max(50, 100 - (time_spent_seconds - 120) / 6)
        time_score *= 0.3

        return round(scroll_score + sections_score + time_score, 1)

    # ==========================================================================
    # LIFETIME MEMBERSHIP CONTEXT - For AI personalization
    # ==========================================================================

    async def get_lifetime_member_context(
        self,
        user_id: str,
    ) -> LifetimeMemberContext:
        """
        Get lifetime membership context for AI personalization.

        Args:
            user_id: User ID

        Returns:
            LifetimeMemberContext with membership details and AI context
        """
        try:
            db = get_supabase_db()

            # Query user subscription for lifetime status
            response = db.client.table("user_subscriptions").select(
                "is_lifetime, lifetime_purchase_date, lifetime_original_price, "
                "lifetime_member_tier, tier, status"
            ).eq(
                "user_id", user_id
            ).single().execute()

            if not response.data:
                logger.debug(f"[Lifetime Context] No subscription found for user {user_id}")
                return LifetimeMemberContext()

            subscription = response.data

            # Check if user is a lifetime member
            is_lifetime = subscription.get("is_lifetime", False) or subscription.get("tier") == "lifetime"

            if not is_lifetime:
                return LifetimeMemberContext()

            # Parse lifetime purchase date
            lifetime_purchase_date = None
            if subscription.get("lifetime_purchase_date"):
                try:
                    lifetime_purchase_date = datetime.fromisoformat(
                        subscription["lifetime_purchase_date"].replace("Z", "+00:00")
                    )
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse purchase date: {e}")

            # Calculate days as member
            days_as_member = 0
            if lifetime_purchase_date:
                days_as_member = (datetime.now(lifetime_purchase_date.tzinfo) - lifetime_purchase_date).days

            # Get or calculate member tier
            member_tier = subscription.get("lifetime_member_tier")
            if not member_tier and days_as_member > 0:
                if days_as_member >= 365:
                    member_tier = "Veteran"
                elif days_as_member >= 180:
                    member_tier = "Loyal"
                elif days_as_member >= 90:
                    member_tier = "Established"
                else:
                    member_tier = "New"

            # Calculate tier level
            tier_level_map = {"New": 1, "Established": 2, "Loyal": 3, "Veteran": 4}
            member_tier_level = tier_level_map.get(member_tier, 0)

            # Calculate estimated value received (assuming $9.99/month value)
            months_as_member = days_as_member / 30.0
            estimated_value = months_as_member * 9.99

            # Calculate value multiplier
            original_price = subscription.get("lifetime_original_price", 0) or 0
            value_multiplier = 0.0
            if original_price > 0:
                value_multiplier = estimated_value / original_price

            # All features are unlocked for lifetime members
            features_unlocked = ["all"]

            context = LifetimeMemberContext(
                is_lifetime_member=True,
                lifetime_purchase_date=lifetime_purchase_date,
                days_as_member=days_as_member,
                member_tier=member_tier,
                member_tier_level=member_tier_level,
                estimated_value_received=estimated_value,
                value_multiplier=value_multiplier,
                features_unlocked=features_unlocked,
            )

            logger.info(
                f"[Lifetime Context] User {user_id}: tier={member_tier}, "
                f"days={days_as_member}, value=${estimated_value:.2f}"
            )

            return context

        except Exception as e:
            logger.error(f"Failed to get lifetime member context: {e}", exc_info=True)
            return LifetimeMemberContext()

    async def get_full_user_context_for_ai(
        self,
        user_id: str,
        include_patterns: bool = True,
        include_lifetime: bool = True,
        include_cardio: bool = True,
        include_diabetes: bool = True,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get comprehensive user context for AI personalization.

        This aggregates all relevant user context including:
        - Activity patterns (mood, workout times, etc.)
        - Cardio patterns (location preferences, frequency)
        - Lifetime membership status and tier
        - Diabetes management context (glucose, insulin, A1C)
        - Recent engagement metrics

        Use this method when generating AI responses that need full user context.

        Args:
            user_id: User ID
            include_patterns: Whether to include user behavior patterns
            include_lifetime: Whether to include lifetime membership context
            include_cardio: Whether to include cardio patterns
            include_diabetes: Whether to include diabetes management context
            days: Number of days to analyze for patterns

        Returns:
            Dictionary with comprehensive user context and AI-ready strings
        """
        result = {
            "user_id": user_id,
            "context_generated_at": datetime.now().isoformat(),
        }

        ai_context_parts = []

        # Get lifetime membership context
        if include_lifetime:
            lifetime_context = await self.get_lifetime_member_context(user_id)
            result["lifetime_membership"] = lifetime_context.to_dict()

            lifetime_ai_context = lifetime_context.get_ai_personalization_context()
            if lifetime_ai_context:
                ai_context_parts.append(lifetime_ai_context)

        # Get user patterns
        if include_patterns:
            patterns = await self.get_user_patterns(user_id, days)
            result["patterns"] = patterns.to_dict()

            # Add relevant pattern context for AI
            if patterns.preferred_workout_time:
                ai_context_parts.append(
                    f"User typically works out in the {patterns.preferred_workout_time}."
                )
            if patterns.most_common_mood:
                ai_context_parts.append(
                    f"User's most common mood before workouts is '{patterns.most_common_mood}'."
                )
            if patterns.avg_workouts_per_week > 0:
                ai_context_parts.append(
                    f"User completes an average of {patterns.avg_workouts_per_week:.1f} workouts per week."
                )

            # Add cardio context
            if include_cardio and patterns.cardio_patterns:
                cardio_ai_context = patterns.cardio_patterns.get_ai_recommendations_context()
                if cardio_ai_context:
                    ai_context_parts.append(cardio_ai_context)

        # Get diabetes management context
        if include_diabetes:
            diabetes_patterns = await self.get_diabetes_patterns(user_id, days=7)
            if diabetes_patterns.diabetes_type:
                result["diabetes"] = diabetes_patterns.to_dict()
                result["diabetes_pre_workout_safety"] = diabetes_patterns.get_pre_workout_safety_context()

                diabetes_ai_context = diabetes_patterns.get_ai_context()
                if diabetes_ai_context:
                    ai_context_parts.append(diabetes_ai_context)

        # Combine all AI context into a single string
        result["ai_personalization_context"] = " ".join(ai_context_parts)

        return result

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
            logger.error(f"Failed to get mood workout correlation: {e}", exc_info=True)
            return []

    async def get_conversion_attribution(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get conversion attribution data for a user.

        Analyzes the sequence of actions leading to conversion (or current state).

        Args:
            user_id: User ID
            days: Number of days to analyze

        Returns:
            Dictionary with attribution data
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Get all trial/demo related events
            trial_event_types = [
                EventType.PLAN_PREVIEW_VIEWED.value,
                EventType.PLAN_PREVIEW_SCROLL_DEPTH.value,
                EventType.TRY_WORKOUT_STARTED.value,
                EventType.TRY_WORKOUT_COMPLETED.value,
                EventType.TRY_WORKOUT_ABANDONED.value,
                EventType.DEMO_DAY_STARTED.value,
                EventType.DEMO_DAY_EXPIRED.value,
                EventType.TRIAL_STARTED.value,
                EventType.TRIAL_CONVERTED.value,
                EventType.PAYWALL_VIEWED.value,
                EventType.PAYWALL_SKIPPED.value,
                EventType.FREE_FEATURE_TAPPED.value,
                EventType.LOCKED_FEATURE_TAPPED.value,
            ]

            response = db.client.table("user_context_logs").select("*").eq(
                "user_id", user_id
            ).in_(
                "event_type", trial_event_types
            ).gte(
                "created_at", cutoff
            ).order(
                "created_at", desc=False
            ).execute()

            events = response.data or []

            if not events:
                return {
                    "user_id": user_id,
                    "has_trial_events": False,
                    "conversion_status": "no_trial_activity",
                }

            # Build the event sequence
            event_sequence = []
            for event in events:
                event_sequence.append({
                    "event_type": event["event_type"],
                    "timestamp": event["created_at"],
                    "data": event["event_data"],
                })

            # Check if converted
            converted = any(e["event_type"] == EventType.TRIAL_CONVERTED.value for e in events)

            # Find last action before conversion (if converted)
            last_action_before_conversion = None
            if converted:
                conversion_index = next(
                    i for i, e in enumerate(events)
                    if e["event_type"] == EventType.TRIAL_CONVERTED.value
                )
                if conversion_index > 0:
                    last_action_before_conversion = events[conversion_index - 1]["event_type"]

            # Calculate time from first interaction to conversion/now
            first_interaction = datetime.fromisoformat(
                events[0]["created_at"].replace("Z", "+00:00")
            )
            if converted:
                conversion_event = next(
                    e for e in events
                    if e["event_type"] == EventType.TRIAL_CONVERTED.value
                )
                conversion_time = datetime.fromisoformat(
                    conversion_event["created_at"].replace("Z", "+00:00")
                )
                time_to_conversion = conversion_time - first_interaction
            else:
                time_to_conversion = datetime.now(first_interaction.tzinfo) - first_interaction

            # Count key events
            event_counts = {}
            for event in events:
                event_type = event["event_type"]
                event_counts[event_type] = event_counts.get(event_type, 0) + 1

            # Identify high-intent signals
            high_intent_signals = []
            if event_counts.get(EventType.TRY_WORKOUT_COMPLETED.value, 0) > 0:
                high_intent_signals.append("completed_trial_workout")
            if event_counts.get(EventType.LOCKED_FEATURE_TAPPED.value, 0) >= 3:
                high_intent_signals.append("multiple_locked_taps")
            if event_counts.get(EventType.PLAN_PREVIEW_SCROLL_DEPTH.value, 0) > 0:
                # Check if they had high engagement
                scroll_events = [
                    e for e in events
                    if e["event_type"] == EventType.PLAN_PREVIEW_SCROLL_DEPTH.value
                ]
                for scroll_event in scroll_events:
                    if scroll_event["event_data"].get("engagement_score", 0) > 70:
                        high_intent_signals.append("high_plan_engagement")
                        break

            return {
                "user_id": user_id,
                "has_trial_events": True,
                "conversion_status": "converted" if converted else "not_converted",
                "first_interaction_date": first_interaction.isoformat(),
                "time_to_conversion_hours": round(time_to_conversion.total_seconds() / 3600, 1),
                "last_action_before_conversion": last_action_before_conversion,
                "event_sequence": event_sequence,
                "event_counts": event_counts,
                "total_trial_events": len(events),
                "high_intent_signals": high_intent_signals,
                "paywall_views": event_counts.get(EventType.PAYWALL_VIEWED.value, 0),
                "paywall_skips": event_counts.get(EventType.PAYWALL_SKIPPED.value, 0),
                "locked_feature_taps": event_counts.get(EventType.LOCKED_FEATURE_TAPPED.value, 0),
            }

        except Exception as e:
            logger.error(f"Failed to get conversion attribution: {e}", exc_info=True)
            return {
                "user_id": user_id,
                "error": str(e),
            }

    async def get_trial_funnel_metrics(
        self,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get aggregate trial funnel metrics for all users.

        Args:
            days: Number of days to analyze

        Returns:
            Dictionary with funnel metrics
        """
        try:
            db = get_supabase_db()
            cutoff = (datetime.now() - timedelta(days=days)).isoformat()

            # Get all trial events in the period
            trial_event_types = [
                EventType.PLAN_PREVIEW_VIEWED.value,
                EventType.TRY_WORKOUT_STARTED.value,
                EventType.TRY_WORKOUT_COMPLETED.value,
                EventType.TRIAL_STARTED.value,
                EventType.TRIAL_CONVERTED.value,
                EventType.PAYWALL_VIEWED.value,
            ]

            response = db.client.table("user_context_logs").select(
                "user_id, event_type"
            ).in_(
                "event_type", trial_event_types
            ).gte(
                "created_at", cutoff
            ).execute()

            events = response.data or []

            if not events:
                return {
                    "period_days": days,
                    "no_data": True,
                }

            # Group by user
            user_events: Dict[str, set] = {}
            for event in events:
                user_id = event["user_id"]
                if user_id not in user_events:
                    user_events[user_id] = set()
                user_events[user_id].add(event["event_type"])

            # Calculate funnel stages
            plan_preview_users = sum(
                1 for events in user_events.values()
                if EventType.PLAN_PREVIEW_VIEWED.value in events
            )
            try_workout_started = sum(
                1 for events in user_events.values()
                if EventType.TRY_WORKOUT_STARTED.value in events
            )
            try_workout_completed = sum(
                1 for events in user_events.values()
                if EventType.TRY_WORKOUT_COMPLETED.value in events
            )
            trial_started = sum(
                1 for events in user_events.values()
                if EventType.TRIAL_STARTED.value in events
            )
            converted = sum(
                1 for events in user_events.values()
                if EventType.TRIAL_CONVERTED.value in events
            )

            # Calculate conversion rates
            def safe_rate(numerator: int, denominator: int) -> float:
                return round((numerator / denominator * 100), 1) if denominator > 0 else 0

            return {
                "period_days": days,
                "total_users_with_trial_events": len(user_events),
                "funnel": {
                    "plan_preview_viewed": plan_preview_users,
                    "try_workout_started": try_workout_started,
                    "try_workout_completed": try_workout_completed,
                    "trial_started": trial_started,
                    "converted": converted,
                },
                "conversion_rates": {
                    "preview_to_try": safe_rate(try_workout_started, plan_preview_users),
                    "try_to_complete": safe_rate(try_workout_completed, try_workout_started),
                    "complete_to_trial": safe_rate(trial_started, try_workout_completed),
                    "trial_to_paid": safe_rate(converted, trial_started),
                    "overall_preview_to_paid": safe_rate(converted, plan_preview_users),
                },
            }

        except Exception as e:
            logger.error(f"Failed to get trial funnel metrics: {e}", exc_info=True)
            return {
                "period_days": days,
                "error": str(e),
            }
