"""OAuth token issuance, verification, and rotation.

Access + refresh tokens are random URL-safe strings. They are NEVER stored
in plaintext — we store SHA-256(pepper || token) and compare on lookup.
Pepper is a server-side secret (MCPConfig.TOKEN_PEPPER); rotating it
invalidates all outstanding tokens (emergency mass-revoke lever).

Bcrypt would be nicer cryptographically but tokens are high-entropy random
strings, so a keyed hash is sufficient and much faster on the hot path.
"""
from __future__ import annotations

import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

from core.logger import get_logger
from core.supabase_client import get_supabase
from mcp.config import get_mcp_config

logger = get_logger(__name__)
_cfg = get_mcp_config()

ACCESS_TOKEN_BYTES = 32    # 256 bits
REFRESH_TOKEN_BYTES = 48   # 384 bits


# ─── Hashing ─────────────────────────────────────────────────────────────────

def hash_token(token: str) -> str:
    """Keyed SHA-256 hash. Deterministic so we can look up by hash."""
    pepper = _cfg.TOKEN_PEPPER.encode("utf-8")
    return hmac.new(pepper, token.encode("utf-8"), hashlib.sha256).hexdigest()


def generate_access_token() -> str:
    return secrets.token_urlsafe(ACCESS_TOKEN_BYTES)


def generate_refresh_token() -> str:
    return secrets.token_urlsafe(REFRESH_TOKEN_BYTES)


# ─── Token issuance ──────────────────────────────────────────────────────────

async def issue_token_pair(
    *,
    client_id: str,
    user_id: str,
    scopes: list[str],
) -> dict:
    """Mint an access+refresh token pair and persist hashes.

    Returns the raw tokens (caller hands them to the OAuth client response).
    These are the ONLY moments the plaintext tokens exist.
    """
    access_token = generate_access_token()
    refresh_token = generate_refresh_token()

    now = datetime.now(timezone.utc)
    access_expires = now + timedelta(seconds=_cfg.ACCESS_TOKEN_TTL_SEC)
    refresh_expires = now + timedelta(seconds=_cfg.REFRESH_TOKEN_TTL_SEC)

    supabase = get_supabase()
    supabase.client.table("mcp_tokens").insert({
        "access_token_hash": hash_token(access_token),
        "refresh_token_hash": hash_token(refresh_token),
        "client_id": client_id,
        "user_id": user_id,
        "scopes": scopes,
        "access_expires_at": access_expires.isoformat(),
        "refresh_expires_at": refresh_expires.isoformat(),
    }).execute()

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "Bearer",
        "expires_in": _cfg.ACCESS_TOKEN_TTL_SEC,
        "scope": " ".join(scopes),
    }


# ─── Access-token verification (hot path) ────────────────────────────────────

async def verify_access_token(token: str) -> Optional[dict]:
    """Look up a plaintext access token and return its row if valid.

    Returns None for any failure reason (not found, expired, revoked).
    Callers should NOT differentiate error reasons to the client — return
    a generic 401 to avoid oracle attacks.

    The returned dict is shaped to drop into existing `get_current_user`
    consumers (id, email, auth_id, scopes).
    """
    token_hash = hash_token(token)
    supabase = get_supabase()

    result = supabase.client.table("mcp_tokens") \
        .select("token_id, user_id, client_id, scopes, access_expires_at, revoked_at") \
        .eq("access_token_hash", token_hash) \
        .limit(1) \
        .execute()

    rows = result.data or []
    if not rows:
        return None

    row = rows[0]

    if row.get("revoked_at"):
        return None

    try:
        expires_at = datetime.fromisoformat(row["access_expires_at"].replace("Z", "+00:00"))
    except (ValueError, KeyError):
        return None
    if expires_at < datetime.now(timezone.utc):
        return None

    # Resolve to the user row that existing auth consumers expect.
    user_row = supabase.client.table("users") \
        .select("id, email, auth_id") \
        .eq("id", row["user_id"]) \
        .limit(1) \
        .execute()
    users = user_row.data or []
    if not users:
        return None

    user = users[0]

    # Best-effort last_used_at update (non-blocking — errors swallowed).
    try:
        supabase.client.table("mcp_tokens") \
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
        # MCP-specific context:
        "mcp_token_id": row["token_id"],
        "mcp_client_id": row["client_id"],
        "mcp_scopes": row["scopes"],
    }


# ─── Refresh flow ────────────────────────────────────────────────────────────

async def rotate_refresh_token(refresh_token: str, client_id: str) -> Optional[dict]:
    """Exchange a refresh token for a new access+refresh pair.

    On success, revokes the OLD token row (refresh-token rotation per OAuth 2.1
    best practice, RFC 6749 §10.4 + §10.5). On detected reuse (refresh token
    presented after it was already rotated), revokes the entire token family
    as a stolen-token countermeasure.
    """
    token_hash = hash_token(refresh_token)
    supabase = get_supabase()

    result = supabase.client.table("mcp_tokens") \
        .select("token_id, user_id, client_id, scopes, refresh_expires_at, revoked_at, revoked_reason") \
        .eq("refresh_token_hash", token_hash) \
        .limit(1) \
        .execute()

    rows = result.data or []
    if not rows:
        return None

    row = rows[0]

    # Client mismatch — token was minted for a different client. Suspicious.
    if str(row["client_id"]) != str(client_id):
        logger.warning(
            f"MCP refresh-token client mismatch: token client={row['client_id']}, requester={client_id}"
        )
        return None

    # Replay detection: if already revoked with reason 'rotated', someone is
    # replaying a superseded refresh token. Revoke the whole family.
    if row.get("revoked_at"):
        if row.get("revoked_reason") == "rotated":
            logger.warning(
                f"MCP refresh-token replay detected: user={row['user_id']}. Revoking family."
            )
            await _revoke_user_client_family(row["user_id"], row["client_id"])
        return None

    try:
        refresh_expires = datetime.fromisoformat(row["refresh_expires_at"].replace("Z", "+00:00"))
    except (ValueError, KeyError):
        return None
    if refresh_expires < datetime.now(timezone.utc):
        return None

    # Mint a new pair first, then revoke the old row. If the insert fails
    # the old token remains valid — safer than briefly having no valid token.
    new_pair = await issue_token_pair(
        client_id=row["client_id"],
        user_id=row["user_id"],
        scopes=row["scopes"],
    )

    supabase.client.table("mcp_tokens") \
        .update({
            "revoked_at": datetime.now(timezone.utc).isoformat(),
            "revoked_reason": "rotated",
        }) \
        .eq("token_id", row["token_id"]) \
        .execute()

    return new_pair


async def _revoke_user_client_family(user_id: str, client_id: str) -> None:
    """Revoke every active token for a (user, client) pair. Used on replay detection."""
    supabase = get_supabase()
    supabase.client.table("mcp_tokens") \
        .update({
            "revoked_at": datetime.now(timezone.utc).isoformat(),
            "revoked_reason": "refresh_token_replay",
        }) \
        .eq("user_id", user_id) \
        .eq("client_id", client_id) \
        .is_("revoked_at", "null") \
        .execute()


# ─── Explicit revocation (RFC 7009) ──────────────────────────────────────────

async def revoke_token_by_value(token: str, client_id: str) -> bool:
    """Revoke a token (access or refresh) by its plaintext value.

    Called from /oauth/revoke. Silent success even if token doesn't exist
    or already revoked (RFC 7009 §2.2).
    """
    token_hash = hash_token(token)
    supabase = get_supabase()

    # Try as access token first, then refresh token.
    for column in ("access_token_hash", "refresh_token_hash"):
        result = supabase.client.table("mcp_tokens") \
            .update({
                "revoked_at": datetime.now(timezone.utc).isoformat(),
                "revoked_reason": "client_revoked",
            }) \
            .eq(column, token_hash) \
            .eq("client_id", client_id) \
            .is_("revoked_at", "null") \
            .execute()
        if result.data:
            return True
    return False
