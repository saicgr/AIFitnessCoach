"""
Comprehensive Stats API - Aggregates all fitness statistics.

Provides endpoints for:
- Workout statistics (frequency, volume, total time, streaks)
- Achievements and badges
- Body measurements and progress
- Personal records (PRs)
- Nutrition statistics
- Progress graphs data
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.timezone_utils import resolve_timezone, get_user_today
from models.schemas import AchievementType, UserAchievement, PersonalRecord

router = APIRouter(prefix="/stats", tags=["stats"])
logger = get_logger(__name__)


# ============================================
# Response Models
# ============================================

class QuickStatsResponse(BaseModel):
    """Quick overview statistics."""
    total_workouts: int
    workouts_this_week: int
    workouts_this_month: int
    current_streak: int
    longest_streak: int
    total_time_minutes: int
    avg_workout_duration: int
    total_achievements: int
    total_prs: int


class WorkoutFrequencyData(BaseModel):
    """Weekly workout frequency for graphs."""
    week_start_date: str
    week_number: int
    workouts_count: int
    total_minutes: int


class VolumeProgressData(BaseModel):
    """Training volume over time."""
    date: str
    total_sets: int
    total_reps: int
    total_weight_kg: float


class WeightTrendData(BaseModel):
    """Weight tracking over time."""
    date: str
    weight_kg: float
    body_fat_percent: Optional[float]
    bmi: Optional[float]


class NutritionStatsResponse(BaseModel):
    """Nutrition statistics."""
    avg_daily_calories: int
    avg_daily_protein_g: float
    avg_daily_carbs_g: float
    avg_daily_fat_g: float
    avg_daily_water_ml: int
    days_tracked: int
    calorie_trend: List[Dict[str, Any]]


class BodyMeasurementsResponse(BaseModel):
    """Current body measurements."""
    weight_kg: Optional[float]
    body_fat_percent: Optional[float]
    chest_cm: Optional[float]
    waist_cm: Optional[float]
    hip_cm: Optional[float]
    bicep_left_cm: Optional[float]
    bicep_right_cm: Optional[float]
    thigh_left_cm: Optional[float]
    thigh_right_cm: Optional[float]
    measured_at: Optional[datetime]


class ComprehensiveStatsResponse(BaseModel):
    """Complete stats overview."""
    quick_stats: QuickStatsResponse
    recent_achievements: List[UserAchievement]
    top_prs: List[PersonalRecord]
    body_measurements: Optional[BodyMeasurementsResponse]


# ============================================
# Main Endpoints
# ============================================

@router.get("/overview/{user_id}", response_model=ComprehensiveStatsResponse)
async def get_comprehensive_stats(user_id: str, request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Get comprehensive stats overview for a user.
    Includes quick stats, achievements, PRs, and measurements.
    """
    logger.info(f"Getting comprehensive stats for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        # 1. Quick Stats
        quick_stats = await _get_quick_stats(user_id, db, user_tz)

        # 2. Recent Achievements (last 5)
        achievements_result = db.client.table("user_achievements") \
            .select("*, achievement_types(*)") \
            .eq("user_id", user_id) \
            .order("earned_at", desc=True) \
            .limit(5) \
            .execute()

        recent_achievements = [
            UserAchievement(
                id=a["id"],
                user_id=a["user_id"],
                achievement_id=a["achievement_id"],
                achievement_name=a["achievement_types"]["name"],
                achievement_icon=a["achievement_types"]["icon"],
                achievement_category=a["achievement_types"]["category"],
                earned_at=a["earned_at"],
                trigger_value=a.get("trigger_value"),
                trigger_details=a.get("trigger_details", {})
            )
            for a in achievements_result.data
        ]

        # 3. Top Personal Records (top 3)
        prs_result = db.client.table("personal_records") \
            .select("*") \
            .eq("user_id", user_id) \
            .order("achieved_at", desc=True) \
            .limit(3) \
            .execute()

        top_prs = [
            PersonalRecord(
                id=pr["id"],
                user_id=pr["user_id"],
                exercise_name=pr["exercise_name"],
                record_type=pr["record_type"],
                record_value=pr["record_value"],
                record_unit=pr["record_unit"],
                previous_value=pr.get("previous_value"),
                improvement_percentage=pr.get("improvement_percentage"),
                achieved_at=pr["achieved_at"]
            )
            for pr in prs_result.data
        ]

        # 4. Latest Body Measurements
        measurements = await _get_latest_body_measurements(user_id, db)

        return ComprehensiveStatsResponse(
            quick_stats=quick_stats,
            recent_achievements=recent_achievements,
            top_prs=top_prs,
            body_measurements=measurements
        )

    except Exception as e:
        logger.error(f"Failed to get comprehensive stats: {e}")
        raise safe_internal_error(e, "stats")


@router.get("/quick/{user_id}", response_model=QuickStatsResponse)
async def get_quick_stats(user_id: str, request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get quick overview statistics."""
    logger.info(f"Getting quick stats for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        return await _get_quick_stats(user_id, db, user_tz)

    except Exception as e:
        logger.error(f"Failed to get quick stats: {e}")
        raise safe_internal_error(e, "stats")


@router.get("/workout-frequency/{user_id}", response_model=List[WorkoutFrequencyData])
async def get_workout_frequency(user_id: str, request: Request, weeks: int = 12,
    current_user: dict = Depends(get_current_user),
):
    """
    Get workout frequency by week for graphing.
    Returns last N weeks of workout data.
    """
    logger.info(f"Getting workout frequency for user {user_id}, last {weeks} weeks")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today = date.fromisoformat(get_user_today(user_tz))
        cutoff_date = datetime.combine(today - timedelta(weeks=weeks), datetime.min.time())

        # Get workout logs
        result = db.client.table("workout_logs") \
            .select("completed_at, duration_minutes") \
            .eq("user_id", user_id) \
            .gte("completed_at", cutoff_date.isoformat()) \
            .execute()

        # Group by week
        weekly_data: Dict[str, Dict[str, Any]] = {}

        for log in result.data:
            completed_date = datetime.fromisoformat(log["completed_at"].replace("Z", "+00:00"))
            week_start = completed_date - timedelta(days=completed_date.weekday())
            week_key = week_start.strftime("%Y-%m-%d")

            if week_key not in weekly_data:
                weekly_data[week_key] = {
                    "week_start_date": week_key,
                    "week_number": week_start.isocalendar()[1],
                    "workouts_count": 0,
                    "total_minutes": 0
                }

            weekly_data[week_key]["workouts_count"] += 1
            weekly_data[week_key]["total_minutes"] += log.get("duration_minutes", 0)

        # Convert to list and sort
        frequency_data = sorted(
            [WorkoutFrequencyData(**data) for data in weekly_data.values()],
            key=lambda x: x.week_start_date
        )

        return frequency_data

    except Exception as e:
        logger.error(f"Failed to get workout frequency: {e}")
        raise safe_internal_error(e, "stats")


@router.get("/weight-trend/{user_id}", response_model=List[WeightTrendData])
async def get_weight_trend(user_id: str, request: Request, days: int = 90,
    current_user: dict = Depends(get_current_user),
):
    """
    Get weight tracking trend over time.
    Returns measurements from last N days.
    """
    logger.info(f"Getting weight trend for user {user_id}, last {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today = date.fromisoformat(get_user_today(user_tz))
        cutoff_date = datetime.combine(today - timedelta(days=days), datetime.min.time())

        result = db.client.table("body_measurements") \
            .select("measured_at, weight_kg, body_fat_percent, bmi") \
            .eq("user_id", user_id) \
            .gte("measured_at", cutoff_date.isoformat()) \
            .order("measured_at", desc=False) \
            .execute()

        return [
            WeightTrendData(
                date=m["measured_at"],
                weight_kg=m.get("weight_kg", 0),
                body_fat_percent=m.get("body_fat_percent"),
                bmi=m.get("bmi")
            )
            for m in result.data
        ]

    except Exception as e:
        logger.error(f"Failed to get weight trend: {e}")
        raise safe_internal_error(e, "stats")


@router.get("/nutrition/{user_id}", response_model=NutritionStatsResponse)
async def get_nutrition_stats(user_id: str, request: Request, days: int = 7,
    current_user: dict = Depends(get_current_user),
):
    """
    Get nutrition statistics (averages over last N days).
    """
    logger.info(f"Getting nutrition stats for user {user_id}, last {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today = date.fromisoformat(get_user_today(user_tz))
        cutoff_date = datetime.combine(today - timedelta(days=days), datetime.min.time())

        # Get food logs
        result = db.client.table("food_logs") \
            .select("logged_at, total_calories, protein_g, carbs_g, fat_g") \
            .eq("user_id", user_id) \
            .gte("logged_at", cutoff_date.isoformat()) \
            .execute()

        # Get hydration logs
        hydration_result = db.client.table("hydration_logs") \
            .select("logged_at, amount_ml") \
            .eq("user_id", user_id) \
            .gte("logged_at", cutoff_date.isoformat()) \
            .execute()

        # Calculate averages
        total_calories = sum(log.get("total_calories", 0) for log in result.data)
        total_protein = sum(log.get("protein_g", 0) for log in result.data)
        total_carbs = sum(log.get("carbs_g", 0) for log in result.data)
        total_fat = sum(log.get("fat_g", 0) for log in result.data)
        total_water = sum(log.get("amount_ml", 0) for log in hydration_result.data)

        days_tracked = len(result.data)

        # Build calorie trend
        calorie_trend = [
            {
                "date": log["logged_at"],
                "calories": log.get("total_calories", 0)
            }
            for log in result.data
        ]

        return NutritionStatsResponse(
            avg_daily_calories=int(total_calories / days_tracked) if days_tracked > 0 else 0,
            avg_daily_protein_g=round(total_protein / days_tracked, 1) if days_tracked > 0 else 0,
            avg_daily_carbs_g=round(total_carbs / days_tracked, 1) if days_tracked > 0 else 0,
            avg_daily_fat_g=round(total_fat / days_tracked, 1) if days_tracked > 0 else 0,
            avg_daily_water_ml=int(total_water / days) if days > 0 else 0,
            days_tracked=days_tracked,
            calorie_trend=calorie_trend
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition stats: {e}")
        raise safe_internal_error(e, "stats")


@router.get("/volume-progress/{user_id}", response_model=List[VolumeProgressData])
async def get_volume_progress(user_id: str, request: Request, days: int = 30,
    current_user: dict = Depends(get_current_user),
):
    """
    Get training volume progression over time.
    """
    logger.info(f"Getting volume progress for user {user_id}, last {days} days")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today = date.fromisoformat(get_user_today(user_tz))
        cutoff_date = datetime.combine(today - timedelta(days=days), datetime.min.time())

        # Get workout logs with performance data
        result = db.client.table("workout_logs") \
            .select("completed_at, exercises_performance") \
            .eq("user_id", user_id) \
            .gte("completed_at", cutoff_date.isoformat()) \
            .execute()

        # Aggregate volume by date
        daily_volume: Dict[str, Dict[str, Any]] = {}

        for log in result.data:
            completed_date = datetime.fromisoformat(
                log["completed_at"].replace("Z", "+00:00")
            ).strftime("%Y-%m-%d")

            if completed_date not in daily_volume:
                daily_volume[completed_date] = {
                    "date": completed_date,
                    "total_sets": 0,
                    "total_reps": 0,
                    "total_weight_kg": 0
                }

            # Sum up from exercises_performance JSON
            exercises = log.get("exercises_performance", [])
            for exercise in exercises:
                for set_data in exercise.get("sets", []):
                    daily_volume[completed_date]["total_sets"] += 1
                    daily_volume[completed_date]["total_reps"] += set_data.get("reps", 0)
                    daily_volume[completed_date]["total_weight_kg"] += set_data.get("weight_kg", 0)

        # Convert to list and sort
        volume_data = sorted(
            [VolumeProgressData(**data) for data in daily_volume.values()],
            key=lambda x: x.date
        )

        return volume_data

    except Exception as e:
        logger.error(f"Failed to get volume progress: {e}")
        raise safe_internal_error(e, "stats")


# ============================================
# Helper Functions
# ============================================

async def _get_quick_stats(user_id: str, db, user_tz: str) -> QuickStatsResponse:
    """Calculate quick overview statistics."""

    # Total workouts
    total_workouts_result = db.client.table("workout_logs") \
        .select("id", count="exact") \
        .eq("user_id", user_id) \
        .execute()
    total_workouts = total_workouts_result.count or 0

    # Workouts this week
    today = date.fromisoformat(get_user_today(user_tz))
    week_start = datetime.combine(today - timedelta(days=today.weekday()), datetime.min.time())
    week_workouts_result = db.client.table("workout_logs") \
        .select("id", count="exact") \
        .eq("user_id", user_id) \
        .gte("completed_at", week_start.isoformat()) \
        .execute()
    workouts_this_week = week_workouts_result.count or 0

    # Workouts this month
    month_start = datetime.combine(today.replace(day=1), datetime.min.time())
    month_workouts_result = db.client.table("workout_logs") \
        .select("id", count="exact") \
        .eq("user_id", user_id) \
        .gte("completed_at", month_start.isoformat()) \
        .execute()
    workouts_this_month = month_workouts_result.count or 0

    # Get streak data
    streak_result = db.client.table("user_streaks") \
        .select("*") \
        .eq("user_id", user_id) \
        .eq("streak_type", "workout") \
        .execute()

    current_streak = 0
    longest_streak = 0
    if streak_result.data:
        current_streak = streak_result.data[0].get("current_streak", 0)
        longest_streak = streak_result.data[0].get("longest_streak", 0)

    # Total time and average duration
    duration_result = db.client.table("workout_logs") \
        .select("duration_minutes") \
        .eq("user_id", user_id) \
        .execute()

    total_time = sum(log.get("duration_minutes", 0) for log in duration_result.data)
    avg_duration = int(total_time / total_workouts) if total_workouts > 0 else 0

    # Total achievements
    achievements_result = db.client.table("user_achievements") \
        .select("id", count="exact") \
        .eq("user_id", user_id) \
        .execute()
    total_achievements = achievements_result.count or 0

    # Total PRs
    prs_result = db.client.table("personal_records") \
        .select("id", count="exact") \
        .eq("user_id", user_id) \
        .execute()
    total_prs = prs_result.count or 0

    return QuickStatsResponse(
        total_workouts=total_workouts,
        workouts_this_week=workouts_this_week,
        workouts_this_month=workouts_this_month,
        current_streak=current_streak,
        longest_streak=longest_streak,
        total_time_minutes=total_time,
        avg_workout_duration=avg_duration,
        total_achievements=total_achievements,
        total_prs=total_prs
    )


async def _get_latest_body_measurements(user_id: str, db) -> Optional[BodyMeasurementsResponse]:
    """Get the most recent body measurements."""

    result = db.client.table("body_measurements") \
        .select("*") \
        .eq("user_id", user_id) \
        .order("measured_at", desc=True) \
        .limit(1) \
        .execute()

    if not result.data:
        return None

    m = result.data[0]
    return BodyMeasurementsResponse(
        weight_kg=m.get("weight_kg"),
        body_fat_percent=m.get("body_fat_percent"),
        chest_cm=m.get("chest_cm"),
        waist_cm=m.get("waist_cm"),
        hip_cm=m.get("hip_cm"),
        bicep_left_cm=m.get("bicep_left_cm"),
        bicep_right_cm=m.get("bicep_right_cm"),
        thigh_left_cm=m.get("thigh_left_cm"),
        thigh_right_cm=m.get("thigh_right_cm"),
        measured_at=m.get("measured_at")
    )
