"""
Muscle Analytics API - Muscle-Level Insights Endpoints.

Provides endpoints for:
- Muscle heatmap data for body diagram visualization
- Training frequency per muscle group
- Muscle balance analysis (push/pull, upper/lower ratios)
- Exercises for specific muscle groups
- Muscle training history over time
"""
from core.db import get_supabase_db

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.timezone_utils import user_today_date
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta, timezone
from pydantic import BaseModel, Field
from enum import Enum
import json

from core.logger import get_logger
from services.strength_calculator_service import StrengthCalculatorService

router = APIRouter(prefix="/muscle-analytics", tags=["Muscle Analytics"])
logger = get_logger(__name__)


# ============================================
# Enums
# ============================================

class TimeRange(str, Enum):
    """Time range options for muscle analytics."""
    ONE_DAY = "1_day"
    THREE_DAYS = "3_days"
    SEVEN_DAYS = "7_days"
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
        TimeRange.ONE_DAY: 1,
        TimeRange.THREE_DAYS: 3,
        TimeRange.SEVEN_DAYS: 7,
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
    current_user: dict = Depends(get_current_user),
):
    """
    Get muscle heatmap data for body diagram visualization.

    Returns intensity scores and colors for each muscle group
    based on training volume in the specified time period.
    """
    verify_user_ownership(current_user, user_id)
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
            logger.warning(f"RPC failed, using fallback query: {rpc_error}", exc_info=True)

        # Fallback: aggregate from workout_logs.sets_json (the real
        # source of truth — the `muscle_training_frequency` view
        # depends on `workout_sets`, which returns empty in prod).
        now_utc = datetime.now(timezone.utc)
        cutoff_dt = now_utc - timedelta(days=days_back)

        logs_result = db.client.table("workout_logs").select(
            "id, sets_json, completed_at"
        ).eq(
            "user_id", user_id
        ).eq(
            "status", "completed"
        ).gte(
            "completed_at", cutoff_dt.isoformat()
        ).execute()

        log_rows = logs_result.data or []

        # Aggregate per primary-muscle-group: sets, volume_kg, unique
        # workout ids, last_trained. Uses the strength calculator's
        # authoritative muscle map so heatmap + strength stay aligned.
        strength_service = StrengthCalculatorService()
        agg: Dict[str, Dict[str, Any]] = {}

        def _coerce(raw):
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

        def _w_kg(item: dict) -> float:
            w = item.get("weight_kg")
            if isinstance(w, (int, float)) and w > 0:
                return float(w)
            lb = item.get("weight_lbs") or item.get("weight_lb")
            if isinstance(lb, (int, float)) and lb > 0:
                return float(lb) / 2.20462
            return 0.0

        for row in log_rows:
            log_id = row.get("id")
            completed_at = row.get("completed_at")
            payload = _coerce(row.get("sets_json"))
            if isinstance(payload, dict):
                payload = payload.get("exercises") or []
            if not isinstance(payload, list):
                continue

            for ex in payload:
                if not isinstance(ex, dict):
                    continue
                name = ex.get("name") or ex.get("exercise_name") or ""
                if not name:
                    continue
                # Pass the per-row exercise dict as fallback metadata so
                # AI-generated bodyweight moves whose names aren't in the
                # static map still attribute to whichever muscle the AI
                # tagged. Without this they silently dropped, leaving the
                # heatmap empty after a bodyweight session.
                muscle_groups = strength_service.get_exercise_muscle_groups(
                    name, exercise_data=ex
                )
                if not muscle_groups:
                    # Generic full_body bucket so a session with unmapped
                    # exercises still shows up — better than vanishing
                    # entirely. Surfaces a discoverable signal in the
                    # heatmap that the user can drill into.
                    muscle_groups = ["full_body"]
                primary = muscle_groups[0]

                # Figure out volume + set count for this exercise.
                sets_field = ex.get("sets")
                set_count = 0
                volume_kg = 0.0
                if isinstance(sets_field, list):
                    set_count = len(sets_field)
                    for s in sets_field:
                        if not isinstance(s, dict):
                            continue
                        w = _w_kg(s)
                        r = s.get("reps") or s.get("reps_completed") or 0
                        if isinstance(r, (int, float)) and r > 0 and w > 0:
                            volume_kg += w * float(r)
                elif isinstance(sets_field, (int, float)) and sets_field > 0:
                    set_count = int(sets_field)
                    w = _w_kg(ex)
                    r = ex.get("reps") or 0
                    if isinstance(r, (int, float)) and r > 0 and w > 0:
                        volume_kg += w * float(r) * float(set_count)
                else:
                    # Per-set row (shape A) with no `sets` field.
                    set_count = 1
                    w = _w_kg(ex)
                    r = ex.get("reps") or ex.get("reps_completed") or 0
                    if isinstance(r, (int, float)) and r > 0 and w > 0:
                        volume_kg += w * float(r)

                if set_count <= 0 and volume_kg <= 0:
                    continue

                bucket = agg.setdefault(primary, {
                    "sets_count": 0,
                    "volume_kg": 0.0,
                    "workout_ids": set(),
                    "last_trained": None,
                })
                bucket["sets_count"] += set_count
                bucket["volume_kg"] += volume_kg
                if log_id is not None:
                    bucket["workout_ids"].add(log_id)
                if completed_at and (
                    bucket["last_trained"] is None
                    or completed_at > bucket["last_trained"]
                ):
                    bucket["last_trained"] = completed_at

        max_volume = max((b["volume_kg"] for b in agg.values()), default=0.0)
        if max_volume <= 0:
            max_volume = 1.0  # avoid div-by-zero; intensities stay 0

        muscles: List[MuscleHeatmapItem] = []
        for mg, stats in agg.items():
            intensity = stats["volume_kg"] / max_volume if max_volume > 0 else 0
            color, hex_color = get_intensity_color(intensity)
            days_since = None
            if stats["last_trained"]:
                try:
                    last_dt = datetime.fromisoformat(
                        str(stats["last_trained"]).replace("Z", "+00:00")
                    )
                    if last_dt.tzinfo is None:
                        last_dt = last_dt.replace(tzinfo=timezone.utc)
                    days_since = (now_utc - last_dt).days
                except Exception:
                    days_since = None

            muscles.append(MuscleHeatmapItem(
                muscle_group=mg,
                intensity=round(intensity, 4),
                intensity_score=int(intensity * 100),
                sets_count=stats["sets_count"],
                volume_kg=round(stats["volume_kg"], 2),
                workout_count=len(stats["workout_ids"]),
                last_trained=stats["last_trained"],
                days_since_training=days_since,
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
            max_volume_kg=round(max_volume if max_volume > 1 else 0.0, 2),
        )

    except Exception as e:
        logger.error(f"Error getting muscle heatmap: {e}", exc_info=True)
        raise safe_internal_error(e, "muscle_heatmap")


@router.get("/frequency", response_model=MuscleFrequencyResponse)
async def get_muscle_training_frequency(
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get training frequency for each muscle group.

    Shows how often each muscle is trained with recommendations
    for optimal training frequency.
    """
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()

        logger.info(f"Getting muscle frequency for user {user_id}")

        # Compute frequency from exercise_workout_history (no dedicated view needed)
        from datetime import timezone
        from collections import defaultdict
        now = datetime.now(timezone.utc)
        d7 = (now - timedelta(days=7)).date().isoformat()
        d30 = (now - timedelta(days=30)).date().isoformat()

        # Use exercise_workout_history (same table the exercises endpoint uses)
        try:
            result = db.client.from_("exercise_workout_history") \
                .select("muscle_group, workout_date, total_volume_kg") \
                .eq("user_id", user_id) \
                .gte("workout_date", d30) \
                .not_.is_("muscle_group", "null") \
                .execute()
        except Exception:
            result = type('R', (), {'data': []})()

        data = result.data or []

        # Aggregate by muscle group
        group_stats = defaultdict(lambda: {
            "count_7d": 0, "count_30d": 0, "total_vol": 0.0,
            "dates": [],
        })

        for row in data:
            mg = row.get("muscle_group", "").lower()
            if not mg:
                continue
            workout_date = row.get("workout_date", "")
            group_stats[mg]["count_30d"] += 1
            group_stats[mg]["total_vol"] += float(row.get("total_volume_kg", 0) or 0)
            if workout_date:
                group_stats[mg]["dates"].append(workout_date)
                if workout_date >= d7:
                    group_stats[mg]["count_7d"] += 1

        frequencies = []
        undertrained_count = 0
        overtrained_count = 0

        for mg, stats in group_stats.items():
            weekly_freq = stats["count_30d"] / 4 if stats["count_30d"] else 0
            recommendation = get_frequency_recommendation(weekly_freq)

            if recommendation == "undertrained":
                undertrained_count += 1
            elif recommendation == "overtrained":
                overtrained_count += 1

            # Calculate days since last training
            dates = sorted(stats["dates"], reverse=True)
            last_date = dates[0] if dates else None
            days_since = None
            if last_date:
                try:
                    last_dt = datetime.fromisoformat(last_date.replace("Z", "+00:00"))
                    days_since = (now - last_dt).days
                except Exception:
                    pass

            frequencies.append(MuscleFrequencyItem(
                muscle_group=mg,
                workout_count_last_7_days=stats["count_7d"],
                workout_count_last_30_days=stats["count_30d"],
                total_workout_count=stats["count_30d"],
                weekly_frequency=round(weekly_freq, 1),
                total_volume_kg=round(stats["total_vol"], 2),
                avg_days_between_training=None,
                last_trained_date=last_date,
                days_since_last_training=days_since,
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
        logger.error(f"Error getting muscle frequency: {e}", exc_info=True)
        raise safe_internal_error(e, "muscle_frequency")


@router.get("/balance", response_model=MuscleBalanceResponse)
async def get_muscle_balance(
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get muscle balance analysis.

    Analyzes push/pull ratio, upper/lower ratio, and other
    antagonist muscle pair balances.
    """
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()

        logger.info(f"Getting muscle balance for user {user_id}")

        # Compute balance from exercise_workout_history (no dedicated view needed)
        from datetime import timezone
        from collections import defaultdict
        d90 = (datetime.now(timezone.utc) - timedelta(days=90)).isoformat()

        try:
            result = db.client.from_("exercise_workout_history") \
                .select("muscle_group, total_volume_kg") \
                .eq("user_id", user_id) \
                .gte("workout_date", d90) \
                .not_.is_("muscle_group", "null") \
                .execute()
        except Exception:
            result = type('R', (), {'data': []})()

        rows = result.data or []

        # Aggregate volume by muscle group
        vol_by_muscle = defaultdict(float)
        for row in rows:
            mg = (row.get("muscle_group") or "").lower()
            if mg:
                vol_by_muscle[mg] += float(row.get("total_volume_kg", 0) or 0)

        # Muscle group classifications
        push_muscles = {"chest", "shoulders", "triceps"}
        pull_muscles = {"back", "lats", "upper_back", "biceps", "rear_delts"}
        upper_muscles = {"chest", "shoulders", "triceps", "back", "lats", "upper_back", "biceps", "rear_delts", "forearms"}
        lower_muscles = {"quads", "hamstrings", "glutes", "calves", "adductors", "abductors"}

        push_vol = sum(vol_by_muscle[m] for m in push_muscles if m in vol_by_muscle)
        pull_vol = sum(vol_by_muscle[m] for m in pull_muscles if m in vol_by_muscle)
        upper_vol = sum(vol_by_muscle[m] for m in upper_muscles if m in vol_by_muscle)
        lower_vol = sum(vol_by_muscle[m] for m in lower_muscles if m in vol_by_muscle)
        chest_vol = vol_by_muscle.get("chest", 0)
        back_vol = sum(vol_by_muscle.get(m, 0) for m in ("back", "lats", "upper_back"))
        quad_vol = vol_by_muscle.get("quads", 0)
        ham_vol = vol_by_muscle.get("hamstrings", 0)

        ratios = []
        recommendations = []

        def _build_ratio(cat, s1_name, s2_name, s1_vol, s2_vol, low, high):
            total = s1_vol + s2_vol
            s1_pct = (s1_vol / total * 100) if total > 0 else 50
            s2_pct = 100 - s1_pct
            ratio_val = (s1_vol / s2_vol) if s2_vol > 0 else 0
            status, _ = get_balance_status(ratio_val, low, high)
            return BalanceRatio(
                category=cat, side1=s1_name, side2=s2_name,
                side1_volume_kg=round(s1_vol, 2), side2_volume_kg=round(s2_vol, 2),
                side1_percent=round(s1_pct, 1), side2_percent=round(s2_pct, 1),
                ratio=round(ratio_val, 2), status=status, recommendation=None,
            ), s1_pct, status

        # Push/Pull
        pp, pp_pct, pp_status = _build_ratio("push_pull", "Push", "Pull", push_vol, pull_vol, 0.8, 1.2)
        pp = pp.model_copy(update={"recommendation": "Add more pulling exercises (rows, pulldowns)" if pp_pct > 55 else ("Add more pushing exercises" if pp_pct < 45 else None)})
        ratios.append(pp)
        if pp_status in ("imbalanced", "severe_imbalance"):
            recommendations.append("Add more pulling exercises to balance push/pull ratio" if pp_pct > 55 else "Add more pushing exercises to balance push/pull ratio")

        # Upper/Lower
        ul, ul_pct, ul_status = _build_ratio("upper_lower", "Upper Body", "Lower Body", upper_vol, lower_vol, 0.8, 1.5)
        ul = ul.model_copy(update={"recommendation": "Add more lower body exercises" if ul_pct > 60 else ("Add more upper body exercises" if ul_pct < 40 else None)})
        ratios.append(ul)
        if ul_status in ("imbalanced", "severe_imbalance"):
            recommendations.append("Add more lower body exercises (squats, deadlifts, lunges)" if ul_pct > 60 else "Add more upper body exercises")

        # Chest/Back
        cb, cb_pct, cb_status = _build_ratio("chest_back", "Chest", "Back", chest_vol, back_vol, 0.7, 1.0)
        cb = cb.model_copy(update={"recommendation": "Add more back exercises for posture" if cb_pct > 55 else None})
        ratios.append(cb)

        # Quad/Hamstring
        qh, _, qh_status = _build_ratio("quad_hamstring", "Quadriceps", "Hamstrings", quad_vol, ham_vol, 1.5, 2.5)
        qh = qh.model_copy(update={"recommendation": "Add more hamstring exercises (RDLs, leg curls)" if qh.ratio > 3 else None})
        ratios.append(qh)

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
        logger.error(f"Error getting muscle balance: {e}", exc_info=True)
        raise safe_internal_error(e, "muscle_balance")


@router.get("/muscle/{muscle_group}/exercises", response_model=MuscleExercisesResponse)
async def get_exercises_for_muscle(
    muscle_group: str,
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get all exercises performed for a specific muscle group.

    Shows which exercises target this muscle with volume
    and frequency statistics.
    """
    verify_user_ownership(current_user, user_id)
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
            logger.warning(f"RPC failed, using fallback: {rpc_error}", exc_info=True)

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
        logger.error(f"Error getting exercises for muscle: {e}", exc_info=True)
        raise safe_internal_error(e, "muscle_exercises")


@router.get("/muscle/{muscle_group}/history", response_model=MuscleHistoryResponse)
async def get_muscle_history(
    muscle_group: str,
    request: Request,
    user_id: str = Query(..., description="User ID"),
    time_range: TimeRange = Query(TimeRange.TWELVE_WEEKS, description="Time range for history"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get historical training data for a specific muscle group.

    Shows weekly training volume trends over time.
    """
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        days_back = get_days_for_time_range(time_range)
        start_date = (user_today_date(request) - timedelta(days=days_back)).isoformat()

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
        logger.error(f"Error getting muscle history: {e}", exc_info=True)
        raise safe_internal_error(e, "muscle_history")


@router.post("/log-view")
async def log_muscle_analytics_view(request: ViewLogRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Log when a user views muscle analytics for tracking engagement.
    """
    verify_user_ownership(current_user, request.user_id)
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
        logger.warning(f"Failed to log muscle analytics view: {e}", exc_info=True)
        return {"status": "error", "message": "Failed to log view"}
