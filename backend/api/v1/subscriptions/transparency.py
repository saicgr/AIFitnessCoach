"""
Subscription transparency endpoints: history, upcoming renewal, refund requests.
"""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from typing import Optional, List

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from api.v1.subscriptions.models import (
    SubscriptionHistoryEvent,
    SubscriptionHistoryResponse,
    UpcomingRenewalResponse,
    RefundRequest,
    RefundRequestResponse,
    RefundRequestDetails,
    RefundStatus,
)

router = APIRouter()
logger = get_logger(__name__)


@router.get("/{user_id}/history", response_model=SubscriptionHistoryResponse)
async def get_subscription_history(
    user_id: str,
    current_user: dict = Depends(get_current_user),
    limit: int = 50,
    offset: int = 0,
):
    """Get user's subscription change history."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching subscription history for user: {user_id}")

    try:
        supabase = get_supabase()

        count_result = supabase.client.table("subscription_history")\
            .select("id", count="exact")\
            .eq("user_id", user_id)\
            .execute()

        total_count = count_result.count if count_result.count else 0

        result = supabase.client.table("subscription_history")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)\
            .execute()

        events = []
        for row in result.data or []:
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
        raise safe_internal_error(e, "get_subscription_history")


@router.get("/{user_id}/upcoming-renewal", response_model=UpcomingRenewalResponse)
async def get_upcoming_renewal(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get upcoming subscription renewal information."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching upcoming renewal for user: {user_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("user_subscriptions")\
            .select("*")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not result.data:
            return UpcomingRenewalResponse(
                user_id=user_id,
                tier="free",
                status="active",
                renewal_status_message="No active subscription - using free tier",
                days_until_renewal=0
            )

        sub = result.data

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

        days_until_renewal = 0
        if sub.get("current_period_end"):
            try:
                period_end = datetime.fromisoformat(sub["current_period_end"].replace("Z", "+00:00"))
                now = datetime.now(period_end.tzinfo) if period_end.tzinfo else datetime.utcnow()
                days_until_renewal = max(0, (period_end - now).days)
            except (ValueError, TypeError) as e:
                logger.debug(f"Failed to parse renewal date: {e}")

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
        raise safe_internal_error(e, "get_upcoming_renewal")


@router.post("/{user_id}/request-refund", response_model=RefundRequestResponse)
async def request_refund(user_id: str, request: RefundRequest, current_user: dict = Depends(get_current_user)):
    """Submit a refund request for the user's subscription."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Processing refund request for user: {user_id}")

    try:
        supabase = get_supabase()

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
        await log_user_error(
            user_id=user_id,
            action="refund_request_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/request-refund",
            error_message=str(e),
            metadata={"reason": request.reason}
        )
        raise safe_internal_error(e, "request_refund")


@router.get("/{user_id}/refund-requests", response_model=List[RefundRequestDetails])
async def get_refund_requests(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get all refund requests for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        raise safe_internal_error(e, "get_refund_requests")
