"""
Exercise Preferences API - Staple exercises, variation control, and avoidance lists.

This module allows users to:
1. Mark exercises as "staples" that should never be rotated out
2. Control their exercise variation percentage (0-100%)
3. View week-over-week exercise changes
4. Specify exercises to avoid (injuries, dislikes)
5. Specify muscle groups to avoid (injuries, limitations)

Staple exercises are core lifts (like Squat, Bench Press, Deadlift) that users
want to keep in every workout regardless of the weekly variation setting.

Avoided exercises/muscles are excluded from AI-generated workouts entirely.
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, date, timedelta
import logging
import json

from core.supabase_db import get_supabase_db

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/exercise-preferences", tags=["Exercise Preferences"])


# =============================================================================
# Request/Response Models
# =============================================================================

class StapleExerciseCreate(BaseModel):
    """Request to add a staple exercise."""
    user_id: str
    exercise_name: str = Field(..., min_length=1, max_length=200)
    library_id: Optional[str] = None
    muscle_group: Optional[str] = None
    reason: Optional[str] = Field(default=None, max_length=100)  # "core_compound", "favorite", "rehab"


class StapleExerciseResponse(BaseModel):
    """Response for a staple exercise."""
    id: str
    exercise_name: str
    library_id: Optional[str]
    muscle_group: Optional[str]
    reason: Optional[str]
    created_at: datetime
    # From join with exercise_library
    body_part: Optional[str] = None
    equipment: Optional[str] = None
    gif_url: Optional[str] = None


class VariationPreferenceUpdate(BaseModel):
    """Request to update variation percentage."""
    user_id: str
    variation_percentage: int = Field(..., ge=0, le=100)


class VariationPreferenceResponse(BaseModel):
    """Response with current variation setting."""
    variation_percentage: int
    description: str


class WeekComparisonResponse(BaseModel):
    """Response for week-over-week exercise comparison."""
    current_week_start: date
    previous_week_start: date
    kept_exercises: List[str]
    new_exercises: List[str]
    removed_exercises: List[str]
    total_current: int
    total_previous: int
    variation_summary: str


class ExerciseRotationResponse(BaseModel):
    """Response for a single exercise rotation record."""
    id: str
    exercise_added: str
    exercise_removed: Optional[str]
    muscle_group: Optional[str]
    rotation_reason: Optional[str]
    week_start_date: date
    created_at: datetime


# =============================================================================
# Avoided Exercises Models
# =============================================================================

class AvoidedExerciseCreate(BaseModel):
    """Request to add an exercise to avoid."""
    exercise_name: str = Field(..., min_length=1, max_length=200)
    exercise_id: Optional[str] = None
    reason: Optional[str] = Field(default=None, max_length=200)
    is_temporary: bool = False
    end_date: Optional[date] = None


class AvoidedExerciseResponse(BaseModel):
    """Response for an avoided exercise."""
    id: str
    exercise_name: str
    exercise_id: Optional[str]
    reason: Optional[str]
    is_temporary: bool
    end_date: Optional[date]
    created_at: datetime


# =============================================================================
# Avoided Muscles Models
# =============================================================================

class AvoidedMuscleCreate(BaseModel):
    """Request to add a muscle group to avoid."""
    muscle_group: str = Field(..., min_length=1, max_length=100)
    reason: Optional[str] = Field(default=None, max_length=200)
    is_temporary: bool = False
    end_date: Optional[date] = None
    severity: str = Field(default="avoid", pattern="^(avoid|reduce)$")


class AvoidedMuscleResponse(BaseModel):
    """Response for an avoided muscle group."""
    id: str
    muscle_group: str
    reason: Optional[str]
    is_temporary: bool
    end_date: Optional[date]
    severity: str
    created_at: datetime


# Common muscle groups for reference
MUSCLE_GROUPS = [
    # Primary muscle groups
    "chest", "back", "shoulders", "biceps", "triceps", "core",
    "quadriceps", "hamstrings", "glutes", "calves",
    # Specific areas
    "lower_back", "upper_back", "lats", "traps", "forearms",
    "hip_flexors", "adductors", "abductors", "abs", "obliques",
]


# =============================================================================
# Staple Exercises Endpoints
# =============================================================================

@router.get("/staples/{user_id}", response_model=List[StapleExerciseResponse])
async def get_user_staples(user_id: str):
    """
    Get all staple exercises for a user.

    Staple exercises are guaranteed to be included in generated workouts
    and are never rotated out during weekly variation.
    """
    logger.info(f"Getting staple exercises for user {user_id}")

    try:
        db = get_supabase_db()

        # Use the view that joins with exercise_library for details
        result = db.client.table("user_staples_with_details").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()

        staples = []
        for row in result.data or []:
            staples.append(StapleExerciseResponse(
                id=row["id"],
                exercise_name=row["exercise_name"],
                library_id=row.get("library_id"),
                muscle_group=row.get("muscle_group"),
                reason=row.get("reason"),
                created_at=row["created_at"],
                body_part=row.get("body_part"),
                equipment=row.get("equipment"),
                gif_url=row.get("gif_url"),
            ))

        return staples

    except Exception as e:
        logger.error(f"Error getting staple exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/staples", response_model=StapleExerciseResponse)
async def add_staple_exercise(request: StapleExerciseCreate):
    """
    Add an exercise to user's staples.

    Staple exercises will:
    - Always be included in generated workouts (when targeting the same muscle)
    - Never appear in the "avoid recently used" list
    - Be visually marked in the workout UI
    """
    logger.info(f"Adding staple exercise '{request.exercise_name}' for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Check if already exists
        existing = db.client.table("staple_exercises").select("id").eq("user_id", request.user_id).eq("exercise_name", request.exercise_name).execute()

        if existing.data:
            raise HTTPException(status_code=400, detail="Exercise is already a staple")

        # Insert new staple
        insert_data = {
            "user_id": request.user_id,
            "exercise_name": request.exercise_name,
            "library_id": request.library_id,
            "muscle_group": request.muscle_group,
            "reason": request.reason,
        }

        result = db.client.table("staple_exercises").insert(insert_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to add staple exercise")

        row = result.data[0]

        # Clear future incomplete workouts so they regenerate with the new staple
        # This ensures the staple exercise appears in today's and upcoming workouts
        try:
            today_str = date.today().isoformat()
            deleted = db.client.table("workouts").delete().eq(
                "user_id", request.user_id
            ).gte(
                "scheduled_date", today_str
            ).eq(
                "is_completed", False
            ).execute()
            deleted_count = len(deleted.data) if deleted.data else 0
            if deleted_count > 0:
                logger.info(f"⭐ Cleared {deleted_count} future workouts to include new staple: {request.exercise_name}")
        except Exception as e:
            logger.warning(f"Could not clear future workouts for staple: {e}")

        # Get exercise details from library if library_id provided
        body_part = None
        equipment = None
        gif_url = None

        if request.library_id:
            lib_result = db.client.table("exercise_library").select("body_part, equipment, gif_url").eq("id", request.library_id).execute()
            if lib_result.data:
                lib_row = lib_result.data[0]
                body_part = lib_row.get("body_part")
                equipment = lib_row.get("equipment")
                gif_url = lib_row.get("gif_url")

        return StapleExerciseResponse(
            id=row["id"],
            exercise_name=row["exercise_name"],
            library_id=row.get("library_id"),
            muscle_group=row.get("muscle_group"),
            reason=row.get("reason"),
            created_at=row["created_at"],
            body_part=body_part,
            equipment=equipment,
            gif_url=gif_url,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding staple exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/staples/{user_id}/{staple_id}")
async def remove_staple_exercise(user_id: str, staple_id: str):
    """
    Remove an exercise from user's staples.

    The exercise will now be subject to normal weekly variation rules.
    """
    logger.info(f"Removing staple exercise {staple_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ownership and delete
        result = db.client.table("staple_exercises").delete().eq("id", staple_id).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Staple exercise not found")

        return {"success": True, "message": "Staple exercise removed"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing staple exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Variation Percentage Endpoints
# =============================================================================

@router.get("/variation/{user_id}", response_model=VariationPreferenceResponse)
async def get_variation_preference(user_id: str):
    """
    Get user's exercise variation percentage setting.

    0% = Keep same exercises every week (maximum consistency)
    30% = Default - rotate about 1/3 of exercises (balanced)
    100% = Maximum variety - new exercises every week
    """
    logger.info(f"Getting variation preference for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("users").select("variation_percentage").eq("id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        percentage = result.data[0].get("variation_percentage", 30)

        # Generate description
        if percentage == 0:
            description = "Same exercises every week"
        elif percentage <= 25:
            description = "Minimal variety - mostly consistent"
        elif percentage <= 50:
            description = "Balanced variety"
        elif percentage <= 75:
            description = "High variety - frequent changes"
        else:
            description = "Maximum variety - new exercises each week"

        return VariationPreferenceResponse(
            variation_percentage=percentage,
            description=description
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting variation preference: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/variation", response_model=VariationPreferenceResponse)
async def update_variation_preference(request: VariationPreferenceUpdate):
    """
    Update user's exercise variation percentage.

    This controls how much the weekly workouts change:
    - Lower values = more consistency (same exercises)
    - Higher values = more variety (different exercises)

    Note: Staple exercises are never affected by this setting.
    """
    logger.info(f"Updating variation preference to {request.variation_percentage}% for user {request.user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("users").update({
            "variation_percentage": request.variation_percentage
        }).eq("id", request.user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        # Generate description
        percentage = request.variation_percentage
        if percentage == 0:
            description = "Same exercises every week"
        elif percentage <= 25:
            description = "Minimal variety - mostly consistent"
        elif percentage <= 50:
            description = "Balanced variety"
        elif percentage <= 75:
            description = "High variety - frequent changes"
        else:
            description = "Maximum variety - new exercises each week"

        return VariationPreferenceResponse(
            variation_percentage=percentage,
            description=description
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating variation preference: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Sets/Reps Limits Endpoints
# =============================================================================

class SetsLimitsUpdate(BaseModel):
    """Request to update sets/reps limits preferences."""
    user_id: str
    max_sets_per_exercise: int = Field(default=4, ge=1, le=10)
    min_sets_per_exercise: int = Field(default=2, ge=1, le=10)
    max_reps_ceiling: Optional[int] = Field(default=None, ge=1, le=50)
    enforce_rep_ceiling: bool = False


class SetsLimitsResponse(BaseModel):
    """Response for sets/reps limits."""
    max_sets_per_exercise: int
    min_sets_per_exercise: int
    max_reps_ceiling: Optional[int]
    enforce_rep_ceiling: bool
    description: str


@router.get("/sets-limits/{user_id}", response_model=SetsLimitsResponse)
async def get_sets_limits(user_id: str):
    """
    Get user's sets/reps limits preferences.

    These limits control:
    - max_sets_per_exercise: Maximum sets per exercise (1-10, default 4)
    - min_sets_per_exercise: Minimum sets per exercise (1-10, default 2)
    - max_reps_ceiling: Hard cap on reps if enforce_rep_ceiling is True
    - enforce_rep_ceiling: Whether to strictly enforce the max_reps_ceiling
    """
    logger.info(f"Getting sets limits for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("users").select("preferences").eq("id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        preferences = result.data[0].get("preferences") or {}
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        max_sets = preferences.get("max_sets_per_exercise", 4)
        min_sets = preferences.get("min_sets_per_exercise", 2)
        max_reps_ceiling = preferences.get("max_reps_ceiling")
        enforce_rep_ceiling = preferences.get("enforce_rep_ceiling", False)

        # Generate description
        description = f"{min_sets}-{max_sets} sets per exercise"
        if enforce_rep_ceiling and max_reps_ceiling:
            description += f", max {max_reps_ceiling} reps"

        return SetsLimitsResponse(
            max_sets_per_exercise=max_sets,
            min_sets_per_exercise=min_sets,
            max_reps_ceiling=max_reps_ceiling,
            enforce_rep_ceiling=enforce_rep_ceiling,
            description=description
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting sets limits: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/sets-limits", response_model=SetsLimitsResponse)
async def update_sets_limits(request: SetsLimitsUpdate):
    """
    Update user's sets/reps limits preferences.

    These settings control workout generation:
    - max_sets_per_exercise: Maximum sets per exercise (1-10, default 4)
    - min_sets_per_exercise: Minimum sets per exercise (1-10, default 2)
    - max_reps_ceiling: Hard cap on reps (only applies if enforce_rep_ceiling is True)
    - enforce_rep_ceiling: Whether to strictly enforce the max_reps_ceiling

    Example use cases:
    - User wants shorter workouts: max_sets=3, min_sets=2
    - User prefers strength training: max_reps_ceiling=8, enforce_rep_ceiling=True
    - User wants high volume: max_sets=6, min_sets=4
    """
    logger.info(
        f"Updating sets limits for user {request.user_id}: "
        f"max_sets={request.max_sets_per_exercise}, min_sets={request.min_sets_per_exercise}, "
        f"max_reps_ceiling={request.max_reps_ceiling}, enforce_rep_ceiling={request.enforce_rep_ceiling}"
    )

    try:
        db = get_supabase_db()

        # Validate min <= max for sets
        if request.min_sets_per_exercise > request.max_sets_per_exercise:
            raise HTTPException(
                status_code=400,
                detail="min_sets_per_exercise cannot be greater than max_sets_per_exercise"
            )

        # Get existing preferences
        result = db.client.table("users").select("preferences").eq("id", request.user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        existing_preferences = result.data[0].get("preferences") or {}
        if isinstance(existing_preferences, str):
            try:
                existing_preferences = json.loads(existing_preferences)
            except json.JSONDecodeError:
                existing_preferences = {}

        # Update preferences
        existing_preferences["max_sets_per_exercise"] = request.max_sets_per_exercise
        existing_preferences["min_sets_per_exercise"] = request.min_sets_per_exercise
        existing_preferences["max_reps_ceiling"] = request.max_reps_ceiling
        existing_preferences["enforce_rep_ceiling"] = request.enforce_rep_ceiling

        # Save updated preferences
        update_result = db.client.table("users").update({
            "preferences": json.dumps(existing_preferences)
        }).eq("id", request.user_id).execute()

        if not update_result.data:
            raise HTTPException(status_code=500, detail="Failed to update preferences")

        # Generate description
        description = f"{request.min_sets_per_exercise}-{request.max_sets_per_exercise} sets per exercise"
        if request.enforce_rep_ceiling and request.max_reps_ceiling:
            description += f", max {request.max_reps_ceiling} reps"

        return SetsLimitsResponse(
            max_sets_per_exercise=request.max_sets_per_exercise,
            min_sets_per_exercise=request.min_sets_per_exercise,
            max_reps_ceiling=request.max_reps_ceiling,
            enforce_rep_ceiling=request.enforce_rep_ceiling,
            description=description
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating sets limits: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Week Comparison Endpoints
# =============================================================================

@router.get("/week-comparison/{user_id}", response_model=WeekComparisonResponse)
async def get_week_comparison(
    user_id: str,
    current_week_start: Optional[date] = None,
):
    """
    Compare exercises between current week and previous week.

    Returns which exercises were:
    - Kept (appeared in both weeks)
    - Added (new this week)
    - Removed (not in this week but was last week)
    """
    logger.info(f"Getting week comparison for user {user_id}")

    try:
        db = get_supabase_db()

        # Default to current week's Monday
        if current_week_start is None:
            today = date.today()
            current_week_start = today - timedelta(days=today.weekday())

        previous_week_start = current_week_start - timedelta(days=7)

        # Get exercises from current week's workouts
        current_week_end = current_week_start + timedelta(days=7)
        current_result = db.client.table("workouts").select("exercises_json").eq("user_id", user_id).gte("scheduled_date", current_week_start.isoformat()).lt("scheduled_date", current_week_end.isoformat()).execute()

        current_exercises = set()
        for workout in current_result.data or []:
            exercises = workout.get("exercises_json", [])
            if isinstance(exercises, list):
                for ex in exercises:
                    if isinstance(ex, dict) and ex.get("name"):
                        current_exercises.add(ex["name"].lower())

        # Get exercises from previous week's workouts
        previous_week_end = previous_week_start + timedelta(days=7)
        previous_result = db.client.table("workouts").select("exercises_json").eq("user_id", user_id).gte("scheduled_date", previous_week_start.isoformat()).lt("scheduled_date", previous_week_end.isoformat()).execute()

        previous_exercises = set()
        for workout in previous_result.data or []:
            exercises = workout.get("exercises_json", [])
            if isinstance(exercises, list):
                for ex in exercises:
                    if isinstance(ex, dict) and ex.get("name"):
                        previous_exercises.add(ex["name"].lower())

        # Calculate differences
        kept = current_exercises & previous_exercises
        new = current_exercises - previous_exercises
        removed = previous_exercises - current_exercises

        # Generate summary
        total_current = len(current_exercises)
        total_previous = len(previous_exercises)
        changes = len(new) + len(removed)

        if total_previous > 0:
            change_percent = round((len(new) / total_previous) * 100)
            summary = f"{len(new)} new exercises ({change_percent}% change)"
        else:
            summary = f"{len(new)} exercises this week"

        return WeekComparisonResponse(
            current_week_start=current_week_start,
            previous_week_start=previous_week_start,
            kept_exercises=sorted([e.title() for e in kept]),
            new_exercises=sorted([e.title() for e in new]),
            removed_exercises=sorted([e.title() for e in removed]),
            total_current=total_current,
            total_previous=total_previous,
            variation_summary=summary
        )

    except Exception as e:
        logger.error(f"Error getting week comparison: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/rotations/{user_id}", response_model=List[ExerciseRotationResponse])
async def get_exercise_rotations(
    user_id: str,
    weeks: int = Query(default=4, ge=1, le=12),
):
    """
    Get recent exercise rotation history.

    Shows which exercises were added/removed during workout generation
    over the specified number of weeks.
    """
    logger.info(f"Getting exercise rotations for user {user_id}, last {weeks} weeks")

    try:
        db = get_supabase_db()

        # Calculate date range
        today = date.today()
        start_date = today - timedelta(weeks=weeks)

        result = db.client.table("exercise_rotations").select("*").eq("user_id", user_id).gte("week_start_date", start_date.isoformat()).order("created_at", desc=True).execute()

        rotations = []
        for row in result.data or []:
            rotations.append(ExerciseRotationResponse(
                id=row["id"],
                exercise_added=row["exercise_added"],
                exercise_removed=row.get("exercise_removed"),
                muscle_group=row.get("muscle_group"),
                rotation_reason=row.get("rotation_reason"),
                week_start_date=row["week_start_date"],
                created_at=row["created_at"]
            ))

        return rotations

    except Exception as e:
        logger.error(f"Error getting exercise rotations: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Helper Functions (for use by other modules)
# =============================================================================

async def get_user_staple_exercises(user_id: str) -> List[str]:
    """
    Get list of staple exercise names for a user.
    Used by RAG service and workout generation.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("staple_exercises").select("exercise_name").eq("user_id", user_id).execute()
        return [row["exercise_name"] for row in result.data or []]
    except Exception as e:
        logger.error(f"Error getting staple exercises: {e}")
        return []


async def get_user_variation_percentage(user_id: str) -> int:
    """
    Get user's variation percentage setting.
    Used by workout generation to control variety.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("users").select("variation_percentage").eq("id", user_id).execute()
        if result.data:
            return result.data[0].get("variation_percentage", 30)
        return 30  # Default
    except Exception as e:
        logger.error(f"Error getting variation percentage: {e}")
        return 30


async def log_exercise_rotation(
    user_id: str,
    workout_id: Optional[str],
    week_start_date: date,
    exercise_added: str,
    exercise_removed: Optional[str] = None,
    muscle_group: Optional[str] = None,
    rotation_reason: str = "variety"
):
    """
    Log an exercise rotation for week-over-week tracking.
    Called during workout generation when exercises are swapped.
    """
    try:
        db = get_supabase_db()
        db.client.table("exercise_rotations").insert({
            "user_id": user_id,
            "workout_id": workout_id,
            "week_start_date": week_start_date.isoformat(),
            "exercise_added": exercise_added,
            "exercise_removed": exercise_removed,
            "muscle_group": muscle_group,
            "rotation_reason": rotation_reason
        }).execute()
    except Exception as e:
        logger.error(f"Error logging exercise rotation: {e}")


# =============================================================================
# Avoided Exercises Endpoints
# =============================================================================

@router.get("/avoided-exercises/{user_id}", response_model=List[AvoidedExerciseResponse])
async def get_avoided_exercises(user_id: str, include_expired: bool = False):
    """
    Get all exercises the user wants to avoid.

    By default, only returns active avoidances (not expired temporary ones).
    Set include_expired=true to get all entries.
    """
    logger.info(f"Getting avoided exercises for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("avoided_exercises").select("*").eq("user_id", user_id)

        if not include_expired:
            # Filter out expired temporary avoidances
            today = date.today().isoformat()
            # Get non-temporary OR temporary with no end_date OR temporary with future end_date
            query = query.or_(
                f"is_temporary.eq.false,end_date.is.null,end_date.gt.{today}"
            )

        result = query.order("created_at", desc=True).execute()

        exercises = []
        for row in result.data or []:
            exercises.append(AvoidedExerciseResponse(
                id=row["id"],
                exercise_name=row["exercise_name"],
                exercise_id=row.get("exercise_id"),
                reason=row.get("reason"),
                is_temporary=row.get("is_temporary", False),
                end_date=row.get("end_date"),
                created_at=row["created_at"],
            ))

        return exercises

    except Exception as e:
        logger.error(f"Error getting avoided exercises: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/avoided-exercises/{user_id}", response_model=AvoidedExerciseResponse)
async def add_avoided_exercise(user_id: str, request: AvoidedExerciseCreate):
    """
    Add an exercise to the user's avoidance list.

    The AI will completely skip this exercise when generating workouts.
    Useful for injuries, equipment limitations, or personal preference.
    """
    logger.info(f"Adding avoided exercise '{request.exercise_name}' for user {user_id}")

    try:
        db = get_supabase_db()

        # Check if already exists
        existing = db.client.table("avoided_exercises").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).execute()

        if existing.data:
            raise HTTPException(status_code=400, detail="Exercise is already in avoidance list")

        # Insert new avoided exercise
        insert_data = {
            "user_id": user_id,
            "exercise_name": request.exercise_name,
            "exercise_id": request.exercise_id,
            "reason": request.reason,
            "is_temporary": request.is_temporary,
            "end_date": request.end_date.isoformat() if request.end_date else None,
        }

        result = db.client.table("avoided_exercises").insert(insert_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to add avoided exercise")

        row = result.data[0]

        # Clear future incomplete workouts so they regenerate without the avoided exercise
        # This ensures the avoided exercise is excluded from today's and upcoming workouts
        try:
            today_str = date.today().isoformat()
            deleted = db.client.table("workouts").delete().eq(
                "user_id", user_id
            ).gte(
                "scheduled_date", today_str
            ).eq(
                "is_completed", False
            ).execute()
            deleted_count = len(deleted.data) if deleted.data else 0
            if deleted_count > 0:
                logger.info(f"🚫 Cleared {deleted_count} future workouts to exclude avoided exercise: {request.exercise_name}")
        except Exception as e:
            logger.warning(f"Could not clear future workouts for avoided exercise: {e}")

        return AvoidedExerciseResponse(
            id=row["id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            reason=row.get("reason"),
            is_temporary=row.get("is_temporary", False),
            end_date=row.get("end_date"),
            created_at=row["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding avoided exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/avoided-exercises/{user_id}/{exercise_id}", response_model=AvoidedExerciseResponse)
async def update_avoided_exercise(user_id: str, exercise_id: str, request: AvoidedExerciseCreate):
    """
    Update an avoided exercise entry.
    """
    logger.info(f"Updating avoided exercise {exercise_id} for user {user_id}")

    try:
        db = get_supabase_db()

        update_data = {
            "exercise_name": request.exercise_name,
            "exercise_id": request.exercise_id,
            "reason": request.reason,
            "is_temporary": request.is_temporary,
            "end_date": request.end_date.isoformat() if request.end_date else None,
            "updated_at": datetime.utcnow().isoformat(),
        }

        result = db.client.table("avoided_exercises").update(update_data).eq(
            "id", exercise_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Avoided exercise not found")

        row = result.data[0]
        return AvoidedExerciseResponse(
            id=row["id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            reason=row.get("reason"),
            is_temporary=row.get("is_temporary", False),
            end_date=row.get("end_date"),
            created_at=row["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating avoided exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/avoided-exercises/{user_id}/{exercise_id}")
async def remove_avoided_exercise(user_id: str, exercise_id: str):
    """
    Remove an exercise from the avoidance list.

    The AI will be able to use this exercise again in workouts.
    """
    logger.info(f"Removing avoided exercise {exercise_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("avoided_exercises").delete().eq(
            "id", exercise_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Avoided exercise not found")

        return {"success": True, "message": "Exercise removed from avoidance list"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing avoided exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Avoided Muscles Endpoints
# =============================================================================

@router.get("/avoided-muscles/{user_id}", response_model=List[AvoidedMuscleResponse])
async def get_avoided_muscles(user_id: str, include_expired: bool = False):
    """
    Get all muscle groups the user wants to avoid.

    By default, only returns active avoidances (not expired temporary ones).
    Set include_expired=true to get all entries.
    """
    logger.info(f"Getting avoided muscles for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("avoided_muscles").select("*").eq("user_id", user_id)

        if not include_expired:
            today = date.today().isoformat()
            query = query.or_(
                f"is_temporary.eq.false,end_date.is.null,end_date.gt.{today}"
            )

        result = query.order("created_at", desc=True).execute()

        muscles = []
        for row in result.data or []:
            muscles.append(AvoidedMuscleResponse(
                id=row["id"],
                muscle_group=row["muscle_group"],
                reason=row.get("reason"),
                is_temporary=row.get("is_temporary", False),
                end_date=row.get("end_date"),
                severity=row.get("severity", "avoid"),
                created_at=row["created_at"],
            ))

        return muscles

    except Exception as e:
        logger.error(f"Error getting avoided muscles: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/avoided-muscles/{user_id}", response_model=AvoidedMuscleResponse)
async def add_avoided_muscle(user_id: str, request: AvoidedMuscleCreate):
    """
    Add a muscle group to the user's avoidance list.

    The AI will skip or reduce exercises targeting this muscle based on severity:
    - 'avoid': Completely skip all exercises targeting this muscle
    - 'reduce': Limit exercises targeting this muscle

    Useful for injuries, recovery, or limitations.
    """
    logger.info(f"Adding avoided muscle '{request.muscle_group}' for user {user_id}")

    try:
        db = get_supabase_db()

        # Check if already exists
        existing = db.client.table("avoided_muscles").select("id").eq(
            "user_id", user_id
        ).eq("muscle_group", request.muscle_group).execute()

        if existing.data:
            raise HTTPException(status_code=400, detail="Muscle group is already in avoidance list")

        # Insert new avoided muscle
        insert_data = {
            "user_id": user_id,
            "muscle_group": request.muscle_group,
            "reason": request.reason,
            "is_temporary": request.is_temporary,
            "end_date": request.end_date.isoformat() if request.end_date else None,
            "severity": request.severity,
        }

        result = db.client.table("avoided_muscles").insert(insert_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to add avoided muscle")

        row = result.data[0]

        # Clear future incomplete workouts so they regenerate with muscle avoidance applied
        # This ensures exercises targeting this muscle are excluded/reduced in upcoming workouts
        try:
            today_str = date.today().isoformat()
            deleted = db.client.table("workouts").delete().eq(
                "user_id", user_id
            ).gte(
                "scheduled_date", today_str
            ).eq(
                "is_completed", False
            ).execute()
            deleted_count = len(deleted.data) if deleted.data else 0
            if deleted_count > 0:
                logger.info(f"🚫 Cleared {deleted_count} future workouts to {request.severity} muscle: {request.muscle_group}")
        except Exception as e:
            logger.warning(f"Could not clear future workouts for avoided muscle: {e}")

        return AvoidedMuscleResponse(
            id=row["id"],
            muscle_group=row["muscle_group"],
            reason=row.get("reason"),
            is_temporary=row.get("is_temporary", False),
            end_date=row.get("end_date"),
            severity=row.get("severity", "avoid"),
            created_at=row["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding avoided muscle: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/avoided-muscles/{user_id}/{muscle_id}", response_model=AvoidedMuscleResponse)
async def update_avoided_muscle(user_id: str, muscle_id: str, request: AvoidedMuscleCreate):
    """
    Update an avoided muscle entry.
    """
    logger.info(f"Updating avoided muscle {muscle_id} for user {user_id}")

    try:
        db = get_supabase_db()

        update_data = {
            "muscle_group": request.muscle_group,
            "reason": request.reason,
            "is_temporary": request.is_temporary,
            "end_date": request.end_date.isoformat() if request.end_date else None,
            "severity": request.severity,
            "updated_at": datetime.utcnow().isoformat(),
        }

        result = db.client.table("avoided_muscles").update(update_data).eq(
            "id", muscle_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Avoided muscle not found")

        row = result.data[0]
        return AvoidedMuscleResponse(
            id=row["id"],
            muscle_group=row["muscle_group"],
            reason=row.get("reason"),
            is_temporary=row.get("is_temporary", False),
            end_date=row.get("end_date"),
            severity=row.get("severity", "avoid"),
            created_at=row["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating avoided muscle: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/avoided-muscles/{user_id}/{muscle_id}")
async def remove_avoided_muscle(user_id: str, muscle_id: str):
    """
    Remove a muscle group from the avoidance list.

    The AI will be able to target this muscle group again in workouts.
    """
    logger.info(f"Removing avoided muscle {muscle_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("avoided_muscles").delete().eq(
            "id", muscle_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Avoided muscle not found")

        return {"success": True, "message": "Muscle group removed from avoidance list"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing avoided muscle: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/muscle-groups")
async def get_muscle_groups():
    """
    Get list of all available muscle groups that can be avoided.
    """
    return {
        "muscle_groups": MUSCLE_GROUPS,
        "primary": ["chest", "back", "shoulders", "biceps", "triceps", "core",
                    "quadriceps", "hamstrings", "glutes", "calves"],
        "secondary": ["lower_back", "upper_back", "lats", "traps", "forearms",
                      "hip_flexors", "adductors", "abductors", "abs", "obliques"],
    }


# =============================================================================
# Exercise Substitute Suggestions (for injuries/limitations)
# =============================================================================

class SubstituteRequest(BaseModel):
    """Request for exercise substitutes."""
    exercise_name: str = Field(..., min_length=1, max_length=200)
    reason: Optional[str] = None  # e.g., "knee injury", "shoulder pain"


class SubstituteExercise(BaseModel):
    """A suggested substitute exercise."""
    name: str
    muscle_group: Optional[str] = None
    equipment: Optional[str] = None
    difficulty: Optional[str] = None
    is_safe_for_reason: bool = True
    library_id: Optional[str] = None
    gif_url: Optional[str] = None


class SubstituteResponse(BaseModel):
    """Response with substitute suggestions."""
    original_exercise: str
    reason: Optional[str]
    substitutes: List[SubstituteExercise]
    message: str


# Extended injury mappings for more comprehensive coverage
INJURY_KEYWORDS = {
    "knee": ["knee", "knees", "patella", "acl", "mcl", "meniscus"],
    "shoulder": ["shoulder", "shoulders", "rotator", "deltoid"],
    "lower_back": ["back", "lower back", "lumbar", "spine", "disc"],
    "elbow": ["elbow", "elbows", "tennis elbow", "golfer"],
    "wrist": ["wrist", "wrists", "carpal"],
    "hip": ["hip", "hips", "hip flexor"],
    "ankle": ["ankle", "ankles", "achilles"],
    "neck": ["neck", "cervical"],
}

# Exercises to avoid per injury type (more comprehensive)
INJURY_EXERCISE_CONTRAINDICATIONS = {
    "knee": [
        "squat", "lunge", "leg press", "leg extension", "leg curl",
        "jump", "box jump", "step up", "pistol", "bulgarian",
        "walking lunge", "reverse lunge", "goblet squat", "hack squat",
        "sissy squat", "front squat", "back squat"
    ],
    "shoulder": [
        "overhead press", "military press", "lateral raise", "front raise",
        "bench press", "incline press", "dip", "upright row",
        "arnold press", "push press", "handstand", "shoulder press"
    ],
    "lower_back": [
        "deadlift", "barbell row", "good morning", "back squat",
        "bent over row", "hyperextension", "seated row",
        "romanian deadlift", "stiff leg deadlift"
    ],
    "elbow": [
        "tricep pushdown", "skull crusher", "close grip bench",
        "bicep curl", "hammer curl", "preacher curl", "french press"
    ],
    "wrist": [
        "bench press", "push up", "front squat", "wrist curl",
        "plank", "handstand"
    ],
    "hip": [
        "hip thrust", "squat", "deadlift", "lunge", "leg raise",
        "hip flexor stretch", "good morning"
    ],
    "ankle": [
        "calf raise", "jump", "running", "box jump", "skip",
        "squat", "lunge"
    ],
    "neck": [
        "shoulder shrug", "upright row", "behind neck press"
    ],
}

# Safe alternatives per muscle group (injury-friendly options)
SAFE_ALTERNATIVES = {
    "knee": {
        "quadriceps": [
            {"name": "Seated Leg Extension (Light)", "equipment": "machine", "note": "Use light weight, avoid full extension"},
            {"name": "Wall Sit (Partial)", "equipment": "bodyweight", "note": "Don't go too deep"},
            {"name": "Terminal Knee Extension", "equipment": "band", "note": "Rehab-friendly"},
            {"name": "Straight Leg Raise", "equipment": "bodyweight", "note": "No knee stress"},
        ],
        "hamstrings": [
            {"name": "Lying Leg Curl", "equipment": "machine", "note": "No knee loading"},
            {"name": "Glute Ham Raise", "equipment": "bodyweight", "note": "Focus on hamstrings"},
            {"name": "Nordic Curl (Assisted)", "equipment": "bodyweight", "note": "Use support"},
        ],
        "glutes": [
            {"name": "Glute Bridge", "equipment": "bodyweight", "note": "Knee-friendly"},
            {"name": "Hip Thrust", "equipment": "barbell", "note": "No knee stress"},
            {"name": "Cable Kickback", "equipment": "cable", "note": "Isolation"},
            {"name": "Clamshell", "equipment": "band", "note": "Rehab-friendly"},
        ],
    },
    "shoulder": {
        "chest": [
            {"name": "Flat Dumbbell Press", "equipment": "dumbbells", "note": "Neutral grip"},
            {"name": "Cable Fly", "equipment": "cable", "note": "Controlled movement"},
            {"name": "Push-Up (Modified)", "equipment": "bodyweight", "note": "Don't go too deep"},
            {"name": "Pec Deck Machine", "equipment": "machine", "note": "Fixed path"},
        ],
        "shoulders": [
            {"name": "Face Pull", "equipment": "cable", "note": "External rotation focus"},
            {"name": "Reverse Fly", "equipment": "dumbbells", "note": "Rear delts, shoulder-safe"},
            {"name": "Band Pull Apart", "equipment": "band", "note": "Rehab-friendly"},
        ],
    },
    "lower_back": {
        "back": [
            {"name": "Lat Pulldown", "equipment": "cable", "note": "Seated, no back stress"},
            {"name": "Chest Supported Row", "equipment": "machine", "note": "Back supported"},
            {"name": "Seated Cable Row", "equipment": "cable", "note": "Keep back neutral"},
            {"name": "Single Arm Row (Bench)", "equipment": "dumbbell", "note": "One arm at a time"},
        ],
        "glutes": [
            {"name": "Hip Thrust", "equipment": "barbell", "note": "Spine neutral"},
            {"name": "Glute Bridge", "equipment": "bodyweight", "note": "No back loading"},
            {"name": "Cable Kickback", "equipment": "cable", "note": "Isolation"},
        ],
    },
}


def detect_injury_type(reason: Optional[str]) -> Optional[str]:
    """Detect injury type from reason text."""
    if not reason:
        return None

    reason_lower = reason.lower()
    for injury_type, keywords in INJURY_KEYWORDS.items():
        if any(kw in reason_lower for kw in keywords):
            return injury_type
    return None


def get_exercise_muscle_group(exercise_name: str) -> Optional[str]:
    """Determine muscle group from exercise name."""
    name_lower = exercise_name.lower()

    if any(x in name_lower for x in ["squat", "leg press", "leg extension", "lunge"]):
        return "quadriceps"
    elif any(x in name_lower for x in ["leg curl", "hamstring", "romanian"]):
        return "hamstrings"
    elif any(x in name_lower for x in ["deadlift", "hip thrust", "glute"]):
        return "glutes"
    elif any(x in name_lower for x in ["bench", "chest", "push", "fly", "pec"]):
        return "chest"
    elif any(x in name_lower for x in ["row", "pulldown", "pull up", "lat"]):
        return "back"
    elif any(x in name_lower for x in ["press", "shoulder", "lateral", "raise"]):
        return "shoulders"
    elif any(x in name_lower for x in ["curl", "bicep"]):
        return "biceps"
    elif any(x in name_lower for x in ["tricep", "pushdown", "extension", "skull"]):
        return "triceps"

    return None


@router.post("/suggest-substitutes", response_model=SubstituteResponse)
async def suggest_exercise_substitutes(request: SubstituteRequest):
    """
    Get safe substitute exercises when avoiding a specific exercise.

    Takes an exercise name and optional reason (e.g., "knee injury")
    and returns appropriate alternatives that work the same muscles
    while avoiding the problematic movement.
    """
    logger.info(f"Getting substitutes for: {request.exercise_name}, reason: {request.reason}")

    try:
        db = get_supabase_db()
        substitutes = []

        # Detect injury type from reason
        injury_type = detect_injury_type(request.reason)
        muscle_group = get_exercise_muscle_group(request.exercise_name)

        # 1. First, try to get safe alternatives from our curated list
        if injury_type and injury_type in SAFE_ALTERNATIVES:
            injury_alternatives = SAFE_ALTERNATIVES[injury_type]
            if muscle_group and muscle_group in injury_alternatives:
                for alt in injury_alternatives[muscle_group]:
                    substitutes.append(SubstituteExercise(
                        name=alt["name"],
                        equipment=alt.get("equipment"),
                        is_safe_for_reason=True,
                    ))

        # 2. Get general substitutes from EXERCISE_SUBSTITUTES
        from core.exercise_data import EXERCISE_SUBSTITUTES
        exercise_lower = request.exercise_name.lower()

        for key, subs in EXERCISE_SUBSTITUTES.items():
            if key in exercise_lower:
                for sub in subs:
                    # Check if this substitute is safe for the injury
                    is_safe = True
                    if injury_type and injury_type in INJURY_EXERCISE_CONTRAINDICATIONS:
                        contraindicated = INJURY_EXERCISE_CONTRAINDICATIONS[injury_type]
                        is_safe = not any(c in sub.lower() for c in contraindicated)

                    if is_safe:
                        # Check if already added
                        if not any(s.name.lower() == sub.lower() for s in substitutes):
                            substitutes.append(SubstituteExercise(
                                name=sub,
                                is_safe_for_reason=is_safe,
                            ))

        # 3. Search exercise library for similar exercises
        if muscle_group:
            try:
                library_result = db.client.table("exercise_library").select(
                    "id", "name", "body_part", "equipment", "gif_url"
                ).ilike("body_part", f"%{muscle_group}%").limit(10).execute()

                for row in library_result.data or []:
                    exercise_name_lib = row.get("name", "")

                    # Skip if it's the original exercise
                    if exercise_name_lib.lower() == request.exercise_name.lower():
                        continue

                    # Check if safe for injury
                    is_safe = True
                    if injury_type and injury_type in INJURY_EXERCISE_CONTRAINDICATIONS:
                        contraindicated = INJURY_EXERCISE_CONTRAINDICATIONS[injury_type]
                        is_safe = not any(c in exercise_name_lib.lower() for c in contraindicated)

                    if is_safe:
                        # Check if already added
                        if not any(s.name.lower() == exercise_name_lib.lower() for s in substitutes):
                            substitutes.append(SubstituteExercise(
                                name=exercise_name_lib,
                                muscle_group=row.get("body_part"),
                                equipment=row.get("equipment"),
                                library_id=row.get("id"),
                                gif_url=row.get("gif_url"),
                                is_safe_for_reason=is_safe,
                            ))
            except Exception as e:
                logger.warning(f"Error searching exercise library: {e}")

        # Limit to top 8 substitutes
        substitutes = substitutes[:8]

        # Generate helpful message
        if injury_type:
            message = f"Here are {len(substitutes)} safe alternatives that avoid {injury_type} stress"
        elif substitutes:
            message = f"Found {len(substitutes)} alternative exercises for {request.exercise_name}"
        else:
            message = "No specific substitutes found, but you can search the exercise library for alternatives"

        return SubstituteResponse(
            original_exercise=request.exercise_name,
            reason=request.reason,
            substitutes=substitutes,
            message=message,
        )

    except Exception as e:
        logger.error(f"Error getting substitutes: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/injury-exercises/{injury_type}")
async def get_exercises_to_avoid_for_injury(injury_type: str):
    """
    Get list of exercises to avoid for a specific injury type.

    Useful when a user says "I have a knee problem" - this returns
    all exercises they should consider avoiding.
    """
    injury_lower = injury_type.lower()

    # Map common injury descriptions to types
    detected_type = detect_injury_type(injury_lower)
    if detected_type:
        injury_lower = detected_type

    exercises_to_avoid = INJURY_EXERCISE_CONTRAINDICATIONS.get(injury_lower, [])
    safe_alternatives = SAFE_ALTERNATIVES.get(injury_lower, {})

    return {
        "injury_type": injury_lower,
        "exercises_to_avoid": exercises_to_avoid,
        "safe_alternatives_by_muscle": safe_alternatives,
        "message": f"Found {len(exercises_to_avoid)} exercises that may stress your {injury_lower}"
    }


# =============================================================================
# Helper Functions for Avoidance Lists (for use by other modules)
# =============================================================================

async def get_user_avoided_exercises(user_id: str) -> List[str]:
    """
    Get list of exercise names to avoid for a user.
    Used by RAG service and workout generation.
    Only returns active avoidances (not expired).
    """
    try:
        db = get_supabase_db()
        today = date.today().isoformat()

        result = db.client.table("avoided_exercises").select("exercise_name").eq(
            "user_id", user_id
        ).or_(
            f"is_temporary.eq.false,end_date.is.null,end_date.gt.{today}"
        ).execute()

        return [row["exercise_name"] for row in result.data or []]
    except Exception as e:
        logger.error(f"Error getting avoided exercises: {e}")
        return []


async def get_user_avoided_muscles(user_id: str) -> List[dict]:
    """
    Get list of muscle groups to avoid for a user with severity.
    Used by RAG service and workout generation.
    Only returns active avoidances (not expired).

    Returns list of dicts: [{"muscle_group": "lower_back", "severity": "avoid"}, ...]
    """
    try:
        db = get_supabase_db()
        today = date.today().isoformat()

        result = db.client.table("avoided_muscles").select(
            "muscle_group", "severity"
        ).eq("user_id", user_id).or_(
            f"is_temporary.eq.false,end_date.is.null,end_date.gt.{today}"
        ).execute()

        return [
            {"muscle_group": row["muscle_group"], "severity": row.get("severity", "avoid")}
            for row in result.data or []
        ]
    except Exception as e:
        logger.error(f"Error getting avoided muscles: {e}")
        return []


async def is_exercise_avoided(user_id: str, exercise_name: str) -> bool:
    """
    Check if a specific exercise is in the user's avoidance list.
    """
    avoided = await get_user_avoided_exercises(user_id)
    return any(
        a.lower() == exercise_name.lower() for a in avoided
    )


async def is_muscle_avoided(user_id: str, muscle_group: str) -> tuple[bool, str]:
    """
    Check if a muscle group is avoided and return severity.
    Returns (is_avoided, severity) tuple.
    """
    avoided = await get_user_avoided_muscles(user_id)
    for item in avoided:
        if item["muscle_group"].lower() == muscle_group.lower():
            return (True, item["severity"])
    return (False, "")


# =============================================================================
# Recent Swaps Endpoint
# =============================================================================

class RecentSwapResponse(BaseModel):
    """Response for a recent exercise swap."""
    name: str
    target_muscle: Optional[str] = None
    equipment: Optional[str] = None
    body_part: Optional[str] = None
    last_used: Optional[datetime] = None
    swap_count: int = 1


@router.get("/recent-swaps", response_model=List[RecentSwapResponse])
async def get_recent_swaps(
    user_id: str = Query(..., description="User ID"),
    limit: int = Query(default=10, le=50, description="Max number of swaps to return"),
):
    """
    Get user's recent exercise swaps for quick re-selection.

    Returns exercises the user has recently swapped TO, deduplicated
    and sorted by most recent first. Useful for showing a "Recent" tab
    in the exercise swap sheet.
    """
    logger.info(f"Getting recent swaps for user {user_id}, limit {limit}")

    try:
        db = get_supabase_db()

        # Get distinct recent exercises the user has swapped TO
        result = db.client.table("exercise_swaps").select(
            "new_exercise, swapped_at"
        ).eq("user_id", user_id).order(
            "swapped_at", desc=True
        ).limit(limit * 3).execute()  # Get extra to account for deduplication

        # Deduplicate and count occurrences
        seen = {}
        for row in result.data or []:
            name = row["new_exercise"]
            name_lower = name.lower()
            if name_lower not in seen:
                seen[name_lower] = {
                    "name": name,
                    "last_used": row["swapped_at"],
                    "count": 1
                }
            else:
                seen[name_lower]["count"] += 1

        # Get exercise details from library for each unique exercise
        recent_exercises = []
        for name_lower, data in list(seen.items())[:limit]:
            exercise_info = db.client.table("exercise_library_cleaned").select(
                "name, target_muscle, equipment, body_part"
            ).ilike("name", data["name"]).limit(1).execute()

            if exercise_info.data:
                ex = exercise_info.data[0]
                recent_exercises.append(RecentSwapResponse(
                    name=ex.get("name") or data["name"],
                    target_muscle=ex.get("target_muscle"),
                    equipment=ex.get("equipment"),
                    body_part=ex.get("body_part"),
                    last_used=data["last_used"],
                    swap_count=data["count"],
                ))
            else:
                # Exercise not in library, still include it
                recent_exercises.append(RecentSwapResponse(
                    name=data["name"],
                    last_used=data["last_used"],
                    swap_count=data["count"],
                ))

        logger.info(f"Found {len(recent_exercises)} recent swaps for user {user_id}")
        return recent_exercises

    except Exception as e:
        logger.error(f"Error getting recent swaps: {e}")
        raise HTTPException(status_code=500, detail=str(e))
