"""Pydantic models for feedback."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class SetDetail(BaseModel):
    """Individual set detail for an exercise."""
    reps: int
    weight_kg: float

class ExercisePerformance(BaseModel):
    """Exercise performance data for a workout session."""
    name: str
    sets: int
    reps: int
    weight_kg: float
    time_seconds: int = 0  # Time spent on this exercise
    set_details: List[SetDetail] = []  # Individual set data

class PlannedExercise(BaseModel):
    """Planned exercise from workout definition (for skip detection)."""
    name: str
    target_sets: int = 3
    target_reps: int = 10
    target_weight_kg: float = 0.0

class AICoachFeedbackRequest(BaseModel):
    """Request body for AI Coach feedback generation."""
    user_id: str
    workout_log_id: str
    workout_id: str
    workout_name: str
    workout_type: str = "strength"
    exercises: List[ExercisePerformance]
    planned_exercises: List[PlannedExercise] = []  # For skip detection
    total_time_seconds: int
    total_rest_seconds: int = 0
    avg_rest_seconds: float = 0.0
    calories_burned: int = 0
    total_sets: int = 0
    total_reps: int = 0
    total_volume_kg: float = 0.0
    # Coach personality settings
    coach_name: Optional[str] = None
    coaching_style: Optional[str] = None  # "motivational", "drill_sergeant", "buddy", "zen_master"
    communication_tone: Optional[str] = None  # "encouraging", "direct", "friendly"
    encouragement_level: Optional[float] = None  # 0.0-1.0
    # Trophy/achievement context for personalized feedback
    earned_prs: Optional[List[dict]] = None
    earned_achievements: Optional[List[dict]] = None
    total_workouts_completed: Optional[int] = None
    next_milestone: Optional[dict] = None

class AICoachFeedbackResponse(BaseModel):
    """Response from AI Coach feedback generation."""
    feedback: str
    indexed: bool = False
    workout_log_id: str

# Singleton services (lazy initialization)
_gemini_service: Optional[GeminiService] = None
_feedback_rag_service: Optional[WorkoutFeedbackRAGService] = None

class ProgressionSuggestionResponse(BaseModel):
    """Response model for progression suggestions."""
    exercise_name: str
    suggested_next_variant: str
    consecutive_easy_sessions: int
    difficulty_increase: Optional[float] = None
    chain_id: Optional[str] = None

class ProgressionResponseRequest(BaseModel):
    """Request body for responding to a progression suggestion."""
    user_id: str
    exercise_name: str
    new_exercise_name: str
    accepted: bool
    decline_reason: Optional[str] = None

class ChallengeExerciseFeedbackRequest(BaseModel):
    """Request body for challenge exercise feedback."""
    user_id: str
    exercise_name: str
    difficulty_felt: str  # "too_easy", "just_right", "too_hard"
    completed: bool
    workout_id: Optional[str] = None
    performance_data: Optional[dict] = None  # {sets_completed, total_reps, avg_weight}

class ChallengeExerciseFeedbackResponse(BaseModel):
    """Response from challenge exercise feedback submission."""
    success: bool
    exercise_name: str
    consecutive_successes: int
    ready_for_main_workout: bool
    message: str

