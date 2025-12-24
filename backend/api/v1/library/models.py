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
    secondary_muscles: Optional[str] = None
    instructions: Optional[str] = None
    difficulty_level: Optional[int] = None
    category: Optional[str] = None
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    image_url: Optional[str] = None  # Thumbnail image URL
    goals: Optional[List[str]] = None  # Derived fitness goals
    suitable_for: Optional[List[str]] = None  # Suitability categories
    avoid_if: Optional[List[str]] = None  # Injury considerations


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
