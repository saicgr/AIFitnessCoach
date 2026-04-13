"""Personal Access Tokens for MCP — simpler alternative to OAuth.

Users generate a PAT from the FitWiz app (Settings → AI Integrations →
Create Connection). They paste the generated JSON config directly into their
MCP client. No consent screen, no cross-device token copying, no OAuth
authorization code dance.

Security posture vs. OAuth:
- PATs are long-lived (never auto-expire) → higher blast radius if leaked
- Mitigations:
  * User-scoped revocation (same UX as OAuth integrations)
  * Yearly-sub gate enforced at creation AND at every tool call
  * Scopes stored and enforced identically to OAuth
  * last_used_at surfaced in settings so stale/forgotten tokens stand out
  * Audit log writes the token_id so misuse can be traced

Token format:
    fwz_pat_<43-char-base64url>
The prefix makes accidental paste into chat visible, and lets
verify_access_token dispatch PAT vs OAuth lookup by shape.
"""
from __future__ import annotations

import secrets
from datetime import datetime, timezone
from typing import Optional

from core.logger import get_logger
from core.supabase_client import get_supabase
from mcp.auth.token_service import hash_token
from mcp.auth.scopes import InvalidScopeError, parse_scope_string
from mcp.config import get_mcp_config
from mcp.subscription import is_mcp_eligible

logger = get_logger(__name__)
_cfg = get_mcp_config()

PAT_PREFIX = "fwz_pat_"
PAT_RANDOM_BYTES = 32  # 256-bit random body


def _generate_pat() -> str:
    """Generate a fresh personal access token."""
    return PAT_PREFIX + secrets.token_urlsafe(PAT_RANDOM_BYTES)


def looks_like_pat(token: str) -> bool:
    """Quick prefix check — cheap dispatch for verify_access_token."""
    return bool(token) and token.startswith(PAT_PREFIX)


async def create_personal_token(
    *,
    user_id: str,
    name: str,
    scopes: Optional[list[str]] = None,
    created_by_ip: Optional[str] = None,
) -> dict:
    """Create a new PAT for a yearly subscriber.

    Returns `{token, token_id, name, scopes, created_at}`. The raw `token` is
    the ONLY time the plaintext value exists — store it or it's gone.

    Raises PermissionError if the user is not MCP-eligible.
    Raises ValueError for bad inputs (empty name, invalid scopes).
    """
    if not await is_mcp_eligible(user_id, use_cache=False):
        raise PermissionError("subscription_required")

    clean_name = (name or "").strip()
    if not clean_name:
        raise ValueError("name is required")
    if len(clean_name) > 100:
        raise ValueError("name too long (max 100 chars)")

    # Validate scopes against master list. None/empty → defaults.
    try:
        clean_scopes = parse_scope_string(" ".join(scopes) if scopes else None)
    except InvalidScopeError as e:
        raise ValueError(str(e)) from e

    raw_token = _generate_pat()
    token_hash = hash_token(raw_token)

    supabase = get_supabase()
    result = supabase.client.table("mcp_personal_tokens").insert({
        "access_token_hash": token_hash,
        "user_id": user_id,
        "name": clean_name,
        "scopes": clean_scopes,
        "created_by_ip": created_by_ip,
    }).execute()

    if not result.data:
        raise RuntimeError("Failed to persist PAT")

    row = result.data[0]
    logger.info(
        f"MCP PAT created: user={user_id} token_id={row['token_id']} "
        f"name='{clean_name}' scopes={clean_scopes}"
    )

    return {
        "token": raw_token,
        "token_id": row["token_id"],
        "name": clean_name,
        "scopes": clean_scopes,
        "created_at": row["created_at"],
    }


async def verify_personal_token(token: str) -> Optional[dict]:
    """Look up a PAT and return the user context if valid.

    Returns the same shape as OAuth `verify_access_token` so downstream
    middleware can treat both identically:
        {id, email, auth_id, user_metadata, mcp_token_id, mcp_client_id, mcp_scopes}

    `mcp_client_id` is None for PATs — use `mcp_token_id` for audit tracing.
    """
    if not looks_like_pat(token):
        return None

    token_hash = hash_token(token)
    supabase = get_supabase()

    row_resp = supabase.client.table("mcp_personal_tokens") \
        .select("token_id, user_id, scopes, revoked_at") \
        .eq("access_token_hash", token_hash) \
        .limit(1) \
        .execute()

    rows = row_resp.data or []
    if not rows:
        return None

    row = rows[0]
    if row.get("revoked_at"):
        return None

    user_resp = supabase.client.table("users") \
        .select("id, email, auth_id") \
        .eq("id", row["user_id"]) \
        .limit(1) \
        .execute()
    users = user_resp.data or []
    if not users:
        return None
    user = users[0]

    # Best-effort last_used_at bump — non-blocking, errors swallowed.
    try:
        supabase.client.table("mcp_personal_tokens") \
            .update({"last_used_at": datetime.now(timezone.utc).isoformat()}) \
            .eq("token_id", row["token_id"]) \
            .execute()
    except Exception:
        pass

    return {
        "id": user["id"],
        "email": user.get("email"),
        "auth_id": user.get("auth_id"),
        "user_metadata": {},
        "mcp_token_id": row["token_id"],
        "mcp_client_id": None,                # no OAuth client for PATs
        "mcp_scopes": row["scopes"],
        "mcp_auth_type": "pat",
    }


async def list_personal_tokens(user_id: str) -> list[dict]:
    """Active (non-revoked) PATs for a user. For the settings screen."""
    supabase = get_supabase()
    result = supabase.client.table("mcp_personal_tokens") \
        .select("token_id, name, scopes, created_at, last_used_at") \
        .eq("user_id", user_id) \
        .is_("revoked_at", "null") \
        .order("created_at", desc=True) \
        .execute()
    return result.data or []


async def revoke_personal_token(
    user_id: str,
    token_id: str,
    *,
    reason: str = "user_revoked",
) -> bool:
    """Revoke a single PAT owned by the user. Returns True on success.

    IDOR-safe: the `user_id` filter ensures a user can only revoke tokens
    they own even if they guess another user's token_id.
    """
    supabase = get_supabase()
    now = datetime.now(timezone.utc).isoformat()
    try:
        result = supabase.client.table("mcp_personal_tokens") \
            .update({"revoked_at": now, "revoked_reason": reason}) \
            .eq("token_id", token_id) \
            .eq("user_id", user_id) \
            .is_("revoked_at", "null") \
            .execute()
        return bool(result.data)
    except Exception as e:
        logger.error(
            f"Failed to revoke PAT user={user_id} token_id={token_id}: {e}",
            exc_info=True,
        )
        return False


async def revoke_all_personal_tokens(
    user_id: str,
    *,
    reason: str = "subscription_expired",
) -> int:
    """Revoke every PAT for a user. Called from the RevenueCat webhook."""
    supabase = get_supabase()
    now = datetime.now(timezone.utc).isoformat()
    try:
        result = supabase.client.table("mcp_personal_tokens") \
            .update({"revoked_at": now, "revoked_reason": reason}) \
            .eq("user_id", user_id) \
            .is_("revoked_at", "null") \
            .execute()
        return len(result.data or [])
    except Exception as e:
        logger.error(
            f"Failed to revoke PATs for user={user_id}: {e}", exc_info=True
        )
        return 0
