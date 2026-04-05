"""
Subscription management: get subscription, check access, track usage, feature limits, paywall.
"""
from datetime import datetime, date, timedelta
from fastapi import APIRouter, Depends, HTTPException
from typing import Optional, List

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.config import get_settings
from core.activity_logger import log_user_activity
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from api.v1.subscriptions.models import (
    SubscriptionTier,
    SubscriptionStatus,
    SubscriptionResponse,
    FeatureAccessRequest,
    FeatureAccessResponse,
    FeatureUsageRequest,
    PaywallImpressionRequest,
    UsageStatsResponse,
    _get_next_tier,
)

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
async def get_subscription(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get user's current subscription status."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        raise safe_internal_error(e, "get_subscription")


@router.post("/{user_id}/check-access", response_model=FeatureAccessResponse)
async def check_feature_access(user_id: str, request: FeatureAccessRequest, current_user: dict = Depends(get_current_user)):
    """
    Check if user has access to a specific feature.

    This checks:
    1. User's current subscription tier
    2. Feature's minimum required tier
    3. Usage limits for the current period
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        raise safe_internal_error(e, "check_feature_access")


@router.post("/{user_id}/track-usage")
async def track_feature_usage(user_id: str, request: FeatureUsageRequest, current_user: dict = Depends(get_current_user)):
    """
    Track usage of a feature for rate limiting.

    This increments the daily usage counter for the feature.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
            raise safe_internal_error(e2, "track_feature_usage")


@router.post("/{user_id}/paywall-impression")
async def track_paywall_impression(user_id: str, request: PaywallImpressionRequest, current_user: dict = Depends(get_current_user)):
    """Track user interaction with paywall screens. Used for conversion funnel analysis."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def get_usage_stats(user_id: str, feature_key: Optional[str] = None, current_user: dict = Depends(get_current_user)):
    """Get feature usage statistics for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        raise safe_internal_error(e, "get_usage_stats")


# ==================== BULK FEATURE LIMITS ====================

# The 5 AI feature keys we expose in the bulk endpoint
_PREMIUM_FEATURE_KEYS = [
    "ai_workout_generation",
    "food_scanning",
    "form_video_analysis",
    "text_to_calories",
    "ai_meal_plan",
    "ai_chat_messages",
]


@router.get("/{user_id}/feature-limits")
async def get_feature_limits(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Return all 5 AI feature gates with current usage computed.

    For premium users every limit is null (unlimited).
    For free users, remaining counts are calculated based on reset_period:
      - 'daily'   -> usage today
      - 'monthly' -> usage this calendar month
      - null       -> feature locked (free_limit = 0 means premium-only)
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    try:
        supabase = get_supabase()

        # 1. Get user tier
        try:
            sub_result = supabase.client.table("user_subscriptions")\
                .select("tier")\
                .eq("user_id", user_id)\
                .single()\
                .execute()
            user_tier = sub_result.data["tier"] if sub_result.data else "free"
        except Exception as e:
            logger.warning(f"Failed to fetch user tier: {e}")
            user_tier = "free"

        is_premium = user_tier in ("premium", "premium_plus")

        # 2. Fetch all 5 gates in one query
        gates_result = supabase.client.table("feature_gates")\
            .select("feature_key, display_name, free_limit, reset_period, minimum_tier, is_enabled")\
            .in_("feature_key", _PREMIUM_FEATURE_KEYS)\
            .execute()

        gates_by_key = {g["feature_key"]: g for g in (gates_result.data or [])}

        # 3. Fetch all usage records for this user for relevant feature keys this month
        today = date.today()
        first_of_month = today.replace(day=1).isoformat()
        usage_result = supabase.client.table("feature_usage")\
            .select("feature_key, usage_date, usage_count")\
            .eq("user_id", user_id)\
            .in_("feature_key", _PREMIUM_FEATURE_KEYS)\
            .gte("usage_date", first_of_month)\
            .execute()

        # 4. Compute usage per feature based on reset_period
        usage_rows = {}
        for row in (usage_result.data or []):
            usage_rows.setdefault(row["feature_key"], []).append(row)

        limits = {}
        for fk in _PREMIUM_FEATURE_KEYS:
            gate = gates_by_key.get(fk)
            if not gate:
                limits[fk] = {"limit": None, "used": 0, "remaining": None, "reset_period": None, "resets_at": None}
                continue

            if is_premium:
                limits[fk] = {"limit": None, "used": 0, "remaining": None, "reset_period": gate.get("reset_period"), "resets_at": None}
                continue

            free_limit = gate.get("free_limit")
            reset_period = gate.get("reset_period")

            # Compute used count
            used = 0
            rows = usage_rows.get(fk, [])
            if reset_period == "daily":
                today_str = today.isoformat()
                used = sum(r["usage_count"] for r in rows if r["usage_date"] == today_str)
            elif reset_period == "monthly":
                used = sum(r["usage_count"] for r in rows)

            remaining = max(0, free_limit - used) if free_limit is not None else None

            # Compute resets_at
            resets_at = None
            if reset_period == "daily":
                tomorrow = today + timedelta(days=1)
                resets_at = datetime(tomorrow.year, tomorrow.month, tomorrow.day).isoformat() + "Z"
            elif reset_period == "monthly":
                if today.month == 12:
                    next_month = datetime(today.year + 1, 1, 1)
                else:
                    next_month = datetime(today.year, today.month + 1, 1)
                resets_at = next_month.isoformat() + "Z"

            limits[fk] = {
                "limit": free_limit,
                "used": used,
                "remaining": remaining,
                "reset_period": reset_period,
                "resets_at": resets_at,
            }

        return {"limits": limits, "is_premium": is_premium}

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "get_feature_limits")
