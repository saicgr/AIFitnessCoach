"""
Exercise Preferences API - Staple exercises and variation control.

This module allows users to:
1. Mark exercises as "staples" that should never be rotated out
2. Control their exercise variation percentage (0-100%)
3. View week-over-week exercise changes

Staple exercises are core lifts (like Squat, Bench Press, Deadlift) that users
want to keep in every workout regardless of the weekly variation setting.
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, date, timedelta
import logging

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
