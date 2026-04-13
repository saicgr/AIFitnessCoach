"""
MCP Integrations endpoints.

Lets a user create, inspect, and revoke the external AI assistants (Claude
Desktop, ChatGPT, Cursor, etc.) that have been granted access to their FitWiz
account via the MCP server.

There are two connection paths:

1. **Personal Access Tokens (PAT)** — the primary user-facing flow. User taps
   "Create Connection" in Settings → AI Integrations, names the integration,
   picks scopes, and gets a JSON config block to paste into their MCP client.
   Never-expire, revocable, scoped. Simple like Supabase MCP.

2. **OAuth** — reserved for future third-party marketplace listings
   (ChatGPT Apps, Claude Connector store). Still fully wired server-side;
   surfaced here as a read-only view of connected clients.

ENDPOINTS:
- GET    /api/v1/users/me/mcp-integrations                  — list all active integrations (PAT + OAuth)
- POST   /api/v1/users/me/mcp-integrations/pat              — create a new PAT
- DELETE /api/v1/users/me/mcp-integrations/pat/{token_id}   — revoke a PAT
- DELETE /api/v1/users/me/mcp-integrations/{client_id}      — revoke an OAuth client

All require authentication via get_current_user. The POST endpoint also
enforces the yearly-subscription gate at token creation time.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.logger import get_logger
from core.supabase_client import get_supabase

router = APIRouter()
logger = get_logger(__name__)


# ────────────────────────────────────────────────────────────────────────────
# Models
# ────────────────────────────────────────────────────────────────────────────

class CreatePatRequest(BaseModel):
    """Create a new personal access token.

    `name` is user-chosen and shown in the integrations list so people can
    tell multiple connections apart ("My Laptop Claude" vs "Work ChatGPT").
    `scopes` is optional — omit for the full default scope set (Quick Setup).
    """
    name: str = Field(..., min_length=1, max_length=100)
    scopes: Optional[List[str]] = None


class CreatePatResponse(BaseModel):
    """Returned ONCE at creation. `token` plaintext never appears again."""
    token_id: str
    name: str
    scopes: List[str]
    token: str                 # fwz_pat_...
    created_at: str
    # Pre-built JSON config block the user can paste directly into Claude /
    # ChatGPT / Cursor configuration. Server constructs it so the frontend
    # doesn't need to know the MCP server URL.
    connection_config: Dict[str, Any]


# ────────────────────────────────────────────────────────────────────────────
# GET — unified list of PATs + OAuth integrations
# ────────────────────────────────────────────────────────────────────────────

@router.get("")
@router.get("/")
async def list_mcp_integrations(
    current_user: dict = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """List every active integration (both PAT and OAuth) for the caller.

    The UI renders them in a single list. Response shape is stable across
    both types; `auth_type` tells the frontend how to key revoke actions:

        [
          {
            "auth_type": "pat" | "oauth",
            "id":   "<token_id> for PAT / <client_id> for OAuth",
            "name": "My Laptop Claude" | "Claude Desktop",
            "scopes": [...],
            "created_at": "...",
            "last_used_at": "..." | null
          },
          ...
        ]
    """
    user_id = current_user["id"]
    supabase = get_supabase()
    integrations: List[Dict[str, Any]] = []

    # ─── PATs (user-generated) ────────────────────────────────────────────
    try:
        from mcp.personal_tokens import list_personal_tokens
        pats = await list_personal_tokens(user_id)
        for p in pats:
            integrations.append({
                "auth_type": "pat",
                "id": p["token_id"],
                "name": p.get("name") or "Connection",
                "scopes": p.get("scopes") or [],
                "created_at": p.get("created_at"),
                "last_used_at": p.get("last_used_at"),
            })
    except Exception as e:
        logger.error(
            f"Failed to load PATs for user={user_id}: {e}", exc_info=True
        )
        # Soft-fail so OAuth integrations still list even if PAT backend
        # errored. The UI shows an inline error banner for partial failures.

    # ─── OAuth clients (de-duped, kept for future marketplace use) ────────
    try:
        result = (
            supabase.client.table("mcp_tokens")
            .select(
                "token_id, client_id, scopes, created_at, last_used_at, "
                "mcp_oauth_clients(client_name)"
            )
            .eq("user_id", user_id)
            .is_("revoked_at", "null")
            .order("created_at", desc=True)
            .execute()
        )
        rows = result.data or []
        seen_clients: set = set()
        for row in rows:
            client_id = row.get("client_id")
            if not client_id or client_id in seen_clients:
                continue
            seen_clients.add(client_id)
            client_rel = row.get("mcp_oauth_clients")
            if isinstance(client_rel, list):
                client_rel = client_rel[0] if client_rel else None
            client_name = (client_rel or {}).get("client_name") or "Unknown Client"

            integrations.append({
                "auth_type": "oauth",
                "id": client_id,
                "name": client_name,
                "scopes": row.get("scopes") or [],
                "created_at": row.get("created_at"),
                "last_used_at": row.get("last_used_at"),
            })
    except Exception as e:
        logger.error(
            f"Failed to list OAuth integrations for user={user_id}: {e}",
            exc_info=True,
        )
        # If we already loaded PATs successfully, return what we have rather
        # than 500ing the whole list.
        if not integrations:
            raise HTTPException(
                status_code=500,
                detail="Failed to load MCP integrations. Please try again.",
            )

    # Newest first, regardless of type.
    integrations.sort(key=lambda i: i.get("created_at") or "", reverse=True)

    logger.info(
        f"MCP integrations listed for user={user_id}: "
        f"{len(integrations)} active (PAT+OAuth combined)"
    )
    return integrations


# ────────────────────────────────────────────────────────────────────────────
# POST /pat — create a new personal access token
# ────────────────────────────────────────────────────────────────────────────

@router.post("/pat", response_model=CreatePatResponse, status_code=201)
async def create_pat(
    body: CreatePatRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
) -> CreatePatResponse:
    """Mint a new PAT and return the copy-paste JSON config block.

    Enforces the yearly-subscription gate at creation time. Returning 402
    vs 403 intentionally — follows RevenueCat/Stripe convention for "pay up
    to access this".
    """
    user_id = current_user["id"]
    client_ip = request.client.host if request.client else None

    try:
        from mcp.personal_tokens import create_personal_token
        from mcp.config import get_mcp_config
    except Exception as e:
        logger.error(f"MCP subsystem unavailable: {e}", exc_info=True)
        raise HTTPException(
            status_code=503,
            detail="MCP is not available right now. Please try again later.",
        )

    cfg = get_mcp_config()

    try:
        created = await create_personal_token(
            user_id=user_id,
            name=body.name,
            scopes=body.scopes,
            created_by_ip=client_ip,
        )
    except PermissionError:
        raise HTTPException(
            status_code=402,
            detail={
                "error": "subscription_required",
                "error_description": "MCP access requires a yearly FitWiz subscription.",
                "upgrade_url": cfg.UPGRADE_URL,
            },
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to create PAT for user={user_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Failed to create connection. Please try again.",
        )

    mcp_url = f"{cfg.OAUTH_ISSUER.rstrip('/')}/mcp"
    connection_config = {
        "mcpServers": {
            "fitwiz": {
                "url": mcp_url,
                "transport": "http",
                "headers": {
                    "Authorization": f"Bearer {created['token']}",
                },
            }
        }
    }

    return CreatePatResponse(
        token_id=created["token_id"],
        name=created["name"],
        scopes=created["scopes"],
        token=created["token"],
        created_at=created["created_at"],
        connection_config=connection_config,
    )


# ────────────────────────────────────────────────────────────────────────────
# DELETE /pat/{token_id} — revoke a PAT
# ────────────────────────────────────────────────────────────────────────────

@router.delete("/pat/{token_id}")
async def revoke_pat(
    token_id: str,
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """Revoke a single PAT the caller owns. Idempotent — revoking an already
    revoked token returns `{"revoked": false}` rather than 404.
    """
    user_id = current_user["id"]
    try:
        from mcp.personal_tokens import revoke_personal_token
    except Exception as e:
        logger.error(f"MCP subsystem unavailable: {e}", exc_info=True)
        raise HTTPException(status_code=503, detail="MCP is unavailable.")

    ok = await revoke_personal_token(user_id, token_id, reason="user_revoked")
    logger.info(
        f"MCP PAT revoke: user={user_id} token_id={token_id} ok={ok}"
    )
    return {"revoked": bool(ok)}


# ────────────────────────────────────────────────────────────────────────────
# DELETE /{client_id} — revoke an OAuth client (legacy/marketplace path)
# ────────────────────────────────────────────────────────────────────────────

@router.delete("/{client_id}")
async def revoke_mcp_integration(
    client_id: str,
    current_user: dict = Depends(get_current_user),
) -> Dict[str, int]:
    """Revoke every active OAuth token for a single (user, client) pair.

    Kept for future marketplace integrations (ChatGPT Apps, Claude Connector
    store). The primary user-facing flow uses PATs + the /pat/{token_id} path.
    """
    user_id = current_user["id"]

    try:
        from mcp.subscription import revoke_client_tokens
    except Exception as e:
        logger.error(f"MCP subsystem unavailable: {e}", exc_info=True)
        raise HTTPException(status_code=503, detail="MCP is unavailable.")

    try:
        revoked = await revoke_client_tokens(
            user_id, client_id, reason="user_revoked"
        )
    except Exception as e:
        logger.error(
            f"Failed to revoke MCP client={client_id} for user={user_id}: {e}",
            exc_info=True,
        )
        raise HTTPException(
            status_code=500,
            detail="Failed to disconnect integration. Please try again.",
        )

    logger.info(
        f"MCP integration revoked: user={user_id} client={client_id} "
        f"tokens_revoked={revoked}"
    )
    return {"revoked": revoked}
