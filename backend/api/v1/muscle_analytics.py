"""
Muscle Analytics API - Muscle-Level Insights Endpoints.

Provides endpoints for:
- Muscle heatmap data for body diagram visualization
- Training frequency per muscle group
- Muscle balance analysis (push/pull, upper/lower ratios)
- Exercises for specific muscle groups
- Muscle training history over time
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from pydantic import BaseModel, Field
from enum import Enum

from core.supabase_db import get_supabase_db
from core.logger import get_logger

router = APIRouter(prefix="/muscle-analytics", tags=["Muscle Analytics"])
logger = get_logger(__name__)


# ============================================
# Enums
# ============================================

class TimeRange(str, Enum):
    """Time range options for muscle analytics."""
    ONE_WEEK = "1_week"
    TWO_WEEKS = "2_weeks"
    FOUR_WEEKS = "4_weeks"
    EIGHT_WEEKS = "8_weeks"
    TWELVE_WEEKS = "12_weeks"


class ViewType(str, Enum):
    """Types of muscle analytics views."""
    HEATMAP = "heatmap"
    FREQUENCY = "frequency"
    BALANCE = "balance"
    MUSCLE_DETAIL = "muscle_detail"
    TRENDS = "trends"


# ============================================
# Response Models
# ============================================

class MuscleHeatmapItem(BaseModel):
    """Single muscle group heatmap data."""
    muscle_group: str
    intensity: float  # 0.0 to 1.0 for heat coloring
    intensity_score: int  # 0 to 100
    sets_count: int
    volume_kg: float
    workout_count: int
    last_trained: Optional[str] = None
    days_since_training: Optional[int] = None
    color: str  # 'high', 'medium', 'low', 'none'
    hex_color: str


class MuscleHeatmapResponse(BaseModel):
    """Response for muscle heatmap endpoint."""
    user_id: str
    time_range: str
    period_days: int
    muscles: List[MuscleHeatmapItem]
    most_trained: str
    least_trained: str
    total_sets: int
    total_volume_kg: float
    max_volume_kg: float


class MuscleFrequencyItem(BaseModel):
    """Training frequency for a muscle group."""
    muscle_group: str
    workout_count_last_7_days: int
    workout_count_last_30_days: int
    total_workout_count: int
    weekly_frequency: float  # Average sessions per week
    total_volume_kg: float
    avg_days_between_training: Optional[float] = None
    last_trained_date: Optional[str] = None
    days_since_last_training: Optional[int] = None
    recommendation: str  # 'optimal', 'undertrained', 'overtrained'


class MuscleFrequencyResponse(BaseModel):
    """Response for muscle training frequency."""
    user_id: str
    frequencies: List[MuscleFrequencyItem]
    avg_weekly_workouts: float
    undertrained_count: int
    overtrained_count: int


class BalanceRatio(BaseModel):
    """Balance ratio between muscle categories."""
    category: str  # 'push_pull', 'upper_lower', 'chest_back', 'quad_hamstring'
    side1: str
    side2: str
    side1_volume_kg: float
    side2_volume_kg: float
    side1_percent: float
    side2_percent: float
    ratio: float
    status: str  # 'balanced', 'imbalanced', 'severe_imbalance'
    recommendation: Optional[str] = None


class MuscleBalanceResponse(BaseModel):
    """Response for muscle balance analysis."""
    user_id: str
    ratios: List[BalanceRatio]
    imbalance_count: int
    overall_status: str  # 'balanced', 'minor_imbalances', 'significant_imbalances'
    recommendations: List[str]


class MuscleExerciseItem(BaseModel):
    """Exercise performed for a muscle group."""
    exercise_name: str
    times_performed: int
    total_volume_kg: float
    max_weight_kg: float
    contribution: float  # Percentage contribution to muscle training
    last_performed: Optional[str] = None


class MuscleExercisesResponse(BaseModel):
    """Response for exercises targeting a muscle group."""
    user_id: str
    muscle_group: str
    exercises: List[MuscleExerciseItem]
    total_exercises: int
    total_volume_kg: float


class MuscleHistoryDataPoint(BaseModel):
    """Weekly muscle training data point."""
    week_start: str
    week_number: int
    year: int
    sets_count: int
    volume_kg: float
    exercise_count: int
    max_weight_kg: float


class MuscleHistoryResponse(BaseModel):
    """Response for muscle training history."""
    user_id: str
    muscle_group: str
    time_range: str
    data_points: List[MuscleHistoryDataPoint]
    avg_weekly_sets: float
    avg_weekly_volume: float
    volume_trend: str  # 'improving', 'declining', 'stable'
    volume_change: float  # Percentage change


class ViewLogRequest(BaseModel):
    """Request to log muscle analytics view."""
    user_id: str
    view_type: ViewType
    muscle_group: Optional[str] = None
    session_duration_seconds: Optional[int] = None


# ============================================
# Helper Functions
# ============================================

def get_days_for_time_range(time_range: TimeRange) -> int:
    """Convert time range enum to days."""
    mapping = {
        TimeRange.ONE_WEEK: 7,
        TimeRange.TWO_WEEKS: 14,
        TimeRange.FOUR_WEEKS: 28,
        TimeRange.EIGHT_WEEKS: 56,
        TimeRange.TWELVE_WEEKS: 84,
    }
    return mapping.get(time_range, 28)


def get_intensity_color(intensity: float) -> tuple:
    """Get color based on intensity (0.0 to 1.0)."""
    if intensity >= 0.8:
        return "high", "#FF4444"
    elif intensity >= 0.5:
        return "medium", "#FF8844"
    elif intensity >= 0.2:
        return "low", "#FFCC44"
    else:
        return "none", "#88CC88"


def get_frequency_recommendation(weekly_freq: float) -> str:
    """Get training frequency recommendation."""
    if weekly_freq < 1:
        return "undertrained"
    elif weekly_freq > 4:
        return "overtrained"
    else:
        return "optimal"


def get_balance_status(ratio: float, ideal_min: float, ideal_max: float) -> tuple:
    """Get balance status based on ratio."""
    if ratio == 0:
        return "insufficient_data", None
    elif ideal_min <= ratio <= ideal_max:
        return "balanced", None
    elif ratio > ideal_max * 1.5 or ratio < ideal_min * 0.5:
        return "severe_imbalance", f"Consider balancing training between muscle groups"
    else:
        return "imbalanced", f"Slight imbalance detected"


# ============================================
# Endpoints
# ============================================

@router.get("/heatmap", response_model=MuscleHeatmapResponse)
async def get_muscle_heatmap_data(
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.FOUR_WEEKS, description="Time range for heatmap"),
):
    """
    Get muscle heatmap data for body diagram visualization.

    Returns intensity scores and colors for each muscle group
    based on training volume in the specified time period.
    """
    try:
        db = get_supabase_db()
        days_back = get_days_for_time_range(time_range)

        logger.info(f"Getting muscle heatmap for user {user_id}, range: {time_range.value}")

        # Try to use the database function first
        try:
            result = db.client.rpc(
                "get_muscle_heatmap_data",
                {"p_user_id": user_id, "p_days_back": days_back}
            ).execute()

            if result.data:
                data = result.data
                muscles = []
                for m in data.get("muscles", []):
                    intensity = m.get("intensity_score", 0) / 100
                    color, hex_color = get_intensity_color(intensity)
                    muscles.append(MuscleHeatmapItem(
                        muscle_group=m.get("muscle_group", ""),
                        intensity=intensity,
                        intensity_score=m.get("intensity_score", 0),
                        sets_count=m.get("workout_count", 0),
                        volume_kg=float(m.get("total_volume_kg", 0) or 0),
                        workout_count=m.get("workout_count", 0),
                        last_trained=m.get("last_trained"),
                        days_since_training=m.get("days_since_training"),
                        color=m.get("color", color),
                        hex_color=m.get("hex_color", hex_color),
                    ))

                sorted_muscles = sorted(muscles, key=lambda x: x.volume_kg, reverse=True)
                most_trained = sorted_muscles[0].muscle_group if sorted_muscles else ""
                least_trained = sorted_muscles[-1].muscle_group if sorted_muscles else ""

                return MuscleHeatmapResponse(
                    user_id=user_id,
                    time_range=time_range.value,
                    period_days=days_back,
                    muscles=muscles,
                    most_trained=most_trained,
                    least_trained=least_trained,
                    total_sets=sum(m.sets_count for m in muscles),
                    total_volume_kg=round(sum(m.volume_kg for m in muscles), 2),
                    max_volume_kg=float(data.get("max_volume_kg", 0) or 0),
                )

        except Exception as rpc_error:
            logger.warning(f"RPC failed, using fallback query: {rpc_error}")

        # Fallback: Query muscle_training_frequency view
        query = db.client.from_("muscle_training_frequency") \
            .select("*") \
            .eq("user_id", user_id)

        result = query.execute()
        data = result.data or []

        # Calculate max volume for normalization
        volumes = [float(r.get("total_volume_last_30_days_kg", 0) or 0) for r in data]
        max_volume = max(volumes) if volumes else 1

        muscles = []
        for row in data:
            volume = float(row.get("total_volume_last_30_days_kg", 0) or 0)
            intensity = volume / max_volume if max_volume > 0 else 0
            color, hex_color = get_intensity_color(intensity)

            muscles.append(MuscleHeatmapItem(
                muscle_group=row.get("muscle_group", ""),
                intensity=intensity,
                intensity_score=int(intensity * 100),
                sets_count=row.get("workout_count_last_30_days", 0),
                volume_kg=round(volume, 2),
                workout_count=row.get("workout_count_last_30_days", 0),
                last_trained=row.get("last_workout_date"),
                days_since_training=row.get("days_since_last_training"),
                color=color,
                hex_color=hex_color,
            ))

        sorted_muscles = sorted(muscles, key=lambda x: x.volume_kg, reverse=True)
        most_trained = sorted_muscles[0].muscle_group if sorted_muscles else ""
        least_trained = sorted_muscles[-1].muscle_group if sorted_muscles else ""

        return MuscleHeatmapResponse(
            user_id=user_id,
            time_range=time_range.value,
            period_days=days_back,
            muscles=muscles,
            most_trained=most_trained,
            least_trained=least_trained,
            total_sets=sum(m.sets_count for m in muscles),
            total_volume_kg=round(sum(m.volume_kg for m in muscles), 2),
            max_volume_kg=round(max_volume, 2),
        )

    except Exception as e:
        logger.error(f"Error getting muscle heatmap: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get muscle heatmap: {str(e)}")


@router.get("/frequency", response_model=MuscleFrequencyResponse)
async def get_muscle_training_frequency(
    user_id: str = Query(..., description="User ID"),
):
    """
    Get training frequency for each muscle group.

    Shows how often each muscle is trained with recommendations
    for optimal training frequency.
    """
    try:
        db = get_supabase_db()

        logger.info(f"Getting muscle frequency for user {user_id}")

        # Query muscle_training_frequency view
        query = db.client.from_("muscle_training_frequency") \
            .select("*") \
            .eq("user_id", user_id)

        result = query.execute()
        data = result.data or []

        frequencies = []
        undertrained_count = 0
        overtrained_count = 0

        for row in data:
            # Calculate weekly frequency (sessions per week over 4 weeks)
            sessions_30_days = row.get("workout_count_last_30_days", 0)
            weekly_freq = sessions_30_days / 4 if sessions_30_days else 0
            recommendation = get_frequency_recommendation(weekly_freq)

            if recommendation == "undertrained":
                undertrained_count += 1
            elif recommendation == "overtrained":
                overtrained_count += 1

            frequencies.append(MuscleFrequencyItem(
                muscle_group=row.get("muscle_group", ""),
                workout_count_last_7_days=row.get("workout_count_last_7_days", 0),
                workout_count_last_30_days=sessions_30_days,
                total_workout_count=row.get("total_workout_count", 0),
                weekly_frequency=round(weekly_freq, 1),
                total_volume_kg=float(row.get("total_volume_all_time_kg", 0) or 0),
                avg_days_between_training=row.get("avg_days_between_training"),
                last_trained_date=row.get("last_workout_date"),
                days_since_last_training=row.get("days_since_last_training"),
                recommendation=recommendation,
            ))

        # Calculate average weekly workouts
        total_weekly_sessions = sum(f.weekly_frequency for f in frequencies)
        avg_weekly = total_weekly_sessions / len(frequencies) if frequencies else 0

        return MuscleFrequencyResponse(
            user_id=user_id,
            frequencies=frequencies,
            avg_weekly_workouts=round(avg_weekly, 1),
            undertrained_count=undertrained_count,
            overtrained_count=overtrained_count,
        )

    except Exception as e:
        logger.error(f"Error getting muscle frequency: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get muscle frequency: {str(e)}")


@router.get("/balance", response_model=MuscleBalanceResponse)
async def get_muscle_balance(
    user_id: str = Query(..., description="User ID"),
):
    """
    Get muscle balance analysis.

    Analyzes push/pull ratio, upper/lower ratio, and other
    antagonist muscle pair balances.
    """
    try:
        db = get_supabase_db()

        logger.info(f"Getting muscle balance for user {user_id}")

        # Query muscle_balance_analysis view
        query = db.client.from_("muscle_balance_analysis") \
            .select("*") \
            .eq("user_id", user_id) \
            .limit(1)

        result = query.execute()
        data = result.data[0] if result.data else {}

        ratios = []
        recommendations = []

        if data:
            # Push/Pull Ratio
            push_vol = float(data.get("push_volume_kg", 0) or 0)
            pull_vol = float(data.get("pull_volume_kg", 0) or 0)
            total_pp = push_vol + pull_vol
            push_pct = (push_vol / total_pp * 100) if total_pp > 0 else 50
            pull_pct = 100 - push_pct
            pp_ratio = float(data.get("push_pull_ratio", 0) or 0)
            pp_status, pp_rec = get_balance_status(pp_ratio, 0.8, 1.2)

            ratios.append(BalanceRatio(
                category="push_pull",
                side1="Push",
                side2="Pull",
                side1_volume_kg=round(push_vol, 2),
                side2_volume_kg=round(pull_vol, 2),
                side1_percent=round(push_pct, 1),
                side2_percent=round(pull_pct, 1),
                ratio=round(pp_ratio, 2),
                status=pp_status,
                recommendation="Add more pulling exercises (rows, pulldowns)" if push_pct > 55 else ("Add more pushing exercises" if pull_pct > 55 else None),
            ))

            if pp_status in ["imbalanced", "severe_imbalance"]:
                if push_pct > 55:
                    recommendations.append("Add more pulling exercises to balance push/pull ratio")
                else:
                    recommendations.append("Add more pushing exercises to balance push/pull ratio")

            # Upper/Lower Ratio
            upper_vol = float(data.get("upper_volume_kg", 0) or 0)
            lower_vol = float(data.get("lower_volume_kg", 0) or 0)
            total_ul = upper_vol + lower_vol
            upper_pct = (upper_vol / total_ul * 100) if total_ul > 0 else 50
            lower_pct = 100 - upper_pct
            ul_ratio = float(data.get("upper_lower_ratio", 0) or 0)
            ul_status, ul_rec = get_balance_status(ul_ratio, 0.8, 1.5)

            ratios.append(BalanceRatio(
                category="upper_lower",
                side1="Upper Body",
                side2="Lower Body",
                side1_volume_kg=round(upper_vol, 2),
                side2_volume_kg=round(lower_vol, 2),
                side1_percent=round(upper_pct, 1),
                side2_percent=round(lower_pct, 1),
                ratio=round(ul_ratio, 2),
                status=ul_status,
                recommendation="Add more lower body exercises" if upper_pct > 60 else ("Add more upper body exercises" if lower_pct > 60 else None),
            ))

            if ul_status in ["imbalanced", "severe_imbalance"]:
                if upper_pct > 60:
                    recommendations.append("Add more lower body exercises (squats, deadlifts, lunges)")
                else:
                    recommendations.append("Add more upper body exercises")

            # Chest/Back Ratio
            chest_vol = float(data.get("chest_volume_kg", 0) or 0)
            back_vol = float(data.get("back_volume_kg", 0) or 0)
            total_cb = chest_vol + back_vol
            chest_pct = (chest_vol / total_cb * 100) if total_cb > 0 else 50
            back_pct = 100 - chest_pct
            cb_ratio = float(data.get("chest_back_ratio", 0) or 0)
            cb_status, _ = get_balance_status(cb_ratio, 0.7, 1.0)

            ratios.append(BalanceRatio(
                category="chest_back",
                side1="Chest",
                side2="Back",
                side1_volume_kg=round(chest_vol, 2),
                side2_volume_kg=round(back_vol, 2),
                side1_percent=round(chest_pct, 1),
                side2_percent=round(back_pct, 1),
                ratio=round(cb_ratio, 2),
                status=cb_status,
                recommendation="Add more back exercises for posture" if chest_pct > 55 else None,
            ))

            # Quad/Hamstring Ratio
            quad_vol = float(data.get("quad_volume_kg", 0) or 0)
            ham_vol = float(data.get("hamstring_volume_kg", 0) or 0)
            total_qh = quad_vol + ham_vol
            quad_pct = (quad_vol / total_qh * 100) if total_qh > 0 else 50
            ham_pct = 100 - quad_pct
            qh_ratio = float(data.get("quad_hamstring_ratio", 0) or 0)
            qh_status, _ = get_balance_status(qh_ratio, 1.5, 2.5)

            ratios.append(BalanceRatio(
                category="quad_hamstring",
                side1="Quadriceps",
                side2="Hamstrings",
                side1_volume_kg=round(quad_vol, 2),
                side2_volume_kg=round(ham_vol, 2),
                side1_percent=round(quad_pct, 1),
                side2_percent=round(ham_pct, 1),
                ratio=round(qh_ratio, 2),
                status=qh_status,
                recommendation="Add more hamstring exercises (RDLs, leg curls)" if qh_ratio > 3 else None,
            ))

        # Determine overall status
        imbalance_count = sum(1 for r in ratios if r.status in ["imbalanced", "severe_imbalance"])
        if imbalance_count == 0:
            overall_status = "balanced"
        elif imbalance_count <= 1:
            overall_status = "minor_imbalances"
        else:
            overall_status = "significant_imbalances"

        return MuscleBalanceResponse(
            user_id=user_id,
            ratios=ratios,
            imbalance_count=imbalance_count,
            overall_status=overall_status,
            recommendations=recommendations,
        )

    except Exception as e:
        logger.error(f"Error getting muscle balance: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get muscle balance: {str(e)}")


@router.get("/muscle/{muscle_group}/exercises", response_model=MuscleExercisesResponse)
async def get_exercises_for_muscle(
    muscle_group: str,
    user_id: str = Query(..., description="User ID"),
):
    """
    Get all exercises performed for a specific muscle group.

    Shows which exercises target this muscle with volume
    and frequency statistics.
    """
    try:
        db = get_supabase_db()

        logger.info(f"Getting exercises for muscle {muscle_group}, user {user_id}")

        # Try RPC first
        try:
            result = db.client.rpc(
                "get_exercises_for_muscle",
                {"p_user_id": user_id, "p_muscle_group": muscle_group}
            ).execute()

            if result.data:
                data = result.data
                exercises_data = data.get("exercises", [])
                total_vol = sum(float(e.get("total_volume_kg", 0) or 0) for e in exercises_data)

                exercises = []
                for ex in exercises_data:
                    ex_vol = float(ex.get("total_volume_kg", 0) or 0)
                    contribution = (ex_vol / total_vol * 100) if total_vol > 0 else 0
                    exercises.append(MuscleExerciseItem(
                        exercise_name=ex.get("exercise_name", ""),
                        times_performed=ex.get("times_performed", 0),
                        total_volume_kg=round(ex_vol, 2),
                        max_weight_kg=float(ex.get("max_weight_kg", 0) or 0),
                        contribution=round(contribution, 1),
                        last_performed=ex.get("last_performed"),
                    ))

                return MuscleExercisesResponse(
                    user_id=user_id,
                    muscle_group=muscle_group,
                    exercises=exercises,
                    total_exercises=len(exercises),
                    total_volume_kg=round(total_vol, 2),
                )

        except Exception as rpc_error:
            logger.warning(f"RPC failed, using fallback: {rpc_error}")

        # Fallback query
        query = db.client.from_("exercise_workout_history") \
            .select("exercise_name, total_volume_kg, max_weight_kg, workout_date") \
            .eq("user_id", user_id) \
            .ilike("muscle_group", muscle_group.lower())

        result = query.execute()
        data = result.data or []

        # Aggregate
        exercise_stats = {}
        for row in data:
            name = row.get("exercise_name", "")
            if name not in exercise_stats:
                exercise_stats[name] = {
                    "times_performed": 0,
                    "total_volume_kg": 0,
                    "max_weight_kg": 0,
                    "last_performed": None,
                }
            exercise_stats[name]["times_performed"] += 1
            exercise_stats[name]["total_volume_kg"] += float(row.get("total_volume_kg", 0) or 0)
            weight = float(row.get("max_weight_kg", 0) or 0)
            if weight > exercise_stats[name]["max_weight_kg"]:
                exercise_stats[name]["max_weight_kg"] = weight
            date_str = row.get("workout_date")
            if date_str and (not exercise_stats[name]["last_performed"] or date_str > exercise_stats[name]["last_performed"]):
                exercise_stats[name]["last_performed"] = date_str

        total_vol = sum(e["total_volume_kg"] for e in exercise_stats.values())

        exercises = []
        for name, stats in sorted(exercise_stats.items(), key=lambda x: x[1]["times_performed"], reverse=True):
            contribution = (stats["total_volume_kg"] / total_vol * 100) if total_vol > 0 else 0
            exercises.append(MuscleExerciseItem(
                exercise_name=name,
                times_performed=stats["times_performed"],
                total_volume_kg=round(stats["total_volume_kg"], 2),
                max_weight_kg=round(stats["max_weight_kg"], 2),
                contribution=round(contribution, 1),
                last_performed=stats["last_performed"],
            ))

        return MuscleExercisesResponse(
            user_id=user_id,
            muscle_group=muscle_group,
            exercises=exercises,
            total_exercises=len(exercises),
            total_volume_kg=round(total_vol, 2),
        )

    except Exception as e:
        logger.error(f"Error getting exercises for muscle: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get exercises: {str(e)}")


@router.get("/muscle/{muscle_group}/history", response_model=MuscleHistoryResponse)
async def get_muscle_history(
    muscle_group: str,
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.TWELVE_WEEKS, description="Time range for history"),
):
    """
    Get historical training data for a specific muscle group.

    Shows weekly training volume trends over time.
    """
    try:
        db = get_supabase_db()
        days_back = get_days_for_time_range(time_range)
        start_date = (date.today() - timedelta(days=days_back)).isoformat()

        logger.info(f"Getting muscle history for {muscle_group}, user {user_id}")

        # Query weekly volume data
        query = db.client.from_("muscle_group_weekly_volume") \
            .select("*") \
            .eq("user_id", user_id) \
            .ilike("muscle_group", muscle_group.lower()) \
            .gte("week_start", start_date) \
            .order("week_start", desc=False)

        result = query.execute()
        data = result.data or []

        data_points = []
        for row in data:
            data_points.append(MuscleHistoryDataPoint(
                week_start=row.get("week_start", ""),
                week_number=row.get("week_number", 0),
                year=row.get("year", 0),
                sets_count=row.get("total_sets", 0),
                volume_kg=float(row.get("total_volume_kg", 0) or 0),
                exercise_count=row.get("exercise_count", 0),
                max_weight_kg=float(row.get("max_weight_kg", 0) or 0),
            ))

        # Calculate averages and trends
        if len(data_points) >= 2:
            avg_sets = sum(d.sets_count for d in data_points) / len(data_points)
            avg_volume = sum(d.volume_kg for d in data_points) / len(data_points)

            first_vol = data_points[0].volume_kg
            last_vol = data_points[-1].volume_kg

            if first_vol > 0:
                volume_change = ((last_vol - first_vol) / first_vol) * 100
            else:
                volume_change = 0

            if volume_change > 10:
                volume_trend = "improving"
            elif volume_change < -10:
                volume_trend = "declining"
            else:
                volume_trend = "stable"
        else:
            avg_sets = sum(d.sets_count for d in data_points) / len(data_points) if data_points else 0
            avg_volume = sum(d.volume_kg for d in data_points) / len(data_points) if data_points else 0
            volume_trend = "insufficient_data"
            volume_change = 0

        return MuscleHistoryResponse(
            user_id=user_id,
            muscle_group=muscle_group,
            time_range=time_range.value,
            data_points=data_points,
            avg_weekly_sets=round(avg_sets, 1),
            avg_weekly_volume=round(avg_volume, 2),
            volume_trend=volume_trend,
            volume_change=round(volume_change, 1),
        )

    except Exception as e:
        logger.error(f"Error getting muscle history: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get muscle history: {str(e)}")


@router.post("/log-view")
async def log_muscle_analytics_view(request: ViewLogRequest):
    """
    Log when a user views muscle analytics for tracking engagement.
    """
    try:
        db = get_supabase_db()

        logger.info(f"Logging muscle analytics view for user {request.user_id}, type: {request.view_type.value}")

        # Insert log entry
        db.client.from_("muscle_analytics_logs").insert({
            "user_id": request.user_id,
            "view_type": request.view_type.value,
            "muscle_group_filter": request.muscle_group,
            "session_duration_seconds": request.session_duration_seconds,
        }).execute()

        return {"status": "logged"}

    except Exception as e:
        logger.warning(f"Failed to log muscle analytics view: {e}")
        return {"status": "error", "message": str(e)}
