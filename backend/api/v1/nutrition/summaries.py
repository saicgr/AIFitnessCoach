"""Daily/weekly nutrition summaries and targets endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, get_user_today, to_utc_iso
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from api.v1.nutrition.helpers import resign_food_image_url
from models.schemas import UpdateNutritionTargetsRequest

from api.v1.nutrition.models import (
    FoodLogResponse,
    DailyNutritionResponse,
    WeeklyNutritionResponse,
    NutritionTargetsResponse,
)

from core.redis_cache import RedisCache

router = APIRouter()
logger = get_logger(__name__)

# 60s cache for daily summaries — prevents redundant DB hits on tab switches
_daily_summary_cache = RedisCache(prefix="nutrition_daily", ttl_seconds=60, max_size=100)


async def invalidate_daily_summary_cache(user_id: str, date: str = None):
    """Invalidate cached daily summary after a meal is logged/deleted.
    If date is None, clears all dates for the user (uses prefix delete)."""
    if date:
        await _daily_summary_cache.delete(f"{user_id}:{date}")
    else:
        # Best-effort: clear today's cache at minimum
        from core.timezone_utils import get_user_today
        today = get_user_today("UTC")
        await _daily_summary_cache.delete(f"{user_id}:{today}")

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

        # Check cache first (60s TTL)
        cache_key = f"{user_id}:{date}"
        cached = await _daily_summary_cache.get(cache_key)
        if cached:
            logger.debug(f"Cache hit for daily summary {cache_key}")
            return DailyNutritionResponse(**cached)

        logger.info(f"Getting daily nutrition summary for user {user_id}, date={date}, tz={user_tz}")

        # Get summary (timezone-aware) — includes meals, no need to query again
        summary = db.get_daily_nutrition_summary(user_id, date, timezone_str=user_tz)

        meal_responses = []
        for log in (summary.get("meals") or [])[:20]:
            meal_responses.append(FoodLogResponse(
                id=log.get("id"),
                user_id=log.get("user_id"),
                meal_type=log.get("meal_type"),
                logged_at=to_utc_iso(log.get("logged_at")),
                food_items=log.get("food_items", []),
                total_calories=log.get("total_calories", 0),
                protein_g=log.get("protein_g", 0),
                carbs_g=log.get("carbs_g", 0),
                fat_g=log.get("fat_g", 0),
                fiber_g=log.get("fiber_g"),
                health_score=log.get("health_score"),
                ai_feedback=log.get("ai_feedback"),
                notes=log.get("notes"),
                mood_before=log.get("mood_before"),
                mood_after=log.get("mood_after"),
                energy_level=log.get("energy_level"),
                inflammation_score=log.get("inflammation_score"),
                is_ultra_processed=log.get("is_ultra_processed"),
                # Row-level provenance — drives the thumbnail / source icon in the
                # nutrition tab. Omitted here previously, which meant image-logged
                # foods rendered without their photo in the daily summary view.
                image_url=resign_food_image_url(log.get("image_url")),
                source_type=log.get("source_type"),
                user_query=log.get("user_query"),
                # Key micronutrients (optional surfacing in row detail)
                sodium_mg=log.get("sodium_mg"),
                sugar_g=log.get("sugar_g"),
                saturated_fat_g=log.get("saturated_fat_g"),
                cholesterol_mg=log.get("cholesterol_mg"),
                potassium_mg=log.get("potassium_mg"),
                calcium_mg=log.get("calcium_mg"),
                iron_mg=log.get("iron_mg"),
                vitamin_a_ug=log.get("vitamin_a_ug"),
                vitamin_c_mg=log.get("vitamin_c_mg"),
                vitamin_d_iu=log.get("vitamin_d_iu"),
                created_at=to_utc_iso(log.get("created_at") or log.get("logged_at")),
            ))

        response = DailyNutritionResponse(
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

        # Cache the response
        await _daily_summary_cache.set(cache_key, response.dict())

        return response

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

