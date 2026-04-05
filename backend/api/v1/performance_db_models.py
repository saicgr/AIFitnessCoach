"""Pydantic models for performance_db."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class ExerciseLastPerformance(BaseModel):
    """Last performance data for an exercise."""
    exercise_name: str
    sets: List[dict]  # List of {set_number, weight_kg, reps_completed, set_type, rir, rpe}
    recorded_at: Optional[str] = None
    workout_log_id: Optional[str] = None


class StreakResponse(BaseModel):
    """Response model for workout streaks."""
    current_streak: int  # Current consecutive days
    longest_streak: int  # Best ever streak
    last_workout_date: Optional[str] = None  # ISO date string
    is_active_today: bool  # Did user workout today?
    streak_at_risk: bool  # Will lose streak if no workout today?


class DrinkIntakeSummary(BaseModel):
    """Summary of drink intake for a workout."""
    workout_log_id: str
    total_ml: int
    intake_count: int


class RestIntervalStats(BaseModel):
    """Statistics for rest intervals in a workout."""
    workout_log_id: str
    total_rest_seconds: int
    avg_rest_seconds: float
    interval_count: int
    between_sets_count: int
    between_exercises_count: int


class ExerciseProgressionTrend(BaseModel):
    """Progression trend for an exercise."""
    trend: str  # "increasing", "stable", "decreasing", "insufficient_data", "unknown"
    change_percent: Optional[float] = None
    message: str


class ExerciseStats(BaseModel):
    """Statistics for a single exercise."""
    exercise_name: Optional[str] = None
    total_sets: int
    total_volume: Optional[float] = None  # weight * reps in kg
    max_weight: Optional[float] = None
    max_reps: Optional[int] = None
    estimated_1rm: Optional[float] = None
    avg_rpe: Optional[float] = None
    last_workout_date: Optional[str] = None
    progression: Optional[ExerciseProgressionTrend] = None
    has_data: bool = False
    message: Optional[str] = None


class AllExerciseStats(BaseModel):
    """Stats for all exercises a user has performed."""
    exercises: dict  # exercise_name -> ExerciseStats
    total_exercises_tracked: int
    total_sets_all: int
    has_data: bool


class ExerciseHistoryItem(BaseModel):
    """Single item in exercise history list."""
    exercise_name: str
    total_sets: int
    total_volume: Optional[float] = None
    max_weight: Optional[float] = None
    max_reps: Optional[int] = None
    estimated_1rm: Optional[float] = None
    avg_rpe: Optional[float] = None
    last_workout_date: Optional[str] = None
    progression: Optional[ExerciseProgressionTrend] = None
    has_data: bool = True


