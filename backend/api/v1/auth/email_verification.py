"""Email verification — a non-blocking nudge.

Signup no longer walls on email confirmation: Supabase autoconfirm is ON, so
`signUp` returns a session immediately and the user flows straight into the app.
Verification moves here — the backend issues its own token, emails a branded
link, and tracks `users.email_verified` (migration 2083). The app stays fully
usable while unverified; an in-app banner nudges the user.

Endpoints (mounted under /api/v1/auth):
  GET  /email/verify?token=...      public — the email link target
  POST /email/resend-verification   authenticated — re-issue + resend

`issue_and_send_verification()` is the shared helper the signup endpoint and the
24h reminder cron call to mint a token and send the email.
"""
from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import HTMLResponse

from core.auth import get_verified_auth_token
from core.config import get_settings
from core.logger import get_logger
from core.rate_limiter import limiter
from core.supabase_client import get_supabase
from mcp.auth.token_service import hash_token  # reuse the keyed-SHA256 helper
from services.email_service import get_email_service

logger = get_logger(__name__)
router = APIRouter()

# A verification link is good for 48h; after that the user taps Resend.
TOKEN_TTL = timedelta(hours=48)
# Minimum gap between resends, anti-abuse / anti-email-bomb.
RESEND_COOLDOWN = timedelta(seconds=60)


def _new_token() -> tuple[str, str]:
    """Return (raw_token, token_hash). Raw lives only in the email link;
    the DB stores the hash."""
    raw = secrets.token_urlsafe(32)
    return raw, hash_token(raw)


def _first_name(name: str | None) -> str:
    return (name or "").strip().split(" ")[0] if (name or "").strip() else "there"


async def issue_and_send_verification(
    *, user_id: str, email: str, name: str | None = None
) -> None:
    """Mint a fresh verification token for [user_id], store its hash, and email
    the branded verification link. Never raises — a failed send must not break
    signup; the banner + Resend recover it.
    """
    try:
        raw, token_hash = _new_token()
        get_supabase().client.table("users").update({
            "email_verification_token_hash": token_hash,
            "email_verification_sent_at": datetime.now(timezone.utc).isoformat(),
        }).eq("id", user_id).execute()

        verify_url = (
            f"{get_settings().backend_base_url}/api/v1/auth/email/verify?token={raw}"
        )
        await get_email_service().send_verification_email(
            to_email=email,
            first_name=_first_name(name),
            verify_url=verify_url,
        )
        logger.info(f"Verification email issued for user {user_id}")
    except Exception as e:  # noqa: BLE001 — verification is best-effort
        logger.error(
            f"issue_and_send_verification failed for user {user_id}: {e}",
            exc_info=True,
        )


# ── Result pages ─────────────────────────────────────────────────────────────

def _result_page(*, heading: str, body: str, ok: bool) -> HTMLResponse:
    accent = "#16A34A" if ok else "#FC4C02"
    icon = "&#10003;" if ok else "&#9888;"
    html = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Zealova</title></head>
<body style="margin:0;background:#0b0b0b;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="min-height:100vh;">
    <tr><td align="center" style="padding:64px 20px;">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:420px;background:#141414;border:1px solid #232323;border-radius:20px;">
        <tr><td align="center" style="padding:44px 32px;">
          <div style="width:64px;height:64px;line-height:64px;border-radius:50%;background:{accent}22;color:{accent};font-size:30px;">{icon}</div>
          <h1 style="margin:24px 0 8px;font-size:22px;color:#ffffff;">{heading}</h1>
          <p style="margin:0;font-size:15px;line-height:1.6;color:#a1a1aa;">{body}</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body></html>"""
    return HTMLResponse(content=html)


# ── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/email/verify", response_class=HTMLResponse, include_in_schema=False)
async def verify_email(token: str = Query(...)) -> HTMLResponse:
    """Public target of the email link. Marks the user verified and clears the
    token. Idempotent-friendly: a second tap (hash already cleared) shows a
    calm 'no longer valid' page rather than an error."""
    token_hash = hash_token(token)
    sb = get_supabase().client
    res = (
        sb.table("users")
        .select("id, email_verified, email_verification_sent_at")
        .eq("email_verification_token_hash", token_hash)
        .limit(1)
        .execute()
    )
    rows = res.data or []
    if not rows:
        # No match: token already used/cleared, or never valid.
        return _result_page(
            heading="Link no longer valid",
            body="If you already verified your email, you are all set. "
            "Otherwise open the Zealova app and tap Resend on the banner.",
            ok=False,
        )

    user = rows[0]
    sent_at_raw = user.get("email_verification_sent_at")
    if sent_at_raw:
        try:
            sent_at = datetime.fromisoformat(str(sent_at_raw).replace("Z", "+00:00"))
            if datetime.now(timezone.utc) - sent_at > TOKEN_TTL:
                return _result_page(
                    heading="This link has expired",
                    body="Verification links last 48 hours. Open the Zealova "
                    "app and tap Resend on the banner for a fresh one.",
                    ok=False,
                )
        except (ValueError, TypeError):
            pass  # unparseable timestamp — don't block verification on it

    sb.table("users").update({
        "email_verified": True,
        "email_verification_token_hash": None,
    }).eq("id", user["id"]).execute()
    logger.info(f"Email verified for user {user['id']}")

    return _result_page(
        heading="Email verified",
        body="You are all set. You can close this tab and head back to Zealova.",
        ok=True,
    )


@router.get("/email/status", include_in_schema=False)
async def email_verification_status(
    request: Request,
    verified_token: dict = Depends(get_verified_auth_token),
) -> dict:
    """Lightweight check the app polls (on launch / resume) to decide whether
    to show the 'verify your email' banner. Avoids touching the User model /
    codegen — the banner reads this instead."""
    auth_id = verified_token.get("sub")
    if not auth_id:
        return {"verified": True}  # fail-open: never nag on an unreadable token
    res = (
        get_supabase().client.table("users")
        .select("email_verified")
        .eq("auth_id", auth_id)
        .limit(1)
        .execute()
    )
    rows = res.data or []
    # Fail-open if the row is missing — the banner is a nudge, not a gate.
    return {"verified": bool(rows[0].get("email_verified")) if rows else True}


@router.post("/email/resend-verification", include_in_schema=False)
@limiter.limit("5/minute")
async def resend_verification(
    request: Request,
    verified_token: dict = Depends(get_verified_auth_token),
) -> dict:
    """Re-issue and resend the verification email for the signed-in user.
    Rate-limited (60s cooldown server-side, plus the 5/min IP limiter)."""
    auth_id = verified_token.get("sub")
    if not auth_id:
        return {"sent": False, "reason": "no_subject"}

    sb = get_supabase().client
    res = (
        sb.table("users")
        .select("id, email, name, email_verified, email_verification_sent_at")
        .eq("auth_id", auth_id)
        .limit(1)
        .execute()
    )
    rows = res.data or []
    if not rows:
        return {"sent": False, "reason": "user_not_found"}

    user = rows[0]
    if user.get("email_verified"):
        return {"sent": False, "already_verified": True}

    # 60s cooldown — block rapid re-taps / email bombing.
    sent_at_raw = user.get("email_verification_sent_at")
    if sent_at_raw:
        try:
            sent_at = datetime.fromisoformat(str(sent_at_raw).replace("Z", "+00:00"))
            if datetime.now(timezone.utc) - sent_at < RESEND_COOLDOWN:
                return {"sent": False, "reason": "cooldown"}
        except (ValueError, TypeError):
            pass

    await issue_and_send_verification(
        user_id=user["id"], email=user["email"], name=user.get("name"),
    )
    return {"sent": True}
