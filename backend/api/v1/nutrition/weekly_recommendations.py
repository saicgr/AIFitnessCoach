"""Weekly recommendations and check-in summary endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.activity_logger import log_user_activity
from services.gemini_service import GeminiService

from pydantic import BaseModel

from api.v1.nutrition.models import (
    WeeklyRecommendationResponse,
)
from api.v1.consistency import get_week_starts_sunday, week_start_for

router = APIRouter()
logger = get_logger(__name__)


def _row_to_recommendation(row: dict) -> WeeklyRecommendationResponse:
    """`weekly_nutrition_recommendations` row → response, one shape for both
    the GET and the POST.

    Both handlers used to build the response inline with a datetime
    `week_start` and `.get(..., 0)` defaults that do not match the model or
    the Flutter `WeeklyRecommendation.fromJson` contract. Building it in one
    place keeps the wire shape and the persisted shape from drifting apart
    again.
    """
    return WeeklyRecommendationResponse(
        id=str(row["id"]),
        user_id=str(row["user_id"]),
        # DATE column → 'YYYY-MM-DD'. Not a datetime: this is a calendar week
        # boundary, and pydantic rejects a datetime for a str field anyway.
        week_start=str(row["week_start"])[:10] if row.get("week_start") else None,
        current_goal=row.get("current_goal") or "maintain",
        target_rate_per_week=float(row.get("target_rate_per_week") or 0.0),
        calculated_tdee=row.get("calculated_tdee"),
        recommended_calories=row["recommended_calories"],
        recommended_protein_g=row.get("recommended_protein_g"),
        recommended_carbs_g=row.get("recommended_carbs_g"),
        recommended_fat_g=row.get("recommended_fat_g"),
        adjustment_reason=row.get("adjustment_reason"),
        # NULL when the user has no configured target to diff against —
        # never coerced to 0, which would read as "no change needed".
        adjustment_amount=row.get("adjustment_amount"),
        user_accepted=bool(row.get("user_accepted", False)),
        user_modified=bool(row.get("user_modified", False)),
        modified_calories=row.get("modified_calories"),
        created_at=row.get("created_at"),
    )


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
    verify_user_ownership(current_user, user_id)
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
    verify_user_ownership(current_user, user_id)
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

        return _row_to_recommendation(result.data[0])

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
    verify_user_ownership(current_user, user_id)
    logger.info(f"Getting weekly summary for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        today_str = get_user_today(user_tz)
        today_obj = datetime.strptime(today_str, "%Y-%m-%d").date()

        # This card is presented next to a calendar-week label ("this week",
        # a specific Mon/Sun-Sun/Sat date range) — it must count the SAME
        # calendar week, not a rolling trailing window. `today - 7 days` to
        # `today` is an 8-day span that reaches back into the PREVIOUS
        # calendar week (e.g. today Aug 23 → window starts Aug 16, pulling in
        # a dinner that belongs to last week's Aug 16-22 range and inflating
        # "days logged" for a week that only actually has one log in it).
        starts_sunday = get_week_starts_sunday(db, user_id)
        week_start_obj = week_start_for(today_obj, starts_sunday)
        from_date_str = week_start_obj.strftime("%Y-%m-%d")

        # Convert local date boundaries to UTC for querying
        from_utc_start, _ = local_date_to_utc_range(from_date_str, user_tz)
        _, to_utc_end = local_date_to_utc_range(today_str, user_tz)

        # Get food logs for the past week (UTC-aware boundaries)
        food_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, protein_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", from_utc_start)\
            .lte("logged_at", to_utc_end)\
            .execute()

        food_logs = food_result.data or []

        # Get weight logs for the past week (UTC-aware boundaries)
        weight_result = db.client.table("weight_logs")\
            .select("weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", from_utc_start)\
            .lte("logged_at", to_utc_end)\
            .order("logged_at", desc=False)\
            .execute()

        weight_logs = weight_result.data or []

        # Calculate days logged (convert UTC timestamps to user's local date)
        from zoneinfo import ZoneInfo
        tz = ZoneInfo(user_tz) if user_tz and user_tz != "UTC" else ZoneInfo("UTC")
        logged_dates = set(
            datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).astimezone(tz).date()
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
    verify_user_ownership(current_user, user_id)
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

        prefs = (prefs_result.data if prefs_result else None) or {}
        current_goal = prefs.get("nutrition_goal") or "maintain"
        # NO 2000/150/200/70 fallback. A user who never configured targets has
        # none; inventing a baseline here makes `adjustment_amount` a diff
        # against a plan they never chose, and the accept path
        # (`respond_to_recommendation`) would then WRITE that invented plan
        # into nutrition_preferences. None means "no baseline".
        current_calories = prefs.get("target_calories")

        # Determine adjustment
        adjustment_reason = None
        adjustment_amount: Optional[int] = None
        calculated_tdee = 0
        target_rate = 0.0

        # maybe_single() returns None (not a response) on zero rows.
        adaptive_row = (adaptive_result.data if adaptive_result else None)
        if adaptive_row:
            adaptive = adaptive_row
            calculated_tdee = adaptive.get("calculated_tdee", 0)
            quality = adaptive.get("data_quality_score", 0)

            # Only make recommendations if we have enough data
            if quality >= 0.5 and calculated_tdee > 0:
                # Determine goal-based adjustment
                if current_goal == "lose_fat":
                    target_rate = -0.5  # 0.5 kg/week loss
                    recommended_calories = calculated_tdee - 500
                elif current_goal == "build_muscle":
                    target_rate = 0.25  # 0.25 kg/week gain
                    recommended_calories = calculated_tdee + 250
                else:  # maintain
                    target_rate = 0.0
                    recommended_calories = calculated_tdee

                # The delta is only meaningful against a target the user
                # actually set. With no baseline the recommendation stands on
                # its own and `adjustment_amount` stays NULL — the client
                # renders the recommended number, not a phantom "+340 cal".
                if current_calories is not None:
                    adjustment_amount = recommended_calories - current_calories
                    goal_label = {
                        "lose_fat": "fat loss goal",
                        "build_muscle": "muscle building",
                    }.get(current_goal, "maintenance")
                    # Maintenance ignores sub-100 cal noise; a smaller drift
                    # than that is inside the TDEE estimate's own error bar.
                    if current_goal not in ("lose_fat", "build_muscle") and abs(adjustment_amount) <= 100:
                        adjustment_amount = 0
                    if adjustment_amount != 0:
                        adjustment_reason = (
                            f"Based on your actual TDEE of {calculated_tdee} cal, "
                            f"adjusting by {adjustment_amount:+d} cal for {goal_label}"
                        )
                else:
                    adjustment_reason = (
                        f"Based on your actual TDEE of {calculated_tdee} cal. "
                        "You haven't set a calorie target yet — accept this to make it yours."
                    )
            else:
                # Not enough data - keep current targets
                recommended_calories = current_calories
                adjustment_reason = "Need more tracking data (6+ days logged, 2+ weight entries) for adaptive recommendations"
        else:
            recommended_calories = current_calories
            adjustment_reason = "No adaptive calculation available yet - continue tracking to get personalized recommendations"

        if recommended_calories is None:
            # No configured target AND no usable adaptive TDEE — there is
            # nothing to recommend. Answer honestly instead of inventing a
            # 2000 kcal baseline and persisting it as a "recommendation".
            raise HTTPException(
                status_code=409,
                detail=(
                    "No calorie target configured and not enough tracking data for an "
                    "adaptive recommendation yet. Set your targets in nutrition settings, "
                    "or keep logging for a few more days."
                ),
            )

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
            raise safe_internal_error(ValueError("Failed to create weekly nutrition recommendation"), "nutrition")

        return _row_to_recommendation(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate weekly recommendation: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


