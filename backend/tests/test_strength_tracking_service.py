"""
Tests for Strength Tracking Service.

Tests:
- Recording strength performances
- 1RM estimation
- Personal record detection
- Exercise history retrieval
- PR aggregation

Run with: pytest backend/tests/test_strength_tracking_service.py -v
"""

import pytest
from datetime import datetime, timedelta

from services.strength_tracking_service import StrengthTrackingService
from models.performance import StrengthRecord


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def strength_service():
    """Create a fresh strength tracking service for each test."""
    return StrengthTrackingService()


# ============================================================
# RECORD STRENGTH TESTS
# ============================================================

class TestRecordStrength:
    """Test recording strength performances."""

    def test_record_strength_first_time(self, strength_service):
        """Test recording first performance is always a PR."""
        record, is_pr = strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=80.0,
            reps=8,
            rpe=7.5,
        )

        assert isinstance(record, StrengthRecord)
        assert is_pr is True
        assert record.exercise_id == "bench_press"
        assert record.exercise_name == "Bench Press"
        assert record.user_id == 100
        assert record.weight_kg == 80.0
        assert record.reps == 8
        assert record.rpe == 7.5
        assert record.is_pr is True

    def test_record_strength_calculates_1rm(self, strength_service):
        """Test 1RM is calculated correctly."""
        record, _ = strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=100.0,
            reps=5,
        )

        # Epley formula: 1RM = weight * (1 + reps / 30)
        # 1RM = 100 * (1 + 5/30) = 100 * 1.167 = 116.7
        expected_1rm = StrengthRecord.calculate_1rm(100.0, 5)
        assert record.estimated_1rm == expected_1rm

    def test_record_strength_pr_detection(self, strength_service):
        """Test PR detection with multiple performances."""
        # First performance - PR
        record1, is_pr1 = strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=80.0,
            reps=8,
        )

        assert is_pr1 is True

        # Lower performance - not a PR
        record2, is_pr2 = strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=75.0,
            reps=8,
        )

        assert is_pr2 is False

        # Higher performance - new PR
        record3, is_pr3 = strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=85.0,
            reps=8,
        )

        assert is_pr3 is True

    def test_record_strength_same_weight_more_reps_is_pr(self, strength_service):
        """Test more reps at same weight is a PR."""
        # First: 80kg x 5
        record1, is_pr1 = strength_service.record_strength(
            exercise_id="squat",
            exercise_name="Squat",
            user_id=100,
            weight=80.0,
            reps=5,
        )

        assert is_pr1 is True

        # Second: 80kg x 8 (higher estimated 1RM)
        record2, is_pr2 = strength_service.record_strength(
            exercise_id="squat",
            exercise_name="Squat",
            user_id=100,
            weight=80.0,
            reps=8,
        )

        assert is_pr2 is True
        assert record2.estimated_1rm > record1.estimated_1rm

    def test_record_strength_stores_record(self, strength_service):
        """Test that records are stored correctly."""
        strength_service.record_strength(
            exercise_id="deadlift",
            exercise_name="Deadlift",
            user_id=100,
            weight=120.0,
            reps=5,
        )

        history = strength_service.get_exercise_history("deadlift", 100)
        assert len(history) == 1
        assert history[0].weight_kg == 120.0

    def test_record_strength_without_rpe(self, strength_service):
        """Test recording without RPE."""
        record, _ = strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=80.0,
            reps=8,
        )

        assert record.rpe is None

    def test_record_strength_different_users_isolated(self, strength_service):
        """Test that different users have isolated records."""
        # User 100
        record1, is_pr1 = strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=100.0,
            reps=5,
        )

        # User 200 - should also be a PR (first time for this user)
        record2, is_pr2 = strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=200,
            weight=60.0,
            reps=5,
        )

        assert is_pr1 is True
        assert is_pr2 is True

        # User histories should be separate
        history_100 = strength_service.get_exercise_history("bench_press", 100)
        history_200 = strength_service.get_exercise_history("bench_press", 200)

        assert len(history_100) == 1
        assert len(history_200) == 1
        assert history_100[0].weight_kg == 100.0
        assert history_200[0].weight_kg == 60.0


# ============================================================
# GET EXERCISE HISTORY TESTS
# ============================================================

class TestGetExerciseHistory:
    """Test exercise history retrieval."""

    def test_get_exercise_history_empty(self, strength_service):
        """Test getting history for exercise with no records."""
        history = strength_service.get_exercise_history("nonexistent", 100)
        assert history == []

    def test_get_exercise_history_sorted_by_date(self, strength_service):
        """Test history is sorted by date descending."""
        # Record multiple performances
        for weight in [80, 85, 82]:
            strength_service.record_strength(
                exercise_id="bench_press",
                exercise_name="Bench Press",
                user_id=100,
                weight=float(weight),
                reps=8,
            )

        history = strength_service.get_exercise_history("bench_press", 100)

        # Should be sorted newest first
        for i in range(len(history) - 1):
            assert history[i].date >= history[i + 1].date

    def test_get_exercise_history_with_limit(self, strength_service):
        """Test history respects limit parameter."""
        # Record 5 performances
        for i in range(5):
            strength_service.record_strength(
                exercise_id="squat",
                exercise_name="Squat",
                user_id=100,
                weight=80.0 + i,
                reps=5,
            )

        history = strength_service.get_exercise_history("squat", 100, limit=3)
        assert len(history) == 3

    def test_get_exercise_history_default_limit(self, strength_service):
        """Test default limit is 10."""
        # Record 15 performances
        for i in range(15):
            strength_service.record_strength(
                exercise_id="deadlift",
                exercise_name="Deadlift",
                user_id=100,
                weight=100.0 + i,
                reps=5,
            )

        history = strength_service.get_exercise_history("deadlift", 100)
        assert len(history) == 10


# ============================================================
# GET CURRENT 1RM TESTS
# ============================================================

class TestGetCurrent1RM:
    """Test getting current best 1RM."""

    def test_get_current_1rm_no_history(self, strength_service):
        """Test getting 1RM with no history returns None."""
        result = strength_service.get_current_1rm("nonexistent", 100)
        assert result is None

    def test_get_current_1rm_single_record(self, strength_service):
        """Test getting 1RM with single record."""
        strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=80.0,
            reps=8,
        )

        result = strength_service.get_current_1rm("bench_press", 100)
        expected = StrengthRecord.calculate_1rm(80.0, 8)
        assert result == expected

    def test_get_current_1rm_returns_best(self, strength_service):
        """Test getting 1RM returns best ever."""
        # Record performances with varying 1RMs
        performances = [
            (80.0, 5),   # ~93.3 kg 1RM
            (85.0, 3),   # ~93.5 kg 1RM
            (75.0, 10),  # 100 kg 1RM
            (70.0, 8),   # ~82.7 kg 1RM
        ]

        for weight, reps in performances:
            strength_service.record_strength(
                exercise_id="squat",
                exercise_name="Squat",
                user_id=100,
                weight=weight,
                reps=reps,
            )

        result = strength_service.get_current_1rm("squat", 100)

        # Best should be 75kg x 10 = 100kg 1RM
        expected = StrengthRecord.calculate_1rm(75.0, 10)
        assert result == expected


# ============================================================
# GET ALL PRS TESTS
# ============================================================

class TestGetAllPRs:
    """Test getting all personal records."""

    def test_get_all_prs_empty(self, strength_service):
        """Test getting PRs with no records."""
        prs = strength_service.get_all_prs(100)
        assert prs == []

    def test_get_all_prs_single_exercise(self, strength_service):
        """Test getting PRs for single exercise."""
        # First record is a PR
        strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=80.0,
            reps=8,
        )

        # Lower weight - not a PR
        strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=75.0,
            reps=8,
        )

        # Higher weight - new PR
        strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=85.0,
            reps=8,
        )

        prs = strength_service.get_all_prs(100)

        # Should have 2 PRs (first and third)
        assert len(prs) == 2
        assert all(pr.is_pr for pr in prs)

    def test_get_all_prs_multiple_exercises(self, strength_service):
        """Test getting PRs across multiple exercises."""
        # Bench PR
        strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=80.0,
            reps=8,
        )

        # Squat PR
        strength_service.record_strength(
            exercise_id="squat",
            exercise_name="Squat",
            user_id=100,
            weight=100.0,
            reps=5,
        )

        # Deadlift PR
        strength_service.record_strength(
            exercise_id="deadlift",
            exercise_name="Deadlift",
            user_id=100,
            weight=140.0,
            reps=3,
        )

        prs = strength_service.get_all_prs(100)
        assert len(prs) == 3

        exercise_names = {pr.exercise_name for pr in prs}
        assert "Bench Press" in exercise_names
        assert "Squat" in exercise_names
        assert "Deadlift" in exercise_names

    def test_get_all_prs_sorted_by_date(self, strength_service):
        """Test PRs are sorted by date descending."""
        for i in range(5):
            strength_service.record_strength(
                exercise_id=f"exercise_{i}",
                exercise_name=f"Exercise {i}",
                user_id=100,
                weight=50.0 + i * 10,
                reps=5,
            )

        prs = strength_service.get_all_prs(100)

        for i in range(len(prs) - 1):
            assert prs[i].date >= prs[i + 1].date

    def test_get_all_prs_respects_limit(self, strength_service):
        """Test PR retrieval respects limit."""
        for i in range(15):
            strength_service.record_strength(
                exercise_id=f"exercise_{i}",
                exercise_name=f"Exercise {i}",
                user_id=100,
                weight=50.0 + i,
                reps=5,
            )

        prs = strength_service.get_all_prs(100, limit=5)
        assert len(prs) == 5

    def test_get_all_prs_only_for_user(self, strength_service):
        """Test PRs are only returned for specified user."""
        # User 100 PRs
        strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=100,
            weight=80.0,
            reps=8,
        )

        # User 200 PRs
        strength_service.record_strength(
            exercise_id="bench_press",
            exercise_name="Bench Press",
            user_id=200,
            weight=100.0,
            reps=8,
        )

        prs_100 = strength_service.get_all_prs(100)
        prs_200 = strength_service.get_all_prs(200)

        assert len(prs_100) == 1
        assert len(prs_200) == 1
        assert prs_100[0].user_id == 100
        assert prs_200[0].user_id == 200


# ============================================================
# STRENGTH RECORD MODEL TESTS
# ============================================================

class TestStrengthRecordModel:
    """Test StrengthRecord model methods."""

    def test_calculate_1rm_epley(self):
        """Test 1RM calculation using Epley formula."""
        # 100kg x 10 reps = 100 * (1 + 10/30) = 133.33 kg
        result = StrengthRecord.calculate_1rm(100.0, 10)
        expected = 100.0 * (1 + 10 / 30)
        assert abs(result - expected) < 0.01

    def test_calculate_1rm_single_rep(self):
        """Test 1RM for single rep is the weight itself."""
        result = StrengthRecord.calculate_1rm(150.0, 1)
        expected = 150.0 * (1 + 1 / 30)
        assert abs(result - expected) < 0.01

    def test_calculate_1rm_various_weights(self):
        """Test 1RM calculation for various weights."""
        test_cases = [
            (80.0, 8, 80.0 * (1 + 8 / 30)),   # 101.3 kg
            (60.0, 12, 60.0 * (1 + 12 / 30)), # 84 kg
            (120.0, 5, 120.0 * (1 + 5 / 30)), # 140 kg
        ]

        for weight, reps, expected in test_cases:
            result = StrengthRecord.calculate_1rm(weight, reps)
            assert abs(result - expected) < 0.01


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases."""

    def test_zero_weight(self, strength_service):
        """Test handling zero weight."""
        record, is_pr = strength_service.record_strength(
            exercise_id="test",
            exercise_name="Test",
            user_id=100,
            weight=0.0,
            reps=10,
        )

        assert record.weight_kg == 0.0
        assert record.estimated_1rm == 0.0

    def test_high_reps(self, strength_service):
        """Test handling high rep counts."""
        record, _ = strength_service.record_strength(
            exercise_id="test",
            exercise_name="Test",
            user_id=100,
            weight=20.0,
            reps=100,
        )

        # Should still calculate (though not very accurate for high reps)
        assert record.estimated_1rm > 0

    def test_special_characters_in_exercise_id(self, strength_service):
        """Test handling special characters in exercise ID."""
        record, _ = strength_service.record_strength(
            exercise_id="dumbbell-curl_v2",
            exercise_name="Dumbbell Curl v2",
            user_id=100,
            weight=15.0,
            reps=12,
        )

        history = strength_service.get_exercise_history("dumbbell-curl_v2", 100)
        assert len(history) == 1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
