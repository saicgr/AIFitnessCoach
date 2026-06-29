"""Per-exercise tracking-metric CRUD (Phase C of the generic metric feature).

Two resources, both keyed to the authenticated user:

  • custom metric DEFINITIONS  -> ``user_custom_metrics``        (scope='exercise')
  • per-exercise metric PREFS   -> ``user_exercise_metric_prefs`` (which columns
    a user wants to track for a given exercise, e.g. add "incline" to a treadmill)

Companion to ``services/metric_registry.py`` (the built-in catalog) — a user's
custom metric keys extend that catalog per-user; the prefs row records which
metric keys (built-in or custom) render as input columns for an exercise.

PATH NOTE: the custom-metric endpoints live at ``/metrics/exercise-custom`` —
NOT ``/metrics/custom`` — because ``/metrics/custom`` is already owned by the
HEALTH custom-metric feature (``api/v1/metrics.py`` + the Flutter
``metrics_repository.dart``), backed by the SAME ``user_custom_metrics`` table.
A ``scope`` discriminator (default 'health') keeps the two from colliding; see
migration 2296.
"""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/metrics", tags=["Exercise Metrics"])


# ---------------------------------------------------------------------------
# Pydantic bodies
# ---------------------------------------------------------------------------
class CustomMetricUpsert(BaseModel):
    """Body for POST /metrics/exercise-custom — a custom per-set metric def."""
    user_id: str
    key: str = Field(..., min_length=1, max_length=64)
    label: str = Field(..., min_length=1, max_length=120)
    unit: Optional[str] = Field(default=None, max_length=32)
    canonical_unit: Optional[str] = Field(default=None, max_length=32)
    input_type: Optional[str] = Field(default=None, max_length=32)


class ExercisePrefsUpsert(BaseModel):
    """Body for PUT /metrics/exercise-prefs — which metric keys an exercise tracks."""
    user_id: str
    exercise_id: str = Field(..., min_length=1)
    metric_keys: List[str] = Field(default_factory=list)


def _assert_owner(current_user: dict, user_id: str) -> None:
    if str(current_user.get("id")) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")


# ---------------------------------------------------------------------------
# Custom metric definitions
# ---------------------------------------------------------------------------
@router.get("/exercise-custom")
async def list_custom_metrics(
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """List a user's custom per-set tracking-metric definitions."""
    _assert_owner(current_user, user_id)
    db = get_supabase_db()
    try:
        result = (
            db.client.table("user_custom_metrics")
            .select("key,label,unit,canonical_unit,input_type")
            .eq("user_id", user_id)
            .eq("scope", "exercise")
            .order("created_at", desc=False)
            .execute()
        )
        return {"custom_metrics": result.data or []}
    except Exception as e:
        logger.error(f"❌ [exercise-metrics] list custom failed: {e}", exc_info=True)
        raise safe_internal_error(e, "metrics")


@router.post("/exercise-custom")
async def upsert_custom_metric(
    body: CustomMetricUpsert,
    current_user: dict = Depends(get_current_user),
):
    """Create or update a custom per-set metric definition (on_conflict user_id,key)."""
    _assert_owner(current_user, body.user_id)
    db = get_supabase_db()
    try:
        data = {
            "user_id": body.user_id,
            "key": body.key,
            "label": body.label,
            "unit": body.unit,
            "canonical_unit": body.canonical_unit,
            "input_type": body.input_type,
            "scope": "exercise",
        }
        result = (
            db.client.table("user_custom_metrics")
            .upsert(data, on_conflict="user_id,key")
            .execute()
        )
        row = (result.data or [{}])[0]
        logger.info(f"✅ [exercise-metrics] upserted custom key='{body.key}' for {body.user_id}")
        return {
            "custom_metric": {
                "key": row.get("key", body.key),
                "label": row.get("label", body.label),
                "unit": row.get("unit", body.unit),
                "canonical_unit": row.get("canonical_unit", body.canonical_unit),
                "input_type": row.get("input_type", body.input_type),
            }
        }
    except Exception as e:
        logger.error(f"❌ [exercise-metrics] upsert custom failed: {e}", exc_info=True)
        raise safe_internal_error(e, "metrics")


# ---------------------------------------------------------------------------
# Per-exercise metric preferences
# ---------------------------------------------------------------------------
@router.get("/exercise-prefs")
async def get_exercise_prefs(
    user_id: str = Query(...),
    exercise_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Return the metric keys a user has chosen to track for an exercise."""
    _assert_owner(current_user, user_id)
    db = get_supabase_db()
    try:
        result = (
            db.client.table("user_exercise_metric_prefs")
            .select("metric_keys")
            .eq("user_id", user_id)
            .eq("exercise_id", exercise_id)
            .limit(1)
            .execute()
        )
        keys = (result.data[0].get("metric_keys") if result.data else None) or []
        return {"metric_keys": keys}
    except Exception as e:
        logger.error(f"❌ [exercise-metrics] get prefs failed: {e}", exc_info=True)
        raise safe_internal_error(e, "metrics")


@router.put("/exercise-prefs")
async def put_exercise_prefs(
    body: ExercisePrefsUpsert,
    current_user: dict = Depends(get_current_user),
):
    """Upsert the metric keys for an exercise (on_conflict user_id,exercise_id)."""
    _assert_owner(current_user, body.user_id)
    db = get_supabase_db()
    try:
        from datetime import datetime, timezone

        data = {
            "user_id": body.user_id,
            "exercise_id": body.exercise_id,
            "metric_keys": body.metric_keys,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        result = (
            db.client.table("user_exercise_metric_prefs")
            .upsert(data, on_conflict="user_id,exercise_id")
            .execute()
        )
        row = (result.data or [{}])[0]
        logger.info(
            f"✅ [exercise-metrics] put prefs ex={body.exercise_id} "
            f"keys={body.metric_keys} for {body.user_id}"
        )
        return {"metric_keys": row.get("metric_keys", body.metric_keys)}
    except Exception as e:
        logger.error(f"❌ [exercise-metrics] put prefs failed: {e}", exc_info=True)
        raise safe_internal_error(e, "metrics")
