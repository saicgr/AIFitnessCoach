"""Authenticated in-app data export.

Thin wrapper over `services.data_export` so logged-in users can export their
data from Settings → Data & Privacy in one tap. Complements the public DSAR
flow (api/v1/dsar.py) which handles out-of-app email-verified requests for
users who can't reach the in-app settings screen.

Why separate from DSAR: DSAR is mandatory GDPR/CCPA plumbing and deliberately
public + email-verified (works for locked-out users, forgotten passwords).
This endpoint targets the happy path — the user is logged in, tapped
"Export" from Settings, and wants their ZIP *now*.

Formats: csv (default ZIP bundle), json, excel, parquet. All reuse the
same data-gathering pass in `data_export.py`; only the serialization differs.

Size strategy:
    - < 10 MB → stream inline (Content-Disposition: attachment).
    - ≥ 10 MB → run export in BackgroundTask, upload ZIP to S3 with a
      7-day presigned URL, email the user via Resend, return 202 with a
      "check your email" hint. Reuses DSAR's S3 + Resend helpers.

Rate limit: 1 successful export/hour/user. Exports are relatively expensive
(dozens of DB queries) and users almost never need two per hour legitimately.
Abuse would be replaying exports to scrape data.
"""
from __future__ import annotations

import hashlib
import io
import secrets
import time
from datetime import datetime, timedelta, timezone as _tz
from typing import Literal, Optional

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Request
from fastapi.responses import JSONResponse, StreamingResponse

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from services.data_export import (
    export_user_data,
    export_user_data_excel,
    export_user_data_json,
    export_user_data_parquet,
)

logger = get_logger(__name__)
router = APIRouter()

# Threshold above which we switch from inline stream → background + email.
# Picked based on typical export size: an 18-month-old power user lands
# around 4-8 MB; a 3-year pro-lifter can hit 15+ MB. Inline at 10 MB keeps
# the wait at ~5-10 s on mobile LTE; bigger goes async.
INLINE_MAX_BYTES = 10 * 1024 * 1024

# How long S3 presigned download links stay valid. Matches DSAR TTL so we
# get a consistent retention window across both access paths.
S3_DOWNLOAD_TTL = timedelta(days=7)

# Per-format metadata table: (mime, filename template, exporter, file_ext)
# The exporter functions return bytes (csv/excel/parquet) or str (json)
# and we normalize to bytes at call sites.
_FORMAT_MAP = {
    "csv":     ("application/zip",
                "zealova-export-{ts}.zip",
                export_user_data,
                "zip"),
    "json":    ("application/json",
                "zealova-export-{ts}.json",
                export_user_data_json,
                "json"),
    "excel":   ("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "zealova-export-{ts}.xlsx",
                export_user_data_excel,
                "xlsx"),
    "parquet": ("application/zip",
                "zealova-export-{ts}-parquet.zip",
                export_user_data_parquet,
                "zip"),
}


def _run_exporter(exporter, user_id: str, start_date, end_date) -> bytes:
    """Call exporter and normalize output to bytes."""
    out = exporter(user_id, start_date=start_date, end_date=end_date)
    if isinstance(out, str):
        return out.encode("utf-8")
    return out


# ── Background export path ────────────────────────────────────────────────

def _background_export_and_email(
    user_id: str,
    user_email: str,
    format_key: str,
    start_date: Optional[str],
    end_date: Optional[str],
) -> None:
    """Run a large export out-of-band: export → S3 upload → email presigned URL.

    Runs in a FastAPI BackgroundTask — blocking here is fine (the HTTP
    response has already been sent). All errors are logged; we do NOT
    raise because the client is long gone.
    """
    try:
        _, filename_template, exporter, file_ext = _FORMAT_MAP[format_key]
        payload = _run_exporter(exporter, user_id, start_date, end_date)

        ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
        filename = filename_template.format(ts=ts)

        # S3 key includes a random suffix so even if a user re-requests an
        # export within the same second, presigned URLs don't collide.
        suffix = secrets.token_hex(4)
        key = f"user-exports/{user_id}/{ts}-{suffix}.{file_ext}"

        # Import late — boto3 is heavy and only needed on this cold path.
        from api.v1.dsar import _upload_and_sign, _send_export_ready_email

        # _upload_and_sign expects (bytes, key) and returns (url, expires_at).
        # It writes the zip with SSE + proper Content-Disposition already.
        url, expires_at = _upload_and_sign(payload, key)
        _send_export_ready_email(
            email=user_email,
            download_url=url,
            expires_at=expires_at,
            request_type="export",
        )
        logger.info(
            f"✅ [Export/bg] user={user_id} format={format_key} "
            f"size={len(payload)/1024/1024:.1f}MB delivered via S3 + email"
        )
    except Exception as e:
        logger.error(
            f"❌ [Export/bg] user={user_id} format={format_key} failed: {e}",
            exc_info=True,
        )


# ── Endpoint ──────────────────────────────────────────────────────────────

@router.get("/export")
@limiter.limit("1/hour")
async def export_my_data(
    request: Request,
    format: Literal["csv", "json", "excel", "parquet"] = Query(
        "csv",
        description="Export format. csv = ZIP of CSV files (default, Hevy-importable via workouts_strong.csv).",
    ),
    start_date: Optional[str] = Query(None, description="Optional YYYY-MM-DD range start"),
    end_date: Optional[str] = Query(None, description="Optional YYYY-MM-DD range end"),
    background_tasks: BackgroundTasks = None,  # type: ignore
    current_user: dict = Depends(get_current_user),
):
    """Return the user's data in the requested format.

    Small exports are streamed directly. Large ones kick off a background
    job + email delivery and return 202 with a status hint.
    """
    user_id = str(current_user["id"])
    user_email = current_user.get("email") or ""
    logger.info(
        f"📦 [Export] Requested by user={user_id} format={format} "
        f"range={start_date}→{end_date}"
    )

    start = time.time()
    try:
        mime, filename_template, exporter, _ext = _FORMAT_MAP[format]
        # Generate payload synchronously first — we still need to *know* the
        # size before deciding streaming vs async. The heavy DB fetches
        # happen here regardless of path; we just pick the delivery mode.
        payload = _run_exporter(exporter, user_id, start_date, end_date)
    except ValueError as e:
        # e.g. user not found — bubble up as 404 rather than 500.
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"❌ [Export] user={user_id} failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Export failed. Please try again later.")

    size_mb = len(payload) / (1024 * 1024)
    elapsed = time.time() - start
    logger.info(
        f"✅ [Export] user={user_id} format={format} "
        f"size={size_mb:.2f}MB in {elapsed:.1f}s"
    )

    # Large → background-upload + email. Payload already computed above;
    # the background task just does S3 upload + email. We pass the payload
    # via closure so we don't re-run the export.
    if len(payload) > INLINE_MAX_BYTES:
        if not user_email:
            # Can't email — fall back to inline and hope the client can
            # handle the stream. Log loudly so ops see it.
            logger.warning(
                f"⚠️ [Export] user={user_id} large ({size_mb:.1f}MB) but no "
                f"email on file — streaming inline as fallback."
            )
        else:
            def _deliver() -> None:
                """Inline closure: upload the already-generated bytes, email."""
                try:
                    from api.v1.dsar import _upload_and_sign, _send_export_ready_email
                    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
                    suffix = secrets.token_hex(4)
                    key = f"user-exports/{user_id}/{ts}-{suffix}.{_FORMAT_MAP[format][3]}"
                    url, expires_at = _upload_and_sign(payload, key)
                    _send_export_ready_email(
                        email=user_email,
                        download_url=url,
                        expires_at=expires_at,
                        request_type="export",
                    )
                    logger.info(
                        f"✅ [Export/bg] user={user_id} delivered {size_mb:.1f}MB via email"
                    )
                except Exception as e:
                    logger.error(
                        f"❌ [Export/bg] user={user_id} delivery failed: {e}",
                        exc_info=True,
                    )

            if background_tasks is not None:
                background_tasks.add_task(_deliver)
            else:
                # Shouldn't happen under normal routing — FastAPI injects bt.
                logger.error(
                    f"[Export] user={user_id} BackgroundTasks is None; falling back to inline stream"
                )

            return JSONResponse(
                status_code=202,
                content={
                    "status": "queued",
                    "size_bytes": len(payload),
                    "message": (
                        "Your export is {:.1f}MB — too large for an in-app download. "
                        "We'll email you a secure download link in ~30 seconds. "
                        "The link is valid for 7 days."
                    ).format(size_mb),
                    "delivered_to": user_email,
                    "expires_in_days": S3_DOWNLOAD_TTL.days,
                },
            )

    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    filename = filename_template.format(ts=ts)
    etag = hashlib.sha256(payload).hexdigest()[:16]

    return StreamingResponse(
        io.BytesIO(payload),
        media_type=mime,
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Content-Length": str(len(payload)),
            "ETag": f'"{etag}"',
            "X-Export-Size-Bytes": str(len(payload)),
            "X-Export-Format": format,
        },
    )
