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

from services.progression_service import ProgressionService, RPE_THRESHOLDS, PROGRESSION_PACE_THRESHOLDS
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


# ============================================================
# REP CEILING TESTS
# ============================================================

class TestRepCeilingEnforcement:
    """Test rep ceiling enforcement to prevent 20+ rep sets."""

    def test_compound_exercise_ceiling_at_12_reps(self, progression_service):
        """
        Test compound exercises (bench press, squat) cap at 12 reps.
        This addresses competitor feedback about doing 20 reps.
        """
        # Create performance with reps at ceiling (12)
        # Use "Barbell Bench Press" so it's detected as barbell equipment
        performance = ExercisePerformance(
            exercise_id="bench_press",
            exercise_name="Barbell Bench Press",  # Explicit barbell - compound exercise
            target_sets=3,
            target_reps=12,  # At ceiling
            sets=[
                SetPerformance(set_number=1, weight_kg=60.0, reps_completed=12, rpe=8.0, completed=True),
                SetPerformance(set_number=2, weight_kg=60.0, reps_completed=12, rpe=8.0, completed=True),
                SetPerformance(set_number=3, weight_kg=60.0, reps_completed=12, rpe=8.0, completed=True),
            ],
            average_rpe=8.0,  # Moderate RPE - triggers DOUBLE_PROGRESSION
            estimated_1rm=85.0,
            total_reps=36,
            total_volume=2160.0,
        )

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Barbell Bench Press",
            last_performance=performance,
            performance_history=[performance],
        )

        # At rep ceiling, should FORCE weight increase instead of going to 13 reps
        assert recommendation.recommended_reps <= 12, \
            f"Compound exercise should never exceed 12 reps, got {recommendation.recommended_reps}"
        # Should increase weight when hitting ceiling (60 + 2.5 = 62.5 for barbell)
        assert recommendation.recommended_weight_kg > 60.0, \
            f"Should increase weight when at rep ceiling, got {recommendation.recommended_weight_kg}"

    def test_isolation_exercise_ceiling_at_15_reps(self, progression_service):
        """
        Test isolation exercises (curls, extensions) cap at 15 reps.
        """
        # Create performance with reps at isolation ceiling (15)
        performance = ExercisePerformance(
            exercise_id="bicep_curl",
            exercise_name="Dumbbell Curl",  # Isolation exercise
            target_sets=3,
            target_reps=15,  # At ceiling for isolation
            sets=[
                SetPerformance(set_number=1, weight_kg=10.0, reps_completed=15, rpe=8.0, completed=True),
                SetPerformance(set_number=2, weight_kg=10.0, reps_completed=15, rpe=8.0, completed=True),
                SetPerformance(set_number=3, weight_kg=10.0, reps_completed=15, rpe=8.0, completed=True),
            ],
            average_rpe=8.0,  # Moderate RPE - triggers DOUBLE_PROGRESSION
            estimated_1rm=15.0,
            total_reps=45,
            total_volume=450.0,
        )

        recommendation = progression_service.get_recommendation(
            exercise_id="bicep_curl",
            exercise_name="Dumbbell Curl",
            last_performance=performance,
            performance_history=[performance],
        )

        # At rep ceiling, should not exceed 15 for isolation
        assert recommendation.recommended_reps <= 15, \
            f"Isolation exercise should never exceed 15 reps, got {recommendation.recommended_reps}"

    def test_double_progression_caps_reps_before_ceiling(self, progression_service):
        """
        Test that double progression doesn't let reps creep past ceiling.
        """
        # Create performance at 11 reps (just below compound ceiling of 12)
        performance = ExercisePerformance(
            exercise_id="squat",
            exercise_name="Barbell Squat",
            target_sets=3,
            target_reps=11,  # One below ceiling
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=10, rpe=8.0, completed=True),  # Missed target
                SetPerformance(set_number=2, weight_kg=80.0, reps_completed=10, rpe=8.5, completed=True),
                SetPerformance(set_number=3, weight_kg=80.0, reps_completed=9, rpe=9.0, completed=True),
            ],
            average_rpe=8.5,  # Moderate-high RPE - triggers DOUBLE_PROGRESSION
            estimated_1rm=100.0,
            total_reps=29,
            total_volume=2320.0,
        )

        recommendation = progression_service.get_recommendation(
            exercise_id="squat",
            exercise_name="Barbell Squat",
            last_performance=performance,
            performance_history=[performance],
        )

        # Double progression should add reps but cap at 12
        assert recommendation.recommended_reps <= 12, \
            f"Reps should be capped at 12 for compound, got {recommendation.recommended_reps}"

    def test_wave_loading_respects_rep_ceiling(self, progression_service):
        """
        Test wave loading (plateau response) doesn't exceed rep ceiling.
        """
        # Create plateau scenario with reps already at 11
        plateau_performance = ExercisePerformance(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            target_sets=3,
            target_reps=11,
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=11, rpe=8.0, completed=True),
                SetPerformance(set_number=2, weight_kg=80.0, reps_completed=11, rpe=8.0, completed=True),
                SetPerformance(set_number=3, weight_kg=80.0, reps_completed=11, rpe=8.0, completed=True),
            ],
            average_rpe=8.0,
            estimated_1rm=100.0,  # Stagnant 1RM
            total_reps=33,
            total_volume=2640.0,
        )

        # Create plateau history (4 identical performances)
        history = [plateau_performance] * 4

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=plateau_performance,
            performance_history=history,
        )

        # Wave loading adds 2 reps but should cap at 12
        if recommendation.strategy == ProgressionStrategy.WAVE:
            assert recommendation.recommended_reps <= 12, \
                f"Wave loading should cap at 12 reps for compound, got {recommendation.recommended_reps}"

    def test_rep_ceiling_message_when_forced_increase(self, progression_service):
        """
        Test that reason message mentions ceiling when weight is forced up.
        """
        # Performance at ceiling
        performance = ExercisePerformance(
            exercise_id="deadlift",
            exercise_name="Deadlift",
            target_sets=3,
            target_reps=12,  # At compound ceiling
            sets=[
                SetPerformance(set_number=1, weight_kg=100.0, reps_completed=11, rpe=8.0, completed=True),  # Missed target
                SetPerformance(set_number=2, weight_kg=100.0, reps_completed=10, rpe=8.5, completed=True),
                SetPerformance(set_number=3, weight_kg=100.0, reps_completed=10, rpe=9.0, completed=True),
            ],
            average_rpe=8.5,  # Triggers DOUBLE_PROGRESSION
            estimated_1rm=140.0,
            total_reps=31,
            total_volume=3100.0,
        )

        recommendation = progression_service.get_recommendation(
            exercise_id="deadlift",
            exercise_name="Deadlift",
            last_performance=performance,
            performance_history=[performance],
        )

        # If we're at ceiling and force weight increase, reason should mention it
        if recommendation.recommended_weight_kg > 100.0:
            assert "ceiling" in recommendation.reason.lower() or "increase weight" in recommendation.reason.lower(), \
                f"Reason should mention ceiling, got: {recommendation.reason}"

    def test_bodyweight_exercise_allows_higher_reps(self, progression_service):
        """
        Test bodyweight exercises (push-ups) allow up to 20 reps.
        """
        performance = ExercisePerformance(
            exercise_id="pushup",
            exercise_name="Push-ups",  # Bodyweight exercise
            target_sets=3,
            target_reps=18,  # High reps OK for bodyweight
            sets=[
                SetPerformance(set_number=1, weight_kg=0, reps_completed=18, rpe=8.0, completed=True),
                SetPerformance(set_number=2, weight_kg=0, reps_completed=17, rpe=8.5, completed=True),
                SetPerformance(set_number=3, weight_kg=0, reps_completed=16, rpe=9.0, completed=True),
            ],
            average_rpe=8.5,  # Triggers DOUBLE_PROGRESSION
            estimated_1rm=0,
            total_reps=51,
            total_volume=0,
        )

        recommendation = progression_service.get_recommendation(
            exercise_id="pushup",
            exercise_name="Push-ups",
            last_performance=performance,
            performance_history=[performance],
        )

        # Bodyweight can go up to 20 reps (higher ceiling)
        assert recommendation.recommended_reps <= 20, \
            f"Bodyweight exercise should cap at 20 reps, got {recommendation.recommended_reps}"


# ============================================================
# PROGRESSION PACE TESTS
# ============================================================

class TestProgressionPace:
    """
    Test pace-aware progression to address competitor feedback:
    'going up 10 or 15 pounds every week is not what I want'

    Users can now choose:
    - slow: same weight for 3-4 weeks before increase
    - medium: increase every 1-2 weeks
    - fast: increase every session when ready
    """

    def test_slow_pace_requires_4_ready_sessions(self, progression_service):
        """
        Test that slow pace requires 4 consecutive ready sessions before
        recommending weight increase.
        """
        # Create 3 ready performances (not enough for slow pace)
        ready_perf = ExercisePerformance(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, rpe=7.0, completed=True),
                SetPerformance(set_number=2, weight_kg=80.0, reps_completed=8, rpe=7.0, completed=True),
                SetPerformance(set_number=3, weight_kg=80.0, reps_completed=8, rpe=7.0, completed=True),
            ],
            average_rpe=7.0,  # Below 7.5 = ready to progress
            estimated_1rm=100.0,
            total_reps=24,
            total_volume=1920.0,
        )

        # Only 3 ready sessions - should NOT progress with slow pace
        history = [ready_perf, ready_perf, ready_perf]

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=ready_perf,
            performance_history=history,
            progression_pace="slow",
        )

        # Should use DOUBLE_PROGRESSION (not LINEAR) because not enough sessions
        assert recommendation.strategy == ProgressionStrategy.DOUBLE_PROGRESSION, \
            f"Expected DOUBLE_PROGRESSION with only 3 ready sessions, got {recommendation.strategy}"
        assert "3/4" in recommendation.reason or "consistency" in recommendation.reason.lower(), \
            f"Reason should mention progress toward threshold, got: {recommendation.reason}"

    def test_slow_pace_progresses_after_4_ready_sessions(self, progression_service):
        """
        Test that slow pace DOES progress after 4 consecutive ready sessions.
        """
        # Create 4 different performances to avoid plateau detection
        # (plateau = < 3% 1RM variance over 4 sessions)
        history = []
        for i in range(4):
            perf = ExercisePerformance(
                exercise_id="bench_press",
                exercise_name="Barbell Bench Press",  # Use barbell to avoid dumbbell snapping
                target_sets=3,
                target_reps=8,
                sets=[
                    SetPerformance(set_number=1, weight_kg=80.0 + i, reps_completed=8, rpe=7.0, completed=True),
                    SetPerformance(set_number=2, weight_kg=80.0 + i, reps_completed=8, rpe=7.0, completed=True),
                    SetPerformance(set_number=3, weight_kg=80.0 + i, reps_completed=8, rpe=7.0, completed=True),
                ],
            )
            history.append(perf)

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Barbell Bench Press",
            last_performance=history[-1],
            performance_history=history,
            progression_pace="slow",
        )

        # Should use LINEAR (weight increase) - not WAVE (plateau would trigger WAVE)
        assert recommendation.strategy == ProgressionStrategy.LINEAR, \
            f"Expected LINEAR progression after 4 ready sessions, got {recommendation.strategy}"
        assert recommendation.recommended_weight_kg > 83.0, \
            f"Should increase weight after threshold met, got {recommendation.recommended_weight_kg}"

    def test_medium_pace_requires_2_ready_sessions(self, progression_service):
        """
        Test that medium pace requires 2 consecutive ready sessions.
        """
        ready_perf = ExercisePerformance(
            exercise_id="squat",
            exercise_name="Squat",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=100.0, reps_completed=8, rpe=7.0, completed=True),
                SetPerformance(set_number=2, weight_kg=100.0, reps_completed=8, rpe=7.0, completed=True),
                SetPerformance(set_number=3, weight_kg=100.0, reps_completed=8, rpe=7.0, completed=True),
            ],
            average_rpe=7.0,
            estimated_1rm=125.0,
            total_reps=24,
            total_volume=2400.0,
        )

        # Only 1 ready session - should NOT progress with medium pace
        history = [ready_perf]

        recommendation = progression_service.get_recommendation(
            exercise_id="squat",
            exercise_name="Squat",
            last_performance=ready_perf,
            performance_history=history,
            progression_pace="medium",
        )

        assert recommendation.strategy == ProgressionStrategy.DOUBLE_PROGRESSION, \
            f"Expected DOUBLE_PROGRESSION with only 1 ready session, got {recommendation.strategy}"

    def test_medium_pace_progresses_after_2_ready_sessions(self, progression_service):
        """
        Test that medium pace progresses after 2 consecutive ready sessions.
        """
        ready_perf = ExercisePerformance(
            exercise_id="squat",
            exercise_name="Squat",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=100.0, reps_completed=8, rpe=7.0, completed=True),
                SetPerformance(set_number=2, weight_kg=100.0, reps_completed=8, rpe=7.0, completed=True),
                SetPerformance(set_number=3, weight_kg=100.0, reps_completed=8, rpe=7.0, completed=True),
            ],
            average_rpe=7.0,
            estimated_1rm=125.0,
            total_reps=24,
            total_volume=2400.0,
        )

        # 2 ready sessions - SHOULD progress
        history = [ready_perf, ready_perf]

        recommendation = progression_service.get_recommendation(
            exercise_id="squat",
            exercise_name="Squat",
            last_performance=ready_perf,
            performance_history=history,
            progression_pace="medium",
        )

        assert recommendation.strategy == ProgressionStrategy.LINEAR, \
            f"Expected LINEAR progression after 2 ready sessions, got {recommendation.strategy}"

    def test_fast_pace_progresses_immediately(self, progression_service):
        """
        Test that fast pace progresses after just 1 ready session (original behavior).
        """
        ready_perf = ExercisePerformance(
            exercise_id="deadlift",
            exercise_name="Barbell Deadlift",  # Use barbell to avoid dumbbell weight snapping
            target_sets=3,
            target_reps=5,
            sets=[
                SetPerformance(set_number=1, weight_kg=120.0, reps_completed=5, rpe=7.0, completed=True),
                SetPerformance(set_number=2, weight_kg=120.0, reps_completed=5, rpe=7.0, completed=True),
                SetPerformance(set_number=3, weight_kg=120.0, reps_completed=5, rpe=7.0, completed=True),
            ],
        )

        # Just 1 ready session - SHOULD progress with fast pace
        history = [ready_perf]

        recommendation = progression_service.get_recommendation(
            exercise_id="deadlift",
            exercise_name="Barbell Deadlift",
            last_performance=ready_perf,
            performance_history=history,
            progression_pace="fast",
        )

        assert recommendation.strategy == ProgressionStrategy.LINEAR, \
            f"Expected LINEAR progression with fast pace after 1 session, got {recommendation.strategy}"
        assert recommendation.recommended_weight_kg > 120.0, \
            f"Fast pace should increase weight immediately, got {recommendation.recommended_weight_kg}"

    def test_pace_counter_resets_on_not_ready_session(self, progression_service):
        """
        Test that consecutive ready counter resets when a non-ready session occurs.
        """
        ready_perf = ExercisePerformance(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, rpe=7.0, completed=True),
                SetPerformance(set_number=2, weight_kg=80.0, reps_completed=8, rpe=7.0, completed=True),
                SetPerformance(set_number=3, weight_kg=80.0, reps_completed=8, rpe=7.0, completed=True),
            ],
            average_rpe=7.0,  # Ready
            estimated_1rm=100.0,
            total_reps=24,
            total_volume=1920.0,
        )

        not_ready_perf = ExercisePerformance(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            target_sets=3,
            target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=80.0, reps_completed=7, rpe=8.5, completed=True),
                SetPerformance(set_number=2, weight_kg=80.0, reps_completed=6, rpe=9.0, completed=True),
                SetPerformance(set_number=3, weight_kg=80.0, reps_completed=6, rpe=9.0, completed=True),
            ],
            average_rpe=8.5,  # Above 7.5 = NOT ready
            estimated_1rm=95.0,
            total_reps=19,
            total_volume=1520.0,
        )

        # 2 ready, then 1 not-ready, then 1 ready = only 1 consecutive ready
        history = [ready_perf, ready_perf, not_ready_perf, ready_perf]

        recommendation = progression_service.get_recommendation(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            last_performance=ready_perf,
            performance_history=history,
            progression_pace="medium",  # Requires 2 consecutive
        )

        # Should NOT progress because consecutive count reset
        assert recommendation.strategy == ProgressionStrategy.DOUBLE_PROGRESSION, \
            "Counter should reset after not-ready session"

    def test_count_consecutive_ready_sessions_helper(self, progression_service):
        """Test the helper function counts correctly."""
        # average_rpe is computed from sets, so we need to provide sets with rpe values
        ready_perf = ExercisePerformance(
            exercise_id="test", exercise_name="Test",
            target_sets=3, target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=50.0, reps_completed=8, rpe=7.0, completed=True),
            ],  # avg RPE = 7.0 (ready)
        )

        not_ready_perf = ExercisePerformance(
            exercise_id="test", exercise_name="Test",
            target_sets=3, target_reps=8,
            sets=[
                SetPerformance(set_number=1, weight_kg=50.0, reps_completed=8, rpe=8.0, completed=True),
            ],  # avg RPE = 8.0 (not ready)
        )

        # 3 ready sessions from most recent
        history = [not_ready_perf, ready_perf, ready_perf, ready_perf]
        count = progression_service._count_consecutive_ready_sessions(history)
        assert count == 3, f"Expected 3 consecutive ready, got {count}"

        # Empty history
        count = progression_service._count_consecutive_ready_sessions([])
        assert count == 0, "Empty history should return 0"

        # All not ready
        history = [not_ready_perf, not_ready_perf]
        count = progression_service._count_consecutive_ready_sessions(history)
        assert count == 0, f"Expected 0 ready sessions, got {count}"

    def test_pace_thresholds_exist(self):
        """Test that pace thresholds are properly defined."""
        assert "slow" in PROGRESSION_PACE_THRESHOLDS
        assert "medium" in PROGRESSION_PACE_THRESHOLDS
        assert "fast" in PROGRESSION_PACE_THRESHOLDS
        assert PROGRESSION_PACE_THRESHOLDS["slow"] > PROGRESSION_PACE_THRESHOLDS["medium"]
        assert PROGRESSION_PACE_THRESHOLDS["medium"] > PROGRESSION_PACE_THRESHOLDS["fast"]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
