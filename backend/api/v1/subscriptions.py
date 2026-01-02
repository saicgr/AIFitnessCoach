"""
Subscription API endpoints.

ENDPOINTS:
- GET  /api/v1/subscriptions/{user_id} - Get user's subscription
- POST /api/v1/subscriptions/{user_id}/check-access - Check feature access
- POST /api/v1/subscriptions/{user_id}/track-usage - Track feature usage
- POST /api/v1/subscriptions/webhook/revenuecat - RevenueCat webhook handler
- POST /api/v1/subscriptions/{user_id}/paywall-impression - Track paywall interaction
- GET  /api/v1/subscriptions/{user_id}/usage-stats - Get feature usage stats
- GET  /api/v1/subscriptions/{user_id}/history - Get subscription change history
- GET  /api/v1/subscriptions/{user_id}/upcoming-renewal - Get upcoming renewal info
- POST /api/v1/subscriptions/{user_id}/request-refund - Submit refund request
- POST /api/v1/subscriptions/{user_id}/pause - Pause subscription
- POST /api/v1/subscriptions/{user_id}/resume - Resume paused subscription
- GET  /api/v1/subscriptions/{user_id}/retention-offers - Get retention offers
- POST /api/v1/subscriptions/{user_id}/accept-offer - Accept retention offer
"""
from datetime import datetime, date, timedelta
from fastapi import APIRouter, HTTPException, Request, Header
from typing import Optional, List
from pydantic import BaseModel
from enum import Enum
import hmac
import hashlib

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.config import get_settings
from core.activity_logger import log_user_activity, log_user_error


class SubscriptionTier(str, Enum):
    free = "free"
    premium = "premium"
    premium_plus = "premium_plus"
    lifetime = "lifetime"


class SubscriptionStatus(str, Enum):
    active = "active"
    canceled = "canceled"
    expired = "expired"
    trial = "trial"
    grace_period = "grace_period"
    paused = "paused"


class SubscriptionResponse(BaseModel):
    """User's current subscription details."""
    user_id: str
    tier: SubscriptionTier
    status: SubscriptionStatus
    is_trial: bool = False
    trial_end_date: Optional[str] = None
    current_period_end: Optional[str] = None
    features: dict = {}


class FeatureAccessRequest(BaseModel):
    """Request to check feature access."""
    feature_key: str


class FeatureAccessResponse(BaseModel):
    """Response for feature access check."""
    feature_key: str
    has_access: bool
    remaining_uses: Optional[int] = None
    limit: Optional[int] = None
    upgrade_required: bool = False
    minimum_tier: Optional[str] = None


class FeatureUsageRequest(BaseModel):
    """Request to track feature usage."""
    feature_key: str
    metadata: Optional[dict] = None


class PaywallImpressionRequest(BaseModel):
    """Request to track paywall interaction."""
    screen: str  # 'features', 'timeline', 'pricing'
    source: Optional[str] = None  # 'onboarding', 'upgrade_prompt', 'settings'
    action: str  # 'viewed', 'dismissed', 'continued', 'purchased', 'restored'
    selected_product: Optional[str] = None
    time_on_screen_ms: Optional[int] = None
    session_id: Optional[str] = None
    device_type: Optional[str] = None
    app_version: Optional[str] = None
    experiment_id: Optional[str] = None
    variant: Optional[str] = None


class UsageStatsResponse(BaseModel):
    """Feature usage statistics for a user."""
    feature_key: str
    today_usage: int
    week_usage: int
    month_usage: int
    limit: Optional[int] = None


router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


def get_user_internal_id(supabase, user_id: str) -> str:
    """Get internal user ID from users table."""
    result = supabase.client.table("users").select("id").eq("id", user_id).single().execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")
    return result.data["id"]


@router.get("/{user_id}", response_model=SubscriptionResponse)
async def get_subscription(user_id: str):
    """Get user's current subscription status."""
    logger.info(f"Fetching subscription for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get subscription from database
        result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not result.data:
            # No subscription record - return free tier
            return SubscriptionResponse(
                user_id=user_id,
                tier=SubscriptionTier.free,
                status=SubscriptionStatus.active,
                is_trial=False,
                features={}
            )

        sub = result.data

        return SubscriptionResponse(
            user_id=user_id,
            tier=SubscriptionTier(sub["tier"]),
            status=SubscriptionStatus(sub["status"]),
            is_trial=sub.get("is_trial", False),
            trial_end_date=sub.get("trial_end_date"),
            current_period_end=sub.get("current_period_end"),
            features=sub.get("features", {})
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get subscription: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/check-access", response_model=FeatureAccessResponse)
async def check_feature_access(user_id: str, request: FeatureAccessRequest):
    """
    Check if user has access to a specific feature.

    This checks:
    1. User's current subscription tier
    2. Feature's minimum required tier
    3. Usage limits for the current period
    """
    logger.info(f"Checking access to '{request.feature_key}' for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get user's subscription
        sub_result = supabase.client.table("user_subscriptions")\
            .select("tier, status, features")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        user_tier = sub_result.data["tier"] if sub_result.data else "free"
        sub_status = sub_result.data["status"] if sub_result.data else "active"

        # Get feature gate config
        gate_result = supabase.client.table("feature_gates")\
            .select("*")\
            .eq("feature_key", request.feature_key)\
            .single()\
            .execute()

        if not gate_result.data:
            # Feature not configured - allow access by default
            return FeatureAccessResponse(
                feature_key=request.feature_key,
                has_access=True,
                upgrade_required=False
            )

        gate = gate_result.data

        # Check if feature is enabled
        if not gate.get("is_enabled", True):
            return FeatureAccessResponse(
                feature_key=request.feature_key,
                has_access=False,
                upgrade_required=False
            )

        # Tier hierarchy: free < premium < premium_plus < lifetime
        tier_levels = {"free": 0, "premium": 1, "premium_plus": 2, "lifetime": 3}
        user_level = tier_levels.get(user_tier, 0)
        required_level = tier_levels.get(gate["minimum_tier"], 0)

        # Check tier access
        if user_level < required_level:
            return FeatureAccessResponse(
                feature_key=request.feature_key,
                has_access=False,
                upgrade_required=True,
                minimum_tier=gate["minimum_tier"]
            )

        # Check usage limits
        limit_key = f"{user_tier}_limit"
        limit = gate.get(limit_key)

        if limit is not None:
            # Get today's usage
            today = date.today().isoformat()
            usage_result = supabase.client.table("feature_usage")\
                .select("usage_count")\
                .eq("user_id", user_id)\
                .eq("feature_key", request.feature_key)\
                .eq("usage_date", today)\
                .single()\
                .execute()

            current_usage = usage_result.data["usage_count"] if usage_result.data else 0

            if current_usage >= limit:
                return FeatureAccessResponse(
                    feature_key=request.feature_key,
                    has_access=False,
                    remaining_uses=0,
                    limit=limit,
                    upgrade_required=True,
                    minimum_tier=_get_next_tier(user_tier)
                )

            return FeatureAccessResponse(
                feature_key=request.feature_key,
                has_access=True,
                remaining_uses=limit - current_usage,
                limit=limit,
                upgrade_required=False
            )

        # No limit - full access
        return FeatureAccessResponse(
            feature_key=request.feature_key,
            has_access=True,
            upgrade_required=False
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to check feature access: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _get_next_tier(current_tier: str) -> str:
    """Get the next tier for upgrade prompt."""
    tiers = ["free", "premium", "premium_plus", "lifetime"]
    try:
        idx = tiers.index(current_tier)
        if idx < len(tiers) - 1:
            return tiers[idx + 1]
    except ValueError:
        pass
    return "premium"


@router.post("/{user_id}/track-usage")
async def track_feature_usage(user_id: str, request: FeatureUsageRequest):
    """
    Track usage of a feature for rate limiting.

    This increments the daily usage counter for the feature.
    """
    logger.info(f"Tracking usage of '{request.feature_key}' for user: {user_id}")

    try:
        supabase = get_supabase()
        today = date.today().isoformat()

        # Try to upsert usage record
        result = supabase.client.rpc(
            "increment_feature_usage",
            {
                "p_user_id": user_id,
                "p_feature_key": request.feature_key,
                "p_usage_date": today,
                "p_metadata": request.metadata or {}
            }
        ).execute()

        return {"status": "tracked", "feature_key": request.feature_key}

    except Exception as e:
        # If the RPC doesn't exist, fall back to manual upsert
        logger.warning(f"RPC not available, using fallback: {e}")

        try:
            # Check if record exists
            existing = supabase.client.table("feature_usage")\
                .select("id, usage_count")\
                .eq("user_id", user_id)\
                .eq("feature_key", request.feature_key)\
                .eq("usage_date", today)\
                .single()\
                .execute()

            if existing.data:
                # Update existing
                supabase.client.table("feature_usage")\
                    .update({"usage_count": existing.data["usage_count"] + 1})\
                    .eq("id", existing.data["id"])\
                    .execute()
            else:
                # Insert new
                supabase.client.table("feature_usage").insert({
                    "user_id": user_id,
                    "feature_key": request.feature_key,
                    "usage_date": today,
                    "usage_count": 1,
                    "metadata": request.metadata or {}
                }).execute()

            return {"status": "tracked", "feature_key": request.feature_key}

        except Exception as e2:
            logger.error(f"Failed to track usage: {e2}")
            raise HTTPException(status_code=500, detail=str(e2))


@router.post("/{user_id}/paywall-impression")
async def track_paywall_impression(user_id: str, request: PaywallImpressionRequest):
    """
    Track user interaction with paywall screens.

    Used for conversion funnel analysis.
    """
    logger.info(f"Tracking paywall impression: user={user_id}, screen={request.screen}, action={request.action}")

    try:
        supabase = get_supabase()

        # Insert impression record
        supabase.client.table("paywall_impressions").insert({
            "user_id": user_id,
            "screen": request.screen,
            "source": request.source,
            "action": request.action,
            "selected_product": request.selected_product,
            "time_on_screen_ms": request.time_on_screen_ms,
            "session_id": request.session_id,
            "device_type": request.device_type,
            "app_version": request.app_version,
            "experiment_id": request.experiment_id,
            "variant": request.variant,
        }).execute()

        # Log paywall interaction for conversion tracking
        await log_user_activity(
            user_id=user_id,
            action="paywall_impression",
            endpoint=f"/api/v1/subscriptions/{user_id}/paywall-impression",
            message=f"Paywall {request.action} on {request.screen}",
            metadata={
                "screen": request.screen,
                "action": request.action,
                "source": request.source,
                "selected_product": request.selected_product,
            },
            status_code=200
        )

        return {"status": "tracked"}

    except Exception as e:
        logger.error(f"Failed to track paywall impression: {e}")
        # Don't fail the request for analytics errors
        return {"status": "error", "message": str(e)}


@router.get("/{user_id}/usage-stats", response_model=List[UsageStatsResponse])
async def get_usage_stats(user_id: str, feature_key: Optional[str] = None):
    """Get feature usage statistics for a user."""
    logger.info(f"Fetching usage stats for user: {user_id}")

    try:
        supabase = get_supabase()
        today = date.today()

        # Build query
        query = supabase.client.table("feature_usage")\
            .select("feature_key, usage_date, usage_count")\
            .eq("user_id", user_id)\
            .gte("usage_date", (today.replace(day=1)).isoformat())

        if feature_key:
            query = query.eq("feature_key", feature_key)

        result = query.execute()

        # Aggregate by feature
        stats = {}
        for row in result.data or []:
            fk = row["feature_key"]
            if fk not in stats:
                stats[fk] = {"today": 0, "week": 0, "month": 0}

            usage_date = datetime.fromisoformat(row["usage_date"]).date()
            count = row["usage_count"]

            # Today
            if usage_date == today:
                stats[fk]["today"] += count

            # This week (last 7 days)
            days_ago = (today - usage_date).days
            if days_ago < 7:
                stats[fk]["week"] += count

            # This month
            stats[fk]["month"] += count

        # Get limits from feature_gates
        gates_result = supabase.client.table("feature_gates")\
            .select("feature_key, free_limit, premium_limit, ultra_limit")\
            .execute()

        limits = {g["feature_key"]: g for g in gates_result.data or []}

        # Get user's tier
        sub_result = supabase.client.table("user_subscriptions")\
            .select("tier")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        user_tier = sub_result.data["tier"] if sub_result.data else "free"

        # Build response
        response = []
        for fk, s in stats.items():
            limit = None
            if fk in limits:
                limit_key = f"{user_tier}_limit"
                limit = limits[fk].get(limit_key)

            response.append(UsageStatsResponse(
                feature_key=fk,
                today_usage=s["today"],
                week_usage=s["week"],
                month_usage=s["month"],
                limit=limit
            ))

        return response

    except Exception as e:
        logger.error(f"Failed to get usage stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== REVENUECAT WEBHOOK ====================


class RevenueCatEvent(BaseModel):
    """RevenueCat webhook event."""
    event: dict
    api_version: str


@router.post("/webhook/revenuecat")
async def revenuecat_webhook(
    request: Request,
    authorization: Optional[str] = Header(None)
):
    """
    Handle RevenueCat webhook events.

    Events handled:
    - INITIAL_PURCHASE: New subscription
    - RENEWAL: Subscription renewed
    - CANCELLATION: User canceled
    - EXPIRATION: Subscription expired
    - PRODUCT_CHANGE: User upgraded/downgraded
    - BILLING_ISSUE: Payment failed
    - SUBSCRIBER_ALIAS: Customer ID updated
    """
    logger.info("Received RevenueCat webhook")

    try:
        # Verify webhook signature
        webhook_secret = getattr(settings, 'revenuecat_webhook_secret', None)
        if webhook_secret and authorization:
            if authorization != f"Bearer {webhook_secret}":
                logger.warning("Invalid webhook authorization")
                raise HTTPException(status_code=401, detail="Invalid authorization")

        body = await request.json()
        event_type = body.get("event", {}).get("type")
        app_user_id = body.get("event", {}).get("app_user_id")

        logger.info(f"RevenueCat event: type={event_type}, user={app_user_id}")

        if not app_user_id:
            logger.warning("No app_user_id in webhook")
            return {"status": "ignored", "reason": "no_user_id"}

        supabase = get_supabase()

        # Map RevenueCat event to our handler
        handlers = {
            "INITIAL_PURCHASE": _handle_initial_purchase,
            "RENEWAL": _handle_renewal,
            "CANCELLATION": _handle_cancellation,
            "EXPIRATION": _handle_expiration,
            "PRODUCT_CHANGE": _handle_product_change,
            "BILLING_ISSUE": _handle_billing_issue,
            "SUBSCRIBER_ALIAS": _handle_subscriber_alias,
        }

        handler = handlers.get(event_type)
        if handler:
            await handler(supabase, body.get("event", {}))
            return {"status": "processed", "event_type": event_type}

        logger.info(f"Unhandled event type: {event_type}")
        return {"status": "ignored", "reason": "unhandled_event_type"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Webhook processing failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def _handle_initial_purchase(supabase, event: dict):
    """Handle new subscription purchase."""
    user_id = event.get("app_user_id")
    product_id = event.get("product_id", "")
    price = event.get("price", 0)
    currency = event.get("currency", "USD")
    store = event.get("store", "")
    transaction_id = event.get("transaction_id", "")
    expiration_at = event.get("expiration_at_ms")

    # Determine tier from product ID
    tier = _product_to_tier(product_id)

    # Check if trial
    is_trial = event.get("is_trial_conversion", False) or "trial" in product_id.lower()

    logger.info(f"Processing initial purchase: user={user_id}, product={product_id}, tier={tier}")

    # Update or create subscription
    sub_data = {
        "user_id": user_id,
        "tier": tier,
        "status": "trial" if is_trial else "active",
        "product_id": product_id,
        "is_trial": is_trial,
        "started_at": datetime.utcnow().isoformat(),
        "current_period_start": datetime.utcnow().isoformat(),
        "current_period_end": datetime.fromtimestamp(expiration_at / 1000).isoformat() if expiration_at else None,
        "price_paid": price,
        "currency": currency,
        "store": store,
        "revenuecat_customer_id": event.get("original_app_user_id"),
    }

    # Upsert subscription
    supabase.client.table("user_subscriptions")\
        .upsert(sub_data, on_conflict="user_id")\
        .execute()

    # Record in history
    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "purchased",
        "new_tier": tier,
        "product_id": product_id,
        "price": price,
        "currency": currency,
        "store": store,
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()

    # Record transaction
    if transaction_id:
        supabase.client.table("payment_transactions").insert({
            "user_id": user_id,
            "transaction_id": transaction_id,
            "original_transaction_id": event.get("original_transaction_id"),
            "product_id": product_id,
            "price": price,
            "currency": currency,
            "store": store,
            "status": "completed",
            "metadata": event
        }).execute()


async def _handle_renewal(supabase, event: dict):
    """Handle subscription renewal."""
    user_id = event.get("app_user_id")
    expiration_at = event.get("expiration_at_ms")

    logger.info(f"Processing renewal for user: {user_id}")

    # Update subscription period
    supabase.client.table("user_subscriptions")\
        .update({
            "status": "active",
            "current_period_start": datetime.utcnow().isoformat(),
            "current_period_end": datetime.fromtimestamp(expiration_at / 1000).isoformat() if expiration_at else None,
        })\
        .eq("user_id", user_id)\
        .execute()

    # Record in history
    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "renewed",
        "product_id": event.get("product_id"),
        "price": event.get("price"),
        "currency": event.get("currency", "USD"),
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()


async def _handle_cancellation(supabase, event: dict):
    """Handle subscription cancellation."""
    user_id = event.get("app_user_id")
    expiration_at = event.get("expiration_at_ms")

    logger.info(f"Processing cancellation for user: {user_id}")

    # Update subscription status
    supabase.client.table("user_subscriptions")\
        .update({
            "status": "canceled",
            "canceled_at": datetime.utcnow().isoformat(),
            "expires_at": datetime.fromtimestamp(expiration_at / 1000).isoformat() if expiration_at else None,
        })\
        .eq("user_id", user_id)\
        .execute()

    # Record in history
    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "canceled",
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()


async def _handle_expiration(supabase, event: dict):
    """Handle subscription expiration."""
    user_id = event.get("app_user_id")

    logger.info(f"Processing expiration for user: {user_id}")

    # Get previous tier
    prev_result = supabase.client.table("user_subscriptions")\
        .select("tier")\
        .eq("user_id", user_id)\
        .single()\
        .execute()

    prev_tier = prev_result.data["tier"] if prev_result.data else None

    # Downgrade to free
    supabase.client.table("user_subscriptions")\
        .update({
            "tier": "free",
            "status": "expired",
            "is_trial": False,
        })\
        .eq("user_id", user_id)\
        .execute()

    # Record in history
    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "expired",
        "previous_tier": prev_tier,
        "new_tier": "free",
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()


async def _handle_product_change(supabase, event: dict):
    """Handle subscription upgrade/downgrade."""
    user_id = event.get("app_user_id")
    new_product_id = event.get("new_product_id", "")
    old_product_id = event.get("old_product_id", "")

    new_tier = _product_to_tier(new_product_id)
    old_tier = _product_to_tier(old_product_id)

    logger.info(f"Processing product change for user: {user_id}, {old_tier} -> {new_tier}")

    # Update subscription
    supabase.client.table("user_subscriptions")\
        .update({
            "tier": new_tier,
            "product_id": new_product_id,
            "status": "active",
        })\
        .eq("user_id", user_id)\
        .execute()

    # Determine event type
    tier_levels = {"free": 0, "premium": 1, "premium_plus": 2, "lifetime": 3}
    event_type = "upgraded" if tier_levels.get(new_tier, 0) > tier_levels.get(old_tier, 0) else "downgraded"

    # Record in history
    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": event_type,
        "previous_tier": old_tier,
        "new_tier": new_tier,
        "product_id": new_product_id,
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()


async def _handle_billing_issue(supabase, event: dict):
    """Handle billing/payment issue."""
    user_id = event.get("app_user_id")

    logger.warning(f"Billing issue for user: {user_id}")

    # Update status to grace period
    supabase.client.table("user_subscriptions")\
        .update({"status": "grace_period"})\
        .eq("user_id", user_id)\
        .execute()

    # Record in history
    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "billing_issue",
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()


async def _handle_subscriber_alias(supabase, event: dict):
    """Handle customer ID alias update."""
    user_id = event.get("app_user_id")
    new_customer_id = event.get("new_customer_id")

    logger.info(f"Updating customer ID alias for user: {user_id}")

    if new_customer_id:
        supabase.client.table("user_subscriptions")\
            .update({"revenuecat_customer_id": new_customer_id})\
            .eq("user_id", user_id)\
            .execute()


def _product_to_tier(product_id: str) -> str:
    """Map RevenueCat product ID to subscription tier."""
    product_id = product_id.lower()

    if "lifetime" in product_id:
        return "lifetime"
    elif "premium_plus" in product_id:
        return "premium_plus"
    elif "premium" in product_id:
        return "premium"
    else:
        return "free"


# ==================== SUBSCRIPTION TRANSPARENCY ENDPOINTS ====================


class RefundStatus(str, Enum):
    """Refund request status."""
    pending = "pending"
    approved = "approved"
    denied = "denied"
    processed = "processed"


class SubscriptionHistoryEvent(BaseModel):
    """A single subscription history event."""
    id: str
    event_type: str
    event_description: str
    created_at: str
    previous_tier: Optional[str] = None
    new_tier: Optional[str] = None
    product_id: Optional[str] = None
    price: Optional[float] = None
    currency: Optional[str] = None
    price_display: Optional[str] = None


class SubscriptionHistoryResponse(BaseModel):
    """User's subscription change history."""
    user_id: str
    events: List[SubscriptionHistoryEvent]
    total_count: int


class UpcomingRenewalResponse(BaseModel):
    """Upcoming subscription renewal details."""
    user_id: str
    tier: str
    status: str
    product_id: Optional[str] = None
    renewal_date: Optional[str] = None
    current_price: Optional[float] = None
    currency: Optional[str] = None
    is_trial: bool = False
    trial_end_date: Optional[str] = None
    will_cancel: bool = False
    cancellation_effective_date: Optional[str] = None
    renewal_status_message: str
    days_until_renewal: int = 0


class RefundRequest(BaseModel):
    """Request to submit a refund."""
    reason: str
    additional_details: Optional[str] = None


class RefundRequestResponse(BaseModel):
    """Response after submitting a refund request."""
    id: str
    tracking_id: str
    status: RefundStatus
    amount: Optional[float] = None
    currency: Optional[str] = None
    created_at: str
    message: str


class RefundRequestDetails(BaseModel):
    """Full details of a refund request."""
    id: str
    tracking_id: str
    reason: str
    additional_details: Optional[str] = None
    status: RefundStatus
    amount: Optional[float] = None
    currency: Optional[str] = None
    created_at: str
    updated_at: str
    processed_at: Optional[str] = None


@router.get("/{user_id}/history", response_model=SubscriptionHistoryResponse)
async def get_subscription_history(
    user_id: str,
    limit: int = 50,
    offset: int = 0
):
    """
    Get user's subscription change history.

    Returns a list of all subscription events including:
    - Initial purchases
    - Renewals
    - Upgrades/Downgrades
    - Cancellations
    - Expirations
    - Refunds
    - Billing issues

    This provides full transparency into all subscription changes.
    """
    logger.info(f"Fetching subscription history for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get total count first
        count_result = supabase.client.table("subscription_history")\
            .select("id", count="exact")\
            .eq("user_id", user_id)\
            .execute()

        total_count = count_result.count if count_result.count else 0

        # Get subscription history with readable format
        # We query the base table and format in Python for better control
        result = supabase.client.table("subscription_history")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)\
            .execute()

        events = []
        for row in result.data or []:
            # Format event description
            event_type = row.get("event_type", "unknown")
            previous_tier = row.get("previous_tier")
            new_tier = row.get("new_tier")

            descriptions = {
                "purchased": f"Subscribed to {new_tier or 'plan'}",
                "renewed": "Subscription renewed",
                "canceled": "Subscription canceled",
                "expired": "Subscription expired",
                "upgraded": f"Upgraded from {previous_tier or 'previous plan'} to {new_tier or 'new plan'}",
                "downgraded": f"Downgraded from {previous_tier or 'previous plan'} to {new_tier or 'new plan'}",
                "trial_started": "Started free trial",
                "trial_converted": "Trial converted to paid subscription",
                "refunded": "Refund processed",
                "billing_issue": "Billing issue detected"
            }
            event_description = descriptions.get(event_type, event_type)

            # Format price display
            price = row.get("price")
            currency = row.get("currency", "USD")
            price_display = f"{currency} {price:.2f}" if price else None

            events.append(SubscriptionHistoryEvent(
                id=row["id"],
                event_type=event_type,
                event_description=event_description,
                created_at=row["created_at"],
                previous_tier=previous_tier,
                new_tier=new_tier,
                product_id=row.get("product_id"),
                price=price,
                currency=currency,
                price_display=price_display
            ))

        # Log this access for audit trail
        await log_user_activity(
            user_id=user_id,
            action="subscription_history_viewed",
            endpoint=f"/api/v1/subscriptions/{user_id}/history",
            message="User viewed subscription history",
            metadata={"events_count": len(events)},
            status_code=200
        )

        return SubscriptionHistoryResponse(
            user_id=user_id,
            events=events,
            total_count=total_count
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get subscription history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/upcoming-renewal", response_model=UpcomingRenewalResponse)
async def get_upcoming_renewal(user_id: str):
    """
    Get upcoming subscription renewal information.

    Returns details about the next renewal including:
    - Renewal date
    - Current price that will be charged
    - Whether subscription will auto-renew or cancel
    - Days until renewal

    This provides transparency about upcoming charges.

    Note: Lifetime members never have upcoming renewals.
    """
    logger.info(f"Fetching upcoming renewal for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get current subscription
        result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not result.data:
            # No subscription - return free tier info
            return UpcomingRenewalResponse(
                user_id=user_id,
                tier="free",
                status="active",
                renewal_status_message="No active subscription - using free tier",
                days_until_renewal=0
            )

        sub = result.data

        # Check if lifetime member - they never have renewals
        is_lifetime = sub.get("is_lifetime", False) or sub.get("tier") == "lifetime"
        if is_lifetime:
            return UpcomingRenewalResponse(
                user_id=user_id,
                tier="lifetime",
                status="active",
                renewal_status_message="Lifetime membership - no renewal needed",
                days_until_renewal=0,
                will_cancel=False,
                is_trial=False
            )

        # Calculate days until renewal
        days_until_renewal = 0
        if sub.get("current_period_end"):
            try:
                period_end = datetime.fromisoformat(sub["current_period_end"].replace("Z", "+00:00"))
                now = datetime.now(period_end.tzinfo) if period_end.tzinfo else datetime.utcnow()
                days_until_renewal = max(0, (period_end - now).days)
            except (ValueError, TypeError):
                pass

        # Determine renewal status message
        is_trial = sub.get("is_trial", False)
        canceled = sub.get("canceled_at") is not None
        status = sub.get("status", "active")

        if is_trial:
            renewal_status_message = "Your trial ends and billing starts"
        elif canceled:
            renewal_status_message = "Subscription will end (canceled)"
        elif status == "grace_period":
            renewal_status_message = "Payment required to continue"
        elif status == "expired":
            renewal_status_message = "Subscription has expired"
        else:
            renewal_status_message = "Subscription will auto-renew"

        return UpcomingRenewalResponse(
            user_id=user_id,
            tier=sub.get("tier", "free"),
            status=status,
            product_id=sub.get("product_id"),
            renewal_date=sub.get("current_period_end"),
            current_price=float(sub["price_paid"]) if sub.get("price_paid") else None,
            currency=sub.get("currency", "USD"),
            is_trial=is_trial,
            trial_end_date=sub.get("trial_end_date"),
            will_cancel=canceled,
            cancellation_effective_date=sub.get("expires_at"),
            renewal_status_message=renewal_status_message,
            days_until_renewal=days_until_renewal
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get upcoming renewal: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/request-refund", response_model=RefundRequestResponse)
async def request_refund(user_id: str, request: RefundRequest):
    """
    Submit a refund request for the user's subscription.

    The request will be logged and a tracking ID returned for follow-up.
    All refund requests are reviewed by the support team.

    This addresses concerns about unwanted tier changes by providing
    a clear path to request refunds.
    """
    logger.info(f"Processing refund request for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get current subscription to include amount info
        sub_result = supabase.client.table("user_subscriptions")\
            .select("id, tier, price_paid, currency, product_id")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        subscription_id = None
        amount = None
        currency = "USD"

        if sub_result.data:
            subscription_id = sub_result.data.get("id")
            amount = sub_result.data.get("price_paid")
            currency = sub_result.data.get("currency", "USD")

        # Create refund request - tracking_id is auto-generated by trigger
        refund_data = {
            "user_id": user_id,
            "subscription_id": subscription_id,
            "reason": request.reason,
            "additional_details": request.additional_details,
            "status": "pending",
            "amount": amount,
            "currency": currency
        }

        result = supabase.client.table("refund_requests")\
            .insert(refund_data)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create refund request")

        refund = result.data[0]

        # Log to subscription history
        supabase.client.table("subscription_history").insert({
            "user_id": user_id,
            "event_type": "refund_requested",
            "product_id": sub_result.data.get("product_id") if sub_result.data else None,
            "price": amount,
            "currency": currency,
            "metadata": {
                "refund_request_id": refund["id"],
                "tracking_id": refund["tracking_id"],
                "reason": request.reason
            }
        }).execute()

        # Log user activity for audit trail
        await log_user_activity(
            user_id=user_id,
            action="refund_requested",
            endpoint=f"/api/v1/subscriptions/{user_id}/request-refund",
            message=f"Refund request submitted: {request.reason[:100]}",
            metadata={
                "tracking_id": refund["tracking_id"],
                "amount": amount,
                "currency": currency
            },
            status_code=200
        )

        logger.info(f"Refund request created with tracking ID: {refund['tracking_id']}")

        return RefundRequestResponse(
            id=refund["id"],
            tracking_id=refund["tracking_id"],
            status=RefundStatus.pending,
            amount=float(amount) if amount else None,
            currency=currency,
            created_at=refund["created_at"],
            message=f"Your refund request has been submitted. Your tracking ID is {refund['tracking_id']}. "
                    f"Our support team will review your request and respond within 2-3 business days."
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create refund request: {e}")
        await log_user_error(
            user_id=user_id,
            action="refund_request_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/request-refund",
            error_message=str(e),
            metadata={"reason": request.reason}
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/refund-requests", response_model=List[RefundRequestDetails])
async def get_refund_requests(user_id: str):
    """
    Get all refund requests for a user.

    Returns the status of all submitted refund requests.
    """
    logger.info(f"Fetching refund requests for user: {user_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("refund_requests")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .execute()

        refunds = []
        for row in result.data or []:
            refunds.append(RefundRequestDetails(
                id=row["id"],
                tracking_id=row["tracking_id"],
                reason=row["reason"],
                additional_details=row.get("additional_details"),
                status=RefundStatus(row["status"]),
                amount=float(row["amount"]) if row.get("amount") else None,
                currency=row.get("currency", "USD"),
                created_at=row["created_at"],
                updated_at=row["updated_at"],
                processed_at=row.get("processed_at")
            ))

        return refunds

    except Exception as e:
        logger.error(f"Failed to get refund requests: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== FREE TRIAL SYSTEM ====================
# 7-day free trial available on ALL plans (monthly, yearly, lifetime intro)


class TrialEligibilityResponse(BaseModel):
    """Response for trial eligibility check."""
    user_id: str
    is_eligible: bool
    reason: Optional[str] = None
    trial_duration_days: int = 7
    available_plans: List[str] = []
    previous_trials: int = 0
    can_extend: bool = False
    extension_reason: Optional[str] = None


class StartTrialRequest(BaseModel):
    """Request to start a free trial."""
    plan_type: str  # monthly, yearly, lifetime_intro
    demo_session_id: Optional[str] = None
    source: Optional[str] = None  # onboarding, paywall, settings


class StartTrialResponse(BaseModel):
    """Response after starting a trial."""
    user_id: str
    tier: str
    status: str
    trial_started: bool
    trial_end_date: str
    trial_plan_type: str
    message: str
    features_unlocked: List[str] = []


class TrialConversionRequest(BaseModel):
    """Request to convert trial to paid subscription."""
    product_id: str
    transaction_id: Optional[str] = None


@router.get("/trial-eligibility/{user_id}", response_model=TrialEligibilityResponse)
async def check_trial_eligibility(user_id: str):
    """
    Check if a user is eligible for a free trial.

    A user is eligible if:
    1. They have never had a trial before
    2. They don't have an active subscription
    3. Their account is not flagged for abuse

    The 7-day free trial is available on ALL plans:
    - Monthly ($9.99/month after trial)
    - Yearly ($59.99/year after trial)
    - Lifetime Intro ($149.99 one-time - trial gives full access preview)

    Returns eligibility status and available trial options.
    """
    logger.info(f"Checking trial eligibility for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get current subscription status
        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        subscription = sub_result.data

        # Check for previous trials
        previous_trials = 0
        if subscription:
            # Count how many times is_trial was true
            history_result = supabase.client.table("subscription_history")\
                .select("id")\
                .eq("user_id", user_id)\
                .in_("event_type", ["trial_started", "purchased"])\
                .execute()

            # Check if any were trials
            trial_history = supabase.client.table("subscription_history")\
                .select("id")\
                .eq("user_id", user_id)\
                .eq("event_type", "trial_started")\
                .execute()

            previous_trials = len(trial_history.data) if trial_history.data else 0

            # Check trial extension eligibility
            extension_result = supabase.client.table("trial_extensions")\
                .select("id")\
                .eq("user_id", user_id)\
                .execute()

            has_had_extension = len(extension_result.data) > 0 if extension_result.data else False

        # Determine eligibility
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
                # Check if they can extend
                if not has_had_extension:
                    can_extend = True
                    extension_reason = "Contact support for a trial extension"
            elif previous_trials > 0:
                is_eligible = False
                reason = "You have already used your free trial"
                # Special cases for re-eligibility
                if previous_trials == 1:
                    # Check if it's been more than 6 months since last trial
                    # (win-back campaign eligibility)
                    can_extend = True
                    extension_reason = "You may be eligible for a special offer. Contact support."

        # Available plans for trial
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
        logger.error(f"Failed to check trial eligibility: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/start-trial/{user_id}", response_model=StartTrialResponse)
async def start_trial(user_id: str, request: StartTrialRequest):
    """
    Start a 7-day free trial for a user.

    The trial provides FULL ACCESS to all premium features:
    - Unlimited workout generation
    - AI coach chat
    - Nutrition tracking
    - Progress analytics
    - Exercise library (1700+ exercises)

    The trial is linked to a specific plan type (monthly, yearly, lifetime)
    so the user knows what they're signing up for.

    No payment required to start - just creates the trial subscription.
    """
    logger.info(f"Starting trial for user: {user_id}, plan: {request.plan_type}")

    try:
        supabase = get_supabase()

        # Validate plan type
        valid_plans = ["monthly", "yearly", "lifetime_intro"]
        if request.plan_type not in valid_plans:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid plan type. Must be one of: {', '.join(valid_plans)}"
            )

        # Check eligibility first
        eligibility = await check_trial_eligibility(user_id)
        if not eligibility.is_eligible:
            raise HTTPException(
                status_code=400,
                detail=eligibility.reason or "You are not eligible for a free trial"
            )

        # Calculate trial end date
        now = datetime.utcnow()
        trial_end = now + timedelta(days=7)

        # Map plan type to tier for trial
        plan_tier_map = {
            "monthly": "premium",
            "yearly": "premium",
            "lifetime_intro": "lifetime",  # Give lifetime preview during trial
        }
        trial_tier = plan_tier_map.get(request.plan_type, "premium")

        # Create or update subscription with trial
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

        # Upsert subscription
        supabase.client.table("user_subscriptions")\
            .upsert(sub_data, on_conflict="user_id")\
            .execute()

        # Record in subscription history
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

        # If there was a demo session, update it
        if request.demo_session_id:
            try:
                supabase.client.table("demo_sessions").update({
                    "converted_to_user_id": user_id,
                    "conversion_trigger": f"trial_started_{request.plan_type}",
                    "ended_at": now.isoformat(),
                }).eq("session_id", request.demo_session_id).execute()
            except Exception as e:
                logger.warning(f"Failed to update demo session: {e}")

        # Log activity
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
        logger.error(f"Failed to start trial: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/convert-trial/{user_id}")
async def convert_trial_to_paid(user_id: str, request: TrialConversionRequest):
    """
    Convert a trial to a paid subscription.

    This is called after successful payment through RevenueCat/App Store/Play Store.
    It updates the subscription status from 'trial' to 'active'.
    """
    logger.info(f"Converting trial to paid for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get current subscription
        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not sub_result.data:
            raise HTTPException(status_code=404, detail="No subscription found")

        subscription = sub_result.data

        if not subscription.get("is_trial"):
            raise HTTPException(
                status_code=400,
                detail="User is not on a trial"
            )

        # Determine tier from product ID
        tier = _product_to_tier(request.product_id)

        # Update subscription
        now = datetime.utcnow()
        supabase.client.table("user_subscriptions")\
            .update({
                "tier": tier,
                "status": "active",
                "is_trial": False,
                "product_id": request.product_id,
                "current_period_start": now.isoformat(),
                # Period end will be set by RevenueCat webhook
            })\
            .eq("user_id", user_id)\
            .execute()

        # Record in history
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

        # Log activity
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
        logger.error(f"Failed to convert trial: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/trial-status/{user_id}")
async def get_trial_status(user_id: str):
    """
    Get detailed trial status for a user.

    Returns:
    - Whether user is on trial
    - Days remaining
    - Trial plan type
    - Conversion options
    """
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

        # Calculate days remaining
        days_remaining = 0
        if subscription.get("trial_end_date"):
            try:
                trial_end = datetime.fromisoformat(
                    subscription["trial_end_date"].replace("Z", "+00:00")
                )
                now = datetime.now(trial_end.tzinfo) if trial_end.tzinfo else datetime.utcnow()
                days_remaining = max(0, (trial_end - now).days)
            except (ValueError, TypeError):
                pass

        # Get pricing for conversion
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
        logger.error(f"Failed to get trial status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== LIFETIME MEMBERSHIP SYSTEM ====================


class LifetimeMemberTier(str, Enum):
    """Lifetime member recognition tiers based on membership duration."""
    veteran = "Veteran"      # 365+ days
    loyal = "Loyal"          # 180+ days
    established = "Established"  # 90+ days
    new = "New"              # < 90 days


class LifetimeStatusResponse(BaseModel):
    """Response for lifetime membership status check."""
    user_id: str
    is_lifetime: bool
    purchase_date: Optional[str] = None
    days_as_member: int = 0
    months_as_member: int = 0
    member_tier: Optional[str] = None
    member_tier_level: int = 0
    features_unlocked: List[str] = []
    estimated_value_received: Optional[float] = None
    value_multiplier: Optional[float] = None
    ai_context: Optional[str] = None
    original_price: Optional[float] = None


class LifetimeMemberBenefitsResponse(BaseModel):
    """Detailed lifetime member benefits."""
    user_id: str
    is_lifetime: bool
    member_tier: str
    purchase_date: str
    days_as_member: int
    features: List[str]
    perks: List[dict]
    estimated_savings: float
    message: str


def is_lifetime_member(supabase, user_id: str) -> bool:
    """
    Check if a user is a lifetime member.

    Args:
        supabase: Supabase client
        user_id: User ID to check

    Returns:
        True if user is a lifetime member, False otherwise
    """
    try:
        result = supabase.client.table("user_subscriptions")\
            .select("is_lifetime, tier")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not result.data:
            return False

        # Check both is_lifetime flag and tier
        return result.data.get("is_lifetime", False) or result.data.get("tier") == "lifetime"

    except Exception as e:
        logger.warning(f"Error checking lifetime status: {e}")
        return False


def get_lifetime_member_tier(days_as_member: int) -> tuple:
    """
    Calculate lifetime member tier based on days of membership.

    Args:
        days_as_member: Number of days since lifetime purchase

    Returns:
        Tuple of (tier_name, tier_level)
    """
    if days_as_member >= 365:
        return ("Veteran", 4)
    elif days_as_member >= 180:
        return ("Loyal", 3)
    elif days_as_member >= 90:
        return ("Established", 2)
    else:
        return ("New", 1)


def calculate_lifetime_value(months_as_member: int, monthly_price: float = 9.99) -> float:
    """
    Calculate estimated value received by lifetime member.

    Args:
        months_as_member: Number of months since purchase
        monthly_price: Assumed monthly subscription cost

    Returns:
        Estimated value in dollars
    """
    return round(months_as_member * monthly_price, 2)


@router.get("/{user_id}/lifetime-status", response_model=LifetimeStatusResponse)
async def get_lifetime_status(user_id: str):
    """
    Check if user is a lifetime member and get their status.

    Returns:
    - is_lifetime: Whether user has lifetime membership
    - purchase_date: When lifetime was purchased
    - member_tier: Recognition tier (Veteran/Loyal/Established/New)
    - features_unlocked: All features available to lifetime members
    - ai_context: Context string for AI personalization

    Lifetime members:
    - Never see renewal reminders
    - Have all features unlocked
    - Never expire
    - Get recognition badges based on membership duration
    """
    logger.info(f"Checking lifetime status for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get subscription details
        result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not result.data:
            return LifetimeStatusResponse(
                user_id=user_id,
                is_lifetime=False,
                features_unlocked=[]
            )

        sub = result.data
        tier = sub.get("tier", "free")
        is_lifetime = sub.get("is_lifetime", False) or tier == "lifetime"

        if not is_lifetime:
            return LifetimeStatusResponse(
                user_id=user_id,
                is_lifetime=False,
                features_unlocked=[]
            )

        # Calculate membership duration
        purchase_date = sub.get("lifetime_purchase_date") or sub.get("started_at") or sub.get("created_at")

        days_as_member = 0
        months_as_member = 0

        if purchase_date:
            try:
                from datetime import datetime
                purchase_dt = datetime.fromisoformat(purchase_date.replace("Z", "+00:00"))
                now = datetime.now(purchase_dt.tzinfo) if purchase_dt.tzinfo else datetime.utcnow()
                delta = now - purchase_dt
                days_as_member = max(0, delta.days)
                months_as_member = max(0, days_as_member // 30)
            except (ValueError, TypeError) as e:
                logger.warning(f"Error parsing purchase date: {e}")

        # Calculate tier
        member_tier, tier_level = get_lifetime_member_tier(days_as_member)

        # Calculate value metrics
        original_price = sub.get("lifetime_original_price") or sub.get("price_paid") or 99.99
        estimated_value = calculate_lifetime_value(months_as_member)
        value_multiplier = round(estimated_value / original_price, 2) if original_price > 0 else 0

        # All features for lifetime members
        features_unlocked = [
            "unlimited_workouts",
            "ai_coach",
            "nutrition_tracking",
            "progress_analytics",
            "exercise_library",
            "custom_workouts",
            "workout_sharing",
            "trainer_mode",
            "priority_support",
            "early_access"
        ]

        # AI context for personalization
        ai_context = None
        if purchase_date:
            try:
                from datetime import datetime
                purchase_dt = datetime.fromisoformat(purchase_date.replace("Z", "+00:00"))
                formatted_date = purchase_dt.strftime("%B %d, %Y")
                ai_context = (
                    f"This user is a valued lifetime member since {formatted_date} "
                    f"({member_tier} tier with {days_as_member} days). "
                    f"Treat them as a long-term committed customer who has invested in their fitness journey. "
                    f"They have full access to all features and should receive premium support."
                )
            except (ValueError, TypeError):
                pass

        return LifetimeStatusResponse(
            user_id=user_id,
            is_lifetime=True,
            purchase_date=purchase_date,
            days_as_member=days_as_member,
            months_as_member=months_as_member,
            member_tier=member_tier,
            member_tier_level=tier_level,
            features_unlocked=features_unlocked,
            estimated_value_received=estimated_value,
            value_multiplier=value_multiplier,
            ai_context=ai_context,
            original_price=float(original_price) if original_price else None
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get lifetime status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/lifetime-benefits", response_model=LifetimeMemberBenefitsResponse)
async def get_lifetime_benefits(user_id: str):
    """
    Get detailed lifetime member benefits and perks.

    Returns comprehensive information about what the lifetime member gets,
    including estimated savings and tier-specific perks.
    """
    logger.info(f"Fetching lifetime benefits for user: {user_id}")

    try:
        # First check lifetime status
        status = await get_lifetime_status(user_id)

        if not status.is_lifetime:
            raise HTTPException(
                status_code=404,
                detail="User is not a lifetime member"
            )

        # Define features
        features = [
            "Unlimited AI-generated workouts",
            "Full exercise library (1700+ exercises)",
            "AI coach chat (unlimited)",
            "Nutrition tracking and meal suggestions",
            "Progress analytics and insights",
            "Custom workout builder",
            "Social workout sharing",
            "Personal trainer mode",
            "Priority support (24h response)",
            "Early access to new features"
        ]

        # Tier-specific perks
        tier_perks = {
            "Veteran": [
                {"name": "Veteran Badge", "description": "Exclusive badge for 1+ year members"},
                {"name": "Feature Voting Priority", "description": "Your feature requests get priority"},
                {"name": "Beta Access", "description": "First access to beta features"},
            ],
            "Loyal": [
                {"name": "Loyal Badge", "description": "Exclusive badge for 6+ month members"},
                {"name": "Beta Access", "description": "Early access to beta features"},
            ],
            "Established": [
                {"name": "Established Badge", "description": "Badge for 3+ month members"},
            ],
            "New": [
                {"name": "New Member Badge", "description": "Welcome to the lifetime family!"},
            ],
        }

        perks = tier_perks.get(status.member_tier, [])

        # Calculate savings
        monthly_price = 9.99
        yearly_price = 79.99
        estimated_savings = status.estimated_value_received - (status.original_price or 99.99)
        estimated_savings = max(0, estimated_savings)

        # Personalized message
        messages = {
            "Veteran": f"Thank you for being with us for over a year! You've saved ${estimated_savings:.2f} with your lifetime membership.",
            "Loyal": f"Welcome to the Loyal tier! After 6 months, you're well on your way to Veteran status.",
            "Established": f"You're now an Established member! Keep going to reach Loyal status at 180 days.",
            "New": f"Welcome to lifetime! Your investment pays off more every month you train with us.",
        }

        return LifetimeMemberBenefitsResponse(
            user_id=user_id,
            is_lifetime=True,
            member_tier=status.member_tier,
            purchase_date=status.purchase_date,
            days_as_member=status.days_as_member,
            features=features,
            perks=perks,
            estimated_savings=round(estimated_savings, 2),
            message=messages.get(status.member_tier, "Thank you for being a lifetime member!")
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get lifetime benefits: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/convert-to-lifetime")
async def convert_to_lifetime(
    user_id: str,
    product_id: str = "lifetime",
    price_paid: float = 99.99,
    promotion_code: Optional[str] = None
):
    """
    Convert a user's subscription to lifetime membership.

    This endpoint is typically called after successful payment verification
    from RevenueCat or direct purchase flow.

    Args:
        user_id: User ID
        product_id: Product ID for the lifetime purchase
        price_paid: Amount paid for lifetime membership
        promotion_code: Optional promotion code used

    Returns:
        Updated subscription status
    """
    logger.info(f"Converting user {user_id} to lifetime membership")

    try:
        supabase = get_supabase()
        now = datetime.utcnow()

        # Get current subscription
        current = supabase.client.table("user_subscriptions")\
            .select("tier, status")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        previous_tier = current.data.get("tier") if current.data else "free"

        # Update to lifetime
        sub_data = {
            "user_id": user_id,
            "tier": "lifetime",
            "status": "active",
            "is_lifetime": True,
            "lifetime_purchase_date": now.isoformat(),
            "lifetime_original_price": price_paid,
            "lifetime_promotion_code": promotion_code,
            "lifetime_member_tier": "New",
            "product_id": product_id,
            "price_paid": price_paid,
            "started_at": now.isoformat(),
            # Lifetime never expires
            "current_period_end": None,
            "expires_at": None,
            "is_trial": False,
        }

        supabase.client.table("user_subscriptions")\
            .upsert(sub_data, on_conflict="user_id")\
            .execute()

        # Record in history
        supabase.client.table("subscription_history").insert({
            "user_id": user_id,
            "event_type": "purchased" if previous_tier == "free" else "upgraded",
            "previous_tier": previous_tier,
            "new_tier": "lifetime",
            "product_id": product_id,
            "price": price_paid,
            "currency": "USD",
            "metadata": {
                "promotion_code": promotion_code,
                "conversion_type": "lifetime",
            }
        }).execute()

        # Cancel any pending billing notifications
        try:
            supabase.client.table("billing_notifications")\
                .update({"status": "cancelled", "updated_at": now.isoformat()})\
                .eq("user_id", user_id)\
                .eq("status", "pending")\
                .execute()
        except Exception as e:
            logger.warning(f"Failed to cancel billing notifications: {e}")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="lifetime_purchased",
            endpoint=f"/api/v1/subscriptions/{user_id}/convert-to-lifetime",
            message=f"User converted to lifetime membership",
            metadata={
                "previous_tier": previous_tier,
                "price_paid": price_paid,
                "promotion_code": promotion_code,
            },
            status_code=200
        )

        logger.info(f"Successfully converted user {user_id} to lifetime membership")

        return {
            "status": "success",
            "user_id": user_id,
            "tier": "lifetime",
            "is_lifetime": True,
            "message": "Welcome to lifetime membership! You now have permanent access to all features."
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to convert to lifetime: {e}")
        await log_user_error(
            user_id=user_id,
            action="lifetime_conversion_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/convert-to-lifetime",
            error_message=str(e),
            metadata={"product_id": product_id, "price_paid": price_paid}
        )
        raise HTTPException(status_code=500, detail=str(e))


# ==================== SUBSCRIPTION PAUSE/RESUME SYSTEM ====================


class PauseSubscriptionRequest(BaseModel):
    """Request to pause a subscription."""
    duration_days: int  # 7, 14, 30, 60, or 90 days
    reason: Optional[str] = None


class PauseSubscriptionResponse(BaseModel):
    """Response after pausing subscription."""
    user_id: str
    status: str
    paused_at: str
    resume_date: str
    duration_days: int
    message: str


class ResumeSubscriptionResponse(BaseModel):
    """Response after resuming subscription."""
    user_id: str
    status: str
    resumed_at: str
    tier: str
    message: str


class RetentionOffer(BaseModel):
    """A retention offer to prevent cancellation."""
    id: str
    type: str  # discount, extension, downgrade, pause
    title: str
    description: str
    value: Optional[str] = None
    discount_percent: Optional[int] = None
    extension_days: Optional[int] = None
    target_tier: Optional[str] = None
    expires_in_hours: int = 24


class RetentionOffersResponse(BaseModel):
    """Available retention offers for a user."""
    user_id: str
    offers: List[RetentionOffer]
    cancellation_reason: Optional[str] = None


class AcceptOfferRequest(BaseModel):
    """Request to accept a retention offer."""
    offer_id: str
    cancellation_reason: Optional[str] = None


class AcceptOfferResponse(BaseModel):
    """Response after accepting a retention offer."""
    user_id: str
    offer_id: str
    offer_type: str
    applied: bool
    new_status: Optional[str] = None
    new_tier: Optional[str] = None
    discount_applied: Optional[int] = None
    extension_days: Optional[int] = None
    message: str


@router.post("/{user_id}/pause", response_model=PauseSubscriptionResponse)
async def pause_subscription(user_id: str, request: PauseSubscriptionRequest):
    """
    Pause a user's subscription for a specified duration.

    Valid durations: 7, 14, 30, 60, or 90 days.

    During pause:
    - Billing is suspended
    - Premium features are disabled
    - User data is preserved
    - Subscription auto-resumes on the resume date

    Note: Lifetime members cannot pause (they have permanent access).
    """
    logger.info(f"Pausing subscription for user: {user_id}, duration: {request.duration_days} days")

    try:
        supabase = get_supabase()

        # Validate duration
        valid_durations = [7, 14, 30, 60, 90]
        if request.duration_days not in valid_durations:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid duration. Must be one of: {', '.join(map(str, valid_durations))} days"
            )

        # Get current subscription
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

        # Lifetime members cannot pause
        if tier == "lifetime" or subscription.get("is_lifetime"):
            raise HTTPException(
                status_code=400,
                detail="Lifetime memberships cannot be paused. You have permanent access!"
            )

        # Free tier cannot pause
        if tier == "free":
            raise HTTPException(
                status_code=400,
                detail="Free accounts cannot be paused. Upgrade to pause your subscription."
            )

        # Already paused
        if status == "paused":
            raise HTTPException(
                status_code=400,
                detail="Subscription is already paused"
            )

        # Calculate dates
        now = datetime.utcnow()
        resume_date = now + timedelta(days=request.duration_days)

        # Update subscription to paused
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

        # Record in subscription_pauses table
        supabase.client.table("subscription_pauses").insert({
            "user_id": user_id,
            "subscription_id": subscription.get("id"),
            "paused_at": now.isoformat(),
            "resume_date": resume_date.isoformat(),
            "duration_days": request.duration_days,
            "reason": request.reason,
            "status": "active",
        }).execute()

        # Record in history
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

        # Log activity
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
        logger.error(f"Failed to pause subscription: {e}")
        await log_user_error(
            user_id=user_id,
            action="subscription_pause_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/pause",
            error_message=str(e),
            metadata={"duration_days": request.duration_days}
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/resume", response_model=ResumeSubscriptionResponse)
async def resume_subscription(user_id: str):
    """
    Resume a paused subscription early.

    This reactivates the subscription immediately and restores access
    to all premium features.

    Note: Billing cycle adjustments are handled by RevenueCat.
    """
    logger.info(f"Resuming subscription for user: {user_id}")

    try:
        supabase = get_supabase()

        # Get current subscription
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

        # Check if actually paused
        if status != "paused":
            raise HTTPException(
                status_code=400,
                detail=f"Subscription is not paused. Current status: {status}"
            )

        now = datetime.utcnow()

        # Update subscription to active
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

        # Update the pause record
        supabase.client.table("subscription_pauses")\
            .update({
                "status": "resumed_early",
                "actual_resume_date": now.isoformat(),
            })\
            .eq("user_id", user_id)\
            .eq("status", "active")\
            .execute()

        # Record in history
        supabase.client.table("subscription_history").insert({
            "user_id": user_id,
            "event_type": "resumed",
            "new_tier": tier,
            "metadata": {
                "resumed_early": True,
                "original_resume_date": subscription.get("pause_resume_date"),
            }
        }).execute()

        # Log activity
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
        logger.error(f"Failed to resume subscription: {e}")
        await log_user_error(
            user_id=user_id,
            action="subscription_resume_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/resume",
            error_message=str(e),
            metadata={}
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/retention-offers", response_model=RetentionOffersResponse)
async def get_retention_offers(user_id: str, reason: Optional[str] = None):
    """
    Get available retention offers to prevent cancellation.

    Returns personalized offers based on:
    - User's subscription history
    - Usage patterns
    - Cancellation reason
    - Previous offers accepted/declined

    Offer types:
    - discount: Percentage off next billing cycle
    - extension: Free days added to subscription
    - downgrade: Move to a lower tier instead of canceling
    - pause: Pause subscription instead of canceling
    """
    logger.info(f"Fetching retention offers for user: {user_id}, reason: {reason}")

    try:
        supabase = get_supabase()

        # Get subscription details
        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not sub_result.data:
            return RetentionOffersResponse(
                user_id=user_id,
                offers=[],
                cancellation_reason=reason
            )

        subscription = sub_result.data
        tier = subscription.get("tier", "free")
        is_lifetime = subscription.get("is_lifetime") or tier == "lifetime"

        # Lifetime members should not see retention offers
        if is_lifetime:
            return RetentionOffersResponse(
                user_id=user_id,
                offers=[],
                cancellation_reason=reason
            )

        # Check for previous retention offers
        prev_offers = supabase.client.table("retention_offers_accepted")\
            .select("offer_type")\
            .eq("user_id", user_id)\
            .execute()

        accepted_types = [o["offer_type"] for o in (prev_offers.data or [])]

        # Build personalized offers based on reason and history
        offers = []

        # Always offer pause first
        if "pause" not in accepted_types:
            offers.append(RetentionOffer(
                id=f"pause_{user_id}_{datetime.utcnow().timestamp()}",
                type="pause",
                title="Take a Break",
                description="Pause your subscription for up to 3 months. Your data stays safe, and billing stops.",
                value="Free",
                expires_in_hours=48
            ))

        # Discount offer based on reason
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

        # Extension offer for high-value users
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

        # Downgrade offer if on Premium Plus
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

        return RetentionOffersResponse(
            user_id=user_id,
            offers=offers,
            cancellation_reason=reason
        )

    except Exception as e:
        logger.error(f"Failed to get retention offers: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/accept-offer", response_model=AcceptOfferResponse)
async def accept_retention_offer(user_id: str, request: AcceptOfferRequest):
    """
    Accept a retention offer.

    This applies the offer to the user's subscription:
    - discount: Applies discount to next billing cycle
    - extension: Adds free days to subscription
    - downgrade: Changes tier immediately
    - pause: Pauses subscription (redirects to pause endpoint)

    Records the acceptance for analytics and prevents double-use.
    """
    logger.info(f"Accepting retention offer for user: {user_id}, offer: {request.offer_id}")

    try:
        supabase = get_supabase()

        # Parse offer ID to get type and validate
        offer_parts = request.offer_id.split("_")
        if len(offer_parts) < 2:
            raise HTTPException(status_code=400, detail="Invalid offer ID format")

        offer_type = offer_parts[0]

        # Get subscription
        sub_result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not sub_result.data:
            raise HTTPException(status_code=404, detail="No subscription found")

        subscription = sub_result.data
        now = datetime.utcnow()

        # Apply offer based on type
        new_status = subscription.get("status")
        new_tier = subscription.get("tier")
        discount_applied = None
        extension_days = None
        message = ""

        if offer_type == "discount":
            # Extract discount percentage from offer ID
            try:
                discount_applied = int(offer_parts[1])
            except (ValueError, IndexError):
                discount_applied = 25  # Default

            # Record discount for next billing
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
            # Extract extension days
            try:
                extension_days = int(offer_parts[1])
            except (ValueError, IndexError):
                extension_days = 7  # Default

            # Extend current period
            current_end = subscription.get("current_period_end")
            if current_end:
                try:
                    end_date = datetime.fromisoformat(current_end.replace("Z", "+00:00"))
                    new_end = end_date + timedelta(days=extension_days)
                    supabase.client.table("user_subscriptions")\
                        .update({"current_period_end": new_end.isoformat()})\
                        .eq("user_id", user_id)\
                        .execute()
                except (ValueError, TypeError):
                    pass

            message = f"{extension_days} free days have been added to your subscription."

        elif offer_type == "downgrade":
            # Extract target tier
            target_tier = "premium" if len(offer_parts) < 2 else offer_parts[1]
            new_tier = target_tier

            supabase.client.table("user_subscriptions")\
                .update({"tier": target_tier})\
                .eq("user_id", user_id)\
                .execute()

            message = f"Your subscription has been changed to {target_tier.title()}."

        elif offer_type == "pause":
            # Redirect to pause - return info to client
            message = "Please use the pause subscription option to complete this action."

        else:
            raise HTTPException(status_code=400, detail=f"Unknown offer type: {offer_type}")

        # Record offer acceptance
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

        # Record in subscription history
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

        # Log activity
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
        logger.error(f"Failed to accept retention offer: {e}")
        await log_user_error(
            user_id=user_id,
            action="retention_offer_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/accept-offer",
            error_message=str(e),
            metadata={"offer_id": request.offer_id}
        )
        raise HTTPException(status_code=500, detail=str(e))
