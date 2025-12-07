"""Exercise-related Pydantic models."""

from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ExerciseCreate(BaseModel):
    external_id: str
    name: str
    category: str = "strength"
    subcategory: str = "compound"
    difficulty_level: int = 1
    primary_muscle: str
    secondary_muscles: str = "[]"
    equipment_required: str = "[]"
    body_part: str
    equipment: str
    target: str
    default_sets: int = 3
    default_reps: Optional[int] = None
    default_duration_seconds: Optional[int] = None
    default_rest_seconds: int = 60
    min_weight_kg: Optional[float] = None
    calories_per_minute: float = 5.0
    instructions: str
    tips: str = "[]"
    contraindicated_injuries: str = "[]"
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    is_compound: bool = True
    is_unilateral: bool = False
    tags: str = "[]"
    is_custom: bool = False
    created_by_user_id: Optional[str] = None  # UUID string from Supabase


class Exercise(ExerciseCreate):
    id: str  # UUID string from Supabase
    created_at: datetime
