"""
Tests for Smart Scheduling API endpoints.

Tests cover:
- GET /scheduling/missed - Get missed workouts
- POST /scheduling/reschedule - Reschedule a workout
- POST /scheduling/skip - Skip a workout
- GET /scheduling/suggestions - Get AI suggestions
- GET /scheduling/skip-reasons - Get skip reason categories
- POST /scheduling/detect-missed - Trigger missed detection
- GET /scheduling/preferences - Get user preferences
- PUT /scheduling/preferences - Update user preferences
- GET /scheduling/history - Get scheduling history
"""

import pytest
from datetime import datetime, date, timedelta
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

# Mock Supabase before importing the router
@pytest.fixture(autouse=True)
def mock_supabase():
    """Mock Supabase client for all tests."""
    with patch('api.v1.scheduling.get_supabase_db') as mock_db:
        mock_client = MagicMock()
        mock_db.return_value.client = mock_client
        yield mock_client


@pytest.fixture
def client():
    """Create test client."""
    from fastapi import FastAPI
    from api.v1.scheduling import router

    app = FastAPI()
    app.include_router(router, prefix="/scheduling")

    return TestClient(app)


@pytest.fixture
def sample_user_id():
    return "test-user-123"


@pytest.fixture
def sample_workout():
    """Sample workout data for testing."""
    return {
        "id": "workout-123",
        "user_id": "test-user-123",
        "name": "Upper Body Strength",
        "type": "strength",
        "difficulty": "intermediate",
        "scheduled_date": (datetime.now() - timedelta(days=2)).isoformat(),
        "is_completed": False,
        "status": "missed",
        "duration_minutes": 45,
        "reschedule_count": 0,
        "exercises_json": '[{"name": "Bench Press", "sets": 3, "reps": 10}]',
    }


class TestGetMissedWorkouts:
    """Tests for GET /scheduling/missed endpoint."""

    def test_get_missed_workouts_success(self, client, mock_supabase, sample_user_id, sample_workout):
        """Test successful retrieval of missed workouts."""
        # Setup mock
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.or_.return_value.gte.return_value.lt.return_value.order.return_value.execute.return_value.data = [sample_workout]
        mock_supabase.rpc.return_value.execute.return_value = MagicMock()

        response = client.get(
            f"/scheduling/missed?user_id={sample_user_id}&days_back=7"
        )

        assert response.status_code == 200
        data = response.json()
        assert "missed_workouts" in data
        assert "total_count" in data

    def test_get_missed_workouts_empty(self, client, mock_supabase, sample_user_id):
        """Test when no missed workouts exist."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.or_.return_value.gte.return_value.lt.return_value.order.return_value.execute.return_value.data = []
        mock_supabase.rpc.return_value.execute.return_value = MagicMock()

        response = client.get(
            f"/scheduling/missed?user_id={sample_user_id}&days_back=7"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["missed_workouts"] == []
        assert data["total_count"] == 0

    def test_get_missed_workouts_requires_user_id(self, client):
        """Test that user_id is required."""
        response = client.get("/scheduling/missed")
        assert response.status_code == 422  # Validation error


class TestRescheduleWorkout:
    """Tests for POST /scheduling/reschedule endpoint."""

    def test_reschedule_workout_success(self, client, mock_supabase, sample_workout):
        """Test successful workout rescheduling."""
        # Setup mocks
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = sample_workout
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()
        mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock()

        new_date = date.today().isoformat()
        response = client.post(
            "/scheduling/reschedule",
            json={
                "workout_id": "workout-123",
                "new_date": new_date,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["workout_id"] == "workout-123"
        assert data["new_date"] == new_date

    def test_reschedule_workout_not_found(self, client, mock_supabase):
        """Test reschedule with non-existent workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        response = client.post(
            "/scheduling/reschedule",
            json={
                "workout_id": "nonexistent",
                "new_date": date.today().isoformat(),
            }
        )

        assert response.status_code == 404

    def test_reschedule_completed_workout_fails(self, client, mock_supabase, sample_workout):
        """Test that completed workouts cannot be rescheduled."""
        completed_workout = {**sample_workout, "is_completed": True}
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = completed_workout

        response = client.post(
            "/scheduling/reschedule",
            json={
                "workout_id": "workout-123",
                "new_date": date.today().isoformat(),
            }
        )

        assert response.status_code == 400
        assert "completed" in response.json()["detail"].lower()

    def test_reschedule_to_past_date_fails(self, client, mock_supabase, sample_workout):
        """Test that rescheduling to a past date fails."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = sample_workout

        past_date = (date.today() - timedelta(days=1)).isoformat()
        response = client.post(
            "/scheduling/reschedule",
            json={
                "workout_id": "workout-123",
                "new_date": past_date,
            }
        )

        assert response.status_code == 400
        assert "past" in response.json()["detail"].lower()

    def test_reschedule_invalid_date_format(self, client):
        """Test reschedule with invalid date format."""
        response = client.post(
            "/scheduling/reschedule",
            json={
                "workout_id": "workout-123",
                "new_date": "invalid-date",
            }
        )

        assert response.status_code == 400


class TestSkipWorkout:
    """Tests for POST /scheduling/skip endpoint."""

    def test_skip_workout_success(self, client, mock_supabase, sample_workout):
        """Test successful workout skip."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = sample_workout
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()
        mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock()

        response = client.post(
            "/scheduling/skip",
            json={
                "workout_id": "workout-123",
                "reason_category": "too_busy",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["workout_id"] == "workout-123"

    def test_skip_workout_without_reason(self, client, mock_supabase, sample_workout):
        """Test skip without providing a reason."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = sample_workout
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()
        mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock()

        response = client.post(
            "/scheduling/skip",
            json={"workout_id": "workout-123"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_skip_completed_workout_fails(self, client, mock_supabase, sample_workout):
        """Test that completed workouts cannot be skipped."""
        completed_workout = {**sample_workout, "is_completed": True}
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = completed_workout

        response = client.post(
            "/scheduling/skip",
            json={"workout_id": "workout-123"}
        )

        assert response.status_code == 400


class TestGetSchedulingSuggestions:
    """Tests for GET /scheduling/suggestions endpoint."""

    def test_get_suggestions_success(self, client, mock_supabase, sample_user_id, sample_workout):
        """Test successful retrieval of scheduling suggestions."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = sample_workout
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.return_value.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []

        response = client.get(
            f"/scheduling/suggestions?workout_id=workout-123&user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert "suggestions" in data
        assert "workout_name" in data
        assert len(data["suggestions"]) > 0

    def test_get_suggestions_workout_not_found(self, client, mock_supabase, sample_user_id):
        """Test suggestions for non-existent workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        response = client.get(
            f"/scheduling/suggestions?workout_id=nonexistent&user_id={sample_user_id}"
        )

        assert response.status_code == 404


class TestGetSkipReasons:
    """Tests for GET /scheduling/skip-reasons endpoint."""

    def test_get_skip_reasons_success(self, client, mock_supabase):
        """Test successful retrieval of skip reasons."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
            {"id": "too_busy", "display_name": "Too Busy", "emoji": "📅"},
            {"id": "feeling_unwell", "display_name": "Feeling Unwell", "emoji": "🤒"},
        ]

        response = client.get("/scheduling/skip-reasons")

        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 2
        assert data[0]["id"] == "too_busy"

    def test_get_skip_reasons_fallback(self, client, mock_supabase):
        """Test fallback skip reasons when database fails."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.side_effect = Exception("DB error")

        response = client.get("/scheduling/skip-reasons")

        assert response.status_code == 200
        data = response.json()
        # Should return default reasons
        assert len(data) > 0
        assert any(r["id"] == "too_busy" for r in data)


class TestDetectMissedWorkouts:
    """Tests for POST /scheduling/detect-missed endpoint."""

    def test_detect_missed_success(self, client, mock_supabase, sample_user_id):
        """Test successful missed workout detection."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.lt.return_value.execute.return_value.data = [
            {"id": "workout-1"},
            {"id": "workout-2"},
        ]
        mock_supabase.table.return_value.update.return_value.in_.return_value.execute.return_value = MagicMock()

        response = client.post(
            f"/scheduling/detect-missed?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["marked_missed"] == 2

    def test_detect_missed_no_workouts(self, client, mock_supabase, sample_user_id):
        """Test detection when no workouts to mark."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.lt.return_value.execute.return_value.data = []

        response = client.post(
            f"/scheduling/detect-missed?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["marked_missed"] == 0


class TestSchedulingPreferences:
    """Tests for scheduling preferences endpoints."""

    def test_get_preferences_success(self, client, mock_supabase, sample_user_id):
        """Test getting scheduling preferences."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "auto_detect_missed": True,
            "missed_notification_enabled": True,
            "max_reschedule_days": 3,
        }

        response = client.get(f"/scheduling/preferences?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["auto_detect_missed"] is True
        assert data["max_reschedule_days"] == 3

    def test_get_preferences_defaults(self, client, mock_supabase, sample_user_id):
        """Test default preferences when none exist."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = Exception("Not found")

        response = client.get(f"/scheduling/preferences?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        # Should return defaults
        assert data["auto_detect_missed"] is True
        assert data["max_reschedule_days"] == 3

    def test_update_preferences(self, client, mock_supabase, sample_user_id):
        """Test updating scheduling preferences."""
        mock_supabase.table.return_value.upsert.return_value.execute.return_value = MagicMock()

        response = client.put(
            f"/scheduling/preferences?user_id={sample_user_id}",
            json={
                "auto_detect_missed": False,
                "max_reschedule_days": 5,
                "allow_same_day_swap": True,
                "prefer_swap_similar_type": True,
                "track_skip_patterns": True,
                "missed_notification_enabled": True,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["auto_detect_missed"] is False
        assert data["max_reschedule_days"] == 5


class TestSchedulingHistory:
    """Tests for GET /scheduling/history endpoint."""

    def test_get_history_success(self, client, mock_supabase, sample_user_id):
        """Test successful retrieval of scheduling history."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value.data = [
            {
                "id": "history-1",
                "workout_id": "workout-123",
                "action_type": "skip",
                "original_date": "2024-01-01",
                "reason_category": "too_busy",
                "created_at": datetime.now().isoformat(),
                "workouts": {"name": "Upper Body"},
            }
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.count = 1

        response = client.get(f"/scheduling/history?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert "history" in data
        assert data["total_count"] >= 0

    def test_get_history_empty(self, client, mock_supabase, sample_user_id):
        """Test history when no records exist."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.count = 0

        response = client.get(f"/scheduling/history?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["history"] == []
        assert data["total_count"] == 0


class TestRescheduleWithSwap:
    """Tests for rescheduling with workout swap."""

    def test_reschedule_with_swap_success(self, client, mock_supabase, sample_workout):
        """Test successful reschedule with swap."""
        swap_workout = {
            "id": "workout-456",
            "user_id": "test-user-123",
            "name": "Leg Day",
            "scheduled_date": datetime.now().isoformat(),
            "is_completed": False,
        }

        # First call for main workout, second for swap workout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
            MagicMock(data=sample_workout),
            MagicMock(data=swap_workout),
        ]
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()
        mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock()

        response = client.post(
            "/scheduling/reschedule",
            json={
                "workout_id": "workout-123",
                "new_date": date.today().isoformat(),
                "swap_with_workout_id": "workout-456",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["swapped_with"] == "workout-456"
        assert data["swapped_workout_name"] == "Leg Day"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
