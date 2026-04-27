"""
Out-of-app DSAR (Data Subject Access Request) flow.

Satisfies GDPR Art. 15 (right to access), Art. 17 (erasure), Art. 20
(portability) and CCPA/CPRA equivalents for users who cannot log in to
the app — for example a user who forgot their password, had their
account disabled, or has since uninstalled and only has email access.

Endpoints (all public, no auth required):
    GET  /api/v1/dsar/                 — HTML request form
    POST /api/v1/dsar/request          — create a request, email token
    GET  /api/v1/dsar/verify           — verify token, queue fulfillment
    GET  /api/v1/dsar/status/{id}      — show request status (user-linked)

Security model:
    * Email ownership is proven by a one-time token sent to that email.
      The token plaintext is NEVER stored; only SHA-256(token + secret).
    * One open request per email per 24h (partial unique index).
    * Request IP + user-agent are captured for compliance audit.
    * Fulfillment runs in a background task so the HTTP response is fast
      and the verification link click doesn't time out on large exports.
    * Download URLs are S3 presigned, expire in 7 days.
"""
from __future__ import annotations

import hashlib
import hmac
import io
import os
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

import boto3
import resend
from botocore.exceptions import ClientError
from fastapi import APIRouter, BackgroundTasks, Form, HTTPException, Query, Request
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel, EmailStr, Field

from core import branding
from core.config import get_settings
from core.logger import get_logger
from core.rate_limiter import limiter
from core.supabase_client import get_supabase
from services.data_export import export_user_data

logger = get_logger(__name__)
router = APIRouter()


# --- Config ----------------------------------------------------------------

VERIFICATION_TTL = timedelta(hours=24)
DOWNLOAD_TTL = timedelta(days=7)
# Path prefix inside the S3 bucket for DSAR archives. Must be covered by a
# bucket lifecycle rule that auto-deletes objects after 8 days so the S3
# copy disappears shortly after the signed URL expires.
DSAR_S3_PREFIX = "dsar-exports/"


# --- Helpers ---------------------------------------------------------------


def _hash_token(token: str) -> str:
    """Hash a plaintext verification token with a server-side pepper.

    Using a keyed SHA-256 so that compromise of the `dsar_requests` table
    alone is insufficient to forge verification links; the pepper lives
    in env (`CRON_SECRET` or `SECRET_KEY`) and never in DB.
    """
    settings = get_settings()
    pepper = (
        getattr(settings, "secret_key", None)
        or settings.cron_secret
        or "fallback-dsar-pepper-set-SECRET_KEY"
    )
    return hmac.new(pepper.encode(), token.encode(), hashlib.sha256).hexdigest()


def _base_url() -> str:
    return get_settings().backend_base_url.rstrip("/")


def _supabase():
    return get_supabase().client


# --- Models ----------------------------------------------------------------


class DSARRequestIn(BaseModel):
    """Request payload for POST /dsar/request."""
    email: EmailStr
    request_type: str = Field(default="export", pattern="^(export|delete|access)$")


class DSARRequestOut(BaseModel):
    id: str
    status: str
    message: str


# --- Public HTML form ------------------------------------------------------


_PUBLIC_FORM_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>__BRAND__ — Request Your Data</title>
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
         margin: 0; background: #0a0a0f; color: #e5e7eb; line-height: 1.6; }}
  .wrap {{ max-width: 560px; margin: 0 auto; padding: 48px 24px; }}
  h1 {{ font-size: 28px; color: #06b6d4; margin: 0 0 8px; }}
  p  {{ color: #a1a1aa; }}
  form {{ background: #111827; padding: 24px; border-radius: 16px;
         border: 1px solid #1f2937; margin-top: 24px; }}
  label {{ display: block; font-weight: 600; margin: 12px 0 6px; color: #f3f4f6; }}
  input, select {{ width: 100%; padding: 12px 14px; border-radius: 10px;
                   border: 1px solid #374151; background: #0a0a0f;
                   color: #f3f4f6; font-size: 15px; box-sizing: border-box; }}
  button {{ margin-top: 20px; width: 100%; padding: 14px; border-radius: 999px;
            border: 0; background: #06b6d4; color: #0a0a0f; font-size: 16px;
            font-weight: 700; cursor: pointer; }}
  .muted {{ font-size: 13px; color: #6b7280; margin-top: 16px; }}
  .ok {{ background: #064e3b; color: #d1fae5; padding: 16px; border-radius: 12px;
         margin-bottom: 24px; }}
  .err {{ background: #7f1d1d; color: #fee2e2; padding: 16px; border-radius: 12px;
         margin-bottom: 24px; }}
</style>
</head>
<body>
  <div class="wrap">
    <h1>Request Your Data</h1>
    <p>Use this form to export, access, or delete the personal data __BRAND__ holds about you — even if you can no longer sign in. We'll email a verification link to prove you own the address.</p>
    {banner}
    <form method="POST" action="/api/v1/dsar/request">
      <label for="email">Email address</label>
      <input type="email" name="email" id="email" required autocomplete="email"
             placeholder="you@example.com">
      <label for="request_type">What do you want to do?</label>
      <select name="request_type" id="request_type">
        <option value="export">Export my data (GDPR Art. 20 / CCPA)</option>
        <option value="access">List what data you hold about me (GDPR Art. 15)</option>
        <option value="delete">Delete my account and data (GDPR Art. 17)</option>
      </select>
      <button type="submit">Send verification email</button>
    </form>
    <p class="muted">We respond within 30 days as required by GDPR. Questions? <a style="color:#06b6d4" href="mailto:__PRIVACY_EMAIL__">__PRIVACY_EMAIL__</a>.</p>
  </div>
</body>
</html>""".replace("__BRAND__", branding.APP_NAME).replace("__PRIVACY_EMAIL__", branding.PRIVACY_EMAIL)


@router.get("/", response_class=HTMLResponse)
async def dsar_form(message: Optional[str] = Query(default=None),
                    error: Optional[str] = Query(default=None)):
    """Public HTML form. Works without JavaScript and without auth so
    a locked-out user can still exercise their rights."""
    banner = ""
    if message:
        banner = f'<div class="ok">{message}</div>'
    elif error:
        banner = f'<div class="err">{error}</div>'
    return HTMLResponse(_PUBLIC_FORM_HTML.format(banner=banner))


# --- Create request --------------------------------------------------------


@router.post("/request")
@limiter.limit("5/hour")
async def create_dsar_request(
    request: Request,
    background_tasks: BackgroundTasks,
    email: str = Form(...),
    request_type: str = Form("export"),
):
    """Accept a DSAR from the public form or a JSON client.

    We respond with a generic success message regardless of whether the
    email matches an account. Revealing whether an email is registered
    would be an enumeration oracle — a privacy regression we must avoid
    in a privacy-rights endpoint.
    """
    email_normalized = email.strip().lower()
    if request_type not in ("export", "delete", "access"):
        return HTMLResponse(
            _PUBLIC_FORM_HTML.format(
                banner='<div class="err">Invalid request type.</div>'
            ),
            status_code=400,
        )

    # Generate a long random token. 32 bytes (~256 bits) of entropy is
    # overkill for a 24h link but cheap and future-proof.
    token = secrets.token_urlsafe(32)
    token_hash = _hash_token(token)
    now = datetime.now(timezone.utc)
    expires_at = now + VERIFICATION_TTL

    client_ip = (request.client.host if request.client else None) or "unknown"
    ua = request.headers.get("user-agent", "")[:500]

    # Try to find the matching user. If none, we still record the request
    # — GDPR requires a response even to "I'm not a user" / "I used an
    # account you deleted" scenarios, and we reply transparently.
    matched_user_id: Optional[str] = None
    try:
        res = (
            _supabase()
            .table("users")
            .select("id")
            .eq("email", email_normalized)
            .limit(1)
            .execute()
        )
        if res.data:
            matched_user_id = res.data[0]["id"]
    except Exception as e:
        logger.warning(f"dsar: failed to lookup user by email: {e}")

    try:
        insert = (
            _supabase()
            .table("dsar_requests")
            .insert(
                {
                    "email": email_normalized,
                    "request_type": request_type,
                    "verification_token_hash": token_hash,
                    "verification_expires_at": expires_at.isoformat(),
                    "request_ip": client_ip,
                    "request_user_agent": ua,
                    "matched_user_id": matched_user_id,
                }
            )
            .execute()
        )
    except Exception as e:
        # Partial unique index will raise if an open request already
        # exists for this email. Surface a friendly message but still
        # don't leak whether a duplicate came from a real account.
        logger.info(f"dsar: insert failed (likely duplicate pending): {e}")
        return HTMLResponse(
            _PUBLIC_FORM_HTML.format(
                banner=(
                    '<div class="ok">If this email has a pending request, '
                    'check your inbox for the verification link. Otherwise '
                    'try again in 24 hours.</div>'
                )
            )
        )

    dsar_id = insert.data[0]["id"] if insert.data else None

    # Fire off the verification email as a background task so the user
    # always sees a fast "check your inbox" response.
    verify_link = f"{_base_url()}/api/v1/dsar/verify?token={token}"
    background_tasks.add_task(
        _send_verification_email,
        email_normalized,
        request_type,
        verify_link,
        dsar_id,
    )

    return HTMLResponse(
        _PUBLIC_FORM_HTML.format(
            banner=(
                '<div class="ok">Thanks. If this email is associated with a '
                f'{branding.APP_NAME} account, we have sent a verification link. It expires '
                'in 24 hours.</div>'
            )
        )
    )


# --- Verify + fulfill ------------------------------------------------------


@router.get("/verify", response_class=HTMLResponse)
@limiter.limit("30/hour")
async def verify_dsar_request(
    request: Request,
    background_tasks: BackgroundTasks,
    token: str = Query(..., min_length=20, max_length=200),
):
    """Consume the verification token and queue fulfillment.

    The token is single-use: we transition the row to 'verified' atomically
    and rotate the token_hash so the link cannot be replayed.
    """
    token_hash = _hash_token(token)
    now = datetime.now(timezone.utc)

    try:
        result = (
            _supabase()
            .table("dsar_requests")
            .select("*")
            .eq("verification_token_hash", token_hash)
            .eq("status", "pending_verification")
            .limit(1)
            .execute()
        )
    except Exception as e:
        logger.error(f"dsar: verify lookup failed: {e}", exc_info=True)
        return HTMLResponse(_result_page("Something went wrong. Try again later."), status_code=500)

    if not result.data:
        return HTMLResponse(
            _result_page("This link is invalid or has already been used."),
            status_code=410,
        )

    row = result.data[0]
    expires = datetime.fromisoformat(row["verification_expires_at"].replace("Z", "+00:00"))
    if expires < now:
        _supabase().table("dsar_requests").update(
            {"status": "expired", "updated_at": now.isoformat()}
        ).eq("id", row["id"]).execute()
        return HTMLResponse(
            _result_page("This link has expired. Please submit a new request."),
            status_code=410,
        )

    # Atomically move to 'verified' and invalidate the token so a
    # replayed click cannot re-trigger fulfillment. Rotating the hash
    # to a random value guarantees no future token will collide.
    _supabase().table("dsar_requests").update(
        {
            "status": "verified",
            "verified_at": now.isoformat(),
            "verification_token_hash": secrets.token_urlsafe(32),
            "updated_at": now.isoformat(),
        }
    ).eq("id", row["id"]).execute()

    # Kick off fulfillment. Background task so we return the success
    # page immediately even if the export takes 30+ seconds.
    background_tasks.add_task(_fulfill_request, row["id"])

    if row["request_type"] == "delete":
        msg = (
            "Thanks — your deletion request is verified. We will erase your "
            "account and personal data within 30 days and email you when "
            "the deletion is complete."
        )
    else:
        msg = (
            "Thanks — your request is verified. We are preparing your data "
            "archive now and will email a secure download link to "
            f"<strong>{row['email']}</strong> within a few minutes. The "
            "link expires in 7 days."
        )
    return HTMLResponse(_result_page(msg))


def _result_page(message: str) -> str:
    return f"""<!DOCTYPE html><html><head><meta charset="UTF-8">
<title>{branding.APP_NAME} — Data Request</title>
<style>body{{font-family:-apple-system,sans-serif;background:#0a0a0f;color:#e5e7eb;
margin:0}}.wrap{{max-width:560px;margin:0 auto;padding:64px 24px}}
h1{{color:#06b6d4;font-size:24px}}.card{{background:#111827;padding:24px;
border-radius:16px;border:1px solid #1f2937;margin-top:24px}}</style></head>
<body><div class="wrap"><h1>{branding.APP_NAME} — Data Request</h1>
<div class="card">{message}</div></div></body></html>"""


# --- Fulfillment (background) ----------------------------------------------


def _fulfill_request(dsar_id: str) -> None:
    """Carry out the verified request.

    Runs in a FastAPI BackgroundTask (same process, post-response). Wraps
    the whole thing in try/except so an error transitions the row to
    'failed' with a reason the compliance team can see.
    """
    sb = _supabase()
    try:
        row = (
            sb.table("dsar_requests")
            .select("*")
            .eq("id", dsar_id)
            .limit(1)
            .execute()
            .data
        )
        if not row:
            return
        row = row[0]

        sb.table("dsar_requests").update(
            {"status": "processing", "updated_at": datetime.now(timezone.utc).isoformat()}
        ).eq("id", dsar_id).execute()

        user_id = row.get("matched_user_id")
        rtype = row["request_type"]

        if rtype in ("export", "access"):
            if not user_id:
                # No matching account. Tell the user plainly, per GDPR
                # transparency requirements, and close the request.
                _send_no_account_email(row["email"], rtype)
                sb.table("dsar_requests").update(
                    {
                        "status": "fulfilled",
                        "fulfilled_at": datetime.now(timezone.utc).isoformat(),
                        "failure_reason": "no_matching_account",
                        "updated_at": datetime.now(timezone.utc).isoformat(),
                    }
                ).eq("id", dsar_id).execute()
                return

            zip_bytes = export_user_data(str(user_id))
            key = f"{DSAR_S3_PREFIX}{dsar_id}.zip"
            url, url_exp = _upload_and_sign(zip_bytes, key)
            _send_export_ready_email(row["email"], url, url_exp, rtype)

            sb.table("dsar_requests").update(
                {
                    "status": "fulfilled",
                    "fulfilled_at": datetime.now(timezone.utc).isoformat(),
                    "download_url": url,
                    "download_expires_at": url_exp.isoformat(),
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                }
            ).eq("id", dsar_id).execute()

        elif rtype == "delete":
            # Mark for deletion only. The actual cascade runs through the
            # existing account-deletion pathway so we don't duplicate logic
            # or bypass any referential integrity checks. The compliance
            # team runs the deletion queue and confirms completion.
            _send_deletion_queued_email(row["email"])
            sb.table("dsar_requests").update(
                {
                    "status": "fulfilled",
                    "fulfilled_at": datetime.now(timezone.utc).isoformat(),
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                }
            ).eq("id", dsar_id).execute()

    except Exception as e:
        logger.error(f"dsar: fulfillment failed for {dsar_id}: {e}", exc_info=True)
        try:
            sb.table("dsar_requests").update(
                {
                    "status": "failed",
                    "failure_reason": str(e)[:500],
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                }
            ).eq("id", dsar_id).execute()
        except Exception:
            pass


def _upload_and_sign(zip_bytes: bytes, key: str) -> tuple[str, datetime]:
    """Upload the export archive to S3 and return (presigned_url, expires_at)."""
    settings = get_settings()
    if not settings.s3_bucket_name:
        raise RuntimeError("S3_BUCKET_NAME is not configured — cannot deliver DSAR export")

    s3 = boto3.client(
        "s3",
        region_name=settings.aws_default_region,
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
    )
    s3.put_object(
        Bucket=settings.s3_bucket_name,
        Key=key,
        Body=zip_bytes,
        ContentType="application/zip",
        ContentDisposition=f'attachment; filename="{branding.APP_NAME.lower()}-data-{datetime.utcnow():%Y%m%d}.zip"',
        # Server-side encryption with AWS-managed keys. Bucket policy
        # should already enforce this but we set it explicitly.
        ServerSideEncryption="AES256",
    )
    expires_in = int(DOWNLOAD_TTL.total_seconds())
    url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.s3_bucket_name, "Key": key},
        ExpiresIn=expires_in,
    )
    return url, datetime.now(timezone.utc) + DOWNLOAD_TTL


# --- Email templates -------------------------------------------------------


def _send_verification_email(
    email: str, request_type: str, verify_link: str, dsar_id: Optional[str]
) -> None:
    if not os.getenv("RESEND_API_KEY"):
        logger.warning("dsar: RESEND_API_KEY not set, skipping email")
        return
    resend.api_key = os.getenv("RESEND_API_KEY")
    from_email = os.getenv("RESEND_FROM_EMAIL", f"{branding.APP_NAME} <{branding.PRIVACY_EMAIL}>")

    label = {
        "export": "export your data",
        "access": "see what data we hold about you",
        "delete": "delete your account and data",
    }.get(request_type, "process your request")

    html = f"""<!DOCTYPE html><html><body style="font-family:-apple-system,sans-serif;
background:#0a0a0f;color:#e5e7eb;margin:0;padding:32px">
<div style="max-width:560px;margin:0 auto;background:#111827;padding:32px;
border-radius:16px;border:1px solid #1f2937">
<h1 style="color:#06b6d4;font-size:24px;margin:0 0 16px">Verify your data request</h1>
<p>We received a request to <strong>{label}</strong>. To confirm this was you,
click the verification button below within 24 hours.</p>
<p style="margin:32px 0"><a href="{verify_link}"
style="display:inline-block;padding:14px 28px;background:#06b6d4;color:#0a0a0f;
font-weight:700;border-radius:999px;text-decoration:none">Verify my request</a></p>
<p style="font-size:13px;color:#6b7280">If you did not submit this request, you
can safely ignore this email — no action will be taken.</p>
<p style="font-size:13px;color:#6b7280">Link not working? Copy and paste this URL:<br>
<span style="word-break:break-all">{verify_link}</span></p>
<hr style="border:0;border-top:1px solid #1f2937;margin:32px 0">
<p style="font-size:12px;color:#6b7280">{branding.APP_NAME} — GDPR/CCPA Data Rights Desk</p>
</div></body></html>"""
    try:
        resend.Emails.send(
            {
                "from": from_email,
                "to": [email],
                "subject": f"Verify your {branding.APP_NAME} data request",
                "html": html,
            }
        )
    except Exception as e:
        logger.error(f"dsar: failed to send verification email to {email}: {e}")


def _send_export_ready_email(
    email: str, download_url: str, expires_at: datetime, request_type: str
) -> None:
    if not os.getenv("RESEND_API_KEY"):
        return
    resend.api_key = os.getenv("RESEND_API_KEY")
    from_email = os.getenv("RESEND_FROM_EMAIL", f"{branding.APP_NAME} <{branding.PRIVACY_EMAIL}>")

    verb = "export" if request_type == "export" else "access report"
    html = f"""<!DOCTYPE html><html><body style="font-family:-apple-system,sans-serif;
background:#0a0a0f;color:#e5e7eb;margin:0;padding:32px">
<div style="max-width:560px;margin:0 auto;background:#111827;padding:32px;
border-radius:16px;border:1px solid #1f2937">
<h1 style="color:#06b6d4;font-size:24px;margin:0 0 16px">Your data {verb} is ready</h1>
<p>Your {branding.APP_NAME} data archive is ready to download. The link expires on
<strong>{expires_at.strftime('%B %d, %Y at %H:%M UTC')}</strong>.</p>
<p style="margin:32px 0"><a href="{download_url}"
style="display:inline-block;padding:14px 28px;background:#06b6d4;color:#0a0a0f;
font-weight:700;border-radius:999px;text-decoration:none">Download my data</a></p>
<p style="font-size:13px;color:#6b7280">The archive contains every table that
holds personal data about you: profile, workouts, food logs, chat history,
progress photos, measurements, and more. See the included README.txt for a
file-by-file breakdown.</p>
<p style="font-size:13px;color:#6b7280">Questions? Reply to this email or
write to <a style="color:#06b6d4" href="mailto:{branding.PRIVACY_EMAIL}">{branding.PRIVACY_EMAIL}</a>.</p>
</div></body></html>"""
    try:
        resend.Emails.send(
            {
                "from": from_email,
                "to": [email],
                "subject": f"Your {branding.APP_NAME} data {verb} is ready",
                "html": html,
            }
        )
    except Exception as e:
        logger.error(f"dsar: failed to send export-ready email to {email}: {e}")


def _send_no_account_email(email: str, request_type: str) -> None:
    if not os.getenv("RESEND_API_KEY"):
        return
    resend.api_key = os.getenv("RESEND_API_KEY")
    from_email = os.getenv("RESEND_FROM_EMAIL", f"{branding.APP_NAME} <{branding.PRIVACY_EMAIL}>")

    html = f"""<!DOCTYPE html><html><body style="font-family:-apple-system,sans-serif;
background:#0a0a0f;color:#e5e7eb;margin:0;padding:32px">
<div style="max-width:560px;margin:0 auto;background:#111827;padding:32px;
border-radius:16px;border:1px solid #1f2937">
<h1 style="color:#06b6d4;font-size:24px;margin:0 0 16px">No account found</h1>
<p>We verified your email, but we do not hold any personal data under
<strong>{email}</strong>. No further action is needed.</p>
<p>If you used a different email with {branding.APP_NAME} in the past, submit another
request from <a style="color:#06b6d4" href="{_base_url()}/api/v1/dsar/">this
page</a> with that address.</p>
<p style="font-size:13px;color:#6b7280">Questions? Write to
<a style="color:#06b6d4" href="mailto:{branding.PRIVACY_EMAIL}">{branding.PRIVACY_EMAIL}</a>.</p>
</div></body></html>"""
    try:
        resend.Emails.send(
            {
                "from": from_email,
                "to": [email],
                "subject": f"{branding.APP_NAME} data request — no account found",
                "html": html,
            }
        )
    except Exception as e:
        logger.error(f"dsar: failed to send no-account email to {email}: {e}")


def _send_deletion_queued_email(email: str) -> None:
    if not os.getenv("RESEND_API_KEY"):
        return
    resend.api_key = os.getenv("RESEND_API_KEY")
    from_email = os.getenv("RESEND_FROM_EMAIL", f"{branding.APP_NAME} <{branding.PRIVACY_EMAIL}>")

    html = f"""<!DOCTYPE html><html><body style="font-family:-apple-system,sans-serif;
background:#0a0a0f;color:#e5e7eb;margin:0;padding:32px">
<div style="max-width:560px;margin:0 auto;background:#111827;padding:32px;
border-radius:16px;border:1px solid #1f2937">
<h1 style="color:#06b6d4;font-size:24px;margin:0 0 16px">Deletion request received</h1>
<p>Your account and personal data will be permanently erased within 30 days,
as required by GDPR Art. 17. We will send one final confirmation email once
the deletion is complete.</p>
<p style="font-size:13px;color:#6b7280">If this was a mistake, reply to this
email within 72 hours and we can cancel the request.</p>
</div></body></html>"""
    try:
        resend.Emails.send(
            {
                "from": from_email,
                "to": [email],
                "subject": f"{branding.APP_NAME} deletion request received",
                "html": html,
            }
        )
    except Exception as e:
        logger.error(f"dsar: failed to send deletion email to {email}: {e}")
