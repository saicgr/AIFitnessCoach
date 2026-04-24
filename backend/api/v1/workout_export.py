"""
Workout export endpoint — `GET /workout-history/export`.

Streams a user's strength + cardio (and optionally templates) out of FitWiz
in any of the formats the import pipeline accepts, proving round-trip
reversibility for the "not locked in" GDPR promise.

Separate from the existing `api/v1/export.py` (which is a GDPR-Article-20
bulk ZIP of the whole account), because this one targets the narrower
"I want my workouts in Hevy format" use case and dispatches per-format
via `services.workout_export.orchestrator`.

Auth + error patterns mirror `api/v1/workout_history.py`: `get_current_user`
dependency, `safe_internal_error` for 500s, detailed logging prefixed with
`[WorkoutExport]`.
"""
from __future__ import annotations

import io
import logging
from datetime import date
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse, StreamingResponse

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from services.workout_export.orchestrator import (
    SUPPORTED_FORMATS,
    export_user_data,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/workout-history", tags=["Workout Export"])


def _parse_include(include: Optional[str]) -> tuple[bool, bool, bool]:
    """Parse the `include` query param → (strength, cardio, templates).

    Accepts comma-separated list like `"strength,cardio,templates"`. Empty
    / missing param defaults to `strength,cardio` (most common user intent)
    because an empty export is almost never what anyone wants.
    """
    if not include:
        return True, True, False
    parts = {p.strip().lower() for p in include.split(",") if p.strip()}
    return ("strength" in parts, "cardio" in parts, "templates" in parts)


@router.get("/export/formats")
async def list_export_formats(
    current_user: dict = Depends(get_current_user),
):
    """Return the format catalog for the UI picker.

    Auth required so unauthenticated scrapers can't enumerate our feature
    surface, even though the list itself is not sensitive.
    """
    return {
        "formats": [
            {
                "key": key,
                "display_name": spec["display"],
                "description": spec["description"],
                "extension": spec["extension"],
                "content_type": spec["content_type"],
                "cardio_only": spec["cardio_only"],
            }
            for key, spec in SUPPORTED_FORMATS.items()
        ],
    }


@router.get("/export")
async def export_workout_data(
    format: str = Query(..., description="One of: hevy, strong, fitbod, csv, json, parquet, xlsx, pdf, tcx, gpx"),
    include: Optional[str] = Query(
        default=None,
        description="Comma-separated: strength, cardio, templates. Defaults to strength,cardio.",
    ),
    from_date_q: Optional[date] = Query(default=None, alias="from", description="YYYY-MM-DD"),
    to_date_q: Optional[date] = Query(default=None, alias="to", description="YYYY-MM-DD"),
    current_user: dict = Depends(get_current_user),
):
    """Generate + stream an export file.

    Query params:
      - format: format key (see /formats endpoint)
      - include: comma list (strength, cardio, templates)
      - from: inclusive start date (YYYY-MM-DD)
      - to: inclusive end date (YYYY-MM-DD)

    Response: `Content-Disposition: attachment; filename=...`
    """
    # Defensive: date range sanity. An inverted range would silently return
    # zero rows; better to 400 early so the client can fix.
    if from_date_q and to_date_q and from_date_q > to_date_q:
        raise HTTPException(
            status_code=400,
            detail="`from` must be <= `to`",
        )

    include_strength, include_cardio, include_templates = _parse_include(include)

    # If the user asked for nothing, return 400 — an empty file is never
    # what a user clicking "Export" meant to request.
    if not (include_strength or include_cardio or include_templates):
        raise HTTPException(
            status_code=400,
            detail="Select at least one of: strength, cardio, templates.",
        )

    try:
        user_id = UUID(current_user["id"])
    except (KeyError, ValueError, TypeError):
        raise HTTPException(status_code=401, detail="Invalid user context.")

    try:
        payload, content_type, filename = await export_user_data(
            user_id=user_id,
            format=format,
            include_strength=include_strength,
            include_cardio=include_cardio,
            include_templates=include_templates,
            from_date=from_date_q,
            to_date=to_date_q,
        )
    except ValueError as ve:
        # Unsupported format / validation — expose to the client.
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"[WorkoutExport] export failed for user={user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_export")

    return StreamingResponse(
        io.BytesIO(payload),
        media_type=content_type,
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Content-Length": str(len(payload)),
            "X-Export-Format": format,
            "X-Export-Size-Bytes": str(len(payload)),
        },
    )
