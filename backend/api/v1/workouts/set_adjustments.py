"""
Set Adjustment API endpoints.

This module handles set adjustment operations during active workouts:
- POST /{workout_id}/sets/adjust - Record a set adjustment (removed, skipped, reduced)
- POST /{workout_id}/sets/{set_number}/edit - Edit a completed set's reps/weight
- DELETE /{workout_id}/sets/{set_number} - Delete a completed set
- GET /{workout_id}/adjustments - Get all adjustments made during a workout
- GET /users/{user_id}/set-adjustment-patterns - Get user's adjustment patterns for AI

Fatigue Detection endpoints:
- POST /{workout_id}/fatigue-check - Analyze fatigue and get recommendations
- POST /{workout_id}/fatigue-response - Log user response to fatigue suggestion
- GET /{workout_id}/fatigue-history - Get fatigue events for a workout
- GET /{workout_id}/fatigue-summary - Get fatigue summary for completed workout

These endpoints track how users modify their workouts in real-time,
which is valuable data for improving AI workout personalization.
"""

from .set_adjustments_models import *  # noqa: F401, F403
from .set_adjustments_endpoints import router as _endpoints_router

import json
import uuid
from datetime import datetime, timedelta
from typing import Optional, List
from collections import Counter
from pydantic import BaseModel, Field

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error

from core.supabase_db import get_supabase_db
from core.db import get_supabase_db as get_db
from core.logger import get_logger
from models.schemas import (
    SetAdjustmentRequest,
    SetAdjustmentResponse,
    EditSetRequest,
    EditSetResponse,
    DeleteSetResponse,
    SetAdjustmentRecord,
    WorkoutAdjustmentsResponse,
    ExerciseAdjustmentPattern,
    UserSetAdjustmentPatternsResponse,
)
from services.user_context_service import user_context_service
from services.fatigue_detection_service import (
    FatigueDetectionService,
    SetPerformance,
    FatigueAnalysis,
    log_fatigue_detection_event,
    get_fatigue_detection_service,
)

from .utils import log_workout_change

router = APIRouter()
logger = get_logger(__name__)


# Valid adjustment types and reasons for validation
VALID_ADJUSTMENT_TYPES = {
    "set_removed",
    "set_skipped",
    "sets_reduced",
    "exercise_ended_early",
    "set_edited",
    "set_deleted",
}

VALID_REASONS = {
    "fatigue",
    "time_constraint",
    "pain",
    "equipment_issue",
    "other",
}


@router.post("/{workout_id}/sets/adjust", response_model=SetAdjustmentResponse)
async def adjust_sets(workout_id: str, request: SetAdjustmentRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Record a set adjustment during an active workout.

    This endpoint is called when a user:
    - Removes a set from an exercise
    - Skips a set
    - Reduces the total number of sets for an exercise
    - Ends an exercise early
    - Edits a completed set
    - Deletes a completed set

    The data is logged for AI personalization - understanding when and why
    users adjust their workouts helps generate better-tailored plans.
    """
    logger.info(
        f"Recording set adjustment for workout {workout_id}: "
        f"exercise={request.exercise_name}, type={request.adjustment_type}"
    )

    # Validate adjustment type
    if request.adjustment_type not in VALID_ADJUSTMENT_TYPES:
        logger.warning(f"Invalid adjustment type: {request.adjustment_type}")
        raise HTTPException(
            status_code=400,
            detail=f"Invalid adjustment_type. Must be one of: {', '.join(VALID_ADJUSTMENT_TYPES)}"
        )

    # Validate reason if provided
    if request.reason and request.reason not in VALID_REASONS:
        logger.warning(f"Invalid adjustment reason: {request.reason}")
        raise HTTPException(
            status_code=400,
            detail=f"Invalid reason. Must be one of: {', '.join(VALID_REASONS)}"
        )

    try:
        db = get_supabase_db()
        supabase = get_db().client

        # Verify workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            logger.warning(f"Workout not found: {workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        user_id = workout.get("user_id")

        # Generate adjustment ID
        adjustment_id = str(uuid.uuid4())
        now = datetime.now()

        # Prepare adjustment record
        adjustment_data = {
            "id": adjustment_id,
            "workout_id": workout_id,
            "user_id": user_id,
            "exercise_index": request.exercise_index,
            "exercise_id": request.exercise_id,
            "exercise_name": request.exercise_name,
            "adjustment_type": request.adjustment_type,
            "original_sets": request.original_sets,
            "adjusted_sets": request.adjusted_sets,
            "reason": request.reason,
            "reason_details": request.reason_details,
            "set_number": request.set_number,
            "metadata": json.dumps(request.metadata) if request.metadata else None,
            "recorded_at": now.isoformat(),
        }

        # Insert into set_adjustments table
        supabase.table("set_adjustments").insert(adjustment_data).execute()

        logger.info(
            f"Set adjustment recorded: id={adjustment_id}, "
            f"workout={workout_id}, exercise={request.exercise_name}, "
            f"type={request.adjustment_type}, sets: {request.original_sets} -> {request.adjusted_sets}"
        )

        # Log workout change for audit trail
        log_workout_change(
            workout_id=workout_id,
            user_id=user_id,
            change_type="set_adjustment",
            field_changed="exercises",
            old_value={
                "exercise_name": request.exercise_name,
                "original_sets": request.original_sets,
            },
            new_value={
                "exercise_name": request.exercise_name,
                "adjusted_sets": request.adjusted_sets,
                "adjustment_type": request.adjustment_type,
                "reason": request.reason,
            },
            change_source="user",
            change_reason=request.reason_details or request.reason,
        )

        # Log to user context for AI personalization
        try:
            await user_context_service.log_event(
                user_id=user_id,
                event_type="set_adjustment",
                event_data={
                    "workout_id": workout_id,
                    "adjustment_id": adjustment_id,
                    "exercise_name": request.exercise_name,
                    "exercise_id": request.exercise_id,
                    "adjustment_type": request.adjustment_type,
                    "original_sets": request.original_sets,
                    "adjusted_sets": request.adjusted_sets,
                    "sets_reduced_by": request.original_sets - request.adjusted_sets,
                    "reason": request.reason,
                    "reason_details": request.reason_details,
                },
            )
        except Exception as log_error:
            # Non-critical, continue even if logging fails
            logger.warning(f"Failed to log set adjustment to user context: {log_error}", exc_info=True)

        # Build response message
        sets_diff = request.original_sets - request.adjusted_sets
        if request.adjustment_type == "set_removed":
            message = f"Removed 1 set from {request.exercise_name}"
        elif request.adjustment_type == "set_skipped":
            message = f"Skipped set {request.set_number or ''} for {request.exercise_name}"
        elif request.adjustment_type == "sets_reduced":
            message = f"Reduced {request.exercise_name} from {request.original_sets} to {request.adjusted_sets} sets"
        elif request.adjustment_type == "exercise_ended_early":
            message = f"Ended {request.exercise_name} early after {request.adjusted_sets} of {request.original_sets} sets"
        else:
            message = f"Set adjustment recorded for {request.exercise_name}"

        return SetAdjustmentResponse(
            adjustment_id=adjustment_id,
            workout_id=workout_id,
            exercise_name=request.exercise_name,
            adjustment_type=request.adjustment_type,
            original_sets=request.original_sets,
            adjusted_sets=request.adjusted_sets,
            recorded_at=now,
            message=message,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to record set adjustment: {e}", exc_info=True)
        raise safe_internal_error(e, "set_adjustments")


@router.post("/{workout_id}/sets/{set_number}/edit", response_model=EditSetResponse)
async def edit_set(workout_id: str, set_number: int, request: EditSetRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Edit a completed set's reps and/or weight.

    Called when a user wants to correct the reps or weight they entered
    for a completed set. This updates both the set adjustment log and
    the underlying workout data.
    """
    logger.info(
        f"Editing set {set_number} for workout {workout_id}: "
        f"exercise={request.exercise_name}, "
        f"reps: {request.previous_reps} -> {request.new_reps}, "
        f"weight: {request.previous_weight} -> {request.new_weight}"
    )

    if set_number < 1:
        raise HTTPException(status_code=400, detail="Set number must be at least 1")

    try:
        db = get_supabase_db()
        supabase = get_db().client

        # Verify workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            logger.warning(f"Workout not found: {workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        user_id = workout.get("user_id")
        now = datetime.now()

        # Record the edit as a set adjustment
        adjustment_id = str(uuid.uuid4())
        adjustment_data = {
            "id": adjustment_id,
            "workout_id": workout_id,
            "user_id": user_id,
            "exercise_index": request.exercise_index,
            "exercise_name": request.exercise_name,
            "adjustment_type": "set_edited",
            "original_sets": 1,  # Individual set edit
            "adjusted_sets": 1,
            "set_number": set_number,
            "metadata": json.dumps({
                "previous_reps": request.previous_reps,
                "previous_weight": request.previous_weight,
                "new_reps": request.new_reps,
                "new_weight": request.new_weight,
            }),
            "recorded_at": now.isoformat(),
        }

        supabase.table("set_adjustments").insert(adjustment_data).execute()

        # Update the workout exercises_json if the workout has the data
        exercises = workout.get("exercises") or workout.get("exercises_json") or []
        if isinstance(exercises, str):
            exercises = json.loads(exercises)

        if 0 <= request.exercise_index < len(exercises):
            exercise = exercises[request.exercise_index]
            sets = exercise.get("sets", [])
            if 0 < set_number <= len(sets):
                # Update the specific set
                sets[set_number - 1]["reps"] = request.new_reps
                sets[set_number - 1]["weight_kg"] = request.new_weight
                sets[set_number - 1]["edited_at"] = now.isoformat()

                # Update the workout
                db.update_workout(workout_id, {
                    "exercises": exercises,
                    "last_modified_at": now.isoformat(),
                    "last_modified_method": "set_edited",
                })

        logger.info(f"Set {set_number} edited for workout {workout_id}")

        # Log workout change
        log_workout_change(
            workout_id=workout_id,
            user_id=user_id,
            change_type="set_edited",
            field_changed="exercises",
            old_value={
                "exercise_name": request.exercise_name,
                "set_number": set_number,
                "reps": request.previous_reps,
                "weight_kg": request.previous_weight,
            },
            new_value={
                "exercise_name": request.exercise_name,
                "set_number": set_number,
                "reps": request.new_reps,
                "weight_kg": request.new_weight,
            },
            change_source="user",
        )

        # Log to user context
        try:
            await user_context_service.log_event(
                user_id=user_id,
                event_type="set_edited",
                event_data={
                    "workout_id": workout_id,
                    "exercise_name": request.exercise_name,
                    "set_number": set_number,
                    "previous_reps": request.previous_reps,
                    "previous_weight": request.previous_weight,
                    "new_reps": request.new_reps,
                    "new_weight": request.new_weight,
                    "reps_diff": request.new_reps - request.previous_reps,
                    "weight_diff": request.new_weight - request.previous_weight,
                },
            )
        except Exception as log_error:
            logger.warning(f"Failed to log set edit to user context: {log_error}", exc_info=True)

        return EditSetResponse(
            success=True,
            workout_id=workout_id,
            set_number=set_number,
            exercise_name=request.exercise_name,
            previous_reps=request.previous_reps,
            previous_weight=request.previous_weight,
            new_reps=request.new_reps,
            new_weight=request.new_weight,
            edited_at=now,
            message=f"Set {set_number} updated: {request.new_reps} reps @ {request.new_weight}kg",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to edit set: {e}", exc_info=True)
        raise safe_internal_error(e, "set_adjustments")


@router.delete("/{workout_id}/sets/{set_number}", response_model=DeleteSetResponse)
async def delete_set(
    workout_id: str,
    set_number: int,
    exercise_index: int = Query(..., ge=0, description="Index of the exercise in the workout"),
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a completed set from a workout.

    Removes the specified set and records the deletion for AI learning.
    """
    logger.info(f"Deleting set {set_number} from workout {workout_id}, exercise_index={exercise_index}")

    if set_number < 1:
        raise HTTPException(status_code=400, detail="Set number must be at least 1")

    try:
        db = get_supabase_db()
        supabase = get_db().client

        # Verify workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            logger.warning(f"Workout not found: {workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        user_id = workout.get("user_id")
        now = datetime.now()

        # Get exercises
        exercises = workout.get("exercises") or workout.get("exercises_json") or []
        if isinstance(exercises, str):
            exercises = json.loads(exercises)

        if exercise_index >= len(exercises):
            raise HTTPException(
                status_code=400,
                detail=f"Exercise index {exercise_index} out of range"
            )

        exercise = exercises[exercise_index]
        exercise_name = exercise.get("name", "Unknown Exercise")
        sets = exercise.get("sets", [])

        if set_number > len(sets):
            raise HTTPException(
                status_code=400,
                detail=f"Set number {set_number} out of range for exercise with {len(sets)} sets"
            )

        # Get the set data before deleting
        deleted_set = sets[set_number - 1] if sets else None

        # Remove the set from the exercise
        del sets[set_number - 1]

        # Update the workout
        db.update_workout(workout_id, {
            "exercises": exercises,
            "last_modified_at": now.isoformat(),
            "last_modified_method": "set_deleted",
        })

        # Record the deletion as a set adjustment
        adjustment_id = str(uuid.uuid4())
        adjustment_data = {
            "id": adjustment_id,
            "workout_id": workout_id,
            "user_id": user_id,
            "exercise_index": exercise_index,
            "exercise_name": exercise_name,
            "adjustment_type": "set_deleted",
            "original_sets": len(sets) + 1,  # Before deletion
            "adjusted_sets": len(sets),  # After deletion
            "set_number": set_number,
            "metadata": json.dumps({
                "deleted_set": deleted_set,
            }) if deleted_set else None,
            "recorded_at": now.isoformat(),
        }

        supabase.table("set_adjustments").insert(adjustment_data).execute()

        logger.info(f"Deleted set {set_number} from exercise {exercise_name} in workout {workout_id}")

        # Log workout change
        log_workout_change(
            workout_id=workout_id,
            user_id=user_id,
            change_type="set_deleted",
            field_changed="exercises",
            old_value={
                "exercise_name": exercise_name,
                "set_number": set_number,
                "set_data": deleted_set,
            },
            new_value={
                "exercise_name": exercise_name,
                "sets_remaining": len(sets),
            },
            change_source="user",
        )

        # Log to user context
        try:
            await user_context_service.log_event(
                user_id=user_id,
                event_type="set_deleted",
                event_data={
                    "workout_id": workout_id,
                    "exercise_name": exercise_name,
                    "exercise_index": exercise_index,
                    "set_number": set_number,
                    "deleted_set_data": deleted_set,
                },
            )
        except Exception as log_error:
            logger.warning(f"Failed to log set deletion to user context: {log_error}", exc_info=True)

        return DeleteSetResponse(
            success=True,
            workout_id=workout_id,
            set_number=set_number,
            exercise_name=exercise_name,
            exercise_index=exercise_index,
            deleted_at=now,
            message=f"Deleted set {set_number} from {exercise_name}",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete set: {e}", exc_info=True)
        raise safe_internal_error(e, "set_adjustments")


@router.get("/{workout_id}/adjustments", response_model=WorkoutAdjustmentsResponse)
async def get_workout_adjustments(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all set adjustments made during a workout.

    Returns a list of all adjustments (removed sets, edited sets, etc.)
    along with a summary of the modifications.
    """
    logger.info(f"Getting adjustments for workout {workout_id}")

    try:
        db = get_supabase_db()
        supabase = get_db().client

        # Verify workout exists
        workout = db.get_workout(workout_id)
        if not workout:
            logger.warning(f"Workout not found: {workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")

        # Get all adjustments for this workout
        result = supabase.table("set_adjustments").select("*").eq(
            "workout_id", workout_id
        ).order("recorded_at", desc=False).execute()

        adjustments = []
        adjustment_types = Counter()
        reasons = Counter()
        exercises_adjusted = set()
        total_sets_removed = 0

        for row in result.data or []:
            # Parse metadata if present
            metadata = None
            if row.get("metadata"):
                try:
                    metadata = json.loads(row["metadata"]) if isinstance(row["metadata"], str) else row["metadata"]
                except json.JSONDecodeError:
                    metadata = None

            adjustment = SetAdjustmentRecord(
                id=row["id"],
                workout_id=row["workout_id"],
                user_id=row["user_id"],
                exercise_index=row["exercise_index"],
                exercise_id=row.get("exercise_id"),
                exercise_name=row["exercise_name"],
                adjustment_type=row["adjustment_type"],
                original_sets=row["original_sets"],
                adjusted_sets=row["adjusted_sets"],
                reason=row.get("reason"),
                reason_details=row.get("reason_details"),
                set_number=row.get("set_number"),
                metadata=metadata,
                recorded_at=row["recorded_at"],
            )
            adjustments.append(adjustment)

            # Track summary stats
            adjustment_types[row["adjustment_type"]] += 1
            if row.get("reason"):
                reasons[row["reason"]] += 1
            exercises_adjusted.add(row["exercise_name"])
            total_sets_removed += row["original_sets"] - row["adjusted_sets"]

        # Build summary
        summary = {
            "total_adjustments": len(adjustments),
            "adjustment_types": dict(adjustment_types),
            "reason_distribution": dict(reasons) if reasons else None,
            "exercises_adjusted": list(exercises_adjusted),
            "total_sets_removed": total_sets_removed,
        }

        logger.info(f"Found {len(adjustments)} adjustments for workout {workout_id}")

        return WorkoutAdjustmentsResponse(
            workout_id=workout_id,
            adjustments=adjustments,
            total_adjustments=len(adjustments),
            adjustment_summary=summary,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout adjustments: {e}", exc_info=True)
        raise safe_internal_error(e, "set_adjustments")



# Include secondary endpoints
router.include_router(_endpoints_router)
