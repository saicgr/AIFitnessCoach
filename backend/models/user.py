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


class UserCreate(BaseModel):
    fitness_level: str = Field(..., max_length=50)
    goals: str = Field(..., max_length=2000)
    equipment: str = Field(..., max_length=2000)
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
    gender: Optional[str] = Field(default=None, max_length=20)
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
    preferences: Optional[str] = Field(default=None, max_length=10000)
    active_injuries: Optional[str] = Field(default=None, max_length=2000)
    onboarding_completed: Optional[bool] = None  # Set to True after onboarding
    # Extended onboarding fields
    days_per_week: Optional[int] = Field(default=None, ge=1, le=7)
    workout_duration: Optional[int] = Field(default=None, ge=1, le=480)
    training_split: Optional[str] = Field(default=None, max_length=50)
    intensity_preference: Optional[str] = Field(default=None, max_length=50)
    preferred_time: Optional[str] = Field(default=None, max_length=50)
    # New personal/health fields
    name: Optional[str] = Field(default=None, max_length=200)
    gender: Optional[str] = Field(default=None, max_length=20)
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
    accessibility_mode: Optional[str] = Field(default=None, max_length=20)  # 'normal', 'senior', 'kids'
    accessibility_settings: Optional[dict] = None  # Detailed settings (font_scale, etc.)


class User(BaseModel):
    id: str = Field(..., max_length=100)  # UUID from Supabase
    username: Optional[str] = Field(default=None, max_length=100)
    name: Optional[str] = Field(default=None, max_length=200)
    email: Optional[str] = Field(default=None, max_length=320)  # User's email address
    onboarding_completed: bool = False
    fitness_level: str = Field(..., max_length=50)
    goals: str = Field(..., max_length=2000)
    equipment: str = Field(..., max_length=2000)
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
    gender: Optional[str] = Field(default=None, max_length=20)
    activity_level: Optional[str] = Field(default=None, max_length=50)
    # Accessibility settings
    accessibility_mode: Optional[str] = Field(default="normal", max_length=20)  # 'normal', 'senior', 'kids'
    accessibility_settings: Optional[dict] = None  # Detailed settings
