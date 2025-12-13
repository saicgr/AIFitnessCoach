"""User-related Pydantic models."""

from pydantic import BaseModel
from typing import Optional
from datetime import datetime


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
    date_of_birth: Optional[str] = None  # ISO date string: "1990-05-15"
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
    date_of_birth: Optional[str] = None  # ISO date string: "1990-05-15"
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    target_weight_kg: Optional[float] = None
    selected_days: Optional[str] = None  # JSON array of day indices
    workout_experience: Optional[str] = None  # JSON array
    workout_variety: Optional[str] = None
    health_conditions: Optional[str] = None  # JSON array
    activity_level: Optional[str] = None
    # Push notification token
    fcm_token: Optional[str] = None  # Firebase Cloud Messaging token


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
