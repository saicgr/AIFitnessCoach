"""
Pydantic models and constants for exercise preferences API.
"""
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional
from datetime import datetime, date


class StapleExerciseCreate(BaseModel):
    """Request to add a staple exercise."""
    user_id: str
    exercise_name: str = Field(..., min_length=1, max_length=200)
    library_id: Optional[str] = None
    muscle_group: Optional[str] = None
    reason: Optional[str] = Field(default=None, max_length=100)
    gym_profile_id: Optional[str] = None
    section: Optional[str] = Field(default="main")
    user_duration_seconds: Optional[int] = None
    user_speed_mph: Optional[float] = None
    user_incline_percent: Optional[float] = None
    user_rpm: Optional[int] = None
    user_resistance_level: Optional[int] = None
    user_stroke_rate_spm: Optional[int] = None
    user_sets: Optional[int] = None
    user_reps: Optional[str] = None
    user_rest_seconds: Optional[int] = None
    user_weight_lbs: Optional[float] = None
    target_days: Optional[List[int]] = None

    @field_validator('section')
    @classmethod
    def validate_section(cls, v):
        valid_sections = ('main', 'warmup', 'stretches')
        if v and v not in valid_sections:
            raise ValueError(f"section must be one of {valid_sections}")
        return v or 'main'

    @field_validator('target_days')
    @classmethod
    def validate_target_days(cls, v):
        if v is not None:
            if not all(isinstance(d, int) and 0 <= d <= 6 for d in v):
                raise ValueError("target_days must contain integers 0-6 (Mon=0, Sun=6)")
        return v


class StapleExerciseResponse(BaseModel):
    """Response for a staple exercise."""
    id: str
    exercise_name: str
    library_id: Optional[str]
    muscle_group: Optional[str]
    reason: Optional[str]
    created_at: datetime
    body_part: Optional[str] = None
    equipment: Optional[str] = None
    gif_url: Optional[str] = None
    gym_profile_id: Optional[str] = None
    gym_profile_name: Optional[str] = None
    gym_profile_color: Optional[str] = None
    section: str = "main"
    default_incline_percent: Optional[float] = None
    default_speed_mph: Optional[float] = None
    default_rpm: Optional[int] = None
    default_resistance_level: Optional[int] = None
    stroke_rate_spm: Optional[int] = None
    default_duration_seconds: Optional[int] = None
    user_duration_seconds: Optional[int] = None
    user_speed_mph: Optional[float] = None
    user_incline_percent: Optional[float] = None
    user_rpm: Optional[int] = None
    user_resistance_level: Optional[int] = None
    user_stroke_rate_spm: Optional[int] = None
    user_sets: Optional[int] = None
    user_reps: Optional[str] = None
    user_rest_seconds: Optional[int] = None
    target_days: Optional[List[int]] = None
    movement_pattern: Optional[str] = None
    energy_system: Optional[str] = None
    impact_level: Optional[str] = None
    category: Optional[str] = None


class StapleExerciseUpdate(BaseModel):
    """Request to update a staple exercise."""
    exercise_name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    library_id: Optional[str] = None
    muscle_group: Optional[str] = None
    reason: Optional[str] = Field(default=None, max_length=100)
    gym_profile_id: Optional[str] = None
    section: Optional[str] = None
    user_duration_seconds: Optional[int] = None
    user_speed_mph: Optional[float] = None
    user_incline_percent: Optional[float] = None
    user_rpm: Optional[int] = None
    user_resistance_level: Optional[int] = None
    user_stroke_rate_spm: Optional[int] = None
    user_sets: Optional[int] = None
    user_reps: Optional[str] = None
    user_rest_seconds: Optional[int] = None
    user_weight_lbs: Optional[float] = None
    target_days: Optional[List[int]] = None

    @field_validator('section')
    @classmethod
    def validate_section(cls, v):
        valid_sections = ('main', 'warmup', 'stretches')
        if v is not None and v not in valid_sections:
            raise ValueError(f"section must be one of {valid_sections}")
        return v

    @field_validator('target_days')
    @classmethod
    def validate_target_days(cls, v):
        if v is not None:
            if not all(isinstance(d, int) and 0 <= d <= 6 for d in v):
                raise ValueError("target_days must contain integers 0-6 (Mon=0, Sun=6)")
        return v


class VariationPreferenceUpdate(BaseModel):
    """Request to update variation percentage."""
    user_id: str
    variation_percentage: int = Field(..., ge=0, le=100)


class VariationPreferenceResponse(BaseModel):
    """Response with current variation setting."""
    variation_percentage: int
    description: str


class WeekComparisonResponse(BaseModel):
    """Response for week-over-week exercise comparison."""
    current_week_start: date
    previous_week_start: date
    kept_exercises: List[str]
    new_exercises: List[str]
    removed_exercises: List[str]
    total_current: int
    total_previous: int
    variation_summary: str


class ExerciseRotationResponse(BaseModel):
    """Response for a single exercise rotation record."""
    id: str
    exercise_added: str
    exercise_removed: Optional[str]
    muscle_group: Optional[str]
    rotation_reason: Optional[str]
    week_start_date: date
    created_at: datetime


class AvoidedExerciseCreate(BaseModel):
    """Request to add an exercise to avoid."""
    exercise_name: str = Field(..., min_length=1, max_length=200)
    exercise_id: Optional[str] = None
    reason: Optional[str] = Field(default=None, max_length=200)
    is_temporary: bool = False
    end_date: Optional[date] = None


class AvoidedExerciseResponse(BaseModel):
    """Response for an avoided exercise."""
    id: str
    exercise_name: str
    exercise_id: Optional[str]
    reason: Optional[str]
    is_temporary: bool
    end_date: Optional[date]
    created_at: datetime


class AvoidedMuscleCreate(BaseModel):
    """Request to add a muscle group to avoid."""
    muscle_group: str = Field(..., min_length=1, max_length=100)
    reason: Optional[str] = Field(default=None, max_length=200)
    is_temporary: bool = False
    end_date: Optional[date] = None
    severity: str = Field(default="avoid", pattern="^(avoid|reduce)$")


class AvoidedMuscleResponse(BaseModel):
    """Response for an avoided muscle group."""
    id: str
    muscle_group: str
    reason: Optional[str]
    is_temporary: bool
    end_date: Optional[date]
    severity: str
    created_at: datetime


class SetsLimitsUpdate(BaseModel):
    """Request to update sets limits."""
    user_id: str
    min_sets: int = Field(..., ge=1, le=10)
    max_sets: int = Field(..., ge=1, le=10)


class SetsLimitsResponse(BaseModel):
    """Response with current sets limits."""
    min_sets: int
    max_sets: int


class SubstituteRequest(BaseModel):
    """Request for exercise substitutes."""
    exercise_name: str = Field(..., min_length=1, max_length=200)
    user_id: str
    reason: Optional[str] = Field(default=None, max_length=500)


class SubstituteExercise(BaseModel):
    """A substitute exercise suggestion.

    `media_url` is the canonical media field — populated as
    COALESCE(gif_url, video_url, image_url) by the endpoint. `gif_url` is
    populated with the same coalesced value for back-compat with existing
    Flutter substitute-tile UI.
    """
    name: str
    equipment: Optional[str] = None
    target_muscle: Optional[str] = None
    body_part: Optional[str] = None
    muscle_group: Optional[str] = None
    library_id: Optional[str] = None
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    image_url: Optional[str] = None
    media_url: Optional[str] = None
    reason: Optional[str] = None
    difficulty: Optional[str] = None
    is_safe_for_reason: Optional[bool] = None


class SubstituteResponse(BaseModel):
    """Response with substitute exercises."""
    original_exercise: str
    substitutes: List[SubstituteExercise]
    injury_warning: Optional[str] = None
    intent: Optional[str] = None
    safety_warning: Optional[str] = None
    message: Optional[str] = None
    reason: Optional[str] = None


class RecentSwapResponse(BaseModel):
    """Response for a recent exercise swap."""
    old_exercise_name: str
    new_exercise_name: str
    workout_id: str
    workout_date: Optional[str] = None
    swapped_at: str


MUSCLE_GROUPS = [
    "chest", "back", "shoulders", "biceps", "triceps", "core",
    "quadriceps", "hamstrings", "glutes", "calves",
    "lower_back", "upper_back", "lats", "traps", "forearms",
    "hip_flexors", "adductors", "abductors", "abs", "obliques",
]
