"""
Tests for Saved Workouts API endpoints.

Tests:
- Save workouts from activity feed
- Get saved workouts
- Update/delete saved workouts
- Challenge tracking
- Workout badges
- Scheduled workouts
- Calendar view

Run with: pytest backend/tests/test_saved_workouts_api.py -v
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, date, time, timezone, timedelta
import uuid

from main import app
from models.saved_workouts import (
    ScheduledWorkoutStatus, DifficultyLevel,
)


client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Mock Supabase client for testing."""
    with patch('api.v1.saved_workouts.get_supabase') as mock:
        supabase_mock = MagicMock()
        mock.return_value.client = supabase_mock
        yield supabase_mock


@pytest.fixture
def mock_social_rag():
    """Mock Social RAG service for testing."""
    with patch('api.v1.saved_workouts.get_social_rag_service') as mock:
        rag_mock = MagicMock()
        collection_mock = MagicMock()
        rag_mock.get_social_collection.return_value = collection_mock
        mock.return_value = rag_mock
        yield rag_mock, collection_mock


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_activity_id():
    """Sample activity ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_saved_workout_id():
    """Sample saved workout ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_activity_data():
    """Sample activity data with workout information."""
    return {
        "user_id": str(uuid.uuid4()),
        "activity_type": "workout_completed",
        "activity_data": {
            "workout_name": "Full Body Blast",
            "duration_minutes": 60,
            "exercises_count": 8,
            "total_volume": 8500,
            "exercises_performance": [
                {"name": "Squats", "sets": 4, "reps": 10, "weight_kg": 100},
                {"name": "Bench Press", "sets": 4, "reps": 8, "weight_kg": 80},
                {"name": "Deadlifts", "sets": 3, "reps": 5, "weight_kg": 140},
            ]
        },
        "users": {
            "name": "Friend User",
            "avatar_url": "https://example.com/avatar.jpg"
        }
    }


@pytest.fixture
def sample_exercises():
    """Sample exercises list."""
    return [
        {"name": "Squats", "sets": 4, "reps": 10, "weight_kg": 100, "rest_seconds": 60},
        {"name": "Bench Press", "sets": 4, "reps": 8, "weight_kg": 80, "rest_seconds": 90},
    ]


# ============================================================
# CHALLENGE TRACKING TESTS
# ============================================================

class TestChallengeTracking:
    """Test challenge click tracking."""

    def test_track_challenge_click_new(self, mock_supabase, mock_social_rag, sample_user_id, sample_activity_id):
        """Test tracking a new challenge click."""
        rag_mock, collection_mock = mock_social_rag

        # Mock no existing share entry
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        # Mock activity lookup
        activity_mock = MagicMock()
        activity_mock.execute.return_value.data = [{"user_id": str(uuid.uuid4())}]
        mock_supabase.table.return_value.select.return_value.eq.return_value = MagicMock()
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"user_id": str(uuid.uuid4())}
        ]

        # Mock insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{}]

        # Mock user name lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Test User"}
        ]

        response = client.post(
            f"/api/v1/saved-workouts/challenge/{sample_activity_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["challenge_count"] == 1
        assert "tracked" in data["message"].lower()

    def test_track_challenge_click_existing(self, mock_supabase, mock_social_rag, sample_user_id, sample_activity_id):
        """Test tracking challenge click on existing share entry."""
        rag_mock, collection_mock = mock_social_rag
        share_id = str(uuid.uuid4())

        # Mock existing share entry
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "id": share_id,
            "challenge_count": 5,
        }]

        # Mock update
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": share_id,
            "challenge_count": 6,
        }]

        # Mock user name lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Test User"}
        ]

        response = client.post(
            f"/api/v1/saved-workouts/challenge/{sample_activity_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["challenge_count"] == 6

    def test_track_challenge_activity_not_found(self, mock_supabase, sample_user_id, sample_activity_id):
        """Test tracking challenge for non-existent activity."""
        # Mock no share entry
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        # Mock no activity found
        activity_mock = MagicMock()
        activity_mock.execute.return_value.data = []

        # Chain the mock properly
        table_mock = MagicMock()
        table_mock.select.return_value.eq.return_value.execute.return_value.data = []
        mock_supabase.table.return_value = table_mock

        response = client.post(
            f"/api/v1/saved-workouts/challenge/{sample_activity_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 404


# ============================================================
# WORKOUT BADGES TESTS
# ============================================================

class TestWorkoutBadges:
    """Test workout badge retrieval."""

    def test_get_badges_trending(self, mock_supabase, sample_activity_id):
        """Test getting badges for a trending workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "is_trending": True,
            "is_hall_of_fame": False,
            "is_most_copied": False,
            "is_beast_mode": False,
            "share_count": 25,
            "challenge_count": 10,
            "completion_count": 20,
        }]

        response = client.get(f"/api/v1/saved-workouts/badges/{sample_activity_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["activity_id"] == sample_activity_id
        assert len(data["badges"]) >= 1
        assert any(b["type"] == "trending" for b in data["badges"])

    def test_get_badges_hall_of_fame(self, mock_supabase, sample_activity_id):
        """Test getting Hall of Fame badge for popular workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "is_trending": False,
            "is_hall_of_fame": True,
            "is_most_copied": False,
            "is_beast_mode": False,
            "share_count": 150,
            "challenge_count": 30,
            "completion_count": 100,
        }]

        response = client.get(f"/api/v1/saved-workouts/badges/{sample_activity_id}")

        assert response.status_code == 200
        data = response.json()
        assert any(b["type"] == "hall_of_fame" for b in data["badges"])

    def test_get_badges_beast_mode(self, mock_supabase, sample_activity_id):
        """Test getting Beast Mode badge for highly challenged workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "is_trending": False,
            "is_hall_of_fame": False,
            "is_most_copied": False,
            "is_beast_mode": True,
            "share_count": 20,
            "challenge_count": 75,
            "completion_count": 10,
        }]

        response = client.get(f"/api/v1/saved-workouts/badges/{sample_activity_id}")

        assert response.status_code == 200
        data = response.json()
        assert any(b["type"] == "beast_mode" for b in data["badges"])

    def test_get_badges_no_badges(self, mock_supabase, sample_activity_id):
        """Test getting badges when workout has none."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "is_trending": False,
            "is_hall_of_fame": False,
            "is_most_copied": False,
            "is_beast_mode": False,
            "share_count": 5,
            "challenge_count": 2,
            "completion_count": 3,
        }]

        response = client.get(f"/api/v1/saved-workouts/badges/{sample_activity_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["badges"] == []

    def test_get_badges_no_share_data(self, mock_supabase, sample_activity_id):
        """Test getting badges when no share data exists."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.get(f"/api/v1/saved-workouts/badges/{sample_activity_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["share_count"] == 0
        assert data["challenge_count"] == 0


# ============================================================
# SAVE WORKOUT FROM ACTIVITY TESTS
# ============================================================

class TestSaveWorkoutFromActivity:
    """Test saving workouts from activity feed."""

    def test_save_workout_success(self, mock_supabase, mock_social_rag, sample_user_id, sample_activity_id, sample_activity_data):
        """Test successfully saving a workout from activity."""
        rag_mock, collection_mock = mock_social_rag
        saved_workout_id = str(uuid.uuid4())

        # Mock activity lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [sample_activity_data]

        # Mock no existing save
        check_mock = MagicMock()
        check_mock.execute.return_value.data = []

        # Mock insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": saved_workout_id,
            "user_id": sample_user_id,
            "source_activity_id": sample_activity_id,
            "source_user_id": sample_activity_data["user_id"],
            "workout_name": "Full Body Blast",
            "workout_description": "Saved from Friend User's workout",
            "exercises": sample_activity_data["activity_data"]["exercises_performance"],
            "total_exercises": 3,
            "estimated_duration_minutes": 60,
            "folder": "From Friends",
            "tags": ["friend-workout", "social"],
            "times_completed": 0,
            "saved_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }]

        # Mock user name lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Test User"}
        ]

        response = client.post(
            f"/api/v1/saved-workouts/save-from-activity?user_id={sample_user_id}",
            json={
                "activity_id": sample_activity_id,
                "folder": "From Friends",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == saved_workout_id
        assert data["workout_name"] == "Full Body Blast"

    def test_save_workout_activity_not_found(self, mock_supabase, sample_user_id, sample_activity_id):
        """Test saving from non-existent activity."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.post(
            f"/api/v1/saved-workouts/save-from-activity?user_id={sample_user_id}",
            json={
                "activity_id": sample_activity_id,
            }
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_save_workout_no_workout_data(self, mock_supabase, sample_user_id, sample_activity_id):
        """Test saving from activity without workout data."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "user_id": str(uuid.uuid4()),
            "activity_type": "achievement_earned",
            "activity_data": {"achievement_name": "First Workout"},  # No workout_name
            "users": {"name": "User"}
        }]

        response = client.post(
            f"/api/v1/saved-workouts/save-from-activity?user_id={sample_user_id}",
            json={
                "activity_id": sample_activity_id,
            }
        )

        assert response.status_code == 400
        assert "workout data" in response.json()["detail"].lower()

    def test_save_workout_already_saved(self, mock_supabase, sample_user_id, sample_activity_id, sample_activity_data):
        """Test saving an already saved workout."""
        # First call returns activity data
        # Second call (checking existing) returns existing save
        call_count = [0]

        def mock_execute():
            result = MagicMock()
            call_count[0] += 1
            if call_count[0] == 1:
                result.data = [sample_activity_data]
            else:
                result.data = [{"id": str(uuid.uuid4())}]  # Already exists
            return result

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute = mock_execute
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {"id": str(uuid.uuid4())}
        ]

        response = client.post(
            f"/api/v1/saved-workouts/save-from-activity?user_id={sample_user_id}",
            json={
                "activity_id": sample_activity_id,
            }
        )

        assert response.status_code == 400
        assert "already saved" in response.json()["detail"].lower()


# ============================================================
# GET SAVED WORKOUTS TESTS
# ============================================================

class TestGetSavedWorkouts:
    """Test getting saved workouts."""

    def test_get_saved_workouts_list(self, mock_supabase, sample_user_id):
        """Test getting list of saved workouts."""
        saved_workout_id = str(uuid.uuid4())

        # Mock list query
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(
            data=[{
                "id": saved_workout_id,
                "user_id": sample_user_id,
                "workout_name": "My Workout",
                "workout_description": "Test workout",
                "exercises": [],
                "total_exercises": 5,
                "estimated_duration_minutes": 45,
                "folder": "Favorites",
                "tags": ["strength"],
                "times_completed": 3,
                "saved_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }],
            count=1
        )

        # Mock folders query
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"folder": "Favorites"},
            {"folder": "From Friends"},
        ]

        response = client.get(f"/api/v1/saved-workouts/?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1
        assert len(data["workouts"]) == 1
        assert "Favorites" in data["folders"]

    def test_get_saved_workouts_with_folder_filter(self, mock_supabase, sample_user_id):
        """Test getting saved workouts filtered by folder."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.eq.return_value.range.return_value.execute.return_value = MagicMock(
            data=[],
            count=0
        )

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.get(
            f"/api/v1/saved-workouts/?user_id={sample_user_id}&folder=From%20Friends"
        )

        assert response.status_code == 200

    def test_get_single_saved_workout(self, mock_supabase, sample_user_id, sample_saved_workout_id):
        """Test getting a single saved workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_saved_workout_id,
            "user_id": sample_user_id,
            "workout_name": "Leg Day",
            "workout_description": "Focus on legs",
            "exercises": [{"name": "Squats", "sets": 4, "reps": 10, "weight_kg": 100, "rest_seconds": 60}],
            "total_exercises": 1,
            "folder": "Favorites",
            "tags": [],
            "times_completed": 0,
            "saved_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.get(
            f"/api/v1/saved-workouts/{sample_saved_workout_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_saved_workout_id
        assert data["workout_name"] == "Leg Day"

    def test_get_saved_workout_not_found(self, mock_supabase, sample_user_id, sample_saved_workout_id):
        """Test getting non-existent saved workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        response = client.get(
            f"/api/v1/saved-workouts/{sample_saved_workout_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 404


# ============================================================
# UPDATE/DELETE SAVED WORKOUTS TESTS
# ============================================================

class TestUpdateDeleteSavedWorkouts:
    """Test updating and deleting saved workouts."""

    def test_update_saved_workout(self, mock_supabase, sample_user_id, sample_saved_workout_id):
        """Test updating a saved workout."""
        # Mock ownership check
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"user_id": sample_user_id}
        ]

        # Mock update
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_saved_workout_id,
            "user_id": sample_user_id,
            "workout_name": "Updated Workout",
            "workout_description": "Updated description",
            "exercises": [],
            "total_exercises": 0,
            "folder": "New Folder",
            "tags": ["updated"],
            "times_completed": 0,
            "saved_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.put(
            f"/api/v1/saved-workouts/{sample_saved_workout_id}?user_id={sample_user_id}",
            json={
                "workout_name": "Updated Workout",
                "folder": "New Folder",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["workout_name"] == "Updated Workout"
        assert data["folder"] == "New Folder"

    def test_update_saved_workout_not_owner(self, mock_supabase, sample_user_id, sample_saved_workout_id):
        """Test updating workout not owned by user."""
        other_user_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"user_id": other_user_id}  # Different owner
        ]

        response = client.put(
            f"/api/v1/saved-workouts/{sample_saved_workout_id}?user_id={sample_user_id}",
            json={"workout_name": "Hacked Workout"}
        )

        assert response.status_code == 403

    def test_delete_saved_workout(self, mock_supabase, sample_user_id, sample_saved_workout_id):
        """Test deleting a saved workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"user_id": sample_user_id}
        ]

        mock_supabase.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.delete(
            f"/api/v1/saved-workouts/{sample_saved_workout_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        assert "deleted" in response.json()["message"].lower()

    def test_delete_saved_workout_not_owner(self, mock_supabase, sample_user_id, sample_saved_workout_id):
        """Test deleting workout not owned by user."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"user_id": str(uuid.uuid4())}  # Different owner
        ]

        response = client.delete(
            f"/api/v1/saved-workouts/{sample_saved_workout_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 403


# ============================================================
# DO WORKOUT NOW TESTS
# ============================================================

class TestDoWorkoutNow:
    """Test starting a saved workout immediately."""

    def test_do_workout_now_success(self, mock_supabase, sample_user_id, sample_saved_workout_id, sample_exercises):
        """Test starting a saved workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_saved_workout_id,
            "user_id": sample_user_id,
            "workout_name": "Quick Workout",
            "workout_description": "30 minute session",
            "exercises": sample_exercises,
            "total_exercises": 2,
            "estimated_duration_minutes": 30,
        }]

        response = client.post(
            f"/api/v1/saved-workouts/do-now/{sample_saved_workout_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_saved_workout_id
        assert data["name"] == "Quick Workout"
        assert data["source"] == "saved_workout"
        assert len(data["exercises"]) == 2

    def test_do_workout_now_not_found(self, mock_supabase, sample_user_id, sample_saved_workout_id):
        """Test starting non-existent workout."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        response = client.post(
            f"/api/v1/saved-workouts/do-now/{sample_saved_workout_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 404


# ============================================================
# SCHEDULED WORKOUTS TESTS
# ============================================================

class TestScheduledWorkouts:
    """Test scheduled workout functionality."""

    def test_schedule_workout_from_saved(self, mock_supabase, sample_user_id, sample_saved_workout_id, sample_exercises):
        """Test scheduling a saved workout."""
        scheduled_id = str(uuid.uuid4())
        schedule_date = (datetime.now() + timedelta(days=3)).date()

        # Mock saved workout lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_saved_workout_id,
            "workout_name": "Leg Day",
            "exercises": sample_exercises,
        }]

        # Mock insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": scheduled_id,
            "user_id": sample_user_id,
            "saved_workout_id": sample_saved_workout_id,
            "scheduled_date": schedule_date.isoformat(),
            "scheduled_time": "09:00:00",
            "workout_name": "Leg Day",
            "exercises": sample_exercises,
            "reminder_enabled": True,
            "reminder_minutes_before": 60,
            "status": "scheduled",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.post(
            f"/api/v1/saved-workouts/schedule?user_id={sample_user_id}",
            json={
                "saved_workout_id": sample_saved_workout_id,
                "scheduled_date": schedule_date.isoformat(),
                "scheduled_time": "09:00:00",
                "reminder_enabled": True,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == scheduled_id
        assert data["status"] == "scheduled"

    def test_schedule_workout_no_source(self, mock_supabase, sample_user_id):
        """Test scheduling without saved_workout_id or activity_id."""
        schedule_date = (datetime.now() + timedelta(days=3)).date()

        response = client.post(
            f"/api/v1/saved-workouts/schedule?user_id={sample_user_id}",
            json={
                "scheduled_date": schedule_date.isoformat(),
            }
        )

        assert response.status_code == 400
        assert "saved_workout_id or activity_id" in response.json()["detail"]

    def test_get_upcoming_scheduled(self, mock_supabase, sample_user_id):
        """Test getting upcoming scheduled workouts."""
        scheduled_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[{
                "id": scheduled_id,
                "user_id": sample_user_id,
                "scheduled_date": (datetime.now() + timedelta(days=2)).date().isoformat(),
                "workout_name": "Push Day",
                "exercises": [],
                "status": "scheduled",
                "reminder_enabled": True,
                "reminder_minutes_before": 60,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }],
            count=1
        )

        response = client.get(
            f"/api/v1/saved-workouts/scheduled/upcoming?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1

    def test_update_scheduled_workout(self, mock_supabase, sample_user_id):
        """Test updating a scheduled workout."""
        scheduled_id = str(uuid.uuid4())
        new_date = (datetime.now() + timedelta(days=5)).date()

        # Mock ownership check
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"user_id": sample_user_id}
        ]

        # Mock update
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": scheduled_id,
            "user_id": sample_user_id,
            "scheduled_date": new_date.isoformat(),
            "workout_name": "Updated Workout",
            "exercises": [],
            "status": "scheduled",
            "reminder_enabled": False,
            "reminder_minutes_before": 30,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.put(
            f"/api/v1/saved-workouts/scheduled/{scheduled_id}?user_id={sample_user_id}",
            json={
                "scheduled_date": new_date.isoformat(),
                "reminder_enabled": False,
            }
        )

        assert response.status_code == 200

    def test_delete_scheduled_workout(self, mock_supabase, sample_user_id):
        """Test deleting a scheduled workout."""
        scheduled_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"user_id": sample_user_id}
        ]

        mock_supabase.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.delete(
            f"/api/v1/saved-workouts/scheduled/{scheduled_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200


# ============================================================
# CALENDAR VIEW TESTS
# ============================================================

class TestMonthlyCalendar:
    """Test monthly calendar view."""

    def test_get_monthly_calendar(self, mock_supabase, sample_user_id):
        """Test getting monthly calendar view."""
        scheduled_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.lt.return_value.order.return_value.execute.return_value.data = [
            {
                "id": scheduled_id,
                "scheduled_date": "2025-01-15",
                "scheduled_time": "10:00:00",
                "workout_name": "Full Body",
                "exercises": [{"name": "Squats"}],
                "status": "scheduled",
            },
            {
                "id": str(uuid.uuid4()),
                "scheduled_date": "2025-01-20",
                "workout_name": "Cardio",
                "exercises": [],
                "status": "completed",
            }
        ]

        response = client.get(
            f"/api/v1/saved-workouts/scheduled/month/2025/1?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["year"] == 2025
        assert data["month"] == 1
        assert len(data["workouts"]) == 2
        assert data["total_scheduled"] == 1
        assert data["total_completed"] == 1

    def test_get_monthly_calendar_empty(self, mock_supabase, sample_user_id):
        """Test getting empty monthly calendar."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.lt.return_value.order.return_value.execute.return_value.data = []

        response = client.get(
            f"/api/v1/saved-workouts/scheduled/month/2025/6?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["workouts"] == []
        assert data["total_scheduled"] == 0
        assert data["total_completed"] == 0


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_chromadb_failure_doesnt_fail_save(self, mock_supabase, sample_user_id, sample_activity_id, sample_activity_data):
        """Test that ChromaDB failure doesn't fail the save request."""
        saved_workout_id = str(uuid.uuid4())

        with patch('api.v1.saved_workouts.get_social_rag_service') as mock_rag:
            rag_mock = MagicMock()
            collection_mock = MagicMock()
            collection_mock.add.side_effect = Exception("ChromaDB error")
            rag_mock.get_social_collection.return_value = collection_mock
            mock_rag.return_value = rag_mock

            # Mock activity lookup
            mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [sample_activity_data]

            # Mock no existing save
            mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

            # Mock insert
            mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
                "id": saved_workout_id,
                "user_id": sample_user_id,
                "workout_name": "Full Body Blast",
                "exercises": [],
                "total_exercises": 3,
                "folder": "From Friends",
                "tags": [],
                "times_completed": 0,
                "saved_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }]

            # Mock user name lookup
            mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
                {"name": "Test User"}
            ]

            response = client.post(
                f"/api/v1/saved-workouts/save-from-activity?user_id={sample_user_id}",
                json={"activity_id": sample_activity_id}
            )

            # Should succeed even if ChromaDB fails
            assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
