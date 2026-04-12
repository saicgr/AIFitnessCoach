"""
RevenueCat webhook handler and event processing.
"""
from datetime import datetime
from fastapi import APIRouter, BackgroundTasks, HTTPException, Request, Header
from typing import Optional
import hmac
import logging

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.config import get_settings
from core.exceptions import safe_internal_error
from services.email_service import get_email_service
from services.discord_webhooks import notify_subscription

from api.v1.subscriptions.models import _product_to_tier

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


@router.post("/webhook/revenuecat")
async def revenuecat_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
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
        if not webhook_secret:
            raise HTTPException(status_code=503, detail="Webhook not configured")
        if not authorization or not hmac.compare_digest(authorization, f"Bearer {webhook_secret}"):
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
            await handler(supabase, body.get("event", {}), background_tasks)
            return {"status": "processed", "event_type": event_type}

        logger.info(f"Unhandled event type: {event_type}")
        return {"status": "ignored", "reason": "unhandled_event_type"}

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "revenuecat_webhook")


async def _handle_initial_purchase(supabase, event: dict, background_tasks=None):
    """Handle new subscription purchase."""
    user_id = event.get("app_user_id")
    product_id = event.get("product_id", "")
    price = event.get("price", 0)
    currency = event.get("currency", "USD")
    store = event.get("store", "")
    transaction_id = event.get("transaction_id", "")
    expiration_at = event.get("expiration_at_ms")

    tier = _product_to_tier(product_id)
    is_trial = event.get("is_trial_conversion", False) or "trial" in product_id.lower()

    logger.info(f"Processing initial purchase: user={user_id}, product={product_id}, tier={tier}")

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

    supabase.client.table("user_subscriptions")\
        .upsert(sub_data, on_conflict="user_id")\
        .execute()

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

    if background_tasks:
        try:
            user_result = supabase.client.table("users") \
                .select("email, name") \
                .eq("id", user_id) \
                .single() \
                .execute()
            if user_result.data:
                user_email = user_result.data["email"]
                user_name = user_result.data.get("name", "")

                # Purchase confirmation email (skip for trials)
                if not is_trial:
                    background_tasks.add_task(
                        get_email_service().send_purchase_confirmation,
                        user_email,
                        user_name,
                        tier,
                        price,
                        currency,
                    )

                # Discord notification for all purchases (trial and paid)
                background_tasks.add_task(
                    notify_subscription,
                    email=user_email,
                    user_id=user_id,
                    plan=product_id,
                    price=price,
                    currency=currency,
                    is_trial=is_trial,
                    store=store,
                    name=user_name,
                )
        except Exception as notify_err:
            logger.error(f"❌ Failed to queue purchase notifications: {notify_err}", exc_info=True)


async def _handle_renewal(supabase, event: dict, background_tasks=None):
    """Handle subscription renewal."""
    user_id = event.get("app_user_id")
    expiration_at = event.get("expiration_at_ms")

    logger.info(f"Processing renewal for user: {user_id}")

    supabase.client.table("user_subscriptions")\
        .update({
            "status": "active",
            "current_period_start": datetime.utcnow().isoformat(),
            "current_period_end": datetime.fromtimestamp(expiration_at / 1000).isoformat() if expiration_at else None,
        })\
        .eq("user_id", user_id)\
        .execute()

    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "renewed",
        "product_id": event.get("product_id"),
        "price": event.get("price"),
        "currency": event.get("currency", "USD"),
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()


async def _handle_cancellation(supabase, event: dict, background_tasks=None):
    """Handle subscription cancellation."""
    user_id = event.get("app_user_id")
    expiration_at = event.get("expiration_at_ms")

    logger.info(f"Processing cancellation for user: {user_id}")

    supabase.client.table("user_subscriptions")\
        .update({
            "status": "canceled",
            "canceled_at": datetime.utcnow().isoformat(),
            "expires_at": datetime.fromtimestamp(expiration_at / 1000).isoformat() if expiration_at else None,
        })\
        .eq("user_id", user_id)\
        .execute()

    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "canceled",
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()

    if background_tasks:
        try:
            user_result = supabase.client.table("users") \
                .select("email, name") \
                .eq("id", user_id) \
                .single() \
                .execute()
            sub_result = supabase.client.table("user_subscriptions") \
                .select("tier") \
                .eq("user_id", user_id) \
                .single() \
                .execute()
            pref_result = supabase.client.table("email_preferences") \
                .select("promotional") \
                .eq("user_id", user_id) \
                .single() \
                .execute()
            promotional_ok = True
            if pref_result.data and pref_result.data.get("promotional") is False:
                promotional_ok = False
            if user_result.data and promotional_ok:
                tier_name = sub_result.data.get("tier", "premium") if sub_result.data else "premium"
                workout_count_result = supabase.client.table("workout_logs") \
                    .select("id") \
                    .eq("user_id", user_id) \
                    .execute()
                workout_count = len(workout_count_result.data or [])
                background_tasks.add_task(
                    get_email_service().send_cancellation_retention,
                    user_result.data["email"],
                    user_result.data.get("name", ""),
                    tier_name,
                    workout_count,
                    0.0,  # total_volume_kg simplified
                    0,    # current_streak simplified
                )
        except Exception as email_err:
            logger.error(f"❌ Failed to queue cancellation retention email: {email_err}", exc_info=True)


async def _handle_expiration(supabase, event: dict, background_tasks=None):
    """Handle subscription expiration."""
    user_id = event.get("app_user_id")

    logger.info(f"Processing expiration for user: {user_id}")

    prev_result = supabase.client.table("user_subscriptions")\
        .select("tier")\
        .eq("user_id", user_id)\
        .single()\
        .execute()

    prev_tier = prev_result.data["tier"] if prev_result.data else None

    supabase.client.table("user_subscriptions")\
        .update({
            "tier": "free",
            "status": "expired",
            "is_trial": False,
        })\
        .eq("user_id", user_id)\
        .execute()

    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "expired",
        "previous_tier": prev_tier,
        "new_tier": "free",
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()

    is_trial = event.get("is_trial_period", False)
    if is_trial and background_tasks:
        try:
            user_result = supabase.client.table("users") \
                .select("email, name") \
                .eq("id", user_id) \
                .single() \
                .execute()
            if user_result.data:
                workout_count_result = supabase.client.table("workout_logs") \
                    .select("id") \
                    .eq("user_id", user_id) \
                    .execute()
                workout_count = len(workout_count_result.data or [])
                background_tasks.add_task(
                    get_email_service().send_trial_expired,
                    user_result.data["email"],
                    user_result.data.get("name", ""),
                    workout_count,
                )
        except Exception as email_err:
            logger.error(f"❌ Failed to queue trial expired email: {email_err}", exc_info=True)


async def _handle_product_change(supabase, event: dict, background_tasks=None):
    """Handle subscription upgrade/downgrade."""
    user_id = event.get("app_user_id")
    new_product_id = event.get("new_product_id", "")
    old_product_id = event.get("old_product_id", "")

    new_tier = _product_to_tier(new_product_id)
    old_tier = _product_to_tier(old_product_id)

    logger.info(f"Processing product change for user: {user_id}, {old_tier} -> {new_tier}")

    supabase.client.table("user_subscriptions")\
        .update({
            "tier": new_tier,
            "product_id": new_product_id,
            "status": "active",
        })\
        .eq("user_id", user_id)\
        .execute()

    tier_levels = {"free": 0, "premium": 1, "premium_plus": 2, "lifetime": 3}
    event_type = "upgraded" if tier_levels.get(new_tier, 0) > tier_levels.get(old_tier, 0) else "downgraded"

    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": event_type,
        "previous_tier": old_tier,
        "new_tier": new_tier,
        "product_id": new_product_id,
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()


async def _handle_billing_issue(supabase, event: dict, background_tasks=None):
    """Handle billing/payment issue."""
    user_id = event.get("app_user_id")

    logger.warning(f"Billing issue for user: {user_id}")

    supabase.client.table("user_subscriptions")\
        .update({"status": "grace_period"})\
        .eq("user_id", user_id)\
        .execute()

    supabase.client.table("subscription_history").insert({
        "user_id": user_id,
        "event_type": "billing_issue",
        "revenuecat_event_id": event.get("id"),
        "metadata": event
    }).execute()

    if background_tasks:
        try:
            user_result = supabase.client.table("users") \
                .select("email, name") \
                .eq("id", user_id) \
                .single() \
                .execute()
            sub_result = supabase.client.table("user_subscriptions") \
                .select("tier") \
                .eq("user_id", user_id) \
                .single() \
                .execute()
            if user_result.data:
                tier_name = sub_result.data.get("tier", "premium") if sub_result.data else "premium"
                background_tasks.add_task(
                    get_email_service().send_billing_issue,
                    user_result.data["email"],
                    user_result.data.get("name", ""),
                    tier_name,
                )
        except Exception as email_err:
            logger.error(f"❌ Failed to queue billing issue email: {email_err}", exc_info=True)


async def _handle_subscriber_alias(supabase, event: dict, background_tasks=None):
    """Handle customer ID alias update."""
    user_id = event.get("app_user_id")
    new_customer_id = event.get("new_customer_id")

    logger.info(f"Updating customer ID alias for user: {user_id}")

    if new_customer_id:
        supabase.client.table("user_subscriptions")\
            .update({"revenuecat_customer_id": new_customer_id})\
            .eq("user_id", user_id)\
            .execute()
