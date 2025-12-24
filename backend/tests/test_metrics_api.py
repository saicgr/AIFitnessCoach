"""
Tests for Health Metrics API endpoints.

Tests:
- Metrics calculation
- Metrics recording and storage
- Metrics history retrieval
- Latest metrics retrieval
- Metrics deletion
- Injury endpoints

Run with: pytest backend/tests/test_metrics_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for metrics operations."""
    with patch("api.v1.metrics.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_metrics_calculator():
    """Mock MetricsCalculator."""
    with patch("api.v1.metrics.MetricsCalculator") as mock_calc_class:
        mock_calc = MagicMock()
        mock_calc_class.return_value = mock_calc

        # Mock calculated metrics
        mock_metrics = MagicMock()
        mock_metrics.bmi = 24.5
        mock_metrics.bmi_category = "Normal weight"
        mock_metrics.target_bmi = None
        mock_metrics.ideal_body_weight_devine = 70.0
        mock_metrics.ideal_body_weight_robinson = 68.0
        mock_metrics.ideal_body_weight_miller = 69.0
        mock_metrics.bmr_mifflin = 1800.0
        mock_metrics.bmr_harris = 1850.0
        mock_metrics.tdee = 2500.0
        mock_metrics.waist_to_height_ratio = 0.45
        mock_metrics.waist_to_hip_ratio = 0.85
        mock_metrics.body_fat_navy = 18.0
        mock_metrics.lean_body_mass = 65.0
        mock_metrics.ffmi = 22.0

        mock_calc.calculate_all.return_value = mock_metrics
        mock_calc.get_bmi_interpretation.return_value = "Your BMI is in the healthy range."
        mock_calc.get_tdee_interpretation.return_value = "You burn about 2500 calories per day."

        yield mock_calc


@pytest.fixture
def mock_injury_service():
    """Mock InjuryService."""
    with patch("api.v1.metrics.get_injury_service") as mock_get_service:
        mock_service = MagicMock()
        mock_get_service.return_value = mock_service

        mock_service.get_recovery_summary.return_value = {
            "expected_recovery_date": "2025-01-15",
            "current_phase": "recovery",
            "phase_description": "Active recovery phase",
            "allowed_intensity": 50,
            "days_since_injury": 7,
            "days_remaining": 14,
            "progress_percent": 33,
        }
        mock_service.get_rehab_exercises.return_value = [
            {"name": "Gentle Stretching"},
            {"name": "Light Walking"},
        ]

        yield mock_service


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_metrics_input():
    return {
        "user_id": "user-123-abc",
        "weight_kg": 75.0,
        "height_cm": 175.0,
        "age": 30,
        "gender": "male",
        "activity_level": "moderately_active",
        "target_weight_kg": 72.0,
        "waist_cm": 80.0,
        "hip_cm": 95.0,
        "neck_cm": 38.0,
        "body_fat_percent": 18.0,
    }


# ============================================================
# CALCULATE METRICS TESTS
# ============================================================

class TestCalculateMetrics:
    """Test metrics calculation endpoint."""

    def test_calculate_metrics_success(self, mock_supabase_db, mock_metrics_calculator, sample_metrics_input):
        """Test successful metrics calculation."""
        from api.v1.metrics import calculate_metrics
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            calculate_metrics(MagicMock(**sample_metrics_input))
        )

        assert result.bmi == 24.5
        assert result.bmi_category == "Normal weight"
        assert result.weight_kg == sample_metrics_input["weight_kg"]
        assert result.height_cm == sample_metrics_input["height_cm"]

    def test_calculate_metrics_with_optional_fields(self, mock_supabase_db, mock_metrics_calculator):
        """Test metrics calculation with only required fields."""
        from api.v1.metrics import calculate_metrics, MetricsInput
        import asyncio

        input_data = MetricsInput(
            user_id="user-123",
            weight_kg=70.0,
            height_cm=170.0,
            age=25,
            gender="female",
        )

        result = asyncio.get_event_loop().run_until_complete(
            calculate_metrics(input_data)
        )

        assert result.bmi == 24.5
        mock_metrics_calculator.calculate_all.assert_called_once()

    def test_calculate_ibw_average(self, mock_supabase_db, mock_metrics_calculator, sample_metrics_input):
        """Test ideal body weight average calculation."""
        from api.v1.metrics import calculate_metrics
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            calculate_metrics(MagicMock(**sample_metrics_input))
        )

        # Average of 70, 68, 69 = 69.0
        expected_avg = round((70.0 + 68.0 + 69.0) / 3, 1)
        assert result.ideal_body_weight_average == expected_avg


# ============================================================
# RECORD METRICS TESTS
# ============================================================

class TestRecordMetrics:
    """Test metrics recording endpoint."""

    def test_record_metrics_success(self, mock_supabase_db, mock_metrics_calculator, sample_metrics_input):
        """Test successful metrics recording."""
        from api.v1.metrics import record_metrics
        import asyncio

        mock_supabase_db.create_user_metrics.return_value = {"id": 1}

        result = asyncio.get_event_loop().run_until_complete(
            record_metrics(MagicMock(**sample_metrics_input))
        )

        assert result.bmi == 24.5
        mock_supabase_db.create_user_metrics.assert_called_once()

    def test_record_metrics_stores_all_fields(self, mock_supabase_db, mock_metrics_calculator, sample_metrics_input):
        """Test that all metrics are stored in database."""
        from api.v1.metrics import record_metrics
        import asyncio

        mock_supabase_db.create_user_metrics.return_value = {"id": 1}

        asyncio.get_event_loop().run_until_complete(
            record_metrics(MagicMock(**sample_metrics_input))
        )

        call_args = mock_supabase_db.create_user_metrics.call_args[0][0]

        assert call_args["user_id"] == sample_metrics_input["user_id"]
        assert call_args["weight_kg"] == sample_metrics_input["weight_kg"]
        assert call_args["bmi"] == 24.5
        assert call_args["bmi_category"] == "Normal weight"
        assert call_args["tdee"] == 2500.0


# ============================================================
# METRICS HISTORY TESTS
# ============================================================

class TestMetricsHistory:
    """Test metrics history endpoint."""

    def test_get_metrics_history_success(self, mock_supabase_db, sample_user_id):
        """Test retrieving metrics history."""
        from api.v1.metrics import get_metrics_history
        import asyncio

        mock_supabase_db.list_user_metrics.return_value = [
            {
                "id": 1,
                "recorded_at": "2025-01-01T10:00:00",
                "weight_kg": 75.0,
                "bmi": 24.5,
                "bmi_category": "Normal weight",
                "bmr": 1800.0,
                "tdee": 2500.0,
                "body_fat_measured": 18.0,
            },
            {
                "id": 2,
                "recorded_at": "2025-01-08T10:00:00",
                "weight_kg": 74.5,
                "bmi": 24.3,
                "bmi_category": "Normal weight",
                "bmr": 1790.0,
                "tdee": 2480.0,
                "body_fat_calculated": 17.5,
            },
        ]

        result = asyncio.get_event_loop().run_until_complete(
            get_metrics_history(sample_user_id)
        )

        assert len(result) == 2
        assert result[0].id == 1
        assert result[0].weight_kg == 75.0
        assert result[1].body_fat == 17.5  # Uses body_fat_calculated when measured is None

    def test_get_metrics_history_empty(self, mock_supabase_db, sample_user_id):
        """Test retrieving empty metrics history."""
        from api.v1.metrics import get_metrics_history
        import asyncio

        mock_supabase_db.list_user_metrics.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            get_metrics_history(sample_user_id)
        )

        assert len(result) == 0

    def test_get_metrics_history_with_limit(self, mock_supabase_db, sample_user_id):
        """Test metrics history respects limit parameter."""
        from api.v1.metrics import get_metrics_history
        import asyncio

        mock_supabase_db.list_user_metrics.return_value = []

        asyncio.get_event_loop().run_until_complete(
            get_metrics_history(sample_user_id, limit=10)
        )

        mock_supabase_db.list_user_metrics.assert_called_with(
            user_id=sample_user_id,
            limit=10
        )


# ============================================================
# LATEST METRICS TESTS
# ============================================================

class TestLatestMetrics:
    """Test latest metrics endpoint."""

    def test_get_latest_metrics_exists(self, mock_supabase_db, sample_user_id):
        """Test getting latest metrics when history exists."""
        from api.v1.metrics import get_latest_metrics
        import asyncio

        mock_supabase_db.get_latest_user_metrics.return_value = {
            "id": 5,
            "recorded_at": "2025-01-10T10:00:00",
            "weight_kg": 74.0,
            "bmi": 24.2,
            "bmi_category": "Normal weight",
            "bmr": 1780.0,
            "tdee": 2470.0,
            "body_fat_measured": 17.0,
            "lean_body_mass": 61.0,
            "ffmi": 21.5,
            "waist_to_height_ratio": 0.44,
            "waist_to_hip_ratio": 0.84,
            "ideal_body_weight": 70.0,
        }

        result = asyncio.get_event_loop().run_until_complete(
            get_latest_metrics(sample_user_id)
        )

        assert result["has_metrics"] is True
        assert result["weight_kg"] == 74.0
        assert result["body_fat"] == 17.0

    def test_get_latest_metrics_not_exists(self, mock_supabase_db, sample_user_id):
        """Test getting latest metrics when no history exists."""
        from api.v1.metrics import get_latest_metrics
        import asyncio

        mock_supabase_db.get_latest_user_metrics.return_value = None

        result = asyncio.get_event_loop().run_until_complete(
            get_latest_metrics(sample_user_id)
        )

        assert result["has_metrics"] is False
        assert result["message"] == "No metrics history found"


# ============================================================
# DELETE METRICS TESTS
# ============================================================

class TestDeleteMetrics:
    """Test metrics deletion endpoint."""

    def test_delete_metric_success(self, mock_supabase_db, sample_user_id):
        """Test successful metric deletion."""
        from api.v1.metrics import delete_metric_entry
        import asyncio

        mock_supabase_db.delete_user_metrics.return_value = True

        result = asyncio.get_event_loop().run_until_complete(
            delete_metric_entry(sample_user_id, metric_id=1)
        )

        assert result["message"] == "Metric entry deleted successfully"

    def test_delete_metric_not_found(self, mock_supabase_db, sample_user_id):
        """Test deleting non-existent metric."""
        from api.v1.metrics import delete_metric_entry
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.delete_user_metrics.return_value = False

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                delete_metric_entry(sample_user_id, metric_id=999)
            )

        assert exc_info.value.status_code == 404


# ============================================================
# INJURY ENDPOINTS TESTS
# ============================================================

class TestInjuryEndpoints:
    """Test injury-related endpoints in metrics API."""

    def test_get_active_injuries_success(self, mock_supabase_db, mock_injury_service, sample_user_id):
        """Test retrieving active injuries."""
        from api.v1.metrics import get_active_injuries
        import asyncio

        mock_supabase_db.get_active_injuries.return_value = [
            {
                "id": 1,
                "user_id": sample_user_id,
                "body_part": "knee",
                "severity": "moderate",
                "reported_at": "2025-01-01T10:00:00",
                "expected_recovery_date": "2025-01-15T10:00:00",
                "pain_level_current": 4,
                "improvement_notes": "Improving gradually",
            }
        ]

        result = asyncio.get_event_loop().run_until_complete(
            get_active_injuries(sample_user_id)
        )

        assert result["count"] == 1
        assert result["injuries"][0]["body_part"] == "knee"
        assert result["injuries"][0]["current_phase"] == "recovery"
        assert len(result["injuries"][0]["rehab_exercises"]) == 2

    def test_get_active_injuries_empty(self, mock_supabase_db, mock_injury_service, sample_user_id):
        """Test retrieving injuries when none exist."""
        from api.v1.metrics import get_active_injuries
        import asyncio

        mock_supabase_db.get_active_injuries.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            get_active_injuries(sample_user_id)
        )

        assert result["count"] == 0
        assert result["injuries"] == []


# ============================================================
# HELPER FUNCTION TESTS
# ============================================================

class TestHelperFunctions:
    """Test helper functions."""

    def test_row_to_metrics_history_item(self):
        """Test conversion of database row to MetricsHistoryItem."""
        from api.v1.metrics import row_to_metrics_history_item

        row = {
            "id": 1,
            "recorded_at": "2025-01-01T10:00:00",
            "weight_kg": 75.0,
            "bmi": 24.5,
            "bmi_category": "Normal weight",
            "bmr": 1800.0,
            "tdee": 2500.0,
            "body_fat_measured": 18.0,
            "body_fat_calculated": 17.5,
        }

        result = row_to_metrics_history_item(row)

        assert result.id == 1
        assert result.weight_kg == 75.0
        assert result.body_fat == 18.0  # Prefers measured over calculated

    def test_row_to_metrics_history_item_uses_calculated(self):
        """Test that calculated body fat is used when measured is None."""
        from api.v1.metrics import row_to_metrics_history_item

        row = {
            "id": 1,
            "recorded_at": "2025-01-01T10:00:00",
            "weight_kg": 75.0,
            "bmi": 24.5,
            "bmi_category": "Normal weight",
            "bmr": 1800.0,
            "tdee": 2500.0,
            "body_fat_measured": None,
            "body_fat_calculated": 17.5,
        }

        result = row_to_metrics_history_item(row)

        assert result.body_fat == 17.5


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestMetricsModels:
    """Test Pydantic model validation."""

    def test_metrics_input_valid(self):
        """Test valid MetricsInput."""
        from api.v1.metrics import MetricsInput

        data = MetricsInput(
            user_id="user-123",
            weight_kg=75.0,
            height_cm=175.0,
            age=30,
            gender="male",
        )

        assert data.user_id == "user-123"
        assert data.weight_kg == 75.0
        assert data.activity_level == "lightly_active"  # Default value

    def test_metrics_input_invalid_weight(self):
        """Test MetricsInput with invalid weight."""
        from api.v1.metrics import MetricsInput
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            MetricsInput(
                user_id="user-123",
                weight_kg=-5.0,  # Invalid: must be > 0
                height_cm=175.0,
                age=30,
                gender="male",
            )

    def test_metrics_input_invalid_age(self):
        """Test MetricsInput with invalid age."""
        from api.v1.metrics import MetricsInput
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            MetricsInput(
                user_id="user-123",
                weight_kg=75.0,
                height_cm=175.0,
                age=150,  # Invalid: max 120
                gender="male",
            )

    def test_metrics_input_body_fat_range(self):
        """Test MetricsInput body fat percentage range."""
        from api.v1.metrics import MetricsInput
        from pydantic import ValidationError

        # Valid body fat
        data = MetricsInput(
            user_id="user-123",
            weight_kg=75.0,
            height_cm=175.0,
            age=30,
            gender="male",
            body_fat_percent=25.0,
        )
        assert data.body_fat_percent == 25.0

        # Invalid body fat
        with pytest.raises(ValidationError):
            MetricsInput(
                user_id="user-123",
                weight_kg=75.0,
                height_cm=175.0,
                age=30,
                gender="male",
                body_fat_percent=80.0,  # Invalid: max 70
            )


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
