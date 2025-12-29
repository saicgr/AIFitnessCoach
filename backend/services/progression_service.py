"""
Progression Service - Weight/rep recommendation logic.

Handles:
- Generating progression recommendations
- Deload detection
- Strategy selection (linear, wave, double progression)
- Equipment-aware weight recommendations (industry standard increments)
"""
from typing import List, Optional, Tuple
from models.performance import (
    ExercisePerformance, WorkoutPerformance,
    ProgressionRecommendation, ProgressionStrategy
)
from core import (
    PROGRESSION_INCREMENTS,
    get_exercise_type,
    get_rep_limits,
    get_equipment_increment,
    round_to_equipment_increment,
    snap_to_available_weights,
    detect_equipment_type,
    get_starting_weight,
)

# RPE thresholds for progression decisions
RPE_THRESHOLDS = {
    "ready_to_progress": 7.5,
    "maintain": 8.5,
    "deload": 9.5,
}

# Progression pace thresholds - how many consecutive "ready" sessions before weight increase
# Addresses competitor feedback: "going up 10 or 15 pounds every week is not what I want"
PROGRESSION_PACE_THRESHOLDS = {
    "slow": 4,    # Require 4 consecutive "ready" sessions (~3-4 weeks)
    "medium": 2,  # Require 2 consecutive "ready" sessions (~1-2 weeks)
    "fast": 1,    # Progress immediately when ready (every session)
}


class ProgressionService:
    """Generates weight/rep progression recommendations."""

    def get_recommendation(
        self,
        exercise_id: str,
        exercise_name: str,
        last_performance: Optional[ExercisePerformance],
        performance_history: List[ExercisePerformance],
        progression_pace: str = "medium",
    ) -> ProgressionRecommendation:
        """
        Generate a progression recommendation for an exercise.

        Args:
            exercise_id: Unique exercise identifier
            exercise_name: Name of the exercise
            last_performance: Most recent performance data
            performance_history: List of previous performances
            progression_pace: User's preferred pace - "slow", "medium", or "fast"
                - slow: 3-4 weeks same weight before increase
                - medium: 1-2 weeks same weight before increase
                - fast: increase every session when ready

        Returns:
            ProgressionRecommendation with weight/rep suggestions
        """
        if not last_performance:
            return self._get_initial_recommendation(exercise_id, exercise_name)

        avg_rpe = self._calculate_average_rpe(performance_history[-3:])
        is_plateau = self._detect_plateau(performance_history)

        # Count consecutive "ready to progress" sessions for pace-aware logic
        consecutive_ready = self._count_consecutive_ready_sessions(performance_history)
        pace_threshold = PROGRESSION_PACE_THRESHOLDS.get(progression_pace, 2)

        # Determine strategy
        if is_plateau:
            strategy = ProgressionStrategy.WAVE
            reason = "Plateau detected - introducing wave loading"
        elif avg_rpe and avg_rpe > RPE_THRESHOLDS["deload"]:
            strategy = ProgressionStrategy.DELOAD
            reason = "High fatigue detected - recommending deload"
        elif avg_rpe and avg_rpe <= RPE_THRESHOLDS["ready_to_progress"]:
            # Check if user meets pace threshold for progression
            if consecutive_ready >= pace_threshold:
                strategy = ProgressionStrategy.LINEAR
                reason = f"Strong performance for {consecutive_ready} sessions - ready for progression"
            else:
                # User is ready but hasn't met pace threshold yet
                strategy = ProgressionStrategy.DOUBLE_PROGRESSION
                sessions_needed = pace_threshold - consecutive_ready
                reason = f"Building consistency ({consecutive_ready}/{pace_threshold} sessions before weight increase)"
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
        equipment_type: Optional[str] = None,
        fitness_level: str = "beginner",
    ) -> ProgressionRecommendation:
        """
        Get recommendation for first-time exercise.

        Uses equipment-aware starting weights instead of hardcoded values.
        For example:
        - Beginner + Dumbbell Bench Press = 10 kg
        - Intermediate + Barbell Squat = 20 kg
        - Advanced + Machine Chest Press = 50 kg

        Args:
            exercise_id: Unique exercise identifier
            exercise_name: Name of the exercise
            equipment_type: Equipment type (detected from name if not provided)
            fitness_level: User's fitness level

        Returns:
            ProgressionRecommendation with appropriate starting weight
        """
        # Detect equipment if not provided
        if not equipment_type:
            equipment_type = detect_equipment_type(exercise_name)

        # Get smart starting weight based on exercise, equipment, and fitness level
        starting_weight = get_starting_weight(
            exercise_name=exercise_name,
            equipment_type=equipment_type,
            fitness_level=fitness_level,
        )

        # Adjust reps based on fitness level
        if fitness_level == "beginner":
            reps = 10
            sets = 2
        elif fitness_level == "advanced":
            reps = 8
            sets = 4
        else:  # intermediate
            reps = 10
            sets = 3

        return ProgressionRecommendation(
            exercise_id=exercise_id,
            exercise_name=exercise_name,
            current_weight_kg=0,
            current_reps=0,
            recommended_weight_kg=starting_weight,
            recommended_reps=reps,
            recommended_sets=sets,
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
        equipment_type: Optional[str] = None,
    ) -> ProgressionRecommendation:
        """
        Calculate specific weight/rep recommendations using equipment-aware increments.

        Uses realistic weight increments based on equipment type:
        - Dumbbells: 2.5 kg (5 lb) minimum jumps
        - Barbells: 2.5 kg (5 lb)
        - Machines: 5.0 kg (10 lb)
        - Kettlebells: 4.0 kg (8 lb)

        Args:
            exercise_id: Unique exercise identifier
            exercise_name: Name of the exercise
            last_performance: Previous performance data
            strategy: Progression strategy to use
            reason: Reason for the recommendation
            equipment_type: Equipment type (detected from name if not provided)

        Returns:
            ProgressionRecommendation with valid weight increments
        """
        # Detect equipment type if not provided
        if not equipment_type:
            equipment_type = detect_equipment_type(exercise_name)

        # Get equipment-aware increment (instead of exercise-type based)
        increment = get_equipment_increment(equipment_type)

        last_weight = max(s.weight_kg for s in last_performance.sets if s.completed)
        last_reps = last_performance.target_reps
        last_sets = last_performance.target_sets

        if strategy == ProgressionStrategy.LINEAR:
            new_weight = last_weight + increment
            new_reps = last_reps
            new_sets = last_sets
            confidence = 0.85

        elif strategy == ProgressionStrategy.DOUBLE_PROGRESSION:
            # Get exercise-specific rep limits to prevent rep creep
            exercise_type = get_exercise_type(exercise_name)
            min_reps, max_reps = get_rep_limits(exercise_type)

            # Check if user hit the rep ceiling
            if last_reps >= max_reps:
                # At ceiling - FORCE weight increase to prevent 20+ rep sets
                new_weight = last_weight + increment
                new_reps = min_reps + 2  # Reset to comfortable range (e.g., 8 for compounds)
                new_sets = last_sets
                confidence = 0.85
                reason = f"Hit {max_reps} rep ceiling - time to increase weight!"
            elif self._hit_rep_target(last_performance):
                # Hit rep target - normal progression
                new_weight = last_weight + increment
                new_reps = max(min_reps, last_reps - 2)  # Ensure we don't go below min
                new_sets = last_sets
                confidence = 0.80
            else:
                # Still building - increase reps but cap at max
                new_weight = last_weight
                new_reps = min(last_reps + 1, max_reps)  # CAP AT CEILING
                new_sets = last_sets
                confidence = 0.75

        elif strategy == ProgressionStrategy.WAVE:
            # Get exercise-specific rep limits
            exercise_type = get_exercise_type(exercise_name)
            min_reps, max_reps = get_rep_limits(exercise_type)

            new_weight = last_weight * 0.9
            # Cap wave loading reps at the ceiling
            new_reps = min(last_reps + 2, max_reps)
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

        # Snap to valid equipment weights (e.g., standard dumbbell increments)
        final_weight = snap_to_available_weights(new_weight, equipment_type)

        return ProgressionRecommendation(
            exercise_id=exercise_id,
            exercise_name=exercise_name,
            current_weight_kg=last_weight,
            current_reps=last_reps,
            recommended_weight_kg=final_weight,
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

    def _count_consecutive_ready_sessions(
        self, history: List[ExercisePerformance]
    ) -> int:
        """
        Count consecutive sessions where user was "ready to progress" (RPE <= 7.5).

        This enables pace-aware progression:
        - slow pace: requires 4 consecutive ready sessions
        - medium pace: requires 2 consecutive ready sessions
        - fast pace: requires 1 session (immediate)

        Args:
            history: List of performance history (most recent last)

        Returns:
            Number of consecutive sessions at or below ready_to_progress threshold
        """
        if not history:
            return 0

        consecutive = 0
        threshold = RPE_THRESHOLDS["ready_to_progress"]

        # Iterate from most recent to oldest
        for perf in reversed(history):
            if perf.average_rpe is not None and perf.average_rpe <= threshold:
                consecutive += 1
            else:
                # Break on first non-ready session
                break

        return consecutive

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
