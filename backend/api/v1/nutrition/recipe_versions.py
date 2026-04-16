"""Recipe version history endpoints — list, view, diff, revert."""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
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


@router.get("/recipes/{recipe_id}/versions", response_model=RecipeVersionsResponse)
async def list_versions(
    recipe_id: str,
    limit: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
):
    return await get_recipe_version_service().list_versions(recipe_id, limit=limit)


@router.get("/recipes/{recipe_id}/versions/{version_id}", response_model=RecipeVersion)
async def get_version(
    recipe_id: str, version_id: str, current_user: dict = Depends(get_current_user)
):
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
    try:
        return await get_recipe_version_service().revert(
            recipe_id, request.target_version, edited_by=user_id
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")
