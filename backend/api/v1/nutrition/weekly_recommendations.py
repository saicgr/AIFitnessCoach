"""Weekly recommendations and check-in summary endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity
from services.gemini_service import GeminiService

from pydantic import BaseModel

from api.v1.nutrition.models import (
    WeeklyRecommendationResponse,
)

router = APIRouter()
logger = get_logger(__name__)

@router.post("/recommendations/{recommendation_id}/respond")
async def respond_to_recommendation(
    recommendation_id: str,
    user_id: str,
    accepted: bool,
    current_user: dict = Depends(get_current_user),
):
    """
    Respond to a weekly nutrition recommendation (accept or decline).

    If accepted, updates the user's nutrition preferences with recommended values.
    """
    logger.info(f"User {user_id} responding to recommendation {recommendation_id}: accepted={accepted}")

    try:
        db = get_supabase_db()

        # Get the recommendation
        rec_result = db.client.table("weekly_nutrition_recommendations")\
            .select("*")\
            .eq("id", recommendation_id)\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not rec_result.data:
            raise HTTPException(status_code=404, detail="Recommendation not found")

        rec = rec_result.data

        # Update recommendation status
        db.client.table("weekly_nutrition_recommendations")\
            .update({"user_accepted": accepted})\
            .eq("id", recommendation_id)\
            .execute()

        # If accepted, update preferences
        if accepted:
            db.client.table("nutrition_preferences")\
                .update({
                    "target_calories": rec["recommended_calories"],
                    "target_protein_g": rec["recommended_protein_g"],
                    "target_carbs_g": rec["recommended_carbs_g"],
                    "target_fat_g": rec["recommended_fat_g"],
                    "calculated_tdee": rec["calculated_tdee"],
                    "last_recalculated_at": datetime.utcnow().isoformat(),
                })\
                .eq("user_id", user_id)\
                .execute()

        return {"success": True, "accepted": accepted}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to respond to recommendation: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/recommendations/{user_id}", response_model=Optional[WeeklyRecommendationResponse])
async def get_weekly_recommendation(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get the latest pending weekly nutrition recommendation for a user.
    """
    logger.info(f"Getting weekly recommendation for user {user_id}")

    try:
        db = get_supabase_db()

        # Use limit(1) and check the list instead of maybe_single() to avoid 406 errors
        result = db.client.table("weekly_nutrition_recommendations")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("user_accepted", False)\
            .order("created_at", desc=True)\
            .limit(1)\
            .execute()

        if not result or not result.data or len(result.data) == 0:
            return None

        data = result.data[0]
        return WeeklyRecommendationResponse(
            id=data["id"],
            user_id=data["user_id"],
            week_start=datetime.fromisoformat(str(data["week_start"]).replace("Z", "+00:00")),
            current_goal=data.get("current_goal", "maintain"),
            target_rate_per_week=float(data.get("target_rate_per_week", 0)),
            calculated_tdee=data.get("calculated_tdee", 0),
            recommended_calories=data.get("recommended_calories", 0),
            recommended_protein_g=data.get("recommended_protein_g", 0),
            recommended_carbs_g=data.get("recommended_carbs_g", 0),
            recommended_fat_g=data.get("recommended_fat_g", 0),
            adjustment_reason=data.get("adjustment_reason"),
            adjustment_amount=data.get("adjustment_amount", 0),
            user_accepted=data.get("user_accepted", False),
            user_modified=data.get("user_modified", False),
            modified_calories=data.get("modified_calories"),
        )

    except Exception as e:
        logger.error(f"Failed to get weekly recommendation: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


class WeeklySummaryResponse(BaseModel):
    """Response model for weekly nutrition summary"""
    days_logged: int
    avg_calories: int
    avg_protein: int
    weight_change: Optional[float] = None
    total_meals: int = 0
    start_weight_kg: Optional[float] = None
    end_weight_kg: Optional[float] = None


@router.get("/weekly-summary/{user_id}", response_model=WeeklySummaryResponse)
async def get_checkin_weekly_summary(request: Request, user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get the weekly nutrition summary for a user (last 7 days) — used by the weekly check-in sheet.
    """
    logger.info(f"Getting weekly summary for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        today_str = get_user_today(user_tz)
        from_date_obj = datetime.strptime(today_str, "%Y-%m-%d") - timedelta(days=7)
        from_date_str = from_date_obj.strftime("%Y-%m-%d")

        # Get food logs for the past week
        food_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, protein_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .execute()

        food_logs = food_result.data or []

        # Get weight logs for the past week
        weight_result = db.client.table("weight_logs")\
            .select("weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .order("logged_at", desc=False)\
            .execute()

        weight_logs = weight_result.data or []

        # Calculate days logged
        logged_dates = set(
            datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            for log in food_logs
        )
        days_logged = len(logged_dates)

        # Calculate average calories and protein
        total_calories = 0
        total_protein = 0
        for log in food_logs:
            total_calories += log.get("total_calories") or 0
            total_protein += float(log.get("protein_g") or 0)

        avg_calories = int(total_calories / days_logged) if days_logged > 0 else 0
        avg_protein = int(total_protein / days_logged) if days_logged > 0 else 0

        # Calculate weight change
        weight_change = None
        start_weight = None
        end_weight = None
        if len(weight_logs) >= 2:
            start_weight = float(weight_logs[0]["weight_kg"])
            end_weight = float(weight_logs[-1]["weight_kg"])
            weight_change = round(end_weight - start_weight, 2)

        return WeeklySummaryResponse(
            days_logged=days_logged,
            avg_calories=avg_calories,
            avg_protein=avg_protein,
            weight_change=weight_change,
            total_meals=len(food_logs),
            start_weight_kg=start_weight,
            end_weight_kg=end_weight,
        )

    except Exception as e:
        logger.error(f"Failed to get weekly summary: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/recommendations/{user_id}/generate", response_model=WeeklyRecommendationResponse)
async def generate_weekly_recommendation(request: Request, user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Generate a new weekly nutrition recommendation based on adaptive TDEE calculation.
    """
    logger.info(f"Generating weekly recommendation for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        # First, get the latest adaptive calculation
        adaptive_result = db.client.table("adaptive_nutrition_calculations")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(1)\
            .maybe_single()\
            .execute()

        # Get user's nutrition preferences
        prefs_result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        prefs = prefs_result.data or {}
        current_goal = prefs.get("nutrition_goal", "maintain")
        current_calories = prefs.get("target_calories", 2000)
        current_protein = prefs.get("target_protein_g", 150)
        current_carbs = prefs.get("target_carbs_g", 200)
        current_fat = prefs.get("target_fat_g", 70)

        # Determine adjustment
        adjustment_reason = None
        adjustment_amount = 0
        calculated_tdee = 0
        target_rate = 0.0

        if adaptive_result.data:
            adaptive = adaptive_result.data
            calculated_tdee = adaptive.get("calculated_tdee", 0)
            quality = adaptive.get("data_quality_score", 0)

            # Only make recommendations if we have enough data
            if quality >= 0.5 and calculated_tdee > 0:
                # Determine goal-based adjustment
                if current_goal == "lose_fat":
                    target_rate = -0.5  # 0.5 kg/week loss
                    recommended_calories = calculated_tdee - 500
                    adjustment_amount = recommended_calories - current_calories
                    if adjustment_amount != 0:
                        adjustment_reason = f"Based on your actual TDEE of {calculated_tdee} cal, adjusting by {adjustment_amount:+d} cal for fat loss goal"
                elif current_goal == "build_muscle":
                    target_rate = 0.25  # 0.25 kg/week gain
                    recommended_calories = calculated_tdee + 250
                    adjustment_amount = recommended_calories - current_calories
                    if adjustment_amount != 0:
                        adjustment_reason = f"Based on your actual TDEE of {calculated_tdee} cal, adjusting by {adjustment_amount:+d} cal for muscle building"
                else:  # maintain
                    target_rate = 0.0
                    recommended_calories = calculated_tdee
                    adjustment_amount = recommended_calories - current_calories
                    if abs(adjustment_amount) > 100:
                        adjustment_reason = f"Based on your actual TDEE of {calculated_tdee} cal, adjusting by {adjustment_amount:+d} cal for maintenance"
                    else:
                        adjustment_amount = 0
            else:
                # Not enough data - keep current targets
                recommended_calories = current_calories
                adjustment_reason = "Need more tracking data (6+ days logged, 2+ weight entries) for adaptive recommendations"
        else:
            recommended_calories = current_calories
            adjustment_reason = "No adaptive calculation available yet - continue tracking to get personalized recommendations"

        # Calculate macros based on new calories
        # Use a balanced split: 30% protein, 40% carbs, 30% fat
        recommended_protein = int((recommended_calories * 0.30) / 4)  # 4 cal/g
        recommended_carbs = int((recommended_calories * 0.40) / 4)    # 4 cal/g
        recommended_fat = int((recommended_calories * 0.30) / 9)      # 9 cal/g

        # Create the recommendation
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        week_start = today - timedelta(days=today.weekday())

        rec_data = {
            "user_id": user_id,
            "week_start": week_start.isoformat(),
            "current_goal": current_goal,
            "target_rate_per_week": target_rate,
            "calculated_tdee": calculated_tdee,
            "recommended_calories": recommended_calories,
            "recommended_protein_g": recommended_protein,
            "recommended_carbs_g": recommended_carbs,
            "recommended_fat_g": recommended_fat,
            "adjustment_reason": adjustment_reason,
            "adjustment_amount": adjustment_amount,
            "user_accepted": False,
            "user_modified": False,
        }

        result = db.client.table("weekly_nutrition_recommendations")\
            .insert(rec_data)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create weekly nutrition recommendation")

        data = result.data[0]
        return WeeklyRecommendationResponse(
            id=data["id"],
            user_id=data["user_id"],
            week_start=datetime.fromisoformat(str(data["week_start"]).replace("Z", "+00:00")),
            current_goal=data.get("current_goal", "maintain"),
            target_rate_per_week=float(data.get("target_rate_per_week", 0)),
            calculated_tdee=data.get("calculated_tdee", 0),
            recommended_calories=data.get("recommended_calories", 0),
            recommended_protein_g=data.get("recommended_protein_g", 0),
            recommended_carbs_g=data.get("recommended_carbs_g", 0),
            recommended_fat_g=data.get("recommended_fat_g", 0),
            adjustment_reason=data.get("adjustment_reason"),
            adjustment_amount=data.get("adjustment_amount", 0),
            user_accepted=data.get("user_accepted", False),
            user_modified=data.get("user_modified", False),
            modified_calories=data.get("modified_calories"),
        )

    except Exception as e:
        logger.error(f"Failed to generate weekly recommendation: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


