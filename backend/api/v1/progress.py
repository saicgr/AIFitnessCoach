"""
Progress Analytics API - Visual Progress Charts Endpoints.

Provides endpoints for:
- Strength progression over time (per muscle group)
- Volume progression over time (total and per muscle group)
- Progress summary statistics
- User context logging for analytics
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from pydantic import BaseModel, Field
from enum import Enum

from core.supabase_db import get_supabase_db
from core.logger import get_logger

router = APIRouter(prefix="/progress", tags=["Progress"])
logger = get_logger(__name__)


# ============================================
# Enums
# ============================================

class TimeRange(str, Enum):
    """Time range options for progress charts."""
    FOUR_WEEKS = "4_weeks"
    EIGHT_WEEKS = "8_weeks"
    TWELVE_WEEKS = "12_weeks"
    ALL_TIME = "all_time"


class ChartType(str, Enum):
    """Chart type for analytics logging."""
    STRENGTH = "strength"
    VOLUME = "volume"
    SUMMARY = "summary"
    MUSCLE_GROUP = "muscle_group"
    ALL = "all"


# ============================================
# Response Models
# ============================================

class WeeklyStrengthData(BaseModel):
    """Strength data for a single week."""
    week_start: str
    week_number: int
    year: int
    muscle_group: str
    total_sets: int
    total_reps: int
    total_volume_kg: float
    max_weight_kg: float
    workout_count: int


class StrengthProgressionResponse(BaseModel):
    """Response for strength over time endpoint."""
    user_id: str
    time_range: str
    weeks_count: int
    muscle_groups: List[str]
    data: List[WeeklyStrengthData]
    summary: Dict[str, Any]


class WeeklyVolumeData(BaseModel):
    """Volume data for a single week."""
    week_start: str
    week_number: int
    year: int
    workouts_completed: int
    total_minutes: int
    avg_duration_minutes: float
    total_volume_kg: float
    total_sets: int
    total_reps: int


class VolumeProgressionResponse(BaseModel):
    """Response for volume over time endpoint."""
    user_id: str
    time_range: str
    weeks_count: int
    data: List[WeeklyVolumeData]
    trend: Dict[str, Any]


class ExerciseStrengthData(BaseModel):
    """Strength data for a specific exercise."""
    exercise_name: str
    muscle_group: str
    week_start: str
    times_performed: int
    max_weight_kg: float
    estimated_1rm_kg: float


class ExerciseProgressionResponse(BaseModel):
    """Response for exercise-specific strength progression."""
    user_id: str
    time_range: str
    exercise_name: str
    data: List[ExerciseStrengthData]
    improvement: Dict[str, Any]


class ProgressSummaryResponse(BaseModel):
    """Response for overall progress summary."""
    user_id: str
    total_workouts: int
    total_volume_kg: float
    total_prs: int
    first_workout_date: Optional[str]
    last_workout_date: Optional[str]
    volume_increase_percent: float
    avg_weekly_workouts: float
    current_streak: int
    muscle_group_breakdown: List[Dict[str, Any]]
    recent_prs: List[Dict[str, Any]]
    best_week: Optional[Dict[str, Any]]


class ChartViewLogRequest(BaseModel):
    """Request to log chart view for analytics."""
    user_id: str
    chart_type: ChartType
    time_range: TimeRange
    muscle_group: Optional[str] = None
    session_duration_seconds: Optional[int] = None


# ============================================
# Endpoints
# ============================================

@router.get("/strength-over-time", response_model=StrengthProgressionResponse)
async def get_strength_over_time(
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.TWELVE_WEEKS, description="Time range for data"),
    muscle_group: Optional[str] = Query(None, description="Filter by muscle group"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get weekly strength progression per muscle group.

    Returns weekly data including:
    - Total sets, reps, and volume per muscle group
    - Max weight lifted
    - Workout count
    """
    logger.info(f"Getting strength progression for user {user_id}, range: {time_range}")

    try:
        db = get_supabase_db()

        # Calculate date cutoff based on time range
        cutoff_date = _get_cutoff_date(time_range)

        # Query muscle group weekly volume view
        query = db.client.table("muscle_group_weekly_volume") \
            .select("*") \
            .eq("user_id", user_id)

        if cutoff_date:
            query = query.gte("week_start", cutoff_date.isoformat())

        if muscle_group:
            query = query.eq("muscle_group", muscle_group.lower())

        query = query.order("week_start", desc=False)
        result = query.execute()

        data = result.data or []

        # Transform data
        weekly_data = [
            WeeklyStrengthData(
                week_start=row["week_start"],
                week_number=_get_week_number(row["week_start"]),
                year=_get_year(row["week_start"]),
                muscle_group=row["muscle_group"],
                total_sets=row.get("total_sets", 0),
                total_reps=row.get("total_reps", 0),
                total_volume_kg=float(row.get("total_volume_kg", 0)),
                max_weight_kg=float(row.get("max_weight_kg", 0)),
                workout_count=row.get("workout_count", 0)
            )
            for row in data
        ]

        # Get unique muscle groups
        muscle_groups = list(set(d.muscle_group for d in weekly_data))

        # Calculate summary
        summary = _calculate_strength_summary(weekly_data)

        return StrengthProgressionResponse(
            user_id=user_id,
            time_range=time_range.value,
            weeks_count=len(set(d.week_start for d in weekly_data)),
            muscle_groups=sorted(muscle_groups),
            data=weekly_data,
            summary=summary
        )

    except Exception as e:
        logger.error(f"Failed to get strength progression: {e}")
        raise safe_internal_error(e, "progress")


@router.get("/volume-over-time", response_model=VolumeProgressionResponse)
async def get_volume_over_time(
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.TWELVE_WEEKS, description="Time range for data"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get weekly total volume progression (sets x reps x weight).

    Returns weekly aggregated data including:
    - Workouts completed
    - Total duration
    - Total volume in kg
    - Total sets and reps
    """
    logger.info(f"Getting volume progression for user {user_id}, range: {time_range}")

    try:
        db = get_supabase_db()

        # Calculate date cutoff
        cutoff_date = _get_cutoff_date(time_range)

        # Query weekly progress summary view
        query = db.client.table("weekly_progress_summary") \
            .select("*") \
            .eq("user_id", user_id)

        if cutoff_date:
            query = query.gte("week_start", cutoff_date.isoformat())

        query = query.order("week_start", desc=False)
        result = query.execute()

        data = result.data or []

        # Transform data
        weekly_data = [
            WeeklyVolumeData(
                week_start=row["week_start"],
                week_number=row.get("week_number", _get_week_number(row["week_start"])),
                year=row.get("year", _get_year(row["week_start"])),
                workouts_completed=row.get("workouts_completed", 0),
                total_minutes=row.get("total_minutes", 0),
                avg_duration_minutes=float(row.get("avg_duration_minutes", 0)),
                total_volume_kg=float(row.get("total_volume_kg", 0)),
                total_sets=row.get("total_sets", 0),
                total_reps=row.get("total_reps", 0)
            )
            for row in data
        ]

        # Calculate trend
        trend = _calculate_volume_trend(weekly_data)

        return VolumeProgressionResponse(
            user_id=user_id,
            time_range=time_range.value,
            weeks_count=len(weekly_data),
            data=weekly_data,
            trend=trend
        )

    except Exception as e:
        logger.error(f"Failed to get volume progression: {e}")
        raise safe_internal_error(e, "progress")


@router.get("/exercise/{exercise_name}", response_model=ExerciseProgressionResponse)
async def get_exercise_progression(
    exercise_name: str,
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.TWELVE_WEEKS, description="Time range for data"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get strength progression for a specific exercise.

    Returns weekly data including:
    - Times performed
    - Max weight
    - Estimated 1RM
    """
    logger.info(f"Getting exercise progression for {exercise_name}, user {user_id}")

    try:
        db = get_supabase_db()

        # Calculate date cutoff
        cutoff_date = _get_cutoff_date(time_range)

        # Query exercise strength progress view
        query = db.client.table("exercise_strength_progress") \
            .select("*") \
            .eq("user_id", user_id) \
            .ilike("exercise_name", f"%{exercise_name.lower()}%")

        if cutoff_date:
            query = query.gte("week_start", cutoff_date.isoformat())

        query = query.order("week_start", desc=False)
        result = query.execute()

        data = result.data or []

        # Transform data
        exercise_data = [
            ExerciseStrengthData(
                exercise_name=row["exercise_name"],
                muscle_group=row.get("muscle_group", "other"),
                week_start=row["week_start"],
                times_performed=row.get("times_performed", 0),
                max_weight_kg=float(row.get("max_weight_kg", 0)),
                estimated_1rm_kg=float(row.get("estimated_1rm_kg", 0))
            )
            for row in data
        ]

        # Calculate improvement
        improvement = _calculate_exercise_improvement(exercise_data)

        return ExerciseProgressionResponse(
            user_id=user_id,
            time_range=time_range.value,
            exercise_name=exercise_name,
            data=exercise_data,
            improvement=improvement
        )

    except Exception as e:
        logger.error(f"Failed to get exercise progression: {e}")
        raise safe_internal_error(e, "progress")


@router.get("/summary", response_model=ProgressSummaryResponse)
async def get_progress_summary(
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get overall progress summary statistics.

    Returns:
    - Total workouts, volume, PRs
    - Volume increase percentage
    - Muscle group breakdown
    - Recent PRs
    - Best week
    """
    logger.info(f"Getting progress summary for user {user_id}")

    try:
        db = get_supabase_db()

        # Call the summary function
        summary_result = db.client.rpc(
            "get_user_progress_summary",
            {"p_user_id": user_id}
        ).execute()

        summary_data = summary_result.data[0] if summary_result.data else {}

        # Get muscle group breakdown (last 4 weeks)
        muscle_result = db.client.table("muscle_group_weekly_volume") \
            .select("muscle_group, total_sets, total_volume_kg") \
            .eq("user_id", user_id) \
            .gte("week_start", (datetime.now() - timedelta(weeks=4)).date().isoformat()) \
            .execute()

        # Aggregate muscle data
        muscle_breakdown = {}
        for row in muscle_result.data or []:
            mg = row["muscle_group"]
            if mg not in muscle_breakdown:
                muscle_breakdown[mg] = {"muscle_group": mg, "total_sets": 0, "total_volume_kg": 0}
            muscle_breakdown[mg]["total_sets"] += row.get("total_sets", 0)
            muscle_breakdown[mg]["total_volume_kg"] += float(row.get("total_volume_kg", 0))

        # Get recent PRs (last 30 days)
        prs_result = db.client.table("personal_records") \
            .select("exercise_name, record_value, record_unit, achieved_at") \
            .eq("user_id", user_id) \
            .gte("achieved_at", (datetime.now() - timedelta(days=30)).isoformat()) \
            .order("achieved_at", desc=True) \
            .limit(5) \
            .execute()

        recent_prs = [
            {
                "exercise_name": pr["exercise_name"],
                "record_value": pr["record_value"],
                "record_unit": pr.get("record_unit", "kg"),
                "achieved_at": pr["achieved_at"]
            }
            for pr in prs_result.data or []
        ]

        # Get best week by volume
        best_week_result = db.client.table("weekly_progress_summary") \
            .select("week_start, total_volume_kg, workouts_completed, total_sets") \
            .eq("user_id", user_id) \
            .order("total_volume_kg", desc=True) \
            .limit(1) \
            .execute()

        best_week = None
        if best_week_result.data:
            bw = best_week_result.data[0]
            best_week = {
                "week_start": bw["week_start"],
                "total_volume_kg": float(bw.get("total_volume_kg", 0)),
                "workouts_completed": bw.get("workouts_completed", 0),
                "total_sets": bw.get("total_sets", 0)
            }

        return ProgressSummaryResponse(
            user_id=user_id,
            total_workouts=summary_data.get("total_workouts", 0),
            total_volume_kg=float(summary_data.get("total_volume_kg", 0)),
            total_prs=summary_data.get("total_prs", 0),
            first_workout_date=summary_data.get("first_workout_date"),
            last_workout_date=summary_data.get("last_workout_date"),
            volume_increase_percent=float(summary_data.get("volume_increase_percent", 0)),
            avg_weekly_workouts=float(summary_data.get("avg_weekly_workouts", 0)),
            current_streak=summary_data.get("current_streak", 0),
            muscle_group_breakdown=list(muscle_breakdown.values()),
            recent_prs=recent_prs,
            best_week=best_week
        )

    except Exception as e:
        logger.error(f"Failed to get progress summary: {e}")
        raise safe_internal_error(e, "progress")


@router.post("/log-view")
async def log_chart_view(request: ChartViewLogRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Log when a user views progress charts for analytics.

    Used to understand user engagement with progress features.
    """
    logger.info(f"Logging chart view for user {request.user_id}: {request.chart_type}")

    try:
        db = get_supabase_db()

        db.client.table("progress_charts_views").insert({
            "user_id": request.user_id,
            "chart_type": request.chart_type.value,
            "time_range": request.time_range.value,
            "muscle_group": request.muscle_group,
            "session_duration_seconds": request.session_duration_seconds,
            "viewed_at": datetime.now().isoformat()
        }).execute()

        return {"success": True, "message": "Chart view logged"}

    except Exception as e:
        logger.error(f"Failed to log chart view: {e}")
        # Don't fail the request for logging errors
        return {"success": False, "message": str(e)}


@router.get("/muscle-groups/{user_id}")
async def get_available_muscle_groups(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get list of muscle groups the user has trained.

    Used for populating filter dropdowns.
    """
    logger.info(f"Getting available muscle groups for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("muscle_group_weekly_volume") \
            .select("muscle_group") \
            .eq("user_id", user_id) \
            .execute()

        # Get unique muscle groups
        muscle_groups = list(set(row["muscle_group"] for row in result.data or []))

        return {
            "user_id": user_id,
            "muscle_groups": sorted(muscle_groups),
            "count": len(muscle_groups)
        }

    except Exception as e:
        logger.error(f"Failed to get muscle groups: {e}")
        raise safe_internal_error(e, "progress")


# ============================================
# Helper Functions
# ============================================

def _get_cutoff_date(time_range: TimeRange) -> Optional[date]:
    """Get the cutoff date based on time range."""
    if time_range == TimeRange.ALL_TIME:
        return None

    weeks_map = {
        TimeRange.FOUR_WEEKS: 4,
        TimeRange.EIGHT_WEEKS: 8,
        TimeRange.TWELVE_WEEKS: 12,
    }

    weeks = weeks_map.get(time_range, 12)
    return (datetime.now() - timedelta(weeks=weeks)).date()


def _get_week_number(date_str: str) -> int:
    """Extract week number from date string."""
    try:
        d = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        return d.isocalendar()[1]
    except:
        return 0


def _get_year(date_str: str) -> int:
    """Extract year from date string."""
    try:
        d = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        return d.year
    except:
        return datetime.now().year


def _calculate_strength_summary(data: List[WeeklyStrengthData]) -> Dict[str, Any]:
    """Calculate strength summary statistics."""
    if not data:
        return {
            "total_volume_kg": 0,
            "total_sets": 0,
            "avg_weekly_volume_kg": 0,
            "top_muscle_group": None,
            "volume_trend": "no_data"
        }

    total_volume = sum(d.total_volume_kg for d in data)
    total_sets = sum(d.total_sets for d in data)
    unique_weeks = len(set(d.week_start for d in data))

    # Find top muscle group by volume
    mg_volumes = {}
    for d in data:
        mg_volumes[d.muscle_group] = mg_volumes.get(d.muscle_group, 0) + d.total_volume_kg
    top_mg = max(mg_volumes, key=mg_volumes.get) if mg_volumes else None

    # Calculate trend (compare first half vs second half of data)
    sorted_data = sorted(data, key=lambda x: x.week_start)
    if len(sorted_data) >= 4:
        mid = len(sorted_data) // 2
        first_half_vol = sum(d.total_volume_kg for d in sorted_data[:mid])
        second_half_vol = sum(d.total_volume_kg for d in sorted_data[mid:])
        if first_half_vol > 0:
            change = ((second_half_vol - first_half_vol) / first_half_vol) * 100
            if change > 5:
                trend = "improving"
            elif change < -5:
                trend = "declining"
            else:
                trend = "maintaining"
        else:
            trend = "improving" if second_half_vol > 0 else "no_data"
    else:
        trend = "insufficient_data"

    return {
        "total_volume_kg": round(total_volume, 2),
        "total_sets": total_sets,
        "avg_weekly_volume_kg": round(total_volume / max(unique_weeks, 1), 2),
        "top_muscle_group": top_mg,
        "volume_trend": trend
    }


def _calculate_volume_trend(data: List[WeeklyVolumeData]) -> Dict[str, Any]:
    """Calculate volume trend statistics."""
    if not data:
        return {
            "direction": "no_data",
            "percent_change": 0,
            "avg_weekly_volume_kg": 0,
            "peak_volume_kg": 0,
            "peak_week": None
        }

    sorted_data = sorted(data, key=lambda x: x.week_start)

    # Find peak
    peak = max(data, key=lambda x: x.total_volume_kg)

    # Calculate trend
    if len(sorted_data) >= 2:
        recent_weeks = sorted_data[-4:] if len(sorted_data) >= 4 else sorted_data[-2:]
        older_weeks = sorted_data[:-len(recent_weeks)] if len(sorted_data) > len(recent_weeks) else []

        recent_avg = sum(d.total_volume_kg for d in recent_weeks) / len(recent_weeks)
        older_avg = sum(d.total_volume_kg for d in older_weeks) / len(older_weeks) if older_weeks else recent_avg

        if older_avg > 0:
            percent_change = ((recent_avg - older_avg) / older_avg) * 100
        else:
            percent_change = 100 if recent_avg > 0 else 0

        if percent_change > 5:
            direction = "improving"
        elif percent_change < -5:
            direction = "declining"
        else:
            direction = "maintaining"
    else:
        direction = "insufficient_data"
        percent_change = 0

    total_volume = sum(d.total_volume_kg for d in data)

    return {
        "direction": direction,
        "percent_change": round(percent_change, 1),
        "avg_weekly_volume_kg": round(total_volume / max(len(data), 1), 2),
        "peak_volume_kg": round(peak.total_volume_kg, 2),
        "peak_week": peak.week_start
    }


def _calculate_exercise_improvement(data: List[ExerciseStrengthData]) -> Dict[str, Any]:
    """Calculate improvement for a specific exercise."""
    if not data:
        return {
            "has_improvement": False,
            "weight_increase_kg": 0,
            "weight_increase_percent": 0,
            "rm_increase_kg": 0,
            "rm_increase_percent": 0
        }

    sorted_data = sorted(data, key=lambda x: x.week_start)

    first_entry = sorted_data[0]
    last_entry = sorted_data[-1]

    weight_increase = last_entry.max_weight_kg - first_entry.max_weight_kg
    weight_percent = (weight_increase / first_entry.max_weight_kg * 100) if first_entry.max_weight_kg > 0 else 0

    rm_increase = last_entry.estimated_1rm_kg - first_entry.estimated_1rm_kg
    rm_percent = (rm_increase / first_entry.estimated_1rm_kg * 100) if first_entry.estimated_1rm_kg > 0 else 0

    return {
        "has_improvement": weight_increase > 0 or rm_increase > 0,
        "weight_increase_kg": round(weight_increase, 2),
        "weight_increase_percent": round(weight_percent, 1),
        "rm_increase_kg": round(rm_increase, 2),
        "rm_increase_percent": round(rm_percent, 1),
        "first_max_weight_kg": round(first_entry.max_weight_kg, 2),
        "current_max_weight_kg": round(last_entry.max_weight_kg, 2),
        "first_1rm_kg": round(first_entry.estimated_1rm_kg, 2),
        "current_1rm_kg": round(last_entry.estimated_1rm_kg, 2)
    }
