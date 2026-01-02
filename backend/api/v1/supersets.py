"""
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
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
import logging
import json
import uuid

from core.supabase_db import get_supabase_db

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/supersets", tags=["Supersets"])


# =============================================================================
# Antagonist Muscle Pairs (for AI suggestions)
# =============================================================================

ANTAGONIST_PAIRS = {
    "chest": ["back", "lats", "rear_delts"],
    "back": ["chest", "pectorals", "front_delts"],
    "lats": ["chest", "pectorals"],
    "biceps": ["triceps"],
    "triceps": ["biceps"],
    "quadriceps": ["hamstrings", "glutes"],
    "hamstrings": ["quadriceps"],
    "shoulders": ["back", "lats"],
    "front_delts": ["rear_delts", "back"],
    "rear_delts": ["chest", "front_delts"],
    "glutes": ["hip_flexors", "quadriceps"],
    "hip_flexors": ["glutes", "hamstrings"],
    "abs": ["lower_back"],
    "lower_back": ["abs", "core"],
    "calves": ["tibialis"],
    "tibialis": ["calves"],
}

# Exercises that pair well together (curated combinations)
CLASSIC_SUPERSET_PAIRS = [
    {
        "exercise_1": "Bench Press",
        "exercise_2": "Barbell Row",
        "muscle_1": "chest",
        "muscle_2": "back",
        "category": "antagonist",
        "description": "Classic push/pull chest-back superset",
    },
    {
        "exercise_1": "Bicep Curl",
        "exercise_2": "Tricep Pushdown",
        "muscle_1": "biceps",
        "muscle_2": "triceps",
        "category": "antagonist",
        "description": "Arm antagonist superset for maximum pump",
    },
    {
        "exercise_1": "Leg Extension",
        "exercise_2": "Leg Curl",
        "muscle_1": "quadriceps",
        "muscle_2": "hamstrings",
        "category": "antagonist",
        "description": "Quad/hamstring antagonist superset",
    },
    {
        "exercise_1": "Lat Pulldown",
        "exercise_2": "Dumbbell Chest Press",
        "muscle_1": "lats",
        "muscle_2": "chest",
        "category": "antagonist",
        "description": "Vertical pull paired with horizontal push",
    },
    {
        "exercise_1": "Overhead Press",
        "exercise_2": "Pull-Up",
        "muscle_1": "shoulders",
        "muscle_2": "back",
        "category": "antagonist",
        "description": "Vertical push/pull superset",
    },
    {
        "exercise_1": "Dumbbell Fly",
        "exercise_2": "Face Pull",
        "muscle_1": "chest",
        "muscle_2": "rear_delts",
        "category": "antagonist",
        "description": "Chest isolation with rear delt work",
    },
    {
        "exercise_1": "Squat",
        "exercise_2": "Romanian Deadlift",
        "muscle_1": "quadriceps",
        "muscle_2": "hamstrings",
        "category": "antagonist",
        "description": "Lower body push/pull compound superset",
    },
    {
        "exercise_1": "Calf Raise",
        "exercise_2": "Tibialis Raise",
        "muscle_1": "calves",
        "muscle_2": "tibialis",
        "category": "antagonist",
        "description": "Lower leg antagonist superset for balance",
    },
    {
        "exercise_1": "Plank",
        "exercise_2": "Superman Hold",
        "muscle_1": "abs",
        "muscle_2": "lower_back",
        "category": "antagonist",
        "description": "Core anterior/posterior superset",
    },
    {
        "exercise_1": "Push-Up",
        "exercise_2": "Inverted Row",
        "muscle_1": "chest",
        "muscle_2": "back",
        "category": "antagonist",
        "description": "Bodyweight push/pull superset",
    },
]


# =============================================================================
# Request/Response Models
# =============================================================================

class SupersetPreferences(BaseModel):
    """User's superset preferences configuration."""
    enabled: bool = Field(default=True, description="Whether supersets are enabled")
    max_pairs_per_workout: int = Field(default=3, ge=1, le=6, description="Maximum superset pairs per workout")
    rest_between_supersets: int = Field(default=60, ge=30, le=180, description="Rest seconds between superset pairs")
    rest_within_superset: int = Field(default=10, ge=0, le=30, description="Rest seconds between exercises in a superset")
    prefer_antagonist: bool = Field(default=True, description="Prefer antagonist muscle pair supersets")
    allow_same_muscle: bool = Field(default=False, description="Allow same muscle group supersets (compound sets)")


class SupersetPreferencesUpdate(BaseModel):
    """Request to update superset preferences."""
    enabled: Optional[bool] = None
    max_pairs_per_workout: Optional[int] = Field(default=None, ge=1, le=6)
    rest_between_supersets: Optional[int] = Field(default=None, ge=30, le=180)
    rest_within_superset: Optional[int] = Field(default=None, ge=0, le=30)
    prefer_antagonist: Optional[bool] = None
    allow_same_muscle: Optional[bool] = None


class SupersetPreferencesResponse(BaseModel):
    """Response with current superset preferences."""
    user_id: str
    preferences: SupersetPreferences
    description: str
    updated_at: Optional[datetime] = None


class CreateSupersetPairRequest(BaseModel):
    """Request to create a manual superset pair in a workout."""
    workout_id: str = Field(..., description="The workout ID to modify")
    exercise_index_1: int = Field(..., ge=0, description="Index of first exercise in exercises_json")
    exercise_index_2: int = Field(..., ge=0, description="Index of second exercise in exercises_json")


class SupersetPairResponse(BaseModel):
    """Response for a superset pair operation."""
    workout_id: str
    superset_group: int
    exercise_1: Dict[str, Any]
    exercise_2: Dict[str, Any]
    message: str


class RemoveSupersetPairResponse(BaseModel):
    """Response for removing a superset pair."""
    workout_id: str
    superset_group: int
    exercises_updated: int
    message: str


class SupersetSuggestion(BaseModel):
    """A suggested superset pair."""
    exercise_1_name: str
    exercise_1_index: Optional[int] = None
    exercise_2_name: str
    exercise_2_index: Optional[int] = None
    muscle_1: str
    muscle_2: str
    category: str  # antagonist, compound_set, upper_lower
    reasoning: str
    confidence: float = Field(ge=0.0, le=1.0)


class SupersetSuggestionsResponse(BaseModel):
    """Response with AI-suggested superset pairs."""
    user_id: str
    workout_id: Optional[str]
    suggestions: List[SupersetSuggestion]
    classic_pairs: List[Dict[str, Any]]
    message: str


class FavoriteSupersetPair(BaseModel):
    """A user's favorite superset pair."""
    exercise_1_name: str = Field(..., min_length=1, max_length=200)
    exercise_2_name: str = Field(..., min_length=1, max_length=200)
    exercise_1_id: Optional[str] = None
    exercise_2_id: Optional[str] = None
    muscle_1: Optional[str] = None
    muscle_2: Optional[str] = None
    category: str = Field(default="antagonist", pattern="^(antagonist|compound_set|upper_lower|custom)$")
    notes: Optional[str] = Field(default=None, max_length=500)


class FavoriteSupersetPairResponse(BaseModel):
    """Response for a favorite superset pair."""
    id: str
    user_id: str
    exercise_1_name: str
    exercise_2_name: str
    exercise_1_id: Optional[str]
    exercise_2_id: Optional[str]
    muscle_1: Optional[str]
    muscle_2: Optional[str]
    category: str
    notes: Optional[str]
    times_used: int
    created_at: datetime


class SupersetHistoryEntry(BaseModel):
    """A superset usage history entry."""
    id: str
    workout_id: str
    workout_name: Optional[str]
    exercise_1_name: str
    exercise_2_name: str
    superset_group: int
    completed_at: datetime
    duration_seconds: Optional[int]
    sets_completed: Optional[int]


class SupersetHistoryResponse(BaseModel):
    """Response with superset usage history."""
    user_id: str
    history: List[SupersetHistoryEntry]
    total_supersets_completed: int
    favorite_pairs: List[Dict[str, Any]]
    stats: Dict[str, Any]


# =============================================================================
# Superset Preferences Endpoints
# =============================================================================

@router.get("/preferences/{user_id}", response_model=SupersetPreferencesResponse)
async def get_superset_preferences(user_id: str):
    """
    Get user's superset preferences.

    Returns configuration for how supersets are generated and used in workouts.
    """
    logger.info(f"Getting superset preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Get preferences from users table
        result = db.client.table("users").select("preferences").eq("id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user_preferences = result.data[0].get("preferences") or {}
        if isinstance(user_preferences, str):
            try:
                user_preferences = json.loads(user_preferences)
            except json.JSONDecodeError:
                user_preferences = {}

        # Extract superset preferences with defaults
        superset_prefs = user_preferences.get("supersets", {})

        preferences = SupersetPreferences(
            enabled=superset_prefs.get("enabled", True),
            max_pairs_per_workout=superset_prefs.get("max_pairs_per_workout", 3),
            rest_between_supersets=superset_prefs.get("rest_between_supersets", 60),
            rest_within_superset=superset_prefs.get("rest_within_superset", 10),
            prefer_antagonist=superset_prefs.get("prefer_antagonist", True),
            allow_same_muscle=superset_prefs.get("allow_same_muscle", False),
        )

        # Generate description
        if not preferences.enabled:
            description = "Supersets are disabled"
        else:
            parts = []
            parts.append(f"Up to {preferences.max_pairs_per_workout} superset pairs per workout")
            parts.append(f"{preferences.rest_between_supersets}s rest between pairs")
            if preferences.prefer_antagonist:
                parts.append("Prefers antagonist muscle pairings")
            if preferences.allow_same_muscle:
                parts.append("Allows compound sets (same muscle)")
            description = ". ".join(parts)

        return SupersetPreferencesResponse(
            user_id=user_id,
            preferences=preferences,
            description=description,
            updated_at=superset_prefs.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting superset preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/preferences/{user_id}", response_model=SupersetPreferencesResponse)
async def update_superset_preferences(user_id: str, request: SupersetPreferencesUpdate):
    """
    Update user's superset preferences.

    Allows partial updates - only provided fields will be changed.
    """
    logger.info(f"Updating superset preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Get existing preferences
        result = db.client.table("users").select("preferences").eq("id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user_preferences = result.data[0].get("preferences") or {}
        if isinstance(user_preferences, str):
            try:
                user_preferences = json.loads(user_preferences)
            except json.JSONDecodeError:
                user_preferences = {}

        # Get existing superset preferences
        superset_prefs = user_preferences.get("supersets", {})

        # Update only provided fields
        if request.enabled is not None:
            superset_prefs["enabled"] = request.enabled
        if request.max_pairs_per_workout is not None:
            superset_prefs["max_pairs_per_workout"] = request.max_pairs_per_workout
        if request.rest_between_supersets is not None:
            superset_prefs["rest_between_supersets"] = request.rest_between_supersets
        if request.rest_within_superset is not None:
            superset_prefs["rest_within_superset"] = request.rest_within_superset
        if request.prefer_antagonist is not None:
            superset_prefs["prefer_antagonist"] = request.prefer_antagonist
        if request.allow_same_muscle is not None:
            superset_prefs["allow_same_muscle"] = request.allow_same_muscle

        superset_prefs["updated_at"] = datetime.utcnow().isoformat()

        # Save back to user preferences
        user_preferences["supersets"] = superset_prefs

        update_result = db.client.table("users").update({
            "preferences": json.dumps(user_preferences)
        }).eq("id", user_id).execute()

        if not update_result.data:
            raise HTTPException(status_code=500, detail="Failed to update preferences")

        # Build response
        preferences = SupersetPreferences(
            enabled=superset_prefs.get("enabled", True),
            max_pairs_per_workout=superset_prefs.get("max_pairs_per_workout", 3),
            rest_between_supersets=superset_prefs.get("rest_between_supersets", 60),
            rest_within_superset=superset_prefs.get("rest_within_superset", 10),
            prefer_antagonist=superset_prefs.get("prefer_antagonist", True),
            allow_same_muscle=superset_prefs.get("allow_same_muscle", False),
        )

        # Generate description
        if not preferences.enabled:
            description = "Supersets are disabled"
        else:
            parts = []
            parts.append(f"Up to {preferences.max_pairs_per_workout} superset pairs per workout")
            parts.append(f"{preferences.rest_between_supersets}s rest between pairs")
            if preferences.prefer_antagonist:
                parts.append("Prefers antagonist muscle pairings")
            if preferences.allow_same_muscle:
                parts.append("Allows compound sets (same muscle)")
            description = ". ".join(parts)

        logger.info(f"Updated superset preferences for user {user_id}")

        return SupersetPreferencesResponse(
            user_id=user_id,
            preferences=preferences,
            description=description,
            updated_at=superset_prefs.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating superset preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Manual Superset Pair Creation/Removal
# =============================================================================

@router.post("/pair", response_model=SupersetPairResponse)
async def create_superset_pair(request: CreateSupersetPairRequest):
    """
    Create a manual superset pair within a workout.

    Updates the exercises_json to add superset_group and superset_order
    to the specified exercises, pairing them together.
    """
    logger.info(
        f"Creating superset pair in workout {request.workout_id}: "
        f"exercises {request.exercise_index_1} and {request.exercise_index_2}"
    )

    try:
        db = get_supabase_db()

        # Get the workout
        result = db.client.table("workouts").select(
            "id", "user_id", "exercises_json"
        ).eq("id", request.workout_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout = result.data[0]
        exercises = workout.get("exercises_json", [])

        if not isinstance(exercises, list):
            try:
                exercises = json.loads(exercises) if exercises else []
            except json.JSONDecodeError:
                exercises = []

        # Validate indices
        if request.exercise_index_1 >= len(exercises):
            raise HTTPException(
                status_code=400,
                detail=f"Exercise index {request.exercise_index_1} is out of range (max: {len(exercises) - 1})"
            )
        if request.exercise_index_2 >= len(exercises):
            raise HTTPException(
                status_code=400,
                detail=f"Exercise index {request.exercise_index_2} is out of range (max: {len(exercises) - 1})"
            )
        if request.exercise_index_1 == request.exercise_index_2:
            raise HTTPException(
                status_code=400,
                detail="Cannot pair an exercise with itself"
            )

        # Check if either exercise is already in a superset
        ex1 = exercises[request.exercise_index_1]
        ex2 = exercises[request.exercise_index_2]

        if ex1.get("superset_group") is not None:
            raise HTTPException(
                status_code=400,
                detail=f"Exercise '{ex1.get('name', 'Unknown')}' is already in superset group {ex1.get('superset_group')}"
            )
        if ex2.get("superset_group") is not None:
            raise HTTPException(
                status_code=400,
                detail=f"Exercise '{ex2.get('name', 'Unknown')}' is already in superset group {ex2.get('superset_group')}"
            )

        # Find the next available superset group number
        existing_groups = set()
        for ex in exercises:
            if ex.get("superset_group") is not None:
                existing_groups.add(ex["superset_group"])

        new_group = 1
        while new_group in existing_groups:
            new_group += 1

        # Update the exercises
        exercises[request.exercise_index_1]["superset_group"] = new_group
        exercises[request.exercise_index_1]["superset_order"] = 1

        exercises[request.exercise_index_2]["superset_group"] = new_group
        exercises[request.exercise_index_2]["superset_order"] = 2
        exercises[request.exercise_index_2]["rest_seconds"] = 0  # No rest within superset

        # Save the updated exercises
        update_result = db.client.table("workouts").update({
            "exercises_json": exercises,
            "updated_at": datetime.utcnow().isoformat()
        }).eq("id", request.workout_id).execute()

        if not update_result.data:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        logger.info(f"Created superset group {new_group} in workout {request.workout_id}")

        return SupersetPairResponse(
            workout_id=request.workout_id,
            superset_group=new_group,
            exercise_1=exercises[request.exercise_index_1],
            exercise_2=exercises[request.exercise_index_2],
            message=f"Created superset group {new_group} with {ex1.get('name', 'Unknown')} and {ex2.get('name', 'Unknown')}"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating superset pair: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/pair/{workout_id}/{superset_group}", response_model=RemoveSupersetPairResponse)
async def remove_superset_pair(workout_id: str, superset_group: int):
    """
    Remove a superset pair from a workout.

    Clears the superset_group and superset_order from all exercises
    that belong to the specified superset group.
    """
    logger.info(f"Removing superset group {superset_group} from workout {workout_id}")

    try:
        db = get_supabase_db()

        # Get the workout
        result = db.client.table("workouts").select(
            "id", "user_id", "exercises_json"
        ).eq("id", workout_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout = result.data[0]
        exercises = workout.get("exercises_json", [])

        if not isinstance(exercises, list):
            try:
                exercises = json.loads(exercises) if exercises else []
            except json.JSONDecodeError:
                exercises = []

        # Find and update exercises in the superset group
        updated_count = 0
        for ex in exercises:
            if ex.get("superset_group") == superset_group:
                ex.pop("superset_group", None)
                ex.pop("superset_order", None)
                # Restore default rest time (60 seconds)
                if ex.get("rest_seconds") == 0:
                    ex["rest_seconds"] = 60
                updated_count += 1

        if updated_count == 0:
            raise HTTPException(
                status_code=404,
                detail=f"Superset group {superset_group} not found in workout"
            )

        # Save the updated exercises
        update_result = db.client.table("workouts").update({
            "exercises_json": exercises,
            "updated_at": datetime.utcnow().isoformat()
        }).eq("id", workout_id).execute()

        if not update_result.data:
            raise HTTPException(status_code=500, detail="Failed to update workout")

        logger.info(f"Removed superset group {superset_group} from workout {workout_id}, updated {updated_count} exercises")

        return RemoveSupersetPairResponse(
            workout_id=workout_id,
            superset_group=superset_group,
            exercises_updated=updated_count,
            message=f"Removed superset group {superset_group}, updated {updated_count} exercises"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing superset pair: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# AI Superset Suggestions
# =============================================================================

def _get_muscle_group(exercise: Dict[str, Any]) -> str:
    """Extract muscle group from exercise, normalizing various field names."""
    muscle = (
        exercise.get("muscle_group") or
        exercise.get("target_muscle") or
        exercise.get("body_part") or
        exercise.get("primary_muscle") or
        ""
    ).lower()

    # Normalize common variations
    muscle_map = {
        "pectorals": "chest",
        "pecs": "chest",
        "chest": "chest",
        "latissimus dorsi": "lats",
        "latissimus": "lats",
        "upper back": "back",
        "middle back": "back",
        "lower back": "lower_back",
        "quads": "quadriceps",
        "thighs": "quadriceps",
        "glutes": "glutes",
        "gluteus": "glutes",
        "abdominals": "abs",
        "rectus abdominis": "abs",
        "deltoids": "shoulders",
        "anterior deltoids": "front_delts",
        "posterior deltoids": "rear_delts",
    }

    return muscle_map.get(muscle, muscle)


def _find_antagonist_pairs(exercises: List[Dict[str, Any]]) -> List[SupersetSuggestion]:
    """Find antagonist muscle pair suggestions from a list of exercises."""
    suggestions = []

    for i, ex1 in enumerate(exercises):
        muscle1 = _get_muscle_group(ex1)
        if not muscle1:
            continue

        antagonists = ANTAGONIST_PAIRS.get(muscle1, [])
        if not antagonists:
            continue

        for j, ex2 in enumerate(exercises):
            if j <= i:  # Avoid duplicates and self-pairing
                continue

            muscle2 = _get_muscle_group(ex2)
            if muscle2 in antagonists:
                # Check if either is already in a superset
                if ex1.get("superset_group") is not None or ex2.get("superset_group") is not None:
                    continue

                # Calculate confidence based on how classic the pairing is
                confidence = 0.7
                pair_key = f"{muscle1}_{muscle2}"
                classic_pairs = [
                    "chest_back", "back_chest", "biceps_triceps", "triceps_biceps",
                    "quadriceps_hamstrings", "hamstrings_quadriceps"
                ]
                if pair_key in classic_pairs:
                    confidence = 0.9

                suggestions.append(SupersetSuggestion(
                    exercise_1_name=ex1.get("name", "Unknown"),
                    exercise_1_index=i,
                    exercise_2_name=ex2.get("name", "Unknown"),
                    exercise_2_index=j,
                    muscle_1=muscle1,
                    muscle_2=muscle2,
                    category="antagonist",
                    reasoning=f"Antagonist pairing: {muscle1} and {muscle2} work opposing muscle groups",
                    confidence=confidence,
                ))

    # Sort by confidence
    suggestions.sort(key=lambda x: x.confidence, reverse=True)

    return suggestions


@router.get("/suggestions/{user_id}", response_model=SupersetSuggestionsResponse)
async def get_superset_suggestions(
    user_id: str,
    workout_id: Optional[str] = Query(default=None, description="Optional workout ID to suggest pairs for"),
):
    """
    Get AI-suggested superset pairs based on a workout or general recommendations.

    If workout_id is provided, analyzes the workout's exercises to find
    optimal antagonist pairings. Otherwise, returns classic superset pairs
    that work well together.
    """
    logger.info(f"Getting superset suggestions for user {user_id}, workout_id={workout_id}")

    try:
        db = get_supabase_db()
        suggestions = []

        if workout_id:
            # Get the workout exercises
            result = db.client.table("workouts").select(
                "id", "name", "exercises_json"
            ).eq("id", workout_id).execute()

            if not result.data:
                raise HTTPException(status_code=404, detail="Workout not found")

            workout = result.data[0]
            exercises = workout.get("exercises_json", [])

            if not isinstance(exercises, list):
                try:
                    exercises = json.loads(exercises) if exercises else []
                except json.JSONDecodeError:
                    exercises = []

            if len(exercises) >= 2:
                suggestions = _find_antagonist_pairs(exercises)

        # Get user's favorite pairs for reference
        favorites_result = db.client.table("favorite_superset_pairs").select(
            "exercise_1_name", "exercise_2_name", "muscle_1", "muscle_2", "times_used"
        ).eq("user_id", user_id).order("times_used", desc=True).limit(5).execute()

        favorite_pairs = []
        for row in favorites_result.data or []:
            favorite_pairs.append({
                "exercise_1": row.get("exercise_1_name"),
                "exercise_2": row.get("exercise_2_name"),
                "muscle_1": row.get("muscle_1"),
                "muscle_2": row.get("muscle_2"),
                "times_used": row.get("times_used", 0),
            })

        # Build message
        if suggestions:
            message = f"Found {len(suggestions)} potential superset pairs for your workout"
        elif workout_id:
            message = "No antagonist pairs found in this workout. Consider adding exercises for opposing muscle groups."
        else:
            message = "Here are some classic superset combinations to try"

        return SupersetSuggestionsResponse(
            user_id=user_id,
            workout_id=workout_id,
            suggestions=suggestions[:5],  # Top 5 suggestions
            classic_pairs=CLASSIC_SUPERSET_PAIRS[:5],  # Top 5 classic pairs
            message=message,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting superset suggestions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Favorite Superset Pairs
# =============================================================================

@router.post("/favorites", response_model=FavoriteSupersetPairResponse)
async def save_favorite_superset_pair(user_id: str = Query(...), request: FavoriteSupersetPair = ...):
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
            raise HTTPException(status_code=500, detail="Failed to save favorite pair")

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
        logger.error(f"Error saving favorite superset pair: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/favorites/{user_id}", response_model=List[FavoriteSupersetPairResponse])
async def get_favorite_superset_pairs(user_id: str):
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
        logger.error(f"Error getting favorite superset pairs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/favorites/{pair_id}")
async def remove_favorite_superset_pair(pair_id: str, user_id: str = Query(...)):
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
        logger.error(f"Error removing favorite superset pair: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Superset History
# =============================================================================

@router.get("/history/{user_id}", response_model=SupersetHistoryResponse)
async def get_superset_history(
    user_id: str,
    days: int = Query(default=30, ge=7, le=90, description="Number of days of history to retrieve"),
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
        logger.error(f"Error getting superset history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        logger.error(f"Error getting superset preferences: {e}")
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
        logger.error(f"Error incrementing favorite pair usage: {e}")


def get_antagonist_muscles(muscle: str) -> List[str]:
    """
    Get antagonist muscles for a given muscle group.
    Used by workout generation for smart pairing.
    """
    return ANTAGONIST_PAIRS.get(muscle.lower(), [])


def is_valid_superset_pair(muscle_1: str, muscle_2: str, allow_same: bool = False) -> bool:
    """
    Check if two muscle groups make a valid superset pair.
    """
    m1, m2 = muscle_1.lower(), muscle_2.lower()

    if m1 == m2:
        return allow_same  # Same muscle = compound set

    # Check if they're antagonists
    return m2 in ANTAGONIST_PAIRS.get(m1, []) or m1 in ANTAGONIST_PAIRS.get(m2, [])
