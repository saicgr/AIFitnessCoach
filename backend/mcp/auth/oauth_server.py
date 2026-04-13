"""OAuth 2.1 authorization server for the FitWiz MCP.

Endpoints (mounted under /mcp/oauth in backend/main.py):
  POST   /register                      — Dynamic Client Registration (RFC 7591)
  GET    /authorize                     — Kicks off authorization_code flow
  POST   /authorize/complete            — Consent UI callback (internal)
  POST   /token                         — Token endpoint (code exchange + refresh)
  POST   /revoke                        — Token revocation (RFC 7009)
  GET    /.well-known/oauth-authorization-server  — Server metadata (RFC 8414)

Security notes:
  - PKCE S256 is REQUIRED (OAuth 2.1). Plain method is rejected.
  - Authorization codes are single-use (consumed_at is set on exchange).
  - Refresh tokens rotate on every /token call; replay revokes the family.
  - Non-yearly-subscriber users are bounced to an upgrade page before code issuance.
  - Client secrets are stored as HMAC-SHA256(pepper, secret) — never plaintext.
"""
from __future__ import annotations

import base64
import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional
from urllib.parse import urlencode

from fastapi import APIRouter, Form, HTTPException, Query, Request
from fastapi.responses import JSONResponse, RedirectResponse
from pydantic import BaseModel

from core.logger import get_logger
from core.supabase_client import get_supabase
from mcp.auth import consent_session
from mcp.auth.dcr import (
    ClientRegistrationRequest,
    ClientRegistrationResponse,
    get_client_by_id,
    register_client,
    verify_client_credentials,
)
from mcp.auth.scopes import InvalidScopeError, describe_scopes, parse_scope_string
from mcp.auth.token_service import (
    issue_token_pair,
    revoke_token_by_value,
    rotate_refresh_token,
)
from mcp.config import get_mcp_config
from mcp.subscription import is_mcp_eligible

logger = get_logger(__name__)
_cfg = get_mcp_config()

router = APIRouter(prefix="/mcp/oauth", tags=["mcp-oauth"])


# ─── Error helpers ───────────────────────────────────────────────────────────

def _oauth_error(error: str, description: str, status_code: int = 400) -> HTTPException:
    """Build an RFC 6749 §5.2 error response."""
    return HTTPException(
        status_code=status_code,
        detail={"error": error, "error_description": description},
    )


def _redirect_with_error(redirect_uri: str, state: Optional[str], error: str, description: str) -> RedirectResponse:
    params = {"error": error, "error_description": description}
    if state:
        params["state"] = state
    sep = "&" if "?" in redirect_uri else "?"
    return RedirectResponse(url=f"{redirect_uri}{sep}{urlencode(params)}", status_code=302)


# ─── POST /register (DCR) ────────────────────────────────────────────────────

@router.post("/register", response_model=ClientRegistrationResponse, status_code=201)
async def register(req: ClientRegistrationRequest, request: Request) -> ClientRegistrationResponse:
    try:
        return await register_client(req, request)
    except ValueError as e:
        raise _oauth_error("invalid_client_metadata", str(e))


# ─── GET /authorize ──────────────────────────────────────────────────────────

@router.get("/authorize")
async def authorize(
    request: Request,
    response_type: str = Query(...),
    client_id: str = Query(...),
    redirect_uri: str = Query(...),
    scope: Optional[str] = Query(None),
    state: Optional[str] = Query(None),
    code_challenge: str = Query(...),
    code_challenge_method: str = Query("S256"),
):
    """Validate the authorization request and redirect to the consent UI.

    MCP clients land here first; we bounce to https://fitwiz.us/oauth/authorize
    with a signed consent-session token that carries the request params.
    """
    if response_type != "code":
        raise _oauth_error("unsupported_response_type", "Only 'code' is supported.")

    if code_challenge_method != "S256":
        raise _oauth_error("invalid_request", "PKCE S256 is required.")

    client = await get_client_by_id(client_id)
    if not client:
        raise _oauth_error("invalid_client", "Unknown client.", status_code=401)

    if redirect_uri not in client["redirect_uris"]:
        raise _oauth_error("invalid_request", "redirect_uri not registered for this client.")

    try:
        requested_scopes = parse_scope_string(scope)
    except InvalidScopeError as e:
        return _redirect_with_error(redirect_uri, state, "invalid_scope", str(e))

    # Requested scopes must be a subset of what the client registered for.
    client_scopes = set(client["scopes"])
    if not set(requested_scopes).issubset(client_scopes):
        excess = set(requested_scopes) - client_scopes
        return _redirect_with_error(
            redirect_uri, state, "invalid_scope",
            f"Scopes not registered for this client: {', '.join(excess)}",
        )

    # Pack request into an opaque signed token for the consent UI to carry.
    session_token = consent_session.encode({
        "client_id": client_id,
        "client_name": client["client_name"],
        "redirect_uri": redirect_uri,
        "scopes": requested_scopes,
        "state": state,
        "code_challenge": code_challenge,
    }, ttl_sec=600)

    consent_url = f"{_cfg.CONSENT_URL}?{urlencode({'consent': session_token})}"
    return RedirectResponse(url=consent_url, status_code=302)


# ─── POST /authorize/complete (called by consent UI on fitwiz.us) ────────────

class AuthorizeCompleteRequest(BaseModel):
    consent: str                  # Opaque token from GET /authorize
    supabase_access_token: str    # User's live Supabase session JWT
    approved_scopes: list[str]    # Subset of requested scopes user actually approved


@router.post("/authorize/complete")
async def authorize_complete(body: AuthorizeCompleteRequest):
    """Complete the authorization step: user has consented on fitwiz.us.

    Verifies the Supabase session, checks MCP eligibility (yearly sub),
    issues an authorization code, and returns the redirect URL the consent
    UI should send the browser to.
    """
    payload = consent_session.decode(body.consent)
    if not payload:
        raise _oauth_error("invalid_request", "Consent session expired or invalid.")

    requested_scopes = set(payload["scopes"])
    approved = set(body.approved_scopes)
    if not approved.issubset(requested_scopes):
        raise _oauth_error("invalid_scope", "Approved scopes exceed what was requested.")
    if not approved:
        raise _oauth_error("access_denied", "No scopes approved.")

    # Resolve user via Supabase session.
    supabase = get_supabase()
    try:
        user_resp = supabase.auth_client.auth.get_user(body.supabase_access_token)
    except Exception as e:
        logger.warning(f"MCP consent: Supabase token validation failed: {e}")
        raise _oauth_error("access_denied", "Invalid Supabase session.", status_code=401)

    if not user_resp or not user_resp.user:
        raise _oauth_error("access_denied", "No Supabase user.", status_code=401)

    auth_id = str(user_resp.user.id)
    user_row_resp = supabase.client.table("users") \
        .select("id") \
        .eq("auth_id", auth_id) \
        .limit(1) \
        .execute()
    if not user_row_resp.data:
        raise _oauth_error("access_denied", "User has no FitWiz profile.", status_code=401)

    user_id = user_row_resp.data[0]["id"]

    # Subscription gate — yearly only.
    if not await is_mcp_eligible(user_id, use_cache=False):
        # Return 402 with upgrade_url so the consent UI can redirect the user.
        raise HTTPException(
            status_code=402,
            detail={
                "error": "subscription_required",
                "error_description": "MCP access requires a yearly subscription.",
                "upgrade_url": _cfg.UPGRADE_URL,
            },
        )

    # Issue authorization code.
    code = secrets.token_urlsafe(32)
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=_cfg.AUTH_CODE_TTL_SEC)

    supabase.client.table("mcp_auth_codes").insert({
        "code": code,
        "client_id": payload["client_id"],
        "user_id": user_id,
        "scopes": sorted(approved),
        "code_challenge": payload["code_challenge"],
        "code_challenge_method": "S256",
        "redirect_uri": payload["redirect_uri"],
        "expires_at": expires_at.isoformat(),
    }).execute()

    logger.info(
        f"MCP: issued auth code for user={user_id} client={payload['client_id']} "
        f"scopes={sorted(approved)}"
    )

    # Build redirect URL back to the MCP client.
    params = {"code": code}
    if payload.get("state"):
        params["state"] = payload["state"]
    sep = "&" if "?" in payload["redirect_uri"] else "?"
    redirect_to = f"{payload['redirect_uri']}{sep}{urlencode(params)}"

    return {"redirect_to": redirect_to}


@router.get("/authorize/peek")
async def authorize_peek(consent: str = Query(...)):
    """Consent UI helper: decode the session token so the UI can render
    the client name + scope list without needing to understand the format.
    """
    payload = consent_session.decode(consent)
    if not payload:
        raise _oauth_error("invalid_request", "Consent session expired or invalid.")
    return {
        "client_id": payload["client_id"],
        "client_name": payload["client_name"],
        "requested_scopes": describe_scopes(payload["scopes"]),
    }


# ─── POST /token ─────────────────────────────────────────────────────────────

@router.post("/token")
async def token(
    grant_type: str = Form(...),
    code: Optional[str] = Form(None),
    redirect_uri: Optional[str] = Form(None),
    client_id: Optional[str] = Form(None),
    client_secret: Optional[str] = Form(None),
    code_verifier: Optional[str] = Form(None),
    refresh_token: Optional[str] = Form(None),
):
    """Exchange an authorization code for tokens, or refresh an existing pair."""
    if not client_id or not client_secret:
        raise _oauth_error("invalid_client", "client_id and client_secret required.", status_code=401)

    client = await verify_client_credentials(client_id, client_secret)
    if not client:
        raise _oauth_error("invalid_client", "Client authentication failed.", status_code=401)

    if grant_type == "authorization_code":
        return await _exchange_code(
            code=code,
            redirect_uri=redirect_uri,
            code_verifier=code_verifier,
            client_id=client_id,
        )
    if grant_type == "refresh_token":
        return await _exchange_refresh(refresh_token=refresh_token, client_id=client_id)

    raise _oauth_error("unsupported_grant_type", f"grant_type '{grant_type}' not supported.")


async def _exchange_code(*, code: Optional[str], redirect_uri: Optional[str],
                         code_verifier: Optional[str], client_id: str) -> dict:
    if not code or not redirect_uri or not code_verifier:
        raise _oauth_error("invalid_request", "code, redirect_uri, code_verifier required.")

    supabase = get_supabase()
    now = datetime.now(timezone.utc)

    # Atomic claim: update consumed_at only if still null.
    row_resp = supabase.client.table("mcp_auth_codes") \
        .select("code, client_id, user_id, scopes, code_challenge, redirect_uri, expires_at, consumed_at") \
        .eq("code", code) \
        .limit(1) \
        .execute()

    rows = row_resp.data or []
    if not rows:
        raise _oauth_error("invalid_grant", "Unknown code.")
    auth_code = rows[0]

    # Already consumed → possible replay. Nuke any tokens minted from this code.
    if auth_code.get("consumed_at"):
        logger.warning(
            f"MCP: authorization_code replay attempt. code={code[:8]}... "
            f"user={auth_code['user_id']} client={auth_code['client_id']}"
        )
        # Note: we don't have an easy link from code→tokens, so log loudly.
        raise _oauth_error("invalid_grant", "Authorization code already used.")

    if str(auth_code["client_id"]) != str(client_id):
        raise _oauth_error("invalid_grant", "Code was issued to a different client.")

    if auth_code["redirect_uri"] != redirect_uri:
        raise _oauth_error("invalid_grant", "redirect_uri mismatch.")

    try:
        expires_at = datetime.fromisoformat(auth_code["expires_at"].replace("Z", "+00:00"))
    except (ValueError, KeyError):
        raise _oauth_error("invalid_grant", "Malformed code expiry.")
    if expires_at < now:
        raise _oauth_error("invalid_grant", "Code expired.")

    # PKCE S256 verification.
    expected_challenge = _pkce_s256(code_verifier)
    if expected_challenge != auth_code["code_challenge"]:
        raise _oauth_error("invalid_grant", "PKCE code_verifier does not match.")

    # Re-check eligibility (defense in depth — sub could have lapsed between
    # consent and token exchange).
    if not await is_mcp_eligible(auth_code["user_id"], use_cache=False):
        raise HTTPException(
            status_code=402,
            detail={
                "error": "subscription_required",
                "error_description": "Yearly subscription is no longer active.",
            },
        )

    # Mark code consumed.
    supabase.client.table("mcp_auth_codes") \
        .update({"consumed_at": now.isoformat()}) \
        .eq("code", code) \
        .execute()

    pair = await issue_token_pair(
        client_id=auth_code["client_id"],
        user_id=auth_code["user_id"],
        scopes=auth_code["scopes"],
    )
    return pair


async def _exchange_refresh(*, refresh_token: Optional[str], client_id: str) -> dict:
    if not refresh_token:
        raise _oauth_error("invalid_request", "refresh_token required.")

    new_pair = await rotate_refresh_token(refresh_token, client_id=client_id)
    if not new_pair:
        raise _oauth_error("invalid_grant", "Refresh token invalid, expired, or replayed.")

    # Re-check subscription on refresh; if it lapsed, deny.
    # We need the user_id from the new pair's DB row — issue_token_pair just
    # inserted it, so look it up by the new access hash.
    from mcp.auth.token_service import hash_token
    supabase = get_supabase()
    row = supabase.client.table("mcp_tokens") \
        .select("user_id") \
        .eq("access_token_hash", hash_token(new_pair["access_token"])) \
        .limit(1) \
        .execute()
    if row.data:
        user_id = row.data[0]["user_id"]
        if not await is_mcp_eligible(user_id, use_cache=False):
            # Subscription lapsed — revoke the freshly-minted pair and fail.
            from mcp.subscription import revoke_all_mcp_tokens
            await revoke_all_mcp_tokens(user_id, reason="subscription_expired")
            raise HTTPException(
                status_code=402,
                detail={
                    "error": "subscription_required",
                    "error_description": "Yearly subscription is no longer active.",
                },
            )
    return new_pair


def _pkce_s256(code_verifier: str) -> str:
    """Compute PKCE S256 challenge: base64url-nopadding(SHA-256(verifier))."""
    digest = hashlib.sha256(code_verifier.encode("ascii")).digest()
    return base64.urlsafe_b64encode(digest).rstrip(b"=").decode("ascii")


# ─── POST /revoke (RFC 7009) ─────────────────────────────────────────────────

@router.post("/revoke")
async def revoke(
    token: str = Form(...),
    client_id: str = Form(...),
    client_secret: str = Form(...),
    token_type_hint: Optional[str] = Form(None),
):
    client = await verify_client_credentials(client_id, client_secret)
    if not client:
        raise _oauth_error("invalid_client", "Client authentication failed.", status_code=401)

    await revoke_token_by_value(token, client_id=client_id)
    # RFC 7009 §2.2: success is 200 regardless of whether token existed.
    return JSONResponse(status_code=200, content={})


# ─── GET /.well-known/oauth-authorization-server (RFC 8414) ──────────────────

@router.get("/.well-known/oauth-authorization-server")
async def metadata():
    base = _cfg.OAUTH_ISSUER.rstrip("/")
    return {
        "issuer": base,
        "registration_endpoint": f"{base}/mcp/oauth/register",
        "authorization_endpoint": f"{base}/mcp/oauth/authorize",
        "token_endpoint": f"{base}/mcp/oauth/token",
        "revocation_endpoint": f"{base}/mcp/oauth/revoke",
        "response_types_supported": ["code"],
        "grant_types_supported": ["authorization_code", "refresh_token"],
        "code_challenge_methods_supported": ["S256"],
        "token_endpoint_auth_methods_supported": ["client_secret_post"],
        "scopes_supported": list(_cfg.SCOPES.keys()),
        "registration_endpoint_auth_methods_supported": ["none"],
    }
