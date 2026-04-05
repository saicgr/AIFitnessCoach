"""Recipe CRUD and logging endpoints."""
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, get_user_now_iso
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
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


@router.post("/recipes", response_model=Recipe)
async def create_recipe(request: RecipeCreate, user_id: str = Query(...), current_user: dict = Depends(get_current_user)):
    """
    Create a new recipe with ingredients.

    The recipe's nutrition values are automatically calculated from ingredients.
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
            raise HTTPException(status_code=500, detail="Failed to create recipe")

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

        # Fetch the updated recipe (trigger will have calculated nutrition)
        updated = db.client.table("user_recipes").select("*").eq("id", recipe_id).single().execute()

        logger.info(f"Successfully created recipe {recipe_id}")

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
        logger.error(f"Failed to create recipe: {e}")
        raise safe_internal_error(e, "nutrition")


@router.get("/recipes", response_model=RecipesResponse)
async def list_recipes(
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    category: Optional[str] = Query(default=None),
    include_public: bool = Query(default=False),
):
    """
    List user's recipes with optional public recipes.
    """
    logger.info(f"Listing recipes for user {user_id}")

    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("user_recipes")\
            .select("id, name, category, calories_per_serving, protein_per_serving_g, servings, times_logged, image_url, created_at")\
            .is_("deleted_at", "null")\
            .order("times_logged", desc=True)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)

        if include_public:
            query = query.or_(f"user_id.eq.{user_id},is_public.eq.true")
        else:
            query = query.eq("user_id", user_id)

        if category:
            query = query.eq("category", category)

        result = query.execute()

        # Get ingredient counts
        items = []
        for row in result.data or []:
            # Count ingredients
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
            ))

        # Get total count
        count_query = db.client.table("user_recipes")\
            .select("id", count="exact")\
            .is_("deleted_at", "null")

        if include_public:
            count_query = count_query.or_(f"user_id.eq.{user_id},is_public.eq.true")
        else:
            count_query = count_query.eq("user_id", user_id)

        if category:
            count_query = count_query.eq("category", category)

        count_result = count_query.execute()
        total_count = count_result.count or 0

        return RecipesResponse(items=items, total_count=total_count)

    except Exception as e:
        logger.error(f"Failed to list recipes: {e}")
        raise safe_internal_error(e, "nutrition")


@router.get("/recipes/{recipe_id}", response_model=Recipe)
async def get_recipe(recipe_id: str, user_id: str = Query(...), current_user: dict = Depends(get_current_user)):
    """
    Get a specific recipe with all ingredients.
    """
    logger.info(f"Getting recipe {recipe_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get recipe
        result = db.client.table("user_recipes")\
            .select("*")\
            .eq("id", recipe_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        row = result.data

        # Check ownership or public
        if row["user_id"] != user_id and not row.get("is_public"):
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

        return Recipe(
            id=row["id"],
            user_id=row["user_id"],
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
            ingredients=ingredients,
            ingredient_count=len(ingredients),
            created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(row["updated_at"].replace("Z", "+00:00")),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get recipe: {e}")
        raise safe_internal_error(e, "nutrition")


@router.delete("/recipes/{recipe_id}")
async def delete_recipe(recipe_id: str, user_id: str = Query(...), current_user: dict = Depends(get_current_user)):
    """
    Delete a recipe (soft delete).
    """
    logger.info(f"Deleting recipe {recipe_id} for user {user_id}")

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
        logger.error(f"Failed to delete recipe: {e}")
        raise safe_internal_error(e, "nutrition")


@router.post("/recipes/{recipe_id}/log", response_model=LogRecipeResponse)
async def log_recipe(
    recipe_id: str,
    request: LogRecipeRequest,
    http_request: Request = None,
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
        logger.error(f"Failed to log recipe: {e}")
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
            raise HTTPException(status_code=500, detail="Failed to add ingredient")

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
        logger.error(f"Failed to add ingredient: {e}")
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
        logger.error(f"Failed to remove ingredient: {e}")
        raise safe_internal_error(e, "nutrition")


