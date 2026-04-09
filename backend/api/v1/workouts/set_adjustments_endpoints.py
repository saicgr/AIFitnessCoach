"""Secondary endpoints for set_adjustments.  Sub-router included by main module.
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
from typing import List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
import logging
logger = logging.getLogger(__name__)
from collections import Counter
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from services.fatigue_detection_service import SetPerformance, FatigueAnalysis
from services.fatigue_detection_service_helpers import get_fatigue_detection_service, log_fatigue_detection_event

from .set_adjustments_models import (
    SetPerformanceInput,
    FatigueCheckRequest,
    FatigueCheckResponse,
    FatigueResponseRequest,
    FatigueResponseResponse,
    FatigueHistoryItem,
    FatigueHistoryResponse,
)
from models.schemas import (
    UserSetAdjustmentPatternsResponse,
    ExerciseAdjustmentPattern,
)

router = APIRouter()

@router.get("/users/{user_id}/set-adjustment-patterns", response_model=UserSetAdjustmentPatternsResponse)
async def get_user_set_adjustment_patterns(
    user_id: str,
    days: int = Query(default=90, ge=7, le=365, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
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
        supabase = db.client

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
            except Exception as e:
                logger.debug(f"Failed to parse adjustment time: {e}")

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
        logger.error(f"Failed to get user set adjustment patterns: {e}", exc_info=True)
        raise safe_internal_error(e, "set_adjustments")


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
        logger.error(f"Error validating workout: {e}", exc_info=True)
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
        logger.error(f"Error in fatigue analysis: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Error analyzing fatigue"
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
        logger.error(f"Error logging fatigue response: {e}", exc_info=True)
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
                except Exception as e:
                    logger.debug(f"Failed to parse fatigue timestamp: {e}")
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
        logger.error(f"Error getting fatigue history: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Error retrieving fatigue history"
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
