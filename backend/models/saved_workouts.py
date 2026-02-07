"""
Pydantic models for saved and scheduled workouts.

Features:
- Save workouts from social feed
- Schedule workouts for future dates
- Track workout sharing metrics
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date as date_type, time as time_type
from enum import Enum


# ============================================================
# ENUMS
# ============================================================

class DifficultyLevel(str, Enum):
    """Workout difficulty levels."""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class ScheduledWorkoutStatus(str, Enum):
    """Status of scheduled workouts."""
    SCHEDULED = "scheduled"
    COMPLETED = "completed"
    SKIPPED = "skipped"
    RESCHEDULED = "rescheduled"


# ============================================================
# EXERCISE MODELS
# ============================================================

class ExerciseTemplate(BaseModel):
    """Template for an exercise in a saved workout."""
    name: str = Field(..., max_length=200)
    sets: int = Field(..., ge=1, le=20)
    reps: int = Field(..., ge=1, le=100)
    weight_kg: float = Field(..., ge=0, le=1000)
    rest_seconds: Optional[int] = Field(default=60, ge=0, le=600)
    notes: Optional[str] = Field(default=None, max_length=500)


# ============================================================
# SAVED WORKOUTS
# ============================================================

class SavedWorkoutBase(BaseModel):
    """Base model for saved workouts."""
    workout_name: str = Field(..., max_length=200)
    workout_description: Optional[str] = Field(default=None, max_length=2000)
    exercises: List[ExerciseTemplate] = Field(..., max_length=50)
    total_exercises: int = Field(..., ge=0, le=100)
    estimated_duration_minutes: Optional[int] = Field(default=None, ge=1, le=480)
    difficulty_level: Optional[DifficultyLevel] = None
    folder: Optional[str] = Field(default="Favorites", max_length=100)
    tags: List[str] = Field(default_factory=list, max_length=20)
    notes: Optional[str] = Field(default=None, max_length=2000)


class SavedWorkoutCreate(SavedWorkoutBase):
    """Create a saved workout."""
    source_activity_id: Optional[str] = Field(default=None, max_length=100)
    source_user_id: Optional[str] = Field(default=None, max_length=100)


class SavedWorkout(SavedWorkoutBase):
    """Saved workout from database."""
    id: str
    user_id: str
    source_activity_id: Optional[str] = None
    source_user_id: Optional[str] = None
    times_completed: int = 0
    last_completed_at: Optional[datetime] = None
    saved_at: datetime
    updated_at: datetime

    # Optional joined data
    source_user_name: Optional[str] = None
    source_user_avatar: Optional[str] = None

    class Config:
        from_attributes = True


class SavedWorkoutUpdate(BaseModel):
    """Update a saved workout."""
    workout_name: Optional[str] = Field(default=None, max_length=200)
    workout_description: Optional[str] = Field(default=None, max_length=2000)
    folder: Optional[str] = Field(default=None, max_length=100)
    tags: Optional[List[str]] = Field(default=None, max_length=20)
    notes: Optional[str] = Field(default=None, max_length=2000)


class SavedWorkoutsResponse(BaseModel):
    """Paginated response for saved workouts."""
    workouts: List[SavedWorkout]
    total_count: int
    folders: List[str]  # List of unique folders


# ============================================================
# SCHEDULED WORKOUTS
# ============================================================

class ScheduledWorkoutBase(BaseModel):
    """Base model for scheduled workouts."""
    scheduled_date: date_type
    scheduled_time: Optional[time_type] = None
    workout_name: str = Field(..., max_length=200)
    exercises: List[ExerciseTemplate] = Field(..., max_length=50)
    reminder_enabled: bool = True
    reminder_minutes_before: int = Field(default=60, ge=0, le=1440)
    notes: Optional[str] = Field(default=None, max_length=2000)


class ScheduledWorkoutCreate(ScheduledWorkoutBase):
    """Create a scheduled workout."""
    saved_workout_id: Optional[str] = Field(default=None, max_length=100)
    workout_id: Optional[str] = Field(default=None, max_length=100)


class ScheduledWorkout(ScheduledWorkoutBase):
    """Scheduled workout from database."""
    id: str
    user_id: str
    saved_workout_id: Optional[str] = None
    workout_id: Optional[str] = None
    status: ScheduledWorkoutStatus
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ScheduledWorkoutUpdate(BaseModel):
    """Update a scheduled workout."""
    scheduled_date: Optional[date_type] = None
    scheduled_time: Optional[time_type] = None
    status: Optional[ScheduledWorkoutStatus] = None
    reminder_enabled: Optional[bool] = None
    reminder_minutes_before: Optional[int] = Field(default=None, ge=0, le=1440)
    notes: Optional[str] = Field(default=None, max_length=2000)


class ScheduledWorkoutsResponse(BaseModel):
    """Response for scheduled workouts."""
    scheduled: List[ScheduledWorkout]
    total_count: int


# ============================================================
# WORKOUT SHARES
# ============================================================

class WorkoutShare(BaseModel):
    """Workout sharing metrics."""
    id: str
    shared_by: str
    workout_log_id: Optional[str] = None
    activity_id: Optional[str] = None
    share_count: int = 0
    completion_count: int = 0
    average_rating: Optional[float] = None
    is_public: bool = False
    created_at: datetime

    # Optional joined data
    creator_name: Optional[str] = None
    creator_avatar: Optional[str] = None
    activity_data: Optional[Dict[str, Any]] = None

    class Config:
        from_attributes = True


class PopularWorkout(BaseModel):
    """Popular shared workout."""
    id: str
    workout_name: str
    creator_name: str
    creator_avatar: Optional[str] = None
    exercises: List[ExerciseTemplate]
    share_count: int
    completion_count: int
    average_rating: Optional[float] = None
    difficulty_level: Optional[DifficultyLevel] = None


# ============================================================
# ACTIONS
# ============================================================

class SaveWorkoutFromActivity(BaseModel):
    """Request to save a workout from an activity."""
    activity_id: str = Field(..., max_length=100)
    folder: Optional[str] = Field(default="From Friends", max_length=100)
    notes: Optional[str] = Field(default=None, max_length=2000)


class DoWorkoutNow(BaseModel):
    """Request to start a saved workout now."""
    saved_workout_id: str = Field(..., max_length=100)
    # Will create a workout session and navigate to ActiveWorkoutScreen


class ScheduleWorkoutRequest(BaseModel):
    """Request to schedule a workout."""
    saved_workout_id: Optional[str] = Field(default=None, max_length=100)
    activity_id: Optional[str] = Field(default=None, max_length=100)  # Can schedule directly from activity
    scheduled_date: date_type
    scheduled_time: Optional[time_type] = None
    reminder_enabled: bool = True
    reminder_minutes_before: int = Field(default=60, ge=0, le=1440)
    notes: Optional[str] = Field(default=None, max_length=2000)


# ============================================================
# CALENDAR VIEW
# ============================================================

class CalendarWorkout(BaseModel):
    """Simplified workout for calendar view."""
    id: str
    date: date_type
    time: Optional[time_type] = None
    name: str
    status: ScheduledWorkoutStatus
    exercise_count: int
    estimated_duration: Optional[int] = None


class MonthlyCalendar(BaseModel):
    """Calendar view for a month."""
    year: int
    month: int
    workouts: List[CalendarWorkout]
    total_scheduled: int
    total_completed: int
