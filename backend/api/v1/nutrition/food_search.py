"""Food search/lookup endpoints (USDA, branded, whole foods)."""
import asyncio
import time
from core.db import get_supabase_db
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel

from core.rate_limiter import limiter
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from services.food_database_service import get_food_database_service
from services.nutrition_rag_service import get_nutrition_rag_service

router = APIRouter()
logger = get_logger(__name__)

# ============================================
# USDA FoodData Central Endpoints
# ============================================

from services.usda_food_service import get_usda_food_service, USDAFood, USDASearchResult


class USDAFoodResponse(BaseModel):
    """USDA food item response."""
    fdc_id: int
    description: str
    data_type: str
    brand_owner: Optional[str] = None
    brand_name: Optional[str] = None
    ingredients: Optional[str] = None
    food_category: Optional[str] = None
    gtin_upc: Optional[str] = None
    nutrients: dict
    nutrients_per_serving: Optional[dict] = None
    score: Optional[float] = None
    weight_per_unit_g: Optional[float] = None
    default_count: Optional[int] = None
    serving_weight_g: Optional[float] = None
    matched_query: Optional[str] = None  # Which sub-query this result matched (for multi-food queries)
    verification_level: Optional[str] = None  # 'curated', 'lab_verified', 'manufacturer_verified', 'community_verified'
    total_calories: Optional[int] = None  # Total calories for saved foods (per-serving, not per-100g)
    partial_match: bool = False  # True if food_match_gate only accepted this as a partial (tier-B/C) match; frontend should show "Closest matches" banner


class USDASearchResponse(BaseModel):
    """USDA food search response."""
    foods: List[USDAFoodResponse]
    total_hits: int
    current_page: int
    total_pages: int
    query: str
    search_time_ms: Optional[int] = None


class CombinedFoodSearchResponse(BaseModel):
    """Combined food search from multiple sources."""
    usda_foods: List[USDAFoodResponse]
    usda_total_hits: int
    source: str = "combined"
    query: str


@router.get("/food-search", response_model=USDASearchResponse)
async def search_foods(
    query: str = Query(..., min_length=1, max_length=200, description="Food search query"),
    # NOTE: list-view payload is intentionally capped at 10 (plan A2). Full
    # nutrient detail is fetched on the per-item endpoint.
    page_size: int = Query(default=10, ge=1, le=10, description="Number of results per page"),
    page: int = Query(default=1, ge=1, description="Page number"),
    source: Optional[str] = Query(
        default=None,
        description="Filter by data source: usda, openfoodfacts, cnf, indb"
    ),
    current_user: dict = Depends(get_current_user),
    data_types: Optional[str] = Query(
        default=None,
        description="Comma-separated food types: Branded,Foundation,SR Legacy"
    ),
    brand_owner: Optional[str] = Query(
        default=None,
        max_length=200,
        description="Filter by brand owner (for branded foods)"
    ),
    user_id: Optional[str] = Query(
        default=None,
        description="User ID to include personal saved foods in results"
    ),
    restaurant: Optional[str] = Query(
        default=None,
        max_length=100,
        description="Filter by restaurant name (e.g. McDonald's, Taco Bell)"
    ),
    category: Optional[str] = Query(
        default=None,
        max_length=50,
        description="Filter by food category (e.g. burgers, drinks, breakfast)"
    ),
    country: Optional[str] = Query(
        default=None,
        max_length=2,
        description="ISO 3166-1 alpha-2 country code to filter country foods (e.g. 'US', 'IN', 'JP')"
    ),
):
    """
    Search the food database for foods matching a query.

    Primary search uses the local food database (528K+ foods from USDA, OpenFoodFacts,
    CNF, and INDB) for instant results. Falls back to USDA API if local DB is unavailable.

    Returns complete nutrient data including calories, macros, and serving info.
    """
    logger.info(f"Searching foods for: {query} (page {page}, size {page_size}, source={source})")

    try:
        # Primary: Use local food database
        from services.food_database_lookup_service import get_food_db_lookup_service
        food_db_service = get_food_db_lookup_service()

        _search_start = time.time()
        # Hard 5s ceiling on the underlying search. On timeout return 504 with
        # an empty list so the UI's existing error path triggers (plan A2).
        try:
            if user_id:
                results = await asyncio.wait_for(
                    food_db_service.search_foods_unified(
                        query=query,
                        user_id=user_id,
                        page_size=page_size,
                        page=page,
                        restaurant=restaurant,
                        food_category=category,
                        region=country,
                    ),
                    timeout=5.0,
                )
            else:
                results = await asyncio.wait_for(
                    food_db_service.search_foods(
                        query=query,
                        page_size=page_size,
                        page=page,
                        source=source,
                        restaurant=restaurant,
                        food_category=category,
                        region=country,
                    ),
                    timeout=5.0,
                )
        except asyncio.TimeoutError:
            logger.warning(f"⚠️ [FoodSearch] search timeout (>5s) for query='{query}'")
            raise HTTPException(
                status_code=504,
                detail={"results": [], "error": "search_timeout"},
            )
        _search_time_ms = int((time.time() - _search_start) * 1000)

        # Convert local DB results to USDAFoodResponse format for compatibility
        foods = []
        for item in results:
            # Sanity check: skip entries with near-zero calories but non-trivial macros (bad data)
            _cal = float(item.get("calories_per_100g") or 0)
            _prot = float(item.get("protein_per_100g") or 0)
            _fat = float(item.get("fat_per_100g") or 0)
            _carbs = float(item.get("carbs_per_100g") or 0)
            _source = item.get("source", "")
            if _source not in ("saved", "saved_item") and _cal < 5 and (_prot > 1 or _fat > 1 or _carbs > 1):
                logger.warning(f"[FoodSearch] Skipping bad data: '{item.get('name')}' has {_cal} cal/100g with macros P={_prot} F={_fat} C={_carbs}")
                continue

            # List-view payload is intentionally trimmed to a flat shape
            # (kcal / protein / carbs / fat / serving). Full nutrient detail
            # is exposed on GET /food/{fdc_id} (plan A2).
            serving_weight = item.get("serving_weight_g") or item.get("weight_per_unit_g")
            nutrients: Dict[str, Any] = {
                "kcal": item.get("calories_per_100g", 0) or 0,
                "protein_g": item.get("protein_per_100g", 0) or 0,
                "carbs_g": item.get("carbs_per_100g", 0) or 0,
                "fat_g": item.get("fat_per_100g", 0) or 0,
                "serving_weight_g": serving_weight,
            }

            # Per-serving calculation (kept flat — same trimmed shape as above)
            nutrients_per_serving = None
            if serving_weight and serving_weight > 0:
                mult = serving_weight / 100.0
                nutrients_per_serving = {
                    "kcal": round((item.get("calories_per_100g", 0) or 0) * mult, 1),
                    "protein_g": round((item.get("protein_per_100g", 0) or 0) * mult, 1),
                    "carbs_g": round((item.get("carbs_per_100g", 0) or 0) * mult, 1),
                    "fat_g": round((item.get("fat_per_100g", 0) or 0) * mult, 1),
                }

            # ID may be BIGINT (food_database) or TEXT/UUID (saved foods from unified)
            raw_id = item.get("id", 0)
            try:
                fdc_id = int(raw_id)
            except (ValueError, TypeError):
                fdc_id = 0  # Saved food UUIDs -> 0; frontend uses source field

            # Derive verification_level from source
            source_str = item.get("source", "")
            if source_str == "verified":
                v_level = "curated"
            elif source_str.startswith("verified:"):
                v_level = source_str.split(":", 1)[1]
            elif source_str in ("saved", "saved_item"):
                v_level = "user_saved"
            else:
                v_level = item.get("verification_level")

            # For saved foods, pass total_calories directly (not per-100g)
            total_cal = None
            if _source in ("saved", "saved_item"):
                total_cal = int(item.get("total_calories") or item.get("calories_per_100g") or 0)

            foods.append(USDAFoodResponse(
                fdc_id=fdc_id,
                description=item.get("name", "Unknown"),
                data_type=item.get("source", "local_db"),
                brand_owner=item.get("brand"),
                brand_name=item.get("brand"),
                ingredients=None,
                food_category=item.get("category"),
                gtin_upc=None,
                nutrients=nutrients,
                nutrients_per_serving=nutrients_per_serving,
                score=item.get("similarity_score"),
                weight_per_unit_g=item.get("weight_per_unit_g"),
                default_count=item.get("default_count"),
                serving_weight_g=item.get("serving_weight_g"),
                matched_query=item.get("matched_query"),
                verification_level=v_level,
                total_calories=total_cal,
                partial_match=bool(item.get("partial_match", False)),
            ))

        total_hits = len(foods)
        logger.info(f"Found {total_hits} foods for query: {query} in {_search_time_ms}ms")

        return USDASearchResponse(
            foods=foods,
            total_hits=total_hits,
            current_page=page,
            total_pages=max(1, (total_hits + page_size - 1) // page_size),
            query=query,
            search_time_ms=_search_time_ms,
        )

    except Exception as e:
        logger.warning(f"Local food DB search failed, falling back to USDA: {e}", exc_info=True)

        # Fallback: Use USDA API
        try:
            service = get_usda_food_service()

            parsed_data_types = None
            if data_types:
                parsed_data_types = [dt.strip() for dt in data_types.split(",") if dt.strip()]

            result = await service.search_foods(
                query=query,
                page_size=page_size,
                page_number=page,
                data_types=parsed_data_types,
                brand_owner=brand_owner,
            )

            foods = []
            for food in result.foods:
                food_dict = food.to_dict()
                foods.append(USDAFoodResponse(
                    fdc_id=food_dict["fdc_id"],
                    description=food_dict["description"],
                    data_type=food_dict["data_type"],
                    brand_owner=food_dict.get("brand_owner"),
                    brand_name=food_dict.get("brand_name"),
                    ingredients=food_dict.get("ingredients"),
                    food_category=food_dict.get("food_category"),
                    gtin_upc=food_dict.get("gtin_upc"),
                    nutrients=food_dict["nutrients"],
                    nutrients_per_serving=food_dict.get("nutrients_per_serving"),
                    score=food_dict.get("score"),
                ))

            return USDASearchResponse(
                foods=foods,
                total_hits=result.total_hits,
                current_page=result.current_page,
                total_pages=result.total_pages,
                query=query,
            )
        except Exception as usda_error:
            logger.error(f"Both local DB and USDA search failed: {usda_error}", exc_info=True)
            raise safe_internal_error(usda_error, "food_search")


@router.get("/food/{fdc_id}", response_model=USDAFoodResponse)
async def get_usda_food(fdc_id: int, current_user: dict = Depends(get_current_user)):
    """
    Get complete food details from USDA by FDC ID.

    Returns full nutrient profile including:
    - Macronutrients (calories, protein, carbs, fat, fiber, sugar)
    - Vitamins (A, C, D, B12, folate)
    - Minerals (sodium, potassium, calcium, iron, magnesium, zinc)
    - Serving size information
    """
    logger.info(f"Fetching USDA food by FDC ID: {fdc_id}")

    try:
        service = get_usda_food_service()
        food = await service.get_food(fdc_id)

        if not food:
            raise HTTPException(
                status_code=404,
                detail=f"Food not found for FDC ID: {fdc_id}"
            )

        food_dict = food.to_dict()
        return USDAFoodResponse(
            fdc_id=food_dict["fdc_id"],
            description=food_dict["description"],
            data_type=food_dict["data_type"],
            brand_owner=food_dict.get("brand_owner"),
            brand_name=food_dict.get("brand_name"),
            ingredients=food_dict.get("ingredients"),
            food_category=food_dict.get("food_category"),
            gtin_upc=food_dict.get("gtin_upc"),
            nutrients=food_dict["nutrients"],
            nutrients_per_serving=food_dict.get("nutrients_per_serving"),
            score=None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get USDA food {fdc_id}: {e}", exc_info=True)
        if "not configured" in str(e).lower():
            raise HTTPException(
                status_code=503,
                detail="USDA food lookup is not available. Please configure USDA_API_KEY."
            )
        raise safe_internal_error(e, "nutrition")


@router.get("/food-search/branded", response_model=USDASearchResponse)
async def search_branded_foods(
    query: str = Query(..., min_length=1, max_length=200, description="Food search query"),
    page_size: int = Query(default=25, ge=1, le=50, description="Number of results per page"),
    current_user: dict = Depends(get_current_user),
):
    """
    Search branded/packaged foods.

    Uses the local food database filtered to branded items from OpenFoodFacts and USDA Branded.
    """
    logger.info(f"Searching branded foods for: {query}")

    try:
        from services.food_database_lookup_service import get_food_db_lookup_service
        food_db_service = get_food_db_lookup_service()

        # Search local DB — branded items typically come from openfoodfacts
        results = await food_db_service.search_foods(
            query=query,
            page_size=page_size,
            source="openfoodfacts",
        )

        foods = []
        for item in results:
            nutrients = {
                "calories_per_100g": item.get("calories_per_100g", 0),
                "protein_per_100g": item.get("protein_per_100g", 0),
                "carbs_per_100g": item.get("carbs_per_100g", 0),
                "fat_per_100g": item.get("fat_per_100g", 0),
                "fiber_per_100g": item.get("fiber_per_100g", 0),
                "sugar_per_100g": item.get("sugar_per_100g", 0),
            }
            foods.append(USDAFoodResponse(
                fdc_id=item.get("id", 0),
                description=item.get("name", "Unknown"),
                data_type=item.get("source", "openfoodfacts"),
                brand_owner=item.get("brand"),
                brand_name=item.get("brand"),
                ingredients=None,
                food_category=item.get("category"),
                gtin_upc=None,
                nutrients=nutrients,
                nutrients_per_serving=None,
                score=item.get("similarity_score"),
            ))

        return USDASearchResponse(
            foods=foods,
            total_hits=len(foods),
            current_page=1,
            total_pages=1,
            query=query,
        )

    except Exception as e:
        logger.error(f"Failed to search branded foods: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/food-search/whole-foods", response_model=USDASearchResponse)
async def search_whole_foods(
    query: str = Query(..., min_length=1, max_length=200, description="Food search query"),
    page_size: int = Query(default=25, ge=1, le=50, description="Number of results per page"),
    current_user: dict = Depends(get_current_user),
):
    """
    Search whole/basic foods (fruits, vegetables, meats, grains).

    Uses the local food database filtered to USDA Foundation and SR Legacy data.
    """
    logger.info(f"Searching whole foods for: {query}")

    try:
        from services.food_database_lookup_service import get_food_db_lookup_service
        food_db_service = get_food_db_lookup_service()

        # Search local DB filtered to USDA source (Foundation/SR Legacy)
        results = await food_db_service.search_foods(
            query=query,
            page_size=page_size,
            source="usda",
        )

        foods = []
        for item in results:
            nutrients = {
                "calories_per_100g": item.get("calories_per_100g", 0),
                "protein_per_100g": item.get("protein_per_100g", 0),
                "carbs_per_100g": item.get("carbs_per_100g", 0),
                "fat_per_100g": item.get("fat_per_100g", 0),
                "fiber_per_100g": item.get("fiber_per_100g", 0),
                "sugar_per_100g": item.get("sugar_per_100g", 0),
            }
            foods.append(USDAFoodResponse(
                fdc_id=item.get("id", 0),
                description=item.get("name", "Unknown"),
                data_type=item.get("source", "usda"),
                brand_owner=item.get("brand"),
                brand_name=item.get("brand"),
                ingredients=None,
                food_category=item.get("category"),
                gtin_upc=None,
                nutrients=nutrients,
                nutrients_per_serving=None,
                score=item.get("similarity_score"),
            ))

        return USDASearchResponse(
            foods=foods,
            total_hits=len(foods),
            current_page=1,
            total_pages=1,
            query=query,
        )

    except Exception as e:
        logger.error(f"Failed to search whole foods: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


# ============================================
