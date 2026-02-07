"""
Hormonal Health Models
Pydantic models for hormonal health tracking, cycle management, and kegel preferences.
"""

from datetime import date as date_type, time as time_type, datetime
from typing import Optional, List
from pydantic import BaseModel, Field, validator
from enum import Enum


# ============================================================================
# ENUMS
# ============================================================================

class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"
    NON_BINARY = "non_binary"
    OTHER = "other"
    PREFER_NOT_TO_SAY = "prefer_not_to_say"


class BirthSex(str, Enum):
    MALE = "male"
    FEMALE = "female"
    INTERSEX = "intersex"
    PREFER_NOT_TO_SAY = "prefer_not_to_say"


class HormoneGoal(str, Enum):
    OPTIMIZE_TESTOSTERONE = "optimize_testosterone"
    BALANCE_ESTROGEN = "balance_estrogen"
    IMPROVE_FERTILITY = "improve_fertility"
    MENOPAUSE_SUPPORT = "menopause_support"
    PCOS_MANAGEMENT = "pcos_management"
    PERIMENOPAUSE_SUPPORT = "perimenopause_support"
    ANDROPAUSE_SUPPORT = "andropause_support"
    GENERAL_WELLNESS = "general_wellness"
    LIBIDO_ENHANCEMENT = "libido_enhancement"
    ENERGY_OPTIMIZATION = "energy_optimization"
    MOOD_STABILIZATION = "mood_stabilization"
    SLEEP_IMPROVEMENT = "sleep_improvement"


class MenopauseStatus(str, Enum):
    PRE = "pre"
    PERI = "peri"
    POST = "post"
    NOT_APPLICABLE = "not_applicable"


class AndropauseStatus(str, Enum):
    NONE = "none"
    EARLY = "early"
    MODERATE = "moderate"
    ADVANCED = "advanced"
    NOT_APPLICABLE = "not_applicable"


class CyclePhase(str, Enum):
    MENSTRUAL = "menstrual"
    FOLLICULAR = "follicular"
    OVULATION = "ovulation"
    LUTEAL = "luteal"


class PeriodFlow(str, Enum):
    NONE = "none"
    SPOTTING = "spotting"
    LIGHT = "light"
    MEDIUM = "medium"
    HEAVY = "heavy"


class Mood(str, Enum):
    EXCELLENT = "excellent"
    GOOD = "good"
    STABLE = "stable"
    LOW = "low"
    IRRITABLE = "irritable"
    ANXIOUS = "anxious"
    DEPRESSED = "depressed"


class Symptom(str, Enum):
    BLOATING = "bloating"
    CRAMPS = "cramps"
    HEADACHE = "headache"
    MIGRAINE = "migraine"
    HOT_FLASHES = "hot_flashes"
    NIGHT_SWEATS = "night_sweats"
    FATIGUE = "fatigue"
    MUSCLE_WEAKNESS = "muscle_weakness"
    BRAIN_FOG = "brain_fog"
    BREAST_TENDERNESS = "breast_tenderness"
    BACK_PAIN = "back_pain"
    JOINT_PAIN = "joint_pain"
    ACNE = "acne"
    SKIN_CHANGES = "skin_changes"
    HAIR_CHANGES = "hair_changes"
    WEIGHT_FLUCTUATION = "weight_fluctuation"
    WATER_RETENTION = "water_retention"
    DIGESTIVE_ISSUES = "digestive_issues"
    INSOMNIA = "insomnia"
    VIVID_DREAMS = "vivid_dreams"
    ANXIETY = "anxiety"
    IRRITABILITY = "irritability"
    LOW_LIBIDO = "low_libido"
    VAGINAL_DRYNESS = "vaginal_dryness"
    ERECTILE_DIFFICULTY = "erectile_difficulty"


class CycleRegularity(str, Enum):
    REGULAR = "regular"
    IRREGULAR = "irregular"
    VERY_IRREGULAR = "very_irregular"
    UNKNOWN = "unknown"


class ExerciseIntensity(str, Enum):
    REST = "rest"
    LIGHT = "light"
    MODERATE = "moderate"
    INTENSE = "intense"


class CervicalMucus(str, Enum):
    DRY = "dry"
    STICKY = "sticky"
    CREAMY = "creamy"
    WATERY = "watery"
    EGG_WHITE = "egg_white"


class ThyroidConditionType(str, Enum):
    HYPOTHYROID = "hypothyroid"
    HYPERTHYROID = "hyperthyroid"
    HASHIMOTOS = "hashimotos"
    GRAVES = "graves"
    OTHER = "other"


# ============================================================================
# HORMONAL PROFILE MODELS
# ============================================================================

class HormonalProfileBase(BaseModel):
    """Base model for hormonal profile data."""
    gender: Optional[Gender] = None
    birth_sex: Optional[BirthSex] = None
    hormone_goals: List[HormoneGoal] = Field(default_factory=list)

    # Menstrual Tracking
    menstrual_tracking_enabled: bool = False
    cycle_length_days: Optional[int] = Field(None, ge=21, le=45)
    last_period_start_date: Optional[date_type] = None
    typical_period_duration_days: Optional[int] = Field(None, ge=2, le=10)
    cycle_regularity: Optional[CycleRegularity] = None

    # Menopause/Andropause
    menopause_status: MenopauseStatus = MenopauseStatus.NOT_APPLICABLE
    andropause_status: AndropauseStatus = AndropauseStatus.NOT_APPLICABLE

    # Feature Toggles
    testosterone_optimization_enabled: bool = False
    estrogen_balance_enabled: bool = False
    include_hormone_supportive_foods: bool = True
    include_hormone_supportive_exercises: bool = True
    cycle_sync_workouts: bool = False
    cycle_sync_nutrition: bool = False

    # Health Conditions
    has_pcos: bool = False
    has_endometriosis: bool = False
    has_thyroid_condition: bool = False
    thyroid_condition_type: Optional[ThyroidConditionType] = None
    on_hormone_therapy: bool = False
    hormone_therapy_type: Optional[str] = None


class HormonalProfileCreate(HormonalProfileBase):
    """Model for creating a hormonal profile."""
    pass


class HormonalProfileUpdate(BaseModel):
    """Model for updating a hormonal profile (all fields optional)."""
    gender: Optional[Gender] = None
    birth_sex: Optional[BirthSex] = None
    hormone_goals: Optional[List[HormoneGoal]] = None
    menstrual_tracking_enabled: Optional[bool] = None
    cycle_length_days: Optional[int] = Field(None, ge=21, le=45)
    last_period_start_date: Optional[date_type] = None
    typical_period_duration_days: Optional[int] = Field(None, ge=2, le=10)
    cycle_regularity: Optional[CycleRegularity] = None
    menopause_status: Optional[MenopauseStatus] = None
    andropause_status: Optional[AndropauseStatus] = None
    testosterone_optimization_enabled: Optional[bool] = None
    estrogen_balance_enabled: Optional[bool] = None
    include_hormone_supportive_foods: Optional[bool] = None
    include_hormone_supportive_exercises: Optional[bool] = None
    cycle_sync_workouts: Optional[bool] = None
    cycle_sync_nutrition: Optional[bool] = None
    has_pcos: Optional[bool] = None
    has_endometriosis: Optional[bool] = None
    has_thyroid_condition: Optional[bool] = None
    thyroid_condition_type: Optional[ThyroidConditionType] = None
    on_hormone_therapy: Optional[bool] = None
    hormone_therapy_type: Optional[str] = None


class HormonalProfile(HormonalProfileBase):
    """Full hormonal profile model with database fields."""
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# HORMONE LOG MODELS
# ============================================================================

class HormoneLogBase(BaseModel):
    """Base model for hormone log data."""
    log_date: date_type

    # Cycle Information
    cycle_day: Optional[int] = Field(None, ge=1, le=45)
    cycle_phase: Optional[CyclePhase] = None
    period_flow: Optional[PeriodFlow] = None

    # Wellness Metrics (1-10)
    energy_level: Optional[int] = Field(None, ge=1, le=10)
    sleep_quality: Optional[int] = Field(None, ge=1, le=10)
    libido_level: Optional[int] = Field(None, ge=1, le=10)
    stress_level: Optional[int] = Field(None, ge=1, le=10)
    motivation_level: Optional[int] = Field(None, ge=1, le=10)
    recovery_feeling: Optional[int] = Field(None, ge=1, le=10)

    # Mood
    mood: Optional[Mood] = None
    mood_notes: Optional[str] = None

    # Symptoms
    symptoms: List[Symptom] = Field(default_factory=list)

    # Additional Tracking
    exercise_performed: Optional[bool] = None
    exercise_intensity: Optional[ExerciseIntensity] = None
    basal_body_temperature: Optional[float] = Field(None, ge=35.0, le=40.0)
    cervical_mucus: Optional[CervicalMucus] = None

    # Notes
    notes: Optional[str] = None


class HormoneLogCreate(HormoneLogBase):
    """Model for creating a hormone log."""
    pass


class HormoneLog(HormoneLogBase):
    """Full hormone log model with database fields."""
    id: str
    user_id: str
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# CYCLE PHASE MODELS
# ============================================================================

class CyclePhaseInfo(BaseModel):
    """Information about current cycle phase."""
    user_id: str
    menstrual_tracking_enabled: bool
    current_cycle_day: Optional[int] = None
    current_phase: Optional[CyclePhase] = None
    days_until_next_phase: Optional[int] = None
    next_phase: Optional[CyclePhase] = None
    cycle_length_days: Optional[int] = None
    last_period_start_date: Optional[date_type] = None

    # Phase-specific recommendations
    recommended_intensity: Optional[str] = None
    avoid_exercises: List[str] = Field(default_factory=list)
    recommended_exercises: List[str] = Field(default_factory=list)
    nutrition_focus: List[str] = Field(default_factory=list)


class CyclePhaseRecommendation(BaseModel):
    """Recommendations based on cycle phase."""
    phase: CyclePhase
    phase_description: str
    workout_intensity: str
    recommended_exercise_types: List[str]
    exercises_to_avoid: List[str]
    nutrition_tips: List[str]
    self_care_tips: List[str]
    expected_energy_level: str


# ============================================================================
# KEGEL MODELS
# ============================================================================

class KegelFocusArea(str, Enum):
    GENERAL = "general"
    MALE_SPECIFIC = "male_specific"
    FEMALE_SPECIFIC = "female_specific"
    POSTPARTUM = "postpartum"
    PROSTATE_HEALTH = "prostate_health"


class KegelLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class ReminderFrequency(str, Enum):
    ONCE = "once"
    TWICE = "twice"
    THREE_TIMES = "three_times"
    HOURLY = "hourly"


class KegelSessionType(str, Enum):
    QUICK = "quick"
    STANDARD = "standard"
    ADVANCED = "advanced"
    CUSTOM = "custom"


class KegelPerformedDuring(str, Enum):
    WARMUP = "warmup"
    COOLDOWN = "cooldown"
    STANDALONE = "standalone"
    DAILY_ROUTINE = "daily_routine"
    OTHER = "other"


class KegelPreferencesBase(BaseModel):
    """Base model for kegel preferences."""
    kegels_enabled: bool = False
    include_in_warmup: bool = False
    include_in_cooldown: bool = False
    include_as_standalone: bool = False
    include_in_daily_routine: bool = False

    daily_reminder_enabled: bool = False
    daily_reminder_time: Optional[time_type] = None
    reminder_frequency: ReminderFrequency = ReminderFrequency.TWICE

    target_sessions_per_day: int = Field(3, ge=1, le=10)
    target_duration_seconds: int = Field(300, ge=30, le=1800)

    current_level: KegelLevel = KegelLevel.BEGINNER
    focus_area: KegelFocusArea = KegelFocusArea.GENERAL


class KegelPreferencesCreate(KegelPreferencesBase):
    """Model for creating kegel preferences."""
    pass


class KegelPreferencesUpdate(BaseModel):
    """Model for updating kegel preferences (all fields optional)."""
    kegels_enabled: Optional[bool] = None
    include_in_warmup: Optional[bool] = None
    include_in_cooldown: Optional[bool] = None
    include_as_standalone: Optional[bool] = None
    include_in_daily_routine: Optional[bool] = None
    daily_reminder_enabled: Optional[bool] = None
    daily_reminder_time: Optional[time_type] = None
    reminder_frequency: Optional[ReminderFrequency] = None
    target_sessions_per_day: Optional[int] = Field(None, ge=1, le=10)
    target_duration_seconds: Optional[int] = Field(None, ge=30, le=1800)
    current_level: Optional[KegelLevel] = None
    focus_area: Optional[KegelFocusArea] = None


class KegelPreferences(KegelPreferencesBase):
    """Full kegel preferences model with database fields."""
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class KegelSessionBase(BaseModel):
    """Base model for kegel session."""
    session_date: date_type = Field(default_factory=date_type.today)
    duration_seconds: int = Field(..., gt=0)
    reps_completed: Optional[int] = Field(None, ge=0)
    hold_duration_seconds: Optional[int] = Field(None, ge=0)
    session_type: KegelSessionType = KegelSessionType.STANDARD
    exercise_name: Optional[str] = None
    performed_during: Optional[KegelPerformedDuring] = None
    workout_id: Optional[str] = None
    difficulty_rating: Optional[int] = Field(None, ge=1, le=5)
    notes: Optional[str] = None


class KegelSessionCreate(KegelSessionBase):
    """Model for creating a kegel session."""
    pass


class KegelSession(KegelSessionBase):
    """Full kegel session model with database fields."""
    id: str
    user_id: str
    session_time: Optional[time_type] = None
    created_at: datetime

    class Config:
        from_attributes = True


class KegelStats(BaseModel):
    """Kegel exercise statistics."""
    user_id: str
    kegels_enabled: bool
    target_sessions_per_day: int
    total_days_practiced: int
    total_sessions: int
    total_duration_seconds: int
    avg_session_duration: int
    sessions_today: int
    sessions_last_7_days: int
    current_streak: int
    longest_streak: int
    daily_goal_met_today: bool


class KegelExercise(BaseModel):
    """Kegel exercise definition."""
    id: str
    name: str
    display_name: str
    description: str
    instructions: List[str]
    target_audience: str  # 'all', 'male', 'female'
    focus_muscles: List[str]
    difficulty: str
    default_duration_seconds: int
    default_reps: int
    default_hold_seconds: int
    rest_between_reps_seconds: int
    benefits: List[str]
    video_url: Optional[str] = None
    animation_type: Optional[str] = None

    class Config:
        from_attributes = True


class KegelDailyGoal(BaseModel):
    """Daily kegel goal status."""
    user_id: str
    date: date_type
    goal_met: bool
    sessions_completed: int
    target_sessions: int
    remaining: int


# ============================================================================
# HORMONE-SUPPORTIVE FOOD MODELS
# ============================================================================

class HormoneSupportiveFood(BaseModel):
    """Hormone-supportive food definition."""
    id: str
    name: str
    category: str
    supports_testosterone: bool
    supports_estrogen_balance: bool
    supports_pcos: bool
    supports_menopause: bool
    supports_fertility: bool
    supports_thyroid: bool
    good_for_menstrual: bool
    good_for_follicular: bool
    good_for_ovulation: bool
    good_for_luteal: bool
    key_nutrients: List[str]
    description: Optional[str] = None
    serving_suggestion: Optional[str] = None

    class Config:
        from_attributes = True


class HormonalFoodRecommendation(BaseModel):
    """Personalized hormonal food recommendations."""
    user_id: str
    hormone_goals: List[HormoneGoal]
    current_cycle_phase: Optional[CyclePhase] = None
    recommended_foods: List[HormoneSupportiveFood]
    foods_to_limit: List[str]
    key_nutrients_to_focus: List[str]
    meal_timing_tips: List[str]


# ============================================================================
# HORMONAL RECOMMENDATION MODELS
# ============================================================================

class HormonalRecommendation(BaseModel):
    """AI-generated hormonal health recommendation."""
    user_id: str
    recommendation_type: str  # 'workout', 'nutrition', 'lifestyle', 'supplement'
    title: str
    description: str
    action_items: List[str]
    based_on: List[str]  # What data points this recommendation is based on
    priority: str  # 'high', 'medium', 'low'
    created_at: datetime


class HormonalInsights(BaseModel):
    """Comprehensive hormonal health insights."""
    user_id: str
    profile: Optional[HormonalProfile] = None
    current_cycle_phase: Optional[CyclePhaseInfo] = None
    recent_logs_summary: Optional[dict] = None
    recommendations: List[HormonalRecommendation] = Field(default_factory=list)
    food_recommendations: Optional[HormonalFoodRecommendation] = None
    kegel_stats: Optional[KegelStats] = None
