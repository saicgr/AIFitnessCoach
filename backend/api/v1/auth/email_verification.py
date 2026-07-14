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
from services import email_sender
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
    # Empty (not "there") when no name — at email-signup the name isn't collected
    # yet, and send_verification_email drops the greeting rather than show a wrong
    # fallback. See email_service.send_verification_email.
    return (name or "").strip().split(" ")[0] if (name or "").strip() else ""


def _plan_from_user_row(user: dict) -> dict:
    """Best-effort onboarding-plan dict from a `public.users` row, for the recap
    card on RESEND (the signup path passes the plan from JWT metadata instead).
    Reads defensively — only includes keys whose columns exist + are populated."""
    import json

    plan: dict = {}
    goals = user.get("goals")
    if isinstance(goals, str):
        try:
            goals = json.loads(goals)
        except (ValueError, TypeError):
            goals = None
    if isinstance(goals, list) and goals:
        plan["goal"] = goals[0]
    elif user.get("primary_goal"):
        plan["goal"] = user["primary_goal"]

    if user.get("fitness_level"):
        plan["fitness_level"] = user["fitness_level"]

    days = user.get("workouts_per_week") or user.get("days_per_week")
    if days:
        plan["days_per_week"] = days

    if user.get("goal_weight_kg"):
        plan["goal_weight_kg"] = user.get("goal_weight_kg")
    if user.get("weight_direction"):
        plan["weight_direction"] = user.get("weight_direction")
    return plan


async def issue_and_send_verification(
    *, user_id: str, email: str, name: str | None = None,
    plan: dict | None = None,
) -> dict:
    """Mint a fresh verification token for [user_id], store its hash, and email
    the branded verification link. Never raises — a failed send must not break
    signup; the banner + Resend recover it.

    `plan` (optional) carries the onboarding answers (goal / experience / days /
    weight target) so the email can render a "Your plan so far" recap card.

    Returns `{"sent": bool, "reason": str | None, "id": str | None}`.

    `sent` is TRUE ONLY when Resend accepted the message and returned an id. It is
    FALSE — with a machine-readable `reason` — when `services.email_sender` BLOCKED
    the send (`undeliverable_domain` / `not_configured` / `frequency_cap`) or when
    the send errored. A blocked send is normal control flow, not an exception: it is
    how the test harnesses' `@zealova.invalid` / `@zealova-loadtest.dev` accounts
    stop generating SES bounces. Callers MUST NOT treat a `{"sent": False}` result
    as a delivered email — in particular `api/v1/email_cron.py`'s
    `email_verification_reminder` job must not write an `email_send_log` row for it,
    or the 2-day cooldown gets burned on mail that never left the building.
    """
    # Deliverability is checked BEFORE the token is minted. `email_sender` would
    # block the send anyway, but rotating `email_verification_token_hash` and
    # stamping `email_verification_sent_at` for mail that provably cannot be
    # delivered would (a) invalidate any still-valid link and (b) make the reminder
    # cron believe a nudge went out. Same policy predicate the chokepoint uses — the
    # chokepoint stays authoritative, this only keeps our DB state honest.
    if email_sender.is_undeliverable(email):
        logger.warning(
            f"Verification email NOT issued for user {user_id}: "
            f"undeliverable address {email}"
        )
        return {"sent": False, "reason": "undeliverable_domain", "id": None}

    try:
        raw, token_hash = _new_token()
        get_supabase().client.table("users").update({
            "email_verification_token_hash": token_hash,
            "email_verification_sent_at": datetime.now(timezone.utc).isoformat(),
        }).eq("id", user_id).execute()

        verify_url = (
            f"{get_settings().backend_base_url}/api/v1/auth/email/verify?token={raw}"
        )
        result = await get_email_service().send_verification_email(
            to_email=email,
            first_name=_first_name(name),
            verify_url=verify_url,
            plan=plan,
        ) or {}

        # Three possible shapes out of the email service:
        #   blocked  -> {"success": False, "skipped": True, "reason": R, "id": None}
        #   failed   -> {"error": "..."}          (Resend raised, or not configured)
        #   sent     -> {"success": True, "id": "<resend id>"}
        if result.get("skipped"):
            reason = result.get("reason") or "skipped"
            logger.warning(
                f"Verification email BLOCKED for user {user_id} ({email}): {reason}"
            )
            return {"sent": False, "reason": reason, "id": None}

        if result.get("error"):
            logger.error(
                f"Verification email failed for user {user_id}: {result['error']}"
            )
            return {"sent": False, "reason": "send_failed", "id": None}

        email_id = result.get("id")
        if not email_id:
            # Resend always returns an id on a real accept. No id and no skip marker
            # means we cannot claim delivery — report it rather than paper over it.
            logger.error(
                f"Verification email for user {user_id} returned no id "
                f"(unconfirmed send): {result!r}"
            )
            return {"sent": False, "reason": "no_id", "id": None}

        logger.info(f"Verification email issued for user {user_id}")
        return {"sent": True, "reason": None, "id": email_id}

    except Exception as e:  # noqa: BLE001 — verification is best-effort
        logger.error(
            f"issue_and_send_verification failed for user {user_id}: {e}",
            exc_info=True,
        )
        return {"sent": False, "reason": "exception", "id": None}


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
    # select("*") avoids schema-drift 500s and lets us read whatever onboarding
    # columns exist to rebuild the plan recap (the row is populated by resend time).
    res = (
        sb.table("users")
        .select("*")
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

    result = await issue_and_send_verification(
        user_id=user["id"], email=user["email"], name=user.get("name"),
        plan=_plan_from_user_row(user),
    )
    # Report the truth. A send blocked by `services.email_sender` (undeliverable
    # address, Resend not configured) is NOT a delivered email, so it must not come
    # back as {"sent": true} — the app would tell the user "check your inbox" for
    # mail that was never sent. It is also NOT a 500: blocking is normal control
    # flow, and this endpoint is exactly the path the injury/loadtest harnesses
    # hammer with @zealova.invalid accounts.
    if not result.get("sent"):
        return {"sent": False, "reason": result.get("reason") or "send_failed"}
    return {"sent": True}
