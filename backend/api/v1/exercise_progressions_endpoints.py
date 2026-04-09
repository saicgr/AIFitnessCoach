"""Secondary endpoints for exercise_progressions.  Sub-router included by main module.
Exercise Progressions API - Leverage-based exercise progressions for adaptive difficulty.

This module provides endpoints to:
1. Track exercise mastery levels based on user feedback
2. Suggest progression to harder variants when exercises become too easy
3. Manage progression chains (e.g., Push-up -> Diamond Push-up -> Archer Push-up)
4. Allow users to customize rep range preferences and progression style

The key insight: Instead of just adding more reps when an exercise is too easy,
we suggest progressing to a harder variant (leverage-based progression).

Example chains:
- Push-up: Wall -> Incline -> Knee -> Standard -> Diamond -> Archer -> One-arm
- Row: Inverted Row (high) -> Inverted Row (low) -> Pull-up -> Weighted Pull-up
- Squat: Assisted -> Bodyweight -> Split -> Bulgarian -> Pistol
"""
from typing import List, Optional
from datetime import datetime
import uuid
from fastapi import APIRouter, Depends, HTTPException
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.activity_logger import log_user_activity


def _progressions_parent():
    """Lazy import to avoid circular dependency."""
    from .exercise_progressions import check_progression_readiness, get_next_variant, _parse_mastery
    return check_progression_readiness, get_next_variant, _parse_mastery


from .exercise_progressions_models import (
    TrainingFocus,
    ProgressionStyle,
    ChainType,
    MuscleGroup,
    ProgressionVariant,
    ProgressionChainResponse,
    ExerciseMastery,
    ProgressionSuggestion,
    UpdateMasteryRequest,
    UpdateMasteryResponse,
    AcceptProgressionRequest,
    AcceptProgressionResponse,
    RepPreferences,
    RepPreferencesResponse,
)

router = APIRouter()

@router.get("/user/{user_id}/rep-preferences", response_model=RepPreferencesResponse)
async def get_rep_preferences(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get user's rep range preferences and training focus.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting rep preferences for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("user_rep_preferences").select("*").eq(
            "user_id", user_id
        ).execute()

        if result.data:
            prefs = result.data[0]
            training_focus = TrainingFocus(prefs.get("training_focus", "hypertrophy"))
            min_reps = prefs.get("preferred_min_reps", 6)
            max_reps = prefs.get("preferred_max_reps", 12)
            avoid_high = prefs.get("avoid_high_reps", False)
            progression_style = ProgressionStyle(prefs.get("progression_style", "moderate"))
        else:
            # Return defaults
            training_focus = TrainingFocus.HYPERTROPHY
            min_reps = 6
            max_reps = 12
            avoid_high = False
            progression_style = ProgressionStyle.MODERATE

        # Generate description
        if training_focus == TrainingFocus.STRENGTH:
            description = "Strength focus: Lower reps (1-5) with heavier weights"
        elif training_focus == TrainingFocus.HYPERTROPHY:
            description = "Hypertrophy focus: Moderate reps (6-12) for muscle growth"
        elif training_focus == TrainingFocus.ENDURANCE:
            description = "Endurance focus: Higher reps (12-20+) for muscular endurance"
        else:
            description = "Mixed training: Varied rep ranges across workouts"

        if avoid_high:
            description += ". Avoiding high rep sets."

        return RepPreferencesResponse(
            training_focus=training_focus,
            preferred_min_reps=min_reps,
            preferred_max_reps=max_reps,
            avoid_high_reps=avoid_high,
            progression_style=progression_style,
            description=description,
        )

    except Exception as e:
        logger.error(f"Failed to get rep preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_progressions")


@router.put("/user/{user_id}/rep-preferences", response_model=RepPreferencesResponse)
async def update_rep_preferences(user_id: str, request: RepPreferences, current_user: dict = Depends(get_current_user)):
    """
    Update user's rep range preferences.

    This affects how the AI generates workouts:
    - training_focus: Determines overall rep range strategy
    - preferred_min_reps/max_reps: Custom rep range override
    - avoid_high_reps: Never prescribe sets above 15 reps
    - progression_style: How aggressively to suggest harder variants
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating rep preferences for user {user_id}: {request.training_focus}")

    try:
        db = get_supabase_db()
        now = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing = db.client.table("user_rep_preferences").select("id").eq(
            "user_id", user_id
        ).execute()

        prefs_data = {
            "training_focus": request.training_focus.value,
            "preferred_min_reps": request.preferred_min_reps,
            "preferred_max_reps": request.preferred_max_reps,
            "avoid_high_reps": request.avoid_high_reps,
            "progression_style": request.progression_style.value,
            "updated_at": now,
        }

        if existing.data:
            # Update existing
            db.client.table("user_rep_preferences").update(prefs_data).eq(
                "id", existing.data[0]["id"]
            ).execute()
        else:
            # Insert new
            prefs_data["id"] = str(uuid.uuid4())
            prefs_data["user_id"] = user_id
            prefs_data["created_at"] = now
            db.client.table("user_rep_preferences").insert(prefs_data).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="rep_preferences_updated",
            endpoint=f"/api/v1/exercise-progressions/user/{user_id}/rep-preferences",
            message=f"Updated rep preferences: {request.training_focus.value}",
            metadata={
                "training_focus": request.training_focus.value,
                "min_reps": request.preferred_min_reps,
                "max_reps": request.preferred_max_reps,
                "avoid_high_reps": request.avoid_high_reps,
                "progression_style": request.progression_style.value,
            },
            status_code=200
        )

        # Generate description
        if request.training_focus == TrainingFocus.STRENGTH:
            description = "Strength focus: Lower reps (1-5) with heavier weights"
        elif request.training_focus == TrainingFocus.HYPERTROPHY:
            description = "Hypertrophy focus: Moderate reps (6-12) for muscle growth"
        elif request.training_focus == TrainingFocus.ENDURANCE:
            description = "Endurance focus: Higher reps (12-20+) for muscular endurance"
        else:
            description = "Mixed training: Varied rep ranges across workouts"

        if request.avoid_high_reps:
            description += ". Avoiding high rep sets."

        return RepPreferencesResponse(
            training_focus=request.training_focus,
            preferred_min_reps=request.preferred_min_reps,
            preferred_max_reps=request.preferred_max_reps,
            avoid_high_reps=request.avoid_high_reps,
            progression_style=request.progression_style,
            description=description,
        )

    except Exception as e:
        logger.error(f"Failed to update rep preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_progressions")


# =============================================================================
# Utility Endpoints
# =============================================================================

@router.get("/user/{user_id}/check-readiness/{exercise_name}")
async def check_readiness_endpoint(user_id: str, exercise_name: str, current_user: dict = Depends(get_current_user)):
    """
    Check if user is ready to progress on a specific exercise.

    Returns readiness status with reason and suggested next variant.
    """
    check_progression_readiness, get_next_variant, _parse_mastery = _progressions_parent()
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Checking readiness for user {user_id}, exercise: {exercise_name}")

    result = await check_progression_readiness(user_id, exercise_name)
    return result


@router.get("/next-variant/{exercise_name}")
async def get_next_variant_endpoint(exercise_name: str, current_user: dict = Depends(get_current_user)):
    """
    Get the next harder variant for an exercise.

    Returns variant info or null if not in a progression chain.
    """
    check_progression_readiness, get_next_variant, _parse_mastery = _progressions_parent()
    logger.info(f"Getting next variant for: {exercise_name}")

    result = await get_next_variant(exercise_name)

    if result is None:
        return {
            "found": False,
            "message": f"{exercise_name} is not in a progression chain or is already the hardest variant",
        }

    return {
        "found": True,
        "current_exercise": exercise_name,
        "next_variant": result["variant"],
        "chain_id": result["chain_id"],
        "chain_name": result["chain_name"],
    }


@router.get("/chain-types")
async def get_chain_types(current_user: dict = Depends(get_current_user)):
    """Get all available progression chain types with descriptions."""
    return {
        "chain_types": [
            {
                "type": ChainType.LEVERAGE.value,
                "name": "Leverage",
                "description": "Progressions based on body position (e.g., incline to flat to decline)",
            },
            {
                "type": ChainType.LOAD.value,
                "name": "Load",
                "description": "Progressions based on weight or resistance (e.g., bodyweight to weighted)",
            },
            {
                "type": ChainType.STABILITY.value,
                "name": "Stability",
                "description": "Progressions based on stability challenges (e.g., bilateral to unilateral)",
            },
            {
                "type": ChainType.RANGE.value,
                "name": "Range of Motion",
                "description": "Progressions based on movement range (e.g., partial to full ROM)",
            },
            {
                "type": ChainType.TEMPO.value,
                "name": "Tempo",
                "description": "Progressions based on speed/time under tension",
            },
        ]
    }


@router.get("/muscle-groups")
async def get_muscle_groups(current_user: dict = Depends(get_current_user)):
    """Get all available muscle groups for filtering chains."""
    return {
        "muscle_groups": [mg.value for mg in MuscleGroup],
        "grouped": {
            "upper_body": [
                MuscleGroup.CHEST.value,
                MuscleGroup.BACK.value,
                MuscleGroup.SHOULDERS.value,
                MuscleGroup.BICEPS.value,
                MuscleGroup.TRICEPS.value,
            ],
            "lower_body": [
                MuscleGroup.QUADRICEPS.value,
                MuscleGroup.HAMSTRINGS.value,
                MuscleGroup.GLUTES.value,
                MuscleGroup.CALVES.value,
            ],
            "core": [MuscleGroup.CORE.value],
            "full_body": [MuscleGroup.FULL_BODY.value],
        }
    }


# =============================================================================
# Helper Functions for External Use
# =============================================================================

async def get_user_mastery_for_exercise(user_id: str, exercise_name: str) -> Optional[ExerciseMastery]:
    """
    Get mastery data for a specific exercise.
    Used by workout generation to consider mastery when selecting exercises.
    """
    check_progression_readiness, get_next_variant, _parse_mastery = _progressions_parent()
    try:
        db = get_supabase_db()
        result = db.client.table("exercise_mastery").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", exercise_name).execute()

        if result.data:
            return _parse_mastery(result.data[0])
        return None
    except Exception as e:
        logger.error(f"Error getting mastery for {exercise_name}: {e}", exc_info=True)
        return None


async def get_user_ready_progressions(user_id: str) -> List[str]:
    """
    Get list of exercise names the user is ready to progress on.
    Used by workout generation to suggest progressions.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("exercise_mastery").select(
            "exercise_name, suggested_next_variant"
        ).eq("user_id", user_id).eq("ready_for_progression", True).execute()

        return [
            row["suggested_next_variant"]
            for row in result.data or []
            if row.get("suggested_next_variant")
        ]
    except Exception as e:
        logger.error(f"Error getting ready progressions for user {user_id}: {e}", exc_info=True)
        return []


async def should_suggest_progression(user_id: str, exercise_name: str) -> bool:
    """
    Quick check if we should suggest a harder variant for this exercise.
    Used by workout generation to decide whether to auto-swap.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("exercise_mastery").select(
            "ready_for_progression"
        ).eq("user_id", user_id).eq("exercise_name", exercise_name).execute()

        if result.data:
            return result.data[0].get("ready_for_progression", False)
        return False
    except Exception as e:
        logger.error(f"Error checking progression suggestion: {e}", exc_info=True)
        return False


async def get_user_rep_range(user_id: str) -> tuple[int, int]:
    """
    Get user's preferred rep range.
    Used by workout generation to set appropriate rep counts.
    Returns (min_reps, max_reps) tuple.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("user_rep_preferences").select(
            "preferred_min_reps, preferred_max_reps"
        ).eq("user_id", user_id).execute()

        if result.data:
            return (
                result.data[0].get("preferred_min_reps", 6),
                result.data[0].get("preferred_max_reps", 12)
            )
        return (6, 12)  # Default hypertrophy range
    except Exception as e:
        logger.error(f"Error getting user rep range: {e}", exc_info=True)
        return (6, 12)
