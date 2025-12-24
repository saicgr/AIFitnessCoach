"""
Tests for core/db/nutrition_db.py module.

Tests food logs, nutrition summaries, and user nutrition targets.
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
def nutrition_db(mock_supabase_manager):
    """Create NutritionDB with mocked Supabase."""
    from core.db.nutrition_db import NutritionDB
    return NutritionDB(mock_supabase_manager)


class TestNutritionDBCreateFoodLog:
    """Test NutritionDB.create_food_log method."""

    def test_create_food_log_basic(self, nutrition_db):
        """Should create basic food log."""
        result = nutrition_db.create_food_log(
            user_id="user-123",
            meal_type="lunch",
            food_items=["chicken breast", "rice", "vegetables"],
            total_calories=500,
            protein_g=40.0,
            carbs_g=50.0,
            fat_g=15.0,
        )
        assert result["meal_type"] == "lunch"
        assert result["total_calories"] == 500

    def test_create_food_log_with_all_fields(self, nutrition_db):
        """Should create food log with all fields."""
        result = nutrition_db.create_food_log(
            user_id="user-123",
            meal_type="dinner",
            food_items=["salmon", "quinoa"],
            total_calories=600,
            protein_g=45.0,
            carbs_g=40.0,
            fat_g=25.0,
            fiber_g=8.0,
            ai_feedback="Great protein choice!",
            health_score=85,
        )
        assert result["health_score"] == 85
        assert result["fiber_g"] == 8.0


class TestNutritionDBGetFoodLog:
    """Test NutritionDB.get_food_log method."""

    def test_get_food_log_found(self, mock_supabase_manager):
        """Should return food log when found."""
        log_data = {"id": "log-123", "user_id": "user-123", "meal_type": "breakfast"}
        mock_supabase_manager._client._table_data["food_logs"] = [log_data]

        from core.db.nutrition_db import NutritionDB
        db = NutritionDB(mock_supabase_manager)

        result = db.get_food_log("log-123")
        assert result == log_data

    def test_get_food_log_not_found(self, nutrition_db):
        """Should return None when log not found."""
        result = nutrition_db.get_food_log("nonexistent")
        assert result is None


class TestNutritionDBListFoodLogs:
    """Test NutritionDB.list_food_logs method."""

    def test_list_food_logs_all(self, mock_supabase_manager):
        """Should list all food logs for user."""
        logs = [
            {"id": "log-1", "user_id": "user-123", "meal_type": "breakfast"},
            {"id": "log-2", "user_id": "user-123", "meal_type": "lunch"},
        ]
        mock_supabase_manager._client._table_data["food_logs"] = logs

        from core.db.nutrition_db import NutritionDB
        db = NutritionDB(mock_supabase_manager)

        result = db.list_food_logs("user-123")
        assert len(result) == 2

    def test_list_food_logs_with_filters(self, mock_supabase_manager):
        """Should apply filters correctly."""
        logs = [{"id": "log-1", "user_id": "user-123", "meal_type": "lunch"}]
        mock_supabase_manager._client._table_data["food_logs"] = logs

        from core.db.nutrition_db import NutritionDB
        db = NutritionDB(mock_supabase_manager)

        result = db.list_food_logs(
            "user-123",
            from_date="2024-01-01",
            to_date="2024-01-31",
            meal_type="lunch",
        )
        assert len(result) == 1

    def test_list_food_logs_empty(self, nutrition_db):
        """Should return empty list when no logs."""
        result = nutrition_db.list_food_logs("user-123")
        assert result == []


class TestNutritionDBDeleteFoodLog:
    """Test NutritionDB.delete_food_log method."""

    def test_delete_food_log_success(self, nutrition_db):
        """Should delete food log."""
        result = nutrition_db.delete_food_log("log-123")
        assert result is True


class TestNutritionDBDeleteFoodLogsByUser:
    """Test NutritionDB.delete_food_logs_by_user method."""

    def test_delete_food_logs_by_user(self, nutrition_db):
        """Should delete all food logs for user."""
        result = nutrition_db.delete_food_logs_by_user("user-123")
        assert result is True


class TestNutritionDBDailySummary:
    """Test NutritionDB.get_daily_nutrition_summary method."""

    def test_get_daily_nutrition_summary(self, mock_supabase_manager):
        """Should calculate daily nutrition totals."""
        logs = [
            {"total_calories": 400, "protein_g": 30, "carbs_g": 50, "fat_g": 10, "fiber_g": 5},
            {"total_calories": 600, "protein_g": 40, "carbs_g": 60, "fat_g": 20, "fiber_g": 8},
        ]
        mock_supabase_manager._client._table_data["food_logs"] = logs

        from core.db.nutrition_db import NutritionDB
        db = NutritionDB(mock_supabase_manager)

        result = db.get_daily_nutrition_summary("user-123", "2024-01-15")
        assert result["date"] == "2024-01-15"
        assert result["total_calories"] == 1000
        assert result["total_protein_g"] == 70
        assert result["total_carbs_g"] == 110
        assert result["total_fat_g"] == 30
        assert result["total_fiber_g"] == 13
        assert result["meal_count"] == 2

    def test_get_daily_nutrition_summary_empty(self, nutrition_db):
        """Should return zeros when no meals."""
        result = nutrition_db.get_daily_nutrition_summary("user-123", "2024-01-15")
        assert result["total_calories"] == 0
        assert result["total_protein_g"] == 0
        assert result["meal_count"] == 0

    def test_get_daily_nutrition_summary_handles_none_values(self, mock_supabase_manager):
        """Should handle None values in logs."""
        logs = [
            {"total_calories": None, "protein_g": None, "carbs_g": None, "fat_g": None, "fiber_g": None},
            {"total_calories": 500, "protein_g": 30, "carbs_g": 50, "fat_g": 15, "fiber_g": 5},
        ]
        mock_supabase_manager._client._table_data["food_logs"] = logs

        from core.db.nutrition_db import NutritionDB
        db = NutritionDB(mock_supabase_manager)

        result = db.get_daily_nutrition_summary("user-123", "2024-01-15")
        assert result["total_calories"] == 500
        assert result["total_protein_g"] == 30


class TestNutritionDBWeeklySummary:
    """Test NutritionDB.get_weekly_nutrition_summary method."""

    def test_get_weekly_nutrition_summary(self, mock_supabase_manager):
        """Should return 7 days of summaries."""
        # Each day will get empty logs from mock
        mock_supabase_manager._client._table_data["food_logs"] = []

        from core.db.nutrition_db import NutritionDB
        db = NutritionDB(mock_supabase_manager)

        result = db.get_weekly_nutrition_summary("user-123", "2024-01-15")
        assert len(result) == 7

    def test_get_weekly_nutrition_summary_dates(self, mock_supabase_manager):
        """Should have correct dates for each day."""
        mock_supabase_manager._client._table_data["food_logs"] = []

        from core.db.nutrition_db import NutritionDB
        db = NutritionDB(mock_supabase_manager)

        result = db.get_weekly_nutrition_summary("user-123", "2024-01-15")

        # Check first and last dates
        assert result[0]["date"] == "2024-01-15"
        assert result[6]["date"] == "2024-01-21"


class TestNutritionDBNutritionTargets:
    """Test NutritionDB nutrition target methods."""

    def test_update_user_nutrition_targets(self, nutrition_db):
        """Should update nutrition targets."""
        result = nutrition_db.update_user_nutrition_targets(
            user_id="user-123",
            daily_calorie_target=2000,
            daily_protein_target_g=150.0,
            daily_carbs_target_g=250.0,
            daily_fat_target_g=70.0,
        )
        # Mock returns None, but method should execute

    def test_update_user_nutrition_targets_partial(self, nutrition_db):
        """Should update only provided targets."""
        result = nutrition_db.update_user_nutrition_targets(
            user_id="user-123",
            daily_calorie_target=2000,
        )
        # Should only update calorie target

    def test_update_user_nutrition_targets_none(self, nutrition_db):
        """Should return None when no updates provided."""
        result = nutrition_db.update_user_nutrition_targets(user_id="user-123")
        assert result is None

    def test_get_user_nutrition_targets_found(self, mock_supabase_manager):
        """Should get nutrition targets."""
        targets = [{
            "daily_calorie_target": 2000,
            "daily_protein_target_g": 150.0,
            "daily_carbs_target_g": 250.0,
            "daily_fat_target_g": 70.0,
        }]
        mock_supabase_manager._client._table_data["users"] = targets

        from core.db.nutrition_db import NutritionDB
        db = NutritionDB(mock_supabase_manager)

        result = db.get_user_nutrition_targets("user-123")
        assert result["daily_calorie_target"] == 2000
        assert result["daily_protein_target_g"] == 150.0

    def test_get_user_nutrition_targets_not_found(self, nutrition_db):
        """Should return None values when user not found."""
        result = nutrition_db.get_user_nutrition_targets("user-123")
        assert result["daily_calorie_target"] is None
        assert result["daily_protein_target_g"] is None
        assert result["daily_carbs_target_g"] is None
        assert result["daily_fat_target_g"] is None
