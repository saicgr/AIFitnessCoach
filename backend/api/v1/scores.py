"""
Scores API Endpoints
====================
Handles strength scores, readiness scores, personal records, nutrition scores,
and combined fitness scores.

Endpoints:
- POST /readiness - Submit daily readiness check-in
- GET /readiness/{date} - Get readiness for specific date
- GET /readiness/history - Get readiness history
- GET /strength - Get all muscle group strength scores
- GET /strength/{muscle_group} - Get specific muscle strength detail
- POST /strength/calculate - Trigger strength score recalculation
- GET /personal-records - Get all personal records
- GET /personal-records/{exercise} - Get PRs for specific exercise
- GET /nutrition - Get weekly nutrition score
- POST /nutrition/calculate - Calculate nutrition score
- GET /fitness - Get overall fitness score
- POST /fitness/calculate - Calculate overall fitness score
- GET /overview - Combined dashboard data
"""

from .scores_models import *  # noqa: F401, F403
from .scores_endpoints import router as _endpoints_router


from datetime import datetime, date, timedelta, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Query, Depends, BackgroundTasks, Request
from core.auth import get_current_user, verify_user_ownership
from core.timezone_utils import user_today_date, resolve_timezone
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field

from core.db import get_supabase_db
from services.strength_calculator_service import (
    StrengthCalculatorService,
    StrengthLevel,
    MuscleGroup,
)
from services.readiness_service import (
    ReadinessService,
    ReadinessCheckIn,
    ReadinessLevel,
    WorkoutIntensity,
)
from services.personal_records_service import PersonalRecordsService
from services.ai_insights_service import ai_insights_service
from services.nutrition_calculator_service import (
    NutritionCalculatorService,
    NutritionScore,
    NutritionLevel,
    NutritionTargets,
    DailyNutrition,
)
from services.fitness_score_calculator_service import (
    FitnessScoreCalculatorService,
    FitnessScore,
    FitnessLevel,
)
from services.user_context_service import user_context_service, EventType

import logging
import json

logger = logging.getLogger(__name__)

router = APIRouter()


# ============================================================================
# Helper Functions
# ============================================================================


def _coerce_sets_json(raw) -> Any:
    """Workout_logs.sets_json is jsonb but occasionally arrives as str."""
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


def _weight_kg(item: dict) -> float:
    """Extract weight in kg (prefers weight_kg, converts lbs when needed)."""
    w = item.get("weight_kg")
    if isinstance(w, (int, float)) and w > 0:
        return float(w)
    lb = item.get("weight_lbs")
    if lb is None:
        lb = item.get("weight_lb")
    if isinstance(lb, (int, float)) and lb > 0:
        return float(lb) / 2.20462
    return 0.0


def _flatten_logs_for_strength(log_rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Flatten workout_logs.sets_json rows into the per-exercise shape
    StrengthCalculatorService.calculate_all_muscle_scores expects:

        [{exercise_name, weight_kg, reps, sets}, ...]

    Handles the three sets_json shapes in production:
      A) Per-set rows with exercise_name embedded — group by name, keep the
         best set's (weight, reps) and count sets.
      B) Exercise summary with integer sets count and top-level weight/reps.
      C) Nested list: {name, sets: [ {weight, reps}, ... ]}
    """
    # First pass: accumulate per-exercise best set + set count across ALL logs
    best: Dict[str, Dict[str, Any]] = {}

    def _consider(name: str, weight_kg: float, reps: int, set_count: int):
        if not name or weight_kg <= 0 or reps <= 0 or set_count <= 0:
            return
        key = name.strip().lower()
        score = weight_kg * reps
        prev = best.get(key)
        if prev is None or score > prev["_score"]:
            best[key] = {
                "exercise_name": name,
                "weight_kg": weight_kg,
                "reps": int(reps),
                "sets": int(set_count),
                "_score": score,
            }
        else:
            # Same exercise logged again — accumulate the set count so the
            # downstream weekly_sets aggregation reflects real volume.
            prev["sets"] = int(prev["sets"]) + int(set_count)

    for row in log_rows:
        payload = _coerce_sets_json(row.get("sets_json"))
        if not isinstance(payload, list):
            # Shape wrapped in a dict under "exercises"
            if isinstance(payload, dict):
                payload = payload.get("exercises") or []
            else:
                continue
            if not isinstance(payload, list):
                continue

        for el in payload:
            if not isinstance(el, dict):
                continue
            name = el.get("name") or el.get("exercise_name") or ""
            sets_field = el.get("sets")

            if isinstance(sets_field, list):
                # Shape C: nested sets — find the best set, count len.
                best_w, best_r = 0.0, 0
                for s in sets_field:
                    if not isinstance(s, dict):
                        continue
                    sw = _weight_kg(s)
                    sr = s.get("reps") or s.get("reps_completed")
                    if not (isinstance(sr, (int, float)) and sr > 0):
                        continue
                    if sw * sr > best_w * best_r:
                        best_w, best_r = sw, int(sr)
                _consider(name, best_w, best_r, len(sets_field))
                continue

            # Shape B: integer set count.
            if isinstance(sets_field, (int, float)) and sets_field > 0:
                set_count = int(sets_field)
                w_kg = _weight_kg(el)
                reps = el.get("reps")
                if isinstance(reps, (int, float)) and reps > 0:
                    _consider(name, w_kg, int(reps), set_count)
                continue

            # Shape A fallback: per-set row missing a sets field — 1 set.
            w_kg = _weight_kg(el)
            reps = el.get("reps") or el.get("reps_completed")
            if isinstance(reps, (int, float)) and reps > 0 and w_kg > 0:
                _consider(name, w_kg, int(reps), 1)

    out = []
    for entry in best.values():
        entry.pop("_score", None)
        out.append(entry)
    return out


def get_user_body_info(user_data: dict) -> tuple[float, str]:
    """
    Extract bodyweight and gender from user data.

    Primary source is the dedicated columns. Falls back to preferences JSON
    for backwards compatibility with users who onboarded before the column
    migration (run scripts/backfill_user_columns.py to fix these).

    Args:
        user_data: User row from database with weight_kg, gender, and preferences columns

    Returns:
        Tuple of (bodyweight_kg: float, gender: str) with defaults if not found
    """
    weight_kg = user_data.get("weight_kg")
    gender_val = user_data.get("gender")

    # Fallback to preferences JSON for backwards compatibility
    if weight_kg is None or gender_val is None:
        prefs = user_data.get("preferences")
        if isinstance(prefs, str):
            try:
                prefs = json.loads(prefs)
            except (json.JSONDecodeError, TypeError):
                prefs = {}
        elif not isinstance(prefs, dict):
            prefs = {}

        if weight_kg is None:
            weight_kg = prefs.get("weight_kg")
        if gender_val is None:
            gender_val = prefs.get("gender")

    return float(weight_kg or 70), gender_val or "male"


# ============================================================================
# Pydantic Models - Readiness
# ============================================================================

class ReadinessCheckInRequest(BaseModel):
    """Request model for daily readiness check-in."""
    user_id: str
    score_date: Optional[date] = None  # Defaults to today
    sleep_quality: int = Field(..., ge=1, le=7, description="1=excellent, 7=very poor")
    fatigue_level: int = Field(..., ge=1, le=7, description="1=fresh, 7=exhausted")
    stress_level: int = Field(..., ge=1, le=7, description="1=relaxed, 7=extremely stressed")
    muscle_soreness: int = Field(..., ge=1, le=7, description="1=none, 7=severe")
    mood: Optional[int] = Field(None, ge=1, le=7)
    energy_level: Optional[int] = Field(None, ge=1, le=7)
    sleep_minutes: Optional[int] = Field(None, ge=0, description="Objective sleep duration in minutes from wearable")
    objective_recovery_score: Optional[int] = Field(None, ge=0, le=100, description="Objective recovery score from wearable (0-100)")
    mood_emoji: Optional[str] = Field(None, description="Emoji representing user's mood")
    notes: Optional[str] = Field(None, description="Free-text wellness notes")


class ReadinessResponse(BaseModel):
    """Response model for readiness data."""
    id: str
    user_id: str
    score_date: date
    sleep_quality: int
    fatigue_level: int
    stress_level: int
    muscle_soreness: int
    mood: Optional[int] = None
    energy_level: Optional[int] = None
    hooper_index: int
    readiness_score: int
    readiness_level: str
    ai_workout_recommendation: Optional[str] = None
    recommended_intensity: Optional[str] = None
    ai_insight: Optional[str] = None
    mood_emoji: Optional[str] = None
    notes: Optional[str] = None
    submitted_at: datetime
    created_at: datetime


class ReadinessHistoryResponse(BaseModel):
    """Response model for readiness history."""
    readiness_scores: List[ReadinessResponse]
    average_score: float
    trend: str
    days_above_60: int
    total_days: int


# ============================================================================
# Pydantic Models - Strength
# ============================================================================

class StrengthScoreResponse(BaseModel):
    """Response model for muscle group strength score."""
    id: Optional[str] = None
    user_id: str
    muscle_group: str
    strength_score: int
    strength_level: str
    best_exercise_name: Optional[str] = None
    best_estimated_1rm_kg: Optional[float] = None
    bodyweight_ratio: Optional[float] = None
    weekly_sets: int = 0
    weekly_volume_kg: float = 0
    trend: str = "maintaining"
    previous_score: Optional[int] = None
    score_change: Optional[int] = None
    calculated_at: Optional[datetime] = None


class AllStrengthScoresResponse(BaseModel):
    """Response model for all strength scores."""
    user_id: str
    overall_score: int
    overall_level: str
    muscle_scores: Dict[str, StrengthScoreResponse]
    calculated_at: datetime


class StrengthDetailResponse(BaseModel):
    """Response model for detailed muscle group strength."""
    muscle_group: str
    strength_score: int
    strength_level: str
    best_exercise_name: Optional[str] = None
    best_estimated_1rm_kg: Optional[float] = None
    bodyweight_ratio: Optional[float] = None
    exercises: List[Dict[str, Any]]
    trend_data: List[Dict[str, Any]]
    recommendations: List[str]


# ============================================================================
# Pydantic Models - Personal Records
# ============================================================================

class PersonalRecordResponse(BaseModel):
    """Response model for a personal record."""
    id: str
    user_id: str
    exercise_name: str
    exercise_id: Optional[str] = None
    muscle_group: Optional[str] = None
    weight_kg: float
    reps: int
    estimated_1rm_kg: float
    set_type: str = "working"
    rpe: Optional[float] = None
    achieved_at: datetime
    workout_id: Optional[str] = None
    previous_weight_kg: Optional[float] = None
    previous_1rm_kg: Optional[float] = None
    improvement_kg: Optional[float] = None
    improvement_percent: Optional[float] = None
    is_all_time_pr: bool = True
    celebration_message: Optional[str] = None
    created_at: datetime


class PRStatsResponse(BaseModel):
    """Response model for PR statistics."""
    total_prs: int
    prs_this_period: int
    exercises_with_prs: int
    best_improvement_percent: Optional[float] = None
    most_improved_exercise: Optional[str] = None
    longest_pr_streak: int
    current_pr_streak: int
    recent_prs: List[PersonalRecordResponse]


# ============================================================================
# Pydantic Models - Nutrition Score
# ============================================================================

class NutritionScoreResponse(BaseModel):
    """Response model for weekly nutrition score."""
    id: Optional[str] = None
    user_id: str
    week_start: Optional[date] = None
    week_end: Optional[date] = None
    days_logged: int = 0
    total_days: int = 7
    adherence_percent: float = 0.0
    calorie_adherence_percent: float = 0.0
    protein_adherence_percent: float = 0.0
    carb_adherence_percent: float = 0.0
    fat_adherence_percent: float = 0.0
    avg_health_score: float = 0.0
    fiber_target_met_days: int = 0
    nutrition_score: int = 0
    nutrition_level: str = "needs_work"
    ai_weekly_summary: Optional[str] = None
    ai_improvement_tips: List[str] = []
    calculated_at: Optional[datetime] = None


class NutritionCalculateRequest(BaseModel):
    """Request model for calculating nutrition score."""
    user_id: str
    week_start: Optional[date] = None  # Defaults to current week


# ============================================================================
# Pydantic Models - Fitness Score
# ============================================================================

class FitnessScoreResponse(BaseModel):
    """Response model for overall fitness score."""
    id: Optional[str] = None
    user_id: str
    calculated_date: Optional[date] = None
    strength_score: int = 0
    readiness_score: int = 0
    consistency_score: int = 0
    nutrition_score: int = 0
    overall_fitness_score: int = 0
    fitness_level: str = "beginner"
    strength_weight: float = 0.40
    consistency_weight: float = 0.30
    nutrition_weight: float = 0.20
    readiness_weight: float = 0.10
    ai_summary: Optional[str] = None
    focus_recommendation: Optional[str] = None
    previous_score: Optional[int] = None
    score_change: Optional[int] = None
    trend: str = "maintaining"
    calculated_at: Optional[datetime] = None


class FitnessScoreBreakdownResponse(BaseModel):
    """Response model for fitness score with breakdown."""
    fitness_score: FitnessScoreResponse
    breakdown: List[Dict[str, Any]]
    level_description: str
    level_color: str


class FitnessCalculateRequest(BaseModel):
    """Request model for calculating fitness score."""
    user_id: str


# ============================================================================
# Pydantic Models - Overview
# ============================================================================

class ScoresOverviewResponse(BaseModel):
    """Combined dashboard response."""
    user_id: str
    today_readiness: Optional[ReadinessResponse] = None
    has_checked_in_today: bool
    overall_strength_score: int
    overall_strength_level: str
    muscle_scores_summary: Dict[str, int]
    recent_prs: List[PersonalRecordResponse]
    pr_count_30_days: int
    readiness_average_7_days: Optional[float] = None
    # New fitness score fields
    nutrition_score: Optional[int] = None
    nutrition_level: Optional[str] = None
    consistency_score: Optional[int] = None
    overall_fitness_score: Optional[int] = None
    fitness_level: Optional[str] = None


# ============================================================================
# Readiness Endpoints
# ============================================================================

@router.post("/readiness", response_model=ReadinessResponse, tags=["Readiness"])
async def submit_readiness_checkin(
    request: ReadinessCheckInRequest,
    background_tasks: BackgroundTasks,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Submit daily readiness check-in.

    Uses the Hooper Index methodology to calculate readiness score.
    """
    verify_user_ownership(current_user, request.user_id)
    db = get_supabase_db()
    readiness_service = ReadinessService()

    # Determine date
    check_date = request.score_date or user_today_date(http_request, db, request.user_id)

    # Create check-in object
    check_in = ReadinessCheckIn(
        sleep_quality=request.sleep_quality,
        fatigue_level=request.fatigue_level,
        stress_level=request.stress_level,
        muscle_soreness=request.muscle_soreness,
        mood=request.mood,
        energy_level=request.energy_level,
        mood_emoji=request.mood_emoji,
        notes=request.notes,
    )

    # Calculate readiness (with optional objective data blending)
    result = readiness_service.calculate_readiness(
        check_in,
        objective_sleep_minutes=request.sleep_minutes,
        objective_recovery_score=request.objective_recovery_score,
    )

    # Prepare data for database
    record_data = {
        "user_id": request.user_id,
        "score_date": check_date.isoformat(),
        "sleep_quality": request.sleep_quality,
        "fatigue_level": request.fatigue_level,
        "stress_level": request.stress_level,
        "muscle_soreness": request.muscle_soreness,
        "mood": request.mood,
        "energy_level": request.energy_level,
        "hooper_index": result.hooper_index,
        "readiness_score": result.readiness_score,
        "readiness_level": result.readiness_level.value,
        "ai_workout_recommendation": result.ai_workout_recommendation,
        "recommended_intensity": result.recommended_intensity.value,
        "ai_insight": result.ai_insight,
        "mood_emoji": request.mood_emoji,
        "notes": request.notes,
        "submitted_at": datetime.now().isoformat(),
    }

    # Upsert (update if exists for today)
    response = db.client.table("readiness_scores").upsert(
        record_data,
        on_conflict="user_id,score_date",
    ).execute()

    if not response.data:
        raise safe_internal_error(ValueError("Failed to save readiness check-in"), "scores")

    record = response.data[0]

    # Generate AI recommendation in background and update record
    tz_str = resolve_timezone(http_request, db, request.user_id)
    background_tasks.add_task(
        generate_ai_readiness_insight,
        user_id=request.user_id,
        record_id=record["id"],
        readiness_data={
            "sleep_quality": request.sleep_quality,
            "fatigue_level": request.fatigue_level,
            "stress_level": request.stress_level,
            "muscle_soreness": request.muscle_soreness,
            "readiness_score": result.readiness_score,
            "readiness_level": result.readiness_level.value,
        },
        db=db,
        timezone_str=tz_str,
    )

    return ReadinessResponse(
        id=record["id"],
        user_id=record["user_id"],
        score_date=date.fromisoformat(record["score_date"]),
        sleep_quality=record["sleep_quality"],
        fatigue_level=record["fatigue_level"],
        stress_level=record["stress_level"],
        muscle_soreness=record["muscle_soreness"],
        mood=record.get("mood"),
        energy_level=record.get("energy_level"),
        hooper_index=record["hooper_index"],
        readiness_score=record["readiness_score"],
        readiness_level=record["readiness_level"],
        ai_workout_recommendation=record.get("ai_workout_recommendation"),
        recommended_intensity=record.get("recommended_intensity"),
        ai_insight=record.get("ai_insight"),
        submitted_at=datetime.fromisoformat(record["submitted_at"]),
        created_at=datetime.fromisoformat(record["created_at"]),
    )


@router.get("/readiness/{score_date}", response_model=Optional[ReadinessResponse], tags=["Readiness"])
async def get_readiness_for_date(
    score_date: date,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Get readiness score for a specific date."""
    verify_user_ownership(current_user, user_id)
    db = get_supabase_db()

    response = db.client.table("readiness_scores").select("*").eq(
        "user_id", user_id
    ).eq(
        "score_date", score_date.isoformat()
    ).maybe_single().execute()

    if not response or not response.data:
        return None

    record = response.data
    return ReadinessResponse(
        id=record["id"],
        user_id=record["user_id"],
        score_date=date.fromisoformat(record["score_date"]),
        sleep_quality=record["sleep_quality"],
        fatigue_level=record["fatigue_level"],
        stress_level=record["stress_level"],
        muscle_soreness=record["muscle_soreness"],
        mood=record.get("mood"),
        energy_level=record.get("energy_level"),
        hooper_index=record["hooper_index"],
        readiness_score=record["readiness_score"],
        readiness_level=record["readiness_level"],
        ai_workout_recommendation=record.get("ai_workout_recommendation"),
        recommended_intensity=record.get("recommended_intensity"),
        ai_insight=record.get("ai_insight"),
        submitted_at=datetime.fromisoformat(record["submitted_at"]),
        created_at=datetime.fromisoformat(record["created_at"]),
    )


@router.get("/readiness/history", response_model=ReadinessHistoryResponse, tags=["Readiness"])
async def get_readiness_history(
    http_request: Request,
    user_id: str = Query(...),
    days: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
):
    """Get readiness history for specified number of days."""
    verify_user_ownership(current_user, user_id)
    db = get_supabase_db()
    readiness_service = ReadinessService()

    start_date = (user_today_date(http_request, db, user_id) - timedelta(days=days)).isoformat()

    response = db.client.table("readiness_scores").select("*").eq(
        "user_id", user_id
    ).gte(
        "score_date", start_date
    ).order(
        "score_date", desc=True
    ).execute()

    records = response.data or []

    # Convert to response objects
    readiness_scores = [
        ReadinessResponse(
            id=r["id"],
            user_id=r["user_id"],
            score_date=date.fromisoformat(r["score_date"]),
            sleep_quality=r["sleep_quality"],
            fatigue_level=r["fatigue_level"],
            stress_level=r["stress_level"],
            muscle_soreness=r["muscle_soreness"],
            mood=r.get("mood"),
            energy_level=r.get("energy_level"),
            hooper_index=r["hooper_index"],
            readiness_score=r["readiness_score"],
            readiness_level=r["readiness_level"],
            ai_workout_recommendation=r.get("ai_workout_recommendation"),
            recommended_intensity=r.get("recommended_intensity"),
            ai_insight=r.get("ai_insight"),
            submitted_at=datetime.fromisoformat(r["submitted_at"]),
            created_at=datetime.fromisoformat(r["created_at"]),
        )
        for r in records
    ]

    # Calculate trend
    scores = [r.readiness_score for r in readiness_scores]
    trend_data = readiness_service.calculate_readiness_trend(
        scores[0] if scores else 0,
        scores[1:] if len(scores) > 1 else [],
        days,
    )

    return ReadinessHistoryResponse(
        readiness_scores=readiness_scores,
        average_score=trend_data["average"],
        trend=trend_data["trend"],
        days_above_60=trend_data["days_above_60"],
        total_days=len(readiness_scores),
    )


# ============================================================================
# Strength Score Endpoints
# ============================================================================

@router.get("/strength", response_model=AllStrengthScoresResponse, tags=["Strength"])
async def get_all_strength_scores(
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Get all muscle group strength scores for a user."""
    db = get_supabase_db()
    strength_service = StrengthCalculatorService()

    # Get user's bodyweight and gender (check column first, then preferences JSON)
    user_response = db.client.table("users").select("weight_kg, gender, preferences").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response or not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    bodyweight, gender = get_user_body_info(user_response.data)

    # Get latest strength scores from database
    scores_response = db.client.table("latest_strength_scores").select("*").eq(
        "user_id", user_id
    ).execute()

    muscle_scores = {}

    if scores_response and scores_response.data:
        for record in scores_response.data:
            muscle_scores[record["muscle_group"]] = StrengthScoreResponse(
                id=record["id"],
                user_id=record["user_id"],
                muscle_group=record["muscle_group"],
                strength_score=record["strength_score"] or 0,
                strength_level=record["strength_level"] or "beginner",
                best_exercise_name=record.get("best_exercise_name"),
                best_estimated_1rm_kg=record.get("best_estimated_1rm_kg"),
                bodyweight_ratio=record.get("bodyweight_ratio"),
                trend=record.get("trend", "maintaining"),
                calculated_at=datetime.fromisoformat(record["calculated_at"]) if record.get("calculated_at") else None,
            )

    # Fill in missing muscle groups with defaults
    for mg in MuscleGroup:
        if mg.value not in muscle_scores:
            muscle_scores[mg.value] = StrengthScoreResponse(
                user_id=user_id,
                muscle_group=mg.value,
                strength_score=0,
                strength_level="beginner",
            )

    # Calculate overall score
    score_objects = {
        k: type('obj', (object,), {'strength_score': v.strength_score})()
        for k, v in muscle_scores.items()
    }
    overall_score, overall_level = strength_service.calculate_overall_strength_score(score_objects)

    return AllStrengthScoresResponse(
        user_id=user_id,
        overall_score=overall_score,
        overall_level=overall_level.value,
        muscle_scores=muscle_scores,
        calculated_at=datetime.now(),
    )


@router.get("/strength/{muscle_group}", response_model=StrengthDetailResponse, tags=["Strength"])
async def get_strength_detail(
    muscle_group: str,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Get detailed strength information for a specific muscle group."""
    db = get_supabase_db()
    strength_service = StrengthCalculatorService()

    # Validate muscle group
    try:
        mg = MuscleGroup(muscle_group.lower())
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid muscle group: {muscle_group}")

    # Get user info (check column first, then preferences JSON)
    user_response = db.client.table("users").select("weight_kg, gender, preferences").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response or not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    bodyweight, gender = get_user_body_info(user_response.data)

    # Get latest strength score
    score_response = db.client.table("latest_strength_scores").select("*").eq(
        "user_id", user_id
    ).eq(
        "muscle_group", muscle_group.lower()
    ).maybe_single().execute()

    # Get exercises for this muscle group from workout history
    # This is simplified - in production, would query workout logs
    exercises = []

    # Get trend data (historical scores)
    trend_response = db.client.table("strength_scores").select(
        "strength_score, calculated_at"
    ).eq(
        "user_id", user_id
    ).eq(
        "muscle_group", muscle_group.lower()
    ).order(
        "calculated_at", desc=True
    ).limit(12).execute()

    trend_data = [
        {
            "score": r["strength_score"],
            "date": r["calculated_at"],
        }
        for r in (trend_response.data or [])
    ]

    score_data = score_response.data or {}

    return StrengthDetailResponse(
        muscle_group=muscle_group.lower(),
        strength_score=score_data.get("strength_score", 0),
        strength_level=score_data.get("strength_level", "beginner"),
        best_exercise_name=score_data.get("best_exercise_name"),
        best_estimated_1rm_kg=score_data.get("best_estimated_1rm_kg"),
        bodyweight_ratio=score_data.get("bodyweight_ratio"),
        exercises=exercises,
        trend_data=trend_data,
        recommendations=[
            f"Focus on compound exercises for {muscle_group}",
            "Track your lifts consistently for accurate scoring",
            "Aim for progressive overload each week",
        ],
    )


@router.post("/strength/calculate", tags=["Strength"])
async def calculate_strength_scores(
    http_request: Request,
    user_id: str = Query(...),
    background_tasks: BackgroundTasks = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Trigger recalculation of strength scores.

    Analyzes workout history and updates all muscle group scores.
    """
    db = get_supabase_db()
    strength_service = StrengthCalculatorService()
    today = user_today_date(http_request, db, user_id)

    # Get user info (check column first, then preferences JSON)
    user_response = db.client.table("users").select("weight_kg, gender, preferences").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response or not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    bodyweight, gender = get_user_body_info(user_response.data)

    # Get workout data from last 90 days — PROD schema note:
    # `workouts.completed` does NOT exist and `workouts.exercises` is
    # frequently empty on logged (post-hoc) sessions. The source of
    # truth for volume is `workout_logs.sets_json`, the same jsonb
    # column used by personal_bests and heatmap aggregations.
    cutoff = datetime.now(timezone.utc) - timedelta(days=90)

    logs_response = db.client.table("workout_logs").select(
        "sets_json, completed_at"
    ).eq(
        "user_id", user_id
    ).eq(
        "status", "completed"
    ).gte(
        "completed_at", cutoff.isoformat()
    ).execute()

    # Extract exercise performances from sets_json. We emit one row per
    # exercise per log in the shape calculate_all_muscle_scores expects:
    #   { exercise_name, weight_kg, reps, sets }
    workout_data = _flatten_logs_for_strength(logs_response.data or [])

    # Calculate scores for all muscle groups
    muscle_scores = strength_service.calculate_all_muscle_scores(
        workout_data, bodyweight, gender
    )

    # Get previous scores for trend calculation
    previous_response = db.client.table("latest_strength_scores").select(
        "muscle_group, strength_score"
    ).eq("user_id", user_id).execute()

    previous_scores = {
        r["muscle_group"]: r["strength_score"]
        for r in (previous_response.data or [])
    }

    # Save new scores
    now = datetime.now()
    period_end = today
    period_start = period_end - timedelta(days=7)

    for mg, score in muscle_scores.items():
        prev_score = previous_scores.get(mg)

        # Determine trend
        if prev_score is not None:
            if score.strength_score > prev_score + 2:
                trend = "improving"
            elif score.strength_score < prev_score - 2:
                trend = "declining"
            else:
                trend = "maintaining"
            score_change = score.strength_score - prev_score
        else:
            trend = "maintaining"
            score_change = None

        record_data = {
            "user_id": user_id,
            "muscle_group": mg,
            "strength_score": score.strength_score,
            "strength_level": score.strength_level.value,
            "best_exercise_name": score.best_exercise_name,
            "best_estimated_1rm_kg": score.best_estimated_1rm_kg,
            "bodyweight_ratio": score.bodyweight_ratio,
            "weekly_sets": score.weekly_sets,
            "weekly_volume_kg": score.weekly_volume_kg,
            "previous_score": prev_score,
            "score_change": score_change,
            "trend": trend,
            "calculated_at": now.isoformat(),
            "period_start": period_start.isoformat(),
            "period_end": period_end.isoformat(),
        }

        db.client.table("strength_scores").insert(record_data).execute()

    return {
        "success": True,
        "message": f"Calculated strength scores for {len(muscle_scores)} muscle groups",
        "calculated_at": now.isoformat(),
    }


# ============================================================================
# Personal Records Endpoints
# ============================================================================

@router.get("/personal-records", response_model=PRStatsResponse, tags=["Personal Records"])
async def get_personal_records(
    user_id: str = Query(...),
    limit: int = Query(10, ge=1, le=50),
    period_days: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
):
    """Get personal records and statistics for a user."""
    db = get_supabase_db()
    pr_service = PersonalRecordsService()

    # Get all PRs
    response = db.client.table("personal_records").select("*").eq(
        "user_id", user_id
    ).order(
        "achieved_at", desc=True
    ).execute()

    all_prs = response.data or []

    # Calculate statistics
    stats = pr_service.get_pr_statistics(all_prs, period_days)

    # Get recent PRs
    recent_prs = [
        PersonalRecordResponse(
            id=pr["id"],
            user_id=pr["user_id"],
            exercise_name=pr["exercise_name"],
            exercise_id=pr.get("exercise_id"),
            muscle_group=pr.get("muscle_group"),
            weight_kg=float(pr["weight_kg"]),
            reps=int(pr["reps"]),
            estimated_1rm_kg=float(pr["estimated_1rm_kg"]),
            set_type=pr.get("set_type", "working"),
            rpe=float(pr["rpe"]) if pr.get("rpe") else None,
            achieved_at=datetime.fromisoformat(pr["achieved_at"]),
            workout_id=pr.get("workout_id"),
            previous_weight_kg=float(pr["previous_weight_kg"]) if pr.get("previous_weight_kg") else None,
            previous_1rm_kg=float(pr["previous_1rm_kg"]) if pr.get("previous_1rm_kg") else None,
            improvement_kg=float(pr["improvement_kg"]) if pr.get("improvement_kg") else None,
            improvement_percent=float(pr["improvement_percent"]) if pr.get("improvement_percent") else None,
            is_all_time_pr=pr.get("is_all_time_pr", True),
            celebration_message=pr.get("celebration_message"),
            created_at=datetime.fromisoformat(pr["created_at"]),
        )
        for pr in all_prs[:limit]
    ]

    return PRStatsResponse(
        total_prs=stats["total_prs"],
        prs_this_period=stats["prs_this_period"],
        exercises_with_prs=stats["exercises_with_prs"],
        best_improvement_percent=stats["best_improvement_percent"],
        most_improved_exercise=stats["most_improved_exercise"],
        longest_pr_streak=stats["longest_pr_streak"],
        current_pr_streak=stats["current_pr_streak"],
        recent_prs=recent_prs,
    )



# =============================================================================
# Weekly volume per muscle — feeds the Flutter weekly-volume bars widget.
# =============================================================================

class WeeklyVolumeEntry(BaseModel):
    muscle_group: str
    weekly_sets: int
    weekly_volume_kg: float
    cap_sets: Optional[int] = None
    pct_of_cap: Optional[float] = None


class WeeklyVolumePerMuscleResponse(BaseModel):
    muscles: List[WeeklyVolumeEntry]


@router.get("/weekly-volume-per-muscle", response_model=WeeklyVolumePerMuscleResponse, tags=["Strength"])
async def weekly_volume_per_muscle(current_user: dict = Depends(get_current_user)):
    """Per-muscle weekly sets / volume + strain cap context.

    Reads existing `strength_scores` (latest row per muscle) and
    `muscle_volume_caps` so the UI can render bars with "at cap" shading
    without issuing two round-trips.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Latest strength_scores row per muscle_group. Supabase-Python has no
        # DISTINCT-ON; order + group in app code.
        rows = db.client.table("strength_scores").select(
            "muscle_group, weekly_sets, weekly_volume_kg, calculated_at"
        ).eq("user_id", user_id).order(
            "calculated_at", desc=True
        ).execute()
        latest_by_muscle: Dict[str, Dict[str, Any]] = {}
        for row in rows.data or []:
            mg = row.get("muscle_group")
            if mg and mg not in latest_by_muscle:
                latest_by_muscle[mg] = row

        caps: Dict[str, int] = {}
        try:
            cap_rows = db.client.table("muscle_volume_caps").select(
                "muscle_group, max_weekly_sets"
            ).eq("user_id", user_id).execute()
            for c in cap_rows.data or []:
                caps[c["muscle_group"]] = int(c["max_weekly_sets"] or 0)
        except Exception:
            # Table may not exist in some environments; fall back to no caps.
            caps = {}

        entries: List[WeeklyVolumeEntry] = []
        for muscle, row in latest_by_muscle.items():
            sets = int(row.get("weekly_sets") or 0)
            volume = float(row.get("weekly_volume_kg") or 0)
            cap = caps.get(muscle)
            pct = (sets / cap) if cap and cap > 0 else None
            entries.append(WeeklyVolumeEntry(
                muscle_group=muscle,
                weekly_sets=sets,
                weekly_volume_kg=volume,
                cap_sets=cap,
                pct_of_cap=pct,
            ))
        entries.sort(key=lambda e: e.muscle_group)
        return WeeklyVolumePerMuscleResponse(muscles=entries)
    except Exception as e:
        raise safe_internal_error(e, "weekly_volume_per_muscle")


# Include secondary endpoints
router.include_router(_endpoints_router)
