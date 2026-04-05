"""
Free trial system: eligibility, start trial, convert, trial status.
"""
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from typing import Optional

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from api.v1.subscriptions.models import (
    TrialEligibilityResponse,
    StartTrialRequest,
    StartTrialResponse,
    TrialConversionRequest,
    _product_to_tier,
)

router = APIRouter()
logger = get_logger(__name__)


@router.get("/trial-eligibility/{user_id}", response_model=TrialEligibilityResponse)
async def check_trial_eligibility(user_id: str, current_user: dict = Depends(get_current_user)):
    """Check if a user is eligible for a free trial."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Checking trial eligibility for user: {user_id}")

    try:
        supabase = get_supabase()

        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        subscription = sub_result.data

        previous_trials = 0
        has_had_extension = False
        if subscription:
            trial_history = supabase.client.table("subscription_history")\
                .select("id")\
                .eq("user_id", user_id)\
                .eq("event_type", "trial_started")\
                .execute()

            previous_trials = len(trial_history.data) if trial_history.data else 0

            extension_result = supabase.client.table("trial_extensions")\
                .select("id")\
                .eq("user_id", user_id)\
                .execute()

            has_had_extension = len(extension_result.data) > 0 if extension_result.data else False

        is_eligible = True
        reason = None
        can_extend = False
        extension_reason = None

        if subscription:
            current_tier = subscription.get("tier", "free")
            current_status = subscription.get("status", "")

            if current_tier != "free" and current_status == "active":
                is_eligible = False
                reason = "You already have an active subscription"
            elif subscription.get("is_trial") and current_status == "trial":
                is_eligible = False
                reason = "You are currently on a trial"
                if not has_had_extension:
                    can_extend = True
                    extension_reason = "Contact support for a trial extension"
            elif previous_trials > 0:
                is_eligible = False
                reason = "You have already used your free trial"
                if previous_trials == 1:
                    can_extend = True
                    extension_reason = "You may be eligible for a special offer. Contact support."

        available_plans = ["monthly", "yearly", "lifetime_intro"] if is_eligible else []

        return TrialEligibilityResponse(
            user_id=user_id,
            is_eligible=is_eligible,
            reason=reason,
            trial_duration_days=7,
            available_plans=available_plans,
            previous_trials=previous_trials,
            can_extend=can_extend,
            extension_reason=extension_reason,
        )

    except Exception as e:
        raise safe_internal_error(e, "check_trial_eligibility")


@router.post("/start-trial/{user_id}", response_model=StartTrialResponse)
async def start_trial(user_id: str, request: StartTrialRequest, current_user: dict = Depends(get_current_user)):
    """Start a 7-day free trial for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Starting trial for user: {user_id}, plan: {request.plan_type}")

    try:
        supabase = get_supabase()

        valid_plans = ["monthly", "yearly", "lifetime_intro"]
        if request.plan_type not in valid_plans:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid plan type. Must be one of: {', '.join(valid_plans)}"
            )

        eligibility = await check_trial_eligibility(user_id)
        if not eligibility.is_eligible:
            raise HTTPException(
                status_code=400,
                detail=eligibility.reason or "You are not eligible for a free trial"
            )

        now = datetime.utcnow()
        trial_end = now + timedelta(days=7)

        plan_tier_map = {
            "monthly": "premium",
            "yearly": "premium",
            "lifetime_intro": "lifetime",
        }
        trial_tier = plan_tier_map.get(request.plan_type, "premium")

        sub_data = {
            "user_id": user_id,
            "tier": trial_tier,
            "status": "trial",
            "is_trial": True,
            "trial_type": "full_access",
            "trial_plan_type": request.plan_type,
            "trial_end_date": trial_end.isoformat(),
            "started_at": now.isoformat(),
            "current_period_start": now.isoformat(),
            "current_period_end": trial_end.isoformat(),
            "demo_session_id": request.demo_session_id,
        }

        supabase.client.table("user_subscriptions")\
            .upsert(sub_data, on_conflict="user_id")\
            .execute()

        supabase.client.table("subscription_history").insert({
            "user_id": user_id,
            "event_type": "trial_started",
            "new_tier": trial_tier,
            "metadata": {
                "trial_plan_type": request.plan_type,
                "trial_duration_days": 7,
                "source": request.source,
                "demo_session_id": request.demo_session_id,
            }
        }).execute()

        if request.demo_session_id:
            try:
                supabase.client.table("demo_sessions").update({
                    "converted_to_user_id": user_id,
                    "conversion_trigger": f"trial_started_{request.plan_type}",
                    "ended_at": now.isoformat(),
                }).eq("session_id", request.demo_session_id).execute()
            except Exception as e:
                logger.warning(f"Failed to update demo session: {e}")

        await log_user_activity(
            user_id=user_id,
            action="trial_started",
            endpoint=f"/api/v1/subscriptions/start-trial/{user_id}",
            message=f"Started 7-day trial for {request.plan_type} plan",
            metadata={
                "plan_type": request.plan_type,
                "trial_tier": trial_tier,
                "source": request.source,
            },
            status_code=200
        )

        return StartTrialResponse(
            user_id=user_id,
            tier=trial_tier,
            status="trial",
            trial_started=True,
            trial_end_date=trial_end.isoformat(),
            trial_plan_type=request.plan_type,
            message=f"Your 7-day free trial has started! Enjoy full access to all {trial_tier} features.",
            features_unlocked=[
                "Unlimited AI-generated workouts",
                "Full exercise library (1700+ exercises)",
                "AI coach chat",
                "Nutrition tracking",
                "Progress analytics",
                "Custom workout builder",
            ],
        )

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "start_trial")


@router.post("/convert-trial/{user_id}")
async def convert_trial_to_paid(user_id: str, request: TrialConversionRequest, current_user: dict = Depends(get_current_user)):
    """Convert a trial to a paid subscription."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Converting trial to paid for user: {user_id}")

    try:
        supabase = get_supabase()

        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not sub_result.data:
            raise HTTPException(status_code=404, detail="No subscription found")

        subscription = sub_result.data

        if not subscription.get("is_trial"):
            raise HTTPException(status_code=400, detail="User is not on a trial")

        tier = _product_to_tier(request.product_id)

        now = datetime.utcnow()
        supabase.client.table("user_subscriptions")\
            .update({
                "tier": tier,
                "status": "active",
                "is_trial": False,
                "product_id": request.product_id,
                "current_period_start": now.isoformat(),
            })\
            .eq("user_id", user_id)\
            .execute()

        supabase.client.table("subscription_history").insert({
            "user_id": user_id,
            "event_type": "trial_converted",
            "previous_tier": subscription.get("tier"),
            "new_tier": tier,
            "product_id": request.product_id,
            "metadata": {
                "trial_plan_type": subscription.get("trial_plan_type"),
                "trial_duration_days": 7,
                "conversion_day": (now - datetime.fromisoformat(subscription["started_at"].replace("Z", "+00:00")).replace(tzinfo=None)).days if subscription.get("started_at") else None,
            }
        }).execute()

        await log_user_activity(
            user_id=user_id,
            action="trial_converted",
            endpoint=f"/api/v1/subscriptions/convert-trial/{user_id}",
            message=f"Trial converted to {tier} subscription",
            metadata={
                "product_id": request.product_id,
                "tier": tier,
            },
            status_code=200
        )

        return {
            "status": "converted",
            "tier": tier,
            "message": f"Welcome to {tier.title()}! Your subscription is now active.",
        }

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "convert_trial_to_paid")


@router.get("/trial-status/{user_id}")
async def get_trial_status(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get detailed trial status for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting trial status for user: {user_id}")

    try:
        supabase = get_supabase()

        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not sub_result.data:
            return {
                "is_on_trial": False,
                "has_subscription": False,
                "trial_eligible": True,
                "message": "No subscription found. Start your free trial!",
            }

        subscription = sub_result.data

        if not subscription.get("is_trial"):
            return {
                "is_on_trial": False,
                "has_subscription": True,
                "tier": subscription.get("tier"),
                "status": subscription.get("status"),
                "message": f"You have an active {subscription.get('tier')} subscription.",
            }

        days_remaining = 0
        if subscription.get("trial_end_date"):
            try:
                trial_end = datetime.fromisoformat(
                    subscription["trial_end_date"].replace("Z", "+00:00")
                )
                now = datetime.now(trial_end.tzinfo) if trial_end.tzinfo else datetime.utcnow()
                days_remaining = max(0, (trial_end - now).days)
            except (ValueError, TypeError) as e:
                logger.debug(f"Failed to parse trial end date: {e}")

        pricing = {
            "monthly": {"price": 9.99, "currency": "USD", "period": "month"},
            "yearly": {"price": 59.99, "currency": "USD", "period": "year", "savings": "50%"},
            "lifetime_intro": {"price": 149.99, "currency": "USD", "period": "one-time", "limited": True},
        }

        trial_plan = subscription.get("trial_plan_type", "monthly")

        return {
            "is_on_trial": True,
            "has_subscription": True,
            "tier": subscription.get("tier"),
            "trial_plan_type": trial_plan,
            "trial_started": subscription.get("started_at"),
            "trial_end_date": subscription.get("trial_end_date"),
            "days_remaining": days_remaining,
            "conversion_pricing": pricing.get(trial_plan, pricing["monthly"]),
            "all_plans": pricing,
            "message": f"You have {days_remaining} days left in your trial. Subscribe to keep your progress!",
            "features_at_risk": [
                "AI workout generation",
                "Progress tracking",
                "Exercise history",
                "Nutrition insights",
            ] if days_remaining <= 2 else [],
        }

    except Exception as e:
        raise safe_internal_error(e, "get_trial_status")
