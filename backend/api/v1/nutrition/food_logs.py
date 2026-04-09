"""Food log CRUD endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta
from typing import List, Optional
import json
import time

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today, get_user_now_iso, target_date_to_utc_iso
from core.auth import get_current_user, verify_resource_ownership
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity
from core.supabase_client import get_supabase
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias

from api.v1.nutrition.models import (
    FoodLogResponse,
    UpdateFoodLogRequest,
    UpdateMoodRequest,
)

router = APIRouter()
logger = get_logger(__name__)


@router.get("/food-logs/{user_id}", response_model=List[FoodLogResponse])
async def list_food_logs(
    user_id: str,
    request: Request,
    limit: int = Query(default=50, le=500),
    from_date: Optional[str] = Query(default=None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(default=None, description="End date (YYYY-MM-DD)"),
    meal_type: Optional[str] = Query(default=None, description="Filter by meal type"),
    current_user: dict = Depends(get_current_user),
):
    """
    List food logs for a user.

    Optional filters:
    - from_date: Filter logs from this date
    - to_date: Filter logs until this date
    - meal_type: Filter by meal type (breakfast, lunch, dinner, snack)
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Listing food logs for user {user_id}, limit={limit}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        # Convert date-only params to timezone-aware UTC ranges
        tz_from = None
        tz_to = None
        if from_date and len(from_date) == 10:  # YYYY-MM-DD only
            tz_from, _ = local_date_to_utc_range(from_date, user_tz)
        else:
            tz_from = from_date
        if to_date and len(to_date) == 10:
            _, tz_to = local_date_to_utc_range(to_date, user_tz)
        else:
            tz_to = to_date

        logs = db.list_food_logs(
            user_id=user_id,
            from_date=tz_from,
            to_date=tz_to,
            meal_type=meal_type,
            limit=limit
        )

        # Format response
        result = []
        for log in logs:
            result.append(FoodLogResponse(
                id=log.get("id"),
                user_id=log.get("user_id"),
                meal_type=log.get("meal_type"),
                logged_at=str(log.get("logged_at", "")),
                food_items=log.get("food_items", []),
                total_calories=log.get("total_calories", 0),
                protein_g=log.get("protein_g", 0),
                carbs_g=log.get("carbs_g", 0),
                fat_g=log.get("fat_g", 0),
                fiber_g=log.get("fiber_g"),
                health_score=log.get("health_score"),
                ai_feedback=log.get("ai_feedback"),
                created_at=str(log.get("created_at") or log.get("logged_at") or ""),
            ))

        logger.info(f"Returning {len(result)} food logs for user {user_id}")
        return result

    except Exception as e:
        logger.error(f"Failed to list food logs: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/food-logs/{user_id}/{log_id}", response_model=FoodLogResponse)
async def get_food_log(user_id: str, log_id: str, current_user: dict = Depends(get_current_user)):
    """Get a specific food log."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting food log {log_id} for user {user_id}")

    try:
        db = get_supabase_db()
        log = db.get_food_log(log_id)

        if not log:
            raise HTTPException(status_code=404, detail="Food log not found")

        # Verify ownership
        if log.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        return FoodLogResponse(
            id=log.get("id"),
            user_id=log.get("user_id"),
            meal_type=log.get("meal_type"),
            logged_at=str(log.get("logged_at", "")),
            food_items=log.get("food_items", []),
            total_calories=log.get("total_calories", 0),
            protein_g=log.get("protein_g", 0),
            carbs_g=log.get("carbs_g", 0),
            fat_g=log.get("fat_g", 0),
            fiber_g=log.get("fiber_g"),
            health_score=log.get("health_score"),
            ai_feedback=log.get("ai_feedback"),
            created_at=str(log.get("created_at") or log.get("logged_at") or ""),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get food log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.delete("/food-logs/{log_id}")
async def delete_food_log(log_id: str, current_user: dict = Depends(get_current_user)):
    """Delete a food log."""
    logger.info(f"Deleting food log {log_id}")

    try:
        db = get_supabase_db()
        log = db.get_food_log(log_id)
        verify_resource_ownership(current_user, log, "Food log")
        success = db.delete_food_log(log_id)

        if not success:
            raise HTTPException(status_code=404, detail="Food log not found")

        return {"status": "deleted", "id": log_id, "soft_deleted": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete food log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.put("/food-logs/{log_id}")
async def update_food_log(log_id: str, body: UpdateFoodLogRequest, current_user: dict = Depends(get_current_user)):
    """Update macros/weight on an existing food log (e.g. after portion adjustment)."""
    user_id = current_user.get("id") or current_user.get("sub")
    logger.info(f"Updating food log {log_id} for user {user_id}")

    try:
        db = get_supabase_db()
        updated = db.update_food_log(
            log_id=log_id,
            user_id=user_id,
            total_calories=body.total_calories,
            protein_g=body.protein_g,
            carbs_g=body.carbs_g,
            fat_g=body.fat_g,
            fiber_g=body.fiber_g,
            weight_g=body.weight_g,
        )

        if not updated:
            raise HTTPException(status_code=404, detail="Food log not found or not owned by user")

        return {
            "status": "updated",
            "id": log_id,
            "total_calories": updated.get("total_calories"),
            "protein_g": updated.get("protein_g"),
            "carbs_g": updated.get("carbs_g"),
            "fat_g": updated.get("fat_g"),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update food log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.patch("/food-logs/{log_id}/mood")
async def update_food_log_mood(log_id: str, body: UpdateMoodRequest, current_user: dict = Depends(get_current_user)):
    """Update mood/wellness tracking on an existing food log (post-logging review)."""
    user_id = current_user.get("id") or current_user.get("sub")
    logger.info(f"Updating mood for food log {log_id}: before={body.mood_before}, after={body.mood_after}, energy={body.energy_level}")

    try:
        supabase = get_supabase()
        update_data = {}
        if body.mood_before is not None:
            update_data["mood_before"] = body.mood_before
        if body.mood_after is not None:
            update_data["mood_after"] = body.mood_after
        if body.energy_level is not None:
            update_data["energy_level"] = max(1, min(5, body.energy_level))

        if not update_data:
            return {"status": "no_changes", "id": log_id}

        result = supabase.client.table("food_logs").update(update_data).eq(
            "id", log_id
        ).eq(
            "user_id", user_id
        ).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Food log not found or not owned by user")

        return {"status": "updated", "id": log_id, **update_data}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update food log mood: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/food-logs/{log_id}/copy")
async def copy_food_log(log_id: str, http_request: Request, meal_type: str = Query(..., description="Target meal type"), target_date: Optional[str] = Query(None, description="Target date YYYY-MM-DD; defaults to now"), current_user: dict = Depends(get_current_user)):
    """Copy an existing food log to a different meal type (or the same). Optionally specify a target date."""
    logger.info(f"Copying food log {log_id} to {meal_type}, target_date={target_date}")

    try:
        db = get_supabase_db()

        # Get the source food log
        source = db.get_food_log(log_id)
        if not source:
            raise HTTPException(status_code=404, detail="Food log not found")

        # Resolve timezone for logged_at timestamp
        user_tz = resolve_timezone(http_request, db, source["user_id"])
        if target_date:
            user_tz_logged_at = target_date_to_utc_iso(target_date, user_tz)
        else:
            user_tz_logged_at = get_user_now_iso(user_tz)

        # Create a new food log with the same data but different meal type
        created_log = db.create_food_log(
            user_id=source["user_id"],
            meal_type=meal_type,
            food_items=source.get("food_items", []),
            total_calories=source.get("total_calories", 0),
            protein_g=source.get("protein_g", 0),
            carbs_g=source.get("carbs_g", 0),
            fat_g=source.get("fat_g", 0),
            fiber_g=source.get("fiber_g", 0),
            health_score=source.get("health_score"),
            logged_at=user_tz_logged_at,
            source_type=source.get("source_type", "text"),
        )

        food_log_id = created_log.get("id") if created_log else "unknown"
        logger.info(f"Copied food log {log_id} -> {food_log_id} as {meal_type}")

        return {
            "status": "copied",
            "source_id": log_id,
            "new_id": food_log_id,
            "meal_type": meal_type,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to copy food log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")
