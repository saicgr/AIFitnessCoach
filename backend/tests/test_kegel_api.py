"""
Tests for Kegel/Pelvic Floor API Endpoints
"""

import pytest
from datetime import date, timedelta
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from uuid import uuid4

# Test data
TEST_USER_ID = str(uuid4())


class TestKegelPreferencesEndpoints:
    """Tests for kegel preferences CRUD operations."""

    def test_get_preferences_not_found(self, client, mock_supabase):
        """Test getting preferences when none exist."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.get(f"/api/v1/kegel/preferences/{TEST_USER_ID}")
        assert response.status_code == 200
        assert response.json() is None

    def test_get_preferences_success(self, client, mock_supabase):
        """Test getting existing preferences."""
        mock_data = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "kegels_enabled": True,
            "include_in_warmup": True,
            "include_in_cooldown": False,
            "target_sessions_per_day": 3,
            "current_level": "beginner",
            "focus_area": "general",
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_data]

        response = client.get(f"/api/v1/kegel/preferences/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["kegels_enabled"] is True
        assert data["target_sessions_per_day"] == 3

    def test_upsert_preferences_create(self, client, mock_supabase):
        """Test creating new preferences."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        mock_result = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "kegels_enabled": True,
            "include_in_warmup": True,
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [mock_result]

        prefs_data = {
            "kegels_enabled": True,
            "include_in_warmup": True,
        }

        response = client.put(f"/api/v1/kegel/preferences/{TEST_USER_ID}", json=prefs_data)
        assert response.status_code == 200

    def test_upsert_preferences_update(self, client, mock_supabase):
        """Test updating existing preferences."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"id": str(uuid4())}
        ]

        mock_result = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "kegels_enabled": True,
            "target_sessions_per_day": 5,
            "updated_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [mock_result]

        prefs_data = {
            "target_sessions_per_day": 5,
        }

        response = client.put(f"/api/v1/kegel/preferences/{TEST_USER_ID}", json=prefs_data)
        assert response.status_code == 200


class TestKegelSessionEndpoints:
    """Tests for kegel session logging."""

    def test_create_session(self, client, mock_supabase):
        """Test creating a kegel session."""
        mock_result = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "session_date": "2025-01-01",
            "duration_seconds": 120,
            "reps_completed": 10,
            "session_type": "standard",
            "created_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [mock_result]

        session_data = {
            "duration_seconds": 120,
            "reps_completed": 10,
            "session_type": "standard",
        }

        response = client.post(f"/api/v1/kegel/sessions/{TEST_USER_ID}", json=session_data)
        assert response.status_code == 200
        data = response.json()
        assert data["duration_seconds"] == 120

    def test_get_sessions(self, client, mock_supabase):
        """Test getting kegel sessions."""
        mock_data = [
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "session_date": "2025-01-01",
                "duration_seconds": 120,
                "created_at": "2025-01-01T00:00:00Z",
            },
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "session_date": "2025-01-01",
                "duration_seconds": 90,
                "created_at": "2025-01-01T01:00:00Z",
            },
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.order.return_value.limit.return_value.execute.return_value.data = mock_data

        response = client.get(f"/api/v1/kegel/sessions/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_today_sessions(self, client, mock_supabase):
        """Test getting today's kegel sessions."""
        mock_data = [
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "session_date": date.today().isoformat(),
                "duration_seconds": 120,
                "created_at": "2025-01-01T00:00:00Z",
            },
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value.data = mock_data

        response = client.get(f"/api/v1/kegel/sessions/{TEST_USER_ID}/today")
        assert response.status_code == 200


class TestKegelStatsEndpoints:
    """Tests for kegel statistics."""

    def test_get_stats(self, client, mock_supabase):
        """Test getting kegel statistics."""
        # Mock preferences
        mock_prefs = {
            "kegels_enabled": True,
            "target_sessions_per_day": 3,
        }
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_prefs]

        # Mock sessions
        mock_sessions = [
            {"id": str(uuid4()), "session_date": date.today().isoformat(), "duration_seconds": 120},
            {"id": str(uuid4()), "session_date": date.today().isoformat(), "duration_seconds": 90},
            {"id": str(uuid4()), "session_date": (date.today() - timedelta(days=1)).isoformat(), "duration_seconds": 100},
        ]

        # Set up the mock chain
        mock_table = MagicMock()
        mock_supabase.table.return_value = mock_table

        # For preferences query
        mock_prefs_query = MagicMock()
        mock_prefs_query.execute.return_value.data = [mock_prefs]

        # For sessions query
        mock_sessions_query = MagicMock()
        mock_sessions_query.execute.return_value.data = mock_sessions

        def side_effect(table_name):
            if table_name == "kegel_preferences":
                return mock_prefs_query
            elif table_name == "kegel_sessions":
                return mock_sessions_query
            return MagicMock()

        mock_supabase.table.side_effect = lambda t: MagicMock(
            select=lambda *args: MagicMock(
                eq=lambda *args: mock_prefs_query if t == "kegel_preferences" else mock_sessions_query
            )
        )

        response = client.get(f"/api/v1/kegel/stats/{TEST_USER_ID}")
        assert response.status_code == 200

    def test_check_daily_goal_met(self, client, mock_supabase):
        """Test checking if daily goal is met."""
        # Mock preferences with target of 2
        mock_prefs = [{"target_sessions_per_day": 2}]

        # Mock 2 sessions today
        mock_sessions = [
            {"id": str(uuid4())},
            {"id": str(uuid4())},
        ]

        def mock_table(table_name):
            mock = MagicMock()
            if table_name == "kegel_preferences":
                mock.select.return_value.eq.return_value.execute.return_value.data = mock_prefs
            else:
                mock.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = mock_sessions
            return mock

        mock_supabase.table.side_effect = mock_table

        response = client.get(f"/api/v1/kegel/daily-goal/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["goal_met"] is True
        assert data["sessions_completed"] == 2

    def test_check_daily_goal_not_met(self, client, mock_supabase):
        """Test checking when daily goal is not met."""
        # Mock preferences with target of 3
        mock_prefs = [{"target_sessions_per_day": 3}]

        # Mock only 1 session today
        mock_sessions = [{"id": str(uuid4())}]

        def mock_table(table_name):
            mock = MagicMock()
            if table_name == "kegel_preferences":
                mock.select.return_value.eq.return_value.execute.return_value.data = mock_prefs
            else:
                mock.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = mock_sessions
            return mock

        mock_supabase.table.side_effect = mock_table

        response = client.get(f"/api/v1/kegel/daily-goal/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["goal_met"] is False
        assert data["remaining"] == 2


class TestKegelExercisesEndpoints:
    """Tests for kegel exercises reference data."""

    def test_get_all_exercises(self, client, mock_supabase):
        """Test getting all kegel exercises."""
        mock_data = [
            {
                "id": str(uuid4()),
                "name": "basic_kegel_hold",
                "display_name": "Basic Kegel Hold",
                "description": "Foundation exercise",
                "instructions": ["Step 1", "Step 2"],
                "target_audience": "all",
                "difficulty": "beginner",
                "default_duration_seconds": 60,
                "default_reps": 10,
                "benefits": ["Strengthens pelvic floor"],
            },
            {
                "id": str(uuid4()),
                "name": "quick_flicks",
                "display_name": "Quick Flicks",
                "description": "Rapid contractions",
                "instructions": ["Step 1", "Step 2"],
                "target_audience": "all",
                "difficulty": "beginner",
                "default_duration_seconds": 60,
                "default_reps": 20,
                "benefits": ["Fast-twitch response"],
            },
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = mock_data

        response = client.get("/api/v1/kegel/exercises")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_exercises_filtered_by_audience(self, client, mock_supabase):
        """Test getting exercises filtered by target audience."""
        mock_data = [
            {
                "id": str(uuid4()),
                "name": "prostate_support",
                "display_name": "Prostate Support Kegels",
                "target_audience": "male",
                "difficulty": "beginner",
            },
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.in_.return_value.order.return_value.execute.return_value.data = mock_data

        response = client.get("/api/v1/kegel/exercises", params={"target_audience": "male"})
        assert response.status_code == 200

    def test_get_exercise_by_id(self, client, mock_supabase):
        """Test getting a specific exercise by ID."""
        exercise_id = str(uuid4())
        mock_data = {
            "id": exercise_id,
            "name": "basic_kegel_hold",
            "display_name": "Basic Kegel Hold",
            "description": "Foundation exercise",
            "instructions": ["Step 1", "Step 2"],
            "target_audience": "all",
            "difficulty": "beginner",
        }
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_data]

        response = client.get(f"/api/v1/kegel/exercises/{exercise_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "basic_kegel_hold"


class TestKegelWorkoutIntegration:
    """Tests for kegel workout integration endpoints."""

    def test_get_kegels_for_workout_enabled(self, client, mock_supabase):
        """Test getting kegels for workout when enabled."""
        # Mock preferences
        mock_prefs = {
            "kegels_enabled": True,
            "include_in_warmup": True,
            "current_level": "beginner",
            "focus_area": "general",
        }

        # Mock exercises
        mock_exercises = [
            {
                "id": str(uuid4()),
                "name": "basic_kegel_hold",
                "display_name": "Basic Kegel Hold",
                "default_duration_seconds": 60,
            },
        ]

        def mock_table(table_name):
            mock = MagicMock()
            if table_name == "kegel_preferences":
                mock.select.return_value.eq.return_value.execute.return_value.data = [mock_prefs]
            else:
                mock.select.return_value.eq.return_value.eq.return_value.in_.return_value.order.return_value.limit.return_value.execute.return_value.data = mock_exercises
            return mock

        mock_supabase.table.side_effect = mock_table

        response = client.get(f"/api/v1/kegel/for-workout/{TEST_USER_ID}", params={"placement": "warmup"})
        assert response.status_code == 200
        data = response.json()
        assert data["include_kegels"] is True

    def test_get_kegels_for_workout_disabled(self, client, mock_supabase):
        """Test getting kegels for workout when disabled."""
        mock_prefs = {
            "kegels_enabled": False,
        }
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_prefs]

        response = client.get(f"/api/v1/kegel/for-workout/{TEST_USER_ID}", params={"placement": "warmup"})
        assert response.status_code == 200
        data = response.json()
        assert data["include_kegels"] is False

    def test_log_from_workout(self, client, mock_supabase):
        """Test logging kegels completed during workout."""
        workout_id = str(uuid4())
        mock_result = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "session_date": date.today().isoformat(),
            "duration_seconds": 60,
            "performed_during": "warmup",
            "workout_id": workout_id,
            "created_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [mock_result]

        response = client.post(
            f"/api/v1/kegel/log-from-workout/{TEST_USER_ID}",
            params={
                "workout_id": workout_id,
                "placement": "warmup",
                "duration_seconds": 60,
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert data["performed_during"] == "warmup"


# Pytest fixtures
@pytest.fixture
def client():
    """Create test client."""
    from main import app
    return TestClient(app)


@pytest.fixture
def mock_supabase():
    """Mock Supabase client."""
    with patch("api.v1.kegel.get_supabase_client") as mock:
        mock_client = MagicMock()
        mock.return_value = mock_client
        yield mock_client
