"""Nutrition preferences and dynamic targets endpoints."""
from core.db import get_supabase_db
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone, local_date_to_utc_range, user_today_date
from core.supabase_db import get_supabase_db
from core.logger import get_logger

from api.v1.nutrition.models import (
    NutritionPreferencesResponse,
    NutritionPreferencesUpdate,
    DynamicTargetsResponse,
)

router = APIRouter()
logger = get_logger(__name__)

@router.get("/preferences/{user_id}", response_model=NutritionPreferencesResponse)
async def get_nutrition_preferences(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get user's nutrition preferences.

    Returns nutrition goals, targets, dietary restrictions, and settings.
    """
    logger.info(f"Getting nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not result or not result.data:
            # Return default preferences
            return NutritionPreferencesResponse(user_id=user_id)

        data = result.data
        # Get nutrition_goals, fallback to single goal in array if not present
        nutrition_goals = data.get("nutrition_goals") or []
        if not nutrition_goals and data.get("nutrition_goal"):
            nutrition_goals = [data.get("nutrition_goal")]

        # goal_weight_kg is stored as target_weight_kg in the users table
        goal_weight_kg = None
        try:
            user_result = db.client.table("users").select("target_weight_kg").eq("id", user_id).maybe_single().execute()
            if user_result and user_result.data:
                goal_weight_kg = user_result.data.get("target_weight_kg")
        except Exception:
            pass

        return NutritionPreferencesResponse(
            id=data.get("id"),
            user_id=data.get("user_id", user_id),
            nutrition_goals=nutrition_goals,
            nutrition_goal=data.get("nutrition_goal") or (nutrition_goals[0] if nutrition_goals else "maintain"),
            rate_of_change=data.get("rate_of_change"),
            goal_weight_kg=goal_weight_kg,
            goal_date=str(data["goal_date"]) if data.get("goal_date") else None,
            weeks_to_goal=data.get("weeks_to_goal"),
            calculated_bmr=data.get("calculated_bmr"),
            calculated_tdee=data.get("calculated_tdee"),
            target_calories=data.get("target_calories"),
            target_protein_g=data.get("target_protein_g"),
            target_carbs_g=data.get("target_carbs_g"),
            target_fat_g=data.get("target_fat_g"),
            target_fiber_g=data.get("target_fiber_g", 25),
            diet_type=data.get("diet_type", "balanced"),
            custom_carb_percent=data.get("custom_carb_percent"),
            custom_protein_percent=data.get("custom_protein_percent"),
            custom_fat_percent=data.get("custom_fat_percent"),
            allergies=data.get("allergies") or [],
            dietary_restrictions=data.get("dietary_restrictions") or [],
            disliked_foods=data.get("disliked_foods") or [],
            meal_pattern=data.get("meal_pattern", "3_meals"),
            cooking_skill=data.get("cooking_skill", "intermediate"),
            cooking_time_minutes=data.get("cooking_time_minutes", 30),
            budget_level=data.get("budget_level", "moderate"),
            show_ai_feedback_after_logging=data.get("show_ai_feedback_after_logging", True),
            calm_mode_enabled=data.get("calm_mode_enabled", False),
            show_weekly_instead_of_daily=data.get("show_weekly_instead_of_daily", False),
            adjust_calories_for_training=data.get("adjust_calories_for_training", True),
            adjust_calories_for_rest=data.get("adjust_calories_for_rest", False),
            nutrition_onboarding_completed=data.get("nutrition_onboarding_completed", False),
            onboarding_completed_at=datetime.fromisoformat(str(data.get("onboarding_completed_at")).replace("Z", "+00:00")) if data.get("onboarding_completed_at") else None,
            last_recalculated_at=datetime.fromisoformat(str(data.get("last_recalculated_at")).replace("Z", "+00:00")) if data.get("last_recalculated_at") else None,
            created_at=datetime.fromisoformat(str(data.get("created_at")).replace("Z", "+00:00")) if data.get("created_at") else None,
            updated_at=datetime.fromisoformat(str(data.get("updated_at")).replace("Z", "+00:00")) if data.get("updated_at") else None,
            weekly_checkin_enabled=data.get("weekly_checkin_enabled", True),
            last_weekly_checkin_at=datetime.fromisoformat(str(data.get("last_weekly_checkin_at")).replace("Z", "+00:00")) if data.get("last_weekly_checkin_at") else None,
            weekly_checkin_dismiss_count=data.get("weekly_checkin_dismiss_count", 0),
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.put("/preferences/{user_id}", response_model=NutritionPreferencesResponse)
async def update_nutrition_preferences(user_id: str, request: NutritionPreferencesUpdate, current_user: dict = Depends(get_current_user)):
    """
    Update user's nutrition preferences.

    Allows updating goals, targets, dietary restrictions, and settings.
    """
    logger.info(f"Updating nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Build update data, only including non-None fields
        update_data = {}
        for field, value in request.model_dump().items():
            if value is not None:
                update_data[field] = value

        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing = db.client.table("nutrition_preferences")\
            .select("id")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if existing.data:
            # Update existing
            result = db.client.table("nutrition_preferences")\
                .update(update_data)\
                .eq("user_id", user_id)\
                .execute()
        else:
            # Insert new
            update_data["user_id"] = user_id
            result = db.client.table("nutrition_preferences")\
                .insert(update_data)\
                .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update preferences")

        # Return the updated preferences
        return await get_nutrition_preferences(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update nutrition preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/dynamic-targets/{user_id}", response_model=DynamicTargetsResponse)
async def get_dynamic_nutrition_targets(
    request: Request,
    user_id: str,
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format, defaults to today"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get dynamic nutrition targets for a specific date.

    Adjusts base targets based on:
    - Whether it's a training day (workout scheduled/completed)
    - Whether it's a fasting day (for 5:2, ADF protocols)
    - User's preferences for training/rest day adjustments
    """
    logger.info(f"Getting dynamic nutrition targets for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        # Parse target date
        if date:
            target_date = datetime.fromisoformat(date).date()
        else:
            target_date = user_today_date(request, db, user_id)

        target_date_str = target_date.isoformat()

        # Get user's base preferences
        prefs_result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        prefs = (prefs_result.data if prefs_result else None) or {}

        base_calories = prefs.get("target_calories") or 2000
        base_protein = prefs.get("target_protein_g") or 150
        base_carbs = prefs.get("target_carbs_g") or 200
        base_fat = prefs.get("target_fat_g") or 65
        base_fiber = prefs.get("target_fiber_g") or 25
        adjust_for_training = prefs.get("adjust_calories_for_training", True)
        adjust_for_rest = prefs.get("adjust_calories_for_rest", False)

        # Check if today is a training day per the user's workout schedule
        # workout_days is stored as 0-indexed (0=Mon, 1=Tue, ..., 6=Sun)
        # Python's weekday() is also 0=Mon, 1=Tue, ..., 6=Sun
        is_scheduled_training_day = False
        gym_profile_result = db.client.table("gym_profiles")\
            .select("workout_days")\
            .eq("user_id", user_id)\
            .eq("is_active", True)\
            .maybe_single()\
            .execute()

        if gym_profile_result and gym_profile_result.data:
            workout_days = gym_profile_result.data.get("workout_days") or []
            is_scheduled_training_day = target_date.weekday() in workout_days

        # Check if there's a workout logged today (timezone-aware UTC range)
        utc_start, utc_end = local_date_to_utc_range(target_date_str, user_tz)
        workout_result = db.client.table("workout_logs")\
            .select("id")\
            .eq("user_id", user_id)\
            .gte("completed_at", utc_start)\
            .lt("completed_at", utc_end)\
            .execute()

        has_workout_log = bool(workout_result and workout_result.data)

        # A day counts as a training day if:
        # 1. It's in the user's workout_days schedule, OR
        # 2. There's an actual completed workout log for it
        has_workout = is_scheduled_training_day or has_workout_log

        # Check if it's a fasting day (for 5:2 or ADF protocols)
        is_fasting_day = False
        fasting_prefs = db.client.table("fasting_preferences")\
            .select("default_protocol, fasting_days")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if fasting_prefs and fasting_prefs.data:
            protocol = fasting_prefs.data.get("default_protocol", "")
            fasting_days = fasting_prefs.data.get("fasting_days") or []

            if protocol in ["5:2", "adf"]:
                day_name = target_date.strftime("%A").lower()
                is_fasting_day = day_name in [d.lower() for d in fasting_days]

        # Calculate adjustments
        calorie_adjustment = 0
        adjustment_reason = None

        if is_fasting_day:
            # Fasting day: significant calorie reduction
            calorie_adjustment = -int(base_calories * 0.75)  # 25% of normal
            adjustment_reason = "Fasting day - reduced calories"
        elif has_workout and adjust_for_training:
            # Training day: increase calories
            calorie_adjustment = 200
            adjustment_reason = "Training day - extra fuel for workout and recovery"
        elif not has_workout and adjust_for_rest:
            # Rest day: slight decrease
            calorie_adjustment = -100
            adjustment_reason = "Rest day - slightly reduced intake"

        target_calories = base_calories + calorie_adjustment

        # Adjust protein on training days
        target_protein = base_protein
        if has_workout and adjust_for_training:
            target_protein = int(base_protein * 1.1)  # 10% more protein

        # Adjust carbs on training days
        target_carbs = base_carbs
        if has_workout and adjust_for_training:
            target_carbs = int(base_carbs * 1.15)  # 15% more carbs for glycogen

        return DynamicTargetsResponse(
            target_calories=target_calories,
            target_protein_g=target_protein,
            target_carbs_g=target_carbs,
            target_fat_g=base_fat,
            target_fiber_g=base_fiber,
            is_training_day=has_workout,
            is_fasting_day=is_fasting_day,
            is_rest_day=not has_workout and not is_fasting_day,
            adjustment_reason=adjustment_reason,
            calorie_adjustment=calorie_adjustment,
        )

    except Exception as e:
        logger.error(f"Failed to get dynamic nutrition targets: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")

