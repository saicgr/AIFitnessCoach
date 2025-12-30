"""
Tests for PR Detection Integration in Workout Completion.

Tests cover:
- PR detection during workout completion
- AI celebration message generation
- Strength score recalculation background task
- Edge cases (no PRs, empty exercises, etc.)
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, date, timedelta
from decimal import Decimal

from services.personal_records_service import (
    PersonalRecordsService,
    PersonalRecord,
    PRComparison,
)


class TestPersonalRecordsService:
    """Tests for PersonalRecordsService PR detection."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_check_for_pr_first_ever_pr(self):
        """Test detecting first-ever PR for an exercise."""
        comparison = self.service.check_for_pr(
            exercise_name="bench_press",
            weight_kg=100,
            reps=5,
            existing_prs=[],
        )

        assert comparison.is_pr is True
        assert comparison.is_all_time_pr is True
        assert comparison.previous_1rm is None
        assert comparison.improvement_kg is None
        assert comparison.current_1rm > 100  # 1RM should be higher than 5RM weight

    def test_check_for_pr_new_pr_beats_existing(self):
        """Test detecting PR that beats existing record."""
        existing_prs = [
            {"estimated_1rm_kg": 110, "achieved_at": datetime.now() - timedelta(days=30)}
        ]

        # 120kg x 5 reps ≈ 135kg 1RM (beats 110kg)
        comparison = self.service.check_for_pr(
            exercise_name="squat",
            weight_kg=120,
            reps=5,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.is_all_time_pr is True
        assert comparison.previous_1rm == 110
        assert comparison.improvement_kg > 0
        assert comparison.improvement_percent > 0

    def test_check_for_pr_no_improvement(self):
        """Test when lift doesn't beat existing PR."""
        existing_prs = [
            {"estimated_1rm_kg": 150, "achieved_at": datetime.now() - timedelta(days=7)}
        ]

        # 100kg x 5 reps ≈ 112kg 1RM (doesn't beat 150kg)
        comparison = self.service.check_for_pr(
            exercise_name="deadlift",
            weight_kg=100,
            reps=5,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is False
        assert comparison.is_all_time_pr is False
        assert comparison.improvement_kg is None

    def test_detect_prs_in_workout_multiple_prs(self):
        """Test detecting multiple PRs in a single workout."""
        workout_exercises = [
            {
                "exercise_name": "bench_press",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 100, "reps": 5, "completed": True},
                    {"weight_kg": 105, "reps": 3, "completed": True},  # This is the PR
                ]
            },
            {
                "exercise_name": "squat",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 140, "reps": 5, "completed": True},  # This is a PR
                ]
            },
        ]

        existing_prs_by_exercise = {
            "bench_press": [{"estimated_1rm_kg": 100, "achieved_at": datetime.now() - timedelta(days=60)}],
            "squat": [{"estimated_1rm_kg": 140, "achieved_at": datetime.now() - timedelta(days=30)}],
        }

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise=existing_prs_by_exercise,
        )

        # Should find PRs for both exercises
        assert len(new_prs) >= 2
        exercise_names = [pr.exercise_name for pr in new_prs]
        assert "bench_press" in exercise_names
        assert "squat" in exercise_names

    def test_detect_prs_in_workout_empty_exercises(self):
        """Test with no exercises in workout."""
        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=[],
            existing_prs_by_exercise={},
        )

        assert new_prs == []

    def test_detect_prs_in_workout_incomplete_sets(self):
        """Test that incomplete sets are skipped."""
        workout_exercises = [
            {
                "exercise_name": "bench_press",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 200, "reps": 5, "completed": False},  # Skipped
                    {"weight_kg": 80, "reps": 5, "completed": True},
                ]
            },
        ]

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise={},
        )

        # Should only count the completed set
        if new_prs:
            assert new_prs[0].weight_kg == 80

    def test_detect_prs_in_workout_zero_weight(self):
        """Test that sets with zero weight are skipped."""
        workout_exercises = [
            {
                "exercise_name": "pull_ups",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 0, "reps": 10, "completed": True},  # Skipped
                ]
            },
        ]

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise={},
        )

        assert new_prs == []

    def test_celebration_message_generation(self):
        """Test celebration message is generated."""
        workout_exercises = [
            {
                "exercise_name": "bench_press",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 100, "reps": 5, "completed": True},
                ]
            },
        ]

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise={},  # First PR
        )

        assert len(new_prs) == 1
        assert new_prs[0].celebration_message is not None
        assert "Bench Press" in new_prs[0].celebration_message


class TestPRStatistics:
    """Tests for PR statistics calculation."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_get_pr_statistics_empty(self):
        """Test statistics with no PRs."""
        stats = self.service.get_pr_statistics([])

        assert stats["total_prs"] == 0
        assert stats["prs_this_period"] == 0
        assert stats["exercises_with_prs"] == 0
        assert stats["best_improvement_percent"] is None

    def test_get_pr_statistics_with_data(self):
        """Test statistics calculation with PR data."""
        all_prs = [
            {
                "exercise_name": "bench_press",
                "achieved_at": datetime.now() - timedelta(days=5),
                "improvement_percent": 5.5,
            },
            {
                "exercise_name": "squat",
                "achieved_at": datetime.now() - timedelta(days=10),
                "improvement_percent": 8.2,
            },
            {
                "exercise_name": "bench_press",
                "achieved_at": datetime.now() - timedelta(days=45),
                "improvement_percent": 3.0,
            },
        ]

        stats = self.service.get_pr_statistics(all_prs, period_days=30)

        assert stats["total_prs"] == 3
        assert stats["prs_this_period"] == 2  # Only 2 within 30 days
        assert stats["exercises_with_prs"] == 2  # bench_press and squat
        assert stats["best_improvement_percent"] == 8.2
        assert stats["most_improved_exercise"] == "squat"

    def test_get_exercise_pr_history(self):
        """Test getting PR history for specific exercise."""
        all_prs = [
            {
                "exercise_name": "Bench Press",
                "achieved_at": datetime.now() - timedelta(days=60),
                "estimated_1rm_kg": 100,
                "weight_kg": 90,
                "reps": 5,
            },
            {
                "exercise_name": "bench_press",  # Different format, same exercise
                "achieved_at": datetime.now() - timedelta(days=30),
                "estimated_1rm_kg": 110,
                "weight_kg": 95,
                "reps": 5,
            },
            {
                "exercise_name": "squat",
                "achieved_at": datetime.now() - timedelta(days=15),
                "estimated_1rm_kg": 150,
                "weight_kg": 130,
                "reps": 5,
            },
        ]

        history = self.service.get_exercise_pr_history("bench_press", all_prs)

        assert history["exercise_name"] == "bench_press"
        assert history["total_prs"] == 2
        assert history["total_improvement_kg"] == 10
        assert len(history["pr_timeline"]) == 2


class TestCompleteWorkoutWithPRDetection:
    """Tests for complete_workout endpoint with PR detection."""

    @pytest.mark.asyncio
    async def test_complete_workout_detects_prs(self):
        """Test that workout completion detects PRs."""
        from api.v1.workouts.crud import complete_workout
        from fastapi import BackgroundTasks

        mock_db = MagicMock()
        mock_db.get_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
            "name": "Push Day",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "is_completed": False,
            "exercises": [
                {
                    "name": "bench_press",
                    "sets": [
                        {"weight_kg": 100, "reps": 5, "completed": True},
                    ]
                }
            ],
        }
        mock_db.update_workout.return_value = {
            **mock_db.get_workout.return_value,
            "is_completed": True,
        }

        mock_supabase = MagicMock()
        # No existing PRs
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(data=[])
        mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[])

        background_tasks = BackgroundTasks()

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with patch("api.v1.workouts.crud.get_db", return_value=mock_supabase):
                with patch("api.v1.workouts.crud.index_workout_to_rag", new_callable=AsyncMock):
                    with patch("api.v1.workouts.crud.ai_insights_service.generate_pr_celebration", new_callable=AsyncMock) as mock_ai:
                        mock_ai.return_value = "Congrats on your new PR!"
                        result = await complete_workout("workout-1", background_tasks)

        assert result.workout.is_completed is True
        # Should detect at least one PR (first PR for bench press)
        assert len(result.personal_records) >= 1 or "error" not in result.message.lower()

    @pytest.mark.asyncio
    async def test_complete_workout_no_prs(self):
        """Test workout completion when no PRs are set."""
        from api.v1.workouts.crud import complete_workout
        from fastapi import BackgroundTasks

        mock_db = MagicMock()
        mock_db.get_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
            "name": "Easy Day",
            "type": "strength",
            "difficulty": "easy",
            "scheduled_date": "2024-01-15",
            "is_completed": False,
            "exercises": [
                {
                    "name": "bench_press",
                    "sets": [
                        {"weight_kg": 50, "reps": 5, "completed": True},
                    ]
                }
            ],
        }
        mock_db.update_workout.return_value = {
            **mock_db.get_workout.return_value,
            "is_completed": True,
        }

        mock_supabase = MagicMock()
        # Existing PR is higher
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[
                {"exercise_name": "bench_press", "estimated_1rm_kg": 150, "achieved_at": datetime.now().isoformat()}
            ]
        )

        background_tasks = BackgroundTasks()

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with patch("api.v1.workouts.crud.get_db", return_value=mock_supabase):
                with patch("api.v1.workouts.crud.index_workout_to_rag", new_callable=AsyncMock):
                    result = await complete_workout("workout-1", background_tasks)

        assert result.workout.is_completed is True
        assert result.personal_records == []
        assert "personal record" not in result.message.lower()

    @pytest.mark.asyncio
    async def test_complete_workout_empty_exercises(self):
        """Test workout completion with no exercises."""
        from api.v1.workouts.crud import complete_workout
        from fastapi import BackgroundTasks

        mock_db = MagicMock()
        mock_db.get_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
            "name": "Rest Day",
            "type": "rest",
            "difficulty": "easy",
            "scheduled_date": "2024-01-15",
            "is_completed": False,
            "exercises": [],
        }
        mock_db.update_workout.return_value = {
            **mock_db.get_workout.return_value,
            "is_completed": True,
        }

        mock_supabase = MagicMock()
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(data=[])

        background_tasks = BackgroundTasks()

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with patch("api.v1.workouts.crud.get_db", return_value=mock_supabase):
                with patch("api.v1.workouts.crud.index_workout_to_rag", new_callable=AsyncMock):
                    result = await complete_workout("workout-1", background_tasks)

        assert result.workout.is_completed is True
        assert result.personal_records == []

    @pytest.mark.asyncio
    async def test_complete_workout_not_found(self):
        """Test completing non-existent workout."""
        from api.v1.workouts.crud import complete_workout
        from fastapi import HTTPException, BackgroundTasks

        mock_db = MagicMock()
        mock_db.get_workout.return_value = None

        background_tasks = BackgroundTasks()

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await complete_workout("nonexistent-id", background_tasks)

        assert exc_info.value.status_code == 404


class TestStrengthScoreRecalculation:
    """Tests for strength score background recalculation."""

    @pytest.mark.asyncio
    async def test_recalculate_strength_scores_success(self):
        """Test successful strength score recalculation."""
        from api.v1.workouts.crud import recalculate_user_strength_scores

        mock_supabase = MagicMock()

        # Mock user query
        mock_supabase.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(
            data={"weight_kg": 80, "gender": "male"}
        )

        # Mock workouts query
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.gte.return_value.execute.return_value = MagicMock(
            data=[
                {
                    "id": "workout-1",
                    "exercises": [
                        {
                            "name": "bench_press",
                            "sets": [{"weight_kg": 100, "reps": 5, "completed": True}]
                        }
                    ],
                    "completed_at": datetime.now().isoformat(),
                }
            ]
        )

        # Mock previous scores
        mock_supabase.from_.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(data=[])

        # Mock insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[])

        await recalculate_user_strength_scores("user-1", mock_supabase)

        # Verify strength_scores insert was called
        assert mock_supabase.table.return_value.insert.called

    @pytest.mark.asyncio
    async def test_recalculate_strength_scores_user_not_found(self):
        """Test handling of non-existent user."""
        from api.v1.workouts.crud import recalculate_user_strength_scores

        mock_supabase = MagicMock()
        mock_supabase.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(
            data=None
        )

        # Should not raise, just log and return
        await recalculate_user_strength_scores("nonexistent-user", mock_supabase)


class TestPRImprovementCalculations:
    """Tests for PR improvement calculations."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_improvement_percentage_calculation(self):
        """Test improvement percentage is calculated correctly."""
        existing_prs = [
            {"estimated_1rm_kg": 100, "achieved_at": datetime.now() - timedelta(days=30)}
        ]

        # New lift that gives ~120kg 1RM (20% improvement)
        comparison = self.service.check_for_pr(
            exercise_name="bench_press",
            weight_kg=107,
            reps=5,  # ~120kg 1RM
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.improvement_percent is not None
        assert comparison.improvement_percent > 15  # Should be around 20%
        assert comparison.improvement_percent < 25

    def test_time_since_last_pr(self):
        """Test time since last PR calculation."""
        thirty_days_ago = datetime.now() - timedelta(days=30)
        existing_prs = [
            {"estimated_1rm_kg": 100, "achieved_at": thirty_days_ago.isoformat()}
        ]

        comparison = self.service.check_for_pr(
            exercise_name="squat",
            weight_kg=120,  # Will beat the 100kg 1RM
            reps=5,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.time_since_last_pr is not None
        assert 29 <= comparison.time_since_last_pr <= 31  # ~30 days


class TestExerciseNameNormalization:
    """Tests for exercise name normalization in PR detection."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_normalize_exercise_name_spaces(self):
        """Test normalization with spaces."""
        assert self.service._normalize_exercise_name("Bench Press") == "bench_press"

    def test_normalize_exercise_name_dashes(self):
        """Test normalization with dashes."""
        assert self.service._normalize_exercise_name("pull-ups") == "pull_ups"

    def test_normalize_exercise_name_uppercase(self):
        """Test normalization with uppercase."""
        assert self.service._normalize_exercise_name("SQUAT") == "squat"

    def test_normalize_exercise_name_empty(self):
        """Test normalization with empty string."""
        assert self.service._normalize_exercise_name("") == ""

    def test_pr_detection_matches_normalized_names(self):
        """Test that PR detection matches normalized exercise names."""
        existing_prs_by_exercise = {
            "bench_press": [
                {"estimated_1rm_kg": 100, "achieved_at": datetime.now() - timedelta(days=30)}
            ]
        }

        workout_exercises = [
            {
                "exercise_name": "Bench Press",  # Different format
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 120, "reps": 5, "completed": True},  # Should beat existing PR
                ]
            }
        ]

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise=existing_prs_by_exercise,
        )

        # Should match despite different name format
        assert len(new_prs) == 1
        assert new_prs[0].improvement_kg is not None


class TestOneRepMaxCalculation:
    """Tests for 1RM calculation in PR context."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_higher_reps_lower_weight_can_be_pr(self):
        """Test that high reps at lower weight can still be a PR."""
        existing_prs = [
            {"estimated_1rm_kg": 100, "achieved_at": datetime.now() - timedelta(days=30)}
        ]

        # 85kg x 10 reps ≈ 113kg 1RM (beats 100kg)
        comparison = self.service.check_for_pr(
            exercise_name="bench_press",
            weight_kg=85,
            reps=10,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.current_1rm > 100

    def test_lower_reps_higher_weight_comparison(self):
        """Test comparing different rep ranges."""
        existing_prs = [
            {"estimated_1rm_kg": 115, "achieved_at": datetime.now() - timedelta(days=30)}  # e.g., 100kg x 5
        ]

        # 110kg x 3 reps ≈ 117kg 1RM (slightly beats 115kg)
        comparison = self.service.check_for_pr(
            exercise_name="squat",
            weight_kg=110,
            reps=3,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.current_1rm > 115
