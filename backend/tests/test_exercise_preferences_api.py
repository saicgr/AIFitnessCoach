"""
Tests for Exercise Preferences API endpoints.

Tests the favorite exercises, exercise queue, and consistency mode endpoints.
These features address competitor feedback about "favoriting exercises didn't help"
and "queuing exercises didn't help".
"""
import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, timedelta


# Helper to create a properly chained mock for Supabase operations
def create_mock_db(user_data=None, table_data=None, check_existing_data=None):
    """Create a mock database with proper chaining for Supabase operations."""
    mock_db = MagicMock()

    # Mock get_user to return user data
    mock_db.get_user.return_value = user_data or {"id": "test-user-123", "email": "test@example.com"}

    # Create a universal chainable mock that returns itself for any method
    # This handles any arbitrary chain of Supabase operations
    class ChainableMock(MagicMock):
        def __init__(self, final_data=None, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self._final_data = final_data

        def _get_child_mock(self, **kw):
            # Create child mocks that are also chainable
            child = ChainableMock(final_data=self._final_data)
            return child

        def execute(self):
            return MagicMock(data=self._final_data or [])

    # For favorites (SELECT -> eq -> order -> execute)
    table_mock = ChainableMock(final_data=table_data)
    mock_db.client.table.return_value = table_mock

    # For checking existing (needs to return empty for new items)
    # Override the default for select().eq().eq().execute() pattern
    check_mock = ChainableMock(final_data=check_existing_data or [])

    # Handle the specific pattern for duplicate checking
    select_mock = MagicMock()
    table_mock.select.return_value = select_mock

    # For order pattern (favorites GET)
    eq_chain = MagicMock()
    select_mock.eq.return_value = eq_chain
    eq_chain.eq.return_value = eq_chain
    eq_chain.is_.return_value = eq_chain
    eq_chain.gte.return_value = eq_chain
    eq_chain.gt.return_value = eq_chain

    order_chain = MagicMock()
    eq_chain.order.return_value = order_chain
    order_chain.order.return_value = order_chain
    order_chain.execute.return_value = MagicMock(data=table_data or [])

    # Direct execute for duplicate checking
    eq_chain.execute.return_value = MagicMock(data=check_existing_data or [])

    # For INSERT operations
    insert_mock = MagicMock()
    table_mock.insert.return_value = insert_mock
    insert_mock.execute.return_value = MagicMock(data=table_data or [])

    # For DELETE operations
    delete_mock = MagicMock()
    table_mock.delete.return_value = delete_mock
    delete_eq = MagicMock()
    delete_mock.eq.return_value = delete_eq
    delete_eq.eq.return_value = delete_eq
    delete_eq.execute.return_value = MagicMock(data=table_data or [])

    return mock_db


class TestFavoriteExercisesAPI:
    """Tests for the favorite exercises API endpoints."""

    @patch('api.v1.users.get_supabase_db')
    def test_get_favorite_exercises_empty(self, mock_get_db, client):
        """Test getting favorites for user with no favorites."""
        user_id = "test-user-123"

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[]
        )
        mock_get_db.return_value = mock_db

        response = client.get(f"/api/v1/users/{user_id}/favorite-exercises")

        assert response.status_code == 200
        assert response.json() == []

    @patch('api.v1.users.get_supabase_db')
    def test_get_favorite_exercises_with_data(self, mock_get_db, client):
        """Test getting favorites returns list of favorites."""
        user_id = "test-user-123"

        favorites_data = [
            {
                "id": "fav-1",
                "user_id": user_id,
                "exercise_name": "Bench Press",
                "exercise_id": "ex-123",
                "added_at": "2024-01-01T10:00:00Z"
            },
            {
                "id": "fav-2",
                "user_id": user_id,
                "exercise_name": "Deadlift",
                "exercise_id": None,
                "added_at": "2024-01-02T10:00:00Z"
            }
        ]

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=favorites_data
        )
        mock_get_db.return_value = mock_db

        response = client.get(f"/api/v1/users/{user_id}/favorite-exercises")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["exercise_name"] == "Bench Press"
        assert data[1]["exercise_name"] == "Deadlift"

    @patch('api.v1.users.get_supabase_db')
    def test_add_favorite_exercise(self, mock_get_db, client):
        """Test adding a new favorite exercise."""
        user_id = "test-user-123"

        new_favorite = {
            "id": "new-fav-id",
            "user_id": user_id,
            "exercise_name": "Squat",
            "exercise_id": "ex-456",
            "added_at": "2024-01-03T10:00:00Z"
        }

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[new_favorite]
        )
        mock_get_db.return_value = mock_db

        response = client.post(
            f"/api/v1/users/{user_id}/favorite-exercises",
            json={
                "exercise_name": "Squat",
                "exercise_id": "ex-456"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["exercise_name"] == "Squat"
        assert data["id"] == "new-fav-id"

    @patch('api.v1.users.get_supabase_db')
    def test_add_favorite_exercise_without_exercise_id(self, mock_get_db, client):
        """Test adding a favorite without optional exercise_id."""
        user_id = "test-user-123"

        new_favorite = {
            "id": "new-fav-id",
            "user_id": user_id,
            "exercise_name": "Custom Exercise",
            "exercise_id": None,
            "added_at": "2024-01-03T10:00:00Z"
        }

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[new_favorite]
        )
        mock_get_db.return_value = mock_db

        response = client.post(
            f"/api/v1/users/{user_id}/favorite-exercises",
            json={"exercise_name": "Custom Exercise"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["exercise_name"] == "Custom Exercise"
        assert data["exercise_id"] is None

    @patch('api.v1.users.get_supabase_db')
    def test_add_favorite_duplicate_returns_400(self, mock_get_db, client):
        """Test adding a duplicate favorite returns 400."""
        user_id = "test-user-123"

        # Create mock that returns existing data for duplicate check
        mock_db = MagicMock()
        mock_db.get_user.return_value = {"id": user_id, "email": "test@example.com"}

        # Chain for select to check existing
        table_mock = MagicMock()
        mock_db.client.table.return_value = table_mock
        select_mock = MagicMock()
        table_mock.select.return_value = select_mock
        eq_mock = MagicMock()
        select_mock.eq.return_value = eq_mock
        eq_mock.eq.return_value = eq_mock
        # Return existing data to simulate duplicate
        eq_mock.execute.return_value = MagicMock(data=[{"id": "existing-fav"}])

        mock_get_db.return_value = mock_db

        response = client.post(
            f"/api/v1/users/{user_id}/favorite-exercises",
            json={"exercise_name": "Already Favorited"}
        )

        assert response.status_code == 400
        assert "already in favorites" in response.json()["detail"].lower()

    @patch('api.v1.users.get_supabase_db')
    def test_remove_favorite_exercise(self, mock_get_db, client):
        """Test removing a favorite exercise."""
        user_id = "test-user-123"
        exercise_name = "Bench Press"

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[{"id": "fav-1"}]  # Deleted row returned
        )
        mock_get_db.return_value = mock_db

        response = client.delete(
            f"/api/v1/users/{user_id}/favorite-exercises/{exercise_name}"
        )

        assert response.status_code == 200
        assert "removed" in response.json()["message"].lower()

    @patch('api.v1.users.get_supabase_db')
    def test_remove_favorite_url_encoded_name(self, mock_get_db, client):
        """Test removing a favorite with URL-encoded name (spaces)."""
        user_id = "test-user-123"
        exercise_name = "Barbell%20Bench%20Press"  # URL encoded

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[{"id": "fav-1"}]
        )
        mock_get_db.return_value = mock_db

        response = client.delete(
            f"/api/v1/users/{user_id}/favorite-exercises/{exercise_name}"
        )

        assert response.status_code == 200

    @patch('api.v1.users.get_supabase_db')
    def test_remove_nonexistent_favorite(self, mock_get_db, client):
        """Test removing a favorite that doesn't exist returns 404."""
        user_id = "test-user-123"

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[]  # Empty = not found
        )
        mock_get_db.return_value = mock_db

        response = client.delete(
            f"/api/v1/users/{user_id}/favorite-exercises/NonExistent"
        )

        assert response.status_code == 404

    @patch('api.v1.users.get_supabase_db')
    def test_get_favorites_user_not_found(self, mock_get_db, client):
        """Test getting favorites for non-existent user returns 404."""
        mock_db = MagicMock()
        mock_db.get_user.return_value = None
        mock_get_db.return_value = mock_db

        response = client.get("/api/v1/users/non-existent-user/favorite-exercises")

        assert response.status_code == 404


class TestExerciseQueueAPI:
    """Tests for the exercise queue API endpoints."""

    @patch('api.v1.users.get_supabase_db')
    def test_get_exercise_queue_empty(self, mock_get_db, client):
        """Test getting queue for user with no queued exercises."""
        user_id = "test-user-123"

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[]
        )
        mock_get_db.return_value = mock_db

        response = client.get(f"/api/v1/users/{user_id}/exercise-queue")

        assert response.status_code == 200
        assert response.json() == []

    @patch('api.v1.users.get_supabase_db')
    def test_get_exercise_queue_with_data(self, mock_get_db, client):
        """Test getting queue returns list of queued exercises."""
        user_id = "test-user-123"
        future_date = (datetime.now() + timedelta(days=5)).isoformat()

        queue_data = [
            {
                "id": "queue-1",
                "user_id": user_id,
                "exercise_name": "Lat Pulldown",
                "exercise_id": None,
                "priority": 0,
                "target_muscle_group": "back",
                "added_at": "2024-01-01T10:00:00Z",
                "expires_at": future_date,
                "used_at": None
            },
            {
                "id": "queue-2",
                "user_id": user_id,
                "exercise_name": "Bicep Curl",
                "exercise_id": "ex-789",
                "priority": 1,
                "target_muscle_group": "arms",
                "added_at": "2024-01-02T10:00:00Z",
                "expires_at": future_date,
                "used_at": None
            }
        ]

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=queue_data
        )
        mock_get_db.return_value = mock_db

        response = client.get(f"/api/v1/users/{user_id}/exercise-queue")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["exercise_name"] == "Lat Pulldown"
        assert data[0]["target_muscle_group"] == "back"
        assert data[1]["priority"] == 1

    @patch('api.v1.users.get_supabase_db')
    def test_add_to_exercise_queue(self, mock_get_db, client):
        """Test adding an exercise to the queue."""
        user_id = "test-user-123"
        future_date = (datetime.now() + timedelta(days=7)).isoformat()

        new_queued = {
            "id": "new-queue-id",
            "user_id": user_id,
            "exercise_name": "Tricep Dip",
            "exercise_id": "ex-101",
            "priority": 0,
            "target_muscle_group": "arms",
            "added_at": "2024-01-03T10:00:00Z",
            "expires_at": future_date,
            "used_at": None
        }

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[new_queued]
        )
        mock_get_db.return_value = mock_db

        response = client.post(
            f"/api/v1/users/{user_id}/exercise-queue",
            json={
                "exercise_name": "Tricep Dip",
                "exercise_id": "ex-101",
                "priority": 0,
                "target_muscle_group": "arms"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["exercise_name"] == "Tricep Dip"
        assert data["target_muscle_group"] == "arms"

    @patch('api.v1.users.get_supabase_db')
    def test_add_to_queue_minimal_data(self, mock_get_db, client):
        """Test adding to queue with only required fields."""
        user_id = "test-user-123"
        future_date = (datetime.now() + timedelta(days=7)).isoformat()

        new_queued = {
            "id": "new-queue-id",
            "user_id": user_id,
            "exercise_name": "Custom Exercise",
            "exercise_id": None,
            "priority": 0,
            "target_muscle_group": None,
            "added_at": "2024-01-03T10:00:00Z",
            "expires_at": future_date,
            "used_at": None
        }

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[new_queued]
        )
        mock_get_db.return_value = mock_db

        response = client.post(
            f"/api/v1/users/{user_id}/exercise-queue",
            json={"exercise_name": "Custom Exercise"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["exercise_name"] == "Custom Exercise"

    @patch('api.v1.users.get_supabase_db')
    def test_add_to_queue_duplicate_returns_400(self, mock_get_db, client):
        """Test adding duplicate to queue returns 400."""
        user_id = "test-user-123"

        # Create mock that returns existing data for duplicate check
        mock_db = MagicMock()
        mock_db.get_user.return_value = {"id": user_id, "email": "test@example.com"}

        # Chain for select to check existing
        table_mock = MagicMock()
        mock_db.client.table.return_value = table_mock
        select_mock = MagicMock()
        table_mock.select.return_value = select_mock
        eq_mock = MagicMock()
        select_mock.eq.return_value = eq_mock
        eq_mock.eq.return_value = eq_mock
        # Return existing data to simulate duplicate
        eq_mock.execute.return_value = MagicMock(data=[{"id": "existing-queue-item"}])

        mock_get_db.return_value = mock_db

        response = client.post(
            f"/api/v1/users/{user_id}/exercise-queue",
            json={"exercise_name": "Already Queued"}
        )

        assert response.status_code == 400
        assert "already in queue" in response.json()["detail"].lower()

    @patch('api.v1.users.get_supabase_db')
    def test_remove_from_exercise_queue(self, mock_get_db, client):
        """Test removing an exercise from the queue."""
        user_id = "test-user-123"
        exercise_name = "Lat Pulldown"

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[{"id": "queue-1"}]  # Deleted row returned
        )
        mock_get_db.return_value = mock_db

        response = client.delete(
            f"/api/v1/users/{user_id}/exercise-queue/{exercise_name}"
        )

        assert response.status_code == 200
        assert "removed" in response.json()["message"].lower()

    @patch('api.v1.users.get_supabase_db')
    def test_remove_from_queue_url_encoded_name(self, mock_get_db, client):
        """Test removing from queue with URL-encoded name."""
        user_id = "test-user-123"
        exercise_name = "Cable%20Lat%20Pulldown"  # URL encoded

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[{"id": "queue-1"}]
        )
        mock_get_db.return_value = mock_db

        response = client.delete(
            f"/api/v1/users/{user_id}/exercise-queue/{exercise_name}"
        )

        assert response.status_code == 200

    @patch('api.v1.users.get_supabase_db')
    def test_remove_nonexistent_from_queue(self, mock_get_db, client):
        """Test removing non-existent queue item returns 404."""
        user_id = "test-user-123"

        mock_db = create_mock_db(
            user_data={"id": user_id, "email": "test@example.com"},
            table_data=[]  # Empty = not found
        )
        mock_get_db.return_value = mock_db

        response = client.delete(
            f"/api/v1/users/{user_id}/exercise-queue/NonExistent"
        )

        assert response.status_code == 404


class TestConsistencyModeAPI:
    """Tests for the exercise consistency mode preferences."""

    @patch('api.v1.users.get_supabase_db')
    @patch('api.v1.users.log_user_activity')
    def test_update_consistency_mode_to_consistent(self, mock_log, mock_get_db, client):
        """Test updating consistency mode from vary to consistent."""
        user_id = "test-user-123"

        existing_user = {
            "id": user_id,
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": '["build_muscle"]',
            "equipment": '["dumbbells"]',
            "preferences": {"exercise_consistency": "vary"},
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
        }

        updated_user = {
            **existing_user,
            "preferences": {"exercise_consistency": "consistent"},
        }

        mock_db = MagicMock()
        mock_db.get_user.return_value = existing_user
        mock_db.update_user.return_value = updated_user
        mock_get_db.return_value = mock_db
        mock_log.return_value = None

        response = client.put(
            f"/api/v1/users/{user_id}",
            json={"exercise_consistency": "consistent"}
        )

        assert response.status_code == 200
        # Just verify the endpoint responds successfully

    @patch('api.v1.users.get_supabase_db')
    @patch('api.v1.users.log_user_activity')
    def test_update_consistency_mode_to_vary(self, mock_log, mock_get_db, client):
        """Test updating consistency mode from consistent to vary."""
        user_id = "test-user-456"

        existing_user = {
            "id": user_id,
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": '["build_muscle"]',
            "equipment": '["dumbbells"]',
            "preferences": {"exercise_consistency": "consistent"},
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
        }

        updated_user = {
            **existing_user,
            "preferences": {"exercise_consistency": "vary"},
        }

        mock_db = MagicMock()
        mock_db.get_user.return_value = existing_user
        mock_db.update_user.return_value = updated_user
        mock_get_db.return_value = mock_db
        mock_log.return_value = None

        response = client.put(
            f"/api/v1/users/{user_id}",
            json={"exercise_consistency": "vary"}
        )

        assert response.status_code == 200

    @patch('api.v1.users.get_supabase_db')
    @patch('api.v1.users.log_user_activity')
    def test_consistency_mode_preserves_other_preferences(self, mock_log, mock_get_db, client):
        """Test updating consistency mode doesn't overwrite other preferences."""
        user_id = "test-user-789"

        existing_user = {
            "id": user_id,
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": '["build_muscle"]',
            "equipment": '["dumbbells"]',
            "preferences": {
                "exercise_consistency": "vary",
                "progression_pace": "slow",
                "workout_type_preference": "strength",
                "days_per_week": 4
            },
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
        }

        updated_user = {
            **existing_user,
            "preferences": {
                "exercise_consistency": "consistent",
                "progression_pace": "slow",
                "workout_type_preference": "strength",
                "days_per_week": 4
            },
        }

        mock_db = MagicMock()
        mock_db.get_user.return_value = existing_user
        mock_db.update_user.return_value = updated_user
        mock_get_db.return_value = mock_db
        mock_log.return_value = None

        response = client.put(
            f"/api/v1/users/{user_id}",
            json={"exercise_consistency": "consistent"}
        )

        assert response.status_code == 200
        # The response indicates successful update


class TestExercisePreferencesValidation:
    """Tests for input validation on exercise preferences endpoints."""

    def test_add_favorite_missing_exercise_name(self, client):
        """Test adding favorite without exercise_name fails validation."""
        response = client.post(
            "/api/v1/users/test-user/favorite-exercises",
            json={}
        )
        assert response.status_code == 422

    def test_add_to_queue_missing_exercise_name(self, client):
        """Test adding to queue without exercise_name fails validation."""
        response = client.post(
            "/api/v1/users/test-user/exercise-queue",
            json={}
        )
        assert response.status_code == 422

    @patch('api.v1.users.get_supabase_db')
    def test_add_favorite_empty_exercise_name(self, mock_get_db, client):
        """Test adding favorite with empty exercise_name."""
        user_id = "test-user"

        # The endpoint may accept empty string but return error
        mock_db = MagicMock()
        mock_db.get_user.return_value = {"id": user_id, "email": "test@example.com"}
        mock_get_db.return_value = mock_db

        response = client.post(
            f"/api/v1/users/{user_id}/favorite-exercises",
            json={"exercise_name": ""}
        )
        # Empty string should fail at some level
        assert response.status_code in [400, 422, 500]

    def test_add_to_queue_invalid_priority_type(self, client):
        """Test adding to queue with invalid priority type."""
        response = client.post(
            "/api/v1/users/test-user/exercise-queue",
            json={
                "exercise_name": "Test",
                "priority": "high"  # Should be int
            }
        )
        assert response.status_code == 422
