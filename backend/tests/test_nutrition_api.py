"""
Tests for Nutrition API endpoints.

Tests:
- Food logs listing, retrieval, deletion
- Daily and weekly summaries
- Nutrition targets CRUD

Run with: pytest backend/tests/test_nutrition_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for nutrition operations."""
    with patch("api.v1.nutrition.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_food_log():
    return {
        "id": "log-1",
        "user_id": "user-123-abc",
        "meal_type": "lunch",
        "logged_at": "2025-01-10T12:00:00",
        "food_items": [
            {"name": "Grilled Chicken", "calories": 250, "protein_g": 30},
            {"name": "Brown Rice", "calories": 200, "carbs_g": 45},
        ],
        "total_calories": 450,
        "protein_g": 35.0,
        "carbs_g": 50.0,
        "fat_g": 10.0,
        "fiber_g": 5.0,
        "health_score": 85,
        "ai_feedback": "Great balanced meal!",
        "created_at": "2025-01-10T12:00:00",
    }


@pytest.fixture
def sample_nutrition_targets():
    return {
        "daily_calorie_target": 2000,
        "daily_protein_target_g": 150.0,
        "daily_carbs_target_g": 200.0,
        "daily_fat_target_g": 70.0,
    }


# ============================================================
# LIST FOOD LOGS TESTS
# ============================================================

class TestListFoodLogs:
    """Test food logs listing endpoint."""

    def test_list_food_logs_success(self, mock_supabase_db, sample_user_id, sample_food_log):
        """Test successful food logs listing."""
        from api.v1.nutrition import list_food_logs
        import asyncio

        mock_supabase_db.list_food_logs.return_value = [sample_food_log]

        result = asyncio.get_event_loop().run_until_complete(
            list_food_logs(sample_user_id)
        )

        assert len(result) == 1
        assert result[0].id == "log-1"
        assert result[0].total_calories == 450

    def test_list_food_logs_empty(self, mock_supabase_db, sample_user_id):
        """Test listing food logs when none exist."""
        from api.v1.nutrition import list_food_logs
        import asyncio

        mock_supabase_db.list_food_logs.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            list_food_logs(sample_user_id)
        )

        assert len(result) == 0

    def test_list_food_logs_with_filters(self, mock_supabase_db, sample_user_id, sample_food_log):
        """Test food logs listing with date and meal type filters."""
        from api.v1.nutrition import list_food_logs
        import asyncio

        mock_supabase_db.list_food_logs.return_value = [sample_food_log]

        asyncio.get_event_loop().run_until_complete(
            list_food_logs(
                sample_user_id,
                from_date="2025-01-01",
                to_date="2025-01-31",
                meal_type="lunch"
            )
        )

        mock_supabase_db.list_food_logs.assert_called_with(
            user_id=sample_user_id,
            from_date="2025-01-01",
            to_date="2025-01-31",
            meal_type="lunch",
            limit=50
        )

    def test_list_food_logs_error(self, mock_supabase_db, sample_user_id):
        """Test error handling in food logs listing."""
        from api.v1.nutrition import list_food_logs
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.list_food_logs.side_effect = Exception("Database error")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                list_food_logs(sample_user_id)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# GET FOOD LOG TESTS
# ============================================================

class TestGetFoodLog:
    """Test get single food log endpoint."""

    def test_get_food_log_success(self, mock_supabase_db, sample_user_id, sample_food_log):
        """Test getting a specific food log."""
        from api.v1.nutrition import get_food_log
        import asyncio

        mock_supabase_db.get_food_log.return_value = sample_food_log

        result = asyncio.get_event_loop().run_until_complete(
            get_food_log(sample_user_id, "log-1")
        )

        assert result.id == "log-1"
        assert result.meal_type == "lunch"

    def test_get_food_log_not_found(self, mock_supabase_db, sample_user_id):
        """Test getting non-existent food log."""
        from api.v1.nutrition import get_food_log
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_food_log.return_value = None

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_food_log(sample_user_id, "nonexistent")
            )

        assert exc_info.value.status_code == 404

    def test_get_food_log_access_denied(self, mock_supabase_db, sample_food_log):
        """Test accessing food log belonging to another user."""
        from api.v1.nutrition import get_food_log
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_food_log.return_value = sample_food_log

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_food_log("different-user", "log-1")
            )

        assert exc_info.value.status_code == 403


# ============================================================
# DELETE FOOD LOG TESTS
# ============================================================

class TestDeleteFoodLog:
    """Test delete food log endpoint."""

    def test_delete_food_log_success(self, mock_supabase_db):
        """Test successful food log deletion."""
        from api.v1.nutrition import delete_food_log
        import asyncio

        mock_supabase_db.delete_food_log.return_value = True

        result = asyncio.get_event_loop().run_until_complete(
            delete_food_log("log-1")
        )

        assert result["status"] == "deleted"
        assert result["id"] == "log-1"

    def test_delete_food_log_not_found(self, mock_supabase_db):
        """Test deleting non-existent food log."""
        from api.v1.nutrition import delete_food_log
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.delete_food_log.return_value = False

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                delete_food_log("nonexistent")
            )

        assert exc_info.value.status_code == 404


# ============================================================
# DAILY SUMMARY TESTS
# ============================================================

class TestDailySummary:
    """Test daily nutrition summary endpoint."""

    def test_get_daily_summary_success(self, mock_supabase_db, sample_user_id, sample_food_log):
        """Test getting daily nutrition summary."""
        from api.v1.nutrition import get_daily_summary
        import asyncio

        mock_supabase_db.get_daily_nutrition_summary.return_value = {
            "total_calories": 1800,
            "total_protein_g": 120.0,
            "total_carbs_g": 200.0,
            "total_fat_g": 60.0,
            "total_fiber_g": 25.0,
            "meal_count": 4,
            "avg_health_score": 80.0,
        }
        mock_supabase_db.list_food_logs.return_value = [sample_food_log]

        result = asyncio.get_event_loop().run_until_complete(
            get_daily_summary(sample_user_id, date="2025-01-10")
        )

        assert result.date == "2025-01-10"
        assert result.total_calories == 1800
        assert result.meal_count == 4
        assert len(result.meals) == 1

    def test_get_daily_summary_defaults_to_today(self, mock_supabase_db, sample_user_id):
        """Test that daily summary defaults to today's date."""
        from api.v1.nutrition import get_daily_summary
        import asyncio
        from datetime import datetime

        mock_supabase_db.get_daily_nutrition_summary.return_value = {
            "total_calories": 0,
            "total_protein_g": 0,
            "total_carbs_g": 0,
            "total_fat_g": 0,
            "total_fiber_g": 0,
            "meal_count": 0,
            "avg_health_score": None,
        }
        mock_supabase_db.list_food_logs.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            get_daily_summary(sample_user_id)
        )

        assert result.date == datetime.now().strftime("%Y-%m-%d")

    def test_get_daily_summary_empty_day(self, mock_supabase_db, sample_user_id):
        """Test daily summary for a day with no meals."""
        from api.v1.nutrition import get_daily_summary
        import asyncio

        mock_supabase_db.get_daily_nutrition_summary.return_value = {
            "total_calories": None,
            "total_protein_g": None,
            "total_carbs_g": None,
            "total_fat_g": None,
            "total_fiber_g": None,
            "meal_count": None,
            "avg_health_score": None,
        }
        mock_supabase_db.list_food_logs.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            get_daily_summary(sample_user_id, date="2025-01-01")
        )

        assert result.total_calories == 0
        assert result.meal_count == 0
        assert len(result.meals) == 0


# ============================================================
# WEEKLY SUMMARY TESTS
# ============================================================

class TestWeeklySummary:
    """Test weekly nutrition summary endpoint."""

    def test_get_weekly_summary_success(self, mock_supabase_db, sample_user_id):
        """Test getting weekly nutrition summary."""
        from api.v1.nutrition import get_weekly_summary
        import asyncio

        mock_supabase_db.get_weekly_nutrition_summary.return_value = [
            {"date": "2025-01-01", "total_calories": 2000, "meal_count": 3},
            {"date": "2025-01-02", "total_calories": 1800, "meal_count": 3},
            {"date": "2025-01-03", "total_calories": 2200, "meal_count": 4},
        ]

        result = asyncio.get_event_loop().run_until_complete(
            get_weekly_summary(sample_user_id, start_date="2025-01-01")
        )

        assert result.start_date == "2025-01-01"
        assert result.total_calories == 6000
        assert result.total_meals == 10
        assert result.average_daily_calories == 2000.0

    def test_get_weekly_summary_with_empty_days(self, mock_supabase_db, sample_user_id):
        """Test weekly summary with some empty days."""
        from api.v1.nutrition import get_weekly_summary
        import asyncio

        mock_supabase_db.get_weekly_nutrition_summary.return_value = [
            {"date": "2025-01-01", "total_calories": 2000, "meal_count": 3},
            {"date": "2025-01-02", "total_calories": None, "meal_count": None},
            {"date": "2025-01-03", "total_calories": 1800, "meal_count": 3},
        ]

        result = asyncio.get_event_loop().run_until_complete(
            get_weekly_summary(sample_user_id, start_date="2025-01-01")
        )

        assert result.total_calories == 3800
        assert result.average_daily_calories == 1900.0  # Average over 2 days with data


# ============================================================
# NUTRITION TARGETS TESTS
# ============================================================

class TestNutritionTargets:
    """Test nutrition targets endpoints."""

    def test_get_nutrition_targets_success(self, mock_supabase_db, sample_user_id, sample_nutrition_targets):
        """Test getting nutrition targets."""
        from api.v1.nutrition import get_nutrition_targets
        import asyncio

        mock_supabase_db.get_user_nutrition_targets.return_value = sample_nutrition_targets

        result = asyncio.get_event_loop().run_until_complete(
            get_nutrition_targets(sample_user_id)
        )

        assert result.user_id == sample_user_id
        assert result.daily_calorie_target == 2000
        assert result.daily_protein_target_g == 150.0

    def test_get_nutrition_targets_not_set(self, mock_supabase_db, sample_user_id):
        """Test getting nutrition targets when not set."""
        from api.v1.nutrition import get_nutrition_targets
        import asyncio

        mock_supabase_db.get_user_nutrition_targets.return_value = {}

        result = asyncio.get_event_loop().run_until_complete(
            get_nutrition_targets(sample_user_id)
        )

        assert result.user_id == sample_user_id
        assert result.daily_calorie_target is None

    def test_update_nutrition_targets_success(self, mock_supabase_db, sample_user_id, sample_nutrition_targets):
        """Test updating nutrition targets."""
        from api.v1.nutrition import update_nutrition_targets
        from models.schemas import UpdateNutritionTargetsRequest
        import asyncio

        mock_supabase_db.update_user_nutrition_targets.return_value = sample_nutrition_targets

        request = MagicMock(spec=UpdateNutritionTargetsRequest)
        request.daily_calorie_target = 2000
        request.daily_protein_target_g = 150.0
        request.daily_carbs_target_g = 200.0
        request.daily_fat_target_g = 70.0

        result = asyncio.get_event_loop().run_until_complete(
            update_nutrition_targets(sample_user_id, request)
        )

        assert result.daily_calorie_target == 2000


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestNutritionModels:
    """Test Pydantic model validation."""

    def test_food_log_response_model(self):
        """Test FoodLogResponse model."""
        from api.v1.nutrition import FoodLogResponse

        response = FoodLogResponse(
            id="log-1",
            user_id="user-123",
            meal_type="lunch",
            logged_at="2025-01-10T12:00:00",
            food_items=[{"name": "Chicken", "calories": 200}],
            total_calories=200,
            protein_g=30.0,
            carbs_g=0.0,
            fat_g=5.0,
            created_at="2025-01-10T12:00:00",
        )

        assert response.id == "log-1"
        assert response.fiber_g is None  # Optional field

    def test_daily_nutrition_response_model(self):
        """Test DailyNutritionResponse model."""
        from api.v1.nutrition import DailyNutritionResponse

        response = DailyNutritionResponse(
            date="2025-01-10",
            total_calories=1800,
            total_protein_g=120.0,
            total_carbs_g=200.0,
            total_fat_g=60.0,
            total_fiber_g=25.0,
            meal_count=4,
        )

        assert response.total_calories == 1800
        assert response.avg_health_score is None  # Optional field

    def test_weekly_nutrition_response_model(self):
        """Test WeeklyNutritionResponse model."""
        from api.v1.nutrition import WeeklyNutritionResponse

        response = WeeklyNutritionResponse(
            start_date="2025-01-01",
            end_date="2025-01-07",
            daily_summaries=[],
            total_calories=14000,
            average_daily_calories=2000.0,
            total_meals=21,
        )

        assert response.average_daily_calories == 2000.0


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestErrorHandling:
    """Test error handling across endpoints."""

    def test_list_food_logs_database_error(self, mock_supabase_db, sample_user_id):
        """Test handling of database errors."""
        from api.v1.nutrition import list_food_logs
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.list_food_logs.side_effect = Exception("Connection failed")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                list_food_logs(sample_user_id)
            )

        assert exc_info.value.status_code == 500
        assert "Connection failed" in str(exc_info.value.detail)

    def test_get_daily_summary_error(self, mock_supabase_db, sample_user_id):
        """Test handling of errors in daily summary."""
        from api.v1.nutrition import get_daily_summary
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_daily_nutrition_summary.side_effect = Exception("Query failed")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_daily_summary(sample_user_id)
            )

        assert exc_info.value.status_code == 500


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
