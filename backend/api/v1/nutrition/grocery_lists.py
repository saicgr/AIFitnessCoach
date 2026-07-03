"""Grocery list endpoints — build from plan or recipe, manage items, export."""
import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
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


class QuickAddRequest(BaseModel):
    item_name: str = Field(..., min_length=1, max_length=255)
    quantity: Optional[str] = Field(default=None, max_length=100)


# Registered BEFORE the /grocery-lists/{list_id}* routes so the static
# "active" segment is never captured as a list_id.
@router.post("/grocery-lists/active/quick-add", response_model=GroceryListItem)
async def quick_add_active_item(
    request: QuickAddRequest,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Append one named item to the user's active (most-recent) grocery list,
    creating "My Shopping List" if they have none. Powers the fridge flow's
    missing-ingredient chip."""
    try:
        return await get_grocery_service().quick_add_active(
            user_id, request.item_name, request.quantity
        )
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


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


# ─────────────────────────────────────────────────────────────────
# Add from food log (Phase D — meal long-press → "Add to shopping list")
# Aggregates by `ingredient_name_normalized` (generated column from
# migration 2056) so "Idli" + "idli" + "Idlis" collapse to one row.
# ─────────────────────────────────────────────────────────────────


class AddFromFoodLogResponse(BaseModel):
    list_id: str
    list_name: str
    items_added: int
    items_merged: int


@router.post("/grocery-lists/active/add-from-food-log/{log_id}",
             response_model=AddFromFoodLogResponse)
async def add_from_food_log(
    log_id: str,
    item_index: Optional[int] = Query(
        default=None, ge=0,
        description="If set, only add food_items[item_index] from the log. Mirrors the per-item long-press flow.",
    ),
    current_user: dict = Depends(get_current_user),
):
    """Append the food_log's items to the user's most-recent active grocery
    list (creates "My Shopping List" if none exists). Quantities sum when
    units match; incompatible units stay as separate rows with a note."""
    user_id = current_user.get("id") or current_user.get("sub")
    db = get_supabase_db()
    food_log = db.get_food_log(log_id)
    if not food_log or food_log.get("user_id") != user_id:
        raise HTTPException(status_code=404, detail="Food log not found")
    try:
        result = await get_grocery_service().add_from_food_log(
            user_id=user_id,
            food_log=food_log,
            item_index=item_index,
        )
        return AddFromFoodLogResponse(**result)
    except HTTPException:
        raise
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")
