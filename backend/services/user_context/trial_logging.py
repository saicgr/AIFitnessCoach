"""
Trial/Demo Event Logging Mixin
===============================
Trial, demo, paywall, and conversion-related event logging.
"""

from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
import logging

from services.user_context.models import EventType

logger = logging.getLogger(__name__)


class TrialLoggingMixin:
    """Mixin for trial/demo event logging."""

    async def log_trial_event(
        self,
        user_id: str,
        event_type: EventType,
        event_data: Dict[str, Any],
        session_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Generic method to log trial/demo events with consistent structure."""
        context = self._build_context(
            device=device,
            app_version=app_version,
            session_id=session_id,
            extra_context={
                "trial_tracking_version": "1.0",
                "is_trial_event": True,
            },
        )

        logger.info(
            f"[Trial Event] User {user_id}: {event_type.value} - "
            f"session={session_id}, data={event_data}"
        )

        return await self.log_event(
            user_id=user_id,
            event_type=event_type,
            event_data=event_data,
            context=context,
        )

    async def log_plan_preview_viewed(
        self,
        user_id: str,
        plan_type: str,
        workout_count: int,
        duration_days: int,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user sees their personalized plan preview."""
        event_data = {
            "plan_type": plan_type,
            "workout_count": workout_count,
            "duration_days": duration_days,
            "preview_shown_at": datetime.now().isoformat(),
        }

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.PLAN_PREVIEW_VIEWED,
            event_data=event_data,
            session_id=session_id,
            device=device,
            app_version=app_version,
        )

    async def log_plan_preview_scroll_depth(
        self,
        user_id: str,
        scroll_percentage: float,
        sections_viewed: List[str],
        time_spent_seconds: int,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log how far user scrolled through the plan preview."""
        event_data = {
            "scroll_percentage": min(100, max(0, scroll_percentage)),
            "sections_viewed": sections_viewed,
            "sections_count": len(sections_viewed),
            "time_spent_seconds": time_spent_seconds,
            "engagement_score": self._calculate_engagement_score(
                scroll_percentage, len(sections_viewed), time_spent_seconds
            ),
        }

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.PLAN_PREVIEW_SCROLL_DEPTH,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_try_workout_started(
        self,
        user_id: str,
        workout_id: str,
        workout_name: str,
        exercise_count: int,
        estimated_duration_minutes: int,
        source: str,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user starts the free trial workout."""
        event_data = {
            "workout_id": workout_id,
            "workout_name": workout_name,
            "exercise_count": exercise_count,
            "estimated_duration_minutes": estimated_duration_minutes,
            "source": source,
            "started_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Try Workout Started] User {user_id}: {workout_name} ({exercise_count} exercises)"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRY_WORKOUT_STARTED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_try_workout_completed(
        self,
        user_id: str,
        workout_id: str,
        workout_name: str,
        duration_seconds: int,
        exercises_completed: int,
        exercises_total: int,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user finishes the trial workout."""
        completion_rate = round(
            (exercises_completed / exercises_total * 100) if exercises_total > 0 else 0, 1
        )

        event_data = {
            "workout_id": workout_id,
            "workout_name": workout_name,
            "duration_seconds": duration_seconds,
            "duration_minutes": round(duration_seconds / 60, 1),
            "exercises_completed": exercises_completed,
            "exercises_total": exercises_total,
            "completion_rate": completion_rate,
            "completed_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Try Workout Completed] User {user_id}: {workout_name} - "
            f"{exercises_completed}/{exercises_total} ({completion_rate}%) in {round(duration_seconds / 60)}min"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRY_WORKOUT_COMPLETED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_try_workout_abandoned(
        self,
        user_id: str,
        workout_id: str,
        workout_name: str,
        duration_seconds: int,
        exercises_completed: int,
        exercises_total: int,
        last_exercise_name: Optional[str] = None,
        abandon_reason: Optional[str] = None,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user leaves mid-workout."""
        progress_percentage = round(
            (exercises_completed / exercises_total * 100) if exercises_total > 0 else 0, 1
        )

        event_data = {
            "workout_id": workout_id,
            "workout_name": workout_name,
            "duration_seconds": duration_seconds,
            "exercises_completed": exercises_completed,
            "exercises_total": exercises_total,
            "progress_percentage": progress_percentage,
            "last_exercise_name": last_exercise_name,
            "abandon_reason": abandon_reason,
            "abandoned_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Try Workout Abandoned] User {user_id}: {workout_name} - "
            f"dropped at {progress_percentage}% ({exercises_completed}/{exercises_total}), "
            f"reason: {abandon_reason or 'unknown'}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRY_WORKOUT_ABANDONED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_demo_day_started(
        self,
        user_id: str,
        demo_expiry: datetime,
        features_unlocked: List[str],
        source: str,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when 24-hour demo begins."""
        event_data = {
            "demo_started_at": datetime.now().isoformat(),
            "demo_expiry": demo_expiry.isoformat(),
            "demo_duration_hours": 24,
            "features_unlocked": features_unlocked,
            "features_count": len(features_unlocked),
            "source": source,
        }

        logger.info(
            f"[Demo Day Started] User {user_id}: expires {demo_expiry.isoformat()}, "
            f"features: {len(features_unlocked)}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.DEMO_DAY_STARTED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_demo_day_expired(
        self,
        user_id: str,
        features_used: List[str],
        workouts_completed: int,
        total_active_time_minutes: int,
        converted: bool,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when demo time runs out."""
        event_data = {
            "demo_expired_at": datetime.now().isoformat(),
            "features_used": features_used,
            "features_used_count": len(features_used),
            "workouts_completed": workouts_completed,
            "total_active_time_minutes": total_active_time_minutes,
            "converted_before_expiry": converted,
        }

        logger.info(
            f"[Demo Day Expired] User {user_id}: used {len(features_used)} features, "
            f"{workouts_completed} workouts, converted={converted}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.DEMO_DAY_EXPIRED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_trial_started(
        self,
        user_id: str,
        trial_duration_days: int,
        trial_type: str,
        source: str,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user starts 7-day (or other) trial."""
        trial_end = datetime.now() + timedelta(days=trial_duration_days)

        event_data = {
            "trial_started_at": datetime.now().isoformat(),
            "trial_end_date": trial_end.isoformat(),
            "trial_duration_days": trial_duration_days,
            "trial_type": trial_type,
            "source": source,
        }

        logger.info(
            f"[Trial Started] User {user_id}: {trial_type} ({trial_duration_days} days), "
            f"source={source}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRIAL_STARTED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_trial_converted(
        self,
        user_id: str,
        trial_type: str,
        days_until_conversion: int,
        subscription_plan: str,
        price_paid: float,
        currency: str,
        conversion_source: str,
        last_action_before_conversion: Optional[str] = None,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when trial converts to paid."""
        event_data = {
            "converted_at": datetime.now().isoformat(),
            "trial_type": trial_type,
            "days_until_conversion": days_until_conversion,
            "subscription_plan": subscription_plan,
            "price_paid": price_paid,
            "currency": currency,
            "conversion_source": conversion_source,
            "last_action_before_conversion": last_action_before_conversion,
        }

        logger.info(
            f"[Trial Converted] User {user_id}: {trial_type} -> {subscription_plan} "
            f"({days_until_conversion} days), ${price_paid} {currency}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.TRIAL_CONVERTED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_paywall_viewed(
        self,
        user_id: str,
        paywall_variant: str,
        trigger: str,
        plans_shown: List[Dict[str, Any]],
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when paywall screen is shown."""
        event_data = {
            "paywall_variant": paywall_variant,
            "trigger": trigger,
            "plans_shown": plans_shown,
            "plans_count": len(plans_shown),
            "viewed_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Paywall Viewed] User {user_id}: variant={paywall_variant}, "
            f"trigger={trigger}, plans={len(plans_shown)}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.PAYWALL_VIEWED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_paywall_skipped(
        self,
        user_id: str,
        paywall_variant: str,
        trigger: str,
        time_on_paywall_seconds: int,
        skip_method: str,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user skips paywall."""
        event_data = {
            "paywall_variant": paywall_variant,
            "trigger": trigger,
            "time_on_paywall_seconds": time_on_paywall_seconds,
            "skip_method": skip_method,
            "skipped_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Paywall Skipped] User {user_id}: variant={paywall_variant}, "
            f"time={time_on_paywall_seconds}s, method={skip_method}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.PAYWALL_SKIPPED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_free_feature_tapped(
        self,
        user_id: str,
        feature_name: str,
        screen_context: str,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user taps on a free feature."""
        event_data = {
            "feature_name": feature_name,
            "screen_context": screen_context,
            "feature_type": "free",
            "tapped_at": datetime.now().isoformat(),
        }

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.FREE_FEATURE_TAPPED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )

    async def log_locked_feature_tapped(
        self,
        user_id: str,
        feature_name: str,
        screen_context: str,
        showed_upgrade_prompt: bool,
        session_id: Optional[str] = None,
        device: Optional[str] = None,
    ) -> Optional[str]:
        """Log when user taps on a locked/premium feature."""
        event_data = {
            "feature_name": feature_name,
            "screen_context": screen_context,
            "feature_type": "locked",
            "showed_upgrade_prompt": showed_upgrade_prompt,
            "tapped_at": datetime.now().isoformat(),
        }

        logger.info(
            f"[Locked Feature Tapped] User {user_id}: {feature_name} on {screen_context}"
        )

        return await self.log_trial_event(
            user_id=user_id,
            event_type=EventType.LOCKED_FEATURE_TAPPED,
            event_data=event_data,
            session_id=session_id,
            device=device,
        )
