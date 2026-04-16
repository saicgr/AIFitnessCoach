"""Discover tab — serves the curated recipe catalog.

Endpoint:
  GET /recipes/discover  — returns is_curated=TRUE recipes with filters/sort.

Curated rows are seeded with user_id=NULL and is_curated=TRUE (migration
1925). SELECT RLS allows all authenticated users to read them. Discover
is intentionally the ONLY endpoint that lists curated rows — `GET /recipes`
filters them out so the user's "My Recipes" tab stays personal.

Registered BEFORE `recipes.router` so the literal `/recipes/discover` path
wins over the catch-all `GET /recipes/{recipe_id}`.
"""
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from models.recipe import RecipesResponse, RecipeSummary
from services.recipe_favorites_service import get_recipe_favorites_service

logger = logging.getLogger(__name__)
router = APIRouter()


# Allowed sort modes for the Discover list. Kept as a literal regex union in
# the route signature for fast validation, but centralized here for docs.
_ALLOWED_SORTS = ("most_logged", "created_desc", "name_asc")


@router.get("/recipes/discover", response_model=RecipesResponse)
async def discover_recipes(
    current_user: dict = Depends(get_current_user),
    category: Optional[str] = Query(default=None, description="RecipeCategory enum value"),
    sort: str = Query(
        default="most_logged",
        regex=r"^(most_logged|created_desc|name_asc)$",
        description="Sort order. Default surfaces popular dishes first.",
    ),
    limit: int = Query(default=30, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    """List curated recipes for the Discover tab.

    Filters:
      - Always: is_curated = TRUE, deleted_at IS NULL.
      - Optional: category (eq on enum value).

    Sorts:
      - most_logged (default): times_logged DESC, then created_at DESC tiebreak.
      - created_desc: newest seeded first.
      - name_asc: alphabetical (for "Browse all" browsing).
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # --- Base query ---
        query = (
            db.client.table("user_recipes")
            .select(
                "id, name, category, calories_per_serving, protein_per_serving_g, "
                "servings, times_logged, image_url, created_at, is_curated, slug, "
                "source_recipe_id, source_recipe_name, source_type"
            )
            .eq("is_curated", True)
            .is_("deleted_at", "null")
        )
        if category:
            query = query.eq("category", category)

        # --- Sort ---
        if sort == "most_logged":
            # times_logged is a popularity proxy across all users; curated
            # recipes accumulate this via recipe-logging triggers.
            query = query.order("times_logged", desc=True).order("created_at", desc=True)
        elif sort == "name_asc":
            query = query.order("name")
        else:  # created_desc
            query = query.order("created_at", desc=True)

        query = query.range(offset, offset + limit - 1)
        result = query.execute()
        rows = result.data or []

        # --- Total count (same filters, no pagination) ---
        count_q = (
            db.client.table("user_recipes")
            .select("id", count="exact")
            .eq("is_curated", True)
            .is_("deleted_at", "null")
        )
        if category:
            count_q = count_q.eq("category", category)
        count_res = count_q.execute()
        total_count = count_res.count or 0

        # --- is_favorited for the current user (bulk to avoid N+1) ---
        ids = [r["id"] for r in rows]
        fav_svc = get_recipe_favorites_service()
        fav_map = await fav_svc.is_favorited_bulk(user_id, ids)

        items = []
        for row in rows:
            items.append(RecipeSummary(
                id=row["id"],
                name=row["name"],
                category=row.get("category"),
                calories_per_serving=row.get("calories_per_serving"),
                protein_per_serving_g=row.get("protein_per_serving_g"),
                servings=row.get("servings", 1),
                ingredient_count=0,  # deferred to detail view — Discover list is tile-only
                times_logged=row.get("times_logged", 0),
                image_url=row.get("image_url"),
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
                is_curated=True,
                slug=row.get("slug"),
                source_recipe_id=row.get("source_recipe_id"),
                source_recipe_name=row.get("source_recipe_name"),
                source_type=row.get("source_type"),
                is_favorited=fav_map.get(row["id"], False),
            ))

        return RecipesResponse(items=items, total_count=total_count)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("[Discover] failed: %s", exc, exc_info=True)
        raise safe_internal_error(exc, "nutrition")
