"""Shared recipe-create logic used by `/recipes` POST and `/save-as-recipe`.

Extracted out of `api/v1/nutrition/recipes.py:create_recipe` so the
Save-as-Recipe pipeline (which adds an AI enrichment step in front) can
share the same dedupe + insert + ChromaDB-index code path. Triggers in
migration 039 / 505 / 506 / 509 do the rest:
  - `recalculate_recipe_nutrition()`  → per-serving macros
  - `recipe_versions` snapshot trigger → v1 capture
  - `update_recipe_log_count()`        → times_logged auto-increment when
                                          a food_log is later linked

The dedupe layer reads the GENERATED STORED `name_normalized` column added
in migration 2056 — a pre-insert SELECT on (user_id, name_normalized) finds
existing recipes regardless of casing / punctuation / plurals / diacritics.
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional

from fastapi import BackgroundTasks, HTTPException

from core.db import get_supabase_db
from core.food_naming import normalize_food_name
from core.logger import get_logger
from models.recipe import (
    Recipe,
    RecipeCategory,
    RecipeCreate,
    RecipeIngredient,
    RecipeSourceType,
)

logger = get_logger(__name__)


@dataclass
class PersistRecipeResult:
    recipe: Recipe
    merged: bool   # True when an existing recipe was returned instead of inserting a new one


async def persist_recipe(
    *,
    user_id: str,
    request: RecipeCreate,
    background_tasks: BackgroundTasks,
) -> PersistRecipeResult:
    """Insert (or merge into) a `user_recipes` row + ingredients + ChromaDB index.

    Dedupe rule: if a soft-undeleted recipe owned by `user_id` already has the
    same `name_normalized`, return that recipe with `merged=True` instead of
    inserting a duplicate. The DB-side unique index on
    (user_id, name_normalized) WHERE deleted_at IS NULL would otherwise
    raise a 23505, so the SELECT-then-INSERT path is the friendlier UX.

    The caller is responsible for any subsequent linkage (e.g. setting
    `food_logs.recipe_id` to fire the times_logged trigger).
    """
    db = get_supabase_db()

    # ── Dedupe: pre-insert SELECT on the GENERATED `name_normalized` column.
    name_norm = normalize_food_name(request.name)
    if name_norm:
        existing = (
            db.client.table("user_recipes")
            .select("*")
            .eq("user_id", user_id)
            .eq("name_normalized", name_norm)
            .is_("deleted_at", "null")
            .limit(1)
            .execute()
        )
        if existing.data:
            row = existing.data[0]
            ings = (
                db.client.table("recipe_ingredients")
                .select("*")
                .eq("recipe_id", row["id"])
                .order("ingredient_order")
                .execute()
            )
            return PersistRecipeResult(
                recipe=_row_to_recipe(row, ings.data or []),
                merged=True,
            )

    # ── Fresh insert.
    recipe_id = str(uuid.uuid4())
    now = datetime.now().isoformat()
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

    # ── Ingredients.
    ingredients: List[RecipeIngredient] = []
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
            "cooking_method": ing.cooking_method.value if ing.cooking_method else None,
            "nutrition_source": ing.nutrition_source.value if ing.nutrition_source else None,
            "nutrition_confidence": ing.nutrition_confidence,
            "is_negligible": ing.is_negligible,
            "raw_text": ing.raw_text,
            "created_at": now,
            "updated_at": now,
        }
        db.client.table("recipe_ingredients").insert(ing_data).execute()
        # ing is a RecipeIngredientCreate which already carries ingredient_order;
        # strip it from the splat to avoid colliding with the explicit kwarg.
        ing_payload = {k: v for k, v in ing.dict().items() if k != "ingredient_order"}
        ingredients.append(
            RecipeIngredient(
                id=ing_id,
                recipe_id=recipe_id,
                ingredient_order=idx,
                **ing_payload,
                created_at=datetime.fromisoformat(now),
                updated_at=datetime.fromisoformat(now),
            )
        )

    # ── Refetch to pick up trigger-computed per-serving nutrition.
    try:
        updated = (
            db.client.table("user_recipes")
            .select("*")
            .eq("id", recipe_id)
            .single()
            .execute()
        )
    except Exception as e:
        logger.error(f"Failed to refetch recipe {recipe_id} after insert: {e}")
        raise HTTPException(status_code=500, detail="Recipe created but could not be loaded.")

    # ── Fire-and-forget ChromaDB index for semantic search.
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

    return PersistRecipeResult(
        recipe=_row_to_recipe(updated.data, [_ing_to_dict(i) for i in ingredients], ingredients=ingredients),
        merged=False,
    )


def _ing_to_dict(i: RecipeIngredient) -> dict:
    return i.dict()


def _row_to_recipe(row: dict, ing_rows: list, *, ingredients: Optional[List[RecipeIngredient]] = None) -> Recipe:
    """Hydrate a Recipe from a Supabase row + the matching ingredient rows."""
    if ingredients is None:
        ingredients = [
            RecipeIngredient(
                id=ir["id"],
                recipe_id=ir["recipe_id"],
                ingredient_order=ir.get("ingredient_order", 0),
                food_name=ir["food_name"],
                brand=ir.get("brand"),
                amount=ir["amount"],
                unit=ir["unit"],
                amount_grams=ir.get("amount_grams"),
                barcode=ir.get("barcode"),
                calories=ir.get("calories"),
                protein_g=ir.get("protein_g"),
                carbs_g=ir.get("carbs_g"),
                fat_g=ir.get("fat_g"),
                fiber_g=ir.get("fiber_g"),
                sugar_g=ir.get("sugar_g"),
                vitamin_d_iu=ir.get("vitamin_d_iu"),
                calcium_mg=ir.get("calcium_mg"),
                iron_mg=ir.get("iron_mg"),
                sodium_mg=ir.get("sodium_mg"),
                omega3_g=ir.get("omega3_g"),
                notes=ir.get("notes"),
                is_optional=ir.get("is_optional", False),
                created_at=_parse_iso(ir.get("created_at")),
                updated_at=_parse_iso(ir.get("updated_at")),
            )
            for ir in ing_rows
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
        ingredients=ingredients,
        ingredient_count=len(ingredients),
        created_at=_parse_iso(row["created_at"]),
        updated_at=_parse_iso(row["updated_at"]),
    )


def _parse_iso(s) -> datetime:
    """Lenient ISO-8601 parser. Python 3.9's `fromisoformat` rejects fractional
    seconds with non-3/6 digit precision (e.g. Postgres' 5-digit microseconds),
    so fall back to dateutil which handles every realistic shape."""
    if s is None:
        return datetime.now()
    if isinstance(s, datetime):
        return s
    raw = str(s).replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(raw)
    except ValueError:
        from dateutil import parser as _dateutil_parser
        return _dateutil_parser.isoparse(raw)


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
