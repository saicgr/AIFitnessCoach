"""
Tests for core/db/workout_db.py module.

Tests workout CRUD operations, SCD2 versioning, logs, and related operations.
"""
import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime
import json


class MockQueryBuilder:
    """Mock Supabase query builder for testing."""

    def __init__(self, data=None):
        self._data = data or []

    def select(self, *args, **kwargs):
        return self

    def insert(self, data):
        self._data = [data] if isinstance(data, dict) else data
        return self

    def update(self, data):
        return self

    def delete(self):
        return self

    def eq(self, *args):
        return self

    def neq(self, *args):
        return self

    def gte(self, *args):
        return self

    def lte(self, *args):
        return self

    def or_(self, *args):
        return self

    def order(self, *args, **kwargs):
        return self

    def limit(self, *args):
        return self

    def range(self, *args):
        return self

    def execute(self):
        return MagicMock(data=self._data)


class MockSupabaseClient:
    """Mock Supabase client for testing."""

    def __init__(self, table_data=None):
        self._table_data = table_data or {}

    def table(self, name):
        data = self._table_data.get(name, [])
        return MockQueryBuilder(data)


class MockSupabaseManager:
    """Mock SupabaseManager for testing."""

    def __init__(self, client=None):
        self._client = client or MockSupabaseClient()

    @property
    def client(self):
        return self._client


@pytest.fixture
def mock_supabase_manager():
    """Create a mock SupabaseManager."""
    return MockSupabaseManager()


@pytest.fixture
def workout_db(mock_supabase_manager):
    """Create WorkoutDB with mocked Supabase."""
    from core.db.workout_db import WorkoutDB
    return WorkoutDB(mock_supabase_manager)


class TestWorkoutDBGetWorkout:
    """Test WorkoutDB.get_workout method."""

    def test_get_workout_found(self, mock_supabase_manager):
        """Should return workout when found."""
        workout_data = {
            "id": "workout-123",
            "user_id": "user-123",
            "name": "Upper Body",
            "type": "strength",
        }
        mock_supabase_manager._client._table_data["workouts"] = [workout_data]

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.get_workout("workout-123")
        assert result == workout_data

    def test_get_workout_not_found(self, workout_db):
        """Should return None when workout not found."""
        result = workout_db.get_workout("nonexistent")
        assert result is None


class TestWorkoutDBListWorkouts:
    """Test WorkoutDB.list_workouts method."""

    def test_list_workouts_basic(self, mock_supabase_manager):
        """Should list workouts for user."""
        workouts = [
            {"id": "w1", "user_id": "user-123", "scheduled_date": "2024-01-15"},
            {"id": "w2", "user_id": "user-123", "scheduled_date": "2024-01-16"},
        ]
        mock_supabase_manager._client._table_data["workouts"] = workouts

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.list_workouts("user-123")
        assert len(result) == 2

    def test_list_workouts_empty(self, workout_db):
        """Should return empty list when no workouts."""
        result = workout_db.list_workouts("user-123")
        assert result == []

    def test_list_workouts_with_filters(self, mock_supabase_manager):
        """Should apply filters correctly."""
        workouts = [
            {"id": "w1", "user_id": "user-123", "is_completed": True, "scheduled_date": "2024-01-15"},
        ]
        mock_supabase_manager._client._table_data["workouts"] = workouts

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.list_workouts(
            "user-123",
            is_completed=True,
            from_date="2024-01-01",
            to_date="2024-01-31",
        )
        assert len(result) == 1


class TestWorkoutDBCreateWorkout:
    """Test WorkoutDB.create_workout method."""

    def test_create_workout_success(self, workout_db):
        """Should create and return new workout."""
        workout_data = {
            "user_id": "user-123",
            "name": "Leg Day",
            "type": "strength",
            "difficulty": "medium",
        }
        result = workout_db.create_workout(workout_data)
        assert result["name"] == "Leg Day"


class TestWorkoutDBUpdateWorkout:
    """Test WorkoutDB.update_workout method."""

    def test_update_workout_success(self, workout_db):
        """Should update workout."""
        update_data = {"is_completed": True}
        result = workout_db.update_workout("workout-123", update_data)


class TestWorkoutDBDeleteWorkout:
    """Test WorkoutDB.delete_workout method."""

    def test_delete_workout_success(self, workout_db):
        """Should delete workout."""
        result = workout_db.delete_workout("workout-123")
        assert result is True


class TestWorkoutDBGetWorkoutsByDateRange:
    """Test WorkoutDB.get_workouts_by_date_range method."""

    def test_get_workouts_by_date_range(self, mock_supabase_manager):
        """Should return workouts in date range."""
        workouts = [
            {"id": "w1", "user_id": "user-123", "scheduled_date": "2024-01-15"},
        ]
        mock_supabase_manager._client._table_data["workouts"] = workouts

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.get_workouts_by_date_range("user-123", "2024-01-01", "2024-01-31")
        assert len(result) == 1


class TestWorkoutDBVersioning:
    """Test WorkoutDB SCD2 versioning methods."""

    def test_list_current_workouts(self, mock_supabase_manager):
        """Should only list current workouts."""
        workouts = [
            {"id": "w1", "is_current": True, "scheduled_date": "2024-01-15"},
        ]
        mock_supabase_manager._client._table_data["workouts"] = workouts

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.list_current_workouts("user-123")
        assert len(result) == 1

    def test_get_workout_versions(self, mock_supabase_manager):
        """Should get all versions of a workout."""
        workouts = [
            {"id": "w1", "version_number": 1, "is_current": False},
            {"id": "w2", "version_number": 2, "is_current": True, "parent_workout_id": "w1"},
        ]
        mock_supabase_manager._client._table_data["workouts"] = workouts

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.get_workout_versions("w1")
        assert len(result) == 2

    def test_soft_delete_workout(self, workout_db):
        """Should soft delete by marking as not current."""
        result = workout_db.soft_delete_workout("workout-123")
        assert result is True


class TestWorkoutDBLogs:
    """Test WorkoutDB workout log methods."""

    def test_get_workout_log(self, mock_supabase_manager):
        """Should get workout log by ID."""
        logs = [{"id": 1, "user_id": "user-123", "workout_id": "w1"}]
        mock_supabase_manager._client._table_data["workout_logs"] = logs

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.get_workout_log(1)
        assert result["id"] == 1

    def test_list_workout_logs(self, mock_supabase_manager):
        """Should list workout logs for user."""
        logs = [
            {"id": 1, "user_id": "user-123"},
            {"id": 2, "user_id": "user-123"},
        ]
        mock_supabase_manager._client._table_data["workout_logs"] = logs

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.list_workout_logs("user-123")
        assert len(result) == 2

    def test_create_workout_log(self, workout_db):
        """Should create workout log."""
        data = {"user_id": "user-123", "workout_id": "w1", "duration_minutes": 45}
        result = workout_db.create_workout_log(data)
        assert result["duration_minutes"] == 45

    def test_delete_workout_logs_by_workout(self, workout_db):
        """Should delete logs for workout."""
        result = workout_db.delete_workout_logs_by_workout("w1")
        assert result is True

    def test_delete_workout_logs_by_user(self, workout_db):
        """Should delete all logs for user."""
        result = workout_db.delete_workout_logs_by_user("user-123")
        assert result is True


class TestWorkoutDBChanges:
    """Test WorkoutDB workout changes methods."""

    def test_list_workout_changes(self, mock_supabase_manager):
        """Should list workout changes."""
        changes = [{"id": 1, "workout_id": 123, "change_type": "add_exercise"}]
        mock_supabase_manager._client._table_data["workout_changes"] = changes

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.list_workout_changes(workout_id=123)
        assert len(result) == 1

    def test_create_workout_change(self, workout_db):
        """Should create workout change record."""
        data = {"workout_id": 123, "change_type": "add_exercise", "details": "Added push-ups"}
        result = workout_db.create_workout_change(data)
        assert result["change_type"] == "add_exercise"

    def test_delete_workout_changes_by_workout(self, workout_db):
        """Should delete changes for workout."""
        result = workout_db.delete_workout_changes_by_workout("w1")
        assert result is True


class TestWorkoutDBExits:
    """Test WorkoutDB workout exit methods."""

    def test_create_workout_exit(self, workout_db):
        """Should create workout exit record."""
        data = {"user_id": "user-123", "workout_id": "w1", "reason": "too tired"}
        result = workout_db.create_workout_exit(data)
        assert result["reason"] == "too tired"

    def test_list_workout_exits(self, mock_supabase_manager):
        """Should list workout exits for user."""
        exits = [{"id": 1, "user_id": "user-123", "workout_id": "w1"}]
        mock_supabase_manager._client._table_data["workout_exits"] = exits

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.list_workout_exits("user-123")
        assert len(result) == 1

    def test_delete_workout_exits_by_user(self, workout_db):
        """Should delete exits for user."""
        result = workout_db.delete_workout_exits_by_user("user-123")
        assert result is True


class TestWorkoutDBDrinkIntake:
    """Test WorkoutDB drink intake methods."""

    def test_create_drink_intake(self, workout_db):
        """Should create drink intake record."""
        data = {"user_id": "user-123", "workout_log_id": "log-1", "amount_ml": 250}
        result = workout_db.create_drink_intake(data)
        assert result["amount_ml"] == 250

    def test_list_drink_intakes(self, mock_supabase_manager):
        """Should list drink intakes."""
        intakes = [
            {"id": 1, "user_id": "user-123", "amount_ml": 250},
            {"id": 2, "user_id": "user-123", "amount_ml": 300},
        ]
        mock_supabase_manager._client._table_data["drink_intake_logs"] = intakes

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.list_drink_intakes("user-123")
        assert len(result) == 2

    def test_get_workout_total_drink_intake(self, mock_supabase_manager):
        """Should calculate total drink intake for workout."""
        intakes = [
            {"amount_ml": 250},
            {"amount_ml": 300},
        ]
        mock_supabase_manager._client._table_data["drink_intake_logs"] = intakes

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.get_workout_total_drink_intake("log-1")
        assert result == 550


class TestWorkoutDBRestIntervals:
    """Test WorkoutDB rest interval methods."""

    def test_create_rest_interval(self, workout_db):
        """Should create rest interval record."""
        data = {
            "user_id": "user-123",
            "workout_log_id": "log-1",
            "rest_duration_seconds": 60,
            "rest_type": "between_sets",
        }
        result = workout_db.create_rest_interval(data)
        assert result["rest_duration_seconds"] == 60

    def test_list_rest_intervals(self, mock_supabase_manager):
        """Should list rest intervals."""
        intervals = [
            {"id": 1, "rest_duration_seconds": 60, "rest_type": "between_sets"},
        ]
        mock_supabase_manager._client._table_data["rest_intervals"] = intervals

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.list_rest_intervals("user-123")
        assert len(result) == 1

    def test_get_workout_rest_stats(self, mock_supabase_manager):
        """Should calculate rest statistics."""
        intervals = [
            {"rest_duration_seconds": 60, "rest_type": "between_sets"},
            {"rest_duration_seconds": 90, "rest_type": "between_sets"},
            {"rest_duration_seconds": 120, "rest_type": "between_exercises"},
        ]
        mock_supabase_manager._client._table_data["rest_intervals"] = intervals

        from core.db.workout_db import WorkoutDB
        db = WorkoutDB(mock_supabase_manager)

        result = db.get_workout_rest_stats("log-1")
        assert result["total_rest_seconds"] == 270
        assert result["interval_count"] == 3
        assert result["between_sets_count"] == 2
        assert result["between_exercises_count"] == 1
        assert result["avg_rest_seconds"] == 90

    def test_get_workout_rest_stats_empty(self, workout_db):
        """Should return zeros when no intervals."""
        result = workout_db.get_workout_rest_stats("log-1")
        assert result["total_rest_seconds"] == 0
        assert result["interval_count"] == 0
        assert result["avg_rest_seconds"] == 0
