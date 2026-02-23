"""
Smart Weight Auto-Fill API.

Provides intelligent weight suggestions for exercises based on:
- User's 1RM (one-rep max) from strength_records table
- Target intensity for training goal (hypertrophy, strength, endurance)
- Performance modifier from last session (RPE-based adjustments)
- Equipment-aware rounding (2.5kg for dumbbells, 5kg for machines)

This is a pre-workout weight suggestion (auto-fill), distinct from the
real-time weight_suggestions.py which provides intra-workout adjustments.
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import Optional, List
from datetime import datetime, timedelta
from pydantic import BaseModel
from enum import Enum

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.strength_calculator_service import StrengthCalculatorService

router = APIRouter()
logger = get_logger(__name__)

# Initialize strength calculator service
strength_calculator = StrengthCalculatorService()


class TrainingGoal(str, Enum):
    """Training goal determines target intensity percentage."""
    STRENGTH = "strength"  # 85-95% 1RM, 1-5 reps
    HYPERTROPHY = "hypertrophy"  # 65-80% 1RM, 8-12 reps
    ENDURANCE = "endurance"  # 50-65% 1RM, 15-20+ reps
    POWER = "power"  # 70-85% 1RM, 3-6 reps (explosive)


# Target intensity percentages by goal
GOAL_INTENSITY_RANGES = {
    TrainingGoal.STRENGTH: (0.85, 0.95),
    TrainingGoal.HYPERTROPHY: (0.65, 0.80),
    TrainingGoal.ENDURANCE: (0.50, 0.65),
    TrainingGoal.POWER: (0.70, 0.85),
}

# Default target intensity (hypertrophy focused)
DEFAULT_INTENSITY = 0.75

# Equipment-aware rounding increments
EQUIPMENT_INCREMENTS = {
    "dumbbell": 2.5,
    "dumbbells": 2.5,
    "barbell": 2.5,
    "machine": 5.0,
    "cable": 2.5,
    "kettlebell": 4.0,
    "smith_machine": 2.5,
    "ez_bar": 2.5,
    "bodyweight": 0,  # No weight suggestion for bodyweight
}


class LastSessionData(BaseModel):
    """Data from the user's last session with this exercise."""
    weight_kg: float
    reps: int
    rpe: Optional[int] = None
    rir: Optional[int] = None
    date: str
    workout_id: Optional[str] = None


class SmartWeightResponse(BaseModel):
    """Response model for smart weight suggestion."""
    suggested_weight: float
    reasoning: str
    confidence: float  # 0.0 - 1.0
    last_session_data: Optional[LastSessionData] = None
    one_rm_kg: Optional[float] = None
    target_intensity: float
    training_goal: str
    equipment_increment: float
    performance_modifier: float  # 1.0 = no change, >1 = increase, <1 = decrease


class RPEEstimate(BaseModel):
    """Estimated RPE from reps and percentage of 1RM."""
    estimated_rpe: float
    confidence: float
    description: str


def get_equipment_increment(equipment: str) -> float:
    """Get the appropriate weight increment for equipment type."""
    equipment_lower = equipment.lower().strip()

    for key, increment in EQUIPMENT_INCREMENTS.items():
        if key in equipment_lower:
            return increment

    return 2.5  # Default increment


def round_to_increment(weight: float, increment: float) -> float:
    """Round weight to the nearest equipment increment."""
    if increment <= 0:
        return weight
    return round(weight / increment) * increment


def calculate_performance_modifier(
    last_rpe: Optional[int],
    last_rir: Optional[int],
    last_reps: int,
    target_reps: int,
) -> float:
    """
    Calculate a performance modifier based on last session data.

    Returns a multiplier:
    - > 1.0: Increase weight (last session was too easy)
    - 1.0: Maintain weight
    - < 1.0: Decrease weight (last session was too hard)
    """
    # Convert RIR to RPE if needed
    effective_rpe = None
    if last_rpe is not None:
        effective_rpe = last_rpe
    elif last_rir is not None:
        effective_rpe = 10 - last_rir

    # Calculate rep completion ratio
    rep_ratio = last_reps / target_reps if target_reps > 0 else 1.0

    if effective_rpe is None:
        # No intensity data - check rep completion only
        if rep_ratio >= 1.2:  # Did 20%+ more reps than target
            return 1.05  # Increase 5%
        elif rep_ratio < 0.8:  # Did less than 80% of target
            return 0.95  # Decrease 5%
        return 1.0

    # RPE-based adjustment
    # Target working RPE is typically 7-8 for hypertrophy
    TARGET_RPE = 8.0

    rpe_diff = TARGET_RPE - effective_rpe

    # Each RPE point translates to roughly 3-5% weight adjustment
    if rpe_diff >= 2:  # RPE was 6 or lower (too easy)
        return 1.05  # Increase 5%
    elif rpe_diff >= 1:  # RPE was 7 (slightly easy)
        return 1.025  # Increase 2.5%
    elif rpe_diff <= -2:  # RPE was 10 (too hard)
        return 0.95  # Decrease 5%
    elif rpe_diff <= -1:  # RPE was 9 (slightly hard)
        return 0.975  # Decrease 2.5%

    # Also consider rep completion
    if rep_ratio < 0.9 and effective_rpe >= 9:
        return 0.92  # Decrease 8% if failing to hit reps at high RPE

    return 1.0  # Maintain weight


async def get_user_1rm(
    user_id: str,
    exercise_id: Optional[str] = None,
    exercise_name: Optional[str] = None,
) -> Optional[float]:
    """
    Get user's estimated 1RM for an exercise from strength_records.

    Looks up the best estimated_1rm from the strength_records table.
    """
    try:
        db = get_supabase_db()

        # Query strength_records for this exercise
        query = db.client.table("strength_records").select(
            "estimated_1rm, weight_kg, reps, achieved_at"
        ).eq("user_id", user_id)

        if exercise_id:
            query = query.eq("exercise_id", exercise_id)
        elif exercise_name:
            # Case-insensitive search by name
            query = query.ilike("exercise_name", f"%{exercise_name}%")
        else:
            return None

        # Get recent records (last 90 days for 1RM relevance)
        ninety_days_ago = (datetime.now() - timedelta(days=90)).isoformat()
        query = query.gte("achieved_at", ninety_days_ago)
        query = query.order("estimated_1rm", desc=True)
        query = query.limit(1)

        result = query.execute()

        if result.data and len(result.data) > 0:
            return result.data[0].get("estimated_1rm")

        # If no recent 1RM, try to calculate from performance_logs
        return await estimate_1rm_from_performance(user_id, exercise_id, exercise_name)

    except Exception as e:
        logger.warning(f"Error fetching 1RM: {e}")
        return None


async def estimate_1rm_from_performance(
    user_id: str,
    exercise_id: Optional[str] = None,
    exercise_name: Optional[str] = None,
) -> Optional[float]:
    """
    Estimate 1RM from recent performance logs if no strength_records exist.
    """
    try:
        db = get_supabase_db()

        # Query performance_logs for recent sets
        query = db.client.table("performance_logs").select(
            "weight_kg, reps_completed, recorded_at"
        ).eq("user_id", user_id)

        if exercise_id:
            query = query.eq("exercise_id", exercise_id)
        elif exercise_name:
            query = query.ilike("exercise_name", f"%{exercise_name}%")
        else:
            return None

        # Get last 30 days of data
        thirty_days_ago = (datetime.now() - timedelta(days=30)).isoformat()
        query = query.gte("recorded_at", thirty_days_ago)
        query = query.order("weight_kg", desc=True)
        query = query.limit(10)

        result = query.execute()

        if not result.data or len(result.data) == 0:
            return None

        # Find the best estimated 1RM from performance logs
        best_1rm = 0.0
        for log in result.data:
            weight = log.get("weight_kg", 0)
            reps = log.get("reps_completed", 0)
            if weight > 0 and reps > 0:
                estimated = strength_calculator.calculate_1rm_average(weight, reps)
                best_1rm = max(best_1rm, estimated)

        return best_1rm if best_1rm > 0 else None

    except Exception as e:
        logger.warning(f"Error estimating 1RM from performance: {e}")
        return None


async def get_last_session_data(
    user_id: str,
    exercise_id: Optional[str] = None,
    exercise_name: Optional[str] = None,
) -> Optional[LastSessionData]:
    """
    Get the user's last session data for this exercise.

    Returns the most recent set data with weight, reps, and intensity.
    """
    try:
        db = get_supabase_db()

        # Query performance_logs for the most recent session
        query = db.client.table("performance_logs").select(
            "weight_kg, reps_completed, rpe, rir, recorded_at, workout_log_id"
        ).eq("user_id", user_id)

        if exercise_id:
            query = query.eq("exercise_id", exercise_id)
        elif exercise_name:
            query = query.ilike("exercise_name", f"%{exercise_name}%")
        else:
            return None

        query = query.order("recorded_at", desc=True)
        query = query.limit(1)

        result = query.execute()

        if result.data and len(result.data) > 0:
            row = result.data[0]
            return LastSessionData(
                weight_kg=row.get("weight_kg", 0),
                reps=row.get("reps_completed", 0),
                rpe=row.get("rpe"),
                rir=row.get("rir"),
                date=row.get("recorded_at", ""),
                workout_id=row.get("workout_log_id"),
            )

        return None

    except Exception as e:
        logger.warning(f"Error fetching last session data: {e}")
        return None


def get_target_intensity(
    goal: TrainingGoal,
    target_reps: int,
) -> float:
    """
    Calculate target intensity based on training goal and target reps.

    Uses standard rep-to-intensity mapping adjusted for goal.
    """
    min_intensity, max_intensity = GOAL_INTENSITY_RANGES.get(
        goal, GOAL_INTENSITY_RANGES[TrainingGoal.HYPERTROPHY]
    )

    # Adjust within range based on rep target
    # Lower reps = higher intensity within the range
    if goal == TrainingGoal.STRENGTH:
        # Strength: 1-5 reps
        if target_reps <= 2:
            return max_intensity  # 95%
        elif target_reps <= 3:
            return 0.90
        elif target_reps <= 4:
            return 0.87
        else:
            return min_intensity  # 85%

    elif goal == TrainingGoal.HYPERTROPHY:
        # Hypertrophy: 6-12 reps
        if target_reps <= 6:
            return max_intensity  # 80%
        elif target_reps <= 8:
            return 0.75
        elif target_reps <= 10:
            return 0.70
        else:
            return min_intensity  # 65%

    elif goal == TrainingGoal.ENDURANCE:
        # Endurance: 15-20+ reps
        if target_reps <= 15:
            return max_intensity  # 65%
        elif target_reps <= 18:
            return 0.58
        else:
            return min_intensity  # 50%

    elif goal == TrainingGoal.POWER:
        # Power: 3-6 reps (explosive)
        if target_reps <= 3:
            return max_intensity  # 85%
        elif target_reps <= 5:
            return 0.77
        else:
            return min_intensity  # 70%

    return DEFAULT_INTENSITY


@router.get("/smart-weight/{user_id}/{exercise_id}", response_model=SmartWeightResponse)
async def get_smart_weight(
    user_id: str,
    exercise_id: str,
    exercise_name: Optional[str] = None,
    target_reps: int = Query(default=10, ge=1, le=50),
    goal: TrainingGoal = Query(default=TrainingGoal.HYPERTROPHY),
    equipment: str = Query(default="dumbbell"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get smart weight suggestion for an exercise.

    This endpoint calculates an optimal starting weight based on:
    1. User's 1RM for this exercise
    2. Target reps and training goal (determines intensity %)
    3. Last session performance (RPE-based modifier)
    4. Equipment-aware rounding

    Used for pre-populating weight fields when starting a workout.
    """
    logger.info(
        f"Smart weight request: user={user_id}, exercise={exercise_id or exercise_name}, "
        f"reps={target_reps}, goal={goal}, equipment={equipment}"
    )

    try:
        # Get equipment increment
        equipment_increment = get_equipment_increment(equipment)

        # Handle bodyweight exercises
        if equipment_increment == 0:
            return SmartWeightResponse(
                suggested_weight=0,
                reasoning="Bodyweight exercise - no external weight needed.",
                confidence=1.0,
                last_session_data=None,
                one_rm_kg=None,
                target_intensity=0,
                training_goal=goal.value,
                equipment_increment=0,
                performance_modifier=1.0,
            )

        # Get user's 1RM
        one_rm = await get_user_1rm(user_id, exercise_id, exercise_name)

        # Get last session data
        last_session = await get_last_session_data(user_id, exercise_id, exercise_name)

        # Calculate target intensity
        target_intensity = get_target_intensity(goal, target_reps)

        # Calculate performance modifier from last session
        performance_modifier = 1.0
        if last_session:
            performance_modifier = calculate_performance_modifier(
                last_rpe=last_session.rpe,
                last_rir=last_session.rir,
                last_reps=last_session.reps,
                target_reps=target_reps,
            )

        # Calculate suggested weight
        confidence = 0.0
        reasoning = ""
        suggested_weight = 0.0

        if one_rm and one_rm > 0:
            # We have 1RM data - use percentage-based calculation
            base_weight = one_rm * target_intensity
            adjusted_weight = base_weight * performance_modifier
            suggested_weight = round_to_increment(adjusted_weight, equipment_increment)

            confidence = 0.85 if last_session else 0.70

            modifier_desc = ""
            if performance_modifier > 1.0:
                modifier_desc = f" Increased {(performance_modifier - 1) * 100:.0f}% based on easy last session."
            elif performance_modifier < 1.0:
                modifier_desc = f" Decreased {(1 - performance_modifier) * 100:.0f}% based on challenging last session."

            reasoning = (
                f"Based on your estimated 1RM of {one_rm:.1f}kg at {target_intensity * 100:.0f}% intensity "
                f"for {target_reps} reps ({goal.value} goal).{modifier_desc}"
            )

        elif last_session and last_session.weight_kg > 0:
            # No 1RM but we have last session data
            # Use last session weight with performance modifier
            adjusted_weight = last_session.weight_kg * performance_modifier
            suggested_weight = round_to_increment(adjusted_weight, equipment_increment)

            confidence = 0.60

            modifier_desc = ""
            if performance_modifier > 1.0:
                modifier_desc = " - suggesting slight increase based on performance."
            elif performance_modifier < 1.0:
                modifier_desc = " - suggesting slight decrease based on performance."

            reasoning = (
                f"Based on your last session ({last_session.weight_kg:.1f}kg x {last_session.reps} reps)"
                f"{modifier_desc} Track more sessions for 1RM-based suggestions."
            )

        else:
            # No data available
            suggested_weight = 0
            confidence = 0.0
            reasoning = (
                "No previous data for this exercise. "
                "Start with a comfortable weight and track your performance for future suggestions."
            )

        # Ensure weight is non-negative
        suggested_weight = max(0, suggested_weight)

        logger.info(
            f"Smart weight suggestion: {suggested_weight}kg "
            f"(1RM: {one_rm}kg, intensity: {target_intensity:.0%}, "
            f"modifier: {performance_modifier:.2f}, confidence: {confidence:.0%})"
        )

        return SmartWeightResponse(
            suggested_weight=suggested_weight,
            reasoning=reasoning,
            confidence=confidence,
            last_session_data=last_session,
            one_rm_kg=one_rm,
            target_intensity=target_intensity,
            training_goal=goal.value,
            equipment_increment=equipment_increment,
            performance_modifier=performance_modifier,
        )

    except Exception as e:
        logger.error(f"Smart weight calculation failed: {e}")
        raise safe_internal_error(e, "smart_weights")


@router.get("/smart-weight/by-name/{user_id}", response_model=SmartWeightResponse)
async def get_smart_weight_by_name(
    user_id: str,
    exercise_name: str = Query(..., description="Name of the exercise"),
    target_reps: int = Query(default=10, ge=1, le=50),
    goal: TrainingGoal = Query(default=TrainingGoal.HYPERTROPHY),
    equipment: str = Query(default="dumbbell"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get smart weight suggestion by exercise name (no exercise_id required).

    This is a convenience endpoint for cases where exercise_id is not available.
    Uses fuzzy matching on exercise name.
    """
    # Delegate to the main endpoint with exercise_name
    return await get_smart_weight(
        user_id=user_id,
        exercise_id="",  # Empty ID, will use name
        exercise_name=exercise_name,
        target_reps=target_reps,
        goal=goal,
        equipment=equipment,
    )
