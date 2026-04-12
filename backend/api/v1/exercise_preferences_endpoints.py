"""Secondary endpoints for exercise_preferences.  Sub-router included by main module.
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
from typing import List, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, Field
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.timezone_utils import user_today_date, get_user_today

from .exercise_preferences_models import (
    StapleExerciseCreate,
    StapleExerciseResponse,
    VariationPreferenceUpdate,
    VariationPreferenceResponse,
    WeekComparisonResponse,
    ExerciseRotationResponse,
    AvoidedExerciseCreate,
    AvoidedExerciseResponse,
    AvoidedMuscleCreate,
    AvoidedMuscleResponse,
    StapleExerciseUpdate,
    SetsLimitsUpdate,
    SetsLimitsResponse,
    SubstituteRequest,
    SubstituteExercise,
    SubstituteResponse,
    RecentSwapResponse,
)

router = APIRouter()

@router.post("/avoided-exercises/{user_id}")
async def add_avoided_exercise(user_id: str, request: AvoidedExerciseCreate, current_user: dict = Depends(get_current_user)):
    """
    Add an exercise to the user's avoidance list.

    The AI will completely skip this exercise when generating workouts.
    Useful for injuries, equipment limitations, or personal preference.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Adding avoided exercise '{request.exercise_name}' for user {user_id}")

    try:
        db = get_supabase_db()

        # Check if already exists
        existing = db.client.table("avoided_exercises").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).execute()

        if existing.data:
            raise HTTPException(status_code=400, detail="Exercise is already in avoidance list")

        # Resolve staple/avoid conflict
        from api.v1.workouts.preference_engine import resolve_staple_avoid_conflict, apply_avoid_exercise_to_workouts
        conflict_msg = resolve_staple_avoid_conflict(db, user_id, request.exercise_name, "avoid")
        if conflict_msg:
            logger.info(f"Conflict resolved: {conflict_msg}")

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
            raise safe_internal_error(ValueError("Failed to add avoided exercise"), "exercise_preferences")

        row = result.data[0]

        # Apply avoid to upcoming workouts (rule-based inline swaps, no regeneration)
        engine_result = await apply_avoid_exercise_to_workouts(db, user_id, request.exercise_name)

        response = AvoidedExerciseResponse(
            id=row["id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            reason=row.get("reason"),
            is_temporary=row.get("is_temporary", False),
            end_date=row.get("end_date"),
            created_at=row["created_at"],
        ).model_dump()
        response["changes"] = engine_result.get("changes", [])
        response["engine_message"] = engine_result.get("message", "")
        if conflict_msg:
            response["conflict_resolved"] = conflict_msg
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding avoided exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.put("/avoided-exercises/{user_id}/{exercise_id}", response_model=AvoidedExerciseResponse)
async def update_avoided_exercise(user_id: str, exercise_id: str, request: AvoidedExerciseCreate, current_user: dict = Depends(get_current_user)):
    """
    Update an avoided exercise entry.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        logger.error(f"Error updating avoided exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.delete("/avoided-exercises/{user_id}/{exercise_id}")
async def remove_avoided_exercise(user_id: str, exercise_id: str, current_user: dict = Depends(get_current_user)):
    """
    Remove an exercise from the avoidance list.

    The AI will be able to use this exercise again in workouts.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Removing avoided exercise {exercise_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("avoided_exercises").delete().eq(
            "id", exercise_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Avoided exercise not found")

        return {
            "success": True,
            "message": "Removed from avoid list. Existing workouts keep their current exercises. New workouts will include this exercise."
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing avoided exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


# =============================================================================
# Avoided Muscles Endpoints
# =============================================================================

@router.get("/avoided-muscles/{user_id}", response_model=List[AvoidedMuscleResponse])
async def get_avoided_muscles(request: Request, user_id: str, include_expired: bool = False, current_user: dict = Depends(get_current_user)):
    """
    Get all muscle groups the user wants to avoid.

    By default, only returns active avoidances (not expired temporary ones).
    Set include_expired=true to get all entries.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting avoided muscles for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("avoided_muscles").select("*").eq("user_id", user_id)

        if not include_expired:
            today = user_today_date(request, db, user_id).isoformat()
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
        logger.error(f"Error getting avoided muscles: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.post("/avoided-muscles/{user_id}")
async def add_avoided_muscle(user_id: str, request: AvoidedMuscleCreate, current_user: dict = Depends(get_current_user)):
    """
    Add a muscle group to the user's avoidance list.

    The AI will skip or reduce exercises targeting this muscle based on severity:
    - 'avoid': Completely skip all exercises targeting this muscle
    - 'reduce': Limit exercises targeting this muscle

    Useful for injuries, recovery, or limitations.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
            raise safe_internal_error(ValueError("Failed to add avoided muscle"), "exercise_preferences")

        row = result.data[0]

        # Apply muscle avoidance to upcoming workouts (rule-based inline swaps, no regeneration)
        from api.v1.workouts.preference_engine import apply_avoid_muscle_to_workouts
        engine_result = await apply_avoid_muscle_to_workouts(db, user_id, request.muscle_group, request.severity)

        response = AvoidedMuscleResponse(
            id=row["id"],
            muscle_group=row["muscle_group"],
            reason=row.get("reason"),
            is_temporary=row.get("is_temporary", False),
            end_date=row.get("end_date"),
            severity=row.get("severity", "avoid"),
            created_at=row["created_at"],
        ).model_dump()
        response["changes"] = engine_result.get("changes", [])
        response["engine_message"] = engine_result.get("message", "")
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding avoided muscle: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.put("/avoided-muscles/{user_id}/{muscle_id}")
async def update_avoided_muscle(user_id: str, muscle_id: str, request: AvoidedMuscleCreate, current_user: dict = Depends(get_current_user)):
    """
    Update an avoided muscle entry.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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

        # Re-apply muscle avoidance to upcoming workouts with updated settings
        from api.v1.workouts.preference_engine import apply_avoid_muscle_to_workouts
        engine_result = await apply_avoid_muscle_to_workouts(db, user_id, request.muscle_group, request.severity)

        response = AvoidedMuscleResponse(
            id=row["id"],
            muscle_group=row["muscle_group"],
            reason=row.get("reason"),
            is_temporary=row.get("is_temporary", False),
            end_date=row.get("end_date"),
            severity=row.get("severity", "avoid"),
            created_at=row["created_at"],
        ).model_dump()
        response["changes"] = engine_result.get("changes", [])
        response["engine_message"] = engine_result.get("message", "")
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating avoided muscle: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.delete("/avoided-muscles/{user_id}/{muscle_id}")
async def remove_avoided_muscle(user_id: str, muscle_id: str, current_user: dict = Depends(get_current_user)):
    """
    Remove a muscle group from the avoidance list.

    The AI will be able to target this muscle group again in workouts.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        logger.error(f"Error removing avoided muscle: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.get("/muscle-groups")
async def get_muscle_groups(current_user: dict = Depends(get_current_user)):
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
async def suggest_exercise_substitutes(request: SubstituteRequest, current_user: dict = Depends(get_current_user)):
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
                logger.warning(f"Error searching exercise library: {e}", exc_info=True)

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
        logger.error(f"Error getting substitutes: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")


@router.get("/injury-exercises/{injury_type}")
async def get_exercises_to_avoid_for_injury(injury_type: str, current_user: dict = Depends(get_current_user)):
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

async def get_user_avoided_exercises(user_id: str, timezone_str: str) -> List[str]:
    """
    Get list of exercise names to avoid for a user.
    Used by RAG service and workout generation.
    Only returns active avoidances (not expired).
    """
    try:
        db = get_supabase_db()
        today = date.fromisoformat(get_user_today(timezone_str)).isoformat()

        result = db.client.table("avoided_exercises").select("exercise_name").eq(
            "user_id", user_id
        ).or_(
            f"is_temporary.eq.false,end_date.is.null,end_date.gt.{today}"
        ).execute()

        return [row["exercise_name"] for row in result.data or []]
    except Exception as e:
        logger.error(f"Error getting avoided exercises: {e}", exc_info=True)
        return []


async def get_user_avoided_muscles(user_id: str, timezone_str: str) -> List[dict]:
    """
    Get list of muscle groups to avoid for a user with severity.
    Used by RAG service and workout generation.
    Only returns active avoidances (not expired).

    Returns list of dicts: [{"muscle_group": "lower_back", "severity": "avoid"}, ...]
    """
    try:
        db = get_supabase_db()
        today = date.fromisoformat(get_user_today(timezone_str)).isoformat()

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
        logger.error(f"Error getting avoided muscles: {e}", exc_info=True)
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
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's recent exercise swaps for quick re-selection.

    Returns exercises the user has recently swapped TO, deduplicated
    and sorted by most recent first. Useful for showing a "Recent" tab
    in the exercise swap sheet.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        logger.error(f"Error getting recent swaps: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_preferences")
