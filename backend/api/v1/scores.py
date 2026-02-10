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

from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Query, Depends, BackgroundTasks
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
):
    """
    Submit daily readiness check-in.

    Uses the Hooper Index methodology to calculate readiness score.
    """
    db = get_supabase_db()
    readiness_service = ReadinessService()

    # Determine date
    check_date = request.score_date or date.today()

    # Create check-in object
    check_in = ReadinessCheckIn(
        sleep_quality=request.sleep_quality,
        fatigue_level=request.fatigue_level,
        stress_level=request.stress_level,
        muscle_soreness=request.muscle_soreness,
        mood=request.mood,
        energy_level=request.energy_level,
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
        "submitted_at": datetime.now().isoformat(),
    }

    # Upsert (update if exists for today)
    response = db.client.table("readiness_scores").upsert(
        record_data,
        on_conflict="user_id,score_date",
    ).execute()

    if not response.data:
        raise HTTPException(status_code=500, detail="Failed to save readiness check-in")

    record = response.data[0]

    # Generate AI recommendation in background and update record
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
):
    """Get readiness score for a specific date."""
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
    user_id: str = Query(...),
    days: int = Query(30, ge=1, le=365),
):
    """Get readiness history for specified number of days."""
    db = get_supabase_db()
    readiness_service = ReadinessService()

    start_date = (date.today() - timedelta(days=days)).isoformat()

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
    user_id: str = Query(...),
    background_tasks: BackgroundTasks = None,
):
    """
    Trigger recalculation of strength scores.

    Analyzes workout history and updates all muscle group scores.
    """
    db = get_supabase_db()
    strength_service = StrengthCalculatorService()

    # Get user info (check column first, then preferences JSON)
    user_response = db.client.table("users").select("weight_kg, gender, preferences").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response or not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    bodyweight, gender = get_user_body_info(user_response.data)

    # Get workout data from last 90 days
    start_date = (date.today() - timedelta(days=90)).isoformat()

    workouts_response = db.client.table("workouts").select(
        "id, exercises, completed_at"
    ).eq(
        "user_id", user_id
    ).eq(
        "completed", True
    ).gte(
        "scheduled_date", start_date
    ).execute()

    # Extract exercise performances
    workout_data = []
    for workout in (workouts_response.data or []):
        exercises = workout.get("exercises", [])
        for exercise in exercises:
            if isinstance(exercise, dict):
                # Get best set for this exercise
                sets = exercise.get("sets", [])
                if sets:
                    best_set = max(
                        (s for s in sets if s.get("completed", True)),
                        key=lambda s: float(s.get("weight_kg", 0)) * int(s.get("reps", 0)),
                        default=None,
                    )
                    if best_set:
                        workout_data.append({
                            "exercise_name": exercise.get("name", ""),
                            "weight_kg": float(best_set.get("weight_kg", 0)),
                            "reps": int(best_set.get("reps", 0)),
                            "sets": len(sets),
                        })

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
    period_end = date.today()
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


@router.get("/personal-records/{exercise}", tags=["Personal Records"])
async def get_exercise_pr_history(
    exercise: str,
    user_id: str = Query(...),
):
    """Get PR history for a specific exercise."""
    db = get_supabase_db()
    pr_service = PersonalRecordsService()

    # Get all PRs for this exercise
    response = db.client.table("personal_records").select("*").eq(
        "user_id", user_id
    ).ilike(
        "exercise_name", f"%{exercise}%"
    ).order(
        "achieved_at", desc=True
    ).execute()

    all_prs = response.data or []

    return pr_service.get_exercise_pr_history(exercise, all_prs)


# ============================================================================
# Nutrition Score Endpoints
# ============================================================================

@router.get("/nutrition", response_model=NutritionScoreResponse, tags=["Nutrition"])
async def get_nutrition_score(
    user_id: str = Query(...),
    week_start: Optional[date] = Query(None, description="Start of week (Monday)"),
):
    """
    Get weekly nutrition score for a user.

    If week_start is not provided, returns current week's score.
    """
    db = get_supabase_db()
    nutrition_service = NutritionCalculatorService()

    # Determine week range
    if week_start is None:
        week_start, week_end = nutrition_service.get_current_week_range()
    else:
        week_end = week_start + timedelta(days=6)

    # Try to get cached score from database
    score_response = db.client.table("nutrition_scores").select("*").eq(
        "user_id", user_id
    ).eq(
        "week_start", week_start.isoformat()
    ).maybe_single().execute()

    if score_response and score_response.data:
        record = score_response.data
        return NutritionScoreResponse(
            id=record["id"],
            user_id=record["user_id"],
            week_start=date.fromisoformat(record["week_start"]),
            week_end=date.fromisoformat(record["week_end"]),
            days_logged=record["days_logged"],
            total_days=record.get("total_days", 7),
            adherence_percent=record["adherence_percent"],
            calorie_adherence_percent=record.get("calorie_adherence_percent", 0),
            protein_adherence_percent=record.get("protein_adherence_percent", 0),
            carb_adherence_percent=record.get("carb_adherence_percent", 0),
            fat_adherence_percent=record.get("fat_adherence_percent", 0),
            avg_health_score=record.get("avg_health_score", 0),
            fiber_target_met_days=record.get("fiber_target_met_days", 0),
            nutrition_score=record["nutrition_score"],
            nutrition_level=record["nutrition_level"],
            ai_weekly_summary=record.get("ai_weekly_summary"),
            ai_improvement_tips=record.get("ai_improvement_tips", []),
            calculated_at=datetime.fromisoformat(record["calculated_at"]) if record.get("calculated_at") else None,
        )

    # No cached score - return empty score for this week
    return NutritionScoreResponse(
        user_id=user_id,
        week_start=week_start,
        week_end=week_end,
        days_logged=0,
        total_days=7,
        nutrition_score=0,
        nutrition_level="needs_work",
    )


@router.post("/nutrition/calculate", response_model=NutritionScoreResponse, tags=["Nutrition"])
async def calculate_nutrition_score(
    request: NutritionCalculateRequest,
    background_tasks: BackgroundTasks,
):
    """
    Calculate and save weekly nutrition score.

    Analyzes food logs for the week and calculates adherence to targets.
    """
    db = get_supabase_db()
    nutrition_service = NutritionCalculatorService()

    # Determine week range
    if request.week_start is None:
        week_start, week_end = nutrition_service.get_current_week_range()
    else:
        week_start = request.week_start
        week_end = week_start + timedelta(days=6)

    # Get user's nutrition targets
    user_response = db.client.table("users").select(
        "id, daily_calories, protein_g, carbs_g, fat_g, fiber_g"
    ).eq("id", request.user_id).maybe_single().execute()

    if not user_response or not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_response.data
    targets = NutritionTargets(
        calories=int(user.get("daily_calories", 2000)),
        protein_g=int(user.get("protein_g", 150)),
        carbs_g=int(user.get("carbs_g", 200)),
        fat_g=int(user.get("fat_g", 65)),
        fiber_g=int(user.get("fiber_g", 30)),
    )

    # Get food logs for the week
    food_logs_response = db.client.table("food_logs").select("*").eq(
        "user_id", request.user_id
    ).gte(
        "log_date", week_start.isoformat()
    ).lte(
        "log_date", week_end.isoformat()
    ).execute()

    food_logs = food_logs_response.data or []

    # Aggregate daily nutrition from food logs
    daily_data = {}
    for log in food_logs:
        log_date = date.fromisoformat(log["log_date"])
        if log_date not in daily_data:
            daily_data[log_date] = DailyNutrition(
                date=log_date,
                calories=0,
                protein_g=0,
                carbs_g=0,
                fat_g=0,
                fiber_g=0,
                health_score=0,
                meals_logged=0,
            )

        daily = daily_data[log_date]
        daily.calories += float(log.get("calories", 0))
        daily.protein_g += float(log.get("protein_g", 0))
        daily.carbs_g += float(log.get("carbs_g", 0))
        daily.fat_g += float(log.get("fat_g", 0))
        daily.fiber_g += float(log.get("fiber_g", 0))
        daily.meals_logged += 1

        # Average health score
        if log.get("health_score"):
            if daily.health_score == 0:
                daily.health_score = float(log["health_score"])
            else:
                daily.health_score = (daily.health_score + float(log["health_score"])) / 2

    # Calculate nutrition score
    score = nutrition_service.calculate_weekly_nutrition_score(
        user_id=request.user_id,
        week_start=week_start,
        week_end=week_end,
        daily_data=list(daily_data.values()),
        targets=targets,
    )

    # Get improvement tips
    tips = nutrition_service.get_improvement_tips(score)
    score.ai_improvement_tips = tips

    # Get previous week's score for comparison
    previous_week_start, previous_week_end = nutrition_service.get_previous_week_range()
    previous_response = db.client.table("nutrition_scores").select(
        "nutrition_score"
    ).eq(
        "user_id", request.user_id
    ).eq(
        "week_start", previous_week_start.isoformat()
    ).maybe_single().execute()

    previous_score = previous_response.data.get("nutrition_score") if previous_response and previous_response.data else None

    # Save to database
    record_data = {
        "user_id": request.user_id,
        "week_start": week_start.isoformat(),
        "week_end": week_end.isoformat(),
        "days_logged": score.days_logged,
        "total_days": score.total_days,
        "adherence_percent": score.adherence_percent,
        "calorie_adherence_percent": score.calorie_adherence_percent,
        "protein_adherence_percent": score.protein_adherence_percent,
        "carb_adherence_percent": score.carb_adherence_percent,
        "fat_adherence_percent": score.fat_adherence_percent,
        "avg_health_score": score.avg_health_score,
        "fiber_target_met_days": score.fiber_target_met_days,
        "nutrition_score": score.nutrition_score,
        "nutrition_level": score.nutrition_level.value,
        "ai_improvement_tips": score.ai_improvement_tips,
        "previous_score": previous_score,
        "calculated_at": datetime.now().isoformat(),
    }

    # Upsert (update if exists for this week)
    response = db.client.table("nutrition_scores").upsert(
        record_data,
        on_conflict="user_id,week_start",
    ).execute()

    if not response.data:
        raise HTTPException(status_code=500, detail="Failed to save nutrition score")

    record = response.data[0]

    return NutritionScoreResponse(
        id=record["id"],
        user_id=record["user_id"],
        week_start=date.fromisoformat(record["week_start"]),
        week_end=date.fromisoformat(record["week_end"]),
        days_logged=record["days_logged"],
        total_days=record.get("total_days", 7),
        adherence_percent=record["adherence_percent"],
        calorie_adherence_percent=record.get("calorie_adherence_percent", 0),
        protein_adherence_percent=record.get("protein_adherence_percent", 0),
        carb_adherence_percent=record.get("carb_adherence_percent", 0),
        fat_adherence_percent=record.get("fat_adherence_percent", 0),
        avg_health_score=record.get("avg_health_score", 0),
        fiber_target_met_days=record.get("fiber_target_met_days", 0),
        nutrition_score=record["nutrition_score"],
        nutrition_level=record["nutrition_level"],
        ai_weekly_summary=record.get("ai_weekly_summary"),
        ai_improvement_tips=record.get("ai_improvement_tips", []),
        calculated_at=datetime.fromisoformat(record["calculated_at"]) if record.get("calculated_at") else None,
    )


# ============================================================================
# Fitness Score Endpoints
# ============================================================================

@router.get("/fitness", response_model=FitnessScoreBreakdownResponse, tags=["Fitness"])
async def get_fitness_score(
    user_id: str = Query(...),
):
    """
    Get overall fitness score with breakdown.

    Returns the combined fitness score from strength, consistency, nutrition, and readiness.
    """
    db = get_supabase_db()
    fitness_service = FitnessScoreCalculatorService()

    # Get the latest fitness score from database
    score_response = db.client.table("fitness_scores").select("*").eq(
        "user_id", user_id
    ).order(
        "calculated_at", desc=True
    ).limit(1).maybe_single().execute()

    if score_response and score_response.data:
        record = score_response.data
        fitness_score = FitnessScoreResponse(
            id=record["id"],
            user_id=record["user_id"],
            calculated_date=date.fromisoformat(record["calculated_date"]) if record.get("calculated_date") else None,
            strength_score=record["strength_score"],
            readiness_score=record["readiness_score"],
            consistency_score=record["consistency_score"],
            nutrition_score=record["nutrition_score"],
            overall_fitness_score=record["overall_fitness_score"],
            fitness_level=record["fitness_level"],
            ai_summary=record.get("ai_summary"),
            focus_recommendation=record.get("focus_recommendation"),
            previous_score=record.get("previous_score"),
            score_change=record.get("score_change"),
            trend=record.get("trend", "maintaining"),
            calculated_at=datetime.fromisoformat(record["calculated_at"]) if record.get("calculated_at") else None,
        )

        # Build breakdown
        score_obj = FitnessScore(
            user_id=user_id,
            strength_score=record["strength_score"],
            readiness_score=record["readiness_score"],
            consistency_score=record["consistency_score"],
            nutrition_score=record["nutrition_score"],
            overall_fitness_score=record["overall_fitness_score"],
            fitness_level=FitnessLevel(record["fitness_level"]),
        )
        breakdown = fitness_service.get_score_breakdown_display(score_obj)
        level_description = fitness_service.get_level_description(score_obj.fitness_level)
        level_color = fitness_service.get_level_color(score_obj.fitness_level)

        return FitnessScoreBreakdownResponse(
            fitness_score=fitness_score,
            breakdown=breakdown,
            level_description=level_description,
            level_color=level_color,
        )

    # No score exists - return default
    default_score = FitnessScoreResponse(
        user_id=user_id,
        overall_fitness_score=0,
        fitness_level="beginner",
    )
    return FitnessScoreBreakdownResponse(
        fitness_score=default_score,
        breakdown=[],
        level_description="Starting your fitness journey - focus on consistency.",
        level_color="#9E9E9E",
    )


@router.post("/fitness/calculate", response_model=FitnessScoreBreakdownResponse, tags=["Fitness"])
async def calculate_fitness_score(
    request: FitnessCalculateRequest,
    background_tasks: BackgroundTasks,
):
    """
    Calculate and save overall fitness score.

    Combines strength, consistency, nutrition, and readiness into one score.
    """
    db = get_supabase_db()
    fitness_service = FitnessScoreCalculatorService()
    strength_service = StrengthCalculatorService()

    user_id = request.user_id

    # 1. Get strength score (overall)
    strength_response = db.client.table("latest_strength_scores").select(
        "muscle_group, strength_score"
    ).eq("user_id", user_id).execute()

    if strength_response and strength_response.data:
        score_objects = {
            r["muscle_group"]: type('obj', (object,), {'strength_score': r["strength_score"] or 0})()
            for r in strength_response.data
        }
        strength_score, _ = strength_service.calculate_overall_strength_score(score_objects)
    else:
        strength_score = 0

    # 2. Get consistency score (workout completion rate for last 30 days)
    thirty_days_ago = (date.today() - timedelta(days=30)).isoformat()

    # Count scheduled workouts
    scheduled_response = db.client.table("workouts").select(
        "id", count="exact"
    ).eq(
        "user_id", user_id
    ).gte(
        "scheduled_date", thirty_days_ago
    ).execute()
    scheduled_count = scheduled_response.count or 0

    # Count completed workouts
    completed_response = db.client.table("workouts").select(
        "id", count="exact"
    ).eq(
        "user_id", user_id
    ).eq(
        "completed", True
    ).gte(
        "scheduled_date", thirty_days_ago
    ).execute()
    completed_count = completed_response.count or 0

    consistency_score = fitness_service.calculate_consistency_score(
        scheduled=scheduled_count,
        completed=completed_count,
    )

    # 3. Get nutrition score (current week)
    from services.nutrition_calculator_service import nutrition_calculator_service
    week_start, week_end = nutrition_calculator_service.get_current_week_range()

    nutrition_response = db.client.table("nutrition_scores").select(
        "nutrition_score"
    ).eq(
        "user_id", user_id
    ).eq(
        "week_start", week_start.isoformat()
    ).maybe_single().execute()

    nutrition_score = nutrition_response.data.get("nutrition_score", 0) if nutrition_response and nutrition_response.data else 0

    # 4. Get readiness score (7-day average)
    seven_days_ago = (date.today() - timedelta(days=7)).isoformat()
    readiness_response = db.client.table("readiness_scores").select(
        "readiness_score"
    ).eq(
        "user_id", user_id
    ).gte(
        "score_date", seven_days_ago
    ).execute()

    readiness_scores = [r["readiness_score"] for r in (readiness_response.data or [])]
    readiness_score = round(sum(readiness_scores) / len(readiness_scores)) if readiness_scores else 50

    # 5. Get previous fitness score
    previous_response = db.client.table("fitness_scores").select(
        "overall_fitness_score"
    ).eq(
        "user_id", user_id
    ).order(
        "calculated_at", desc=True
    ).limit(1).maybe_single().execute()

    previous_score = previous_response.data.get("overall_fitness_score") if previous_response and previous_response.data else None

    # 6. Calculate overall fitness score
    score = fitness_service.calculate_fitness_score(
        user_id=user_id,
        strength_score=strength_score,
        readiness_score=readiness_score,
        consistency_score=consistency_score,
        nutrition_score=nutrition_score,
        previous_score=previous_score,
    )

    # 7. Save to database
    record_data = {
        "user_id": user_id,
        "calculated_date": date.today().isoformat(),
        "strength_score": score.strength_score,
        "readiness_score": score.readiness_score,
        "consistency_score": score.consistency_score,
        "nutrition_score": score.nutrition_score,
        "overall_fitness_score": score.overall_fitness_score,
        "fitness_level": score.fitness_level.value,
        "strength_weight": score.strength_weight,
        "consistency_weight": score.consistency_weight,
        "nutrition_weight": score.nutrition_weight,
        "readiness_weight": score.readiness_weight,
        "focus_recommendation": score.focus_recommendation,
        "previous_score": score.previous_score,
        "score_change": score.score_change,
        "trend": score.trend,
        "calculated_at": datetime.now().isoformat(),
    }

    response = db.client.table("fitness_scores").insert(record_data).execute()

    if not response.data:
        raise HTTPException(status_code=500, detail="Failed to save fitness score")

    record = response.data[0]

    # Log score calculation event
    await user_context_service.log_event(
        user_id=user_id,
        event_type=EventType.SCORE_VIEW,
        event_data={
            "action": "calculate",
            "overall_score": score.overall_fitness_score,
            "fitness_level": score.fitness_level.value,
        },
        context={"screen": "fitness_calculation"},
    )

    # Build response
    fitness_score_response = FitnessScoreResponse(
        id=record["id"],
        user_id=record["user_id"],
        calculated_date=date.fromisoformat(record["calculated_date"]),
        strength_score=record["strength_score"],
        readiness_score=record["readiness_score"],
        consistency_score=record["consistency_score"],
        nutrition_score=record["nutrition_score"],
        overall_fitness_score=record["overall_fitness_score"],
        fitness_level=record["fitness_level"],
        focus_recommendation=record.get("focus_recommendation"),
        previous_score=record.get("previous_score"),
        score_change=record.get("score_change"),
        trend=record.get("trend", "maintaining"),
        calculated_at=datetime.fromisoformat(record["calculated_at"]),
    )

    breakdown = fitness_service.get_score_breakdown_display(score)
    level_description = fitness_service.get_level_description(score.fitness_level)
    level_color = fitness_service.get_level_color(score.fitness_level)

    return FitnessScoreBreakdownResponse(
        fitness_score=fitness_score_response,
        breakdown=breakdown,
        level_description=level_description,
        level_color=level_color,
    )


# ============================================================================
# Overview Endpoint
# ============================================================================

@router.get("/overview", response_model=ScoresOverviewResponse, tags=["Overview"])
async def get_scores_overview(
    user_id: str = Query(...),
):
    """Get combined dashboard data including readiness, strength, and PRs."""
    db = get_supabase_db()
    strength_service = StrengthCalculatorService()

    # Get today's readiness
    today = date.today().isoformat()
    try:
        readiness_response = db.client.table("readiness_scores").select("*").eq(
            "user_id", user_id
        ).eq(
            "score_date", today
        ).maybe_single().execute()
    except Exception as e:
        # Handle 406 or other errors gracefully
        logger.warning(f"Failed to fetch readiness score: {e}")
        readiness_response = None

    today_readiness = None
    has_checked_in = False

    if readiness_response and readiness_response.data:
        has_checked_in = True
        r = readiness_response.data
        today_readiness = ReadinessResponse(
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

    # Get strength scores summary
    strength_response = db.client.table("latest_strength_scores").select(
        "muscle_group, strength_score"
    ).eq("user_id", user_id).execute()

    muscle_scores_summary = {
        r["muscle_group"]: r["strength_score"] or 0
        for r in (strength_response.data or [])
    }

    # Calculate overall strength
    if muscle_scores_summary:
        score_objects = {
            k: type('obj', (object,), {'strength_score': v})()
            for k, v in muscle_scores_summary.items()
        }
        overall_score, overall_level = strength_service.calculate_overall_strength_score(score_objects)
    else:
        overall_score = 0
        overall_level = StrengthLevel.BEGINNER

    # Get recent PRs
    pr_response = db.client.table("personal_records").select("*").eq(
        "user_id", user_id
    ).order(
        "achieved_at", desc=True
    ).limit(5).execute()

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
        for pr in (pr_response.data or [])
    ]

    # Count PRs in last 30 days
    thirty_days_ago = (date.today() - timedelta(days=30)).isoformat()
    pr_count_response = db.client.table("personal_records").select(
        "id", count="exact"
    ).eq(
        "user_id", user_id
    ).gte(
        "achieved_at", thirty_days_ago
    ).execute()

    pr_count = pr_count_response.count or 0

    # Get 7-day readiness average
    seven_days_ago = (date.today() - timedelta(days=7)).isoformat()
    readiness_avg_response = db.client.table("readiness_scores").select(
        "readiness_score"
    ).eq(
        "user_id", user_id
    ).gte(
        "score_date", seven_days_ago
    ).execute()

    readiness_scores = [r["readiness_score"] for r in (readiness_avg_response.data or [])]
    readiness_average = (
        sum(readiness_scores) / len(readiness_scores)
        if readiness_scores else None
    )

    # Get current week nutrition score
    nutrition_service = NutritionCalculatorService()
    week_start, week_end = nutrition_service.get_current_week_range()
    nutrition_response = db.client.table("nutrition_scores").select(
        "nutrition_score, nutrition_level"
    ).eq(
        "user_id", user_id
    ).eq(
        "week_start", week_start.isoformat()
    ).maybe_single().execute()

    nutrition_score = nutrition_response.data.get("nutrition_score") if nutrition_response and nutrition_response.data else None
    nutrition_level = nutrition_response.data.get("nutrition_level") if nutrition_response and nutrition_response.data else None

    # Get latest fitness score
    fitness_response = db.client.table("fitness_scores").select(
        "overall_fitness_score, fitness_level, consistency_score"
    ).eq(
        "user_id", user_id
    ).order(
        "calculated_at", desc=True
    ).limit(1).maybe_single().execute()

    overall_fitness_score = fitness_response.data.get("overall_fitness_score") if fitness_response and fitness_response.data else None
    fitness_level = fitness_response.data.get("fitness_level") if fitness_response and fitness_response.data else None
    consistency_score = fitness_response.data.get("consistency_score") if fitness_response and fitness_response.data else None

    return ScoresOverviewResponse(
        user_id=user_id,
        today_readiness=today_readiness,
        has_checked_in_today=has_checked_in,
        overall_strength_score=overall_score,
        overall_strength_level=overall_level.value,
        muscle_scores_summary=muscle_scores_summary,
        recent_prs=recent_prs,
        pr_count_30_days=pr_count,
        readiness_average_7_days=round(readiness_average, 1) if readiness_average else None,
        nutrition_score=nutrition_score,
        nutrition_level=nutrition_level,
        consistency_score=consistency_score,
        overall_fitness_score=overall_fitness_score,
        fitness_level=fitness_level,
    )


# ============================================================================
# Background Tasks
# ============================================================================

async def generate_ai_readiness_insight(
    user_id: str,
    record_id: str,
    readiness_data: Dict[str, Any],
    db,
):
    """
    Background task to generate AI-powered readiness recommendations.
    Updates the readiness record with the AI insight.
    """
    try:
        logger.info(f"Generating AI readiness insight for user {user_id}")

        # Get today's scheduled workout if any
        today = date.today().isoformat()
        workout_response = db.client.table("workouts").select(
            "name, type, duration_minutes"
        ).eq(
            "user_id", user_id
        ).eq(
            "scheduled_date", today
        ).eq(
            "is_completed", False
        ).maybe_single().execute()

        scheduled_workout = None
        if workout_response and workout_response.data:
            w = workout_response.data
            scheduled_workout = {
                "name": w.get("name"),
                "type": w.get("type"),
                "duration_minutes": w.get("duration_minutes"),
            }

        # Get user profile
        user_response = db.client.table("users").select(
            "display_name, fitness_level, goals"
        ).eq("id", user_id).maybe_single().execute()

        user_profile = {}
        if user_response and user_response.data:
            u = user_response.data
            user_profile = {
                "id": user_id,
                "name": u.get("display_name"),
                "fitness_level": u.get("fitness_level", "intermediate"),
                "goals": u.get("goals", ["general fitness"]),
            }

        # Generate AI recommendation
        ai_recommendation = await ai_insights_service.generate_readiness_recommendation(
            readiness_data=readiness_data,
            scheduled_workout=scheduled_workout,
            user_profile=user_profile,
        )

        # Update record with AI insight
        db.client.table("readiness_scores").update({
            "ai_insight": ai_recommendation,
        }).eq("id", record_id).execute()

        logger.info(f"AI readiness insight saved for user {user_id}")

    except Exception as e:
        logger.error(f"Failed to generate AI readiness insight: {e}")
