"""Glucose ↔ food correlation insight endpoint (Gap 15).

GET /api/v1/nutrition/glucose-food-insights — the foods with this user's highest
measured post-meal glucose response. Empty for non-diabetes users (no readings).
"""
import asyncio
from typing import List, Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


class GlucoseFoodItem(BaseModel):
    food: str
    avg_peak_mg_dl: int
    avg_delta_mg_dl: Optional[int] = None
    n: int


class GlucoseFoodInsights(BaseModel):
    has_data: bool
    items: List[GlucoseFoodItem] = Field(default_factory=list)


@router.get("/glucose-food-insights", response_model=GlucoseFoodInsights)
async def get_glucose_food_insights(
    request: Request,
    days: int = Query(default=30, ge=7, le=90),
    current_user: dict = Depends(get_current_user),
):
    """Foods ranked by this user's measured post-meal glucose response."""
    user_id = str(current_user["id"])
    try:
        from services.glucose_food_correlation import compute_glucose_food_correlations

        corr = await asyncio.to_thread(
            compute_glucose_food_correlations, user_id, None, days
        )
        return GlucoseFoodInsights(
            has_data=bool(corr),
            items=[GlucoseFoodItem(**c) for c in corr],
        )
    except Exception as e:
        logger.error(f"[glucose_insights] failed for {user_id[:8]}: {e}", exc_info=True)
        raise safe_internal_error(e, "glucose_insights")
