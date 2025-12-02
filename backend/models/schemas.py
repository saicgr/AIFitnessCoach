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
    created_by_user_id: Optional[str] = None  # UUID string from Supabase


class Exercise(ExerciseCreate):
    id: str  # UUID string from Supabase
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
    # SCD2 Versioning fields
    version_number: int = 1
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_workout_id: Optional[str] = None  # UUID of original workout
    superseded_by: Optional[str] = None  # UUID of newer version


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
    """Request to generate workouts for a specified number of weeks (default 12 weeks)."""
    user_id: str  # UUID string from Supabase
    month_start_date: str  # ISO date string, e.g., "2024-11-01"
    selected_days: List[int]  # 0=Mon, 1=Tue, ..., 6=Sun
    duration_minutes: Optional[int] = 45
    weeks: Optional[int] = 12  # Number of weeks to generate (default 12 weeks)


class GenerateMonthlyResponse(BaseModel):
    """Response containing all generated workouts for the month."""
    workouts: List[Workout]
    total_generated: int


class SwapWorkoutsRequest(BaseModel):
    workout_id: str  # UUID string from Supabase
    new_date: str  # ISO date, e.g., "2024-11-25"
    reason: Optional[str] = None


class RegenerateWorkoutRequest(BaseModel):
    """Request to regenerate a workout with new settings while preserving history."""
    workout_id: str  # UUID of the workout to regenerate
    user_id: str  # UUID of the user
    duration_minutes: Optional[int] = 45
    fitness_level: Optional[str] = None  # beginner/intermediate/advanced
    difficulty: Optional[str] = None  # easy/medium/hard - explicit workout difficulty
    equipment: Optional[List[str]] = None
    focus_areas: Optional[List[str]] = None


class RevertWorkoutRequest(BaseModel):
    """Request to revert a workout to a previous version."""
    workout_id: str  # UUID of current workout
    target_version: int  # Version number to revert to


class WorkoutVersionInfo(BaseModel):
    """Summarized version info for version history display."""
    id: str
    version_number: int
    name: str
    is_current: bool
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    generation_method: Optional[str] = None
    exercises_count: int = 0


# ============================================
# Workout Log Models
# ============================================

class WorkoutLogCreate(BaseModel):
    workout_id: str  # UUID string from Supabase
    user_id: str  # UUID string from Supabase
    sets_json: str
    total_time_seconds: int


class WorkoutLog(WorkoutLogCreate):
    id: str  # UUID string from Supabase
    completed_at: datetime


# ============================================
# Performance Log Models
# ============================================

class PerformanceLogCreate(BaseModel):
    workout_log_id: str  # UUID string from Supabase
    user_id: str  # UUID string from Supabase
    exercise_id: str
    exercise_name: str
    set_number: int
    reps_completed: int
    weight_kg: float
    set_type: Optional[str] = None  # 'warmup', 'working', or 'failure'
    rpe: Optional[float] = None
    rir: Optional[int] = None
    tempo: Optional[str] = None
    is_completed: bool = True
    failed_at_rep: Optional[int] = None
    notes: Optional[str] = None


class PerformanceLog(PerformanceLogCreate):
    id: str  # UUID string from Supabase
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
    id: str  # UUID string from Supabase
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
    id: str  # UUID string from Supabase
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
    id: str  # UUID string from Supabase
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
    id: str  # UUID string from Supabase


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


# ============================================
# Nutrition / Food Log Models
# ============================================

class FoodItem(BaseModel):
    """Individual food item with nutrition data."""
    name: str
    amount: Optional[str] = None  # e.g., "150g", "1 cup"
    calories: Optional[int] = None
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None


class FoodLogCreate(BaseModel):
    """Create a new food log."""
    user_id: str  # UUID string
    meal_type: str  # breakfast, lunch, dinner, snack
    food_items: List[FoodItem]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    health_score: Optional[int] = None  # 1-10
    ai_feedback: Optional[str] = None


class FoodLog(BaseModel):
    """Food log response."""
    id: str  # UUID string
    user_id: str
    meal_type: str
    logged_at: datetime
    food_items: List[FoodItem]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    health_score: Optional[int] = None
    ai_feedback: Optional[str] = None
    created_at: datetime


class DailyNutritionSummary(BaseModel):
    """Daily nutrition summary."""
    date: str
    total_calories: int
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    total_fiber_g: float
    meal_count: int
    avg_health_score: Optional[float] = None


class NutritionTargets(BaseModel):
    """User's daily nutrition targets."""
    daily_calorie_target: Optional[int] = None
    daily_protein_target_g: Optional[float] = None
    daily_carbs_target_g: Optional[float] = None
    daily_fat_target_g: Optional[float] = None


class UpdateNutritionTargetsRequest(BaseModel):
    """Request to update user's nutrition targets."""
    user_id: str  # UUID string
    daily_calorie_target: Optional[int] = None
    daily_protein_target_g: Optional[float] = None
    daily_carbs_target_g: Optional[float] = None
    daily_fat_target_g: Optional[float] = None


# ============================================
# Chat with Image Support Models
# ============================================

class ChatMessageRequest(BaseModel):
    """Chat message request with optional image for food analysis."""
    user_id: str  # UUID string
    message: str
    image_base64: Optional[str] = None  # Base64 encoded image (without data:image prefix)
    conversation_history: Optional[List[dict]] = None  # Previous messages for context


class ChatMessageResponse(BaseModel):
    """Chat message response."""
    response: str
    intent: Optional[str] = None
    tool_results: Optional[List[dict]] = None  # Results from any tools called
    food_log_id: Optional[str] = None  # If a food was logged
    nutrition_data: Optional[dict] = None  # Nutrition analysis results


# ============================================
# Warmup and Stretch Models (SCD2 Versioned)
# ============================================

class WarmupExercise(BaseModel):
    """Individual warm-up exercise."""
    name: str
    sets: int = 1
    reps: Optional[int] = None
    duration_seconds: Optional[int] = None
    rest_seconds: int = 10
    equipment: str = "none"
    muscle_group: str
    notes: Optional[str] = None


class WarmupCreate(BaseModel):
    """Create a new warmup for a workout."""
    workout_id: str  # UUID string
    exercises_json: List[WarmupExercise]
    duration_minutes: int = 5


class Warmup(BaseModel):
    """Warmup response with SCD2 versioning."""
    id: str  # UUID string
    workout_id: Optional[str] = None  # UUID string (nullable for historical)
    exercises_json: List[WarmupExercise]
    duration_minutes: int = 5
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    # SCD2 Versioning fields
    version_number: int = 1
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_warmup_id: Optional[str] = None  # UUID of original warmup
    superseded_by: Optional[str] = None  # UUID of newer version


class WarmupVersionInfo(BaseModel):
    """Summarized version info for warmup history display."""
    id: str
    version_number: int
    is_current: bool
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    exercises_count: int = 0


class StretchExercise(BaseModel):
    """Individual stretch exercise."""
    name: str
    sets: int = 1
    reps: int = 1
    duration_seconds: int = 30
    rest_seconds: int = 0
    equipment: str = "none"
    muscle_group: str
    notes: Optional[str] = None


class StretchCreate(BaseModel):
    """Create a new stretch routine for a workout."""
    workout_id: str  # UUID string
    exercises_json: List[StretchExercise]
    duration_minutes: int = 5


class Stretch(BaseModel):
    """Stretch response with SCD2 versioning."""
    id: str  # UUID string
    workout_id: Optional[str] = None  # UUID string (nullable for historical)
    exercises_json: List[StretchExercise]
    duration_minutes: int = 5
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    # SCD2 Versioning fields
    version_number: int = 1
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_stretch_id: Optional[str] = None  # UUID of original stretch
    superseded_by: Optional[str] = None  # UUID of newer version


class StretchVersionInfo(BaseModel):
    """Summarized version info for stretch history display."""
    id: str
    version_number: int
    is_current: bool
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    exercises_count: int = 0


class RegenerateWarmupRequest(BaseModel):
    """Request to regenerate warmup with new settings while preserving history."""
    warmup_id: str  # UUID of the warmup to regenerate
    workout_id: str  # UUID of the workout
    duration_minutes: Optional[int] = 5


class RegenerateStretchRequest(BaseModel):
    """Request to regenerate stretch with new settings while preserving history."""
    stretch_id: str  # UUID of the stretch to regenerate
    workout_id: str  # UUID of the workout
    duration_minutes: Optional[int] = 5


# ============================================
# Background Workout Generation
# ============================================

class PendingWorkoutGenerationStatus(BaseModel):
    """Status response for pending workout generation."""
    user_id: str
    status: str  # pending, in_progress, completed, failed
    total_expected: int = 0
    total_generated: int = 0
    error_message: Optional[str] = None


class ScheduleBackgroundGenerationRequest(BaseModel):
    """Request to schedule background workout generation."""
    user_id: str
    month_start_date: str
    duration_minutes: int = 45
    selected_days: List[int]
    weeks: int = 11
