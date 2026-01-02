"""Cardio Session Pydantic models.

This module defines models for cardio workout sessions, enabling users to:
- Log running, cycling, swimming, and other cardio activities
- Track distance, duration, pace, and heart rate
- View aggregate statistics and progress over time
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from enum import Enum


class CardioType(str, Enum):
    """Types of cardio activities."""
    RUNNING = "running"
    CYCLING = "cycling"
    SWIMMING = "swimming"
    ROWING = "rowing"
    ELLIPTICAL = "elliptical"
    WALKING = "walking"
    HIKING = "hiking"
    STAIR_CLIMBING = "stair_climbing"
    JUMP_ROPE = "jump_rope"
    OTHER = "other"


class CardioLocation(str, Enum):
    """Locations where cardio sessions take place."""
    INDOOR = "indoor"
    OUTDOOR = "outdoor"
    TREADMILL = "treadmill"
    TRACK = "track"
    TRAIL = "trail"
    POOL = "pool"
    GYM = "gym"


# =============================================================================
# Cardio Session Create/Update Models
# =============================================================================

class CardioSessionCreate(BaseModel):
    """Create a new cardio session."""
    user_id: str = Field(..., max_length=100)
    workout_id: Optional[str] = Field(default=None, max_length=100)

    # Session type and location
    cardio_type: CardioType
    location: CardioLocation

    # Distance and duration
    distance_km: Optional[float] = Field(default=None, ge=0, le=1000)
    duration_minutes: int = Field(..., ge=1, le=1440)  # Max 24 hours

    # Pace and speed
    avg_pace_per_km: Optional[str] = Field(default=None, max_length=10)  # Format: "MM:SS"
    avg_speed_kmh: Optional[float] = Field(default=None, ge=0, le=200)

    # Elevation
    elevation_gain_m: Optional[int] = Field(default=None, ge=0, le=20000)

    # Heart rate data
    avg_heart_rate: Optional[int] = Field(default=None, ge=40, le=250)
    max_heart_rate: Optional[int] = Field(default=None, ge=40, le=250)

    # Energy
    calories_burned: Optional[int] = Field(default=None, ge=0, le=10000)

    # Additional info
    notes: Optional[str] = Field(default=None, max_length=2000)
    weather_conditions: Optional[str] = Field(default=None, max_length=100)

    @field_validator('avg_pace_per_km')
    @classmethod
    def validate_pace_format(cls, v: Optional[str]) -> Optional[str]:
        """Validate pace format is MM:SS or M:SS."""
        if v is None:
            return v
        parts = v.split(':')
        if len(parts) != 2:
            raise ValueError('Pace must be in MM:SS format')
        try:
            minutes = int(parts[0])
            seconds = int(parts[1])
            if minutes < 0 or seconds < 0 or seconds >= 60:
                raise ValueError('Invalid pace values')
        except ValueError:
            raise ValueError('Pace must be in MM:SS format with valid numbers')
        return v


class CardioSessionUpdate(BaseModel):
    """Update an existing cardio session."""
    workout_id: Optional[str] = Field(default=None, max_length=100)
    cardio_type: Optional[CardioType] = None
    location: Optional[CardioLocation] = None
    distance_km: Optional[float] = Field(default=None, ge=0, le=1000)
    duration_minutes: Optional[int] = Field(default=None, ge=1, le=1440)
    avg_pace_per_km: Optional[str] = Field(default=None, max_length=10)
    avg_speed_kmh: Optional[float] = Field(default=None, ge=0, le=200)
    elevation_gain_m: Optional[int] = Field(default=None, ge=0, le=20000)
    avg_heart_rate: Optional[int] = Field(default=None, ge=40, le=250)
    max_heart_rate: Optional[int] = Field(default=None, ge=40, le=250)
    calories_burned: Optional[int] = Field(default=None, ge=0, le=10000)
    notes: Optional[str] = Field(default=None, max_length=2000)
    weather_conditions: Optional[str] = Field(default=None, max_length=100)

    @field_validator('avg_pace_per_km')
    @classmethod
    def validate_pace_format(cls, v: Optional[str]) -> Optional[str]:
        """Validate pace format is MM:SS or M:SS."""
        if v is None:
            return v
        parts = v.split(':')
        if len(parts) != 2:
            raise ValueError('Pace must be in MM:SS format')
        try:
            minutes = int(parts[0])
            seconds = int(parts[1])
            if minutes < 0 or seconds < 0 or seconds >= 60:
                raise ValueError('Invalid pace values')
        except ValueError:
            raise ValueError('Pace must be in MM:SS format with valid numbers')
        return v


# =============================================================================
# Cardio Session Response Models
# =============================================================================

class CardioSession(BaseModel):
    """A cardio session entry."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    workout_id: Optional[str] = Field(default=None, max_length=100)

    # Session type and location
    cardio_type: CardioType
    location: CardioLocation

    # Distance and duration
    distance_km: Optional[float] = Field(default=None)
    duration_minutes: int

    # Pace and speed
    avg_pace_per_km: Optional[str] = Field(default=None, max_length=10)
    avg_speed_kmh: Optional[float] = Field(default=None)

    # Elevation
    elevation_gain_m: Optional[int] = Field(default=None)

    # Heart rate data
    avg_heart_rate: Optional[int] = Field(default=None)
    max_heart_rate: Optional[int] = Field(default=None)

    # Energy
    calories_burned: Optional[int] = Field(default=None)

    # Additional info
    notes: Optional[str] = Field(default=None, max_length=2000)
    weather_conditions: Optional[str] = Field(default=None, max_length=100)

    # Timestamps
    created_at: datetime
    updated_at: datetime


class CardioSessionSummary(BaseModel):
    """Summary view of a cardio session for list views."""
    id: str = Field(..., max_length=100)
    cardio_type: CardioType
    location: CardioLocation
    distance_km: Optional[float] = Field(default=None)
    duration_minutes: int
    avg_pace_per_km: Optional[str] = Field(default=None, max_length=10)
    calories_burned: Optional[int] = Field(default=None)
    created_at: datetime


# =============================================================================
# Cardio Session List and Filter Models
# =============================================================================

class CardioSessionsListResponse(BaseModel):
    """Response containing a list of cardio sessions."""
    user_id: str = Field(..., max_length=100)
    sessions: List[CardioSession] = Field(default=[])
    total_count: int = Field(default=0, ge=0)
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)


# =============================================================================
# Cardio Session Statistics Models
# =============================================================================

class CardioTypeStats(BaseModel):
    """Statistics for a specific cardio type."""
    cardio_type: CardioType
    session_count: int = Field(default=0, ge=0)
    total_distance_km: float = Field(default=0, ge=0)
    total_duration_minutes: int = Field(default=0, ge=0)
    avg_distance_km: float = Field(default=0, ge=0)
    avg_duration_minutes: float = Field(default=0, ge=0)
    avg_pace_per_km: Optional[str] = Field(default=None, max_length=10)
    avg_speed_kmh: float = Field(default=0, ge=0)
    avg_heart_rate: Optional[float] = Field(default=None)
    total_calories_burned: int = Field(default=0, ge=0)
    total_elevation_gain_m: int = Field(default=0, ge=0)
    first_session: Optional[datetime] = None
    last_session: Optional[datetime] = None


class CardioSessionStatsResponse(BaseModel):
    """Aggregate statistics for a user's cardio sessions."""
    user_id: str = Field(..., max_length=100)
    period_days: int = Field(default=30, ge=1, le=365)

    # Overall stats
    total_sessions: int = Field(default=0, ge=0)
    total_distance_km: float = Field(default=0, ge=0)
    total_duration_minutes: int = Field(default=0, ge=0)
    total_calories_burned: int = Field(default=0, ge=0)
    total_elevation_gain_m: int = Field(default=0, ge=0)

    # Averages
    avg_sessions_per_week: float = Field(default=0, ge=0)
    avg_distance_per_session_km: float = Field(default=0, ge=0)
    avg_duration_per_session_minutes: float = Field(default=0, ge=0)
    avg_calories_per_session: float = Field(default=0, ge=0)
    avg_heart_rate: Optional[float] = Field(default=None)

    # Per-type breakdown
    stats_by_type: List[CardioTypeStats] = Field(default=[])

    # Trends (compared to previous period)
    distance_trend_percent: Optional[float] = Field(default=None)  # Positive = improvement
    duration_trend_percent: Optional[float] = Field(default=None)
    frequency_trend_percent: Optional[float] = Field(default=None)

    # Best performances
    longest_distance_session: Optional[CardioSessionSummary] = None
    longest_duration_session: Optional[CardioSessionSummary] = None
    fastest_pace_session: Optional[CardioSessionSummary] = None
    highest_calorie_session: Optional[CardioSessionSummary] = None
