"""
Lifetime membership endpoints: status, benefits, conversion.
"""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from typing import Optional

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from api.v1.subscriptions.models import (
    LifetimeStatusResponse,
    LifetimeMemberBenefitsResponse,
    get_lifetime_member_tier,
    calculate_lifetime_value,
)

router = APIRouter()
logger = get_logger(__name__)


@router.get("/{user_id}/lifetime-status", response_model=LifetimeStatusResponse)
async def get_lifetime_status(user_id: str, current_user: dict = Depends(get_current_user)):
    """Check if user is a lifetime member and get their status."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Checking lifetime status for user: {user_id}")

    try:
        supabase = get_supabase()

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

        purchase_date = sub.get("lifetime_purchase_date") or sub.get("started_at") or sub.get("created_at")

        days_as_member = 0
        months_as_member = 0

        if purchase_date:
            try:
                purchase_dt = datetime.fromisoformat(purchase_date.replace("Z", "+00:00"))
                now = datetime.now(purchase_dt.tzinfo) if purchase_dt.tzinfo else datetime.utcnow()
                delta = now - purchase_dt
                days_as_member = max(0, delta.days)
                months_as_member = max(0, days_as_member // 30)
            except (ValueError, TypeError) as e:
                logger.warning(f"Error parsing purchase date: {e}")

        member_tier, tier_level = get_lifetime_member_tier(days_as_member)

        original_price = sub.get("lifetime_original_price") or sub.get("price_paid") or 99.99
        estimated_value = calculate_lifetime_value(months_as_member)
        value_multiplier = round(estimated_value / original_price, 2) if original_price > 0 else 0

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

        ai_context = None
        if purchase_date:
            try:
                purchase_dt = datetime.fromisoformat(purchase_date.replace("Z", "+00:00"))
                formatted_date = purchase_dt.strftime("%B %d, %Y")
                ai_context = (
                    f"This user is a valued lifetime member since {formatted_date} "
                    f"({member_tier} tier with {days_as_member} days). "
                    f"Treat them as a long-term committed customer who has invested in their fitness journey. "
                    f"They have full access to all features and should receive premium support."
                )
            except (ValueError, TypeError) as e:
                logger.debug(f"Failed to format lifetime date: {e}")

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
        raise safe_internal_error(e, "get_lifetime_status")


@router.get("/{user_id}/lifetime-benefits", response_model=LifetimeMemberBenefitsResponse)
async def get_lifetime_benefits(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get detailed lifetime member benefits and perks."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching lifetime benefits for user: {user_id}")

    try:
        status = await get_lifetime_status(user_id)

        if not status.is_lifetime:
            raise HTTPException(status_code=404, detail="User is not a lifetime member")

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

        estimated_savings = status.estimated_value_received - (status.original_price or 99.99)
        estimated_savings = max(0, estimated_savings)

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
        raise safe_internal_error(e, "get_lifetime_benefits")


@router.post("/{user_id}/convert-to-lifetime")
async def convert_to_lifetime(
    user_id: str,
    product_id: str = "lifetime",
    price_paid: float = 99.99,
    promotion_code: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """Convert a user's subscription to lifetime membership."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Converting user {user_id} to lifetime membership")

    try:
        supabase = get_supabase()
        now = datetime.utcnow()

        current = supabase.client.table("user_subscriptions")\
            .select("tier, status")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        previous_tier = current.data.get("tier") if current.data else "free"

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
            "current_period_end": None,
            "expires_at": None,
            "is_trial": False,
        }

        supabase.client.table("user_subscriptions")\
            .upsert(sub_data, on_conflict="user_id")\
            .execute()

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

        try:
            supabase.client.table("billing_notifications")\
                .update({"status": "cancelled", "updated_at": now.isoformat()})\
                .eq("user_id", user_id)\
                .eq("status", "pending")\
                .execute()
        except Exception as e:
            logger.warning(f"Failed to cancel billing notifications: {e}")

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
        await log_user_error(
            user_id=user_id,
            action="lifetime_conversion_failed",
            endpoint=f"/api/v1/subscriptions/{user_id}/convert-to-lifetime",
            error_message=str(e),
            metadata={"product_id": product_id, "price_paid": price_paid}
        )
        raise safe_internal_error(e, "convert_to_lifetime")
