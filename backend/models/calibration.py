"""
Calibration Workout Pydantic models.

Models for the calibration workout feature that helps assess user strength
and validate their self-reported fitness level during onboarding.
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class PerceivedDifficulty(str, Enum):
    """Rating levels for perceived exercise difficulty."""
    TOO_EASY = "too_easy"
    MODERATE = "moderate"
    CHALLENGING = "challenging"
    MAX_EFFORT = "max_effort"


class CalibrationWorkoutType(str, Enum):
    """Types of calibration workouts."""
    ONBOARDING = "onboarding"
    REASSESSMENT = "reassessment"
    MANUAL = "manual"


class CalibrationWorkoutStatus(str, Enum):
    """Status of a calibration workout."""
    SCHEDULED = "scheduled"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    SKIPPED = "skipped"
    CANCELLED = "cancelled"


# ============================================
# Calibration Exercise Models
# ============================================

class CalibrationExercise(BaseModel):
    """
    Model for an exercise in a calibration workout.

    Contains both suggested values (from AI) and actual performed values
    to compare expected vs actual performance.
    """
    exercise_name: str = Field(..., max_length=200, description="Name of the exercise")
    exercise_id: Optional[str] = Field(default=None, max_length=100, description="Exercise ID from database")
    target_muscle: str = Field(..., max_length=100, description="Primary muscle group targeted")
    equipment: str = Field(..., max_length=100, description="Equipment required for this exercise")

    # Suggested values (AI-generated based on user profile)
    suggested_weight_kg: Optional[float] = Field(default=None, ge=0, description="AI-suggested weight in kg")
    suggested_reps: int = Field(..., ge=1, le=100, description="Suggested number of reps")
    suggested_sets: int = Field(default=1, ge=1, le=10, description="Suggested number of sets")

    # Actual performed values (filled in after workout)
    actual_weight_kg: Optional[float] = Field(default=None, ge=0, description="Actual weight used in kg")
    actual_reps: Optional[int] = Field(default=None, ge=0, le=200, description="Actual reps performed")
    actual_sets: Optional[int] = Field(default=None, ge=0, le=20, description="Actual sets completed")

    # Subjective feedback
    perceived_difficulty: Optional[PerceivedDifficulty] = Field(
        default=None,
        description="User's perceived difficulty (too_easy, moderate, challenging, max_effort)"
    )
    notes: Optional[str] = Field(default=None, max_length=500, description="User notes about this exercise")


# ============================================
# Calibration Workout Create/Update Models
# ============================================

class CalibrationWorkoutCreate(BaseModel):
    """
    Model for creating a new calibration workout.

    Used when generating a calibration workout for a user during onboarding
    or when manually triggering a reassessment.
    """
    workout_type: CalibrationWorkoutType = Field(
        default=CalibrationWorkoutType.ONBOARDING,
        description="Type of calibration workout"
    )
    exercises: List[CalibrationExercise] = Field(
        ...,
        min_length=1,
        max_length=20,
        description="List of exercises in the calibration workout"
    )


# ============================================
# Calibration Workout Response Models
# ============================================

class CalibrationWorkoutResponse(BaseModel):
    """
    Full calibration workout response model.

    Contains all workout data including exercises, timing, and analysis results.
    """
    id: str = Field(..., max_length=100, description="Unique workout ID")
    user_id: str = Field(..., max_length=100, description="User ID")
    workout_type: str = Field(..., max_length=50, description="Type of calibration workout")
    status: str = Field(..., max_length=50, description="Current workout status")
    scheduled_date: datetime = Field(..., description="When the workout was/is scheduled")

    # Timing
    started_at: Optional[datetime] = Field(default=None, description="When user started the workout")
    completed_at: Optional[datetime] = Field(default=None, description="When user completed the workout")
    duration_minutes: Optional[int] = Field(default=None, ge=0, description="Total workout duration in minutes")

    # Exercises
    exercises: List[CalibrationExercise] = Field(default_factory=list, description="List of exercises")

    # User feedback
    user_reported_difficulty: Optional[str] = Field(
        default=None,
        max_length=50,
        description="Overall difficulty reported by user"
    )

    # AI analysis results
    ai_analysis: Optional[Dict[str, Any]] = Field(
        default=None,
        description="AI analysis of the calibration workout results"
    )
    suggested_adjustments: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Suggested profile adjustments based on analysis"
    )
    user_accepted_adjustments: Optional[bool] = Field(
        default=None,
        description="Whether user accepted the suggested adjustments"
    )

    # Metadata
    created_at: datetime = Field(..., description="When the workout was created")


# ============================================
# Calibration Result Models
# ============================================

class CalibrationResult(BaseModel):
    """
    Model for recording calibration workout results.

    Submitted by user after completing the calibration workout with
    actual performance data.
    """
    calibration_workout_id: str = Field(..., max_length=100, description="ID of the calibration workout")
    exercises: List[CalibrationExercise] = Field(
        ...,
        min_length=1,
        description="Exercises with actual values filled in"
    )
    user_reported_difficulty: str = Field(
        ...,
        max_length=50,
        description="Overall workout difficulty (too_easy, moderate, challenging, max_effort)"
    )
    duration_minutes: int = Field(..., ge=1, le=300, description="Total workout duration in minutes")
    notes: Optional[str] = Field(default=None, max_length=1000, description="User notes about the workout")


# ============================================
# Strength Baseline Models
# ============================================

class StrengthBaseline(BaseModel):
    """
    Model for storing strength baseline data for an exercise.

    Created from calibration workout results to track user's starting point
    and enable personalized weight suggestions.
    """
    id: str = Field(..., max_length=100, description="Unique baseline ID")
    user_id: str = Field(..., max_length=100, description="User ID")
    calibration_workout_id: Optional[str] = Field(
        default=None,
        max_length=100,
        description="ID of the calibration workout that generated this baseline"
    )

    # Exercise info
    exercise_name: str = Field(..., max_length=200, description="Name of the exercise")
    exercise_id: Optional[str] = Field(default=None, max_length=100, description="Exercise ID from database")

    # Tested values
    tested_weight_kg: Optional[float] = Field(default=None, ge=0, description="Weight used during test")
    tested_reps: Optional[int] = Field(default=None, ge=1, le=200, description="Reps performed during test")
    tested_sets: Optional[int] = Field(default=None, ge=1, le=20, description="Sets completed during test")
    perceived_difficulty: Optional[PerceivedDifficulty] = Field(
        default=None,
        description="User's perceived difficulty during test"
    )

    # Calculated values
    estimated_1rm: Optional[float] = Field(
        default=None,
        ge=0,
        description="Estimated 1 rep max based on test performance"
    )

    notes: Optional[str] = Field(default=None, max_length=500, description="Notes about this baseline")
    created_at: datetime = Field(..., description="When this baseline was created")


class StrengthBaselineCreate(BaseModel):
    """Model for creating a new strength baseline."""
    exercise_name: str = Field(..., max_length=200)
    exercise_id: Optional[str] = Field(default=None, max_length=100)
    calibration_workout_id: Optional[str] = Field(default=None, max_length=100)
    tested_weight_kg: Optional[float] = Field(default=None, ge=0)
    tested_reps: Optional[int] = Field(default=None, ge=1, le=200)
    tested_sets: Optional[int] = Field(default=None, ge=1, le=20)
    perceived_difficulty: Optional[PerceivedDifficulty] = Field(default=None)
    estimated_1rm: Optional[float] = Field(default=None, ge=0)
    notes: Optional[str] = Field(default=None, max_length=500)


# ============================================
# Calibration Analysis Models
# ============================================

class ExerciseInsight(BaseModel):
    """Insight for a single exercise from calibration analysis."""
    exercise_name: str = Field(..., max_length=200)
    expected_vs_actual: str = Field(..., max_length=200, description="Comparison of expected vs actual performance")
    strength_indicator: str = Field(..., max_length=100, description="e.g., 'above average', 'below average'")
    notes: Optional[str] = Field(default=None, max_length=500)


class CalibrationAnalysis(BaseModel):
    """
    AI analysis result from a calibration workout.

    Compares user's actual performance against their self-reported fitness level
    to determine accuracy and suggest adjustments.
    """
    fitness_level_match: bool = Field(
        ...,
        description="Whether onboarding fitness level matches actual performance"
    )
    onboarding_fitness_level: str = Field(
        ...,
        max_length=50,
        description="Fitness level user selected during onboarding"
    )
    suggested_fitness_level: str = Field(
        ...,
        max_length=50,
        description="Fitness level suggested based on performance"
    )
    confidence_score: float = Field(
        ...,
        ge=0,
        le=1,
        description="Confidence in the analysis (0-1)"
    )
    analysis_summary: str = Field(
        ...,
        max_length=1000,
        description="2-3 sentence summary of the analysis"
    )
    exercise_insights: List[ExerciseInsight] = Field(
        default_factory=list,
        description="Per-exercise analysis insights"
    )
    recommended_adjustments: Dict[str, Any] = Field(
        default_factory=dict,
        description="Recommended changes to user profile"
    )


# ============================================
# Suggested Adjustments Models
# ============================================

class CalibrationSuggestedAdjustments(BaseModel):
    """
    Suggested profile adjustments based on calibration workout results.

    Contains specific recommendations that can be applied to the user's profile
    to better personalize their workouts.
    """
    adjust_fitness_level: bool = Field(
        default=False,
        description="Whether to adjust the fitness level"
    )
    new_fitness_level: Optional[str] = Field(
        default=None,
        max_length=50,
        description="New recommended fitness level"
    )

    adjust_intensity: bool = Field(
        default=False,
        description="Whether to adjust workout intensity preference"
    )
    new_intensity_preference: Optional[str] = Field(
        default=None,
        max_length=50,
        description="New recommended intensity preference"
    )

    adjust_starting_weights: bool = Field(
        default=False,
        description="Whether to adjust starting weights"
    )
    weight_multiplier: Optional[float] = Field(
        default=None,
        ge=0.1,
        le=3.0,
        description="Multiplier for weight suggestions (e.g., 1.2 for 20% increase)"
    )

    message_to_user: str = Field(
        ...,
        max_length=1000,
        description="Friendly message explaining the suggestions to the user"
    )


# ============================================
# Request/Response Models
# ============================================

class StartCalibrationRequest(BaseModel):
    """Request to start a calibration workout."""
    workout_type: CalibrationWorkoutType = Field(default=CalibrationWorkoutType.ONBOARDING)


class StartCalibrationResponse(BaseModel):
    """Response when starting a calibration workout."""
    success: bool
    message: str = Field(..., max_length=500)
    workout: CalibrationWorkoutResponse


class SubmitCalibrationResultRequest(BaseModel):
    """Request to submit calibration workout results."""
    exercises: List[CalibrationExercise] = Field(..., min_length=1)
    user_reported_difficulty: str = Field(..., max_length=50)
    duration_minutes: int = Field(..., ge=1, le=300)
    notes: Optional[str] = Field(default=None, max_length=1000)


class SubmitCalibrationResultResponse(BaseModel):
    """Response after submitting calibration results."""
    success: bool
    message: str = Field(..., max_length=500)
    workout: CalibrationWorkoutResponse
    analysis: CalibrationAnalysis
    suggested_adjustments: CalibrationSuggestedAdjustments


class AcceptAdjustmentsRequest(BaseModel):
    """Request to accept or reject suggested adjustments."""
    calibration_workout_id: str = Field(..., max_length=100)
    accepted: bool = Field(..., description="Whether user accepts the adjustments")


class AcceptAdjustmentsResponse(BaseModel):
    """Response after accepting/rejecting adjustments."""
    success: bool
    message: str = Field(..., max_length=500)
    adjustments_applied: bool


class GetCalibrationHistoryResponse(BaseModel):
    """Response containing user's calibration workout history."""
    workouts: List[CalibrationWorkoutResponse]
    total_count: int
    latest_analysis: Optional[CalibrationAnalysis] = None


class GetStrengthBaselinesResponse(BaseModel):
    """Response containing user's strength baselines."""
    baselines: List[StrengthBaseline]
    total_count: int
    last_updated: Optional[datetime] = None
