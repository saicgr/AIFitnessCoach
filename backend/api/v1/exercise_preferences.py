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
