"""MCP authentication middleware.

Resolves the OAuth 2.1 Bearer token off the inbound HTTP request, validates
it against the `mcp_tokens` table, and enforces the yearly-subscription
gate. The returned user dict is drop-in compatible with existing FastAPI
`get_current_user` consumers so tool handlers can pass it through to
shared service functions unchanged.

The FastMCP SDK exposes the underlying Starlette request via
`Context.request_context.request` (or via the ASGI scope). We support both
shapes so the same helper works across SDK versions.
"""
from __future__ import annotations

from typing import Any, Optional

from core.logger import get_logger
from mcp.auth.token_service import verify_access_token
from mcp.personal_tokens import looks_like_pat, verify_personal_token
from mcp.subscription import is_mcp_eligible

logger = get_logger(__name__)


class AuthError(Exception):
    """Raised when the request is unauthenticated or not MCP-eligible.

    Tool wrappers translate this into an MCP error response. We do NOT
    leak why auth failed (expired vs revoked vs not-found) to avoid
    oracle attacks — the caller just sees "invalid_token".
    """

    def __init__(self, code: str = "invalid_token", message: str = "Authentication required"):
        super().__init__(message)
        self.code = code
        self.message = message


# ─── Bearer token extraction ─────────────────────────────────────────────────

def _headers_from_ctx(ctx: Any) -> dict:
    """Best-effort extraction of HTTP headers from the MCP SDK Context.

    The SDK has changed shape across versions; we try a few known paths
    and gracefully return an empty dict if none match. Downstream
    _extract_bearer_token() will treat that as "no token".
    """
    # Path 1: ctx.request_context.request (FastAPI/Starlette Request)
    try:
        req = getattr(getattr(ctx, "request_context", None), "request", None)
        if req is not None and hasattr(req, "headers"):
            # Starlette Headers is case-insensitive Mapping
            return {k.lower(): v for k, v in req.headers.items()}
    except Exception:
        pass

    # Path 2: ctx.request_context.meta / ctx.meta (some SDK shapes stash headers there)
    for attr_chain in (("request_context", "meta"), ("meta",), ("_meta",)):
        try:
            obj: Any = ctx
            for attr in attr_chain:
                obj = getattr(obj, attr, None)
                if obj is None:
                    break
            if isinstance(obj, dict):
                headers = obj.get("headers") or obj.get("Headers")
                if isinstance(headers, dict):
                    return {k.lower(): v for k, v in headers.items()}
        except Exception:
            continue

    # Path 3: raw ASGI scope
    try:
        scope = getattr(getattr(ctx, "request_context", None), "scope", None)
        if isinstance(scope, dict):
            raw = scope.get("headers") or []
            return {k.decode("latin-1").lower(): v.decode("latin-1") for k, v in raw}
    except Exception:
        pass

    return {}


def _extract_bearer_token(ctx: Any) -> Optional[str]:
    """Pull the raw Bearer token string off the Authorization header."""
    headers = _headers_from_ctx(ctx)
    auth = headers.get("authorization") or headers.get("Authorization")
    if not auth:
        return None
    # Tolerate "Bearer xxx" and bare "xxx" (some relays strip the scheme)
    parts = auth.strip().split(None, 1)
    if len(parts) == 2 and parts[0].lower() == "bearer":
        return parts[1].strip()
    if len(parts) == 1:
        return parts[0].strip()
    return None


# ─── Main entry point ───────────────────────────────────────────────────────

async def require_user(ctx: Any) -> dict:
    """Resolve the caller into a user dict. Raises AuthError on failure.

    Returns a dict with the standard FastAPI `get_current_user` shape plus
    MCP-specific fields:
      - id, email, auth_id, user_metadata
      - mcp_token_id, mcp_client_id, mcp_scopes
    """
    token = _extract_bearer_token(ctx)
    if not token:
        raise AuthError("invalid_token", "Missing Authorization header")

    # Dispatch PAT vs OAuth access token by prefix. PAT is the default user-
    # facing path (Settings → AI Integrations → Create Connection). OAuth
    # remains for future third-party marketplace integrations.
    if looks_like_pat(token):
        user = await verify_personal_token(token)
    else:
        user = await verify_access_token(token)

    if user is None:
        raise AuthError("invalid_token", "Token is invalid, expired, or revoked")

    # Subscription gate — yearly only. Cached 5 min in Redis; safe because
    # expiry has its own hard revoke path via the webhook handler.
    try:
        eligible = await is_mcp_eligible(user["id"], use_cache=True)
    except Exception as e:
        # Fail closed if the subscription service is unreachable.
        logger.error(f"MCP eligibility check errored for user {user.get('id')}: {e}", exc_info=True)
        raise AuthError("subscription_required", "Could not verify subscription")

    if not eligible:
        raise AuthError(
            "subscription_required",
            "MCP access requires an active yearly FitWiz subscription.",
        )

    return user
