"""Cook event endpoints — leftover tracking for cook-once-eat-many."""
import logging
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from models.cook_event import (
    ActiveCookEvent,
    ActiveCookEventsResponse,
    CookEvent,
    CookEventCreate,
    CookEventUpdate,
)
from services.cook_event_service import get_cook_event_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/cook-events", response_model=CookEvent)
async def create_cook_event(
    request: CookEventCreate,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        return await get_cook_event_service().create(user_id, request)
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.get("/cook-events/active", response_model=ActiveCookEventsResponse)
async def list_active_cook_events(
    user_id: str = Query(...), current_user: dict = Depends(get_current_user)
):
    items = await get_cook_event_service().list_active(user_id)
    return ActiveCookEventsResponse(items=items)


@router.patch("/cook-events/{event_id}", response_model=CookEvent)
async def update_cook_event(
    event_id: str,
    request: CookEventUpdate,
    current_user: dict = Depends(get_current_user),
):
    ev = await get_cook_event_service().update(event_id, request)
    if not ev:
        raise HTTPException(status_code=404, detail="cook event not found")
    return ev


@router.delete("/cook-events/{event_id}")
async def delete_cook_event(event_id: str, current_user: dict = Depends(get_current_user)):
    await get_cook_event_service().delete(event_id)
    return {"status": "deleted", "id": event_id}
