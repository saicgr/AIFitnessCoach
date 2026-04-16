"""Improvize endpoint — fork any visible recipe into the caller's library.

POST /recipes/{recipe_id}/improvize  → returns the new Recipe (201).

Works on curated sources (is_curated=TRUE, user_id IS NULL), public
community sources (is_public=TRUE), and the caller's own recipes. The
service raises 404 if the source isn't visible.
"""
import logging

from fastapi import APIRouter, Depends, HTTPException

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from models.recipe import Recipe
from services.recipe_improvize_service import get_recipe_improvize_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/recipes/{recipe_id}/improvize", response_model=Recipe, status_code=201)
async def improvize_recipe(
    recipe_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Create a private, editable fork of `recipe_id` for the current user.

    The fork:
      - Starts with name "Improvized: <source name>" (idempotent prefix).
      - Is NOT public and NOT curated.
      - Has source_recipe_id/source_recipe_name/source_recipe_user_id set
        so the UI can show "Based on: <original>".
      - Has per-serving macros recomputed by the DB trigger from the copied
        ingredients (not trusted from the source copy).
    """
    try:
        svc = get_recipe_improvize_service()
        return await svc.fork(source_recipe_id=recipe_id, target_user_id=current_user["id"])
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("[Improvize] failed: %s", exc, exc_info=True)
        raise safe_internal_error(exc, "nutrition")
