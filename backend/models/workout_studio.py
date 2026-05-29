"""Pydantic models for the Workout Customization Studio + adaptation engine.

These back the instant, RAG-driven customize/adapt/preset/shuffle/trim/swap
surfaces. `WorkoutBuildParams` is the single param set consumed by
`services.workout_builder.build_adapted_workout`.
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any


# ── Build params (shared by every surface) ───────────────────────────────────

class WorkoutBuildParams(BaseModel):
    """The full customization param set. All optional so partial updates from a
    slider drag work; the engine fills sensible defaults. Pain/injury avoidance
    (sore_areas + profile injuries) is treated as a HARD constraint."""
    focus_areas: List[str] = Field(default_factory=lambda: ["full_body"])
    # equipment None => fall back to the user's profile equipment
    equipment: Optional[List[str]] = None
    intensity: str = "moderate"            # light | moderate | intense
    duration_minutes: int = Field(default=20, ge=5, le=120)
    training_style: str = "hypertrophy"    # strength | hypertrophy | endurance | circuit
    warmup_minutes: int = Field(default=5, ge=0, le=30)
    cooldown_minutes: int = Field(default=5, ge=0, le=30)
    sore_areas: List[str] = Field(default_factory=list)   # transient, NOT persisted to profile
    impact_level: str = "normal"           # low | normal | high
    supersets: Optional[bool] = None       # None => auto
    amrap: Optional[bool] = None           # None => auto
    prioritize_staples: bool = False
    exercise_count: Optional[int] = Field(default=None, ge=1, le=20)
    avoid_exercises: List[str] = Field(default_factory=list)
    exclude_current: List[str] = Field(default_factory=list)  # for shuffle / variation
    active_recovery: bool = False          # mobility/recovery preset
    seed: Optional[int] = None             # vary => fresh draw (shuffle passes a new seed)


# ── Built workout (engine output) ─────────────────────────────────────────────

class BuiltWorkout(BaseModel):
    name: str
    type: str
    difficulty: str
    duration_minutes: int
    target_muscles: List[str] = Field(default_factory=list)
    warmup: List[Dict[str, Any]] = Field(default_factory=list)
    exercises: List[Dict[str, Any]] = Field(default_factory=list)
    cooldown: List[Dict[str, Any]] = Field(default_factory=list)
    relaxed_constraints: List[str] = Field(default_factory=list)  # what we had to loosen + why
    notes: Optional[str] = None
    workout_id: Optional[str] = None  # set when persisted


# ── Endpoint request models ───────────────────────────────────────────────────

class CustomizeRequest(BaseModel):
    """POST /workouts/customize. persist=False => in-memory preview (no DB row);
    persist=True => create a real workout and return its id.

    `prebuilt` is the WYSIWYG guarantee: on Apply the client sends back the
    BuiltWorkout it previewed, and we persist it verbatim instead of re-running
    the engine (which could draw different exercises). If absent, we build."""
    params: WorkoutBuildParams = Field(default_factory=WorkoutBuildParams)
    persist: bool = False
    name: Optional[str] = Field(default=None, max_length=200)
    prebuilt: Optional[BuiltWorkout] = None


class AdaptRequest(BaseModel):
    """POST /workouts/{workout_id}/adapt. Either structured params or free text.
    replace_in_place mutates the source (detail 'Adjust', with client-side undo);
    otherwise a NEW workout is forked (chat 'I have back pain' keeps the original)."""
    params: Optional[WorkoutBuildParams] = None
    constraints_text: Optional[str] = Field(default=None, max_length=500)
    replace_in_place: bool = False
    # WYSIWYG: Studio 'Apply' on an existing workout sends back the previewed
    # BuiltWorkout to persist verbatim (in-place) instead of re-deriving it.
    prebuilt: Optional[BuiltWorkout] = None


class WorkoutThumbsRequest(BaseModel):
    thumbs: int = Field(..., ge=-1, le=1)   # 1 up, -1 down (0 not used; delete to clear)
    reason: Optional[str] = Field(default=None, max_length=500)


class SaveWorkoutFromWorkout(BaseModel):
    workout_id: str = Field(..., max_length=100)
    name: Optional[str] = Field(default=None, max_length=200)
    folder: Optional[str] = Field(default="My Workouts", max_length=100)
    notes: Optional[str] = Field(default=None, max_length=2000)


class WorkoutPresetCreate(BaseModel):
    name: str = Field(..., max_length=120)
    params: WorkoutBuildParams


class WorkoutPresetUpdate(BaseModel):
    name: Optional[str] = Field(default=None, max_length=120)
    params: Optional[WorkoutBuildParams] = None


class WorkoutPreset(BaseModel):
    id: str
    user_id: str
    name: str
    params: Dict[str, Any]
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
