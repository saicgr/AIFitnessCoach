"""
Workout-related data models.
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class WorkoutExercise(BaseModel):
    """Single exercise in a workout."""
    exercise_id: str
    name: str
    sets: int = 3
    reps: int = 12
    rest_seconds: int = 60
    muscle_groups: List[str] = []
    equipment: Optional[str] = None
    gif_url: Optional[str] = None
    # Challenge exercise fields
    is_challenge: bool = False  # True if this is an optional challenge exercise
    progression_from: Optional[str] = None  # Name of the main exercise this progresses from
    difficulty: Optional[str] = None  # Exercise difficulty level
    difficulty_num: Optional[int] = None  # Numeric difficulty (1-10)


class Workout(BaseModel):
    """Workout model."""
    id: int
    name: str
    type: str
    difficulty: str
    scheduled_date: datetime
    is_completed: bool = False
    exercises: List[WorkoutExercise] = []
    challenge_exercise: Optional[WorkoutExercise] = None  # Optional challenge exercise for beginners
    metadata: Dict[str, Any] = {}


class WorkoutModification(BaseModel):
    """Modification made to a workout."""
    type: str  # added, removed, modified, swapped
    exercise_name: str
    previous_value: Optional[str] = None
    new_value: Optional[str] = None
    description: Optional[str] = None


class WorkoutModificationResult(BaseModel):
    """Result of workout modification."""
    workout_id: int
    workout_name: str
    changes: List[WorkoutModification] = []
