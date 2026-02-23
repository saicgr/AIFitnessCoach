"""
Subscription Transparency API

Addresses complaint: "Have to go through the sign up process and create an account
before they hit you with the subscription screen."

This API tracks subscription transparency events, trial status, and ensures users
see pricing information before committing to signup.
"""

from datetime import datetime, timedelta
from enum import Enum
from typing import Optional, List
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field
from supabase import Client

from core.supabase_client import get_supabase

router = APIRouter(prefix="/subscription-transparency", tags=["subscription-transparency"])


# =============================================================================
# ENUMS
# =============================================================================

class TransparencyEventType(str, Enum):
    """Types of transparency events we track."""
    PRICING_VIEWED = "pricing_viewed"
    PRICING_DETAILS_OPENED = "pricing_details_opened"
    TRIAL_INFO_VIEWED = "trial_info_viewed"
    FREE_TIER_EXPLAINED = "free_tier_explained"
    DEMO_STARTED = "demo_started"
    DEMO_COMPLETED = "demo_completed"
    GUEST_MODE_STARTED = "guest_mode_started"
    GUEST_MODE_ENDED = "guest_mode_ended"
    TRY_WORKOUT_STARTED = "try_workout_started"
    TRY_WORKOUT_COMPLETED = "try_workout_completed"
    PLAN_PREVIEW_VIEWED = "plan_preview_viewed"
    TRIAL_STARTED = "trial_started"
    TRIAL_REMINDER_SENT = "trial_reminder_sent"
    TRIAL_EXPIRED = "trial_expired"
    TRIAL_CONVERTED = "trial_converted"
    FREE_PLAN_SELECTED = "free_plan_selected"
    SUBSCRIPTION_STARTED = "subscription_started"
    SUBSCRIPTION_CANCELLED = "subscription_cancelled"


class TrialStatus(str, Enum):
    """Trial status values."""
    ACTIVE = "active"
    EXPIRED = "expired"
    CONVERTED = "converted"
    CANCELLED = "cancelled"


# =============================================================================
# REQUEST/RESPONSE MODELS
# =============================================================================

class TransparencyEventRequest(BaseModel):
    """Request to log a transparency event."""
    event_type: TransparencyEventType
    user_id: Optional[UUID] = None
    device_id: Optional[str] = None
    session_id: Optional[str] = None
    event_data: dict = Field(default_factory=dict)
    app_version: Optional[str] = None
    platform: Optional[str] = None


class TransparencyEventResponse(BaseModel):
    """Response after logging an event."""
    id: UUID
    event_type: str
    created_at: datetime
    success: bool = True


class TrialStatusResponse(BaseModel):
    """Response with user's trial status."""
    user_id: UUID
    trial_status: Optional[str] = None
    trial_start_date: Optional[datetime] = None
    trial_end_date: Optional[datetime] = None
    trial_plan: Optional[str] = None
    days_remaining: Optional[int] = None
    reminder_sent_day_5: bool = False
    reminder_sent_day_7: bool = False
    features_used: List[str] = Field(default_factory=list)
    is_active: bool = False


class StartTrialRequest(BaseModel):
    """Request to start a trial."""
    user_id: UUID
    trial_plan: str = "premium_yearly"
    trial_days: int = 7


class StartTrialResponse(BaseModel):
    """Response after starting a trial."""
    success: bool
    trial_start_date: datetime
    trial_end_date: datetime
    trial_plan: str
    message: str


class PricingShownResponse(BaseModel):
    """Response indicating if pricing was shown to user."""
    user_id: Optional[UUID] = None
    device_id: Optional[str] = None
    pricing_shown_before_signup: bool
    pricing_shown_at: Optional[datetime] = None
    trial_info_shown: bool = False
    free_tier_explained: bool = False


class ConversionTriggerRequest(BaseModel):
    """Request to log what triggered a conversion."""
    user_id: UUID
    trigger_type: str  # 'plan_preview', 'try_workout', 'demo_day', 'feature_tap'
    trigger_details: dict = Field(default_factory=dict)
    resulted_in: str  # 'trial', 'purchase', 'nothing'


# =============================================================================
# ENDPOINTS
# =============================================================================

@router.post("/event", response_model=TransparencyEventResponse)
async def log_transparency_event(
    request: TransparencyEventRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> TransparencyEventResponse:
    """
    Log a subscription transparency event.

    Called when users view pricing, start trials, etc.
    Tracks the entire user journey for transparency compliance.
    """
    event_id = uuid4()

    try:
        data = {
            "id": str(event_id),
            "event_type": request.event_type.value,
            "user_id": str(request.user_id) if request.user_id else None,
            "device_id": request.device_id,
            "session_id": request.session_id,
            "event_data": request.event_data,
            "app_version": request.app_version,
            "platform": request.platform,
            "created_at": datetime.utcnow().isoformat()
        }

        # Try to insert into the tracking table
        result = supabase.table("subscription_transparency_events").insert(data).execute()

        return TransparencyEventResponse(
            id=event_id,
            event_type=request.event_type.value,
            created_at=datetime.utcnow(),
            success=True
        )
    except Exception as e:
        # Log but don't fail - transparency tracking shouldn't block user flow
        print(f"❌ Failed to log transparency event: {e}")
        return TransparencyEventResponse(
            id=event_id,
            event_type=request.event_type.value,
            created_at=datetime.utcnow(),
            success=False
        )


@router.get("/trial-status/{user_id}", response_model=TrialStatusResponse)
async def get_trial_status(
    user_id: UUID,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> TrialStatusResponse:
    """
    Get the trial status for a user.

    Returns trial dates, remaining days, and what features they've used.
    """
    try:
        result = supabase.table("user_trial_status").select("*").eq(
            "user_id", str(user_id)
        ).single().execute()

        if not result.data:
            return TrialStatusResponse(
                user_id=user_id,
                is_active=False
            )

        data = result.data
        trial_end = datetime.fromisoformat(data["trial_end_date"].replace("Z", "+00:00"))
        now = datetime.utcnow().replace(tzinfo=trial_end.tzinfo)
        days_remaining = max(0, (trial_end - now).days)
        is_active = data["trial_status"] == "active" and days_remaining > 0

        return TrialStatusResponse(
            user_id=user_id,
            trial_status=data["trial_status"],
            trial_start_date=datetime.fromisoformat(data["trial_start_date"].replace("Z", "+00:00")),
            trial_end_date=trial_end,
            trial_plan=data["trial_plan"],
            days_remaining=days_remaining,
            reminder_sent_day_5=data.get("reminder_sent_day_5", False),
            reminder_sent_day_7=data.get("reminder_sent_day_7", False),
            features_used=data.get("features_used", []),
            is_active=is_active
        )
    except Exception as e:
        print(f"❌ Failed to get trial status: {e}")
        return TrialStatusResponse(
            user_id=user_id,
            is_active=False
        )


@router.post("/trial/start", response_model=StartTrialResponse)
async def start_trial(
    request: StartTrialRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> StartTrialResponse:
    """
    Start a trial for a user.

    Creates trial status record and logs the event.
    """
    trial_start = datetime.utcnow()
    trial_end = trial_start + timedelta(days=request.trial_days)

    try:
        # Check if user already has a trial
        existing = supabase.table("user_trial_status").select("id").eq(
            "user_id", str(request.user_id)
        ).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="User already has a trial record. Use update endpoint instead."
            )

        # Create trial status
        trial_data = {
            "id": str(uuid4()),
            "user_id": str(request.user_id),
            "trial_start_date": trial_start.isoformat(),
            "trial_end_date": trial_end.isoformat(),
            "trial_plan": request.trial_plan,
            "trial_status": "active",
            "features_used": []
        }

        supabase.table("user_trial_status").insert(trial_data).execute()

        # Log the event
        await log_transparency_event(
            TransparencyEventRequest(
                event_type=TransparencyEventType.TRIAL_STARTED,
                user_id=request.user_id,
                event_data={
                    "trial_plan": request.trial_plan,
                    "trial_days": request.trial_days
                }
            ),
            supabase
        )

        return StartTrialResponse(
            success=True,
            trial_start_date=trial_start,
            trial_end_date=trial_end,
            trial_plan=request.trial_plan,
            message=f"Trial started successfully. Expires on {trial_end.strftime('%Y-%m-%d')}"
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Failed to start trial: {e}")
        raise safe_internal_error(e, "subscription_start_trial")


@router.get("/pricing-shown", response_model=PricingShownResponse)
async def check_pricing_shown(
    user_id: Optional[UUID] = Query(None),
    device_id: Optional[str] = Query(None),
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> PricingShownResponse:
    """
    Check if pricing was shown to a user before signup.

    Used to verify transparency compliance.
    """
    if not user_id and not device_id:
        raise HTTPException(
            status_code=400,
            detail="Must provide either user_id or device_id"
        )

    try:
        # Look for pricing_viewed events
        query = supabase.table("subscription_transparency_events").select("*").eq(
            "event_type", TransparencyEventType.PRICING_VIEWED.value
        )

        if user_id:
            query = query.eq("user_id", str(user_id))
        if device_id:
            query = query.eq("device_id", device_id)

        result = query.order("created_at", desc=True).limit(1).execute()

        pricing_shown = len(result.data) > 0
        pricing_shown_at = None

        if pricing_shown:
            pricing_shown_at = datetime.fromisoformat(
                result.data[0]["created_at"].replace("Z", "+00:00")
            )

        # Check for trial info and free tier explanation events
        trial_info_result = supabase.table("subscription_transparency_events").select("id").eq(
            "event_type", TransparencyEventType.TRIAL_INFO_VIEWED.value
        )
        if user_id:
            trial_info_result = trial_info_result.eq("user_id", str(user_id))
        if device_id:
            trial_info_result = trial_info_result.eq("device_id", device_id)
        trial_info_result = trial_info_result.limit(1).execute()

        free_tier_result = supabase.table("subscription_transparency_events").select("id").eq(
            "event_type", TransparencyEventType.FREE_TIER_EXPLAINED.value
        )
        if user_id:
            free_tier_result = free_tier_result.eq("user_id", str(user_id))
        if device_id:
            free_tier_result = free_tier_result.eq("device_id", device_id)
        free_tier_result = free_tier_result.limit(1).execute()

        return PricingShownResponse(
            user_id=user_id,
            device_id=device_id,
            pricing_shown_before_signup=pricing_shown,
            pricing_shown_at=pricing_shown_at,
            trial_info_shown=len(trial_info_result.data) > 0,
            free_tier_explained=len(free_tier_result.data) > 0
        )
    except Exception as e:
        print(f"❌ Failed to check pricing shown: {e}")
        return PricingShownResponse(
            user_id=user_id,
            device_id=device_id,
            pricing_shown_before_signup=False
        )


@router.post("/conversion-trigger")
async def log_conversion_trigger(
    request: ConversionTriggerRequest,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Log what triggered a user's conversion decision.

    Helps analyze which features drive conversions.
    """
    try:
        data = {
            "id": str(uuid4()),
            "user_id": str(request.user_id),
            "trigger_type": request.trigger_type,
            "trigger_details": request.trigger_details,
            "resulted_in": request.resulted_in,
            "occurred_at": datetime.utcnow().isoformat()
        }

        supabase.table("conversion_triggers").insert(data).execute()

        return {"success": True, "message": "Conversion trigger logged"}
    except Exception as e:
        print(f"❌ Failed to log conversion trigger: {e}")
        return {"success": False, "error": str(e)}


@router.post("/plan-preview")
async def log_plan_preview(
    session_id: Optional[str] = None,
    user_id: Optional[UUID] = None,
    quiz_data: dict = None,
    generated_plan: dict = None,
    preview_type: str = "full_plan",
    device_info: dict = None,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Log when a user previews their personalized plan before signup.

    This is key for showing value before asking for payment.
    """
    try:
        data = {
            "id": str(uuid4()),
            "session_id": session_id,
            "user_id": str(user_id) if user_id else None,
            "quiz_data": quiz_data or {},
            "generated_plan": generated_plan or {},
            "preview_type": preview_type,
            "device_info": device_info
        }

        supabase.table("plan_previews").insert(data).execute()

        return {"success": True, "message": "Plan preview logged"}
    except Exception as e:
        print(f"❌ Failed to log plan preview: {e}")
        return {"success": False, "error": str(e)}


@router.post("/try-workout")
async def log_try_workout(
    session_id: Optional[str] = None,
    user_id: Optional[UUID] = None,
    workout_data: dict = None,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Log when a user starts a "Try One Workout" session.
    """
    try:
        data = {
            "id": str(uuid4()),
            "session_id": session_id,
            "user_id": str(user_id) if user_id else None,
            "workout_data": workout_data or {}
        }

        supabase.table("try_workout_sessions").insert(data).execute()

        return {"success": True, "message": "Try workout session started"}
    except Exception as e:
        print(f"❌ Failed to log try workout: {e}")
        return {"success": False, "error": str(e)}


@router.patch("/try-workout/{session_id}")
async def update_try_workout(
    session_id: str,
    completed: bool = False,
    completion_percentage: int = 0,
    exercises_completed: int = 0,
    feedback: str = None,
    converted_after: bool = False,
    supabase: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Update a try workout session with completion data.
    """
    try:
        update_data = {
            "completion_percentage": completion_percentage,
            "exercises_completed": exercises_completed,
            "converted_after": converted_after
        }

        if completed:
            update_data["completed_at"] = datetime.utcnow().isoformat()

        if feedback:
            update_data["feedback"] = feedback

        supabase.table("try_workout_sessions").update(update_data).eq(
            "session_id", session_id
        ).execute()

        return {"success": True, "message": "Try workout session updated"}
    except Exception as e:
        print(f"❌ Failed to update try workout: {e}")
        return {"success": False, "error": str(e)}
