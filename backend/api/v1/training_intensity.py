"""
Training Intensity API - Percentage-based 1RM training endpoints.

Endpoints for:
- Managing user 1RMs (manual, calculated, tested)
- Setting global training intensity (50-100%)
- Setting per-exercise intensity overrides
- Calculating working weights
- Auto-populating 1RMs from workout history
"""
from typing import Dict, List, Optional
from datetime import datetime
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
import logging

from core.supabase_client import get_supabase
from services.percentage_training_service import PercentageTrainingService


def get_supabase_client():
    """Get the Supabase client for database operations."""
    return get_supabase().client

logger = logging.getLogger(__name__)
router = APIRouter()


# -------------------------------------------------------------------------
# Request/Response Models
# -------------------------------------------------------------------------

class Set1RMRequest(BaseModel):
    """Request to set a user's 1RM for an exercise."""
    user_id: str
    exercise_name: str
    one_rep_max_kg: float = Field(..., ge=0.5, le=1000)
    source: str = Field(default='manual', pattern='^(manual|calculated|tested)$')
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    last_tested_at: Optional[datetime] = None


class UserExercise1RMResponse(BaseModel):
    """Response containing a user's 1RM."""
    exercise_name: str
    one_rep_max_kg: float
    source: str
    confidence: float
    last_tested_at: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]


class SetIntensityRequest(BaseModel):
    """Request to set training intensity."""
    user_id: str
    intensity_percent: int = Field(..., ge=50, le=100)


class SetExerciseIntensityRequest(BaseModel):
    """Request to set per-exercise intensity override."""
    user_id: str
    exercise_name: str
    intensity_percent: int = Field(..., ge=50, le=100)


class IntensityResponse(BaseModel):
    """Response containing intensity settings."""
    intensity_percent: int
    description: str


class IntensitySettingsResponse(BaseModel):
    """Full intensity settings for a user."""
    global_intensity_percent: int
    global_description: str
    exercise_overrides: Dict[str, int]


class CalculateWeightRequest(BaseModel):
    """Request to calculate working weight."""
    one_rep_max_kg: float = Field(..., ge=0.5, le=1000)
    intensity_percent: int = Field(..., ge=50, le=100)
    equipment_type: str = Field(default='barbell')


class WorkingWeightResponse(BaseModel):
    """Response with calculated working weight."""
    one_rep_max_kg: float
    intensity_percent: int
    working_weight_kg: float
    equipment_type: str
    description: str


class AutoPopulateResponse(BaseModel):
    """Response from auto-populate operation."""
    count: int
    message: str


class BulkWorkingWeightsRequest(BaseModel):
    """Request to calculate working weights for multiple exercises."""
    user_id: str
    exercises: List[str]
    equipment_types: Optional[Dict[str, str]] = None


class ExerciseWorkingWeight(BaseModel):
    """Working weight for a single exercise."""
    exercise_name: str
    one_rep_max_kg: float
    intensity_percent: int
    working_weight_kg: float
    is_from_override: bool


# -------------------------------------------------------------------------
# 1RM Endpoints
# -------------------------------------------------------------------------

@router.post("/training/1rm", response_model=UserExercise1RMResponse)
async def set_user_1rm(request: Set1RMRequest):
    """
    Set or update a user's 1RM for an exercise.

    The source can be:
    - 'manual': User entered the value manually
    - 'calculated': Estimated from workout performance
    - 'tested': User performed an actual 1RM test
    """
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        result = await service.set_user_1rm(
            user_id=request.user_id,
            exercise_name=request.exercise_name,
            one_rep_max_kg=request.one_rep_max_kg,
            source=request.source,
            confidence=request.confidence,
            last_tested_at=request.last_tested_at,
        )

        return UserExercise1RMResponse(
            exercise_name=result.exercise_name,
            one_rep_max_kg=result.one_rep_max_kg,
            source=result.source,
            confidence=result.confidence,
            last_tested_at=str(result.last_tested_at) if result.last_tested_at else None,
            created_at=str(result.created_at) if result.created_at else None,
            updated_at=str(result.updated_at) if result.updated_at else None,
        )
    except Exception as e:
        logger.error(f"Error setting 1RM: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/training/1rm/{user_id}", response_model=List[UserExercise1RMResponse])
async def get_user_1rms(user_id: str):
    """Get all stored 1RMs for a user."""
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        results = await service.get_user_1rms(user_id)

        return [
            UserExercise1RMResponse(
                exercise_name=r.exercise_name,
                one_rep_max_kg=r.one_rep_max_kg,
                source=r.source,
                confidence=r.confidence,
                last_tested_at=str(r.last_tested_at) if r.last_tested_at else None,
                created_at=str(r.created_at) if r.created_at else None,
                updated_at=str(r.updated_at) if r.updated_at else None,
            )
            for r in results
        ]
    except Exception as e:
        logger.error(f"Error getting 1RMs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/training/1rm/{user_id}/{exercise_name}", response_model=Optional[UserExercise1RMResponse])
async def get_user_1rm(user_id: str, exercise_name: str):
    """Get stored 1RM for a specific exercise."""
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        result = await service.get_user_1rm(user_id, exercise_name)

        if not result:
            return None

        return UserExercise1RMResponse(
            exercise_name=result.exercise_name,
            one_rep_max_kg=result.one_rep_max_kg,
            source=result.source,
            confidence=result.confidence,
            last_tested_at=str(result.last_tested_at) if result.last_tested_at else None,
            created_at=str(result.created_at) if result.created_at else None,
            updated_at=str(result.updated_at) if result.updated_at else None,
        )
    except Exception as e:
        logger.error(f"Error getting 1RM: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/training/1rm/{user_id}/{exercise_name}")
async def delete_user_1rm(user_id: str, exercise_name: str):
    """Delete a stored 1RM for an exercise."""
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        await service.delete_user_1rm(user_id, exercise_name)

        return {"message": f"Deleted 1RM for {exercise_name}"}
    except Exception as e:
        logger.error(f"Error deleting 1RM: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------------------
# Training Intensity Endpoints
# -------------------------------------------------------------------------

@router.post("/training/intensity", response_model=IntensityResponse)
async def set_global_intensity(request: SetIntensityRequest):
    """
    Set user's global training intensity (percentage of 1RM).

    Values range from 50% (light/recovery) to 100% (max effort).
    Typical ranges:
    - 50-60%: Light / Recovery
    - 65-75%: Moderate / Hypertrophy
    - 75-85%: Working weight
    - 85-95%: Heavy / Strength
    - 95-100%: Near max
    """
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        intensity = await service.set_global_training_intensity(
            user_id=request.user_id,
            intensity_percent=request.intensity_percent,
        )

        description = service.get_intensity_description(intensity)

        return IntensityResponse(
            intensity_percent=intensity,
            description=description,
        )
    except Exception as e:
        logger.error(f"Error setting intensity: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/training/intensity/{user_id}", response_model=IntensitySettingsResponse)
async def get_intensity_settings(user_id: str):
    """Get user's complete intensity settings including overrides."""
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        global_intensity = await service.get_training_intensity(user_id)
        overrides = await service.get_all_intensity_overrides(user_id)
        description = service.get_intensity_description(global_intensity)

        return IntensitySettingsResponse(
            global_intensity_percent=global_intensity,
            global_description=description,
            exercise_overrides=overrides,
        )
    except Exception as e:
        logger.error(f"Error getting intensity settings: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/training/intensity/exercise", response_model=IntensityResponse)
async def set_exercise_intensity_override(request: SetExerciseIntensityRequest):
    """Set per-exercise intensity override."""
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        intensity = await service.set_exercise_intensity_override(
            user_id=request.user_id,
            exercise_name=request.exercise_name,
            intensity_percent=request.intensity_percent,
        )

        description = service.get_intensity_description(intensity)

        return IntensityResponse(
            intensity_percent=intensity,
            description=description,
        )
    except Exception as e:
        logger.error(f"Error setting exercise intensity: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/training/intensity/exercise/{user_id}/{exercise_name}")
async def delete_exercise_intensity_override(user_id: str, exercise_name: str):
    """Remove per-exercise intensity override (reverts to global setting)."""
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        await service.delete_exercise_intensity_override(user_id, exercise_name)

        return {"message": f"Removed intensity override for {exercise_name}"}
    except Exception as e:
        logger.error(f"Error deleting exercise intensity: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------------------
# Working Weight Calculation Endpoints
# -------------------------------------------------------------------------

@router.post("/training/calculate-weight", response_model=WorkingWeightResponse)
async def calculate_working_weight(request: CalculateWeightRequest):
    """
    Calculate working weight from 1RM and intensity percentage.

    The weight is rounded to the nearest equipment increment:
    - Barbell: 2.5 kg
    - Dumbbell: 2.0 kg
    - Machine: 5.0 kg
    - Cable: 2.5 kg
    - Kettlebell: 4.0 kg
    """
    try:
        service = PercentageTrainingService()

        working_weight = service.calculate_working_weight(
            one_rep_max_kg=request.one_rep_max_kg,
            intensity_percent=request.intensity_percent,
            equipment_type=request.equipment_type,
        )

        description = service.get_intensity_description(request.intensity_percent)

        return WorkingWeightResponse(
            one_rep_max_kg=request.one_rep_max_kg,
            intensity_percent=request.intensity_percent,
            working_weight_kg=working_weight,
            equipment_type=request.equipment_type,
            description=description,
        )
    except Exception as e:
        logger.error(f"Error calculating working weight: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/training/workout-weights", response_model=List[ExerciseWorkingWeight])
async def calculate_workout_weights(request: BulkWorkingWeightsRequest):
    """
    Calculate working weights for all exercises in a workout.

    Returns working weights for exercises where the user has stored 1RMs.
    Uses per-exercise intensity overrides where set, otherwise global intensity.
    """
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        results = await service.calculate_working_weights_for_workout(
            user_id=request.user_id,
            exercises=request.exercises,
            equipment_types=request.equipment_types,
        )

        return [
            ExerciseWorkingWeight(
                exercise_name=r.exercise_name,
                one_rep_max_kg=r.one_rep_max_kg,
                intensity_percent=r.intensity_percent,
                working_weight_kg=r.working_weight_kg,
                is_from_override=r.is_from_override,
            )
            for r in results
        ]
    except Exception as e:
        logger.error(f"Error calculating workout weights: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------------------
# Auto-Populate Endpoints
# -------------------------------------------------------------------------

@router.post("/training/auto-populate/{user_id}", response_model=AutoPopulateResponse)
async def auto_populate_1rms(
    user_id: str,
    days_lookback: int = Query(default=90, ge=7, le=365),
    min_confidence: float = Query(default=0.7, ge=0.5, le=1.0),
):
    """
    Auto-calculate 1RMs from workout history.

    Analyzes completed workout sets and estimates 1RM using
    the Brzycki formula. Only saves estimates with confidence
    above the threshold.

    Args:
        user_id: User ID
        days_lookback: How far back to look in workout history (default: 90 days)
        min_confidence: Minimum confidence threshold to save (default: 0.7)

    Returns:
        Number of 1RMs calculated and saved
    """
    try:
        supabase = get_supabase_client()
        service = PercentageTrainingService(supabase)

        count = await service.auto_populate_1rms(
            user_id=user_id,
            days_lookback=days_lookback,
            min_confidence=min_confidence,
        )

        if count > 0:
            message = f"Successfully calculated and saved {count} 1RMs from your workout history"
        else:
            message = "No 1RMs could be calculated. Try completing more workouts with tracked weights."

        return AutoPopulateResponse(
            count=count,
            message=message,
        )
    except Exception as e:
        logger.error(f"Error auto-populating 1RMs: {e}")
        raise HTTPException(status_code=500, detail=str(e))
