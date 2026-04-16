"""Recipe favorites endpoints.

Endpoints:
  POST   /recipes/{recipe_id}/favorite  → add a favorite (idempotent).
  DELETE /recipes/{recipe_id}/favorite  → remove a favorite (idempotent).
  GET    /recipes/favorites             → list the caller's favorites.

All three are auth'd via Depends(get_current_user). The list endpoint takes
an explicit `user_id` query param matching the rest of the nutrition API's
convention, and validates it matches the authenticated user to avoid
cross-user enumeration (RLS would also catch this, but an early 403 is
clearer to clients).

NOTE: This router MUST be registered in api/v1/nutrition/__init__.py BEFORE
`recipes.router` because `recipes.router` contains the catch-all
`GET /recipes/{recipe_id}` which would otherwise match `/recipes/favorites`.
"""
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from models.recipe import RecipesResponse, RecipeSummary
from services.recipe_favorites_service import get_recipe_favorites_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/recipes/{recipe_id}/favorite")
async def add_favorite(
    recipe_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Mark a recipe as favorited by the caller.

    Returns `{favorited: true, already_favorited: bool}`. The second flag
    tells the UI whether this was a new favorite (play a heart animation)
    or an idempotent no-op (skip the animation).
    """
    try:
        user_id = current_user["id"]
        svc = get_recipe_favorites_service()
        inserted = await svc.add(user_id, recipe_id)
        return {"favorited": True, "already_favorited": not inserted}
    except Exception as exc:
        logger.error("[Favorites] POST failed: %s", exc, exc_info=True)
        raise safe_internal_error(exc, "nutrition")


@router.delete("/recipes/{recipe_id}/favorite", status_code=204)
async def remove_favorite(
    recipe_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Remove a favorite. Always returns 204, even if not currently favorited.

    Idempotent-by-design so the UI can rapid-toggle without caring about
    prior state.
    """
    try:
        user_id = current_user["id"]
        svc = get_recipe_favorites_service()
        await svc.remove(user_id, recipe_id)
        # Return Response with no body to guarantee a true 204 (FastAPI will
        # otherwise serialize `None` as the JSON string "null").
        return Response(status_code=204)
    except Exception as exc:
        logger.error("[Favorites] DELETE failed: %s", exc, exc_info=True)
        raise safe_internal_error(exc, "nutrition")


@router.get("/recipes/favorites", response_model=RecipesResponse)
async def list_favorites(
    user_id: str = Query(..., description="Must match authenticated user"),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    """Return the caller's favorited recipes, newest-favorite first.

    Shape matches `GET /recipes`: `{items: RecipeSummary[], total_count}`.
    `total_count` reflects the total number of favorites (not just this page).
    """
    try:
        # Defense-in-depth: prevent cross-user enumeration via the query param.
        if user_id != current_user["id"]:
            raise HTTPException(status_code=403, detail="user_id mismatch")

        svc = get_recipe_favorites_service()
        rows = await svc.list_for_user(user_id, limit=limit, offset=offset)

        items = []
        for row in rows:
            items.append(RecipeSummary(
                id=row["id"],
                name=row["name"],
                category=row.get("category"),
                calories_per_serving=row.get("calories_per_serving"),
                protein_per_serving_g=row.get("protein_per_serving_g"),
                servings=row.get("servings", 1),
                # Favorites view doesn't need exact counts for sort — we skip
                # the N+1 ingredient count query here. Clients that need it
                # can hit the single recipe endpoint.
                ingredient_count=0,
                times_logged=row.get("times_logged", 0),
                image_url=row.get("image_url"),
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
                is_curated=row.get("is_curated", False),
                slug=row.get("slug"),
                source_recipe_id=row.get("source_recipe_id"),
                source_recipe_name=row.get("source_recipe_name"),
                source_type=row.get("source_type"),
                is_favorited=True,  # by definition for this endpoint
            ))

        # total_count == all favorites; fetch the count separately for correct
        # pagination UIs. We ignore soft-deleted recipes here to match the
        # items list.
        total_ids = await svc.recipe_ids_for_user(user_id)
        return RecipesResponse(items=items, total_count=len(total_ids))
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("[Favorites] list failed: %s", exc, exc_info=True)
        raise safe_internal_error(exc, "nutrition")
