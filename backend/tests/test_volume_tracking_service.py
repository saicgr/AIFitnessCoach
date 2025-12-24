"""
Tests for Volume Tracking Service.

Tests:
- Weekly volume calculation per muscle group
- Recovery status determination
- Undertrained/overtrained muscle detection

Run with: pytest backend/tests/test_volume_tracking_service.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, timedelta

from services.volume_tracking_service import VolumeTrackingService
from models.performance import (
    WorkoutPerformance, ExercisePerformance,
    MuscleGroupVolume, SetPerformance
)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def volume_service():
    return VolumeTrackingService()


@pytest.fixture
def sample_workout_performances():
    """Create sample workout performances for testing."""
    today = datetime.now()

    # Day 1: Chest & Back
    workout1 = WorkoutPerformance(
        workout_id=1,
        user_id=100,
        workout_name="Push Day",
        scheduled_date=today - timedelta(days=2),
        exercises=[
            ExercisePerformance(
                exercise_id="bench_press",
                exercise_name="Bench Press",
                target_sets=4,
                target_reps=8,
                sets=[
                    SetPerformance(set_number=1, weight_kg=80.0, reps_completed=8, completed=True),
                    SetPerformance(set_number=2, weight_kg=80.0, reps_completed=8, completed=True),
                    SetPerformance(set_number=3, weight_kg=80.0, reps_completed=7, completed=True),
                    SetPerformance(set_number=4, weight_kg=80.0, reps_completed=6, completed=True),
                ],
                total_reps=29,
                total_volume=2320.0,
            ),
        ],
        total_volume=2320.0,
        completion_rate=100,
    )

    # Day 2: Legs
    workout2 = WorkoutPerformance(
        workout_id=2,
        user_id=100,
        workout_name="Leg Day",
        scheduled_date=today - timedelta(days=1),
        exercises=[
            ExercisePerformance(
                exercise_id="squat",
                exercise_name="Squat",
                target_sets=4,
                target_reps=6,
                sets=[
                    SetPerformance(set_number=1, weight_kg=100.0, reps_completed=6, completed=True),
                    SetPerformance(set_number=2, weight_kg=100.0, reps_completed=6, completed=True),
                    SetPerformance(set_number=3, weight_kg=100.0, reps_completed=5, completed=True),
                    SetPerformance(set_number=4, weight_kg=100.0, reps_completed=5, completed=True),
                ],
                total_reps=22,
                total_volume=2200.0,
            ),
            ExercisePerformance(
                exercise_id="leg_press",
                exercise_name="Leg Press",
                target_sets=3,
                target_reps=12,
                sets=[
                    SetPerformance(set_number=1, weight_kg=150.0, reps_completed=12, completed=True),
                    SetPerformance(set_number=2, weight_kg=150.0, reps_completed=10, completed=True),
                    SetPerformance(set_number=3, weight_kg=150.0, reps_completed=10, completed=True),
                ],
                total_reps=32,
                total_volume=4800.0,
            ),
        ],
        total_volume=7000.0,
        completion_rate=100,
    )

    return [workout1, workout2]


# ============================================================
# CALCULATE WEEKLY VOLUME TESTS
# ============================================================

class TestCalculateWeeklyVolume:
    """Test weekly volume calculation."""

    @patch('services.volume_tracking_service.get_muscle_groups')
    @patch('services.volume_tracking_service.get_target_sets')
    @patch('services.volume_tracking_service.get_recovery_status')
    def test_calculate_weekly_volume_structure(
        self, mock_recovery, mock_target, mock_muscles, volume_service, sample_workout_performances
    ):
        """Test volume calculation returns correct structure."""
        mock_muscles.side_effect = lambda name: ["chest"] if "Bench" in name else ["quadriceps"]
        mock_target.return_value = 15
        mock_recovery.return_value = "recovered"

        volumes = volume_service.calculate_weekly_volume(sample_workout_performances)

        assert isinstance(volumes, list)
        assert all(isinstance(v, MuscleGroupVolume) for v in volumes)

    @patch('services.volume_tracking_service.get_muscle_groups')
    @patch('services.volume_tracking_service.get_target_sets')
    @patch('services.volume_tracking_service.get_recovery_status')
    def test_calculate_weekly_volume_aggregates_sets(
        self, mock_recovery, mock_target, mock_muscles, volume_service, sample_workout_performances
    ):
        """Test sets are correctly aggregated per muscle."""
        mock_muscles.side_effect = lambda name: ["chest"] if "Bench" in name else ["quadriceps"]
        mock_target.return_value = 15
        mock_recovery.return_value = "recovered"

        volumes = volume_service.calculate_weekly_volume(sample_workout_performances)

        # Find chest volume
        chest_volume = next((v for v in volumes if v.muscle_group == "chest"), None)
        assert chest_volume is not None
        assert chest_volume.total_sets == 4  # 4 sets of bench press

    @patch('services.volume_tracking_service.get_muscle_groups')
    @patch('services.volume_tracking_service.get_target_sets')
    @patch('services.volume_tracking_service.get_recovery_status')
    def test_calculate_weekly_volume_aggregates_reps(
        self, mock_recovery, mock_target, mock_muscles, volume_service, sample_workout_performances
    ):
        """Test reps are correctly aggregated per muscle."""
        mock_muscles.side_effect = lambda name: ["chest"] if "Bench" in name else ["quadriceps"]
        mock_target.return_value = 15
        mock_recovery.return_value = "recovered"

        volumes = volume_service.calculate_weekly_volume(sample_workout_performances)

        chest_volume = next((v for v in volumes if v.muscle_group == "chest"), None)
        assert chest_volume is not None
        assert chest_volume.total_reps == 29  # 8 + 8 + 7 + 6

    @patch('services.volume_tracking_service.get_muscle_groups')
    @patch('services.volume_tracking_service.get_target_sets')
    @patch('services.volume_tracking_service.get_recovery_status')
    def test_calculate_weekly_volume_aggregates_volume(
        self, mock_recovery, mock_target, mock_muscles, volume_service, sample_workout_performances
    ):
        """Test volume is correctly aggregated per muscle."""
        mock_muscles.side_effect = lambda name: ["chest"] if "Bench" in name else ["quadriceps"]
        mock_target.return_value = 15
        mock_recovery.return_value = "recovered"

        volumes = volume_service.calculate_weekly_volume(sample_workout_performances)

        chest_volume = next((v for v in volumes if v.muscle_group == "chest"), None)
        assert chest_volume is not None
        assert chest_volume.total_volume_kg == 2320.0

    @patch('services.volume_tracking_service.get_muscle_groups')
    @patch('services.volume_tracking_service.get_target_sets')
    @patch('services.volume_tracking_service.get_recovery_status')
    def test_calculate_weekly_volume_tracks_frequency(
        self, mock_recovery, mock_target, mock_muscles, volume_service
    ):
        """Test training frequency is correctly tracked."""
        today = datetime.now()

        # Same muscle trained on 3 different days
        workouts = []
        for i in range(3):
            workout = WorkoutPerformance(
                workout_id=i,
                user_id=100,
                workout_name=f"Workout {i}",
                scheduled_date=today - timedelta(days=i),
                exercises=[
                    ExercisePerformance(
                        exercise_id="bench_press",
                        exercise_name="Bench Press",
                        target_sets=3,
                        target_reps=10,
                        sets=[SetPerformance(set_number=1, weight_kg=80.0, reps_completed=10, completed=True)],
                        total_reps=10,
                        total_volume=800.0,
                    ),
                ],
                total_volume=800.0,
                completion_rate=100,
            )
            workouts.append(workout)

        mock_muscles.return_value = ["chest"]
        mock_target.return_value = 15
        mock_recovery.return_value = "recovered"

        volumes = volume_service.calculate_weekly_volume(workouts)

        chest_volume = next((v for v in volumes if v.muscle_group == "chest"), None)
        assert chest_volume is not None
        assert chest_volume.frequency == 3

    @patch('services.volume_tracking_service.get_muscle_groups')
    @patch('services.volume_tracking_service.get_target_sets')
    @patch('services.volume_tracking_service.get_recovery_status')
    def test_calculate_weekly_volume_empty_workouts(
        self, mock_recovery, mock_target, mock_muscles, volume_service
    ):
        """Test handling empty workout list."""
        volumes = volume_service.calculate_weekly_volume([])
        assert volumes == []

    @patch('services.volume_tracking_service.get_muscle_groups')
    @patch('services.volume_tracking_service.get_target_sets')
    @patch('services.volume_tracking_service.get_recovery_status')
    def test_calculate_weekly_volume_multiple_exercises_same_muscle(
        self, mock_recovery, mock_target, mock_muscles, volume_service
    ):
        """Test multiple exercises for same muscle are aggregated."""
        today = datetime.now()

        workout = WorkoutPerformance(
            workout_id=1,
            user_id=100,
            workout_name="Chest Day",
            scheduled_date=today,
            exercises=[
                ExercisePerformance(
                    exercise_id="bench_press",
                    exercise_name="Bench Press",
                    target_sets=3,
                    target_reps=10,
                    sets=[
                        SetPerformance(set_number=1, weight_kg=80.0, reps_completed=10, completed=True),
                        SetPerformance(set_number=2, weight_kg=80.0, reps_completed=10, completed=True),
                        SetPerformance(set_number=3, weight_kg=80.0, reps_completed=10, completed=True),
                    ],
                    total_reps=30,
                    total_volume=2400.0,
                ),
                ExercisePerformance(
                    exercise_id="incline_press",
                    exercise_name="Incline Press",
                    target_sets=3,
                    target_reps=10,
                    sets=[
                        SetPerformance(set_number=1, weight_kg=60.0, reps_completed=10, completed=True),
                        SetPerformance(set_number=2, weight_kg=60.0, reps_completed=10, completed=True),
                        SetPerformance(set_number=3, weight_kg=60.0, reps_completed=10, completed=True),
                    ],
                    total_reps=30,
                    total_volume=1800.0,
                ),
            ],
            total_volume=4200.0,
            completion_rate=100,
        )

        mock_muscles.return_value = ["chest"]  # Both exercises target chest
        mock_target.return_value = 15
        mock_recovery.return_value = "recovered"

        volumes = volume_service.calculate_weekly_volume([workout])

        chest_volume = next((v for v in volumes if v.muscle_group == "chest"), None)
        assert chest_volume is not None
        assert chest_volume.total_sets == 6  # 3 + 3
        assert chest_volume.total_reps == 60  # 30 + 30
        assert chest_volume.total_volume_kg == 4200.0


# ============================================================
# GET UNDERTRAINED MUSCLES TESTS
# ============================================================

class TestGetUndertrainedMuscles:
    """Test undertrained muscle detection."""

    def test_get_undertrained_muscles_none(self, volume_service):
        """Test when no muscles are undertrained."""
        volumes = [
            MuscleGroupVolume(
                muscle_group="chest",
                total_sets=15,
                total_reps=120,
                total_volume_kg=3000.0,
                frequency=2,
                target_sets=15,
                recovery_status="recovered"
            ),
            MuscleGroupVolume(
                muscle_group="back",
                total_sets=18,
                total_reps=150,
                total_volume_kg=4000.0,
                frequency=2,
                target_sets=15,
                recovery_status="recovered"
            ),
        ]

        undertrained = volume_service.get_undertrained_muscles(volumes)
        assert undertrained == []

    def test_get_undertrained_muscles_some(self, volume_service):
        """Test detecting undertrained muscles."""
        volumes = [
            MuscleGroupVolume(
                muscle_group="chest",
                total_sets=5,
                total_reps=40,
                total_volume_kg=1000.0,
                frequency=1,
                target_sets=15,
                recovery_status="undertrained"
            ),
            MuscleGroupVolume(
                muscle_group="back",
                total_sets=18,
                total_reps=150,
                total_volume_kg=4000.0,
                frequency=2,
                target_sets=15,
                recovery_status="recovered"
            ),
        ]

        undertrained = volume_service.get_undertrained_muscles(volumes)
        assert len(undertrained) == 1
        assert undertrained[0].muscle_group == "chest"

    def test_get_undertrained_muscles_all(self, volume_service):
        """Test when all muscles are undertrained."""
        volumes = [
            MuscleGroupVolume(
                muscle_group="chest",
                total_sets=3,
                total_reps=24,
                total_volume_kg=600.0,
                frequency=1,
                target_sets=15,
                recovery_status="undertrained"
            ),
            MuscleGroupVolume(
                muscle_group="back",
                total_sets=4,
                total_reps=32,
                total_volume_kg=800.0,
                frequency=1,
                target_sets=15,
                recovery_status="undertrained"
            ),
        ]

        undertrained = volume_service.get_undertrained_muscles(volumes)
        assert len(undertrained) == 2


# ============================================================
# GET OVERTRAINED MUSCLES TESTS
# ============================================================

class TestGetOvertrainedMuscles:
    """Test overtrained muscle detection."""

    def test_get_overtrained_muscles_none(self, volume_service):
        """Test when no muscles are overtrained."""
        volumes = [
            MuscleGroupVolume(
                muscle_group="chest",
                total_sets=15,
                total_reps=120,
                total_volume_kg=3000.0,
                frequency=2,
                target_sets=15,
                recovery_status="recovered"
            ),
        ]

        overtrained = volume_service.get_overtrained_muscles(volumes)
        assert overtrained == []

    def test_get_overtrained_muscles_some(self, volume_service):
        """Test detecting overtrained muscles."""
        volumes = [
            MuscleGroupVolume(
                muscle_group="chest",
                total_sets=30,
                total_reps=300,
                total_volume_kg=8000.0,
                frequency=5,
                target_sets=15,
                recovery_status="overtrained"
            ),
            MuscleGroupVolume(
                muscle_group="back",
                total_sets=15,
                total_reps=120,
                total_volume_kg=3000.0,
                frequency=2,
                target_sets=15,
                recovery_status="recovered"
            ),
        ]

        overtrained = volume_service.get_overtrained_muscles(volumes)
        assert len(overtrained) == 1
        assert overtrained[0].muscle_group == "chest"

    def test_get_overtrained_muscles_multiple(self, volume_service):
        """Test detecting multiple overtrained muscles."""
        volumes = [
            MuscleGroupVolume(
                muscle_group="chest",
                total_sets=30,
                total_reps=300,
                total_volume_kg=8000.0,
                frequency=5,
                target_sets=15,
                recovery_status="overtrained"
            ),
            MuscleGroupVolume(
                muscle_group="shoulders",
                total_sets=25,
                total_reps=250,
                total_volume_kg=5000.0,
                frequency=4,
                target_sets=12,
                recovery_status="overtrained"
            ),
        ]

        overtrained = volume_service.get_overtrained_muscles(volumes)
        assert len(overtrained) == 2


# ============================================================
# MUSCLE GROUP VOLUME MODEL TESTS
# ============================================================

class TestMuscleGroupVolumeModel:
    """Test MuscleGroupVolume model."""

    def test_muscle_group_volume_creation(self):
        """Test creating MuscleGroupVolume."""
        volume = MuscleGroupVolume(
            muscle_group="chest",
            total_sets=12,
            total_reps=96,
            total_volume_kg=2400.0,
            frequency=2,
            target_sets=15,
            recovery_status="recovered"
        )

        assert volume.muscle_group == "chest"
        assert volume.total_sets == 12
        assert volume.total_reps == 96
        assert volume.total_volume_kg == 2400.0
        assert volume.frequency == 2
        assert volume.target_sets == 15
        assert volume.recovery_status == "recovered"


# ============================================================
# INTEGRATION TESTS
# ============================================================

class TestVolumeTrackingIntegration:
    """Integration tests for volume tracking."""

    @patch('services.volume_tracking_service.get_muscle_groups')
    @patch('services.volume_tracking_service.get_target_sets')
    @patch('services.volume_tracking_service.get_recovery_status')
    def test_full_week_analysis(
        self, mock_recovery, mock_target, mock_muscles, volume_service
    ):
        """Test analyzing a full week of workouts."""
        today = datetime.now()

        # Create a week's worth of workouts
        workouts = []

        # Monday: Chest
        workouts.append(WorkoutPerformance(
            workout_id=1, user_id=100, workout_name="Chest Day",
            scheduled_date=today - timedelta(days=6),
            exercises=[
                ExercisePerformance(
                    exercise_id="bench", exercise_name="Bench Press",
                    target_sets=4, target_reps=8,
                    sets=[SetPerformance(set_number=i, weight_kg=80.0, reps_completed=8, completed=True) for i in range(1, 5)],
                    total_reps=32, total_volume_kg=2560.0,
                ),
            ],
            total_volume=2560.0, completion_rate=100,
        ))

        # Wednesday: Back
        workouts.append(WorkoutPerformance(
            workout_id=2, user_id=100, workout_name="Back Day",
            scheduled_date=today - timedelta(days=4),
            exercises=[
                ExercisePerformance(
                    exercise_id="rows", exercise_name="Rows",
                    target_sets=4, target_reps=10,
                    sets=[SetPerformance(set_number=i, weight_kg=70.0, reps_completed=10, completed=True) for i in range(1, 5)],
                    total_reps=40, total_volume_kg=2800.0,
                ),
            ],
            total_volume=2800.0, completion_rate=100,
        ))

        # Friday: Legs
        workouts.append(WorkoutPerformance(
            workout_id=3, user_id=100, workout_name="Leg Day",
            scheduled_date=today - timedelta(days=2),
            exercises=[
                ExercisePerformance(
                    exercise_id="squat", exercise_name="Squat",
                    target_sets=4, target_reps=6,
                    sets=[SetPerformance(set_number=i, weight_kg=100.0, reps_completed=6, completed=True) for i in range(1, 5)],
                    total_reps=24, total_volume_kg=2400.0,
                ),
            ],
            total_volume=2400.0, completion_rate=100,
        ))

        # Setup mocks
        def get_muscles(name):
            if "Bench" in name:
                return ["chest"]
            elif "Row" in name:
                return ["back"]
            else:
                return ["quadriceps"]

        mock_muscles.side_effect = get_muscles
        mock_target.return_value = 15
        mock_recovery.side_effect = lambda muscle, sets: "undertrained" if sets < 10 else "recovered"

        volumes = volume_service.calculate_weekly_volume(workouts)

        assert len(volumes) == 3  # chest, back, quadriceps

        # All should be undertrained (only 4 sets each)
        undertrained = volume_service.get_undertrained_muscles(volumes)
        assert len(undertrained) == 3

        overtrained = volume_service.get_overtrained_muscles(volumes)
        assert len(overtrained) == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
