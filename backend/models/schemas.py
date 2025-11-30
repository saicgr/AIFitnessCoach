"""Pydantic models for API requests and responses."""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ============================================
# User Models
# ============================================

class UserPreferences(BaseModel):
    """Extended user preferences for workout customization."""
    days_per_week: int = 4
    workout_duration: int = 45  # minutes
    training_split: str = "full_body"  # full_body, upper_lower, push_pull_legs, body_part
    intensity_preference: str = "moderate"  # light, moderate, intense
    preferred_time: str = "morning"  # morning, afternoon, evening


class UserCreate(BaseModel):
    fitness_level: str
    goals: str
    equipment: str
    preferences: str = "{}"
    active_injuries: str = "[]"
    # Extended onboarding fields - merged into preferences on save
    days_per_week: Optional[int] = None
    workout_duration: Optional[int] = None
    training_split: Optional[str] = None
    intensity_preference: Optional[str] = None
    preferred_time: Optional[str] = None
    # New personal/health fields
    name: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    target_weight_kg: Optional[float] = None
    selected_days: Optional[str] = None  # JSON array of day indices [0,1,3,4]
    workout_experience: Optional[str] = None  # JSON array
    workout_variety: Optional[str] = None
    health_conditions: Optional[str] = None  # JSON array
    activity_level: Optional[str] = None


class UserUpdate(BaseModel):
    fitness_level: Optional[str] = None
    goals: Optional[str] = None
    equipment: Optional[str] = None
    preferences: Optional[str] = None
    active_injuries: Optional[str] = None
    onboarding_completed: Optional[bool] = None  # Set to True after onboarding
    # Extended onboarding fields
    days_per_week: Optional[int] = None
    workout_duration: Optional[int] = None
    training_split: Optional[str] = None
    intensity_preference: Optional[str] = None
    preferred_time: Optional[str] = None
    # New personal/health fields
    name: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    target_weight_kg: Optional[float] = None
    selected_days: Optional[str] = None  # JSON array of day indices
    workout_experience: Optional[str] = None  # JSON array
    workout_variety: Optional[str] = None
    health_conditions: Optional[str] = None  # JSON array
    activity_level: Optional[str] = None


class User(BaseModel):
    id: str  # UUID from Supabase
    username: Optional[str] = None
    name: Optional[str] = None
    onboarding_completed: bool = False
    fitness_level: str
    goals: str
    equipment: str
    preferences: str
    active_injuries: str
    created_at: datetime


# ============================================
# Exercise Models
# ============================================

class ExerciseCreate(BaseModel):
    external_id: str
    name: str
    category: str = "strength"
    subcategory: str = "compound"
    difficulty_level: int = 1
    primary_muscle: str
    secondary_muscles: str = "[]"
    equipment_required: str = "[]"
    body_part: str
    equipment: str
    target: str
    default_sets: int = 3
    default_reps: Optional[int] = None
    default_duration_seconds: Optional[int] = None
    default_rest_seconds: int = 60
    min_weight_kg: Optional[float] = None
    calories_per_minute: float = 5.0
    instructions: str
    tips: str = "[]"
    contraindicated_injuries: str = "[]"
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    is_compound: bool = True
    is_unilateral: bool = False
    tags: str = "[]"
    is_custom: bool = False
    created_by_user_id: Optional[int] = None


class Exercise(ExerciseCreate):
    id: int
    created_at: datetime


# ============================================
# Workout Models
# ============================================

class WorkoutCreate(BaseModel):
    user_id: str  # UUID string from Supabase
    name: str
    type: str
    difficulty: str
    scheduled_date: datetime
    exercises_json: str
    duration_minutes: int = 45
    generation_method: str = "algorithm"
    generation_source: str = "onboarding"
    generation_metadata: str = "{}"


class WorkoutUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    difficulty: Optional[str] = None
    scheduled_date: Optional[datetime] = None
    is_completed: Optional[bool] = None
    exercises_json: Optional[str] = None
    last_modified_method: Optional[str] = None


class Workout(BaseModel):
    id: str  # UUID string from Supabase
    user_id: str  # UUID string from Supabase
    name: str
    type: str
    difficulty: str
    scheduled_date: datetime
    is_completed: bool
    exercises_json: str
    duration_minutes: int = 45
    created_at: Optional[datetime] = None
    generation_method: Optional[str] = None
    generation_source: Optional[str] = None
    generation_metadata: Optional[str] = None  # Will be JSON stringified
    generated_at: Optional[datetime] = None
    last_modified_method: Optional[str] = None
    last_modified_at: Optional[datetime] = None
    modification_history: Optional[str] = None  # Will be JSON stringified


class GenerateWorkoutRequest(BaseModel):
    user_id: str  # UUID string from Supabase
    workout_type: Optional[str] = None
    duration_minutes: Optional[int] = 45
    focus_areas: Optional[List[str]] = None
    exclude_exercises: Optional[List[str]] = None
    # Optional overrides - if provided, use these instead of user profile
    fitness_level: Optional[str] = None
    goals: Optional[List[str]] = None
    equipment: Optional[List[str]] = None


class GenerateWeeklyRequest(BaseModel):
    """Request to generate workouts for multiple days in a week."""
    user_id: str  # UUID string from Supabase
    week_start_date: str  # ISO date string, e.g., "2024-11-25"
    selected_days: List[int]  # 0=Mon, 1=Tue, etc.
    duration_minutes: Optional[int] = 45


class GenerateWeeklyResponse(BaseModel):
    """Response containing multiple generated workouts."""
    workouts: List[Workout]


class GenerateMonthlyRequest(BaseModel):
    """Request to generate workouts for a full month."""
    user_id: str  # UUID string from Supabase
    month_start_date: str  # ISO date string, e.g., "2024-11-01"
    selected_days: List[int]  # 0=Mon, 1=Tue, ..., 6=Sun
    duration_minutes: Optional[int] = 45


class GenerateMonthlyResponse(BaseModel):
    """Response containing all generated workouts for the month."""
    workouts: List[Workout]
    total_generated: int


class SwapWorkoutsRequest(BaseModel):
    workout_id: int
    new_date: str  # ISO date, e.g., "2024-11-25"
    reason: Optional[str] = None


# ============================================
# Workout Log Models
# ============================================

class WorkoutLogCreate(BaseModel):
    workout_id: int
    user_id: str  # UUID string from Supabase
    sets_json: str
    total_time_seconds: int


class WorkoutLog(WorkoutLogCreate):
    id: int
    completed_at: datetime


# ============================================
# Performance Log Models
# ============================================

class PerformanceLogCreate(BaseModel):
    workout_log_id: int
    user_id: str  # UUID string from Supabase
    exercise_id: str
    exercise_name: str
    set_number: int
    reps_completed: int
    weight_kg: float
    rpe: Optional[float] = None
    rir: Optional[int] = None
    tempo: Optional[str] = None
    is_completed: bool = True
    failed_at_rep: Optional[int] = None
    notes: Optional[str] = None


class PerformanceLog(PerformanceLogCreate):
    id: int
    recorded_at: datetime


# ============================================
# Strength Record Models
# ============================================

class StrengthRecordCreate(BaseModel):
    user_id: str  # UUID string from Supabase
    exercise_id: str
    exercise_name: str
    weight_kg: float
    reps: int
    estimated_1rm: float
    rpe: Optional[float] = None
    is_pr: bool = False


class StrengthRecord(StrengthRecordCreate):
    id: int
    achieved_at: datetime


# ============================================
# Weekly Volume Models
# ============================================

class WeeklyVolumeCreate(BaseModel):
    user_id: str  # UUID string from Supabase
    muscle_group: str
    week_number: int
    year: int
    total_sets: int
    total_reps: int
    total_volume_kg: float
    frequency: int
    target_sets: int
    recovery_status: str = "recovered"


class WeeklyVolume(WeeklyVolumeCreate):
    id: int
    updated_at: datetime


# ============================================
# Chat History Models
# ============================================

class ChatCreate(BaseModel):
    user_id: str  # UUID string from Supabase
    user_message: str
    ai_response: str
    context_json: Optional[str] = None


class ChatHistory(ChatCreate):
    id: int
    timestamp: datetime


# ============================================
# Injury Models
# ============================================

class InjuryCreate(BaseModel):
    user_id: str  # UUID string from Supabase
    body_part: str
    severity: str
    onset_date: datetime
    affected_exercises: str
    is_active: bool = True


class Injury(InjuryCreate):
    id: int


# ============================================
# Analytics Models
# ============================================

class ExerciseAnalytics(BaseModel):
    exercise_id: str
    exercise_name: str
    total_sets: int
    total_reps: int
    total_volume_kg: float
    max_weight_kg: float
    current_1rm: float
    progression_rate: float  # % improvement over time


class MuscleGroupVolume(BaseModel):
    muscle_group: str
    total_sets: int
    target_sets: int
    percentage: float
    recovery_status: str


class PerformanceAnalyticsResponse(BaseModel):
    weekly_volumes: List[MuscleGroupVolume]
    top_exercises: List[ExerciseAnalytics]
    total_workouts: int
    total_volume_kg: float
    avg_workout_duration_minutes: float
