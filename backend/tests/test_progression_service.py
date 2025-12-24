"""
Tests for Progression Service.

Tests:
- Initial recommendations for new exercises
- Progression strategies (linear, double, wave, deload)
- RPE-based progression decisions
- Plateau detection
- Deload week detection

Run with: pytest backend/tests/test_progression_service.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, timedelta

from services.progression_service import ProgressionService, RPE_THRESHOLDS
from models.performance import (
    ExercisePerformance, WorkoutPerformance,
    ProgressionRecommendation, ProgressionStrategy, SetPerformance
)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def progression_service():
    return ProgressionService()


@pytest.fixture
def mock_exercise_performance():
    """Create a mock exercise performance."""
    return ExercisePerformance(
        exercise_id="bench_press",
        exercise_name="Bench Press",
        target_sets=3,
        target_reps=8,
        sets=[
            SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, rpe=7.0, completed=True),
            SetPerformance(set_number=2, weight_kg=80.0, reps_completed=8, rpe=7.5, completed=True),
            SetPerformance(set_number=3, weight_kg=80.0, reps_completed=8, rpe=8.0, completed=True),
        ],
        average_rpe=7.5,
        estimated_1rm=100.0,
        total_reps=24,
        total_volume=1920.0,
    )


@pytest.fixture
def high_rpe_performance():
    """Create a high RPE performance indicating fatigue."""
    return ExercisePerformance(
        exercise_id="bench_press",
        exercise_name="Bench Press",
        target_sets=3,
        target_reps=8,
        sets=[
            SetPerformance(set_number=1, weight_kg=85.0, reps_completed=6, rpe=9.5, completed=True),
            SetPerformance(set_number=2, weight_kg=85.0, reps_completed=5, rpe=10.0, completed=True),
            SetPerformance(set_number=3, weight_kg=85.0, reps_completed=4, rpe=10.0, completed=False),
        ],
        average_rpe=9.8,
        estimated_1rm=98.0,
        total_reps=15,
        total_volume=1275.0,
    )


@pytest.fixture
def low_rpe_performance():
    """Create a low RPE performance indicating readiness."""
    return ExercisePerformance(
        exercise_id="bench_press",
        exercise_name="Bench Press",
        target_sets=3,
        target_reps=8,
        sets=[
            SetPerformance(set_number=1, weight_kg=75.0, reps_completed=8, rpe=6.0, completed=True),
            SetPerformance(set_number=2, weight_kg=75.0, reps_completed=8, rpe=6.5, completed=True),
            SetPerformance(set_number=3, weight_kg=75.0, reps_completed=8, rpe=7.0, completed=True),
        ],
        average_rpe=6.5,
        estimated_1rm=94.0,
        total_reps=24,
        total_volume=1800.0,
    )


# ============================================================
# INITIAL RECOMMENDATION TESTS
# ============================================================

class TestInitialRecommendation:
    """Test recommendations for new exercises."""

    def test_initial_recommendation_no_history(self, progression_service):
        """Test recommendation when no performance history exists."""
        recommendation = progression_service.get_recommendation(
            exercise_id="new_exercise",
            exercise_name="New Exercise",
            last_performance=None,
            performance_history=[],
        )

        assert isinstance(recommendation, ProgressionRecommendation)
        assert recommendation.strategy == ProgressionStrategy.LINEAR
        assert recommendation.recommended_weight_kg == 20.0
        assert recommendation.recommended_reps == 10
        assert recommendation.recommended_sets == 3
        assert recommendation.confidence == 0.5
        assert "first time" in recommendation.reason.lower()

    def test_initial_recommendation_fields(self, progression_service):
        """Test initial recommendation has correct fields."""
        recommendation = progression_service.get_recommendation(
            exercise_id="squat",
            exercise_name="Squat",
            last_performance=None,
            performance_history=[],
        )

        assert recommendation.exercise_id == "squat"
        assert recommendation.exercise_name == "Squat"
        assert recommendation.current_weight_kg == 0
        assert recommendation.current_reps == 0


# ============================================================
# LINEAR PROGRESSION TESTS
# ============================================================

class TestLinearProgression:
    """Test linear progression strategy."""

    @patch('services.progression_service.get_exercise_type')
    @patch('services.progression_service.PROGRESSION_INCREMENTS', {'compound': 2.5, 'isolation': 1.25})
    def test_linear_progression_compound(self, mock_get_type, progression_service, low_rpe_performance):
        """Test linear progression for compound exercise."""
        mock_get_type.return_value = 'compound'

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=low_rpe_performance,
            performance_history=[low_rpe_performance],
        )

        # Low RPE means ready for linear progression
        assert recommendation.strategy == ProgressionStrategy.LINEAR
        assert recommendation.recommended_weight_kg == 77.5  # 75 + 2.5
        assert recommendation.confidence >= 0.8

    @patch('services.progression_service.get_exercise_type')
    @patch('services.progression_service.PROGRESSION_INCREMENTS', {'compound': 2.5, 'isolation': 1.25})
    def test_linear_progression_reason(self, mock_get_type, progression_service, low_rpe_performance):
        """Test linear progression has appropriate reason."""
        mock_get_type.return_value = 'compound'

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=low_rpe_performance,
            performance_history=[low_rpe_performance],
        )

        assert "progression" in recommendation.reason.lower() or "strong" in recommendation.reason.lower()


# ============================================================
# DELOAD STRATEGY TESTS
# ============================================================

class TestDeloadStrategy:
    """Test deload progression strategy."""

    @patch('services.progression_service.get_exercise_type')
    @patch('services.progression_service.PROGRESSION_INCREMENTS', {'compound': 2.5, 'isolation': 1.25})
    def test_deload_on_high_rpe(self, mock_get_type, progression_service, high_rpe_performance):
        """Test deload recommended on high RPE."""
        mock_get_type.return_value = 'compound'

        # Create history with consistently high RPE
        high_rpe_history = [high_rpe_performance, high_rpe_performance, high_rpe_performance]

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=high_rpe_performance,
            performance_history=high_rpe_history,
        )

        assert recommendation.strategy == ProgressionStrategy.DELOAD
        assert recommendation.recommended_weight_kg < 85.0 * 0.7  # At least 30% reduction
        assert "fatigue" in recommendation.reason.lower() or "deload" in recommendation.reason.lower()

    @patch('services.progression_service.get_exercise_type')
    @patch('services.progression_service.PROGRESSION_INCREMENTS', {'compound': 2.5, 'isolation': 1.25})
    def test_deload_reduces_sets(self, mock_get_type, progression_service, high_rpe_performance):
        """Test deload reduces sets."""
        mock_get_type.return_value = 'compound'

        high_rpe_history = [high_rpe_performance, high_rpe_performance, high_rpe_performance]

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=high_rpe_performance,
            performance_history=high_rpe_history,
        )

        # Deload should reduce or maintain sets
        assert recommendation.recommended_sets <= high_rpe_performance.target_sets


# ============================================================
# DOUBLE PROGRESSION TESTS
# ============================================================

class TestDoubleProgression:
    """Test double progression strategy."""

    @patch('services.progression_service.get_exercise_type')
    @patch('services.progression_service.PROGRESSION_INCREMENTS', {'compound': 2.5, 'isolation': 1.25})
    def test_double_progression_moderate_rpe(self, mock_get_type, progression_service, mock_exercise_performance):
        """Test double progression on moderate RPE."""
        mock_get_type.return_value = 'compound'

        # Moderate RPE (between ready and deload thresholds)
        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=mock_exercise_performance,
            performance_history=[mock_exercise_performance],
        )

        # With avg RPE of 7.5, should use double progression
        assert recommendation.strategy == ProgressionStrategy.DOUBLE_PROGRESSION
        assert "consistency" in recommendation.reason.lower() or "building" in recommendation.reason.lower()


# ============================================================
# PLATEAU DETECTION TESTS
# ============================================================

class TestPlateauDetection:
    """Test plateau detection."""

    def test_no_plateau_with_short_history(self, progression_service):
        """Test no plateau detected with short history."""
        performance = ExercisePerformance(
            exercise_id="test",
            exercise_name="Test",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, completed=True),
            ],
            estimated_1rm=100.0,
            total_reps=8,
            total_volume=640.0,
        )

        is_plateau = progression_service._detect_plateau([performance, performance])
        assert is_plateau is False  # Need at least 4 data points

    def test_plateau_detected_with_stagnant_1rm(self, progression_service):
        """Test plateau detected when 1RM stagnates."""
        # Create performances with very similar 1RMs (< 3% variance)
        performances = []
        for i in range(4):
            perf = ExercisePerformance(
                exercise_id="test",
                exercise_name="Test",
                target_sets=3,
                target_reps=8,
                sets=[
                    SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, completed=True),
                ],
                estimated_1rm=100.0 + (i * 0.5),  # Very small variance
                total_reps=8,
                total_volume=640.0,
            )
            performances.append(perf)

        is_plateau = progression_service._detect_plateau(performances)
        assert is_plateau is True

    def test_no_plateau_with_progressive_1rm(self, progression_service):
        """Test no plateau when 1RM is progressing."""
        performances = []
        for i in range(4):
            perf = ExercisePerformance(
                exercise_id="test",
                exercise_name="Test",
                target_sets=3,
                target_reps=8,
                sets=[
                    SetPerformance(set_number=1, weight_kg=80.0 + (i * 5), reps_completed=8, completed=True),
                ],
                estimated_1rm=100.0 + (i * 5),  # Good progression
                total_reps=8,
                total_volume=640.0 + (i * 40),
            )
            performances.append(perf)

        is_plateau = progression_service._detect_plateau(performances)
        assert is_plateau is False


# ============================================================
# WAVE PROGRESSION TESTS
# ============================================================

class TestWaveProgression:
    """Test wave progression strategy for plateaus."""

    @patch('services.progression_service.get_exercise_type')
    @patch('services.progression_service.PROGRESSION_INCREMENTS', {'compound': 2.5, 'isolation': 1.25})
    def test_wave_progression_on_plateau(self, mock_get_type, progression_service):
        """Test wave progression recommended on plateau."""
        mock_get_type.return_value = 'compound'

        # Create plateau history
        plateau_performance = ExercisePerformance(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, rpe=8.0, completed=True),
                SetPerformance(set_number=2, weight_kg=80.0, reps_completed=8, rpe=8.0, completed=True),
                SetPerformance(set_number=3, weight_kg=80.0, reps_completed=8, rpe=8.0, completed=True),
            ],
            average_rpe=8.0,
            estimated_1rm=100.0,
            total_reps=24,
            total_volume=1920.0,
        )

        # Create 4 identical performances (plateau)
        history = [plateau_performance] * 4

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=plateau_performance,
            performance_history=history,
        )

        assert recommendation.strategy == ProgressionStrategy.WAVE
        assert "plateau" in recommendation.reason.lower()
        # Wave loading should reduce weight slightly
        assert recommendation.recommended_weight_kg < 80.0


# ============================================================
# AVERAGE RPE CALCULATION TESTS
# ============================================================

class TestAverageRPECalculation:
    """Test average RPE calculation."""

    def test_calculate_average_rpe(self, progression_service):
        """Test average RPE calculation with valid data."""
        performances = [
            ExercisePerformance(
                exercise_id="test", exercise_name="Test",
                target_sets=3, target_reps=8,
                sets=[], average_rpe=7.0, total_reps=24, total_volume=1920.0,
            ),
            ExercisePerformance(
                exercise_id="test", exercise_name="Test",
                target_sets=3, target_reps=8,
                sets=[], average_rpe=8.0, total_reps=24, total_volume=1920.0,
            ),
            ExercisePerformance(
                exercise_id="test", exercise_name="Test",
                target_sets=3, target_reps=8,
                sets=[], average_rpe=9.0, total_reps=24, total_volume=1920.0,
            ),
        ]

        avg = progression_service._calculate_average_rpe(performances)
        assert avg == 8.0

    def test_calculate_average_rpe_with_none_values(self, progression_service):
        """Test average RPE calculation handles None values."""
        performances = [
            ExercisePerformance(
                exercise_id="test", exercise_name="Test",
                target_sets=3, target_reps=8,
                sets=[], average_rpe=7.0, total_reps=24, total_volume=1920.0,
            ),
            ExercisePerformance(
                exercise_id="test", exercise_name="Test",
                target_sets=3, target_reps=8,
                sets=[], average_rpe=None, total_reps=24, total_volume=1920.0,
            ),
        ]

        avg = progression_service._calculate_average_rpe(performances)
        assert avg == 7.0

    def test_calculate_average_rpe_empty_list(self, progression_service):
        """Test average RPE returns None for empty list."""
        avg = progression_service._calculate_average_rpe([])
        assert avg is None


# ============================================================
# HIT REP TARGET TESTS
# ============================================================

class TestHitRepTarget:
    """Test rep target hit detection."""

    def test_hit_rep_target_all_sets_complete(self, progression_service):
        """Test returns True when all sets hit target."""
        performance = ExercisePerformance(
            exercise_id="test",
            exercise_name="Test",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, completed=True),
                SetPerformance(set_number=2, weight_kg=80.0, reps_completed=9, completed=True),
                SetPerformance(set_number=3, weight_kg=80.0, reps_completed=8, completed=True),
            ],
            total_reps=25,
            total_volume=2000.0,
        )

        assert progression_service._hit_rep_target(performance) is True

    def test_hit_rep_target_missed_reps(self, progression_service):
        """Test returns False when reps are missed."""
        performance = ExercisePerformance(
            exercise_id="test",
            exercise_name="Test",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, completed=True),
                SetPerformance(set_number=2, weight_kg=80.0, reps_completed=6, completed=True),  # Missed
                SetPerformance(set_number=3, weight_kg=80.0, reps_completed=5, completed=True),  # Missed
            ],
            total_reps=19,
            total_volume=1520.0,
        )

        assert progression_service._hit_rep_target(performance) is False


# ============================================================
# SHOULD DELOAD TESTS
# ============================================================

class TestShouldDeload:
    """Test deload week detection."""

    def test_should_deload_high_session_rpe(self, progression_service):
        """Test deload recommended with high session RPE."""
        workouts = []
        for i in range(4):
            workout = MagicMock(spec=WorkoutPerformance)
            workout.session_rpe = 9.6  # Above deload threshold
            workout.total_volume = 5000
            workout.completion_rate = 90
            workouts.append(workout)

        should_deload, reason = progression_service.should_deload(workouts)

        assert should_deload is True
        assert "rpe" in reason.lower()

    def test_should_deload_declining_volume(self, progression_service):
        """Test deload recommended with declining volume."""
        workouts = []
        volumes = [5000, 4500, 4200, 4000]  # Declining
        for vol in volumes:
            workout = MagicMock(spec=WorkoutPerformance)
            workout.session_rpe = 8.0
            workout.total_volume = vol
            workout.completion_rate = 90
            workouts.append(workout)

        should_deload, reason = progression_service.should_deload(workouts)

        assert should_deload is True
        assert "volume" in reason.lower() or "declining" in reason.lower()

    def test_should_deload_low_completion(self, progression_service):
        """Test deload recommended with low completion rates."""
        workouts = []
        for i in range(4):
            workout = MagicMock(spec=WorkoutPerformance)
            workout.session_rpe = 8.0
            workout.total_volume = 5000
            workout.completion_rate = 70  # Low completion
            workouts.append(workout)

        should_deload, reason = progression_service.should_deload(workouts)

        assert should_deload is True
        assert "completion" in reason.lower() or "fatigue" in reason.lower()

    def test_should_not_deload_short_history(self, progression_service):
        """Test no deload with short history."""
        workouts = [MagicMock(spec=WorkoutPerformance) for _ in range(2)]

        should_deload, reason = progression_service.should_deload(workouts)

        assert should_deload is False
        assert reason is None

    def test_should_not_deload_good_performance(self, progression_service):
        """Test no deload with good performance."""
        workouts = []
        volumes = [4800, 5000, 5200, 5400]  # Increasing
        for vol in volumes:
            workout = MagicMock(spec=WorkoutPerformance)
            workout.session_rpe = 7.5  # Below threshold
            workout.total_volume = vol
            workout.completion_rate = 95  # High completion
            workouts.append(workout)

        should_deload, reason = progression_service.should_deload(workouts)

        assert should_deload is False
        assert reason is None


# ============================================================
# RPE THRESHOLD TESTS
# ============================================================

class TestRPEThresholds:
    """Test RPE threshold values."""

    def test_rpe_thresholds_exist(self):
        """Test RPE thresholds are defined."""
        assert "ready_to_progress" in RPE_THRESHOLDS
        assert "maintain" in RPE_THRESHOLDS
        assert "deload" in RPE_THRESHOLDS

    def test_rpe_thresholds_ordered(self):
        """Test RPE thresholds are in correct order."""
        assert RPE_THRESHOLDS["ready_to_progress"] < RPE_THRESHOLDS["maintain"]
        assert RPE_THRESHOLDS["maintain"] < RPE_THRESHOLDS["deload"]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
