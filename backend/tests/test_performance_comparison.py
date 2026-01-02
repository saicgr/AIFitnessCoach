"""
Tests for Performance Comparison Service

Tests the service that compares workout performance over time,
showing improvements and setbacks vs previous sessions.
"""
import pytest
from datetime import datetime, timedelta
from decimal import Decimal

from services.performance_comparison_service import (
    PerformanceComparisonService,
    ExerciseComparison,
    WorkoutComparison,
    PerformanceComparisonResult,
)


class TestExerciseComparison:
    """Tests for exercise-level performance comparison."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PerformanceComparisonService()

    def test_first_time_exercise(self):
        """Test that first-time exercise returns 'first_time' status."""
        current_performance = {
            'exercise_name': 'Bench Press',
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2400.0,
            'max_weight_kg': 100.0,
            'estimated_1rm_kg': 120.0,
        }

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Bench Press',
            current_performance=current_performance,
            previous_performances=[],  # No previous sessions
        )

        assert comparison.status == 'first_time'
        assert comparison.current_sets == 3
        assert comparison.current_reps == 24
        assert comparison.current_volume_kg == 2400.0
        assert comparison.previous_sets is None
        assert comparison.volume_diff_kg is None

    def test_improved_exercise_via_1rm(self):
        """Test that higher 1RM shows improvement."""
        current_performance = {
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2500.0,
            'max_weight_kg': 105.0,
            'estimated_1rm_kg': 126.0,  # 5% improvement
        }

        previous_performances = [{
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2400.0,
            'max_weight_kg': 100.0,
            'estimated_1rm_kg': 120.0,
            'performed_at': datetime.now() - timedelta(days=3),
        }]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Bench Press',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        assert comparison.status == 'improved'
        assert comparison.rm_diff_kg == 6.0
        assert comparison.rm_diff_percent == 5.0
        assert comparison.volume_diff_kg == 100.0

    def test_declined_exercise_via_1rm(self):
        """Test that lower 1RM shows decline."""
        current_performance = {
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2300.0,
            'max_weight_kg': 95.0,
            'estimated_1rm_kg': 114.0,  # 5% decline
        }

        previous_performances = [{
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2400.0,
            'max_weight_kg': 100.0,
            'estimated_1rm_kg': 120.0,
            'performed_at': datetime.now() - timedelta(days=3),
        }]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Bench Press',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        assert comparison.status == 'declined'
        assert comparison.rm_diff_kg == -6.0
        assert comparison.rm_diff_percent == -5.0

    def test_maintained_exercise(self):
        """Test that similar performance shows maintained."""
        current_performance = {
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2400.0,
            'max_weight_kg': 100.0,
            'estimated_1rm_kg': 120.5,  # 0.4% change
        }

        previous_performances = [{
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2400.0,
            'max_weight_kg': 100.0,
            'estimated_1rm_kg': 120.0,
            'performed_at': datetime.now() - timedelta(days=3),
        }]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Bench Press',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        assert comparison.status == 'maintained'

    def test_timed_exercise_improvement(self):
        """Test time-based exercise improvement (e.g., plank)."""
        current_performance = {
            'total_sets': 3,
            'total_time_seconds': 180,  # 3 minutes total
        }

        previous_performances = [{
            'total_sets': 3,
            'total_time_seconds': 150,  # 2.5 minutes
            'performed_at': datetime.now() - timedelta(days=3),
        }]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Plank',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        assert comparison.status == 'improved'
        assert comparison.time_diff_seconds == 30
        assert comparison.time_diff_percent == 20.0

    def test_timed_exercise_decline(self):
        """Test time-based exercise decline."""
        current_performance = {
            'total_sets': 3,
            'total_time_seconds': 120,  # 2 minutes
        }

        previous_performances = [{
            'total_sets': 3,
            'total_time_seconds': 150,  # 2.5 minutes
            'performed_at': datetime.now() - timedelta(days=3),
        }]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Plank',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        assert comparison.status == 'declined'
        assert comparison.time_diff_seconds == -30
        assert comparison.time_diff_percent == -20.0

    def test_volume_fallback_status(self):
        """Test volume-based status when 1RM not available."""
        current_performance = {
            'total_sets': 3,
            'total_reps': 30,
            'total_volume_kg': 3000.0,  # 25% improvement
        }

        previous_performances = [{
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2400.0,
            'performed_at': datetime.now() - timedelta(days=3),
        }]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Bodyweight Squats',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        assert comparison.status == 'improved'
        assert comparison.volume_diff_kg == 600.0
        assert comparison.volume_diff_percent == 25.0

    def test_decimal_value_handling(self):
        """Test that Decimal values are properly converted."""
        current_performance = {
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': Decimal('2400.50'),
            'max_weight_kg': Decimal('100.25'),
            'estimated_1rm_kg': Decimal('120.50'),
        }

        previous_performances = [{
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': Decimal('2300.00'),
            'max_weight_kg': Decimal('95.00'),
            'estimated_1rm_kg': Decimal('114.00'),
            'performed_at': datetime.now() - timedelta(days=3),
        }]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Bench Press',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        assert isinstance(comparison.current_volume_kg, float)
        assert isinstance(comparison.current_max_weight_kg, float)
        assert comparison.status == 'improved'


class TestWorkoutComparison:
    """Tests for workout-level performance comparison."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PerformanceComparisonService()

    def test_first_workout(self):
        """Test first workout returns 'first_time' status."""
        current_stats = {
            'duration_seconds': 3600,
            'total_volume_kg': 5000.0,
            'total_sets': 20,
            'total_reps': 200,
            'total_exercises': 6,
            'estimated_calories': 350,
        }

        comparison = self.service.compute_workout_comparison(
            current_stats=current_stats,
            previous_stats=None,
        )

        assert comparison.overall_status == 'first_time'
        assert comparison.has_previous is False
        assert comparison.current_duration_seconds == 3600
        assert comparison.current_total_volume_kg == 5000.0

    def test_improved_workout(self):
        """Test workout with improved volume."""
        current_stats = {
            'duration_seconds': 3600,
            'total_volume_kg': 5500.0,  # 10% improvement
            'total_sets': 22,
            'total_reps': 220,
            'total_exercises': 6,
            'estimated_calories': 400,
        }

        previous_stats = {
            'duration_seconds': 3500,
            'total_volume_kg': 5000.0,
            'total_sets': 20,
            'total_reps': 200,
            'total_exercises': 6,
            'estimated_calories': 350,
            'performed_at': datetime.now() - timedelta(days=7),
        }

        comparison = self.service.compute_workout_comparison(
            current_stats=current_stats,
            previous_stats=previous_stats,
        )

        assert comparison.overall_status == 'improved'
        assert comparison.has_previous is True
        assert comparison.volume_diff_kg == 500.0
        assert comparison.volume_diff_percent == 10.0
        assert comparison.sets_diff == 2
        assert comparison.reps_diff == 20

    def test_declined_workout(self):
        """Test workout with declined volume."""
        current_stats = {
            'duration_seconds': 3600,
            'total_volume_kg': 4500.0,  # 10% decline
            'total_sets': 18,
            'total_reps': 180,
            'total_exercises': 5,
            'estimated_calories': 300,
        }

        previous_stats = {
            'duration_seconds': 3500,
            'total_volume_kg': 5000.0,
            'total_sets': 20,
            'total_reps': 200,
            'total_exercises': 6,
            'estimated_calories': 350,
        }

        comparison = self.service.compute_workout_comparison(
            current_stats=current_stats,
            previous_stats=previous_stats,
        )

        assert comparison.overall_status == 'declined'
        assert comparison.volume_diff_kg == -500.0
        assert comparison.volume_diff_percent == -10.0

    def test_maintained_workout(self):
        """Test workout with similar volume."""
        current_stats = {
            'duration_seconds': 3600,
            'total_volume_kg': 5050.0,  # 1% change
            'total_sets': 20,
            'total_reps': 200,
            'total_exercises': 6,
            'estimated_calories': 350,
        }

        previous_stats = {
            'duration_seconds': 3500,
            'total_volume_kg': 5000.0,
            'total_sets': 20,
            'total_reps': 200,
            'total_exercises': 6,
            'estimated_calories': 350,
        }

        comparison = self.service.compute_workout_comparison(
            current_stats=current_stats,
            previous_stats=previous_stats,
        )

        assert comparison.overall_status == 'maintained'

    def test_duration_difference(self):
        """Test duration difference calculation."""
        current_stats = {
            'duration_seconds': 4000,  # +10 minutes
            'total_volume_kg': 5000.0,
            'total_sets': 20,
            'total_reps': 200,
            'total_exercises': 6,
            'estimated_calories': 350,
        }

        previous_stats = {
            'duration_seconds': 3400,
            'total_volume_kg': 5000.0,
            'total_sets': 20,
            'total_reps': 200,
            'total_exercises': 6,
            'estimated_calories': 350,
        }

        comparison = self.service.compute_workout_comparison(
            current_stats=current_stats,
            previous_stats=previous_stats,
        )

        assert comparison.duration_diff_seconds == 600  # +10 minutes
        assert comparison.duration_diff_percent == pytest.approx(17.6, rel=0.1)


class TestPerformanceComparisonResult:
    """Tests for complete performance comparison results."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PerformanceComparisonService()

    def test_status_counts(self):
        """Test correct counting of improvement statuses."""
        exercise_comparisons = [
            ExerciseComparison(exercise_name='Bench Press', status='improved'),
            ExerciseComparison(exercise_name='Squat', status='improved'),
            ExerciseComparison(exercise_name='Deadlift', status='declined'),
            ExerciseComparison(exercise_name='OHP', status='maintained'),
            ExerciseComparison(exercise_name='Rows', status='first_time'),
        ]

        workout_comparison = WorkoutComparison(
            current_duration_seconds=3600,
            current_total_volume_kg=5000.0,
            overall_status='improved',
        )

        result = self.service.get_comparison_result(
            exercise_comparisons=exercise_comparisons,
            workout_comparison=workout_comparison,
        )

        assert result.improved_count == 2
        assert result.maintained_count == 1
        assert result.declined_count == 1
        assert result.first_time_count == 1

    def test_best_improvement_selection(self):
        """Test that best improvement is correctly identified."""
        exercise_comparisons = [
            ExerciseComparison(
                exercise_name='Bench Press',
                status='improved',
                rm_diff_percent=5.0,
            ),
            ExerciseComparison(
                exercise_name='Squat',
                status='improved',
                rm_diff_percent=10.0,  # Best improvement
            ),
            ExerciseComparison(
                exercise_name='Deadlift',
                status='improved',
                rm_diff_percent=3.0,
            ),
        ]

        workout_comparison = WorkoutComparison(
            current_duration_seconds=3600,
            current_total_volume_kg=5000.0,
            overall_status='improved',
        )

        result = self.service.get_comparison_result(
            exercise_comparisons=exercise_comparisons,
            workout_comparison=workout_comparison,
        )

        assert result.best_improvement is not None
        assert result.best_improvement.exercise_name == 'Squat'
        assert result.best_improvement.rm_diff_percent == 10.0

    def test_biggest_decline_selection(self):
        """Test that biggest decline is correctly identified."""
        exercise_comparisons = [
            ExerciseComparison(
                exercise_name='Bench Press',
                status='declined',
                rm_diff_percent=-5.0,
            ),
            ExerciseComparison(
                exercise_name='Squat',
                status='declined',
                rm_diff_percent=-15.0,  # Biggest decline
            ),
            ExerciseComparison(
                exercise_name='Deadlift',
                status='declined',
                rm_diff_percent=-3.0,
            ),
        ]

        workout_comparison = WorkoutComparison(
            current_duration_seconds=3600,
            current_total_volume_kg=5000.0,
            overall_status='declined',
        )

        result = self.service.get_comparison_result(
            exercise_comparisons=exercise_comparisons,
            workout_comparison=workout_comparison,
        )

        assert result.biggest_decline is not None
        assert result.biggest_decline.exercise_name == 'Squat'
        assert result.biggest_decline.rm_diff_percent == -15.0


class TestFormatters:
    """Tests for formatting utilities."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PerformanceComparisonService()

    def test_format_time_diff_positive_seconds(self):
        """Test formatting positive time difference in seconds."""
        assert self.service.format_time_diff(30) == "+30s"

    def test_format_time_diff_negative_seconds(self):
        """Test formatting negative time difference in seconds."""
        assert self.service.format_time_diff(-15) == "-15s"

    def test_format_time_diff_minutes(self):
        """Test formatting time difference in minutes."""
        assert self.service.format_time_diff(125) == "+2m 5s"

    def test_format_time_diff_negative_minutes(self):
        """Test formatting negative time difference in minutes."""
        assert self.service.format_time_diff(-90) == "-1m 30s"

    def test_format_time_diff_none(self):
        """Test formatting None time difference."""
        assert self.service.format_time_diff(None) == ""

    def test_format_weight_diff_positive(self):
        """Test formatting positive weight difference."""
        assert self.service.format_weight_diff(5.5) == "+5.5 kg"

    def test_format_weight_diff_negative(self):
        """Test formatting negative weight difference."""
        assert self.service.format_weight_diff(-2.5) == "-2.5 kg"

    def test_format_weight_diff_none(self):
        """Test formatting None weight difference."""
        assert self.service.format_weight_diff(None) == ""

    def test_format_percent_diff_positive(self):
        """Test formatting positive percentage difference."""
        assert self.service.format_percent_diff(10.5) == "+10.5%"

    def test_format_percent_diff_negative(self):
        """Test formatting negative percentage difference."""
        assert self.service.format_percent_diff(-5.2) == "-5.2%"

    def test_format_percent_diff_none(self):
        """Test formatting None percentage difference."""
        assert self.service.format_percent_diff(None) == ""


class TestBuildPerformanceSummary:
    """Tests for building performance summary records."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PerformanceComparisonService()

    def test_build_workout_summary(self):
        """Test building workout summary record."""
        exercises_performance = [
            {
                'exercise_name': 'Bench Press',
                'sets': [
                    {'reps': 8, 'weight_kg': 100, 'completed': True},
                    {'reps': 8, 'weight_kg': 100, 'completed': True},
                    {'reps': 6, 'weight_kg': 100, 'completed': True},
                ],
            },
            {
                'exercise_name': 'Squat',
                'sets': [
                    {'reps': 8, 'weight_kg': 120, 'completed': True},
                    {'reps': 8, 'weight_kg': 120, 'completed': True},
                ],
            },
        ]

        workout_stats = {
            'workout_name': 'Push Day',
            'workout_type': 'strength',
            'total_sets': 5,
            'total_reps': 38,
            'total_volume_kg': 4120.0,
            'duration_seconds': 3600,
            'calories': 350,
            'completed_at': datetime.now(),
        }

        workout_summary, exercise_summaries = self.service.build_performance_summary(
            workout_log_id='log-123',
            user_id='user-456',
            workout_id='workout-789',
            exercises_performance=exercises_performance,
            workout_stats=workout_stats,
        )

        assert workout_summary['user_id'] == 'user-456'
        assert workout_summary['workout_log_id'] == 'log-123'
        assert workout_summary['workout_name'] == 'Push Day'
        assert workout_summary['total_exercises'] == 2
        assert workout_summary['total_sets'] == 5
        assert workout_summary['total_reps'] == 38
        assert workout_summary['total_volume_kg'] == 4120.0

    def test_build_exercise_summaries(self):
        """Test building exercise summary records."""
        exercises_performance = [
            {
                'exercise_name': 'Bench Press',
                'exercise_id': 'ex-001',
                'sets': [
                    {'reps': 8, 'weight_kg': 100, 'completed': True},
                    {'reps': 8, 'weight_kg': 100, 'completed': True},
                    {'reps': 6, 'weight_kg': 100, 'completed': True},
                ],
            },
        ]

        workout_stats = {
            'workout_name': 'Push Day',
            'completed_at': datetime.now(),
        }

        _, exercise_summaries = self.service.build_performance_summary(
            workout_log_id='log-123',
            user_id='user-456',
            workout_id='workout-789',
            exercises_performance=exercises_performance,
            workout_stats=workout_stats,
        )

        assert len(exercise_summaries) == 1
        ex = exercise_summaries[0]

        assert ex['exercise_name'] == 'Bench Press'
        assert ex['exercise_id'] == 'ex-001'
        assert ex['total_sets'] == 3
        assert ex['total_reps'] == 22  # 8 + 8 + 6
        assert ex['total_volume_kg'] == 2200.0  # 22 * 100
        assert ex['max_weight_kg'] == 100.0
        assert ex['estimated_1rm_kg'] is not None  # Should calculate 1RM

    def test_skip_incomplete_sets(self):
        """Test that incomplete sets are excluded from summaries."""
        exercises_performance = [
            {
                'exercise_name': 'Bench Press',
                'sets': [
                    {'reps': 8, 'weight_kg': 100, 'completed': True},
                    {'reps': 0, 'weight_kg': 100, 'completed': False},  # Incomplete
                ],
            },
        ]

        workout_stats = {
            'workout_name': 'Push Day',
            'completed_at': datetime.now(),
        }

        _, exercise_summaries = self.service.build_performance_summary(
            workout_log_id='log-123',
            user_id='user-456',
            workout_id='workout-789',
            exercises_performance=exercises_performance,
            workout_stats=workout_stats,
        )

        assert len(exercise_summaries) == 1
        ex = exercise_summaries[0]
        assert ex['total_sets'] == 1  # Only 1 completed set
        assert ex['total_reps'] == 8

    def test_timed_exercise_summary(self):
        """Test building summary for timed exercises."""
        exercises_performance = [
            {
                'exercise_name': 'Plank',
                'sets': [
                    {'duration_seconds': 60, 'completed': True},
                    {'duration_seconds': 45, 'completed': True},
                    {'duration_seconds': 30, 'completed': True},
                ],
            },
        ]

        workout_stats = {
            'workout_name': 'Core',
            'completed_at': datetime.now(),
        }

        _, exercise_summaries = self.service.build_performance_summary(
            workout_log_id='log-123',
            user_id='user-456',
            workout_id='workout-789',
            exercises_performance=exercises_performance,
            workout_stats=workout_stats,
        )

        ex = exercise_summaries[0]
        assert ex['total_time_seconds'] == 135  # 60 + 45 + 30
        assert ex['best_time_seconds'] == 60
        assert ex['avg_time_seconds'] == 45.0


class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PerformanceComparisonService()

    def test_empty_current_performance(self):
        """Test handling empty current performance."""
        comparison = self.service.compute_exercise_comparison(
            exercise_name='Test',
            current_performance={},
            previous_performances=[],
        )

        assert comparison.status == 'first_time'
        assert comparison.current_sets == 0
        assert comparison.current_reps == 0

    def test_zero_division_handling(self):
        """Test that zero division is handled."""
        current_performance = {
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 0,  # Zero volume
            'max_weight_kg': 0,
            'estimated_1rm_kg': 0,
        }

        previous_performances = [{
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 0,
            'max_weight_kg': 0,
            'estimated_1rm_kg': 0,
        }]

        # Should not raise exception
        comparison = self.service.compute_exercise_comparison(
            exercise_name='Test',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        assert comparison.volume_diff_percent is None

    def test_null_values_in_previous(self):
        """Test handling null values in previous performance."""
        current_performance = {
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2400.0,
        }

        previous_performances = [{
            'total_sets': None,
            'total_reps': None,
            'total_volume_kg': None,
        }]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Test',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        # Should not raise exception
        assert comparison.previous_sets is None
        assert comparison.previous_reps is None

    def test_multiple_previous_performances(self):
        """Test that most recent previous performance is used."""
        current_performance = {
            'total_sets': 3,
            'total_reps': 24,
            'total_volume_kg': 2400.0,
            'estimated_1rm_kg': 120.0,
        }

        # List sorted by most recent first
        previous_performances = [
            {
                'total_sets': 3,
                'total_reps': 24,
                'total_volume_kg': 2300.0,
                'estimated_1rm_kg': 115.0,
                'performed_at': datetime.now() - timedelta(days=3),
            },
            {
                'total_sets': 3,
                'total_reps': 24,
                'total_volume_kg': 2200.0,
                'estimated_1rm_kg': 110.0,
                'performed_at': datetime.now() - timedelta(days=7),
            },
        ]

        comparison = self.service.compute_exercise_comparison(
            exercise_name='Test',
            current_performance=current_performance,
            previous_performances=previous_performances,
        )

        # Should compare with most recent (first in list)
        assert comparison.previous_1rm_kg == 115.0
        assert comparison.rm_diff_kg == 5.0


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
