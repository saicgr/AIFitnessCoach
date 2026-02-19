"""
Hydration Tracking API endpoints.

ENDPOINTS:
- POST /api/v1/hydration/log - Log hydration intake
- GET  /api/v1/hydration/daily/{user_id} - Get daily hydration summary
- GET  /api/v1/hydration/logs/{user_id} - Get hydration logs
- DELETE /api/v1/hydration/log/{log_id} - Delete a hydration log
- PUT /api/v1/hydration/goal/{user_id} - Update daily hydration goal
- GET /api/v1/hydration/goal/{user_id} - Get user's hydration goal
"""
from fastapi import APIRouter, HTTPException, Query, Request
from typing import List, Optional
from datetime import datetime, date, timedelta
import uuid

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.timezone_utils import resolve_timezone, get_user_today
from models.schemas import (
    HydrationLog, HydrationLogCreate,
    DailyHydrationSummary, HydrationGoalUpdate,
)

router = APIRouter()
logger = get_logger(__name__)

# Default daily hydration goal in ml (about 84 oz)
DEFAULT_DAILY_GOAL_ML = 2500


def row_to_hydration_log(row: dict) -> HydrationLog:
    """Convert a Supabase row dict to HydrationLog model."""
    return HydrationLog(
        id=row.get("id"),
        user_id=row.get("user_id"),
        drink_type=row.get("drink_type"),
        amount_ml=row.get("amount_ml"),
        workout_id=row.get("workout_id"),
        notes=row.get("notes"),
        logged_at=row.get("logged_at"),
    )


# ==================== Hydration Logging ====================

@router.post("/log", response_model=HydrationLog)
async def log_hydration(data: HydrationLogCreate, http_request: Request):
    """
    Log a hydration intake entry.

    drink_type options: "water", "protein_shake", "sports_drink", "coffee", "other"
    """
    logger.info(f"Logging hydration for user {data.user_id}: {data.amount_ml}ml {data.drink_type}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, data.user_id)

        # Use client's local date if provided, otherwise derive from user timezone
        utc_now = datetime.utcnow()
        local_date = data.local_date or get_user_today(user_tz)

        log_data = {
            "id": str(uuid.uuid4()),
            "user_id": data.user_id,
            "drink_type": data.drink_type,
            "amount_ml": data.amount_ml,
            "workout_id": data.workout_id,
            "notes": data.notes,
            "logged_at": utc_now.isoformat(),
            "local_date": local_date,
        }

        result = db.client.table("hydration_logs").insert(log_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create hydration log")

        # Log hydration entry
        await log_user_activity(
            user_id=data.user_id,
            action="hydration_log",
            endpoint="/api/v1/hydration/log",
            message=f"Logged {data.amount_ml}ml {data.drink_type}",
            metadata={
                "amount_ml": data.amount_ml,
                "drink_type": data.drink_type,
            },
            status_code=200
        )

        return row_to_hydration_log(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error logging hydration: {e}")
        await log_user_error(
            user_id=data.user_id,
            action="hydration_log",
            error=e,
            endpoint="/api/v1/hydration/log",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/daily/{user_id}", response_model=DailyHydrationSummary)
async def get_daily_hydration(
    user_id: str,
    http_request: Request,
    date_str: Optional[str] = Query(None, description="Date in YYYY-MM-DD format, defaults to today"),
):
    """Get daily hydration summary for a user."""
    logger.info(f"Getting daily hydration for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, user_id)

        # Parse date or use today in user's timezone
        if date_str:
            target_date = datetime.fromisoformat(date_str).date()
        else:
            target_date = date.fromisoformat(get_user_today(user_tz))

        target_date_str = target_date.isoformat()

        # Try filtering by local_date first (timezone-correct)
        # Fall back to logged_at range for older entries without local_date
        result = db.client.table("hydration_logs").select("*").eq(
            "user_id", user_id
        ).eq(
            "local_date", target_date_str
        ).order("logged_at", desc=True).execute()

        # If no results with local_date, fall back to logged_at range (legacy data)
        if not result.data:
            start_of_day = datetime.combine(target_date, datetime.min.time())
            end_of_day = datetime.combine(target_date, datetime.max.time())
            result = db.client.table("hydration_logs").select("*").eq(
                "user_id", user_id
            ).gte(
                "logged_at", start_of_day.isoformat()
            ).lte(
                "logged_at", end_of_day.isoformat()
            ).order("logged_at", desc=True).execute()

        logs = [row_to_hydration_log(row) for row in (result.data or [])]

        # Calculate totals by type
        water_ml = sum(log.amount_ml for log in logs if log.drink_type == "water")
        protein_shake_ml = sum(log.amount_ml for log in logs if log.drink_type == "protein_shake")
        sports_drink_ml = sum(log.amount_ml for log in logs if log.drink_type == "sports_drink")
        other_ml = sum(log.amount_ml for log in logs if log.drink_type in ["coffee", "other"])
        total_ml = water_ml + protein_shake_ml + sports_drink_ml + other_ml

        # Get user's goal (from user_settings or default)
        goal_ml = await get_user_hydration_goal(user_id)
        goal_percentage = round((total_ml / goal_ml) * 100, 1) if goal_ml > 0 else 0

        return DailyHydrationSummary(
            date=target_date.isoformat(),
            total_ml=total_ml,
            water_ml=water_ml,
            protein_shake_ml=protein_shake_ml,
            sports_drink_ml=sports_drink_ml,
            other_ml=other_ml,
            goal_ml=goal_ml,
            goal_percentage=goal_percentage,
            entries=logs,
        )

    except Exception as e:
        logger.error(f"Error getting daily hydration: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/logs/{user_id}", response_model=List[HydrationLog])
async def get_hydration_logs(
    user_id: str,
    http_request: Request,
    workout_id: Optional[str] = None,
    days: int = Query(default=7, ge=1, le=90),
    limit: int = Query(default=100, ge=1, le=500),
):
    """Get hydration logs for a user, optionally filtered by workout."""
    logger.info(f"Getting hydration logs for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, user_id)

        # Calculate date range based on user's timezone
        today = date.fromisoformat(get_user_today(user_tz))
        start_date = datetime.combine(today - timedelta(days=days), datetime.min.time())

        query = db.client.table("hydration_logs").select("*").eq(
            "user_id", user_id
        ).gte(
            "logged_at", start_date.isoformat()
        )

        if workout_id:
            query = query.eq("workout_id", workout_id)

        result = query.order("logged_at", desc=True).limit(limit).execute()

        return [row_to_hydration_log(row) for row in (result.data or [])]

    except Exception as e:
        logger.error(f"Error getting hydration logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/log/{log_id}")
async def delete_hydration_log(log_id: str):
    """Delete a hydration log entry."""
    logger.info(f"Deleting hydration log {log_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("hydration_logs").delete().eq("id", log_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Hydration log not found")

        return {"status": "deleted", "id": log_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting hydration log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Hydration Goals ====================

async def get_user_hydration_goal(user_id: str) -> int:
    """Get user's daily hydration goal from settings."""
    try:
        db = get_supabase_db()

        result = db.client.table("user_settings").select("hydration_goal_ml").eq(
            "user_id", user_id
        ).single().execute()

        if result.data and result.data.get("hydration_goal_ml"):
            return result.data["hydration_goal_ml"]

        return DEFAULT_DAILY_GOAL_ML

    except Exception:
        return DEFAULT_DAILY_GOAL_ML


@router.get("/goal/{user_id}")
async def get_hydration_goal(user_id: str):
    """Get user's daily hydration goal."""
    goal = await get_user_hydration_goal(user_id)
    return {"user_id": user_id, "daily_goal_ml": goal}


@router.put("/goal/{user_id}")
async def update_hydration_goal(user_id: str, data: HydrationGoalUpdate):
    """Update user's daily hydration goal."""
    logger.info(f"Updating hydration goal for user {user_id} to {data.daily_goal_ml}ml")

    try:
        db = get_supabase_db()

        # Upsert into user_settings
        result = db.client.table("user_settings").upsert({
            "user_id": user_id,
            "hydration_goal_ml": data.daily_goal_ml,
            "updated_at": datetime.utcnow().isoformat(),
        }, on_conflict="user_id").execute()

        return {"user_id": user_id, "daily_goal_ml": data.daily_goal_ml}

    except Exception as e:
        logger.error(f"Error updating hydration goal: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Quick Log Helpers ====================

@router.post("/quick-log/{user_id}")
async def quick_log_hydration(
    user_id: str,
    http_request: Request,
    drink_type: str = Query(default="water"),
    amount_ml: int = Query(default=250),  # Default glass of water ~8oz
    workout_id: Optional[str] = None,
    local_date: Optional[str] = Query(default=None),
):
    """
    Quick log hydration with minimal parameters.

    Common amounts:
    - Glass of water: 250ml (8oz)
    - Water bottle: 500ml (16oz)
    - Large bottle: 750ml (24oz)
    - Protein shake: 350ml (12oz)
    """
    return await log_hydration(HydrationLogCreate(
        user_id=user_id,
        drink_type=drink_type,
        amount_ml=amount_ml,
        workout_id=workout_id,
        local_date=local_date,
    ), http_request)
