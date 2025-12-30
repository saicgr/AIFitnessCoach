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

import logging
logger = logging.getLogger(__name__)

router = APIRouter()


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

    # Calculate readiness
    result = readiness_service.calculate_readiness(check_in)

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

    if not response.data:
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

    # Get user's bodyweight and gender
    user_response = db.client.table("users").select("weight_kg, gender").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_response.data
    bodyweight = float(user.get("weight_kg", 70))
    gender = user.get("gender", "male")

    # Get latest strength scores from database
    scores_response = db.from_("latest_strength_scores").select("*").eq(
        "user_id", user_id
    ).execute()

    muscle_scores = {}

    if scores_response.data:
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

    # Get user info
    user_response = db.client.table("users").select("weight_kg, gender").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_response.data
    bodyweight = float(user.get("weight_kg", 70))
    gender = user.get("gender", "male")

    # Get latest strength score
    score_response = db.from_("latest_strength_scores").select("*").eq(
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

    # Get user info
    user_response = db.client.table("users").select("weight_kg, gender").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_response.data
    bodyweight = float(user.get("weight_kg", 70))
    gender = user.get("gender", "male")

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
    previous_response = db.from_("latest_strength_scores").select(
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
    readiness_response = db.client.table("readiness_scores").select("*").eq(
        "user_id", user_id
    ).eq(
        "score_date", today
    ).maybe_single().execute()

    today_readiness = None
    has_checked_in = False

    if readiness_response.data:
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
    strength_response = db.from_("latest_strength_scores").select(
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
        if workout_response.data:
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
        if user_response.data:
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
