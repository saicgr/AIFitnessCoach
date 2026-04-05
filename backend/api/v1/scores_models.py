"""Pydantic models for scores."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


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

class DotsLiftDetail(BaseModel):
    exercise_name: str
    estimated_1rm_kg: float


class DotsScoreResponse(BaseModel):
    dots_score: float
    wilks_score: float
    total_kg: float
    bodyweight_kg: float
    gender: str
    lifts: List[DotsLiftDetail]


