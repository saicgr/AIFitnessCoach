"""
Cardio Custom Trends read endpoint (Wave 2 / SLICE_TRENDS).

`GET /trends/cardio-series?metric=<key>&days=<n>` returns the per-day
history for one of the 13 registered cardio metrics, projected from
`public.cardio_metric_snapshots` (populated daily by
`services.cardio_metric_snapshot_job`).

Response shape:
    {
      "metric": "race_predicted_5k_sec",
      "days": 90,
      "daily_series": [
        {"date": "2026-05-01", "value": 1450.0},
        ...
      ]
    }

The metric_key is validated against an explicit allowlist — boolean tags
(e.g. is_hill_workout) are intentionally NOT registered as Custom Trends
metrics; Wave-1 trends infra is numeric-only.

TODO: register in __init__.py
"""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.cardio_metric_snapshot_job import REGISTERED_METRIC_KEYS

logger = get_logger(__name__)
router = APIRouter()


_ALLOWED = set(REGISTERED_METRIC_KEYS)


@router.get("/cardio-series")
async def get_cardio_series(
    metric: str = Query(..., description="Registered cardio metric_key."),
    days: int = Query(
        90, ge=0, le=3650,
        description="Lookback window in days. 0 = all available history.",
    ),
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """Return per-day series for one registered cardio metric."""
    if metric not in _ALLOWED:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown metric '{metric}'. "
                   f"Allowed: {sorted(_ALLOWED)}",
        )

    user_id = current_user.get("id") or current_user.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Missing user id")

    try:
        db = get_supabase_db()
        q = (
            db.client.table("cardio_metric_snapshots")
            .select("snapshot_date,value_numeric")
            .eq("user_id", user_id)
            .eq("metric_key", metric)
        )
        if days > 0:
            cutoff = (
                datetime.now(timezone.utc).date() - timedelta(days=days)
            ).isoformat()
            q = q.gte("snapshot_date", cutoff)

        r = q.order("snapshot_date", desc=False).execute()
        rows = r.data or []

        daily_series: List[Dict[str, Any]] = []
        for row in rows:
            d = row.get("snapshot_date")
            v = row.get("value_numeric")
            if d is None or v is None:
                continue
            daily_series.append({"date": str(d), "value": float(v)})

        return {"metric": metric, "days": days, "daily_series": daily_series}
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(f"[TrendsCardio] {metric} failed: {e}", exc_info=True)
        raise safe_internal_error(e, "trends_cardio")
