"""
Shared premium feature gate checking and usage tracking.

Provides `check_premium_gate()` for backend endpoints to enforce
free-tier limits on AI features. Premium/premium_plus users
get unlimited access.
"""
import os
from datetime import date, datetime
from typing import Optional, Tuple
from fastapi import HTTPException

from core.supabase_client import get_supabase
from core.logger import get_logger

logger = get_logger(__name__)

_is_production = os.getenv("RENDER", "false").lower() == "true" or os.getenv("ENV", "dev") == "production"

# Feature keys that this module manages
PREMIUM_FEATURE_KEYS = [
    "ai_chat",
    "ai_workout_generation",
    "food_scanning",
    "form_video_analysis",
    "text_to_calories",
]


async def check_premium_gate(user_id: str, feature_key: str) -> Tuple[bool, Optional[int]]:
    """
    Check if a user has access to a premium-gated feature.

    Returns:
        (has_access, remaining) - remaining is None for unlimited (premium users).

    Raises:
        HTTPException(402) if user has exhausted their free-tier limit.
    """
    # Dev environment: skip all gates for full access
    if not _is_production:
        return True, None

    supabase = get_supabase()

    # Get user's subscription tier
    try:
        sub_result = supabase.client.table("user_subscriptions")\
            .select("tier, status")\
            .eq("user_id", user_id)\
            .single()\
            .execute()
        user_tier = sub_result.data["tier"] if sub_result.data else "free"
    except Exception:
        user_tier = "free"

    # Premium/premium_plus users get unlimited access
    if user_tier in ("premium", "premium_plus"):
        return True, None

    # Get the feature gate config
    try:
        gate_result = supabase.client.table("feature_gates")\
            .select("free_limit, reset_period, minimum_tier, is_enabled")\
            .eq("feature_key", feature_key)\
            .single()\
            .execute()
    except Exception:
        # Gate not found — apply conservative defaults for known features
        if feature_key in PREMIUM_FEATURE_KEYS:
            logger.warning(f"Feature gate '{feature_key}' not found in DB, applying fallback limits", exc_info=True)
            gate_result = type('obj', (object,), {'data': _get_fallback_gate(feature_key)})()
        else:
            logger.warning(f"Unknown feature gate '{feature_key}', allowing access", exc_info=True)
            return True, None

    if not gate_result.data:
        return True, None

    gate = gate_result.data

    if not gate.get("is_enabled", True):
        raise HTTPException(
            status_code=402,
            detail={
                "detail": f"{feature_key} is currently disabled",
                "feature": feature_key,
                "upgrade_required": False,
            }
        )

    # Tier check - if minimum_tier is 'premium', free users can't access at all
    tier_levels = {"free": 0, "premium": 1, "premium_plus": 2}
    if tier_levels.get(user_tier, 0) < tier_levels.get(gate["minimum_tier"], 0):
        raise HTTPException(
            status_code=402,
            detail={
                "detail": f"{feature_key} requires a premium subscription",
                "feature": feature_key,
                "upgrade_required": True,
            }
        )

    free_limit = gate.get("free_limit")
    if free_limit is None:
        # No limit configured - allow
        return True, None

    # Compute current usage based on reset_period
    reset_period = gate.get("reset_period")
    current_usage = _get_current_usage(supabase, user_id, feature_key, reset_period)

    remaining = max(0, free_limit - current_usage)
    if current_usage >= free_limit:
        raise HTTPException(
            status_code=402,
            detail={
                "detail": f"{feature_key} limit reached",
                "feature": feature_key,
                "upgrade_required": True,
                "limit": free_limit,
                "used": current_usage,
            }
        )

    return True, remaining


def _get_fallback_gate(feature_key: str) -> dict:
    """Hardcoded fallback limits when the feature_gates table is missing rows."""
    fallbacks = {
        "ai_chat": {"free_limit": 10, "reset_period": "daily", "minimum_tier": "free", "is_enabled": True},
        "ai_workout_generation": {"free_limit": 2, "reset_period": "monthly", "minimum_tier": "free", "is_enabled": True},
        "food_scanning": {"free_limit": 1, "reset_period": "daily", "minimum_tier": "free", "is_enabled": True},
        "form_video_analysis": {"free_limit": 0, "reset_period": None, "minimum_tier": "premium", "is_enabled": True},
        "text_to_calories": {"free_limit": 3, "reset_period": "daily", "minimum_tier": "free", "is_enabled": True},
    }
    return fallbacks.get(feature_key, {"free_limit": None, "reset_period": None, "minimum_tier": "free", "is_enabled": True})


async def track_premium_usage(user_id: str, feature_key: str):
    """Increment usage counter for a feature after successful use."""
    supabase = get_supabase()
    today = date.today().isoformat()

    try:
        # Try RPC first
        supabase.client.rpc(
            "increment_feature_usage",
            {
                "p_user_id": user_id,
                "p_feature_key": feature_key,
                "p_usage_date": today,
                "p_metadata": {}
            }
        ).execute()
    except Exception:
        # Fallback to manual upsert
        try:
            existing = supabase.client.table("feature_usage")\
                .select("id, usage_count")\
                .eq("user_id", user_id)\
                .eq("feature_key", feature_key)\
                .eq("usage_date", today)\
                .single()\
                .execute()

            if existing.data:
                supabase.client.table("feature_usage")\
                    .update({"usage_count": existing.data["usage_count"] + 1})\
                    .eq("id", existing.data["id"])\
                    .execute()
            else:
                supabase.client.table("feature_usage").insert({
                    "user_id": user_id,
                    "feature_key": feature_key,
                    "usage_date": today,
                    "usage_count": 1,
                    "metadata": {}
                }).execute()
        except Exception as e:
            logger.error(f"Failed to track usage for {feature_key}: {e}", exc_info=True)


def _get_current_usage(supabase, user_id: str, feature_key: str, reset_period: Optional[str]) -> int:
    """Get current usage count respecting the reset period."""
    today = date.today()

    try:
        if reset_period == "daily":
            result = supabase.client.table("feature_usage")\
                .select("usage_count")\
                .eq("user_id", user_id)\
                .eq("feature_key", feature_key)\
                .eq("usage_date", today.isoformat())\
                .execute()
            return sum(row["usage_count"] for row in (result.data or []))

        elif reset_period == "monthly":
            first_of_month = today.replace(day=1).isoformat()
            result = supabase.client.table("feature_usage")\
                .select("usage_count")\
                .eq("user_id", user_id)\
                .eq("feature_key", feature_key)\
                .gte("usage_date", first_of_month)\
                .execute()
            return sum(row["usage_count"] for row in (result.data or []))

        else:
            # No reset period (null) - sum all time usage
            result = supabase.client.table("feature_usage")\
                .select("usage_count")\
                .eq("user_id", user_id)\
                .eq("feature_key", feature_key)\
                .execute()
            return sum(row["usage_count"] for row in (result.data or []))

    except Exception as e:
        logger.warning(f"Failed to get usage for {feature_key}: {e}", exc_info=True)
        return 0
