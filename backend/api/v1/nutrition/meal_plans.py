"""Meal plan endpoints — CRUD, simulate (what-if), apply-to-today."""
import logging
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
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


@router.post("/meal-plans", response_model=MealPlan)
async def create_meal_plan(
    request: MealPlanCreate,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
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
    try:
        items = await get_meal_plan_service().list_for_user(
            user_id, plan_date=plan_date, templates_only=templates_only
        )
        return MealPlansResponse(items=items, total_count=len(items))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.get("/meal-plans/{plan_id}", response_model=MealPlan)
async def get_meal_plan(plan_id: str, current_user: dict = Depends(get_current_user)):
    plan = await get_meal_plan_service().get(plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="meal plan not found")
    return plan


@router.patch("/meal-plans/{plan_id}", response_model=MealPlan)
async def update_meal_plan(
    plan_id: str, request: MealPlanUpdate, current_user: dict = Depends(get_current_user)
):
    plan = await get_meal_plan_service().update(plan_id, request)
    if not plan:
        raise HTTPException(status_code=404, detail="meal plan not found")
    return plan


@router.delete("/meal-plans/{plan_id}")
async def delete_meal_plan(plan_id: str, current_user: dict = Depends(get_current_user)):
    await get_meal_plan_service().delete(plan_id)
    return {"status": "deleted", "id": plan_id}


@router.post("/meal-plans/{plan_id}/items", response_model=MealPlanItem)
async def add_plan_item(
    plan_id: str, item: MealPlanItemCreate, current_user: dict = Depends(get_current_user)
):
    return await get_meal_plan_service().add_item(plan_id, item)


@router.delete("/meal-plans/{plan_id}/items/{item_id}")
async def remove_plan_item(
    plan_id: str, item_id: str, current_user: dict = Depends(get_current_user)
):
    await get_meal_plan_service().remove_item(item_id)
    return {"status": "removed", "id": item_id}


@router.post("/meal-plans/{plan_id}/simulate", response_model=SimulateResponse)
async def simulate_plan(
    plan_id: str,
    with_swaps: bool = Query(True),
    current_user: dict = Depends(get_current_user),
):
    try:
        return await get_meal_plan_service().simulate(plan_id, with_swaps=with_swaps)
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
    try:
        return await get_meal_plan_service().apply(plan_id, target_date)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")
