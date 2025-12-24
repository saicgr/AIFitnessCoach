"""
Tests for core/db/activity_db.py module.

Tests daily activity tracking from Health Connect / Apple Health.
"""
import pytest
from unittest.mock import MagicMock
from datetime import datetime, timedelta


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

    def gte(self, *args):
        return self

    def lte(self, *args):
        return self

    def order(self, *args, **kwargs):
        return self

    def limit(self, *args):
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
def activity_db(mock_supabase_manager):
    """Create ActivityDB with mocked Supabase."""
    from core.db.activity_db import ActivityDB
    return ActivityDB(mock_supabase_manager)


class TestActivityDBUpsertDailyActivity:
    """Test ActivityDB.upsert_daily_activity method."""

    def test_upsert_daily_activity_basic(self, activity_db):
        """Should upsert daily activity data."""
        data = {
            "user_id": "user-123",
            "activity_date": "2024-01-15",
            "steps": 10000,
            "calories_burned": 2500,
            "distance_meters": 8000,
        }
        result = activity_db.upsert_daily_activity(data)
        assert result["steps"] == 10000

    def test_upsert_daily_activity_with_datetime(self, activity_db):
        """Should convert datetime to string."""
        data = {
            "user_id": "user-123",
            "activity_date": datetime(2024, 1, 15),
            "steps": 10000,
        }
        result = activity_db.upsert_daily_activity(data)
        # Should not raise an error


class TestActivityDBGetDailyActivity:
    """Test ActivityDB.get_daily_activity method."""

    def test_get_daily_activity_found(self, mock_supabase_manager):
        """Should return activity when found."""
        activity_data = {
            "user_id": "user-123",
            "activity_date": "2024-01-15",
            "steps": 10000,
        }
        mock_supabase_manager._client._table_data["daily_activity"] = [activity_data]

        from core.db.activity_db import ActivityDB
        db = ActivityDB(mock_supabase_manager)

        result = db.get_daily_activity("user-123", "2024-01-15")
        assert result == activity_data

    def test_get_daily_activity_not_found(self, activity_db):
        """Should return None when not found."""
        result = activity_db.get_daily_activity("user-123", "2024-01-15")
        assert result is None


class TestActivityDBListDailyActivity:
    """Test ActivityDB.list_daily_activity method."""

    def test_list_daily_activity_all(self, mock_supabase_manager):
        """Should list all activity for user."""
        activities = [
            {"user_id": "user-123", "activity_date": "2024-01-15", "steps": 10000},
            {"user_id": "user-123", "activity_date": "2024-01-14", "steps": 8000},
        ]
        mock_supabase_manager._client._table_data["daily_activity"] = activities

        from core.db.activity_db import ActivityDB
        db = ActivityDB(mock_supabase_manager)

        result = db.list_daily_activity("user-123")
        assert len(result) == 2

    def test_list_daily_activity_with_date_range(self, mock_supabase_manager):
        """Should filter by date range."""
        activities = [
            {"user_id": "user-123", "activity_date": "2024-01-15", "steps": 10000},
        ]
        mock_supabase_manager._client._table_data["daily_activity"] = activities

        from core.db.activity_db import ActivityDB
        db = ActivityDB(mock_supabase_manager)

        result = db.list_daily_activity(
            "user-123",
            from_date="2024-01-01",
            to_date="2024-01-31",
        )
        assert len(result) == 1

    def test_list_daily_activity_empty(self, activity_db):
        """Should return empty list when no activity."""
        result = activity_db.list_daily_activity("user-123")
        assert result == []


class TestActivityDBGetActivitySummary:
    """Test ActivityDB.get_activity_summary method."""

    def test_get_activity_summary(self, mock_supabase_manager):
        """Should calculate activity summary."""
        activities = [
            {"steps": 10000, "calories_burned": 2500, "distance_meters": 8000, "resting_heart_rate": 60},
            {"steps": 8000, "calories_burned": 2200, "distance_meters": 6500, "resting_heart_rate": 62},
            {"steps": 12000, "calories_burned": 2800, "distance_meters": 9500, "resting_heart_rate": 58},
        ]
        mock_supabase_manager._client._table_data["daily_activity"] = activities

        from core.db.activity_db import ActivityDB
        db = ActivityDB(mock_supabase_manager)

        result = db.get_activity_summary("user-123", days=7)
        assert result["total_steps"] == 30000
        assert result["total_calories"] == 7500
        assert result["total_distance_meters"] == 24000
        assert result["avg_steps"] == 10000
        assert result["avg_resting_hr"] == 60
        assert result["days_with_data"] == 3

    def test_get_activity_summary_empty(self, activity_db):
        """Should return zeros when no activity."""
        result = activity_db.get_activity_summary("user-123", days=7)
        assert result["total_steps"] == 0
        assert result["total_calories"] == 0
        assert result["avg_steps"] == 0
        assert result["avg_resting_hr"] is None
        assert result["days_with_data"] == 0

    def test_get_activity_summary_handles_none_values(self, mock_supabase_manager):
        """Should handle None values in activity data."""
        activities = [
            {"steps": None, "calories_burned": None, "distance_meters": None, "resting_heart_rate": None},
            {"steps": 10000, "calories_burned": 2500, "distance_meters": 8000, "resting_heart_rate": 60},
        ]
        mock_supabase_manager._client._table_data["daily_activity"] = activities

        from core.db.activity_db import ActivityDB
        db = ActivityDB(mock_supabase_manager)

        result = db.get_activity_summary("user-123", days=7)
        assert result["total_steps"] == 10000
        assert result["avg_resting_hr"] == 60


class TestActivityDBDeleteDailyActivity:
    """Test ActivityDB.delete_daily_activity method."""

    def test_delete_daily_activity_success(self, activity_db):
        """Should delete specific daily activity."""
        result = activity_db.delete_daily_activity("user-123", "2024-01-15")
        assert result is True


class TestActivityDBDeleteDailyActivityByUser:
    """Test ActivityDB.delete_daily_activity_by_user method."""

    def test_delete_daily_activity_by_user(self, activity_db):
        """Should delete all activity for user."""
        result = activity_db.delete_daily_activity_by_user("user-123")
        assert result is True


class TestActivityDBActivitySummaryCalculations:
    """Test ActivityDB activity summary calculation edge cases."""

    def test_summary_with_missing_heart_rate(self, mock_supabase_manager):
        """Should calculate avg HR only from days with HR data."""
        activities = [
            {"steps": 10000, "calories_burned": 2500, "distance_meters": 8000, "resting_heart_rate": 60},
            {"steps": 8000, "calories_burned": 2200, "distance_meters": 6500, "resting_heart_rate": None},
        ]
        mock_supabase_manager._client._table_data["daily_activity"] = activities

        from core.db.activity_db import ActivityDB
        db = ActivityDB(mock_supabase_manager)

        result = db.get_activity_summary("user-123", days=7)
        assert result["avg_resting_hr"] == 60  # Only one day with HR

    def test_summary_rounds_correctly(self, mock_supabase_manager):
        """Should round values appropriately."""
        activities = [
            {"steps": 10001, "calories_burned": 2500.5, "distance_meters": 8000.7, "resting_heart_rate": 60},
            {"steps": 10002, "calories_burned": 2500.5, "distance_meters": 8000.3, "resting_heart_rate": 61},
        ]
        mock_supabase_manager._client._table_data["daily_activity"] = activities

        from core.db.activity_db import ActivityDB
        db = ActivityDB(mock_supabase_manager)

        result = db.get_activity_summary("user-123", days=7)
        # Steps should be integers
        assert isinstance(result["avg_steps"], int)
        # Calories and distance should be rounded to 1 decimal
        assert result["total_calories"] == 5001.0
        assert result["total_distance_meters"] == 16001.0
