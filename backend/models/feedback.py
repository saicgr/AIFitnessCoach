"""Feedback and exit tracking Pydantic models."""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# Workout Exit / Quit Tracking

class WorkoutExitCreate(BaseModel):
    """Request to log a workout exit/quit event."""
    user_id: str = Field(..., max_length=100)  # UUID string
    workout_id: str = Field(..., max_length=100)  # UUID string
    exit_reason: str = Field(..., max_length=100)  # "completed", "too_tired", "out_of_time", etc.
    exit_notes: Optional[str] = Field(default=None, max_length=1000)  # Optional additional notes
    exercises_completed: int = Field(default=0, ge=0, le=100)  # Number of exercises completed
    total_exercises: int = Field(default=0, ge=0, le=100)  # Total exercises in workout
    sets_completed: int = Field(default=0, ge=0, le=500)  # Total sets completed
    time_spent_seconds: int = Field(default=0, ge=0, le=86400)  # Total time spent (max 24h)
    progress_percentage: float = Field(default=0.0, ge=0, le=100)  # Percentage of workout completed


class WorkoutExit(BaseModel):
    """Workout exit log entry."""
    id: str = Field(..., max_length=100)  # UUID string
    user_id: str = Field(..., max_length=100)
    workout_id: str = Field(..., max_length=100)
    exit_reason: str = Field(..., max_length=100)
    exit_notes: Optional[str] = Field(default=None, max_length=1000)
    exercises_completed: int = Field(..., ge=0, le=100)
    total_exercises: int = Field(..., ge=0, le=100)
    sets_completed: int = Field(..., ge=0, le=500)
    time_spent_seconds: int = Field(..., ge=0, le=86400)
    progress_percentage: float = Field(..., ge=0, le=100)
    exited_at: datetime


# Exercise Feedback

class ExerciseFeedbackCreate(BaseModel):
    """Create feedback for an individual exercise."""
    user_id: str = Field(..., max_length=100)
    workout_id: str = Field(..., max_length=100)
    exercise_name: str = Field(..., max_length=200)
    exercise_index: int = Field(..., ge=0, le=100)
    rating: int = Field(..., ge=1, le=5)  # 1-5 stars
    comment: Optional[str] = Field(default=None, max_length=1000)
    difficulty_felt: Optional[str] = Field(default=None, max_length=50)  # "too_easy", "just_right", "too_hard"
    would_do_again: bool = True


class ExerciseFeedback(BaseModel):
    """Exercise feedback entry."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    workout_id: str = Field(..., max_length=100)
    exercise_name: str = Field(..., max_length=200)
    exercise_index: int = Field(..., ge=0, le=100)
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = Field(default=None, max_length=1000)
    difficulty_felt: Optional[str] = Field(default=None, max_length=50)
    would_do_again: bool = True
    created_at: datetime


class WorkoutFeedbackCreate(BaseModel):
    """Create overall workout feedback."""
    user_id: str = Field(..., max_length=100)
    workout_id: str = Field(..., max_length=100)
    overall_rating: int = Field(..., ge=1, le=5)  # 1-5 stars
    energy_level: Optional[str] = Field(default=None, max_length=50)  # "exhausted", "tired", "good", etc.
    overall_difficulty: Optional[str] = Field(default=None, max_length=50)  # "too_easy", "just_right", "too_hard"
    comment: Optional[str] = Field(default=None, max_length=2000)
    would_recommend: bool = True
    exercise_feedback: Optional[List[ExerciseFeedbackCreate]] = Field(default=None, max_length=50)


class WorkoutFeedback(BaseModel):
    """Overall workout feedback entry."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    workout_id: str = Field(..., max_length=100)
    overall_rating: int = Field(..., ge=1, le=5)
    energy_level: Optional[str] = Field(default=None, max_length=50)
    overall_difficulty: Optional[str] = Field(default=None, max_length=50)
    comment: Optional[str] = Field(default=None, max_length=2000)
    would_recommend: bool = True
    completed_at: datetime
    created_at: datetime


class WorkoutFeedbackWithExercises(WorkoutFeedback):
    """Workout feedback including individual exercise ratings."""
    exercise_feedback: List[ExerciseFeedback] = Field(default=[], max_length=50)


# Drink Intake during workout

class DrinkIntakeCreate(BaseModel):
    """Request to log drink intake during workout."""
    user_id: str = Field(..., max_length=100)  # UUID string
    workout_log_id: str = Field(..., max_length=100)  # UUID string
    amount_ml: int = Field(..., ge=1, le=10000)  # Amount in milliliters
    drink_type: str = Field(default="water", max_length=50)  # "water", "sports_drink", etc.
    notes: Optional[str] = Field(default=None, max_length=500)


class DrinkIntake(BaseModel):
    """Drink intake log entry."""
    id: str = Field(..., max_length=100)  # UUID string
    user_id: str = Field(..., max_length=100)
    workout_log_id: str = Field(..., max_length=100)
    amount_ml: int = Field(..., ge=1, le=10000)
    drink_type: str = Field(..., max_length=50)
    notes: Optional[str] = Field(default=None, max_length=500)
    logged_at: datetime


# Rest Intervals between sets/exercises

class RestIntervalCreate(BaseModel):
    """Request to log rest interval during workout."""
    user_id: str = Field(..., max_length=100)  # UUID string
    workout_log_id: str = Field(..., max_length=100)  # UUID string
    exercise_index: int = Field(..., ge=0, le=100)  # Index of the exercise in workout
    exercise_name: str = Field(..., max_length=200)
    set_number: Optional[int] = Field(default=None, ge=1, le=100)  # Which set the rest followed
    rest_duration_seconds: int = Field(..., ge=0, le=3600)  # Actual rest taken (max 1 hour)
    prescribed_rest_seconds: Optional[int] = Field(default=None, ge=0, le=600)  # What was recommended
    rest_type: str = Field(default="between_sets", max_length=50)  # "between_sets", "between_exercises", etc.
    notes: Optional[str] = Field(default=None, max_length=500)


class RestInterval(BaseModel):
    """Rest interval log entry."""
    id: str = Field(..., max_length=100)  # UUID string
    user_id: str = Field(..., max_length=100)
    workout_log_id: str = Field(..., max_length=100)
    exercise_index: int = Field(..., ge=0, le=100)
    exercise_name: str = Field(..., max_length=200)
    set_number: Optional[int] = Field(default=None, ge=1, le=100)
    rest_duration_seconds: int = Field(..., ge=0, le=3600)
    prescribed_rest_seconds: Optional[int] = Field(default=None, ge=0, le=600)
    rest_type: str = Field(..., max_length=50)
    notes: Optional[str] = Field(default=None, max_length=500)
    logged_at: datetime
