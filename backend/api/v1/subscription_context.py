"""
Subscription Context API for AI Personalization

Logs subscription-related events for the AI to understand user's subscription
journey and provide personalized assistance.

This data helps the AI coach:
- Understand user's subscription status
- Provide relevant recommendations based on their plan
- Offer upgrade suggestions at appropriate times
- Personalize messaging based on trial status
"""

from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field
from supabase import Client

from core.supabase_client import get_supabase
from services.user_context_service import UserContextService

router = APIRouter(prefix="/subscription-context", tags=["subscription-context"])


# =============================================================================
# EVENT TYPES
# =============================================================================

class SubscriptionEventType(str, Enum):
    """Subscription-related events for AI context."""
    PRICING_VIEWED = "subscription_pricing_viewed"
    TRIAL_STARTED = "subscription_trial_started"
    TRIAL_REMINDER_SHOWN = "subscription_trial_reminder_shown"
    TRIAL_EXPIRING = "subscription_trial_expiring"
    FREE_PLAN_SELECTED = "subscription_free_plan_selected"
    DEMO_WORKOUT_VIEWED = "subscription_demo_workout_viewed"
    DEMO_WORKOUT_COMPLETED = "subscription_demo_workout_completed"
    GUEST_SESSION_STARTED = "subscription_guest_session_started"
    GUEST_SESSION_ENDED = "subscription_guest_session_ended"
    GUEST_CONVERTED = "subscription_guest_converted"
    UPGRADE_PROMPT_SHOWN = "subscription_upgrade_prompt_shown"
    UPGRADE_PROMPT_DISMISSED = "subscription_upgrade_prompt_dismissed"
    FEATURE_LIMIT_HIT = "subscription_feature_limit_hit"
    PLAN_CHANGED = "subscription_plan_changed"


# =============================================================================
# REQUEST MODELS
# =============================================================================

class PricingViewedRequest(BaseModel):
    """Request when user views pricing."""
    screen: str = "welcome"  # Which screen showed pricing
    plans_viewed: list = Field(default_factory=list)  # Which plans they looked at
    time_spent_seconds: int = 0


class TrialStartedRequest(BaseModel):
    """Request when trial starts."""
    plan: str
    trial_days: int = 7
    source: str = "signup"  # signup, upgrade, promotion


class TrialReminderRequest(BaseModel):
    """Request when trial reminder is shown."""
    days_remaining: int
    reminder_type: str  # day_5, day_7, final


class FreePlanSelectedRequest(BaseModel):
    """Request when user selects free plan."""
    reason: Optional[str] = None  # Why they chose free
    features_seen: list = Field(default_factory=list)


class DemoWorkoutRequest(BaseModel):
    """Request for demo workout events."""
    workout_type: str
    exercises_completed: int = 0
    total_exercises: int = 0
    duration_seconds: int = 0


class GuestSessionRequest(BaseModel):
    """Request for guest session events."""
    session_duration_seconds: int = 0
    features_explored: list = Field(default_factory=list)
    workouts_viewed: int = 0


class FeatureLimitRequest(BaseModel):
    """Request when user hits a feature limit."""
    feature: str  # chat, workout_generation, food_scan
    current_usage: int
    limit: int
    shown_upgrade_option: bool = False


class PlanChangedRequest(BaseModel):
    """Request when subscription plan changes."""
    old_plan: Optional[str] = None
    new_plan: str
    change_type: str  # upgrade, downgrade, cancel


# =============================================================================
# ENDPOINTS
# =============================================================================

@router.post("/{user_id}/pricing-viewed")
async def log_pricing_viewed(
    user_id: UUID,
    request: PricingViewedRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log when user views pricing information."""
    try:
        context_service = UserContextService(supabase)

        await context_service.log_event(
            user_id=str(user_id),
            event_type=SubscriptionEventType.PRICING_VIEWED.value,
            event_data={
                "screen": request.screen,
                "plans_viewed": request.plans_viewed,
                "time_spent_seconds": request.time_spent_seconds,
                "timestamp": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Pricing view logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log pricing viewed: {e}")
        return {"success": False, "error": str(e)}


@router.post("/{user_id}/trial-started")
async def log_trial_started(
    user_id: UUID,
    request: TrialStartedRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log when user starts a trial."""
    try:
        context_service = UserContextService(supabase)

        await context_service.log_event(
            user_id=str(user_id),
            event_type=SubscriptionEventType.TRIAL_STARTED.value,
            event_data={
                "plan": request.plan,
                "trial_days": request.trial_days,
                "source": request.source,
                "start_date": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Trial start logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log trial started: {e}")
        return {"success": False, "error": str(e)}


@router.post("/{user_id}/trial-reminder")
async def log_trial_reminder(
    user_id: UUID,
    request: TrialReminderRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log when trial reminder is shown to user."""
    try:
        context_service = UserContextService(supabase)

        await context_service.log_event(
            user_id=str(user_id),
            event_type=SubscriptionEventType.TRIAL_REMINDER_SHOWN.value,
            event_data={
                "days_remaining": request.days_remaining,
                "reminder_type": request.reminder_type,
                "shown_at": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Trial reminder logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log trial reminder: {e}")
        return {"success": False, "error": str(e)}


@router.post("/{user_id}/free-plan-selected")
async def log_free_plan_selected(
    user_id: UUID,
    request: FreePlanSelectedRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log when user selects the free plan."""
    try:
        context_service = UserContextService(supabase)

        await context_service.log_event(
            user_id=str(user_id),
            event_type=SubscriptionEventType.FREE_PLAN_SELECTED.value,
            event_data={
                "reason": request.reason,
                "features_seen": request.features_seen,
                "selected_at": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Free plan selection logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log free plan selected: {e}")
        return {"success": False, "error": str(e)}


@router.post("/{user_id}/demo-workout-viewed")
async def log_demo_workout_viewed(
    user_id: UUID,
    request: DemoWorkoutRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log when user views/completes a demo workout."""
    try:
        context_service = UserContextService(supabase)

        event_type = SubscriptionEventType.DEMO_WORKOUT_COMPLETED if request.exercises_completed > 0 else SubscriptionEventType.DEMO_WORKOUT_VIEWED

        await context_service.log_event(
            user_id=str(user_id),
            event_type=event_type.value,
            event_data={
                "workout_type": request.workout_type,
                "exercises_completed": request.exercises_completed,
                "total_exercises": request.total_exercises,
                "duration_seconds": request.duration_seconds,
                "completion_rate": (request.exercises_completed / max(request.total_exercises, 1)) * 100,
                "timestamp": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Demo workout logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log demo workout: {e}")
        return {"success": False, "error": str(e)}


@router.post("/{user_id}/guest-session")
async def log_guest_session(
    user_id: UUID,
    request: GuestSessionRequest,
    ended: bool = False,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log guest session start or end."""
    try:
        context_service = UserContextService(supabase)

        event_type = SubscriptionEventType.GUEST_SESSION_ENDED if ended else SubscriptionEventType.GUEST_SESSION_STARTED

        await context_service.log_event(
            user_id=str(user_id),
            event_type=event_type.value,
            event_data={
                "session_duration_seconds": request.session_duration_seconds,
                "features_explored": request.features_explored,
                "workouts_viewed": request.workouts_viewed,
                "timestamp": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Guest session logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log guest session: {e}")
        return {"success": False, "error": str(e)}


@router.post("/{user_id}/guest-converted")
async def log_guest_converted(
    user_id: UUID,
    converted_to: str = "account",  # account, trial, paid
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log when a guest user converts to a registered user."""
    try:
        context_service = UserContextService(supabase)

        await context_service.log_event(
            user_id=str(user_id),
            event_type=SubscriptionEventType.GUEST_CONVERTED.value,
            event_data={
                "converted_to": converted_to,
                "converted_at": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Guest conversion logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log guest conversion: {e}")
        return {"success": False, "error": str(e)}


@router.post("/{user_id}/feature-limit-hit")
async def log_feature_limit_hit(
    user_id: UUID,
    request: FeatureLimitRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log when user hits a feature usage limit."""
    try:
        context_service = UserContextService(supabase)

        await context_service.log_event(
            user_id=str(user_id),
            event_type=SubscriptionEventType.FEATURE_LIMIT_HIT.value,
            event_data={
                "feature": request.feature,
                "current_usage": request.current_usage,
                "limit": request.limit,
                "shown_upgrade_option": request.shown_upgrade_option,
                "timestamp": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Feature limit hit logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log feature limit hit: {e}")
        return {"success": False, "error": str(e)}


@router.post("/{user_id}/plan-changed")
async def log_plan_changed(
    user_id: UUID,
    request: PlanChangedRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Log when user's subscription plan changes."""
    try:
        context_service = UserContextService(supabase)

        await context_service.log_event(
            user_id=str(user_id),
            event_type=SubscriptionEventType.PLAN_CHANGED.value,
            event_data={
                "old_plan": request.old_plan,
                "new_plan": request.new_plan,
                "change_type": request.change_type,
                "changed_at": datetime.utcnow().isoformat()
            }
        )

        return {"success": True, "message": "Plan change logged for AI context"}
    except Exception as e:
        print(f"❌ Failed to log plan change: {e}")
        return {"success": False, "error": str(e)}


@router.get("/{user_id}/context")
async def get_subscription_context(
    user_id: UUID,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Get subscription context for AI personalization.

    Returns recent subscription-related events for the AI to use
    when personalizing responses.
    """
    try:
        context_service = UserContextService(supabase)

        # Get recent subscription events
        events = await context_service.get_recent_events(
            user_id=str(user_id),
            event_type_prefix="subscription_",
            limit=20
        )

        # Get trial status
        trial_result = supabase.table("user_trial_status").select("*").eq(
            "user_id", str(user_id)
        ).single().execute()

        # Get subscription status
        subscription_result = supabase.table("user_subscriptions").select(
            "subscription_type", "is_active", "subscription_tier"
        ).eq("user_id", str(user_id)).single().execute()

        return {
            "user_id": str(user_id),
            "recent_events": events,
            "trial_status": trial_result.data if trial_result.data else None,
            "subscription_status": subscription_result.data if subscription_result.data else None,
            "context_summary": _generate_context_summary(events, trial_result.data, subscription_result.data)
        }
    except Exception as e:
        print(f"❌ Failed to get subscription context: {e}")
        return {
            "user_id": str(user_id),
            "recent_events": [],
            "trial_status": None,
            "subscription_status": None,
            "context_summary": "Unable to retrieve subscription context"
        }


def _generate_context_summary(events: list, trial_data: dict, subscription_data: dict) -> str:
    """Generate a natural language summary of user's subscription context for AI."""
    parts = []

    if subscription_data:
        if subscription_data.get("is_active"):
            tier = subscription_data.get("subscription_tier", "unknown")
            parts.append(f"User has an active {tier} subscription.")
        else:
            parts.append("User does not have an active paid subscription.")

    if trial_data:
        status = trial_data.get("trial_status", "unknown")
        if status == "active":
            parts.append("User is currently in their free trial period.")
        elif status == "expired":
            parts.append("User's trial has expired.")
        elif status == "converted":
            parts.append("User converted from trial to paid.")

    # Analyze recent events
    event_types = [e.get("event_type", "") for e in events] if events else []

    if "subscription_feature_limit_hit" in event_types:
        parts.append("User has recently hit feature limits.")

    if "subscription_demo_workout_completed" in event_types:
        parts.append("User has tried demo workouts.")

    if "subscription_pricing_viewed" in event_types:
        parts.append("User has recently viewed pricing.")

    return " ".join(parts) if parts else "No subscription context available."
