"""Gym Profile Pydantic models for multi-gym profile system."""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class GymProfileBase(BaseModel):
    """Base fields for gym profile."""
    name: str = Field(..., min_length=1, max_length=100, description="Profile name (e.g., 'Home Gym', '24 Hour Fitness')")
    icon: str = Field(default="fitness_center", max_length=50, description="Material icon name or emoji")
    color: str = Field(default="#00BCD4", max_length=7, description="Hex color for profile accent")

    # Equipment configuration
    equipment: List[str] = Field(default=[], description="List of equipment IDs (e.g., ['dumbbells', 'barbell'])")
    equipment_details: List[dict] = Field(default=[], description="Detailed equipment with quantities and weights")
    workout_environment: str = Field(default="commercial_gym", max_length=50, description="Environment type: commercial_gym, home_gym, home, hotel, outdoors")

    # Workout preferences
    training_split: Optional[str] = Field(default=None, max_length=50, description="Training split: full_body, upper_lower, push_pull_legs, body_part, pplul, phul, arnold_split, ai_adaptive")
    workout_days: List[int] = Field(default=[], description="Workout days as indices (0=Mon, 6=Sun)")
    duration_minutes: int = Field(default=45, ge=10, le=180, description="Default workout duration")
    duration_minutes_min: Optional[int] = Field(default=None, ge=10, le=180, description="Minimum duration for range")
    duration_minutes_max: Optional[int] = Field(default=None, ge=10, le=180, description="Maximum duration for range")
    goals: List[str] = Field(default=[], description="Profile-specific goals (overrides user goals if set)")
    focus_areas: List[str] = Field(default=[], description="Focus muscle areas")


class GymProfileCreate(GymProfileBase):
    """Request model for creating a gym profile."""
    pass


class GymProfileUpdate(BaseModel):
    """Request model for updating a gym profile. All fields optional."""
    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    icon: Optional[str] = Field(default=None, max_length=50)
    color: Optional[str] = Field(default=None, max_length=7)

    # Equipment configuration
    equipment: Optional[List[str]] = None
    equipment_details: Optional[List[dict]] = None
    workout_environment: Optional[str] = Field(default=None, max_length=50)

    # Workout preferences
    training_split: Optional[str] = Field(default=None, max_length=50)
    workout_days: Optional[List[int]] = None
    duration_minutes: Optional[int] = Field(default=None, ge=10, le=180)
    duration_minutes_min: Optional[int] = Field(default=None, ge=10, le=180)
    duration_minutes_max: Optional[int] = Field(default=None, ge=10, le=180)
    goals: Optional[List[str]] = None
    focus_areas: Optional[List[str]] = None

    # Program tracking
    current_program_id: Optional[str] = None
    program_custom_name: Optional[str] = Field(default=None, max_length=200)


class GymProfile(GymProfileBase):
    """Response model for gym profile."""
    id: str
    user_id: str

    # Program tracking
    current_program_id: Optional[str] = None
    program_custom_name: Optional[str] = None

    # Ordering and state
    display_order: int = 0
    is_active: bool = False

    # Timestamps
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class GymProfileWithStats(GymProfile):
    """Gym profile with additional statistics."""
    workout_count: int = 0
    last_workout_date: Optional[datetime] = None


class ReorderProfilesRequest(BaseModel):
    """Request model for reordering gym profiles."""
    profile_ids: List[str] = Field(..., min_length=1, description="Ordered list of profile IDs")


class ActivateProfileResponse(BaseModel):
    """Response for profile activation."""
    success: bool
    active_profile: GymProfile
    message: str = "Profile activated successfully"


class GymProfileListResponse(BaseModel):
    """Response for listing gym profiles."""
    profiles: List[GymProfile]
    active_profile_id: Optional[str] = None
    count: int
