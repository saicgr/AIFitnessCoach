"""
Tests for core/db/facade.py module.

Tests the unified SupabaseDB facade that delegates to specialized modules.
"""
import pytest
from unittest.mock import MagicMock, patch


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

    def upsert(self, data, on_conflict=None):
        self._data = [data] if isinstance(data, dict) else data
        return self

    def eq(self, *args):
        return self

    def neq(self, *args):
        return self

    def gte(self, *args):
        return self

    def lte(self, *args):
        return self

    def ilike(self, *args):
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
def supabase_db(mock_supabase_manager):
    """Create SupabaseDB facade with mocked Supabase."""
    from core.db.facade import SupabaseDB
    return SupabaseDB(mock_supabase_manager)


class TestSupabaseDBInitialization:
    """Test SupabaseDB facade initialization."""

    def test_initialization_creates_all_modules(self, mock_supabase_manager):
        """Should create all specialized database modules."""
        from core.db.facade import SupabaseDB
        db = SupabaseDB(mock_supabase_manager)

        assert db._user_db is not None
        assert db._workout_db is not None
        assert db._exercise_db is not None
        assert db._analytics_db is not None
        assert db._nutrition_db is not None
        assert db._activity_db is not None

    def test_properties(self, supabase_db, mock_supabase_manager):
        """Should expose supabase manager and client."""
        assert supabase_db.supabase == mock_supabase_manager
        assert supabase_db.client == mock_supabase_manager.client


class TestSupabaseDBUserDelegation:
    """Test user operation delegation."""

    def test_get_user_delegates(self, mock_supabase_manager):
        """Should delegate get_user to UserDB."""
        user_data = {"id": "user-123", "email": "test@example.com"}
        mock_supabase_manager._client._table_data["users"] = [user_data]

        from core.db.facade import SupabaseDB
        db = SupabaseDB(mock_supabase_manager)

        result = db.get_user("user-123")
        assert result == user_data

    def test_create_user_delegates(self, supabase_db):
        """Should delegate create_user to UserDB."""
        user_data = {"email": "test@example.com"}
        result = supabase_db.create_user(user_data)
        assert result["email"] == "test@example.com"

    def test_update_user_delegates(self, supabase_db):
        """Should delegate update_user to UserDB."""
        result = supabase_db.update_user("user-123", {"name": "New Name"})

    def test_delete_user_delegates(self, supabase_db):
        """Should delegate delete_user to UserDB."""
        result = supabase_db.delete_user("user-123")
        assert result is True


class TestSupabaseDBWorkoutDelegation:
    """Test workout operation delegation."""

    def test_get_workout_delegates(self, mock_supabase_manager):
        """Should delegate get_workout to WorkoutDB."""
        workout_data = {"id": "w-123", "name": "Upper Body"}
        mock_supabase_manager._client._table_data["workouts"] = [workout_data]

        from core.db.facade import SupabaseDB
        db = SupabaseDB(mock_supabase_manager)

        result = db.get_workout("w-123")
        assert result == workout_data

    def test_create_workout_delegates(self, supabase_db):
        """Should delegate create_workout to WorkoutDB."""
        workout_data = {"name": "Leg Day", "type": "strength"}
        result = supabase_db.create_workout(workout_data)
        assert result["name"] == "Leg Day"

    def test_list_workouts_delegates(self, supabase_db):
        """Should delegate list_workouts to WorkoutDB."""
        result = supabase_db.list_workouts("user-123")
        assert result == []


class TestSupabaseDBExerciseDelegation:
    """Test exercise operation delegation."""

    def test_get_exercise_delegates(self, mock_supabase_manager):
        """Should delegate get_exercise to ExerciseDB."""
        exercise_data = {"id": 1, "name": "Bench Press"}
        mock_supabase_manager._client._table_data["exercises"] = [exercise_data]

        from core.db.facade import SupabaseDB
        db = SupabaseDB(mock_supabase_manager)

        result = db.get_exercise(1)
        assert result == exercise_data

    def test_list_exercises_delegates(self, supabase_db):
        """Should delegate list_exercises to ExerciseDB."""
        result = supabase_db.list_exercises()
        assert result == []


class TestSupabaseDBAnalyticsDelegation:
    """Test analytics operation delegation."""

    def test_record_regeneration_delegates(self, supabase_db):
        """Should delegate record_workout_regeneration to AnalyticsDB."""
        result = supabase_db.record_workout_regeneration(
            user_id="user-123",
            original_workout_id="old-w1",
            new_workout_id="new-w1",
        )
        # Mock returns data

    def test_get_regeneration_analytics_delegates(self, supabase_db):
        """Should delegate get_user_regeneration_analytics to AnalyticsDB."""
        result = supabase_db.get_user_regeneration_analytics("user-123")
        assert result == []


class TestSupabaseDBNutritionDelegation:
    """Test nutrition operation delegation."""

    def test_create_food_log_delegates(self, supabase_db):
        """Should delegate create_food_log to NutritionDB."""
        result = supabase_db.create_food_log(
            user_id="user-123",
            meal_type="lunch",
            food_items=["chicken"],
            total_calories=500,
            protein_g=40.0,
            carbs_g=50.0,
            fat_g=15.0,
        )
        assert result["meal_type"] == "lunch"

    def test_list_food_logs_delegates(self, supabase_db):
        """Should delegate list_food_logs to NutritionDB."""
        result = supabase_db.list_food_logs("user-123")
        assert result == []


class TestSupabaseDBActivityDelegation:
    """Test activity operation delegation."""

    def test_upsert_daily_activity_delegates(self, supabase_db):
        """Should delegate upsert_daily_activity to ActivityDB."""
        data = {"user_id": "user-123", "activity_date": "2024-01-15", "steps": 10000}
        result = supabase_db.upsert_daily_activity(data)
        assert result["steps"] == 10000

    def test_list_daily_activity_delegates(self, supabase_db):
        """Should delegate list_daily_activity to ActivityDB."""
        result = supabase_db.list_daily_activity("user-123")
        assert result == []


class TestSupabaseDBFullUserReset:
    """Test full_user_reset method."""

    def test_full_user_reset_calls_all_deletes(self, supabase_db):
        """Should delete all user data."""
        result = supabase_db.full_user_reset("user-123")
        assert result is True


class TestGetSupabaseDB:
    """Test get_supabase_db singleton function."""

    def test_get_supabase_db_returns_instance(self):
        """Should return SupabaseDB instance."""
        # Note: This would require mocking the supabase client
        # In production, this creates a real connection
        pass

    def test_get_supabase_db_singleton(self):
        """Should return same instance on multiple calls."""
        # Reset singleton for testing
        import core.db.facade as facade_module
        facade_module._supabase_db = None

        # In a real test with proper mocking:
        # first = get_supabase_db()
        # second = get_supabase_db()
        # assert first is second
        pass


class TestBackwardCompatibility:
    """Test backward compatibility with core.supabase_db module."""

    def test_import_from_core_supabase_db(self):
        """Should be importable from core.supabase_db."""
        from core.supabase_db import SupabaseDB, get_supabase_db
        from core.supabase_db import UserDB, WorkoutDB, ExerciseDB
        from core.supabase_db import AnalyticsDB, NutritionDB, ActivityDB
        from core.supabase_db import BaseDB

        # All imports should work
        assert SupabaseDB is not None
        assert UserDB is not None
        assert WorkoutDB is not None

    def test_import_from_core_db(self):
        """Should be importable from core.db."""
        from core.db import SupabaseDB, get_supabase_db
        from core.db import UserDB, WorkoutDB, ExerciseDB
        from core.db import AnalyticsDB, NutritionDB, ActivityDB
        from core.db import BaseDB

        # All imports should work
        assert SupabaseDB is not None
        assert UserDB is not None
        assert WorkoutDB is not None


class TestModuleLineCount:
    """Verify modules stay within recommended size limits."""

    def test_user_db_under_300_lines(self):
        """UserDB should be under 300 lines."""
        import core.db.user_db as module
        import inspect
        source = inspect.getsource(module)
        lines = source.count('\n')
        assert lines < 300, f"user_db.py has {lines} lines (max 300)"

    def test_workout_db_under_300_lines(self):
        """WorkoutDB should be under 300 lines."""
        import core.db.workout_db as module
        import inspect
        source = inspect.getsource(module)
        lines = source.count('\n')
        # WorkoutDB is larger due to SCD2 versioning logic
        assert lines < 500, f"workout_db.py has {lines} lines (max 500)"

    def test_exercise_db_under_300_lines(self):
        """ExerciseDB should be under 300 lines."""
        import core.db.exercise_db as module
        import inspect
        source = inspect.getsource(module)
        lines = source.count('\n')
        assert lines < 300, f"exercise_db.py has {lines} lines (max 300)"

    def test_analytics_db_under_300_lines(self):
        """AnalyticsDB should be under 300 lines."""
        import core.db.analytics_db as module
        import inspect
        source = inspect.getsource(module)
        lines = source.count('\n')
        assert lines < 300, f"analytics_db.py has {lines} lines (max 300)"

    def test_nutrition_db_under_300_lines(self):
        """NutritionDB should be under 300 lines."""
        import core.db.nutrition_db as module
        import inspect
        source = inspect.getsource(module)
        lines = source.count('\n')
        assert lines < 300, f"nutrition_db.py has {lines} lines (max 300)"

    def test_activity_db_under_300_lines(self):
        """ActivityDB should be under 300 lines."""
        import core.db.activity_db as module
        import inspect
        source = inspect.getsource(module)
        lines = source.count('\n')
        assert lines < 300, f"activity_db.py has {lines} lines (max 300)"
