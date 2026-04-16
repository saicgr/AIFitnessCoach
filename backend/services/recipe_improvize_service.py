"""
Recipe Improvize Service
========================

"Improvize" forks a curated (or any visible) recipe into the user's own
library so they can freely tweak it without modifying the original. This is
the public-discover equivalent of `.clone()` from the share flow.

Differences vs share/clone:
- No slug/share-link required — operates on recipe_id directly.
- Sets source_type='improvized' + denormalizes the source's name / owner so
  the fork survives the original being deleted.
- Works for both user-owned (is_public=true) AND curated (user_id IS NULL,
  is_curated=true) sources. Migration 1925 ensures SELECT RLS allows us to
  read curated rows.
"""

import logging
from typing import Optional

from fastapi import HTTPException

from core.db import get_supabase_db
from models.recipe import (
    Recipe,
    RecipeCategory,
    RecipeIngredient,
    RecipeSourceType,
)
from services.recipe_share_service import _copy_recipe_to_user
from datetime import datetime

logger = logging.getLogger(__name__)


_IMPROVIZED_PREFIX = "Improvized: "
_NAME_MAX = 255  # matches VARCHAR(255) on user_recipes.name


def _improvized_name(source_name: Optional[str]) -> str:
    """Prefix 'Improvized: ' once, capped at 255 chars.

    - Idempotent: if the source is already "Improvized: X" we don't nest it.
    - Truncation preserves the prefix (the prefix is what users recognize
      in their library), then trims the right-hand side.
    """
    base = (source_name or "Untitled recipe").strip()
    if base.lower().startswith(_IMPROVIZED_PREFIX.lower()):
        name = base
    else:
        name = f"{_IMPROVIZED_PREFIX}{base}"
    if len(name) > _NAME_MAX:
        name = name[:_NAME_MAX]
    return name


class RecipeImprovizeService:
    """Forks a recipe into the caller's library."""

    def __init__(self):
        self.db = get_supabase_db()

    async def fork(self, source_recipe_id: str, target_user_id: str) -> Recipe:
        """Create and return a new improvized copy owned by target_user_id.

        Raises HTTPException(404) if the source is not found / not visible.

        Visibility is enforced two ways:
          1) The route uses Depends(get_current_user) — caller is authed.
          2) We check the source row's ownership OR is_curated OR is_public.
             Because we read via service-role, RLS won't block us, so we
             replicate the policy client-side: curated rows are visible to
             everyone; otherwise require ownership OR is_public.
        """
        # --- 1) Load source ---
        src_res = (
            self.db.client.table("user_recipes")
            .select("*")
            .eq("id", source_recipe_id)
            .is_("deleted_at", "null")
            .limit(1)
            .execute()
        )
        if not src_res.data:
            raise HTTPException(status_code=404, detail="Recipe not found")
        src = src_res.data[0]

        # Replicate SELECT RLS policy client-side (we bypassed it via service role)
        is_curated = bool(src.get("is_curated"))
        is_public = bool(src.get("is_public"))
        is_owner = src.get("user_id") == target_user_id
        if not (is_curated or is_public or is_owner):
            # Same 404 as missing to avoid leaking existence
            raise HTTPException(status_code=404, detail="Recipe not found")

        # --- 2) Fork via shared helper ---
        # source_recipe_user_id may be NULL when forking a curated recipe,
        # which is why the FK column is nullable per migration 1925.
        new_id = await _copy_recipe_to_user(
            source=src,
            target_user_id=target_user_id,
            source_type=RecipeSourceType.IMPROVIZED.value,
            extras={
                "name": _improvized_name(src.get("name")),
                "source_recipe_id": source_recipe_id,
                "source_recipe_name": src.get("name"),
                "source_recipe_user_id": src.get("user_id"),  # NULL for curated
            },
        )

        # --- 3) Re-fetch the fully-hydrated fork (trigger has now computed macros) ---
        rec_res = (
            self.db.client.table("user_recipes")
            .select("*")
            .eq("id", new_id)
            .single()
            .execute()
        )
        if not rec_res.data:
            # Extremely unlikely — we just inserted it. Surface as 500 so the
            # user sees a clear error rather than an empty response.
            logger.error("[Improvize] refetch failed for new_id=%s", new_id)
            raise HTTPException(
                status_code=500,
                detail="Recipe forked but could not be loaded.",
            )
        row = rec_res.data

        ing_res = (
            self.db.client.table("recipe_ingredients")
            .select("*")
            .eq("recipe_id", new_id)
            .order("ingredient_order")
            .execute()
        )
        ingredients = [_ingredient_row_to_model(ing) for ing in (ing_res.data or [])]

        return Recipe(
            id=row["id"],
            user_id=row.get("user_id"),
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
            source_type=RecipeSourceType(row.get("source_type", "improvized")),
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
            is_curated=row.get("is_curated", False),
            slug=row.get("slug"),
            source_recipe_id=row.get("source_recipe_id"),
            source_recipe_name=row.get("source_recipe_name"),
            source_recipe_user_id=row.get("source_recipe_user_id"),
            is_favorited=False,  # new fork — never favorited yet
            ingredients=ingredients,
            ingredient_count=len(ingredients),
            created_at=_parse_ts(row["created_at"]),
            updated_at=_parse_ts(row["updated_at"]),
        )


def _parse_ts(ts: str) -> datetime:
    """Parse a Postgres timestamp string tolerantly (handles both Z and +00:00)."""
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def _ingredient_row_to_model(ing: dict) -> RecipeIngredient:
    """Raw recipe_ingredients row → RecipeIngredient Pydantic model."""
    return RecipeIngredient(
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
        is_negligible=ing.get("is_negligible", False),
        created_at=_parse_ts(ing["created_at"]),
        updated_at=_parse_ts(ing["updated_at"]),
    )


_instance: Optional[RecipeImprovizeService] = None


def get_recipe_improvize_service() -> RecipeImprovizeService:
    global _instance
    if _instance is None:
        _instance = RecipeImprovizeService()
    return _instance
