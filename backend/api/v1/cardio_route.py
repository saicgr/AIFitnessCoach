"""
Cardio route polyline upload endpoint.

POST /cardio-logs/{id}/route
    Uploads a recorded GPS polyline (JSON: [[lat, lng], ...]) for an
    existing cardio_logs row, persists it to S3, and writes the resulting
    object key back to `cardio_logs.route_polyline_s3_key` (column added
    by migration 2094).

Why a separate endpoint:
    The Flutter HealthImportService discovers routes from HealthKit
    AFTER the cardio_logs row has been created (the row is written first
    from the workout summary; the route is fetched separately via
    HKWorkoutRoute). Doing the route upload over the standard
    `/cardio-logs` insert would require buffering up to several MB of
    polyline JSON inside the synchronous insert path — slower and
    harder to retry.

TODO: register in __init__.py — add
    `from api.v1 import cardio_route`
    `router.include_router(cardio_route.router)`
    in `backend/api/v1/__init__.py`. (Composer/integrator owns the batch
    register at end of slice; do NOT touch __init__.py from here.)
"""
from __future__ import annotations

import json
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, validator

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.s3_service import get_s3_service

logger = get_logger(__name__)

router = APIRouter(prefix="/cardio-logs", tags=["Cardio Logs"])


# ----- Request model -----

class RouteUploadRequest(BaseModel):
    """A list of [lat, lng] pairs in recorded order, plus optional metadata.

    No per-point timestamp here — pace/speed series live on the cardio_logs
    row itself. This endpoint is purely about the spatial polyline for map
    rendering.
    """

    polyline: List[List[float]] = Field(
        ...,
        description="Polyline as [[lat, lng], ...]. Length 2–50,000.",
    )
    source: Optional[str] = Field(
        default="apple_health",
        description="Source tag (apple_health | strava | manual | …). Stored "
                    "alongside the polyline in S3 for provenance.",
    )

    @validator("polyline")
    def _check_polyline(cls, v: List[List[float]]) -> List[List[float]]:
        # Bound the payload — a 4-hour HealthKit route at 1 sample/sec is
        # ~14,400 points. 50,000 gives plenty of headroom for ultra-endurance
        # workouts without inviting accidental DOS.
        if not v or len(v) < 2:
            raise ValueError("polyline must contain at least 2 points")
        if len(v) > 50_000:
            raise ValueError("polyline too long (>50,000 points)")
        for i, p in enumerate(v):
            if len(p) != 2:
                raise ValueError(f"point {i} must be [lat, lng]")
            lat, lng = p
            # Reject obviously invalid coords — keeps S3 garbage out.
            if not (-90.0 <= lat <= 90.0) or not (-180.0 <= lng <= 180.0):
                raise ValueError(f"point {i} out of range: ({lat}, {lng})")
        return v


# ----- Endpoint -----

@router.post("/{cardio_log_id}/route")
async def upload_cardio_route(
    cardio_log_id: str,
    payload: RouteUploadRequest,
    current_user: dict = Depends(get_current_user),
):
    """Upload a polyline to S3 and link it to the cardio_logs row.

    Auth: row must belong to the calling user. We verify by selecting the
    row scoped to `user_id` before uploading anything to S3 (cheap guard
    that avoids dumping bytes for an unauthorized request).
    """
    user_id = current_user.get("id") or current_user.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    db = get_supabase_db()

    # ---- Verify ownership of the cardio_logs row before uploading bytes.
    try:
        existing = (
            db.client.table("cardio_logs")
            .select("id, user_id, route_polyline_s3_key")
            .eq("id", cardio_log_id)
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
    except Exception as e:
        logger.exception("cardio_route lookup failed: %s", e)
        raise safe_internal_error("Failed to look up cardio log") from e

    if not existing or not existing.data:
        # Either the row doesn't exist or it isn't owned by this user.
        # Surface as 404 either way — don't leak the difference.
        raise HTTPException(status_code=404, detail="Cardio log not found")

    # ---- Upload to S3.
    s3 = get_s3_service()
    if not s3.is_configured():
        # Surface as 503 — the client should retry once S3 comes back.
        raise HTTPException(
            status_code=503,
            detail="Route upload temporarily unavailable",
        )

    blob = json.dumps(
        {
            "version": 1,
            "source": payload.source,
            "points": payload.polyline,
        },
        separators=(",", ":"),
    ).encode("utf-8")

    try:
        s3_key = s3.upload_bytes(
            blob,
            key_prefix=f"cardio_routes/{user_id}",
            filename=f"{cardio_log_id}.json",
            content_type="application/json",
        )
    except Exception as e:
        logger.exception("cardio_route S3 upload failed: %s", e)
        raise safe_internal_error("Failed to upload route to storage") from e

    # ---- Persist the key on the row.
    try:
        db.client.table("cardio_logs").update(
            {"route_polyline_s3_key": s3_key}
        ).eq("id", cardio_log_id).eq("user_id", user_id).execute()
    except Exception as e:
        # The bytes are already in S3; surface the failure but log that the
        # object key is orphaned so cleanup can reclaim it later if needed.
        logger.exception(
            "cardio_route key persist failed (orphaned S3 object: %s): %s",
            s3_key,
            e,
        )
        raise safe_internal_error("Failed to save route metadata") from e

    logger.info(
        "🗺️  [cardio_route] user=%s log=%s key=%s points=%d",
        user_id,
        cardio_log_id,
        s3_key,
        len(payload.polyline),
    )

    return {
        "cardio_log_id": cardio_log_id,
        "route_polyline_s3_key": s3_key,
        "points": len(payload.polyline),
    }
