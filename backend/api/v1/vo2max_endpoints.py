"""
VO2max Endpoints
================

Read-only API surface for the user-facing VO2max trend detail screen.

Owned by SLICE_VO2MAX (Wave 2). Data flows in from `cardio_metrics`
(populated either by user-entered measurements, fitness-test estimates,
or Apple HealthKit imports owned by SLICE_GPS via the
`health_import_service.dart` path on the client). This module is
read-only — it never writes to `cardio_metrics`.

Endpoints
---------
- GET /vo2max/history?days=180
    Returns a list of `{recorded_at, ml_per_kg_per_min, source}` from
    `cardio_metrics` filtered to `vo2_max_estimate IS NOT NULL`, ordered
    by `measured_at` ascending. Days param bounds the window.

- GET /vo2max/latest
    Returns the most recent measurement using the `latest_cardio_metrics`
    Postgres view. Returns null when the user has no measurements.

TODO: register in __init__.py
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/vo2max", tags=["VO2max"])


# ---------------------------------------------------------------------------
# Response models
# ---------------------------------------------------------------------------
class Vo2MaxHistoryPoint(BaseModel):
    """Single VO2max measurement entry on the trend chart."""

    recorded_at: datetime = Field(
        ..., description="UTC timestamp when the VO2max value was recorded"
    )
    ml_per_kg_per_min: float = Field(
        ..., description="VO2max measurement in ml/(kg·min)"
    )
    source: Optional[str] = Field(
        None,
        description=(
            "Origin of the measurement: 'calculated' | 'measured' | "
            "'health_kit' | 'fitness_test' | 'manual'"
        ),
    )


class Vo2MaxLatestResponse(BaseModel):
    """Latest VO2max snapshot or null when no measurements exist."""

    recorded_at: Optional[datetime] = None
    ml_per_kg_per_min: Optional[float] = None
    source: Optional[str] = None
    fitness_age: Optional[int] = Field(
        None, description="Fitness age derived alongside this measurement"
    )


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@router.get(
    "/history",
    response_model=List[Vo2MaxHistoryPoint],
    summary="VO2max trend history",
)
async def get_vo2max_history(
    days: int = Query(
        180,
        ge=1,
        le=730,
        description="Window length in days (default 180, max 730)",
    ),
    current_user: dict = Depends(get_current_user),
) -> List[Vo2MaxHistoryPoint]:
    """Return VO2max measurements for the current user within the window.

    Filters out rows where `vo2_max_estimate IS NULL`. Empty list when the
    user has no qualifying measurements — the client renders the empty
    state ("Run outdoors a few times…").
    """
    user_id = str(current_user["id"])
    try:
        db = get_supabase_db()
        cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()

        # Filter `vo2_max_estimate IS NOT NULL` at the DB layer when the
        # client supports it; fall back to a Python filter otherwise so the
        # contract holds across PostgREST client versions.
        query = (
            db.client.table("cardio_metrics")
            .select("measured_at,vo2_max_estimate,source")
            .eq("user_id", user_id)
            .gte("measured_at", cutoff)
            .order("measured_at", desc=False)
        )
        try:
            # Newer postgrest-py: .not_.is_(col, "null")
            query = query.not_.is_("vo2_max_estimate", "null")
        except Exception:  # pragma: no cover - defensive across client versions
            pass

        resp = query.execute()
        rows = resp.data or []

        out: List[Vo2MaxHistoryPoint] = []
        for row in rows:
            v = row.get("vo2_max_estimate")
            measured_at = row.get("measured_at")
            if v is None or measured_at is None:
                # Defense in depth — if the .not_.is_ guard was skipped,
                # filter NULLs here so the contract still holds.
                continue
            out.append(
                Vo2MaxHistoryPoint(
                    recorded_at=measured_at,
                    ml_per_kg_per_min=float(v),
                    source=row.get("source"),
                )
            )
        return out
    except HTTPException:
        raise
    except Exception as e:  # pragma: no cover
        logger.exception("vo2max history failed for user %s", user_id)
        raise safe_internal_error(e, "Failed to load VO2max history")


@router.get(
    "/latest",
    response_model=Vo2MaxLatestResponse,
    summary="Latest VO2max snapshot",
)
async def get_vo2max_latest(
    current_user: dict = Depends(get_current_user),
) -> Vo2MaxLatestResponse:
    """Return the most recent VO2max measurement using `latest_cardio_metrics`.

    The view already picks DISTINCT ON (user_id) the most-recent row, but
    that row may itself carry a NULL `vo2_max_estimate` (max_hr / resting_hr
    only). In that case we return an all-null payload so the UI shows the
    empty state.
    """
    user_id = str(current_user["id"])
    try:
        db = get_supabase_db()
        resp = (
            db.client.table("latest_cardio_metrics")
            .select("measured_at,vo2_max_estimate,source,fitness_age")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        rows = resp.data or []
        if not rows:
            return Vo2MaxLatestResponse()
        row = rows[0]
        v = row.get("vo2_max_estimate")
        if v is None:
            return Vo2MaxLatestResponse()
        return Vo2MaxLatestResponse(
            recorded_at=row.get("measured_at"),
            ml_per_kg_per_min=float(v),
            source=row.get("source"),
            fitness_age=row.get("fitness_age"),
        )
    except HTTPException:
        raise
    except Exception as e:  # pragma: no cover
        logger.exception("vo2max latest failed for user %s", user_id)
        raise safe_internal_error(e, "Failed to load latest VO2max")
