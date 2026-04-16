"""Recipe CRUD and logging endpoints."""
from core.db import get_supabase_db
from datetime import datetime
from typing import List, Optional
import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, Query, Request, UploadFile

from core.timezone_utils import resolve_timezone, get_user_now_iso
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.activity_logger import log_user_activity

from models.recipe import (
    Recipe,
    RecipeCreate,
    RecipeUpdate,
    RecipeSummary,
    RecipesResponse,
    RecipeIngredient,
    RecipeIngredientCreate,
    LogRecipeRequest,
    LogRecipeResponse,
    RecipeCategory,
    RecipeSourceType,
)

router = APIRouter()
logger = get_logger(__name__)

# ============================================
# Recipe Endpoints
# ============================================


async def _index_recipe_in_chroma(
    *,
    recipe_id: str,
    user_id: str,
    name: str,
    description: Optional[str],
    ingredient_names: List[str],
    cuisine: Optional[str],
    category: Optional[str],
    tags: Optional[List[str]],
    is_public: bool,
):
    """BackgroundTask helper: index a recipe in the saved_foods Chroma collection.

    Wrapped here so the request can return immediately even when ChromaDB or
    Gemini embedding is slow/unavailable. Failures are logged but never propagate.
    """
    try:
        from services.saved_foods_rag_service import get_saved_foods_rag

        rag = get_saved_foods_rag()
        await rag.save_recipe(
            recipe_id=recipe_id,
            user_id=user_id,
            name=name,
            description=description,
            ingredient_names=ingredient_names,
            cuisine=cuisine,
            category=category,
            tags=tags,
            is_public=is_public,
        )
    except Exception as exc:  # noqa: BLE001 — best-effort indexing
        logger.warning(f"[Chroma] Recipe index failed for {recipe_id}: {exc}", exc_info=True)


async def _delete_recipe_from_chroma(recipe_id: str):
    try:
        from services.saved_foods_rag_service import get_saved_foods_rag

        rag = get_saved_foods_rag()
        await rag.delete_recipe(recipe_id)
    except Exception as exc:  # noqa: BLE001
        logger.warning(f"[Chroma] Recipe delete failed for {recipe_id}: {exc}", exc_info=True)


@router.post("/recipes", response_model=Recipe)
async def create_recipe(
    request: RecipeCreate,
    background_tasks: BackgroundTasks,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new recipe with ingredients.

    The recipe's nutrition values are automatically calculated from ingredients.
    Spawns a background ChromaDB index so semantic recipe search can find this
    row by name/ingredients/cuisine without joining Postgres.
    """
    logger.info(f"Creating recipe '{request.name}' for user {user_id}")

    try:
        db = get_supabase_db()

        # Generate ID
        recipe_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        # Create recipe
        recipe_data = {
            "id": recipe_id,
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "servings": request.servings,
            "prep_time_minutes": request.prep_time_minutes,
            "cook_time_minutes": request.cook_time_minutes,
            "instructions": request.instructions,
            "image_url": request.image_url,
            "category": request.category.value if request.category else None,
            "cuisine": request.cuisine,
            "tags": request.tags or [],
            "source_url": request.source_url,
            "source_type": request.source_type.value,
            "is_public": request.is_public,
            "times_logged": 0,
            "created_at": now,
            "updated_at": now,
        }

        result = db.client.table("user_recipes").insert(recipe_data).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to create recipe"), "nutrition")

        # Add ingredients
        ingredients = []
        for idx, ing in enumerate(request.ingredients):
            ing_id = str(uuid.uuid4())
            ing_data = {
                "id": ing_id,
                "recipe_id": recipe_id,
                "ingredient_order": idx,
                "food_name": ing.food_name,
                "brand": ing.brand,
                "amount": ing.amount,
                "unit": ing.unit,
                "amount_grams": ing.amount_grams,
                "barcode": ing.barcode,
                "calories": ing.calories,
                "protein_g": ing.protein_g,
                "carbs_g": ing.carbs_g,
                "fat_g": ing.fat_g,
                "fiber_g": ing.fiber_g,
                "sugar_g": ing.sugar_g,
                "vitamin_d_iu": ing.vitamin_d_iu,
                "calcium_mg": ing.calcium_mg,
                "iron_mg": ing.iron_mg,
                "sodium_mg": ing.sodium_mg,
                "omega3_g": ing.omega3_g,
                "notes": ing.notes,
                "is_optional": ing.is_optional,
                "created_at": now,
                "updated_at": now,
            }
            db.client.table("recipe_ingredients").insert(ing_data).execute()
            ingredients.append(RecipeIngredient(
                id=ing_id,
                recipe_id=recipe_id,
                ingredient_order=idx,
                food_name=ing.food_name,
                brand=ing.brand,
                amount=ing.amount,
                unit=ing.unit,
                amount_grams=ing.amount_grams,
                barcode=ing.barcode,
                calories=ing.calories,
                protein_g=ing.protein_g,
                carbs_g=ing.carbs_g,
                fat_g=ing.fat_g,
                fiber_g=ing.fiber_g,
                sugar_g=ing.sugar_g,
                vitamin_d_iu=ing.vitamin_d_iu,
                calcium_mg=ing.calcium_mg,
                iron_mg=ing.iron_mg,
                sodium_mg=ing.sodium_mg,
                omega3_g=ing.omega3_g,
                notes=ing.notes,
                is_optional=ing.is_optional,
                created_at=datetime.fromisoformat(now),
                updated_at=datetime.fromisoformat(now),
            ))

        # Fetch the updated recipe (trigger will have calculated nutrition). .single()
        # raises if the row is missing (RLS or race with delete) — surface a clean 500.
        try:
            updated = db.client.table("user_recipes").select("*").eq("id", recipe_id).single().execute()
        except Exception as e:
            logger.error(f"Failed to refetch recipe {recipe_id} after insert: {e}")
            raise HTTPException(status_code=500, detail="Recipe created but could not be loaded.")

        if not updated or not updated.data:
            logger.error(f"Recipe {recipe_id} returned no data after insert")
            raise HTTPException(status_code=500, detail="Recipe created but could not be loaded.")

        logger.info(f"Successfully created recipe {recipe_id}")

        # Fire-and-forget: index in ChromaDB so semantic recipe-search finds it.
        background_tasks.add_task(
            _index_recipe_in_chroma,
            recipe_id=recipe_id,
            user_id=user_id,
            name=request.name,
            description=request.description,
            ingredient_names=[i.food_name for i in request.ingredients],
            cuisine=request.cuisine,
            category=(request.category.value if request.category else None),
            tags=request.tags,
            is_public=request.is_public,
        )

        return Recipe(
            id=updated.data["id"],
            user_id=updated.data["user_id"],
            name=updated.data["name"],
            description=updated.data.get("description"),
            servings=updated.data.get("servings", 1),
            prep_time_minutes=updated.data.get("prep_time_minutes"),
            cook_time_minutes=updated.data.get("cook_time_minutes"),
            instructions=updated.data.get("instructions"),
            image_url=updated.data.get("image_url"),
            category=RecipeCategory(updated.data["category"]) if updated.data.get("category") else None,
            cuisine=updated.data.get("cuisine"),
            tags=updated.data.get("tags", []),
            source_url=updated.data.get("source_url"),
            source_type=RecipeSourceType(updated.data.get("source_type", "manual")),
            is_public=updated.data.get("is_public", False),
            calories_per_serving=updated.data.get("calories_per_serving"),
            protein_per_serving_g=updated.data.get("protein_per_serving_g"),
            carbs_per_serving_g=updated.data.get("carbs_per_serving_g"),
            fat_per_serving_g=updated.data.get("fat_per_serving_g"),
            fiber_per_serving_g=updated.data.get("fiber_per_serving_g"),
            sugar_per_serving_g=updated.data.get("sugar_per_serving_g"),
            vitamin_d_per_serving_iu=updated.data.get("vitamin_d_per_serving_iu"),
            calcium_per_serving_mg=updated.data.get("calcium_per_serving_mg"),
            iron_per_serving_mg=updated.data.get("iron_per_serving_mg"),
            omega3_per_serving_g=updated.data.get("omega3_per_serving_g"),
            sodium_per_serving_mg=updated.data.get("sodium_per_serving_mg"),
            times_logged=updated.data.get("times_logged", 0),
            ingredients=ingredients,
            ingredient_count=len(ingredients),
            created_at=datetime.fromisoformat(updated.data["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(updated.data["updated_at"].replace("Z", "+00:00")),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create recipe: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/recipes", response_model=RecipesResponse)
async def list_recipes(
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    category: Optional[str] = Query(default=None),
    include_public: bool = Query(default=False),
    # --- Discover / Favorites / Improvize additions (migration 1925) ---
    source_type_in: Optional[str] = Query(
        default=None,
        description=(
            "CSV of RecipeSourceType enum values to filter by, e.g. "
            "'improvized,cloned_from_share'. When set, curated rows are NOT "
            "auto-excluded so the caller can request them explicitly."
        ),
    ),
    is_favorite: Optional[bool] = Query(
        default=None,
        description="When true, restrict to recipes favorited by the current user.",
    ),
    sort_by: str = Query(
        default="created_desc",
        regex=r"^(created_desc|name_asc|most_logged|times_logged|last_cooked)$",
        description="Sort order for the My Recipes list.",
    ),
):
    """
    List the user's recipes (and optionally public ones).

    Default behavior ("My Recipes" tab):
      - user_id = caller, is_curated=FALSE (curated = Discover tab only),
        deleted_at IS NULL.

    Behavior changes when extra filters are supplied:
      - is_favorite=true: return only recipes the caller has favorited.
        We DO NOT restrict to user_id in this mode — a user can favorite
        curated or shared recipes owned by others.
      - source_type_in=...: restrict to one or more source_type values.
        In this mode the curated auto-exclude is relaxed (so callers can
        explicitly ask for e.g. source_type_in=improvized to see their forks).

    Sorts:
      - created_desc (default): newest first.
      - name_asc: alphabetical.
      - most_logged: times_logged DESC, tiebreak created_at DESC.
      - last_cooked: last_logged_at DESC (nulls last), tiebreak created_at DESC.
    """
    logger.info(f"Listing recipes for user {user_id}")

    try:
        db = get_supabase_db()

        # Base columns — must include the new Discover/Favorites/Improvize
        # fields so the response includes is_curated / slug / source_*.
        select_cols = (
            "id, name, category, calories_per_serving, protein_per_serving_g, "
            "servings, times_logged, image_url, created_at, last_logged_at, "
            "is_curated, slug, source_recipe_id, source_recipe_name, source_type"
        )

        query = db.client.table("user_recipes").select(select_cols).is_("deleted_at", "null")
        count_query = db.client.table("user_recipes").select("id", count="exact").is_("deleted_at", "null")

        # --- Ownership / visibility ---
        if is_favorite is True:
            # Pull the user's favorite recipe ids; then scope the query to
            # that set. Don't restrict to user_id — users can favorite
            # curated / shared recipes owned by others.
            from services.recipe_favorites_service import get_recipe_favorites_service
            fav_ids = await get_recipe_favorites_service().recipe_ids_for_user(user_id)
            if not fav_ids:
                # Short-circuit: empty list → empty response.
                return RecipesResponse(items=[], total_count=0)
            query = query.in_("id", fav_ids)
            count_query = count_query.in_("id", fav_ids)
        elif include_public:
            query = query.or_(f"user_id.eq.{user_id},is_public.eq.true")
            count_query = count_query.or_(f"user_id.eq.{user_id},is_public.eq.true")
        else:
            query = query.eq("user_id", user_id)
            count_query = count_query.eq("user_id", user_id)

        # --- Curated filter ---
        # Default: exclude curated rows from "My Recipes". Relax only when the
        # caller explicitly asks for source_type filtering OR favorites
        # (favoriting a curated recipe should still list it).
        if is_favorite is not True and not source_type_in:
            query = query.eq("is_curated", False)
            count_query = count_query.eq("is_curated", False)

        # --- Category filter ---
        if category:
            query = query.eq("category", category)
            count_query = count_query.eq("category", category)

        # --- source_type_in filter (CSV → list) ---
        if source_type_in:
            source_types = [s.strip() for s in source_type_in.split(",") if s.strip()]
            if source_types:
                query = query.in_("source_type", source_types)
                count_query = count_query.in_("source_type", source_types)

        # --- Sort ---
        # Normalize legacy alias from older app versions
        if sort_by == "times_logged":
            sort_by = "most_logged"
        if sort_by == "name_asc":
            query = query.order("name")
        elif sort_by == "most_logged":
            query = query.order("times_logged", desc=True).order("created_at", desc=True)
        elif sort_by == "last_cooked":
            # nullsfirst=False → recipes never cooked sink to the bottom.
            query = query.order("last_logged_at", desc=True, nullsfirst=False).order("created_at", desc=True)
        else:  # created_desc (default)
            query = query.order("created_at", desc=True)

        query = query.range(offset, offset + limit - 1)
        result = query.execute()
        rows = result.data or []

        # --- Bulk favorites lookup to avoid N+1 heart checks on the UI ---
        ids = [r["id"] for r in rows]
        from services.recipe_favorites_service import get_recipe_favorites_service
        fav_map = await get_recipe_favorites_service().is_favorited_bulk(current_user["id"], ids)

        items = []
        for row in rows:
            # Ingredient count — per-row query kept for backwards compat, but
            # this is the main hotspot for the list. A future optimization
            # is a single aggregate query grouped by recipe_id.
            count_result = db.client.table("recipe_ingredients")\
                .select("id", count="exact")\
                .eq("recipe_id", row["id"])\
                .execute()
            ingredient_count = count_result.count or 0

            items.append(RecipeSummary(
                id=row["id"],
                name=row["name"],
                category=row.get("category"),
                calories_per_serving=row.get("calories_per_serving"),
                protein_per_serving_g=row.get("protein_per_serving_g"),
                servings=row.get("servings", 1),
                ingredient_count=ingredient_count,
                times_logged=row.get("times_logged", 0),
                image_url=row.get("image_url"),
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
                is_curated=row.get("is_curated", False),
                slug=row.get("slug"),
                source_recipe_id=row.get("source_recipe_id"),
                source_recipe_name=row.get("source_recipe_name"),
                source_type=row.get("source_type"),
                is_favorited=fav_map.get(row["id"], False),
            ))

        count_result = count_query.execute()
        total_count = count_result.count or 0

        return RecipesResponse(items=items, total_count=total_count)

    except Exception as e:
        logger.error(f"Failed to list recipes: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/recipes/{recipe_id}", response_model=Recipe)
async def get_recipe(recipe_id: str, user_id: str = Query(...), current_user: dict = Depends(get_current_user)):
    """
    Get a specific recipe with all ingredients.

    Visibility:
      - Owner can always read.
      - is_public=TRUE: any authenticated user can read.
      - is_curated=TRUE: any authenticated user can read (Discover tab).
    """
    logger.info(f"Getting recipe {recipe_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get recipe (select * includes is_curated, slug, source_recipe_*
        # columns added in migration 1925).
        result = db.client.table("user_recipes")\
            .select("*")\
            .eq("id", recipe_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        row = result.data

        # Check ownership, public, or curated. Curated rows may have user_id=NULL.
        if (
            row.get("user_id") != user_id
            and not row.get("is_public")
            and not row.get("is_curated")
        ):
            raise HTTPException(status_code=403, detail="Access denied")

        # Get ingredients
        ing_result = db.client.table("recipe_ingredients")\
            .select("*")\
            .eq("recipe_id", recipe_id)\
            .order("ingredient_order")\
            .execute()

        ingredients = [
            RecipeIngredient(
                id=ing["id"],
                recipe_id=ing["recipe_id"],
                ingredient_order=ing.get("ingredient_order", 0),
                food_name=ing["food_name"],
                brand=ing.get("brand"),
                amount=ing["amount"],
                unit=ing["unit"],
                amount_grams=ing.get("amount_grams"),
                barcode=ing.get("barcode"),
                calories=ing.get("calories"),
                protein_g=ing.get("protein_g"),
                carbs_g=ing.get("carbs_g"),
                fat_g=ing.get("fat_g"),
                fiber_g=ing.get("fiber_g"),
                sugar_g=ing.get("sugar_g"),
                vitamin_d_iu=ing.get("vitamin_d_iu"),
                calcium_mg=ing.get("calcium_mg"),
                iron_mg=ing.get("iron_mg"),
                sodium_mg=ing.get("sodium_mg"),
                omega3_g=ing.get("omega3_g"),
                notes=ing.get("notes"),
                is_optional=ing.get("is_optional", False),
                created_at=datetime.fromisoformat(ing["created_at"].replace("Z", "+00:00")),
                updated_at=datetime.fromisoformat(ing["updated_at"].replace("Z", "+00:00")),
            )
            for ing in (ing_result.data or [])
        ]

        # Compute is_favorited for the calling user. Lazy import to avoid a
        # circular import at module load (favorites service imports nothing
        # from recipes.py, but keeping it local is cheap).
        from services.recipe_favorites_service import get_recipe_favorites_service
        is_favorited = await get_recipe_favorites_service().is_favorited(current_user["id"], recipe_id)

        return Recipe(
            id=row["id"],
            user_id=row.get("user_id"),  # may be NULL for curated rows
            name=row["name"],
            description=row.get("description"),
            servings=row.get("servings", 1),
            prep_time_minutes=row.get("prep_time_minutes"),
            cook_time_minutes=row.get("cook_time_minutes"),
            instructions=row.get("instructions"),
            image_url=row.get("image_url"),
            category=RecipeCategory(row["category"]) if row.get("category") else None,
            cuisine=row.get("cuisine"),
            tags=row.get("tags", []),
            source_url=row.get("source_url"),
            source_type=RecipeSourceType(row.get("source_type", "manual")),
            is_public=row.get("is_public", False),
            cooked_yield_grams=row.get("cooked_yield_grams"),
            cooking_method=row.get("cooking_method"),
            calories_per_serving=row.get("calories_per_serving"),
            protein_per_serving_g=row.get("protein_per_serving_g"),
            carbs_per_serving_g=row.get("carbs_per_serving_g"),
            fat_per_serving_g=row.get("fat_per_serving_g"),
            fiber_per_serving_g=row.get("fiber_per_serving_g"),
            sugar_per_serving_g=row.get("sugar_per_serving_g"),
            vitamin_d_per_serving_iu=row.get("vitamin_d_per_serving_iu"),
            calcium_per_serving_mg=row.get("calcium_per_serving_mg"),
            iron_per_serving_mg=row.get("iron_per_serving_mg"),
            omega3_per_serving_g=row.get("omega3_per_serving_g"),
            sodium_per_serving_mg=row.get("sodium_per_serving_mg"),
            times_logged=row.get("times_logged", 0),
            last_logged_at=datetime.fromisoformat(row["last_logged_at"].replace("Z", "+00:00")) if row.get("last_logged_at") else None,
            # Discover / Favorites / Improvize (migration 1925)
            is_curated=row.get("is_curated", False),
            slug=row.get("slug"),
            source_recipe_id=row.get("source_recipe_id"),
            source_recipe_name=row.get("source_recipe_name"),
            source_recipe_user_id=row.get("source_recipe_user_id"),
            is_favorited=is_favorited,
            ingredients=ingredients,
            ingredient_count=len(ingredients),
            created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(row["updated_at"].replace("Z", "+00:00")),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get recipe: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.delete("/recipes/{recipe_id}")
async def delete_recipe(
    recipe_id: str,
    background_tasks: BackgroundTasks,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a recipe (soft delete).

    Also removes it from the Chroma semantic-search index so search no longer
    surfaces a deleted recipe (the lexical path already filters via deleted_at).
    """
    logger.info(f"Deleting recipe {recipe_id} for user {user_id}")
    background_tasks.add_task(_delete_recipe_from_chroma, recipe_id)

    try:
        db = get_supabase_db()

        result = db.client.table("user_recipes")\
            .update({"deleted_at": datetime.now().isoformat()})\
            .eq("id", recipe_id)\
            .eq("user_id", user_id)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        return {"status": "deleted", "id": recipe_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete recipe: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/recipes/{recipe_id}/log", response_model=LogRecipeResponse)
async def log_recipe(
    recipe_id: str,
    request: LogRecipeRequest,
    http_request: Request,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Log a recipe as a meal (like re-logging a saved food).
    """
    logger.info(f"Logging recipe {recipe_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get the recipe
        result = db.client.table("user_recipes")\
            .select("*")\
            .eq("id", recipe_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        recipe = result.data

        # Check ownership or public
        if recipe["user_id"] != user_id and not recipe.get("is_public"):
            raise HTTPException(status_code=403, detail="Access denied")

        # Calculate nutrition based on servings
        calories = int((recipe.get("calories_per_serving") or 0) * request.servings)
        protein = round((recipe.get("protein_per_serving_g") or 0) * request.servings, 2)
        carbs = round((recipe.get("carbs_per_serving_g") or 0) * request.servings, 2)
        fat = round((recipe.get("fat_per_serving_g") or 0) * request.servings, 2)
        fiber = round((recipe.get("fiber_per_serving_g") or 0) * request.servings, 2) if recipe.get("fiber_per_serving_g") else None

        # Create food log
        food_items = [{
            "name": recipe["name"],
            "amount": f"{request.servings} serving{'s' if request.servings != 1 else ''}",
            "calories": calories,
            "protein_g": protein,
            "carbs_g": carbs,
            "fat_g": fat,
            "is_recipe": True,
            "recipe_id": recipe_id,
        }]

        # Resolve timezone for logged_at timestamp
        user_tz_logged_at = None
        if http_request:
            user_tz = resolve_timezone(http_request, db, user_id)
            user_tz_logged_at = get_user_now_iso(user_tz)

        created_log = db.create_food_log(
            user_id=user_id,
            meal_type=request.meal_type,
            food_items=food_items,
            total_calories=calories,
            protein_g=protein,
            carbs_g=carbs,
            fat_g=fat,
            fiber_g=fiber,
            ai_feedback=None,
            health_score=None,
            logged_at=user_tz_logged_at,
        )

        # Also update the food_logs table with recipe_id
        food_log_id = created_log.get('id') if created_log else "unknown"
        if food_log_id != "unknown":
            db.client.table("food_logs")\
                .update({"recipe_id": recipe_id})\
                .eq("id", food_log_id)\
                .execute()

        logger.info(f"Successfully logged recipe {recipe_id} as {food_log_id}")

        # Invalidate daily summary cache so the next fetch returns fresh data
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        await invalidate_daily_summary_cache(user_id)

        return LogRecipeResponse(
            success=True,
            food_log_id=food_log_id,
            recipe_name=recipe["name"],
            servings=request.servings,
            total_calories=calories,
            protein_g=protein,
            carbs_g=carbs,
            fat_g=fat,
            fiber_g=fiber,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log recipe: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/recipes/{recipe_id}/ingredients", response_model=RecipeIngredient)
async def add_ingredient(
    recipe_id: str,
    request: RecipeIngredientCreate,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Add an ingredient to a recipe.
    """
    logger.info(f"Adding ingredient to recipe {recipe_id}")

    try:
        db = get_supabase_db()

        # Verify recipe ownership
        recipe_result = db.client.table("user_recipes")\
            .select("id, user_id")\
            .eq("id", recipe_id)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not recipe_result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        # Create ingredient
        ing_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        ing_data = {
            "id": ing_id,
            "recipe_id": recipe_id,
            "ingredient_order": request.ingredient_order,
            "food_name": request.food_name,
            "brand": request.brand,
            "amount": request.amount,
            "unit": request.unit,
            "amount_grams": request.amount_grams,
            "barcode": request.barcode,
            "calories": request.calories,
            "protein_g": request.protein_g,
            "carbs_g": request.carbs_g,
            "fat_g": request.fat_g,
            "fiber_g": request.fiber_g,
            "sugar_g": request.sugar_g,
            "vitamin_d_iu": request.vitamin_d_iu,
            "calcium_mg": request.calcium_mg,
            "iron_mg": request.iron_mg,
            "sodium_mg": request.sodium_mg,
            "omega3_g": request.omega3_g,
            "notes": request.notes,
            "is_optional": request.is_optional,
            "created_at": now,
            "updated_at": now,
        }

        result = db.client.table("recipe_ingredients").insert(ing_data).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to add ingredient"), "nutrition")

        return RecipeIngredient(
            id=ing_id,
            recipe_id=recipe_id,
            ingredient_order=request.ingredient_order,
            food_name=request.food_name,
            brand=request.brand,
            amount=request.amount,
            unit=request.unit,
            amount_grams=request.amount_grams,
            barcode=request.barcode,
            calories=request.calories,
            protein_g=request.protein_g,
            carbs_g=request.carbs_g,
            fat_g=request.fat_g,
            fiber_g=request.fiber_g,
            sugar_g=request.sugar_g,
            vitamin_d_iu=request.vitamin_d_iu,
            calcium_mg=request.calcium_mg,
            iron_mg=request.iron_mg,
            sodium_mg=request.sodium_mg,
            omega3_g=request.omega3_g,
            notes=request.notes,
            is_optional=request.is_optional,
            created_at=datetime.fromisoformat(now),
            updated_at=datetime.fromisoformat(now),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add ingredient: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.delete("/recipes/{recipe_id}/ingredients/{ingredient_id}")
async def remove_ingredient(
    recipe_id: str,
    ingredient_id: str,
    current_user: dict = Depends(get_current_user),
    user_id: str = Query(...),
):
    """
    Remove an ingredient from a recipe.
    """
    logger.info(f"Removing ingredient {ingredient_id} from recipe {recipe_id}")

    try:
        db = get_supabase_db()

        # Verify recipe ownership
        recipe_result = db.client.table("user_recipes")\
            .select("id, user_id")\
            .eq("id", recipe_id)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not recipe_result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        # Delete ingredient
        result = db.client.table("recipe_ingredients")\
            .delete()\
            .eq("id", ingredient_id)\
            .eq("recipe_id", recipe_id)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Ingredient not found")

        return {"status": "deleted", "id": ingredient_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove ingredient: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/recipes/{recipe_id}/upload-image")
async def upload_recipe_image(
    recipe_id: str,
    file: UploadFile = File(...),
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Upload a photo for a recipe. Stores in S3, updates image_url on the recipe row."""
    from api.v1.nutrition.helpers import upload_food_image_to_s3

    db = get_supabase_db()

    # Verify recipe ownership
    recipe_result = (
        db.client.table("user_recipes")
        .select("id, user_id")
        .eq("id", recipe_id)
        .eq("user_id", user_id)
        .is_("deleted_at", "null")
        .single()
        .execute()
    )
    if not recipe_result.data:
        raise HTTPException(status_code=404, detail="Recipe not found")

    image_bytes = await file.read()
    content_type = file.content_type or "image/jpeg"

    image_url, storage_key = await upload_food_image_to_s3(
        file_bytes=image_bytes,
        user_id=user_id,
        content_type=content_type,
        source="recipe",
        meal_type="recipe",
    )

    # Persist the URL on the recipe row
    db.client.table("user_recipes").update({
        "image_url": image_url,
        "updated_at": datetime.now().isoformat(),
    }).eq("id", recipe_id).execute()

    logger.info(f"Uploaded recipe image for {recipe_id}: {storage_key}")
    return {"image_url": image_url, "storage_key": storage_key}

