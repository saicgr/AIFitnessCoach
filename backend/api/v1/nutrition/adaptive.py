"""Adaptive TDEE calculation endpoints."""
from core.db import get_supabase_db
from datetime import datetime, timedelta
from typing import Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger

from api.v1.nutrition.models import AdaptiveCalculationResponse

router = APIRouter()
logger = get_logger(__name__)

@router.get("/adaptive/{user_id}", response_model=Optional[AdaptiveCalculationResponse])
async def get_adaptive_calculation(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get the latest adaptive TDEE calculation for a user.
    """
    logger.info(f"Getting adaptive calculation for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("adaptive_nutrition_calculations")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(1)\
            .maybe_single()\
            .execute()

        if not result.data:
            return None

        data = result.data
        return AdaptiveCalculationResponse(
            id=data["id"],
            user_id=data["user_id"],
            calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
            period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
            period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
            avg_daily_intake=data.get("avg_daily_intake", 0),
            start_trend_weight_kg=float(data["start_trend_weight_kg"]) if data.get("start_trend_weight_kg") else None,
            end_trend_weight_kg=float(data["end_trend_weight_kg"]) if data.get("end_trend_weight_kg") else None,
            calculated_tdee=data.get("calculated_tdee", 0),
            data_quality_score=float(data.get("data_quality_score", 0)),
            confidence_level=data.get("confidence_level", "low"),
            days_logged=data.get("days_logged", 0),
            weight_entries=data.get("weight_entries", 0),
        )

    except Exception as e:
        logger.error(f"Failed to get adaptive calculation: {e}")
        raise safe_internal_error(e, "nutrition")


@router.post("/adaptive/{user_id}/calculate", response_model=AdaptiveCalculationResponse)
async def calculate_adaptive_tdee(
    request: Request,
    user_id: str,
    days: int = Query(14, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate adaptive TDEE based on food intake and weight changes.

    Formula: TDEE = Calories In - (Weight Change * 7700 kcal/kg)

    Requires at least 6 days of food logs and 2 weight entries.
    """
    logger.info(f"Calculating adaptive TDEE for user {user_id} over {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        to_date_str = get_user_today(user_tz)
        from_date_obj = datetime.strptime(to_date_str, "%Y-%m-%d") - timedelta(days=days)
        from_date_str = from_date_obj.strftime("%Y-%m-%d")

        # Get food logs for the period
        food_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, protein_g, carbs_g, fat_g")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .execute()

        food_logs = food_result.data or []

        # Get weight logs for the period
        weight_result = db.client.table("weight_logs")\
            .select("weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .order("logged_at", desc=False)\
            .execute()

        weight_logs = weight_result.data or []

        # Check minimum data requirements
        days_logged = len(set(
            datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            for log in food_logs
        ))
        weight_entries = len(weight_logs)

        if days_logged < 6 or weight_entries < 2:
            # Not enough data, return placeholder calculation
            quality_score = min(days_logged / 6, weight_entries / 2) * 0.5

            calc_data = {
                "user_id": user_id,
                "calculated_at": datetime.utcnow().isoformat(),
                "period_start": from_date_str,
                "period_end": to_date_str,
                "avg_daily_intake": 0,
                "calculated_tdee": 0,
                "data_quality_score": quality_score,
                "confidence_level": "low",
                "days_logged": days_logged,
                "weight_entries": weight_entries,
            }

            try:
                result = db.client.table("adaptive_nutrition_calculations")\
                    .insert(calc_data)\
                    .execute()
                if result.data:
                    data = result.data[0]
                    return AdaptiveCalculationResponse(
                        id=data["id"],
                        user_id=data["user_id"],
                        calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
                        period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
                        period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
                        avg_daily_intake=0,
                        calculated_tdee=0,
                        data_quality_score=quality_score,
                        confidence_level="low",
                        days_logged=days_logged,
                        weight_entries=weight_entries,
                    )
            except Exception as insert_err:
                logger.warning(f"Failed to persist adaptive calculation (non-critical): {insert_err}")

            # Return response without persisted ID if insert failed
            return AdaptiveCalculationResponse(
                id=str(uuid.uuid4()),
                user_id=user_id,
                calculated_at=datetime.utcnow(),
                period_start=datetime.fromisoformat(from_date_str),
                period_end=datetime.fromisoformat(to_date_str),
                avg_daily_intake=0,
                calculated_tdee=0,
                data_quality_score=quality_score,
                confidence_level="low",
                days_logged=days_logged,
                weight_entries=weight_entries,
            )

        # Calculate average daily calorie intake
        total_calories = 0
        for log in food_logs:
            total_calories += log.get("total_calories", 0) or 0

        avg_daily_intake = int(total_calories / days_logged) if days_logged > 0 else 0

        # Calculate weight trend
        start_weights = [float(log["weight_kg"]) for log in weight_logs[:min(3, len(weight_logs))]]
        end_weights = [float(log["weight_kg"]) for log in weight_logs[-min(3, len(weight_logs)):]]

        start_trend = sum(start_weights) / len(start_weights) if start_weights else None
        end_trend = sum(end_weights) / len(end_weights) if end_weights else None

        if start_trend and end_trend:
            weight_change = end_trend - start_trend
            # 7700 kcal = 1 kg of body weight
            caloric_difference = int(weight_change * 7700 / days)
            calculated_tdee = avg_daily_intake - caloric_difference
        else:
            calculated_tdee = avg_daily_intake

        # Calculate quality score (0-1)
        quality_score = min(1.0, (
            (min(days_logged, 14) / 14) * 0.5 +
            (min(weight_entries, 7) / 7) * 0.5
        ))

        confidence = "low" if quality_score < 0.4 else "medium" if quality_score < 0.7 else "high"

        # Save calculation
        calc_data = {
            "user_id": user_id,
            "calculated_at": datetime.utcnow().isoformat(),
            "period_start": from_date_str,
            "period_end": to_date_str,
            "avg_daily_intake": avg_daily_intake,
            "start_trend_weight_kg": start_trend,
            "end_trend_weight_kg": end_trend,
            "calculated_tdee": max(1000, calculated_tdee),  # Minimum TDEE
            "data_quality_score": quality_score,
            "confidence_level": confidence,
            "days_logged": days_logged,
            "weight_entries": weight_entries,
        }

        try:
            result = db.client.table("adaptive_nutrition_calculations")\
                .insert(calc_data)\
                .execute()
            if result.data:
                data = result.data[0]
                return AdaptiveCalculationResponse(
                    id=data["id"],
                    user_id=data["user_id"],
                    calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
                    period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
                    period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
                    avg_daily_intake=avg_daily_intake,
                    start_trend_weight_kg=start_trend,
                    end_trend_weight_kg=end_trend,
                    calculated_tdee=max(1000, calculated_tdee),
                    data_quality_score=quality_score,
                    confidence_level=confidence,
                    days_logged=days_logged,
                    weight_entries=weight_entries,
                )
        except Exception as insert_err:
            logger.warning(f"Failed to persist adaptive calculation (non-critical): {insert_err}")

        # Return response without persisted ID if insert failed
        return AdaptiveCalculationResponse(
            id=str(uuid.uuid4()),
            user_id=user_id,
            calculated_at=datetime.utcnow(),
            period_start=datetime.fromisoformat(from_date_str),
            period_end=datetime.fromisoformat(to_date_str),
            avg_daily_intake=avg_daily_intake,
            start_trend_weight_kg=start_trend,
            end_trend_weight_kg=end_trend,
            calculated_tdee=max(1000, calculated_tdee),
            data_quality_score=quality_score,
            confidence_level=confidence,
            days_logged=days_logged,
            weight_entries=weight_entries,
        )

    except Exception as e:
        logger.error(f"Failed to calculate adaptive TDEE: {e}")
        raise safe_internal_error(e, "nutrition")


