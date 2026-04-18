"""Pydantic models for exercises."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class CustomExerciseCreate(BaseModel):
    """Simplified model for creating a custom exercise."""
    name: str = Field(..., min_length=1, max_length=200)
    primary_muscle: str = Field(..., max_length=100)  # e.g., "chest", "back", "legs"
    equipment: str = Field(default="bodyweight", max_length=200)  # e.g., "dumbbell", "barbell", "none"
    instructions: str = Field(default="", max_length=5000)  # Optional instructions
    default_sets: int = Field(default=3, ge=1, le=10)
    default_reps: Optional[int] = Field(default=10, ge=1, le=100)
    default_rest_seconds: Optional[int] = Field(default=None, ge=0, le=600)
    is_compound: bool = Field(default=False)  # Targets multiple muscle groups?

    # Advanced optional fields — persisted as a preamble in instructions so
    # the AI context reflects them during workout generation. Migrate to
    # dedicated columns on the exercises table later if needed.
    default_rpe: Optional[int] = Field(default=None, ge=1, le=10)
    default_tempo: Optional[str] = Field(default=None, max_length=50)
    default_band_color: Optional[str] = Field(default=None, max_length=30)
    default_notes: Optional[str] = Field(default=None, max_length=500)
    default_range_of_motion: Optional[str] = Field(default=None, max_length=100)
    default_incline_percent: Optional[float] = Field(default=None, ge=-10, le=30)
    default_duration_seconds: Optional[int] = Field(default=None, ge=1, le=7200)
    default_distance_miles: Optional[float] = Field(default=None, ge=0, le=100)


class CustomExerciseResponse(BaseModel):
    """Response model for custom exercises."""
    id: str
    name: str
    primary_muscle: str
    equipment: str
    instructions: str
    default_sets: int
    default_reps: Optional[int]
    is_compound: bool
    created_at: str


class ComponentExercise(BaseModel):
    """Model for a component of a composite exercise."""
    name: str = Field(..., min_length=1, max_length=200)
    order: int = Field(default=1, ge=1, le=10)
    reps: Optional[int] = Field(default=None, ge=1, le=100)
    duration_seconds: Optional[int] = Field(default=None, ge=1, le=600)
    transition_note: Optional[str] = Field(default=None, max_length=200)


class CompositeExerciseCreate(BaseModel):
    """Model for creating a composite/combo exercise."""
    name: str = Field(..., min_length=1, max_length=200, description="e.g., 'Dumbbell Bench Press & Chest Fly'")
    primary_muscle: str = Field(..., max_length=100)
    secondary_muscles: List[str] = Field(default=[], description="Additional muscles targeted")
    equipment: str = Field(default="dumbbell", max_length=200)
    combo_type: str = Field(
        default="superset",
        description="Type of combination: superset, compound_set, giant_set, complex, hybrid"
    )
    component_exercises: List[ComponentExercise] = Field(
        ..., min_length=2, max_length=5,
        description="The exercises that make up this combo (2-5 exercises)"
    )
    instructions: Optional[str] = Field(default=None, max_length=5000)
    custom_notes: Optional[str] = Field(default=None, max_length=2000)
    default_sets: int = Field(default=3, ge=1, le=10)
    default_rest_seconds: int = Field(default=60, ge=0, le=300)
    tags: List[str] = Field(default=[])


class CompositeExerciseResponse(BaseModel):
    """Response model for composite exercises."""
    id: str
    name: str
    primary_muscle: str
    secondary_muscles: List[str]
    equipment: str
    combo_type: str
    component_exercises: List[dict]
    instructions: Optional[str]
    custom_notes: Optional[str]
    default_sets: int
    default_rest_seconds: int
    tags: List[str]
    is_composite: bool
    usage_count: int
    created_at: str


class CustomExerciseFullResponse(BaseModel):
    """Full response model for custom exercises including composite."""
    id: str
    name: str
    primary_muscle: str
    secondary_muscles: Optional[List[str]] = None
    equipment: str
    instructions: Optional[str]
    default_sets: int
    default_reps: Optional[int]
    default_rest_seconds: Optional[int]
    is_compound: bool
    is_composite: bool
    combo_type: Optional[str] = None
    component_exercises: Optional[List[dict]] = None
    custom_notes: Optional[str] = None
    tags: List[str]
    usage_count: int
    last_used: Optional[str] = None
    created_at: str


