"""
Exercise Preferences API - Staple exercises, variation control, and avoidance lists.
"""
from pydantic import BaseModel, Field, field_validator
from core.db import get_supabase_db
from fastapi import APIRouter, HTTPException, Query, Depends, Request
from typing import List, Optional
from datetime import datetime, date, timedelta
import logging
import json

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.timezone_utils import user_today_date

# Models and constants
from .exercise_preferences_models import *  # noqa: F401, F403
from .exercise_preferences_models import (
    StapleExerciseCreate, StapleExerciseResponse, StapleExerciseUpdate,
    VariationPreferenceUpdate, VariationPreferenceResponse,
    WeekComparisonResponse, ExerciseRotationResponse,
    AvoidedExerciseCreate, AvoidedExerciseResponse,
    AvoidedMuscleCreate, AvoidedMuscleResponse,
    SetsLimitsUpdate, SetsLimitsResponse,
    MUSCLE_GROUPS,
)
from .exercise_preferences_endpoints import router as _endpoints_router

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/exercise-preferences", tags=["Exercise Preferences"])
router.include_router(_endpoints_router)


# Models imported from exercise_preferences_models.py

# NOTE: The class definitions below are kept for backward compatibility
# with any code that may import them from this module. They shadow the
# imports from exercise_preferences_models.py but are identical.
class _InlineModelsRemoved:
    """Request to add a staple exercise."""
    user_id: str
    exercise_name: str = Field(..., min_length=1, max_length=200)
    library_id: Optional[str] = None
    muscle_group: Optional[str] = None
    reason: Optional[str] = Field(default=None, max_length=100)  # "core_compound", "favorite", "rehab"
    gym_profile_id: Optional[str] = None
    section: Optional[str] = Field(default="main")
    # User-provided cardio overrides (optional)
    user_duration_seconds: Optional[int] = None
    user_speed_mph: Optional[float] = None
    user_incline_percent: Optional[float] = None
    user_rpm: Optional[int] = None
    user_resistance_level: Optional[int] = None
    user_stroke_rate_spm: Optional[int] = None
    # Strength overrides (optional)
    user_sets: Optional[int] = None
    user_reps: Optional[str] = None  # "10" or "8-12" format
    user_rest_seconds: Optional[int] = None
    user_weight_lbs: Optional[float] = None  # User-specified weight in lbs
    # Day-of-week targeting (optional): [0,2,4] = Mon/Wed/Fri, None = all days
    target_days: Optional[List[int]] = None

    @field_validator('section')
    @classmethod
    def validate_section(cls, v):
        valid_sections = ('main', 'warmup', 'stretches')
        if v and v not in valid_sections:
            raise ValueError(f"section must be one of {valid_sections}")
        return v or 'main'

    @field_validator('target_days')
    @classmethod
    def validate_target_days(cls, v):
        if v is not None:
            if not all(isinstance(d, int) and 0 <= d <= 6 for d in v):
                raise ValueError("target_days must contain integers 0-6 (Mon=0, Sun=6)")
        return v


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
    # From join with gym_profiles
    gym_profile_id: Optional[str] = None
    gym_profile_name: Optional[str] = None
    gym_profile_color: Optional[str] = None
    # Section (main/warmup/stretches)
    section: str = "main"
    # Cardio metadata from exercise_library
    default_incline_percent: Optional[float] = None
    default_speed_mph: Optional[float] = None
    default_rpm: Optional[int] = None
    default_resistance_level: Optional[int] = None
    stroke_rate_spm: Optional[int] = None
    default_duration_seconds: Optional[int] = None
    # User overrides (take priority over library defaults)
    user_duration_seconds: Optional[int] = None
    user_speed_mph: Optional[float] = None
    user_incline_percent: Optional[float] = None
    user_rpm: Optional[int] = None
    user_resistance_level: Optional[int] = None
    user_stroke_rate_spm: Optional[int] = None
    # Strength overrides
    user_sets: Optional[int] = None
    user_reps: Optional[str] = None
    user_rest_seconds: Optional[int] = None
    # Day-of-week targeting
    target_days: Optional[List[int]] = None
    # Movement classification
    movement_pattern: Optional[str] = None
    energy_system: Optional[str] = None
    impact_level: Optional[str] = None
    category: Optional[str] = None


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
async def get_user_staples(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get all staple exercises for a user.

    Staple exercises are guaranteed to be included in generated workouts
    and are never rotated out during weekly variation.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
                gym_profile_id=row.get("gym_profile_id"),
                gym_profile_name=row.get("gym_profile_name"),
                gym_profile_color=row.get("gym_profile_color"),
                section=row.get("section", "main"),
                default_incline_percent=row.get("default_incline_percent"),
                default_speed_mph=row.get("default_speed_mph"),
                default_rpm=row.get("default_rpm"),
                default_resistance_level=row.get("default_resistance_level"),
                stroke_rate_spm=row.get("stroke_rate_spm"),
                default_duration_seconds=row.get("default_duration_seconds"),
                user_duration_seconds=row.get("user_duration_seconds"),
                user_speed_mph=row.get("user_speed_mph"),
                user_incline_percent=row.get("user_incline_percent"),
                user_rpm=row.get("user_rpm"),
                user_resistance_level=row.get("user_resistance_level"),
                user_stroke_rate_spm=row.get("user_stroke_rate_spm"),
                user_sets=row.get("user_sets"),
                user_reps=row.get("user_reps"),
                user_rest_seconds=row.get("user_rest_seconds"),
                target_days=row.get("target_days"),
                movement_pattern=row.get("movement_pattern"),
                energy_system=row.get("energy_system"),
                impact_level=row.get("impact_level"),
                category=row.get("category"),
            ))

        return staples

    except Exception as e:
        logger.error(f"Error getting staple exercises: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.post("/staples")
async def add_staple_exercise(http_request: Request, request: StapleExerciseCreate, current_user: dict = Depends(get_current_user)):
    """
    Add an exercise to user's staples.

    Staple exercises will:
    - Always be included in generated workouts (when targeting the same muscle)
    - Never appear in the "avoid recently used" list
    - Be visually marked in the workout UI
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Adding staple exercise '{request.exercise_name}' for user {request.user_id}")

    # Frontend may pass `custom_<uuid>` as library_id for not-yet-resolved custom
    # exercises. The DB column is uuid; strip the sentinel prefix and let the
    # backend resolve to the real custom_exercises row by name if needed.
    if request.library_id and isinstance(request.library_id, str) and request.library_id.startswith("custom_"):
        stripped = request.library_id[len("custom_"):]
        # If the stripped value is a valid uuid, use it; otherwise null out so we
        # store as a name-only staple (DB will accept null library_id).
        import re as _re
        if _re.fullmatch(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", stripped):
            request.library_id = stripped
        else:
            request.library_id = None

    try:
        db = get_supabase_db()

        # Check if already exists for this profile and section
        existing_query = db.client.table("staple_exercises").select("id").eq("user_id", request.user_id).eq("exercise_name", request.exercise_name).eq("section", request.section or "main")
        if request.gym_profile_id:
            existing_query = existing_query.eq("gym_profile_id", request.gym_profile_id)
        else:
            existing_query = existing_query.is_("gym_profile_id", "null")
        existing = existing_query.execute()

        if existing.data:
            raise HTTPException(status_code=400, detail="Exercise is already a staple")

        # Insert new staple
        insert_data = {
            "user_id": request.user_id,
            "exercise_name": request.exercise_name,
            "library_id": request.library_id,
            "muscle_group": request.muscle_group,
            "reason": request.reason,
            "gym_profile_id": request.gym_profile_id,
            "section": request.section or "main",
            "user_duration_seconds": request.user_duration_seconds,
            "user_speed_mph": request.user_speed_mph,
            "user_incline_percent": request.user_incline_percent,
            "user_rpm": request.user_rpm,
            "user_resistance_level": request.user_resistance_level,
            "user_stroke_rate_spm": request.user_stroke_rate_spm,
            "user_sets": request.user_sets,
            "user_reps": request.user_reps,
            "user_rest_seconds": request.user_rest_seconds,
            "user_weight_lbs": request.user_weight_lbs,
            "target_days": request.target_days,
        }

        # Remove None values to avoid DB errors for columns that may not exist yet
        insert_data = {k: v for k, v in insert_data.items() if v is not None}

        result = db.client.table("staple_exercises").insert(insert_data).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to add staple exercise"), "exercise_preferences")

        row = result.data[0]

        # Resolve staple/avoid conflict
        from api.v1.workouts.preference_engine import resolve_staple_avoid_conflict, apply_staple_to_workouts
        conflict_msg = resolve_staple_avoid_conflict(db, request.user_id, request.exercise_name, "staple")
        if conflict_msg:
            logger.info(f"Conflict resolved: {conflict_msg}")

        # Get exercise details from library if library_id provided
        body_part = None
        equipment = None
        gif_url = None
        default_incline_percent = None
        default_speed_mph = None
        default_rpm = None
        default_resistance_level = None
        stroke_rate_spm = None
        default_duration_seconds = None
        movement_pattern = None
        energy_system = None
        impact_level = None
        category = None

        if request.library_id:
            lib_result = db.client.table("exercise_library").select(
                "body_part, equipment, gif_url, "
                "default_incline_percent, default_speed_mph, default_rpm, "
                "default_resistance_level, stroke_rate_spm, default_duration_seconds, "
                "movement_pattern, energy_system, impact_level, category"
            ).eq("id", request.library_id).execute()
            if lib_result.data:
                lib_row = lib_result.data[0]
                body_part = lib_row.get("body_part")
                equipment = lib_row.get("equipment")
                gif_url = lib_row.get("gif_url")
                default_incline_percent = lib_row.get("default_incline_percent")
                default_speed_mph = lib_row.get("default_speed_mph")
                default_rpm = lib_row.get("default_rpm")
                default_resistance_level = lib_row.get("default_resistance_level")
                stroke_rate_spm = lib_row.get("stroke_rate_spm")
                default_duration_seconds = lib_row.get("default_duration_seconds")
                movement_pattern = lib_row.get("movement_pattern")
                energy_system = lib_row.get("energy_system")
                impact_level = lib_row.get("impact_level")
                category = lib_row.get("category")

        # Look up gym profile name/color if provided
        gym_profile_name = None
        gym_profile_color = None
        if request.gym_profile_id:
            try:
                profile_result = db.client.table("gym_profiles").select("name, color").eq("id", request.gym_profile_id).execute()
                if profile_result.data:
                    gym_profile_name = profile_result.data[0].get("name")
                    gym_profile_color = profile_result.data[0].get("color")
            except Exception as e:
                logger.debug(f"Failed to get gym profile info: {e}")

        # Apply staple to upcoming workouts (rule-based, no regeneration)
        staple_data = {
            "exercise_name": request.exercise_name,
            "section": request.section or "main",
            "muscle_group": request.muscle_group,
            "target_muscle": request.muscle_group,  # For compatibility
            "equipment": equipment,
            "gif_url": gif_url,
            "category": category,
            "user_sets": request.user_sets,
            "user_reps": request.user_reps,
            "user_rest_seconds": request.user_rest_seconds,
            "user_duration_seconds": request.user_duration_seconds,
            "user_speed_mph": request.user_speed_mph,
            "user_incline_percent": request.user_incline_percent,
            "user_rpm": request.user_rpm,
            "user_resistance_level": request.user_resistance_level,
            "user_stroke_rate_spm": request.user_stroke_rate_spm,
            "default_duration_seconds": default_duration_seconds,
            "target_days": request.target_days,
        }
        from core.timezone_utils import resolve_timezone
        tz_str = resolve_timezone(http_request, db, request.user_id)
        engine_result = await apply_staple_to_workouts(db, request.user_id, staple_data, timezone_str=tz_str)

        response = StapleExerciseResponse(
            id=row["id"],
            exercise_name=row["exercise_name"],
            library_id=row.get("library_id"),
            muscle_group=row.get("muscle_group"),
            reason=row.get("reason"),
            created_at=row["created_at"],
            body_part=body_part,
            equipment=equipment,
            gif_url=gif_url,
            gym_profile_id=request.gym_profile_id,
            gym_profile_name=gym_profile_name,
            gym_profile_color=gym_profile_color,
            section=request.section or "main",
            default_incline_percent=default_incline_percent,
            default_speed_mph=default_speed_mph,
            default_rpm=default_rpm,
            default_resistance_level=default_resistance_level,
            stroke_rate_spm=stroke_rate_spm,
            default_duration_seconds=default_duration_seconds,
            user_duration_seconds=request.user_duration_seconds,
            user_speed_mph=request.user_speed_mph,
            user_incline_percent=request.user_incline_percent,
            user_rpm=request.user_rpm,
            user_resistance_level=request.user_resistance_level,
            user_stroke_rate_spm=request.user_stroke_rate_spm,
            user_sets=request.user_sets,
            user_reps=request.user_reps,
            user_rest_seconds=request.user_rest_seconds,
            target_days=request.target_days,
            movement_pattern=movement_pattern,
            energy_system=energy_system,
            impact_level=impact_level,
            category=category,
        ).model_dump()
        response["changes"] = engine_result.get("changes", [])
        response["engine_message"] = engine_result.get("message", "")
        if conflict_msg:
            response["conflict_resolved"] = conflict_msg
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding staple exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


class StapleExerciseUpdate(BaseModel):
    """Request to update a staple exercise."""
    section: Optional[str] = None
    user_sets: Optional[int] = None
    user_reps: Optional[str] = None
    user_rest_seconds: Optional[int] = None
    user_weight_lbs: Optional[float] = None
    target_days: Optional[List[int]] = None
    user_duration_seconds: Optional[int] = None
    user_speed_mph: Optional[float] = None
    user_incline_percent: Optional[float] = None
    user_rpm: Optional[int] = None
    user_resistance_level: Optional[int] = None
    user_stroke_rate_spm: Optional[int] = None

    @field_validator('section')
    @classmethod
    def validate_section(cls, v):
        if v is not None:
            valid_sections = ('main', 'warmup', 'stretches')
            if v not in valid_sections:
                raise ValueError(f"section must be one of {valid_sections}")
        return v

    @field_validator('target_days')
    @classmethod
    def validate_target_days(cls, v):
        if v is not None:
            if not all(isinstance(d, int) and 0 <= d <= 6 for d in v):
                raise ValueError("target_days must contain integers 0-6 (Mon=0, Sun=6)")
        return v


@router.put("/staples/{user_id}/{staple_id}")
async def update_staple_exercise(user_id: str, staple_id: str, request: StapleExerciseUpdate, current_user: dict = Depends(get_current_user)):
    """
    Update a staple exercise's settings (section, sets/reps/rest, target days, cardio params).
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating staple exercise {staple_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Build update data from non-None fields
        update_data = {}
        if request.section is not None:
            update_data["section"] = request.section
        if request.user_sets is not None:
            update_data["user_sets"] = request.user_sets
        if request.user_reps is not None:
            update_data["user_reps"] = request.user_reps
        if request.user_rest_seconds is not None:
            update_data["user_rest_seconds"] = request.user_rest_seconds
        if request.user_weight_lbs is not None:
            update_data["user_weight_lbs"] = request.user_weight_lbs
        if request.target_days is not None:
            update_data["target_days"] = request.target_days
        if request.user_duration_seconds is not None:
            update_data["user_duration_seconds"] = request.user_duration_seconds
        if request.user_speed_mph is not None:
            update_data["user_speed_mph"] = request.user_speed_mph
        if request.user_incline_percent is not None:
            update_data["user_incline_percent"] = request.user_incline_percent
        if request.user_rpm is not None:
            update_data["user_rpm"] = request.user_rpm
        if request.user_resistance_level is not None:
            update_data["user_resistance_level"] = request.user_resistance_level
        if request.user_stroke_rate_spm is not None:
            update_data["user_stroke_rate_spm"] = request.user_stroke_rate_spm

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = db.client.table("staple_exercises").update(update_data).eq(
            "id", staple_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Staple exercise not found")

        row = result.data[0]

        # Fetch library details for the response
        body_part = None
        equipment = None
        gif_url = None
        if row.get("library_id"):
            lib_result = db.client.table("exercise_library").select(
                "body_part, equipment, gif_url"
            ).eq("id", row["library_id"]).execute()
            if lib_result.data:
                lib_row = lib_result.data[0]
                body_part = lib_row.get("body_part")
                equipment = lib_row.get("equipment")
                gif_url = lib_row.get("gif_url")

        # Fetch gym profile info if applicable
        gym_profile_name = None
        gym_profile_color = None
        if row.get("gym_profile_id"):
            profile_result = db.client.table("gym_profiles").select(
                "name, color"
            ).eq("id", row["gym_profile_id"]).execute()
            if profile_result.data:
                gym_profile_name = profile_result.data[0].get("name")
                gym_profile_color = profile_result.data[0].get("color")

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
            gym_profile_id=row.get("gym_profile_id"),
            gym_profile_name=gym_profile_name,
            gym_profile_color=gym_profile_color,
            section=row.get("section", "main"),
            user_sets=row.get("user_sets"),
            user_reps=row.get("user_reps"),
            user_rest_seconds=row.get("user_rest_seconds"),
            target_days=row.get("target_days"),
            user_duration_seconds=row.get("user_duration_seconds"),
            user_speed_mph=row.get("user_speed_mph"),
            user_incline_percent=row.get("user_incline_percent"),
            user_rpm=row.get("user_rpm"),
            user_resistance_level=row.get("user_resistance_level"),
            user_stroke_rate_spm=row.get("user_stroke_rate_spm"),
        ).model_dump()

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating staple exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.delete("/staples/{user_id}/{staple_id}")
async def remove_staple_exercise(user_id: str, staple_id: str, current_user: dict = Depends(get_current_user)):
    """
    Remove an exercise from user's staples.

    The exercise will now be subject to normal weekly variation rules.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        logger.error(f"Error removing staple exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


# =============================================================================
# Variation Percentage Endpoints
# =============================================================================

@router.get("/variation/{user_id}", response_model=VariationPreferenceResponse)
async def get_variation_preference(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get user's exercise variation percentage setting.

    0% = Keep same exercises every week (maximum consistency)
    30% = Default - rotate about 1/3 of exercises (balanced)
    100% = Maximum variety - new exercises every week
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        logger.error(f"Error getting variation preference: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.put("/variation", response_model=VariationPreferenceResponse)
async def update_variation_preference(request: VariationPreferenceUpdate, current_user: dict = Depends(get_current_user)):
    """
    Update user's exercise variation percentage.

    This controls how much the weekly workouts change:
    - Lower values = more consistency (same exercises)
    - Higher values = more variety (different exercises)

    Note: Staple exercises are never affected by this setting.
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        logger.error(f"Error updating variation preference: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


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
async def get_sets_limits(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get user's sets/reps limits preferences.

    These limits control:
    - max_sets_per_exercise: Maximum sets per exercise (1-10, default 4)
    - min_sets_per_exercise: Minimum sets per exercise (1-10, default 2)
    - max_reps_ceiling: Hard cap on reps if enforce_rep_ceiling is True
    - enforce_rep_ceiling: Whether to strictly enforce the max_reps_ceiling
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        logger.error(f"Error getting sets limits: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.put("/sets-limits", response_model=SetsLimitsResponse)
async def update_sets_limits(request: SetsLimitsUpdate, current_user: dict = Depends(get_current_user)):
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
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
            raise safe_internal_error(ValueError("Failed to update preferences"), "exercise_preferences")

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
        logger.error(f"Error updating sets limits: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


# =============================================================================
# Week Comparison Endpoints
# =============================================================================

@router.get("/week-comparison/{user_id}", response_model=WeekComparisonResponse)
async def get_week_comparison(
    request: Request,
    user_id: str,
    current_week_start: Optional[date] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Compare exercises between current week and previous week.

    Returns which exercises were:
    - Kept (appeared in both weeks)
    - Added (new this week)
    - Removed (not in this week but was last week)
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting week comparison for user {user_id}")

    try:
        db = get_supabase_db()

        # Default to current week's Monday
        if current_week_start is None:
            today = user_today_date(request, db, user_id)
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
        logger.error(f"Error getting week comparison: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.get("/rotations/{user_id}", response_model=List[ExerciseRotationResponse])
async def get_exercise_rotations(
    request: Request,
    user_id: str,
    weeks: int = Query(default=4, ge=1, le=12),
    current_user: dict = Depends(get_current_user),
):
    """
    Get recent exercise rotation history.

    Shows which exercises were added/removed during workout generation
    over the specified number of weeks.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting exercise rotations for user {user_id}, last {weeks} weeks")

    try:
        db = get_supabase_db()

        # Calculate date range
        today = user_today_date(request, db, user_id)
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
        logger.error(f"Error getting exercise rotations: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


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
        logger.error(f"Error getting staple exercises: {e}", exc_info=True)
        return []


async def get_user_staples_by_section(user_id: str, section: str) -> List[dict]:
    """
    Get staple exercises for a user filtered by section (main/warmup/stretches).
    Returns full exercise data with metadata from user_staples_with_details view.
    Used by warmup/stretch service to inject staple warmups/stretches.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("user_staples_with_details").select("*").eq(
            "user_id", user_id
        ).eq("section", section).execute()
        return result.data or []
    except Exception as e:
        logger.error(f"Error getting staples by section: {e}", exc_info=True)
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
        logger.error(f"Error getting variation percentage: {e}", exc_info=True)
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
        logger.error(f"Error logging exercise rotation: {e}", exc_info=True)


# =============================================================================
# Avoided Exercises Endpoints
# =============================================================================

@router.get("/avoided-exercises/{user_id}", response_model=List[AvoidedExerciseResponse])
async def get_avoided_exercises(request: Request, user_id: str, include_expired: bool = False, current_user: dict = Depends(get_current_user)):
    """
    Get all exercises the user wants to avoid.

    By default, only returns active avoidances (not expired temporary ones).
    Set include_expired=true to get all entries.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting avoided exercises for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("avoided_exercises").select("*").eq("user_id", user_id)

        if not include_expired:
            # Filter out expired temporary avoidances
            today = user_today_date(request, db, user_id).isoformat()
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
        logger.error(f"Error getting avoided exercises: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")



# Include secondary endpoints
router.include_router(_endpoints_router)
