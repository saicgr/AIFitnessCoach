"""Public (no-auth) recipe share resolver + auth'd clone endpoint.

GET /r/{slug}        — returns sanitized PublicRecipeView; bumps view_count
POST /r/{slug}/save  — auth'd; clones the public recipe to the caller's library
"""
import logging

from fastapi import APIRouter, Depends, HTTPException

from core.auth import get_current_user
from models.recipe_share import CloneRecipeResponse, PublicRecipeView
from services.recipe_share_service import get_recipe_share_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/r/{slug}", response_model=PublicRecipeView)
async def resolve_share(slug: str):
    view = await get_recipe_share_service().resolve(slug)
    if not view:
        raise HTTPException(
            status_code=410,
            detail="This recipe is no longer shared. The original may have been deleted or unshared.",
        )
    return view


@router.post("/r/{slug}/save", response_model=CloneRecipeResponse)
async def save_share(slug: str, current_user: dict = Depends(get_current_user)):
    user_id = current_user.get("user_id") or current_user.get("id") or current_user.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Sign in to save")
    try:
        return await get_recipe_share_service().clone(slug, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
