"""
Tests for the Quick Start / Today's Workout API endpoints.

Tests the /api/v1/workouts/today endpoint that provides
the quick-start experience on the home screen.

Run with: pytest tests/test_quick_start.py -v
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import date, timedelta
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.v1.workouts.today import (
    _extract_primary_muscles,
    _row_to_summary,
    TodayWorkoutSummary,
    TodayWorkoutResponse,
)


# ============================================================================
# Unit Tests for Helper Functions
# ============================================================================

class TestExtractPrimaryMuscles:
    """Tests for the _extract_primary_muscles helper function."""

    def test_extract_muscles_from_primary_muscle_field(self):
        """Should extract muscles from primary_muscle field."""
        exercises = [
            {"name": "Bench Press", "primary_muscle": "chest"},
            {"name": "Rows", "primary_muscle": "back"},
        ]
        result = _extract_primary_muscles(exercises)
        assert "Chest" in result
        assert "Back" in result

    def test_extract_muscles_from_primaryMuscle_field(self):
        """Should extract muscles from camelCase primaryMuscle field."""
        exercises = [
            {"name": "Squat", "primaryMuscle": "quadriceps"},
        ]
        result = _extract_primary_muscles(exercises)
        assert "Quadriceps" in result

    def test_extract_muscles_from_muscle_group_field(self):
        """Should extract muscles from muscle_group field."""
        exercises = [
            {"name": "Curl", "muscle_group": "biceps"},
        ]
        result = _extract_primary_muscles(exercises)
        assert "Biceps" in result

    def test_extract_muscles_from_target_muscle_field(self):
        """Should extract muscles from target_muscle field."""
        exercises = [
            {"name": "Tricep Extension", "target_muscle": "triceps"},
        ]
        result = _extract_primary_muscles(exercises)
        assert "Triceps" in result

    def test_extract_muscles_limits_to_four(self):
        """Should limit result to maximum 4 muscles."""
        exercises = [
            {"name": "Ex1", "primary_muscle": "chest"},
            {"name": "Ex2", "primary_muscle": "back"},
            {"name": "Ex3", "primary_muscle": "legs"},
            {"name": "Ex4", "primary_muscle": "shoulders"},
            {"name": "Ex5", "primary_muscle": "arms"},
            {"name": "Ex6", "primary_muscle": "core"},
        ]
        result = _extract_primary_muscles(exercises)
        assert len(result) <= 4

    def test_extract_muscles_removes_duplicates(self):
        """Should return unique muscles only."""
        exercises = [
            {"name": "Bench Press", "primary_muscle": "chest"},
            {"name": "Push Up", "primary_muscle": "chest"},
            {"name": "Incline Press", "primary_muscle": "chest"},
        ]
        result = _extract_primary_muscles(exercises)
        assert result == ["Chest"]

    def test_extract_muscles_empty_list(self):
        """Should handle empty exercise list."""
        result = _extract_primary_muscles([])
        assert result == []

    def test_extract_muscles_with_missing_muscle_info(self):
        """Should handle exercises without muscle info."""
        exercises = [
            {"name": "Unknown Exercise"},
            {"name": "Another Exercise", "sets": 3},
        ]
        result = _extract_primary_muscles(exercises)
        assert result == []

    def test_extract_muscles_non_dict_exercises(self):
        """Should handle non-dict items in exercise list."""
        exercises = ["invalid", None, {"primary_muscle": "chest"}]
        result = _extract_primary_muscles(exercises)
        assert "Chest" in result


class TestRowToSummary:
    """Tests for the _row_to_summary helper function."""

    def test_row_to_summary_basic(self):
        """Should convert a basic row to TodayWorkoutSummary."""
        row = {
            "id": "workout-123",
            "name": "Upper Body",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "exercises": [
                {"name": "Push Up", "primary_muscle": "chest"},
                {"name": "Pull Up", "primary_muscle": "back"},
            ],
            "scheduled_date": date.today().isoformat(),
            "is_completed": False,
        }
        summary = _row_to_summary(row)

        assert summary.id == "workout-123"
        assert summary.name == "Upper Body"
        assert summary.type == "strength"
        assert summary.difficulty == "medium"
        assert summary.duration_minutes == 45
        assert summary.exercise_count == 2
        assert summary.is_today is True
        assert summary.is_completed is False

    def test_row_to_summary_with_json_string_exercises(self):
        """Should parse exercises from JSON string."""
        exercises = [{"name": "Squat", "primary_muscle": "legs"}]
        row = {
            "id": "workout-456",
            "name": "Leg Day",
            "type": "strength",
            "difficulty": "hard",
            "duration_minutes": 60,
            "exercises": json.dumps(exercises),
            "scheduled_date": date.today().isoformat(),
            "is_completed": False,
        }
        summary = _row_to_summary(row)

        assert summary.exercise_count == 1
        assert "Legs" in summary.primary_muscles

    def test_row_to_summary_with_exercises_json_field(self):
        """Should use exercises_json field if exercises is not present."""
        row = {
            "id": "workout-789",
            "name": "Full Body",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 50,
            "exercises_json": [{"name": "Deadlift", "primary_muscle": "back"}],
            "scheduled_date": date.today().isoformat(),
            "is_completed": False,
        }
        summary = _row_to_summary(row)

        assert summary.exercise_count == 1

    def test_row_to_summary_with_invalid_json_exercises(self):
        """Should handle invalid JSON in exercises field."""
        row = {
            "id": "workout-invalid",
            "name": "Test",
            "type": "strength",
            "difficulty": "easy",
            "duration_minutes": 30,
            "exercises": "invalid json {",
            "scheduled_date": date.today().isoformat(),
            "is_completed": False,
        }
        summary = _row_to_summary(row)

        assert summary.exercise_count == 0
        assert summary.primary_muscles == []

    def test_row_to_summary_future_date(self):
        """Should correctly identify future workout as not today."""
        tomorrow = (date.today() + timedelta(days=1)).isoformat()
        row = {
            "id": "workout-future",
            "name": "Future Workout",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "exercises": [],
            "scheduled_date": tomorrow,
            "is_completed": False,
        }
        summary = _row_to_summary(row)

        assert summary.is_today is False

    def test_row_to_summary_with_defaults(self):
        """Should use defaults for missing fields."""
        row = {
            "id": "workout-minimal",
            "scheduled_date": date.today().isoformat(),
        }
        summary = _row_to_summary(row)

        assert summary.name == "Workout"
        assert summary.type == "strength"
        assert summary.difficulty == "medium"
        assert summary.duration_minutes == 45
        assert summary.exercise_count == 0

    def test_row_to_summary_datetime_scheduled_date(self):
        """Should handle datetime string for scheduled_date."""
        row = {
            "id": "workout-dt",
            "name": "Test",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 30,
            "exercises": [],
            "scheduled_date": f"{date.today().isoformat()}T10:00:00Z",
            "is_completed": False,
        }
        summary = _row_to_summary(row)

        assert summary.scheduled_date == date.today().isoformat()


# ============================================================================
# API Endpoint Tests
# ============================================================================

class TestGetTodayWorkoutEndpoint:
    """Tests for the GET /workouts/today endpoint."""

    def test_endpoint_exists(self, client):
        """Test that the today endpoint exists."""
        response = client.get("/api/v1/workouts/today?user_id=test-user")
        # Should not be 404
        assert response.status_code != 404

    def test_endpoint_requires_user_id(self, client):
        """Test that user_id parameter is required."""
        response = client.get("/api/v1/workouts/today")
        assert response.status_code == 422  # Validation error

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_today_workout_when_exists(self, mock_context, mock_db, client):
        """Should return today's workout when one is scheduled."""
        today_str = date.today().isoformat()
        mock_workout = {
            "id": "workout-today-123",
            "name": "Morning Strength",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 45,
            "exercises": json.dumps([{"name": "Squat", "primary_muscle": "legs"}]),
            "scheduled_date": today_str,
            "is_completed": False,
        }

        mock_db_instance = MagicMock()
        mock_db_instance.list_workouts.return_value = [mock_workout]
        mock_db.return_value = mock_db_instance
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 200
        data = response.json()
        assert data["has_workout_today"] is True
        assert data["today_workout"]["id"] == "workout-today-123"
        assert data["today_workout"]["name"] == "Morning Strength"
        assert data["today_workout"]["is_today"] is True

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_rest_day_when_no_today_workout(self, mock_context, mock_db, client):
        """Should return rest day message when no workout today."""
        mock_db_instance = MagicMock()
        # No workout today
        mock_db_instance.list_workouts.side_effect = [
            [],  # Today's workouts
            [],  # Future workouts
        ]
        mock_db.return_value = mock_db_instance
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 200
        data = response.json()
        assert data["has_workout_today"] is False
        assert data["today_workout"] is None
        assert data["rest_day_message"] is not None
        assert "No upcoming workouts" in data["rest_day_message"]

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_next_workout_on_rest_day(self, mock_context, mock_db, client):
        """Should return next workout info on rest day."""
        tomorrow_str = (date.today() + timedelta(days=1)).isoformat()
        next_workout = {
            "id": "workout-tomorrow",
            "name": "Leg Day",
            "type": "strength",
            "difficulty": "hard",
            "duration_minutes": 60,
            "exercises": [],
            "scheduled_date": tomorrow_str,
            "is_completed": False,
        }

        mock_db_instance = MagicMock()
        mock_db_instance.list_workouts.side_effect = [
            [],  # Today's workouts (none)
            [next_workout],  # Future workouts
        ]
        mock_db.return_value = mock_db_instance
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 200
        data = response.json()
        assert data["has_workout_today"] is False
        assert data["next_workout"] is not None
        assert data["next_workout"]["id"] == "workout-tomorrow"
        assert data["days_until_next"] == 1
        assert "tomorrow" in data["rest_day_message"].lower()

    @patch('api.v1.workouts.today.get_supabase_db')
    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_days_until_next_workout(self, mock_context, mock_db, client):
        """Should correctly calculate days until next workout."""
        three_days_later = (date.today() + timedelta(days=3)).isoformat()
        next_workout = {
            "id": "workout-later",
            "name": "Full Body",
            "type": "strength",
            "difficulty": "medium",
            "duration_minutes": 50,
            "exercises": [],
            "scheduled_date": three_days_later,
            "is_completed": False,
        }

        mock_db_instance = MagicMock()
        mock_db_instance.list_workouts.side_effect = [
            [],  # Today's workouts
            [next_workout],  # Future workouts
        ]
        mock_db.return_value = mock_db_instance
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 200
        data = response.json()
        assert data["days_until_next"] == 3
        assert "3 days" in data["rest_day_message"]

    @patch('api.v1.workouts.today.get_supabase_db')
    def test_handles_database_error(self, mock_db, client):
        """Should return 500 when database error occurs."""
        mock_db_instance = MagicMock()
        mock_db_instance.list_workouts.side_effect = Exception("Database error")
        mock_db.return_value = mock_db_instance

        response = client.get("/api/v1/workouts/today?user_id=test-user")

        assert response.status_code == 500


class TestLogQuickStartEndpoint:
    """Tests for the POST /workouts/today/start endpoint."""

    def test_endpoint_exists(self, client):
        """Test that the start endpoint exists."""
        response = client.post(
            "/api/v1/workouts/today/start?user_id=test-user&workout_id=workout-123"
        )
        # Should not be 404
        assert response.status_code != 404

    def test_requires_user_id(self, client):
        """Test that user_id is required."""
        response = client.post(
            "/api/v1/workouts/today/start?workout_id=workout-123"
        )
        assert response.status_code == 422

    def test_requires_workout_id(self, client):
        """Test that workout_id is required."""
        response = client.post(
            "/api/v1/workouts/today/start?user_id=test-user"
        )
        assert response.status_code == 422

    @patch('api.v1.workouts.today.user_context_service')
    def test_logs_quick_start_success(self, mock_context, client):
        """Should log quick start event successfully."""
        mock_context.log_event = AsyncMock()

        response = client.post(
            "/api/v1/workouts/today/start?user_id=test-user&workout_id=workout-123"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

        # Verify log_event was called
        mock_context.log_event.assert_called_once()
        call_args = mock_context.log_event.call_args
        assert call_args.kwargs["user_id"] == "test-user"
        assert call_args.kwargs["event_type"] == "quick_start_tapped"
        assert call_args.kwargs["event_data"]["workout_id"] == "workout-123"

    @patch('api.v1.workouts.today.user_context_service')
    def test_returns_success_even_on_logging_failure(self, mock_context, client):
        """Should not fail request even if logging fails."""
        mock_context.log_event = AsyncMock(side_effect=Exception("Logging error"))

        response = client.post(
            "/api/v1/workouts/today/start?user_id=test-user&workout_id=workout-123"
        )

        # Should still return 200, just with success=False
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False


# ============================================================================
# Response Model Tests
# ============================================================================

class TestTodayWorkoutSummaryModel:
    """Tests for the TodayWorkoutSummary model."""

    def test_model_instantiation(self):
        """Should create model with required fields."""
        summary = TodayWorkoutSummary(
            id="workout-123",
            name="Test Workout",
            type="strength",
            difficulty="medium",
            duration_minutes=45,
            exercise_count=5,
            primary_muscles=["Chest", "Back"],
            scheduled_date="2024-01-15",
            is_today=True,
            is_completed=False,
        )

        assert summary.id == "workout-123"
        assert summary.exercise_count == 5
        assert len(summary.primary_muscles) == 2


class TestTodayWorkoutResponseModel:
    """Tests for the TodayWorkoutResponse model."""

    def test_response_with_today_workout(self):
        """Should create response with today's workout."""
        today_workout = TodayWorkoutSummary(
            id="workout-123",
            name="Test Workout",
            type="strength",
            difficulty="medium",
            duration_minutes=45,
            exercise_count=5,
            primary_muscles=["Chest"],
            scheduled_date="2024-01-15",
            is_today=True,
            is_completed=False,
        )

        response = TodayWorkoutResponse(
            has_workout_today=True,
            today_workout=today_workout,
        )

        assert response.has_workout_today is True
        assert response.today_workout is not None
        assert response.next_workout is None

    def test_response_with_next_workout(self):
        """Should create response with next workout on rest day."""
        next_workout = TodayWorkoutSummary(
            id="workout-456",
            name="Tomorrow's Workout",
            type="strength",
            difficulty="medium",
            duration_minutes=45,
            exercise_count=4,
            primary_muscles=["Legs"],
            scheduled_date="2024-01-16",
            is_today=False,
            is_completed=False,
        )

        response = TodayWorkoutResponse(
            has_workout_today=False,
            next_workout=next_workout,
            rest_day_message="Rest day! Next workout tomorrow.",
            days_until_next=1,
        )

        assert response.has_workout_today is False
        assert response.today_workout is None
        assert response.next_workout is not None
        assert response.days_until_next == 1

    def test_response_with_no_workouts(self):
        """Should create response with no workouts scheduled."""
        response = TodayWorkoutResponse(
            has_workout_today=False,
            rest_day_message="No upcoming workouts scheduled.",
        )

        assert response.has_workout_today is False
        assert response.today_workout is None
        assert response.next_workout is None
        assert response.days_until_next is None
