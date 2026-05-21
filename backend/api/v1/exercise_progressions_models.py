"""Pydantic models for exercise_progressions.

These models are aligned to the REAL deployed schema (migrations 081 + 089):
  - exercise_progression_chains (id, name, description, category, created_at)
  - exercise_progression_steps  (id, chain_id, exercise_name, step_order,
                                 difficulty_level, prerequisites, unlock_criteria,
                                 tips, video_url, created_at)
  - user_exercise_mastery       (id, user_id, exercise_name, consecutive_easy_sessions,
                                 consecutive_hard_sessions, total_sessions,
                                 ready_for_progression, suggested_next_variant,
                                 progression_chain_id, last_progression_suggested_at,
                                 progression_declined_at, decline_reason,
                                 progression_accepted_count, progression_declined_count,
                                 first_performed_at, last_performed_at, created_at,
                                 updated_at, current_max_reps, current_max_weight_kg,
                                 current_difficulty_level, current_max_weight,
                                 mastery_level, progression_status)
"""
from datetime import datetime, date
from enum import Enum
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class ProgressionType(str, Enum):
    """Types of exercise progressions."""
    LEVERAGE = "leverage"
    LOAD = "load"
    STABILITY = "stability"
    RANGE = "range"
    TEMPO = "tempo"


class ChainCategory(str, Enum):
    """Progression chain categories — matches exercise_progression_chains.category.

    The deployed seed data uses skill-movement categories, not muscle groups.
    """
    PUSHUP = "pushup"
    PULLUP = "pullup"
    SQUAT = "squat"
    HANDSTAND = "handstand"
    MUSCLE_UP = "muscle_up"
    FRONT_LEVER = "front_lever"
    PLANCHE = "planche"


class DifficultyFeedback(str, Enum):
    """User feedback on exercise difficulty."""
    TOO_EASY = "too_easy"
    JUST_RIGHT = "just_right"
    TOO_HARD = "too_hard"


class MasteryStatus(str, Enum):
    """Mastery status for an exercise. Stored in user_exercise_mastery.progression_status."""
    LEARNING = "learning"
    PROFICIENT = "proficient"
    MASTERED = "mastered"
    PROGRESSED = "progressed"


class ProgressionStyle(str, Enum):
    """User's preferred progression style."""
    CONSERVATIVE = "conservative"
    MODERATE = "moderate"
    AGGRESSIVE = "aggressive"


class TrainingFocus(str, Enum):
    """User's training focus affecting rep ranges."""
    STRENGTH = "strength"
    HYPERTROPHY = "hypertrophy"
    ENDURANCE = "endurance"
    MIXED = "mixed"


class ProgressionStep(BaseModel):
    """A single step in a progression chain.

    Maps directly to a row of exercise_progression_steps. Replaces the old
    `ProgressionVariant` model which referenced phantom columns (variant_order,
    difficulty_score, cues, common_mistakes, library_exercise_id).
    """
    id: str
    name: str = Field(..., description="exercise_name column")
    order: int = Field(..., ge=0, description="step_order in the chain (1 = easiest)")
    difficulty_level: int = Field(
        default=5, ge=1, le=10, description="1-10 difficulty rating (difficulty_level column)"
    )
    tips: Optional[str] = Field(default=None, description="Form tips for this step (tips column)")
    video_url: Optional[str] = None
    prerequisites: List[str] = Field(
        default_factory=list,
        description="Exercises/criteria to master first (parsed from prerequisites TEXT/JSON column)",
    )
    unlock_criteria: Dict[str, Any] = Field(
        default_factory=dict,
        description="JSONB criteria, e.g. {'reps': 12, 'sets': 3, 'consecutive_sessions': 3}",
    )
    recommended_reps: str = Field(
        default="8-12", description="Recommended rep range, derived from unlock_criteria"
    )


class ProgressionChainResponse(BaseModel):
    """A progression chain with all its steps. Maps to exercise_progression_chains."""
    id: str
    name: str
    category: Optional[str] = Field(default=None, description="Chain category column")
    description: Optional[str] = None
    total_steps: int = 0
    steps: List[ProgressionStep] = Field(default_factory=list)
    created_at: Optional[datetime] = None


class ExerciseMastery(BaseModel):
    """User's mastery status for a specific exercise. Maps to user_exercise_mastery.

    Phantom columns dropped: current_variant_order (derived from step lookup, exposed
    as current_step_order), mastered_at (no column), average_difficulty_rating (no column).
    """
    id: str
    user_id: str
    exercise_name: str
    chain_id: Optional[str] = Field(
        default=None, description="progression_chain_id column"
    )
    current_step_order: Optional[int] = Field(
        default=None,
        description="Derived: step_order of this exercise in its chain (not a stored column)",
    )
    status: MasteryStatus = Field(
        default=MasteryStatus.LEARNING, description="progression_status column"
    )
    total_sessions: int = 0
    consecutive_easy_sessions: int = 0
    consecutive_hard_sessions: int = 0
    current_max_reps: int = 0
    current_max_weight: Optional[float] = None
    ready_for_progression: bool = False
    suggested_next_variant: Optional[str] = None
    progression_accepted_count: int = 0
    progression_declined_count: int = 0
    first_performed_at: Optional[datetime] = None
    last_performed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ExerciseMasteryWithChain(ExerciseMastery):
    """Exercise mastery with chain details joined in."""
    chain_name: Optional[str] = None
    next_step: Optional[ProgressionStep] = None


class ProgressionSuggestion(BaseModel):
    """A suggestion to progress to a harder exercise variant."""
    exercise_name: str
    current_difficulty_level: int = Field(default=5, ge=1, le=10)
    suggested_exercise: str
    suggested_difficulty_level: int = Field(default=6, ge=1, le=10)
    chain_id: str
    chain_name: str
    reason: str
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence in this suggestion")
    stats: Dict[str, Any] = Field(default_factory=dict)


class UpdateMasteryRequest(BaseModel):
    """Request to update mastery after a workout."""
    exercise_name: str = Field(..., min_length=1, max_length=200)
    reps_performed: int = Field(..., ge=0, le=1000)
    weight_used: Optional[float] = Field(default=None, ge=0, le=2000)
    difficulty_felt: DifficultyFeedback
    sets_completed: int = Field(default=3, ge=1, le=20)
    notes: Optional[str] = Field(default=None, max_length=500)


class UpdateMasteryResponse(BaseModel):
    """Response from updating mastery."""
    success: bool
    mastery: ExerciseMastery
    progression_unlocked: bool = False
    suggested_next: Optional[str] = None
    message: str


class AcceptProgressionRequest(BaseModel):
    """Request to accept a progression suggestion."""
    current_exercise: str = Field(..., min_length=1, max_length=200)
    new_exercise: str = Field(..., min_length=1, max_length=200)


class AcceptProgressionResponse(BaseModel):
    """Response from accepting a progression."""
    success: bool
    old_exercise: str
    old_status: MasteryStatus
    new_exercise: str
    new_status: MasteryStatus
    message: str


class RepPreferences(BaseModel):
    """User's rep range preferences."""
    training_focus: TrainingFocus = TrainingFocus.HYPERTROPHY
    preferred_min_reps: int = Field(default=6, ge=1, le=50)
    preferred_max_reps: int = Field(default=12, ge=1, le=100)
    avoid_high_reps: bool = False
    progression_style: ProgressionStyle = ProgressionStyle.MODERATE


class RepPreferencesResponse(BaseModel):
    """Response with rep preferences."""
    training_focus: TrainingFocus
    preferred_min_reps: int
    preferred_max_reps: int
    avoid_high_reps: bool
    progression_style: ProgressionStyle
    description: str


# =============================================================================
# Helper Functions
# =============================================================================
