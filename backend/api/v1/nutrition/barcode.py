"""Barcode lookup and food logging from barcode endpoints."""
from core.db import get_supabase_db
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request

from core.timezone_utils import resolve_timezone, get_user_now_iso
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity
from services.food_database_service import get_food_database_service

from api.v1.nutrition.models import (
    BarcodeProductResponse,
    LogBarcodeRequest,
    LogBarcodeResponse,
)

router = APIRouter()
logger = get_logger(__name__)

# ============================================
# Barcode Scanning Endpoints
# ============================================


@router.get("/barcode/{barcode}", response_model=BarcodeProductResponse)
async def lookup_barcode(barcode: str, current_user: dict = Depends(get_current_user)):
    """
    Look up a product by barcode using Open Food Facts API.

    Returns product information including:
    - Product name and brand
    - Nutritional information (per 100g and per serving)
    - Nutri-Score grade
    - Ingredients and allergens
    """
    import re

    # Validate barcode format BEFORE lookup
    cleaned = barcode.strip().replace(" ", "").replace("-", "")
    if not re.match(r'^\d{8,14}$', cleaned):
        logger.warning(f"Invalid barcode format rejected: {barcode[:50]}...")
        raise HTTPException(
            status_code=400,
            detail="Invalid barcode. Product barcodes must be 8-14 digits."
        )

    logger.info(f"Looking up barcode: {cleaned}")

    try:
        service = get_food_database_service()
        product = await service.lookup_barcode(cleaned)
        
        if not product:
            raise HTTPException(
                status_code=404, 
                detail=f"Product not found for barcode: {barcode}"
            )
        
        return BarcodeProductResponse(
            barcode=product.barcode,
            product_name=product.product_name,
            brand=product.brand,
            categories=product.categories,
            image_url=product.image_url,
            image_thumb_url=product.image_thumb_url,
            nutrients=product.nutrients.to_dict(),
            nutriscore_grade=product.nutriscore_grade,
            nova_group=product.nova_group,
            ingredients_text=product.ingredients_text,
            allergens=product.allergens,
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to lookup barcode {barcode}: {e}")
        raise safe_internal_error(e, "nutrition")


@router.post("/log-barcode", response_model=LogBarcodeResponse)
async def log_food_from_barcode(request: LogBarcodeRequest, http_request: Request = None, current_user: dict = Depends(get_current_user)):
    """
    Log food to meal diary from barcode scan.

    This endpoint:
    1. Looks up the product by barcode
    2. Calculates nutrition based on servings
    3. Creates a food log entry
    """
    logger.info(f"Logging barcode {request.barcode} for user {request.user_id}")
    
    try:
        # First, lookup the product
        service = get_food_database_service()
        product = await service.lookup_barcode(request.barcode)
        
        if not product:
            raise HTTPException(
                status_code=404,
                detail=f"Product not found for barcode: {request.barcode}"
            )
        
        # Calculate serving size
        serving_size_g = request.serving_size_g
        if serving_size_g is None:
            serving_size_g = product.nutrients.serving_size_g or 100.0
        
        # Calculate nutrition based on servings
        total_grams = serving_size_g * request.servings
        multiplier = total_grams / 100.0
        
        total_calories = int(product.nutrients.calories_per_100g * multiplier)
        protein_g = round(product.nutrients.protein_per_100g * multiplier, 1)
        carbs_g = round(product.nutrients.carbs_per_100g * multiplier, 1)
        fat_g = round(product.nutrients.fat_per_100g * multiplier, 1)
        fiber_g = round(product.nutrients.fiber_per_100g * multiplier, 1)
        
        # Create food item
        food_item = {
            "name": product.product_name,
            "amount": f"{total_grams:.0f}g ({request.servings} serving{'s' if request.servings != 1 else ''})",
            "calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "barcode": request.barcode,
            "brand": product.brand,
        }
        
        # Create food log
        db = get_supabase_db()

        # Resolve timezone for logged_at timestamp
        user_tz_logged_at = None
        if http_request:
            user_tz = resolve_timezone(http_request, db, request.user_id)
            user_tz_logged_at = get_user_now_iso(user_tz)

        # Save to database using positional arguments
        created_log = db.create_food_log(
            user_id=request.user_id,
            meal_type=request.meal_type,
            food_items=[food_item],
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=None,
            health_score=None,
            logged_at=user_tz_logged_at,
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged barcode {request.barcode} as {food_log_id}")
        
        return LogBarcodeResponse(
            success=True,
            food_log_id=food_log_id,
            product_name=product.product_name,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log barcode {request.barcode}: {e}")
        raise safe_internal_error(e, "nutrition")


