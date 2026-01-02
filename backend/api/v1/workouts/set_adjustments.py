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
import json
import uuid
from datetime import datetime, timedelta
from typing import Optional, List
from collections import Counter
from pydantic import BaseModel, Field

from fastapi import APIRouter, HTTPException, Query

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
async def adjust_sets(workout_id: str, request: SetAdjustmentRequest):
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
            logger.warning(f"Failed to log set adjustment to user context: {log_error}")

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
        logger.error(f"Failed to record set adjustment: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{workout_id}/sets/{set_number}/edit", response_model=EditSetResponse)
async def edit_set(workout_id: str, set_number: int, request: EditSetRequest):
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
            logger.warning(f"Failed to log set edit to user context: {log_error}")

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
        logger.error(f"Failed to edit set: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{workout_id}/sets/{set_number}", response_model=DeleteSetResponse)
async def delete_set(
    workout_id: str,
    set_number: int,
    exercise_index: int = Query(..., ge=0, description="Index of the exercise in the workout"),
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
            logger.warning(f"Failed to log set deletion to user context: {log_error}")

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
        logger.error(f"Failed to delete set: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{workout_id}/adjustments", response_model=WorkoutAdjustmentsResponse)
async def get_workout_adjustments(workout_id: str):
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
        logger.error(f"Failed to get workout adjustments: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/users/{user_id}/set-adjustment-patterns", response_model=UserSetAdjustmentPatternsResponse)
async def get_user_set_adjustment_patterns(
    user_id: str,
    days: int = Query(default=90, ge=7, le=365, description="Number of days to analyze"),
):
    """
    Get user's set adjustment patterns for AI personalization.

    Analyzes the user's historical set adjustments to identify patterns:
    - Which exercises they frequently reduce sets for
    - Common reasons for adjustments (fatigue, time, pain)
    - Time-of-day patterns
    - Workout duration patterns

    This data helps the AI generate better-tailored workouts by:
    - Reducing sets for exercises the user consistently adjusts
    - Adjusting workout length based on time constraint patterns
    - Avoiding exercises that frequently cause pain
    """
    logger.info(f"Getting set adjustment patterns for user {user_id} (last {days} days)")

    try:
        db = get_supabase_db()
        supabase = get_db().client

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Calculate date range
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        # Get all adjustments for this user in the time period
        result = supabase.table("set_adjustments").select("*").eq(
            "user_id", user_id
        ).gte("recorded_at", cutoff_date).execute()

        adjustments = result.data or []

        if not adjustments:
            logger.info(f"No adjustments found for user {user_id} in the last {days} days")
            return UserSetAdjustmentPatternsResponse(
                user_id=user_id,
                analysis_period_days=days,
                total_workouts_analyzed=0,
                total_adjustments=0,
                avg_adjustments_per_workout=0,
                frequently_adjusted_exercises=[],
            )

        # Count unique workouts
        workout_ids = set(adj["workout_id"] for adj in adjustments)
        total_workouts = len(workout_ids)

        # Aggregate by exercise
        exercise_adjustments = {}
        adjustment_types = Counter()
        reasons = Counter()
        time_of_day = Counter()

        for adj in adjustments:
            exercise_name = adj["exercise_name"]
            exercise_id = adj.get("exercise_id")

            if exercise_name not in exercise_adjustments:
                exercise_adjustments[exercise_name] = {
                    "exercise_id": exercise_id,
                    "count": 0,
                    "total_sets_reduced": 0,
                    "reasons": Counter(),
                    "types": Counter(),
                    "last_adjustment": None,
                }

            ea = exercise_adjustments[exercise_name]
            ea["count"] += 1
            ea["total_sets_reduced"] += adj["original_sets"] - adj["adjusted_sets"]
            if adj.get("reason"):
                ea["reasons"][adj["reason"]] += 1
            ea["types"][adj["adjustment_type"]] += 1

            # Track last adjustment
            recorded_at = adj["recorded_at"]
            if ea["last_adjustment"] is None or recorded_at > ea["last_adjustment"]:
                ea["last_adjustment"] = recorded_at

            # Overall stats
            adjustment_types[adj["adjustment_type"]] += 1
            if adj.get("reason"):
                reasons[adj["reason"]] += 1

            # Time of day analysis
            try:
                if isinstance(recorded_at, str):
                    dt = datetime.fromisoformat(recorded_at.replace("Z", "+00:00"))
                else:
                    dt = recorded_at

                hour = dt.hour
                if 5 <= hour < 12:
                    time_of_day["morning"] += 1
                elif 12 <= hour < 17:
                    time_of_day["afternoon"] += 1
                elif 17 <= hour < 21:
                    time_of_day["evening"] += 1
                else:
                    time_of_day["night"] += 1
            except Exception:
                pass

        # Build frequently adjusted exercises list (sorted by count)
        frequently_adjusted = []
        for exercise_name, data in sorted(
            exercise_adjustments.items(),
            key=lambda x: x[1]["count"],
            reverse=True
        )[:20]:  # Top 20 exercises
            avg_sets_reduced = data["total_sets_reduced"] / data["count"] if data["count"] > 0 else 0
            most_common_reason = data["reasons"].most_common(1)[0][0] if data["reasons"] else None

            pattern = ExerciseAdjustmentPattern(
                exercise_name=exercise_name,
                exercise_id=data["exercise_id"],
                total_adjustments=data["count"],
                avg_sets_reduced=round(avg_sets_reduced, 2),
                most_common_reason=most_common_reason,
                reason_distribution=dict(data["reasons"]) if data["reasons"] else None,
                adjustment_type_distribution=dict(data["types"]) if data["types"] else None,
                last_adjustment_date=data["last_adjustment"],
            )
            frequently_adjusted.append(pattern)

        # Calculate overall stats
        avg_adjustments = len(adjustments) / total_workouts if total_workouts > 0 else 0
        most_common_type = adjustment_types.most_common(1)[0][0] if adjustment_types else None
        most_common_reason = reasons.most_common(1)[0][0] if reasons else None

        # Generate AI recommendations based on patterns
        recommendations = []

        # Pain-related recommendations
        pain_count = reasons.get("pain", 0)
        if pain_count > 0:
            pain_pct = (pain_count / len(adjustments)) * 100
            if pain_pct > 10:
                recommendations.append(
                    f"User frequently adjusts due to pain ({pain_pct:.0f}% of adjustments). "
                    "Consider lighter weights and more warmup time."
                )

        # Fatigue recommendations
        fatigue_count = reasons.get("fatigue", 0)
        if fatigue_count > 0:
            fatigue_pct = (fatigue_count / len(adjustments)) * 100
            if fatigue_pct > 20:
                recommendations.append(
                    f"User frequently adjusts due to fatigue ({fatigue_pct:.0f}% of adjustments). "
                    "Consider reducing workout volume or adding rest days."
                )

        # Time constraint recommendations
        time_count = reasons.get("time_constraint", 0)
        if time_count > 0:
            time_pct = (time_count / len(adjustments)) * 100
            if time_pct > 15:
                recommendations.append(
                    f"User frequently adjusts due to time constraints ({time_pct:.0f}%). "
                    "Consider shorter workout duration or fewer exercises."
                )

        # Exercise-specific recommendations
        for ex_pattern in frequently_adjusted[:3]:
            if ex_pattern.total_adjustments >= 3 and ex_pattern.avg_sets_reduced >= 1:
                recommendations.append(
                    f"Consider reducing default sets for '{ex_pattern.exercise_name}' "
                    f"(avg {ex_pattern.avg_sets_reduced:.1f} sets reduced per workout)."
                )

        logger.info(
            f"Generated adjustment patterns for user {user_id}: "
            f"{len(adjustments)} adjustments across {total_workouts} workouts"
        )

        return UserSetAdjustmentPatternsResponse(
            user_id=user_id,
            analysis_period_days=days,
            total_workouts_analyzed=total_workouts,
            total_adjustments=len(adjustments),
            avg_adjustments_per_workout=round(avg_adjustments, 2),
            most_common_adjustment_type=most_common_type,
            most_common_reason=most_common_reason,
            frequently_adjusted_exercises=frequently_adjusted,
            reason_distribution=dict(reasons) if reasons else None,
            adjustments_by_time_of_day=dict(time_of_day) if time_of_day else None,
            ai_recommendations=recommendations if recommendations else None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user set adjustment patterns: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Fatigue Detection Models
# =============================================================================

class SetPerformanceInput(BaseModel):
    """Input model for set performance data in fatigue analysis."""
    reps: int = Field(..., ge=0, le=100, description="Number of reps completed")
    weight_kg: float = Field(..., ge=0, le=1000, description="Weight used in kg")
    rpe: Optional[float] = Field(
        default=None,
        ge=1, le=10,
        description="Rate of Perceived Exertion (1-10)"
    )
    duration_seconds: Optional[int] = Field(
        default=None,
        ge=0,
        description="Time taken to complete the set in seconds"
    )
    rest_before_seconds: Optional[int] = Field(
        default=None,
        ge=0,
        description="Rest time taken before this set in seconds"
    )
    timestamp: Optional[datetime] = Field(
        default=None,
        description="When the set was completed"
    )
    is_failure: bool = Field(
        default=False,
        description="Whether the set was taken to failure"
    )
    notes: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Any notes about the set"
    )


class FatigueCheckRequest(BaseModel):
    """Request body for fatigue analysis."""
    user_id: str = Field(..., max_length=100, description="User ID")
    exercise_name: str = Field(..., max_length=200, description="Name of the exercise")
    current_set: int = Field(..., ge=1, description="Current set number (1-indexed)")
    total_sets: int = Field(..., ge=1, description="Total planned sets")
    set_data: List[SetPerformanceInput] = Field(
        ...,
        description="Performance data from completed sets"
    )
    exercise_type: Optional[str] = Field(
        default=None,
        max_length=50,
        description="Type of exercise (compound/isolation/bodyweight)"
    )


class FatigueCheckResponse(BaseModel):
    """Response from fatigue analysis."""
    fatigue_level: float = Field(
        ...,
        ge=0, le=1,
        description="Overall fatigue level (0=fresh, 1=exhausted)"
    )
    indicators: List[str] = Field(
        ...,
        description="List of detected fatigue indicators"
    )
    confidence: float = Field(
        ...,
        ge=0, le=1,
        description="Confidence in the analysis"
    )
    recommendation: str = Field(
        ...,
        description="Suggested action: continue, reduce_weight, reduce_sets, stop_exercise"
    )
    message: str = Field(
        ...,
        description="Human-readable explanation of the analysis"
    )
    suggested_weight_reduction_pct: Optional[int] = Field(
        default=None,
        description="Suggested weight reduction percentage (if applicable)"
    )
    suggested_remaining_sets: Optional[int] = Field(
        default=None,
        description="Suggested remaining sets (if applicable)"
    )
    show_prompt: bool = Field(
        default=False,
        description="Whether to show a prompt to the user"
    )
    prompt_text: Optional[str] = Field(
        default=None,
        description="Text to show in the user prompt"
    )
    alternative_actions: List[str] = Field(
        default_factory=list,
        description="Alternative actions the user could take"
    )


class FatigueResponseRequest(BaseModel):
    """Request to log user response to fatigue suggestion."""
    user_id: str = Field(..., max_length=100)
    exercise_name: str = Field(..., max_length=200)
    fatigue_level: float = Field(..., ge=0, le=1)
    recommendation: str = Field(..., max_length=50)
    user_response: str = Field(
        ...,
        max_length=50,
        description="User response: accepted, declined, ignored"
    )


class FatigueResponseResponse(BaseModel):
    """Response after logging user's fatigue response."""
    success: bool
    message: str
    event_id: Optional[str] = None


class FatigueHistoryItem(BaseModel):
    """A single fatigue detection event."""
    exercise_name: str
    fatigue_level: float
    recommendation: str
    user_response: Optional[str]
    timestamp: datetime


class FatigueHistoryResponse(BaseModel):
    """Response with fatigue history for a workout."""
    workout_id: str
    events: List[FatigueHistoryItem]
    total_events: int


# =============================================================================
# Fatigue Detection API Endpoints
# =============================================================================

@router.post(
    "/{workout_id}/fatigue-check",
    response_model=FatigueCheckResponse,
    summary="Analyze fatigue and get recommendations",
    description="""
    Analyze the user's performance during an active workout to detect fatigue
    and suggest appropriate adjustments.

    This endpoint examines:
    - Rep decline across sets (>20% decline = fatigue indicator)
    - RPE patterns (high RPE or increasing RPE)
    - Weight reductions mid-exercise
    - Rest time patterns
    - Historical performance comparison

    Returns a fatigue analysis with:
    - Fatigue level (0-1)
    - Detected indicators
    - Recommendation (continue, reduce_weight, reduce_sets, stop_exercise)
    - User-friendly prompt text if action is needed
    """,
)
async def check_fatigue(
    workout_id: str,
    request: FatigueCheckRequest,
):
    """
    Analyze fatigue and get recommendations for set adjustments.

    Args:
        workout_id: The ID of the current workout
        request: FatigueCheckRequest with set performance data

    Returns:
        FatigueCheckResponse with analysis and recommendations
    """
    logger.info(
        f"[Fatigue Check] workout_id={workout_id}, user={request.user_id}, "
        f"exercise={request.exercise_name}, set={request.current_set}/{request.total_sets}"
    )

    # Validate workout exists
    try:
        db = get_supabase_db()
        workout_result = db.client.table("workouts").select("id, user_id").eq(
            "id", workout_id
        ).execute()

        if not workout_result.data:
            raise HTTPException(status_code=404, detail="Workout not found")

        workout = workout_result.data[0]
        if workout["user_id"] != request.user_id:
            raise HTTPException(
                status_code=403,
                detail="User does not have access to this workout"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error validating workout: {e}")
        raise HTTPException(status_code=500, detail="Error validating workout")

    # Convert input to SetPerformance objects
    set_data = [
        SetPerformance(
            reps=s.reps,
            weight_kg=s.weight_kg,
            rpe=s.rpe,
            duration_seconds=s.duration_seconds,
            rest_before_seconds=s.rest_before_seconds,
            timestamp=s.timestamp,
            is_failure=s.is_failure,
            notes=s.notes,
        )
        for s in request.set_data
    ]

    # Run fatigue analysis
    service = get_fatigue_detection_service()

    try:
        analysis = await service.analyze_performance(
            user_id=request.user_id,
            exercise_name=request.exercise_name,
            current_set=request.current_set,
            total_sets=request.total_sets,
            set_data=set_data,
            workout_id=workout_id,
            exercise_type=request.exercise_type,
        )

        # Get recommendation
        recommendation = service.get_set_recommendation(analysis)

        logger.info(
            f"[Fatigue Check] Result: fatigue={analysis.fatigue_level:.2f}, "
            f"recommendation={analysis.recommendation}, "
            f"indicators={len(analysis.indicators)}"
        )

        return FatigueCheckResponse(
            fatigue_level=analysis.fatigue_level,
            indicators=analysis.indicators,
            confidence=analysis.confidence,
            recommendation=analysis.recommendation,
            message=analysis.message,
            suggested_weight_reduction_pct=analysis.suggested_weight_reduction_pct,
            suggested_remaining_sets=analysis.suggested_remaining_sets,
            show_prompt=recommendation.show_prompt,
            prompt_text=recommendation.prompt_text,
            alternative_actions=recommendation.alternative_actions,
        )

    except Exception as e:
        logger.error(f"Error in fatigue analysis: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Error analyzing fatigue: {str(e)}"
        )


@router.post(
    "/{workout_id}/fatigue-response",
    response_model=FatigueResponseResponse,
    summary="Log user response to fatigue suggestion",
    description="""
    Log how the user responded to a fatigue suggestion.

    This data is used to:
    1. Improve future fatigue detection accuracy
    2. Learn user preferences for workout intensity
    3. Personalize future workout generation

    Valid responses: accepted, declined, ignored
    """,
)
async def log_fatigue_response(
    workout_id: str,
    request: FatigueResponseRequest,
):
    """
    Log user response to fatigue suggestion for AI learning.

    Args:
        workout_id: The ID of the current workout
        request: FatigueResponseRequest with user response

    Returns:
        FatigueResponseResponse confirming the log
    """
    logger.info(
        f"[Fatigue Response] workout_id={workout_id}, user={request.user_id}, "
        f"exercise={request.exercise_name}, response={request.user_response}"
    )

    # Validate response value
    valid_responses = {"accepted", "declined", "ignored"}
    if request.user_response not in valid_responses:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid user_response. Must be one of: {valid_responses}"
        )

    # Create a minimal FatigueAnalysis for logging
    analysis = FatigueAnalysis(
        fatigue_level=request.fatigue_level,
        indicators=[],  # Not needed for logging
        confidence=0.0,  # Not needed for logging
        recommendation=request.recommendation,
    )

    # Log the event
    try:
        event_id = await log_fatigue_detection_event(
            user_id=request.user_id,
            workout_id=workout_id,
            exercise_name=request.exercise_name,
            fatigue_analysis=analysis,
            user_response=request.user_response,
        )

        return FatigueResponseResponse(
            success=True,
            message=f"Fatigue response logged: {request.user_response}",
            event_id=event_id,
        )

    except Exception as e:
        logger.error(f"Error logging fatigue response: {e}")
        return FatigueResponseResponse(
            success=False,
            message=f"Failed to log response: {str(e)}",
            event_id=None,
        )


@router.get(
    "/{workout_id}/fatigue-history",
    response_model=FatigueHistoryResponse,
    summary="Get fatigue events for a workout",
    description="""
    Retrieve all fatigue detection events that occurred during a workout.

    This is useful for:
    - Post-workout analysis
    - Understanding fatigue patterns
    - Reviewing decisions made during the workout
    """,
)
async def get_fatigue_history(
    workout_id: str,
    user_id: str = Query(..., description="User ID for validation"),
):
    """
    Get fatigue detection history for a workout.

    Args:
        workout_id: The ID of the workout
        user_id: The user's ID (for validation)

    Returns:
        FatigueHistoryResponse with all fatigue events
    """
    logger.info(f"[Fatigue History] workout_id={workout_id}, user={user_id}")

    try:
        db = get_supabase_db()

        # Query user_context_logs for fatigue events
        result = db.client.table("user_context_logs").select(
            "event_data, created_at"
        ).eq("user_id", user_id).eq("event_type", "feature_interaction").execute()

        if not result.data:
            return FatigueHistoryResponse(
                workout_id=workout_id,
                events=[],
                total_events=0,
            )

        # Filter for fatigue events for this workout
        fatigue_events = []
        for row in result.data:
            event_data = row.get("event_data", {})
            if (
                event_data.get("workout_id") == workout_id
                and "fatigue_level" in event_data
            ):
                try:
                    timestamp = datetime.fromisoformat(
                        row["created_at"].replace("Z", "+00:00")
                    ) if row.get("created_at") else datetime.now()
                except Exception:
                    timestamp = datetime.now()

                fatigue_events.append(
                    FatigueHistoryItem(
                        exercise_name=event_data.get("exercise_name", "Unknown"),
                        fatigue_level=event_data.get("fatigue_level", 0),
                        recommendation=event_data.get("recommendation", "unknown"),
                        user_response=event_data.get("user_response"),
                        timestamp=timestamp,
                    )
                )

        # Sort by timestamp
        fatigue_events.sort(key=lambda x: x.timestamp)

        return FatigueHistoryResponse(
            workout_id=workout_id,
            events=fatigue_events,
            total_events=len(fatigue_events),
        )

    except Exception as e:
        logger.error(f"Error getting fatigue history: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving fatigue history: {str(e)}"
        )


@router.get(
    "/{workout_id}/fatigue-summary",
    summary="Get fatigue summary for completed workout",
    description="""
    Get a summary of fatigue patterns for a completed workout.
    Includes average fatigue level, most common recommendations, and user responses.
    """,
)
async def get_fatigue_summary(
    workout_id: str,
    user_id: str = Query(..., description="User ID for validation"),
):
    """
    Get fatigue summary for a completed workout.

    Args:
        workout_id: The ID of the workout
        user_id: The user's ID (for validation)

    Returns:
        Summary of fatigue patterns
    """
    history = await get_fatigue_history(workout_id, user_id)

    if not history.events:
        return {
            "workout_id": workout_id,
            "has_fatigue_data": False,
            "message": "No fatigue events recorded for this workout.",
        }

    events = history.events

    # Calculate summary statistics
    avg_fatigue = sum(e.fatigue_level for e in events) / len(events)
    max_fatigue = max(e.fatigue_level for e in events)

    # Count recommendations
    recommendation_counts = {}
    for e in events:
        rec = e.recommendation
        recommendation_counts[rec] = recommendation_counts.get(rec, 0) + 1

    # Count user responses
    response_counts = {}
    for e in events:
        if e.user_response:
            response_counts[e.user_response] = response_counts.get(e.user_response, 0) + 1

    # Find exercises with highest fatigue
    exercise_fatigue = {}
    for e in events:
        if e.exercise_name not in exercise_fatigue:
            exercise_fatigue[e.exercise_name] = []
        exercise_fatigue[e.exercise_name].append(e.fatigue_level)

    highest_fatigue_exercises = sorted(
        [(name, max(levels)) for name, levels in exercise_fatigue.items()],
        key=lambda x: x[1],
        reverse=True,
    )[:3]

    return {
        "workout_id": workout_id,
        "has_fatigue_data": True,
        "total_fatigue_events": len(events),
        "average_fatigue_level": round(avg_fatigue, 2),
        "max_fatigue_level": round(max_fatigue, 2),
        "recommendation_breakdown": recommendation_counts,
        "user_response_breakdown": response_counts,
        "highest_fatigue_exercises": [
            {"exercise": name, "max_fatigue": round(level, 2)}
            for name, level in highest_fatigue_exercises
        ],
        "suggestions_accepted": response_counts.get("accepted", 0),
        "suggestions_declined": response_counts.get("declined", 0),
        "suggestions_ignored": response_counts.get("ignored", 0),
    }
