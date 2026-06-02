"""Barcode lookup and food logging from barcode endpoints."""
from core.db import get_supabase_db
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request

from core.timezone_utils import resolve_timezone, get_user_now_iso
from core.auth import get_current_user
from core.exceptions import safe_internal_error
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
        # Resolve the user's country so a multi-country verified override can
        # pick the right regional row (F1).
        country = None
        try:
            db = get_supabase_db()
            u = db.get_user(str(current_user.get("id"))) or {}
            country = u.get("country_code") or u.get("country")
        except Exception:
            country = None
        product = await service.lookup_barcode(cleaned, country=country)

        if not product:
            # Clear, non-fabricated not-found signal — the client/coach prompts
            # the user to describe the food instead of inventing a row.
            raise HTTPException(
                status_code=404,
                detail=f"Product not found for barcode: {barcode}. Describe it and we'll log it instead."
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
        logger.error(f"Failed to lookup barcode {barcode}: {e}", exc_info=True)
        # Open Food Facts being down (502/503/timeout) is an UPSTREAM outage,
        # not our bug — surface 503 so clients can show "try again shortly"
        # instead of a generic 500 crash banner.
        msg = str(e).lower()
        if any(s in msg for s in ("502", "503", "504", "timeout", "timed out",
                                  "bad gateway", "connecterror", "connection")):
            raise HTTPException(
                status_code=503,
                detail="Barcode lookup is temporarily unavailable (upstream "
                       "food database). Please try again shortly.",
            )
        raise safe_internal_error(e, "nutrition")


@router.post("/log-barcode", response_model=LogBarcodeResponse)
async def log_food_from_barcode(request: LogBarcodeRequest, http_request: Request, current_user: dict = Depends(get_current_user)):
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
        db = get_supabase_db()
        # Resolve country for the verified-override regional pick (F1).
        country = None
        try:
            u = db.get_user(request.user_id) or {}
            country = u.get("country_code") or u.get("country")
        except Exception:
            country = None
        product = await service.lookup_barcode(request.barcode, country=country)

        if not product:
            raise HTTPException(
                status_code=404,
                detail=f"Product not found for barcode: {request.barcode}. Describe it and we'll log it instead."
            )

        # Calculate serving size
        serving_size_g = request.serving_size_g
        if serving_size_g is None:
            serving_size_g = product.nutrients.serving_size_g or 100.0

        # Calculate nutrition based on servings. `consumed_fraction` (F1) lets
        # the user log a fraction of the whole package (e.g. 0.5 = half the bag)
        # — it scales on TOP of servings × serving size.
        frac = request.consumed_fraction
        if frac is not None and frac > 0:
            frac = min(float(frac), 1.0)
        else:
            frac = 1.0
        total_grams = serving_size_g * request.servings * frac
        multiplier = total_grams / 100.0
        
        total_calories = int(product.nutrients.calories_per_100g * multiplier)
        protein_g = round(product.nutrients.protein_per_100g * multiplier, 1)
        carbs_g = round(product.nutrients.carbs_per_100g * multiplier, 1)
        fat_g = round(product.nutrients.fat_per_100g * multiplier, 1)
        fiber_g = round(product.nutrients.fiber_per_100g * multiplier, 1)
        
        # Create food item with quality metadata
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

        # Store food quality metadata in food_item
        if product.nutriscore_grade:
            food_item["nutriscore_grade"] = product.nutriscore_grade
        if product.nova_group is not None:
            food_item["nova_group"] = product.nova_group
        if product.ecoscore_grade:
            food_item["ecoscore_grade"] = product.ecoscore_grade
        if product.allergens:
            food_item["allergens"] = product.allergens
        if product.labels_tags:
            food_item["labels_tags"] = product.labels_tags
        if product.additives_tags:
            food_item["additives_tags"] = product.additives_tags
        if product.ingredients_text:
            food_item["ingredients_text"] = product.ingredients_text

        # Derive inflammation score from NOVA group
        nova_group = product.nova_group
        inflammation_score = None
        is_ultra_processed = False
        if nova_group:
            nova_group = int(nova_group)
            is_ultra_processed = nova_group == 4
            # Map NOVA to inflammation score
            nova_to_inflammation = {1: 3, 2: 4, 3: 6, 4: 8}
            inflammation_score = nova_to_inflammation.get(nova_group, 5)

        # Store inflammation data in food_item
        if inflammation_score is not None:
            food_item["inflammation_score"] = inflammation_score
        food_item["is_ultra_processed"] = is_ultra_processed

        # Calculate micronutrients based on serving multiplier
        sugar_g = round(product.nutrients.sugar_per_100g * multiplier, 1) if product.nutrients.sugar_per_100g else None
        sodium_mg = round(product.nutrients.sodium_per_100g * multiplier, 1) if product.nutrients.sodium_per_100g else None
        saturated_fat_g = round(product.nutrients.saturated_fat_per_100g * multiplier, 1) if product.nutrients.saturated_fat_per_100g else None

        vitamin_a_ug = round(product.nutrients.vitamin_a_100g * multiplier, 2) if product.nutrients.vitamin_a_100g else None
        vitamin_c_mg = round(product.nutrients.vitamin_c_100g * multiplier, 2) if product.nutrients.vitamin_c_100g else None
        vitamin_d_iu = None  # OFF gives µg, conversion to IU = µg * 40
        if product.nutrients.vitamin_d_100g:
            vitamin_d_iu = round(product.nutrients.vitamin_d_100g * multiplier * 40, 1)
        calcium_mg = round(product.nutrients.calcium_100g * multiplier, 1) if product.nutrients.calcium_100g else None
        iron_mg = round(product.nutrients.iron_100g * multiplier, 2) if product.nutrients.iron_100g else None
        potassium_mg = round(product.nutrients.potassium_100g * multiplier, 1) if product.nutrients.potassium_100g else None
        magnesium_mg = round(product.nutrients.magnesium_100g * multiplier, 1) if product.nutrients.magnesium_100g else None
        zinc_mg = round(product.nutrients.zinc_100g * multiplier, 2) if product.nutrients.zinc_100g else None

        # F5 — extended micros from OFF. OFF reports most micros in GRAMS per
        # 100g; nutrient_rdas wants mg (×1000) or µg (×1_000_000). Vitamin B9 /
        # selenium / iodine / vit-K are µg-scale; the rest mg-scale. We only
        # emit a value when OFF actually carried it (None otherwise → never read
        # as 0 intake downstream).
        def _mg(v):  # grams → mg
            return round(v * multiplier * 1000, 3) if v else None
        def _ug(v):  # grams → µg
            return round(v * multiplier * 1_000_000, 2) if v else None
        n = product.nutrients
        vitamin_e_mg = _mg(n.vitamin_e_100g)
        vitamin_k_ug = _ug(n.vitamin_k_100g)
        vitamin_b1_mg = _mg(n.vitamin_b1_100g)
        vitamin_b2_mg = _mg(n.vitamin_b2_100g)
        vitamin_b3_mg = _mg(n.vitamin_b3_100g)
        vitamin_b6_mg = _mg(n.vitamin_b6_100g)
        vitamin_b9_ug = _ug(n.vitamin_b9_100g)
        vitamin_b12_ug = _ug(n.vitamin_b12_100g)
        selenium_ug = _ug(n.selenium_100g)
        phosphorus_mg = _mg(n.phosphorus_100g)
        copper_mg = _mg(n.copper_100g)
        manganese_mg = _mg(n.manganese_100g)
        iodine_ug = _ug(n.iodine_100g)
        cholesterol_mg = _mg(n.cholesterol_100g)
        omega3_g = round(n.omega3_100g * multiplier, 3) if n.omega3_100g else None
        omega6_g = round(n.omega6_100g * multiplier, 3) if n.omega6_100g else None

        # F1 — apply the user's learned per-food correction on top of the
        # barcode/label macros, so a personal override (e.g. they always log a
        # different scoop size for this protein) trumps the database value.
        try:
            from services.food_override_service import apply_user_food_overrides
            _items, _totals, _n_over = apply_user_food_overrides(
                db, request.user_id, [food_item]
            )
            if _n_over:
                logger.info(f"Applied user override on barcode log for {request.user_id}")
                food_item = _items[0]
                total_calories = _totals["total_calories"]
                protein_g = _totals["protein_g"]
                carbs_g = _totals["carbs_g"]
                fat_g = _totals["fat_g"]
        except Exception as ov_err:
            logger.warning(f"Barcode override application skipped: {ov_err}")

        # Resolve timezone for logged_at timestamp
        user_tz_logged_at = None
        if http_request:
            user_tz = resolve_timezone(http_request, db, request.user_id)
            user_tz_logged_at = get_user_now_iso(user_tz)

        # Save to database with micronutrients
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
            source_type="barcode",
            input_type="barcode",
            user_query=product.product_name,
            sugar_g=sugar_g,
            sodium_mg=sodium_mg,
            saturated_fat_g=saturated_fat_g,
            vitamin_a_ug=vitamin_a_ug,
            vitamin_c_mg=vitamin_c_mg,
            vitamin_d_iu=vitamin_d_iu,
            calcium_mg=calcium_mg,
            iron_mg=iron_mg,
            potassium_mg=potassium_mg,
            magnesium_mg=magnesium_mg,
            zinc_mg=zinc_mg,
            # F5 — extended micros (only set when OFF carried them).
            vitamin_e_mg=vitamin_e_mg,
            vitamin_k_ug=vitamin_k_ug,
            vitamin_b1_mg=vitamin_b1_mg,
            vitamin_b2_mg=vitamin_b2_mg,
            vitamin_b3_mg=vitamin_b3_mg,
            vitamin_b6_mg=vitamin_b6_mg,
            vitamin_b9_ug=vitamin_b9_ug,
            vitamin_b12_ug=vitamin_b12_ug,
            selenium_ug=selenium_ug,
            phosphorus_mg=phosphorus_mg,
            copper_mg=copper_mg,
            manganese_mg=manganese_mg,
            iodine_ug=iodine_ug,
            cholesterol_mg=cholesterol_mg,
            omega3_g=omega3_g,
            omega6_g=omega6_g,
            inflammation_score=inflammation_score,
            is_ultra_processed=is_ultra_processed,
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged barcode {request.barcode} as {food_log_id}")

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        await invalidate_daily_summary_cache(request.user_id)
        await invalidate_bootstrap_cache(request.user_id)

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
        logger.error(f"Failed to log barcode {request.barcode}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


