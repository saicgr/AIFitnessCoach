"""Hybrid lexical+semantic recipe search."""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, Query

from core.auth import get_current_user
from models.recipe import RecipesResponse
from services.recipe_search_service import get_recipe_search_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/recipes-search", response_model=RecipesResponse)
async def search_recipes(
    user_id: str = Query(...),
    q: str = Query(..., min_length=2, max_length=200),
    scope: str = Query("mine", pattern="^(mine|community)$"),
    category: Optional[str] = Query(None),
    cuisine: Optional[str] = Query(None),
    has_leftovers: bool = Query(False),
    limit: int = Query(30, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """Search recipes by name, ingredient, tag, cuisine, or semantic similarity."""
    return await get_recipe_search_service().search(
        user_id=user_id, query=q, scope=scope,
        category=category, cuisine=cuisine,
        has_leftovers=has_leftovers, limit=limit,
    )
