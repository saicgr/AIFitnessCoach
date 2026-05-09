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
import re
from typing import Any, Dict, List, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, Field
from cachetools import TTLCache
import logging
logger = logging.getLogger(__name__)

# In-memory cache for hot library reads (finding #20).
# 5-min TTL absorbs harness bursts; short enough that data backfills propagate.
_LIBRARY_CACHE: "TTLCache[Any, Any]" = TTLCache(maxsize=512, ttl=300)

# Whitespace + punctuation normalization (finding #15).
_NAME_PUNCT = re.compile(r"[_./()\\\-]+")
_NAME_WS = re.compile(r"\s+")


def _normalize_exercise_name(s: Optional[str]) -> str:
    """Collapse whitespace + replace punctuation with spaces. Preserves casing."""
    s = _NAME_PUNCT.sub(" ", s or "")
    s = _NAME_WS.sub(" ", s).strip()
    return s


def _normalize_for_matching(s: Optional[str]) -> str:
    return _normalize_exercise_name(s).lower()
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.timezone_utils import user_today_date, get_user_today

from .exercise_preferences_models import (
    MUSCLE_GROUPS,
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
# Models live in exercise_preferences_models.py — imported at top of file.
# =============================================================================


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

# Plyometric / ballistic keyword family — block under any joint injury (finding #12).
# `knee` and `lower_back` already include `jump`/`box jump`; this widens coverage to
# every joint that should not see ballistic loading during recovery.
_PLYO_KEYWORDS = [
    "jump", "plyo", "clap", "bound", "box jump", "tuck jump",
    "broad jump", "depth jump", "burpee",
]
for _joint in ("ankle", "hip", "wrist", "elbow", "shoulder", "neck", "knee", "lower_back"):
    _existing = INJURY_EXERCISE_CONTRAINDICATIONS.setdefault(_joint, [])
    for _kw in _PLYO_KEYWORDS:
        if _kw not in _existing:
            _existing.append(_kw)
del _joint, _existing, _kw

# Walking-lunge variants are knee-loading even when avoid_if[] data is missing.
# Belt-and-suspenders independent of migration 2040 backfill (finding #19).
for _kw in ("sandbag walking lunge", "treadmill walking lunge", "weighted walking lunge"):
    if _kw not in INJURY_EXERCISE_CONTRAINDICATIONS["knee"]:
        INJURY_EXERCISE_CONTRAINDICATIONS["knee"].append(_kw)
del _kw

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
    """Determine muscle group from exercise name. Order matters — most-specific first."""
    name_lower = exercise_name.lower()

    # Cardio / full-body conditioning (check FIRST so "burpee" doesn't fall through)
    if any(x in name_lower for x in ["burpee", "mountain climber", "jumping jack", "jump rope",
                                      "high knee", "skater", "sprint", "treadmill", "rowing machine",
                                      "battle rope", "bear crawl", "shuttle run"]):
        return "cardio"
    # Core / abs (Plank, Crunch, Twist, Leg Raise, Ab Wheel, Hanging Leg Raise, etc.)
    if any(x in name_lower for x in ["plank", "crunch", "sit-up", "situp", "russian twist",
                                      "ab wheel", "rollout", "hanging leg raise", "hanging knee",
                                      "leg raise", "flutter kick", "dead bug", "bird dog",
                                      "hollow hold", "v-up", "v up", "toe touch", "windshield",
                                      "woodchop", "pallof", "side bend", "cable crunch"]):
        return "core"
    # Plyometrics → quads/glutes (treat as quad-dominant)
    if any(x in name_lower for x in ["box jump", "jump squat", "broad jump", "tuck jump",
                                      "depth jump", "bound", "skip "]):
        return "quadriceps"
    # Calves
    if any(x in name_lower for x in ["calf raise", "calves", "donkey calf", "seated calf",
                                      "standing calf", "tibialis"]):
        return "calves"
    # Forearms / grip
    if any(x in name_lower for x in ["wrist curl", "farmer", "forearm", "grip"]):
        return "forearms"
    # Triceps (BEFORE biceps so "tricep extension" doesn't fall to triceps via "extension")
    if any(x in name_lower for x in ["tricep", "skull crusher", "skullcrusher", "pushdown",
                                      "kickback", "close grip bench", "diamond push", "dip"]):
        return "triceps"
    # Biceps
    if any(x in name_lower for x in ["bicep curl", "barbell curl", "dumbbell curl",
                                      "preacher curl", "concentration curl", "hammer curl",
                                      "ez bar curl", "ez-bar curl", "spider curl", "21s"]):
        return "biceps"
    # Hamstrings (BEFORE quadriceps so "leg curl" wins)
    if any(x in name_lower for x in ["leg curl", "lying leg curl", "seated leg curl",
                                      "hamstring", "romanian deadlift", "rdl", "good morning",
                                      "nordic", "stiff leg deadlift", "stiff-leg deadlift"]):
        return "hamstrings"
    # Glutes (BEFORE quadriceps for "hip thrust", "glute bridge")
    if any(x in name_lower for x in ["hip thrust", "glute bridge", "glute kickback",
                                      "cable kickback", "donkey kick", "fire hydrant",
                                      "clamshell", "single leg bridge", "frog pump"]):
        return "glutes"
    # Quadriceps
    if any(x in name_lower for x in ["squat", "leg press", "leg extension", "lunge",
                                      "step up", "step-up", "split squat", "wall sit",
                                      "sissy squat", "pistol squat", "bulgarian"]):
        return "quadriceps"
    # Deadlift family (compound posterior chain) — bucket under glutes for substitute purposes
    if any(x in name_lower for x in ["deadlift", "trap bar", "sumo deadlift",
                                      "conventional deadlift"]):
        return "glutes"
    # Chest
    if any(x in name_lower for x in ["bench press", "chest press", "incline press",
                                      "decline press", "push-up", "push up", "pushup",
                                      "chest fly", "cable fly", "dumbbell fly", "pec deck",
                                      "pec-deck", "svend press", "archer push"]):
        return "chest"
    # Back / lats
    if any(x in name_lower for x in ["row", "pulldown", "pull-up", "pull up", "pullup",
                                      "chin-up", "chin up", "chinup", "lat pulldown",
                                      "lat pull", "face pull", "shrug", "rear delt fly",
                                      "rear-delt fly", "inverted row", "t-bar", "t bar"]):
        return "back"
    # Shoulders (after triceps, after chest "press" specifics handled)
    if any(x in name_lower for x in ["overhead press", "shoulder press", "military press",
                                      "arnold press", "push press", "lateral raise",
                                      "front raise", "side raise", "upright row",
                                      "handstand", "pike push"]):
        return "shoulders"
    # Generic fallbacks for keywords missed above
    if any(x in name_lower for x in ["press"]):
        return "shoulders"
    if any(x in name_lower for x in ["curl"]):
        return "biceps"
    if any(x in name_lower for x in ["extension"]):
        return "triceps"

    return None


# Maps logical muscle_group (from get_exercise_muscle_group) to the canonical
# `display_body_part` value in exercise_library_cleaned (the materialized view used
# everywhere else in the app — 51× faster than raw exercise_library). The MV's
# `display_body_part` column has 16 clean values: Quadriceps, Triceps, Hamstrings,
# Core, Shoulders, Lower Back, Neck, Glutes, Hips, Chest, Back, Calves, Biceps,
# Full Body, Forearms, Rotator Cuff. category is used for cardio.
MUSCLE_TO_LIBRARY_QUERY: Dict[str, Dict[str, Optional[str]]] = {
    "quadriceps": {"display_body_part": "Quadriceps", "category": None},
    "hamstrings": {"display_body_part": "Hamstrings", "category": None},
    "glutes":     {"display_body_part": "Glutes",     "category": None},
    "calves":     {"display_body_part": "Calves",     "category": None},
    "chest":      {"display_body_part": "Chest",      "category": None},
    "back":       {"display_body_part": "Back",       "category": None},
    "shoulders":  {"display_body_part": "Shoulders",  "category": None},
    "biceps":     {"display_body_part": "Biceps",     "category": None},
    "triceps":    {"display_body_part": "Triceps",    "category": None},
    "forearms":   {"display_body_part": "Forearms",   "category": None},
    "core":       {"display_body_part": "Core",       "category": None},
    "abs":        {"display_body_part": "Core",       "category": None},
    "cardio":     {"display_body_part": None,         "category": "cardio"},
    "lower_back": {"display_body_part": "Lower Back", "category": None},
    "hips":       {"display_body_part": "Hips",       "category": None},
}

# Cross-muscle library expansion: when an injury restricts the original muscle group,
# we query OTHER muscle groups the user can still safely train. All hits remain real
# exercise_library rows (contraindication-filtered).
INJURY_SAFE_MUSCLE_EXPANSION: Dict[str, List[str]] = {
    "knee":       ["chest", "back", "shoulders", "biceps", "triceps", "core"],
    "shoulder":   ["quadriceps", "hamstrings", "glutes", "calves", "core"],
    "lower_back": ["chest", "back", "biceps", "triceps", "shoulders", "calves"],
    "elbow":      ["quadriceps", "hamstrings", "glutes", "calves", "core"],
    "wrist":      ["quadriceps", "hamstrings", "glutes", "calves", "core"],
    "hip":        ["chest", "back", "shoulders", "biceps", "triceps", "calves"],
    "ankle":      ["chest", "back", "shoulders", "biceps", "triceps", "core"],
    "neck":       ["quadriceps", "hamstrings", "glutes", "biceps", "triceps", "calves"],
}


# Full column list for substitutes — includes media + safety + difficulty fields.
_SUBSTITUTE_COLS = (
    "id, name, body_part, display_body_part, equipment, gif_url, video_url, "
    "image_url, target_muscle, category, avoid_if, difficulty_level"
)


def _cached_query_by_muscle(db, muscle_group: str, limit: int) -> List[Dict[str, Any]]:
    """TTL-cached wrapper for _query_library_by_muscle (finding #20).

    Cache key is (muscle_group, limit). The same muscle search recurs across
    every harness scenario; caching cuts mid-run latency from 5–7s to <50ms
    after first hit.
    """
    key = ("muscle", muscle_group, limit)
    cached = _LIBRARY_CACHE.get(key)
    if cached is not None:
        return cached
    rows = _query_library_by_muscle(db, muscle_group, limit)
    _LIBRARY_CACHE[key] = rows
    return rows


def _query_library_by_muscle(db, muscle_group: str, limit: int = 10) -> List[Dict[str, Any]]:
    """Query exercise_library_cleaned (materialized view) by canonical display_body_part
    or category. Pulls a wider pool than the cap so downstream scoring can rank.
    Returns rows ordered by difficulty (asc) + id for deterministic-but-stable
    ordering — the alphabetic-bias fix combines this with seeded jitter in scoring.
    """
    mapping = MUSCLE_TO_LIBRARY_QUERY.get(muscle_group, {})

    if mapping.get("display_body_part"):
        try:
            res = (
                db.client.table("exercise_library_cleaned").select(_SUBSTITUTE_COLS)
                .eq("display_body_part", mapping["display_body_part"])
                .order("difficulty_level", desc=False).order("id")
                .limit(limit * 4).execute()
            )
            if res.data:
                return res.data
        except Exception as e:
            logger.warning(f"display_body_part query failed for {muscle_group}: {e}")

    if mapping.get("category"):
        try:
            res = (
                db.client.table("exercise_library_cleaned").select(_SUBSTITUTE_COLS)
                .eq("category", mapping["category"])
                .order("difficulty_level", desc=False).order("id")
                .limit(limit * 4).execute()
            )
            if res.data:
                return res.data
        except Exception as e:
            logger.warning(f"category query failed for {muscle_group}: {e}")

    return []


# Maps injury_type (knee/shoulder/etc.) to substring keywords found in `avoid_if` arrays
# of exercise_library_cleaned rows. If any keyword matches, the exercise is unsafe for
# that injury. This replaces brittle name-based contraindication matching with the
# library's authoritative safety metadata.
INJURY_AVOID_IF_KEYWORDS: Dict[str, List[str]] = {
    "knee":       ["knee"],
    "shoulder":   ["shoulder", "rotator cuff"],
    "lower_back": ["lower back", "back", "spine", "lumbar"],
    "elbow":      ["elbow"],
    "wrist":      ["wrist"],
    "hip":        ["hip"],
    "ankle":      ["ankle"],
    "neck":       ["neck", "cervical"],
}


def _is_unsafe_for_injury(row: Dict[str, Any], injury_type: Optional[str]) -> bool:
    """Check exercise_library_cleaned.avoid_if[] for injury contraindications."""
    if not injury_type:
        return False
    keywords = INJURY_AVOID_IF_KEYWORDS.get(injury_type, [])
    if not keywords:
        return False
    avoid_if = row.get("avoid_if") or []
    if not isinstance(avoid_if, list):
        return False
    blob = " ".join(str(x).lower() for x in avoid_if)
    return any(k in blob for k in keywords)


# =============================================================================
# Reason-aware classification (intents beyond the 8 injury types)
# =============================================================================

# Non-injury reason keywords. Detected after detect_injury_type so an injury
# always wins (e.g. "knee pain — bored of squats" classifies as injury_type=knee
# AND intent=boring, but injury filtering is the harder constraint).
INTENT_KEYWORDS: Dict[str, List[str]] = {
    "no_equipment": ["no equipment", "without equipment", "bodyweight only",
                     "no gym", "at home"],
    "boring":       ["boring", "bored", "variety", "repetitive", "tired of",
                     "different", "switch it up", "want variety"],
    "pregnant":     ["pregnan", "trimester", "expecting", "first tri",
                     "second tri", "third tri"],
    "post_surgery": ["post-surgery", "post surgery", "rehab", "recovery from",
                     "recovering from"],
    "menstrual":    ["menstrual", "period", "luteal phase", "pms"],
}

# Belt-and-suspenders pregnancy filter — name keywords whose presence in an
# exercise name makes it unsafe regardless of `avoid_if[]` data quality.
PREGNANCY_UNSAFE_KEYWORDS: List[str] = [
    "jump", "plyo", "clap", "bound", "box jump", "tuck jump",
    "supine", "sit-up", "sit up", "crunch", "prone",
]

# Movement-family keywords — used to penalize same-family results when the user
# says "boring". Pull from the original exercise name; drop candidates sharing
# the keyword.
_MOVEMENT_FAMILY_KEYWORDS: List[str] = [
    "squat", "press", "curl", "row", "deadlift", "lunge",
    "push-up", "push up", "pushup", "pull-up", "pull up", "pullup",
    "dip", "fly", "extension", "raise", "shrug", "thrust",
]


class SubstituteContext:
    """Bundle of decisions made from the request before retrieval starts.

    Built once at endpoint entry by `_classify_reason`. Consumed by the
    candidate filter / scorer so the same context flows through every stage
    (muscle search → token search → cross-muscle → fuzzy → generic fallback).
    """

    __slots__ = (
        "reason", "original_name", "original_lower", "original_norm",
        "injury_type", "intent", "desired_equipment", "seed", "family_keyword",
        "original_category", "original_target_muscle",
    )

    def __init__(
        self,
        reason: Optional[str],
        original_name: str,
        injury_type: Optional[str],
        intent: str,
        desired_equipment: Optional[List[str]],
        seed: str,
        family_keyword: Optional[str],
    ):
        self.reason = reason
        self.original_name = original_name
        # `original_norm` is the punctuation-collapsed lowercase form used for
        # muscle keyword detection, token search, and fuzzy lookup (finding #15).
        # `original_lower` is preserved for back-compat with existing helpers.
        self.original_norm = _normalize_for_matching(original_name)
        self.original_lower = self.original_norm
        self.injury_type = injury_type
        self.intent = intent
        self.desired_equipment = desired_equipment
        self.seed = seed
        self.family_keyword = family_keyword
        # Populated lazily by `_lookup_original_metadata` (findings #17, #21).
        self.original_category: Optional[str] = None
        self.original_target_muscle: Optional[str] = None


def _detect_intent(reason: Optional[str]) -> str:
    """Return one of: none / no_equipment / boring / pregnant / post_surgery / menstrual."""
    if not reason:
        return "none"
    rl = reason.lower()
    for key, kws in INTENT_KEYWORDS.items():
        if any(kw in rl for kw in kws):
            return key
    return "none"


def _detect_family_keyword(name: str) -> Optional[str]:
    """Pick the dominant movement keyword from the original exercise name.

    Used so that `intent=boring` requests can drop same-family candidates
    (e.g. "Bench Press" + boring → don't return "Incline Bench Press").
    """
    nl = name.lower()
    for kw in _MOVEMENT_FAMILY_KEYWORDS:
        if kw in nl:
            return kw
    return None


def _classify_reason(request: SubstituteRequest) -> SubstituteContext:
    """Single-source decision step. injury_type wins over intent for safety."""
    import hashlib
    injury_type = detect_injury_type(request.reason)
    intent = _detect_intent(request.reason)
    desired_equipment: Optional[List[str]] = None
    if intent == "no_equipment":
        desired_equipment = ["bodyweight", "none", ""]
    # Seed includes BOTH name AND reason so the same exercise + different reasons
    # produces different jitter ordering (finding #18 — boring was inert because
    # downstream scoring was identical across reasons).
    norm_name = _normalize_for_matching(request.exercise_name)
    seed_input = f"{norm_name}|{(request.reason or '').lower()}"
    seed = hashlib.md5(seed_input.encode("utf-8")).hexdigest()
    return SubstituteContext(
        reason=request.reason,
        original_name=request.exercise_name,
        injury_type=injury_type,
        intent=intent,
        desired_equipment=desired_equipment,
        seed=seed,
        family_keyword=_detect_family_keyword(_normalize_exercise_name(request.exercise_name)),
    )


def _lookup_original_metadata(db, ctx: SubstituteContext) -> None:
    """Populate ctx.original_category + original_target_muscle from the MV.

    Used by scoring (#17 category-match, #21 target_muscle weight). Cached for
    5 min via _LIBRARY_CACHE; misses are tolerated (scoring degrades gracefully).
    """
    if not ctx.original_norm:
        return
    cache_key = ("original_meta", ctx.original_norm)
    cached = _LIBRARY_CACHE.get(cache_key)
    if cached is not None:
        ctx.original_category, ctx.original_target_muscle = cached
        return
    try:
        res = (
            db.client.table("exercise_library_cleaned")
            .select("name, category, target_muscle")
            .ilike("name", ctx.original_norm)
            .limit(1).execute()
        )
        rows = res.data or []
        if rows:
            ctx.original_category = (rows[0].get("category") or "").lower() or None
            ctx.original_target_muscle = (rows[0].get("target_muscle") or "").lower() or None
        _LIBRARY_CACHE[cache_key] = (ctx.original_category, ctx.original_target_muscle)
    except Exception as e:
        logger.warning(f"original metadata lookup failed for {ctx.original_norm!r}: {e}")


def _is_unsafe_by_name_keyword(name: str, ctx: SubstituteContext) -> bool:
    """Belt-and-suspenders backstop for spotty `avoid_if[]` data.

    Reuses the curated INJURY_EXERCISE_CONTRAINDICATIONS keyword lists for
    injury queries, plus PREGNANCY_UNSAFE_KEYWORDS for pregnant queries.
    Either match returns True so the candidate is dropped.

    Name matching uses the normalized form (collapsed whitespace + punctuation
    → space) so "Bench-Press" / "Bench  Press" / "Bench (Press)" all match the
    same keywords (finding #15).
    """
    if not name:
        return False
    nl = _normalize_for_matching(name)
    if ctx.injury_type:
        for kw in INJURY_EXERCISE_CONTRAINDICATIONS.get(ctx.injury_type, []):
            if kw.lower() in nl:
                return True
    if ctx.intent == "pregnant":
        if any(kw in nl for kw in PREGNANCY_UNSAFE_KEYWORDS):
            return True
    return False


def _passes_intent_filter(row: Dict[str, Any], ctx: SubstituteContext) -> bool:
    """Hard filters applied to every retrieved candidate before scoring."""
    name = (row.get("name") or "").lower()
    equipment = (row.get("equipment") or "").lower()
    category = (row.get("category") or "").lower()

    if ctx.intent == "no_equipment":
        # equipment must be bodyweight / none / empty
        if equipment and equipment not in {"bodyweight", "body weight", "none"}:
            return False

    if ctx.intent == "pregnant":
        # plyometric category OR pregnancy-keyword name → drop
        if category == "plyometric":
            return False
        if any(kw in name for kw in PREGNANCY_UNSAFE_KEYWORDS):
            return False

    if ctx.intent == "post_surgery":
        # cap difficulty at 4 (out of typical 1-7 scale)
        diff = row.get("difficulty_level")
        if isinstance(diff, int) and diff > 4:
            return False

    return True


def _equipment_is_bodyweight(row: Dict[str, Any]) -> bool:
    eq = (row.get("equipment") or "").lower()
    return eq in {"", "bodyweight", "body weight", "none"}


def _seeded_jitter(row_id: Any, seed: str) -> float:
    """Deterministic ε ∈ [0, 0.10) keyed on (row_id, seed).

    Same seed → same value. Different seed → different ranking. Seed is built
    from (normalized exercise_name, reason) so the same exercise + different
    reasons yield different orderings (finding #18 — boring vs none must
    diverge). Range widened from 0.05 → 0.10 so reason-driven jitter can flip
    rankings even when category/muscle scores tie.
    """
    import hashlib
    h = hashlib.md5(f"{row_id}|{seed}".encode("utf-8")).hexdigest()
    return (int(h[:8], 16) / 0xFFFFFFFF) * 0.10


def _score_candidate(
    row: Dict[str, Any],
    detected_muscle: Optional[str],
    ctx: SubstituteContext,
) -> float:
    """Rank a candidate row. Higher = better.

    Weights:
      +0.30 same target_muscle as original (most specific — finding #21)
      +0.20 same display_body_part as detected muscle
      +0.25 same category as original (strength→strength, finding #17)
      −0.25 different category, intent ∉ {post_surgery} (finding #17)
      +0.20 × Jaccard token overlap with original name
      +0.20 if equipment matches ctx.desired_equipment
      +0.15 if post_surgery + category in {stretching, mobility}
      +0.10 if media-rich (gif_url OR video_url OR image_url)
      −0.50 if boring + name shares ctx.family_keyword
      + seeded jitter ∈ [0, 0.10)  — widened so reason flips ordering (#18)
    """
    score = 0.0

    # target_muscle match — most specific, weighted higher than body_part (#21)
    row_target = (row.get("target_muscle") or "").lower()
    if ctx.original_target_muscle and row_target == ctx.original_target_muscle:
        score += 0.30

    if detected_muscle:
        target_dbp = (MUSCLE_TO_LIBRARY_QUERY.get(detected_muscle, {})
                      .get("display_body_part"))
        row_dbp = row.get("display_body_part")
        if target_dbp and row_dbp == target_dbp:
            score += 0.20

    # Category match — strength queries should not be dominated by stretches (#17)
    row_category = (row.get("category") or "").lower()
    if ctx.original_category and row_category:
        if row_category == ctx.original_category:
            score += 0.25
        elif ctx.intent != "post_surgery":
            score -= 0.25

    # Jaccard token overlap
    orig_tokens = {t for t in ctx.original_norm.replace("-", " ").split()
                   if len(t) >= 3}
    name_tokens = {t for t in _normalize_for_matching(row.get("name") or "").split()
                   if len(t) >= 3}
    if orig_tokens and name_tokens:
        inter = len(orig_tokens & name_tokens)
        union = len(orig_tokens | name_tokens)
        if union > 0:
            score += 0.20 * (inter / union)

    if ctx.desired_equipment and _equipment_is_bodyweight(row):
        score += 0.20

    if ctx.intent == "post_surgery":
        if row_category in {"stretching", "mobility", "yoga"}:
            score += 0.15

    if row.get("gif_url") or row.get("video_url") or row.get("image_url"):
        score += 0.10

    if ctx.intent == "boring" and ctx.family_keyword:
        if ctx.family_keyword in _normalize_for_matching(row.get("name") or ""):
            score -= 0.50

    score += _seeded_jitter(row.get("id"), ctx.seed)
    return score


def _row_passes_all_filters(row: Dict[str, Any], ctx: SubstituteContext) -> bool:
    """Single gate for every candidate at every retrieval stage."""
    name = row.get("name") or ""
    if not name:
        return False
    if name.lower() == ctx.original_lower:
        return False  # self-exclusion
    if _is_unsafe_for_injury(row, ctx.injury_type):
        return False
    if _is_unsafe_by_name_keyword(name, ctx):
        return False
    if not _passes_intent_filter(row, ctx):
        return False
    return True


def _token_search(db, exercise_name: str, ctx: SubstituteContext) -> List[Dict[str, Any]]:
    """ilike-based token search across exercise_library_cleaned.name."""
    out: List[Dict[str, Any]] = []
    try:
        # Normalized form so 'Bench-Press' / 'Bench (Press)' / 'Bench  Press'
        # all tokenize the same way (finding #15). Min length 3 catches
        # 'cow', 'cat', 'sq...'.
        norm = _normalize_for_matching(exercise_name)
        tokens = [t for t in norm.split()
                  if len(t) >= 3 and t not in {"with", "the", "and", "for"}]
        for token in tokens[:3]:
            cache_key = ("token", token)
            cached = _LIBRARY_CACHE.get(cache_key)
            if cached is not None:
                out.extend(cached)
                continue
            res = (db.client.table("exercise_library_cleaned").select(_SUBSTITUTE_COLS)
                   .ilike("name", f"%{token}%").limit(12).execute())
            rows = res.data or []
            _LIBRARY_CACHE[cache_key] = rows
            out.extend(rows)
    except Exception as e:
        logger.warning(f"Token-based library search error: {e}", exc_info=True)
    return out


def _expand_to_safe_muscles(
    db, ctx: SubstituteContext, detected_muscle: Optional[str]
) -> List[Dict[str, Any]]:
    """Cross-muscle expansion — fires for injury OR pregnancy OR post-surgery
    when the same-muscle pool would force unsafe picks.
    """
    out: List[Dict[str, Any]] = []
    expansion_key = ctx.injury_type
    if not expansion_key and ctx.intent in {"pregnant", "post_surgery"}:
        # Default to a generally-safe expansion: same as ankle (full upper body + core)
        expansion_key = "ankle"
    if not expansion_key or expansion_key not in INJURY_SAFE_MUSCLE_EXPANSION:
        return out
    for alt_muscle in INJURY_SAFE_MUSCLE_EXPANSION[expansion_key]:
        if alt_muscle == detected_muscle:
            continue
        for row in _cached_query_by_muscle(db, alt_muscle, limit=6):
            out.append(row)
    return out


def _fuzzy_search(db, exercise_name: str) -> List[Dict[str, Any]]:
    """Typo-tolerant trigram search via the substitutes_fuzzy_search RPC
    (migration 2039). Catches Squet → Squat, benchpres → Bench Press.
    """
    try:
        res = db.client.rpc("substitutes_fuzzy_search", {
            "p_search_term": exercise_name,
            "p_limit": 12,
        }).execute()
        return res.data or []
    except Exception as e:
        logger.warning(f"Fuzzy search RPC error: {e}", exc_info=True)
        return []


def _generic_pool_fallback(db) -> List[Dict[str, Any]]:
    """Final fallback when every other stage fails. Pulls from Full Body / Core
    so we always have *something* to suggest for any recognized input.
    """
    out: List[Dict[str, Any]] = []
    for dbp in ("Full Body", "Core"):
        try:
            res = (db.client.table("exercise_library_cleaned").select(_SUBSTITUTE_COLS)
                   .eq("display_body_part", dbp)
                   .order("difficulty_level", desc=False).order("id")
                   .limit(8).execute())
            for row in res.data or []:
                out.append(row)
        except Exception as e:
            logger.warning(f"Generic pool fallback ({dbp}) error: {e}", exc_info=True)
    return out


def _explain_substitute(row: Dict[str, Any], ctx: SubstituteContext) -> str:
    """Short per-substitute explanation rendered in the UI tile."""
    if ctx.injury_type:
        # e.g. "Knee-friendly alternative"
        return f"{ctx.injury_type.replace('_', ' ').title()}-friendly alternative"
    if ctx.intent == "no_equipment":
        return "Bodyweight, no equipment needed"
    if ctx.intent == "pregnant":
        return "Pregnancy-safe alternative"
    if ctx.intent == "post_surgery":
        return "Lower-impact rehab option"
    if ctx.intent == "menstrual":
        return "Lower-intensity option"
    if ctx.intent == "boring":
        return "Different movement pattern"
    return "Same muscle group"


def _to_substitute_exercise(row: Dict[str, Any], ctx: SubstituteContext) -> SubstituteExercise:
    """Build a SubstituteExercise from a library row.

    `media_url` is the canonical media field; `gif_url` is populated with the
    same coalesced value for back-compat with the Flutter substitute-tile UI
    that already reads `gif_url`.
    """
    media = row.get("gif_url") or row.get("video_url") or row.get("image_url")
    # Compute truthful is_safe_for_reason by re-running every safety filter
    # (finding #13 — the old code lied with `True` even when name keywords
    # matched). Anything the post-filter pipeline lets through *should* be
    # safe; this is a belt-and-suspenders attestation that survives any future
    # bug where unsafe rows slip through.
    safe = (
        not _is_unsafe_for_injury(row, ctx.injury_type)
        and not _is_unsafe_by_name_keyword(row.get("name") or "", ctx)
        and _passes_intent_filter(row, ctx)
    )
    return SubstituteExercise(
        name=row.get("name") or "",
        muscle_group=row.get("display_body_part") or row.get("body_part"),
        target_muscle=row.get("target_muscle"),
        body_part=row.get("body_part"),
        equipment=row.get("equipment"),
        library_id=row.get("id"),
        gif_url=media,
        video_url=row.get("video_url"),
        image_url=row.get("image_url"),
        media_url=media,
        reason=_explain_substitute(row, ctx),
        difficulty=str(row.get("difficulty_level")) if row.get("difficulty_level") is not None else None,
        is_safe_for_reason=safe,
    )


def _build_injury_warning(ctx: SubstituteContext) -> Optional[str]:
    if not ctx.injury_type:
        return None
    return f"Showing options that avoid {ctx.injury_type.replace('_', ' ')} stress."


def _build_safety_warning(ctx: SubstituteContext) -> Optional[str]:
    if ctx.intent == "pregnant":
        return ("Pregnancy: avoiding plyometric, supine, and high-impact work. "
                "Consult your OB-GYN before starting any new exercise.")
    if ctx.intent == "post_surgery":
        return ("Post-surgery: capped at moderate difficulty. Confirm clearance "
                "with your physical therapist before progressing.")
    if ctx.intent == "menstrual":
        return ("Lower-intensity options shown. Listen to your body and reduce "
                "load if needed.")
    return None


def _build_message(ctx: SubstituteContext, n: int) -> str:
    if ctx.injury_type:
        return f"Here are {n} safe alternatives that avoid {ctx.injury_type.replace('_', ' ')} stress"
    if ctx.intent == "no_equipment":
        return f"Found {n} bodyweight alternatives for {ctx.original_name}"
    if ctx.intent == "boring":
        return f"Found {n} fresh alternatives to {ctx.original_name}"
    if ctx.intent == "pregnant":
        return f"Here are {n} pregnancy-safe alternatives"
    if ctx.intent == "post_surgery":
        return f"Here are {n} lower-impact rehab alternatives"
    if ctx.intent == "menstrual":
        return f"Here are {n} lower-intensity alternatives"
    if n > 0:
        return f"Found {n} alternative exercises for {ctx.original_name}"
    return "No specific substitutes found, but you can search the exercise library for alternatives"


@router.post("/suggest-substitutes", response_model=SubstituteResponse)
async def suggest_exercise_substitutes(request: SubstituteRequest, current_user: dict = Depends(get_current_user)):
    """
    Get safe substitute exercises when avoiding a specific exercise.

    Reason-aware: detects 8 injury types AND 5 non-injury intents
    (no_equipment, boring, pregnant, post_surgery, menstrual). Returns ≥3
    substitutes for any recognized input via cascading retrieval (muscle
    search → token search → cross-muscle expansion → fuzzy/trigram → generic
    pool). Belt-and-suspenders safety filter combines the library's
    `avoid_if[]` metadata with curated name-keyword lists.
    """
    logger.info(f"Getting substitutes for: {request.exercise_name}, reason: {request.reason}")

    try:
        db = get_supabase_db()

        ctx = _classify_reason(request)
        # Muscle detection uses the punctuation-collapsed form (#15) so
        # "Bench-Press", "Bench  Press", "Bench (Press)" all map to chest.
        muscle_group = get_exercise_muscle_group(_normalize_exercise_name(request.exercise_name))
        # Populate ctx.original_category + original_target_muscle for scoring (#17, #21)
        _lookup_original_metadata(db, ctx)

        # Cascade retrieval: collect a large pool, filter, score, take top N.
        pool: List[Dict[str, Any]] = []

        # 1. Muscle search (primary signal)
        if muscle_group:
            pool.extend(_cached_query_by_muscle(db, muscle_group, limit=12))

        # 2. Token search (catches names that fail muscle keyword detection)
        pool.extend(_token_search(db, request.exercise_name, ctx))

        # 3. Cross-muscle expansion (injury OR pregnant/post-surgery)
        if ctx.injury_type or ctx.intent in {"pregnant", "post_surgery"}:
            pool.extend(_expand_to_safe_muscles(db, ctx, muscle_group))

        # Filter pool through every guard
        seen_ids = set()
        seen_names = set()
        candidates: List[Dict[str, Any]] = []
        for row in pool:
            rid = row.get("id")
            nlow = (row.get("name") or "").lower()
            if rid in seen_ids or nlow in seen_names:
                continue
            if not _row_passes_all_filters(row, ctx):
                continue
            seen_ids.add(rid)
            seen_names.add(nlow)
            candidates.append(row)

        # 4. Fuzzy search fallback if still thin
        if len(candidates) < 3:
            for row in _fuzzy_search(db, request.exercise_name):
                rid = row.get("id")
                nlow = (row.get("name") or "").lower()
                if rid in seen_ids or nlow in seen_names:
                    continue
                if not _row_passes_all_filters(row, ctx):
                    continue
                seen_ids.add(rid)
                seen_names.add(nlow)
                candidates.append(row)

        # 5. Generic Full Body / Core fallback if STILL thin
        if len(candidates) < 3:
            for row in _generic_pool_fallback(db):
                rid = row.get("id")
                nlow = (row.get("name") or "").lower()
                if rid in seen_ids or nlow in seen_names:
                    continue
                if not _row_passes_all_filters(row, ctx):
                    continue
                seen_ids.add(rid)
                seen_names.add(nlow)
                candidates.append(row)

        # Score and rank
        candidates.sort(
            key=lambda r: _score_candidate(r, muscle_group, ctx),
            reverse=True,
        )
        top = candidates[:8]

        # Build response
        if not top:
            # Truly unrecognized input (gibberish / non-Latin / pure typo with no
            # near-match). Return 200 with empty substitutes + helpful message.
            return SubstituteResponse(
                original_exercise=request.exercise_name,
                reason=request.reason,
                substitutes=[],
                intent="unrecognized",
                injury_warning=None,
                safety_warning=None,
                message="Couldn't recognize that exercise — try the search bar or check the spelling.",
            )

        substitutes = [_to_substitute_exercise(r, ctx) for r in top]
        return SubstituteResponse(
            original_exercise=request.exercise_name,
            reason=request.reason,
            substitutes=substitutes,
            injury_warning=_build_injury_warning(ctx),
            intent=ctx.intent,
            safety_warning=_build_safety_warning(ctx),
            message=_build_message(ctx, len(substitutes)),
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
