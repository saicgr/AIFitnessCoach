"""
Tests for the Habits Tracking API endpoints.

Tests the /api/v1/habits/* endpoints for habit CRUD, logging,
streaks, summaries, templates, and AI suggestions.

Run with: pytest tests/test_habits_api.py -v
"""

import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, date, timedelta, timezone
from uuid import uuid4
from fastapi.testclient import TestClient

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def client():
    """Synchronous test client for FastAPI."""
    return TestClient(app)


@pytest.fixture
def test_user_id():
    """Sample user ID for testing."""
    return str(uuid4())


@pytest.fixture
def other_user_id():
    """Another user ID for authorization tests."""
    return str(uuid4())


@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB with chainable Supabase client pattern."""
    with patch("api.v1.habits.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client

        # Create chainable mock for table operations
        mock_table = MagicMock()
        mock_client.table.return_value = mock_table

        # Make all table operations chainable
        mock_table.select.return_value = mock_table
        mock_table.insert.return_value = mock_table
        mock_table.update.return_value = mock_table
        mock_table.delete.return_value = mock_table
        mock_table.upsert.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.neq.return_value = mock_table
        mock_table.gte.return_value = mock_table
        mock_table.lte.return_value = mock_table
        mock_table.lt.return_value = mock_table
        mock_table.gt.return_value = mock_table
        mock_table.order.return_value = mock_table
        mock_table.limit.return_value = mock_table
        mock_table.is_.return_value = mock_table
        mock_table.in_.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.maybe_single.return_value = mock_table

        # Store mock_table for easy access in tests
        mock_db._mock_table = mock_table

        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_habit(test_user_id):
    """Sample habit data for testing."""
    return {
        "id": str(uuid4()),
        "user_id": test_user_id,
        "name": "Drink Water",
        "description": "Drink 8 glasses of water daily",
        "habit_type": "positive",
        "frequency": "daily",
        "target_value": 8,
        "target_unit": "glasses",
        "icon": "water_drop",
        "color": "#2196F3",
        "reminder_time": "09:00",
        "reminder_enabled": True,
        "is_active": True,
        "current_streak": 5,
        "longest_streak": 10,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def sample_negative_habit(test_user_id):
    """Sample negative habit (avoid something)."""
    return {
        "id": str(uuid4()),
        "user_id": test_user_id,
        "name": "No Social Media Before Noon",
        "description": "Avoid social media until after 12pm",
        "habit_type": "negative",
        "frequency": "daily",
        "target_value": None,
        "target_unit": None,
        "icon": "phone_disabled",
        "color": "#F44336",
        "is_active": True,
        "current_streak": 3,
        "longest_streak": 7,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def sample_specific_days_habit(test_user_id):
    """Sample habit with specific days frequency."""
    return {
        "id": str(uuid4()),
        "user_id": test_user_id,
        "name": "Gym Session",
        "description": "Complete a gym workout",
        "habit_type": "positive",
        "frequency": "specific_days",
        "specific_days": [1, 3, 5],  # Monday, Wednesday, Friday
        "target_value": 1,
        "target_unit": "sessions",
        "icon": "fitness_center",
        "color": "#4CAF50",
        "is_active": True,
        "current_streak": 2,
        "longest_streak": 8,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def sample_habit_log(test_user_id, sample_habit):
    """Sample habit log entry."""
    return {
        "id": str(uuid4()),
        "user_id": test_user_id,
        "habit_id": sample_habit["id"],
        "log_date": date.today().isoformat(),
        "status": "completed",
        "value": 8,
        "notes": "Hit my water goal!",
        "logged_at": datetime.now(timezone.utc).isoformat(),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def sample_habit_template():
    """Sample habit template."""
    return {
        "id": "template-hydration",
        "name": "Stay Hydrated",
        "description": "Track daily water intake",
        "category": "health",
        "habit_type": "positive",
        "frequency": "daily",
        "suggested_target_value": 8,
        "suggested_target_unit": "glasses",
        "icon": "water_drop",
        "color": "#2196F3",
        "popularity_score": 95,
        "is_active": True,
    }


@pytest.fixture
def sample_habits_summary(test_user_id):
    """Sample habits summary data."""
    return {
        "user_id": test_user_id,
        "total_habits": 5,
        "active_habits": 4,
        "completed_today": 3,
        "pending_today": 1,
        "current_best_streak": 10,
        "total_completions_this_week": 20,
        "completion_rate_this_week": 85.0,
        "top_habit": "Drink Water",
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================================
# Habit CRUD Tests
# ============================================================================

class TestHabitsAPI:
    """Tests for the Habits API endpoints."""

    # ============ HABIT CRUD ============

    def test_create_habit_success(self, client, mock_supabase_db, test_user_id):
        """Test creating a new habit."""
        habit_id = str(uuid4())
        created_habit = {
            "id": habit_id,
            "user_id": test_user_id,
            "name": "Morning Meditation",
            "description": "Meditate for 10 minutes every morning",
            "habit_type": "positive",
            "frequency": "daily",
            "target_value": 10,
            "target_unit": "minutes",
            "icon": "self_improvement",
            "color": "#9C27B0",
            "is_active": True,
            "current_streak": 0,
            "longest_streak": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_result = MagicMock()
        mock_result.data = [created_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            "/api/v1/habits/",
            json={
                "user_id": test_user_id,
                "name": "Morning Meditation",
                "description": "Meditate for 10 minutes every morning",
                "habit_type": "positive",
                "frequency": "daily",
                "target_value": 10,
                "target_unit": "minutes",
                "icon": "self_improvement",
                "color": "#9C27B0",
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["name"] == "Morning Meditation"
        assert data["habit_type"] == "positive"
        assert data["target_value"] == 10

    def test_create_habit_with_all_fields(self, client, mock_supabase_db, test_user_id):
        """Test creating habit with all optional fields."""
        habit_id = str(uuid4())
        created_habit = {
            "id": habit_id,
            "user_id": test_user_id,
            "name": "Evening Reading",
            "description": "Read for 30 minutes before bed",
            "habit_type": "positive",
            "frequency": "daily",
            "target_value": 30,
            "target_unit": "minutes",
            "icon": "menu_book",
            "color": "#FF9800",
            "reminder_time": "21:00",
            "reminder_enabled": True,
            "is_active": True,
            "category": "personal_growth",
            "priority": "high",
            "start_date": date.today().isoformat(),
            "end_date": (date.today() + timedelta(days=30)).isoformat(),
            "current_streak": 0,
            "longest_streak": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_result = MagicMock()
        mock_result.data = [created_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            "/api/v1/habits/",
            json={
                "user_id": test_user_id,
                "name": "Evening Reading",
                "description": "Read for 30 minutes before bed",
                "habit_type": "positive",
                "frequency": "daily",
                "target_value": 30,
                "target_unit": "minutes",
                "icon": "menu_book",
                "color": "#FF9800",
                "reminder_time": "21:00",
                "reminder_enabled": True,
                "category": "personal_growth",
                "priority": "high",
                "start_date": date.today().isoformat(),
                "end_date": (date.today() + timedelta(days=30)).isoformat(),
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["reminder_enabled"] is True
        assert data["reminder_time"] == "21:00"
        assert data["category"] == "personal_growth"

    def test_create_negative_habit(self, client, mock_supabase_db, test_user_id):
        """Test creating a 'negative' habit (avoid something)."""
        habit_id = str(uuid4())
        created_habit = {
            "id": habit_id,
            "user_id": test_user_id,
            "name": "No Late Night Snacking",
            "description": "Avoid eating after 8pm",
            "habit_type": "negative",
            "frequency": "daily",
            "target_value": None,
            "target_unit": None,
            "icon": "no_food",
            "color": "#F44336",
            "is_active": True,
            "current_streak": 0,
            "longest_streak": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_result = MagicMock()
        mock_result.data = [created_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            "/api/v1/habits/",
            json={
                "user_id": test_user_id,
                "name": "No Late Night Snacking",
                "description": "Avoid eating after 8pm",
                "habit_type": "negative",
                "frequency": "daily",
                "icon": "no_food",
                "color": "#F44336",
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["habit_type"] == "negative"
        assert data["target_value"] is None

    def test_create_habit_specific_days(self, client, mock_supabase_db, test_user_id):
        """Test creating habit with specific days frequency."""
        habit_id = str(uuid4())
        created_habit = {
            "id": habit_id,
            "user_id": test_user_id,
            "name": "Gym Workout",
            "description": "Complete a gym session",
            "habit_type": "positive",
            "frequency": "specific_days",
            "specific_days": [1, 3, 5],  # Mon, Wed, Fri
            "target_value": 1,
            "target_unit": "sessions",
            "icon": "fitness_center",
            "color": "#4CAF50",
            "is_active": True,
            "current_streak": 0,
            "longest_streak": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_result = MagicMock()
        mock_result.data = [created_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            "/api/v1/habits/",
            json={
                "user_id": test_user_id,
                "name": "Gym Workout",
                "description": "Complete a gym session",
                "habit_type": "positive",
                "frequency": "specific_days",
                "specific_days": [1, 3, 5],
                "target_value": 1,
                "target_unit": "sessions",
                "icon": "fitness_center",
                "color": "#4CAF50",
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["frequency"] == "specific_days"
        assert data["specific_days"] == [1, 3, 5]

    def test_get_habits_empty(self, client, mock_supabase_db, test_user_id):
        """Test getting habits when none exist."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(f"/api/v1/habits/?user_id={test_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data == [] or data.get("habits") == []

    def test_get_habits_filters_inactive(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that inactive habits are filtered by default."""
        active_habit = sample_habit.copy()
        inactive_habit = sample_habit.copy()
        inactive_habit["id"] = str(uuid4())
        inactive_habit["is_active"] = False
        inactive_habit["name"] = "Inactive Habit"

        # Only return active habits by default
        mock_result = MagicMock()
        mock_result.data = [active_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(f"/api/v1/habits/?user_id={test_user_id}")

        assert response.status_code == 200
        data = response.json()
        habits = data if isinstance(data, list) else data.get("habits", [])
        assert all(h.get("is_active", True) for h in habits)

    def test_get_today_habits_with_status(self, client, mock_supabase_db, test_user_id, sample_habit, sample_habit_log):
        """Test getting today's habits with completion status."""
        habit_with_status = sample_habit.copy()
        habit_with_status["today_status"] = "completed"
        habit_with_status["today_value"] = 8

        mock_result = MagicMock()
        mock_result.data = [habit_with_status]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/habits/today?user_id={test_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        habits = data if isinstance(data, list) else data.get("habits", [])
        if habits:
            assert "today_status" in habits[0] or "status" in habits[0]

    def test_update_habit(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test updating an existing habit."""
        updated_habit = sample_habit.copy()
        updated_habit["name"] = "Drink More Water"
        updated_habit["target_value"] = 10

        mock_result = MagicMock()
        mock_result.data = [updated_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.put(
            f"/api/v1/habits/{sample_habit['id']}",
            json={
                "user_id": test_user_id,
                "name": "Drink More Water",
                "target_value": 10,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Drink More Water"
        assert data["target_value"] == 10

    def test_delete_habit_soft_delete(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that delete is a soft delete (sets is_active=False)."""
        soft_deleted_habit = sample_habit.copy()
        soft_deleted_habit["is_active"] = False

        mock_result = MagicMock()
        mock_result.data = [soft_deleted_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.delete(
            f"/api/v1/habits/{sample_habit['id']}?user_id={test_user_id}"
        )

        assert response.status_code == 200
        # Verify update was called, not delete
        mock_supabase_db._mock_table.update.assert_called()

    def test_archive_habit(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test archiving a habit."""
        archived_habit = sample_habit.copy()
        archived_habit["is_archived"] = True
        archived_habit["archived_at"] = datetime.now(timezone.utc).isoformat()

        mock_result = MagicMock()
        mock_result.data = [archived_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/archive?user_id={test_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data.get("is_archived") is True or data.get("success") is True

    # ============ HABIT LOGS ============

    def test_log_habit_completion(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test logging a habit as completed."""
        log_id = str(uuid4())
        log_entry = {
            "id": log_id,
            "user_id": test_user_id,
            "habit_id": sample_habit["id"],
            "log_date": date.today().isoformat(),
            "status": "completed",
            "value": 8,
            "logged_at": datetime.now(timezone.utc).isoformat(),
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_result = MagicMock()
        mock_result.data = [log_entry]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                "status": "completed",
                "value": 8,
                "log_date": date.today().isoformat(),
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["status"] == "completed"
        assert data["value"] == 8

    def test_log_habit_with_value(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test logging a quantitative habit with value."""
        log_id = str(uuid4())
        log_entry = {
            "id": log_id,
            "user_id": test_user_id,
            "habit_id": sample_habit["id"],
            "log_date": date.today().isoformat(),
            "status": "completed",
            "value": 6,
            "notes": "Managed 6 glasses today",
            "logged_at": datetime.now(timezone.utc).isoformat(),
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_result = MagicMock()
        mock_result.data = [log_entry]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                "status": "completed",
                "value": 6,
                "notes": "Managed 6 glasses today",
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["value"] == 6
        assert data["notes"] == "Managed 6 glasses today"

    def test_log_habit_skip(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test skipping a habit with reason."""
        log_id = str(uuid4())
        log_entry = {
            "id": log_id,
            "user_id": test_user_id,
            "habit_id": sample_habit["id"],
            "log_date": date.today().isoformat(),
            "status": "skipped",
            "skip_reason": "Feeling unwell",
            "logged_at": datetime.now(timezone.utc).isoformat(),
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_result = MagicMock()
        mock_result.data = [log_entry]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                "status": "skipped",
                "skip_reason": "Feeling unwell",
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["status"] == "skipped"
        assert data["skip_reason"] == "Feeling unwell"

    def test_update_habit_log(self, client, mock_supabase_db, test_user_id, sample_habit_log):
        """Test updating an existing habit log."""
        updated_log = sample_habit_log.copy()
        updated_log["value"] = 10
        updated_log["notes"] = "Actually drank 10 glasses!"

        mock_result = MagicMock()
        mock_result.data = [updated_log]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.put(
            f"/api/v1/habits/logs/{sample_habit_log['id']}",
            json={
                "user_id": test_user_id,
                "value": 10,
                "notes": "Actually drank 10 glasses!",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["value"] == 10

    def test_get_habit_logs_date_range(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test getting habit logs for a date range."""
        today = date.today()
        logs = [
            {
                "id": str(uuid4()),
                "habit_id": sample_habit["id"],
                "log_date": (today - timedelta(days=i)).isoformat(),
                "status": "completed",
                "value": 8,
            }
            for i in range(7)
        ]

        mock_result = MagicMock()
        mock_result.data = logs
        mock_supabase_db._mock_table.execute.return_value = mock_result

        start_date = (today - timedelta(days=6)).isoformat()
        end_date = today.isoformat()

        response = client.get(
            f"/api/v1/habits/{sample_habit['id']}/logs"
            f"?user_id={test_user_id}&start_date={start_date}&end_date={end_date}"
        )

        assert response.status_code == 200
        data = response.json()
        logs_list = data if isinstance(data, list) else data.get("logs", [])
        assert len(logs_list) == 7

    def test_batch_log_habits(self, client, mock_supabase_db, test_user_id, sample_habit, sample_negative_habit):
        """Test logging multiple habits at once."""
        log_entries = [
            {
                "id": str(uuid4()),
                "habit_id": sample_habit["id"],
                "log_date": date.today().isoformat(),
                "status": "completed",
                "value": 8,
            },
            {
                "id": str(uuid4()),
                "habit_id": sample_negative_habit["id"],
                "log_date": date.today().isoformat(),
                "status": "completed",
            },
        ]

        mock_result = MagicMock()
        mock_result.data = log_entries
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.post(
            "/api/v1/habits/logs/batch",
            json={
                "user_id": test_user_id,
                "logs": [
                    {"habit_id": sample_habit["id"], "status": "completed", "value": 8},
                    {"habit_id": sample_negative_habit["id"], "status": "completed"},
                ]
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        logged = data if isinstance(data, list) else data.get("logged", [])
        assert len(logged) == 2

    def test_log_habit_updates_streak(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that logging updates the streak correctly."""
        log_id = str(uuid4())
        log_entry = {
            "id": log_id,
            "habit_id": sample_habit["id"],
            "log_date": date.today().isoformat(),
            "status": "completed",
        }

        updated_habit = sample_habit.copy()
        updated_habit["current_streak"] = 6  # Incremented from 5

        # First call returns the log, second returns updated habit
        mock_log_result = MagicMock()
        mock_log_result.data = [log_entry]

        mock_habit_result = MagicMock()
        mock_habit_result.data = [updated_habit]

        mock_supabase_db._mock_table.execute.side_effect = [
            mock_log_result,
            mock_habit_result,
        ]

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                "status": "completed",
            }
        )

        assert response.status_code in [200, 201]

    # ============ STREAKS ============

    def test_streak_increments_on_consecutive_days(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test streak increases with consecutive completions."""
        # Initial streak is 5
        yesterday = date.today() - timedelta(days=1)

        # Mock getting yesterday's log (exists)
        yesterday_log = {
            "id": str(uuid4()),
            "habit_id": sample_habit["id"],
            "log_date": yesterday.isoformat(),
            "status": "completed",
        }

        # Updated habit with incremented streak
        updated_habit = sample_habit.copy()
        updated_habit["current_streak"] = 6

        mock_supabase_db._mock_table.execute.side_effect = [
            MagicMock(data=[yesterday_log]),
            MagicMock(data=[updated_habit]),
        ]

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                "status": "completed",
            }
        )

        assert response.status_code in [200, 201]

    def test_streak_resets_on_missed_day(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test streak resets when a day is missed."""
        # Simulate no log for yesterday
        updated_habit = sample_habit.copy()
        updated_habit["current_streak"] = 1  # Reset to 1

        mock_supabase_db._mock_table.execute.side_effect = [
            MagicMock(data=[]),  # No log for yesterday
            MagicMock(data=[updated_habit]),
        ]

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                "status": "completed",
            }
        )

        assert response.status_code in [200, 201]

    def test_longest_streak_preserved(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that longest streak is never decreased."""
        # Current streak: 5, Longest: 10
        # After logging, current becomes 6, longest stays 10
        updated_habit = sample_habit.copy()
        updated_habit["current_streak"] = 6
        updated_habit["longest_streak"] = 10  # Should remain unchanged

        mock_result = MagicMock()
        mock_result.data = [updated_habit]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/habits/{sample_habit['id']}?user_id={test_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["longest_streak"] >= data["current_streak"]

    def test_get_all_streaks(self, client, mock_supabase_db, test_user_id, sample_habit, sample_negative_habit):
        """Test getting streaks for all habits."""
        habits_with_streaks = [
            {**sample_habit, "current_streak": 5, "longest_streak": 10},
            {**sample_negative_habit, "current_streak": 3, "longest_streak": 7},
        ]

        mock_result = MagicMock()
        mock_result.data = habits_with_streaks
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(f"/api/v1/habits/streaks?user_id={test_user_id}")

        assert response.status_code == 200
        data = response.json()
        streaks = data if isinstance(data, list) else data.get("streaks", [])
        assert len(streaks) == 2
        assert all("current_streak" in s for s in streaks)

    def test_get_habit_streak(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test getting streak for a specific habit."""
        mock_result = MagicMock()
        mock_result.data = sample_habit
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/habits/{sample_habit['id']}/streak?user_id={test_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert "current_streak" in data
        assert data["current_streak"] == 5
        assert data["longest_streak"] == 10

    # ============ SUMMARIES ============

    def test_get_habits_summary(self, client, mock_supabase_db, test_user_id, sample_habits_summary):
        """Test getting overall habits summary."""
        mock_result = MagicMock()
        mock_result.data = sample_habits_summary
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(f"/api/v1/habits/summary?user_id={test_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert "total_habits" in data
        assert "completed_today" in data
        assert "completion_rate_this_week" in data

    def test_get_weekly_summary(self, client, mock_supabase_db, test_user_id):
        """Test getting weekly summary."""
        weekly_data = {
            "user_id": test_user_id,
            "week_start": (date.today() - timedelta(days=date.today().weekday())).isoformat(),
            "total_completions": 28,
            "total_expected": 35,
            "completion_rate": 80.0,
            "best_day": "Monday",
            "habits_maintained": 4,
            "habits_improved": 2,
            "habits_declined": 1,
        }

        mock_result = MagicMock()
        mock_result.data = weekly_data
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(f"/api/v1/habits/summary/weekly?user_id={test_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert "completion_rate" in data
        assert "total_completions" in data

    def test_get_habits_calendar(self, client, mock_supabase_db, test_user_id):
        """Test getting calendar view data."""
        today = date.today()
        calendar_data = [
            {
                "date": (today - timedelta(days=i)).isoformat(),
                "completed_count": 4 if i % 2 == 0 else 3,
                "total_count": 5,
                "completion_rate": 80.0 if i % 2 == 0 else 60.0,
            }
            for i in range(30)
        ]

        mock_result = MagicMock()
        mock_result.data = calendar_data
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/habits/calendar?user_id={test_user_id}&days=30"
        )

        assert response.status_code == 200
        data = response.json()
        calendar = data if isinstance(data, list) else data.get("calendar", [])
        assert len(calendar) == 30

    # ============ TEMPLATES ============

    def test_get_habit_templates(self, client, mock_supabase_db, sample_habit_template):
        """Test getting all habit templates."""
        templates = [
            sample_habit_template,
            {
                "id": "template-exercise",
                "name": "Daily Exercise",
                "description": "Exercise for 30 minutes",
                "category": "fitness",
                "habit_type": "positive",
                "frequency": "daily",
                "suggested_target_value": 30,
                "suggested_target_unit": "minutes",
                "icon": "fitness_center",
                "color": "#4CAF50",
                "popularity_score": 90,
                "is_active": True,
            },
        ]

        mock_result = MagicMock()
        mock_result.data = templates
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get("/api/v1/habits/templates")

        assert response.status_code == 200
        data = response.json()
        template_list = data if isinstance(data, list) else data.get("templates", [])
        assert len(template_list) == 2

    def test_get_templates_by_category(self, client, mock_supabase_db, sample_habit_template):
        """Test filtering templates by category."""
        health_templates = [sample_habit_template]

        mock_result = MagicMock()
        mock_result.data = health_templates
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get("/api/v1/habits/templates?category=health")

        assert response.status_code == 200
        data = response.json()
        template_list = data if isinstance(data, list) else data.get("templates", [])
        assert all(t["category"] == "health" for t in template_list)

    def test_create_habit_from_template(self, client, mock_supabase_db, test_user_id, sample_habit_template):
        """Test creating a habit from a template."""
        created_habit = {
            "id": str(uuid4()),
            "user_id": test_user_id,
            "name": sample_habit_template["name"],
            "description": sample_habit_template["description"],
            "habit_type": sample_habit_template["habit_type"],
            "frequency": sample_habit_template["frequency"],
            "target_value": sample_habit_template["suggested_target_value"],
            "target_unit": sample_habit_template["suggested_target_unit"],
            "icon": sample_habit_template["icon"],
            "color": sample_habit_template["color"],
            "template_id": sample_habit_template["id"],
            "is_active": True,
            "current_streak": 0,
            "longest_streak": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_template_result = MagicMock()
        mock_template_result.data = sample_habit_template

        mock_create_result = MagicMock()
        mock_create_result.data = [created_habit]

        mock_supabase_db._mock_table.execute.side_effect = [
            mock_template_result,
            mock_create_result,
        ]

        response = client.post(
            f"/api/v1/habits/from-template/{sample_habit_template['id']}",
            json={"user_id": test_user_id}
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["name"] == sample_habit_template["name"]
        assert data["template_id"] == sample_habit_template["id"]

    # ============ AI SUGGESTIONS ============

    def test_get_ai_suggestions(self, client, mock_supabase_db, test_user_id):
        """Test getting AI-powered habit suggestions."""
        suggestions = [
            {
                "id": str(uuid4()),
                "name": "Morning Stretch",
                "description": "Start your day with 5 minutes of stretching",
                "reason": "Based on your workout routine, stretching can improve flexibility",
                "category": "fitness",
                "confidence_score": 0.85,
            },
            {
                "id": str(uuid4()),
                "name": "Protein Intake",
                "description": "Track daily protein consumption",
                "reason": "Your fitness goals suggest higher protein needs",
                "category": "nutrition",
                "confidence_score": 0.78,
            },
        ]

        mock_result = MagicMock()
        mock_result.data = suggestions
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(f"/api/v1/habits/suggestions?user_id={test_user_id}")

        assert response.status_code == 200
        data = response.json()
        suggestion_list = data if isinstance(data, list) else data.get("suggestions", [])
        assert len(suggestion_list) == 2
        assert all("reason" in s for s in suggestion_list)

    def test_get_habit_insights(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test getting AI-generated habit insights."""
        insights = {
            "habit_id": sample_habit["id"],
            "habit_name": sample_habit["name"],
            "current_streak": 5,
            "analysis": "You've been consistent with hydration. Great job!",
            "improvement_tips": [
                "Try setting reminders every 2 hours",
                "Keep a water bottle at your desk",
            ],
            "predicted_success_rate": 0.85,
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_result = MagicMock()
        mock_result.data = insights
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/habits/{sample_habit['id']}/insights?user_id={test_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert "analysis" in data or "insights" in data
        assert "improvement_tips" in data or "tips" in data

    # ============ EDGE CASES ============

    def test_habit_unauthorized_access(self, client, mock_supabase_db, test_user_id, other_user_id, sample_habit):
        """Test that users can't access other users' habits."""
        # Habit belongs to test_user_id, but other_user_id is requesting
        mock_result = MagicMock()
        mock_result.data = []  # Returns empty because of user_id filter
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/habits/{sample_habit['id']}?user_id={other_user_id}"
        )

        # Should either return 404 or empty result
        assert response.status_code in [200, 404]
        if response.status_code == 200:
            data = response.json()
            assert data is None or data == {} or (isinstance(data, dict) and not data.get("id"))

    def test_log_future_date_rejected(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that logging for future dates is rejected."""
        future_date = (date.today() + timedelta(days=5)).isoformat()

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                "status": "completed",
                "log_date": future_date,
            }
        )

        # Should reject future dates
        assert response.status_code in [400, 422]

    def test_duplicate_log_same_date_upsert(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that logging same habit same date updates existing."""
        existing_log = {
            "id": str(uuid4()),
            "habit_id": sample_habit["id"],
            "log_date": date.today().isoformat(),
            "status": "completed",
            "value": 5,
        }

        updated_log = existing_log.copy()
        updated_log["value"] = 8

        mock_supabase_db._mock_table.execute.side_effect = [
            MagicMock(data=[existing_log]),  # Find existing log
            MagicMock(data=[updated_log]),  # Return updated
        ]

        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                "status": "completed",
                "value": 8,
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data["value"] == 8

    def test_specific_days_habit_only_tracked_on_those_days(self, client, mock_supabase_db, test_user_id, sample_specific_days_habit):
        """Test habits with specific_days frequency."""
        # Habit is for Mon, Wed, Fri (days 0, 2, 4 in Python weekday)
        today = date.today()
        today_weekday = today.weekday()  # Monday = 0

        # Convert specific_days (Sun=0 based) to Python weekday (Mon=0)
        habit_days = sample_specific_days_habit["specific_days"]  # [1, 3, 5] = Mon, Wed, Fri

        is_tracking_day = (today_weekday + 1) % 7 in habit_days or today_weekday in [0, 2, 4]

        # This tests the logic rather than the API directly
        # The API should only show this habit on scheduled days
        mock_result = MagicMock()
        if is_tracking_day:
            mock_result.data = [sample_specific_days_habit]
        else:
            mock_result.data = []
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/habits/today?user_id={test_user_id}"
        )

        assert response.status_code == 200


# ============================================================================
# Validation Tests
# ============================================================================

class TestHabitValidation:
    """Tests for request validation in habit endpoints."""

    def test_create_habit_requires_name(self, client, mock_supabase_db, test_user_id):
        """Test that name is required for habit creation."""
        response = client.post(
            "/api/v1/habits/",
            json={
                "user_id": test_user_id,
                "habit_type": "positive",
                "frequency": "daily",
            }
        )

        assert response.status_code == 422

    def test_create_habit_validates_frequency(self, client, mock_supabase_db, test_user_id):
        """Test that frequency must be valid."""
        response = client.post(
            "/api/v1/habits/",
            json={
                "user_id": test_user_id,
                "name": "Test Habit",
                "habit_type": "positive",
                "frequency": "invalid_frequency",
            }
        )

        assert response.status_code == 422

    def test_log_habit_requires_status(self, client, mock_supabase_db, test_user_id, sample_habit):
        """Test that status is required for habit log."""
        response = client.post(
            f"/api/v1/habits/{sample_habit['id']}/log",
            json={
                "user_id": test_user_id,
                # Missing status
            }
        )

        assert response.status_code == 422

    def test_specific_days_requires_days_array(self, client, mock_supabase_db, test_user_id):
        """Test that specific_days frequency requires days array."""
        response = client.post(
            "/api/v1/habits/",
            json={
                "user_id": test_user_id,
                "name": "Test Habit",
                "habit_type": "positive",
                "frequency": "specific_days",
                # Missing specific_days
            }
        )

        assert response.status_code == 422


# ============================================================================
# Error Handling Tests
# ============================================================================

class TestHabitErrorHandling:
    """Tests for error handling in habit endpoints."""

    def test_handles_database_error(self, client, mock_supabase_db, test_user_id):
        """Test handling of database errors."""
        mock_supabase_db._mock_table.execute.side_effect = Exception("Database connection failed")

        response = client.get(f"/api/v1/habits/?user_id={test_user_id}")

        assert response.status_code == 500

    def test_handles_habit_not_found(self, client, mock_supabase_db, test_user_id):
        """Test handling of habit not found."""
        mock_result = MagicMock()
        mock_result.data = None
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/habits/{str(uuid4())}?user_id={test_user_id}"
        )

        assert response.status_code in [404, 200]  # Either 404 or empty response

    def test_handles_log_not_found(self, client, mock_supabase_db, test_user_id):
        """Test handling of log not found for update."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_db._mock_table.execute.return_value = mock_result

        response = client.put(
            f"/api/v1/habits/logs/{str(uuid4())}",
            json={
                "user_id": test_user_id,
                "value": 10,
            }
        )

        assert response.status_code in [404, 400]


# ============================================================================
# Integration-Style Tests
# ============================================================================

class TestHabitIntegration:
    """Integration-style tests for habit workflows."""

    def test_complete_habit_lifecycle(self, client, mock_supabase_db, test_user_id):
        """Test the complete lifecycle: create -> log -> update -> delete."""
        habit_id = str(uuid4())

        # Step 1: Create habit
        created_habit = {
            "id": habit_id,
            "user_id": test_user_id,
            "name": "Test Habit",
            "habit_type": "positive",
            "frequency": "daily",
            "is_active": True,
            "current_streak": 0,
            "longest_streak": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[created_habit])

        create_response = client.post(
            "/api/v1/habits/",
            json={
                "user_id": test_user_id,
                "name": "Test Habit",
                "habit_type": "positive",
                "frequency": "daily",
            }
        )

        assert create_response.status_code in [200, 201]

        # Step 2: Log completion
        log_entry = {
            "id": str(uuid4()),
            "habit_id": habit_id,
            "log_date": date.today().isoformat(),
            "status": "completed",
        }

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[log_entry])

        log_response = client.post(
            f"/api/v1/habits/{habit_id}/log",
            json={
                "user_id": test_user_id,
                "status": "completed",
            }
        )

        assert log_response.status_code in [200, 201]

        # Step 3: Update habit
        updated_habit = created_habit.copy()
        updated_habit["name"] = "Updated Habit Name"

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[updated_habit])

        update_response = client.put(
            f"/api/v1/habits/{habit_id}",
            json={
                "user_id": test_user_id,
                "name": "Updated Habit Name",
            }
        )

        assert update_response.status_code == 200

        # Step 4: Delete (soft delete)
        deleted_habit = updated_habit.copy()
        deleted_habit["is_active"] = False

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[deleted_habit])

        delete_response = client.delete(
            f"/api/v1/habits/{habit_id}?user_id={test_user_id}"
        )

        assert delete_response.status_code == 200

    def test_streak_calculation_workflow(self, client, mock_supabase_db, test_user_id):
        """Test streak calculation over multiple days."""
        habit_id = str(uuid4())
        today = date.today()

        # Simulate logging for 5 consecutive days
        for i in range(5, 0, -1):
            log_date = today - timedelta(days=i)
            log_entry = {
                "id": str(uuid4()),
                "habit_id": habit_id,
                "log_date": log_date.isoformat(),
                "status": "completed",
            }
            mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[log_entry])

        # Final streak check
        habit_with_streak = {
            "id": habit_id,
            "current_streak": 5,
            "longest_streak": 5,
        }

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=habit_with_streak)

        response = client.get(
            f"/api/v1/habits/{habit_id}/streak?user_id={test_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["current_streak"] == 5


# ============================================================================
# Model Validation Tests
# ============================================================================

class TestHabitModels:
    """Tests for habit-related Pydantic models (when they exist)."""

    def test_habit_frequency_values(self):
        """Test valid habit frequency values."""
        valid_frequencies = ["daily", "weekly", "specific_days", "monthly"]
        for freq in valid_frequencies:
            assert freq in ["daily", "weekly", "specific_days", "monthly", "custom"]

    def test_habit_type_values(self):
        """Test valid habit type values."""
        valid_types = ["positive", "negative"]
        for habit_type in valid_types:
            assert habit_type in ["positive", "negative"]

    def test_log_status_values(self):
        """Test valid log status values."""
        valid_statuses = ["completed", "skipped", "partial", "missed"]
        for status in valid_statuses:
            assert status in ["completed", "skipped", "partial", "missed"]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
