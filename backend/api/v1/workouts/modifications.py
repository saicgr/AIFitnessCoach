"""
Workout modification API endpoints for in-workout adjustments.

This module handles exercise modifications during active workouts:
- POST /{workout_id}/exclude-body-parts - Remove exercises targeting specific body parts
- POST /{workout_id}/replace-exercise - Replace an exercise with a safe alternative
"""
import json
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.db import get_supabase_db as get_db
from core.logger import get_logger
from models.schemas import Workout
from services.user_context_service import user_context_service

from .utils import row_to_workout, log_workout_change, index_workout_to_rag

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Request/Response Models
# =============================================================================

class ExcludeBodyPartsRequest(BaseModel):
    """Request body for excluding body parts from a workout."""
    body_parts: List[str] = Field(
        ...,
        description="List of body parts to exclude (e.g., ['calves', 'lower_leg', 'ankle'])",
        min_length=1
    )
    user_id: str = Field(..., description="User ID for context logging")


class ExcludeBodyPartsResponse(BaseModel):
    """Response for body part exclusion operation."""
    workout_id: str
    excluded_body_parts: List[str]
    removed_exercises: List[str]
    remaining_exercises: int
    success: bool = True
    message: str = "Exercises removed successfully"


class ReplaceExerciseRequest(BaseModel):
    """Request body for replacing an exercise in a workout."""
    exercise_id: Optional[str] = Field(None, description="Exercise ID to replace")
    exercise_name: str = Field(..., description="Name of exercise to replace")
    reason: str = Field(
        ...,
        description="Reason for replacement: 'injury', 'equipment', 'preference', 'body_part'"
    )
    body_part_to_avoid: Optional[str] = Field(
        None,
        description="Specific body part to avoid in the replacement"
    )
    user_id: str = Field(..., description="User ID for context logging")


class ReplaceExerciseResponse(BaseModel):
    """Response for exercise replacement operation."""
    replaced: bool
    skipped: bool = False
    original: str
    replacement: Optional[str] = None
    reason: str
    message: str


# =============================================================================
# Body Part Mapping for Exercise Filtering
# =============================================================================

# Maps user-friendly body part names to common muscle/target variations
BODY_PART_MAPPINGS = {
    # Lower leg area
    "calves": ["calves", "calf", "gastrocnemius", "soleus"],
    "lower_leg": ["calves", "calf", "tibialis", "shin", "lower leg", "gastrocnemius", "soleus"],
    "ankle": ["ankle", "tibialis"],

    # Knee area
    "knee": ["knee", "quadriceps", "quads", "hamstrings", "patella"],

    # Upper leg / thighs
    "quadriceps": ["quadriceps", "quads", "quad", "thigh", "front thigh"],
    "hamstrings": ["hamstrings", "hamstring", "back thigh", "rear thigh"],
    "thighs": ["quadriceps", "quads", "hamstrings", "thigh", "adductors", "abductors"],
    "glutes": ["glutes", "gluteus", "butt", "hips"],

    # Back
    "lower_back": ["lower back", "erector spinae", "lumbar", "spinal erectors"],
    "upper_back": ["upper back", "lats", "rhomboids", "traps", "middle back"],
    "back": ["back", "lats", "rhomboids", "traps", "erector", "lumbar"],

    # Shoulders
    "shoulders": ["shoulders", "shoulder", "deltoids", "delts", "rotator cuff"],

    # Arms
    "wrists": ["wrist", "wrists", "forearm", "grip"],
    "elbows": ["elbow", "elbows", "triceps", "biceps"],
    "biceps": ["biceps", "bicep", "arm curl"],
    "triceps": ["triceps", "tricep"],
    "forearms": ["forearms", "forearm", "grip", "wrist"],

    # Core
    "abs": ["abs", "abdominals", "core", "rectus abdominis"],
    "obliques": ["obliques", "side abs", "waist"],
    "core": ["core", "abs", "abdominals", "obliques", "transverse"],

    # Chest
    "chest": ["chest", "pectorals", "pecs", "pectoral"],

    # Neck
    "neck": ["neck", "traps", "trapezius"],

    # Hip
    "hip": ["hip", "hips", "hip flexor", "glutes", "adductors", "abductors"],
    "hip_flexors": ["hip flexor", "hip flexors", "psoas", "iliopsoas"],
}


def get_body_part_keywords(body_parts: List[str]) -> List[str]:
    """
    Expand body part names to include all related keywords.

    Args:
        body_parts: User-provided body part names

    Returns:
        Extended list of keywords to match against exercises
    """
    keywords = set()
    for part in body_parts:
        part_lower = part.lower().strip().replace(" ", "_")
        # Add the original term
        keywords.add(part_lower)
        keywords.add(part.lower().strip())
        # Add mapped keywords
        if part_lower in BODY_PART_MAPPINGS:
            keywords.update(BODY_PART_MAPPINGS[part_lower])
        # Check for partial matches in mappings
        for key, values in BODY_PART_MAPPINGS.items():
            if part_lower in key or key in part_lower:
                keywords.update(values)
    return list(keywords)


def exercise_targets_body_part(
    exercise: dict,
    body_part_keywords: List[str]
) -> tuple[bool, str]:
    """
    Check if an exercise targets any of the specified body parts.

    Args:
        exercise: Exercise dict with muscle/body_part fields
        body_part_keywords: List of keywords to match

    Returns:
        Tuple of (should_exclude, matched_body_part)
    """
    # Get muscle information from exercise
    primary_muscle = (exercise.get('primary_muscle') or
                     exercise.get('target_muscle') or
                     exercise.get('muscle_group') or
                     exercise.get('bodyPart') or
                     exercise.get('body_part') or '').lower()

    secondary_muscles = exercise.get('secondary_muscles') or []
    if isinstance(secondary_muscles, str):
        secondary_muscles = [m.strip() for m in secondary_muscles.split(',')]
    secondary_muscles = [m.lower() for m in secondary_muscles if m]

    # Check exercise name for body part mentions
    exercise_name = (exercise.get('name') or '').lower()

    # Check primary muscle
    for keyword in body_part_keywords:
        keyword_lower = keyword.lower()
        if keyword_lower in primary_muscle or primary_muscle in keyword_lower:
            return True, keyword

    # Check secondary muscles
    for muscle in secondary_muscles:
        for keyword in body_part_keywords:
            keyword_lower = keyword.lower()
            if keyword_lower in muscle or muscle in keyword_lower:
                return True, keyword

    # Check exercise name (for exercises like "calf raise", "wrist curl")
    for keyword in body_part_keywords:
        keyword_lower = keyword.lower()
        if keyword_lower in exercise_name:
            return True, keyword

    return False, ""


# =============================================================================
# API Endpoints
# =============================================================================

@router.post("/{workout_id}/exclude-body-parts", response_model=ExcludeBodyPartsResponse)
async def exclude_body_parts_from_workout(
    workout_id: str,
    request: ExcludeBodyPartsRequest,
):
    """
    Remove exercises targeting specified body parts from an active workout.

    This is useful when a user has an injury or pain in specific areas and wants
    to continue their workout without exercises that might aggravate the issue.

    The removed exercises are marked as 'skipped' in the workout with a reason,
    preserving the original workout structure while filtering unsafe exercises.

    Example use cases:
    - User has lower leg pain: exclude 'calves', 'lower_leg'
    - User has knee issues: exclude 'knee' to filter squats, lunges, etc.
    - User has wrist pain: exclude 'wrists' to filter push-ups, curls, etc.
    """
    logger.info(f"🏋️ Excluding body parts {request.body_parts} from workout {workout_id}")

    try:
        db = get_supabase_db()

        # Get workout
        workout_row = db.get_workout(workout_id)
        if not workout_row:
            logger.warning(f"Workout not found: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get exercises from workout
        exercises = workout_row.get("exercises") or workout_row.get("exercises_json") or []
        if isinstance(exercises, str):
            exercises = json.loads(exercises)

        if not exercises:
            return ExcludeBodyPartsResponse(
                workout_id=workout_id,
                excluded_body_parts=request.body_parts,
                removed_exercises=[],
                remaining_exercises=0,
                message="No exercises in workout"
            )

        # Expand body part keywords for matching
        body_part_keywords = get_body_part_keywords(request.body_parts)
        logger.debug(f"Expanded body part keywords: {body_part_keywords}")

        # Filter exercises
        removed_exercises = []
        filtered_exercises = []

        for exercise in exercises:
            should_exclude, matched_part = exercise_targets_body_part(
                exercise, body_part_keywords
            )

            if should_exclude:
                # Mark exercise as skipped
                exercise['status'] = 'skipped'
                exercise['skip_reason'] = f"Body part excluded: {matched_part}"
                exercise['skipped_at'] = datetime.now().isoformat()
                removed_exercises.append(exercise.get('name', 'Unknown'))
                logger.info(f"  Excluding: {exercise.get('name')} (targets: {matched_part})")

            # Keep all exercises in the list (filtered ones are marked as skipped)
            filtered_exercises.append(exercise)

        # Update workout with modified exercises
        update_data = {
            "exercises_json": filtered_exercises,
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "body_part_exclusion"
        }
        db.update_workout(workout_id, update_data)

        # Log the change
        log_workout_change(
            workout_id=workout_id,
            user_id=request.user_id,
            change_type="body_part_exclusion",
            field_changed="exercises_json",
            old_value={"excluded_body_parts": request.body_parts},
            new_value={"removed_exercises": removed_exercises},
            change_source="active_workout_modification",
            change_reason=f"User excluded body parts: {', '.join(request.body_parts)}"
        )

        # Log context for AI personalization
        try:
            supabase = get_db().client
            supabase.table("user_context_logs").insert({
                "user_id": request.user_id,
                "context_type": "body_part_exclusion",
                "context_data": {
                    "workout_id": workout_id,
                    "excluded_body_parts": request.body_parts,
                    "removed_exercises": removed_exercises,
                    "timestamp": datetime.now().isoformat()
                },
                "created_at": datetime.now().isoformat()
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to log context: {e}")
            # Non-critical, continue

        # Calculate remaining non-skipped exercises
        remaining_count = sum(
            1 for ex in filtered_exercises
            if ex.get('status') != 'skipped'
        )

        logger.info(f"✅ Excluded {len(removed_exercises)} exercises, {remaining_count} remaining")

        return ExcludeBodyPartsResponse(
            workout_id=workout_id,
            excluded_body_parts=request.body_parts,
            removed_exercises=removed_exercises,
            remaining_exercises=remaining_count,
            message=f"Removed {len(removed_exercises)} exercise(s) targeting {', '.join(request.body_parts)}"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to exclude body parts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{workout_id}/replace-exercise", response_model=ReplaceExerciseResponse)
async def replace_exercise_in_workout(
    workout_id: str,
    request: ReplaceExerciseRequest,
):
    """
    Replace an exercise with a safe alternative that avoids a specific body part.

    This finds an alternative exercise that targets the same primary muscle group
    but doesn't involve the body part the user wants to avoid.

    If no suitable replacement is found, the exercise is marked as skipped.
    """
    logger.info(
        f"🔄 Replacing exercise '{request.exercise_name}' in workout {workout_id}, "
        f"reason: {request.reason}, avoiding: {request.body_part_to_avoid}"
    )

    try:
        db = get_supabase_db()
        supabase = get_db().client

        # Get workout
        workout_row = db.get_workout(workout_id)
        if not workout_row:
            raise HTTPException(status_code=404, detail="Workout not found")

        exercises = workout_row.get("exercises") or workout_row.get("exercises_json") or []
        if isinstance(exercises, str):
            exercises = json.loads(exercises)

        # Find the exercise to replace
        exercise_index = None
        original_exercise = None

        for i, ex in enumerate(exercises):
            if (ex.get('name', '').lower() == request.exercise_name.lower() or
                ex.get('id') == request.exercise_id):
                exercise_index = i
                original_exercise = ex
                break

        if original_exercise is None:
            raise HTTPException(status_code=404, detail="Exercise not found in workout")

        # Get the target muscle to find a replacement
        target_muscle = (
            original_exercise.get('primary_muscle') or
            original_exercise.get('target_muscle') or
            original_exercise.get('muscle_group') or
            original_exercise.get('body_part') or
            ''
        )

        # Find alternative exercise
        alternative = await find_safe_alternative(
            supabase=supabase,
            original_exercise=original_exercise,
            target_muscle=target_muscle,
            avoid_body_part=request.body_part_to_avoid,
            user_id=request.user_id
        )

        if alternative:
            # Replace the exercise
            new_exercise = {
                **original_exercise,
                'id': alternative.get('id'),
                'name': alternative.get('name'),
                'gif_url': alternative.get('gif_url'),
                'video_url': alternative.get('video_url'),
                'primary_muscle': alternative.get('target'),
                'body_part': alternative.get('body_part'),
                'equipment': alternative.get('equipment'),
                'secondary_muscles': alternative.get('secondary_muscles'),
                'instructions': alternative.get('instructions'),
                'replacement_reason': request.reason,
                'original_exercise': request.exercise_name,
                'replaced_at': datetime.now().isoformat(),
            }
            exercises[exercise_index] = new_exercise

            # Update workout
            update_data = {
                "exercises_json": exercises,
                "last_modified_at": datetime.now().isoformat(),
                "last_modified_method": "exercise_replacement"
            }
            db.update_workout(workout_id, update_data)

            # Log the change
            log_workout_change(
                workout_id=workout_id,
                user_id=request.user_id,
                change_type="exercise_replaced",
                field_changed="exercises_json",
                old_value={"original": request.exercise_name},
                new_value={"replacement": alternative.get('name')},
                change_source="active_workout_modification",
                change_reason=f"Replaced due to: {request.reason}"
            )

            logger.info(f"✅ Replaced '{request.exercise_name}' with '{alternative.get('name')}'")

            return ReplaceExerciseResponse(
                replaced=True,
                skipped=False,
                original=request.exercise_name,
                replacement=alternative.get('name'),
                reason=request.reason,
                message=f"Replaced with {alternative.get('name')}"
            )

        # No alternative found - skip the exercise
        exercises[exercise_index]['status'] = 'skipped'
        exercises[exercise_index]['skip_reason'] = f"No safe alternative for {request.reason}"
        exercises[exercise_index]['skipped_at'] = datetime.now().isoformat()

        # Update workout
        update_data = {
            "exercises_json": exercises,
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "exercise_skipped"
        }
        db.update_workout(workout_id, update_data)

        logger.info(f"⚠️ No replacement found for '{request.exercise_name}', marked as skipped")

        return ReplaceExerciseResponse(
            replaced=False,
            skipped=True,
            original=request.exercise_name,
            replacement=None,
            reason=request.reason,
            message=f"No safe alternative available, exercise skipped"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to replace exercise: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def find_safe_alternative(
    supabase,
    original_exercise: dict,
    target_muscle: str,
    avoid_body_part: Optional[str],
    user_id: str,
    limit: int = 1
) -> Optional[dict]:
    """
    Find a safe alternative exercise that targets the same muscle but avoids the specified body part.

    Args:
        supabase: Supabase client
        original_exercise: The exercise being replaced
        target_muscle: Primary muscle the replacement should target
        avoid_body_part: Body part to avoid in the replacement
        user_id: User ID for checking avoided exercises
        limit: Number of alternatives to return

    Returns:
        Best alternative exercise or None if no suitable alternative exists
    """
    try:
        original_name = original_exercise.get('name', '').lower()
        original_equipment = original_exercise.get('equipment', '').lower()

        # Query exercises from the library with the same target muscle
        query = supabase.table("exercises").select(
            "id, name, target, body_part, equipment, gif_url, video_url, "
            "secondary_muscles, instructions"
        )

        if target_muscle:
            # Search for exercises targeting similar muscle groups
            query = query.ilike("target", f"%{target_muscle}%")

        result = query.limit(50).execute()
        candidates = result.data if result.data else []

        if not candidates:
            logger.debug(f"No candidates found for target muscle: {target_muscle}")
            return None

        # Get user's avoided exercises
        avoided_response = supabase.table("avoided_exercises").select(
            "exercise_name"
        ).eq("user_id", user_id).eq("is_active", True).execute()

        avoided_names = set(
            ex['exercise_name'].lower()
            for ex in (avoided_response.data or [])
        )

        # Get keywords to avoid if body part specified
        avoid_keywords = []
        if avoid_body_part:
            avoid_keywords = get_body_part_keywords([avoid_body_part])

        # Filter and score candidates
        scored_candidates = []

        for candidate in candidates:
            candidate_name = candidate.get('name', '').lower()

            # Skip the original exercise
            if candidate_name == original_name:
                continue

            # Skip avoided exercises
            if candidate_name in avoided_names:
                continue

            # Check if candidate involves the avoided body part
            if avoid_keywords:
                should_avoid, _ = exercise_targets_body_part(candidate, avoid_keywords)
                if should_avoid:
                    continue

            # Score the candidate
            score = 0

            # Prefer same equipment
            candidate_equipment = candidate.get('equipment', '').lower()
            if candidate_equipment == original_equipment:
                score += 3
            elif 'body weight' in candidate_equipment or 'bodyweight' in candidate_equipment:
                score += 2  # Bodyweight exercises are always available

            # Prefer exercises with GIFs (better UX)
            if candidate.get('gif_url'):
                score += 1

            scored_candidates.append((score, candidate))

        if not scored_candidates:
            return None

        # Sort by score (highest first) and return the best match
        scored_candidates.sort(key=lambda x: x[0], reverse=True)

        return scored_candidates[0][1] if scored_candidates else None

    except Exception as e:
        logger.error(f"Error finding safe alternative: {e}")
        return None


@router.get("/{workout_id}/modification-history")
async def get_modification_history(
    workout_id: str,
    limit: int = Query(default=20, ge=1, le=100)
):
    """
    Get the modification history for a workout.

    Returns a list of changes made to the workout, including:
    - Exercise replacements
    - Body part exclusions
    - Set adjustments
    """
    try:
        db = get_supabase_db()

        # Get workout changes from the audit log
        changes = db.client.table("workout_changes").select(
            "*"
        ).eq(
            "workout_id", workout_id
        ).order(
            "changed_at", desc=True
        ).limit(limit).execute()

        return {
            "workout_id": workout_id,
            "modifications": changes.data or [],
            "count": len(changes.data or [])
        }

    except Exception as e:
        logger.error(f"Error fetching modification history: {e}")
        raise HTTPException(status_code=500, detail=str(e))
