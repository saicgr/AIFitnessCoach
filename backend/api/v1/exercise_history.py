"""
Exercise History API - Per-Exercise Analytics Endpoints.

Provides endpoints for:
- Exercise workout history (every session where exercise was performed)
- Exercise progression analysis over time
- Exercise personal records (PRs)
- Most performed exercises
- Exercise chart data for visualizations
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from pydantic import BaseModel, Field
from enum import Enum

from core.supabase_db import get_supabase_db
from core.logger import get_logger

router = APIRouter(prefix="/exercise-history", tags=["Exercise History"])
logger = get_logger(__name__)


# ============================================
# Enums
# ============================================

class TimeRange(str, Enum):
    """Time range options for exercise history."""
    FOUR_WEEKS = "4_weeks"
    EIGHT_WEEKS = "8_weeks"
    TWELVE_WEEKS = "12_weeks"
    SIX_MONTHS = "6_months"
    ONE_YEAR = "1_year"
    ALL_TIME = "all_time"


# ============================================
# Response Models
# ============================================

class SetRecord(BaseModel):
    """Individual set within a workout session."""
    set_number: int
    reps: int
    weight_kg: float
    volume_kg: float = 0
    is_warmup: bool = False
    is_drop_set: bool = False
    rpe: Optional[int] = None


class ExerciseSessionRecord(BaseModel):
    """Single exercise session record."""
    id: str
    exercise_name: str
    workout_date: str
    workout_name: str
    workout_type: Optional[str] = None
    sets_completed: int
    total_reps: int
    total_volume_kg: float
    max_weight_kg: float
    estimated_1rm_kg: Optional[float] = None
    avg_rpe: Optional[float] = None
    is_pr: bool = False
    notes: Optional[str] = None


class ExerciseHistorySummary(BaseModel):
    """Summary statistics for exercise history."""
    times_performed: int
    total_volume_kg: float
    max_weight_kg: float
    avg_weight_kg: float
    total_reps: int
    total_sets: int
    estimated_1rm_kg: float
    first_performed_at: Optional[str] = None
    last_performed_at: Optional[str] = None


class ExerciseHistoryResponse(BaseModel):
    """Response for exercise history endpoint."""
    user_id: str
    exercise_name: str
    time_range: str
    records: List[ExerciseSessionRecord]
    total_records: int
    current_page: int
    total_pages: int
    has_more: bool
    summary: ExerciseHistorySummary


class ExerciseChartDataPoint(BaseModel):
    """Single data point for exercise chart."""
    date: str
    max_weight_kg: float
    avg_weight_kg: float
    volume_kg: float
    total_reps: int
    estimated_1rm_kg: Optional[float] = None
    is_pr: bool = False


class ExerciseChartTrend(BaseModel):
    """Trend analysis for exercise progression."""
    direction: str  # 'improving', 'declining', 'maintaining', 'no_data'
    percent_change: float
    start_weight: float
    current_weight: float
    start_1rm: float
    current_1rm: float


class ExerciseChartDataResponse(BaseModel):
    """Response for exercise chart data endpoint."""
    user_id: str
    exercise_name: str
    time_range: str
    data_points: List[ExerciseChartDataPoint]
    trend: ExerciseChartTrend


class PersonalRecord(BaseModel):
    """Personal record for an exercise."""
    type: str  # 'max_weight', 'max_volume', 'max_reps', 'best_1rm'
    value: float
    unit: str
    achieved_at: str
    workout_name: str
    reps: Optional[int] = None
    weight_kg: Optional[float] = None


class ExercisePersonalRecordsResponse(BaseModel):
    """Response for exercise PRs endpoint."""
    user_id: str
    exercise_name: str
    records: List[PersonalRecord]
    max_weight: Optional[PersonalRecord] = None
    max_volume: Optional[PersonalRecord] = None
    max_reps: Optional[PersonalRecord] = None
    max_1rm: Optional[PersonalRecord] = None


class MostPerformedExercise(BaseModel):
    """Most performed exercise item."""
    exercise_name: str
    muscle_group: str
    times_performed: int
    total_volume_kg: float
    max_weight_kg: float
    last_performed_at: Optional[str] = None


class MostPerformedExercisesResponse(BaseModel):
    """Response for most performed exercises endpoint."""
    user_id: str
    exercises: List[MostPerformedExercise]
    total_unique_exercises: int


class ViewLogRequest(BaseModel):
    """Request to log exercise history view."""
    user_id: str
    exercise_name: str
    session_duration_seconds: Optional[int] = None


# ============================================
# Helper Functions
# ============================================

def get_days_for_time_range(time_range: TimeRange) -> int:
    """Convert time range enum to days."""
    mapping = {
        TimeRange.FOUR_WEEKS: 28,
        TimeRange.EIGHT_WEEKS: 56,
        TimeRange.TWELVE_WEEKS: 84,
        TimeRange.SIX_MONTHS: 180,
        TimeRange.ONE_YEAR: 365,
        TimeRange.ALL_TIME: 3650,  # ~10 years
    }
    return mapping.get(time_range, 84)


# ============================================
# Endpoints
# ============================================

@router.get("/{exercise_name}", response_model=ExerciseHistoryResponse)
async def get_exercise_history(
    exercise_name: str,
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.TWELVE_WEEKS, description="Time range for data"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page")
):
    """
    Get paginated workout history for a specific exercise.

    Returns every session where the exercise was performed with
    sets, reps, volume, weight, and estimated 1RM.
    """
    try:
        db = get_supabase_db()
        days_back = get_days_for_time_range(time_range)
        offset = (page - 1) * limit

        logger.info(f"Getting exercise history for user {user_id}, exercise: {exercise_name}")

        # Query exercise_workout_history view
        start_date = (date.today() - timedelta(days=days_back)).isoformat()

        # Get total count
        count_query = db.client.from_("exercise_workout_history") \
            .select("*", count="exact") \
            .eq("user_id", user_id) \
            .ilike("exercise_name", exercise_name.lower()) \
            .gte("workout_date", start_date)

        count_result = count_query.execute()
        total_records = count_result.count or 0

        # Get paginated history
        history_query = db.client.from_("exercise_workout_history") \
            .select("*") \
            .eq("user_id", user_id) \
            .ilike("exercise_name", exercise_name.lower()) \
            .gte("workout_date", start_date) \
            .order("workout_date", desc=True) \
            .range(offset, offset + limit - 1)

        history_result = history_query.execute()
        history_data = history_result.data or []

        # Get PRs for marking
        pr_query = db.client.from_("exercise_personal_records") \
            .select("record_type, record_value, achieved_at") \
            .eq("user_id", user_id) \
            .ilike("exercise_name", exercise_name.lower()) \
            .eq("is_current_record", True)

        pr_result = pr_query.execute()
        pr_data = pr_result.data or []
        pr_dates = {pr.get("achieved_at", "")[:10] for pr in pr_data}

        # Build records
        records = []
        for row in history_data:
            is_pr = row.get("workout_date", "") in pr_dates
            records.append(ExerciseSessionRecord(
                id=row.get("workout_log_id", ""),
                exercise_name=row.get("exercise_name", exercise_name),
                workout_date=row.get("workout_date", ""),
                workout_name=row.get("workout_name", ""),
                workout_type=row.get("workout_type"),
                sets_completed=row.get("sets_completed", 0),
                total_reps=row.get("total_reps", 0),
                total_volume_kg=float(row.get("total_volume_kg", 0) or 0),
                max_weight_kg=float(row.get("max_weight_kg", 0) or 0),
                estimated_1rm_kg=float(row.get("estimated_1rm_kg", 0) or 0) if row.get("estimated_1rm_kg") else None,
                avg_rpe=float(row.get("avg_rpe", 0) or 0) if row.get("avg_rpe") else None,
                is_pr=is_pr,
            ))

        # Build summary
        summary_query = db.client.from_("exercise_workout_history") \
            .select("*") \
            .eq("user_id", user_id) \
            .ilike("exercise_name", exercise_name.lower()) \
            .gte("workout_date", start_date)

        summary_result = summary_query.execute()
        summary_data = summary_result.data or []

        if summary_data:
            total_volume = sum(float(r.get("total_volume_kg", 0) or 0) for r in summary_data)
            total_reps = sum(int(r.get("total_reps", 0) or 0) for r in summary_data)
            total_sets = sum(int(r.get("sets_completed", 0) or 0) for r in summary_data)
            weights = [float(r.get("max_weight_kg", 0) or 0) for r in summary_data if r.get("max_weight_kg")]
            max_weight = max(weights) if weights else 0
            avg_weight = sum(weights) / len(weights) if weights else 0
            one_rms = [float(r.get("estimated_1rm_kg", 0) or 0) for r in summary_data if r.get("estimated_1rm_kg")]
            max_1rm = max(one_rms) if one_rms else 0
            dates = sorted([r.get("workout_date", "") for r in summary_data if r.get("workout_date")])

            summary = ExerciseHistorySummary(
                times_performed=len(summary_data),
                total_volume_kg=round(total_volume, 2),
                max_weight_kg=round(max_weight, 2),
                avg_weight_kg=round(avg_weight, 2),
                total_reps=total_reps,
                total_sets=total_sets,
                estimated_1rm_kg=round(max_1rm, 2),
                first_performed_at=dates[0] if dates else None,
                last_performed_at=dates[-1] if dates else None,
            )
        else:
            summary = ExerciseHistorySummary(
                times_performed=0,
                total_volume_kg=0,
                max_weight_kg=0,
                avg_weight_kg=0,
                total_reps=0,
                total_sets=0,
                estimated_1rm_kg=0,
            )

        total_pages = (total_records + limit - 1) // limit if total_records > 0 else 1

        return ExerciseHistoryResponse(
            user_id=user_id,
            exercise_name=exercise_name,
            time_range=time_range.value,
            records=records,
            total_records=total_records,
            current_page=page,
            total_pages=total_pages,
            has_more=page < total_pages,
            summary=summary,
        )

    except Exception as e:
        logger.error(f"Error getting exercise history: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get exercise history: {str(e)}")


@router.get("/{exercise_name}/chart", response_model=ExerciseChartDataResponse)
async def get_exercise_chart_data(
    exercise_name: str,
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.TWELVE_WEEKS, description="Time range for chart"),
):
    """
    Get chart data for visualizing exercise progression over time.

    Returns data points with weight, volume, and 1RM progression,
    along with trend analysis.
    """
    try:
        db = get_supabase_db()
        days_back = get_days_for_time_range(time_range)
        start_date = (date.today() - timedelta(days=days_back)).isoformat()

        logger.info(f"Getting exercise chart data for user {user_id}, exercise: {exercise_name}")

        # Query history data
        query = db.client.from_("exercise_workout_history") \
            .select("*") \
            .eq("user_id", user_id) \
            .ilike("exercise_name", exercise_name.lower()) \
            .gte("workout_date", start_date) \
            .order("workout_date", desc=False)

        result = query.execute()
        data = result.data or []

        # Build data points
        data_points = []
        for row in data:
            data_points.append(ExerciseChartDataPoint(
                date=row.get("workout_date", ""),
                max_weight_kg=float(row.get("max_weight_kg", 0) or 0),
                avg_weight_kg=float(row.get("avg_weight_kg", 0) or 0),
                volume_kg=float(row.get("total_volume_kg", 0) or 0),
                total_reps=int(row.get("total_reps", 0) or 0),
                estimated_1rm_kg=float(row.get("estimated_1rm_kg", 0) or 0) if row.get("estimated_1rm_kg") else None,
                is_pr=False,  # Could enhance with PR detection
            ))

        # Calculate trend
        if len(data_points) >= 2:
            first = data_points[0]
            last = data_points[-1]

            start_weight = first.max_weight_kg
            current_weight = last.max_weight_kg
            start_1rm = first.estimated_1rm_kg or 0
            current_1rm = last.estimated_1rm_kg or 0

            if start_weight > 0:
                percent_change = round(((current_weight - start_weight) / start_weight) * 100, 1)
            else:
                percent_change = 0

            if percent_change > 5:
                direction = "improving"
            elif percent_change < -5:
                direction = "declining"
            else:
                direction = "maintaining"

            trend = ExerciseChartTrend(
                direction=direction,
                percent_change=percent_change,
                start_weight=round(start_weight, 2),
                current_weight=round(current_weight, 2),
                start_1rm=round(start_1rm, 2),
                current_1rm=round(current_1rm, 2),
            )
        else:
            trend = ExerciseChartTrend(
                direction="no_data",
                percent_change=0,
                start_weight=0,
                current_weight=0,
                start_1rm=0,
                current_1rm=0,
            )

        return ExerciseChartDataResponse(
            user_id=user_id,
            exercise_name=exercise_name,
            time_range=time_range.value,
            data_points=data_points,
            trend=trend,
        )

    except Exception as e:
        logger.error(f"Error getting exercise chart data: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get chart data: {str(e)}")


@router.get("/{exercise_name}/prs", response_model=ExercisePersonalRecordsResponse)
async def get_exercise_personal_records(
    exercise_name: str,
    user_id: str = Query(..., description="User ID"),
):
    """
    Get personal records for a specific exercise.

    Returns all current PRs including max weight, max volume,
    max reps, and best estimated 1RM.
    """
    try:
        db = get_supabase_db()

        logger.info(f"Getting exercise PRs for user {user_id}, exercise: {exercise_name}")

        # Query current PRs
        query = db.client.from_("exercise_personal_records") \
            .select("*") \
            .eq("user_id", user_id) \
            .ilike("exercise_name", exercise_name.lower()) \
            .eq("is_current_record", True) \
            .order("achieved_at", desc=True)

        result = query.execute()
        pr_data = result.data or []

        records = []
        max_weight = None
        max_volume = None
        max_reps = None
        max_1rm = None

        for pr in pr_data:
            record = PersonalRecord(
                type=pr.get("record_type", ""),
                value=float(pr.get("record_value", 0)),
                unit=pr.get("record_unit", "kg"),
                achieved_at=pr.get("achieved_at", "")[:10] if pr.get("achieved_at") else "",
                workout_name=pr.get("workout_name", ""),
                reps=pr.get("reps_at_record"),
                weight_kg=float(pr.get("weight_at_record_kg", 0)) if pr.get("weight_at_record_kg") else None,
            )
            records.append(record)

            if pr.get("record_type") == "max_weight":
                max_weight = record
            elif pr.get("record_type") == "max_volume":
                max_volume = record
            elif pr.get("record_type") == "max_reps":
                max_reps = record
            elif pr.get("record_type") == "best_1rm":
                max_1rm = record

        return ExercisePersonalRecordsResponse(
            user_id=user_id,
            exercise_name=exercise_name,
            records=records,
            max_weight=max_weight,
            max_volume=max_volume,
            max_reps=max_reps,
            max_1rm=max_1rm,
        )

    except Exception as e:
        logger.error(f"Error getting exercise PRs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get PRs: {str(e)}")


@router.get("/most-performed", response_model=MostPerformedExercisesResponse)
async def get_most_performed_exercises(
    user_id: str = Query(..., description="User ID"),
    limit: int = Query(10, ge=1, le=50, description="Number of exercises to return"),
):
    """
    Get the most performed exercises for a user.

    Returns exercises sorted by times performed, with volume
    and weight statistics.
    """
    try:
        db = get_supabase_db()

        logger.info(f"Getting most performed exercises for user {user_id}")

        # Query aggregated exercise data
        query = db.client.rpc(
            "get_most_performed_exercises",
            {"p_user_id": user_id, "p_limit": limit}
        )

        result = query.execute()
        data = result.data

        if isinstance(data, dict):
            exercises_data = data.get("exercises", [])
            total_unique = data.get("total_unique_exercises", 0)
        elif isinstance(data, list):
            exercises_data = data
            total_unique = len(data)
        else:
            exercises_data = []
            total_unique = 0

        exercises = []
        for ex in exercises_data:
            exercises.append(MostPerformedExercise(
                exercise_name=ex.get("exercise_name", ""),
                muscle_group=ex.get("muscle_group", ""),
                times_performed=ex.get("times_performed", 0),
                total_volume_kg=float(ex.get("total_volume_kg", 0) or 0),
                max_weight_kg=float(ex.get("max_weight_kg", 0) or 0),
                last_performed_at=ex.get("last_performed_at"),
            ))

        return MostPerformedExercisesResponse(
            user_id=user_id,
            exercises=exercises,
            total_unique_exercises=total_unique,
        )

    except Exception as e:
        logger.error(f"Error getting most performed exercises: {e}")
        # Fallback to simple query if RPC doesn't exist
        try:
            db = get_supabase_db()
            query = db.client.from_("exercise_workout_history") \
                .select("exercise_name, muscle_group") \
                .eq("user_id", user_id)

            result = query.execute()
            data = result.data or []

            # Aggregate manually
            exercise_counts = {}
            for row in data:
                name = row.get("exercise_name", "")
                if name not in exercise_counts:
                    exercise_counts[name] = {
                        "exercise_name": name,
                        "muscle_group": row.get("muscle_group", ""),
                        "times_performed": 0,
                        "total_volume_kg": 0,
                        "max_weight_kg": 0,
                    }
                exercise_counts[name]["times_performed"] += 1

            # Sort by count
            sorted_exercises = sorted(
                exercise_counts.values(),
                key=lambda x: x["times_performed"],
                reverse=True
            )[:limit]

            exercises = [
                MostPerformedExercise(**ex)
                for ex in sorted_exercises
            ]

            return MostPerformedExercisesResponse(
                user_id=user_id,
                exercises=exercises,
                total_unique_exercises=len(exercise_counts),
            )

        except Exception as e2:
            logger.error(f"Fallback also failed: {e2}")
            raise HTTPException(status_code=500, detail=f"Failed to get exercises: {str(e)}")


@router.post("/log-view")
async def log_exercise_history_view(request: ViewLogRequest):
    """
    Log when a user views exercise history for analytics.

    This helps track user engagement with the exercise history feature.
    """
    try:
        db = get_supabase_db()

        logger.info(f"Logging exercise history view for user {request.user_id}, exercise: {request.exercise_name}")

        # Insert log entry
        db.client.from_("muscle_analytics_logs").insert({
            "user_id": request.user_id,
            "view_type": "exercise_history",
            "exercise_name_filter": request.exercise_name,
            "session_duration_seconds": request.session_duration_seconds,
        }).execute()

        return {"status": "logged"}

    except Exception as e:
        logger.warning(f"Failed to log exercise history view: {e}")
        # Don't fail the request on logging errors
        return {"status": "error", "message": str(e)}
