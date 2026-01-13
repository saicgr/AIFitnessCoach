"""User-related Pydantic models."""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class UserPreferences(BaseModel):
    """Extended user preferences for workout customization."""
    days_per_week: int = Field(default=4, ge=1, le=7)
    workout_duration: int = Field(default=45, ge=1, le=480)  # minutes
    training_split: str = Field(default="full_body", max_length=50)  # full_body, upper_lower, push_pull_legs, body_part
    intensity_preference: str = Field(default="moderate", max_length=50)  # light, moderate, intense
    preferred_time: str = Field(default="morning", max_length=50)  # morning, afternoon, evening
    # Progression pace control - addresses competitor feedback about too-fast weight increases
    progression_pace: str = Field(default="medium", max_length=20)  # slow, medium, fast
    # Workout type preference - addresses competitor feedback about no cardio selection
    workout_type_preference: str = Field(default="strength", max_length=20)  # strength, cardio, mixed
    # Warmup and stretch duration preferences (1-15 minutes each)
    warmup_duration_minutes: int = Field(default=5, ge=1, le=15)
    stretch_duration_minutes: int = Field(default=5, ge=1, le=15)
    # Weight unit preference - syncs across app
    weight_unit: str = Field(default="kg", max_length=5)  # 'kg' or 'lbs'


class UserCreate(BaseModel):
    fitness_level: str = Field(..., max_length=50)
    goals: str = Field(..., max_length=2000)
    equipment: str = Field(..., max_length=2000)
    custom_equipment: str = Field(default="[]", max_length=2000)  # User-added equipment not in predefined list
    preferences: str = Field(default="{}", max_length=10000)
    active_injuries: str = Field(default="[]", max_length=2000)
    # Extended onboarding fields - merged into preferences on save
    days_per_week: Optional[int] = Field(default=None, ge=1, le=7)
    workout_duration: Optional[int] = Field(default=None, ge=1, le=480)
    training_split: Optional[str] = Field(default=None, max_length=50)
    intensity_preference: Optional[str] = Field(default=None, max_length=50)
    preferred_time: Optional[str] = Field(default=None, max_length=50)
    # New personal/health fields
    name: Optional[str] = Field(default=None, max_length=200)
    gender: Optional[str] = Field(default=None, max_length=20)  # 'male', 'female', or 'other'
    age: Optional[int] = Field(default=None, ge=1, le=150)
    date_of_birth: Optional[str] = Field(default=None, max_length=20)  # ISO date string: "1990-05-15"
    height_cm: Optional[float] = Field(default=None, ge=50, le=300)
    weight_kg: Optional[float] = Field(default=None, ge=20, le=500)
    target_weight_kg: Optional[float] = Field(default=None, ge=20, le=500)
    selected_days: Optional[str] = Field(default=None, max_length=100)  # JSON array of day indices [0,1,3,4]
    workout_experience: Optional[str] = Field(default=None, max_length=1000)  # JSON array
    workout_variety: Optional[str] = Field(default=None, max_length=100)
    health_conditions: Optional[str] = Field(default=None, max_length=2000)  # JSON array
    activity_level: Optional[str] = Field(default=None, max_length=50)
    # Timezone field for per-user time consistency
    timezone: Optional[str] = Field(default="UTC", max_length=50)  # IANA timezone identifier
    # Progression and workout type preferences
    progression_pace: Optional[str] = Field(default=None, max_length=20)  # slow, medium, fast
    workout_type_preference: Optional[str] = Field(default=None, max_length=20)  # strength, cardio, mixed
    # Weight unit preference - 'kg' or 'lbs'
    weight_unit: Optional[str] = Field(default="kg", max_length=5)


class NotificationPreferences(BaseModel):
    """User's notification preferences and schedule times."""
    # Toggle settings
    workout_reminders: bool = True
    nutrition_reminders: bool = True
    hydration_reminders: bool = True
    ai_coach_messages: bool = True
    streak_alerts: bool = True
    weekly_summary: bool = True
    quiet_hours_start: str = Field(default="22:00", max_length=10)
    quiet_hours_end: str = Field(default="08:00", max_length=10)
    # Time preferences for scheduled notifications
    workout_reminder_time: str = Field(default="08:00", max_length=10)
    nutrition_breakfast_time: str = Field(default="08:00", max_length=10)
    nutrition_lunch_time: str = Field(default="12:00", max_length=10)
    nutrition_dinner_time: str = Field(default="18:00", max_length=10)
    hydration_start_time: str = Field(default="08:00", max_length=10)
    hydration_end_time: str = Field(default="20:00", max_length=10)
    hydration_interval_minutes: int = Field(default=120, ge=15, le=480)
    streak_alert_time: str = Field(default="18:00", max_length=10)
    weekly_summary_day: int = Field(default=0, ge=0, le=6)  # 0=Sunday, 6=Saturday
    weekly_summary_time: str = Field(default="09:00", max_length=10)


class UserUpdate(BaseModel):
    fitness_level: Optional[str] = Field(default=None, max_length=50)
    goals: Optional[str] = Field(default=None, max_length=2000)
    equipment: Optional[str] = Field(default=None, max_length=2000)
    custom_equipment: Optional[str] = Field(default=None, max_length=2000)  # User-added equipment
    preferences: Optional[str] = Field(default=None, max_length=10000)
    active_injuries: Optional[str] = Field(default=None, max_length=2000)
    onboarding_completed: Optional[bool] = None  # Set to True after onboarding
    coach_selected: Optional[bool] = None  # Set to True after coach selection
    paywall_completed: Optional[bool] = None  # Set to True after paywall flow
    # Extended onboarding fields
    days_per_week: Optional[int] = Field(default=None, ge=1, le=7)
    workout_duration: Optional[int] = Field(default=None, ge=1, le=480)
    training_split: Optional[str] = Field(default=None, max_length=50)
    intensity_preference: Optional[str] = Field(default=None, max_length=50)
    preferred_time: Optional[str] = Field(default=None, max_length=50)
    # New personal/health fields
    name: Optional[str] = Field(default=None, max_length=200)
    gender: Optional[str] = Field(default=None, max_length=20)  # 'male', 'female', or 'other'
    age: Optional[int] = Field(default=None, ge=1, le=150)
    date_of_birth: Optional[str] = Field(default=None, max_length=20)  # ISO date string: "1990-05-15"
    height_cm: Optional[float] = Field(default=None, ge=50, le=300)
    weight_kg: Optional[float] = Field(default=None, ge=20, le=500)
    target_weight_kg: Optional[float] = Field(default=None, ge=20, le=500)
    selected_days: Optional[str] = Field(default=None, max_length=100)  # JSON array of day indices
    workout_experience: Optional[str] = Field(default=None, max_length=1000)  # JSON array
    workout_variety: Optional[str] = Field(default=None, max_length=100)
    health_conditions: Optional[str] = Field(default=None, max_length=2000)  # JSON array
    activity_level: Optional[str] = Field(default=None, max_length=50)
    # Timezone field for per-user time consistency
    timezone: Optional[str] = Field(default=None, max_length=50)  # IANA timezone identifier
    # Push notification fields
    fcm_token: Optional[str] = Field(default=None, max_length=500)  # Firebase Cloud Messaging token
    device_platform: Optional[str] = Field(default=None, max_length=20)  # 'android' or 'ios'
    notification_preferences: Optional[dict] = None  # NotificationPreferences as dict
    # Accessibility settings
    accessibility_mode: Optional[str] = Field(default=None, max_length=20)  # 'standard', 'senior', 'kids'
    accessibility_settings: Optional[dict] = None  # Detailed settings (font_scale, etc.)
    # Progression and workout type preferences
    progression_pace: Optional[str] = Field(default=None, max_length=20)  # slow, medium, fast
    workout_type_preference: Optional[str] = Field(default=None, max_length=20)  # strength, cardio, mixed
    # Workout environment - stored in preferences
    workout_environment: Optional[str] = Field(default=None, max_length=50)  # commercial_gym, home_gym, home, etc.
    # Detailed equipment with quantities and weights
    # Array of objects: [{"name": "dumbbells", "quantity": 2, "weights": [15, 25], "weight_unit": "lbs", "notes": ""}]
    equipment_details: Optional[list] = None
    # Enhanced pre-auth quiz fields (stored in preferences JSON)
    sleep_quality: Optional[str] = Field(default=None, max_length=20)  # poor, fair, good, excellent
    obstacles: Optional[list] = None  # ["time", "energy", "motivation", "knowledge", "diet", "access"]
    dietary_restrictions: Optional[list] = None  # ["vegetarian", "vegan", "gluten_free", etc.]
    weight_direction: Optional[str] = Field(default=None, max_length=20)  # lose, gain, maintain
    weight_change_amount: Optional[float] = Field(default=None, ge=0, le=200)  # kg amount
    motivations: Optional[list] = None  # List of motivation tags
    nutrition_goals: Optional[list] = None  # Nutrition goal tags
    interested_in_fasting: Optional[bool] = None
    fasting_protocol: Optional[str] = Field(default=None, max_length=50)
    # Sleep schedule for fasting window optimization
    wake_time: Optional[str] = Field(default=None, max_length=10)  # HH:MM format, e.g., "07:00"
    sleep_time: Optional[str] = Field(default=None, max_length=10)  # HH:MM format, e.g., "23:00"
    coach_id: Optional[str] = Field(default=None, max_length=50)  # Selected coach ID
    # Weight unit preference - 'kg' or 'lbs'
    weight_unit: Optional[str] = Field(default=None, max_length=5)


class User(BaseModel):
    id: str = Field(..., max_length=100)  # UUID from Supabase
    username: Optional[str] = Field(default=None, max_length=100)
    name: Optional[str] = Field(default=None, max_length=200)
    email: Optional[str] = Field(default=None, max_length=320)  # User's email address
    role: str = Field(default="user", max_length=20)  # 'user' or 'admin'
    is_support_user: bool = False  # True only for support@fitwiz.us (cannot be unfriended)
    is_new_user: bool = False  # True on first login - signals to app to show welcome message
    support_friend_added: bool = False  # True when FitWiz Support was auto-added as friend
    onboarding_completed: bool = False
    coach_selected: bool = False  # Whether user has selected their AI coach
    paywall_completed: bool = False  # Whether user has completed paywall flow
    fitness_level: str = Field(..., max_length=50)
    goals: str = Field(..., max_length=2000)
    equipment: str = Field(..., max_length=2000)
    custom_equipment: str = Field(default="[]", max_length=2000)  # User-added equipment
    preferences: str = Field(..., max_length=10000)
    active_injuries: str = Field(..., max_length=2000)
    created_at: datetime
    # Timezone field for per-user time consistency
    timezone: Optional[str] = Field(default="UTC", max_length=50)  # IANA timezone identifier
    # Personal info fields
    height_cm: Optional[float] = Field(default=None, ge=50, le=300)
    weight_kg: Optional[float] = Field(default=None, ge=20, le=500)
    target_weight_kg: Optional[float] = Field(default=None, ge=20, le=500)
    age: Optional[int] = Field(default=None, ge=1, le=150)
    date_of_birth: Optional[str] = Field(default=None, max_length=20)
    gender: Optional[str] = Field(default=None, max_length=20)  # 'male', 'female', or 'other'
    activity_level: Optional[str] = Field(default=None, max_length=50)
    # Weight unit preference - syncs across app
    weight_unit: str = Field(default="kg", max_length=5)  # 'kg' or 'lbs'
    # Accessibility settings
    accessibility_mode: Optional[str] = Field(default="standard", max_length=20)  # 'standard', 'senior', 'kids'
    accessibility_settings: Optional[dict] = None  # Detailed settings
    # Detailed equipment with quantities and weights
    # Array of objects: [{"name": "dumbbells", "quantity": 2, "weights": [15, 25], "weight_unit": "lbs", "notes": ""}]
    equipment_details: Optional[list] = None
