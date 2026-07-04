"""
Fitness Index API.

GET /api/v1/fitness-index → 5-axis fitness radar (body composition, cardio,
strength, endurance, flexibility), an overall, a goal-driven focus, and a
k-anonymous per-axis peer percentile. Snapshots to fitness_index_daily and
narrates the result (grounded + cost-capped). Honest nulls where an axis has
no data or the peer cohort is below the k-anonymity threshold.
"""
from __future__ import annotations

from datetime import date as _date

from fastapi import APIRouter, Depends, Query, Request

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.timezone_utils import user_today_date
from services.fitness_index_service import (
    FitnessIndexResponse,
    build_fitness_index_response,
)

logger = get_logger(__name__)
router = APIRouter(prefix="/fitness-index", tags=["Fitness Index"])


def _first_name(db, user_id: str) -> str:
    try:
        u = db.client.table("users").select(
            "name, email"
        ).eq("id", user_id).maybe_single().execute()
        if u and u.data:
            return (
                (u.data.get("name") or "").split(" ")[0]
                or (u.data.get("email") or "").split("@")[0]
                or "there"
            ).strip() or "there"
    except Exception:
        pass
    return "there"


@router.get("", response_model=FitnessIndexResponse)
async def get_fitness_index(
    request: Request,
    date: str | None = Query(None, description="YYYY-MM-DD; defaults to user-local today"),
    current_user: dict = Depends(get_current_user),
) -> FitnessIndexResponse:
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        ld = None
        if date:
            try:
                ld = _date.fromisoformat(date)
            except ValueError:
                ld = None
        if ld is None:
            ld = user_today_date(request, db, user_id)
        return await build_fitness_index_response(db, user_id, ld, _first_name(db, user_id))
    except Exception as e:
        logger.error(f"[fitness_index] error: {e}", exc_info=True)
        raise safe_internal_error(e, "fitness_index")
