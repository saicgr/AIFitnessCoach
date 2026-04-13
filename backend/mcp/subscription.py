"""MCP subscription eligibility.

MCP is yearly-subscriber-only. This module is the single source of truth
for that gate. Used at two enforcement points:
  1. OAuth /authorize — block non-yearly users before consent.
  2. Every MCP tool call — re-verified via Redis-cached eligibility check.

When a user's yearly subscription lapses (RevenueCat webhook), call
`revoke_all_mcp_tokens(user_id)` to hard-kill all their connections.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from core.logger import get_logger
from core.redis_cache import RedisCache
from core.supabase_client import get_supabase
from mcp.config import get_mcp_config

logger = get_logger(__name__)
_cfg = get_mcp_config()
_eligibility_cache = RedisCache(prefix="mcp_eligible", ttl_seconds=_cfg.SUBSCRIPTION_CACHE_TTL_SEC)


async def is_mcp_eligible(user_id: str, *, use_cache: bool = True) -> bool:
    """Return True iff user holds an active yearly subscription.

    Eligibility rules:
      - subscription row exists
      - status in ('active', 'trial', 'grace_period')  — grace_period kept for
        billing-retry tolerance; revoke-on-expiry fires via webhook, not here
      - product_id is in MCPConfig.YEARLY_PRODUCT_IDS
      - current_period_end (if set) is in the future

    Args:
        user_id: Backend users.id (not auth_id).
        use_cache: Set False on critical paths (e.g. token issuance) where
                   a stale hit would be worse than the extra DB round-trip.
    """
    cache_key = f"v1:{user_id}"
    if use_cache:
        cached = await _eligibility_cache.get(cache_key)
        if cached is not None:
            return bool(cached)

    eligible = await _check_eligibility_db(user_id)
    await _eligibility_cache.set(cache_key, eligible)
    return eligible


async def _check_eligibility_db(user_id: str) -> bool:
    """Source-of-truth DB check (no caching)."""
    supabase = get_supabase()
    try:
        result = supabase.client.table("user_subscriptions") \
            .select("tier, status, product_id, current_period_end, is_trial, trial_end_date") \
            .eq("user_id", user_id) \
            .limit(1) \
            .execute()
    except Exception as e:
        # Fail closed — if we can't verify, deny access.
        logger.error(f"MCP eligibility check failed for user {user_id}: {e}", exc_info=True)
        return False

    rows = result.data or []
    if not rows:
        return False

    sub = rows[0]

    # Status gate
    if sub.get("status") not in ("active", "trial", "grace_period"):
        return False

    # Yearly product gate
    if sub.get("product_id") not in _cfg.YEARLY_PRODUCT_IDS:
        return False

    # Period-end gate (if set)
    period_end = sub.get("current_period_end")
    if period_end:
        try:
            end_dt = datetime.fromisoformat(period_end.replace("Z", "+00:00"))
            if end_dt < datetime.now(timezone.utc):
                return False
        except (ValueError, AttributeError):
            # Malformed date — treat as not eligible rather than crashing.
            logger.warning(f"Malformed current_period_end for user {user_id}: {period_end}")
            return False

    return True


async def invalidate_eligibility_cache(user_id: str) -> None:
    """Call after any subscription change (webhook handlers, admin edits)."""
    await _eligibility_cache.delete(f"v1:{user_id}")


async def revoke_all_mcp_tokens(user_id: str, *, reason: str = "subscription_expired") -> int:
    """Mark all of a user's MCP tokens as revoked.

    Called from the RevenueCat webhook when a user's yearly subscription
    ends (cancellation, expiration, downgrade to monthly). External AI
    clients will get 401 invalid_token on next call.

    Returns number of tokens revoked.
    """
    supabase = get_supabase()
    now = datetime.now(timezone.utc).isoformat()

    try:
        result = supabase.client.table("mcp_tokens") \
            .update({"revoked_at": now, "revoked_reason": reason}) \
            .eq("user_id", user_id) \
            .is_("revoked_at", "null") \
            .execute()
        revoked_count = len(result.data or [])
        logger.info(
            f"MCP: revoked {revoked_count} tokens for user {user_id} (reason={reason})"
        )
    except Exception as e:
        logger.error(f"Failed to revoke MCP tokens for user {user_id}: {e}", exc_info=True)
        revoked_count = 0

    await invalidate_eligibility_cache(user_id)
    return revoked_count


async def revoke_client_tokens(user_id: str, client_id: str, *, reason: str = "user_revoked") -> int:
    """Revoke all tokens for one specific (user, client) pair.

    Called from the Flutter 'AI Integrations' settings screen when the user
    taps 'Disconnect' on a specific client.
    """
    supabase = get_supabase()
    now = datetime.now(timezone.utc).isoformat()

    try:
        result = supabase.client.table("mcp_tokens") \
            .update({"revoked_at": now, "revoked_reason": reason}) \
            .eq("user_id", user_id) \
            .eq("client_id", client_id) \
            .is_("revoked_at", "null") \
            .execute()
        return len(result.data or [])
    except Exception as e:
        logger.error(
            f"Failed to revoke MCP tokens for user={user_id} client={client_id}: {e}",
            exc_info=True,
        )
        return 0
