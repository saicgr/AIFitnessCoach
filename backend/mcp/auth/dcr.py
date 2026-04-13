"""Dynamic Client Registration (RFC 7591).

External MCP clients (Claude Desktop, ChatGPT, Cursor) self-register by
POSTing client metadata here. We issue a client_id + client_secret pair.
"""
from __future__ import annotations

import secrets
from datetime import datetime, timezone
from typing import Optional

from fastapi import Request
from pydantic import BaseModel, Field, field_validator

from core.logger import get_logger
from core.supabase_client import get_supabase
from mcp.auth.token_service import hash_token  # HMAC-SHA256 w/ pepper
from mcp.auth.scopes import parse_scope_string, InvalidScopeError

logger = get_logger(__name__)

CLIENT_SECRET_BYTES = 48  # 384 bits


class ClientRegistrationRequest(BaseModel):
    """RFC 7591 §2 client metadata (subset we accept)."""
    client_name: str = Field(..., min_length=1, max_length=200)
    redirect_uris: list[str] = Field(..., min_length=1, max_length=10)
    scope: Optional[str] = None                    # space-separated
    token_endpoint_auth_method: Optional[str] = "client_secret_post"
    grant_types: Optional[list[str]] = None
    response_types: Optional[list[str]] = None

    @field_validator("redirect_uris")
    @classmethod
    def _validate_redirect_uris(cls, v: list[str]) -> list[str]:
        for uri in v:
            if not (uri.startswith("https://") or uri.startswith("http://localhost") or uri.startswith("http://127.0.0.1")):
                raise ValueError(
                    f"redirect_uri must be https:// or http://localhost (got {uri[:50]})"
                )
            if len(uri) > 2000:
                raise ValueError("redirect_uri too long")
        return v


class ClientRegistrationResponse(BaseModel):
    """RFC 7591 §3 registration response."""
    client_id: str
    client_secret: str
    client_id_issued_at: int
    client_name: str
    redirect_uris: list[str]
    scope: str
    token_endpoint_auth_method: str = "client_secret_post"


async def register_client(
    req: ClientRegistrationRequest,
    request: Request,
) -> ClientRegistrationResponse:
    """Persist a new OAuth client and return its credentials.

    The client_secret is shown ONCE in the response and never retrievable again;
    only the HMAC-SHA256 hash is stored.
    """
    # Validate requested scopes (if any). Defaults apply when empty.
    try:
        scopes = parse_scope_string(req.scope)
    except InvalidScopeError as e:
        raise ValueError(str(e)) from e

    client_secret = secrets.token_urlsafe(CLIENT_SECRET_BYTES)
    client_ip = request.client.host if request.client else None

    supabase = get_supabase()
    result = supabase.client.table("mcp_oauth_clients").insert({
        "client_secret_hash": hash_token(client_secret),
        "client_name": req.client_name[:200],
        "redirect_uris": req.redirect_uris,
        "scopes": scopes,
        "created_by_ip": client_ip,
    }).execute()

    if not result.data:
        raise RuntimeError("Failed to persist OAuth client")

    row = result.data[0]
    client_id = row["client_id"]

    logger.info(
        f"MCP DCR: registered client '{req.client_name}' id={client_id} "
        f"scopes={scopes} ip={client_ip}"
    )

    return ClientRegistrationResponse(
        client_id=client_id,
        client_secret=client_secret,
        client_id_issued_at=int(datetime.now(timezone.utc).timestamp()),
        client_name=req.client_name,
        redirect_uris=req.redirect_uris,
        scope=" ".join(scopes),
    )


async def verify_client_credentials(client_id: str, client_secret: str) -> Optional[dict]:
    """Look up a client by (id, secret). Returns client row or None."""
    supabase = get_supabase()
    result = supabase.client.table("mcp_oauth_clients") \
        .select("client_id, client_name, redirect_uris, scopes, is_revoked") \
        .eq("client_id", client_id) \
        .limit(1) \
        .execute()

    rows = result.data or []
    if not rows:
        return None

    client = rows[0]
    if client.get("is_revoked"):
        return None

    # Constant-time compare of HMAC hashes.
    stored_hash = supabase.client.table("mcp_oauth_clients") \
        .select("client_secret_hash") \
        .eq("client_id", client_id) \
        .limit(1) \
        .execute()

    if not stored_hash.data:
        return None

    import hmac
    if not hmac.compare_digest(stored_hash.data[0]["client_secret_hash"], hash_token(client_secret)):
        return None

    return client


async def get_client_by_id(client_id: str) -> Optional[dict]:
    """Fetch client metadata by ID (no secret check). For /authorize validation."""
    supabase = get_supabase()
    result = supabase.client.table("mcp_oauth_clients") \
        .select("client_id, client_name, redirect_uris, scopes, is_revoked") \
        .eq("client_id", client_id) \
        .limit(1) \
        .execute()

    rows = result.data or []
    if not rows or rows[0].get("is_revoked"):
        return None
    return rows[0]
