"""
Subscription API endpoints.

ENDPOINTS:
- GET  /api/v1/subscriptions/{user_id} - Get user's subscription
- POST /api/v1/subscriptions/{user_id}/check-access - Check feature access
- POST /api/v1/subscriptions/{user_id}/track-usage - Track feature usage
- POST /api/v1/subscriptions/webhook/revenuecat - RevenueCat webhook handler
- POST /api/v1/subscriptions/{user_id}/paywall-impression - Track paywall interaction
- GET  /api/v1/subscriptions/{user_id}/usage-stats - Get feature usage stats
"""
from datetime import datetime, date
from fastapi import APIRouter, HTTPException, Request, Header
from typing import Optional, List
from pydantic import BaseModel
from enum import Enum
import hmac
import hashlib

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.config import get_settings


class SubscriptionTier(str, Enum):
    free = "free"
    premium = "premium"
    ultra = "ultra"
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

        # Tier hierarchy: free < premium < ultra < lifetime
        tier_levels = {"free": 0, "premium": 1, "ultra": 2, "lifetime": 3}
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
    tiers = ["free", "premium", "ultra", "lifetime"]
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
    tier_levels = {"free": 0, "premium": 1, "ultra": 2, "lifetime": 3}
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
    elif "ultra" in product_id:
        return "ultra"
    elif "premium" in product_id:
        return "premium"
    else:
        return "free"
