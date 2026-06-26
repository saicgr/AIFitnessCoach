"""Secondary endpoints for exercise_progressions.  Sub-router included by main module.
Exercise Progressions API - Skill-based exercise progressions for adaptive difficulty.

This module provides endpoints to:
1. Track exercise mastery levels based on user feedback
2. Suggest progression to harder variants when exercises become too easy
3. Manage progression chains (e.g., Wall Pushups -> Standard Pushups -> One-Arm Pushups)
4. Allow users to customize rep range preferences and progression style

Aligned to the REAL deployed schema:
  - exercise_progression_chains / exercise_progression_steps (migration 081)
  - user_exercise_mastery (migration 089_exercise_progression_mastery)
  - user_rep_range_preferences (deployed columns: preference_type, min_reps, max_reps,
                                min_sets_per_exercise, max_sets_per_exercise,
                                enforce_rep_ceiling). NOTE: this table has NO
                                training_focus / progression_style / avoid_high_reps
                                columns — those parts of the API response are derived
                                and not persisted.
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
    ProgressionType,
    ChainCategory,
    ProgressionStep,
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

# Default rep ranges per training focus. training_focus is not a stored column on
# user_rep_range_preferences, so it is inferred from the stored rep range on read.
_FOCUS_DEFAULT_RANGE = {
    TrainingFocus.STRENGTH: (3, 5),
    TrainingFocus.HYPERTROPHY: (6, 12),
    TrainingFocus.ENDURANCE: (12, 20),
    TrainingFocus.MIXED: (6, 15),
}


def _infer_training_focus(min_reps: int, max_reps: int) -> TrainingFocus:
    """Infer training focus from a stored rep range (no training_focus column exists)."""
    if max_reps <= 5:
        return TrainingFocus.STRENGTH
    if min_reps >= 12:
        return TrainingFocus.ENDURANCE
    if min_reps <= 6 and max_reps <= 12:
        return TrainingFocus.HYPERTROPHY
    return TrainingFocus.MIXED


def _focus_description(training_focus: TrainingFocus, avoid_high_reps: bool) -> str:
    """Build a human-readable description of a training focus."""
    if training_focus == TrainingFocus.STRENGTH:
        description = "Strength focus: Lower reps (1-5) with heavier weights"
    elif training_focus == TrainingFocus.HYPERTROPHY:
        description = "Hypertrophy focus: Moderate reps (6-12) for muscle growth"
    elif training_focus == TrainingFocus.ENDURANCE:
        description = "Endurance focus: Higher reps (12-20+) for muscular endurance"
    else:
        description = "Mixed training: Varied rep ranges across workouts"
    if avoid_high_reps:
        description += ". Avoiding high rep sets."
    return description


@router.get("/user/{user_id}/rep-preferences", response_model=RepPreferencesResponse)
async def get_rep_preferences(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get user's rep range preferences and training focus.

    Reads user_rep_range_preferences. training_focus and progression_style are not
    stored columns — training_focus is inferred from the stored rep range and
    progression_style falls back to the MODERATE default.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting rep preferences for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("user_rep_range_preferences").select("*").eq(
            "user_id", user_id
        ).execute()

        if result.data:
            prefs = result.data[0]
            min_reps = prefs.get("min_reps", 6) or 6
            max_reps = prefs.get("max_reps", 12) or 12
            avoid_high = bool(prefs.get("enforce_rep_ceiling", False))
            training_focus = _infer_training_focus(min_reps, max_reps)
            # progression_style is not persisted on this table — use the default.
            progression_style = ProgressionStyle.MODERATE
        else:
            # Return defaults
            training_focus = TrainingFocus.HYPERTROPHY
            min_reps = 6
            max_reps = 12
            avoid_high = False
            progression_style = ProgressionStyle.MODERATE

        return RepPreferencesResponse(
            training_focus=training_focus,
            preferred_min_reps=min_reps,
            preferred_max_reps=max_reps,
            avoid_high_reps=avoid_high,
            progression_style=progression_style,
            description=_focus_description(training_focus, avoid_high),
        )

    except Exception as e:
        logger.error(f"Failed to get rep preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_progressions")


@router.put("/user/{user_id}/rep-preferences", response_model=RepPreferencesResponse)
async def update_rep_preferences(user_id: str, request: RepPreferences, current_user: dict = Depends(get_current_user)):
    """
    Update user's rep range preferences.

    Persists to user_rep_range_preferences. Only the columns that exist on the real
    table are written: preference_type, min_reps, max_reps, enforce_rep_ceiling.
    training_focus is stored indirectly via preference_type; progression_style is
    accepted in the request for API compatibility but not persisted.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating rep preferences for user {user_id}: {request.training_focus}")

    try:
        db = get_supabase_db()
        now = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing = db.client.table("user_rep_range_preferences").select("id").eq(
            "user_id", user_id
        ).execute()

        # Only columns that exist on user_rep_range_preferences.
        prefs_data = {
            "preference_type": request.training_focus.value,
            "min_reps": request.preferred_min_reps,
            "max_reps": request.preferred_max_reps,
            "enforce_rep_ceiling": request.avoid_high_reps,
            "updated_at": now,
        }

        if existing.data:
            # Update existing
            db.client.table("user_rep_range_preferences").update(prefs_data).eq(
                "id", existing.data[0]["id"]
            ).execute()
        else:
            # Insert new
            prefs_data["id"] = str(uuid.uuid4())
            prefs_data["user_id"] = user_id
            prefs_data["created_at"] = now
            db.client.table("user_rep_range_preferences").insert(prefs_data).execute()

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

        return RepPreferencesResponse(
            training_focus=request.training_focus,
            preferred_min_reps=request.preferred_min_reps,
            preferred_max_reps=request.preferred_max_reps,
            avoid_high_reps=request.avoid_high_reps,
            progression_style=request.progression_style,
            description=_focus_description(request.training_focus, request.avoid_high_reps),
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


@router.get("/user/{user_id}/hold-history/{exercise_name}")
async def get_hold_history(
    user_id: str,
    exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
    """Per-session best-hold time-series for a timed skill (Dr-Yaad audit #11).

    Drives the hold-time history chart on the progressions screen — "planche
    10s→14s, plan to 16s by deload". Reads `best_time_seconds` per session from
    `exercise_performance_summary` (already populated on every workout
    completion). Returns the points + the next unlock target (min_hold_seconds)
    when the exercise sits in a progression chain, so the chart can draw a goal
    line. Empty `points` is a normal first-timer state, not an error.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    db = get_supabase_db()
    try:
        rows = (
            db.client.table("exercise_performance_summary")
            .select("best_time_seconds, performed_at")
            .eq("user_id", user_id)
            .ilike("exercise_name", f"%{exercise_name.lower()}%")
            .not_.is_("best_time_seconds", "null")
            .order("performed_at", desc=False)
            .limit(60)
            .execute()
        ).data or []
    except Exception as e:  # pragma: no cover - defensive
        raise safe_internal_error(e, "hold_history")

    points = [
        {
            "performed_at": r.get("performed_at"),
            "best_hold_seconds": int(r["best_time_seconds"]),
        }
        for r in rows
        if r.get("best_time_seconds") is not None and r.get("performed_at")
    ]

    # Next unlock target (min_hold_seconds) from the progression chain, if any.
    target_hold_seconds: Optional[int] = None
    try:
        _check, get_next_variant, _parse = _progressions_parent()
        nv = await get_next_variant(exercise_name)
        if nv and isinstance(nv.get("step"), dict):
            crit = nv["step"].get("unlock_criteria") or {}
            mh = crit.get("min_hold_seconds")
            if mh:
                target_hold_seconds = int(mh)
    except Exception:
        target_hold_seconds = None

    return {
        "exercise_name": exercise_name,
        "points": points,
        "current_best_hold_seconds": points[-1]["best_hold_seconds"] if points else None,
        "target_hold_seconds": target_hold_seconds,
    }


@router.get("/next-variant/{exercise_name}")
async def get_next_variant_endpoint(exercise_name: str, current_user: dict = Depends(get_current_user)):
    """
    Get the next harder variant for an exercise.

    Returns step info or a not-found marker if the exercise is not in a chain.
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
        "next_step": result["step"],
        "chain_id": result["chain_id"],
        "chain_name": result["chain_name"],
    }


@router.get("/chain-types")
async def get_chain_types(current_user: dict = Depends(get_current_user)):
    """Get all available progression types with descriptions."""
    return {
        "chain_types": [
            {
                "type": ProgressionType.LEVERAGE.value,
                "name": "Leverage",
                "description": "Progressions based on body position (e.g., incline to flat to decline)",
            },
            {
                "type": ProgressionType.LOAD.value,
                "name": "Load",
                "description": "Progressions based on weight or resistance (e.g., bodyweight to weighted)",
            },
            {
                "type": ProgressionType.STABILITY.value,
                "name": "Stability",
                "description": "Progressions based on stability challenges (e.g., bilateral to unilateral)",
            },
            {
                "type": ProgressionType.RANGE.value,
                "name": "Range of Motion",
                "description": "Progressions based on movement range (e.g., partial to full ROM)",
            },
            {
                "type": ProgressionType.TEMPO.value,
                "name": "Tempo",
                "description": "Progressions based on speed/time under tension",
            },
        ]
    }


@router.get("/categories")
async def get_chain_categories(current_user: dict = Depends(get_current_user)):
    """Get all progression chain categories actually present in the database.

    Replaces the old /muscle-groups endpoint — exercise_progression_chains is
    categorised by skill movement (pushup, pullup, squat, ...), not muscle group.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("exercise_progression_chains").select("category").execute()
        categories = sorted({
            row["category"] for row in (result.data or []) if row.get("category")
        })
        return {"categories": categories}
    except Exception as e:
        logger.error(f"Failed to get chain categories: {e}", exc_info=True)
        # Fall back to the known enum values if the query fails.
        return {"categories": [c.value for c in ChainCategory]}


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
        result = db.client.table("user_exercise_mastery").select("*").eq(
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
        result = db.client.table("user_exercise_mastery").select(
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
        result = db.client.table("user_exercise_mastery").select(
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
        result = db.client.table("user_rep_range_preferences").select(
            "min_reps, max_reps"
        ).eq("user_id", user_id).execute()

        if result.data:
            return (
                result.data[0].get("min_reps", 6) or 6,
                result.data[0].get("max_reps", 12) or 12
            )
        return (6, 12)  # Default hypertrophy range
    except Exception as e:
        logger.error(f"Error getting user rep range: {e}", exc_info=True)
        return (6, 12)
