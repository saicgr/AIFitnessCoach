"""FastAPI router that serves the OAuth consent UI for the Zealova MCP server.

We embed the consent UI directly in the backend (instead of a separate Vercel
front-end at zealova.com) to simplify v1: one deploy target, no cross-origin
concerns, and the page can talk directly to ``/mcp/oauth/authorize/complete``.
The URL shape (``/mcp/consent/authorize?consent=<signed_token>``) is the only
external contract, so migrating to a standalone Vercel app later is a drop-in.

Routes (all under ``/mcp/consent``):
    GET  /authorize     — the consent HTML page itself.
    GET  /success       — post-approval landing page ("return to Claude").
    GET  /upgrade       — shown when the user lacks a yearly subscription.

The page uses vanilla JS (no framework) and hits two existing endpoints:
    GET  /mcp/oauth/authorize/peek            — to render client + scopes.
    POST /mcp/oauth/authorize/complete        — to approve and redirect back.
"""
from __future__ import annotations

import os
from typing import Optional

from fastapi import APIRouter, Query, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

from core import branding
from core.config import get_settings
from core.logger import get_logger
from mcp.config import get_mcp_config

logger = get_logger(__name__)
_cfg = get_mcp_config()
_settings = get_settings()

router = APIRouter(prefix="/mcp/consent", tags=["mcp-consent"])

# Resolve paths relative to this file so imports work regardless of cwd
# (Render starts uvicorn from /opt/render/project/src/backend, local dev
# typically from backend/, Lambda from /var/task — handle all three).
_HERE = os.path.dirname(os.path.abspath(__file__))
_TEMPLATES_DIR = os.path.join(_HERE, "templates")

# Public — main.py mounts this directly on the app (see NOTE below).
STATIC_DIR = os.path.join(_HERE, "static")

templates = Jinja2Templates(directory=_TEMPLATES_DIR)

# Inject brand identity into Jinja env globals so consent templates can use
# {{ APP_NAME }} / {{ MARKETING_DOMAIN }} / {{ WEBSITE_URL }} without each
# render call passing them. Single source of truth in core/branding.py.
templates.env.globals.update({
    "APP_NAME": branding.APP_NAME,
    "APP_FULL_TITLE": branding.APP_FULL_TITLE,
    "WEBSITE_URL": branding.WEBSITE_URL,
    "MARKETING_DOMAIN": branding.MARKETING_DOMAIN,
    "SUPPORT_EMAIL": branding.SUPPORT_EMAIL,
})

# Serve consent-specific CSS/JS assets at /mcp/consent/static/*.
#
# NOTE: this is NOT mounted here via `router.mount()`. FastAPI's
# `app.include_router()` only migrates `APIRoute` (and websocket route)
# entries from a child router onto the parent app — a bare Starlette `Mount`
# added directly to an `APIRouter` is silently dropped in that process, never
# actually reaching the app's route table. (Confirmed: after
# `app.include_router(mcp_consent_router)`, no mount for this path exists in
# `app.routes` at all — 100% 404 on every static asset, in every environment,
# not a deploy-specific path issue.) `main.py` mounts `STATIC_DIR` directly on
# `app` instead, right after including this router.


# ─── GET /mcp/consent/authorize ──────────────────────────────────────────────

@router.get("/authorize", response_class=HTMLResponse)
async def consent_authorize(
    request: Request,
    consent: Optional[str] = Query(
        None,
        description="Signed consent-session token issued by /mcp/oauth/authorize.",
    ),
) -> HTMLResponse:
    """Render the OAuth consent page.

    The page is mostly inert server-side — all dynamic data (client name,
    requested scopes) is fetched client-side via ``/mcp/oauth/authorize/peek``.
    We render with ``consent`` and a handful of backend URLs so the JS knows
    where to POST the approval.

    Edge cases handled by the template JS:
      - Missing ``consent`` query param → show an error banner.
      - Expired / invalid token → ``peek`` returns 400, JS surfaces the error.
      - 402 from ``/complete`` (no yearly sub) → redirect to /upgrade.
      - User unchecks all scopes → Approve button disabled.
    """
    # Build the absolute issuer URL once so the template can use it for both
    # peek + complete calls. We prefer OAUTH_ISSUER over request.url because
    # the OAuth metadata endpoint advertises OAUTH_ISSUER as canonical —
    # keeping the consent page consistent avoids cookie / origin surprises.
    issuer = _cfg.OAUTH_ISSUER.rstrip("/")
    return templates.TemplateResponse(
        "authorize.html",
        {
            "request": request,
            "consent": consent or "",
            "issuer": issuer,
            "peek_url": f"{issuer}/mcp/oauth/authorize/peek",
            "complete_url": f"{issuer}/mcp/oauth/authorize/complete",
            "upgrade_path": "/mcp/consent/upgrade",
            "upgrade_url": _cfg.UPGRADE_URL,
            # Browser-side Supabase Auth context. Anon key is public and safe
            # to expose. When unset, the page falls back to the legacy
            # paste-token UI so the OAuth flow still works during initial
            # rollout before the env var is configured in Render.
            "supabase_url": _settings.supabase_url,
            "supabase_anon_key": _settings.supabase_anon_key or "",
        },
    )


# ─── GET /mcp/consent/success ────────────────────────────────────────────────

@router.get("/success", response_class=HTMLResponse)
async def consent_success(request: Request) -> HTMLResponse:
    """Post-approval landing. Normally users never see this (the MCP client's
    redirect_uri handles the code exchange), but it's a safe fallback if the
    browser lands here for any reason (e.g. redirect_uri was localhost and
    the user closed the client)."""
    return templates.TemplateResponse("success.html", {"request": request})


# ─── GET /mcp/consent/upgrade ────────────────────────────────────────────────

@router.get("/upgrade", response_class=HTMLResponse)
async def consent_upgrade(
    request: Request,
    reason: Optional[str] = Query(None),
    consent: Optional[str] = Query(
        None,
        description="Same signed consent-session token as /authorize, forwarded "
                    "here on a 402 so 'Not now' can redirect back to the client "
                    "instead of relying on window.close().",
    ),
) -> HTMLResponse:
    """Shown when a user tries to authorize but is not on a yearly plan.

    Links to ``MCPConfig.UPGRADE_URL`` (the zealova.com checkout page).
    """
    from mcp.auth import consent_session as _consent_session

    redirect_uri = ""
    state = ""
    if consent:
        payload = _consent_session.decode(consent)
        if payload:
            redirect_uri = payload.get("redirect_uri") or ""
            state = payload.get("state") or ""

    return templates.TemplateResponse(
        "upgrade.html",
        {
            "request": request,
            "upgrade_url": _cfg.UPGRADE_URL,
            "reason": reason or "",
            "redirect_uri": redirect_uri,
            "state": state,
        },
    )


# ─── Convenience redirect: /mcp/consent → /mcp/consent/authorize ─────────────

@router.get("", include_in_schema=False)
@router.get("/", include_in_schema=False)
async def consent_root(consent: Optional[str] = Query(None)) -> RedirectResponse:
    """Friendly redirect for people who land on the bare /mcp/consent URL."""
    target = "/mcp/consent/authorize"
    if consent:
        # Preserve the signed token if provided.
        from urllib.parse import urlencode
        target = f"{target}?{urlencode({'consent': consent})}"
    return RedirectResponse(url=target, status_code=307)
