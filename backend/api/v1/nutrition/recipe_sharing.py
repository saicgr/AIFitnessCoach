"""Recipe public sharing endpoints (auth-required side; public resolver in api/public/recipes.py)."""
import logging

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from models.recipe_share import CreateShareLinkResponse
from services.recipe_share_service import get_recipe_share_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/recipes/{recipe_id}/share", response_model=CreateShareLinkResponse)
async def enable_share(
    recipe_id: str,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        link = await get_recipe_share_service().enable_share(user_id, recipe_id)
        return CreateShareLinkResponse(link=link)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.delete("/recipes/{recipe_id}/share")
async def disable_share(
    recipe_id: str,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        await get_recipe_share_service().disable_share(user_id, recipe_id)
        return {"status": "unshared", "id": recipe_id}
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")
