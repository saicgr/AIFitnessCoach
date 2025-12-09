"""Feedback and exit tracking Pydantic models."""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# Workout Exit / Quit Tracking

class WorkoutExitCreate(BaseModel):
    """Request to log a workout exit/quit event."""
    user_id: str  # UUID string
    workout_id: str  # UUID string
    exit_reason: str  # "completed", "too_tired", "out_of_time", "not_feeling_well", "equipment_unavailable", "injury", "other"
    exit_notes: Optional[str] = None  # Optional additional notes
    exercises_completed: int = 0  # Number of exercises completed before exit
    total_exercises: int = 0  # Total exercises in workout
    sets_completed: int = 0  # Total sets completed
    time_spent_seconds: int = 0  # Total time spent in workout
    progress_percentage: float = 0.0  # Percentage of workout completed (0-100)


class WorkoutExit(BaseModel):
    """Workout exit log entry."""
    id: str  # UUID string
    user_id: str
    workout_id: str
    exit_reason: str
    exit_notes: Optional[str] = None
    exercises_completed: int
    total_exercises: int
    sets_completed: int
    time_spent_seconds: int
    progress_percentage: float
    exited_at: datetime


# Exercise Feedback

class ExerciseFeedbackCreate(BaseModel):
    """Create feedback for an individual exercise."""
    user_id: str
    workout_id: str
    exercise_name: str
    exercise_index: int
    rating: int = Field(..., ge=1, le=5)  # 1-5 stars
    comment: Optional[str] = None
    difficulty_felt: Optional[str] = None  # "too_easy", "just_right", "too_hard"
    would_do_again: bool = True


class ExerciseFeedback(BaseModel):
    """Exercise feedback entry."""
    id: str
    user_id: str
    workout_id: str
    exercise_name: str
    exercise_index: int
    rating: int
    comment: Optional[str] = None
    difficulty_felt: Optional[str] = None
    would_do_again: bool = True
    created_at: datetime


class WorkoutFeedbackCreate(BaseModel):
    """Create overall workout feedback."""
    user_id: str
    workout_id: str
    overall_rating: int = Field(..., ge=1, le=5)  # 1-5 stars
    energy_level: Optional[str] = None  # "exhausted", "tired", "good", "energized", "great"
    overall_difficulty: Optional[str] = None  # "too_easy", "just_right", "too_hard"
    comment: Optional[str] = None
    would_recommend: bool = True
    exercise_feedback: Optional[List[ExerciseFeedbackCreate]] = None  # Individual exercise feedback


class WorkoutFeedback(BaseModel):
    """Overall workout feedback entry."""
    id: str
    user_id: str
    workout_id: str
    overall_rating: int
    energy_level: Optional[str] = None
    overall_difficulty: Optional[str] = None
    comment: Optional[str] = None
    would_recommend: bool = True
    completed_at: datetime
    created_at: datetime


class WorkoutFeedbackWithExercises(WorkoutFeedback):
    """Workout feedback including individual exercise ratings."""
    exercise_feedback: List[ExerciseFeedback] = []


# Drink Intake during workout

class DrinkIntakeCreate(BaseModel):
    """Request to log drink intake during workout."""
    user_id: str  # UUID string
    workout_log_id: str  # UUID string - links to workout_logs table
    amount_ml: int  # Amount in milliliters
    drink_type: str = "water"  # "water", "sports_drink", "protein_shake", "bcaa", "other"
    notes: Optional[str] = None


class DrinkIntake(BaseModel):
    """Drink intake log entry."""
    id: str  # UUID string
    user_id: str
    workout_log_id: str
    amount_ml: int
    drink_type: str
    notes: Optional[str] = None
    logged_at: datetime


# Rest Intervals between sets/exercises

class RestIntervalCreate(BaseModel):
    """Request to log rest interval during workout."""
    user_id: str  # UUID string
    workout_log_id: str  # UUID string - links to workout_logs table
    exercise_index: int  # Index of the exercise in workout
    exercise_name: str
    set_number: Optional[int] = None  # Which set the rest followed (null = between exercises)
    rest_duration_seconds: int  # Actual rest taken
    prescribed_rest_seconds: Optional[int] = None  # What was recommended
    rest_type: str = "between_sets"  # "between_sets", "between_exercises", "unplanned"
    notes: Optional[str] = None


class RestInterval(BaseModel):
    """Rest interval log entry."""
    id: str  # UUID string
    user_id: str
    workout_log_id: str
    exercise_index: int
    exercise_name: str
    set_number: Optional[int] = None
    rest_duration_seconds: int
    prescribed_rest_seconds: Optional[int] = None
    rest_type: str
    notes: Optional[str] = None
    logged_at: datetime
