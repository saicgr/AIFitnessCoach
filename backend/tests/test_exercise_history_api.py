"""
Tests for Exercise History API endpoints.

Tests per-exercise workout history, progression charts,
personal records, and most performed exercises.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from datetime import datetime, date, timedelta
import uuid

# Import app and router
from main import app
from api.v1.exercise_history import (
    router,
    TimeRange,
    ExerciseHistoryResponse,
    ExerciseChartDataResponse,
    ExercisePersonalRecordsResponse,
    MostPerformedExercisesResponse,
)

client = TestClient(app)

# Test data
TEST_USER_ID = str(uuid.uuid4())
TEST_EXERCISE_NAME = "bench press"


class TestExerciseHistoryEndpoint:
    """Tests for GET /exercise-history/{exercise_name}"""

    def test_get_exercise_history_success(self):
        """Test successful exercise history retrieval."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            # Mock the database queries
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            # Mock count query
            mock_count_result = MagicMock()
            mock_count_result.count = 5
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.execute.return_value = mock_count_result

            # Mock history query
            mock_history_result = MagicMock()
            mock_history_result.data = [
                {
                    "workout_log_id": str(uuid.uuid4()),
                    "exercise_name": "bench press",
                    "workout_date": "2024-01-15",
                    "workout_name": "Push Day",
                    "workout_type": "strength",
                    "sets_completed": 4,
                    "total_reps": 32,
                    "total_volume_kg": 2400.0,
                    "max_weight_kg": 80.0,
                    "estimated_1rm_kg": 96.0,
                    "avg_rpe": 7.5,
                },
                {
                    "workout_log_id": str(uuid.uuid4()),
                    "exercise_name": "bench press",
                    "workout_date": "2024-01-12",
                    "workout_name": "Upper Body",
                    "workout_type": "strength",
                    "sets_completed": 3,
                    "total_reps": 24,
                    "total_volume_kg": 1800.0,
                    "max_weight_kg": 75.0,
                    "estimated_1rm_kg": 90.0,
                    "avg_rpe": 7.0,
                },
            ]

            # Configure the chain of method calls
            mock_chain = MagicMock()
            mock_chain.execute.return_value = mock_history_result
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.range.return_value = mock_chain

            # Mock PR query
            mock_pr_result = MagicMock()
            mock_pr_result.data = []
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.eq.return_value.execute.return_value = mock_pr_result

            response = client.get(
                f"/v1/exercise-history/{TEST_EXERCISE_NAME}",
                params={"user_id": TEST_USER_ID, "time_range": "12_weeks"}
            )

            assert response.status_code == 200
            data = response.json()
            assert "records" in data
            assert "summary" in data
            assert data["exercise_name"] == TEST_EXERCISE_NAME

    def test_get_exercise_history_empty(self):
        """Test exercise history with no data."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            # Mock empty results
            mock_result = MagicMock()
            mock_result.count = 0
            mock_result.data = []
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.execute.return_value = mock_result
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.range.return_value.execute.return_value = mock_result

            response = client.get(
                f"/v1/exercise-history/unknown_exercise",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["total_records"] == 0
            assert data["records"] == []

    def test_get_exercise_history_missing_user_id(self):
        """Test exercise history without user_id parameter."""
        response = client.get(f"/v1/exercise-history/{TEST_EXERCISE_NAME}")
        assert response.status_code == 422  # Validation error

    def test_get_exercise_history_pagination(self):
        """Test exercise history pagination."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.count = 50
            mock_result.data = [{"workout_log_id": str(uuid.uuid4())} for _ in range(20)]

            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.execute.return_value = mock_result
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.range.return_value.execute.return_value = mock_result

            # Mock PR query
            mock_pr_result = MagicMock()
            mock_pr_result.data = []
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.eq.return_value.execute.return_value = mock_pr_result

            response = client.get(
                f"/v1/exercise-history/{TEST_EXERCISE_NAME}",
                params={"user_id": TEST_USER_ID, "page": 1, "limit": 20}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["has_more"] == True
            assert data["total_pages"] == 3


class TestExerciseChartDataEndpoint:
    """Tests for GET /exercise-history/{exercise_name}/chart"""

    def test_get_chart_data_success(self):
        """Test successful chart data retrieval."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "workout_date": "2024-01-01",
                    "max_weight_kg": 70.0,
                    "avg_weight_kg": 65.0,
                    "total_volume_kg": 1400.0,
                    "total_reps": 30,
                    "estimated_1rm_kg": 84.0,
                },
                {
                    "workout_date": "2024-01-15",
                    "max_weight_kg": 75.0,
                    "avg_weight_kg": 70.0,
                    "total_volume_kg": 1600.0,
                    "total_reps": 32,
                    "estimated_1rm_kg": 90.0,
                },
                {
                    "workout_date": "2024-01-29",
                    "max_weight_kg": 80.0,
                    "avg_weight_kg": 75.0,
                    "total_volume_kg": 1800.0,
                    "total_reps": 35,
                    "estimated_1rm_kg": 96.0,
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                f"/v1/exercise-history/{TEST_EXERCISE_NAME}/chart",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert "data_points" in data
            assert "trend" in data
            assert len(data["data_points"]) == 3
            assert data["trend"]["direction"] == "improving"

    def test_get_chart_data_declining_trend(self):
        """Test chart data with declining trend."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {"workout_date": "2024-01-01", "max_weight_kg": 80.0},
                {"workout_date": "2024-01-15", "max_weight_kg": 70.0},
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                f"/v1/exercise-history/{TEST_EXERCISE_NAME}/chart",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["trend"]["direction"] == "declining"

    def test_get_chart_data_insufficient_data(self):
        """Test chart data with insufficient data points."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [{"workout_date": "2024-01-01", "max_weight_kg": 70.0}]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                f"/v1/exercise-history/{TEST_EXERCISE_NAME}/chart",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["trend"]["direction"] == "no_data"


class TestExercisePersonalRecordsEndpoint:
    """Tests for GET /exercise-history/{exercise_name}/prs"""

    def test_get_prs_success(self):
        """Test successful PR retrieval."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "record_type": "max_weight",
                    "record_value": 100.0,
                    "record_unit": "kg",
                    "achieved_at": "2024-01-15T10:00:00",
                    "workout_name": "Push Day",
                    "reps_at_record": 5,
                    "weight_at_record_kg": 100.0,
                },
                {
                    "record_type": "best_1rm",
                    "record_value": 120.0,
                    "record_unit": "kg",
                    "achieved_at": "2024-01-15T10:00:00",
                    "workout_name": "Push Day",
                },
                {
                    "record_type": "max_volume",
                    "record_value": 3000.0,
                    "record_unit": "kg",
                    "achieved_at": "2024-01-10T09:00:00",
                    "workout_name": "Upper Body",
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                f"/v1/exercise-history/{TEST_EXERCISE_NAME}/prs",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["records"]) == 3
            assert data["max_weight"]["value"] == 100.0
            assert data["max_1rm"]["value"] == 120.0
            assert data["max_volume"]["value"] == 3000.0

    def test_get_prs_empty(self):
        """Test PR retrieval with no records."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = []
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                f"/v1/exercise-history/unknown_exercise/prs",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["records"] == []
            assert data["max_weight"] is None


class TestMostPerformedExercisesEndpoint:
    """Tests for GET /exercise-history/most-performed"""

    def test_get_most_performed_success(self):
        """Test successful most performed exercises retrieval."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = {
                "exercises": [
                    {
                        "exercise_name": "bench press",
                        "muscle_group": "chest",
                        "times_performed": 50,
                        "total_volume_kg": 50000.0,
                        "max_weight_kg": 100.0,
                        "last_performed_at": "2024-01-15",
                    },
                    {
                        "exercise_name": "squat",
                        "muscle_group": "quadriceps",
                        "times_performed": 45,
                        "total_volume_kg": 75000.0,
                        "max_weight_kg": 150.0,
                        "last_performed_at": "2024-01-14",
                    },
                ],
                "total_unique_exercises": 25,
            }
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/v1/exercise-history/most-performed",
                params={"user_id": TEST_USER_ID, "limit": 10}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["exercises"]) == 2
            assert data["exercises"][0]["exercise_name"] == "bench press"
            assert data["total_unique_exercises"] == 25


class TestLogViewEndpoint:
    """Tests for POST /exercise-history/log-view"""

    def test_log_view_success(self):
        """Test successful view logging."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [{"id": str(uuid.uuid4())}]
            mock_client.from_.return_value.insert.return_value.execute.return_value = mock_result

            response = client.post(
                "/v1/exercise-history/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "exercise_name": TEST_EXERCISE_NAME,
                    "session_duration_seconds": 120,
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "logged"

    def test_log_view_handles_error(self):
        """Test view logging handles database errors gracefully."""
        with patch("api.v1.exercise_history.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client
            mock_client.from_.return_value.insert.return_value.execute.side_effect = Exception("DB Error")

            response = client.post(
                "/v1/exercise-history/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "exercise_name": TEST_EXERCISE_NAME,
                }
            )

            # Should not fail, just return error status
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "error"


class TestTimeRangeConversion:
    """Tests for time range helper function."""

    def test_time_range_values(self):
        """Test all time range enum values convert correctly."""
        from api.v1.exercise_history import get_days_for_time_range

        assert get_days_for_time_range(TimeRange.FOUR_WEEKS) == 28
        assert get_days_for_time_range(TimeRange.EIGHT_WEEKS) == 56
        assert get_days_for_time_range(TimeRange.TWELVE_WEEKS) == 84
        assert get_days_for_time_range(TimeRange.SIX_MONTHS) == 180
        assert get_days_for_time_range(TimeRange.ONE_YEAR) == 365
        assert get_days_for_time_range(TimeRange.ALL_TIME) == 3650
