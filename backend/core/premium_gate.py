"""
Shared premium feature gate checking and usage tracking.

Provides `check_premium_gate()` for backend endpoints to enforce
free-tier limits on AI features. Every PAYING tier — premium, premium_plus,
its legacy name ultra, and lifetime — gets unlimited access; the tier
hierarchy itself lives in core/feature_gate_policy.py (the single source
shared with the subscription handlers), never as a list in this file.
"""
import os
from datetime import date, datetime
from typing import Optional, Tuple
from fastapi import HTTPException

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.timezone_utils import get_user_today
from core.feature_gate_policy import (
    DEFAULT_RESET_PERIOD,
    is_paid_tier,
    meets_minimum_tier,
    normalize_reset_period,
)

logger = get_logger(__name__)

_is_production = os.getenv("RENDER", "false").lower() == "true" or os.getenv("ENV", "dev") == "production"

# Feature keys that this module manages
PREMIUM_FEATURE_KEYS = [
    # Keep in sync with CHAT_FEATURE_KEY in api/v1/chat.py. Legacy "ai_chat"
    # stays listed so any caller still passing it keeps its fallback limit.
    "ai_chat_messages",
    "ai_chat",
    "ai_workout_generation",
    "food_scanning",
    "form_video_analysis",
    "text_to_calories",
    # Tier-gated premium surfaces (free_limit 0 + minimum_tier premium).
    # Listed here so an unseeded feature_gates table falls through to
    # _get_fallback_gate() and stays CLOSED, instead of hitting the
    # "unknown feature gate -> allow access" branch below and silently
    # handing every free user an unlimited premium feature.
    "program_start",
    "body_analysis",
    "audio_coach",
    "data_export",
]

# Keys that exist only as backwards-compatible ALIASES — they are still
# honoured by check_premium_gate() if a caller passes them, but they must never
# be surfaced to the user as a separate quota (doing so shows two counters for
# one feature). "ai_chat" is the pre-1864 name for "ai_chat_messages".
LEGACY_FEATURE_KEYS = frozenset({"ai_chat"})

# The list any USER-FACING quota display should iterate — e.g. the in-app
# "N left today" strip served by GET /subscriptions/{id}/feature-limits.
#
# Derived, never hand-listed. api/v1/subscriptions/management.py used to keep
# its own literal copy of this list; it drifted (it carried the phantom
# `ai_meal_plan`, was missing `ai_chat`, and would silently have omitted every
# gate added after it was written). A hardcoded per-call-site copy IS the bug —
# the same lesson core/feature_gate_policy.py exists to enforce for tier ranks.
USER_FACING_FEATURE_KEYS = [
    k for k in PREMIUM_FEATURE_KEYS if k not in LEGACY_FEATURE_KEYS
]


async def check_premium_gate(user_id: str, feature_key: str, timezone_str: str) -> Tuple[bool, Optional[int]]:
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

    # Every paying tier gets unlimited access — premium, premium_plus, the legacy
    # `ultra`, and `lifetime`. Ranked from core/feature_gate_policy.TIER_RANK so a
    # tier added to the subscription_tier enum can never be metered as free again.
    if is_paid_tier(user_tier):
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
            # Genuinely unknown key: allow, but log at ERROR. This branch is a
            # safety valve for callers passing an ad-hoc key, NOT a place for a
            # feature we meant to gate — anything we intend to charge for must
            # appear in PREMIUM_FEATURE_KEYS above so it fails CLOSED via
            # _get_fallback_gate() when the table row is missing.
            logger.error(
                f"Unknown feature gate '{feature_key}' — allowing access. If this "
                f"feature is meant to be paid, add it to PREMIUM_FEATURE_KEYS.",
                exc_info=True,
            )
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
    if not meets_minimum_tier(user_tier, gate.get("minimum_tier")):
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
    current_usage = _get_current_usage(supabase, user_id, feature_key, reset_period, timezone_str)

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
        # Mirrors migration 1864/1868 (free_limit 20, daily reset).
        "ai_chat_messages": {"free_limit": 20, "reset_period": "daily", "minimum_tier": "free", "is_enabled": True},
        "ai_chat": {"free_limit": 10, "reset_period": "daily", "minimum_tier": "free", "is_enabled": True},
        "ai_workout_generation": {"free_limit": 2, "reset_period": "monthly", "minimum_tier": "free", "is_enabled": True},
        "food_scanning": {"free_limit": 1, "reset_period": "daily", "minimum_tier": "free", "is_enabled": True},
        # free_limit 0 + minimum_tier premium: tier-gated, never metered. The period
        # is still a valid one — a NULL here is what made the free chat cap a
        # LIFETIME cap (see core/feature_gate_policy, migrations 2330/2380).
        "form_video_analysis": {"free_limit": 0, "reset_period": DEFAULT_RESET_PERIOD, "minimum_tier": "premium", "is_enabled": True},
        "text_to_calories": {"free_limit": 3, "reset_period": "daily", "minimum_tier": "free", "is_enabled": True},
        # ── Tier-gated premium surfaces (migration 2437) ──────────────────
        # free_limit 0 + minimum_tier premium == "paid only, never metered".
        # Same shape as form_video_analysis above: the tier check raises 402
        # before usage is ever counted, so reset_period is inert but must
        # still be a VALID_RESET_PERIODS value (a NULL here is what turned a
        # daily cap into a lifetime one — migrations 2330/2380).
        #
        # Deliberately NOT gated, and must stay that way:
        #   * manual workout / food logging  — never lock a user out of data
        #     they already recorded (logged-data durability).
        #   * browsing programs + exercises  — the free evaluation surface.
        #   * health sync, basic stats       — cheap, and the retention hook.
        #   * GDPR DSAR export (api/v1/dsar) — statutory, cannot be paywalled.
        #     `data_export` below is the SEPARATE in-app convenience export
        #     (Settings -> Data & Privacy, Hevy-importable); the client has
        #     always shown it behind `isSubscribed`, this makes the server
        #     agree. DSAR remains the free statutory path.
        "program_start": {"free_limit": 0, "reset_period": DEFAULT_RESET_PERIOD, "minimum_tier": "premium", "is_enabled": True},
        "body_analysis": {"free_limit": 0, "reset_period": DEFAULT_RESET_PERIOD, "minimum_tier": "premium", "is_enabled": True},
        "audio_coach": {"free_limit": 0, "reset_period": DEFAULT_RESET_PERIOD, "minimum_tier": "premium", "is_enabled": True},
        "data_export": {"free_limit": 0, "reset_period": DEFAULT_RESET_PERIOD, "minimum_tier": "premium", "is_enabled": True},
    }
    return fallbacks.get(feature_key, {"free_limit": None, "reset_period": DEFAULT_RESET_PERIOD, "minimum_tier": "free", "is_enabled": True})


async def track_premium_usage(user_id: str, feature_key: str, timezone_str: str):
    """Increment usage counter for a feature after successful use."""
    supabase = get_supabase()
    today = get_user_today(timezone_str)

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


def _get_current_usage(supabase, user_id: str, feature_key: str, reset_period: Optional[str], timezone_str: str) -> int:
    """
    Get current usage count respecting the reset period.

    There is deliberately no "no reset period" branch: a NULL/invalid period used
    to fall through to summing ALL-TIME usage, which silently turned a daily free
    cap into a permanent one. Migration 2380 makes NULL impossible in the schema;
    normalize_reset_period() is the belt-and-braces read-time chokepoint and logs
    loudly if a row ever escapes the constraint.
    """
    today = date.fromisoformat(get_user_today(timezone_str))
    reset_period = normalize_reset_period(reset_period, feature_key)

    try:
        if reset_period == "daily":
            result = supabase.client.table("feature_usage")\
                .select("usage_count")\
                .eq("user_id", user_id)\
                .eq("feature_key", feature_key)\
                .eq("usage_date", today.isoformat())\
                .execute()
            return sum(row["usage_count"] for row in (result.data or []))

        # "monthly" — normalize_reset_period() guarantees one of VALID_RESET_PERIODS
        first_of_month = today.replace(day=1).isoformat()
        result = supabase.client.table("feature_usage")\
            .select("usage_count")\
            .eq("user_id", user_id)\
            .eq("feature_key", feature_key)\
            .gte("usage_date", first_of_month)\
            .execute()
        return sum(row["usage_count"] for row in (result.data or []))

    except Exception as e:
        logger.warning(f"Failed to get usage for {feature_key}: {e}", exc_info=True)
        return 0
