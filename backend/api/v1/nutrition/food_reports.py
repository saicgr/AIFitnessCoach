"""Food reporting and modifier search endpoints."""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.food_analysis_cache_service import (
    _FOOD_MODIFIERS,
    _MODIFIER_METADATA,
    _classify_modifier,
    _build_default_modifiers,
)

from api.v1.nutrition.models import (
    FoodReportRequest,
    FoodReportResponse,
)

router = APIRouter()
logger = get_logger(__name__)

@router.post("/food-report", response_model=FoodReportResponse)
async def report_food(request: FoodReportRequest, current_user: dict = Depends(get_current_user)):
    """
    Report incorrect food nutrition data or submit user corrections.

    Users can flag foods with wrong data and optionally provide corrected values.
    Corrected values will be used for that user's future lookups.
    """
    # Always use authenticated user's ID, not client-provided value
    user_id = current_user.get("id") or current_user.get("sub") or request.user_id
    logger.info(f"Food report from user {user_id} for '{request.food_name}'")

    try:
        from core.db import get_supabase_db
        db = get_supabase_db()

        report_data = {
            "user_id": user_id,
            "food_name": request.food_name,
            "reported_issue": request.reported_issue,
            "original_calories": request.original_calories,
            "original_protein": request.original_protein,
            "original_carbs": request.original_carbs,
            "original_fat": request.original_fat,
            "corrected_calories": request.corrected_calories,
            "corrected_protein": request.corrected_protein,
            "corrected_carbs": request.corrected_carbs,
            "corrected_fat": request.corrected_fat,
            "data_source": request.data_source,
            "food_log_id": request.food_log_id,
            "status": "pending",
        }

        # Traceability fields (only include if provided to avoid null JSONB issues)
        if request.report_type:
            report_data["report_type"] = request.report_type
        if request.original_query:
            report_data["original_query"] = request.original_query
        if request.analysis_response is not None:
            report_data["analysis_response"] = request.analysis_response
        if request.all_food_items is not None:
            report_data["all_food_items"] = request.all_food_items

        if request.food_database_id:
            report_data["food_database_id"] = request.food_database_id

        result = db.client.table("food_reports").insert(report_data).execute()

        if result.data and len(result.data) > 0:
            report_id = result.data[0].get("id", "unknown")
        else:
            report_id = "unknown"

        logger.info(f"Food report created: {report_id}")

        return FoodReportResponse(
            success=True,
            report_id=str(report_id),
            message="Food report submitted successfully. Thank you for helping improve our data!",
        )

    except Exception as e:
        logger.error(f"Failed to create food report: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


# ── Modifier search ───────────────────────────────────────────────
@router.get("/modifier-search")
async def search_modifiers(
    q: str = Query(..., min_length=2, description="Search query for modifier phrases"),
    _user=Depends(get_current_user),
):
    """
    Search food modifiers by substring match (case-insensitive).
    Returns top 10 matching modifier entries with type, delta, and weight metadata.
    Pure in-memory lookup — no DB call.
    """
    q_lower = q.lower()
    results = []
    for phrase, delta in _FOOD_MODIFIERS.items():
        if q_lower in phrase:
            meta = _MODIFIER_METADATA.get(phrase)
            mod_type = meta.type if meta else _classify_modifier(phrase)
            entry = {
                "phrase": phrase,
                "type": mod_type.value,
                "delta": {
                    "calories": delta[0],
                    "protein_g": delta[1],
                    "carbs_g": delta[2],
                    "fat_g": delta[3],
                    "fiber_g": delta[4],
                },
                "default_weight_g": meta.default_weight_g if meta else None,
                "weight_per_unit_g": meta.weight_per_unit_g if meta else None,
                "unit_name": meta.unit_name if meta else None,
                "display_label": meta.display_label if meta else None,
            }
            results.append(entry)
            if len(results) >= 10:
                break
    return {"results": results, "count": len(results)}


# ── Food modifiers (contextual) ──────────────────────────────────
@router.get("/food-modifiers")
async def get_food_modifiers(
    food_name: str = Query(..., min_length=1, description="Food name to get contextual modifiers for"),
    _user=Depends(get_current_user),
):
    """
    Return contextual modifier groups for a given food name.
    E.g. steak → doneness options, chicken → cooking method options.
    Pure in-memory lookup — no DB call.
    """
    modifiers = _build_default_modifiers(food_name)
    return {"food_name": food_name, "modifiers": modifiers}
