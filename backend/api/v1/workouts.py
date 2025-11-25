"""
Workout API endpoints for Gravl-like features.

ENDPOINTS:
- POST /api/v1/workouts/log - Log a completed workout with detailed metrics
- GET  /api/v1/workouts/{id}/recommendations - Get weight/rep recommendations
- POST /api/v1/workouts/adapt - Adapt a workout based on various factors
- GET  /api/v1/workouts/split - Get AI-optimized weekly split
"""
from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from models.performance import (
    LogWorkoutRequest, LogWorkoutResponse,
    GetRecommendationsRequest, GetRecommendationsResponse,
    AdaptationRequest, AdaptedWorkout,
    ProgressionRecommendation, ExercisePerformance,
    WorkoutPerformance, MuscleGroupVolume,
)
from services.progressive_overload_service import ProgressiveOverloadService
from services.adaptation_service import AdaptationService

router = APIRouter()

# Service instances (initialized on startup)
progressive_overload_service: Optional[ProgressiveOverloadService] = None
adaptation_service: Optional[AdaptationService] = None


def get_progressive_overload() -> ProgressiveOverloadService:
    """Dependency to get progressive overload service."""
    global progressive_overload_service
    if progressive_overload_service is None:
        progressive_overload_service = ProgressiveOverloadService()
    return progressive_overload_service


def get_adaptation_service() -> AdaptationService:
    """Dependency to get adaptation service."""
    global adaptation_service
    if adaptation_service is None:
        adaptation_service = AdaptationService()
    return adaptation_service


# ============ Log Workout ============

@router.post("/log", response_model=LogWorkoutResponse)
async def log_workout(
    request: LogWorkoutRequest,
    prog_service: ProgressiveOverloadService = Depends(get_progressive_overload),
):
    """
    Log a completed workout with detailed performance data.

    This endpoint:
    1. Records all set/rep/weight data
    2. Tracks RPE for each set
    3. Detects new PRs
    4. Generates recommendations for next workout

    Example request:
    ```json
    {
        "workout_id": 1,
        "user_id": 1,
        "started_at": "2024-01-15T09:00:00",
        "completed_at": "2024-01-15T10:15:00",
        "exercises": [
            {
                "exercise_id": "bench_press",
                "exercise_name": "Bench Press",
                "sets": [
                    {"set_number": 1, "reps_completed": 8, "weight_kg": 60, "rpe": 7},
                    {"set_number": 2, "reps_completed": 8, "weight_kg": 60, "rpe": 8},
                    {"set_number": 3, "reps_completed": 6, "weight_kg": 60, "rpe": 9}
                ],
                "target_sets": 3,
                "target_reps": 8
            }
        ],
        "session_rpe": 7.5,
        "notes": "Felt strong today"
    }
    ```
    """
    try:
        new_prs = []
        recommendations = []

        for exercise in request.exercises:
            # Record each exercise performance
            for set_data in exercise.sets:
                if set_data.completed and set_data.weight_kg > 0:
                    record, is_pr = prog_service.record_strength(
                        exercise_id=exercise.exercise_id,
                        exercise_name=exercise.exercise_name,
                        user_id=request.user_id,
                        weight=set_data.weight_kg,
                        reps=set_data.reps_completed,
                        rpe=set_data.rpe,
                    )
                    if is_pr:
                        new_prs.append(f"{exercise.exercise_name}: {set_data.weight_kg}kg x {set_data.reps_completed}")

            # Get history for recommendations
            history = prog_service.get_exercise_history(
                exercise_id=exercise.exercise_id,
                user_id=request.user_id,
                limit=5,
            )

            # Convert to ExercisePerformance list for recommendation
            perf_history = []  # Would come from DB in production

            recommendation = prog_service.get_recommendation(
                exercise_id=exercise.exercise_id,
                exercise_name=exercise.exercise_name,
                user_id=request.user_id,
                last_performance=exercise,
                performance_history=perf_history,
            )
            recommendations.append(recommendation)

        return LogWorkoutResponse(
            success=True,
            workout_log_id=request.workout_id,  # In production, generate new ID
            message=f"Workout logged successfully. {len(new_prs)} new PRs!",
            new_prs=new_prs,
            next_recommendations=recommendations,
        )

    except Exception as e:
        print(f"❌ Error logging workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Get Recommendations ============

class RecommendationQuery(BaseModel):
    """Query params for recommendations."""
    exercise_id: str
    exercise_name: str


@router.get("/{workout_id}/recommendations", response_model=GetRecommendationsResponse)
async def get_recommendations(
    workout_id: int,
    user_id: int,
    prog_service: ProgressiveOverloadService = Depends(get_progressive_overload),
):
    """
    Get weight/rep recommendations for a workout.

    Returns personalized recommendations for each exercise based on:
    - Past performance history
    - Current 1RM estimates
    - Fatigue/recovery status
    - Progression strategy

    Example response:
    ```json
    {
        "user_id": 1,
        "recommendations": [
            {
                "exercise_id": "bench_press",
                "exercise_name": "Bench Press",
                "current_weight_kg": 60,
                "current_reps": 8,
                "recommended_weight_kg": 62.5,
                "recommended_reps": 8,
                "recommended_sets": 3,
                "strategy": "linear",
                "reason": "Strong performance - ready for progression",
                "confidence": 0.85
            }
        ],
        "deload_suggested": false
    }
    ```
    """
    try:
        # In production, fetch workout from DB and get exercises
        # For now, return mock recommendations
        recommendations = []

        # Check if deload is needed
        # In production, fetch recent workout history
        recent_workouts: List[WorkoutPerformance] = []
        should_deload, deload_reason = prog_service.should_deload(user_id, recent_workouts)

        return GetRecommendationsResponse(
            user_id=user_id,
            recommendations=recommendations,
            deload_suggested=should_deload,
            deload_reason=deload_reason,
        )

    except Exception as e:
        print(f"❌ Error getting recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Adapt Workout ============

@router.post("/adapt", response_model=AdaptedWorkout)
async def adapt_workout(
    request: AdaptationRequest,
    adapt_service: AdaptationService = Depends(get_adaptation_service),
):
    """
    Adapt a workout based on various factors.

    Reasons for adaptation:
    - "missed_muscles": Compensate for muscle groups missed in previous workout
    - "recovery": Reduce volume based on fatigue level
    - "time_constraint": Shorten workout to fit available time
    - "progression": Apply progressive overload

    Example request:
    ```json
    {
        "user_id": 1,
        "workout_id": 5,
        "reason": "missed_muscles",
        "missed_muscle_groups": ["triceps", "shoulders"],
        "available_time_minutes": 45,
        "fatigue_level": 6
    }
    ```

    Example response:
    ```json
    {
        "original_workout_id": 5,
        "adapted_exercises": [...],
        "changes_made": [
            "Added Tricep Pushdown to compensate for missed triceps",
            "Added Lateral Raise to compensate for missed shoulders"
        ],
        "reasoning": "Adapted workout from 4 to 6 exercises...",
        "estimated_duration_minutes": 52
    }
    ```
    """
    try:
        # In production, fetch original workout from DB
        original_workout = {
            "id": request.workout_id,
            "name": "Upper Body",
            "exercises": [
                {"name": "Bench Press", "sets": 4, "reps": 8, "rest_seconds": 120},
                {"name": "Barbell Row", "sets": 4, "reps": 8, "rest_seconds": 120},
                {"name": "Overhead Press", "sets": 3, "reps": 10, "rest_seconds": 90},
                {"name": "Pull-ups", "sets": 3, "reps": 8, "rest_seconds": 90},
            ],
        }

        adapted = adapt_service.adapt_workout(
            request=request,
            original_workout=original_workout,
        )

        return adapted

    except Exception as e:
        print(f"❌ Error adapting workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Get Optimized Split ============

class SplitRequest(BaseModel):
    """Request for optimized weekly split."""
    user_id: int
    available_days: int = 4


class SplitDay(BaseModel):
    """Single day in the split."""
    day: int
    focus: List[str]
    exercises: List[dict]


class SplitResponse(BaseModel):
    """Response with optimized split."""
    user_id: int
    available_days: int
    split: List[SplitDay]
    reasoning: str


@router.post("/split", response_model=SplitResponse)
async def get_optimized_split(
    request: SplitRequest,
    adapt_service: AdaptationService = Depends(get_adaptation_service),
    prog_service: ProgressiveOverloadService = Depends(get_progressive_overload),
):
    """
    Get an AI-optimized weekly training split.

    Unlike traditional "leg day" / "push day" splits, this creates
    an intelligent split based on:
    - Which muscle groups need more volume
    - Recovery status of each muscle group
    - Training frequency requirements

    Example response:
    ```json
    {
        "user_id": 1,
        "available_days": 4,
        "split": [
            {
                "day": 1,
                "focus": ["chest", "back"],
                "exercises": [...]
            },
            ...
        ],
        "reasoning": "Split optimized based on current muscle group recovery..."
    }
    ```
    """
    try:
        # In production, calculate actual muscle volumes from workout history
        mock_volumes = [
            MuscleGroupVolume(
                muscle_group="chest", total_sets=8, total_reps=64,
                total_volume_kg=3840, frequency=1, target_sets=14,
                recovery_status="undertrained"
            ),
            MuscleGroupVolume(
                muscle_group="back", total_sets=12, total_reps=96,
                total_volume_kg=4800, frequency=2, target_sets=14,
                recovery_status="recovered"
            ),
            MuscleGroupVolume(
                muscle_group="shoulders", total_sets=6, total_reps=60,
                total_volume_kg=1800, frequency=1, target_sets=12,
                recovery_status="undertrained"
            ),
            MuscleGroupVolume(
                muscle_group="biceps", total_sets=10, total_reps=100,
                total_volume_kg=1500, frequency=2, target_sets=10,
                recovery_status="recovered"
            ),
            MuscleGroupVolume(
                muscle_group="triceps", total_sets=4, total_reps=40,
                total_volume_kg=800, frequency=1, target_sets=10,
                recovery_status="undertrained"
            ),
        ]

        split_plan = adapt_service.optimize_weekly_split(
            user_id=request.user_id,
            muscle_volumes=mock_volumes,
            available_days=request.available_days,
        )

        split_days = []
        for day_plan in split_plan:
            exercises = []
            for ep in day_plan.get("exercise_plan", []):
                for ex in ep.get("exercises", []):
                    exercises.append({
                        "name": ex.title(),
                        "muscle_group": ep["muscle_group"],
                        "sets": 3,
                        "reps": 10,
                    })

            split_days.append(SplitDay(
                day=day_plan["day"],
                focus=day_plan["focus"],
                exercises=exercises,
            ))

        return SplitResponse(
            user_id=request.user_id,
            available_days=request.available_days,
            split=split_days,
            reasoning="Split optimized based on current muscle group recovery status. "
                      "Prioritizing undertrained muscles (chest, shoulders, triceps) "
                      "while maintaining recovered muscles.",
        )

    except Exception as e:
        print(f"❌ Error generating split: {e}")
        raise HTTPException(status_code=500, detail=str(e))
