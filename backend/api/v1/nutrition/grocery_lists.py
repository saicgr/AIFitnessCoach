"""Grocery list endpoints — build from plan or recipe, manage items, export."""
import logging
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import PlainTextResponse

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from models.grocery_list import (
    GroceryList,
    GroceryListCreate,
    GroceryListItem,
    GroceryListItemBase,
    GroceryListItemUpdate,
    GroceryListsResponse,
)
from services.grocery_list_service import get_grocery_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/grocery-lists", response_model=GroceryList)
async def build_grocery_list(
    request: GroceryListCreate,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        return await get_grocery_service().build(user_id, request)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.get("/grocery-lists", response_model=GroceryListsResponse)
async def list_grocery_lists(
    user_id: str = Query(...),
    limit: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
):
    items = await get_grocery_service().list_for_user(user_id, limit=limit)
    return GroceryListsResponse(items=items, total_count=len(items))


@router.get("/grocery-lists/{list_id}", response_model=GroceryList)
async def get_grocery_list(list_id: str, current_user: dict = Depends(get_current_user)):
    gl = await get_grocery_service().get(list_id)
    if not gl:
        raise HTTPException(status_code=404, detail="grocery list not found")
    return gl


@router.post("/grocery-lists/{list_id}/items", response_model=GroceryListItem)
async def add_grocery_item(
    list_id: str, item: GroceryListItemBase, current_user: dict = Depends(get_current_user)
):
    return await get_grocery_service().add_item(list_id, item)


@router.patch("/grocery-lists/{list_id}/items/{item_id}", response_model=GroceryListItem)
async def update_grocery_item(
    list_id: str, item_id: str, request: GroceryListItemUpdate,
    current_user: dict = Depends(get_current_user),
):
    item = await get_grocery_service().update_item(item_id, request)
    if not item:
        raise HTTPException(status_code=404, detail="item not found")
    return item


@router.delete("/grocery-lists/{list_id}/items/{item_id}")
async def delete_grocery_item(
    list_id: str, item_id: str, current_user: dict = Depends(get_current_user)
):
    await get_grocery_service().delete_item(item_id)
    return {"status": "deleted", "id": item_id}


@router.get("/grocery-lists/{list_id}/export", response_class=PlainTextResponse)
async def export_grocery_list(
    list_id: str,
    format: str = Query("text", pattern="^(text|csv)$"),
    current_user: dict = Depends(get_current_user),
):
    svc = get_grocery_service()
    if format == "csv":
        return await svc.export_csv(list_id)
    return await svc.export_text(list_id)
