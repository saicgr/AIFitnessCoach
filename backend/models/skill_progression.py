"""
Skill Progression Pydantic models.

Models for tracking bodyweight skill progressions like:
- Push-up progressions (wall -> incline -> knee -> full -> diamond -> archer -> one-arm)
- Pull-up progressions (dead hang -> scapular pulls -> negatives -> band-assisted -> full -> chest-to-bar -> muscle-up)
- Squat progressions (assisted -> bodyweight -> pistol)
- Handstand progressions (wall hold -> freestanding -> handstand pushup)
- And more...
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class SkillCategory(str, Enum):
    """Categories for skill progressions."""
    PUSH = "push"
    PULL = "pull"
    LEGS = "legs"
    CORE = "core"
    BALANCE = "balance"
    FLEXIBILITY = "flexibility"


class DifficultyLevel(str, Enum):
    """Difficulty levels for progression steps."""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    ELITE = "elite"


# ============================================
# Progression Chain Models
# ============================================

class ProgressionChainBase(BaseModel):
    """Base model for progression chains."""
    name: str = Field(..., max_length=100, description="Name of the progression chain (e.g., 'Push-up Progression')")
    description: str = Field(..., max_length=500, description="Description of what this progression teaches")
    category: SkillCategory = Field(..., description="Category of the skill")
    icon: Optional[str] = Field(default=None, max_length=50, description="Icon identifier for UI")
    target_muscles: List[str] = Field(default_factory=list, max_length=10, description="Primary muscles targeted")
    estimated_weeks_to_master: Optional[int] = Field(default=None, ge=1, le=520, description="Estimated weeks to complete progression")


class ProgressionChainCreate(ProgressionChainBase):
    """Model for creating a new progression chain."""
    pass


class ProgressionChain(ProgressionChainBase):
    """Full progression chain model with ID and metadata."""
    id: str = Field(..., max_length=100)
    total_steps: int = Field(default=0, ge=0, description="Total number of steps in this chain")
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ProgressionChainWithSteps(ProgressionChain):
    """Progression chain with all its steps included."""
    steps: List["ProgressionStep"] = Field(default_factory=list)


# ============================================
# Progression Step Models
# ============================================

class UnlockCriteria(BaseModel):
    """Criteria required to unlock the next progression step."""
    min_reps: Optional[int] = Field(default=None, ge=1, le=100, description="Minimum reps required")
    min_sets: Optional[int] = Field(default=None, ge=1, le=10, description="Minimum sets at min_reps")
    min_hold_seconds: Optional[int] = Field(default=None, ge=1, le=600, description="Minimum hold time for static exercises")
    min_consecutive_days: Optional[int] = Field(default=None, ge=1, le=30, description="Days of consistent practice")
    custom_requirement: Optional[str] = Field(default=None, max_length=200, description="Custom unlock requirement description")


class ProgressionStepBase(BaseModel):
    """Base model for progression steps."""
    exercise_name: str = Field(..., max_length=200, description="Name of the exercise at this step")
    step_order: int = Field(..., ge=0, le=50, description="Order in the progression (0-indexed)")
    difficulty_level: DifficultyLevel = Field(..., description="Difficulty level of this step")
    prerequisites: List[str] = Field(default_factory=list, max_length=5, description="List of prerequisite exercises or skills")
    unlock_criteria: UnlockCriteria = Field(default_factory=UnlockCriteria, description="Criteria to unlock next step")
    tips: List[str] = Field(default_factory=list, max_length=10, description="Tips for mastering this step")
    common_mistakes: List[str] = Field(default_factory=list, max_length=10, description="Common mistakes to avoid")
    video_url: Optional[str] = Field(default=None, max_length=500, description="URL to demonstration video")
    image_url: Optional[str] = Field(default=None, max_length=500, description="URL to demonstration image")
    description: Optional[str] = Field(default=None, max_length=500, description="Detailed description of the exercise")
    sets_recommendation: Optional[str] = Field(default="3", max_length=20, description="Recommended sets (e.g., '3-5')")
    reps_recommendation: Optional[str] = Field(default="8-12", max_length=20, description="Recommended reps (e.g., '8-12')")


class ProgressionStepCreate(ProgressionStepBase):
    """Model for creating a new progression step."""
    chain_id: str = Field(..., max_length=100, description="ID of the parent progression chain")


class ProgressionStep(ProgressionStepBase):
    """Full progression step model with ID and metadata."""
    id: str = Field(..., max_length=100)
    chain_id: str = Field(..., max_length=100)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


# ============================================
# User Skill Progress Models
# ============================================

class SkillAttempt(BaseModel):
    """A single attempt at a skill progression step."""
    reps: int = Field(..., ge=0, le=1000, description="Reps completed in this attempt")
    sets: int = Field(default=1, ge=1, le=20, description="Sets completed")
    hold_seconds: Optional[int] = Field(default=None, ge=0, le=600, description="Hold time for static exercises")
    success: bool = Field(default=False, description="Whether the attempt met the unlock criteria")
    notes: Optional[str] = Field(default=None, max_length=500, description="Notes about this attempt")
    attempted_at: datetime = Field(default_factory=datetime.utcnow)


class UserSkillProgressBase(BaseModel):
    """Base model for user skill progress."""
    current_step_order: int = Field(default=0, ge=0, le=50, description="Current step in the progression")
    unlocked_steps: List[int] = Field(default_factory=lambda: [0], description="List of unlocked step orders")
    attempts_at_current: int = Field(default=0, ge=0, description="Number of attempts at current step")
    best_reps_at_current: int = Field(default=0, ge=0, le=1000, description="Best reps achieved at current step")
    best_hold_at_current: Optional[int] = Field(default=None, ge=0, le=600, description="Best hold time at current step")
    is_completed: bool = Field(default=False, description="Whether the full progression is completed")
    is_active: bool = Field(default=True, description="Whether user is actively working on this progression")


class UserSkillProgressCreate(UserSkillProgressBase):
    """Model for creating user skill progress."""
    user_id: str = Field(..., max_length=100)
    chain_id: str = Field(..., max_length=100)


class UserSkillProgress(UserSkillProgressBase):
    """Full user skill progress model with ID and metadata."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    chain_id: str = Field(..., max_length=100)
    started_at: Optional[datetime] = None
    last_attempt_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class UserSkillProgressWithChain(UserSkillProgress):
    """User skill progress with the associated chain info."""
    chain: Optional[ProgressionChain] = None
    current_step: Optional[ProgressionStep] = None
    next_step: Optional[ProgressionStep] = None


class UserSkillProgressWithHistory(UserSkillProgress):
    """User skill progress with attempt history."""
    chain: Optional[ProgressionChain] = None
    current_step: Optional[ProgressionStep] = None
    recent_attempts: List[SkillAttempt] = Field(default_factory=list)


# ============================================
# Request/Response Models
# ============================================

class LogAttemptRequest(BaseModel):
    """Request to log an attempt at a skill."""
    reps: int = Field(..., ge=0, le=1000, description="Reps completed")
    sets: int = Field(default=1, ge=1, le=20, description="Sets completed")
    hold_seconds: Optional[int] = Field(default=None, ge=0, le=600, description="Hold time for static exercises")
    success: bool = Field(default=False, description="Whether the attempt was successful")
    notes: Optional[str] = Field(default=None, max_length=500, description="Notes about this attempt")


class LogAttemptResponse(BaseModel):
    """Response from logging an attempt."""
    success: bool
    message: str = Field(..., max_length=500)
    progress: UserSkillProgress
    is_new_best: bool = Field(default=False, description="Whether this was a new personal best")
    can_unlock_next: bool = Field(default=False, description="Whether user can now unlock the next step")
    unlock_criteria_met: bool = Field(default=False, description="Whether unlock criteria was met")


class UnlockNextResponse(BaseModel):
    """Response from unlocking the next step."""
    success: bool
    message: str = Field(..., max_length=500)
    progress: UserSkillProgress
    unlocked_step: Optional[ProgressionStep] = None
    is_chain_completed: bool = Field(default=False, description="Whether the full chain is now completed")


class StartChainResponse(BaseModel):
    """Response from starting a new progression chain."""
    success: bool
    message: str = Field(..., max_length=500)
    progress: UserSkillProgress
    chain: ProgressionChain
    first_step: Optional[ProgressionStep] = None


class SkillProgressSummary(BaseModel):
    """Summary of a user's skill progress for display."""
    chain_id: str
    chain_name: str
    category: SkillCategory
    current_step_name: str
    progress_percentage: float = Field(..., ge=0, le=100)
    total_steps: int
    completed_steps: int
    is_completed: bool
    last_attempt_at: Optional[datetime] = None


class UserSkillsSummary(BaseModel):
    """Summary of all user's skill progressions."""
    total_chains_started: int
    total_chains_completed: int
    active_progressions: List[SkillProgressSummary]
    completed_progressions: List[SkillProgressSummary]
    recommended_next_chain: Optional[ProgressionChain] = None


# Update forward references
ProgressionChainWithSteps.model_rebuild()
