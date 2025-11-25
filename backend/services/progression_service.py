"""
Progression Service - Weight/rep recommendation logic.

Handles:
- Generating progression recommendations
- Deload detection
- Strategy selection (linear, wave, double progression)
"""
from typing import List, Optional, Tuple
from models.performance import (
    ExercisePerformance, WorkoutPerformance,
    ProgressionRecommendation, ProgressionStrategy
)
from core import PROGRESSION_INCREMENTS, get_exercise_type

# RPE thresholds for progression decisions
RPE_THRESHOLDS = {
    "ready_to_progress": 7.5,
    "maintain": 8.5,
    "deload": 9.5,
}


class ProgressionService:
    """Generates weight/rep progression recommendations."""

    def get_recommendation(
        self,
        exercise_id: str,
        exercise_name: str,
        last_performance: Optional[ExercisePerformance],
        performance_history: List[ExercisePerformance],
    ) -> ProgressionRecommendation:
        """Generate a progression recommendation for an exercise."""
        if not last_performance:
            return self._get_initial_recommendation(exercise_id, exercise_name)

        avg_rpe = self._calculate_average_rpe(performance_history[-3:])
        is_plateau = self._detect_plateau(performance_history)

        # Determine strategy
        if is_plateau:
            strategy = ProgressionStrategy.WAVE
            reason = "Plateau detected - introducing wave loading"
        elif avg_rpe and avg_rpe > RPE_THRESHOLDS["deload"]:
            strategy = ProgressionStrategy.DELOAD
            reason = "High fatigue detected - recommending deload"
        elif avg_rpe and avg_rpe <= RPE_THRESHOLDS["ready_to_progress"]:
            strategy = ProgressionStrategy.LINEAR
            reason = "Strong performance - ready for progression"
        else:
            strategy = ProgressionStrategy.DOUBLE_PROGRESSION
            reason = "Building consistency before weight increase"

        return self._calculate_progression(
            exercise_id, exercise_name, last_performance, strategy, reason
        )

    def _get_initial_recommendation(
        self,
        exercise_id: str,
        exercise_name: str,
    ) -> ProgressionRecommendation:
        """Get recommendation for first-time exercise."""
        return ProgressionRecommendation(
            exercise_id=exercise_id,
            exercise_name=exercise_name,
            current_weight_kg=0,
            current_reps=0,
            recommended_weight_kg=20.0,
            recommended_reps=10,
            recommended_sets=3,
            strategy=ProgressionStrategy.LINEAR,
            reason="First time - start light to learn form",
            confidence=0.5,
        )

    def _calculate_progression(
        self,
        exercise_id: str,
        exercise_name: str,
        last_performance: ExercisePerformance,
        strategy: ProgressionStrategy,
        reason: str,
    ) -> ProgressionRecommendation:
        """Calculate specific weight/rep recommendations."""
        exercise_type = get_exercise_type(exercise_name)
        increment = PROGRESSION_INCREMENTS.get(exercise_type, 2.5)

        last_weight = max(s.weight_kg for s in last_performance.sets if s.completed)
        last_reps = last_performance.target_reps
        last_sets = last_performance.target_sets

        if strategy == ProgressionStrategy.LINEAR:
            new_weight = last_weight + increment
            new_reps = last_reps
            new_sets = last_sets
            confidence = 0.85

        elif strategy == ProgressionStrategy.DOUBLE_PROGRESSION:
            if self._hit_rep_target(last_performance):
                new_weight = last_weight + increment
                new_reps = last_reps - 2
                new_sets = last_sets
                confidence = 0.80
            else:
                new_weight = last_weight
                new_reps = last_reps + 1
                new_sets = last_sets
                confidence = 0.75

        elif strategy == ProgressionStrategy.WAVE:
            new_weight = last_weight * 0.9
            new_reps = last_reps + 2
            new_sets = last_sets
            confidence = 0.70

        elif strategy == ProgressionStrategy.DELOAD:
            new_weight = last_weight * 0.6
            new_reps = last_reps
            new_sets = max(2, last_sets - 1)
            confidence = 0.90

        else:
            new_weight = last_weight
            new_reps = last_reps
            new_sets = last_sets
            confidence = 0.60

        return ProgressionRecommendation(
            exercise_id=exercise_id,
            exercise_name=exercise_name,
            current_weight_kg=last_weight,
            current_reps=last_reps,
            recommended_weight_kg=round(new_weight, 1),
            recommended_reps=new_reps,
            recommended_sets=new_sets,
            strategy=strategy,
            reason=reason,
            confidence=confidence,
        )

    def _calculate_average_rpe(
        self, performances: List[ExercisePerformance]
    ) -> Optional[float]:
        """Calculate average RPE across recent performances."""
        rpes = [p.average_rpe for p in performances if p.average_rpe is not None]
        return sum(rpes) / len(rpes) if rpes else None

    def _detect_plateau(self, history: List[ExercisePerformance]) -> bool:
        """Detect if user is plateauing on an exercise."""
        if len(history) < 4:
            return False

        recent_1rms = [p.estimated_1rm for p in history[-4:] if p.estimated_1rm]
        if len(recent_1rms) < 3:
            return False

        max_1rm = max(recent_1rms)
        min_1rm = min(recent_1rms)
        variance = (max_1rm - min_1rm) / max_1rm if max_1rm > 0 else 0
        return variance < 0.03

    def _hit_rep_target(self, performance: ExercisePerformance) -> bool:
        """Check if user hit their rep target on all sets."""
        return all(
            s.reps_completed >= performance.target_reps
            for s in performance.sets if s.completed
        )

    def should_deload(
        self,
        recent_workouts: List[WorkoutPerformance],
    ) -> Tuple[bool, Optional[str]]:
        """Determine if user should take a deload week."""
        if len(recent_workouts) < 4:
            return False, None

        # Check for high RPE
        high_rpe_count = sum(
            1 for w in recent_workouts[-4:]
            if w.session_rpe and w.session_rpe > RPE_THRESHOLDS["deload"]
        )
        if high_rpe_count >= 2:
            return True, "Consistently high session RPE - recovery needed"

        # Check for declining performance
        volumes = [w.total_volume for w in recent_workouts[-4:]]
        if volumes[-1] < volumes[0] * 0.85:
            return True, "Volume declining - possible overtraining"

        # Check for low completion rates
        low_completion = sum(
            1 for w in recent_workouts[-4:]
            if w.completion_rate < 80
        )
        if low_completion >= 2:
            return True, "Low workout completion - fatigue accumulation"

        return False, None
