"""
Fatigue Alerts API.

Provides real-time fatigue detection and next set preview endpoints
for active workouts. These endpoints analyze set performance data
and provide actionable recommendations to prevent overtraining and
optimize workout effectiveness.

Endpoints:
- POST /workouts/fatigue-check: Check for fatigue based on session sets
- POST /workouts/next-set-preview: Get AI-recommended parameters for next set
"""

from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional
from pydantic import BaseModel, Field

from core.logger import get_logger
from services.fatigue_detection_service import (
    detect_fatigue,
    calculate_next_set_preview,
    FatigueAlert,
    NextSetPreview,
)

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Request/Response Models
# =============================================================================

class SetData(BaseModel):
    """Data for a single completed set."""
    reps: int = Field(..., ge=0, description="Number of reps completed")
    weight: float = Field(..., ge=0, description="Weight used in kg")
    rpe: Optional[int] = Field(
        None, ge=6, le=10,
        description="Rate of Perceived Exertion (6-10)"
    )
    rir: Optional[int] = Field(
        None, ge=0, le=5,
        description="Reps in Reserve (0-5)"
    )
    is_failure: bool = Field(
        False,
        description="Whether the set was taken to failure"
    )
    target_reps: Optional[int] = Field(
        None, ge=0,
        description="Target reps for this set"
    )


class FatigueCheckRequest(BaseModel):
    """Request body for fatigue check endpoint."""
    sets_data: List[SetData] = Field(
        ...,
        min_length=1,
        description="List of completed sets in current exercise session"
    )
    current_weight: float = Field(
        ..., ge=0,
        description="Current weight being used in kg"
    )
    exercise_type: str = Field(
        "compound",
        description="Type of exercise: 'compound', 'isolation', or 'bodyweight'"
    )
    target_reps: Optional[int] = Field(
        None, ge=0,
        description="Target reps per set (overrides per-set targets)"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "sets_data": [
                    {"reps": 10, "weight": 100, "rpe": 7, "target_reps": 10},
                    {"reps": 8, "weight": 100, "rpe": 8, "target_reps": 10},
                    {"reps": 6, "weight": 100, "rpe": 10, "target_reps": 10},
                ],
                "current_weight": 100,
                "exercise_type": "compound",
                "target_reps": 10
            }
        }


class FatigueCheckResponse(BaseModel):
    """Response from fatigue check endpoint."""
    fatigue_detected: bool = Field(
        ...,
        description="Whether significant fatigue was detected"
    )
    severity: str = Field(
        ...,
        description="Severity level: 'none', 'low', 'moderate', 'high', 'critical'"
    )
    suggested_weight_reduction: int = Field(
        ..., ge=0, le=30,
        description="Suggested weight reduction percentage"
    )
    suggested_weight: float = Field(
        ..., ge=0,
        description="Suggested weight in kg for next set"
    )
    reasoning: str = Field(
        ...,
        description="Human-readable explanation of detection"
    )
    indicators: List[str] = Field(
        ...,
        description="List of triggered fatigue indicators"
    )
    confidence: float = Field(
        ..., ge=0, le=1,
        description="Confidence in the detection (0-1)"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "fatigue_detected": True,
                "severity": "high",
                "suggested_weight_reduction": 15,
                "suggested_weight": 85.0,
                "reasoning": "Significant rep decline (40%) from target. RPE jumped from 7 to 10 between sets. Consider reducing weight by 15%.",
                "indicators": ["severe_rep_decline", "rpe_spike"],
                "confidence": 0.92
            }
        }


class NextSetPreviewRequest(BaseModel):
    """Request body for next set preview endpoint."""
    sets_data: List[SetData] = Field(
        default_factory=list,
        description="List of completed sets (can be empty for first set)"
    )
    current_set_number: int = Field(
        ..., ge=1,
        description="The set number just completed (1-indexed)"
    )
    total_sets: int = Field(
        ..., ge=1,
        description="Total planned sets for this exercise"
    )
    target_reps: int = Field(
        ..., ge=1,
        description="Target reps per set"
    )
    current_weight: float = Field(
        ..., ge=0,
        description="Current weight being used in kg"
    )
    estimated_1rm: Optional[float] = Field(
        None, ge=0,
        description="User's estimated 1RM for this exercise in kg"
    )
    target_intensity: float = Field(
        0.75, ge=0.3, le=1.0,
        description="Target intensity as fraction of 1RM (0.3-1.0)"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "sets_data": [
                    {"reps": 10, "weight": 100, "rpe": 7}
                ],
                "current_set_number": 1,
                "total_sets": 4,
                "target_reps": 10,
                "current_weight": 100,
                "estimated_1rm": 130,
                "target_intensity": 0.75
            }
        }


class NextSetPreviewResponse(BaseModel):
    """Response from next set preview endpoint."""
    recommended_weight: float = Field(
        ..., ge=0,
        description="Recommended weight in kg for next set"
    )
    recommended_reps: int = Field(
        ..., ge=0,
        description="Recommended rep count for next set"
    )
    intensity_percentage: float = Field(
        ..., ge=0, le=100,
        description="Estimated intensity as percentage of 1RM"
    )
    reasoning: str = Field(
        ...,
        description="Explanation for the recommendation"
    )
    confidence: float = Field(
        ..., ge=0, le=1,
        description="Confidence in the recommendation (0-1)"
    )
    is_final_set: bool = Field(
        ...,
        description="Whether the next set is the final set"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "recommended_weight": 102.5,
                "recommended_reps": 10,
                "intensity_percentage": 78.8,
                "reasoning": "Previous set was easy (RIR 4). Try increasing weight.",
                "confidence": 0.85,
                "is_final_set": False
            }
        }


# =============================================================================
# API Endpoints
# =============================================================================

@router.post(
    "/fatigue-check",
    response_model=FatigueCheckResponse,
    summary="Check for workout fatigue",
    description="""
    Analyzes completed sets in the current exercise session to detect
    signs of fatigue that may warrant intervention.

    **Triggers for fatigue detection:**
    1. Rep decline >= 20% from target or first set
    2. RPE increase of 2+ between consecutive sets
    3. Failed set (0 reps or user marks as failed)
    4. Weight already reduced mid-exercise
    5. Multiple high-RPE sets (RPE >= 9)

    **Severity levels:**
    - `none`: No significant fatigue detected
    - `low`: Minor fatigue, monitor but continue
    - `moderate`: Consider reducing weight by 10%
    - `high`: Strongly recommend reducing weight by 15-20%
    - `critical`: Recommend stopping or major weight reduction

    **Usage:**
    Call this endpoint after each set completion during active workouts.
    Show an alert to the user if `fatigue_detected` is true.
    """,
    tags=["Fatigue Detection"],
)
async def check_fatigue(request: FatigueCheckRequest) -> FatigueCheckResponse:
    """
    Check for fatigue based on session set data.

    This endpoint is designed to be called after each set completion
    during an active workout to provide real-time fatigue monitoring.
    """
    logger.info(
        f"[Fatigue Check] Processing {len(request.sets_data)} sets, "
        f"current_weight={request.current_weight}kg, "
        f"exercise_type={request.exercise_type}"
    )

    try:
        # Convert Pydantic models to dicts for the service function
        sets_data = [
            {
                "reps": s.reps,
                "weight": s.weight,
                "rpe": s.rpe,
                "rir": s.rir,
                "is_failure": s.is_failure,
                "target_reps": s.target_reps,
            }
            for s in request.sets_data
        ]

        # Call the detection function
        alert: FatigueAlert = detect_fatigue(
            session_sets=sets_data,
            current_weight=request.current_weight,
            exercise_type=request.exercise_type,
            target_reps=request.target_reps,
        )

        logger.info(
            f"[Fatigue Check] Result: detected={alert.fatigue_detected}, "
            f"severity={alert.severity}, reduction={alert.suggested_weight_reduction}%"
        )

        return FatigueCheckResponse(
            fatigue_detected=alert.fatigue_detected,
            severity=alert.severity,
            suggested_weight_reduction=alert.suggested_weight_reduction,
            suggested_weight=alert.suggested_weight_kg,
            reasoning=alert.reasoning,
            indicators=alert.indicators,
            confidence=alert.confidence,
        )

    except Exception as e:
        logger.error(f"[Fatigue Check] Error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process fatigue check: {str(e)}"
        )


@router.post(
    "/next-set-preview",
    response_model=NextSetPreviewResponse,
    summary="Get AI-recommended next set parameters",
    description="""
    Provides AI-recommended weight and reps for the upcoming set
    based on current performance, 1RM data, and target intensity.

    **How it works:**
    1. Analyzes performance in completed sets (RPE, RIR, rep achievement)
    2. Estimates 1RM using Brzycki formula if not provided
    3. Calculates optimal weight for target intensity
    4. Adjusts based on fatigue and set progression

    **Use cases:**
    - Show during rest periods between sets
    - Help users make informed weight adjustments
    - Guide beginners with appropriate progression

    **Weight rounding:**
    Recommendations are rounded to nearest 2.5kg for practical gym use.
    """,
    tags=["Fatigue Detection"],
)
async def get_next_set_preview(
    request: NextSetPreviewRequest
) -> NextSetPreviewResponse:
    """
    Get AI-recommended parameters for the next set.

    This endpoint is designed to be called during rest periods
    to provide guidance on weight/rep adjustments.
    """
    logger.info(
        f"[Next Set Preview] Set {request.current_set_number}/{request.total_sets}, "
        f"current_weight={request.current_weight}kg, "
        f"target_reps={request.target_reps}"
    )

    try:
        # Convert Pydantic models to dicts
        sets_data = [
            {
                "reps": s.reps,
                "weight": s.weight,
                "rpe": s.rpe,
                "rir": s.rir,
                "is_failure": s.is_failure,
                "target_reps": s.target_reps,
            }
            for s in request.sets_data
        ]

        # Calculate preview
        preview: NextSetPreview = calculate_next_set_preview(
            session_sets=sets_data,
            current_set_number=request.current_set_number,
            total_sets=request.total_sets,
            target_reps=request.target_reps,
            current_weight=request.current_weight,
            estimated_1rm=request.estimated_1rm,
            target_intensity=request.target_intensity,
        )

        logger.info(
            f"[Next Set Preview] Recommendation: {preview.recommended_weight}kg x "
            f"{preview.recommended_reps} reps ({preview.intensity_percentage:.1f}% intensity)"
        )

        return NextSetPreviewResponse(
            recommended_weight=preview.recommended_weight,
            recommended_reps=preview.recommended_reps,
            intensity_percentage=preview.intensity_percentage,
            reasoning=preview.reasoning,
            confidence=preview.confidence,
            is_final_set=preview.is_final_set,
        )

    except Exception as e:
        logger.error(f"[Next Set Preview] Error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to calculate next set preview: {str(e)}"
        )


@router.post(
    "/fatigue-check-with-preview",
    summary="Combined fatigue check and next set preview",
    description="""
    Combines fatigue detection and next set preview in a single call.

    This is more efficient when you need both pieces of information
    after completing a set. The next set preview will incorporate
    the fatigue analysis to provide adjusted recommendations.
    """,
    tags=["Fatigue Detection"],
)
async def check_fatigue_with_preview(
    request: FatigueCheckRequest,
    current_set_number: int = 1,
    total_sets: int = 4,
):
    """
    Combined endpoint for fatigue check and next set preview.

    Returns both fatigue analysis and adjusted next set recommendations.
    """
    logger.info(
        f"[Combined Check] Set {current_set_number}/{total_sets}, "
        f"{len(request.sets_data)} sets completed"
    )

    try:
        # Convert to dicts
        sets_data = [
            {
                "reps": s.reps,
                "weight": s.weight,
                "rpe": s.rpe,
                "rir": s.rir,
                "is_failure": s.is_failure,
                "target_reps": s.target_reps,
            }
            for s in request.sets_data
        ]

        # Get fatigue analysis
        alert: FatigueAlert = detect_fatigue(
            session_sets=sets_data,
            current_weight=request.current_weight,
            exercise_type=request.exercise_type,
            target_reps=request.target_reps,
        )

        # Calculate next set preview
        # If fatigue detected, use suggested weight as basis
        preview_weight = (
            alert.suggested_weight_kg if alert.fatigue_detected
            else request.current_weight
        )

        preview: NextSetPreview = calculate_next_set_preview(
            session_sets=sets_data,
            current_set_number=current_set_number,
            total_sets=total_sets,
            target_reps=request.target_reps or 10,
            current_weight=preview_weight,
        )

        # If fatigue was detected, override preview weight with fatigue suggestion
        if alert.fatigue_detected:
            preview = NextSetPreview(
                recommended_weight=alert.suggested_weight_kg,
                recommended_reps=preview.recommended_reps,
                intensity_percentage=preview.intensity_percentage,
                reasoning=f"Fatigue detected: {alert.reasoning}",
                confidence=max(alert.confidence, preview.confidence),
                is_final_set=preview.is_final_set,
            )

        return {
            "fatigue": {
                "detected": alert.fatigue_detected,
                "severity": alert.severity,
                "suggested_weight_reduction": alert.suggested_weight_reduction,
                "suggested_weight": alert.suggested_weight_kg,
                "reasoning": alert.reasoning,
                "indicators": alert.indicators,
                "confidence": alert.confidence,
            },
            "next_set": preview.to_dict(),
        }

    except Exception as e:
        logger.error(f"[Combined Check] Error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process combined check: {str(e)}"
        )
