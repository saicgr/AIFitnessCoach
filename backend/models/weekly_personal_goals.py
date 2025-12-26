"""
Pydantic models for Weekly Personal Goals feature.

Enables users to set personal weekly fitness goals:
- single_max: Max reps in one set (e.g., "How many push-ups can I do?")
- weekly_volume: Total reps over the week (e.g., "500 push-ups this week")
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from enum import Enum


class GoalType(str, Enum):
    """Goal type enum."""
    single_max = "single_max"       # Max reps in one set
    weekly_volume = "weekly_volume"  # Total reps throughout the week


class GoalStatus(str, Enum):
    """Goal status enum."""
    active = "active"
    completed = "completed"
    abandoned = "abandoned"


# ============================================================
# REQUEST MODELS
# ============================================================

class CreateGoalRequest(BaseModel):
    """Request to create a new weekly goal."""
    exercise_name: str = Field(..., max_length=255, description="Exercise name (e.g., 'Push-ups')")
    goal_type: GoalType = Field(..., description="Type of goal: single_max or weekly_volume")
    target_value: int = Field(..., gt=0, le=10000, description="Target reps/volume")
    week_start: Optional[date] = Field(None, description="Week start date (defaults to current week Monday)")


class RecordAttemptRequest(BaseModel):
    """Request to record a single_max attempt."""
    attempt_value: int = Field(..., gt=0, le=10000, description="Reps achieved in this attempt")
    attempt_notes: Optional[str] = Field(None, max_length=500, description="Optional notes about the attempt")
    workout_log_id: Optional[str] = Field(None, max_length=100, description="Link to workout if done during workout")


class AddVolumeRequest(BaseModel):
    """Request to add volume to a weekly_volume goal."""
    volume_to_add: int = Field(..., gt=0, le=10000, description="Reps to add to current total")
    workout_log_id: Optional[str] = Field(None, max_length=100, description="Link to workout if done during workout")


# ============================================================
# RESPONSE MODELS
# ============================================================

class GoalAttempt(BaseModel):
    """A single attempt for a single_max goal."""
    id: str
    goal_id: str
    user_id: str
    attempt_value: int
    attempt_notes: Optional[str] = None
    attempted_at: datetime
    workout_log_id: Optional[str] = None

    class Config:
        from_attributes = True


class WeeklyPersonalGoal(BaseModel):
    """A weekly personal goal with progress tracking."""
    id: str
    user_id: str
    exercise_name: str
    goal_type: GoalType
    target_value: int
    week_start: date
    week_end: date
    current_value: int = 0
    personal_best: Optional[int] = None
    is_pr_beaten: bool = False
    status: GoalStatus = GoalStatus.active
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    # Computed fields (set by API)
    progress_percentage: float = 0.0
    days_remaining: int = 0

    # Optional: attempts for single_max goals
    attempts: Optional[List[GoalAttempt]] = None

    class Config:
        from_attributes = True


class PersonalGoalRecord(BaseModel):
    """Personal best record for an exercise/goal_type combination."""
    id: str
    user_id: str
    exercise_name: str
    goal_type: GoalType
    record_value: int
    previous_value: Optional[int] = None
    achieved_at: datetime
    goal_id: Optional[str] = None

    class Config:
        from_attributes = True


class GoalsResponse(BaseModel):
    """Response containing list of goals with summary stats."""
    goals: List[WeeklyPersonalGoal]
    current_week_goals: int = 0
    total_prs_this_week: int = 0


class GoalHistoryResponse(BaseModel):
    """Response with historical goal data for a specific exercise."""
    exercise_name: str
    goal_type: GoalType
    weeks: List[WeeklyPersonalGoal]
    all_time_best: Optional[int] = None
    total_weeks: int = 0


class PersonalRecordsResponse(BaseModel):
    """Response with all personal records for a user."""
    records: List[PersonalGoalRecord]
    total_records: int = 0


class GoalSummary(BaseModel):
    """Summary of weekly goals for quick display."""
    active_goals: int = 0
    completed_this_week: int = 0
    prs_this_week: int = 0
    total_volume_this_week: int = 0
