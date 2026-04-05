"""Detailed TDEE analysis, adherence tracking, and recommendation options endpoints."""
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity

from api.v1.nutrition.models import (
    DetailedTDEEResponse,
    AdherenceSummaryResponse,
    RecommendationOption,
    RecommendationOptionsResponse,
    SelectRecommendationRequest,
)

router = APIRouter()
logger = get_logger(__name__)

@router.get("/tdee/{user_id}/detailed", response_model=DetailedTDEEResponse)
async def get_detailed_tdee(request: Request, user_id: str, days: int = Query(default=14, ge=7, le=30), current_user: dict = Depends(get_current_user)):
    """
    Get TDEE with confidence intervals, weight trend, and metabolic adaptation status.

    This endpoint provides MacroFactor-style detailed TDEE calculation:
    - EMA-smoothed weight trends
    - Confidence intervals (e.g., "2,150 ±120 cal")
    - Metabolic adaptation detection
    - Data quality scoring
    """
    logger.info(f"Getting detailed TDEE for user {user_id} over {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        tdee_service = get_adaptive_tdee_service()
        adaptation_service = get_metabolic_adaptation_service()

        # Get food logs for the period
        end_date = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        start_date = end_date - timedelta(days=days)

        food_logs_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, protein_g, carbs_g, fat_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", start_date.isoformat())\
            .lte("logged_at", end_date.isoformat())\
            .execute()

        # Aggregate food logs by day
        daily_calories = {}
        for log in food_logs_result.data or []:
            log_date = datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            if log_date not in daily_calories:
                daily_calories[log_date] = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0}
            daily_calories[log_date]["calories"] += log.get("total_calories", 0) or 0
            daily_calories[log_date]["protein"] += float(log.get("protein_g", 0) or 0)
            daily_calories[log_date]["carbs"] += float(log.get("carbs_g", 0) or 0)
            daily_calories[log_date]["fat"] += float(log.get("fat_g", 0) or 0)

        food_logs = [
            FoodLogSummary(
                date=d,
                total_calories=int(data["calories"]),
                protein_g=data["protein"],
                carbs_g=data["carbs"],
                fat_g=data["fat"],
            )
            for d, data in daily_calories.items()
        ]

        # Get weight logs
        weight_logs_result = db.client.table("weight_logs")\
            .select("id, user_id, weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", start_date.isoformat())\
            .order("logged_at")\
            .execute()

        weight_logs = [
            ServiceWeightLog(
                id=log["id"],
                user_id=log["user_id"],
                weight_kg=float(log["weight_kg"]),
                logged_at=datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")),
            )
            for log in weight_logs_result.data or []
        ]

        # Calculate TDEE with confidence intervals
        calculation = tdee_service.calculate_tdee_with_confidence(food_logs, weight_logs, days)

        if not calculation:
            return DetailedTDEEResponse(
                tdee=0,
                confidence_low=0,
                confidence_high=0,
                uncertainty_display="N/A",
                uncertainty_calories=0,
                data_quality_score=0.0,
                weight_change_kg=0.0,
                avg_daily_intake=0,
                start_weight_kg=0.0,
                end_weight_kg=0.0,
                days_analyzed=days,
                food_logs_count=len(food_logs),
                weight_logs_count=len(weight_logs),
                weight_trend={"status": "insufficient_data", "message": "Need at least 5 food logs and 2 weight entries"},
                metabolic_adaptation=None,
                confidence_level="insufficient_data",
            )

        # Get weight trend
        trend = tdee_service.get_weight_trend(weight_logs)

        # Check for metabolic adaptation
        # Get historical TDEE calculations
        history_result = db.client.table("adaptive_nutrition_calculations")\
            .select("id, user_id, calculated_at, calculated_tdee, weight_change_kg, avg_daily_intake, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(8)\
            .execute()

        tdee_history = [
            TDEEHistoryEntry(
                id=h["id"],
                user_id=h["user_id"],
                calculated_at=datetime.fromisoformat(str(h["calculated_at"]).replace("Z", "+00:00")),
                calculated_tdee=h.get("calculated_tdee") or 0,
                weight_change_kg=float(h.get("weight_change_kg") or 0),
                avg_daily_intake=h.get("avg_daily_intake") or 0,
                data_quality_score=float(h.get("data_quality_score") or 0),
            )
            for h in history_result.data or []
        ]

        # Get user's current goal
        prefs_result = db.client.table("nutrition_preferences")\
            .select("nutrition_goal, target_calories")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        current_goal = prefs_result.data.get("nutrition_goal", "maintain") if prefs_result.data else "maintain"
        current_deficit = 500  # Default deficit

        if prefs_result.data and prefs_result.data.get("target_calories"):
            current_deficit = calculation.tdee - prefs_result.data.get("target_calories", calculation.tdee)

        # Detect metabolic adaptation
        adaptation = adaptation_service.detect_metabolic_adaptation(
            tdee_history, current_goal, abs(current_deficit)
        )

        # Store this calculation in history
        try:
            db.client.table("tdee_calculation_history").insert({
                "user_id": user_id,
                "period_start": start_date.isoformat(),
                "period_end": end_date.isoformat(),
                "days_analyzed": calculation.days_analyzed,
                "food_logs_count": calculation.food_logs_count,
                "weight_logs_count": calculation.weight_logs_count,
                "start_weight_kg": calculation.start_weight_kg,
                "end_weight_kg": calculation.end_weight_kg,
                "weight_change_kg": calculation.weight_change_kg,
                "avg_daily_intake": calculation.avg_daily_intake,
                "calculated_tdee": calculation.tdee,
                "confidence_low": calculation.confidence_low,
                "confidence_high": calculation.confidence_high,
                "uncertainty_calories": calculation.uncertainty_calories,
                "data_quality_score": calculation.data_quality_score,
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to store TDEE history: {e}")

        return DetailedTDEEResponse(
            tdee=calculation.tdee,
            confidence_low=calculation.confidence_low,
            confidence_high=calculation.confidence_high,
            uncertainty_display=f"±{calculation.uncertainty_calories}",
            uncertainty_calories=calculation.uncertainty_calories,
            data_quality_score=calculation.data_quality_score,
            weight_change_kg=calculation.weight_change_kg,
            avg_daily_intake=calculation.avg_daily_intake,
            start_weight_kg=calculation.start_weight_kg,
            end_weight_kg=calculation.end_weight_kg,
            days_analyzed=calculation.days_analyzed,
            food_logs_count=calculation.food_logs_count,
            weight_logs_count=calculation.weight_logs_count,
            weight_trend={
                "smoothed_weight_kg": trend.smoothed_weight if trend else None,
                "raw_weight_kg": trend.raw_weight if trend else None,
                "direction": trend.trend_direction if trend else "stable",
                "weekly_rate_kg": trend.weekly_rate_kg if trend else 0,
                "confidence": trend.confidence if trend else "low",
            },
            metabolic_adaptation=adaptation.to_dict() if adaptation else None,
            confidence_level="high" if calculation.data_quality_score >= 0.7 else "medium" if calculation.data_quality_score >= 0.4 else "low",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get detailed TDEE: {e}")
        raise safe_internal_error(e, "nutrition")


@router.get("/adherence/{user_id}/summary", response_model=AdherenceSummaryResponse)
async def get_adherence_summary(request: Request, user_id: str, weeks: int = Query(default=4, ge=1, le=12), current_user: dict = Depends(get_current_user)):
    """
    Get adherence summary with sustainability score.

    Returns:
    - Weekly adherence breakdown
    - Overall sustainability rating (high/medium/low)
    - Recommendations based on adherence patterns
    """
    logger.info(f"Getting adherence summary for user {user_id} over {weeks} weeks")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        adherence_service = get_adherence_tracking_service()

        # Get user's nutrition targets
        prefs_result = db.client.table("nutrition_preferences")\
            .select("target_calories, target_protein_g, target_carbs_g, target_fat_g, nutrition_goal")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not prefs_result.data:
            raise HTTPException(status_code=404, detail="Nutrition preferences not found")

        prefs = prefs_result.data
        targets = ServiceNutritionTargets(
            calories=prefs.get("target_calories", 2000),
            protein_g=prefs.get("target_protein_g", 150),
            carbs_g=prefs.get("target_carbs_g", 200),
            fat_g=prefs.get("target_fat_g", 65),
        )

        # Get daily nutrition summaries for the period
        end_date = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        start_date = end_date - timedelta(weeks=weeks * 7)

        # Get food logs aggregated by day
        food_logs_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, protein_g, carbs_g, fat_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", start_date.isoformat())\
            .lte("logged_at", end_date.isoformat())\
            .execute()

        # Aggregate by day
        daily_totals = {}
        for log in food_logs_result.data or []:
            log_date = datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            if log_date not in daily_totals:
                daily_totals[log_date] = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0, "meals": 0}
            daily_totals[log_date]["calories"] += log.get("total_calories", 0) or 0
            daily_totals[log_date]["protein"] += float(log.get("protein_g", 0) or 0)
            daily_totals[log_date]["carbs"] += float(log.get("carbs_g", 0) or 0)
            daily_totals[log_date]["fat"] += float(log.get("fat_g", 0) or 0)
            daily_totals[log_date]["meals"] += 1

        # Calculate daily adherence
        daily_adherences = []
        for log_date, totals in daily_totals.items():
            actuals = NutritionActuals(
                date=log_date,
                calories=int(totals["calories"]),
                protein_g=totals["protein"],
                carbs_g=totals["carbs"],
                fat_g=totals["fat"],
                meals_logged=totals["meals"],
            )
            adherence = adherence_service.calculate_daily_adherence(targets, actuals)
            daily_adherences.append(adherence)

        # Group by week and calculate summaries
        weekly_summaries = []
        current_week_start = start_date - timedelta(days=start_date.weekday())  # Monday

        while current_week_start <= end_date:
            week_end = current_week_start + timedelta(days=6)
            week_adherences = [
                a for a in daily_adherences
                if current_week_start <= a.date <= week_end
            ]
            summary = adherence_service.calculate_weekly_summary(week_adherences, current_week_start)
            weekly_summaries.append(summary)
            current_week_start += timedelta(days=7)

        # Calculate sustainability score
        sustainability = adherence_service.calculate_sustainability_score(weekly_summaries)

        return AdherenceSummaryResponse(
            weekly_adherence=[s.to_dict() for s in weekly_summaries[-weeks:]],
            average_adherence=sustainability.avg_adherence,
            sustainability_score=sustainability.score,
            sustainability_rating=sustainability.rating.value,
            recommendation=sustainability.recommendation,
            weeks_analyzed=len(weekly_summaries),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get adherence summary: {e}")
        raise safe_internal_error(e, "nutrition")


@router.get("/recommendations/{user_id}/options", response_model=RecommendationOptionsResponse)
async def get_recommendation_options(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get multiple recommendation options for user to choose from.

    MacroFactor-style multi-option recommendations:
    - Aggressive (if adherence >80% and no adaptation)
    - Moderate (always shown, recommended)
    - Conservative (if adherence <70% or adaptation detected)
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    logger.info(f"Getting recommendation options for user {user_id}")

    try:
        db = get_supabase_db()
        adherence_service = get_adherence_tracking_service()
        adaptation_service = get_metabolic_adaptation_service()

        # Get latest adaptive TDEE
        tdee_result = db.client.table("adaptive_nutrition_calculations")\
            .select("calculated_tdee, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(1)\
            .execute()

        tdee_rows = tdee_result.data or []
        tdee_data = tdee_rows[0] if tdee_rows else None
        if not tdee_data or not tdee_data.get("calculated_tdee"):
            # Fall back to nutrition preferences TDEE
            prefs = db.client.table("nutrition_preferences")\
                .select("calculated_tdee, nutrition_goal")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()

            prefs_data = getattr(prefs, 'data', None)
            if not prefs_data or not prefs_data.get("calculated_tdee"):
                raise HTTPException(
                    status_code=400,
                    detail="No TDEE available. Please log food and weight data first."
                )

            current_tdee = prefs_data.get("calculated_tdee") or 2000
            current_goal = prefs_data.get("nutrition_goal") or "maintain"
        else:
            current_tdee = tdee_data.get("calculated_tdee") or 2000
            # Get goal from preferences
            prefs = db.client.table("nutrition_preferences")\
                .select("nutrition_goal")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()
            prefs_data = getattr(prefs, 'data', None)
            current_goal = (prefs_data.get("nutrition_goal") or "maintain") if prefs_data else "maintain"

        # Get adherence score via service (avoid calling route handler directly)
        try:
            prefs_for_adh = db.client.table("nutrition_preferences")\
                .select("target_calories, target_protein_g, target_carbs_g, target_fat_g")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()
            adh_prefs = getattr(prefs_for_adh, 'data', None) or {}
            adh_targets = ServiceNutritionTargets(
                calories=adh_prefs.get("target_calories", 2000),
                protein_g=adh_prefs.get("target_protein_g", 150),
                carbs_g=adh_prefs.get("target_carbs_g", 200),
                fat_g=adh_prefs.get("target_fat_g", 65),
            )
            end_date = datetime.now().date()
            start_date = end_date - timedelta(weeks=4)
            food_logs_result = db.client.table("food_logs")\
                .select("logged_at, total_calories, protein_g, carbs_g, fat_g")\
                .eq("user_id", user_id)\
                .is_("deleted_at", "null")\
                .gte("logged_at", start_date.isoformat())\
                .lte("logged_at", end_date.isoformat())\
                .execute()
            daily_totals: dict = {}
            for log in food_logs_result.data or []:
                log_date = datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
                if log_date not in daily_totals:
                    daily_totals[log_date] = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0, "meals": 0}
                daily_totals[log_date]["calories"] += log.get("total_calories", 0) or 0
                daily_totals[log_date]["protein"] += float(log.get("protein_g", 0) or 0)
                daily_totals[log_date]["carbs"] += float(log.get("carbs_g", 0) or 0)
                daily_totals[log_date]["fat"] += float(log.get("fat_g", 0) or 0)
                daily_totals[log_date]["meals"] += 1
            daily_adherences = []
            for log_date, totals in daily_totals.items():
                actuals = NutritionActuals(
                    date=log_date,
                    calories=int(totals["calories"]),
                    protein_g=totals["protein"],
                    carbs_g=totals["carbs"],
                    fat_g=totals["fat"],
                    meals_logged=totals["meals"],
                )
                daily_adherences.append(adherence_service.calculate_daily_adherence(adh_targets, actuals))
            weekly_summaries = []
            week_start = start_date - timedelta(days=start_date.weekday())
            while week_start <= end_date:
                week_end = week_start + timedelta(days=6)
                week_adh = [a for a in daily_adherences if week_start <= a.date <= week_end]
                weekly_summaries.append(adherence_service.calculate_weekly_summary(week_adh, week_start))
                week_start += timedelta(days=7)
            sustainability = adherence_service.calculate_sustainability_score(weekly_summaries)
            adherence_score = sustainability.score
        except Exception as adh_err:
            logger.warning(f"Failed to compute adherence score, defaulting to 0.5: {adh_err}")
            adherence_score = 0.5

        # Get TDEE history for adaptation detection
        history_result = db.client.table("adaptive_nutrition_calculations")\
            .select("id, user_id, calculated_at, calculated_tdee, weight_change_kg, avg_daily_intake, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(8)\
            .execute()

        tdee_history = [
            TDEEHistoryEntry(
                id=h["id"],
                user_id=h["user_id"],
                calculated_at=datetime.fromisoformat(str(h["calculated_at"]).replace("Z", "+00:00")),
                calculated_tdee=h.get("calculated_tdee") or 0,
                weight_change_kg=float(h.get("weight_change_kg") or 0),
                avg_daily_intake=h.get("avg_daily_intake") or 0,
                data_quality_score=float(h.get("data_quality_score") or 0),
            )
            for h in history_result.data or []
        ]

        # Detect metabolic adaptation
        adaptation = adaptation_service.detect_metabolic_adaptation(tdee_history, current_goal, 500)

        # Generate recommendation options
        options = _generate_recommendation_options(
            current_tdee=current_tdee,
            goal=current_goal,
            adherence_score=adherence_score,
            has_adaptation=adaptation is not None,
        )

        return RecommendationOptionsResponse(
            current_tdee=current_tdee,
            current_goal=current_goal,
            adherence_score=adherence_score,
            has_adaptation=adaptation is not None,
            adaptation_details=adaptation.to_dict() if adaptation else None,
            options=options,
            recommended_option=next((o.option_type for o in options if o.is_recommended), "moderate"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get recommendation options: {e}")
        raise safe_internal_error(e, "nutrition")


def _generate_recommendation_options(
    current_tdee: int,
    goal: str,
    adherence_score: float,
    has_adaptation: bool,
) -> List[RecommendationOption]:
    """Generate 2-3 recommendation options based on user context."""
    options = []

    if goal in ["lose_fat", "lose_weight"]:
        # Aggressive option (only if high adherence and no adaptation)
        if adherence_score >= 0.8 and not has_adaptation:
            aggressive_cals = current_tdee - 750
            options.append(RecommendationOption(
                option_type="aggressive",
                calories=aggressive_cals,
                protein_g=int((aggressive_cals * 0.35) / 4),
                carbs_g=int((aggressive_cals * 0.35) / 4),
                fat_g=int((aggressive_cals * 0.30) / 9),
                expected_weekly_change_kg=-0.68,
                sustainability_rating="low",
                description="Faster results, requires strict adherence. Best for short-term pushes.",
                is_recommended=False,
            ))

        # Moderate option (always shown, usually recommended)
        moderate_cals = current_tdee - 500
        options.append(RecommendationOption(
            option_type="moderate",
            calories=moderate_cals,
            protein_g=int((moderate_cals * 0.30) / 4),
            carbs_g=int((moderate_cals * 0.40) / 4),
            fat_g=int((moderate_cals * 0.30) / 9),
            expected_weekly_change_kg=-0.45,
            sustainability_rating="medium",
            description="Balanced approach. Steady progress without extreme restriction.",
            is_recommended=not has_adaptation and adherence_score >= 0.6,
        ))

        # Conservative option (for low adherence or adaptation)
        if adherence_score < 0.7 or has_adaptation:
            conservative_cals = current_tdee - 250
            options.append(RecommendationOption(
                option_type="conservative",
                calories=conservative_cals,
                protein_g=int((conservative_cals * 0.30) / 4),
                carbs_g=int((conservative_cals * 0.40) / 4),
                fat_g=int((conservative_cals * 0.30) / 9),
                expected_weekly_change_kg=-0.23,
                sustainability_rating="high",
                description="Slower but more sustainable. Better for long-term success.",
                is_recommended=has_adaptation or adherence_score < 0.6,
            ))

    elif goal == "build_muscle":
        # Lean bulk
        lean_cals = current_tdee + 250
        options.append(RecommendationOption(
            option_type="lean_bulk",
            calories=lean_cals,
            protein_g=int((lean_cals * 0.30) / 4),
            carbs_g=int((lean_cals * 0.45) / 4),
            fat_g=int((lean_cals * 0.25) / 9),
            expected_weekly_change_kg=0.20,
            sustainability_rating="high",
            description="Minimize fat gain while building muscle. Slow and steady.",
            is_recommended=True,
        ))

        # Standard bulk
        standard_cals = current_tdee + 400
        options.append(RecommendationOption(
            option_type="standard_bulk",
            calories=standard_cals,
            protein_g=int((standard_cals * 0.28) / 4),
            carbs_g=int((standard_cals * 0.47) / 4),
            fat_g=int((standard_cals * 0.25) / 9),
            expected_weekly_change_kg=0.35,
            sustainability_rating="medium",
            description="Faster muscle gain, some fat gain expected.",
            is_recommended=False,
        ))

    else:  # maintain
        options.append(RecommendationOption(
            option_type="maintenance",
            calories=current_tdee,
            protein_g=int((current_tdee * 0.25) / 4),
            carbs_g=int((current_tdee * 0.45) / 4),
            fat_g=int((current_tdee * 0.30) / 9),
            expected_weekly_change_kg=0.0,
            sustainability_rating="high",
            description="Maintain current weight and body composition.",
            is_recommended=True,
        ))

    # Ensure at least one option is recommended
    if not any(o.is_recommended for o in options) and options:
        options[0].is_recommended = True

    return options


@router.post("/recommendations/{user_id}/select")
async def select_recommendation(user_id: str, request: SelectRecommendationRequest, current_user: dict = Depends(get_current_user)):
    """
    User selects a recommendation option to apply.

    This updates the user's nutrition targets to match the selected option.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    logger.info(f"User {user_id} selecting recommendation: {request.option_type}")

    try:
        # Get available options
        options_response = await get_recommendation_options(user_id, current_user=current_user)

        # Find selected option
        selected = None
        for opt in options_response.options:
            if opt.option_type == request.option_type:
                selected = opt
                break

        if not selected:
            raise HTTPException(
                status_code=404,
                detail=f"Option '{request.option_type}' not found. Available options: {[o.option_type for o in options_response.options]}"
            )

        db = get_supabase_db()

        # Update user's nutrition targets
        db.client.table("nutrition_preferences")\
            .update({
                "target_calories": selected.calories,
                "target_protein_g": selected.protein_g,
                "target_carbs_g": selected.carbs_g,
                "target_fat_g": selected.fat_g,
                "last_recalculated_at": datetime.utcnow().isoformat(),
            })\
            .eq("user_id", user_id)\
            .execute()

        # Log the decision for analytics
        await log_user_activity(
            user_id=user_id,
            action="recommendation_selected",
            endpoint="/api/v1/nutrition/recommendations/select",
            message=f"Selected {request.option_type} plan: {selected.calories} cal",
            metadata={
                "option_type": request.option_type,
                "calories": selected.calories,
                "protein_g": selected.protein_g,
                "carbs_g": selected.carbs_g,
                "fat_g": selected.fat_g,
                "expected_weekly_change_kg": selected.expected_weekly_change_kg,
            },
            status_code=200
        )

        return {
            "success": True,
            "message": f"Applied {request.option_type} plan",
            "applied": {
                "option_type": selected.option_type,
                "calories": selected.calories,
                "protein_g": selected.protein_g,
                "carbs_g": selected.carbs_g,
                "fat_g": selected.fat_g,
                "description": selected.description,
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to select recommendation: {e}")
        raise safe_internal_error(e, "nutrition")

