"""Pydantic models for demo."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class PreviewPlanRequest(BaseModel):
    """Request for generating a preview workout plan."""
    goals: List[str]
    fitness_level: str  # beginner, intermediate, advanced
    equipment: List[str]
    days_per_week: int
    training_split: Optional[str] = "push_pull_legs"
    session_id: Optional[str] = None


class DemoInteraction(BaseModel):
    """Log a demo user interaction."""
    session_id: str
    action_type: str  # screen_view, exercise_view, workout_start, feature_tap
    screen: Optional[str] = None
    feature: Optional[str] = None
    duration_seconds: Optional[int] = None
    metadata: Optional[Dict[str, Any]] = None


class DemoSession(BaseModel):
    """Start or update a demo session."""
    session_id: Optional[str] = None
    quiz_data: Optional[Dict[str, Any]] = None
    device_info: Optional[Dict[str, Any]] = None


class SessionConvertRequest(BaseModel):
    """Request to mark a demo session as converted."""
    session_id: str
    user_id: str
    trigger: str


class PersonalizedSampleWorkoutRequest(BaseModel):
    """Request for generating a personalized sample workout with real exercises."""
    goals: List[str]
    fitness_level: str  # beginner, intermediate, advanced
    equipment: List[str]
    workout_type_preference: Optional[str] = "strength"  # strength, cardio, mixed
    session_id: Optional[str] = None


class TourStartRequest(BaseModel):
    """Request to start an app tour session."""
    user_id: Optional[str] = None
    device_id: Optional[str] = None
    source: str = "new_user"  # new_user, settings, deep_link
    device_info: Optional[Dict[str, Any]] = None
    app_version: Optional[str] = None
    platform: Optional[str] = None


class TourStepCompletedRequest(BaseModel):
    """Request when a tour step is completed."""
    session_id: str
    step_id: str
    duration_seconds: Optional[int] = None
    action_taken: Optional[str] = None  # skip, next, deep_link
    deep_link_target: Optional[str] = None


class TourCompletedRequest(BaseModel):
    """Request when tour is completed or skipped."""
    session_id: str
    status: str  # completed, skipped
    skip_step: Optional[str] = None
    demo_workout_started: bool = False
    demo_workout_completed: bool = False
    plan_preview_viewed: bool = False
    deep_links_clicked: List[str] = []
    total_duration_seconds: Optional[int] = None


# ============================================================================
# CURATED EXERCISE DATA (for unauthenticated demo/guest experience)
# These are real exercises with real sets/reps, used to showcase the app's
# capabilities before signup. They are NOT personalized user data.
# ============================================================================

CURATED_EXERCISES = {
    "chest": [
        {"name": "Push-ups", "sets": 3, "reps": "10-15", "muscle_group": "Chest"},
        {"name": "Dumbbell Bench Press", "sets": 3, "reps": "8-12", "muscle_group": "Chest"},
        {"name": "Incline Dumbbell Press", "sets": 3, "reps": "8-12", "muscle_group": "Chest"},
        {"name": "Cable Flyes", "sets": 3, "reps": "12-15", "muscle_group": "Chest"},
    ],
    "shoulders": [
        {"name": "Overhead Press", "sets": 3, "reps": "8-10", "muscle_group": "Shoulders"},
        {"name": "Lateral Raises", "sets": 3, "reps": "12-15", "muscle_group": "Shoulders"},
        {"name": "Front Raises", "sets": 3, "reps": "10-12", "muscle_group": "Shoulders"},
    ],
    "triceps": [
        {"name": "Tricep Pushdowns", "sets": 3, "reps": "12-15", "muscle_group": "Triceps"},
        {"name": "Overhead Tricep Extension", "sets": 3, "reps": "10-12", "muscle_group": "Triceps"},
    ],
    "back": [
        {"name": "Lat Pulldowns", "sets": 3, "reps": "10-12", "muscle_group": "Back"},
        {"name": "Seated Cable Rows", "sets": 3, "reps": "10-12", "muscle_group": "Back"},
        {"name": "Dumbbell Rows", "sets": 3, "reps": "8-10", "muscle_group": "Back"},
        {"name": "Face Pulls", "sets": 3, "reps": "15-20", "muscle_group": "Back"},
    ],
    "biceps": [
        {"name": "Barbell Curls", "sets": 3, "reps": "10-12", "muscle_group": "Biceps"},
        {"name": "Hammer Curls", "sets": 3, "reps": "10-12", "muscle_group": "Biceps"},
    ],
    "quadriceps": [
        {"name": "Goblet Squats", "sets": 3, "reps": "10-12", "muscle_group": "Quadriceps"},
        {"name": "Leg Press", "sets": 3, "reps": "10-12", "muscle_group": "Quadriceps"},
        {"name": "Walking Lunges", "sets": 3, "reps": "12 each", "muscle_group": "Quadriceps"},
    ],
    "hamstrings": [
        {"name": "Romanian Deadlifts", "sets": 3, "reps": "8-10", "muscle_group": "Hamstrings"},
        {"name": "Leg Curls", "sets": 3, "reps": "10-12", "muscle_group": "Hamstrings"},
    ],
    "glutes": [
        {"name": "Hip Thrusts", "sets": 3, "reps": "10-12", "muscle_group": "Glutes"},
        {"name": "Glute Bridges", "sets": 3, "reps": "12-15", "muscle_group": "Glutes"},
    ],
    "core": [
        {"name": "Plank", "sets": 3, "reps": "30-60 sec", "muscle_group": "Core"},
        {"name": "Dead Bug", "sets": 3, "reps": "10 each", "muscle_group": "Core"},
    ],
}

CURATED_TEMPLATES = {
    "push_pull_legs": [
        {"name": "Push Day", "focus": ["chest", "shoulders", "triceps"], "type": "strength"},
        {"name": "Pull Day", "focus": ["back", "biceps"], "type": "strength"},
        {"name": "Leg Day", "focus": ["quadriceps", "hamstrings", "glutes"], "type": "strength"},
    ],
    "upper_lower": [
        {"name": "Upper Body", "focus": ["chest", "back", "shoulders", "biceps", "triceps"], "type": "strength"},
        {"name": "Lower Body", "focus": ["quadriceps", "hamstrings", "glutes"], "type": "strength"},
    ],
    "full_body": [
        {"name": "Full Body", "focus": ["chest", "back", "quadriceps", "shoulders", "core"], "type": "strength"},
    ],
    "body_part": [
        {"name": "Chest Day", "focus": ["chest", "triceps"], "type": "strength"},
        {"name": "Back Day", "focus": ["back", "biceps"], "type": "strength"},
        {"name": "Shoulder Day", "focus": ["shoulders"], "type": "strength"},
        {"name": "Leg Day", "focus": ["quadriceps", "hamstrings", "glutes"], "type": "strength"},
        {"name": "Arm Day", "focus": ["biceps", "triceps"], "type": "strength"},
    ],
}


class FullPreviewPlanRequest(BaseModel):
    """Request for generating a full 4-week preview plan with AI."""
    goals: List[str]
    fitness_level: str  # beginner, intermediate, advanced
    equipment: List[str]
    days_per_week: int
    training_split: Optional[str] = "push_pull_legs"
    session_id: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None


class TryWorkoutRequest(BaseModel):
    """Request to try a demo workout."""
    session_id: str
    workout_id: str  # demo workout ID like "demo-beginner-full-body"
    started_at: Optional[str] = None


class TryWorkoutCompleteRequest(BaseModel):
    """Request when demo workout is completed."""
    session_id: str
    workout_id: str
    duration_seconds: int
    exercises_completed: int
    exercises_total: int
    feedback: Optional[str] = None  # too_easy, just_right, too_hard


