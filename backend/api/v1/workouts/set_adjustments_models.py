"""Pydantic models for set_adjustments."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class SetPerformanceInput(BaseModel):
    """Input model for set performance data in fatigue analysis."""
    reps: int = Field(..., ge=0, le=100, description="Number of reps completed")
    weight_kg: float = Field(..., ge=0, le=1000, description="Weight used in kg")
    rpe: Optional[float] = Field(
        default=None,
        ge=1, le=10,
        description="Rate of Perceived Exertion (1-10)"
    )
    duration_seconds: Optional[int] = Field(
        default=None,
        ge=0,
        description="Time taken to complete the set in seconds"
    )
    rest_before_seconds: Optional[int] = Field(
        default=None,
        ge=0,
        description="Rest time taken before this set in seconds"
    )
    timestamp: Optional[datetime] = Field(
        default=None,
        description="When the set was completed"
    )
    is_failure: bool = Field(
        default=False,
        description="Whether the set was taken to failure"
    )
    notes: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Any notes about the set"
    )


class FatigueCheckRequest(BaseModel):
    """Request body for fatigue analysis."""
    user_id: str = Field(..., max_length=100, description="User ID")
    exercise_name: str = Field(..., max_length=200, description="Name of the exercise")
    current_set: int = Field(..., ge=1, description="Current set number (1-indexed)")
    total_sets: int = Field(..., ge=1, description="Total planned sets")
    set_data: List[SetPerformanceInput] = Field(
        ...,
        description="Performance data from completed sets"
    )
    exercise_type: Optional[str] = Field(
        default=None,
        max_length=50,
        description="Type of exercise (compound/isolation/bodyweight)"
    )


class FatigueCheckResponse(BaseModel):
    """Response from fatigue analysis."""
    fatigue_level: float = Field(
        ...,
        ge=0, le=1,
        description="Overall fatigue level (0=fresh, 1=exhausted)"
    )
    indicators: List[str] = Field(
        ...,
        description="List of detected fatigue indicators"
    )
    confidence: float = Field(
        ...,
        ge=0, le=1,
        description="Confidence in the analysis"
    )
    recommendation: str = Field(
        ...,
        description="Suggested action: continue, reduce_weight, reduce_sets, stop_exercise"
    )
    message: str = Field(
        ...,
        description="Human-readable explanation of the analysis"
    )
    suggested_weight_reduction_pct: Optional[int] = Field(
        default=None,
        description="Suggested weight reduction percentage (if applicable)"
    )
    suggested_remaining_sets: Optional[int] = Field(
        default=None,
        description="Suggested remaining sets (if applicable)"
    )
    show_prompt: bool = Field(
        default=False,
        description="Whether to show a prompt to the user"
    )
    prompt_text: Optional[str] = Field(
        default=None,
        description="Text to show in the user prompt"
    )
    alternative_actions: List[str] = Field(
        default_factory=list,
        description="Alternative actions the user could take"
    )


class FatigueResponseRequest(BaseModel):
    """Request to log user response to fatigue suggestion."""
    user_id: str = Field(..., max_length=100)
    exercise_name: str = Field(..., max_length=200)
    fatigue_level: float = Field(..., ge=0, le=1)
    recommendation: str = Field(..., max_length=50)
    user_response: str = Field(
        ...,
        max_length=50,
        description="User response: accepted, declined, ignored"
    )


class FatigueResponseResponse(BaseModel):
    """Response after logging user's fatigue response."""
    success: bool
    message: str
    event_id: Optional[str] = None


class FatigueHistoryItem(BaseModel):
    """A single fatigue detection event."""
    exercise_name: str
    fatigue_level: float
    recommendation: str
    user_response: Optional[str]
    timestamp: datetime


class FatigueHistoryResponse(BaseModel):
    """Response with fatigue history for a workout."""
    workout_id: str
    events: List[FatigueHistoryItem]
    total_events: int


# =============================================================================
# Fatigue Detection API Endpoints
# =============================================================================

