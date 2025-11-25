"""
Progressive Overload Service - Facade for all progressive overload functionality.

This is a thin facade that delegates to specialized services:
- StrengthTrackingService: 1RM tracking and PR detection
- VolumeTrackingService: Weekly volume per muscle group
- ProgressionService: Weight/rep recommendations

USAGE:
    service = ProgressiveOverloadService()
    recommendation = service.get_recommendation(exercise_id, user_id, history)
"""
from typing import List, Optional, Tuple
from models.performance import (
    ExercisePerformance, WorkoutPerformance,
    StrengthRecord, ProgressionRecommendation, MuscleGroupVolume
)
from services.strength_tracking_service import StrengthTrackingService
from services.volume_tracking_service import VolumeTrackingService
from services.progression_service import ProgressionService


class ProgressiveOverloadService:
    """
    Facade for progressive overload functionality.

    Delegates to specialized services for modularity.
    """

    def __init__(self):
        self._strength = StrengthTrackingService()
        self._volume = VolumeTrackingService()
        self._progression = ProgressionService()

    # ============ Recommendations ============

    def get_recommendation(
        self,
        exercise_id: str,
        exercise_name: str,
        user_id: int,
        last_performance: Optional[ExercisePerformance],
        performance_history: List[ExercisePerformance],
    ) -> ProgressionRecommendation:
        """Generate a progression recommendation for an exercise."""
        return self._progression.get_recommendation(
            exercise_id, exercise_name, last_performance, performance_history
        )

    # ============ Strength Tracking ============

    def record_strength(
        self,
        exercise_id: str,
        exercise_name: str,
        user_id: int,
        weight: float,
        reps: int,
        rpe: Optional[float] = None,
    ) -> Tuple[StrengthRecord, bool]:
        """Record a strength performance and check for PR."""
        return self._strength.record_strength(
            exercise_id, exercise_name, user_id, weight, reps, rpe
        )

    def get_exercise_history(
        self,
        exercise_id: str,
        user_id: int,
        limit: int = 10,
    ) -> List[StrengthRecord]:
        """Get strength history for an exercise."""
        return self._strength.get_exercise_history(exercise_id, user_id, limit)

    def get_current_1rm(
        self,
        exercise_id: str,
        user_id: int,
    ) -> Optional[float]:
        """Get the best estimated 1RM for an exercise."""
        return self._strength.get_current_1rm(exercise_id, user_id)

    # ============ Volume Tracking ============

    def calculate_weekly_volume(
        self,
        user_id: int,
        workouts: List[WorkoutPerformance],
    ) -> List[MuscleGroupVolume]:
        """Calculate weekly volume per muscle group."""
        return self._volume.calculate_weekly_volume(workouts)

    # ============ Deload Detection ============

    def should_deload(
        self,
        user_id: int,
        recent_workouts: List[WorkoutPerformance],
    ) -> Tuple[bool, Optional[str]]:
        """Determine if user should take a deload week."""
        return self._progression.should_deload(recent_workouts)
