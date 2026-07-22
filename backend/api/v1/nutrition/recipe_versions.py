"""Recipe version history endpoints — list, view, diff, revert."""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.db.base import is_uuid
from core.exceptions import safe_internal_error
from models.recipe_version import (
    RecipeDiff,
    RecipeRevertRequest,
    RecipeRevertResponse,
    RecipeVersion,
    RecipeVersionsResponse,
)
from services.recipe_version_service import get_recipe_version_service

logger = logging.getLogger(__name__)
router = APIRouter()


def _assert_recipe_access(
    recipe_id: str, current_user: dict, *, require_owner: bool
) -> None:
    """Ownership chokepoint for every recipe_id-addressed endpoint below.

    A recipe_id in the URL is a client ASSERTION: without this, anyone could
    read a stranger's private edit history — or ROLL BACK their recipe, which
    rewrites user_recipes and deletes/reinserts their ingredients.

    Reads mirror the visibility rule in recipes.py::get_recipe (owner,
    is_public or is_curated) so history on a Discover/shared recipe keeps
    working; `require_owner` is for the revert write, which is owner-only.
    404 rather than 403 so a probe can't learn that a recipe id exists.
    """
    caller_id = str(current_user.get("id") or current_user.get("sub") or "")
    if not is_uuid(recipe_id):
        # A non-UUID filtered against user_recipes.id raises 22P02, not an
        # empty result — treat a malformed id as "not found", not a 500.
        raise HTTPException(status_code=404, detail="recipe not found")
    res = (
        get_supabase_db().client.table("user_recipes")
        .select("user_id,is_public,is_curated")
        .eq("id", recipe_id)
        .is_("deleted_at", "null")
        .limit(1)
        .execute()
    )
    row = (res.data or [None])[0]
    if not row:
        raise HTTPException(status_code=404, detail="recipe not found")
    owner_id = row.get("user_id")
    # Curated rows can carry user_id=NULL — never let NULL match a caller.
    if owner_id and caller_id and str(owner_id) == caller_id:
        return
    if require_owner or not (row.get("is_public") or row.get("is_curated")):
        raise HTTPException(status_code=404, detail="recipe not found")


@router.get("/recipes/{recipe_id}/versions", response_model=RecipeVersionsResponse)
async def list_versions(
    recipe_id: str,
    limit: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
):
    _assert_recipe_access(recipe_id, current_user, require_owner=False)
    return await get_recipe_version_service().list_versions(recipe_id, limit=limit)


@router.get("/recipes/{recipe_id}/versions/{version_id}", response_model=RecipeVersion)
async def get_version(
    recipe_id: str, version_id: str, current_user: dict = Depends(get_current_user)
):
    _assert_recipe_access(recipe_id, current_user, require_owner=False)
    v = await get_recipe_version_service().get_version(recipe_id, version_id)
    if not v:
        raise HTTPException(status_code=404, detail="version not found")
    return v


@router.get("/recipes/{recipe_id}/versions-diff", response_model=RecipeDiff)
async def diff_versions(
    recipe_id: str,
    from_version: int = Query(..., ge=1),
    to_version: int = Query(..., ge=1),
    current_user: dict = Depends(get_current_user),
):
    # Outside the try: safe_internal_error catches Exception, which would
    # otherwise turn this 404 into a 500.
    _assert_recipe_access(recipe_id, current_user, require_owner=False)
    try:
        return await get_recipe_version_service().diff(recipe_id, from_version, to_version)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.post("/recipes/{recipe_id}/revert", response_model=RecipeRevertResponse)
async def revert_recipe(
    recipe_id: str,
    request: RecipeRevertRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    # `user_id` is stamped into history as `edited_by`, so it must be the
    # caller — and the revert itself rewrites the recipe, so owner-only.
    verify_user_ownership(current_user, user_id)
    _assert_recipe_access(recipe_id, current_user, require_owner=True)
    try:
        return await get_recipe_version_service().revert(
            recipe_id, request.target_version, edited_by=user_id
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")
