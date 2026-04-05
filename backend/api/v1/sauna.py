"""
Sauna Logging API endpoints.

ENDPOINTS:
- POST /api/v1/sauna/log - Log sauna session
- GET  /api/v1/sauna/daily/{user_id} - Get daily sauna summary
- GET  /api/v1/sauna/logs/{user_id} - Get sauna logs
- DELETE /api/v1/sauna/log/{log_id} - Delete a sauna log
"""
from core.db import get_supabase_db
from fastapi import APIRouter, HTTPException, Query, Request, Depends
from typing import List, Optional
from datetime import datetime, date, timedelta
import uuid

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.timezone_utils import resolve_timezone, get_user_today
from models.sauna import SaunaLog, SaunaLogCreate, DailySaunaSummary
from core.auth import get_current_user, verify_user_ownership, verify_resource_ownership
from core.exceptions import safe_internal_error

router = APIRouter()
logger = get_logger(__name__)


def _estimate_sauna_calories(duration_minutes: int, weight_kg: float = None, height_cm: float = None, age: int = None, gender: str = None) -> int:
    """
    Estimate calories burned during sauna using Mifflin-St Jeor BMR.
    Formula: (BMR / 24) * 1.5 * (minutes / 60)
    Fallback: 1.5 * minutes if profile data is incomplete.
    """
    if weight_kg and height_cm and age and gender:
        # Mifflin-St Jeor equation
        if gender.lower() in ('female', 'f'):
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161
        else:
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
        calories = (bmr / 24) * 1.5 * (duration_minutes / 60)
    else:
        # Fallback: rough average (~75 cal/hr at rest * 1.5)
        calories = 1.5 * duration_minutes
    return max(1, round(calories))


def _get_user_profile(db, user_id: str) -> dict:
    """Fetch user profile data needed for BMR calculation."""
    try:
        result = db.client.table("users").select(
            "weight_kg, height_cm, age, gender"
        ).eq("id", user_id).single().execute()
        return result.data or {}
    except Exception:
        return {}


def row_to_sauna_log(row: dict) -> SaunaLog:
    """Convert a Supabase row dict to SaunaLog model."""
    return SaunaLog(
        id=row.get("id"),
        user_id=row.get("user_id"),
        workout_id=row.get("workout_id"),
        duration_minutes=row.get("duration_minutes"),
        estimated_calories=row.get("estimated_calories"),
        notes=row.get("notes"),
        logged_at=row.get("logged_at"),
    )


@router.post("/log", response_model=SaunaLog)
async def log_sauna(
    data: SaunaLogCreate, http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Log a sauna session with automatic calorie estimation."""
    logger.info(f"Logging sauna for user {data.user_id}: {data.duration_minutes}min")

    try:
        verify_user_ownership(current_user, data.user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, data.user_id)

        # Get user profile for BMR calculation
        profile = _get_user_profile(db, data.user_id)
        estimated_calories = _estimate_sauna_calories(
            duration_minutes=data.duration_minutes,
            weight_kg=profile.get("weight_kg"),
            height_cm=profile.get("height_cm"),
            age=profile.get("age"),
            gender=profile.get("gender"),
        )

        utc_now = datetime.utcnow()
        local_date = data.local_date or get_user_today(user_tz)

        log_data = {
            "id": str(uuid.uuid4()),
            "user_id": data.user_id,
            "workout_id": data.workout_id,
            "duration_minutes": data.duration_minutes,
            "estimated_calories": estimated_calories,
            "notes": data.notes,
            "logged_at": utc_now.isoformat(),
            "local_date": local_date,
        }

        result = db.client.table("sauna_logs").insert(log_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to log sauna session")

        await log_user_activity(
            user_id=data.user_id,
            action="sauna_log",
            endpoint="/api/v1/sauna/log",
            message=f"Logged {data.duration_minutes}min sauna (~{estimated_calories} cal)",
            metadata={
                "duration_minutes": data.duration_minutes,
                "estimated_calories": estimated_calories,
            },
            status_code=200
        )

        return row_to_sauna_log(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error logging sauna: {e}")
        await log_user_error(
            user_id=data.user_id,
            action="sauna_log",
            error=e,
            endpoint="/api/v1/sauna/log",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")


@router.get("/daily/{user_id}", response_model=DailySaunaSummary)
async def get_daily_sauna(
    user_id: str,
    http_request: Request,
    date_str: Optional[str] = Query(None, description="Date in YYYY-MM-DD format, defaults to today"),
    current_user: dict = Depends(get_current_user),
):
    """Get daily sauna summary for a user."""
    logger.info(f"Getting daily sauna for user {user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, user_id)

        if date_str:
            target_date = datetime.fromisoformat(date_str).date()
        else:
            target_date = date.fromisoformat(get_user_today(user_tz))

        target_date_str = target_date.isoformat()

        # Try local_date first, fallback to logged_at range
        result = None
        try:
            result = db.client.table("sauna_logs").select("*").eq(
                "user_id", user_id
            ).eq(
                "local_date", target_date_str
            ).order("logged_at", desc=True).execute()
        except Exception as local_date_err:
            if "local_date" in str(local_date_err):
                result = None
            else:
                raise

        if result is None or not result.data:
            start_of_day = datetime.combine(target_date, datetime.min.time())
            end_of_day = datetime.combine(target_date, datetime.max.time())
            result = db.client.table("sauna_logs").select("*").eq(
                "user_id", user_id
            ).gte(
                "logged_at", start_of_day.isoformat()
            ).lte(
                "logged_at", end_of_day.isoformat()
            ).order("logged_at", desc=True).execute()

        logs = [row_to_sauna_log(row) for row in (result.data or [])]
        total_minutes = sum(log.duration_minutes for log in logs)
        total_calories = sum(log.estimated_calories or 0 for log in logs)

        return DailySaunaSummary(
            date=target_date.isoformat(),
            total_minutes=total_minutes,
            total_calories=total_calories,
            entries=logs,
        )

    except Exception as e:
        logger.error(f"Error getting daily sauna: {e}")
        raise safe_internal_error(e, "endpoint")


@router.get("/logs/{user_id}", response_model=List[SaunaLog])
async def get_sauna_logs(
    user_id: str,
    http_request: Request,
    workout_id: Optional[str] = None,
    days: int = Query(default=7, ge=1, le=90),
    limit: int = Query(default=100, ge=1, le=500),
    current_user: dict = Depends(get_current_user),
):
    """Get sauna logs for a user, optionally filtered by workout."""
    logger.info(f"Getting sauna logs for user {user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, user_id)

        today = date.fromisoformat(get_user_today(user_tz))
        start_date = datetime.combine(today - timedelta(days=days), datetime.min.time())

        query = db.client.table("sauna_logs").select("*").eq(
            "user_id", user_id
        ).gte(
            "logged_at", start_date.isoformat()
        )

        if workout_id:
            query = query.eq("workout_id", workout_id)

        result = query.order("logged_at", desc=True).limit(limit).execute()

        return [row_to_sauna_log(row) for row in (result.data or [])]

    except Exception as e:
        logger.error(f"Error getting sauna logs: {e}")
        raise safe_internal_error(e, "endpoint")


@router.delete("/log/{log_id}")
async def delete_sauna_log(
    log_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a sauna log entry."""
    logger.info(f"Deleting sauna log {log_id}")

    try:
        db = get_supabase_db()

        # Fetch log and verify ownership before deleting
        fetch_result = db.client.table("sauna_logs").select("*").eq("id", log_id).maybe_single().execute()
        log = fetch_result.data if fetch_result else None
        verify_resource_ownership(current_user, log, "Sauna log")

        result = db.client.table("sauna_logs").delete().eq("id", log_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Sauna log not found")

        return {"status": "deleted", "id": log_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting sauna log: {e}")
        raise safe_internal_error(e, "endpoint")
