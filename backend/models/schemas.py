"""
Pydantic models for API requests and responses.

This file re-exports all models for backward compatibility.
Models are now organized in separate domain modules:
- user.py: User-related models
- exercise.py: Exercise models
- workout.py: Workout models (existing)
- nutrition.py: Nutrition and hydration models
- feedback.py: Feedback and exit tracking models
- achievements.py: Achievements and milestones models
- notifications.py: Notification and summary models
"""

# Re-export all models for backward compatibility
from models.user import (
    UserPreferences,
    UserCreate,
    UserUpdate,
    User,
)

from models.exercise import (
    ExerciseCreate,
    Exercise,
)

from models.nutrition import (
    FoodItem,
    FoodLogCreate,
    FoodLog,
    DailyNutritionSummary,
    NutritionTargets,
    UpdateNutritionTargetsRequest,
    HydrationLogCreate,
    HydrationLog,
    DailyHydrationSummary,
    HydrationGoalUpdate,
    HydrationReminderSettings,
)

from models.feedback import (
    WorkoutExitCreate,
    WorkoutExit,
    ExerciseFeedbackCreate,
    ExerciseFeedback,
    WorkoutFeedbackCreate,
    WorkoutFeedback,
    WorkoutFeedbackWithExercises,
    DrinkIntakeCreate,
    DrinkIntake,
    RestIntervalCreate,
    RestInterval,
)

from models.achievements import (
    AchievementType,
    UserAchievement,
    UserStreak,
    PersonalRecord,
    AchievementsSummary,
    NewAchievementNotification,
)

from models.notifications import (
    WeeklySummaryCreate,
    WeeklySummary,
    NotificationPreferences,
    NotificationPreferencesUpdate,
)

# Workout models - kept here as they are the most complex and heavily used
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ============================================
# Workout Models
# ============================================

class WorkoutCreate(BaseModel):
    user_id: str = Field(..., max_length=100)
    name: str = Field(..., max_length=200)
    type: str = Field(..., max_length=50)
    difficulty: str = Field(..., max_length=50)
    scheduled_date: datetime
    exercises_json: str = Field(..., max_length=100000)
    duration_minutes: int = Field(default=45, ge=1, le=480)
    generation_method: str = Field(default="algorithm", max_length=50)
    generation_source: str = Field(default="onboarding", max_length=50)
    generation_metadata: str = Field(default="{}", max_length=50000)


class WorkoutUpdate(BaseModel):
    name: Optional[str] = Field(default=None, max_length=200)
    type: Optional[str] = Field(default=None, max_length=50)
    difficulty: Optional[str] = Field(default=None, max_length=50)
    scheduled_date: Optional[datetime] = None
    is_completed: Optional[bool] = None
    exercises_json: Optional[str] = Field(default=None, max_length=100000)
    last_modified_method: Optional[str] = Field(default=None, max_length=50)


class Workout(BaseModel):
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    name: str = Field(..., max_length=200)
    type: str = Field(..., max_length=50)
    difficulty: str = Field(..., max_length=50)
    scheduled_date: datetime
    is_completed: bool
    exercises_json: str = Field(..., max_length=100000)
    duration_minutes: int = Field(default=45, ge=1, le=480)
    created_at: Optional[datetime] = None
    generation_method: Optional[str] = Field(default=None, max_length=50)
    generation_source: Optional[str] = Field(default=None, max_length=50)
    generation_metadata: Optional[str] = Field(default=None, max_length=50000)
    generated_at: Optional[datetime] = None
    last_modified_method: Optional[str] = Field(default=None, max_length=50)
    last_modified_at: Optional[datetime] = None
    modification_history: Optional[str] = Field(default=None, max_length=100000)
    version_number: int = Field(default=1, ge=1)
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_workout_id: Optional[str] = Field(default=None, max_length=100)
    superseded_by: Optional[str] = Field(default=None, max_length=100)


class GenerateWorkoutRequest(BaseModel):
    user_id: str = Field(..., max_length=100)
    workout_type: Optional[str] = Field(default=None, max_length=50)
    duration_minutes: Optional[int] = Field(default=45, ge=1, le=480)
    focus_areas: Optional[List[str]] = Field(default=None, max_length=20)
    exclude_exercises: Optional[List[str]] = Field(default=None, max_length=50)
    fitness_level: Optional[str] = Field(default=None, max_length=50)
    goals: Optional[List[str]] = Field(default=None, max_length=20)
    equipment: Optional[List[str]] = Field(default=None, max_length=50)


class GenerateWeeklyRequest(BaseModel):
    user_id: str = Field(..., max_length=100)
    week_start_date: str = Field(..., max_length=20)
    selected_days: List[int] = Field(..., max_length=7)
    duration_minutes: Optional[int] = Field(default=45, ge=1, le=480)


class GenerateWeeklyResponse(BaseModel):
    workouts: List[Workout]


class GenerateMonthlyRequest(BaseModel):
    user_id: str = Field(..., max_length=100)
    month_start_date: str = Field(..., max_length=20)
    selected_days: List[int] = Field(..., max_length=7)
    duration_minutes: Optional[int] = Field(default=45, ge=1, le=480)
    weeks: Optional[int] = Field(default=12, ge=1, le=52)


class GenerateMonthlyResponse(BaseModel):
    workouts: List[Workout]
    total_generated: int


class SwapWorkoutsRequest(BaseModel):
    workout_id: str = Field(..., max_length=100)
    new_date: str = Field(..., max_length=20)
    reason: Optional[str] = Field(default=None, max_length=500)


class SwapExerciseRequest(BaseModel):
    """Request to swap an exercise within a workout."""
    workout_id: str = Field(..., max_length=100)
    old_exercise_name: str = Field(..., max_length=200)
    new_exercise_name: str = Field(..., max_length=200)
    reason: Optional[str] = Field(default=None, max_length=500)


class AddExerciseRequest(BaseModel):
    """Request to add an exercise to a workout."""
    workout_id: str = Field(..., max_length=100)
    exercise_name: str = Field(..., max_length=200)
    sets: Optional[int] = Field(default=3, ge=1, le=10)
    reps: Optional[str] = Field(default="8-12", max_length=20)
    rest_seconds: Optional[int] = Field(default=60, ge=0, le=300)


class RegenerateWorkoutRequest(BaseModel):
    workout_id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    duration_minutes: Optional[int] = Field(default=45, ge=1, le=480)
    fitness_level: Optional[str] = Field(default=None, max_length=50)
    difficulty: Optional[str] = Field(default=None, max_length=50)
    equipment: Optional[List[str]] = Field(default=None, max_length=50)
    focus_areas: Optional[List[str]] = Field(default=None, max_length=20)
    injuries: Optional[List[str]] = Field(default=None, max_length=20)  # List of injury areas to avoid
    workout_type: Optional[str] = Field(default=None, max_length=50)  # Workout style: "Strength", "HIIT", etc.
    workout_name: Optional[str] = Field(default=None, max_length=200)  # Optional workout name
    ai_prompt: Optional[str] = Field(default=None, max_length=2000)  # Optional AI prompt for context
    dumbbell_count: Optional[int] = Field(default=None, ge=1, le=10)  # Number of dumbbells available
    kettlebell_count: Optional[int] = Field(default=None, ge=1, le=10)  # Number of kettlebells available


class UpdateProgramRequest(BaseModel):
    """Request to update program preferences and regenerate future workouts."""
    user_id: str = Field(..., max_length=100)
    difficulty: Optional[str] = Field(default=None, max_length=50)
    duration_minutes: Optional[int] = Field(default=45, ge=1, le=480)
    workout_type: Optional[str] = Field(default=None, max_length=50)
    workout_days: Optional[List[str]] = Field(default=None, max_length=7)  # ["Mon", "Wed", "Fri"]
    equipment: Optional[List[str]] = Field(default=None, max_length=50)
    focus_areas: Optional[List[str]] = Field(default=None, max_length=20)
    injuries: Optional[List[str]] = Field(default=None, max_length=20)
    dumbbell_count: Optional[int] = Field(default=2, ge=1, le=10)  # 1 or 2 dumbbells
    kettlebell_count: Optional[int] = Field(default=1, ge=1, le=10)  # 1 or 2 kettlebells
    custom_program_description: Optional[str] = Field(default=None, max_length=500)  # For custom programs


class UpdateProgramResponse(BaseModel):
    """Response from update program endpoint."""
    success: bool
    message: str = Field(..., max_length=500)
    workouts_deleted: int = Field(..., ge=0)
    preferences_updated: bool


class RevertWorkoutRequest(BaseModel):
    workout_id: str = Field(..., max_length=100)
    target_version: int = Field(..., ge=1)


class WorkoutVersionInfo(BaseModel):
    id: str = Field(..., max_length=100)
    version_number: int = Field(..., ge=1)
    name: str = Field(..., max_length=200)
    is_current: bool
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    generation_method: Optional[str] = Field(default=None, max_length=50)
    exercises_count: int = Field(default=0, ge=0)


# ============================================
# Workout Log Models
# ============================================

class WorkoutLogCreate(BaseModel):
    workout_id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    sets_json: str = Field(..., max_length=100000)
    total_time_seconds: int = Field(..., ge=0, le=86400)  # max 24 hours


class WorkoutLog(WorkoutLogCreate):
    id: str = Field(..., max_length=100)
    completed_at: datetime


# ============================================
# Performance Log Models
# ============================================

class PerformanceLogCreate(BaseModel):
    workout_log_id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    exercise_id: str = Field(..., max_length=100)
    exercise_name: str = Field(..., max_length=200)
    set_number: int = Field(..., ge=1, le=100)
    reps_completed: int = Field(..., ge=0, le=1000)
    weight_kg: float = Field(..., ge=0, le=1000)
    set_type: Optional[str] = Field(default=None, max_length=50)
    rpe: Optional[float] = Field(default=None, ge=0, le=10)
    rir: Optional[int] = Field(default=None, ge=0, le=10)
    tempo: Optional[str] = Field(default=None, max_length=20)
    is_completed: bool = True
    failed_at_rep: Optional[int] = Field(default=None, ge=0)
    notes: Optional[str] = Field(default=None, max_length=500)


class PerformanceLog(PerformanceLogCreate):
    id: str = Field(..., max_length=100)
    recorded_at: datetime


# ============================================
# Strength Record Models
# ============================================

class StrengthRecordCreate(BaseModel):
    user_id: str = Field(..., max_length=100)
    exercise_id: str = Field(..., max_length=100)
    exercise_name: str = Field(..., max_length=200)
    weight_kg: float = Field(..., ge=0, le=1000)
    reps: int = Field(..., ge=1, le=1000)
    estimated_1rm: float = Field(..., ge=0, le=2000)
    rpe: Optional[float] = Field(default=None, ge=0, le=10)
    is_pr: bool = False


class StrengthRecord(StrengthRecordCreate):
    id: str = Field(..., max_length=100)
    achieved_at: datetime


# ============================================
# Weekly Volume Models
# ============================================

class WeeklyVolumeCreate(BaseModel):
    user_id: str = Field(..., max_length=100)
    muscle_group: str = Field(..., max_length=50)
    week_number: int = Field(..., ge=1, le=53)
    year: int = Field(..., ge=2000, le=2100)
    total_sets: int = Field(..., ge=0)
    total_reps: int = Field(..., ge=0)
    total_volume_kg: float = Field(..., ge=0)
    frequency: int = Field(..., ge=0, le=7)
    target_sets: int = Field(..., ge=0)
    recovery_status: str = Field(default="recovered", max_length=50)


class WeeklyVolume(WeeklyVolumeCreate):
    id: str = Field(..., max_length=100)
    updated_at: datetime


# ============================================
# Chat History Models
# ============================================

class ChatCreate(BaseModel):
    user_id: str = Field(..., max_length=100)
    user_message: str = Field(..., max_length=5000)
    ai_response: str = Field(..., max_length=20000)
    context_json: Optional[str] = Field(default=None, max_length=50000)


class ChatHistory(ChatCreate):
    id: str = Field(..., max_length=100)
    timestamp: datetime


# ============================================
# Injury Models
# ============================================

class InjuryCreate(BaseModel):
    user_id: str = Field(..., max_length=100)
    body_part: str = Field(..., max_length=100)
    severity: str = Field(..., max_length=50)
    onset_date: datetime
    affected_exercises: str = Field(..., max_length=10000)
    is_active: bool = True


class Injury(InjuryCreate):
    id: str = Field(..., max_length=100)


# ============================================
# Analytics Models
# ============================================

class ExerciseAnalytics(BaseModel):
    exercise_id: str = Field(..., max_length=100)
    exercise_name: str = Field(..., max_length=200)
    total_sets: int = Field(..., ge=0)
    total_reps: int = Field(..., ge=0)
    total_volume_kg: float = Field(..., ge=0)
    max_weight_kg: float = Field(..., ge=0)
    current_1rm: float = Field(..., ge=0)
    progression_rate: float


class MuscleGroupVolume(BaseModel):
    muscle_group: str = Field(..., max_length=50)
    total_sets: int = Field(..., ge=0)
    target_sets: int = Field(..., ge=0)
    percentage: float = Field(..., ge=0)
    recovery_status: str = Field(..., max_length=50)


class PerformanceAnalyticsResponse(BaseModel):
    weekly_volumes: List[MuscleGroupVolume]
    top_exercises: List[ExerciseAnalytics]
    total_workouts: int = Field(..., ge=0)
    total_volume_kg: float = Field(..., ge=0)
    avg_workout_duration_minutes: float = Field(..., ge=0)


# ============================================
# Chat with Image Support Models
# ============================================

class ChatMessageRequest(BaseModel):
    user_id: str = Field(..., max_length=100)
    message: str = Field(..., max_length=5000)
    image_base64: Optional[str] = Field(default=None, max_length=17_800_000)  # ~10MB decoded
    conversation_history: Optional[List[dict]] = Field(default=None, max_length=100)


class ChatMessageResponse(BaseModel):
    response: str = Field(..., max_length=20000)
    intent: Optional[str] = Field(default=None, max_length=50)
    tool_results: Optional[List[dict]] = None
    food_log_id: Optional[str] = Field(default=None, max_length=100)
    nutrition_data: Optional[dict] = None


# ============================================
# Warmup and Stretch Models
# ============================================

class WarmupExercise(BaseModel):
    name: str = Field(..., max_length=200)
    sets: int = Field(default=1, ge=1, le=20)
    reps: Optional[int] = Field(default=None, ge=1, le=100)
    duration_seconds: Optional[int] = Field(default=None, ge=1, le=600)
    rest_seconds: int = Field(default=10, ge=0, le=300)
    equipment: str = Field(default="none", max_length=100)
    muscle_group: str = Field(..., max_length=50)
    notes: Optional[str] = Field(default=None, max_length=500)


class WarmupCreate(BaseModel):
    workout_id: str = Field(..., max_length=100)
    exercises_json: List[WarmupExercise] = Field(..., max_length=20)
    duration_minutes: int = Field(default=5, ge=1, le=60)


class Warmup(BaseModel):
    id: str = Field(..., max_length=100)
    workout_id: Optional[str] = Field(default=None, max_length=100)
    exercises_json: List[WarmupExercise] = Field(..., max_length=20)
    duration_minutes: int = Field(default=5, ge=1, le=60)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    version_number: int = Field(default=1, ge=1)
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_warmup_id: Optional[str] = Field(default=None, max_length=100)
    superseded_by: Optional[str] = Field(default=None, max_length=100)


class WarmupVersionInfo(BaseModel):
    id: str = Field(..., max_length=100)
    version_number: int = Field(..., ge=1)
    is_current: bool
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    exercises_count: int = Field(default=0, ge=0)


class StretchExercise(BaseModel):
    name: str = Field(..., max_length=200)
    sets: int = Field(default=1, ge=1, le=20)
    reps: int = Field(default=1, ge=1, le=100)
    duration_seconds: int = Field(default=30, ge=1, le=600)
    rest_seconds: int = Field(default=0, ge=0, le=300)
    equipment: str = Field(default="none", max_length=100)
    muscle_group: str = Field(..., max_length=50)
    notes: Optional[str] = Field(default=None, max_length=500)


class StretchCreate(BaseModel):
    workout_id: str = Field(..., max_length=100)
    exercises_json: List[StretchExercise] = Field(..., max_length=20)
    duration_minutes: int = Field(default=5, ge=1, le=60)


class Stretch(BaseModel):
    id: str = Field(..., max_length=100)
    workout_id: Optional[str] = Field(default=None, max_length=100)
    exercises_json: List[StretchExercise] = Field(..., max_length=20)
    duration_minutes: int = Field(default=5, ge=1, le=60)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    version_number: int = Field(default=1, ge=1)
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_stretch_id: Optional[str] = Field(default=None, max_length=100)
    superseded_by: Optional[str] = Field(default=None, max_length=100)


class StretchVersionInfo(BaseModel):
    id: str = Field(..., max_length=100)
    version_number: int = Field(..., ge=1)
    is_current: bool
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    exercises_count: int = Field(default=0, ge=0)


class RegenerateWarmupRequest(BaseModel):
    warmup_id: str = Field(..., max_length=100)
    workout_id: str = Field(..., max_length=100)
    duration_minutes: Optional[int] = Field(default=5, ge=1, le=60)


class RegenerateStretchRequest(BaseModel):
    stretch_id: str = Field(..., max_length=100)
    workout_id: str = Field(..., max_length=100)
    duration_minutes: Optional[int] = Field(default=5, ge=1, le=60)


# ============================================
# Background Workout Generation
# ============================================

class PendingWorkoutGenerationStatus(BaseModel):
    user_id: str = Field(..., max_length=100)
    status: str = Field(..., max_length=50)
    total_expected: int = Field(default=0, ge=0)
    total_generated: int = Field(default=0, ge=0)
    error_message: Optional[str] = Field(default=None, max_length=1000)


class ScheduleBackgroundGenerationRequest(BaseModel):
    user_id: str = Field(..., max_length=100)
    month_start_date: str = Field(..., max_length=20)
    duration_minutes: int = Field(default=45, ge=1, le=480)
    selected_days: List[int] = Field(..., max_length=7)
    weeks: int = Field(default=11, ge=1, le=52)


# ============================================
# Workout Exercise Modification Models
# ============================================

class WorkoutExerciseItem(BaseModel):
    name: str = Field(..., max_length=200)
    sets: int = Field(default=3, ge=1, le=20)
    reps: int = Field(default=10, ge=1, le=100)
    weight: Optional[float] = Field(default=None, ge=0, le=1000)
    rest_seconds: int = Field(default=60, ge=0, le=600)
    notes: Optional[str] = Field(default=None, max_length=500)
    target_muscles: Optional[List[str]] = Field(default=None, max_length=20)
    equipment: Optional[str] = Field(default=None, max_length=100)


class UpdateWorkoutExercisesRequest(BaseModel):
    exercises: List[WorkoutExerciseItem] = Field(..., max_length=50)


class UpdateWarmupExercisesRequest(BaseModel):
    exercises: List[WarmupExercise] = Field(..., max_length=20)


class UpdateStretchExercisesRequest(BaseModel):
    exercises: List[StretchExercise] = Field(..., max_length=20)
