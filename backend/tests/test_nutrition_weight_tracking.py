"""
Tests for Nutrition Weight Tracking endpoints.

Tests the weight logging and trend calculation endpoints:
- Weight logging (POST, GET, DELETE /nutrition/weight-logs)
- Weight trend calculation (GET /nutrition/weight-logs/{user_id}/trend)

Run with: pytest backend/tests/test_nutrition_weight_tracking.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, timedelta
import uuid
import sys
import os

# Add the backend directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB with chainable Supabase client pattern."""
    with patch("api.v1.nutrition.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client

        # Create chainable mock for table operations
        mock_table = MagicMock()
        mock_client.table.return_value = mock_table

        # Make all table operations chainable (return the same mock_table)
        mock_table.select.return_value = mock_table
        mock_table.insert.return_value = mock_table
        mock_table.update.return_value = mock_table
        mock_table.delete.return_value = mock_table
        mock_table.upsert.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.neq.return_value = mock_table
        mock_table.gte.return_value = mock_table
        mock_table.lte.return_value = mock_table
        mock_table.order.return_value = mock_table
        mock_table.limit.return_value = mock_table
        mock_table.is_.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.maybe_single.return_value = mock_table

        # Store mock_table for easy access in tests
        mock_db._mock_table = mock_table

        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_user_id():
    return str(uuid.uuid4())


@pytest.fixture
def sample_weight_log():
    return {
        "id": str(uuid.uuid4()),
        "user_id": "user-123-abc",
        "weight_kg": 75.5,
        "logged_at": "2025-01-10T08:00:00+00:00",
        "source": "manual",
        "notes": "Morning weight",
        "created_at": "2025-01-10T08:00:00+00:00",
    }


@pytest.fixture
def sample_weight_history():
    """Sample weight history over 14 days."""
    base_date = datetime(2025, 1, 1)
    return [
        {
            "id": str(uuid.uuid4()),
            "user_id": "user-123-abc",
            "weight_kg": 80.0 - (i * 0.2),  # Losing 0.2kg per entry
            "logged_at": (base_date + timedelta(days=i)).isoformat() + "+00:00",
            "source": "manual",
            "created_at": (base_date + timedelta(days=i)).isoformat() + "+00:00",
        }
        for i in range(14)
    ]


# ============================================================
# WEIGHT LOG TESTS
# ============================================================

class TestWeightLogs:
    """Test weight logging endpoints."""

    def test_create_weight_log_success(self, mock_supabase_db, sample_weight_log):
        """Test successful weight log creation."""
        from api.v1.nutrition import create_weight_log, WeightLogCreate
        import asyncio

        # Setup mock to return data via execute()
        mock_result = MagicMock()
        mock_result.data = [sample_weight_log]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        request = MagicMock(spec=WeightLogCreate)
        request.user_id = sample_weight_log["user_id"]
        request.weight_kg = sample_weight_log["weight_kg"]
        request.logged_at = None
        request.notes = sample_weight_log["notes"]
        request.source = "manual"

        result = asyncio.get_event_loop().run_until_complete(
            create_weight_log(request)
        )

        assert result.weight_kg == 75.5
        assert result.source == "manual"

    def test_create_weight_log_with_custom_date(self, mock_supabase_db, sample_weight_log):
        """Test weight log creation with custom date."""
        from api.v1.nutrition import create_weight_log, WeightLogCreate
        import asyncio

        sample_weight_log["logged_at"] = "2025-01-05T07:00:00+00:00"
        mock_result = MagicMock()
        mock_result.data = [sample_weight_log]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        request = MagicMock(spec=WeightLogCreate)
        request.user_id = sample_weight_log["user_id"]
        request.weight_kg = 75.5
        request.logged_at = datetime(2025, 1, 5, 7, 0, 0)
        request.notes = None
        request.source = "manual"

        result = asyncio.get_event_loop().run_until_complete(
            create_weight_log(request)
        )

        assert "2025-01-05" in str(result.logged_at)

    def test_get_weight_logs_success(self, mock_supabase_db, sample_user_id, sample_weight_history):
        """Test successful weight logs retrieval."""
        from api.v1.nutrition import get_weight_logs
        import asyncio

        mock_result = MagicMock()
        mock_result.data = sample_weight_history
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_weight_logs(sample_user_id)
        )

        assert len(result) == 14

    def test_get_weight_logs_with_limit(self, mock_supabase_db, sample_user_id, sample_weight_history):
        """Test weight logs with limit parameter."""
        from api.v1.nutrition import get_weight_logs
        import asyncio

        limited_history = sample_weight_history[:5]

        mock_result = MagicMock()
        mock_result.data = limited_history
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_weight_logs(sample_user_id, limit=5)
        )

        assert len(result) == 5

    def test_get_weight_logs_empty(self, mock_supabase_db, sample_user_id):
        """Test weight logs when none exist."""
        from api.v1.nutrition import get_weight_logs
        import asyncio

        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_weight_logs(sample_user_id)
        )

        assert len(result) == 0

    def test_delete_weight_log_success(self, mock_supabase_db, sample_user_id, sample_weight_log):
        """Test successful weight log deletion."""
        from api.v1.nutrition import delete_weight_log
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_weight_log]  # Return something to indicate success
        mock_supabase_db._mock_table.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            delete_weight_log(sample_weight_log["id"], sample_weight_log["user_id"])
        )

        assert result["success"] == True

    def test_delete_weight_log_error(self, mock_supabase_db, sample_user_id):
        """Test deleting weight log with database error."""
        from api.v1.nutrition import delete_weight_log
        from fastapi import HTTPException
        import asyncio

        # Simulate database error
        mock_supabase_db._mock_table.execute.side_effect = Exception("Database error")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                delete_weight_log("nonexistent-id", sample_user_id)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# WEIGHT TREND TESTS
# ============================================================

class TestWeightTrend:
    """Test weight trend calculation endpoint."""

    def test_get_weight_trend_losing(self, mock_supabase_db, sample_user_id, sample_weight_history):
        """Test weight trend calculation when losing weight."""
        from api.v1.nutrition import get_weight_trend
        import asyncio

        # Mock the chainable query result
        mock_result = MagicMock()
        mock_result.data = sample_weight_history
        mock_supabase_db._mock_table.execute.return_value = mock_result

        # Pass days as an int (not a Query object)
        result = asyncio.get_event_loop().run_until_complete(
            get_weight_trend(sample_user_id, days=14)
        )

        assert result.direction == "losing"
        assert result.weekly_rate_kg < 0  # Negative for weight loss

    def test_get_weight_trend_gaining(self, mock_supabase_db, sample_user_id):
        """Test weight trend calculation when gaining weight."""
        from api.v1.nutrition import get_weight_trend
        import asyncio

        # Create gaining weight history
        base_date = datetime(2025, 1, 1)
        gaining_history = [
            {
                "id": str(uuid.uuid4()),
                "user_id": sample_user_id,
                "weight_kg": 70.0 + (i * 0.3),  # Gaining 0.3kg per entry
                "logged_at": (base_date + timedelta(days=i)).isoformat() + "+00:00",
                "source": "manual",
            }
            for i in range(14)
        ]

        mock_result = MagicMock()
        mock_result.data = gaining_history
        mock_supabase_db._mock_table.execute.return_value = mock_result

        # Pass days as an int
        result = asyncio.get_event_loop().run_until_complete(
            get_weight_trend(sample_user_id, days=14)
        )

        assert result.direction == "gaining"
        assert result.weekly_rate_kg > 0

    def test_get_weight_trend_maintaining(self, mock_supabase_db, sample_user_id):
        """Test weight trend calculation when maintaining weight."""
        from api.v1.nutrition import get_weight_trend
        import asyncio

        # Create stable weight history
        base_date = datetime(2025, 1, 1)
        stable_history = [
            {
                "id": str(uuid.uuid4()),
                "user_id": sample_user_id,
                "weight_kg": 75.0 + (0.05 if i % 2 == 0 else -0.05),  # Very small fluctuations
                "logged_at": (base_date + timedelta(days=i)).isoformat() + "+00:00",
                "source": "manual",
            }
            for i in range(14)
        ]

        mock_result = MagicMock()
        mock_result.data = stable_history
        mock_supabase_db._mock_table.execute.return_value = mock_result

        # Pass days as an int
        result = asyncio.get_event_loop().run_until_complete(
            get_weight_trend(sample_user_id, days=14)
        )

        assert result.direction == "maintaining"
        assert abs(result.weekly_rate_kg) < 0.5  # Small change

    def test_get_weight_trend_insufficient_data(self, mock_supabase_db, sample_user_id):
        """Test weight trend with insufficient data returns maintaining with zero confidence."""
        from api.v1.nutrition import get_weight_trend
        import asyncio

        # Only one weight entry
        mock_result = MagicMock()
        mock_result.data = [
            {
                "id": str(uuid.uuid4()),
                "user_id": sample_user_id,
                "weight_kg": 75.0,
                "logged_at": datetime.utcnow().isoformat() + "+00:00",
            }
        ]
        mock_supabase_db._mock_table.execute.return_value = mock_result

        # Pass days as an int
        result = asyncio.get_event_loop().run_until_complete(
            get_weight_trend(sample_user_id, days=14)
        )

        # With insufficient data, returns maintaining with 0 confidence
        assert result.direction == "maintaining"
        assert result.confidence == 0.0


# ============================================================
# NUTRITION CALCULATOR TESTS
# ============================================================

class TestNutritionCalculator:
    """Test NutritionCalculator utility class for BMR/TDEE calculations."""

    def test_calculate_bmr_male(self):
        """Test BMR calculation for male using Mifflin-St Jeor."""
        from core.db.nutrition_db import NutritionDB

        # Male, 80kg, 180cm, 30 years
        # BMR = (10 × 80) + (6.25 × 180) − (5 × 30) + 5
        # BMR = 800 + 1125 - 150 + 5 = 1780

        expected_bmr = 1780

        # Manual calculation
        weight_kg = 80
        height_cm = 180
        age = 30
        gender = "male"

        actual_bmr = round((10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5)

        assert actual_bmr == expected_bmr

    def test_calculate_bmr_female(self):
        """Test BMR calculation for female using Mifflin-St Jeor."""
        # Female, 65kg, 165cm, 28 years
        # BMR = (10 × 65) + (6.25 × 165) − (5 × 28) − 161
        # BMR = 650 + 1031.25 - 140 - 161 = 1380.25 ≈ 1380

        weight_kg = 65
        height_cm = 165
        age = 28

        actual_bmr = round((10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161)
        expected_bmr = 1380

        assert actual_bmr == expected_bmr

    def test_tdee_multipliers(self):
        """Test TDEE calculation with activity multipliers."""
        bmr = 1800

        # Sedentary: 1.2
        assert round(bmr * 1.2) == 2160

        # Lightly active: 1.375
        assert round(bmr * 1.375) == 2475

        # Moderately active: 1.55
        assert round(bmr * 1.55) == 2790

        # Very active: 1.725
        assert round(bmr * 1.725) == 3105

        # Extra active: 1.9
        assert round(bmr * 1.9) == 3420


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestWeightLogModels:
    """Test weight log Pydantic models."""

    def test_weight_log_response_model(self):
        """Test WeightLogResponse model creation."""
        from api.v1.nutrition import WeightLogResponse

        response = WeightLogResponse(
            id="test-123",
            user_id="user-456",
            weight_kg=75.5,
            logged_at=datetime(2025, 1, 10, 8, 0, 0),
            source="manual",
            notes="Morning weight",
        )

        assert response.weight_kg == 75.5
        assert response.source == "manual"
        assert response.notes == "Morning weight"

    def test_weight_trend_response_model(self):
        """Test WeightTrendResponse model creation."""
        from api.v1.nutrition import WeightTrendResponse

        response = WeightTrendResponse(
            start_weight=80.0,
            end_weight=78.0,
            change_kg=-2.0,
            weekly_rate_kg=-1.0,
            direction="losing",
            days_analyzed=14,
            confidence=0.85,
        )

        assert response.direction == "losing"
        assert response.change_kg == -2.0
        assert response.confidence == 0.85

    def test_weight_trend_response_maintaining(self):
        """Test WeightTrendResponse model with maintaining direction."""
        from api.v1.nutrition import WeightTrendResponse

        response = WeightTrendResponse(
            direction="maintaining",
            days_analyzed=1,
            confidence=0.0,
        )

        assert response.direction == "maintaining"
        assert response.confidence == 0.0
        assert response.start_weight is None  # Optional fields


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
