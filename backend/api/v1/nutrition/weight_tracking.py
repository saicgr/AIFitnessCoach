"""Weight logging and trend tracking endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger

from api.v1.nutrition.models import (
    WeightLogCreate,
    WeightLogResponse,
    WeightTrendResponse,
)

router = APIRouter()
logger = get_logger(__name__)

@router.post("/weight-logs", response_model=WeightLogResponse)
async def create_weight_log(request: WeightLogCreate, current_user: dict = Depends(get_current_user)):
    """
    Log a weight entry for a user.

    Used for tracking weight over time and enabling adaptive TDEE calculations.
    """
    logger.info(f"Creating weight log for user {request.user_id}: {request.weight_kg} kg")

    try:
        db = get_supabase_db()

        log_data = {
            "user_id": request.user_id,
            "weight_kg": request.weight_kg,
            "logged_at": (request.logged_at or datetime.utcnow()).isoformat(),
            "source": request.source,
        }
        if request.notes:
            log_data["notes"] = request.notes

        result = db.client.table("weight_logs")\
            .insert(log_data)\
            .execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to create weight log"), "nutrition")

        data = result.data[0]
        return WeightLogResponse(
            id=data["id"],
            user_id=data["user_id"],
            weight_kg=float(data["weight_kg"]),
            logged_at=datetime.fromisoformat(str(data["logged_at"]).replace("Z", "+00:00")),
            source=data.get("source", "manual"),
            notes=data.get("notes"),
            created_at=datetime.fromisoformat(str(data["created_at"]).replace("Z", "+00:00")) if data.get("created_at") else None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create weight log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/weight-logs/{user_id}", response_model=List[WeightLogResponse])
async def get_weight_logs(
    user_id: str,
    current_user: dict = Depends(get_current_user),
    limit: int = Query(30, description="Maximum number of logs to return"),
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
):
    """
    Get weight logs for a user.

    Returns logs sorted by date descending (newest first).
    """
    logger.info(f"Getting weight logs for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("weight_logs")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("logged_at", desc=True)\
            .limit(limit)

        if from_date:
            query = query.gte("logged_at", f"{from_date}T00:00:00")
        if to_date:
            query = query.lte("logged_at", f"{to_date}T23:59:59")

        result = query.execute()

        logs = []
        for data in (result.data or []):
            logs.append(WeightLogResponse(
                id=data["id"],
                user_id=data["user_id"],
                weight_kg=float(data["weight_kg"]),
                logged_at=datetime.fromisoformat(str(data["logged_at"]).replace("Z", "+00:00")),
                source=data.get("source", "manual"),
                notes=data.get("notes"),
                created_at=datetime.fromisoformat(str(data["created_at"]).replace("Z", "+00:00")) if data.get("created_at") else None,
            ))

        return logs

    except Exception as e:
        logger.error(f"Failed to get weight logs: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.delete("/weight-logs/{log_id}")
async def delete_weight_log(
    log_id: str,
    current_user: dict = Depends(get_current_user),
    user_id: str = Query(..., description="User ID for verification"),
):
    """
    Delete a weight log entry.
    """
    logger.info(f"Deleting weight log {log_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("weight_logs")\
            .delete()\
            .eq("id", log_id)\
            .eq("user_id", user_id)\
            .execute()

        return {"success": True, "message": "Weight log deleted"}

    except Exception as e:
        logger.error(f"Failed to delete weight log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/weight-logs/{user_id}/trend", response_model=WeightTrendResponse)
async def get_weight_trend(
    request: Request,
    user_id: str,
    days: int = Query(14, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate weight trend from recent weight logs.

    Uses exponential moving average for smoothing.
    """
    logger.info(f"Calculating weight trend for user {user_id} over {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        today_str = get_user_today(user_tz)
        from_date_obj = datetime.strptime(today_str, "%Y-%m-%d") - timedelta(days=days)
        from_date = from_date_obj.isoformat()

        result = db.client.table("weight_logs")\
            .select("weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", from_date)\
            .order("logged_at", desc=False)\
            .execute()

        logs = result.data or []

        if len(logs) < 2:
            return WeightTrendResponse(
                direction="maintaining",
                days_analyzed=len(logs),
                confidence=0.0,
            )

        # Get start and end weights (simple moving average of first/last 3 entries)
        start_weights = [float(log["weight_kg"]) for log in logs[:min(3, len(logs))]]
        end_weights = [float(log["weight_kg"]) for log in logs[-min(3, len(logs)):]]

        start_weight = sum(start_weights) / len(start_weights)
        end_weight = sum(end_weights) / len(end_weights)
        change_kg = end_weight - start_weight

        # Calculate weekly rate
        days_between = (datetime.fromisoformat(str(logs[-1]["logged_at"]).replace("Z", "+00:00")) -
                       datetime.fromisoformat(str(logs[0]["logged_at"]).replace("Z", "+00:00"))).days
        if days_between > 0:
            weekly_rate = (change_kg / days_between) * 7
        else:
            weekly_rate = 0.0

        # Determine direction
        if change_kg < -0.2:
            direction = "losing"
        elif change_kg > 0.2:
            direction = "gaining"
        else:
            direction = "maintaining"

        # Confidence based on number of data points
        confidence = min(1.0, len(logs) / 10)

        return WeightTrendResponse(
            start_weight=round(start_weight, 2),
            end_weight=round(end_weight, 2),
            change_kg=round(change_kg, 2),
            weekly_rate_kg=round(weekly_rate, 2),
            direction=direction,
            days_analyzed=days_between or 1,
            confidence=round(confidence, 2),
        )

    except Exception as e:
        logger.error(f"Failed to calculate weight trend: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")
