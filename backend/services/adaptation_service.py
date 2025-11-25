"""
Adaptation Service - Facade for workout adaptation functionality.

This is a thin facade that delegates to specialized services:
- WorkoutAdaptationService: Adapts workouts for various factors
- SplitOptimizationService: Optimizes weekly training splits

USAGE:
    service = AdaptationService()
    adapted = service.adapt_workout(request, original_workout)
"""
from typing import List, Dict, Any, Optional
from models.performance import (
    AdaptationRequest, AdaptedWorkout, WorkoutPerformance, MuscleGroupVolume
)
from services.workout_adaptation_service import WorkoutAdaptationService
from services.split_optimization_service import SplitOptimizationService


class AdaptationService:
    """
    Facade for workout adaptation functionality.

    Delegates to specialized services for modularity.
    """

    def __init__(self):
        self._workout = WorkoutAdaptationService()
        self._split = SplitOptimizationService()

    def adapt_workout(
        self,
        request: AdaptationRequest,
        original_workout: Dict[str, Any],
        performance_history: Optional[List[WorkoutPerformance]] = None,
        muscle_volumes: Optional[List[MuscleGroupVolume]] = None,
    ) -> AdaptedWorkout:
        """Main entry point for workout adaptation."""
        adapted_exercises = original_workout.get("exercises", []).copy()
        changes_made = []

        # Handle different adaptation reasons
        if request.reason == "missed_muscles" and request.missed_muscle_groups:
            adapted_exercises, new_changes = self._workout.adapt_for_missed_muscles(
                exercises=adapted_exercises,
                missed_muscles=request.missed_muscle_groups,
                available_time=request.available_time_minutes,
            )
            changes_made.extend(new_changes)

        elif request.reason == "recovery" and request.fatigue_level:
            adapted_exercises, new_changes = self._workout.adapt_for_recovery(
                exercises=adapted_exercises,
                fatigue_level=request.fatigue_level,
            )
            changes_made.extend(new_changes)

        elif request.reason == "time_constraint" and request.available_time_minutes:
            adapted_exercises, new_changes = self._workout.adapt_for_time(
                exercises=adapted_exercises,
                available_time=request.available_time_minutes,
            )
            changes_made.extend(new_changes)

        # Handle injuries if present
        if request.injuries:
            adapted_exercises, injury_changes = self._workout.adapt_for_injuries(
                exercises=adapted_exercises,
                injuries=request.injuries,
            )
            changes_made.extend(injury_changes)

        # Calculate estimated duration
        estimated_duration = self._workout._estimate_workout_duration(adapted_exercises)

        # Build reasoning
        reasoning = self._build_adaptation_reasoning(
            original_count=len(original_workout.get("exercises", [])),
            adapted_count=len(adapted_exercises),
            changes=changes_made,
        )

        return AdaptedWorkout(
            original_workout_id=request.workout_id,
            adapted_exercises=adapted_exercises,
            changes_made=changes_made,
            reasoning=reasoning,
            estimated_duration_minutes=estimated_duration,
        )

    def optimize_weekly_split(
        self,
        user_id: int,
        muscle_volumes: List[MuscleGroupVolume],
        available_days: int = 4,
    ) -> List[Dict[str, Any]]:
        """Create an AI-optimized weekly split."""
        return self._split.optimize_weekly_split(user_id, muscle_volumes, available_days)

    def _build_adaptation_reasoning(
        self,
        original_count: int,
        adapted_count: int,
        changes: List[str],
    ) -> str:
        """Build human-readable reasoning for the adaptation."""
        parts = [f"Adapted workout from {original_count} to {adapted_count} exercises."]

        if changes:
            parts.append("Changes made:")
            for i, change in enumerate(changes, 1):
                parts.append(f"  {i}. {change}")
        else:
            parts.append("No changes were necessary.")

        return "\n".join(parts)
