"""Food log CRUD endpoints."""
import asyncio
from core.db import get_supabase_db
from datetime import date, datetime, time as dt_time, timedelta
from typing import List, Optional
import json
import time
import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, Header, HTTPException, Query, Request
from pydantic import BaseModel

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today, get_user_now_iso, target_date_to_utc_iso, to_utc_iso
from core.auth import get_current_user, verify_resource_ownership
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.activity_logger import log_user_activity
from core.supabase_client import get_supabase
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from core.locale import parse_accept_language, overlay_food_i18n
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
    limit: int = Query(default=50, le=1000),
    from_date: Optional[str] = Query(default=None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(default=None, description="End date (YYYY-MM-DD)"),
    meal_type: Optional[str] = Query(default=None, description="Filter by meal type"),
    tz: Optional[str] = Query(default=None, description="IANA timezone fallback"),
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
        if user_tz == "UTC" and tz:
            from core.timezone_utils import _is_valid_tz  # type: ignore[attr-defined]
            if _is_valid_tz(tz):
                user_tz = tz

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

        # Synchronous Supabase call — offload to a thread so the blocking DB
        # round-trip doesn't stall this async worker's event loop under load.
        logs = await asyncio.get_event_loop().run_in_executor(
            None,
            lambda: db.list_food_logs(
                user_id=user_id,
                from_date=tz_from,
                to_date=tz_to,
                meal_type=meal_type,
                limit=limit,
            ),
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
                health_score_reasons=log.get("health_score_reasons"),
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
                vitamin_e_mg=log.get("vitamin_e_mg"),
                vitamin_k_ug=log.get("vitamin_k_ug"),
                vitamin_b6_mg=log.get("vitamin_b6_mg"),
                vitamin_b12_ug=log.get("vitamin_b12_ug"),
                vitamin_b9_ug=log.get("vitamin_b9_ug"),
                magnesium_mg=log.get("magnesium_mg"),
                zinc_mg=log.get("zinc_mg"),
                phosphorus_mg=log.get("phosphorus_mg"),
                selenium_ug=log.get("selenium_ug"),
                copper_mg=log.get("copper_mg"),
                manganese_mg=log.get("manganese_mg"),
                omega3_g=log.get("omega3_g"),
                inflammation_score=log.get("inflammation_score"),
                is_ultra_processed=log.get("is_ultra_processed"),
                image_url=resign_food_image_url(log.get("image_url")),
                idempotency_key=log.get("idempotency_key"),
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
            health_score_reasons=log.get("health_score_reasons"),
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
            vitamin_e_mg=log.get("vitamin_e_mg"),
            vitamin_k_ug=log.get("vitamin_k_ug"),
            vitamin_b6_mg=log.get("vitamin_b6_mg"),
            vitamin_b12_ug=log.get("vitamin_b12_ug"),
            vitamin_b9_ug=log.get("vitamin_b9_ug"),
            magnesium_mg=log.get("magnesium_mg"),
            zinc_mg=log.get("zinc_mg"),
            phosphorus_mg=log.get("phosphorus_mg"),
            selenium_ug=log.get("selenium_ug"),
            copper_mg=log.get("copper_mg"),
            manganese_mg=log.get("manganese_mg"),
            omega3_g=log.get("omega3_g"),
            inflammation_score=log.get("inflammation_score"),
            is_ultra_processed=log.get("is_ultra_processed"),
            image_url=log.get("image_url"),
            idempotency_key=log.get("idempotency_key"),
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
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        user_id = log.get("user_id") or current_user.get("id") or current_user.get("sub")
        await invalidate_daily_summary_cache(user_id)
        await invalidate_bootstrap_cache(user_id)

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
                edited_names = []
                for idx in edited_indices:
                    if 0 <= idx < len(items_after_update):
                        db.upsert_user_food_override(
                            user_id=user_id,
                            food_item=items_after_update[idx],
                        )
                        nm = (items_after_update[idx] or {}).get("name")
                        if nm:
                            edited_names.append(nm)
                # F2 — bust the GLOBAL AI-analysis cache for each corrected food
                # text so the next re-log re-runs analysis and re-stores a fresh
                # baseline (the cache holds the pre-override AI value; a stale
                # entry would otherwise keep returning the old estimate).
                if edited_names:
                    try:
                        from services.food_analysis.cache_service import (
                            get_food_analysis_cache_service,
                        )
                        _cache_svc = get_food_analysis_cache_service()
                        for nm in edited_names:
                            await _cache_svc.invalidate_cache(nm)
                    except Exception as inv_err:
                        logger.warning(f"Food-text cache invalidation skipped: {inv_err}")
            except Exception as ov_err:
                logger.warning(
                    f"Failed to upsert user_food_overrides for {log_id}: {ov_err}"
                )

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        await invalidate_daily_summary_cache(user_id)
        await invalidate_bootstrap_cache(user_id)

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


@router.get("/food-logs/{log_id}/image-url")
async def refresh_food_log_image_url(log_id: str, current_user: dict = Depends(get_current_user)):
    """Return a fresh 24-hour presigned URL for a food log's image.

    Clients call this when a cached image URL has expired (Image.network
    errorBuilder fires) to avoid showing a broken thumbnail indefinitely
    on old logs. Returns 404 if the log has no image or doesn't belong to
    this user.
    """
    user_id = current_user.get("id") or current_user.get("sub")
    try:
        db = get_supabase_db()
        log = db.get_food_log(log_id)
        if not log or log.get("user_id") != user_id:
            raise HTTPException(status_code=404, detail="Food log not found")
        image_url = log.get("image_url")
        if not image_url:
            raise HTTPException(status_code=404, detail="No image for this log")
        fresh = resign_food_image_url(image_url)
        return {"image_url": fresh}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to refresh food log image URL: {e}", exc_info=True)
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
            input_type="copy",
            inflammation_score=source.get("inflammation_score"),
            is_ultra_processed=source.get("is_ultra_processed"),
            health_score_reasons=source.get("health_score_reasons"),
        )

        food_log_id = created_log.get("id") if created_log else "unknown"
        logger.info(f"Copied food log {log_id} -> {food_log_id} as {meal_type}")

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        await invalidate_daily_summary_cache(source["user_id"])
        await invalidate_bootstrap_cache(source["user_id"])

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


# ─────────────────────────────────────────────────────────────────
# Save-as-Recipe (migration 2056 + recipe_persistence + Gemini enrichment)
# ─────────────────────────────────────────────────────────────────

class SaveAsRecipeResponse(BaseModel):
    recipe_id: str
    merged: bool
    cook_event_id: Optional[str] = None


@router.post("/food-logs/{log_id}/save-as-recipe", response_model=SaveAsRecipeResponse)
async def save_food_log_as_recipe(
    log_id: str,
    background_tasks: BackgroundTasks,
    item_index: Optional[int] = Query(
        default=None,
        ge=0,
        description="If set, build a single-ingredient recipe from food_items[item_index] only.",
    ),
    create_cook_event: bool = Query(
        default=False,
        description="When true and the resulting recipe has servings>1, create a recipe_cook_events row "
                    "with portions_remaining = servings - 1 (one was just consumed via this food_log) "
                    "so the user can re-log leftovers from the active cook events list.",
    ),
    current_user: dict = Depends(get_current_user),
):
    """Convert a logged meal into a reusable user_recipes row via Gemini enrichment.

    Pipeline:
      1. Load food_log; 404 if missing or not owned by caller.
      2. Gemini reconstructs full recipe (instructions, quantities, prep/cook).
      3. recipe_persistence.persist_recipe handles dedupe-by-name_normalized
         (using the GENERATED column from migration 2056), inserts user_recipes
         + recipe_ingredients, and queues ChromaDB indexing as a background task.
      4. Set food_logs.recipe_id = new_recipe.id — this fires the
         update_recipe_log_count() trigger so times_logged becomes 1.
      5. Optionally create a recipe_cook_events row (batch-cook leftovers).

    Per feedback_no_silent_fallbacks.md: any failure in Gemini / persistence /
    linkage propagates as a real HTTP error — no degraded "saved without
    instructions" fallback.
    """
    user_id = current_user.get("id") or current_user.get("sub")
    db = get_supabase_db()

    food_log = db.get_food_log(log_id)
    if not food_log or food_log.get("user_id") != user_id:
        raise HTTPException(status_code=404, detail="Food log not found")

    if item_index is not None:
        items = food_log.get("food_items") or []
        if item_index < 0 or item_index >= len(items):
            raise HTTPException(status_code=400, detail="item_index out of range")

    # ── Gemini enrichment.
    from services.recipe_enrichment_service import get_recipe_enrichment_service
    from services.recipe_persistence import persist_recipe

    enrichment = get_recipe_enrichment_service()
    try:
        recipe_create = await enrichment.enrich_food_log_to_recipe(
            food_log,
            single_item_index=item_index,
            image_url=food_log.get("image_url"),
        )
    except Exception as e:
        logger.error(f"[save-as-recipe] Gemini enrichment failed for log {log_id}: {e}", exc_info=True)
        raise HTTPException(status_code=502, detail=f"Recipe enrichment failed: {e}")

    # ── Persist (dedupes by name_normalized; merges if same recipe exists).
    try:
        result = await persist_recipe(
            user_id=user_id,
            request=recipe_create,
            background_tasks=background_tasks,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[save-as-recipe] persist failed for log {log_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")

    recipe = result.recipe

    # ── Link the food_log to the recipe (skip if it's already linked or merged
    # to the same recipe — avoids re-firing update_recipe_log_count).
    food_log_recipe_id = food_log.get("recipe_id")
    cook_event_id: Optional[str] = None
    update_payload: dict = {}

    if food_log_recipe_id != recipe.id:
        update_payload["recipe_id"] = recipe.id

    # ── Optional cook event (batch cooking).
    if create_cook_event and recipe.servings and recipe.servings > 1:
        cook_event_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        try:
            db.client.table("recipe_cook_events").insert({
                "id": cook_event_id,
                "user_id": user_id,
                "recipe_id": recipe.id,
                "cooked_at": now,
                "portions_made": recipe.servings,
                "portions_remaining": max(0, recipe.servings - 1),
                "storage": "fridge",
                "expires_at": (datetime.utcnow() + timedelta(days=4)).isoformat(),
                "notes": None,
                "created_at": now,
                "updated_at": now,
            }).execute()
            update_payload["cook_event_id"] = cook_event_id
            update_payload["servings_consumed"] = 1
        except Exception as e:
            # Cook event failure shouldn't block the recipe save — log + continue.
            logger.warning(f"[save-as-recipe] cook_event create failed: {e}")
            cook_event_id = None

    if update_payload:
        try:
            db.client.table("food_logs").update(update_payload).eq("id", log_id).eq("user_id", user_id).execute()
        except Exception as e:
            logger.warning(f"[save-as-recipe] food_logs link update failed: {e}")
        # The update_recipe_log_count() trigger only fires on INSERT, so bump
        # times_logged manually when retroactively linking an existing log.
        # Skip when "merged" — re-saving the same meal-as-recipe shouldn't
        # double-count the underlying log.
        if "recipe_id" in update_payload and not result.merged:
            try:
                from datetime import datetime as _dt
                now_iso = _dt.utcnow().isoformat()
                # Use raw RPC-style update since supabase-py doesn't expose `set`-with-expression.
                # Read-then-write is fine — concurrent saves of the same recipe are rare.
                cur = db.client.table("user_recipes").select("times_logged").eq("id", recipe.id).single().execute()
                prev = (cur.data or {}).get("times_logged") or 0
                db.client.table("user_recipes").update({
                    "times_logged": prev + 1,
                    "last_logged_at": now_iso,
                    "updated_at": now_iso,
                }).eq("id", recipe.id).execute()
            except Exception as e:
                logger.warning(f"[save-as-recipe] times_logged bump failed: {e}")

    await log_user_activity(
        user_id=user_id,
        action="food_log_saved_as_recipe",
        endpoint="/api/v1/nutrition/food-logs/{log_id}/save-as-recipe",
        message=(
            f"{'Merged into existing' if result.merged else 'Created'} recipe "
            f"{recipe.id} ({recipe.name}) from food_log {log_id}"
        ),
        metadata={
            "food_log_id": log_id,
            "recipe_id": recipe.id,
            "merged": result.merged,
            "cook_event_id": cook_event_id,
            "item_index": item_index,
            "servings": recipe.servings,
        },
        status_code=200,
    )

    return SaveAsRecipeResponse(
        recipe_id=recipe.id,
        merged=result.merged,
        cook_event_id=cook_event_id,
    )


# ─────────────────────────────────────────────────────────────────
# Schedule from food log — chains through Save-as-Recipe when needed.
# Migration 2057 cadence shapes flow through ScheduledRecipeLogCreate.
# ─────────────────────────────────────────────────────────────────


class ScheduleFromFoodLogRequest(BaseModel):
    """Schedule spec accepted by `/food-logs/{log_id}/schedule`.

    Mirrors `ScheduledRecipeLogCreate` minus `recipe_id` (we resolve it from
    the food_log: reuse `food_logs.recipe_id` if present, else run the full
    Save-as-Recipe pipeline first). Keeps the client API single-call: one
    POST → recipe persisted (if needed) + schedule row created.
    """
    # ── ScheduleSpec fields ────────────────────────────────────
    meal_type: str  # breakfast|lunch|dinner|snack — validated by ScheduledRecipeLogCreate
    servings: float = 1.0
    timezone: str
    silent_log: bool = False
    schedule_kind: str  # daily|weekdays|weekends|custom|once
    days_of_week: Optional[List[int]] = None
    local_time: str  # "HH:MM" or "HH:MM:SS"
    until_date: Optional[str] = None       # YYYY-MM-DD
    interval_days: int = 1
    is_temporary_week_only: bool = False
    occurrences_remaining: Optional[int] = None
    # ── Save-as-Recipe pass-through ────────────────────────────
    item_index: Optional[int] = None       # if recipe doesn't exist yet, scope save to one item
    create_cook_event: bool = False        # if creating recipe + multi-serving, mark leftovers


class ScheduleFromFoodLogResponse(BaseModel):
    schedule_id: str
    recipe_id: str
    next_fire_at: str
    merged: bool                           # whether the underlying recipe was reused vs newly created


@router.post("/food-logs/{log_id}/schedule", response_model=ScheduleFromFoodLogResponse)
async def schedule_from_food_log(
    log_id: str,
    request: ScheduleFromFoodLogRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Schedule a meal from a logged food_log. Chains through Save-as-Recipe
    when the food_log isn't already linked to a recipe so the user gets one
    combined toast (instead of "saved" then "scheduled")."""
    user_id = current_user.get("id") or current_user.get("sub")
    db = get_supabase_db()

    food_log = db.get_food_log(log_id)
    if not food_log or food_log.get("user_id") != user_id:
        raise HTTPException(status_code=404, detail="Food log not found")

    # Resolve recipe_id (reuse existing link, or save inline).
    recipe_id = food_log.get("recipe_id")
    merged = False
    if not recipe_id:
        from services.recipe_enrichment_service import get_recipe_enrichment_service
        from services.recipe_persistence import persist_recipe

        try:
            draft = await get_recipe_enrichment_service().enrich_food_log_to_recipe(
                food_log,
                single_item_index=request.item_index,
                image_url=food_log.get("image_url"),
            )
        except Exception as e:
            logger.error(f"[schedule] enrichment failed for log {log_id}: {e}", exc_info=True)
            raise HTTPException(status_code=502, detail=f"Recipe enrichment failed: {e}")

        try:
            res = await persist_recipe(user_id=user_id, request=draft, background_tasks=background_tasks)
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"[schedule] persist failed: {e}", exc_info=True)
            raise safe_internal_error(e, "nutrition")

        recipe_id = res.recipe.id
        merged = res.merged
        # Link the food_log so future "/save-as-recipe" calls hit the dedupe path.
        try:
            db.client.table("food_logs").update({"recipe_id": recipe_id}).eq("id", log_id).eq("user_id", user_id).execute()
        except Exception as e:
            logger.warning(f"[schedule] food_logs link failed: {e}")

    # ── Build the schedule via the existing endpoint's logic.
    from api.v1.nutrition.scheduled_recipes import (
        _next_fire_recurring,
        _week_end_date,
    )
    from models.scheduled_recipe_log import ScheduledRecipeLogCreate

    try:
        spec = ScheduledRecipeLogCreate(
            recipe_id=recipe_id,
            schedule_mode=ScheduleMode.RECURRING,
            meal_type=MealType(request.meal_type),
            servings=request.servings,
            timezone=request.timezone,
            silent_log=request.silent_log,
            schedule_kind=ScheduleKind(request.schedule_kind),
            days_of_week=request.days_of_week,
            local_time=dt_time.fromisoformat(request.local_time),
            until_date=date.fromisoformat(request.until_date) if request.until_date else None,
            interval_days=request.interval_days,
            is_temporary_week_only=request.is_temporary_week_only,
            occurrences_remaining=request.occurrences_remaining,
        )
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Invalid schedule spec: {e}")

    sched_id = str(uuid.uuid4())
    now_iso = datetime.utcnow().isoformat()
    next_fire = _next_fire_recurring(spec)

    week_end = None
    if spec.is_temporary_week_only:
        try:
            from zoneinfo import ZoneInfo
            tz = ZoneInfo(spec.timezone)
        except Exception:
            from datetime import timezone as _tz
            tz = _tz.utc
        week_end = _week_end_date(next_fire.astimezone(tz).date())

    row = {
        "id": sched_id,
        "user_id": user_id,
        "recipe_id": recipe_id,
        "schedule_mode": ScheduleMode.RECURRING.value,
        "meal_type": spec.meal_type.value,
        "servings": spec.servings,
        "schedule_kind": spec.schedule_kind.value,
        "days_of_week": spec.days_of_week,
        "local_time": spec.local_time.isoformat(),
        "timezone": spec.timezone,
        "next_fire_at": next_fire.isoformat(),
        "next_slot_index": 0,
        "enabled": True,
        "silent_log": spec.silent_log,
        "until_date": spec.until_date.isoformat() if spec.until_date else None,
        "interval_days": spec.interval_days,
        "is_temporary_week_only": spec.is_temporary_week_only,
        "week_end_date": week_end.isoformat() if week_end else None,
        "occurrences_remaining": (
            1 if spec.schedule_kind == ScheduleKind.ONCE else spec.occurrences_remaining
        ),
        "created_at": now_iso,
        "updated_at": now_iso,
    }
    try:
        db.client.table("scheduled_recipe_logs").insert(row).execute()
    except Exception as e:
        logger.error(f"[schedule] insert failed: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")

    await log_user_activity(
        user_id=user_id,
        action="food_log_scheduled",
        endpoint="/api/v1/nutrition/food-logs/{log_id}/schedule",
        message=f"Scheduled food_log {log_id} via recipe {recipe_id} ({spec.schedule_kind.value})",
        metadata={
            "food_log_id": log_id, "recipe_id": recipe_id, "schedule_id": sched_id,
            "schedule_kind": spec.schedule_kind.value, "interval_days": spec.interval_days,
            "is_temporary_week_only": spec.is_temporary_week_only,
            "until_date": row["until_date"], "merged_recipe": merged,
        },
        status_code=200,
    )

    return ScheduleFromFoodLogResponse(
        schedule_id=sched_id,
        recipe_id=recipe_id,
        next_fire_at=next_fire.isoformat(),
        merged=merged,
    )


# =============================================================================
# Phase-2 §2.9: Regional dish variants (powers per-item edit Region dropdown)
# =============================================================================

class DishVariant(BaseModel):
    id: int
    food_name_normalized: str
    display_name: str
    region: Optional[str] = None
    restaurant_name: Optional[str] = None
    calories_per_100g: Optional[float] = None
    protein_per_100g: Optional[float] = None
    carbs_per_100g: Optional[float] = None
    fat_per_100g: Optional[float] = None


class DishVariantsResponse(BaseModel):
    name: str
    variants: List[DishVariant]


@router.get("/dish-variants", response_model=DishVariantsResponse)
async def get_dish_variants(
    name: str = Query(..., min_length=2, max_length=100),
    current_user: dict = Depends(get_current_user),
    accept_language: Optional[str] = Header(default=None, alias="Accept-Language"),
):
    """Return regional/restaurant variants of a dish via fuzzy match.
    Used by the per-item edit sheet's Region dropdown.

    Accepts an Accept-Language header to return translated display_name values
    from food_nutrition_overrides_i18n when available. COALESCEs to English
    ('en') when no row exists for the requested locale.
    """
    from services.food_analysis.cache_service_phase2 import _normalize_food_name
    norm = _normalize_food_name(name)
    if not norm:
        return DishVariantsResponse(name=name, variants=[])

    db = get_supabase_db()
    locale = parse_accept_language(accept_language or "en")
    rows = []
    try:
        res = (
            db.client.table("food_nutrition_overrides")
            .select(
                "id,food_name_normalized,display_name,region,country_name,"
                "restaurant_name,calories_per_100g,protein_per_100g,"
                "carbs_per_100g,fat_per_100g"
            )
            .ilike("food_name_normalized", f"%{norm}%")
            .limit(10)
            .execute()
        )
        rows = res.data or []
    except Exception as e:
        logger.warning(f"[dish_variants] query failed for {name!r}: {e}")
        return DishVariantsResponse(name=name, variants=[])

    variants: List[DishVariant] = []
    for r in rows:
        # Apply i18n overlay: updates display_name from food_nutrition_overrides_i18n
        # when a non-en locale is requested and a translation row exists.
        r = dict(r)
        overlay_food_i18n(r, db, locale)
        variants.append(DishVariant(
            id=r.get("id"),
            food_name_normalized=r.get("food_name_normalized") or "",
            display_name=r.get("display_name") or "",
            region=r.get("region") or r.get("country_name"),
            restaurant_name=r.get("restaurant_name"),
            calories_per_100g=r.get("calories_per_100g"),
            protein_per_100g=r.get("protein_per_100g"),
            carbs_per_100g=r.get("carbs_per_100g"),
            fat_per_100g=r.get("fat_per_100g"),
        ))

    return DishVariantsResponse(name=name, variants=variants)


class DishVariantSwapRequest(BaseModel):
    food_log_id: str
    food_item_index: int = 0
    new_override_id: int


class DishVariantSwapResponse(BaseModel):
    success: bool
    new_calories: Optional[int] = None
    new_protein_g: Optional[float] = None
    new_carbs_g: Optional[float] = None
    new_fat_g: Optional[float] = None


@router.post("/dish-variants/swap", response_model=DishVariantSwapResponse)
async def swap_dish_variant(
    body: DishVariantSwapRequest,
    current_user: dict = Depends(get_current_user),
):
    """Swap a logged food_item to a different regional/restaurant variant."""
    db = get_supabase_db()
    user_id = current_user.get("id") or current_user.get("user_id")

    try:
        log_res = (
            db.client.table("food_logs")
            .select("*")
            .eq("id", body.food_log_id)
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        food_log = log_res.data
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"food_log not found: {e}")
    if not food_log:
        raise HTTPException(status_code=404, detail="food_log not found")

    try:
        ov_res = (
            db.client.table("food_nutrition_overrides")
            .select("*")
            .eq("id", body.new_override_id)
            .maybe_single()
            .execute()
        )
        override = ov_res.data
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"override not found: {e}")
    if not override:
        raise HTTPException(status_code=404, detail="override not found")

    items = food_log.get("food_items") or []
    if body.food_item_index >= len(items):
        raise HTTPException(status_code=400, detail="food_item_index out of range")

    weight_g = float(items[body.food_item_index].get("weight_g") or 100)
    ratio = weight_g / 100.0
    items[body.food_item_index].update({
        "name": override.get("display_name"),
        "calories": int(round((override.get("calories_per_100g") or 0) * ratio)),
        "protein_g": round((override.get("protein_per_100g") or 0) * ratio, 1),
        "carbs_g": round((override.get("carbs_per_100g") or 0) * ratio, 1),
        "fat_g": round((override.get("fat_per_100g") or 0) * ratio, 1),
        "fiber_g": round((override.get("fiber_per_100g") or 0) * ratio, 1),
        "override_id": body.new_override_id,
    })

    total_cal = sum(int(it.get("calories", 0)) for it in items)
    total_p = sum(float(it.get("protein_g", 0)) for it in items)
    total_c = sum(float(it.get("carbs_g", 0)) for it in items)
    total_f = sum(float(it.get("fat_g", 0)) for it in items)

    update_payload = {
        "food_items": items,
        "total_calories": total_cal,
        "total_protein_g": round(total_p, 1),
        "total_carbs_g": round(total_c, 1),
        "total_fat_g": round(total_f, 1),
    }
    try:
        db.client.table("food_logs").update(update_payload).eq("id", body.food_log_id).execute()
    except Exception as e:
        raise safe_internal_error(e, "nutrition")

    return DishVariantSwapResponse(
        success=True,
        new_calories=int(round((override.get("calories_per_100g") or 0) * ratio)),
        new_protein_g=round((override.get("protein_per_100g") or 0) * ratio, 1),
        new_carbs_g=round((override.get("carbs_per_100g") or 0) * ratio, 1),
        new_fat_g=round((override.get("fat_per_100g") or 0) * ratio, 1),
    )
