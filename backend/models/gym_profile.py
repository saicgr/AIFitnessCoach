"""Gym Profile Pydantic models for multi-gym profile system."""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Union, Any
from datetime import datetime


def _normalize_equipment(value: Any) -> Any:
    """Accept either a list of equipment names (strings) or a list of detail
    dicts (`{"name": "...", "display_name": ..., "weights": [...], ...}`) and
    return a flat list of canonical name strings. Older mobile clients send
    detail dicts in the `equipment` field; the rich form belongs in
    `equipment_details`. Normalizing here keeps PUT /gym-profiles/{id} from
    422'ing while clients update."""
    # A client that omits the field entirely sends null, not []. Coerce to an
    # empty list rather than passing None through to a non-Optional List field,
    # which 422s the whole request (2026-07-22: POST /gym-profiles/ failed with
    # `equipment_details: Input should be a valid list` for every profile save).
    if value is None:
        return []
    if not isinstance(value, list):
        return value
    out: List[str] = []
    for item in value:
        if isinstance(item, str):
            out.append(item)
        elif isinstance(item, dict):
            name = item.get("name") or item.get("display_name")
            if isinstance(name, str) and name:
                out.append(name)
    return out


class GymProfileBase(BaseModel):
    """Base fields for gym profile."""
    name: str = Field(..., min_length=1, max_length=100, description="Profile name (e.g., 'Home Gym', '24 Hour Fitness')")
    icon: str = Field(default="fitness_center", max_length=50, description="Material icon name or emoji")
    color: str = Field(default="#00BCD4", max_length=7, description="Hex color for profile accent")

    # Equipment configuration
    equipment: List[str] = Field(default=[], description="List of equipment IDs (e.g., ['dumbbells', 'barbell']). May include custom equipment slugs (e.g. 'grip_trainer', or a user-named item like 'my_grip_ring').")
    equipment_details: List[dict] = Field(
        default=[],
        description=(
            "Detailed equipment with quantities and weights. Each item: "
            "{name, display_name?, quantity?, weights?: [kg/lb], weight_inventory?: {weight: qty}, "
            "weight_unit?: 'lbs'|'kg', notes?, is_custom?: bool, "
            "weight_min?, weight_max?, weight_increment?}. Custom / adjustable "
            "equipment (grip trainer 10-160 lb, adjustable dumbbells, banded "
            "ranges) is stored here with an explicit weight list / range so "
            "progression snaps to real available weights (Gravl B2)."
        ),
    )

    @field_validator("equipment", mode="before")
    @classmethod
    def _coerce_equipment(cls, v):
        return _normalize_equipment(v)

    @field_validator("equipment_details", mode="before")
    @classmethod
    def _coerce_equipment_details(cls, v):
        """Null-tolerant: a client with no detail rows sends null, and this
        non-Optional List field would otherwise 422 the entire profile save.
        GymProfileUpdate already types this Optional — this keeps create and
        update from disagreeing about whether null is acceptable."""
        return [] if v is None else v

    workout_environment: str = Field(default="commercial_gym", max_length=50, description="Environment type: commercial_gym, home_gym, home, hotel, outdoors")

    # Location fields for geofencing/auto-switch
    address: Optional[str] = Field(default=None, max_length=255, description="Full address of the gym location")
    city: Optional[str] = Field(default=None, max_length=100, description="City name for display")
    latitude: Optional[float] = Field(default=None, ge=-90, le=90, description="GPS latitude coordinate")
    longitude: Optional[float] = Field(default=None, ge=-180, le=180, description="GPS longitude coordinate")
    place_id: Optional[str] = Field(default=None, max_length=255, description="Google Places ID")
    location_radius_meters: int = Field(default=100, ge=50, le=500, description="Geofence radius in meters")
    auto_switch_enabled: bool = Field(default=True, description="Auto-switch to this profile when arriving at location")

    # Time-based auto-switch fields
    preferred_time_slot: Optional[str] = Field(default=None, pattern="^(early_morning|morning|afternoon|evening|night)$", description="Preferred workout time: early_morning (5-7 AM), morning (7-11 AM), afternoon (11 AM-4 PM), evening (4-8 PM), night (8 PM-12 AM)")
    time_auto_switch_enabled: bool = Field(default=True, description="Auto-switch to this profile during preferred time slot")

    # Workout preferences
    training_split: Optional[str] = Field(default=None, max_length=50, description="Training split: full_body, upper_lower, push_pull_legs, body_part, pplul, phul, arnold_split, ai_adaptive")
    workout_days: List[int] = Field(default=[], description="Workout days as indices (0=Mon, 6=Sun)")
    duration_minutes: int = Field(default=45, ge=10, le=180, description="Default workout duration")
    duration_minutes_min: Optional[int] = Field(default=None, ge=10, le=180, description="Minimum duration for range")
    duration_minutes_max: Optional[int] = Field(default=None, ge=10, le=180, description="Maximum duration for range")
    goals: List[str] = Field(default=[], description="Profile-specific goals (overrides user goals if set)")
    focus_areas: List[str] = Field(default=[], description="Focus muscle areas")

    # Travel Mode (Feature 3B). Defaults False; only the travel-mode endpoint
    # sets it. Additive — ordinary create/edit flows never touch it.
    is_travel_managed: bool = Field(default=False, description="True for the one-tap bodyweight Travel/Hotel profile (at most one per user)")


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

    @field_validator("equipment", mode="before")
    @classmethod
    def _coerce_equipment(cls, v):
        return _normalize_equipment(v)

    # Location fields for geofencing/auto-switch
    address: Optional[str] = Field(default=None, max_length=255)
    city: Optional[str] = Field(default=None, max_length=100)
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    place_id: Optional[str] = Field(default=None, max_length=255)
    location_radius_meters: Optional[int] = Field(default=None, ge=50, le=500)
    auto_switch_enabled: Optional[bool] = None

    # Time-based auto-switch fields
    preferred_time_slot: Optional[str] = Field(default=None, pattern="^(early_morning|morning|afternoon|evening|night)$")
    time_auto_switch_enabled: Optional[bool] = None

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

    # Travel Mode (Feature 3B): TRUE for the single per-user bodyweight
    # Travel/Hotel profile activated via POST /gym-profiles/travel-mode/activate.
    # At most one per user (partial unique index, migration 2243).
    is_travel_managed: bool = False

    # Soft-delete (Gravl B-series): non-null = archived. Archived gyms are
    # hidden from pickers/generation but keep their history attributed and
    # filterable for per-gym progress.
    archived_at: Optional[datetime] = None

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


class DuplicateProfileRequest(BaseModel):
    """Request model for duplicating a gym profile with optional custom name."""
    name: Optional[str] = Field(None, min_length=1, max_length=50, description="Custom name for the duplicated profile")


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
