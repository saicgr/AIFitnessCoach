"""Pydantic models for exercise_progressions."""
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


class ChainType(str, Enum):
    """Types of progression chains."""
    LEVERAGE = "leverage"
    LOAD = "load"
    STABILITY = "stability"
    RANGE = "range"
    TEMPO = "tempo"


class MuscleGroup(str, Enum):
    """Primary muscle groups for filtering chains."""
    CHEST = "chest"
    BACK = "back"
    SHOULDERS = "shoulders"
    BICEPS = "biceps"
    TRICEPS = "triceps"
    CORE = "core"
    QUADRICEPS = "quadriceps"
    HAMSTRINGS = "hamstrings"
    GLUTES = "glutes"
    CALVES = "calves"
    FULL_BODY = "full_body"


class DifficultyFeedback(str, Enum):
    """User feedback on exercise difficulty."""
    TOO_EASY = "too_easy"
    JUST_RIGHT = "just_right"
    TOO_HARD = "too_hard"


class MasteryStatus(str, Enum):
    """Mastery status for an exercise."""
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


class ProgressionVariant(BaseModel):
    """A single variant in a progression chain."""
    id: str
    name: str
    order: int = Field(..., ge=0, description="Order in the chain (0 = easiest)")
    difficulty_score: float = Field(..., ge=1.0, le=10.0, description="1-10 difficulty rating")
    description: Optional[str] = None
    cues: List[str] = Field(default_factory=list, description="Form cues for this variant")
    common_mistakes: List[str] = Field(default_factory=list)
    video_url: Optional[str] = None
    prerequisites: List[str] = Field(default_factory=list, description="What user should master first")
    recommended_reps: str = Field(default="8-12", description="Recommended rep range")
    library_exercise_id: Optional[str] = None


class ProgressionChainResponse(BaseModel):
    """A progression chain with all its variants."""
    id: str
    name: str
    muscle_group: MuscleGroup
    chain_type: ChainType
    description: Optional[str] = None
    total_variants: int
    variants: List[ProgressionVariant] = Field(default_factory=list)
    created_at: Optional[datetime] = None


class ExerciseMastery(BaseModel):
    """User's mastery status for a specific exercise."""
    id: str
    user_id: str
    exercise_name: str
    chain_id: Optional[str] = None
    current_variant_order: Optional[int] = None
    status: MasteryStatus
    total_sessions: int = 0
    consecutive_easy_sessions: int = 0
    consecutive_hard_sessions: int = 0
    current_max_reps: int = 0
    current_max_weight: Optional[float] = None
    average_difficulty_rating: Optional[float] = None
    ready_for_progression: bool = False
    suggested_next_variant: Optional[str] = None
    last_performed_at: Optional[datetime] = None
    mastered_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ProgressionSuggestion(BaseModel):
    """A suggestion to progress to a harder exercise variant."""
    exercise_name: str
    current_difficulty_score: float
    suggested_exercise: str
    suggested_difficulty_score: float
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

