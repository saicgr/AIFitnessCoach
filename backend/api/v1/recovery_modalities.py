"""Recovery-modality logging API (Gap 8).

Cold plunge / ice bath / contrast / massage / foam rolling / etc. Mirrors the
sauna logging endpoints. Logged modalities feed the coach's recovery context
(so it can ease next-day load) and a small bounded recovery-score bonus.

ENDPOINTS:
- POST   /api/v1/recovery-modalities/log
- GET    /api/v1/recovery-modalities/daily/{user_id}
- GET    /api/v1/recovery-modalities/logs/{user_id}
- DELETE /api/v1/recovery-modalities/log/{log_id}
"""
import uuid
from datetime import datetime, date, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.auth import (
    get_current_user,
    verify_resource_ownership,
    verify_user_ownership,
)
from core.activity_logger import log_user_activity, log_user_error
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.timezone_utils import get_user_today, resolve_timezone
from models.recovery_modality import (
    RECOVERY_MODALITIES,
    DailyRecoveryModalitySummary,
    RecoveryModalityLog,
    RecoveryModalityLogCreate,
)

router = APIRouter()
logger = get_logger(__name__)


def _normalize_modality(raw: str) -> str:
    """Map free-text to a known modality; unknown → 'other' (never 422)."""
    t = (raw or "").strip().lower().replace(" ", "_").replace("-", "_")
    if t in RECOVERY_MODALITIES:
        return t
    # Loose aliases.
    if "cold" in t or "plunge" in t:
        return "cold_plunge"
    if "ice" in t:
        return "ice_bath"
    if "contrast" in t:
        return "contrast"
    if "massage" in t or "rub" in t:
        return "massage"
    if "foam" in t or "roll" in t:
        return "foam_rolling"
    if "compress" in t or "boot" in t:
        return "compression"
    if "stretch" in t or "mobility" in t:
        return "stretching"
    return "other"


def row_to_log(row: dict) -> RecoveryModalityLog:
    return RecoveryModalityLog(
        id=row.get("id"),
        user_id=row.get("user_id"),
        modality=row.get("modality"),
        duration_minutes=row.get("duration_minutes"),
        temperature_c=row.get("temperature_c"),
        notes=row.get("notes"),
        logged_at=row.get("logged_at"),
    )


@router.post("/log", response_model=RecoveryModalityLog)
async def log_recovery_modality(
    data: RecoveryModalityLogCreate,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Log a recovery-modality session (cold plunge, massage, contrast, …)."""
    logger.info(f"Logging recovery modality for {data.user_id}: {data.modality}")
    try:
        verify_user_ownership(current_user, data.user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, data.user_id)

        modality = _normalize_modality(data.modality)
        utc_now = datetime.utcnow()
        local_date = data.local_date or get_user_today(user_tz)

        log_data = {
            "id": str(uuid.uuid4()),
            "user_id": data.user_id,
            "modality": modality,
            "duration_minutes": data.duration_minutes,
            "temperature_c": data.temperature_c,
            "notes": data.notes,
            "logged_at": utc_now.isoformat(),
            "local_date": local_date,
        }
        result = db.client.table("recovery_modality_logs").insert(log_data).execute()
        if not result.data:
            raise safe_internal_error(ValueError("Failed to log recovery modality"), "recovery_modality")

        await log_user_activity(
            user_id=data.user_id,
            action="recovery_modality_log",
            endpoint="/api/v1/recovery-modalities/log",
            message=f"Logged {modality}"
            + (f" ({data.duration_minutes}min)" if data.duration_minutes else ""),
            metadata={"modality": modality, "duration_minutes": data.duration_minutes},
            status_code=200,
        )
        return row_to_log(result.data[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error logging recovery modality: {e}", exc_info=True)
        await log_user_error(
            user_id=data.user_id,
            action="recovery_modality_log",
            error=e,
            endpoint="/api/v1/recovery-modalities/log",
            status_code=500,
        )
        raise safe_internal_error(e, "endpoint")


@router.get("/daily/{user_id}", response_model=DailyRecoveryModalitySummary)
async def get_daily_recovery_modalities(
    user_id: str,
    http_request: Request,
    date_str: Optional[str] = Query(None, description="YYYY-MM-DD, defaults to today"),
    current_user: dict = Depends(get_current_user),
):
    """Daily recovery-modality summary."""
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, user_id)

        target_date = (
            datetime.fromisoformat(date_str).date()
            if date_str
            else date.fromisoformat(get_user_today(user_tz))
        )
        target_date_str = target_date.isoformat()

        result = None
        try:
            result = db.client.table("recovery_modality_logs").select("*").eq(
                "user_id", user_id
            ).eq("local_date", target_date_str).order("logged_at", desc=True).execute()
        except Exception as local_date_err:
            if "local_date" in str(local_date_err):
                result = None
            else:
                raise

        if result is None or not result.data:
            start_of_day = datetime.combine(target_date, datetime.min.time())
            end_of_day = datetime.combine(target_date, datetime.max.time())
            result = db.client.table("recovery_modality_logs").select("*").eq(
                "user_id", user_id
            ).gte("logged_at", start_of_day.isoformat()).lte(
                "logged_at", end_of_day.isoformat()
            ).order("logged_at", desc=True).execute()

        logs = [row_to_log(row) for row in (result.data or [])]
        total_minutes = sum(log.duration_minutes or 0 for log in logs)
        modalities = list(dict.fromkeys(log.modality for log in logs))
        return DailyRecoveryModalitySummary(
            date=target_date.isoformat(),
            total_minutes=total_minutes,
            modalities=modalities,
            entries=logs,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting daily recovery modalities: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.get("/logs/{user_id}", response_model=List[RecoveryModalityLog])
async def get_recovery_modality_logs(
    user_id: str,
    http_request: Request,
    days: int = Query(default=7, ge=1, le=90),
    limit: int = Query(default=100, ge=1, le=500),
    current_user: dict = Depends(get_current_user),
):
    """Recovery-modality logs for the last N days."""
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, user_id)
        today = date.fromisoformat(get_user_today(user_tz))
        start_date = datetime.combine(today - timedelta(days=days), datetime.min.time())
        result = db.client.table("recovery_modality_logs").select("*").eq(
            "user_id", user_id
        ).gte("logged_at", start_date.isoformat()).order(
            "logged_at", desc=True
        ).limit(limit).execute()
        return [row_to_log(row) for row in (result.data or [])]
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting recovery modality logs: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.delete("/log/{log_id}")
async def delete_recovery_modality_log(
    log_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a recovery-modality log entry."""
    try:
        db = get_supabase_db()
        fetch_result = db.client.table("recovery_modality_logs").select("*").eq(
            "id", log_id
        ).maybe_single().execute()
        log = fetch_result.data if fetch_result else None
        verify_resource_ownership(current_user, log, "Recovery modality log")
        result = db.client.table("recovery_modality_logs").delete().eq("id", log_id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="Recovery modality log not found")
        return {"status": "deleted", "id": log_id}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting recovery modality log: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")
