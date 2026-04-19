"""
Workout exercise modification API endpoints.

This module handles exercise modifications within workouts:
- PUT /{workout_id}/exercises - Update workout exercises
- PUT /{workout_id}/warmup/exercises - Update warmup exercises
- PUT /{workout_id}/stretches/exercises - Update stretch exercises

Preview-aware routing (added Phase 1C):
- POST /preview/swap-exercise - Swap an exercise on a cached regen preview
- POST /preview/add-exercise  - Append an exercise to a cached regen preview

The /preview/* variants mutate the in-process preview cache (not the DB).
They exist so the user can swap/add exercises inside the Regenerate review
sheet without prematurely persisting the preview as a committed workout.
Once the user taps Approve, /workouts/regenerate-commit flushes the
preview (with its swap/add mutations) to the DB as the new version.
"""
from core.db import get_supabase_db
from datetime import datetime
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from core.logger import get_logger
from models.schemas import (
    Workout,
    UpdateWorkoutExercisesRequest,
    UpdateWarmupExercisesRequest,
    UpdateStretchExercisesRequest,
)
from services.regen_preview_cache import get_preview_cache
from services.exercise_library_service import get_exercise_library_service

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
)

router = APIRouter()
logger = get_logger(__name__)


@router.put("/{workout_id}/exercises", response_model=Workout)
async def update_workout_exercises(workout_id: str, request: UpdateWorkoutExercisesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the exercises in a workout (add, remove, reorder).

    This updates the exercises_json field and re-indexes to RAG.
    """
    logger.info(f"Updating exercises for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Get existing workout
        existing = db.get_workout(workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Convert exercises to dict list
        exercises_list = [ex.model_dump() for ex in request.exercises]

        # Update workout
        update_data = {
            "exercises_json": exercises_list,
            "last_modified_at": datetime.now().isoformat(),
            "last_modified_method": "manual_edit"
        }

        updated = db.update_workout(workout_id, update_data)

        # Log the change
        log_workout_change(
            workout_id=workout_id,
            user_id=existing.get("user_id"),
            change_type="exercises_updated",
            field_changed="exercises_json",
            change_source="manual_edit",
            new_value={"exercises_count": len(exercises_list)}
        )

        # Re-index to RAG
        updated_workout = row_to_workout(updated)
        await index_workout_to_rag(updated_workout)

        logger.info(f"Workout exercises updated: id={workout_id}, count={len(exercises_list)}")
        return updated_workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update workout exercises: {e}", exc_info=True)
        raise safe_internal_error(e, "exercises")


@router.put("/{workout_id}/warmup/exercises")
async def update_warmup_exercises(workout_id: str, request: UpdateWarmupExercisesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the warmup exercises for a workout.
    """
    logger.info(f"Updating warmup exercises for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Check workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get existing warmup
        result = db.client.table("warmups").select("*").eq("workout_id", workout_id).eq("is_current", True).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Warmup not found for this workout")

        warmup = result.data[0]

        # Convert exercises to dict list
        exercises_list = [ex.model_dump() for ex in request.exercises]

        # Update warmup
        db.client.table("warmups").update({
            "exercises_json": exercises_list,
            "updated_at": datetime.now().isoformat()
        }).eq("id", warmup["id"]).execute()

        logger.info(f"Warmup exercises updated: workout_id={workout_id}, count={len(exercises_list)}")
        return {"success": True, "exercises_count": len(exercises_list)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update warmup exercises: {e}", exc_info=True)
        raise safe_internal_error(e, "exercises")


@router.put("/{workout_id}/stretches/exercises")
async def update_stretch_exercises(workout_id: str, request: UpdateStretchExercisesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the stretch exercises for a workout.
    """
    logger.info(f"Updating stretch exercises for workout {workout_id}")
    try:
        db = get_supabase_db()

        # Check workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get existing stretches
        result = db.client.table("stretches").select("*").eq("workout_id", workout_id).eq("is_current", True).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Stretches not found for this workout")

        stretches = result.data[0]

        # Convert exercises to dict list
        exercises_list = [ex.model_dump() for ex in request.exercises]

        # Update stretches
        db.client.table("stretches").update({
            "exercises_json": exercises_list,
            "updated_at": datetime.now().isoformat()
        }).eq("id", stretches["id"]).execute()

        logger.info(f"Stretch exercises updated: workout_id={workout_id}, count={len(exercises_list)}")
        return {"success": True, "exercises_count": len(exercises_list)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update stretch exercises: {e}", exc_info=True)
        raise safe_internal_error(e, "exercises")


# ---------------------------------------------------------------------------
# Preview-aware swap / add (Phase 1C)
# ---------------------------------------------------------------------------
#
# These endpoints mutate an in-process preview payload held by the regenerate
# preview cache. They never touch the database — see versioning.py for the
# commit flow. The client routes to these instead of /workouts/swap-exercise
# and /workouts/add-exercise when `preview_id` is present.
#
# Design choices:
# - We duplicate the library-lookup logic from workout_operations.py rather
#   than importing, to keep the preview path self-contained and to avoid
#   dragging in transitively-owned endpoints (rate limiters, background
#   tasks, etc.). The preview operations are pure in-memory dict mutations
#   and don't need rate limiting, background tasks, or analytics hooks.
# - Derived fields (duration, exercise count) are recomputed on every mutation
#   so the review sheet stays consistent.
# - Mutations are atomic via preview_cache.update() — the mutator runs under
#   the cache lock against a deep-copy, and the new payload replaces the old
#   in one step.
# ---------------------------------------------------------------------------


def _preview_error(code: str, status_code: int, message: str) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={"error": code, "message": message},
    )


def _sum_duration_seconds(exercises: List[Dict[str, Any]]) -> Optional[int]:
    """Compute an approximate total time in seconds from the exercise list.

    Each exercise contributes ``sets * (avg_rep_duration + rest_seconds)`` for
    traditional sets, OR ``duration_seconds`` for timed exercises. Falls back
    to None when the list is empty — we keep the top-level
    ``duration_minutes`` in that case.
    """
    if not exercises:
        return None
    total = 0.0
    AVG_REP_SECONDS = 3.0  # rough average cadence per rep
    for ex in exercises:
        if not isinstance(ex, dict):
            continue
        duration = ex.get("duration_seconds")
        sets = ex.get("sets") or 1
        rest = ex.get("rest_seconds") or 0
        if duration:
            total += (sets * float(duration)) + (max(0, sets - 1) * float(rest))
        else:
            reps = ex.get("reps") or 0
            try:
                reps_int = int(reps) if not isinstance(reps, int) else reps
            except (ValueError, TypeError):
                reps_int = 10
            total += (sets * reps_int * AVG_REP_SECONDS) + (
                max(0, sets - 1) * float(rest)
            )
    return int(total)


def _lookup_exercise(exercise_name: str, exercise_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Look up an exercise by id or name across both library stores."""
    lib = get_exercise_library_service()
    if exercise_id:
        found = lib.get_exercise_by_id(exercise_id)
        if found:
            return found
    results = lib.search_exercises(exercise_name, limit=1)
    if results:
        return results[0]

    # Fallback: exercise_library_cleaned (same pattern as workout_operations.py)
    try:
        db = get_supabase_db()
        cleaned = db.client.table("exercise_library_cleaned") \
            .select("id, name, target_muscle, body_part, equipment, gif_url, video_url, secondary_muscles, instructions") \
            .ilike("name", exercise_name) \
            .limit(1) \
            .execute()
        if cleaned.data:
            row = cleaned.data[0]
            return {
                **row,
                "name": row.get("name", exercise_name),
                "muscle_group": row.get("target_muscle") or row.get("body_part", ""),
            }
    except Exception as e:
        logger.warning(
            f"Fallback exercise_library_cleaned lookup failed for '{exercise_name}': {e}",
            exc_info=True,
        )
    return None


class PreviewSwapExerciseRequest(BaseModel):
    """Swap one exercise for another inside a cached preview payload."""

    preview_id: str = Field(..., min_length=1, max_length=200)
    old_exercise_name: str = Field(..., max_length=200)
    new_exercise_name: str = Field(..., max_length=200)
    new_exercise_id: Optional[str] = Field(default=None, max_length=100)
    # Optional cardio-shape passthroughs, mirroring SwapExerciseRequest so the
    # frontend can share the same request builder.
    duration_seconds: Optional[float] = None
    speed_mph: Optional[float] = None
    incline_percent: Optional[float] = None
    rpm: Optional[float] = None
    resistance_level: Optional[float] = None
    stroke_rate_spm: Optional[float] = None


class PreviewAddExerciseRequest(BaseModel):
    """Append an exercise to a cached preview payload's main section."""

    preview_id: str = Field(..., min_length=1, max_length=200)
    exercise_name: str = Field(..., max_length=200)
    exercise_id: Optional[str] = Field(default=None, max_length=100)
    sets: Optional[int] = Field(default=3, ge=1, le=10)
    reps: Optional[int] = Field(default=10, ge=1, le=100)
    rest_seconds: Optional[int] = Field(default=60, ge=0, le=300)
    duration_seconds: Optional[float] = None
    speed_mph: Optional[float] = None
    incline_percent: Optional[float] = None
    rpm: Optional[float] = None
    resistance_level: Optional[float] = None
    stroke_rate_spm: Optional[float] = None


def _serialize_preview_workout(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Client-facing projection of a preview payload (mirrors the projection
    in versioning.py — kept local to avoid a circular import).
    """
    import json as _json
    exercises = payload.get("exercises_json") or []
    if isinstance(exercises, str):
        try:
            exercises = _json.loads(exercises)
        except (ValueError, _json.JSONDecodeError):
            exercises = []

    equipment = payload.get("equipment")
    if isinstance(equipment, str):
        try:
            equipment = _json.loads(equipment)
        except (ValueError, _json.JSONDecodeError):
            equipment = []

    generation_metadata = payload.get("generation_metadata")
    if isinstance(generation_metadata, str):
        try:
            generation_metadata = _json.loads(generation_metadata)
        except (ValueError, _json.JSONDecodeError):
            generation_metadata = None

    return {
        "id": payload.get("id"),
        "preview_id": payload.get("preview_id"),
        "user_id": payload.get("user_id"),
        "name": payload.get("name"),
        "type": payload.get("type"),
        "difficulty": payload.get("difficulty"),
        "scheduled_date": payload.get("scheduled_date"),
        "exercises_json": exercises,
        "duration_minutes": payload.get("duration_minutes"),
        "equipment": equipment,
        "is_completed": payload.get("is_completed", False),
        "generation_method": payload.get("generation_method"),
        "generation_source": payload.get("generation_source"),
        "generation_metadata": generation_metadata,
        "is_preview": True,
    }


@router.post("/preview/swap-exercise")
async def preview_swap_exercise(
    body: PreviewSwapExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
    """Swap one exercise for another inside a cached preview. No DB write.

    Errors:
      - 404 PREVIEW_EXPIRED: preview missing/expired. Client should retry
        the full regenerate flow.
      - 403 PREVIEW_NOT_OWNED: preview belongs to another user.
      - 404 EXERCISE_NOT_FOUND: ``old_exercise_name`` is not in the preview.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    preview_cache = get_preview_cache()
    entry, err = await preview_cache.get_owned(body.preview_id, user_id)
    if entry is None:
        if err == "PREVIEW_NOT_OWNED":
            raise _preview_error(
                "PREVIEW_NOT_OWNED",
                403,
                "This preview belongs to another user.",
            )
        raise _preview_error(
            "PREVIEW_EXPIRED",
            404,
            "The preview has expired. Please regenerate and try again.",
        )

    # Look up the new exercise (library lookup runs outside the cache lock).
    new_ex_info = _lookup_exercise(body.new_exercise_name, body.new_exercise_id)

    def _mutate(payload: Dict[str, Any]) -> Dict[str, Any]:
        exercises = payload.get("exercises_json") or []
        # Normalize stringified exercises_json (older preview payloads).
        if isinstance(exercises, str):
            try:
                import json as _json
                exercises = _json.loads(exercises)
            except (ValueError, Exception):
                exercises = []

        target_idx = None
        target_name_lower = body.old_exercise_name.lower()
        for i, ex in enumerate(exercises):
            if isinstance(ex, dict) and (ex.get("name") or "").lower() == target_name_lower:
                target_idx = i
                break

        if target_idx is None:
            # Surfaced outside via sentinel — the mutator can't raise HTTP
            # errors directly because we're under the cache lock. Use an
            # in-payload flag to propagate back.
            payload["_swap_result"] = {"ok": False, "reason": "EXERCISE_NOT_FOUND"}
            return payload

        old_entry = exercises[target_idx]
        if new_ex_info:
            swapped = {
                **old_entry,
                "name": new_ex_info.get("name", body.new_exercise_name),
                "muscle_group": new_ex_info.get("target_muscle")
                    or new_ex_info.get("body_part")
                    or old_entry.get("muscle_group"),
                "equipment": new_ex_info.get("equipment") or old_entry.get("equipment"),
                "notes": new_ex_info.get("instructions") or old_entry.get("notes", ""),
                "gif_url": new_ex_info.get("gif_url") or new_ex_info.get("video_url"),
                "video_url": new_ex_info.get("video_url") or new_ex_info.get("gif_url"),
                "library_id": new_ex_info.get("id"),
                "secondary_muscles": new_ex_info.get("secondary_muscles", []),
            }
        else:
            # No library match — still honour the swap with the user-supplied
            # name. The regen preview is transient; we never persist a bad
            # exercise row unless the user explicitly approves.
            swapped = {**old_entry, "name": body.new_exercise_name}

        # Cardio-shape passthroughs
        if body.duration_seconds is not None:
            swapped["duration_seconds"] = body.duration_seconds
            swapped["is_timed"] = True
        for fld in ("speed_mph", "incline_percent", "rpm", "resistance_level", "stroke_rate_spm"):
            v = getattr(body, fld)
            if v is not None:
                swapped[fld] = v

        exercises[target_idx] = swapped
        payload["exercises_json"] = exercises

        # Recompute derived totals so the review sheet stays honest.
        total_s = _sum_duration_seconds(exercises)
        if total_s:
            payload["duration_minutes"] = max(1, int(round(total_s / 60)))

        payload["_swap_result"] = {"ok": True}
        return payload

    updated_entry = await preview_cache.update(body.preview_id, user_id, _mutate)
    if updated_entry is None:
        # Lost the race against TTL expiry.
        raise _preview_error(
            "PREVIEW_EXPIRED",
            404,
            "The preview has expired. Please regenerate and try again.",
        )

    swap_result = updated_entry.payload.pop("_swap_result", {"ok": False})
    if not swap_result.get("ok"):
        reason = swap_result.get("reason", "UNKNOWN")
        if reason == "EXERCISE_NOT_FOUND":
            raise _preview_error(
                "EXERCISE_NOT_FOUND",
                404,
                f"Exercise '{body.old_exercise_name}' is not in this preview.",
            )
        raise _preview_error("SWAP_FAILED", 500, "Swap failed for unknown reason.")

    logger.info(
        f"🔁 Preview swap: preview={body.preview_id} "
        f"'{body.old_exercise_name}' -> '{body.new_exercise_name}'"
    )
    return {"preview_id": body.preview_id, "workout": _serialize_preview_workout(updated_entry.payload)}


@router.post("/preview/add-exercise")
async def preview_add_exercise(
    body: PreviewAddExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
    """Append an exercise to the main section of a cached preview. No DB write."""
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    preview_cache = get_preview_cache()
    entry, err = await preview_cache.get_owned(body.preview_id, user_id)
    if entry is None:
        if err == "PREVIEW_NOT_OWNED":
            raise _preview_error(
                "PREVIEW_NOT_OWNED",
                403,
                "This preview belongs to another user.",
            )
        raise _preview_error(
            "PREVIEW_EXPIRED",
            404,
            "The preview has expired. Please regenerate and try again.",
        )

    ex_info = _lookup_exercise(body.exercise_name, body.exercise_id)

    def _mutate(payload: Dict[str, Any]) -> Dict[str, Any]:
        exercises = payload.get("exercises_json") or []
        if isinstance(exercises, str):
            try:
                import json as _json
                exercises = _json.loads(exercises)
            except (ValueError, Exception):
                exercises = []

        if ex_info:
            new_exercise = {
                "name": ex_info.get("name", body.exercise_name),
                "sets": body.sets,
                "reps": body.reps,
                "rest_seconds": body.rest_seconds,
                "muscle_group": ex_info.get("target_muscle") or ex_info.get("body_part"),
                "equipment": ex_info.get("equipment"),
                "notes": ex_info.get("instructions", ""),
                "gif_url": ex_info.get("gif_url") or ex_info.get("video_url"),
                "video_url": ex_info.get("video_url") or ex_info.get("gif_url"),
                "library_id": ex_info.get("id"),
                "secondary_muscles": ex_info.get("secondary_muscles", []),
            }
        else:
            new_exercise = {
                "name": body.exercise_name,
                "sets": body.sets,
                "reps": body.reps,
                "rest_seconds": body.rest_seconds,
            }

        # Cardio-shape passthroughs
        if body.duration_seconds is not None:
            new_exercise["duration_seconds"] = body.duration_seconds
            new_exercise["is_timed"] = True
        for fld in ("speed_mph", "incline_percent", "rpm", "resistance_level", "stroke_rate_spm"):
            v = getattr(body, fld)
            if v is not None:
                new_exercise[fld] = v

        exercises.append(new_exercise)
        payload["exercises_json"] = exercises

        # Recompute derived fields
        total_s = _sum_duration_seconds(exercises)
        if total_s:
            payload["duration_minutes"] = max(1, int(round(total_s / 60)))

        return payload

    updated_entry = await preview_cache.update(body.preview_id, user_id, _mutate)
    if updated_entry is None:
        raise _preview_error(
            "PREVIEW_EXPIRED",
            404,
            "The preview has expired. Please regenerate and try again.",
        )

    logger.info(
        f"➕ Preview add: preview={body.preview_id} '{body.exercise_name}' "
        f"(exercises now={len(updated_entry.payload.get('exercises_json') or [])})"
    )
    return {"preview_id": body.preview_id, "workout": _serialize_preview_workout(updated_entry.payload)}
