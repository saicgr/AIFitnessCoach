"""Secondary endpoints for supersets.  Sub-router included by main module.
Supersets API - Superset preferences, manual pairing, and AI-suggested superset pairs.

This module allows users to:
1. Configure superset preferences (enable/disable, rest time, max pairs)
2. Create manual superset pairs within a workout
3. Remove superset pairs from a workout
4. Get AI-suggested superset pairs based on workout composition
5. Save favorite superset pairs for reuse
6. View superset usage history

Supersets pair two exercises back-to-back with minimal rest, typically:
- Antagonist pairs (chest/back, biceps/triceps, quads/hamstrings)
- Same muscle group (pre-exhaust or compound set)
- Upper/lower alternation

Benefits:
- Time efficiency (more work in less time)
- Increased metabolic demand
- Enhanced muscle pump
- Greater workout density
"""
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import json
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error


def _supersets_parent():
    """Lazy import to avoid circular dependency."""
    from .supersets import ANTAGONIST_PAIRS
    return ANTAGONIST_PAIRS


from .supersets_models import (
    SupersetPreferences,
    SupersetPreferencesUpdate,
    SupersetPreferencesResponse,
    CreateSupersetPairRequest,
    SupersetPairResponse,
    RemoveSupersetPairResponse,
    SupersetSuggestion,
    SupersetSuggestionsResponse,
    FavoriteSupersetPair,
    FavoriteSupersetPairResponse,
    SupersetHistoryEntry,
    SupersetHistoryResponse,
    SupersetLogRequest,
)

router = APIRouter()

@router.post("/favorites", response_model=FavoriteSupersetPairResponse)
async def save_favorite_superset_pair(user_id: str = Query(...), request: FavoriteSupersetPair = ...,
    current_user: dict = Depends(get_current_user),
):
    """
    Save a favorite superset pair for reuse.

    Favorite pairs can be quickly applied to future workouts.
    """
    logger.info(f"Saving favorite superset pair for user {user_id}: {request.exercise_1_name} + {request.exercise_2_name}")

    try:
        db = get_supabase_db()

        # Check if pair already exists (in either order)
        existing = db.client.table("favorite_superset_pairs").select("id").eq(
            "user_id", user_id
        ).or_(
            f"and(exercise_1_name.eq.{request.exercise_1_name},exercise_2_name.eq.{request.exercise_2_name}),"
            f"and(exercise_1_name.eq.{request.exercise_2_name},exercise_2_name.eq.{request.exercise_1_name})"
        ).execute()

        if existing.data:
            raise HTTPException(status_code=400, detail="This superset pair is already saved")

        # Create new favorite pair
        pair_id = str(uuid.uuid4())
        insert_data = {
            "id": pair_id,
            "user_id": user_id,
            "exercise_1_name": request.exercise_1_name,
            "exercise_2_name": request.exercise_2_name,
            "exercise_1_id": request.exercise_1_id,
            "exercise_2_id": request.exercise_2_id,
            "muscle_1": request.muscle_1,
            "muscle_2": request.muscle_2,
            "category": request.category,
            "notes": request.notes,
            "times_used": 0,
        }

        result = db.client.table("favorite_superset_pairs").insert(insert_data).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to save favorite pair"), "supersets_endpoints")

        row = result.data[0]
        logger.info(f"Saved favorite superset pair {pair_id} for user {user_id}")

        return FavoriteSupersetPairResponse(
            id=row["id"],
            user_id=user_id,
            exercise_1_name=row["exercise_1_name"],
            exercise_2_name=row["exercise_2_name"],
            exercise_1_id=row.get("exercise_1_id"),
            exercise_2_id=row.get("exercise_2_id"),
            muscle_1=row.get("muscle_1"),
            muscle_2=row.get("muscle_2"),
            category=row.get("category", "custom"),
            notes=row.get("notes"),
            times_used=row.get("times_used", 0),
            created_at=row["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error saving favorite superset pair: {e}", exc_info=True)
        raise safe_internal_error(e, "supersets")


@router.get("/favorites/{user_id}", response_model=List[FavoriteSupersetPairResponse])
async def get_favorite_superset_pairs(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's saved favorite superset pairs.

    Returns pairs sorted by usage frequency (most used first).
    """
    logger.info(f"Getting favorite superset pairs for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("favorite_superset_pairs").select("*").eq(
            "user_id", user_id
        ).order("times_used", desc=True).execute()

        pairs = []
        for row in result.data or []:
            pairs.append(FavoriteSupersetPairResponse(
                id=row["id"],
                user_id=user_id,
                exercise_1_name=row["exercise_1_name"],
                exercise_2_name=row["exercise_2_name"],
                exercise_1_id=row.get("exercise_1_id"),
                exercise_2_id=row.get("exercise_2_id"),
                muscle_1=row.get("muscle_1"),
                muscle_2=row.get("muscle_2"),
                category=row.get("category", "custom"),
                notes=row.get("notes"),
                times_used=row.get("times_used", 0),
                created_at=row["created_at"],
            ))

        return pairs

    except Exception as e:
        logger.error(f"Error getting favorite superset pairs: {e}", exc_info=True)
        raise safe_internal_error(e, "supersets")


@router.delete("/favorites/{pair_id}")
async def remove_favorite_superset_pair(pair_id: str, user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Remove a favorite superset pair.
    """
    logger.info(f"Removing favorite superset pair {pair_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("favorite_superset_pairs").delete().eq(
            "id", pair_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Favorite superset pair not found")

        return {"success": True, "message": "Favorite superset pair removed"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing favorite superset pair: {e}", exc_info=True)
        raise safe_internal_error(e, "supersets")


# =============================================================================
# Superset History
# =============================================================================

@router.get("/history/{user_id}", response_model=SupersetHistoryResponse)
async def get_superset_history(
    user_id: str,
    days: int = Query(default=30, ge=7, le=90, description="Number of days of history to retrieve"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's superset usage history.

    Returns history of supersets performed, including which pairs were used
    and how often.
    """
    logger.info(f"Getting superset history for user {user_id}, last {days} days")

    try:
        db = get_supabase_db()

        # Get completed workouts with supersets
        start_date = (datetime.now() - timedelta(days=days)).isoformat()

        workouts_result = db.client.table("workout_logs").select(
            "id, workout_id, completed_at, total_time_seconds"
        ).eq("user_id", user_id).gte("completed_at", start_date).order("completed_at", desc=True).execute()

        history = []
        superset_counts = {}  # Track pair frequencies

        for log in workouts_result.data or []:
            workout_id = log.get("workout_id")
            if not workout_id:
                continue

            # Get the workout exercises
            workout_result = db.client.table("workouts").select(
                "name", "exercises_json"
            ).eq("id", workout_id).execute()

            if not workout_result.data:
                continue

            workout = workout_result.data[0]
            exercises = workout.get("exercises_json", [])

            if not isinstance(exercises, list):
                try:
                    exercises = json.loads(exercises) if exercises else []
                except json.JSONDecodeError:
                    continue

            # Find superset groups
            superset_groups = {}
            for ex in exercises:
                group = ex.get("superset_group")
                if group is not None:
                    if group not in superset_groups:
                        superset_groups[group] = []
                    superset_groups[group].append(ex)

            # Create history entries for each superset
            for group, group_exercises in superset_groups.items():
                if len(group_exercises) >= 2:
                    ex1 = group_exercises[0]
                    ex2 = group_exercises[1]
                    ex1_name = ex1.get("name", "Unknown")
                    ex2_name = ex2.get("name", "Unknown")

                    history.append(SupersetHistoryEntry(
                        id=f"{log['id']}_{group}",
                        workout_id=workout_id,
                        workout_name=workout.get("name"),
                        exercise_1_name=ex1_name,
                        exercise_2_name=ex2_name,
                        superset_group=group,
                        completed_at=log.get("completed_at"),
                        duration_seconds=log.get("total_time_seconds"),
                        sets_completed=ex1.get("sets", 0) + ex2.get("sets", 0),
                    ))

                    # Track pair frequency
                    pair_key = tuple(sorted([ex1_name.lower(), ex2_name.lower()]))
                    superset_counts[pair_key] = superset_counts.get(pair_key, 0) + 1

        # Get favorite pairs sorted by frequency
        sorted_pairs = sorted(superset_counts.items(), key=lambda x: x[1], reverse=True)
        favorite_pairs = [
            {"exercises": list(pair), "count": count}
            for pair, count in sorted_pairs[:5]
        ]

        # Calculate stats
        total_supersets = len(history)
        unique_pairs = len(superset_counts)
        most_common = favorite_pairs[0] if favorite_pairs else None

        stats = {
            "total_supersets_completed": total_supersets,
            "unique_pairs_used": unique_pairs,
            "most_common_pair": most_common,
            "days_analyzed": days,
        }

        return SupersetHistoryResponse(
            user_id=user_id,
            history=history[:50],  # Limit to 50 most recent
            total_supersets_completed=total_supersets,
            favorite_pairs=favorite_pairs,
            stats=stats,
        )

    except Exception as e:
        logger.error(f"Error getting superset history: {e}", exc_info=True)
        raise safe_internal_error(e, "supersets")


# =============================================================================
# Helper Functions (for use by other modules)
# =============================================================================

async def get_user_superset_preferences(user_id: str) -> Dict[str, Any]:
    """
    Get superset preferences for a user.
    Used by workout generation and the adaptive workout service.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("users").select("preferences").eq("id", user_id).execute()

        if not result.data:
            return {"enabled": True, "max_pairs_per_workout": 3}

        user_preferences = result.data[0].get("preferences") or {}
        if isinstance(user_preferences, str):
            try:
                user_preferences = json.loads(user_preferences)
            except json.JSONDecodeError:
                user_preferences = {}

        superset_prefs = user_preferences.get("supersets", {})

        return {
            "enabled": superset_prefs.get("enabled", True),
            "max_pairs_per_workout": superset_prefs.get("max_pairs_per_workout", 3),
            "rest_between_supersets": superset_prefs.get("rest_between_supersets", 60),
            "rest_within_superset": superset_prefs.get("rest_within_superset", 10),
            "prefer_antagonist": superset_prefs.get("prefer_antagonist", True),
            "allow_same_muscle": superset_prefs.get("allow_same_muscle", False),
        }
    except Exception as e:
        logger.error(f"Error getting superset preferences: {e}", exc_info=True)
        return {"enabled": True, "max_pairs_per_workout": 3}


async def increment_favorite_pair_usage(user_id: str, exercise_1: str, exercise_2: str):
    """
    Increment the usage count for a favorite superset pair.
    Called when a superset is completed in a workout.
    """
    try:
        db = get_supabase_db()

        # Find the pair (in either order)
        result = db.client.table("favorite_superset_pairs").select("id", "times_used").eq(
            "user_id", user_id
        ).or_(
            f"and(exercise_1_name.ilike.{exercise_1},exercise_2_name.ilike.{exercise_2}),"
            f"and(exercise_1_name.ilike.{exercise_2},exercise_2_name.ilike.{exercise_1})"
        ).execute()

        if result.data:
            pair = result.data[0]
            db.client.table("favorite_superset_pairs").update({
                "times_used": pair.get("times_used", 0) + 1,
                "last_used_at": datetime.utcnow().isoformat()
            }).eq("id", pair["id"]).execute()

    except Exception as e:
        logger.error(f"Error incrementing favorite pair usage: {e}", exc_info=True)


def get_antagonist_muscles(muscle: str) -> List[str]:
    """
    Get antagonist muscles for a given muscle group.
    Used by workout generation for smart pairing.
    """
    ANTAGONIST_PAIRS = _supersets_parent()
    return ANTAGONIST_PAIRS.get(muscle.lower(), [])


def is_valid_superset_pair(muscle_1: str, muscle_2: str, allow_same: bool = False) -> bool:
    """
    Check if two muscle groups make a valid superset pair.
    """
    ANTAGONIST_PAIRS = _supersets_parent()
    m1, m2 = muscle_1.lower(), muscle_2.lower()

    if m1 == m2:
        return allow_same  # Same muscle = compound set

    # Check if they're antagonists
    return m2 in ANTAGONIST_PAIRS.get(m1, []) or m1 in ANTAGONIST_PAIRS.get(m2, [])


# =============================================================================
# Superset Analytics Logging (for user-created pairs)
# =============================================================================

class SupersetLogRequest(BaseModel):
    """Request to log a user-created superset pair."""
    user_id: str = Field(..., description="User ID")
    workout_id: str = Field(..., description="Workout ID")
    exercise_1_name: str = Field(..., description="First exercise name")
    exercise_2_name: str = Field(..., description="Second exercise name")
    exercise_1_muscle: Optional[str] = Field(default=None, description="First exercise muscle group")
    exercise_2_muscle: Optional[str] = Field(default=None, description="Second exercise muscle group")
    superset_group: int = Field(..., ge=1, description="Superset group number")


@router.post("/logs", status_code=201)
async def log_superset_usage(request: SupersetLogRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Log a user-created superset pair for analytics.

    Called when a workout with user-created supersets is completed.
    This helps track which exercise pairings users prefer.
    """
    logger.info(f"Logging superset: {request.exercise_1_name} + {request.exercise_2_name} for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Insert into user_superset_logs table
        insert_data = {
            "user_id": request.user_id,
            "workout_id": request.workout_id,
            "exercise_1_name": request.exercise_1_name,
            "exercise_2_name": request.exercise_2_name,
            "exercise_1_muscle": request.exercise_1_muscle,
            "exercise_2_muscle": request.exercise_2_muscle,
            "superset_group": request.superset_group,
        }

        result = db.client.table("user_superset_logs").insert(insert_data).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to log superset"), "supersets_endpoints")

        logger.info(f"Logged superset pair for user {request.user_id}")

        return {
            "success": True,
            "message": f"Logged superset: {request.exercise_1_name} + {request.exercise_2_name}",
            "id": result.data[0].get("id") if result.data else None,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error logging superset: {e}", exc_info=True)
        # Don't fail the request - logging is non-critical
        return {"success": False, "message": str(e)}
