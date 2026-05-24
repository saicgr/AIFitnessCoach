"""
Training Load API
=================
Banister TRIMP + acute (7d) / chronic (28d) workload + ACWR.

Endpoints:
- GET /training-load/history?days=120  → per-day TrainingLoadDayPoint series
- GET /training-load/current           → latest TrainingLoadState + classification

Computes live from `cardio_logs` + `cardio_sessions`. A future agent owns a
daily snapshot job (`cardio_metric_snapshot_job.py`) — until then every
request recomputes.
"""
from typing import List

from fastapi import APIRouter, Depends, Query

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.training_load_service import (
    TrainingLoadDayPoint,
    TrainingLoadState,
    compute_training_load_history,
    current_state,
)

logger = get_logger(__name__)
router = APIRouter(prefix="/training-load", tags=["Training Load"])


@router.get("/history", response_model=List[TrainingLoadDayPoint])
async def get_training_load_history(
    days: int = Query(120, ge=7, le=365),
    current_user: dict = Depends(get_current_user),
) -> List[TrainingLoadDayPoint]:
    """Return per-day {date, daily_trimp, acute_load, chronic_load, acwr}.

    Window ends today (inclusive). The chronic-load curve is right-aligned
    over 28 days — its value on the first visible day already accounts for
    the prior 27 days of cardio so the chart isn't artificially low at the
    left edge.
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        return compute_training_load_history(db, user_id, days=days)
    except Exception as e:
        logger.error(f"[TrainingLoad] history error: {e}", exc_info=True)
        raise safe_internal_error(e, "training_load")


@router.get("/current", response_model=TrainingLoadState)
async def get_training_load_current(
    current_user: dict = Depends(get_current_user),
) -> TrainingLoadState:
    """Latest day's TRIMP / acute / chronic / ACWR + classification.

    `state` ∈ {detraining, balanced, loading, overreaching, calibration}.
    `calibration` is returned when the user has < 14 days of history.
    """
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        return current_state(db, user_id)
    except Exception as e:
        logger.error(f"[TrainingLoad] current error: {e}", exc_info=True)
        raise safe_internal_error(e, "training_load")
