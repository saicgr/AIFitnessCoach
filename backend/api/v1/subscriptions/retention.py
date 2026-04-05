"""
Subscription pause/resume and retention offer endpoints.
"""
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from typing import Optional
import logging

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from api.v1.subscriptions.models import (
    PauseSubscriptionRequest,
    PauseSubscriptionResponse,
    ResumeSubscriptionResponse,
    RetentionOffer,
    RetentionOffersResponse,
    AcceptOfferRequest,
    AcceptOfferResponse,
)

router = APIRouter()
logger = get_logger(__name__)
audit_logger = logging.getLogger("audit.subscriptions")


@router.post("/{user_id}/pause", response_model=PauseSubscriptionResponse)
async def pause_subscription(user_id: str, request: PauseSubscriptionRequest, current_user: dict = Depends(get_current_user)):
    """Pause a user's subscription for a specified duration."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Pausing subscription for user: {user_id}, duration: {request.duration_days} days")

    try:
        supabase = get_supabase()

        valid_durations = [7, 14, 30, 60, 90]
        if request.duration_days not in valid_durations:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid duration. Must be one of: {', '.join(map(str, valid_durations))} days"
            )

        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not sub_result.data:
            raise HTTPException(status_code=404, detail="No subscription found")

        subscription = sub_result.data
        tier = subscription.get("tier", "free")
        status = subscription.get("status", "")

        if tier == "lifetime" or subscription.get("is_lifetime"):
            raise HTTPException(status_code=400, detail="Lifetime memberships cannot be paused. You have permanent access!")

        if tier == "free":
            raise HTTPException(status_code=400, detail="Free accounts cannot be paused. Upgrade to pause your subscription.")

        if status == "paused":
            raise HTTPException(status_code=400, detail="Subscription is already paused")

        now = datetime.utcnow()
        resume_date = now + timedelta(days=request.duration_days)

        supabase.client.table("user_subscriptions")\
            .update({
                "status": "paused",
                "paused_at": now.isoformat(),
                "pause_resume_date": resume_date.isoformat(),
                "pause_duration_days": request.duration_days,
                "pause_reason": request.reason,
            })\
            .eq("user_id", user_id)\
            .execute()

        supabase.client.table("subscription_pauses").insert({
            "user_id": user_id,
            "subscription_id": subscription.get("id"),
            "paused_at": now.isoformat(),
            "resume_date": resume_date.isoformat(),
            "duration_days": request.duration_days,
            "reason": request.reason,
            "status": "active",
        }).execute()

        supabase.client.table("subscription_history").insert({
            "user_id": user_id,
            "event_type": "paused",
            "previous_tier": tier,
            "metadata": {
                "duration_days": request.duration_days,
                "resume_date": resume_date.isoformat(),
                "reason": request.reason,
            }
        }).execute()

        await log_user_activity(
            user_id=user_id,
            action="subscription_paused",
            endpoint=f"/api/v1/subscriptions/{user_id}/pause",
            message=f"Subscription paused for {request.duration_days} days",
            metadata={
                "duration_days": request.duration_days,
                "resume_date": resume_date.isoformat(),
                "reason": request.reason,
            },
            status_code=200
        )

        logger.info(f"Subscription paused for user {user_id} until {resume_date.isoformat()}")

        return PauseSubscriptionResponse(
            user_id=user_id,
            status="paused",
            paused_at=now.isoformat(),
            resume_date=resume_date.isoformat(),
            duration_days=request.duration_days,
            message=f"Your subscription has been paused. It will automatically resume on {resume_date.strftime('%B %d, %Y')}."
        )

    except HTTPException:
        raise
    except Exception as e:
        await log_user_error(
            user_id=user_id,
            action="subscription_pause_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/pause",
            error_message=str(e),
            metadata={"duration_days": request.duration_days}
        )
        raise safe_internal_error(e, "pause_subscription")


@router.post("/{user_id}/resume", response_model=ResumeSubscriptionResponse)
async def resume_subscription(user_id: str, current_user: dict = Depends(get_current_user)):
    """Resume a paused subscription early."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Resuming subscription for user: {user_id}")

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
        status = subscription.get("status", "")
        tier = subscription.get("tier", "free")

        if status != "paused":
            raise HTTPException(status_code=400, detail=f"Subscription is not paused. Current status: {status}")

        now = datetime.utcnow()

        supabase.client.table("user_subscriptions")\
            .update({
                "status": "active",
                "resumed_at": now.isoformat(),
                "paused_at": None,
                "pause_resume_date": None,
                "pause_duration_days": None,
                "pause_reason": None,
            })\
            .eq("user_id", user_id)\
            .execute()

        supabase.client.table("subscription_pauses")\
            .update({
                "status": "resumed_early",
                "actual_resume_date": now.isoformat(),
            })\
            .eq("user_id", user_id)\
            .eq("status", "active")\
            .execute()

        supabase.client.table("subscription_history").insert({
            "user_id": user_id,
            "event_type": "resumed",
            "new_tier": tier,
            "metadata": {
                "resumed_early": True,
                "original_resume_date": subscription.get("pause_resume_date"),
            }
        }).execute()

        await log_user_activity(
            user_id=user_id,
            action="subscription_resumed",
            endpoint=f"/api/v1/subscriptions/{user_id}/resume",
            message="Subscription resumed early",
            metadata={
                "tier": tier,
                "resumed_early": True,
            },
            status_code=200
        )

        logger.info(f"Subscription resumed for user {user_id}")

        return ResumeSubscriptionResponse(
            user_id=user_id,
            status="active",
            resumed_at=now.isoformat(),
            tier=tier,
            message=f"Welcome back! Your {tier.title()} subscription is now active."
        )

    except HTTPException:
        raise
    except Exception as e:
        await log_user_error(
            user_id=user_id,
            action="subscription_resume_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/resume",
            error_message=str(e),
            metadata={}
        )
        raise safe_internal_error(e, "resume_subscription")


@router.get("/{user_id}/retention-offers", response_model=RetentionOffersResponse)
async def get_retention_offers(user_id: str, reason: Optional[str] = None, current_user: dict = Depends(get_current_user)):
    """Get available retention offers to prevent cancellation."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching retention offers for user: {user_id}, reason: {reason}")

    try:
        supabase = get_supabase()

        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not sub_result.data:
            return RetentionOffersResponse(user_id=user_id, offers=[], cancellation_reason=reason)

        subscription = sub_result.data
        tier = subscription.get("tier", "free")
        is_lifetime = subscription.get("is_lifetime") or tier == "lifetime"

        if is_lifetime:
            return RetentionOffersResponse(user_id=user_id, offers=[], cancellation_reason=reason)

        prev_offers = supabase.client.table("retention_offers_accepted")\
            .select("offer_type")\
            .eq("user_id", user_id)\
            .execute()

        accepted_types = [o["offer_type"] for o in (prev_offers.data or [])]

        offers = []

        if "pause" not in accepted_types:
            offers.append(RetentionOffer(
                id=f"pause_{user_id}_{datetime.utcnow().timestamp()}",
                type="pause",
                title="Take a Break",
                description="Pause your subscription for up to 3 months. Your data stays safe, and billing stops.",
                value="Free",
                expires_in_hours=48
            ))

        if reason in ["too_expensive", "price", "cost"] and "discount" not in accepted_types:
            offers.append(RetentionOffer(
                id=f"discount_50_{user_id}_{datetime.utcnow().timestamp()}",
                type="discount",
                title="50% Off Next Month",
                description="We'd hate to see you go! Enjoy half off your next billing cycle.",
                value="50% off",
                discount_percent=50,
                expires_in_hours=24
            ))
        elif "discount" not in accepted_types:
            offers.append(RetentionOffer(
                id=f"discount_25_{user_id}_{datetime.utcnow().timestamp()}",
                type="discount",
                title="25% Off Next Month",
                description="Stay with us and save on your next billing cycle.",
                value="25% off",
                discount_percent=25,
                expires_in_hours=24
            ))

        if reason in ["not_using", "busy", "no_time"] and "extension" not in accepted_types:
            offers.append(RetentionOffer(
                id=f"extension_14_{user_id}_{datetime.utcnow().timestamp()}",
                type="extension",
                title="2 Extra Weeks Free",
                description="Take more time to get back on track. We'll add 14 days free to your subscription.",
                value="14 days free",
                extension_days=14,
                expires_in_hours=48
            ))

        if tier == "premium_plus" and "downgrade" not in accepted_types:
            offers.append(RetentionOffer(
                id=f"downgrade_premium_{user_id}_{datetime.utcnow().timestamp()}",
                type="downgrade",
                title="Switch to Premium",
                description="Keep core features at a lower price. Premium gives you everything essential.",
                value="Save $5/month",
                target_tier="premium",
                expires_in_hours=72
            ))

        return RetentionOffersResponse(user_id=user_id, offers=offers, cancellation_reason=reason)

    except Exception as e:
        raise safe_internal_error(e, "get_retention_offers")


@router.post("/{user_id}/accept-offer", response_model=AcceptOfferResponse)
async def accept_retention_offer(user_id: str, request: AcceptOfferRequest, current_user: dict = Depends(get_current_user)):
    """Accept a retention offer."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Accepting retention offer for user: {user_id}, offer: {request.offer_id}")

    try:
        supabase = get_supabase()

        offer_parts = request.offer_id.split("_")
        if len(offer_parts) < 2:
            raise HTTPException(status_code=400, detail="Invalid offer ID format")

        offer_type = offer_parts[0]

        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not sub_result.data:
            raise HTTPException(status_code=404, detail="No subscription found")

        subscription = sub_result.data
        now = datetime.utcnow()

        new_status = subscription.get("status")
        new_tier = subscription.get("tier")
        discount_applied = None
        extension_days = None
        message = ""

        if offer_type == "discount":
            try:
                discount_applied = int(offer_parts[1])
            except (ValueError, IndexError):
                discount_applied = 25

            supabase.client.table("subscription_discounts").insert({
                "user_id": user_id,
                "discount_percent": discount_applied,
                "reason": "retention_offer",
                "offer_id": request.offer_id,
                "valid_until": (now + timedelta(days=45)).isoformat(),
                "status": "pending",
            }).execute()

            message = f"A {discount_applied}% discount will be applied to your next billing cycle."

        elif offer_type == "extension":
            try:
                extension_days = int(offer_parts[1])
            except (ValueError, IndexError):
                extension_days = 7

            current_end = subscription.get("current_period_end")
            if current_end:
                try:
                    end_date = datetime.fromisoformat(current_end.replace("Z", "+00:00"))
                    new_end = end_date + timedelta(days=extension_days)
                    supabase.client.table("user_subscriptions")\
                        .update({"current_period_end": new_end.isoformat()})\
                        .eq("user_id", user_id)\
                        .execute()
                except (ValueError, TypeError) as e:
                    logger.warning(f"Failed to extend subscription: {e}")

            message = f"{extension_days} free days have been added to your subscription."

        elif offer_type == "downgrade":
            target_tier = "premium" if len(offer_parts) < 2 else offer_parts[1]

            # CRITICAL: Prevent tier escalation
            tier_levels = {"free": 0, "premium": 1, "premium_plus": 2, "lifetime": 3}
            current_level = tier_levels.get(subscription.get("tier", "free"), 0)
            target_level = tier_levels.get(target_tier, 0)

            if target_level > current_level:
                audit_logger.warning(
                    f"BLOCKED tier escalation attempt: user={user_id}, "
                    f"current={subscription.get('tier')}, attempted={target_tier}, offer={request.offer_id}"
                )
                raise HTTPException(
                    status_code=403,
                    detail="Retention offers cannot escalate subscription tier"
                )

            new_tier = target_tier
            audit_logger.info(
                f"Tier change via retention offer: user={user_id}, "
                f"from={subscription.get('tier')}, to={target_tier}, offer={request.offer_id}"
            )

            supabase.client.table("user_subscriptions")\
                .update({"tier": target_tier})\
                .eq("user_id", user_id)\
                .execute()

            message = f"Your subscription has been changed to {target_tier.title()}."

        elif offer_type == "pause":
            message = "Please use the pause subscription option to complete this action."

        else:
            raise HTTPException(status_code=400, detail=f"Unknown offer type: {offer_type}")

        supabase.client.table("retention_offers_accepted").insert({
            "user_id": user_id,
            "offer_id": request.offer_id,
            "offer_type": offer_type,
            "cancellation_reason": request.cancellation_reason,
            "accepted_at": now.isoformat(),
            "discount_percent": discount_applied,
            "extension_days": extension_days,
            "target_tier": new_tier if offer_type == "downgrade" else None,
        }).execute()

        supabase.client.table("subscription_history").insert({
            "user_id": user_id,
            "event_type": "retention_offer_accepted",
            "metadata": {
                "offer_id": request.offer_id,
                "offer_type": offer_type,
                "discount_percent": discount_applied,
                "extension_days": extension_days,
                "cancellation_reason": request.cancellation_reason,
            }
        }).execute()

        await log_user_activity(
            user_id=user_id,
            action="retention_offer_accepted",
            endpoint=f"/api/v1/subscriptions/{user_id}/accept-offer",
            message=f"Accepted {offer_type} retention offer",
            metadata={
                "offer_id": request.offer_id,
                "offer_type": offer_type,
            },
            status_code=200
        )

        logger.info(f"Retention offer accepted for user {user_id}: {offer_type}")

        return AcceptOfferResponse(
            user_id=user_id,
            offer_id=request.offer_id,
            offer_type=offer_type,
            applied=True,
            new_status=new_status,
            new_tier=new_tier,
            discount_applied=discount_applied,
            extension_days=extension_days,
            message=message
        )

    except HTTPException:
        raise
    except Exception as e:
        await log_user_error(
            user_id=user_id,
            action="retention_offer_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/accept-offer",
            error_message=str(e),
            metadata={"offer_id": request.offer_id}
        )
        raise safe_internal_error(e, "accept_retention_offer")
