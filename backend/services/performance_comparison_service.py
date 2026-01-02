"""
Performance Comparison Service - Track and compare workout performance over time.

Addresses user review: "It used to show the reductions or increases in time,
both for each exercise and the workout."

This service provides:
- Exercise-by-exercise performance comparison with previous sessions
- Overall workout comparison with previous similar workouts
- Improvement/setback detection and display
- Time-based metrics for timed exercises
"""
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from decimal import Decimal
import logging

from services.strength_calculator_service import StrengthCalculatorService

logger = logging.getLogger(__name__)


@dataclass
class ExerciseComparison:
    """Comparison data for a single exercise vs previous session."""
    exercise_name: str
    exercise_id: Optional[str] = None

    # Current session
    current_sets: int = 0
    current_reps: int = 0
    current_volume_kg: float = 0.0
    current_max_weight_kg: Optional[float] = None
    current_1rm_kg: Optional[float] = None
    current_time_seconds: Optional[int] = None
    current_avg_rpe: Optional[float] = None

    # Previous session
    previous_sets: Optional[int] = None
    previous_reps: Optional[int] = None
    previous_volume_kg: Optional[float] = None
    previous_max_weight_kg: Optional[float] = None
    previous_1rm_kg: Optional[float] = None
    previous_time_seconds: Optional[int] = None
    previous_date: Optional[datetime] = None

    # Differences
    volume_diff_kg: Optional[float] = None
    volume_diff_percent: Optional[float] = None
    weight_diff_kg: Optional[float] = None
    weight_diff_percent: Optional[float] = None
    rm_diff_kg: Optional[float] = None
    rm_diff_percent: Optional[float] = None
    time_diff_seconds: Optional[int] = None
    time_diff_percent: Optional[float] = None
    reps_diff: Optional[int] = None
    sets_diff: Optional[int] = None

    # Status: 'improved', 'maintained', 'declined', 'first_time'
    status: str = 'first_time'

    # Is this a new PR?
    is_pr: bool = False


@dataclass
class WorkoutComparison:
    """Comparison data for overall workout vs previous similar workout."""
    # Current workout
    current_duration_seconds: int = 0
    current_total_volume_kg: float = 0.0
    current_total_sets: int = 0
    current_total_reps: int = 0
    current_exercises: int = 0
    current_calories: int = 0
    current_new_prs: int = 0
    current_performed_at: Optional[datetime] = None

    # Previous workout
    has_previous: bool = False
    previous_workout_log_id: Optional[str] = None
    previous_duration_seconds: Optional[int] = None
    previous_total_volume_kg: Optional[float] = None
    previous_total_sets: Optional[int] = None
    previous_total_reps: Optional[int] = None
    previous_exercises: Optional[int] = None
    previous_calories: Optional[int] = None
    previous_performed_at: Optional[datetime] = None

    # Differences
    duration_diff_seconds: Optional[int] = None
    duration_diff_percent: Optional[float] = None
    volume_diff_kg: Optional[float] = None
    volume_diff_percent: Optional[float] = None
    sets_diff: Optional[int] = None
    reps_diff: Optional[int] = None
    calories_diff: Optional[int] = None

    # Overall status
    overall_status: str = 'first_time'  # 'improved', 'maintained', 'declined', 'first_time'


@dataclass
class PerformanceComparisonResult:
    """Complete performance comparison result for a workout."""
    workout_comparison: WorkoutComparison
    exercise_comparisons: List[ExerciseComparison]

    # Summary counts
    improved_count: int = 0
    maintained_count: int = 0
    declined_count: int = 0
    first_time_count: int = 0

    # Highlights
    best_improvement: Optional[ExerciseComparison] = None
    biggest_decline: Optional[ExerciseComparison] = None


class PerformanceComparisonService:
    """
    Service for comparing workout performance over time.

    Provides detailed comparison data showing:
    - Weight progression (improvements and setbacks)
    - Time-based improvements (for timed exercises)
    - Volume changes
    - Rep and set changes
    """

    def __init__(self):
        self.strength_calculator = StrengthCalculatorService()

    def compute_exercise_comparison(
        self,
        exercise_name: str,
        current_performance: Dict,
        previous_performances: List[Dict],
    ) -> ExerciseComparison:
        """
        Compare current exercise performance with previous session.

        Args:
            exercise_name: Name of the exercise
            current_performance: Current session stats
            previous_performances: List of previous sessions (most recent first)

        Returns:
            ExerciseComparison with detailed comparison data
        """
        comparison = ExerciseComparison(
            exercise_name=exercise_name,
            exercise_id=current_performance.get('exercise_id'),
            current_sets=current_performance.get('total_sets', 0),
            current_reps=current_performance.get('total_reps', 0),
            current_volume_kg=float(current_performance.get('total_volume_kg', 0)),
            current_max_weight_kg=self._to_float(current_performance.get('max_weight_kg')),
            current_1rm_kg=self._to_float(current_performance.get('estimated_1rm_kg')),
            current_time_seconds=current_performance.get('total_time_seconds'),
            current_avg_rpe=self._to_float(current_performance.get('avg_rpe')),
        )

        # Get most recent previous performance
        if not previous_performances:
            comparison.status = 'first_time'
            return comparison

        prev = previous_performances[0]
        comparison.previous_sets = prev.get('total_sets')
        comparison.previous_reps = prev.get('total_reps')
        comparison.previous_volume_kg = self._to_float(prev.get('total_volume_kg'))
        comparison.previous_max_weight_kg = self._to_float(prev.get('max_weight_kg'))
        comparison.previous_1rm_kg = self._to_float(prev.get('estimated_1rm_kg'))
        comparison.previous_time_seconds = prev.get('total_time_seconds')
        comparison.previous_date = prev.get('performed_at')

        # Calculate differences
        if comparison.previous_volume_kg is not None:
            comparison.volume_diff_kg = round(comparison.current_volume_kg - comparison.previous_volume_kg, 2)
            if comparison.previous_volume_kg > 0:
                comparison.volume_diff_percent = round(
                    (comparison.volume_diff_kg / comparison.previous_volume_kg) * 100, 1
                )

        if comparison.current_max_weight_kg and comparison.previous_max_weight_kg:
            comparison.weight_diff_kg = round(
                comparison.current_max_weight_kg - comparison.previous_max_weight_kg, 2
            )
            if comparison.previous_max_weight_kg > 0:
                comparison.weight_diff_percent = round(
                    (comparison.weight_diff_kg / comparison.previous_max_weight_kg) * 100, 1
                )

        if comparison.current_1rm_kg and comparison.previous_1rm_kg:
            comparison.rm_diff_kg = round(comparison.current_1rm_kg - comparison.previous_1rm_kg, 2)
            if comparison.previous_1rm_kg > 0:
                comparison.rm_diff_percent = round(
                    (comparison.rm_diff_kg / comparison.previous_1rm_kg) * 100, 1
                )

        if comparison.current_time_seconds and comparison.previous_time_seconds:
            comparison.time_diff_seconds = comparison.current_time_seconds - comparison.previous_time_seconds
            if comparison.previous_time_seconds > 0:
                comparison.time_diff_percent = round(
                    (comparison.time_diff_seconds / comparison.previous_time_seconds) * 100, 1
                )

        if comparison.previous_reps is not None:
            comparison.reps_diff = comparison.current_reps - comparison.previous_reps

        if comparison.previous_sets is not None:
            comparison.sets_diff = comparison.current_sets - comparison.previous_sets

        # Determine status
        comparison.status = self._determine_status(comparison)

        return comparison

    def _determine_status(self, comparison: ExerciseComparison) -> str:
        """
        Determine if exercise performance improved, declined, or maintained.

        Uses the following priority:
        1. 1RM comparison (for strength exercises)
        2. Time comparison (for timed exercises - longer is usually better)
        3. Volume comparison (fallback)
        """
        # Thresholds for determining change
        improvement_threshold = 1.0  # 1% improvement
        decline_threshold = -1.0  # 1% decline

        # Check 1RM first (primary metric for strength)
        if comparison.rm_diff_percent is not None:
            if comparison.rm_diff_percent >= improvement_threshold:
                return 'improved'
            elif comparison.rm_diff_percent <= decline_threshold:
                return 'declined'
            else:
                return 'maintained'

        # Check time (for timed exercises like planks, longer = better)
        if comparison.time_diff_percent is not None:
            if comparison.time_diff_percent >= 5.0:  # 5% improvement
                return 'improved'
            elif comparison.time_diff_percent <= -5.0:  # 5% decline
                return 'declined'
            else:
                return 'maintained'

        # Fallback to volume
        if comparison.volume_diff_percent is not None:
            if comparison.volume_diff_percent >= improvement_threshold:
                return 'improved'
            elif comparison.volume_diff_percent <= decline_threshold:
                return 'declined'
            else:
                return 'maintained'

        return 'maintained'

    def compute_workout_comparison(
        self,
        current_stats: Dict,
        previous_stats: Optional[Dict] = None,
    ) -> WorkoutComparison:
        """
        Compare current workout with previous similar workout.

        Args:
            current_stats: Current workout statistics
            previous_stats: Previous similar workout statistics (if any)

        Returns:
            WorkoutComparison with detailed comparison data
        """
        comparison = WorkoutComparison(
            current_duration_seconds=current_stats.get('duration_seconds', 0),
            current_total_volume_kg=float(current_stats.get('total_volume_kg', 0)),
            current_total_sets=current_stats.get('total_sets', 0),
            current_total_reps=current_stats.get('total_reps', 0),
            current_exercises=current_stats.get('total_exercises', 0),
            current_calories=current_stats.get('estimated_calories', 0),
            current_new_prs=current_stats.get('new_prs_count', 0),
            current_performed_at=current_stats.get('performed_at'),
        )

        if not previous_stats:
            comparison.overall_status = 'first_time'
            return comparison

        comparison.has_previous = True
        comparison.previous_workout_log_id = previous_stats.get('workout_log_id')
        comparison.previous_duration_seconds = previous_stats.get('duration_seconds')
        comparison.previous_total_volume_kg = self._to_float(previous_stats.get('total_volume_kg'))
        comparison.previous_total_sets = previous_stats.get('total_sets')
        comparison.previous_total_reps = previous_stats.get('total_reps')
        comparison.previous_exercises = previous_stats.get('total_exercises')
        comparison.previous_calories = previous_stats.get('estimated_calories')
        comparison.previous_performed_at = previous_stats.get('performed_at')

        # Calculate differences
        if comparison.previous_duration_seconds:
            comparison.duration_diff_seconds = (
                comparison.current_duration_seconds - comparison.previous_duration_seconds
            )
            if comparison.previous_duration_seconds > 0:
                comparison.duration_diff_percent = round(
                    (comparison.duration_diff_seconds / comparison.previous_duration_seconds) * 100, 1
                )

        if comparison.previous_total_volume_kg:
            comparison.volume_diff_kg = round(
                comparison.current_total_volume_kg - comparison.previous_total_volume_kg, 2
            )
            if comparison.previous_total_volume_kg > 0:
                comparison.volume_diff_percent = round(
                    (comparison.volume_diff_kg / comparison.previous_total_volume_kg) * 100, 1
                )

        if comparison.previous_total_sets is not None:
            comparison.sets_diff = comparison.current_total_sets - comparison.previous_total_sets

        if comparison.previous_total_reps is not None:
            comparison.reps_diff = comparison.current_total_reps - comparison.previous_total_reps

        if comparison.previous_calories is not None:
            comparison.calories_diff = comparison.current_calories - comparison.previous_calories

        # Determine overall status based on volume (primary metric)
        if comparison.volume_diff_percent is not None:
            if comparison.volume_diff_percent >= 2.0:
                comparison.overall_status = 'improved'
            elif comparison.volume_diff_percent <= -2.0:
                comparison.overall_status = 'declined'
            else:
                comparison.overall_status = 'maintained'
        else:
            comparison.overall_status = 'first_time'

        return comparison

    def build_performance_summary(
        self,
        workout_log_id: str,
        user_id: str,
        workout_id: Optional[str],
        exercises_performance: List[Dict],
        workout_stats: Dict,
    ) -> Tuple[Dict, List[Dict]]:
        """
        Build performance summary records for storage.

        Args:
            workout_log_id: ID of the workout log
            user_id: ID of the user
            workout_id: ID of the workout template
            exercises_performance: List of exercise performance data
            workout_stats: Overall workout statistics

        Returns:
            Tuple of (workout_summary_dict, list_of_exercise_summary_dicts)
        """
        # Build workout summary
        workout_summary = {
            'user_id': user_id,
            'workout_log_id': workout_log_id,
            'workout_id': workout_id,
            'workout_name': workout_stats.get('workout_name'),
            'workout_type': workout_stats.get('workout_type'),
            'total_exercises': len(exercises_performance),
            'total_sets': workout_stats.get('total_sets', 0),
            'total_reps': workout_stats.get('total_reps', 0),
            'total_volume_kg': workout_stats.get('total_volume_kg', 0),
            'duration_seconds': workout_stats.get('duration_seconds', 0),
            'active_time_seconds': workout_stats.get('active_time_seconds'),
            'total_rest_seconds': workout_stats.get('total_rest_seconds'),
            'avg_rest_seconds': workout_stats.get('avg_rest_seconds'),
            'avg_rpe': workout_stats.get('avg_rpe'),
            'avg_rir': workout_stats.get('avg_rir'),
            'estimated_calories': workout_stats.get('calories', 0),
            'new_prs_count': workout_stats.get('new_prs_count', 0),
            'performed_at': workout_stats.get('completed_at', datetime.now()),
        }

        # Build exercise summaries
        exercise_summaries = []
        for ex in exercises_performance:
            sets = ex.get('sets', [])
            completed_sets = [s for s in sets if s.get('completed', True)]

            total_reps = sum(s.get('reps', 0) or s.get('reps_completed', 0) for s in completed_sets)
            weights = [s.get('weight_kg', 0) for s in completed_sets if s.get('weight_kg', 0) > 0]
            max_weight = max(weights) if weights else None
            avg_weight = sum(weights) / len(weights) if weights else None
            total_volume = sum(
                (s.get('reps', 0) or s.get('reps_completed', 0)) * s.get('weight_kg', 0)
                for s in completed_sets
            )

            # Calculate 1RM from best set
            estimated_1rm = None
            if completed_sets:
                for s in completed_sets:
                    reps = s.get('reps', 0) or s.get('reps_completed', 0)
                    weight = s.get('weight_kg', 0)
                    if weight > 0 and 0 < reps < 37:
                        set_1rm = self.strength_calculator.calculate_1rm_average(weight, reps)
                        if estimated_1rm is None or set_1rm > estimated_1rm:
                            estimated_1rm = set_1rm

            # Time-based metrics
            times = [s.get('duration_seconds', 0) for s in completed_sets if s.get('duration_seconds')]
            total_time = sum(times) if times else None
            best_time = max(times) if times else None
            avg_time = sum(times) / len(times) if times else None

            # RPE/RIR
            rpes = [s.get('rpe') for s in completed_sets if s.get('rpe') is not None]
            rirs = [s.get('rir') for s in completed_sets if s.get('rir') is not None]

            exercise_summaries.append({
                'user_id': user_id,
                'workout_log_id': workout_log_id,
                'workout_id': workout_id,
                'exercise_name': ex.get('exercise_name', ex.get('name', '')),
                'exercise_id': ex.get('exercise_id'),
                'total_sets': len(completed_sets),
                'total_reps': total_reps,
                'total_volume_kg': round(total_volume, 2),
                'max_weight_kg': round(max_weight, 2) if max_weight else None,
                'avg_weight_kg': round(avg_weight, 2) if avg_weight else None,
                'best_set_reps': max((s.get('reps', 0) or s.get('reps_completed', 0) for s in completed_sets), default=None),
                'best_set_weight_kg': max_weight,
                'estimated_1rm_kg': round(estimated_1rm, 2) if estimated_1rm else None,
                'total_time_seconds': total_time,
                'best_time_seconds': best_time,
                'avg_time_seconds': round(avg_time, 2) if avg_time else None,
                'avg_rpe': round(sum(rpes) / len(rpes), 1) if rpes else None,
                'avg_rir': round(sum(rirs) / len(rirs), 1) if rirs else None,
                'performed_at': workout_stats.get('completed_at', datetime.now()),
            })

        return workout_summary, exercise_summaries

    def get_comparison_result(
        self,
        exercise_comparisons: List[ExerciseComparison],
        workout_comparison: WorkoutComparison,
    ) -> PerformanceComparisonResult:
        """
        Build a complete performance comparison result.

        Args:
            exercise_comparisons: List of exercise comparisons
            workout_comparison: Overall workout comparison

        Returns:
            PerformanceComparisonResult with all comparison data
        """
        # Count statuses
        improved_count = sum(1 for e in exercise_comparisons if e.status == 'improved')
        maintained_count = sum(1 for e in exercise_comparisons if e.status == 'maintained')
        declined_count = sum(1 for e in exercise_comparisons if e.status == 'declined')
        first_time_count = sum(1 for e in exercise_comparisons if e.status == 'first_time')

        # Find best improvement and biggest decline
        improved_exercises = [e for e in exercise_comparisons if e.status == 'improved']
        declined_exercises = [e for e in exercise_comparisons if e.status == 'declined']

        best_improvement = None
        if improved_exercises:
            # Sort by improvement percentage (prefer 1RM, then volume)
            def get_improvement(e):
                return e.rm_diff_percent or e.volume_diff_percent or 0
            best_improvement = max(improved_exercises, key=get_improvement)

        biggest_decline = None
        if declined_exercises:
            def get_decline(e):
                return abs(e.rm_diff_percent or e.volume_diff_percent or 0)
            biggest_decline = max(declined_exercises, key=get_decline)

        return PerformanceComparisonResult(
            workout_comparison=workout_comparison,
            exercise_comparisons=exercise_comparisons,
            improved_count=improved_count,
            maintained_count=maintained_count,
            declined_count=declined_count,
            first_time_count=first_time_count,
            best_improvement=best_improvement,
            biggest_decline=biggest_decline,
        )

    def _to_float(self, value) -> Optional[float]:
        """Convert value to float, handling None and Decimal."""
        if value is None:
            return None
        if isinstance(value, Decimal):
            return float(value)
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    def format_time_diff(self, seconds: Optional[int]) -> str:
        """Format time difference as human-readable string."""
        if seconds is None:
            return ""
        sign = "+" if seconds >= 0 else "-"
        abs_seconds = abs(seconds)
        if abs_seconds >= 60:
            minutes = abs_seconds // 60
            remaining_secs = abs_seconds % 60
            return f"{sign}{minutes}m {remaining_secs}s"
        return f"{sign}{abs_seconds}s"

    def format_weight_diff(self, kg: Optional[float]) -> str:
        """Format weight difference as human-readable string."""
        if kg is None:
            return ""
        sign = "+" if kg >= 0 else ""
        return f"{sign}{kg:.1f} kg"

    def format_percent_diff(self, percent: Optional[float]) -> str:
        """Format percentage difference as human-readable string."""
        if percent is None:
            return ""
        sign = "+" if percent >= 0 else ""
        return f"{sign}{percent:.1f}%"
