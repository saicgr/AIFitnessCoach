"""Saved foods CRUD endpoints."""
import asyncio
import uuid
from datetime import datetime
from typing import List, Optional

from core.db import get_supabase_db
from services.food_analysis_cache_service import get_food_analysis_cache_service

from fastapi import APIRouter, Depends, HTTPException, Query, Form, Request

from core.timezone_utils import resolve_timezone, get_user_now_iso, target_date_to_utc_iso
from core.rate_limiter import limiter
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.activity_logger import log_user_activity
from services.saved_foods_rag_service import get_saved_foods_rag_service

from models.saved_food import (
    SavedFood,
    SavedFoodCreate,
    SavedFoodUpdate,
    SavedFoodsResponse,
    SaveFoodFromLogRequest,
    RelogSavedFoodRequest,
    SavedFoodSummary,
    SearchSavedFoodsRequest,
    SimilarFoodsResponse,
    FoodSourceType,
    AiSuggestFoodRequest,
    AiSuggestFoodResponse,
    AiSuggestedDuplicate,
)
from api.v1.nutrition.models import LogFoodResponse

router = APIRouter()
logger = get_logger(__name__)

# ============================================
# Saved Foods (Favorite Recipes) Endpoints
# ============================================


@router.post("/saved-foods", response_model=SavedFood)
async def save_food(user_id: str = Form(...), request: SaveFoodFromLogRequest = None, current_user: dict = Depends(get_current_user)):
    """
    Save a meal as a favorite recipe.

    This endpoint:
    1. Creates a saved_foods entry in the database
    2. Stores the meal in ChromaDB for semantic search
    """
    # user_id arrives in the form body — a client assertion. Unverified it lets
    # any caller plant saved foods (and RAG entries) in another user's library.
    verify_user_ownership(current_user, user_id)
    logger.info(f"Saving food for user {user_id}: {request.name if request else 'N/A'}")

    try:
        db = get_supabase_db()

        # Generate ID
        saved_food_id = str(uuid.uuid4())

        # Prepare food items for storage
        food_items_data = [
            {
                "name": item.name,
                "amount": item.amount,
                "calories": item.calories,
                "protein_g": item.protein_g,
                "carbs_g": item.carbs_g,
                "fat_g": item.fat_g,
                "fiber_g": item.fiber_g,
                "goal_score": item.goal_score,
                "goal_alignment": item.goal_alignment,
                "brand": item.brand,
                "emoji": item.emoji,
            }
            for item in request.food_items
        ] if request.food_items else []

        # Insert into database
        now = datetime.now().isoformat()
        saved_food_data = {
            "id": saved_food_id,
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "source_type": request.source_type.value if request.source_type else "text",
            "barcode": request.barcode,
            "image_url": request.image_url,
            "total_calories": request.total_calories,
            "total_protein_g": request.total_protein_g,
            "total_carbs_g": request.total_carbs_g,
            "total_fat_g": request.total_fat_g,
            "total_fiber_g": request.total_fiber_g,
            "food_items": food_items_data,
            "overall_meal_score": request.overall_meal_score,
            "goal_alignment_percentage": request.goal_alignment_percentage,
            "tags": request.tags or [],
            "notes": None,
            "times_logged": 0,
            "last_logged_at": None,
            "created_at": now,
            "updated_at": now,
            "deleted_at": None,
        }

        # Save to database
        result = db.client.table("saved_foods").insert(saved_food_data).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to save food to database"), "nutrition")

        # Save to ChromaDB for semantic search
        try:
            rag_service = get_saved_foods_rag_service()
            await rag_service.save_food(
                saved_food_id=saved_food_id,
                user_id=user_id,
                name=request.name,
                description=request.description,
                food_items=food_items_data,
                total_calories=request.total_calories,
                total_protein_g=request.total_protein_g,
                source_type=request.source_type.value if request.source_type else "text",
                tags=request.tags,
            )
        except Exception as e:
            logger.warning(f"Failed to save food to ChromaDB: {e}", exc_info=True)
            # Continue - database save is the primary storage

        logger.info(f"Successfully saved food {saved_food_id}")

        # Return saved food
        saved_data = result.data[0]
        return SavedFood(
            id=saved_data["id"],
            user_id=saved_data["user_id"],
            name=saved_data["name"],
            description=saved_data.get("description"),
            source_type=FoodSourceType(saved_data.get("source_type", "text")),
            barcode=saved_data.get("barcode"),
            image_url=saved_data.get("image_url"),
            total_calories=saved_data.get("total_calories"),
            total_protein_g=saved_data.get("total_protein_g"),
            total_carbs_g=saved_data.get("total_carbs_g"),
            total_fat_g=saved_data.get("total_fat_g"),
            total_fiber_g=saved_data.get("total_fiber_g"),
            food_items=saved_data.get("food_items", []),
            overall_meal_score=saved_data.get("overall_meal_score"),
            goal_alignment_percentage=saved_data.get("goal_alignment_percentage"),
            tags=saved_data.get("tags", []),
            notes=saved_data.get("notes"),
            times_logged=saved_data.get("times_logged", 0),
            last_logged_at=saved_data.get("last_logged_at"),
            created_at=datetime.fromisoformat(saved_data["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(saved_data["updated_at"].replace("Z", "+00:00")),
            deleted_at=None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to save food: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/saved-foods/save", response_model=SavedFood)
async def save_food_json(request: SaveFoodFromLogRequest, user_id: str = Query(...), current_user: dict = Depends(get_current_user)):
    """
    Save a meal as a favorite recipe (JSON body version).

    This endpoint:
    1. Creates a saved_foods entry in the database
    2. Stores the meal in ChromaDB for semantic search
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Saving food for user {user_id}: {request.name}")

    try:
        db = get_supabase_db()

        # Generate ID
        saved_food_id = str(uuid.uuid4())

        # Prepare food items for storage
        food_items_data = [
            {
                "name": item.name,
                "amount": item.amount,
                "calories": item.calories,
                "protein_g": item.protein_g,
                "carbs_g": item.carbs_g,
                "fat_g": item.fat_g,
                "fiber_g": item.fiber_g,
                "goal_score": item.goal_score,
                "goal_alignment": item.goal_alignment,
                "brand": item.brand,
                "emoji": item.emoji,
            }
            for item in request.food_items
        ] if request.food_items else []

        # Insert into database
        now = datetime.now().isoformat()
        saved_food_data = {
            "id": saved_food_id,
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "source_type": request.source_type.value if request.source_type else "text",
            "barcode": request.barcode,
            "image_url": request.image_url,
            "total_calories": request.total_calories,
            "total_protein_g": request.total_protein_g,
            "total_carbs_g": request.total_carbs_g,
            "total_fat_g": request.total_fat_g,
            "total_fiber_g": request.total_fiber_g,
            "food_items": food_items_data,
            "overall_meal_score": request.overall_meal_score,
            "goal_alignment_percentage": request.goal_alignment_percentage,
            "tags": request.tags or [],
            "notes": None,
            "times_logged": 0,
            "last_logged_at": None,
            "created_at": now,
            "updated_at": now,
            "deleted_at": None,
        }

        # Save to database
        result = db.client.table("saved_foods").insert(saved_food_data).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to save food to database"), "nutrition")

        # Save to ChromaDB for semantic search
        try:
            rag_service = get_saved_foods_rag_service()
            await rag_service.save_food(
                saved_food_id=saved_food_id,
                user_id=user_id,
                name=request.name,
                description=request.description,
                food_items=food_items_data,
                total_calories=request.total_calories,
                total_protein_g=request.total_protein_g,
                source_type=request.source_type.value if request.source_type else "text",
                tags=request.tags,
            )
        except Exception as e:
            logger.warning(f"Failed to save food to ChromaDB: {e}", exc_info=True)

        logger.info(f"Successfully saved food {saved_food_id}")

        # Return saved food
        saved_data = result.data[0]
        return SavedFood(
            id=saved_data["id"],
            user_id=saved_data["user_id"],
            name=saved_data["name"],
            description=saved_data.get("description"),
            source_type=FoodSourceType(saved_data.get("source_type", "text")),
            barcode=saved_data.get("barcode"),
            image_url=saved_data.get("image_url"),
            total_calories=saved_data.get("total_calories"),
            total_protein_g=saved_data.get("total_protein_g"),
            total_carbs_g=saved_data.get("total_carbs_g"),
            total_fat_g=saved_data.get("total_fat_g"),
            total_fiber_g=saved_data.get("total_fiber_g"),
            food_items=saved_data.get("food_items", []),
            overall_meal_score=saved_data.get("overall_meal_score"),
            goal_alignment_percentage=saved_data.get("goal_alignment_percentage"),
            tags=saved_data.get("tags", []),
            notes=saved_data.get("notes"),
            times_logged=saved_data.get("times_logged", 0),
            last_logged_at=saved_data.get("last_logged_at"),
            created_at=datetime.fromisoformat(saved_data["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(saved_data["updated_at"].replace("Z", "+00:00")),
            deleted_at=None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to save food: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/saved-foods", response_model=SavedFoodsResponse)
@limiter.limit("10/minute")
async def list_saved_foods(
    request: Request,
    user_id: str = Query(...),
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    source_type: Optional[str] = Query(default=None),
    search: Optional[str] = Query(default=None, max_length=200, description="Search saved foods by name"),
    sort_by: Optional[str] = Query(default=None, description="Sort field: times_logged, total_protein_g, total_calories, total_carbs_g, total_fat_g, name"),
    sort_order: Optional[str] = Query(default="desc", description="Sort order: asc or desc"),
    current_user: dict = Depends(get_current_user),
    min_protein_g: Optional[float] = Query(default=None, ge=0, description="Minimum protein in grams"),
    max_calories: Optional[int] = Query(default=None, ge=0, description="Maximum calories"),
    tag: Optional[str] = Query(default=None, max_length=50, description="Filter by tag"),
):
    """
    List saved foods (favorite recipes) for a user.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Listing saved foods for user {user_id}")

    _VALID_SORT_FIELDS = {"times_logged", "total_protein_g", "total_calories", "total_carbs_g", "total_fat_g", "name"}

    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("saved_foods")\
            .select("*")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")

        if source_type:
            query = query.eq("source_type", source_type)

        if search:
            query = query.ilike("name", f"%{search}%")

        if min_protein_g is not None:
            query = query.gte("total_protein_g", min_protein_g)

        if max_calories is not None:
            query = query.lte("total_calories", max_calories)

        if tag:
            query = query.contains("tags", [tag])

        if sort_by and sort_by in _VALID_SORT_FIELDS:
            query = query.order(sort_by, desc=(sort_order != "asc"))
        else:
            query = query.order("times_logged", desc=True).order("created_at", desc=True)

        query = query.range(offset, offset + limit - 1)

        result = query.execute()

        # Get total count (with same filters applied)
        count_query = db.client.table("saved_foods")\
            .select("id", count="exact")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")

        if source_type:
            count_query = count_query.eq("source_type", source_type)

        if search:
            count_query = count_query.ilike("name", f"%{search}%")

        if min_protein_g is not None:
            count_query = count_query.gte("total_protein_g", min_protein_g)

        if max_calories is not None:
            count_query = count_query.lte("total_calories", max_calories)

        if tag:
            count_query = count_query.contains("tags", [tag])

        count_result = count_query.execute()

        total_count = count_result.count or 0

        # Parse results
        items = []
        for row in result.data or []:
            items.append(SavedFood(
                id=row["id"],
                user_id=row["user_id"],
                name=row["name"],
                description=row.get("description"),
                source_type=FoodSourceType(row.get("source_type", "text")),
                barcode=row.get("barcode"),
                image_url=row.get("image_url"),
                total_calories=row.get("total_calories"),
                total_protein_g=row.get("total_protein_g"),
                total_carbs_g=row.get("total_carbs_g"),
                total_fat_g=row.get("total_fat_g"),
                total_fiber_g=row.get("total_fiber_g"),
                food_items=row.get("food_items", []),
                overall_meal_score=row.get("overall_meal_score"),
                goal_alignment_percentage=row.get("goal_alignment_percentage"),
                tags=row.get("tags", []),
                notes=row.get("notes"),
                times_logged=row.get("times_logged", 0),
                last_logged_at=datetime.fromisoformat(row["last_logged_at"].replace("Z", "+00:00")) if row.get("last_logged_at") else None,
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
                updated_at=datetime.fromisoformat(row["updated_at"].replace("Z", "+00:00")),
                deleted_at=None,
            ))

        return SavedFoodsResponse(items=items, total_count=total_count)

    except Exception as e:
        logger.error(f"Failed to list saved foods: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/saved-foods/{saved_food_id}", response_model=SavedFood)
async def get_saved_food(saved_food_id: str, user_id: str = Query(...), current_user: dict = Depends(get_current_user)):
    """
    Get a specific saved food.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Getting saved food {saved_food_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("saved_foods")\
            .select("*")\
            .eq("id", saved_food_id)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved food not found")

        row = result.data
        return SavedFood(
            id=row["id"],
            user_id=row["user_id"],
            name=row["name"],
            description=row.get("description"),
            source_type=FoodSourceType(row.get("source_type", "text")),
            barcode=row.get("barcode"),
            image_url=row.get("image_url"),
            total_calories=row.get("total_calories"),
            total_protein_g=row.get("total_protein_g"),
            total_carbs_g=row.get("total_carbs_g"),
            total_fat_g=row.get("total_fat_g"),
            total_fiber_g=row.get("total_fiber_g"),
            food_items=row.get("food_items", []),
            overall_meal_score=row.get("overall_meal_score"),
            goal_alignment_percentage=row.get("goal_alignment_percentage"),
            tags=row.get("tags", []),
            notes=row.get("notes"),
            times_logged=row.get("times_logged", 0),
            last_logged_at=datetime.fromisoformat(row["last_logged_at"].replace("Z", "+00:00")) if row.get("last_logged_at") else None,
            created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(row["updated_at"].replace("Z", "+00:00")),
            deleted_at=None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get saved food: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.delete("/saved-foods/{saved_food_id}")
async def delete_saved_food(saved_food_id: str, user_id: str = Query(...), current_user: dict = Depends(get_current_user)):
    """
    Delete a saved food (soft delete).
    """
    # Without this the query-param user_id alone scopes the update — any caller
    # could soft-delete another user's saved food.
    verify_user_ownership(current_user, user_id)
    logger.info(f"Deleting saved food {saved_food_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Soft delete
        result = db.client.table("saved_foods")\
            .update({"deleted_at": datetime.now().isoformat()})\
            .eq("id", saved_food_id)\
            .eq("user_id", user_id)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved food not found")

        # Also delete from ChromaDB
        try:
            rag_service = get_saved_foods_rag_service()
            await rag_service.delete_food(saved_food_id)
        except Exception as e:
            logger.warning(f"Failed to delete food from ChromaDB: {e}", exc_info=True)

        return {"status": "deleted", "id": saved_food_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete saved food: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/saved-foods/{saved_food_id}/log", response_model=LogFoodResponse)
async def relog_saved_food(
    saved_food_id: str,
    request: RelogSavedFoodRequest,
    http_request: Request,
    user_id: str = Query(...),
    target_date: Optional[str] = Query(None, description="Target date YYYY-MM-DD; defaults to now"),
    current_user: dict = Depends(get_current_user),
):
    """
    Re-log a saved food to a meal diary. Optionally specify a target date.
    """
    # This WRITES a food_log row for `user_id` — unverified it lets any caller
    # inject meals into another user's diary and skew their targets.
    verify_user_ownership(current_user, user_id)
    logger.info(f"Re-logging saved food {saved_food_id} for user {user_id}, target_date={target_date}")

    try:
        db = get_supabase_db()

        # Get the saved food
        result = db.client.table("saved_foods")\
            .select("*")\
            .eq("id", saved_food_id)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved food not found")

        saved_food = result.data

        # Resolve timezone for logged_at timestamp
        user_tz_logged_at = None
        if http_request:
            user_tz = resolve_timezone(http_request, db, user_id)
            if target_date:
                user_tz_logged_at = target_date_to_utc_iso(target_date, user_tz)
            else:
                user_tz_logged_at = get_user_now_iso(user_tz)

        # Create food log from saved food
        created_log = db.create_food_log(
            user_id=user_id,
            meal_type=request.meal_type,
            food_items=saved_food.get("food_items", []),
            total_calories=saved_food.get("total_calories", 0),
            protein_g=saved_food.get("total_protein_g", 0),
            carbs_g=saved_food.get("total_carbs_g", 0),
            fat_g=saved_food.get("total_fat_g", 0),
            fiber_g=saved_food.get("total_fiber_g"),
            ai_feedback=None,
            health_score=saved_food.get("overall_meal_score"),
            logged_at=user_tz_logged_at,
            source_type="manual",
            input_type="manual",
        )

        food_log_id = created_log.get('id') if created_log else "unknown"

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        await invalidate_daily_summary_cache(user_id)
        await invalidate_bootstrap_cache(user_id)

        # Update times_logged
        db.client.table("saved_foods")\
            .update({
                "times_logged": saved_food.get("times_logged", 0) + 1,
                "last_logged_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat(),
            })\
            .eq("id", saved_food_id)\
            .execute()

        logger.info(f"Successfully re-logged saved food {saved_food_id} as {food_log_id}")

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=saved_food.get("food_items", []),
            total_calories=saved_food.get("total_calories", 0),
            protein_g=saved_food.get("total_protein_g", 0),
            carbs_g=saved_food.get("total_carbs_g", 0),
            fat_g=saved_food.get("total_fat_g", 0),
            fiber_g=saved_food.get("total_fiber_g"),
            overall_meal_score=saved_food.get("overall_meal_score"),
            health_score=saved_food.get("overall_meal_score"),
            goal_alignment_percentage=saved_food.get("goal_alignment_percentage"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to re-log saved food: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/saved-foods/search", response_model=SimilarFoodsResponse)
async def search_saved_foods(
    request: SearchSavedFoodsRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Search saved foods using semantic search.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Searching saved foods for user {user_id}: {request.query}")

    try:
        if not request.query:
            raise HTTPException(status_code=400, detail="Query is required")

        rag_service = get_saved_foods_rag_service()
        results = await rag_service.search_similar(
            query=request.query,
            user_id=user_id,
            n_results=request.limit,
            min_calories=request.min_calories,
            max_calories=request.max_calories,
        )

        similar_foods = [
            SavedFoodSummary(
                id=r["id"],
                name=r["name"],
                total_calories=r.get("total_calories"),
                total_protein_g=r.get("total_protein_g"),
                source_type=FoodSourceType(r.get("source_type", "text")),
                times_logged=0,  # Not available from ChromaDB
                last_logged_at=None,
                created_at=datetime.now(),  # Not available from ChromaDB
                tags=r.get("tags", []),
            )
            for r in results
        ]

        return SimilarFoodsResponse(
            similar_foods=similar_foods,
            query=request.query,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to search saved foods: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


# ============================================
# A4 — AI-Assisted Custom Food Creation
# ============================================

# Deterministic keyword → emoji map. Keeps the AI-suggest path free of an
# extra Gemini round trip (no duplicate Gemini calls — A4 requirement). The
# client treats the emoji as a *suggestion* and lets the user change it.
# Order matters: more specific keywords are checked first.
_FOOD_EMOJI_KEYWORDS = [
    (("pizza",), "🍕"),
    (("burger", "cheeseburger", "hamburger"), "🍔"),
    (("fries", "french fry"), "🍟"),
    (("hot dog", "hotdog"), "🌭"),
    (("taco",), "🌮"),
    (("burrito", "wrap"), "🌯"),
    (("sandwich", "sub ", "panini"), "🥪"),
    (("salad",), "🥗"),
    (("sushi", "sashimi", "nigiri"), "🍣"),
    (("ramen", "noodle", "pho", "pasta", "spaghetti", "udon"), "🍜"),
    (("rice", "biryani", "fried rice"), "🍚"),
    (("curry",), "🍛"),
    (("steak", "beef", "brisket"), "🥩"),
    (("bacon",), "🥓"),
    (("chicken", "poultry", "wings", "nugget"), "🍗"),
    (("fish", "salmon", "tuna", "cod", "tilapia"), "🐟"),
    (("shrimp", "prawn", "lobster", "crab", "shellfish"), "🦐"),
    (("egg", "omelet", "omelette"), "🥚"),
    (("cheese",), "🧀"),
    (("milk", "dairy"), "🥛"),
    (("yogurt", "yoghurt", "greek yogurt"), "🍶"),
    (("bread", "toast", "bagel", "baguette"), "🍞"),
    (("croissant",), "🥐"),
    (("pancake", "waffle"), "🥞"),
    (("cereal", "oatmeal", "oats", "porridge", "granola", "muesli"), "🥣"),
    (("apple",), "🍎"),
    (("banana",), "🍌"),
    (("orange", "tangerine", "clementine"), "🍊"),
    (("grape",), "🍇"),
    (("strawberry", "berries", "berry"), "🍓"),
    (("watermelon",), "🍉"),
    (("avocado",), "🥑"),
    (("broccoli",), "🥦"),
    (("carrot",), "🥕"),
    (("potato", "mashed potato"), "🥔"),
    (("corn",), "🌽"),
    (("tomato",), "🍅"),
    (("mushroom",), "🍄"),
    (("nut", "almond", "peanut", "cashew", "walnut"), "🥜"),
    (("chocolate", "brownie"), "🍫"),
    (("cookie", "biscuit"), "🍪"),
    (("cake", "cupcake"), "🍰"),
    (("donut", "doughnut"), "🍩"),
    (("ice cream", "gelato"), "🍦"),
    (("candy", "sweet"), "🍬"),
    (("popcorn",), "🍿"),
    (("coffee", "espresso", "latte", "cappuccino"), "☕"),
    (("tea", "matcha"), "🍵"),
    (("soda", "cola", "soft drink", "pop"), "🥤"),
    (("juice", "smoothie", "shake"), "🥤"),
    (("beer",), "🍺"),
    (("wine",), "🍷"),
    (("water",), "💧"),
    (("protein bar", "protein shake", "whey", "supplement"), "💪"),
    (("soup", "broth", "stew"), "🍲"),
    (("honey",), "🍯"),
    (("butter", "oil"), "🧈"),
    (("pretzel",), "🥨"),
    (("dumpling", "gyoza", "potsticker"), "🥟"),
]


def _suggest_emoji(name: Optional[str]) -> Optional[str]:
    """Pick a food emoji from a name; return None when nothing matches confidently."""
    if not name:
        return None
    lowered = name.lower()
    for keywords, emoji in _FOOD_EMOJI_KEYWORDS:
        for kw in keywords:
            if kw in lowered:
                return emoji
    return None


def _normalize_food_name(name: Optional[str]) -> str:
    """Lowercase + collapse whitespace for duplicate comparison."""
    if not name:
        return ""
    return " ".join(name.lower().split())


async def _find_duplicate_custom_food(
    db, user_id: str, candidate_name: Optional[str]
) -> Optional[AiSuggestedDuplicate]:
    """
    Detect an existing custom food that closely matches the candidate name
    (C5: duplicate of an existing custom food → offer "use existing").
    """
    norm = _normalize_food_name(candidate_name)
    if not norm:
        return None
    try:
        result = (
            db.client.table("saved_foods")
            .select("id, name, total_calories, total_protein_g, source_type")
            .eq("user_id", user_id)
            .is_("deleted_at", "null")
            .ilike("name", f"%{candidate_name.strip()}%")
            .limit(10)
            .execute()
        )
        for row in result.data or []:
            if _normalize_food_name(row.get("name")) == norm:
                return AiSuggestedDuplicate(
                    id=row["id"],
                    name=row["name"],
                    total_calories=row.get("total_calories"),
                    total_protein_g=row.get("total_protein_g"),
                    source_type=FoodSourceType(row.get("source_type", "text")),
                )
    except Exception as e:
        # Duplicate detection is best-effort — never block the suggestion on it.
        logger.warning(f"Duplicate-food check failed for {user_id}: {e}")
    return None


@router.post("/saved-foods/ai-suggest", response_model=AiSuggestFoodResponse)
@limiter.limit("15/minute")
async def ai_suggest_custom_food(
    request: Request,
    body: AiSuggestFoodRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    A4 — Suggest fields for a NEW custom food. Does NOT create or log anything.

    Two paths:
      - typed `name`        → text food analysis (reuses /analyze-text engine)
      - `image_base64`      → nutrition-label OCR (reuses analyze_nutrition_label)

    Every returned value is advisory — the client renders them into editable
    fields. Macros the AI cannot determine are returned as null + flagged in
    `missing_fields` (never silently guessed). A matching existing custom food
    is returned in `duplicate` so the client can offer "use existing".
    """
    user_id = current_user["id"]

    if not body.name and not body.image_base64:
        raise HTTPException(
            status_code=400,
            detail="Provide either a food name or a nutrition-label photo.",
        )

    db = get_supabase_db()

    # ---- Path 1: nutrition-label photo ------------------------------------
    if body.image_base64:
        try:
            from services.vision_service import get_vision_service
            vision_service = get_vision_service()
            analysis = await asyncio.wait_for(
                vision_service.analyze_nutrition_label(
                    image_base64=body.image_base64,
                    mime_type=body.mime_type or "image/jpeg",
                    servings_consumed=1.0,
                ),
                timeout=60,
            )
        except asyncio.TimeoutError:
            raise HTTPException(status_code=504, detail="Label analysis timed out. Please retry.")
        except Exception as e:
            logger.error(f"[ai-suggest] Label OCR failed: {e}", exc_info=True)
            raise safe_internal_error(e, "nutrition")

        if not analysis or not analysis.get("food_items"):
            # C5: AI couldn't read it → return a flagged-empty response, don't guess.
            return AiSuggestFoodResponse(
                source="nutrition_label",
                low_confidence=True,
                missing_fields=["calories", "protein_g", "carbs_g", "fat_g", "fiber_g"],
                note="Could not read the nutrition label. Enter the values manually or retry with a clearer photo.",
            )

        product_name = analysis.get("product_name")
        if product_name in (None, "", "unknown"):
            product_name = None
        first_item = (analysis.get("food_items") or [{}])[0]

        # The label OCR returns a product name; a recognizable brand may be
        # embedded. We only surface a brand if the model explicitly read one —
        # never invent one (C5).
        brand = analysis.get("brand")
        if brand in (None, "", "unknown"):
            brand = None

        def _num(v):
            return v if isinstance(v, (int, float)) and v >= 0 else None

        cal = _num(analysis.get("total_calories"))
        protein = _num(analysis.get("total_protein_g"))
        carbs = _num(analysis.get("total_carbs_g"))
        fat = _num(analysis.get("total_fat_g"))
        fiber = _num(analysis.get("total_fiber_g"))

        missing = [
            f for f, v in [
                ("calories", cal), ("protein_g", protein),
                ("carbs_g", carbs), ("fat_g", fat),
            ] if v is None
        ]
        # health_score_reasons == ["ai_unavailable"] signals a degraded read.
        degraded = analysis.get("health_score_reasons") == ["ai_unavailable"]
        low_conf = bool(missing) or degraded

        suggested_name = product_name or first_item.get("name")
        dup = await _find_duplicate_custom_food(db, user_id, suggested_name)

        return AiSuggestFoodResponse(
            name=suggested_name,
            brand=brand,
            emoji=_suggest_emoji(suggested_name),
            amount=analysis.get("serving_size") or first_item.get("amount"),
            calories=int(cal) if cal is not None else None,
            protein_g=protein,
            carbs_g=carbs,
            fat_g=fat,
            fiber_g=fiber,
            source="nutrition_label",
            low_confidence=low_conf,
            missing_fields=missing,
            note=(
                "Some values were unreadable — fill them in before saving."
                if missing else
                ("Double-check the values against the label." if degraded else None)
            ),
            duplicate=dup,
        )

    # ---- Path 2: typed name ----------------------------------------------
    cache_service = get_food_analysis_cache_service()
    try:
        analysis = await asyncio.wait_for(
            cache_service.analyze_food(
                description=body.name,
                user_id=user_id,
                use_cache=True,
            ),
            timeout=8.0,
        )
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="Analysis timed out. Please retry.")
    except Exception as e:
        logger.error(f"[ai-suggest] Text analysis failed: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")

    if not analysis or not analysis.get("food_items"):
        # C5: AI couldn't determine macros → flagged-empty, manual entry.
        return AiSuggestFoodResponse(
            name=body.name.strip(),
            emoji=_suggest_emoji(body.name),
            source="text",
            low_confidence=True,
            missing_fields=["calories", "protein_g", "carbs_g", "fat_g", "fiber_g"],
            note="Couldn't estimate this food. Enter the macros manually.",
        )

    first_item = (analysis.get("food_items") or [{}])[0]

    def _num2(v):
        return v if isinstance(v, (int, float)) and v >= 0 else None

    cal = _num2(analysis.get("total_calories")) or _num2(first_item.get("calories"))
    protein = _num2(analysis.get("total_protein_g")) or _num2(first_item.get("protein_g"))
    carbs = _num2(analysis.get("total_carbs_g")) or _num2(first_item.get("carbs_g"))
    fat = _num2(analysis.get("total_fat_g")) or _num2(first_item.get("fat_g"))
    fiber = _num2(analysis.get("total_fiber_g")) or _num2(first_item.get("fiber_g"))

    missing = [
        f for f, v in [
            ("calories", cal), ("protein_g", protein),
            ("carbs_g", carbs), ("fat_g", fat),
        ] if v is None
    ]

    # A cleaner display name: prefer the AI's parsed item name over raw input.
    suggested_name = first_item.get("name") or body.name.strip()
    # Brand is captured only if the AI parsed one — we never invent it.
    brand = first_item.get("brand") or analysis.get("brand")
    if brand in (None, "", "unknown"):
        brand = None

    dup = await _find_duplicate_custom_food(db, user_id, suggested_name)

    return AiSuggestFoodResponse(
        name=suggested_name,
        brand=brand,
        emoji=_suggest_emoji(suggested_name) or _suggest_emoji(body.name),
        amount=first_item.get("amount"),
        calories=int(cal) if cal is not None else None,
        protein_g=protein,
        carbs_g=carbs,
        fat_g=fat,
        fiber_g=fiber,
        source="text",
        low_confidence=bool(missing),
        missing_fields=missing,
        note=("Some macros couldn't be estimated — fill them in before saving." if missing else None),
        duplicate=dup,
    )


