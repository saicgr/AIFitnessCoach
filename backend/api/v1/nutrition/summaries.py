"""Daily/weekly nutrition summaries and targets endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from models.schemas import UpdateNutritionTargetsRequest

from api.v1.nutrition.models import (
    FoodLogResponse,
    DailyNutritionResponse,
    WeeklyNutritionResponse,
    NutritionTargetsResponse,
)

router = APIRouter()
logger = get_logger(__name__)

@router.get("/summary/daily/{user_id}", response_model=DailyNutritionResponse)
async def get_daily_summary(
    user_id: str,
    request: Request,
    date: Optional[str] = Query(default=None, description="Date (YYYY-MM-DD), defaults to today"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get daily nutrition summary for a user.

    Returns total calories, macros, and list of meals for the day.
    """
    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        if date is None:
            date = get_user_today(user_tz)

        logger.info(f"Getting daily nutrition summary for user {user_id}, date={date}, tz={user_tz}")

        # Get summary (timezone-aware)
        summary = db.get_daily_nutrition_summary(user_id, date, timezone_str=user_tz)

        # Get meals for the day using timezone-aware UTC range
        start_of_day, end_of_day = local_date_to_utc_range(date, user_tz)
        meals = db.list_food_logs(
            user_id=user_id,
            from_date=start_of_day,
            to_date=end_of_day,
            limit=20
        )

        meal_responses = []
        for log in meals:
            meal_responses.append(FoodLogResponse(
                id=log.get("id"),
                user_id=log.get("user_id"),
                meal_type=log.get("meal_type"),
                logged_at=str(log.get("logged_at", "")),
                food_items=log.get("food_items", []),
                total_calories=log.get("total_calories", 0),
                protein_g=log.get("protein_g", 0),
                carbs_g=log.get("carbs_g", 0),
                fat_g=log.get("fat_g", 0),
                fiber_g=log.get("fiber_g"),
                health_score=log.get("health_score"),
                ai_feedback=log.get("ai_feedback"),
                created_at=str(log.get("created_at") or log.get("logged_at") or ""),
            ))

        return DailyNutritionResponse(
            date=date,
            total_calories=summary.get("total_calories", 0) or 0,
            total_protein_g=summary.get("total_protein_g", 0) or 0,
            total_carbs_g=summary.get("total_carbs_g", 0) or 0,
            total_fat_g=summary.get("total_fat_g", 0) or 0,
            total_fiber_g=summary.get("total_fiber_g", 0) or 0,
            meal_count=summary.get("meal_count", 0) or 0,
            avg_health_score=summary.get("avg_health_score"),
            meals=meal_responses,
        )

    except Exception as e:
        logger.error(f"Failed to get daily summary: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/summary/weekly/{user_id}", response_model=WeeklyNutritionResponse)
async def get_weekly_summary(
    user_id: str,
    request: Request,
    current_user: dict = Depends(get_current_user),
    start_date: Optional[str] = Query(default=None, description="Start date (YYYY-MM-DD), defaults to 7 days ago"),
):
    """
    Get weekly nutrition summary for a user.

    Returns daily summaries for 7 days starting from start_date.
    """
    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        if start_date is None:
            from datetime import timedelta
            from zoneinfo import ZoneInfo
            user_now = datetime.now(ZoneInfo(user_tz) if user_tz != "UTC" else ZoneInfo("UTC"))
            start_date = (user_now - timedelta(days=6)).strftime("%Y-%m-%d")

        logger.info(f"Getting weekly nutrition summary for user {user_id}, start_date={start_date}, tz={user_tz}")

        # Get weekly summary (timezone-aware)
        daily_summaries = db.get_weekly_nutrition_summary(user_id, start_date, timezone_str=user_tz)

        # Calculate totals
        total_calories = 0
        total_meals = 0

        for day in daily_summaries:
            total_calories += day.get("total_calories", 0) or 0
            total_meals += day.get("meal_count", 0) or 0

        days_with_data = len([d for d in daily_summaries if d.get("total_calories")])
        avg_daily_calories = total_calories / days_with_data if days_with_data > 0 else 0

        # Calculate end date
        from datetime import timedelta
        start = datetime.strptime(start_date, "%Y-%m-%d")
        end_date = (start + timedelta(days=6)).strftime("%Y-%m-%d")

        return WeeklyNutritionResponse(
            start_date=start_date,
            end_date=end_date,
            daily_summaries=daily_summaries,
            total_calories=total_calories,
            average_daily_calories=avg_daily_calories,
            total_meals=total_meals,
        )

    except Exception as e:
        logger.error(f"Failed to get weekly summary: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/targets/{user_id}", response_model=NutritionTargetsResponse)
async def get_nutrition_targets(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get user's nutrition targets."""
    logger.info(f"Getting nutrition targets for user {user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        targets = db.get_user_nutrition_targets(user_id)

        return NutritionTargetsResponse(
            user_id=user_id,
            daily_calorie_target=targets.get("daily_calorie_target"),
            daily_protein_target_g=targets.get("daily_protein_target_g"),
            daily_carbs_target_g=targets.get("daily_carbs_target_g"),
            daily_fat_target_g=targets.get("daily_fat_target_g"),
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition targets: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.put("/targets/{user_id}", response_model=NutritionTargetsResponse)
async def update_nutrition_targets(user_id: str, request: UpdateNutritionTargetsRequest, current_user: dict = Depends(get_current_user)):
    """Update user's nutrition targets."""
    logger.info(f"Updating nutrition targets for user {user_id}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Update targets
        updated = db.update_user_nutrition_targets(
            user_id=user_id,
            daily_calorie_target=request.daily_calorie_target,
            daily_protein_target_g=request.daily_protein_target_g,
            daily_carbs_target_g=request.daily_carbs_target_g,
            daily_fat_target_g=request.daily_fat_target_g,
        )

        return NutritionTargetsResponse(
            user_id=user_id,
            daily_calorie_target=updated.get("daily_calorie_target"),
            daily_protein_target_g=updated.get("daily_protein_target_g"),
            daily_carbs_target_g=updated.get("daily_carbs_target_g"),
            daily_fat_target_g=updated.get("daily_fat_target_g"),
        )

    except Exception as e:
        logger.error(f"Failed to update nutrition targets: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")

