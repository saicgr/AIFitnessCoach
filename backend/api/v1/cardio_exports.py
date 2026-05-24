"""Cardio export endpoint — GPX / TCX / FIT download for a single cardio_log.

Wraps `services.cardio_export_service.export(...)`. Owner-only auth gate.
Returns a StreamingResponse with the correct Content-Disposition so the
client share-sheet picks up a sensible filename.
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Path, Query
from fastapi.responses import StreamingResponse

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services import cardio_export_service

logger = get_logger(__name__)
router = APIRouter(prefix="/cardio-logs", tags=["Cardio Exports"])


@router.get("/{cardio_log_id}/export")
async def export_cardio_log(
    cardio_log_id: str = Path(...),
    format: str = Query(..., regex="^(gpx|tcx|fit)$"),
    current_user: dict = Depends(get_current_user),
):
    """Download a single cardio_log as GPX / TCX / FIT.

    Raises:
      404 — cardio_log_id not found
      403 — log belongs to a different user
      415 — unsupported format (defense-in-depth; regex above should catch)
      422 — indoor activity + GPX (GPX requires a route)
    """
    try:
        db = get_supabase_db()
        row_res = (
            db.client.table("cardio_logs")
            .select(
                "id,user_id,activity_type,performed_at,duration_seconds,"
                "distance_m,avg_heart_rate,max_heart_rate,calories,notes,"
                "gps_polyline,route_polyline_s3_key,splits_json,"
                "indoor_metadata,source_app"
            )
            .eq("id", cardio_log_id)
            .single()
            .execute()
        )
        row = row_res.data
        if not row:
            raise HTTPException(status_code=404, detail="cardio_log_not_found")
        if str(row.get("user_id")) != str(current_user.get("id")):
            raise HTTPException(status_code=403, detail="forbidden")

        # Decode route from S3 OR inline gps_polyline. Indoor sessions can
        # legitimately have no route — TCX/FIT still work; GPX 422s.
        route_points = None
        try:
            from core.s3_client import get_s3_client  # type: ignore
            s3_key = row.get("route_polyline_s3_key")
            if s3_key:
                blob = get_s3_client().get_object_bytes(s3_key)
                if blob:
                    route_points = cardio_export_service.decode_route_blob(blob)
        except Exception as e:
            logger.warning(f"[CardioExport] S3 route fetch failed: {e}")

        if not route_points and row.get("gps_polyline"):
            try:
                route_points = cardio_export_service.decode_route_blob(
                    row["gps_polyline"].encode() if isinstance(row["gps_polyline"], str)
                    else row["gps_polyline"]
                )
            except Exception:
                route_points = None

        splits = row.get("splits_json") or None
        if isinstance(splits, list) and not splits:
            splits = None

        try:
            result = cardio_export_service.export(
                fmt=format,
                row=row,
                route_points=route_points,
                hr_samples=None,
                splits=splits,
            )
        except ValueError as ve:
            msg = str(ve)
            if msg == "unsupported_format":
                raise HTTPException(status_code=415, detail="unsupported_format")
            if msg == "gpx_requires_route":
                raise HTTPException(
                    status_code=422,
                    detail="GPX requires a recorded route; this is an indoor session.",
                )
            raise

        def _iter():
            yield result.data

        return StreamingResponse(
            _iter(),
            media_type=result.mime_type,
            headers={
                "Content-Disposition": f'attachment; filename="{result.filename}"',
                "Content-Length": str(len(result.data)),
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[CardioExport] error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_exports")
