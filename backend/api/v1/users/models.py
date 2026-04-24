"""
Pydantic models and helper functions for user endpoints.
"""
import json
import re
from typing import Optional, List
from pydantic import BaseModel, Field, EmailStr, field_validator


def get_default_equipment_for_environment(environment: str) -> list:
    """
    Returns default equipment for a workout environment.
    The RAG filter expands 'full_gym' and 'home_gym' to full equipment lists.
    """
    if environment == 'commercial_gym':
        return ['full_gym']
    elif environment == 'home_gym':
        return ['home_gym']
    else:
        return ['bodyweight']


class GoogleAuthRequest(BaseModel):
    """Request body for Google OAuth authentication."""
    access_token: str


def _validate_password_complexity(v: str) -> str:
    """Shared password complexity validator for all user-facing endpoints.

    SECURITY: Requires min 8 chars, at least 1 letter and 1 digit.
    This applies to regular users. Admin passwords have stricter rules in models/admin.py.
    """
    if not re.search(r'[a-zA-Z]', v):
        raise ValueError("Password must contain at least one letter")
    if not re.search(r'[0-9]', v):
        raise ValueError("Password must contain at least one number")
    return v


class EmailAuthRequest(BaseModel):
    """Request body for email/password authentication."""
    email: EmailStr  # SECURITY: Validate email format
    password: str


class EmailSignupRequest(BaseModel):
    """Request body for email/password signup."""
    email: EmailStr  # SECURITY: Validate email format
    password: str = Field(..., min_length=8, max_length=128)
    name: Optional[str] = Field(default=None, max_length=200)

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        return _validate_password_complexity(v)


class ForgotPasswordRequest(BaseModel):
    """Request body for forgot password."""
    email: EmailStr  # SECURITY: Validate email format


class ResetPasswordRequest(BaseModel):
    """Request body for password reset."""
    access_token: str
    new_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        """SECURITY: Enforce same password rules on reset path — prevents
        attacker with stolen reset token from setting a weak password."""
        return _validate_password_complexity(v)


class DestructiveActionRequest(BaseModel):
    """Request body for destructive actions that require re-authentication.

    SECURITY: Prevents someone with an unlocked phone from permanently
    deleting an account or wiping all data without knowing the password.
    For OAuth users (Google sign-in), password is not required since they
    don't have one — the JWT auth is sufficient.
    """
    password: Optional[str] = Field(None, min_length=1, description="Current password for re-authentication (required for email users, optional for OAuth users)")


class ChangePasswordRequest(BaseModel):
    """Request body for in-app password change."""
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        return _validate_password_complexity(v)


class ProgramPreferences(BaseModel):
    """User's current program preferences for customization."""
    difficulty: Optional[str] = None
    duration_minutes: Optional[int] = None
    workout_type: Optional[str] = None
    training_split: Optional[str] = None
    workout_days: List[str] = []
    equipment: List[str] = []
    focus_areas: List[str] = []
    injuries: List[str] = []
    last_updated: Optional[str] = None
    dumbbell_count: Optional[int] = None
    kettlebell_count: Optional[int] = None
    workout_environment: Optional[str] = None  # commercial_gym, home_gym, home, outdoors, hotel, etc.


class UserPreferencesRequest(BaseModel):
    """Request body for updating user preferences from pre-auth quiz."""
    # Goals & Fitness
    goals: Optional[List[str]] = None
    fitness_level: Optional[str] = None
    training_experience: Optional[str] = None
    activity_level: Optional[str] = None

    # Body Metrics
    age: Optional[int] = None
    gender: Optional[str] = None  # 'male' or 'female'
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    goal_weight_kg: Optional[float] = None
    weight_direction: Optional[str] = None  # lose, gain, maintain
    weight_change_amount: Optional[float] = None
    weight_change_rate: Optional[str] = None  # slow, moderate, fast, aggressive

    # Schedule
    days_per_week: Optional[int] = None
    selected_days: Optional[List[int]] = None  # List of day indices [0=Mon, 1=Tue, ..., 6=Sun]
    workout_duration: Optional[int] = None  # Duration in minutes (kept for backwards compatibility)
    workout_duration_min: Optional[int] = None  # Min duration in range (e.g., 45 for "45-60")
    workout_duration_max: Optional[int] = None  # Max duration in range (e.g., 60 for "45-60")

    # Equipment
    equipment: Optional[List[str]] = None
    custom_equipment: Optional[List[str]] = None

    # Training Preferences
    training_split: Optional[str] = None
    workout_type: Optional[str] = None
    progression_pace: Optional[str] = None
    workout_environment: Optional[str] = None  # commercial_gym, home_gym, home, outdoors
    workout_variety: Optional[str] = None  # 'consistent' or 'varied'

    # Coach
    coach_id: Optional[str] = None

    # Lifestyle
    sleep_quality: Optional[str] = None
    obstacles: Optional[List[str]] = None

    # Nutrition
    nutrition_goals: Optional[List[str]] = None
    dietary_restrictions: Optional[List[str]] = None
    meals_per_day: Optional[int] = None
    # Menu-analysis personalization (added 2026-04-23)
    allergens: Optional[List[str]] = None  # FDA Big 9 codes: milk, egg, fish, crustacean_shellfish, tree_nuts, wheat, peanuts, soybeans, sesame
    custom_allergens: Optional[List[str]] = None  # Free-text allergens outside Big 9
    disliked_foods: Optional[List[str]] = None  # Free-text "foods to avoid" tags
    inflammation_sensitivity: Optional[int] = None  # 1-5; 1 indifferent, 5 strict
    meal_budget_usd: Optional[float] = None  # Per-meal $ ceiling for menu filters
    daily_food_budget_usd: Optional[float] = None  # Per-day $ ceiling

    # Fasting
    interested_in_fasting: Optional[bool] = None
    fasting_protocol: Optional[str] = None

    # Sleep schedule for fasting optimization
    wake_time: Optional[str] = None  # HH:MM format, e.g., "07:00"
    sleep_time: Optional[str] = None  # HH:MM format, e.g., "23:00"

    # Motivations
    motivations: Optional[List[str]] = None

    # Focus areas (muscle groups / body parts to prioritize)
    focus_areas: Optional[List[str]] = None

    # Coach (duplicate removed in model, kept for compat)
    # coach_id already defined above


class FavoriteExerciseRequest(BaseModel):
    """Request body for adding a favorite exercise."""
    exercise_name: str
    exercise_id: Optional[str] = None


class FavoriteExercise(BaseModel):
    """Response model for a favorite exercise."""
    id: str
    user_id: str
    exercise_name: str
    exercise_id: Optional[str] = None
    added_at: str


class QueueExerciseRequest(BaseModel):
    """Request body for queuing an exercise."""
    exercise_name: str
    exercise_id: Optional[str] = None
    priority: Optional[int] = 0
    target_muscle_group: Optional[str] = None


class QueuedExercise(BaseModel):
    """Response model for a queued exercise."""
    id: str
    user_id: str
    exercise_name: str
    exercise_id: Optional[str] = None
    priority: int
    target_muscle_group: Optional[str] = None
    added_at: str
    expires_at: str
    used_at: Optional[str] = None


class QueueExerciseUpdateRequest(BaseModel):
    """Request body for updating a queued exercise."""
    priority: Optional[int] = None
    target_muscle_group: Optional[str] = None


class NutritionCalculationRequest(BaseModel):
    """Request body for calculating nutrition metrics."""
    weight_kg: float
    height_cm: float
    age: int
    gender: str  # 'male' or 'female'
    activity_level: Optional[str] = 'lightly_active'
    weight_direction: Optional[str] = 'maintain'
    weight_change_rate: Optional[str] = 'moderate'
    goal_weight_kg: Optional[float] = None
    nutrition_goals: Optional[List[str]] = None
    workout_days_per_week: Optional[int] = 3


class NutritionMetricsResponse(BaseModel):
    """Response model for calculated nutrition metrics."""
    calories: int
    protein: int
    carbs: int
    fat: int
    water_liters: float
    metabolic_age: int
    max_safe_deficit: int
    body_fat_percent: float
    lean_mass: float
    fat_mass: float
    protein_per_kg: float
    ideal_weight_min: float
    ideal_weight_max: float
    goal_date: Optional[str] = None
    weeks_to_goal: Optional[int] = None
    bmr: int
    tdee: int


class SyncFastingRequest(BaseModel):
    """Request to sync fasting preferences from onboarding."""
    interested_in_fasting: bool
    fasting_protocol: Optional[str] = None


class SyncFastingResponse(BaseModel):
    """Response from fasting sync."""
    success: bool
    message: str
    created: bool
    protocol: Optional[str] = None


class ProfilePhotoResponse(BaseModel):
    """Response for profile photo upload."""
    photo_url: str
    message: str


def row_to_user(row: dict, is_new_user: bool = False, support_friend_added: bool = False):
    """Convert a Supabase row dict to User model.

    Args:
        row: Database row as dict
        is_new_user: True if this is the user's first login (show welcome message)
        support_friend_added: True if FitWiz Support was auto-added as friend
    """
    from models.schemas import User
    # Deferred import: photo.py imports ProfilePhotoResponse from this module.
    from api.v1.users.photo import presign_profile_photo_url as _presigned_photo_url

    # Handle JSONB fields - they come as dicts/lists from Supabase
    goals = row.get("goals")
    if isinstance(goals, list):
        goals = json.dumps(goals)
    elif goals is None:
        goals = "[]"

    equipment = row.get("equipment")
    if isinstance(equipment, list):
        equipment = json.dumps(equipment)
    elif equipment is None:
        equipment = "[]"

    # Get preferences as dict for fallback lookups
    prefs_raw = row.get("preferences")
    prefs_dict = prefs_raw if isinstance(prefs_raw, dict) else {}

    preferences = prefs_raw
    if isinstance(preferences, dict):
        preferences = json.dumps(preferences)
    elif preferences is None:
        preferences = "{}"

    active_injuries = row.get("active_injuries")
    if isinstance(active_injuries, list):
        active_injuries = json.dumps(active_injuries)
    elif active_injuries is None:
        active_injuries = "[]"

    custom_equipment = row.get("custom_equipment")
    if isinstance(custom_equipment, list):
        custom_equipment = json.dumps(custom_equipment)
    elif custom_equipment is None:
        custom_equipment = "[]"

    # Helper to get value from column or fall back to preferences JSON
    def get_with_fallback(column_name: str, prefs_key: str = None):
        """Get value from dedicated column, or fall back to preferences JSON.

        Args:
            column_name: Name of the database column
            prefs_key: Key in preferences JSON (defaults to column_name)

        Note: Only falls back to preferences if column value is None.
        This ensures explicit user selections in columns are preserved.
        """
        value = row.get(column_name)
        # Only fall back to preferences if value is None (not set)
        # Don't treat default values as "not set" - user may have explicitly chosen them
        if value is None:
            pref_value = prefs_dict.get(prefs_key or column_name)
            if pref_value is not None:
                return pref_value
        return value

    return User(
        id=row.get("id"),
        username=row.get("username"),  # Use actual username field
        name=row.get("name") or prefs_dict.get("name"),
        email=row.get("email"),  # Include email in response
        role=row.get("role", "user"),  # Admin role support
        is_support_user=row.get("is_support_user", False),  # Support user flag
        is_new_user=is_new_user,  # True on first login
        support_friend_added=support_friend_added,  # True when support friend was added
        onboarding_completed=row.get("onboarding_completed", False),
        coach_selected=row.get("coach_selected", False),
        paywall_completed=row.get("paywall_completed", False),
        fitness_level=row.get("fitness_level", "beginner"),
        goals=goals,
        equipment=equipment,
        preferences=preferences,
        active_injuries=active_injuries,
        custom_equipment=custom_equipment,
        created_at=row.get("created_at"),
        # Personal info fields - fall back to preferences JSON if column is empty
        height_cm=get_with_fallback("height_cm"),
        weight_kg=get_with_fallback("weight_kg"),
        target_weight_kg=get_with_fallback("target_weight_kg"),
        age=get_with_fallback("age"),
        date_of_birth=str(get_with_fallback("date_of_birth")) if get_with_fallback("date_of_birth") else None,
        gender=get_with_fallback("gender"),
        activity_level=get_with_fallback("activity_level"),
        # Detailed equipment with quantities and weights
        equipment_details=row.get("equipment_details"),
        # Weight unit preference (kg or lbs)
        weight_unit=row.get("weight_unit") or "kg",
        # Body measurement unit preference (cm or in)
        measurement_unit=row.get("measurement_unit") or "cm",
        # Profile photo URL and bio. The bucket is private, so we presign the
        # stored S3 URL each time we serve the user (OAuth avatars pass through
        # unchanged).
        photo_url=_presigned_photo_url(row.get("photo_url")),
        bio=row.get("bio"),
        # Device info fields
        device_model=row.get("device_model"),
        device_platform=row.get("device_platform"),
        is_foldable=row.get("is_foldable", False),
        os_version=row.get("os_version"),
        screen_width=row.get("screen_width"),
        screen_height=row.get("screen_height"),
        last_device_update=row.get("last_device_update"),
    )


def merge_extended_fields_into_preferences(
    base_preferences: str,
    days_per_week: Optional[int],
    workout_duration: Optional[int],
    training_split: Optional[str],
    intensity_preference: Optional[str],
    preferred_time: Optional[str],
    progression_pace: Optional[str] = None,
    workout_type_preference: Optional[str] = None,
    workout_environment: Optional[str] = None,
    gym_name: Optional[str] = None,
    # Enhanced pre-auth quiz fields
    sleep_quality: Optional[str] = None,
    obstacles: Optional[List[str]] = None,
    dietary_restrictions: Optional[List[str]] = None,
    meals_per_day: Optional[int] = None,
    weight_direction: Optional[str] = None,
    weight_change_amount: Optional[float] = None,
    motivations: Optional[List[str]] = None,
    nutrition_goals: Optional[List[str]] = None,
    interested_in_fasting: Optional[bool] = None,
    fasting_protocol: Optional[str] = None,
    coach_id: Optional[str] = None,
    training_experience: Optional[str] = None,
    workout_days: Optional[List[int]] = None,  # List of day indices [0=Mon, 1=Tue, ..., 6=Sun]
    # Sleep schedule for fasting optimization
    wake_time: Optional[str] = None,
    sleep_time: Optional[str] = None,
    # Duration range for flexible workout generation
    workout_duration_min: Optional[int] = None,
    workout_duration_max: Optional[int] = None,
    # Exercise consistency preference
    workout_variety: Optional[str] = None,  # 'consistent' or 'varied'
    # Focus areas (muscle groups / body parts to prioritize)
    focus_areas: Optional[List[str]] = None,
    # Menu-analysis personalization
    allergens: Optional[List[str]] = None,
    custom_allergens: Optional[List[str]] = None,
    disliked_foods: Optional[List[str]] = None,
    inflammation_sensitivity: Optional[int] = None,
    meal_budget_usd: Optional[float] = None,
    daily_food_budget_usd: Optional[float] = None,
) -> dict:
    """Merge extended onboarding fields into preferences dict."""
    try:
        if isinstance(base_preferences, dict):
            prefs = base_preferences
        else:
            prefs = json.loads(base_preferences or "{}")
    except json.JSONDecodeError:
        prefs = {}

    if days_per_week is not None:
        prefs["days_per_week"] = days_per_week
    if workout_duration is not None:
        prefs["workout_duration"] = workout_duration
    # Duration range for flexible workout generation
    if workout_duration_min is not None:
        prefs["workout_duration_min"] = workout_duration_min
    if workout_duration_max is not None:
        prefs["workout_duration_max"] = workout_duration_max
    if training_split is not None:
        prefs["training_split"] = training_split
    if intensity_preference is not None:
        prefs["intensity_preference"] = intensity_preference
    if preferred_time is not None:
        prefs["preferred_time"] = preferred_time
    # New preferences for competitor feedback fixes
    if progression_pace is not None:
        prefs["progression_pace"] = progression_pace
    if workout_type_preference is not None:
        prefs["workout_type_preference"] = workout_type_preference
    if workout_environment is not None:
        prefs["workout_environment"] = workout_environment
    if gym_name is not None:
        prefs["gym_name"] = gym_name
    # Enhanced pre-auth quiz fields
    if sleep_quality is not None:
        prefs["sleep_quality"] = sleep_quality
    if obstacles is not None:
        prefs["obstacles"] = obstacles
    if dietary_restrictions is not None:
        prefs["dietary_restrictions"] = dietary_restrictions
    if meals_per_day is not None:
        prefs["meals_per_day"] = meals_per_day
    if weight_direction is not None:
        prefs["weight_direction"] = weight_direction
    if weight_change_amount is not None:
        prefs["weight_change_amount"] = weight_change_amount
    if motivations is not None:
        prefs["motivations"] = motivations
    if nutrition_goals is not None:
        prefs["nutrition_goals"] = nutrition_goals
    if interested_in_fasting is not None:
        prefs["interested_in_fasting"] = interested_in_fasting
    if fasting_protocol is not None:
        prefs["fasting_protocol"] = fasting_protocol
    if coach_id is not None:
        prefs["coach_id"] = coach_id
    if training_experience is not None:
        prefs["training_experience"] = training_experience
    if focus_areas is not None:
        prefs["focus_areas"] = focus_areas
    if workout_days is not None:
        prefs["workout_days"] = workout_days
    # Sleep schedule for fasting optimization
    if wake_time is not None:
        prefs["wake_time"] = wake_time
    if sleep_time is not None:
        prefs["sleep_time"] = sleep_time
    # Exercise consistency preference (workout_variety from frontend -> exercise_consistency in backend)
    if workout_variety is not None:
        prefs["exercise_consistency"] = workout_variety

    # Menu-analysis personalization (added 2026-04-23)
    if allergens is not None:
        prefs["allergens"] = allergens
    if custom_allergens is not None:
        prefs["custom_allergens"] = custom_allergens
    if disliked_foods is not None:
        prefs["disliked_foods"] = disliked_foods
    if inflammation_sensitivity is not None:
        prefs["inflammation_sensitivity"] = inflammation_sensitivity
    if meal_budget_usd is not None:
        prefs["meal_budget_usd"] = meal_budget_usd
    if daily_food_budget_usd is not None:
        prefs["daily_food_budget_usd"] = daily_food_budget_usd

    return prefs
