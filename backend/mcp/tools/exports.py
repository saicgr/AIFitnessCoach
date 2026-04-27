"""Data export + report generation MCP tools.

`export_user_data` — wraps `services.data_export.*` (zip/json/xlsx/parquet),
uploads the artifact to Supabase Storage under bucket `mcp-exports/`, and
returns a 1-hour signed URL.

`generate_report` — delegates PDF/HTML/MD rendering to
`mcp.reports.generators.render_report()` (built by the reports agent).
Same signed-URL flow.

Everything runs synchronously for simplicity — both tools complete in
<30s for typical accounts. If a user's history is large enough to
exceed MCP's transport timeout, we can promote to an async job-queue
flow later; for v1 we keep it simple so there's no `get_export_status`
polling surface.
"""
from __future__ import annotations

import asyncio
import uuid
from typing import Any, Dict, Optional

from core import branding
from core.logger import get_logger
from core.supabase_client import get_supabase
from mcp.tools import run_tool

logger = get_logger(__name__)

_BUCKET = "mcp-exports"
_SIGNED_URL_TTL_SEC = 3600  # 1 hour


def _format_extension(fmt: str) -> str:
    """Map an export format to its file extension."""
    fmt = (fmt or "").lower()
    return {
        "csv": "zip",         # csv export is a zip-of-csvs
        "json": "json",
        "xlsx": "xlsx",
        "excel": "xlsx",
        "parquet": "zip",     # parquet export is a zip-of-parquets
        "pdf": "pdf",
        "html": "html",
        "md": "md",
        "markdown": "md",
    }.get(fmt, "bin")


def _content_type(fmt: str) -> str:
    fmt = (fmt or "").lower()
    return {
        "csv": "application/zip",
        "json": "application/json",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "excel": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "parquet": "application/zip",
        "pdf": "application/pdf",
        "html": "text/html",
        "md": "text/markdown",
        "markdown": "text/markdown",
    }.get(fmt, "application/octet-stream")


async def _upload_and_sign(
    user_id: str,
    blob: bytes,
    filename: str,
    content_type: str,
) -> Dict[str, Any]:
    """Upload bytes to Supabase Storage and return a signed URL."""
    supabase = get_supabase()
    path = f"{user_id}/{filename}"

    # Supabase storage client is sync; run in a thread so we don't block the loop.
    def _do_upload() -> None:
        bucket = supabase.client.storage.from_(_BUCKET)
        # `upload` fails if the object already exists — we use unique filenames
        # via uuid so collisions are rare, but pass upsert=true defensively.
        try:
            bucket.upload(
                path=path,
                file=blob,
                file_options={"content-type": content_type, "upsert": "true"},
            )
        except TypeError:
            # Older storage client signature
            bucket.upload(path, blob, {"content-type": content_type})

    def _do_sign() -> Any:
        bucket = supabase.client.storage.from_(_BUCKET)
        return bucket.create_signed_url(path, _SIGNED_URL_TTL_SEC)

    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, _do_upload)
    signed = await loop.run_in_executor(None, _do_sign)

    # supabase-py returns dict with "signedURL" (or "signed_url")
    url = None
    if isinstance(signed, dict):
        url = signed.get("signedURL") or signed.get("signed_url") or signed.get("signedUrl")
    elif hasattr(signed, "signed_url"):
        url = signed.signed_url
    return {
        "storage_path": path,
        "download_url": url,
        "expires_in_seconds": _SIGNED_URL_TTL_SEC,
    }


# ─── export_user_data ────────────────────────────────────────────────────────

async def _export_user_data_impl(
    user: dict,
    format: str = "csv",
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> Dict[str, Any]:
    """Run the relevant export fn, upload, and return a signed URL."""
    fmt = (format or "csv").lower()
    user_id = user["id"]

    try:
        from services.data_export import (
            export_user_data as svc_zip_export,
            export_user_data_json,
            export_user_data_excel,
            export_user_data_parquet,
        )
    except Exception as e:
        return {"ok": False, "error": "export_service_unavailable", "detail": str(e)[:200]}

    loop = asyncio.get_event_loop()

    try:
        if fmt == "csv":
            blob = await loop.run_in_executor(
                None, lambda: svc_zip_export(user_id, start_date, end_date)
            )
        elif fmt == "json":
            data = await loop.run_in_executor(
                None, lambda: export_user_data_json(user_id, start_date, end_date)
            )
            import json as _json
            blob = _json.dumps(data, indent=2, default=str).encode("utf-8")
        elif fmt in ("xlsx", "excel"):
            blob = await loop.run_in_executor(
                None, lambda: export_user_data_excel(user_id, start_date, end_date)
            )
        elif fmt == "parquet":
            blob = await loop.run_in_executor(
                None, lambda: export_user_data_parquet(user_id, start_date, end_date)
            )
        else:
            return {"ok": False, "error": f"unsupported_format:{fmt}"}
    except Exception as e:
        logger.error(f"export_user_data run failed: {e}", exc_info=True)
        return {"ok": False, "error": "export_failed", "detail": str(e)[:200]}

    ext = _format_extension(fmt)
    filename = f"export_{uuid.uuid4()}.{ext}"
    try:
        upload = await _upload_and_sign(
            user_id=user_id,
            blob=blob,
            filename=filename,
            content_type=_content_type(fmt),
        )
    except Exception as e:
        logger.error(f"export_user_data upload failed: {e}", exc_info=True)
        return {"ok": False, "error": "upload_failed", "detail": str(e)[:200]}

    return {
        "ok": True,
        "format": fmt,
        "bytes": len(blob),
        **upload,
    }


# ─── generate_report ─────────────────────────────────────────────────────────

async def _generate_report_impl(
    user: dict,
    report_type: str,
    start_date: str,
    end_date: str,
    format: str = "pdf",
) -> Dict[str, Any]:
    """Render a report via `mcp.reports.generators.render_report`."""
    try:
        from mcp.reports.generators import render_report, report_content_type
    except Exception as e:
        # Reports agent hasn't shipped generators yet — report gracefully.
        return {
            "ok": False,
            "error": "report_service_unavailable",
            "detail": f"{e}",
        }

    try:
        # render_report is sync per the spec; run off the event loop.
        loop = asyncio.get_event_loop()
        blob = await loop.run_in_executor(
            None,
            lambda: render_report(user["id"], report_type, start_date, end_date, format),
        )
        ctype = report_content_type(format)
    except Exception as e:
        logger.error(f"generate_report failed: {e}", exc_info=True)
        return {"ok": False, "error": "render_failed", "detail": str(e)[:200]}

    ext = _format_extension(format)
    filename = f"report_{report_type}_{uuid.uuid4()}.{ext}"
    try:
        upload = await _upload_and_sign(
            user_id=user["id"],
            blob=blob,
            filename=filename,
            content_type=ctype or _content_type(format),
        )
    except Exception as e:
        logger.error(f"generate_report upload failed: {e}", exc_info=True)
        return {"ok": False, "error": "upload_failed", "detail": str(e)[:200]}

    return {
        "ok": True,
        "report_type": report_type,
        "format": format,
        "bytes": len(blob),
        "period": {"start": start_date, "end": end_date},
        **upload,
    }


# ─── Registrar ───────────────────────────────────────────────────────────────

def register(mcp_app: Any) -> None:
    @mcp_app.tool(
        name="export_user_data",
        description=(
            f"Export the user's full {branding.APP_NAME} dataset. Supported formats: "
            "'csv' (zip of CSVs), 'json', 'xlsx', 'parquet' (zip of Parquets). "
            "Returns a signed download URL valid for 1 hour."
        ),
    )
    async def export_user_data(
        ctx,
        format: str = "csv",
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "export_user_data",
            required_scope="export:data",
            impl=_export_user_data_impl,
            args={"format": format, "start_date": start_date, "end_date": end_date},
        )

    @mcp_app.tool(
        name="generate_report",
        description=(
            "Generate a human-readable report (PDF/HTML/Markdown). "
            "Supported report_type values: weekly_summary, monthly_summary, "
            "nutrition_deep_dive, strength_progression, workout_adherence. "
            "Returns a signed download URL valid for 1 hour."
        ),
    )
    async def generate_report(
        ctx,
        report_type: str,
        start_date: str,
        end_date: str,
        format: str = "pdf",
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "generate_report",
            required_scope="export:data",
            impl=_generate_report_impl,
            args={
                "report_type": report_type,
                "start_date": start_date,
                "end_date": end_date,
                "format": format,
            },
        )
