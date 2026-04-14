"""
Resend webhook endpoint — receives delivery / bounce / complaint events.

Wiring:
  POST /api/v1/email-webhooks/resend
  Header: `svix-signature` (Resend uses Svix for signing)

On `email.bounced` (hard bounce) the user's `email_preferences.deliverable`
is flipped to FALSE after 3 total hard bounces. On `email.complained` (user
hit the spam button) we immediately turn off all marketing categories but
leave billing alerts on (legally required).

Raw event payloads are also written back into `email_send_log` so we can
audit deliverability per email type.
"""
import hmac
import json
from datetime import datetime, timezone
from typing import Optional, Dict, Any

from fastapi import APIRouter, Header, HTTPException, Request
from fastapi.responses import JSONResponse

from core.supabase_client import get_supabase
from core.config import get_settings
from core.logger import get_logger
from core.rate_limiter import limiter

logger = get_logger(__name__)
router = APIRouter()

# Events we handle. Anything else we log and 200 so Resend doesn't retry.
HANDLED_EVENTS = {
    "email.sent",
    "email.delivered",
    "email.delivery_delayed",
    "email.bounced",
    "email.complained",
    "email.opened",
    "email.clicked",
}


@router.post("/email-webhooks/resend")
@limiter.limit("60/minute")
async def resend_webhook(
    request: Request,
    svix_signature: Optional[str] = Header(None, alias="svix-signature"),
    svix_id: Optional[str] = Header(None, alias="svix-id"),
    svix_timestamp: Optional[str] = Header(None, alias="svix-timestamp"),
):
    """Handle a Resend webhook event.

    Signature verification uses Svix's HMAC scheme: `v1,<base64(hmac_sha256(body))>`.
    Production MUST have RESEND_WEBHOOK_SECRET set; dev can leave it unset
    (we skip signature check and log a warning).
    """
    settings = get_settings()
    body = await request.body()

    secret = getattr(settings, "resend_webhook_secret", None) or None
    if secret:
        ok = _verify_svix_signature(body, svix_signature, svix_id, svix_timestamp, secret)
        if not ok:
            logger.warning("[email-webhook] signature verification failed")
            raise HTTPException(status_code=401, detail="Invalid signature")
    else:
        logger.warning("[email-webhook] RESEND_WEBHOOK_SECRET not set — skipping sig check (DEV ONLY)")

    try:
        payload = json.loads(body)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    event_type = payload.get("type", "")
    data = payload.get("data", {}) or {}
    email_id = data.get("email_id") or data.get("id")
    if not email_id:
        logger.info(f"[email-webhook] {event_type} event without email_id — ignoring")
        return {"ok": True, "ignored": True}

    if event_type not in HANDLED_EVENTS:
        logger.info(f"[email-webhook] unhandled event type: {event_type}")
        return {"ok": True, "ignored": True}

    supabase = get_supabase()

    # Find the send log row for this email_id. If we don't have a record,
    # the event is still worth logging but we can't flip prefs with confidence.
    send_log_rows = supabase.client.table("email_send_log") \
        .select("id, user_id, email_type, status") \
        .eq("resend_email_id", email_id) \
        .limit(1) \
        .execute()
    row = (send_log_rows.data or [None])[0]

    now_iso = datetime.now(timezone.utc).isoformat()
    update: Dict[str, Any] = {}

    if event_type == "email.delivered":
        update = {"status": "delivered", "delivered_at": now_iso}
    elif event_type == "email.bounced":
        update = {"status": "bounced", "bounced_at": now_iso}
    elif event_type == "email.complained":
        update = {"status": "complained", "complained_at": now_iso}

    if row and update:
        supabase.client.table("email_send_log") \
            .update(update) \
            .eq("id", row["id"]) \
            .execute()

    # User-level actions on bounce / complaint
    if row and event_type == "email.bounced":
        _handle_hard_bounce(supabase, row["user_id"])
    elif row and event_type == "email.complained":
        _handle_complaint(supabase, row["user_id"])

    return {"ok": True, "event": event_type, "email_id": email_id}


def _verify_svix_signature(
    body: bytes,
    svix_signature: Optional[str],
    svix_id: Optional[str],
    svix_timestamp: Optional[str],
    secret: str,
) -> bool:
    """Verify a Svix-signed webhook. Returns True if any signature in the
    header matches our computed one.

    See: https://docs.svix.com/receiving/verifying-payloads/how-manual
    Secret format: `whsec_<base64>`. We strip the prefix before HMAC.
    """
    import base64
    import hashlib
    if not (svix_signature and svix_id and svix_timestamp):
        return False
    try:
        if secret.startswith("whsec_"):
            raw_secret = base64.b64decode(secret[len("whsec_"):])
        else:
            raw_secret = secret.encode()
        signed_content = f"{svix_id}.{svix_timestamp}.".encode() + body
        expected = base64.b64encode(
            hmac.new(raw_secret, signed_content, hashlib.sha256).digest()
        ).decode()
        # Header may include multiple comma-sep signatures: "v1,sig v1,sig2"
        for part in svix_signature.split():
            if "," not in part:
                continue
            _version, sig = part.split(",", 1)
            if hmac.compare_digest(sig, expected):
                return True
    except Exception as e:
        logger.warning(f"[email-webhook] signature check error: {e}")
    return False


def _handle_hard_bounce(supabase, user_id: str) -> None:
    """After 3 bounces total, mark user as non-deliverable so the cron
    stops sending to the address."""
    try:
        bounces = supabase.client.table("email_send_log") \
            .select("id") \
            .eq("user_id", user_id) \
            .eq("status", "bounced") \
            .execute()
        if bounces.data and len(bounces.data) >= 3:
            supabase.client.table("email_preferences") \
                .update({"deliverable": False}) \
                .eq("user_id", user_id) \
                .execute()
            logger.warning(f"[email-webhook] user {user_id} marked non-deliverable after 3 bounces")
    except Exception as e:
        logger.error(f"[email-webhook] bounce handler failed: {e}", exc_info=True)


def _handle_complaint(supabase, user_id: str) -> None:
    """User hit 'spam' — turn off all marketing categories immediately.
    Leave billing / account categories alone (legally required)."""
    try:
        supabase.client.table("email_preferences").update({
            "weekly_summary": False,
            "promotional": False,
            "motivational_nudges": False,
            "achievement_alerts": False,
            "streak_alerts": False,
            "product_updates": False,
            "coach_tips": False,
            # Intentionally not touched: billing_account, deliverable, workout_reminders
        }).eq("user_id", user_id).execute()
        logger.warning(f"[email-webhook] user {user_id} marketing disabled after complaint")
    except Exception as e:
        logger.error(f"[email-webhook] complaint handler failed: {e}", exc_info=True)
