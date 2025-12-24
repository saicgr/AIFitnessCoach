"""Exercise-related Pydantic models."""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ExerciseCreate(BaseModel):
    external_id: str = Field(..., max_length=100)
    name: str = Field(..., max_length=200)
    category: str = Field(default="strength", max_length=50)
    subcategory: str = Field(default="compound", max_length=50)
    difficulty_level: int = Field(default=1, ge=1, le=10)
    primary_muscle: str = Field(..., max_length=100)
    secondary_muscles: str = Field(default="[]", max_length=1000)
    equipment_required: str = Field(default="[]", max_length=1000)
    body_part: str = Field(..., max_length=100)
    equipment: str = Field(..., max_length=200)
    target: str = Field(..., max_length=100)
    default_sets: int = Field(default=3, ge=1, le=20)
    default_reps: Optional[int] = Field(default=None, ge=1, le=100)
    default_duration_seconds: Optional[int] = Field(default=None, ge=1, le=3600)
    default_rest_seconds: int = Field(default=60, ge=0, le=600)
    min_weight_kg: Optional[float] = Field(default=None, ge=0, le=500)
    calories_per_minute: float = Field(default=5.0, ge=0, le=100)
    instructions: str = Field(..., max_length=10000)
    tips: str = Field(default="[]", max_length=5000)
    contraindicated_injuries: str = Field(default="[]", max_length=2000)
    gif_url: Optional[str] = Field(default=None, max_length=500)
    video_url: Optional[str] = Field(default=None, max_length=500)
    is_compound: bool = True
    is_unilateral: bool = False
    tags: str = Field(default="[]", max_length=1000)
    is_custom: bool = False
    created_by_user_id: Optional[str] = Field(default=None, max_length=100)  # UUID string


class Exercise(ExerciseCreate):
    id: str = Field(..., max_length=100)  # UUID string from Supabase
    created_at: datetime
