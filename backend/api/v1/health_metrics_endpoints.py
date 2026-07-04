"""
Health metrics API — Vitals + Heart Health Score.

GET /api/v1/health/vitals        → 5 overnight signals vs personal baseline
                                     + grounded narration.
GET /api/v1/health/heart-health  → fused 0-100 Heart Health Score + components
                                     + day-over-day delta + grounded narration.

Both resolve local_date in the user's timezone (X-User-Timezone header / ?tz /
users.timezone), read from daily_activity + body_measurements, and degrade
honestly when a signal has no data (no fabricated numbers — CLAUDE.md).
"""
from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query, Request

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.timezone_utils import user_today_date
from services.vitals_service import VitalsResponse, build_vitals_response
from services.heart_health_service import (
    HeartHealthResponse,
    build_heart_health_response,
)

logger = get_logger(__name__)
router = APIRouter(prefix="/health", tags=["Health Metrics"])


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


def _local_date(request: Request, db, user_id: str, date_q: str | None) -> date:
    if date_q:
        try:
            return date.fromisoformat(date_q)
        except ValueError:
            pass
    return user_today_date(request, db, user_id)


@router.get("/vitals", response_model=VitalsResponse)
async def get_vitals(
    request: Request,
    date: str | None = Query(None, description="YYYY-MM-DD; defaults to user-local today"),
    current_user: dict = Depends(get_current_user),
) -> VitalsResponse:
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        ld = _local_date(request, db, user_id, date)
        return await build_vitals_response(db, user_id, ld, _first_name(db, user_id))
    except Exception as e:
        logger.error(f"[vitals] error: {e}", exc_info=True)
        raise safe_internal_error(e, "vitals")


@router.get("/heart-health", response_model=HeartHealthResponse)
async def get_heart_health(
    request: Request,
    date: str | None = Query(None, description="YYYY-MM-DD; defaults to user-local today"),
    current_user: dict = Depends(get_current_user),
) -> HeartHealthResponse:
    user_id = current_user["id"]
    try:
        db = get_supabase_db()
        ld = _local_date(request, db, user_id, date)
        return await build_heart_health_response(db, user_id, ld, _first_name(db, user_id))
    except Exception as e:
        logger.error(f"[heart_health] error: {e}", exc_info=True)
        raise safe_internal_error(e, "heart_health")
