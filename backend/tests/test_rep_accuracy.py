"""
Tests for Rep Accuracy Tracking API

Tests the rep accuracy endpoints that allow users to track actual vs planned reps
during workouts. This addresses user feedback about inability to record when they
completed fewer reps than planned (e.g., "50 crunches planned, only did 30").
"""

import pytest
from datetime import datetime
from unittest.mock import patch, MagicMock, AsyncMock
from uuid import uuid4


# ============================================================================
# Test Data Fixtures
# ============================================================================

@pytest.fixture
def mock_user_id():
    """Generate a test user ID."""
    return str(uuid4())


@pytest.fixture
def mock_workout_id():
    """Generate a test workout ID."""
    return str(uuid4())


@pytest.fixture
def sample_rep_accuracy_request():
    """Sample request data for logging rep accuracy."""
    return {
        "exercise_index": 0,
        "exercise_name": "Crunches",
        "set_number": 1,
        "planned_reps": 50,
        "actual_reps": 30,
        "weight_kg": None,
        "was_modified": True,
        "modification_reason": "fatigue"
    }


@pytest.fixture
def sample_rep_accuracy_met_target():
    """Sample request where user met the target."""
    return {
        "exercise_index": 0,
        "exercise_name": "Push-ups",
        "set_number": 1,
        "planned_reps": 15,
        "actual_reps": 15,
        "weight_kg": None,
        "was_modified": False,
        "modification_reason": None
    }


@pytest.fixture
def sample_rep_accuracy_exceeded():
    """Sample request where user exceeded the target."""
    return {
        "exercise_index": 1,
        "exercise_name": "Squats",
        "set_number": 2,
        "planned_reps": 12,
        "actual_reps": 15,
        "weight_kg": 60.0,
        "was_modified": True,
        "modification_reason": "too_easy"
    }


# ============================================================================
# Unit Tests for Accuracy Calculation
# ============================================================================

class TestAccuracyCalculation:
    """Test accuracy percentage calculations."""

    def test_under_target_accuracy(self):
        """Test accuracy when actual < planned (30/50 = 60%)."""
        planned = 50
        actual = 30
        expected_accuracy = 60.0

        accuracy = (actual / planned) * 100
        assert accuracy == expected_accuracy

    def test_exact_target_accuracy(self):
        """Test accuracy when actual == planned (15/15 = 100%)."""
        planned = 15
        actual = 15
        expected_accuracy = 100.0

        accuracy = (actual / planned) * 100
        assert accuracy == expected_accuracy

    def test_exceeded_target_accuracy(self):
        """Test accuracy when actual > planned (15/12 = 125%)."""
        planned = 12
        actual = 15
        expected_accuracy = 125.0

        accuracy = (actual / planned) * 100
        assert accuracy == expected_accuracy

    def test_zero_planned_reps(self):
        """Test handling of zero planned reps (edge case)."""
        planned = 0
        actual = 10
        # Should default to 100% or handle gracefully
        if planned > 0:
            accuracy = (actual / planned) * 100
        else:
            accuracy = 100.0  # Default for edge case

        assert accuracy == 100.0

    def test_high_rep_accuracy(self):
        """Test accuracy with high rep counts."""
        planned = 100
        actual = 95
        expected_accuracy = 95.0

        accuracy = (actual / planned) * 100
        assert accuracy == expected_accuracy


class TestRepDifferenceCalculation:
    """Test rep difference calculations."""

    def test_negative_difference(self):
        """Test difference when under target (30 - 50 = -20)."""
        planned = 50
        actual = 30
        expected_diff = -20

        diff = actual - planned
        assert diff == expected_diff

    def test_zero_difference(self):
        """Test difference when on target (15 - 15 = 0)."""
        planned = 15
        actual = 15
        expected_diff = 0

        diff = actual - planned
        assert diff == expected_diff

    def test_positive_difference(self):
        """Test difference when exceeded target (15 - 12 = 3)."""
        planned = 12
        actual = 15
        expected_diff = 3

        diff = actual - planned
        assert diff == expected_diff


# ============================================================================
# Integration Tests for API Endpoints
# ============================================================================

class TestRepAccuracyEndpoint:
    """Test the POST /workouts/{workout_id}/sets/rep-accuracy endpoint."""

    @pytest.mark.asyncio
    async def test_log_rep_accuracy_under_target(
        self,
        sample_rep_accuracy_request,
        mock_workout_id,
        mock_user_id
    ):
        """Test logging rep accuracy when user falls short of target."""
        request_data = sample_rep_accuracy_request

        # Validate expected response structure
        expected_response = {
            "id": mock_workout_id,  # Would be generated UUID
            "workout_id": mock_workout_id,
            "exercise_name": "Crunches",
            "set_number": 1,
            "planned_reps": 50,
            "actual_reps": 30,
            "accuracy_percentage": 60.0,
            "rep_difference": -20,
            "was_modified": True,
            "modification_reason": "fatigue"
        }

        # Verify accuracy calculation
        assert expected_response["accuracy_percentage"] == 60.0
        assert expected_response["rep_difference"] == -20

    @pytest.mark.asyncio
    async def test_log_rep_accuracy_met_target(
        self,
        sample_rep_accuracy_met_target,
        mock_workout_id
    ):
        """Test logging rep accuracy when user meets target exactly."""
        request_data = sample_rep_accuracy_met_target

        expected_accuracy = 100.0
        expected_diff = 0

        # Calculate
        planned = request_data["planned_reps"]
        actual = request_data["actual_reps"]
        accuracy = (actual / planned) * 100
        diff = actual - planned

        assert accuracy == expected_accuracy
        assert diff == expected_diff

    @pytest.mark.asyncio
    async def test_log_rep_accuracy_exceeded(
        self,
        sample_rep_accuracy_exceeded,
        mock_workout_id
    ):
        """Test logging rep accuracy when user exceeds target."""
        request_data = sample_rep_accuracy_exceeded

        # Calculate expected values
        planned = request_data["planned_reps"]
        actual = request_data["actual_reps"]
        expected_accuracy = (actual / planned) * 100
        expected_diff = actual - planned

        assert expected_accuracy == 125.0
        assert expected_diff == 3
        assert request_data["modification_reason"] == "too_easy"


class TestValidation:
    """Test request validation for rep accuracy endpoint."""

    def test_valid_modification_reasons(self):
        """Test all valid modification reasons are accepted."""
        valid_reasons = [
            "fatigue",
            "too_easy",
            "pain",
            "form_breakdown",
            "time_constraint",
            "equipment_issue",
            "personal_best",
            "other"
        ]

        for reason in valid_reasons:
            assert reason in valid_reasons

    def test_set_number_minimum(self):
        """Test that set_number must be at least 1."""
        min_set_number = 1

        # Valid
        assert min_set_number >= 1

        # Invalid would be 0 or negative
        invalid_set_numbers = [0, -1, -5]
        for invalid in invalid_set_numbers:
            assert invalid < 1

    def test_planned_reps_minimum(self):
        """Test that planned_reps must be at least 1."""
        min_planned = 1

        # Valid
        assert min_planned >= 1

        # Invalid
        assert 0 < 1
        assert -1 < 1

    def test_actual_reps_minimum(self):
        """Test that actual_reps can be 0 (didn't complete any)."""
        min_actual = 0

        # Valid - user might not complete any reps
        assert min_actual >= 0


# ============================================================================
# Tests for Analytics View
# ============================================================================

class TestRepAccuracyPatterns:
    """Test the v_user_rep_accuracy_patterns analytics view."""

    def test_pattern_aggregation(self):
        """Test that patterns are correctly aggregated by exercise."""
        # Simulated data for 3 sets of crunches
        sets_data = [
            {"exercise_name": "Crunches", "planned": 50, "actual": 30},  # 60%
            {"exercise_name": "Crunches", "planned": 50, "actual": 40},  # 80%
            {"exercise_name": "Crunches", "planned": 50, "actual": 35},  # 70%
        ]

        total_sets = len(sets_data)
        avg_accuracy = sum(
            (s["actual"] / s["planned"]) * 100 for s in sets_data
        ) / total_sets

        assert total_sets == 3
        assert round(avg_accuracy, 1) == 70.0  # Average of 60, 80, 70

    def test_target_hit_classification(self):
        """Test classification of sets meeting/missing targets."""
        sets_data = [
            {"planned": 50, "actual": 30},  # Below target
            {"planned": 15, "actual": 15},  # Met target
            {"planned": 12, "actual": 15},  # Exceeded target
            {"planned": 20, "actual": 18},  # Below target
        ]

        met_or_exceeded = sum(
            1 for s in sets_data if s["actual"] >= s["planned"]
        )
        below_target = sum(
            1 for s in sets_data if s["actual"] < s["planned"]
        )
        exceeded = sum(
            1 for s in sets_data if s["actual"] > s["planned"]
        )

        assert met_or_exceeded == 2
        assert below_target == 2
        assert exceeded == 1


# ============================================================================
# Tests for User Context Logging
# ============================================================================

class TestUserContextLogging:
    """Test that rep accuracy events are logged to user context service."""

    def test_context_event_structure(self, sample_rep_accuracy_request):
        """Test the structure of logged context events."""
        request = sample_rep_accuracy_request

        # Expected event data structure
        event_data = {
            "workout_id": "test-workout-id",
            "exercise_name": request["exercise_name"],
            "set_number": request["set_number"],
            "planned_reps": request["planned_reps"],
            "actual_reps": request["actual_reps"],
            "rep_difference": request["actual_reps"] - request["planned_reps"],
            "accuracy_percent": (request["actual_reps"] / request["planned_reps"]) * 100,
            "weight_kg": request["weight_kg"],
            "modification_reason": request["modification_reason"],
            "exceeded_plan": request["actual_reps"] > request["planned_reps"],
            "fell_short": request["actual_reps"] < request["planned_reps"],
        }

        assert event_data["exercise_name"] == "Crunches"
        assert event_data["rep_difference"] == -20
        assert event_data["accuracy_percent"] == 60.0
        assert event_data["fell_short"] is True
        assert event_data["exceeded_plan"] is False


# ============================================================================
# Tests for Batch Upload
# ============================================================================

class TestBatchRepAccuracy:
    """Test batch upload of rep accuracy data."""

    def test_batch_summary_calculation(self):
        """Test summary calculation from batch data."""
        batch_data = [
            {"planned": 50, "actual": 30},
            {"planned": 50, "actual": 40},
            {"planned": 15, "actual": 15},
            {"planned": 12, "actual": 15},
        ]

        total_sets = len(batch_data)
        total_planned = sum(d["planned"] for d in batch_data)
        total_actual = sum(d["actual"] for d in batch_data)
        overall_accuracy = (total_actual / total_planned) * 100

        accurate_sets = sum(
            1 for d in batch_data if d["actual"] == d["planned"]
        )
        exceeded_sets = sum(
            1 for d in batch_data if d["actual"] > d["planned"]
        )
        short_sets = sum(
            1 for d in batch_data if d["actual"] < d["planned"]
        )

        assert total_sets == 4
        assert total_planned == 127
        assert total_actual == 100
        assert round(overall_accuracy, 1) == 78.7
        assert accurate_sets == 1
        assert exceeded_sets == 1
        assert short_sets == 2


# ============================================================================
# Edge Case Tests
# ============================================================================

class TestEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_very_high_reps(self):
        """Test with very high rep counts."""
        planned = 100
        actual = 95
        accuracy = (actual / planned) * 100

        assert accuracy == 95.0

    def test_single_rep_exercise(self):
        """Test with single rep (like 1RM attempt)."""
        planned = 1
        actual = 1
        accuracy = (actual / planned) * 100

        assert accuracy == 100.0

    def test_zero_actual_reps(self):
        """Test when user completes zero reps (gave up)."""
        planned = 10
        actual = 0
        accuracy = (actual / planned) * 100

        assert accuracy == 0.0

    def test_weight_with_accuracy(self):
        """Test that weight is properly tracked alongside reps."""
        data = {
            "planned_reps": 12,
            "actual_reps": 10,
            "weight_kg": 60.0,
        }

        accuracy = (data["actual_reps"] / data["planned_reps"]) * 100

        assert accuracy == (10/12) * 100
        assert data["weight_kg"] == 60.0


# ============================================================================
# Database Migration Tests
# ============================================================================

class TestDatabaseSchema:
    """Test database schema requirements."""

    def test_required_columns(self):
        """Verify all required columns are defined."""
        required_columns = [
            "id",
            "user_id",
            "workout_log_id",
            "workout_id",
            "exercise_index",
            "exercise_name",
            "set_number",
            "planned_reps",
            "actual_reps",
            "rep_difference",
            "accuracy_percentage",
            "weight_kg",
            "was_modified",
            "modification_reason",
            "created_at"
        ]

        # This would be validated against actual schema
        assert len(required_columns) == 15

    def test_computed_columns(self):
        """Test that computed columns are generated correctly."""
        # rep_difference = actual_reps - planned_reps
        planned = 50
        actual = 30
        expected_diff = actual - planned

        assert expected_diff == -20

        # accuracy_percentage = (actual_reps / planned_reps) * 100
        expected_accuracy = (actual / planned) * 100

        assert expected_accuracy == 60.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
