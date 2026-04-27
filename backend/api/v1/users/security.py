"""
Account-security endpoints — device tracking + alerts.

POST /api/v1/users/me/security/track-device
    Called by the mobile app on first network call after sign-in. The
    server compares the supplied fingerprint to known devices for this
    user. New fingerprint → record + send alert email asynchronously.
    Existing fingerprint → just bump last_seen_at + last_seen_ip.

GET /api/v1/users/me/security/devices
    List the current user's known devices (for a future Settings UI).

DELETE /api/v1/users/me/security/devices/{device_id}
    Forget a device — the next sign-in from it will be treated as new
    and re-trigger the alert email.
"""
from datetime import datetime, timezone
from typing import Optional, List

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.logger import get_logger
from core.supabase_db import get_supabase_db
from services.email_service import EmailService

router = APIRouter(prefix="/me/security", tags=["Account Security"])
logger = get_logger(__name__)


class TrackDeviceRequest(BaseModel):
    """Fingerprint payload sent by the client right after sign-in.

    fingerprint_hash is computed client-side as
        sha256(platform | model | os_version | app_install_id)
    The server treats the same hash from the same user as "known"; a
    different hash → new device.
    """
    fingerprint_hash: str = Field(..., min_length=16, max_length=128)
    platform: Optional[str] = Field(default=None, max_length=24)
    model: Optional[str] = Field(default=None, max_length=120)
    os_version: Optional[str] = Field(default=None, max_length=40)
    app_version: Optional[str] = Field(default=None, max_length=40)
    is_first_signin: bool = Field(
        default=False,
        description=(
            "Set true when this call follows a fresh sign-in (not just app "
            "open). The server uses this as a hint to never alert on app "
            "warm-launches even if the fingerprint somehow rotated."
        ),
    )


class KnownDevice(BaseModel):
    id: str
    platform: Optional[str]
    model: Optional[str]
    os_version: Optional[str]
    app_version: Optional[str]
    last_seen_city: Optional[str]
    last_seen_country: Optional[str]
    last_seen_at: str
    created_at: str
    is_current: bool


@router.post("/track-device")
async def track_device(
    payload: TrackDeviceRequest,
    request: Request,
    background: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Record (or refresh) the calling device. Fires email on first sight."""
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Not authenticated")

    db = get_supabase_db()
    sb = db.client

    # Best-effort IP capture. Render / proxies put the real IP in
    # X-Forwarded-For; fall back to the direct socket otherwise.
    fwd = request.headers.get("x-forwarded-for") or ""
    ip = fwd.split(",")[0].strip() if fwd else (
        request.client.host if request.client else None
    )

    existing_resp = (
        sb.table("user_known_devices")
        .select("id, created_at")
        .eq("user_id", user_id)
        .eq("fingerprint_hash", payload.fingerprint_hash)
        .limit(1)
        .execute()
    )
    existing = (existing_resp.data or [None])[0]

    now_iso = datetime.now(timezone.utc).isoformat()

    if existing:
        # Known device — bump last_seen.
        sb.table("user_known_devices").update({
            "last_seen_at": now_iso,
            "last_seen_ip": ip,
        }).eq("id", existing["id"]).execute()
        return {"status": "known", "device_id": existing["id"]}

    # First time we see this fingerprint for this user. Insert + alert.
    insert_resp = (
        sb.table("user_known_devices")
        .insert({
            "user_id": user_id,
            "fingerprint_hash": payload.fingerprint_hash,
            "platform": payload.platform,
            "model": payload.model,
            "os_version": payload.os_version,
            "app_version": payload.app_version,
            "last_seen_ip": ip,
            "last_seen_at": now_iso,
        })
        .execute()
    )
    new_row = (insert_resp.data or [None])[0]
    if not new_row:
        # Insert failed — most likely a race against a sibling call. Don't
        # alert (we can't be sure it's truly new) and don't 500.
        logger.warning(
            f"track-device insert returned no row for user={user_id}, "
            f"fp={payload.fingerprint_hash[:8]}…"
        )
        return {"status": "unknown"}

    # Suppress alert on the very first device ever — that's the welcome
    # email's territory, not a security alert. Detect by: this is the only
    # row for the user.
    count_resp = (
        sb.table("user_known_devices")
        .select("id", count="exact")
        .eq("user_id", user_id)
        .execute()
    )
    total_devices = count_resp.count or 0

    if total_devices <= 1:
        logger.info(
            f"Skipping new-device alert for user={user_id} (first device ever)"
        )
        return {"status": "first_device", "device_id": new_row["id"]}

    # Otherwise dispatch the email asynchronously so the client doesn't
    # wait on Resend.
    background.add_task(
        _send_alert_async,
        user_id=user_id,
        email=current_user.get("email"),
        first_name=current_user.get("name"),
        device_label=_device_label(payload),
        platform=payload.platform,
        ip=ip,
        device_id=new_row["id"],
    )
    return {"status": "new", "device_id": new_row["id"], "email_dispatched": True}


@router.get("/devices", response_model=List[KnownDevice])
async def list_devices(
    fingerprint_hash: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """List the user's known devices, newest first."""
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Not authenticated")
    db = get_supabase_db()
    resp = (
        db.client.table("user_known_devices")
        .select(
            "id, fingerprint_hash, platform, model, os_version, app_version, "
            "last_seen_city, last_seen_country, last_seen_at, created_at"
        )
        .eq("user_id", user_id)
        .order("last_seen_at", desc=True)
        .execute()
    )
    rows = resp.data or []
    return [
        KnownDevice(
            id=r["id"],
            platform=r.get("platform"),
            model=r.get("model"),
            os_version=r.get("os_version"),
            app_version=r.get("app_version"),
            last_seen_city=r.get("last_seen_city"),
            last_seen_country=r.get("last_seen_country"),
            last_seen_at=r["last_seen_at"],
            created_at=r["created_at"],
            is_current=(fingerprint_hash is not None
                        and r.get("fingerprint_hash") == fingerprint_hash),
        )
        for r in rows
    ]


@router.delete("/devices/{device_id}")
async def forget_device(
    device_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Remove a known device. Next sign-in from it re-triggers the alert."""
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Not authenticated")
    db = get_supabase_db()
    db.client.table("user_known_devices").delete().eq("id", device_id).eq(
        "user_id", user_id
    ).execute()
    return {"status": "forgotten", "device_id": device_id}


def _device_label(payload: TrackDeviceRequest) -> str:
    """Build a human-readable device label like 'iPhone 15 Pro · iOS 17.4'."""
    parts: List[str] = []
    if payload.model:
        parts.append(payload.model)
    if payload.platform and payload.os_version:
        parts.append(f"{payload.platform.capitalize()} {payload.os_version}")
    elif payload.platform:
        parts.append(payload.platform.capitalize())
    return " · ".join(parts) if parts else "Unknown device"


async def _send_alert_async(
    *,
    user_id: str,
    email: Optional[str],
    first_name: Optional[str],
    device_label: str,
    platform: Optional[str],
    ip: Optional[str],
    device_id: str,
) -> None:
    """Background task: send the new-device alert email.

    Errors here MUST NOT propagate — the user is already signed in, the
    device row is already saved; failing to email is a degraded warning,
    not a request failure.
    """
    if not email:
        logger.warning(f"Cannot send new-device alert: no email for user={user_id}")
        return
    try:
        # Best-effort IP geolocation. We deliberately keep this in-process and
        # synchronous-fast (no third-party HTTP) — wrong-country guesses are
        # worse than 'Unknown location'. Real geo can be wired later.
        location = None

        from core.config import get_settings
        backend_url = get_settings().backend_base_url
        sign_out_url = (
            f"{backend_url}/api/v1/users/me/security/devices/{device_id}/revoke-link"
        )

        await EmailService().send_new_device_signin_email(
            to_email=email,
            first_name=first_name,
            device_label=device_label,
            platform=platform,
            location=location,
            ip=ip,
            sign_out_url=sign_out_url,
        )
    except Exception as e:
        logger.exception(f"Failed to send new-device alert for user={user_id}: {e}")
