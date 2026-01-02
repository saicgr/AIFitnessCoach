"""
Tests for Fasting Impact API endpoints.

This module tests:
1. POST /fasting-impact/weight - Log weight with automatic fasting day detection
2. GET /fasting-impact/weight-correlation/{user_id} - Get weight correlation
3. GET /fasting-impact/analysis/{user_id} - Fasting impact analysis
4. GET /fasting-impact/insights/{user_id} - Get insights
5. GET /fasting-impact/calendar/{user_id} - Calendar view
6. GET /fasting-impact/ai-insight/{user_id} - AI insight generation
7. POST /fasting-impact/ai-insight/refresh/{user_id} - Refresh AI insight
8. GET /fasting-impact/ai-correlation/{user_id} - AI correlation score
9. GET /fasting-impact/ai-summary/{user_id} - AI fasting summary
10. POST /fasting-impact/analyze/{user_id} - Trigger fresh analysis

Run with: pytest backend/tests/test_fasting_impact_api.py -v
"""
import pytest
from datetime import date, datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
import uuid
import sys
import os

# Add the backend directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# =============================================================================
# Constants
# =============================================================================

MOCK_USER_ID = "test-user-fasting-123"
MOCK_WEIGHT_LOG_ID = "weight-log-456"
MOCK_FASTING_RECORD_ID = "fasting-record-789"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client for fasting impact tests."""
    with patch("api.v1.fasting_impact.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_activity_logger():
    """Mock the activity logger to avoid database writes during tests."""
    with patch("api.v1.fasting_impact.log_user_activity", new_callable=AsyncMock) as mock_log:
        with patch("api.v1.fasting_impact.log_user_error", new_callable=AsyncMock) as mock_error:
            yield {"log_activity": mock_log, "log_error": mock_error}


@pytest.fixture
def client():
    """Create a test client."""
    from main import app
    return TestClient(app)


@pytest.fixture
def sample_user_id():
    """Generate a sample user ID."""
    return str(uuid.uuid4())


# =============================================================================
# Helper Functions
# =============================================================================

def generate_mock_weight_log(
    weight_kg: float = 75.5,
    date_str: str = None,
    is_fasting_day: bool = False,
    fasting_protocol: str = None,
    fasting_completion_percent: float = None,
    fasting_record_id: str = None,
):
    """Generate a mock weight log response."""
    if date_str is None:
        date_str = date.today().isoformat()

    return {
        "id": str(uuid.uuid4()),
        "user_id": MOCK_USER_ID,
        "weight_kg": weight_kg,
        "date": date_str,
        "notes": "Test weight log",
        "fasting_record_id": fasting_record_id,
        "is_fasting_day": is_fasting_day,
        "fasting_protocol": fasting_protocol,
        "fasting_completion_percent": fasting_completion_percent,
        "created_at": datetime.utcnow().isoformat(),
    }


def generate_mock_fasting_record(
    protocol: str = "16:8",
    status: str = "completed",
    completion_percentage: float = 100.0,
    start_time: str = None,
    end_time: str = None,
):
    """Generate a mock fasting record."""
    if start_time is None:
        start_time = datetime.utcnow().isoformat()
    if end_time is None:
        end_time = (datetime.utcnow() + timedelta(hours=16)).isoformat()

    return {
        "id": str(uuid.uuid4()),
        "user_id": MOCK_USER_ID,
        "protocol": protocol,
        "protocol_type": "time_restricted",
        "status": status,
        "completion_percentage": completion_percentage,
        "start_time": start_time,
        "end_time": end_time,
    }


def generate_mock_workout_log(
    date_str: str = None,
    completed: bool = True,
    completion_percentage: float = 100.0,
):
    """Generate a mock workout log."""
    if date_str is None:
        date_str = date.today().isoformat()

    return {
        "id": str(uuid.uuid4()),
        "user_id": MOCK_USER_ID,
        "date": date_str,
        "completed": completed,
        "completion_percentage": completion_percentage,
    }


def generate_mock_goal_progress(
    date_str: str = None,
    completed: bool = True,
):
    """Generate a mock goal progress entry."""
    if date_str is None:
        date_str = date.today().isoformat()

    return {
        "id": str(uuid.uuid4()),
        "user_id": MOCK_USER_ID,
        "date": date_str,
        "completed": completed,
    }


# =============================================================================
# Weight Logging Tests
# =============================================================================

class TestLogWeightWithFasting:
    """Tests for POST /fasting-impact/weight"""

    def test_log_weight_on_fasting_day(self, client, mock_supabase, mock_activity_logger):
        """Test logging weight on a fasting day with automatic detection."""
        today = date.today().isoformat()

        # Mock fasting status check - user has active fast
        mock_fasting_result = MagicMock()
        mock_fasting_result.data = [
            generate_mock_fasting_record(
                protocol="16:8",
                status="active",
                completion_percentage=75.0,
                start_time=datetime.utcnow().isoformat(),
            )
        ]

        # Mock weight log insert
        mock_insert_result = MagicMock()
        mock_insert_result.data = [generate_mock_weight_log(
            weight_kg=75.0,
            date_str=today,
            is_fasting_day=True,
            fasting_protocol="16:8",
            fasting_completion_percent=75.0,
        )]

        # Setup mock chain
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.neq.return_value.or_.return_value.execute.return_value = mock_fasting_result
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": 75.0,
                "date": today,
                "notes": "Morning weight",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["weight_kg"] == 75.0
        assert data["is_fasting_day"] is True
        assert data["fasting_protocol"] == "16:8"

    def test_log_weight_on_non_fasting_day(self, client, mock_supabase, mock_activity_logger):
        """Test logging weight on a non-fasting day."""
        today = date.today().isoformat()

        # Mock fasting status check - no fasting records
        mock_fasting_result = MagicMock()
        mock_fasting_result.data = []

        # Mock weight log insert
        mock_insert_result = MagicMock()
        mock_insert_result.data = [generate_mock_weight_log(
            weight_kg=76.0,
            date_str=today,
            is_fasting_day=False,
        )]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.neq.return_value.or_.return_value.execute.return_value = mock_fasting_result
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": 76.0,
                "date": today,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["weight_kg"] == 76.0
        assert data["is_fasting_day"] is False
        assert data["fasting_protocol"] is None

    def test_log_weight_with_explicit_fasting_record_id(self, client, mock_supabase, mock_activity_logger):
        """Test logging weight with explicitly provided fasting_record_id."""
        today = date.today().isoformat()
        explicit_fasting_id = "explicit-fasting-record-123"

        # Mock fasting status check
        mock_fasting_result = MagicMock()
        mock_fasting_result.data = [generate_mock_fasting_record()]

        # Mock weight log insert
        mock_insert_result = MagicMock()
        mock_insert_result.data = [generate_mock_weight_log(
            weight_kg=74.5,
            date_str=today,
            is_fasting_day=True,
            fasting_record_id=explicit_fasting_id,
        )]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.neq.return_value.or_.return_value.execute.return_value = mock_fasting_result
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": 74.5,
                "date": today,
                "fasting_record_id": explicit_fasting_id,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["fasting_record_id"] == explicit_fasting_id

    def test_log_weight_invalid_date_format(self, client, mock_supabase, mock_activity_logger):
        """Test logging weight with invalid date format."""
        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": 75.0,
                "date": "12-31-2024",  # Wrong format
            }
        )

        assert response.status_code == 400
        assert "Invalid date format" in response.json()["detail"]

    def test_log_weight_invalid_weight_value(self, client, mock_supabase, mock_activity_logger):
        """Test logging weight with invalid weight value (negative or zero)."""
        today = date.today().isoformat()

        # Test zero weight
        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": 0,
                "date": today,
            }
        )
        assert response.status_code == 422  # Validation error

        # Test negative weight
        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": -5.0,
                "date": today,
            }
        )
        assert response.status_code == 422

    def test_log_weight_missing_required_fields(self, client, mock_supabase):
        """Test weight logging with missing required fields."""
        today = date.today().isoformat()

        # Missing weight_kg
        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "date": today,
            }
        )
        assert response.status_code == 422

        # Missing date
        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": 75.0,
            }
        )
        assert response.status_code == 422

        # Missing user_id
        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "weight_kg": 75.0,
                "date": today,
            }
        )
        assert response.status_code == 422


# =============================================================================
# Weight Correlation Tests
# =============================================================================

class TestGetWeightCorrelation:
    """Tests for GET /fasting-impact/weight-correlation/{user_id}"""

    def test_get_weight_correlation_with_data(self, client, mock_supabase):
        """Test getting weight correlation when data exists."""
        # Generate mock weight logs with mix of fasting and non-fasting days
        mock_weight_logs = [
            generate_mock_weight_log(weight_kg=75.0, date_str=(date.today() - timedelta(days=i)).isoformat(),
                                    is_fasting_day=(i % 2 == 0))
            for i in range(10)
        ]

        mock_result = MagicMock()
        mock_result.data = mock_weight_logs

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}?days=30")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == MOCK_USER_ID
        assert data["period_days"] == 30
        assert "weight_logs" in data
        assert "summary" in data
        assert len(data["weight_logs"]) == 10

    def test_get_weight_correlation_no_data(self, client, mock_supabase):
        """Test getting weight correlation when no data exists."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}")

        assert response.status_code == 200
        data = response.json()
        assert data["weight_logs"] == []
        assert data["summary"]["total_logs"] == 0
        assert data["summary"]["avg_weight_fasting_days"] is None
        assert data["summary"]["avg_weight_non_fasting_days"] is None

    def test_get_weight_correlation_different_day_ranges(self, client, mock_supabase):
        """Test weight correlation with different day range parameters."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.return_value = mock_result

        # Test 7 days
        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}?days=7")
        assert response.status_code == 200
        assert response.json()["period_days"] == 7

        # Test 90 days
        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}?days=90")
        assert response.status_code == 200
        assert response.json()["period_days"] == 90

        # Test 365 days
        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}?days=365")
        assert response.status_code == 200
        assert response.json()["period_days"] == 365

    def test_get_weight_correlation_invalid_days(self, client, mock_supabase):
        """Test weight correlation with invalid days parameter."""
        # Days too low
        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}?days=3")
        assert response.status_code == 422

        # Days too high
        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}?days=500")
        assert response.status_code == 422

    def test_get_weight_correlation_summary_calculation(self, client, mock_supabase):
        """Test that summary statistics are calculated correctly."""
        # Create weight logs with known values
        mock_weight_logs = [
            {"id": "1", "user_id": MOCK_USER_ID, "weight_kg": 70.0, "date": "2024-12-01",
             "is_fasting_day": True, "created_at": "2024-12-01T08:00:00Z"},
            {"id": "2", "user_id": MOCK_USER_ID, "weight_kg": 72.0, "date": "2024-12-02",
             "is_fasting_day": True, "created_at": "2024-12-02T08:00:00Z"},
            {"id": "3", "user_id": MOCK_USER_ID, "weight_kg": 74.0, "date": "2024-12-03",
             "is_fasting_day": False, "created_at": "2024-12-03T08:00:00Z"},
            {"id": "4", "user_id": MOCK_USER_ID, "weight_kg": 76.0, "date": "2024-12-04",
             "is_fasting_day": False, "created_at": "2024-12-04T08:00:00Z"},
        ]

        mock_result = MagicMock()
        mock_result.data = mock_weight_logs

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}")

        assert response.status_code == 200
        summary = response.json()["summary"]

        assert summary["total_logs"] == 4
        assert summary["fasting_day_logs"] == 2
        assert summary["non_fasting_day_logs"] == 2
        assert summary["avg_weight_fasting_days"] == 71.0  # (70 + 72) / 2
        assert summary["avg_weight_non_fasting_days"] == 75.0  # (74 + 76) / 2
        assert summary["weight_difference"] == 4.0  # 75 - 71

    def test_get_weight_correlation_exclude_non_fasting(self, client, mock_supabase):
        """Test filtering to include only fasting day logs."""
        mock_weight_logs = [
            {"id": "1", "user_id": MOCK_USER_ID, "weight_kg": 70.0, "date": "2024-12-01",
             "is_fasting_day": True, "fasting_protocol": "16:8", "created_at": "2024-12-01T08:00:00Z"},
            {"id": "2", "user_id": MOCK_USER_ID, "weight_kg": 74.0, "date": "2024-12-02",
             "is_fasting_day": False, "created_at": "2024-12-02T08:00:00Z"},
        ]

        mock_result = MagicMock()
        mock_result.data = mock_weight_logs

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}?include_non_fasting=false")

        assert response.status_code == 200
        # Only fasting day should be returned
        data = response.json()
        assert len(data["weight_logs"]) == 1
        assert data["weight_logs"][0]["is_fasting_day"] is True


# =============================================================================
# Impact Analysis Tests
# =============================================================================

class TestGetFastingImpactAnalysis:
    """Tests for GET /fasting-impact/analysis/{user_id}"""

    def test_analysis_with_sufficient_data(self, client, mock_supabase):
        """Test fasting impact analysis when sufficient data is available."""
        today = date.today()

        # Mock fasting records
        fasting_records = [
            generate_mock_fasting_record(start_time=(datetime.combine(today - timedelta(days=i), datetime.min.time())).isoformat())
            for i in range(0, 30, 3)  # Every 3rd day
        ]
        mock_fasting_result = MagicMock()
        mock_fasting_result.data = fasting_records

        # Mock weight logs
        weight_logs = [
            {"weight_kg": 75.0 - (i * 0.1), "is_fasting_day": i % 3 == 0, "date": (today - timedelta(days=i)).isoformat()}
            for i in range(30)
        ]
        mock_weight_result = MagicMock()
        mock_weight_result.data = weight_logs

        # Mock workout logs
        workout_logs = [
            generate_mock_workout_log(date_str=(today - timedelta(days=i)).isoformat(),
                                     completion_percentage=90.0 if i % 3 == 0 else 85.0)
            for i in range(30)
        ]
        mock_workout_result = MagicMock()
        mock_workout_result.data = workout_logs

        # Mock goal progress
        goal_progress = [
            generate_mock_goal_progress(date_str=(today - timedelta(days=i)).isoformat(),
                                       completed=i % 2 == 0)
            for i in range(30)
        ]
        mock_goals_result = MagicMock()
        mock_goals_result.data = goal_progress

        # Setup mock chains
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_fasting_result
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.side_effect = [
            mock_weight_result, mock_workout_result, mock_goals_result
        ]

        response = client.get(f"/api/v1/fasting-impact/analysis/{MOCK_USER_ID}?period=month")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == MOCK_USER_ID
        assert data["period"] == "month"
        assert "analysis_date" in data
        assert "fasting_impact_summary" in data
        assert "recommendations" in data
        assert isinstance(data["recommendations"], list)

    def test_analysis_with_insufficient_data(self, client, mock_supabase):
        """Test fasting impact analysis with insufficient data."""
        # Mock empty results
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

        response = client.get(f"/api/v1/fasting-impact/analysis/{MOCK_USER_ID}?period=week")

        assert response.status_code == 200
        data = response.json()
        assert "Not enough data" in data["fasting_impact_summary"]

    def test_analysis_different_periods(self, client, mock_supabase):
        """Test analysis with different period parameters."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

        for period in ["week", "month", "3months", "all"]:
            response = client.get(f"/api/v1/fasting-impact/analysis/{MOCK_USER_ID}?period={period}")
            assert response.status_code == 200
            assert response.json()["period"] == period

    def test_analysis_returns_correlation_metrics(self, client, mock_supabase):
        """Test that analysis includes correlation score and interpretation."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

        response = client.get(f"/api/v1/fasting-impact/analysis/{MOCK_USER_ID}")

        assert response.status_code == 200
        data = response.json()
        assert "correlation_score" in data
        assert "correlation_interpretation" in data


class TestTriggerFastingAnalysis:
    """Tests for POST /fasting-impact/analyze/{user_id}"""

    def test_trigger_analysis_success(self, client, mock_supabase, mock_activity_logger):
        """Test triggering a fresh analysis."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_insert = MagicMock()
        mock_insert.data = [{"id": "analysis-123"}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert

        response = client.post(f"/api/v1/fasting-impact/analyze/{MOCK_USER_ID}?period=month")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == MOCK_USER_ID
        assert data["period"] == "month"

    def test_trigger_analysis_stores_results(self, client, mock_supabase, mock_activity_logger):
        """Test that triggered analysis stores results."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_insert = MagicMock()
        mock_insert.data = [{"id": "analysis-456"}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert

        response = client.post(f"/api/v1/fasting-impact/analyze/{MOCK_USER_ID}")

        assert response.status_code == 200
        # Verify insert was called (analysis stored)
        mock_supabase.client.table.return_value.insert.assert_called()


# =============================================================================
# Insights Tests
# =============================================================================

class TestGetFastingInsights:
    """Tests for GET /fasting-impact/insights/{user_id}"""

    def test_get_insights_success(self, client, mock_supabase):
        """Test getting fasting insights."""
        # Mock data for analysis
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

        response = client.get(f"/api/v1/fasting-impact/insights/{MOCK_USER_ID}")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == MOCK_USER_ID
        assert "generated_at" in data
        assert "key_findings" in data
        assert "personalized_tips" in data
        assert "overall_trend" in data
        assert "confidence_level" in data
        assert data["confidence_level"] in ["high", "medium", "low"]

    def test_insights_confidence_levels(self, client, mock_supabase):
        """Test that confidence level varies based on data quantity."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

        response = client.get(f"/api/v1/fasting-impact/insights/{MOCK_USER_ID}")

        assert response.status_code == 200
        # With no data, should have low confidence
        assert response.json()["confidence_level"] == "low"

    def test_insights_returns_structured_data(self, client, mock_supabase):
        """Test that insights include structured insight objects."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

        response = client.get(f"/api/v1/fasting-impact/insights/{MOCK_USER_ID}")

        assert response.status_code == 200
        data = response.json()
        # These may be None with no data, but keys should exist
        assert "weight_insight" in data
        assert "performance_insight" in data
        assert "goal_insight" in data


# =============================================================================
# Calendar Tests
# =============================================================================

class TestGetFastingCalendar:
    """Tests for GET /fasting-impact/calendar/{user_id}"""

    def test_get_calendar_success(self, client, mock_supabase):
        """Test getting calendar data."""
        # Mock all required data
        mock_fasting = MagicMock()
        mock_fasting.data = [
            generate_mock_fasting_record(start_time="2024-12-05T08:00:00Z"),
            generate_mock_fasting_record(start_time="2024-12-10T08:00:00Z"),
        ]

        mock_weight = MagicMock()
        mock_weight.data = [
            {"date": "2024-12-05", "weight_kg": 75.0},
            {"date": "2024-12-10", "weight_kg": 74.5},
        ]

        mock_workout = MagicMock()
        mock_workout.data = [
            {"id": "w1", "date": "2024-12-05", "completed": True},
        ]

        mock_goals = MagicMock()
        mock_goals.data = [
            {"date": "2024-12-05", "completed": True},
            {"date": "2024-12-05", "completed": False},
        ]

        # Setup mock chain - each table call returns different data
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.neq.return_value.execute.return_value = mock_fasting
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.execute.side_effect = [
            mock_weight, mock_workout, mock_goals
        ]

        response = client.get(f"/api/v1/fasting-impact/calendar/{MOCK_USER_ID}?month=12&year=2024")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == MOCK_USER_ID
        assert data["month"] == 12
        assert data["year"] == 2024
        assert "days" in data
        assert "summary" in data
        assert len(data["days"]) == 31  # December has 31 days

    def test_get_calendar_with_different_months(self, client, mock_supabase):
        """Test calendar for different months."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.execute.return_value = mock_empty

        # Test February (28 days in non-leap year)
        response = client.get(f"/api/v1/fasting-impact/calendar/{MOCK_USER_ID}?month=2&year=2023")
        assert response.status_code == 200
        assert len(response.json()["days"]) == 28

        # Test February (29 days in leap year)
        response = client.get(f"/api/v1/fasting-impact/calendar/{MOCK_USER_ID}?month=2&year=2024")
        assert response.status_code == 200
        assert len(response.json()["days"]) == 29

    def test_get_calendar_invalid_month(self, client, mock_supabase):
        """Test calendar with invalid month parameter."""
        response = client.get(f"/api/v1/fasting-impact/calendar/{MOCK_USER_ID}?month=13&year=2024")
        assert response.status_code == 422

        response = client.get(f"/api/v1/fasting-impact/calendar/{MOCK_USER_ID}?month=0&year=2024")
        assert response.status_code == 422

    def test_get_calendar_summary(self, client, mock_supabase):
        """Test that calendar summary is calculated correctly."""
        mock_fasting = MagicMock()
        mock_fasting.data = [
            generate_mock_fasting_record(start_time="2024-12-01T08:00:00Z"),
            generate_mock_fasting_record(start_time="2024-12-02T08:00:00Z"),
        ]

        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.neq.return_value.execute.return_value = mock_fasting
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.execute.return_value = mock_empty

        response = client.get(f"/api/v1/fasting-impact/calendar/{MOCK_USER_ID}?month=12&year=2024")

        assert response.status_code == 200
        summary = response.json()["summary"]
        assert summary["total_days"] == 31
        assert "fasting_days" in summary
        assert "workout_days" in summary
        assert "fasting_rate" in summary

    def test_get_calendar_day_structure(self, client, mock_supabase):
        """Test that each day in calendar has required fields."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.execute.return_value = mock_empty

        response = client.get(f"/api/v1/fasting-impact/calendar/{MOCK_USER_ID}?month=1&year=2024")

        assert response.status_code == 200
        days = response.json()["days"]
        assert len(days) > 0

        # Check first day has all required fields
        day = days[0]
        assert "date" in day
        assert "is_fasting_day" in day
        assert "workout_completed" in day
        assert "goals_hit" in day
        assert "goals_total" in day


# =============================================================================
# AI Insight Tests
# =============================================================================

class TestGetAIFastingInsight:
    """Tests for GET /fasting-impact/ai-insight/{user_id}"""

    def test_get_ai_insight_success(self, client, mock_supabase, mock_activity_logger):
        """Test getting AI-generated fasting insight."""
        mock_insight = {
            "id": str(uuid.uuid4()),
            "user_id": MOCK_USER_ID,
            "insight_type": "positive",
            "title": "Great Progress!",
            "message": "Your fasting routine is showing positive results.",
            "recommendation": "Keep maintaining your current schedule.",
            "key_finding": "Weight is trending down on fasting days.",
            "data_summary": {"fasting_days": 10, "total_days": 30},
            "created_at": datetime.utcnow().isoformat(),
        }

        with patch("api.v1.fasting_impact.get_fasting_insight_service") as mock_service:
            mock_fasting_service = MagicMock()
            mock_fasting_service.get_fasting_summary_for_insight = AsyncMock(return_value={
                "total_fasting_days": 10,
                "total_non_fasting_days": 20,
            })
            mock_fasting_service.generate_fasting_impact_insight = AsyncMock(return_value=mock_insight)
            mock_service.return_value = mock_fasting_service

            # Mock the weight and goal data functions
            mock_empty = MagicMock()
            mock_empty.data = []
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value = mock_empty
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

            response = client.get(f"/api/v1/fasting-impact/ai-insight/{MOCK_USER_ID}?days=30")

            assert response.status_code == 200
            data = response.json()
            assert data["user_id"] == MOCK_USER_ID
            assert data["insight_type"] == "positive"
            assert "title" in data
            assert "message" in data
            assert "recommendation" in data

    def test_get_ai_insight_with_different_days(self, client, mock_supabase, mock_activity_logger):
        """Test AI insight with different day ranges."""
        mock_insight = {
            "id": str(uuid.uuid4()),
            "user_id": MOCK_USER_ID,
            "insight_type": "neutral",
            "title": "Building Data",
            "message": "Keep tracking for more insights.",
            "recommendation": "Continue logging your data.",
            "data_summary": {},
            "created_at": datetime.utcnow().isoformat(),
        }

        with patch("api.v1.fasting_impact.get_fasting_insight_service") as mock_service:
            mock_fasting_service = MagicMock()
            mock_fasting_service.get_fasting_summary_for_insight = AsyncMock(return_value={})
            mock_fasting_service.generate_fasting_impact_insight = AsyncMock(return_value=mock_insight)
            mock_service.return_value = mock_fasting_service

            mock_empty = MagicMock()
            mock_empty.data = []
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value = mock_empty
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

            for days in [7, 30, 90]:
                response = client.get(f"/api/v1/fasting-impact/ai-insight/{MOCK_USER_ID}?days={days}")
                assert response.status_code == 200

    def test_get_ai_insight_invalid_days(self, client, mock_supabase):
        """Test AI insight with invalid days parameter."""
        response = client.get(f"/api/v1/fasting-impact/ai-insight/{MOCK_USER_ID}?days=5")
        assert response.status_code == 422

        response = client.get(f"/api/v1/fasting-impact/ai-insight/{MOCK_USER_ID}?days=100")
        assert response.status_code == 422


class TestRefreshAIFastingInsight:
    """Tests for POST /fasting-impact/ai-insight/refresh/{user_id}"""

    def test_refresh_ai_insight_success(self, client, mock_supabase, mock_activity_logger):
        """Test refreshing AI insight."""
        mock_insight = {
            "id": str(uuid.uuid4()),
            "user_id": MOCK_USER_ID,
            "insight_type": "positive",
            "title": "Fresh Analysis",
            "message": "Updated analysis of your fasting patterns.",
            "recommendation": "Continue your progress.",
            "data_summary": {},
            "created_at": datetime.utcnow().isoformat(),
        }

        with patch("api.v1.fasting_impact.get_fasting_insight_service") as mock_service:
            mock_fasting_service = MagicMock()
            mock_fasting_service.get_fasting_summary_for_insight = AsyncMock(return_value={})
            mock_fasting_service.generate_fasting_impact_insight = AsyncMock(return_value=mock_insight)
            mock_service.return_value = mock_fasting_service

            mock_empty = MagicMock()
            mock_empty.data = []
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value = mock_empty
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_empty

            response = client.post(f"/api/v1/fasting-impact/ai-insight/refresh/{MOCK_USER_ID}?days=30")

            assert response.status_code == 200
            data = response.json()
            assert data["user_id"] == MOCK_USER_ID


class TestGetAICorrelationScore:
    """Tests for GET /fasting-impact/ai-correlation/{user_id}"""

    def test_get_correlation_score_success(self, client, mock_supabase):
        """Test getting AI correlation score."""
        with patch("api.v1.fasting_impact.get_fasting_insight_service") as mock_service:
            mock_fasting_service = MagicMock()
            mock_fasting_service.calculate_correlation_score = AsyncMock(return_value=0.45)
            mock_service.return_value = mock_fasting_service

            response = client.get(f"/api/v1/fasting-impact/ai-correlation/{MOCK_USER_ID}?days=30")

            assert response.status_code == 200
            data = response.json()
            assert data["user_id"] == MOCK_USER_ID
            assert data["correlation_score"] == 0.45
            assert data["days_analyzed"] == 30
            assert "interpretation" in data
            assert data["sufficient_data"] is True

    def test_get_correlation_score_no_correlation(self, client, mock_supabase):
        """Test correlation score when there's no correlation."""
        with patch("api.v1.fasting_impact.get_fasting_insight_service") as mock_service:
            mock_fasting_service = MagicMock()
            mock_fasting_service.calculate_correlation_score = AsyncMock(return_value=0.0)
            mock_service.return_value = mock_fasting_service

            response = client.get(f"/api/v1/fasting-impact/ai-correlation/{MOCK_USER_ID}?days=30")

            assert response.status_code == 200
            data = response.json()
            assert data["correlation_score"] == 0.0
            assert data["sufficient_data"] is False


class TestGetAIFastingSummary:
    """Tests for GET /fasting-impact/ai-summary/{user_id}"""

    def test_get_fasting_summary_success(self, client, mock_supabase):
        """Test getting AI fasting summary."""
        mock_summary = {
            "total_fasting_days": 15,
            "total_non_fasting_days": 15,
            "most_common_protocol": "16:8",
            "avg_fast_duration_hours": 16.5,
            "correlation_score": 0.35,
        }

        with patch("api.v1.fasting_impact.get_fasting_insight_service") as mock_service:
            mock_fasting_service = MagicMock()
            mock_fasting_service.get_fasting_summary_for_insight = AsyncMock(return_value=mock_summary)
            mock_service.return_value = mock_fasting_service

            response = client.get(f"/api/v1/fasting-impact/ai-summary/{MOCK_USER_ID}?days=30")

            assert response.status_code == 200
            data = response.json()
            assert data["user_id"] == MOCK_USER_ID
            assert data["total_fasting_days"] == 15
            assert data["most_common_protocol"] == "16:8"
            assert data["avg_fast_duration_hours"] == 16.5
            assert data["period_days"] == 30


# =============================================================================
# Helper Function Tests
# =============================================================================

class TestHelperFunctions:
    """Tests for helper functions in the fasting impact module."""

    def test_calculate_correlation_score_positive(self):
        """Test correlation calculation with positive correlation."""
        from api.v1.fasting_impact import calculate_correlation_score

        # All fasting days successful, all non-fasting days unsuccessful
        fasting_success = [True, True, True, True, True]
        non_fasting_success = [False, False, False, False, False]

        score = calculate_correlation_score(fasting_success, non_fasting_success)
        assert score is not None
        assert score > 0.5  # Strong positive correlation

    def test_calculate_correlation_score_no_data(self):
        """Test correlation calculation with no data."""
        from api.v1.fasting_impact import calculate_correlation_score

        score = calculate_correlation_score([], [])
        assert score is None

    def test_calculate_correlation_score_insufficient_data(self):
        """Test correlation calculation with insufficient data."""
        from api.v1.fasting_impact import calculate_correlation_score

        score = calculate_correlation_score([True], [False])
        assert score is None  # Less than 5 data points

    def test_interpret_correlation_strong_positive(self):
        """Test correlation interpretation for strong positive."""
        from api.v1.fasting_impact import interpret_correlation

        interpretation = interpret_correlation(0.6)
        assert "Strong positive" in interpretation

    def test_interpret_correlation_moderate_positive(self):
        """Test correlation interpretation for moderate positive."""
        from api.v1.fasting_impact import interpret_correlation

        interpretation = interpret_correlation(0.4)
        assert "Moderate positive" in interpretation

    def test_interpret_correlation_no_correlation(self):
        """Test correlation interpretation for no correlation."""
        from api.v1.fasting_impact import interpret_correlation

        interpretation = interpret_correlation(0.05)
        assert "No significant correlation" in interpretation

    def test_interpret_correlation_negative(self):
        """Test correlation interpretation for negative correlation."""
        from api.v1.fasting_impact import interpret_correlation

        interpretation = interpret_correlation(-0.4)
        assert "Moderate negative" in interpretation

    def test_interpret_correlation_none(self):
        """Test correlation interpretation when score is None."""
        from api.v1.fasting_impact import interpret_correlation

        interpretation = interpret_correlation(None)
        assert "Not enough data" in interpretation

    def test_generate_impact_insight_positive_weight(self):
        """Test insight generation with positive weight trend."""
        from api.v1.fasting_impact import generate_impact_insight

        insights = generate_impact_insight(
            weight_trend="decreasing",
            avg_weight_fasting=70.0,
            avg_weight_non_fasting=72.0,
            workout_completion_fasting=None,
            workout_completion_non_fasting=None,
            goal_rate_fasting=None,
            goal_rate_non_fasting=None,
            correlation_score=None,
        )

        assert insights["overall_trend"] == "positive"
        assert insights["weight_insight"] is not None
        assert insights["weight_insight"]["direction"] == "positive"

    def test_generate_impact_insight_performance_difference(self):
        """Test insight generation with workout performance difference."""
        from api.v1.fasting_impact import generate_impact_insight

        # Better performance on fasting days
        insights = generate_impact_insight(
            weight_trend=None,
            avg_weight_fasting=None,
            avg_weight_non_fasting=None,
            workout_completion_fasting=90.0,
            workout_completion_non_fasting=75.0,  # 15% difference
            goal_rate_fasting=None,
            goal_rate_non_fasting=None,
            correlation_score=None,
        )

        assert any("complete" in finding.lower() and "more" in finding.lower()
                  for finding in insights["key_findings"])
        assert insights["performance_insight"] is not None

    def test_generate_impact_insight_lower_performance(self):
        """Test insight generation when fasting hurts performance."""
        from api.v1.fasting_impact import generate_impact_insight

        # Worse performance on fasting days
        insights = generate_impact_insight(
            weight_trend=None,
            avg_weight_fasting=None,
            avg_weight_non_fasting=None,
            workout_completion_fasting=70.0,
            workout_completion_non_fasting=85.0,  # 15% lower on fasting
            goal_rate_fasting=None,
            goal_rate_non_fasting=None,
            correlation_score=None,
        )

        assert any("lower" in finding.lower() for finding in insights["key_findings"])
        assert "eating window" in " ".join(insights["personalized_tips"]).lower() or \
               "lighter" in " ".join(insights["personalized_tips"]).lower()

    def test_generate_impact_insight_defaults(self):
        """Test insight generation returns defaults when no significant data."""
        from api.v1.fasting_impact import generate_impact_insight

        insights = generate_impact_insight(
            weight_trend=None,
            avg_weight_fasting=None,
            avg_weight_non_fasting=None,
            workout_completion_fasting=None,
            workout_completion_non_fasting=None,
            goal_rate_fasting=None,
            goal_rate_non_fasting=None,
            correlation_score=None,
        )

        assert len(insights["key_findings"]) > 0
        assert len(insights["personalized_tips"]) > 0
        assert "tracking" in insights["key_findings"][0].lower() or \
               "keep" in insights["personalized_tips"][0].lower()


class TestInterpretAICorrelation:
    """Tests for interpret_ai_correlation function."""

    def test_strong_positive(self):
        """Test strong positive correlation interpretation."""
        from api.v1.fasting_impact import interpret_ai_correlation

        result = interpret_ai_correlation(0.6)
        assert "Strong positive" in result
        assert "significantly" in result.lower()

    def test_moderate_positive(self):
        """Test moderate positive correlation interpretation."""
        from api.v1.fasting_impact import interpret_ai_correlation

        result = interpret_ai_correlation(0.4)
        assert "Moderate positive" in result

    def test_slight_positive(self):
        """Test slight positive correlation interpretation."""
        from api.v1.fasting_impact import interpret_ai_correlation

        result = interpret_ai_correlation(0.15)
        assert "Slight positive" in result

    def test_no_correlation(self):
        """Test no correlation interpretation."""
        from api.v1.fasting_impact import interpret_ai_correlation

        result = interpret_ai_correlation(0.05)
        assert "No clear correlation" in result

    def test_slight_negative(self):
        """Test slight negative correlation interpretation."""
        from api.v1.fasting_impact import interpret_ai_correlation

        result = interpret_ai_correlation(-0.2)
        assert "Slight negative" in result

    def test_moderate_negative(self):
        """Test moderate negative correlation interpretation."""
        from api.v1.fasting_impact import interpret_ai_correlation

        result = interpret_ai_correlation(-0.4)
        assert "Moderate negative" in result

    def test_strong_negative(self):
        """Test strong negative correlation interpretation."""
        from api.v1.fasting_impact import interpret_ai_correlation

        result = interpret_ai_correlation(-0.6)
        assert "Strong negative" in result


# =============================================================================
# Edge Case Tests
# =============================================================================

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_calendar_december_to_january_transition(self, client, mock_supabase):
        """Test calendar at year boundary (December)."""
        mock_empty = MagicMock()
        mock_empty.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.neq.return_value.execute.return_value = mock_empty
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.execute.return_value = mock_empty

        response = client.get(f"/api/v1/fasting-impact/calendar/{MOCK_USER_ID}?month=12&year=2024")
        assert response.status_code == 200
        assert len(response.json()["days"]) == 31

    def test_weight_logging_database_error(self, client, mock_supabase, mock_activity_logger):
        """Test handling database error during weight logging."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.neq.return_value.or_.return_value.execute.side_effect = Exception("Database error")

        response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": 75.0,
                "date": date.today().isoformat(),
            }
        )

        assert response.status_code == 500

    def test_correlation_with_uniform_data(self):
        """Test correlation when all values are the same."""
        from api.v1.fasting_impact import calculate_correlation_score

        # All successes
        fasting_success = [True, True, True, True, True]
        non_fasting_success = [True, True, True, True, True]

        score = calculate_correlation_score(fasting_success, non_fasting_success)
        # With identical data, correlation should be 0 (no variance)
        assert score == 0.0 or score is None


# =============================================================================
# Async Helper Function Tests
# =============================================================================

class TestAsyncHelperFunctions:
    """Tests for async helper functions."""

    @pytest.mark.asyncio
    async def test_get_fasting_status_for_date_fasting_day(self, mock_supabase):
        """Test getting fasting status when it's a fasting day."""
        from api.v1.fasting_impact import get_fasting_status_for_date

        mock_result = MagicMock()
        mock_result.data = [generate_mock_fasting_record(protocol="18:6")]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.neq.return_value.or_.return_value.execute.return_value = mock_result

        with patch("api.v1.fasting_impact.get_supabase_db", return_value=mock_supabase):
            status = await get_fasting_status_for_date(MOCK_USER_ID, date.today())

        assert status["is_fasting_day"] is True
        assert status["protocol"] == "18:6"
        assert status["fasting_record_id"] is not None

    @pytest.mark.asyncio
    async def test_get_fasting_status_for_date_non_fasting_day(self, mock_supabase):
        """Test getting fasting status when it's not a fasting day."""
        from api.v1.fasting_impact import get_fasting_status_for_date

        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.neq.return_value.or_.return_value.execute.return_value = mock_result

        with patch("api.v1.fasting_impact.get_supabase_db", return_value=mock_supabase):
            status = await get_fasting_status_for_date(MOCK_USER_ID, date.today())

        assert status["is_fasting_day"] is False
        assert status["protocol"] is None
        assert status["fasting_record_id"] is None

    @pytest.mark.asyncio
    async def test_get_weight_data_for_ai(self, mock_supabase):
        """Test getting weight data for AI analysis."""
        from api.v1.fasting_impact import get_weight_data_for_ai

        mock_weight_result = MagicMock()
        mock_weight_result.data = [
            {"date": "2024-12-01", "weight_kg": 75.0},
            {"date": "2024-12-02", "weight_kg": 74.5},
        ]

        mock_fasting_result = MagicMock()
        mock_fasting_result.data = [
            {"start_time": "2024-12-01T08:00:00Z"},
        ]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value = mock_weight_result
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.gte.return_value.execute.return_value = mock_fasting_result

        with patch("api.v1.fasting_impact.get_supabase_db", return_value=mock_supabase):
            data = await get_weight_data_for_ai(MOCK_USER_ID, 30)

        assert len(data) == 2
        assert data[0]["is_fasting_day"] is True  # Dec 1 was a fasting day
        assert data[1]["is_fasting_day"] is False  # Dec 2 was not

    @pytest.mark.asyncio
    async def test_get_goal_data_for_ai(self, mock_supabase):
        """Test getting goal data for AI analysis."""
        from api.v1.fasting_impact import get_goal_data_for_ai

        mock_fasting_result = MagicMock()
        mock_fasting_result.data = [
            {"start_time": "2024-12-01T08:00:00Z"},
        ]

        mock_workout_result = MagicMock()
        mock_workout_result.data = [
            {"date": "2024-12-01", "completed": True},
            {"date": "2024-12-02", "completed": True},
        ]

        mock_goals_result = MagicMock()
        mock_goals_result.data = [
            {"date": "2024-12-01", "completed": True},
            {"date": "2024-12-02", "completed": True},
        ]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.gte.return_value.execute.return_value = mock_fasting_result
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.side_effect = [
            mock_workout_result, mock_goals_result
        ]

        with patch("api.v1.fasting_impact.get_supabase_db", return_value=mock_supabase):
            data = await get_goal_data_for_ai(MOCK_USER_ID, 30)

        assert "goals_fasting" in data
        assert "goals_non_fasting" in data
        assert "workout_completion_fasting" in data
        assert "workout_completion_non_fasting" in data


# =============================================================================
# Pydantic Model Validation Tests
# =============================================================================

class TestPydanticModels:
    """Test Pydantic model validation."""

    def test_log_weight_request_validation(self):
        """Test LogWeightWithFastingRequest model validation."""
        from api.v1.fasting_impact import LogWeightWithFastingRequest

        # Valid request
        request = LogWeightWithFastingRequest(
            user_id="test-user-123",
            weight_kg=75.5,
            date="2024-12-15",
            notes="Morning weight",
        )
        assert request.weight_kg == 75.5
        assert request.user_id == "test-user-123"

        # Weight must be positive
        with pytest.raises(Exception):
            LogWeightWithFastingRequest(
                user_id="test-user-123",
                weight_kg=0,
                date="2024-12-15",
            )

    def test_weight_log_response_model(self):
        """Test WeightLogResponse model."""
        from api.v1.fasting_impact import WeightLogResponse

        response = WeightLogResponse(
            id="log-123",
            user_id="user-456",
            weight_kg=75.0,
            date="2024-12-15",
            is_fasting_day=True,
            fasting_protocol="16:8",
            fasting_completion_percent=100.0,
            created_at="2024-12-15T08:00:00Z",
        )

        assert response.is_fasting_day is True
        assert response.fasting_protocol == "16:8"

    def test_calendar_day_data_model(self):
        """Test CalendarDayData model."""
        from api.v1.fasting_impact import CalendarDayData

        day = CalendarDayData(
            date="2024-12-15",
            is_fasting_day=True,
            fasting_protocol="16:8",
            fasting_completion_percent=100.0,
            weight_logged=75.0,
            workout_completed=True,
            goals_hit=3,
            goals_total=5,
        )

        assert day.is_fasting_day is True
        assert day.goals_hit == 3
        assert day.workout_completed is True


# =============================================================================
# Integration-Style Tests
# =============================================================================

class TestFastingImpactIntegration:
    """Integration-style tests for fasting impact analysis flow."""

    def test_full_weight_logging_and_correlation_flow(self, client, mock_supabase, mock_activity_logger):
        """Test complete flow from weight logging to correlation retrieval."""
        today = date.today().isoformat()

        # Step 1: Log weight (mock fasting day)
        mock_fasting_result = MagicMock()
        mock_fasting_result.data = [generate_mock_fasting_record()]

        mock_insert_result = MagicMock()
        mock_insert_result.data = [generate_mock_weight_log(
            weight_kg=75.0,
            is_fasting_day=True,
            fasting_protocol="16:8",
        )]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.neq.return_value.or_.return_value.execute.return_value = mock_fasting_result
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        log_response = client.post(
            "/api/v1/fasting-impact/weight",
            json={
                "user_id": MOCK_USER_ID,
                "weight_kg": 75.0,
                "date": today,
            }
        )

        assert log_response.status_code == 200
        assert log_response.json()["is_fasting_day"] is True

        # Step 2: Get correlation
        mock_weight_logs = [
            generate_mock_weight_log(weight_kg=75.0, is_fasting_day=True),
            generate_mock_weight_log(weight_kg=76.0, is_fasting_day=False),
        ]

        mock_corr_result = MagicMock()
        mock_corr_result.data = mock_weight_logs

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.return_value = mock_corr_result

        corr_response = client.get(f"/api/v1/fasting-impact/weight-correlation/{MOCK_USER_ID}")

        assert corr_response.status_code == 200
        assert len(corr_response.json()["weight_logs"]) == 2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
