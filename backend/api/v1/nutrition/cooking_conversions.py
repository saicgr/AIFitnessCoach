"""Cooking conversion endpoints."""
from core.db import get_supabase_db
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity
from services.cooking_conversion_service import get_cooking_conversion_service

from api.v1.nutrition.models import (
    CookingConversionFactorResponse,
    ConvertWeightRequest,
    ConvertWeightResponse,
    CookingConversionsListResponse,
)

router = APIRouter()
logger = get_logger(__name__)

@router.get("/cooking-conversions", response_model=CookingConversionsListResponse)
async def list_cooking_conversions(
    category: Optional[str] = Query(None, description="Filter by food category (e.g., grains, meats, vegetables)"),
    search: Optional[str] = Query(None, description="Search for specific foods"),
    current_user: dict = Depends(get_current_user),
):
    """
    List all available cooking conversion factors.

    Use category to filter by food type (grains, legumes, meats, poultry, seafood, vegetables, eggs).
    Use search to find specific foods by name.
    """
    try:
        service = get_cooking_conversion_service()

        if search:
            # Search for specific foods
            conversions = service.search_foods(search)
        elif category:
            # Filter by category
            conversions = service.get_conversions_by_category(category)
        else:
            # Get all conversions
            conversions = service.get_all_conversions()

        return CookingConversionsListResponse(
            conversions=[CookingConversionFactorResponse(**c) for c in conversions],
            total_count=len(conversions),
            categories=service.get_available_categories(),
            cooking_methods=service.get_cooking_methods(),
        )

    except Exception as e:
        logger.error(f"Failed to list cooking conversions: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/cooking-conversions/{food_category}", response_model=List[CookingConversionFactorResponse])
async def get_cooking_conversions_by_category(food_category: str, current_user: dict = Depends(get_current_user)):
    """
    Get cooking conversion factors for a specific food category.

    Categories: grains, legumes, meats, poultry, seafood, vegetables, eggs
    """
    try:
        service = get_cooking_conversion_service()
        conversions = service.get_conversions_by_category(food_category)

        if not conversions:
            raise HTTPException(
                status_code=404,
                detail=f"No conversions found for category: {food_category}. "
                       f"Valid categories: {', '.join(service.get_available_categories())}"
            )

        return [CookingConversionFactorResponse(**c) for c in conversions]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get cooking conversions by category: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/convert-weight", response_model=ConvertWeightResponse)
async def convert_food_weight(request: ConvertWeightRequest, current_user: dict = Depends(get_current_user)):
    """
    Convert food weight between raw and cooked states.

    Examples:
    - Convert 100g raw rice to cooked weight: {"weight_g": 100, "food_name": "white_rice", "from_state": "raw"}
    - Convert 240g cooked rice to raw weight: {"weight_g": 240, "food_name": "white_rice", "from_state": "cooked"}
    - Convert with nutrients adjustment: include nutrients_per_100g to get adjusted nutrient values

    Ratios:
    - Grains/legumes have ratio > 1 (absorb water, increase in weight when cooked)
    - Meats/seafood have ratio < 1 (lose moisture, decrease in weight when cooked)
    """
    try:
        service = get_cooking_conversion_service()

        result = service.convert_weight(
            weight_g=request.weight_g,
            food_name=request.food_name,
            from_state=request.from_state,
            cooking_method=request.cooking_method,
            nutrients_per_100g=request.nutrients_per_100g,
        )

        if not result:
            raise HTTPException(
                status_code=404,
                detail=f"No conversion factor found for '{request.food_name}'. "
                       f"Try searching with /cooking-conversions?search={request.food_name}"
            )

        # Log the conversion activity
        await log_user_activity(
            user_id="system",  # Could be updated if user_id is added to request
            action="cooking_conversion",
            endpoint="/api/v1/nutrition/convert-weight",
            message=f"Converted {request.weight_g}g {request.from_state} {request.food_name} to {result.converted_weight_g:.1f}g {result.converted_state}",
            metadata={
                "food_name": request.food_name,
                "from_state": request.from_state,
                "original_weight_g": request.weight_g,
                "converted_weight_g": result.converted_weight_g,
                "cooking_method": result.cooking_method,
                "ratio": result.raw_to_cooked_ratio,
            },
            status_code=200
        )

        return ConvertWeightResponse(**result.to_dict())

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to convert food weight: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")

