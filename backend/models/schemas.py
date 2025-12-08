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
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


# ============================================
# Workout Models
# ============================================

class WorkoutCreate(BaseModel):
    user_id: str
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
    id: str
    user_id: str
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
    generation_metadata: Optional[str] = None
    generated_at: Optional[datetime] = None
    last_modified_method: Optional[str] = None
    last_modified_at: Optional[datetime] = None
    modification_history: Optional[str] = None
    version_number: int = 1
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_workout_id: Optional[str] = None
    superseded_by: Optional[str] = None


class GenerateWorkoutRequest(BaseModel):
    user_id: str
    workout_type: Optional[str] = None
    duration_minutes: Optional[int] = 45
    focus_areas: Optional[List[str]] = None
    exclude_exercises: Optional[List[str]] = None
    fitness_level: Optional[str] = None
    goals: Optional[List[str]] = None
    equipment: Optional[List[str]] = None


class GenerateWeeklyRequest(BaseModel):
    user_id: str
    week_start_date: str
    selected_days: List[int]
    duration_minutes: Optional[int] = 45


class GenerateWeeklyResponse(BaseModel):
    workouts: List[Workout]


class GenerateMonthlyRequest(BaseModel):
    user_id: str
    month_start_date: str
    selected_days: List[int]
    duration_minutes: Optional[int] = 45
    weeks: Optional[int] = 12


class GenerateMonthlyResponse(BaseModel):
    workouts: List[Workout]
    total_generated: int


class SwapWorkoutsRequest(BaseModel):
    workout_id: str
    new_date: str
    reason: Optional[str] = None


class RegenerateWorkoutRequest(BaseModel):
    workout_id: str
    user_id: str
    duration_minutes: Optional[int] = 45
    fitness_level: Optional[str] = None
    difficulty: Optional[str] = None
    equipment: Optional[List[str]] = None
    focus_areas: Optional[List[str]] = None
    injuries: Optional[List[str]] = None  # List of injury areas to avoid (e.g., "Shoulder", "Knee")
    workout_type: Optional[str] = None  # Workout style: "Strength", "HIIT", "Cardio", "Flexibility", etc.


class RevertWorkoutRequest(BaseModel):
    workout_id: str
    target_version: int


class WorkoutVersionInfo(BaseModel):
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
    workout_id: str
    user_id: str
    sets_json: str
    total_time_seconds: int


class WorkoutLog(WorkoutLogCreate):
    id: str
    completed_at: datetime


# ============================================
# Performance Log Models
# ============================================

class PerformanceLogCreate(BaseModel):
    workout_log_id: str
    user_id: str
    exercise_id: str
    exercise_name: str
    set_number: int
    reps_completed: int
    weight_kg: float
    set_type: Optional[str] = None
    rpe: Optional[float] = None
    rir: Optional[int] = None
    tempo: Optional[str] = None
    is_completed: bool = True
    failed_at_rep: Optional[int] = None
    notes: Optional[str] = None


class PerformanceLog(PerformanceLogCreate):
    id: str
    recorded_at: datetime


# ============================================
# Strength Record Models
# ============================================

class StrengthRecordCreate(BaseModel):
    user_id: str
    exercise_id: str
    exercise_name: str
    weight_kg: float
    reps: int
    estimated_1rm: float
    rpe: Optional[float] = None
    is_pr: bool = False


class StrengthRecord(StrengthRecordCreate):
    id: str
    achieved_at: datetime


# ============================================
# Weekly Volume Models
# ============================================

class WeeklyVolumeCreate(BaseModel):
    user_id: str
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
    id: str
    updated_at: datetime


# ============================================
# Chat History Models
# ============================================

class ChatCreate(BaseModel):
    user_id: str
    user_message: str
    ai_response: str
    context_json: Optional[str] = None


class ChatHistory(ChatCreate):
    id: str
    timestamp: datetime


# ============================================
# Injury Models
# ============================================

class InjuryCreate(BaseModel):
    user_id: str
    body_part: str
    severity: str
    onset_date: datetime
    affected_exercises: str
    is_active: bool = True


class Injury(InjuryCreate):
    id: str


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
    progression_rate: float


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
# Chat with Image Support Models
# ============================================

class ChatMessageRequest(BaseModel):
    user_id: str
    message: str
    image_base64: Optional[str] = None
    conversation_history: Optional[List[dict]] = None


class ChatMessageResponse(BaseModel):
    response: str
    intent: Optional[str] = None
    tool_results: Optional[List[dict]] = None
    food_log_id: Optional[str] = None
    nutrition_data: Optional[dict] = None


# ============================================
# Warmup and Stretch Models
# ============================================

class WarmupExercise(BaseModel):
    name: str
    sets: int = 1
    reps: Optional[int] = None
    duration_seconds: Optional[int] = None
    rest_seconds: int = 10
    equipment: str = "none"
    muscle_group: str
    notes: Optional[str] = None


class WarmupCreate(BaseModel):
    workout_id: str
    exercises_json: List[WarmupExercise]
    duration_minutes: int = 5


class Warmup(BaseModel):
    id: str
    workout_id: Optional[str] = None
    exercises_json: List[WarmupExercise]
    duration_minutes: int = 5
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    version_number: int = 1
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_warmup_id: Optional[str] = None
    superseded_by: Optional[str] = None


class WarmupVersionInfo(BaseModel):
    id: str
    version_number: int
    is_current: bool
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    exercises_count: int = 0


class StretchExercise(BaseModel):
    name: str
    sets: int = 1
    reps: int = 1
    duration_seconds: int = 30
    rest_seconds: int = 0
    equipment: str = "none"
    muscle_group: str
    notes: Optional[str] = None


class StretchCreate(BaseModel):
    workout_id: str
    exercises_json: List[StretchExercise]
    duration_minutes: int = 5


class Stretch(BaseModel):
    id: str
    workout_id: Optional[str] = None
    exercises_json: List[StretchExercise]
    duration_minutes: int = 5
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    version_number: int = 1
    is_current: bool = True
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    parent_stretch_id: Optional[str] = None
    superseded_by: Optional[str] = None


class StretchVersionInfo(BaseModel):
    id: str
    version_number: int
    is_current: bool
    valid_from: Optional[datetime] = None
    valid_to: Optional[datetime] = None
    exercises_count: int = 0


class RegenerateWarmupRequest(BaseModel):
    warmup_id: str
    workout_id: str
    duration_minutes: Optional[int] = 5


class RegenerateStretchRequest(BaseModel):
    stretch_id: str
    workout_id: str
    duration_minutes: Optional[int] = 5


# ============================================
# Background Workout Generation
# ============================================

class PendingWorkoutGenerationStatus(BaseModel):
    user_id: str
    status: str
    total_expected: int = 0
    total_generated: int = 0
    error_message: Optional[str] = None


class ScheduleBackgroundGenerationRequest(BaseModel):
    user_id: str
    month_start_date: str
    duration_minutes: int = 45
    selected_days: List[int]
    weeks: int = 11


# ============================================
# Workout Exercise Modification Models
# ============================================

class WorkoutExerciseItem(BaseModel):
    name: str
    sets: int = 3
    reps: int = 10
    weight: Optional[float] = None
    rest_seconds: int = 60
    notes: Optional[str] = None
    target_muscles: Optional[List[str]] = None
    equipment: Optional[str] = None


class UpdateWorkoutExercisesRequest(BaseModel):
    exercises: List[WorkoutExerciseItem]


class UpdateWarmupExercisesRequest(BaseModel):
    exercises: List[WarmupExercise]


class UpdateStretchExercisesRequest(BaseModel):
    exercises: List[StretchExercise]
