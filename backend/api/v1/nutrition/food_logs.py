"""Food log CRUD endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta
from typing import List, Optional
import json
import time

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today, get_user_now_iso, target_date_to_utc_iso, to_utc_iso
from core.auth import get_current_user, verify_resource_ownership
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.activity_logger import log_user_activity
from core.supabase_client import get_supabase
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from api.v1.nutrition.helpers import resign_food_image_url

from api.v1.nutrition.models import (
    FoodLogResponse,
    UpdateFoodLogRequest,
    UpdateMoodRequest,
    FoodItemEditResponse,
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
                logged_at=to_utc_iso(log.get("logged_at")),
                food_items=log.get("food_items", []),
                total_calories=log.get("total_calories", 0),
                protein_g=log.get("protein_g", 0),
                carbs_g=log.get("carbs_g", 0),
                fat_g=log.get("fat_g", 0),
                fiber_g=log.get("fiber_g"),
                health_score=log.get("health_score"),
                ai_feedback=log.get("ai_feedback"),
                notes=log.get("notes"),
                mood_before=log.get("mood_before"),
                mood_after=log.get("mood_after"),
                energy_level=log.get("energy_level"),
                sodium_mg=log.get("sodium_mg"),
                sugar_g=log.get("sugar_g"),
                saturated_fat_g=log.get("saturated_fat_g"),
                cholesterol_mg=log.get("cholesterol_mg"),
                potassium_mg=log.get("potassium_mg"),
                calcium_mg=log.get("calcium_mg"),
                iron_mg=log.get("iron_mg"),
                vitamin_a_ug=log.get("vitamin_a_ug"),
                vitamin_c_mg=log.get("vitamin_c_mg"),
                vitamin_d_iu=log.get("vitamin_d_iu"),
                inflammation_score=log.get("inflammation_score"),
                is_ultra_processed=log.get("is_ultra_processed"),
                image_url=resign_food_image_url(log.get("image_url")),
                created_at=to_utc_iso(log.get("created_at") or log.get("logged_at")),
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
            logged_at=to_utc_iso(log.get("logged_at")),
            food_items=log.get("food_items", []),
            total_calories=log.get("total_calories", 0),
            protein_g=log.get("protein_g", 0),
            carbs_g=log.get("carbs_g", 0),
            fat_g=log.get("fat_g", 0),
            fiber_g=log.get("fiber_g"),
            health_score=log.get("health_score"),
            ai_feedback=log.get("ai_feedback"),
            notes=log.get("notes"),
            mood_before=log.get("mood_before"),
            mood_after=log.get("mood_after"),
            energy_level=log.get("energy_level"),
            sodium_mg=log.get("sodium_mg"),
            sugar_g=log.get("sugar_g"),
            saturated_fat_g=log.get("saturated_fat_g"),
            cholesterol_mg=log.get("cholesterol_mg"),
            potassium_mg=log.get("potassium_mg"),
            calcium_mg=log.get("calcium_mg"),
            iron_mg=log.get("iron_mg"),
            vitamin_a_ug=log.get("vitamin_a_ug"),
            vitamin_c_mg=log.get("vitamin_c_mg"),
            vitamin_d_iu=log.get("vitamin_d_iu"),
            inflammation_score=log.get("inflammation_score"),
            is_ultra_processed=log.get("is_ultra_processed"),
            image_url=log.get("image_url"),
            created_at=to_utc_iso(log.get("created_at") or log.get("logged_at")),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get food log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.delete("/food-logs/{log_id}")
async def delete_food_log(log_id: str, current_user: dict = Depends(get_current_user)):
    """Delete a food log. Idempotent — returns success if already soft-deleted."""
    logger.info(f"Deleting food log {log_id}")

    try:
        db = get_supabase_db()
        log = db.get_food_log(log_id)

        if log is None:
            # Check if it was already soft-deleted (vs never existed)
            existing = db.client.table("food_logs").select("id, user_id, deleted_at").eq("id", log_id).execute()
            if existing.data:
                row = existing.data[0]
                # Verify ownership even for already-deleted logs
                user_id = current_user.get("id") or current_user.get("sub")
                if row.get("user_id") == user_id and row.get("deleted_at"):
                    logger.info(f"Food log {log_id} already soft-deleted — returning success")
                    return {"status": "deleted", "id": log_id, "soft_deleted": True}
            raise HTTPException(status_code=404, detail="Food log not found")

        verify_resource_ownership(current_user, log, "Food log")
        success = db.delete_food_log(log_id)

        if not success:
            raise HTTPException(status_code=404, detail="Food log not found")

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        user_id = log.get("user_id") or current_user.get("id") or current_user.get("sub")
        await invalidate_daily_summary_cache(user_id)

        await log_user_activity(
            user_id=user_id,
            action="food_log_deleted",
            endpoint="/api/v1/nutrition/food-logs/{log_id}",
            message=f"Deleted food log {log_id} ({log.get('meal_type', 'unknown')} — {log.get('total_calories', 0)} cal)",
            metadata={"food_log_id": log_id, "meal_type": log.get("meal_type"), "total_calories": log.get("total_calories", 0)},
            status_code=200,
        )

        return {"status": "deleted", "id": log_id, "soft_deleted": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete food log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.put("/food-logs/{log_id}")
async def update_food_log(log_id: str, body: UpdateFoodLogRequest, current_user: dict = Depends(get_current_user)):
    """Update fields on an existing food log. All fields are optional for partial updates."""
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
            meal_type=body.meal_type,
            logged_at=body.logged_at,
            notes=body.notes,
            food_items=body.food_items,
        )

        if not updated:
            raise HTTPException(status_code=404, detail="Food log not found or not owned by user")

        # Persist any per-field audit rows alongside the update. Audit writes
        # must never fail the update — they are best-effort.
        edits_recorded = 0
        if body.item_edits:
            try:
                edits_recorded = db.insert_food_log_edits(
                    user_id=user_id,
                    food_log_id=log_id,
                    edits=[e.dict() for e in body.item_edits],
                    edit_source='post_save_nutrition_screen',
                )
            except Exception as edit_err:
                logger.warning(f"Failed to record post-save item edits for {log_id}: {edit_err}")

            # Also UPSERT per-user overrides so the next log of the same food
            # defaults to the user's corrected values. One UPSERT per edited
            # item index — merges cross-field edits into a single override row.
            try:
                items_after_update = body.food_items or (updated.get("food_items") or [])
                edited_indices = {e.food_item_index for e in body.item_edits}
                for idx in edited_indices:
                    if 0 <= idx < len(items_after_update):
                        db.upsert_user_food_override(
                            user_id=user_id,
                            food_item=items_after_update[idx],
                        )
            except Exception as ov_err:
                logger.warning(
                    f"Failed to upsert user_food_overrides for {log_id}: {ov_err}"
                )

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        await invalidate_daily_summary_cache(user_id)

        # Determine edit actions for logging
        edit_actions = [e.edited_field for e in body.item_edits] if body.item_edits else []
        await log_user_activity(
            user_id=user_id,
            action="food_log_updated",
            endpoint="/api/v1/nutrition/food-logs/{log_id}",
            message=f"Updated food log {log_id} ({edits_recorded} edits: {', '.join(edit_actions[:5])})",
            metadata={
                "food_log_id": log_id,
                "edits_recorded": edits_recorded,
                "edit_actions": edit_actions[:10],
                "total_calories": updated.get("total_calories", 0),
            },
            status_code=200,
        )

        return {
            "status": "updated",
            "id": log_id,
            "total_calories": updated.get("total_calories"),
            "protein_g": updated.get("protein_g"),
            "carbs_g": updated.get("carbs_g"),
            "fat_g": updated.get("fat_g"),
            "meal_type": updated.get("meal_type"),
            "edits_recorded": edits_recorded,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update food log: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/food-logs/{log_id}/edits", response_model=List[FoodItemEditResponse])
async def list_food_log_edits(log_id: str, current_user: dict = Depends(get_current_user)):
    """Return the per-field edit history for a food log (newest first)."""
    user_id = current_user.get("id") or current_user.get("sub")
    try:
        db = get_supabase_db()
        rows = db.list_food_log_edits(user_id=user_id, food_log_id=log_id)
        # Normalize timestamps/UUIDs to strings for the pydantic response model
        return [
            FoodItemEditResponse(
                id=str(r["id"]),
                food_log_id=str(r["food_log_id"]),
                food_item_index=int(r["food_item_index"]),
                food_item_name=r["food_item_name"],
                food_item_id=r.get("food_item_id"),
                edited_field=r["edited_field"],
                previous_value=float(r["previous_value"]),
                updated_value=float(r["updated_value"]),
                edit_source=r["edit_source"],
                edited_at=str(r["edited_at"]),
            )
            for r in rows
        ]
    except Exception as e:
        logger.error(f"Failed to list food log edits: {e}", exc_info=True)
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
            inflammation_score=source.get("inflammation_score"),
            is_ultra_processed=source.get("is_ultra_processed"),
        )

        food_log_id = created_log.get("id") if created_log else "unknown"
        logger.info(f"Copied food log {log_id} -> {food_log_id} as {meal_type}")

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        await invalidate_daily_summary_cache(source["user_id"])

        await log_user_activity(
            user_id=source["user_id"],
            action="food_log_copied",
            endpoint="/api/v1/nutrition/food-logs/{log_id}/copy",
            message=f"Copied food log {log_id} → {food_log_id} as {meal_type} ({source.get('total_calories', 0)} cal)",
            metadata={"source_id": log_id, "new_id": food_log_id, "meal_type": meal_type, "total_calories": source.get("total_calories", 0)},
            status_code=200,
        )

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
