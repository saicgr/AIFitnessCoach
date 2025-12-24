"""
Tests for core/db/exercise_db.py module.

Tests exercise catalog, performance logs, strength records, and weekly volumes.
"""
import pytest
from unittest.mock import MagicMock


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

    def ilike(self, *args):
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
def exercise_db(mock_supabase_manager):
    """Create ExerciseDB with mocked Supabase."""
    from core.db.exercise_db import ExerciseDB
    return ExerciseDB(mock_supabase_manager)


class TestExerciseDBGetExercise:
    """Test ExerciseDB.get_exercise method."""

    def test_get_exercise_found(self, mock_supabase_manager):
        """Should return exercise when found."""
        exercise_data = {
            "id": 1,
            "name": "Bench Press",
            "category": "strength",
            "body_part": "chest",
        }
        mock_supabase_manager._client._table_data["exercises"] = [exercise_data]

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.get_exercise(1)
        assert result == exercise_data

    def test_get_exercise_not_found(self, exercise_db):
        """Should return None when exercise not found."""
        result = exercise_db.get_exercise(999)
        assert result is None


class TestExerciseDBGetExerciseByExternalId:
    """Test ExerciseDB.get_exercise_by_external_id method."""

    def test_get_exercise_by_external_id(self, mock_supabase_manager):
        """Should return exercise when found by external ID."""
        exercise_data = {
            "id": 1,
            "external_id": "ex-123",
            "name": "Squat",
        }
        mock_supabase_manager._client._table_data["exercises"] = [exercise_data]

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.get_exercise_by_external_id("ex-123")
        assert result["name"] == "Squat"


class TestExerciseDBListExercises:
    """Test ExerciseDB.list_exercises method."""

    def test_list_exercises_all(self, mock_supabase_manager):
        """Should list all exercises."""
        exercises = [
            {"id": 1, "name": "Bench Press"},
            {"id": 2, "name": "Squat"},
        ]
        mock_supabase_manager._client._table_data["exercises"] = exercises

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.list_exercises()
        assert len(result) == 2

    def test_list_exercises_with_filters(self, mock_supabase_manager):
        """Should apply filters correctly."""
        exercises = [
            {"id": 1, "name": "Bench Press", "category": "strength", "body_part": "chest"},
        ]
        mock_supabase_manager._client._table_data["exercises"] = exercises

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.list_exercises(
            category="strength",
            body_part="chest",
            equipment="barbell",
            difficulty_level=2,
        )
        assert len(result) == 1

    def test_list_exercises_empty(self, exercise_db):
        """Should return empty list when no exercises."""
        result = exercise_db.list_exercises()
        assert result == []


class TestExerciseDBCreateExercise:
    """Test ExerciseDB.create_exercise method."""

    def test_create_exercise_success(self, exercise_db):
        """Should create and return new exercise."""
        exercise_data = {
            "name": "New Exercise",
            "category": "strength",
            "body_part": "legs",
        }
        result = exercise_db.create_exercise(exercise_data)
        assert result["name"] == "New Exercise"


class TestExerciseDBDeleteExercise:
    """Test ExerciseDB.delete_exercise method."""

    def test_delete_exercise_success(self, exercise_db):
        """Should delete exercise."""
        result = exercise_db.delete_exercise(1)
        assert result is True


class TestExerciseDBPerformanceLogs:
    """Test ExerciseDB performance log methods."""

    def test_list_performance_logs(self, mock_supabase_manager):
        """Should list performance logs for user."""
        logs = [
            {"id": 1, "user_id": "user-123", "exercise_name": "Bench Press", "weight_kg": 80},
            {"id": 2, "user_id": "user-123", "exercise_name": "Squat", "weight_kg": 100},
        ]
        mock_supabase_manager._client._table_data["performance_logs"] = logs

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.list_performance_logs("user-123")
        assert len(result) == 2

    def test_list_performance_logs_filtered(self, mock_supabase_manager):
        """Should filter by exercise."""
        logs = [
            {"id": 1, "user_id": "user-123", "exercise_id": "ex-1"},
        ]
        mock_supabase_manager._client._table_data["performance_logs"] = logs

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.list_performance_logs("user-123", exercise_id="ex-1")
        assert len(result) == 1

    def test_create_performance_log(self, exercise_db):
        """Should create performance log."""
        data = {
            "user_id": "user-123",
            "exercise_name": "Bench Press",
            "weight_kg": 80,
            "reps": 8,
            "sets": 4,
        }
        result = exercise_db.create_performance_log(data)
        assert result["weight_kg"] == 80

    def test_delete_performance_logs_by_workout_log(self, exercise_db):
        """Should delete logs for workout log."""
        result = exercise_db.delete_performance_logs_by_workout_log(1)
        assert result is True

    def test_delete_performance_logs_by_user(self, exercise_db):
        """Should delete all logs for user."""
        result = exercise_db.delete_performance_logs_by_user("user-123")
        assert result is True


class TestExerciseDBStrengthRecords:
    """Test ExerciseDB strength record methods."""

    def test_list_strength_records(self, mock_supabase_manager):
        """Should list strength records for user."""
        records = [
            {"id": 1, "user_id": "user-123", "exercise_id": "ex-1", "max_weight_kg": 100, "is_pr": True},
            {"id": 2, "user_id": "user-123", "exercise_id": "ex-2", "max_weight_kg": 80, "is_pr": False},
        ]
        mock_supabase_manager._client._table_data["strength_records"] = records

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.list_strength_records("user-123")
        assert len(result) == 2

    def test_list_strength_records_prs_only(self, mock_supabase_manager):
        """Should filter to PRs only."""
        records = [
            {"id": 1, "user_id": "user-123", "is_pr": True},
        ]
        mock_supabase_manager._client._table_data["strength_records"] = records

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.list_strength_records("user-123", prs_only=True)
        assert len(result) == 1

    def test_create_strength_record(self, exercise_db):
        """Should create strength record."""
        data = {
            "user_id": "user-123",
            "exercise_id": "ex-1",
            "max_weight_kg": 100,
            "is_pr": True,
        }
        result = exercise_db.create_strength_record(data)
        assert result["max_weight_kg"] == 100

    def test_delete_strength_records_by_user(self, exercise_db):
        """Should delete all records for user."""
        result = exercise_db.delete_strength_records_by_user("user-123")
        assert result is True


class TestExerciseDBWeeklyVolumes:
    """Test ExerciseDB weekly volume methods."""

    def test_list_weekly_volumes(self, mock_supabase_manager):
        """Should list weekly volumes for user."""
        volumes = [
            {"id": 1, "user_id": "user-123", "muscle_group": "chest", "sets": 15, "week_number": 1, "year": 2024},
            {"id": 2, "user_id": "user-123", "muscle_group": "back", "sets": 18, "week_number": 1, "year": 2024},
        ]
        mock_supabase_manager._client._table_data["weekly_volumes"] = volumes

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.list_weekly_volumes("user-123")
        assert len(result) == 2

    def test_list_weekly_volumes_filtered(self, mock_supabase_manager):
        """Should filter by week and year."""
        volumes = [
            {"id": 1, "user_id": "user-123", "week_number": 1, "year": 2024},
        ]
        mock_supabase_manager._client._table_data["weekly_volumes"] = volumes

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        result = db.list_weekly_volumes("user-123", week_number=1, year=2024)
        assert len(result) == 1

    def test_upsert_weekly_volume_insert(self, mock_supabase_manager):
        """Should insert new volume record."""
        # Empty table - will insert
        mock_supabase_manager._client._table_data["weekly_volumes"] = []

        from core.db.exercise_db import ExerciseDB
        db = ExerciseDB(mock_supabase_manager)

        data = {
            "user_id": "user-123",
            "muscle_group": "chest",
            "sets": 15,
            "week_number": 1,
            "year": 2024,
        }
        result = db.upsert_weekly_volume(data)
        assert result["sets"] == 15

    def test_delete_weekly_volumes_by_user(self, exercise_db):
        """Should delete all volumes for user."""
        result = exercise_db.delete_weekly_volumes_by_user("user-123")
        assert result is True
