"""Recipe import endpoints — URL, text, handwritten image; pantry suggestions; per-row analyzer."""
import json
import logging
from typing import Optional

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from models.recipe import (
    BulkIngredientAnalyzeRequest,
    BulkIngredientAnalyzeResponse,
    ImportHandwrittenRecipeRequest,
    ImportRecipeRequest,
    ImportTextRecipeRequest,
    IngredientAnalyzeRequest,
    IngredientAnalyzeResponse,
    PantryAnalyzeRequest,
    PantryAnalyzeResponse,
)
from services.ingredient_analyzer_service import get_ingredient_analyzer
from services.pantry_analysis_service import get_pantry_service
from services.recipe_import_service import get_recipe_import_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/recipes/analyze-ingredient", response_model=IngredientAnalyzeResponse)
async def analyze_ingredient(
    request: IngredientAnalyzeRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    if not request.user_id:
        request.user_id = user_id
    try:
        return await get_ingredient_analyzer().analyze_one(request)
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.post("/recipes/analyze-ingredients", response_model=BulkIngredientAnalyzeResponse)
async def analyze_ingredients_bulk(
    request: BulkIngredientAnalyzeRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    if not request.user_id:
        request.user_id = user_id
    try:
        return await get_ingredient_analyzer().analyze_many(request)
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


def _sse(event: dict) -> bytes:
    return f"data: {json.dumps(event)}\n\n".encode("utf-8")


@router.post("/recipes/import-url")
async def import_recipe_url(
    request: ImportRecipeRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """SSE-stream the import progress (fetching → extracting → parsing → analyzing → done)."""
    importer = get_recipe_import_service()

    async def stream():
        async for evt in importer.import_url(request.url, user_id=user_id):
            yield _sse(evt)

    return StreamingResponse(stream(), media_type="text/event-stream")


@router.post("/recipes/import-text")
async def import_recipe_text(
    request: ImportTextRecipeRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    importer = get_recipe_import_service()

    async def stream():
        async for evt in importer.import_text(request.text, user_id=user_id):
            yield _sse(evt)

    return StreamingResponse(stream(), media_type="text/event-stream")


@router.post("/recipes/import-handwritten")
async def import_recipe_handwritten(
    request: ImportHandwrittenRecipeRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    importer = get_recipe_import_service()

    async def stream():
        async for evt in importer.import_handwritten(request.image_b64, user_id=user_id):
            yield _sse(evt)

    return StreamingResponse(stream(), media_type="text/event-stream")


@router.post("/recipes/from-pantry", response_model=PantryAnalyzeResponse)
async def from_pantry(
    request: PantryAnalyzeRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        return await get_pantry_service().analyze(user_id, request)
    except RuntimeError as exc:
        # Convert known RuntimeErrors into 400-level so the UI shows the message
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")
