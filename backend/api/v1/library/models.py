"""
Library data models.

This module contains Pydantic models for the library API.
"""
from typing import List, Optional
from pydantic import BaseModel


class LibraryExercise(BaseModel):
    """Exercise from the library."""
    id: str  # UUID in database
    name: str  # Cleaned name (Title Case, no gender suffix)
    original_name: str  # Original name (for video lookup)
    body_part: str
    equipment: Optional[str] = None  # Can be null in database
    target_muscle: Optional[str] = None
    secondary_muscles: Optional[List[str]] = None  # JSONB array in database
    instructions: Optional[str] = None
    difficulty_level: Optional[str] = None  # Can be string like 'Beginner' or int
    category: Optional[str] = None
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    image_url: Optional[str] = None  # Thumbnail image URL
    goals: Optional[List[str]] = None  # Derived fitness goals
    suitable_for: Optional[List[str]] = None  # Suitability categories
    avoid_if: Optional[List[str]] = None  # Injury considerations
    # Exercise metadata (from migration 235)
    movement_pattern: Optional[str] = None
    mechanic_type: Optional[str] = None
    force_type: Optional[str] = None
    plane_of_motion: Optional[str] = None
    energy_system: Optional[str] = None
    default_duration_seconds: Optional[int] = None
    default_rep_range_min: Optional[int] = None
    default_rep_range_max: Optional[int] = None
    default_rest_seconds: Optional[int] = None
    default_tempo: Optional[str] = None
    default_incline_percent: Optional[float] = None
    default_speed_mph: Optional[float] = None
    default_resistance_level: Optional[int] = None
    default_rpm: Optional[int] = None
    stroke_rate_spm: Optional[int] = None
    contraindicated_conditions: Optional[List[str]] = None
    impact_level: Optional[str] = None
    form_complexity: Optional[int] = None
    stability_requirement: Optional[str] = None
    is_dynamic_stretch: Optional[bool] = None
    hold_seconds_min: Optional[int] = None
    hold_seconds_max: Optional[int] = None
    # Equipment flags
    single_dumbbell_friendly: Optional[bool] = None
    single_kettlebell_friendly: Optional[bool] = None


class LibraryProgram(BaseModel):
    """Program from the library."""
    id: str  # UUID in database
    name: str
    category: str
    subcategory: Optional[str] = None
    difficulty_level: Optional[str] = None
    duration_weeks: Optional[int] = None
    sessions_per_week: Optional[int] = None
    session_duration_minutes: Optional[int] = None
    tags: Optional[List[str]] = None
    goals: Optional[List[str]] = None
    description: Optional[str] = None
    short_description: Optional[str] = None
    celebrity_name: Optional[str] = None


class ExercisesByBodyPart(BaseModel):
    """Exercises grouped by body part."""
    body_part: str
    count: int
    exercises: List[LibraryExercise]


class ProgramsByCategory(BaseModel):
    """Programs grouped by category."""
    category: str
    count: int
    programs: List[LibraryProgram]
