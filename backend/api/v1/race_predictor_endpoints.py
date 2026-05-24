"""
Race-time predictor API.

GET /api/v1/cardio-prediction/races
  Returns 5K / 10K / half / marathon finish-time predictions from the user's
  best run in `cardio_logs`. Each entry is either a RacePrediction or null
  (insufficient data — UI renders the "log a measured run" empty state).

Per-user in-memory cache: 1 hour TTL. Race-time math doesn't change minute to
minute and cardio_logs imports are bursty (Strava webhook fires once on
session end), so a flat hourly TTL is plenty. Cache is best-effort — if the
process restarts the next request rebuilds.
"""
from __future__ import annotations

import time
from typing import Dict, Optional

from fastapi import APIRouter, Depends

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.race_predictor_service import RacePrediction, predict_for_user

logger = get_logger(__name__)

router = APIRouter(prefix="/cardio-prediction", tags=["Cardio Prediction"])


# ---------------------------------------------------------------------------
# Tiny per-user TTL cache
# ---------------------------------------------------------------------------

_CACHE_TTL_SECONDS = 3600  # 1h
_cache: Dict[str, tuple[float, Dict[str, Optional[RacePrediction]]]] = {}


def _cache_get(user_id: str) -> Optional[Dict[str, Optional[RacePrediction]]]:
    hit = _cache.get(user_id)
    if not hit:
        return None
    expires_at, payload = hit
    if expires_at < time.time():
        _cache.pop(user_id, None)
        return None
    return payload


def _cache_put(user_id: str, payload: Dict[str, Optional[RacePrediction]]) -> None:
    _cache[user_id] = (time.time() + _CACHE_TTL_SECONDS, payload)


def _invalidate(user_id: str) -> None:
    """Exposed for callers that mutate cardio_logs (bulk import) to bust
    this user's cache. Not currently wired — TTL is short enough that any
    new import surfaces within an hour."""
    _cache.pop(user_id, None)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@router.get("/races")
async def get_race_predictions(current_user: dict = Depends(get_current_user)):
    """Predictions for {five_k, ten_k, half_marathon, marathon}.

    Values are either a RacePrediction dict (predicted_seconds, distance_m,
    base_run, confidence, formula, age_days_of_base) or null.
    """
    user_id = current_user["id"]
    cached = _cache_get(user_id)
    if cached is not None:
        return _serialize(cached)
    try:
        db = get_supabase_db()
        result = predict_for_user(db, user_id)
        _cache_put(user_id, result)
        return _serialize(result)
    except Exception as e:
        logger.error(f"[RacePredictor] endpoint failed user={user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "race_predictor")


def _serialize(predictions: Dict[str, Optional[RacePrediction]]) -> Dict[str, Optional[dict]]:
    return {
        key: (value.model_dump(mode="json") if value is not None else None)
        for key, value in predictions.items()
    }
