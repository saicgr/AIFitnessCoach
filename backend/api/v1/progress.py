"""
Progress Analytics API - Visual Progress Charts Endpoints.

Provides endpoints for:
- Strength progression over time (per muscle group)
- Volume progression over time (total and per muscle group)
- Progress summary statistics
- User context logging for analytics
"""
from core.db import get_supabase_db

import asyncio
from concurrent.futures import ThreadPoolExecutor

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta, timezone
import json
from pydantic import BaseModel, Field
from enum import Enum

from core.logger import get_logger

router = APIRouter(prefix="/progress", tags=["Progress"])

# Per-gym view names — mirrors of the combined views with a gym_profile_id column.
# Used only when the caller passes an explicit `gym_profile_id`. There is no
# `weekly_progress_summary_by_gym`, so the gym-scoped volume path aggregates
# weekly totals from `muscle_group_weekly_volume_by_gym` instead.
_MUSCLE_WEEKLY_BY_GYM = "muscle_group_weekly_volume_by_gym"

# Thread pool for running synchronous Supabase calls concurrently
_db_executor = ThreadPoolExecutor(max_workers=10)
logger = get_logger(__name__)


# ============================================
# Enums
# ============================================

class TimeRange(str, Enum):
    """Time range options for progress charts."""
    ONE_DAY = "1_day"
    THREE_DAYS = "3_days"
    SEVEN_DAYS = "7_days"
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
    gym_profile_id: Optional[str] = Query(
        None,
        description="Filter strength progression to a specific gym profile "
                    "(per-gym progress). Default (no param) = all gyms combined.",
    ),
    current_user: dict = Depends(get_current_user),
):
    """
    Get weekly strength progression per muscle group.

    Returns weekly data including:
    - Total sets, reps, and volume per muscle group
    - Max weight lifted
    - Workout count

    Per-gym progress: when `gym_profile_id` is supplied, the underlying weekly
    volume is read from `muscle_group_weekly_volume_by_gym` filtered to that gym
    so machine/cable numbers stay comparable. Without it, behavior is unchanged
    (the combined `muscle_group_weekly_volume` view).
    """
    logger.info(
        f"Getting strength progression for user {user_id}, range: {time_range}, "
        f"gym_profile_id: {gym_profile_id}"
    )

    try:
        db = get_supabase_db()

        # Calculate date cutoff based on time range
        cutoff_date = _get_cutoff_date(time_range)

        # Per-gym path reads the gym-aware view + filters to the gym; the
        # combined path keeps the original view (byte-for-byte unchanged).
        table_name = _MUSCLE_WEEKLY_BY_GYM if gym_profile_id else "muscle_group_weekly_volume"
        query = db.client.table(table_name) \
            .select("*") \
            .eq("user_id", user_id)

        if gym_profile_id:
            query = query.eq("gym_profile_id", gym_profile_id)

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
        logger.error(f"Failed to get strength progression: {e}", exc_info=True)
        raise safe_internal_error(e, "progress")


@router.get("/volume-over-time", response_model=VolumeProgressionResponse)
async def get_volume_over_time(
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.TWELVE_WEEKS, description="Time range for data"),
    gym_profile_id: Optional[str] = Query(
        None,
        description="Filter volume progression to a specific gym profile "
                    "(per-gym progress). Default (no param) = all gyms combined.",
    ),
    current_user: dict = Depends(get_current_user),
):
    """
    Get weekly total volume progression (sets x reps x weight).

    Returns weekly aggregated data including:
    - Workouts completed
    - Total duration
    - Total volume in kg
    - Total sets and reps

    Per-gym progress: when `gym_profile_id` is supplied, there is no
    `weekly_progress_summary_by_gym` view, so weekly totals are aggregated from
    `muscle_group_weekly_volume_by_gym` (summed across muscle groups per week)
    filtered to that gym. Per-gym duration isn't tracked at the muscle-group
    level, so `total_minutes`/`avg_duration_minutes` are 0 in that path.
    Without the param, behavior is unchanged (the combined
    `weekly_progress_summary` view).
    """
    logger.info(
        f"Getting volume progression for user {user_id}, range: {time_range}, "
        f"gym_profile_id: {gym_profile_id}"
    )

    try:
        db = get_supabase_db()

        # Calculate date cutoff
        cutoff_date = _get_cutoff_date(time_range)

        if gym_profile_id:
            # Per-gym: aggregate weekly totals from the gym-aware muscle volume
            # view (one row per muscle-group/week → fold into one row per week).
            mg_query = db.client.table(_MUSCLE_WEEKLY_BY_GYM) \
                .select("week_start, workout_count, total_sets, total_reps, total_volume_kg") \
                .eq("user_id", user_id) \
                .eq("gym_profile_id", gym_profile_id)

            if cutoff_date:
                mg_query = mg_query.gte("week_start", cutoff_date.isoformat())

            mg_result = mg_query.order("week_start", desc=False).execute()
            mg_rows = mg_result.data or []

            # Fold muscle-group rows into one bucket per week. A single workout
            # hits multiple muscle groups, so summing workout_count across groups
            # would over-count completed workouts — use the per-week max instead.
            week_buckets: Dict[str, Dict[str, Any]] = {}
            for row in mg_rows:
                wk = row.get("week_start")
                if not wk:
                    continue
                bucket = week_buckets.setdefault(wk, {
                    "week_start": wk,
                    "workouts_completed": 0,
                    "total_volume_kg": 0.0,
                    "total_sets": 0,
                    "total_reps": 0,
                })
                bucket["total_volume_kg"] += float(row.get("total_volume_kg", 0) or 0)
                bucket["total_sets"] += int(row.get("total_sets", 0) or 0)
                bucket["total_reps"] += int(row.get("total_reps", 0) or 0)
                bucket["workouts_completed"] = max(
                    bucket["workouts_completed"], int(row.get("workout_count", 0) or 0)
                )

            weekly_data = [
                WeeklyVolumeData(
                    week_start=b["week_start"],
                    week_number=_get_week_number(b["week_start"]),
                    year=_get_year(b["week_start"]),
                    workouts_completed=b["workouts_completed"],
                    total_minutes=0,
                    avg_duration_minutes=0.0,
                    total_volume_kg=round(b["total_volume_kg"], 2),
                    total_sets=b["total_sets"],
                    total_reps=b["total_reps"],
                )
                for b in sorted(week_buckets.values(), key=lambda x: x["week_start"])
            ]
        else:
            # Combined path — unchanged. Query weekly progress summary view.
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
        logger.error(f"Failed to get volume progression: {e}", exc_info=True)
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
        logger.error(f"Failed to get exercise progression: {e}", exc_info=True)
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
        loop = asyncio.get_event_loop()

        # All arithmetic is performed Python-side to avoid calling the
        # broken `get_user_progress_summary` RPC (which internally raises
        # `unit "week" not supported` via an INTERVAL 'N week' literal).
        now_utc = datetime.now(timezone.utc)
        four_weeks_ago_date = (now_utc - timedelta(days=28)).date().isoformat()
        eight_weeks_ago = (now_utc - timedelta(days=56)).isoformat()
        four_weeks_ago = (now_utc - timedelta(days=28)).isoformat()
        thirty_days_ago = (now_utc - timedelta(days=30)).isoformat()

        # ──────────────────────────────────────────────────────────────
        # Independent fetchers (run in a thread pool so they can be
        # gathered concurrently — supabase-py is synchronous).
        # ──────────────────────────────────────────────────────────────
        def _fetch_workout_counts():
            # Completed workouts — for total_workouts + first/last dates.
            return db.client.table("workouts") \
                .select("scheduled_date, completed_at") \
                .eq("user_id", user_id) \
                .eq("is_completed", True) \
                .execute()

        def _fetch_recent_logs():
            # Logs newer than 8 weeks ago — drive both total_volume_kg and
            # the 4-weeks-vs-prior-4-weeks increase calc in one pull.
            return db.client.table("workout_logs") \
                .select("sets_json, completed_at") \
                .eq("user_id", user_id) \
                .eq("status", "completed") \
                .gte("completed_at", eight_weeks_ago) \
                .execute()

        def _fetch_total_prs():
            return db.client.table("personal_records") \
                .select("id", count="exact") \
                .eq("user_id", user_id) \
                .execute()

        def _fetch_completed_dates_28d():
            # Used for avg_weekly_workouts + current_streak.
            return db.client.table("workouts") \
                .select("completed_at, scheduled_date") \
                .eq("user_id", user_id) \
                .eq("is_completed", True) \
                .gte("scheduled_date", (now_utc - timedelta(days=60)).date().isoformat()) \
                .execute()

        def _fetch_muscle_groups():
            return db.client.table("muscle_group_weekly_volume") \
                .select("muscle_group, total_sets, total_volume_kg") \
                .eq("user_id", user_id) \
                .gte("week_start", four_weeks_ago_date) \
                .execute()

        def _fetch_recent_prs():
            # PROD schema: personal_records has weight_kg + reps, NOT
            # record_value/record_unit. Select the real columns.
            return db.client.table("personal_records") \
                .select("exercise_name, weight_kg, reps, achieved_at") \
                .eq("user_id", user_id) \
                .gte("achieved_at", thirty_days_ago) \
                .order("achieved_at", desc=True) \
                .limit(5) \
                .execute()

        def _fetch_best_week():
            return db.client.table("weekly_progress_summary") \
                .select("week_start, total_volume_kg, workouts_completed, total_sets") \
                .eq("user_id", user_id) \
                .order("total_volume_kg", desc=True) \
                .limit(1) \
                .execute()

        (
            workouts_result,
            logs_result,
            prs_count_result,
            dates_result,
            muscle_result,
            prs_result,
            best_week_result,
        ) = await asyncio.gather(
            loop.run_in_executor(_db_executor, _fetch_workout_counts),
            loop.run_in_executor(_db_executor, _fetch_recent_logs),
            loop.run_in_executor(_db_executor, _fetch_total_prs),
            loop.run_in_executor(_db_executor, _fetch_completed_dates_28d),
            loop.run_in_executor(_db_executor, _fetch_muscle_groups),
            loop.run_in_executor(_db_executor, _fetch_recent_prs),
            loop.run_in_executor(_db_executor, _fetch_best_week),
        )

        # ── total_workouts + first/last dates ───────────────────────
        workout_rows = workouts_result.data or []
        total_workouts = len(workout_rows)
        scheduled_dates = [r["scheduled_date"] for r in workout_rows if r.get("scheduled_date")]
        completed_ats = [r["completed_at"] for r in workout_rows if r.get("completed_at")]
        first_workout_date = min(scheduled_dates) if scheduled_dates else None
        last_workout_date = max(completed_ats) if completed_ats else None

        # ── volume totals + recent/prior 4-week buckets ─────────────
        recent_vol_kg = 0.0   # last 28d
        prior_vol_kg = 0.0    # 28–56d ago
        total_vol_kg_8w = 0.0
        for row in logs_result.data or []:
            completed_at = row.get("completed_at")
            vol = _volume_from_sets_json_kg(row.get("sets_json"))
            total_vol_kg_8w += vol
            if not completed_at:
                continue
            if completed_at >= four_weeks_ago:
                recent_vol_kg += vol
            else:
                prior_vol_kg += vol

        # Guard against misleading deltas:
        #   - If prior window had zero volume, we can't compute a percentage
        #     (division by zero / unbounded growth) — show 0 instead of an
        #     arbitrary +100%.
        #   - If recent window has zero volume, avoid showing -99%+ when the
        #     user simply hasn't trained in the last 28 days.
        if prior_vol_kg == 0 or recent_vol_kg == 0:
            volume_increase_percent = 0.0
        else:
            volume_increase_percent = ((recent_vol_kg - prior_vol_kg) / prior_vol_kg) * 100

        # total_volume_kg: sum across the 8-week sample we pulled.
        total_volume_kg = total_vol_kg_8w

        # ── total PRs ────────────────────────────────────────────────
        total_prs = getattr(prs_count_result, "count", None)
        if total_prs is None:
            total_prs = len(prs_count_result.data or [])

        # ── avg_weekly_workouts + current_streak ────────────────────
        date_rows = dates_result.data or []
        # Unique completed dates in the user's last 28 days window
        distinct_dates = set()
        all_distinct_dates = set()
        cutoff_28d = (now_utc - timedelta(days=28)).date()
        for r in date_rows:
            dt_str = r.get("completed_at") or r.get("scheduled_date")
            if not dt_str:
                continue
            try:
                d_obj = datetime.fromisoformat(dt_str.replace("Z", "+00:00")).date()
            except Exception:
                continue
            all_distinct_dates.add(d_obj)
            if d_obj >= cutoff_28d:
                distinct_dates.add(d_obj)

        avg_weekly_workouts = round(len(distinct_dates) / 4.0, 2)

        # Current streak — count consecutive days back from today, allowing
        # 1-day rest gaps (so Mon–Wed–Fri still counts as a 3-day streak).
        today = now_utc.date()
        sorted_dates_desc = sorted(all_distinct_dates, reverse=True)
        current_streak = 0
        if sorted_dates_desc and (today - sorted_dates_desc[0]).days <= 1:
            current_streak = 1
            prev = sorted_dates_desc[0]
            for d_obj in sorted_dates_desc[1:]:
                if (prev - d_obj).days <= 2:  # allow 1 rest day between
                    current_streak += 1
                    prev = d_obj
                else:
                    break

        # ── muscle_group_breakdown ──────────────────────────────────
        muscle_breakdown = {}
        for row in muscle_result.data or []:
            mg = row["muscle_group"]
            if mg not in muscle_breakdown:
                muscle_breakdown[mg] = {"muscle_group": mg, "total_sets": 0, "total_volume_kg": 0}
            muscle_breakdown[mg]["total_sets"] += row.get("total_sets", 0)
            muscle_breakdown[mg]["total_volume_kg"] += float(row.get("total_volume_kg", 0))

        # ── recent_prs — map weight_kg/reps onto the old contract ───
        recent_prs = [
            {
                "exercise_name": pr["exercise_name"],
                "weight_kg": float(pr.get("weight_kg") or 0),
                "reps": int(pr.get("reps") or 0),
                "achieved_at": pr["achieved_at"],
            }
            for pr in prs_result.data or []
        ]

        # ── best_week ───────────────────────────────────────────────
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
            total_workouts=total_workouts,
            total_volume_kg=round(total_volume_kg, 2),
            total_prs=int(total_prs or 0),
            first_workout_date=first_workout_date,
            last_workout_date=last_workout_date,
            volume_increase_percent=round(volume_increase_percent, 2),
            avg_weekly_workouts=avg_weekly_workouts,
            current_streak=current_streak,
            muscle_group_breakdown=list(muscle_breakdown.values()),
            recent_prs=recent_prs,
            best_week=best_week
        )

    except Exception as e:
        logger.error(f"Failed to get progress summary: {e}", exc_info=True)
        raise safe_internal_error(e, "progress")


# ============================================================================
# Progressive Overload Dashboard (2026-06)
# ============================================================================
# ONE curated payload for the dashboard so the client makes a single call instead
# of fanning out across /strength, /strength-over-time, /volume-over-time, the
# per-exercise /chart endpoints, and /personal-records. Every DB read is offloaded
# to the thread pool and gathered (never a sync .execute() in the async body).

class OverloadSparklinePoint(BaseModel):
    date: str
    score: int


class OverloadOverall(BaseModel):
    score: int
    level: str
    percentile: Optional[float] = None
    delta_30d: Optional[int] = None
    delta_365d: Optional[int] = None
    sparkline: List[OverloadSparklinePoint] = []


class OverloadSeriesPoint(BaseModel):
    date: str
    value: float


class OverloadMuscle(BaseModel):
    muscle_group: str
    current_score: int
    score_change: Optional[int] = None
    is_establishing: bool = False
    population_percentile: Optional[float] = None
    score_series: List[OverloadSeriesPoint] = []
    volume_series: List[OverloadSeriesPoint] = []


class OverloadExercisePoint(BaseModel):
    date: str
    e1rm_kg: float
    volume_kg: float


class OverloadTopExercise(BaseModel):
    exercise_name: str
    starting_weight: float
    current_weight: float
    starting_e1rm: float
    current_e1rm: float
    all_time_best_e1rm: float
    trend: str
    e1rm_series: List[OverloadExercisePoint] = []


class OverloadMuscleDelta(BaseModel):
    muscle_group: str
    score_change: int


class OverloadLastWorkout(BaseModel):
    completed_at: Optional[str] = None
    muscle_deltas: List[OverloadMuscleDelta] = []


class OverloadDashboardResponse(BaseModel):
    user_id: str
    time_range: str
    overall: OverloadOverall
    muscles: List[OverloadMuscle] = []
    top_exercises: List[OverloadTopExercise] = []
    recent_prs: List[Dict[str, Any]] = []
    last_workout: OverloadLastWorkout = OverloadLastWorkout()


@router.get("/overload-dashboard", response_model=OverloadDashboardResponse)
async def get_overload_dashboard(
    user_id: str = Query(..., description="User ID"),
    time_range: str = Query("12_weeks", description="1_day..all_time / 6_months / 1_year"),
    gym_profile_id: Optional[str] = Query(
        None, description="Filter to a specific gym profile (per-gym progress)."),
    current_user: dict = Depends(get_current_user),
):
    """Curated Progressive Overload Dashboard payload (offloaded fan-out)."""
    if str(current_user.get("id")) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        # exercise_history owns the richer TimeRange (incl. 6mo/1yr) + day mapping
        # + the shared per-exercise series builder. Reuse rather than duplicate.
        from api.v1.exercise_history import (
            TimeRange as ExTimeRange, get_days_for_time_range, build_exercise_series,
        )
        try:
            ex_range = ExTimeRange(time_range)
        except ValueError:
            ex_range = ExTimeRange.TWELVE_WEEKS
        days_back = get_days_for_time_range(ex_range)

        db = get_supabase_db()
        loop = asyncio.get_event_loop()
        now_utc = datetime.now(timezone.utc)
        start_date = (now_utc - timedelta(days=days_back)).date().isoformat()
        d30 = (now_utc - timedelta(days=30)).isoformat()
        d365 = (now_utc - timedelta(days=365)).isoformat()
        latest_view = (
            "latest_strength_scores_by_gym" if gym_profile_id else "latest_strength_scores"
        )

        def _fetch_latest_scores():
            q = db.client.table(latest_view).select("*").eq("user_id", user_id)
            if gym_profile_id:
                q = q.eq("gym_profile_id", gym_profile_id)
            return q.execute()

        def _fetch_score_history():
            # All per-muscle score rows in the window → per-muscle score_series +
            # 30d/365d overall deltas. Scoped to combined (NULL gym) or the gym.
            q = db.client.table("strength_scores").select(
                "muscle_group, strength_score, calculated_at"
            ).eq("user_id", user_id).gte("calculated_at", d365).order(
                "calculated_at", desc=False
            )
            if gym_profile_id:
                q = q.eq("gym_profile_id", gym_profile_id)
            else:
                q = q.is_("gym_profile_id", "null")
            return q.execute()

        def _fetch_volume():
            view = _MUSCLE_WEEKLY_BY_GYM if gym_profile_id else "muscle_group_weekly_volume"
            q = db.client.table(view).select(
                "muscle_group, week_start, total_volume_kg"
            ).eq("user_id", user_id).gte("week_start", start_date).order(
                "week_start", desc=False
            )
            if gym_profile_id:
                q = q.eq("gym_profile_id", gym_profile_id)
            return q.execute()

        def _fetch_top_names():
            # Most-performed exercises in the window (drives top_exercises).
            q = db.client.from_("exercise_workout_history").select(
                "exercise_name, workout_date"
            ).eq("user_id", user_id).gte("workout_date", start_date)
            if gym_profile_id:
                q = q.eq("gym_profile_id", gym_profile_id)
            return q.execute()

        def _fetch_recent_prs():
            return db.client.table("personal_records").select(
                "exercise_name, weight_kg, reps, estimated_1rm_kg, achieved_at"
            ).eq("user_id", user_id).gte("achieved_at", d30).order(
                "achieved_at", desc=True
            ).limit(8).execute()

        def _fetch_last_workout():
            return db.client.table("workout_logs").select(
                "completed_at"
            ).eq("user_id", user_id).eq("status", "completed").order(
                "completed_at", desc=True
            ).limit(1).execute()

        (
            latest_res, hist_res, vol_res, names_res, prs_res, last_res,
        ) = await asyncio.gather(
            loop.run_in_executor(_db_executor, _fetch_latest_scores),
            loop.run_in_executor(_db_executor, _fetch_score_history),
            loop.run_in_executor(_db_executor, _fetch_volume),
            loop.run_in_executor(_db_executor, _fetch_top_names),
            loop.run_in_executor(_db_executor, _fetch_recent_prs),
            loop.run_in_executor(_db_executor, _fetch_last_workout),
        )

        # ── Overall = median of per-muscle current scores (robust to one weak group)
        latest_rows = latest_res.data or []
        by_muscle = {r["muscle_group"]: r for r in latest_rows}
        scores_now = sorted(int(r.get("strength_score") or 0) for r in latest_rows)
        if scores_now:
            mid = len(scores_now) // 2
            overall_score = (
                scores_now[mid] if len(scores_now) % 2
                else round((scores_now[mid - 1] + scores_now[mid]) / 2)
            )
        else:
            overall_score = 0
        overall_level = _level_label(overall_score)
        # Overall percentile = mean of available per-muscle percentiles.
        pcts = [float(r["population_percentile"]) for r in latest_rows
                if r.get("population_percentile") is not None]
        overall_pct = round(sum(pcts) / len(pcts), 1) if pcts else None

        # ── Per-muscle score history → series + overall sparkline/deltas ─────
        hist_rows = hist_res.data or []
        score_series_by_muscle: Dict[str, List[OverloadSeriesPoint]] = {}
        overall_by_date: Dict[str, List[int]] = {}
        for r in hist_rows:
            mg = r.get("muscle_group")
            sc = int(r.get("strength_score") or 0)
            cal = r.get("calculated_at") or ""
            day = cal[:10]
            score_series_by_muscle.setdefault(mg, []).append(
                OverloadSeriesPoint(date=day, value=sc)
            )
            overall_by_date.setdefault(day, []).append(sc)
        # Overall sparkline = daily median across muscles (sorted by date).
        sparkline: List[OverloadSparklinePoint] = []
        for day in sorted(overall_by_date.keys()):
            vals = sorted(overall_by_date[day])
            m = len(vals) // 2
            med = vals[m] if len(vals) % 2 else round((vals[m - 1] + vals[m]) / 2)
            sparkline.append(OverloadSparklinePoint(date=day, score=med))
        delta_30d = _delta_since(sparkline, overall_score, now_utc, 30)
        delta_365d = _delta_since(sparkline, overall_score, now_utc, 365)

        # ── Per-muscle volume series ─────────────────────────────────────────
        vol_by_muscle: Dict[str, List[OverloadSeriesPoint]] = {}
        for r in vol_res.data or []:
            vol_by_muscle.setdefault(r["muscle_group"], []).append(
                OverloadSeriesPoint(
                    date=str(r.get("week_start") or "")[:10],
                    value=float(r.get("total_volume_kg") or 0),
                )
            )

        muscles: List[OverloadMuscle] = []
        all_mgs = set(by_muscle) | set(score_series_by_muscle) | set(vol_by_muscle)
        for mg in sorted(all_mgs):
            row = by_muscle.get(mg, {})
            muscles.append(OverloadMuscle(
                muscle_group=mg,
                current_score=int(row.get("strength_score") or 0),
                score_change=row.get("score_change"),
                is_establishing=bool(row.get("is_establishing") or False),
                population_percentile=row.get("population_percentile"),
                score_series=score_series_by_muscle.get(mg, []),
                volume_series=vol_by_muscle.get(mg, []),
            ))

        # ── Top exercises (by frequency) → per-exercise series via shared helper
        freq: Dict[str, int] = {}
        for r in names_res.data or []:
            nm = (r.get("exercise_name") or "").strip()
            if nm:
                freq[nm] = freq.get(nm, 0) + 1
        top_names = [n for n, _ in sorted(freq.items(), key=lambda x: x[1], reverse=True)[:6]]

        def _build_one(name: str):
            points, trend = build_exercise_series(db, user_id, name, start_date, gym_profile_id)
            return name, points, trend

        series_results = await asyncio.gather(*[
            loop.run_in_executor(_db_executor, _build_one, nm) for nm in top_names
        ]) if top_names else []

        top_exercises: List[OverloadTopExercise] = []
        for name, points, trend in series_results:
            e1rm_pts = [
                OverloadExercisePoint(
                    date=p.date, e1rm_kg=p.estimated_1rm_kg or 0.0, volume_kg=p.volume_kg
                ) for p in points
            ]
            all_time_best = max((p.estimated_1rm_kg or 0.0) for p in points) if points else 0.0
            top_exercises.append(OverloadTopExercise(
                exercise_name=name,
                starting_weight=trend.start_weight,
                current_weight=trend.current_weight,
                starting_e1rm=trend.start_1rm,
                current_e1rm=trend.current_1rm,
                all_time_best_e1rm=round(all_time_best, 2),
                trend=trend.direction,
                e1rm_series=e1rm_pts,
            ))

        # ── Recent PRs (passthrough shape) ───────────────────────────────────
        recent_prs = [
            {
                "exercise_name": r.get("exercise_name"),
                "weight_kg": float(r.get("weight_kg") or 0),
                "reps": int(r.get("reps") or 0),
                "estimated_1rm_kg": float(r.get("estimated_1rm_kg") or 0),
                "achieved_at": r.get("achieved_at"),
            }
            for r in (prs_res.data or [])
        ]

        # ── Last-workout "what changed" — persisted score_change per muscle ──
        last_completed = None
        if last_res.data:
            last_completed = last_res.data[0].get("completed_at")
        muscle_deltas = [
            OverloadMuscleDelta(muscle_group=r["muscle_group"], score_change=int(r["score_change"]))
            for r in latest_rows
            if r.get("score_change") not in (None, 0)
        ]
        muscle_deltas.sort(key=lambda d: abs(d.score_change), reverse=True)

        return OverloadDashboardResponse(
            user_id=user_id,
            time_range=ex_range.value,
            overall=OverloadOverall(
                score=overall_score,
                level=overall_level,
                percentile=overall_pct,
                delta_30d=delta_30d,
                delta_365d=delta_365d,
                sparkline=sparkline,
            ),
            muscles=muscles,
            top_exercises=top_exercises,
            recent_prs=recent_prs,
            last_workout=OverloadLastWorkout(
                completed_at=last_completed, muscle_deltas=muscle_deltas[:4]
            ),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get overload dashboard: {e}", exc_info=True)
        raise safe_internal_error(e, "progress")


def _level_label(score: int) -> str:
    if score >= 90:
        return "elite"
    if score >= 70:
        return "advanced"
    if score >= 50:
        return "intermediate"
    if score >= 25:
        return "novice"
    return "beginner"


def _delta_since(
    sparkline: List["OverloadSparklinePoint"], current: int, now_utc: datetime, days: int
) -> Optional[int]:
    """Overall score delta vs the closest sparkline point ~`days` ago (None if absent)."""
    if not sparkline:
        return None
    cutoff = (now_utc - timedelta(days=days)).date().isoformat()
    # First point on/after the cutoff is our baseline.
    baseline = None
    for p in sparkline:
        if p.date >= cutoff:
            baseline = p.score
            break
    if baseline is None:
        return None
    return int(current - baseline)


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
        logger.error(f"Failed to log chart view: {e}", exc_info=True)
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
        logger.error(f"Failed to get muscle groups: {e}", exc_info=True)
        raise safe_internal_error(e, "progress")


# ============================================
# Helper Functions
# ============================================


def _coerce_jsonb(raw: Any) -> Any:
    """sets_json is jsonb but sometimes comes back as a string."""
    if raw is None:
        return None
    if isinstance(raw, (list, dict)):
        return raw
    if isinstance(raw, str):
        try:
            return json.loads(raw)
        except Exception:
            return None
    return None


def _weight_kg_from_item(item: dict) -> float:
    """Pull weight in kg from a set/exercise row. Accepts
    weight_kg directly, else converts lbs fields."""
    w = item.get("weight_kg")
    if isinstance(w, (int, float)) and w > 0:
        return float(w)
    lb = item.get("weight_lbs")
    if lb is None:
        lb = item.get("weight_lb")
    if isinstance(lb, (int, float)) and lb > 0:
        return float(lb) / 2.20462
    return 0.0


def _volume_from_sets_json_kg(raw: Any) -> float:
    """Mirror of personal_bests._volume_from_sets_json but outputs kg.

    Handles the three production shapes for workout_logs.sets_json:
      A) per-set rows (post-completion logging)
      B) exercise summaries where `sets` is an integer set-count
      C) nested-list under an exercise dict
    """
    payload = _coerce_jsonb(raw)
    if payload is None:
        return 0.0

    total_kg = 0.0

    def _add_row(item: dict) -> None:
        nonlocal total_kg
        w_kg = _weight_kg_from_item(item)
        reps = item.get("reps")
        if not (isinstance(reps, (int, float)) and reps > 0):
            return
        if w_kg <= 0:
            return
        sets_val = item.get("sets")
        set_count = 1
        if isinstance(sets_val, (int, float)) and sets_val > 0:
            set_count = int(sets_val)
        total_kg += w_kg * float(reps) * float(set_count)

    if isinstance(payload, list):
        for el in payload:
            if not isinstance(el, dict):
                continue
            sets_field = el.get("sets")
            if isinstance(sets_field, list):
                for s in sets_field:
                    if isinstance(s, dict):
                        _add_row({**s, "sets": 1})
                continue
            if "reps" in el and (
                "weight_kg" in el or "weight_lbs" in el or "weight_lb" in el
            ):
                _add_row(el)
    elif isinstance(payload, dict):
        arr = payload.get("exercises") or payload.get("sets")
        if isinstance(arr, list):
            return _volume_from_sets_json_kg(arr)

    return total_kg


def _get_cutoff_date(time_range: TimeRange) -> Optional[date]:
    """Get the cutoff date based on time range."""
    if time_range == TimeRange.ALL_TIME:
        return None

    days_map = {
        TimeRange.ONE_DAY: 1,
        TimeRange.THREE_DAYS: 3,
        TimeRange.SEVEN_DAYS: 7,
        TimeRange.FOUR_WEEKS: 28,
        TimeRange.EIGHT_WEEKS: 56,
        TimeRange.TWELVE_WEEKS: 84,
    }

    days = days_map.get(time_range, 84)
    return (datetime.now() - timedelta(days=days)).date()


def _get_week_number(date_str: str) -> int:
    """Extract week number from date string."""
    try:
        d = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        return d.isocalendar()[1]
    except Exception as e:
        logger.debug(f"Failed to parse week number from date string '{date_str}': {e}")
        return 0


def _get_year(date_str: str) -> int:
    """Extract year from date string."""
    try:
        d = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        return d.year
    except Exception as e:
        logger.debug(f"Failed to parse year from date string '{date_str}': {e}")
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
