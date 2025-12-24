"""
Tests for Workout Modifier Service.

Tests:
- Adding exercises to workout
- Removing exercises from workout
- Modifying workout intensity
- Workout change logging

Run with: pytest backend/tests/test_workout_modifier.py -v
"""

import pytest
import json
from unittest.mock import MagicMock, patch
from datetime import datetime

from services.workout_modifier import WorkoutModifier


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_db():
    """Create a mock database client."""
    mock = MagicMock()
    return mock


@pytest.fixture
def workout_modifier(mock_db):
    """Create workout modifier with mocked database."""
    with patch("services.workout_modifier.get_supabase_db") as mock_get_db:
        mock_get_db.return_value = mock_db
        modifier = WorkoutModifier()
        yield modifier


@pytest.fixture
def sample_workout():
    """Create a sample workout."""
    return {
        "id": 123,
        "user_id": 100,
        "name": "Upper Body",
        "exercises": [
            {"exercise_id": "ex_bench_press", "name": "Bench Press", "sets": 3, "reps": 8, "rest_seconds": 60},
            {"exercise_id": "ex_rows", "name": "Rows", "sets": 3, "reps": 10, "rest_seconds": 60},
        ],
        "modification_history": []
    }


@pytest.fixture
def sample_workout_json_exercises():
    """Create a sample workout with JSON string exercises."""
    return {
        "id": 124,
        "user_id": 100,
        "name": "Leg Day",
        "exercises": json.dumps([
            {"exercise_id": "ex_squat", "name": "Squat", "sets": 4, "reps": 6, "rest_seconds": 90},
        ]),
        "modification_history": json.dumps([])
    }


# ============================================================
# ADD EXERCISES TESTS
# ============================================================

class TestAddExercises:
    """Test adding exercises to workout."""

    def test_add_exercises_success(self, workout_modifier, mock_db, sample_workout):
        """Test successfully adding exercises."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["Bicep Curl", "Tricep Extension"]
        )

        assert result is True
        mock_db.update_workout.assert_called_once()

        # Check the update data
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should have 4 exercises now
        assert len(update_data["exercises"]) == 4

        # Check new exercises were added
        exercise_names = [ex["name"] for ex in update_data["exercises"]]
        assert "Bicep Curl" in exercise_names
        assert "Tricep Extension" in exercise_names

        # Check modification history was updated
        assert len(update_data["modification_history"]) == 1
        assert update_data["modification_history"][0]["type"] == "add_exercises"

    def test_add_exercises_workout_not_found(self, workout_modifier, mock_db):
        """Test adding exercises to non-existent workout."""
        mock_db.get_workout.return_value = None

        result = workout_modifier.add_exercises_to_workout(
            workout_id=999,
            exercise_names=["Bicep Curl"]
        )

        assert result is False
        mock_db.update_workout.assert_not_called()

    def test_add_exercises_duplicate_not_added(self, workout_modifier, mock_db, sample_workout):
        """Test duplicate exercises are not added."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["Bench Press"]  # Already exists
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should still have 2 exercises (duplicate not added)
        assert len(update_data["exercises"]) == 2

    def test_add_exercises_case_insensitive_duplicate(self, workout_modifier, mock_db, sample_workout):
        """Test duplicate check is case insensitive."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["BENCH PRESS"]  # Different case
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should still have 2 exercises
        assert len(update_data["exercises"]) == 2

    def test_add_exercises_json_string_exercises(self, workout_modifier, mock_db, sample_workout_json_exercises):
        """Test adding exercises when exercises are stored as JSON string."""
        mock_db.get_workout.return_value = sample_workout_json_exercises
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.add_exercises_to_workout(
            workout_id=124,
            exercise_names=["Lunges"]
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should have 2 exercises now
        assert len(update_data["exercises"]) == 2

    def test_add_exercises_creates_exercise_structure(self, workout_modifier, mock_db, sample_workout):
        """Test new exercises have correct structure."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["Lateral Raise"]
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Find the new exercise
        new_exercise = [ex for ex in update_data["exercises"] if ex["name"] == "Lateral Raise"][0]

        assert new_exercise["exercise_id"] == "ex_lateral_raise"
        assert new_exercise["sets"] == 3
        assert new_exercise["reps"] == 12
        assert new_exercise["rest_seconds"] == 60

    def test_add_exercises_error_handling(self, workout_modifier, mock_db, sample_workout):
        """Test error handling during add."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.side_effect = Exception("Database error")

        result = workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["Bicep Curl"]
        )

        assert result is False


# ============================================================
# REMOVE EXERCISES TESTS
# ============================================================

class TestRemoveExercises:
    """Test removing exercises from workout."""

    def test_remove_exercises_success(self, workout_modifier, mock_db, sample_workout):
        """Test successfully removing exercises."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.remove_exercises_from_workout(
            workout_id=123,
            exercise_names=["Bench Press"]
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should have 1 exercise now
        assert len(update_data["exercises"]) == 1
        assert update_data["exercises"][0]["name"] == "Rows"

        # Check modification history
        assert update_data["modification_history"][0]["type"] == "remove_exercises"
        assert update_data["modification_history"][0]["removed_count"] == 1

    def test_remove_exercises_workout_not_found(self, workout_modifier, mock_db):
        """Test removing from non-existent workout."""
        mock_db.get_workout.return_value = None

        result = workout_modifier.remove_exercises_from_workout(
            workout_id=999,
            exercise_names=["Bench Press"]
        )

        assert result is False

    def test_remove_exercises_case_insensitive(self, workout_modifier, mock_db, sample_workout):
        """Test removal is case insensitive."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.remove_exercises_from_workout(
            workout_id=123,
            exercise_names=["BENCH PRESS", "rows"]
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should have 0 exercises now
        assert len(update_data["exercises"]) == 0
        assert update_data["modification_history"][0]["removed_count"] == 2

    def test_remove_exercises_nonexistent_name(self, workout_modifier, mock_db, sample_workout):
        """Test removing exercise that doesn't exist."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.remove_exercises_from_workout(
            workout_id=123,
            exercise_names=["NonExistent Exercise"]
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should still have 2 exercises
        assert len(update_data["exercises"]) == 2
        assert update_data["modification_history"][0]["removed_count"] == 0

    def test_remove_exercises_json_string_exercises(self, workout_modifier, mock_db, sample_workout_json_exercises):
        """Test removing when exercises are stored as JSON string."""
        mock_db.get_workout.return_value = sample_workout_json_exercises
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.remove_exercises_from_workout(
            workout_id=124,
            exercise_names=["Squat"]
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should have 0 exercises now
        assert len(update_data["exercises"]) == 0

    def test_remove_exercises_error_handling(self, workout_modifier, mock_db, sample_workout):
        """Test error handling during remove."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.side_effect = Exception("Database error")

        result = workout_modifier.remove_exercises_from_workout(
            workout_id=123,
            exercise_names=["Bench Press"]
        )

        assert result is False


# ============================================================
# MODIFY INTENSITY TESTS
# ============================================================

class TestModifyIntensity:
    """Test modifying workout intensity."""

    def test_modify_intensity_easier(self, workout_modifier, mock_db, sample_workout):
        """Test making workout easier."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.modify_workout_intensity(
            workout_id=123,
            modification="make it easier"
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Check first exercise was made easier
        first_exercise = update_data["exercises"][0]
        assert first_exercise["sets"] <= 3  # Reduced or same
        assert first_exercise["reps"] <= 8  # Reduced or same
        assert first_exercise["rest_seconds"] >= 60  # Increased or same

    def test_modify_intensity_harder(self, workout_modifier, mock_db, sample_workout):
        """Test making workout harder."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.modify_workout_intensity(
            workout_id=123,
            modification="make it harder"
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Check first exercise was made harder
        first_exercise = update_data["exercises"][0]
        assert first_exercise["sets"] >= 3  # Increased or same
        assert first_exercise["reps"] >= 8  # Increased or same
        assert first_exercise["rest_seconds"] <= 60  # Reduced or same

    def test_modify_intensity_reduce(self, workout_modifier, mock_db, sample_workout):
        """Test reducing workout intensity."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.modify_workout_intensity(
            workout_id=123,
            modification="reduce the intensity"
        )

        assert result is True

    def test_modify_intensity_increase(self, workout_modifier, mock_db, sample_workout):
        """Test increasing workout intensity."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.modify_workout_intensity(
            workout_id=123,
            modification="increase difficulty"
        )

        assert result is True

    def test_modify_intensity_workout_not_found(self, workout_modifier, mock_db):
        """Test modifying non-existent workout."""
        mock_db.get_workout.return_value = None

        result = workout_modifier.modify_workout_intensity(
            workout_id=999,
            modification="make easier"
        )

        assert result is False

    def test_modify_intensity_respects_bounds(self, workout_modifier, mock_db):
        """Test intensity modification respects min/max bounds."""
        # Workout with minimal values
        minimal_workout = {
            "id": 123,
            "user_id": 100,
            "name": "Minimal",
            "exercises": [
                {"name": "Exercise", "sets": 1, "reps": 5, "rest_seconds": 30}
            ],
            "modification_history": []
        }
        mock_db.get_workout.return_value = minimal_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        # Try to make easier (should hit minimums)
        result = workout_modifier.modify_workout_intensity(
            workout_id=123,
            modification="easier"
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Check bounds are respected
        first_exercise = update_data["exercises"][0]
        assert first_exercise["sets"] >= 1
        assert first_exercise["reps"] >= 5

    def test_modify_intensity_respects_max_bounds(self, workout_modifier, mock_db):
        """Test intensity modification respects max bounds."""
        # Workout with high values
        max_workout = {
            "id": 123,
            "user_id": 100,
            "name": "Maximal",
            "exercises": [
                {"name": "Exercise", "sets": 5, "reps": 20, "rest_seconds": 120}
            ],
            "modification_history": []
        }
        mock_db.get_workout.return_value = max_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        # Try to make harder (should hit maximums)
        result = workout_modifier.modify_workout_intensity(
            workout_id=123,
            modification="harder"
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Check bounds are respected
        first_exercise = update_data["exercises"][0]
        assert first_exercise["sets"] <= 5
        assert first_exercise["reps"] <= 20

    def test_modify_intensity_updates_history(self, workout_modifier, mock_db, sample_workout):
        """Test modification history is updated."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        result = workout_modifier.modify_workout_intensity(
            workout_id=123,
            modification="easier"
        )

        assert result is True
        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        assert len(update_data["modification_history"]) == 1
        assert update_data["modification_history"][0]["type"] == "modify_intensity"
        assert update_data["modification_history"][0]["modification"] == "easier"

    def test_modify_intensity_error_handling(self, workout_modifier, mock_db, sample_workout):
        """Test error handling during intensity modification."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.side_effect = Exception("Database error")

        result = workout_modifier.modify_workout_intensity(
            workout_id=123,
            modification="easier"
        )

        assert result is False


# ============================================================
# LOG WORKOUT CHANGE TESTS
# ============================================================

class TestLogWorkoutChange:
    """Test workout change logging."""

    def test_log_workout_change_called(self, workout_modifier, mock_db, sample_workout):
        """Test that workout changes are logged."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["Bicep Curl"]
        )

        mock_db.create_workout_change.assert_called_once()

        call_args = mock_db.create_workout_change.call_args[0][0]
        assert call_args["workout_id"] == 123
        assert call_args["user_id"] == 100
        assert call_args["change_type"] == "add_exercises"
        assert call_args["change_source"] == "ai_coach"

    def test_log_workout_change_error_handled(self, workout_modifier, mock_db, sample_workout):
        """Test that logging errors don't fail the operation."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.side_effect = Exception("Logging error")

        # Operation should still succeed even if logging fails
        result = workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["Bicep Curl"]
        )

        assert result is True


# ============================================================
# MODIFICATION HISTORY TESTS
# ============================================================

class TestModificationHistory:
    """Test modification history tracking."""

    def test_preserves_existing_history(self, workout_modifier, mock_db):
        """Test existing modification history is preserved."""
        workout_with_history = {
            "id": 123,
            "user_id": 100,
            "name": "Workout",
            "exercises": [{"name": "Exercise 1", "sets": 3, "reps": 10, "rest_seconds": 60}],
            "modification_history": [
                {"type": "initial", "timestamp": "2025-01-01T00:00:00"}
            ]
        }
        mock_db.get_workout.return_value = workout_with_history
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["New Exercise"]
        )

        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        # Should have 2 entries now
        assert len(update_data["modification_history"]) == 2
        assert update_data["modification_history"][0]["type"] == "initial"
        assert update_data["modification_history"][1]["type"] == "add_exercises"

    def test_history_includes_timestamp(self, workout_modifier, mock_db, sample_workout):
        """Test modification history includes timestamp."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["New Exercise"]
        )

        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        assert "timestamp" in update_data["modification_history"][0]

    def test_history_includes_method(self, workout_modifier, mock_db, sample_workout):
        """Test modification history includes method."""
        mock_db.get_workout.return_value = sample_workout
        mock_db.update_workout.return_value = None
        mock_db.create_workout_change.return_value = None

        workout_modifier.add_exercises_to_workout(
            workout_id=123,
            exercise_names=["New Exercise"]
        )

        call_args = mock_db.update_workout.call_args
        update_data = call_args[0][1]

        assert update_data["modification_history"][0]["method"] == "ai_coach"
        assert update_data["last_modified_method"] == "ai_coach"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
