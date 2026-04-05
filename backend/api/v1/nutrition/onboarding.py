"""Nutrition onboarding, skip, reset, and recalculate endpoints."""
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger

from api.v1.nutrition.models import (
    NutritionOnboardingRequest,
    NutritionPreferencesResponse,
    SkipOnboardingRequest,
)
from api.v1.nutrition.preferences import get_nutrition_preferences

router = APIRouter()
logger = get_logger(__name__)

@router.post("/onboarding/complete", response_model=NutritionPreferencesResponse)
async def complete_nutrition_onboarding(request: NutritionOnboardingRequest, current_user: dict = Depends(get_current_user)):
    """
    Complete nutrition onboarding and calculate initial targets.

    Calculates BMR, TDEE, and macro targets based on user profile and goals.
    """
    logger.info(f"Completing nutrition onboarding for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Get user profile for BMR/TDEE calculation
        user_result = db.client.table("users")\
            .select("weight_kg, height_cm, age, gender, activity_level, preferences")\
            .eq("id", request.user_id)\
            .single()\
            .execute()

        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = user_result.data
        weight_kg = float(user.get("weight_kg") or 70)
        height_cm = float(user.get("height_cm") or 170)
        age = int(user.get("age") or 30)
        gender = user.get("gender", "male").lower()
        activity_level = user.get("activity_level", "moderately_active")

        # Resolve nutrition goals from weight_direction when goals are empty or default "maintain"
        # This prevents the mismatch where user selects "lose weight" but profile shows "Maintain Weight"
        user_prefs = user.get("preferences") or {}
        weight_direction = user_prefs.get("weight_direction")
        if weight_direction and weight_direction != "maintain":
            has_meaningful_goals = (
                request.nutrition_goals
                and request.nutrition_goals != ["maintain"]
            )
            if not has_meaningful_goals:
                if weight_direction == "lose":
                    request.nutrition_goals = ["lose_fat"]
                    request.nutrition_goal = "lose_fat"
                elif weight_direction == "gain":
                    request.nutrition_goals = ["build_muscle"]
                    request.nutrition_goal = "build_muscle"
                logger.info(f"Resolved nutrition goal from weight_direction='{weight_direction}': {request.nutrition_goals}")

        # Calculate BMR using Mifflin-St Jeor equation
        if gender == "male":
            bmr = int((10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5)
        else:
            bmr = int((10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161)

        # Calculate TDEE
        activity_multipliers = {
            "sedentary": 1.2,
            "lightly_active": 1.375,
            "moderately_active": 1.55,
            "very_active": 1.725,
            "extra_active": 1.9,
        }
        multiplier = activity_multipliers.get(activity_level, 1.55)
        tdee = int(bmr * multiplier)

        # Calculate calorie target based on goal
        goal_adjustments = {
            "lose_fat": -500,
            "build_muscle": 300,
            "maintain": 0,
            "improve_energy": 0,
            "eat_healthier": 0,
            "recomposition": -200,
        }

        rate_adjustments = {
            "slow": 250,
            "moderate": 500,
            "aggressive": 750,
        }

        # Use primary_goal property for calculations (first goal in multi-select list)
        primary_goal = request.primary_goal
        adjustment = goal_adjustments.get(primary_goal, 0)
        if primary_goal == "lose_fat" and request.rate_of_change:
            adjustment = -rate_adjustments.get(request.rate_of_change, 500)
        elif primary_goal == "build_muscle" and request.rate_of_change:
            adjustment = rate_adjustments.get(request.rate_of_change, 500) // 2

        target_calories = max(
            1200 if gender == "female" else 1500,
            tdee + adjustment
        )

        # Calculate macros based on diet type
        # Format: (carb%, protein%, fat%)
        diet_macros = {
            # No restrictions
            "no_diet": (45, 25, 30),
            # Macro-focused diets
            "balanced": (45, 25, 30),
            "low_carb": (25, 35, 40),
            "keto": (5, 25, 70),
            "high_protein": (35, 40, 25),
            "mediterranean": (45, 20, 35),
            # Plant-based diets (strict to flexible)
            "vegan": (55, 20, 25),
            "vegetarian": (50, 20, 30),
            "lacto_ovo": (50, 22, 28),
            "pescatarian": (45, 25, 30),
            # Flexible/part-time diets
            "flexitarian": (45, 25, 30),
            "part_time_veg": (50, 20, 30),
        }

        if request.diet_type == "custom" and all([
            request.custom_carb_percent,
            request.custom_protein_percent,
            request.custom_fat_percent
        ]):
            carb_pct = request.custom_carb_percent
            protein_pct = request.custom_protein_percent
            fat_pct = request.custom_fat_percent
        else:
            carb_pct, protein_pct, fat_pct = diet_macros.get(request.diet_type, (45, 25, 30))

        target_protein = int((target_calories * protein_pct / 100) / 4)
        target_carbs = int((target_calories * carb_pct / 100) / 4)
        target_fat = int((target_calories * fat_pct / 100) / 9)

        # Use frontend-calculated values if provided (ensures consistency with what user saw)
        # Otherwise use the values we just calculated above
        final_bmr = request.calculated_bmr if request.calculated_bmr is not None else bmr
        final_tdee = request.calculated_tdee if request.calculated_tdee is not None else tdee
        final_calories = request.target_calories if request.target_calories is not None else target_calories
        final_protein = request.target_protein_g if request.target_protein_g is not None else target_protein
        final_carbs = request.target_carbs_g if request.target_carbs_g is not None else target_carbs
        final_fat = request.target_fat_g if request.target_fat_g is not None else target_fat

        if request.target_calories is not None:
            logger.info(f"Using frontend-calculated values: calories={final_calories}, protein={final_protein}g")
        else:
            logger.info(f"Using backend-calculated values: calories={final_calories}, protein={final_protein}g")

        # Create/update nutrition preferences
        prefs_data = {
            "user_id": request.user_id,
            "nutrition_goals": request.all_goals,  # Multi-select goals array
            "nutrition_goal": request.primary_goal,  # Legacy single goal (primary)
            "rate_of_change": request.rate_of_change,
            "calculated_bmr": final_bmr,
            "calculated_tdee": final_tdee,
            "target_calories": final_calories,
            "target_protein_g": final_protein,
            "target_carbs_g": final_carbs,
            "target_fat_g": final_fat,
            "diet_type": request.diet_type,
            "custom_carb_percent": request.custom_carb_percent,
            "custom_protein_percent": request.custom_protein_percent,
            "custom_fat_percent": request.custom_fat_percent,
            "allergies": request.allergies,
            "dietary_restrictions": request.dietary_restrictions,
            "meal_pattern": request.meal_pattern,
            "cooking_skill": request.cooking_skill,
            "cooking_time_minutes": request.cooking_time_minutes,
            "budget_level": request.budget_level,
            "nutrition_onboarding_completed": True,
            "onboarding_completed_at": datetime.utcnow().isoformat(),
            "last_recalculated_at": datetime.utcnow().isoformat(),
        }

        # Check if preferences exist
        existing = db.client.table("nutrition_preferences")\
            .select("id")\
            .eq("user_id", request.user_id)\
            .maybe_single()\
            .execute()

        if existing.data:
            result = db.client.table("nutrition_preferences")\
                .update(prefs_data)\
                .eq("user_id", request.user_id)\
                .execute()
        else:
            result = db.client.table("nutrition_preferences")\
                .insert(prefs_data)\
                .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save preferences")

        # Sync targets to users table for consistency
        try:
            db.client.table("users").update({
                "daily_calorie_target": final_calories,
                "daily_protein_target_g": final_protein,
                "daily_carbs_target_g": final_carbs,
                "daily_fat_target_g": final_fat,
            }).eq("id", request.user_id).execute()
        except Exception as sync_err:
            logger.warning(f"Failed to sync onboarding targets to users table: {sync_err}")

        # Initialize nutrition streak
        streak_exists = db.client.table("nutrition_streaks")\
            .select("id")\
            .eq("user_id", request.user_id)\
            .maybe_single()\
            .execute()

        if not streak_exists.data:
            db.client.table("nutrition_streaks")\
                .insert({"user_id": request.user_id})\
                .execute()

        # Return the updated preferences
        return await get_nutrition_preferences(request.user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete nutrition onboarding: {e}")
        raise safe_internal_error(e, "nutrition")


@router.post("/onboarding/skip")
async def skip_nutrition_onboarding(request: SkipOnboardingRequest, current_user: dict = Depends(get_current_user)):
    """
    Skip nutrition onboarding permanently.

    Sets nutrition_onboarding_completed to true with default targets (2000 cal).
    User can always customize later in settings.
    """
    logger.info(f"Skipping nutrition onboarding for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Default targets for skipped users
        default_prefs = {
            "user_id": request.user_id,
            "nutrition_onboarding_completed": True,
            "onboarding_completed_at": datetime.utcnow().isoformat(),
            "target_calories": 2000,
            "target_protein_g": 150,
            "target_carbs_g": 200,
            "target_fat_g": 67,
            "target_fiber_g": 25,
            "diet_type": "balanced",
            "meal_pattern": "3_meals",
        }

        # Check if preferences exist
        existing = db.client.table("nutrition_preferences")\
            .select("id")\
            .eq("user_id", request.user_id)\
            .maybe_single()\
            .execute()

        if existing.data:
            # Update existing preferences
            db.client.table("nutrition_preferences")\
                .update({
                    "nutrition_onboarding_completed": True,
                    "onboarding_completed_at": datetime.utcnow().isoformat(),
                })\
                .eq("user_id", request.user_id)\
                .execute()
        else:
            # Create new preferences with defaults
            db.client.table("nutrition_preferences")\
                .insert(default_prefs)\
                .execute()

        return {"success": True, "message": "Nutrition onboarding skipped"}

    except Exception as e:
        logger.error(f"Failed to skip nutrition onboarding: {e}")
        raise safe_internal_error(e, "nutrition")


@router.post("/{user_id}/reset-onboarding")
async def reset_nutrition_onboarding(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Reset nutrition onboarding so user can redo it.

    Sets nutrition_onboarding_completed to false while preserving
    all food logs and nutrition history.
    """
    logger.info(f"Resetting nutrition onboarding for user {user_id}")

    try:
        db = get_supabase_db()

        # Update nutrition_onboarding_completed to false
        result = db.client.table("nutrition_preferences")\
            .update({"nutrition_onboarding_completed": False})\
            .eq("user_id", user_id)\
            .execute()

        if not result.data:
            # No preferences exist yet, that's fine
            logger.info(f"No nutrition preferences found for user {user_id}, nothing to reset")

        return {"success": True, "message": "Nutrition onboarding reset successfully"}

    except Exception as e:
        logger.error(f"Failed to reset nutrition onboarding: {e}")
        raise safe_internal_error(e, "nutrition")


@router.post("/preferences/{user_id}/recalculate", response_model=NutritionPreferencesResponse)
async def recalculate_nutrition_targets(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Recalculate nutrition targets based on current user data.

    Useful after weight changes or profile updates.
    """
    logger.info(f"Recalculating nutrition targets for user {user_id}")

    try:
        db = get_supabase_db()

        # Get current preferences
        prefs_result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not prefs_result.data:
            raise HTTPException(status_code=404, detail="Nutrition preferences not found")

        prefs = prefs_result.data

        # Get user profile
        user_result = db.client.table("users")\
            .select("weight_kg, height_cm, age, gender, activity_level")\
            .eq("id", user_id)\
            .single()\
            .execute()

        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = user_result.data
        weight_kg = float(user.get("weight_kg") or 70)
        height_cm = float(user.get("height_cm") or 170)
        age = int(user.get("age") or 30)
        gender = user.get("gender", "male").lower()
        activity_level = user.get("activity_level", "moderately_active")

        # Recalculate BMR and TDEE
        if gender == "male":
            bmr = int((10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5)
        else:
            bmr = int((10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161)

        activity_multipliers = {
            "sedentary": 1.2,
            "lightly_active": 1.375,
            "moderately_active": 1.55,
            "very_active": 1.725,
            "extra_active": 1.9,
        }
        multiplier = activity_multipliers.get(activity_level, 1.55)
        tdee = int(bmr * multiplier)

        # Calculate calorie target
        goal_adjustments = {
            "lose_fat": -500,
            "build_muscle": 300,
            "maintain": 0,
            "improve_energy": 0,
            "eat_healthier": 0,
            "recomposition": -200,
        }

        rate_adjustments = {
            "slow": 250,
            "moderate": 500,
            "aggressive": 750,
        }

        nutrition_goal = prefs.get("nutrition_goal", "maintain")
        rate_of_change = prefs.get("rate_of_change")

        adjustment = goal_adjustments.get(nutrition_goal, 0)
        if nutrition_goal == "lose_fat" and rate_of_change:
            adjustment = -rate_adjustments.get(rate_of_change, 500)
        elif nutrition_goal == "build_muscle" and rate_of_change:
            adjustment = rate_adjustments.get(rate_of_change, 500) // 2

        target_calories = max(
            1200 if gender == "female" else 1500,
            tdee + adjustment
        )

        # Recalculate macros
        diet_type = prefs.get("diet_type", "balanced")
        # Format: (carb%, protein%, fat%)
        diet_macros = {
            # No restrictions
            "no_diet": (45, 25, 30),
            # Macro-focused diets
            "balanced": (45, 25, 30),
            "low_carb": (25, 35, 40),
            "keto": (5, 25, 70),
            "high_protein": (35, 40, 25),
            "mediterranean": (45, 20, 35),
            # Plant-based diets (strict to flexible)
            "vegan": (55, 20, 25),
            "vegetarian": (50, 20, 30),
            "lacto_ovo": (50, 22, 28),
            "pescatarian": (45, 25, 30),
            # Flexible/part-time diets
            "flexitarian": (45, 25, 30),
            "part_time_veg": (50, 20, 30),
        }

        if diet_type == "custom" and all([
            prefs.get("custom_carb_percent"),
            prefs.get("custom_protein_percent"),
            prefs.get("custom_fat_percent")
        ]):
            carb_pct = prefs["custom_carb_percent"]
            protein_pct = prefs["custom_protein_percent"]
            fat_pct = prefs["custom_fat_percent"]
        else:
            carb_pct, protein_pct, fat_pct = diet_macros.get(diet_type, (45, 25, 30))

        target_protein = int((target_calories * protein_pct / 100) / 4)
        target_carbs = int((target_calories * carb_pct / 100) / 4)
        target_fat = int((target_calories * fat_pct / 100) / 9)

        # Update preferences
        update_data = {
            "calculated_bmr": bmr,
            "calculated_tdee": tdee,
            "target_calories": target_calories,
            "target_protein_g": target_protein,
            "target_carbs_g": target_carbs,
            "target_fat_g": target_fat,
            "last_recalculated_at": datetime.utcnow().isoformat(),
        }

        db.client.table("nutrition_preferences")\
            .update(update_data)\
            .eq("user_id", user_id)\
            .execute()

        # Sync targets to users table for consistency
        try:
            db.client.table("users").update({
                "daily_calorie_target": target_calories,
                "daily_protein_target_g": target_protein,
                "daily_carbs_target_g": target_carbs,
                "daily_fat_target_g": target_fat,
            }).eq("id", user_id).execute()
        except Exception as sync_err:
            logger.warning(f"Failed to sync recalculated targets to users table: {sync_err}")

        return await get_nutrition_preferences(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to recalculate nutrition targets: {e}")
        raise safe_internal_error(e, "nutrition")

