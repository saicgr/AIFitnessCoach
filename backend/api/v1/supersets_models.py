"""Pydantic models for supersets."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class SupersetPreferences(BaseModel):
    """User's superset preferences configuration."""
    enabled: bool = Field(default=True, description="Whether supersets are enabled")
    max_pairs_per_workout: int = Field(default=3, ge=1, le=6, description="Maximum superset pairs per workout")
    rest_between_supersets: int = Field(default=60, ge=30, le=180, description="Rest seconds between superset pairs")
    rest_within_superset: int = Field(default=10, ge=0, le=30, description="Rest seconds between exercises in a superset")
    prefer_antagonist: bool = Field(default=True, description="Prefer antagonist muscle pair supersets")
    allow_same_muscle: bool = Field(default=False, description="Allow same muscle group supersets (compound sets)")


class SupersetPreferencesUpdate(BaseModel):
    """Request to update superset preferences."""
    enabled: Optional[bool] = None
    max_pairs_per_workout: Optional[int] = Field(default=None, ge=1, le=6)
    rest_between_supersets: Optional[int] = Field(default=None, ge=30, le=180)
    rest_within_superset: Optional[int] = Field(default=None, ge=0, le=30)
    prefer_antagonist: Optional[bool] = None
    allow_same_muscle: Optional[bool] = None


class SupersetPreferencesResponse(BaseModel):
    """Response with current superset preferences."""
    user_id: str
    preferences: SupersetPreferences
    description: str
    updated_at: Optional[datetime] = None


class CreateSupersetPairRequest(BaseModel):
    """Request to create a manual superset pair in a workout."""
    workout_id: str = Field(..., description="The workout ID to modify")
    exercise_index_1: int = Field(..., ge=0, description="Index of first exercise in exercises_json")
    exercise_index_2: int = Field(..., ge=0, description="Index of second exercise in exercises_json")


class SupersetPairResponse(BaseModel):
    """Response for a superset pair operation."""
    workout_id: str
    superset_group: int
    exercise_1: Dict[str, Any]
    exercise_2: Dict[str, Any]
    message: str


class RemoveSupersetPairResponse(BaseModel):
    """Response for removing a superset pair."""
    workout_id: str
    superset_group: int
    exercises_updated: int
    message: str


class SupersetSuggestion(BaseModel):
    """A suggested superset pair."""
    exercise_1_name: str
    exercise_1_index: Optional[int] = None
    exercise_2_name: str
    exercise_2_index: Optional[int] = None
    muscle_1: str
    muscle_2: str
    category: str  # antagonist, compound_set, upper_lower
    reasoning: str
    confidence: float = Field(ge=0.0, le=1.0)


class SupersetSuggestionsResponse(BaseModel):
    """Response with AI-suggested superset pairs."""
    user_id: str
    workout_id: Optional[str]
    suggestions: List[SupersetSuggestion]
    classic_pairs: List[Dict[str, Any]]
    message: str


class FavoriteSupersetPair(BaseModel):
    """A user's favorite superset pair."""
    exercise_1_name: str = Field(..., min_length=1, max_length=200)
    exercise_2_name: str = Field(..., min_length=1, max_length=200)
    exercise_1_id: Optional[str] = None
    exercise_2_id: Optional[str] = None
    muscle_1: Optional[str] = None
    muscle_2: Optional[str] = None
    category: str = Field(default="antagonist", pattern="^(antagonist|compound_set|upper_lower|custom)$")
    notes: Optional[str] = Field(default=None, max_length=500)


class FavoriteSupersetPairResponse(BaseModel):
    """Response for a favorite superset pair."""
    id: str
    user_id: str
    exercise_1_name: str
    exercise_2_name: str
    exercise_1_id: Optional[str]
    exercise_2_id: Optional[str]
    muscle_1: Optional[str]
    muscle_2: Optional[str]
    category: str
    notes: Optional[str]
    times_used: int
    created_at: datetime


class SupersetHistoryEntry(BaseModel):
    """A superset usage history entry."""
    id: str
    workout_id: str
    workout_name: Optional[str]
    exercise_1_name: str
    exercise_2_name: str
    superset_group: int
    completed_at: datetime
    duration_seconds: Optional[int]
    sets_completed: Optional[int]


class SupersetHistoryResponse(BaseModel):
    """Response with superset usage history."""
    user_id: str
    history: List[SupersetHistoryEntry]
    total_supersets_completed: int
    favorite_pairs: List[Dict[str, Any]]
    stats: Dict[str, Any]


# =============================================================================
# Superset Preferences Endpoints
# =============================================================================

class SupersetLogRequest(BaseModel):
    """Request to log a user-created superset pair."""
    user_id: str = Field(..., description="User ID")
    workout_id: str = Field(..., description="Workout ID")
    exercise_1_name: str = Field(..., description="First exercise name")
    exercise_2_name: str = Field(..., description="Second exercise name")
    exercise_1_muscle: Optional[str] = Field(default=None, description="First exercise muscle group")
    exercise_2_muscle: Optional[str] = Field(default=None, description="Second exercise muscle group")
    superset_group: int = Field(..., ge=1, description="Superset group number")


