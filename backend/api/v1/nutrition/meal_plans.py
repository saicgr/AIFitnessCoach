"""Meal plan endpoints — CRUD, simulate (what-if), apply-to-today."""
import logging
from datetime import date
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.db.base import is_uuid
from core.exceptions import safe_internal_error
from models.meal_plan import (
    ApplyResponse,
    MealPlan,
    MealPlanCreate,
    MealPlanItem,
    MealPlanItemCreate,
    MealPlanUpdate,
    MealPlansResponse,
    SimulateResponse,
)
from services.meal_plan_service import get_meal_plan_service

logger = logging.getLogger(__name__)
router = APIRouter()


def _caller_id(current_user: dict) -> str:
    return str(current_user.get("id") or current_user.get("sub") or "")


def _assert_plan_owned(plan_id: str, current_user: dict) -> None:
    """Ownership chokepoint for every plan_id-addressed endpoint below.

    A plan_id in the URL is a client ASSERTION, never a fact. Without this the
    whole file was an IDOR: any authenticated caller could read, edit, empty or
    /apply someone else's plan — and /apply writes food_logs into the plan
    OWNER's diary, so a stranger could stuff a victim's food diary. The
    ownership predicate rides in the query so Postgres enforces it and no code
    path can forget to compare. 404 rather than 403 so a probe can't use the
    status code to learn that a plan id exists.
    """
    if not is_uuid(plan_id):
        # A non-UUID filtered against meal_plans.id raises 22P02, not an empty
        # result — treat a malformed id as "not found" instead of a 500.
        raise HTTPException(status_code=404, detail="meal plan not found")
    res = (
        get_supabase_db().client.table("meal_plans")
        .select("id")
        .eq("id", plan_id)
        .eq("user_id", _caller_id(current_user))
        .limit(1)
        .execute()
    )
    if not res.data:
        raise HTTPException(status_code=404, detail="meal plan not found")


def _assert_item_in_plan(plan_id: str, item_id: str) -> None:
    """Scope an item id to the (already ownership-checked) plan.

    The service removes an item by item_id alone, so verifying only the plan
    would still let a caller who owns plan A delete an item out of a stranger's
    plan B by passing its item id.
    """
    if not is_uuid(item_id):
        raise HTTPException(status_code=404, detail="plan item not found")
    res = (
        get_supabase_db().client.table("meal_plan_items")
        .select("id")
        .eq("id", item_id)
        .eq("plan_id", plan_id)
        .limit(1)
        .execute()
    )
    if not res.data:
        raise HTTPException(status_code=404, detail="plan item not found")


@router.post("/meal-plans", response_model=MealPlan)
async def create_meal_plan(
    request: MealPlanCreate,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    # Outside the try: safe_internal_error catches Exception, which would
    # otherwise turn the 403 from this check into a 500.
    verify_user_ownership(current_user, user_id)
    try:
        return await get_meal_plan_service().create(user_id, request)
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.get("/meal-plans", response_model=MealPlansResponse)
async def list_meal_plans(
    user_id: str = Query(...),
    plan_date: Optional[date] = Query(None),
    templates_only: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
    verify_user_ownership(current_user, user_id)
    try:
        items = await get_meal_plan_service().list_for_user(
            user_id, plan_date=plan_date, templates_only=templates_only
        )
        return MealPlansResponse(items=items, total_count=len(items))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.get("/meal-plans/{plan_id}", response_model=MealPlan)
async def get_meal_plan(plan_id: str, current_user: dict = Depends(get_current_user)):
    _assert_plan_owned(plan_id, current_user)
    plan = await get_meal_plan_service().get(plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="meal plan not found")
    return plan


@router.patch("/meal-plans/{plan_id}", response_model=MealPlan)
async def update_meal_plan(
    plan_id: str, request: MealPlanUpdate, current_user: dict = Depends(get_current_user)
):
    _assert_plan_owned(plan_id, current_user)
    plan = await get_meal_plan_service().update(plan_id, request)
    if not plan:
        raise HTTPException(status_code=404, detail="meal plan not found")
    return plan


@router.delete("/meal-plans/{plan_id}")
async def delete_meal_plan(plan_id: str, current_user: dict = Depends(get_current_user)):
    _assert_plan_owned(plan_id, current_user)
    await get_meal_plan_service().delete(plan_id)
    return {"status": "deleted", "id": plan_id}


@router.post("/meal-plans/{plan_id}/items", response_model=MealPlanItem)
async def add_plan_item(
    plan_id: str, item: MealPlanItemCreate, current_user: dict = Depends(get_current_user)
):
    _assert_plan_owned(plan_id, current_user)
    return await get_meal_plan_service().add_item(plan_id, item)


@router.delete("/meal-plans/{plan_id}/items/{item_id}")
async def remove_plan_item(
    plan_id: str, item_id: str, current_user: dict = Depends(get_current_user)
):
    _assert_plan_owned(plan_id, current_user)
    _assert_item_in_plan(plan_id, item_id)
    await get_meal_plan_service().remove_item(item_id)
    return {"status": "removed", "id": item_id}


@router.post("/meal-plans/{plan_id}/simulate", response_model=SimulateResponse)
async def simulate_plan(
    plan_id: str,
    background_tasks: BackgroundTasks,
    with_swaps: bool = Query(True),
    current_user: dict = Depends(get_current_user),
):
    _assert_plan_owned(plan_id, current_user)
    try:
        svc = get_meal_plan_service()
        # Return rule-based projection immediately. Gemini swap generation
        # runs out-of-band and writes to meal_plan_swap_suggestions; the
        # client either re-calls simulate (which hydrates persisted swaps)
        # or subscribes via Realtime. See plan A5.
        response = await svc.simulate(plan_id, with_swaps=with_swaps)
        if with_swaps and not response.swap_suggestions:
            background_tasks.add_task(svc.compute_and_persist_swaps, plan_id)
        return response
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.post("/meal-plans/{plan_id}/apply", response_model=ApplyResponse)
async def apply_plan(
    plan_id: str,
    target_date: date = Query(...),
    current_user: dict = Depends(get_current_user),
):
    _assert_plan_owned(plan_id, current_user)
    try:
        return await get_meal_plan_service().apply(plan_id, target_date)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")
