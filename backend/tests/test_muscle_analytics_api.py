"""
Tests for Muscle Analytics API endpoints.

Tests muscle heatmap, training frequency, balance analysis,
and per-muscle exercise data.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from datetime import datetime, date, timedelta
import uuid

# Import app and router
from main import app
from api.v1.muscle_analytics import (
    router,
    TimeRange,
    ViewType,
    MuscleHeatmapResponse,
    MuscleFrequencyResponse,
    MuscleBalanceResponse,
    MuscleExercisesResponse,
    MuscleHistoryResponse,
)

client = TestClient(app)

# Test data
TEST_USER_ID = str(uuid.uuid4())


class TestMuscleHeatmapEndpoint:
    """Tests for GET /muscle-analytics/heatmap"""

    def test_get_heatmap_success(self):
        """Test successful heatmap data retrieval."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            # Mock RPC call
            mock_result = MagicMock()
            mock_result.data = {
                "user_id": TEST_USER_ID,
                "period_days": 28,
                "max_volume_kg": 5000.0,
                "muscles": [
                    {
                        "muscle_group": "chest",
                        "total_volume_kg": 5000.0,
                        "intensity_score": 100,
                        "workout_count": 8,
                        "color": "high",
                        "hex_color": "#FF4444",
                    },
                    {
                        "muscle_group": "back",
                        "total_volume_kg": 4000.0,
                        "intensity_score": 80,
                        "workout_count": 6,
                        "color": "high",
                        "hex_color": "#FF4444",
                    },
                    {
                        "muscle_group": "legs",
                        "total_volume_kg": 2000.0,
                        "intensity_score": 40,
                        "workout_count": 4,
                        "color": "medium",
                        "hex_color": "#FF8844",
                    },
                ],
            }
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/heatmap",
                params={"user_id": TEST_USER_ID, "time_range": "4_weeks"}
            )

            assert response.status_code == 200
            data = response.json()
            assert "muscles" in data
            assert len(data["muscles"]) == 3
            assert data["most_trained"] == "chest"
            assert data["least_trained"] == "legs"

    def test_get_heatmap_fallback(self):
        """Test heatmap with fallback query when RPC fails."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            # Make RPC fail
            mock_client.rpc.return_value.execute.side_effect = Exception("RPC failed")

            # Mock fallback query
            mock_result = MagicMock()
            mock_result.data = [
                {
                    "muscle_group": "chest",
                    "total_volume_last_30_days_kg": 5000.0,
                    "workout_count_last_30_days": 8,
                    "last_workout_date": "2024-01-15",
                    "days_since_last_training": 2,
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/heatmap",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["muscles"]) == 1

    def test_get_heatmap_empty(self):
        """Test heatmap with no data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = {"muscles": []}
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/heatmap",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["muscles"] == []


class TestMuscleFrequencyEndpoint:
    """Tests for GET /muscle-analytics/frequency"""

    def test_get_frequency_success(self):
        """Test successful frequency data retrieval."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "muscle_group": "chest",
                    "workout_count_last_7_days": 2,
                    "workout_count_last_30_days": 8,
                    "total_workout_count": 50,
                    "total_volume_all_time_kg": 100000.0,
                    "avg_days_between_training": 3.5,
                    "last_workout_date": "2024-01-15",
                    "days_since_last_training": 2,
                },
                {
                    "muscle_group": "calves",
                    "workout_count_last_7_days": 0,
                    "workout_count_last_30_days": 2,
                    "total_workout_count": 10,
                    "total_volume_all_time_kg": 10000.0,
                    "avg_days_between_training": 14.0,
                    "last_workout_date": "2024-01-01",
                    "days_since_last_training": 16,
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/frequency",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["frequencies"]) == 2
            # Chest should be optimal, calves should be undertrained
            assert data["undertrained_count"] == 1
            assert data["overtrained_count"] == 0

    def test_get_frequency_empty(self):
        """Test frequency with no data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = []
            mock_client.from_.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/frequency",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["frequencies"] == []
            assert data["avg_weekly_workouts"] == 0


class TestMuscleBalanceEndpoint:
    """Tests for GET /muscle-analytics/balance"""

    def test_get_balance_balanced(self):
        """Test balance analysis with balanced training."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "push_volume_kg": 5000.0,
                    "pull_volume_kg": 5000.0,
                    "push_pull_ratio": 1.0,
                    "upper_volume_kg": 10000.0,
                    "lower_volume_kg": 8000.0,
                    "upper_lower_ratio": 1.25,
                    "chest_volume_kg": 3000.0,
                    "back_volume_kg": 3500.0,
                    "chest_back_ratio": 0.86,
                    "quad_volume_kg": 4000.0,
                    "hamstring_volume_kg": 2000.0,
                    "quad_hamstring_ratio": 2.0,
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/balance",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["ratios"]) == 4
            assert data["overall_status"] == "balanced"
            assert data["imbalance_count"] == 0

    def test_get_balance_imbalanced(self):
        """Test balance analysis with imbalanced training."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "push_volume_kg": 8000.0,
                    "pull_volume_kg": 4000.0,
                    "push_pull_ratio": 2.0,  # Too high - push dominant
                    "upper_volume_kg": 15000.0,
                    "lower_volume_kg": 5000.0,
                    "upper_lower_ratio": 3.0,  # Too high - upper dominant
                    "chest_volume_kg": 5000.0,
                    "back_volume_kg": 2000.0,
                    "chest_back_ratio": 2.5,
                    "quad_volume_kg": 4000.0,
                    "hamstring_volume_kg": 1000.0,
                    "quad_hamstring_ratio": 4.0,  # Too high
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/balance",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["imbalance_count"] >= 2
            assert data["overall_status"] == "significant_imbalances"
            assert len(data["recommendations"]) > 0

    def test_get_balance_empty(self):
        """Test balance with no data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = []
            mock_client.from_.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/balance",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["ratios"] == []


class TestMuscleExercisesEndpoint:
    """Tests for GET /muscle-analytics/muscle/{muscle_group}/exercises"""

    def test_get_exercises_success(self):
        """Test successful muscle exercises retrieval."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = {
                "exercises": [
                    {
                        "exercise_name": "bench press",
                        "times_performed": 50,
                        "total_volume_kg": 50000.0,
                        "max_weight_kg": 100.0,
                        "last_performed": "2024-01-15",
                    },
                    {
                        "exercise_name": "incline press",
                        "times_performed": 30,
                        "total_volume_kg": 25000.0,
                        "max_weight_kg": 80.0,
                        "last_performed": "2024-01-14",
                    },
                ],
            }
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/chest/exercises",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["exercises"]) == 2
            assert data["muscle_group"] == "chest"
            # First exercise should have higher contribution
            assert data["exercises"][0]["contribution"] > data["exercises"][1]["contribution"]

    def test_get_exercises_empty(self):
        """Test muscle exercises with no data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = {"exercises": []}
            mock_client.rpc.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/forearms/exercises",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["exercises"] == []
            assert data["total_exercises"] == 0


class TestMuscleHistoryEndpoint:
    """Tests for GET /muscle-analytics/muscle/{muscle_group}/history"""

    def test_get_history_success(self):
        """Test successful muscle history retrieval."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "week_start": "2024-01-01",
                    "week_number": 1,
                    "year": 2024,
                    "total_sets": 15,
                    "total_volume_kg": 5000.0,
                    "exercise_count": 3,
                    "max_weight_kg": 100.0,
                },
                {
                    "week_start": "2024-01-08",
                    "week_number": 2,
                    "year": 2024,
                    "total_sets": 18,
                    "total_volume_kg": 6000.0,
                    "exercise_count": 4,
                    "max_weight_kg": 105.0,
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/chest/history",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data["data_points"]) == 2
            assert data["volume_trend"] == "improving"
            assert data["volume_change"] > 0

    def test_get_history_declining(self):
        """Test muscle history with declining trend."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {
                    "week_start": "2024-01-01",
                    "week_number": 1,
                    "year": 2024,
                    "total_sets": 20,
                    "total_volume_kg": 8000.0,
                },
                {
                    "week_start": "2024-01-08",
                    "week_number": 2,
                    "year": 2024,
                    "total_sets": 12,
                    "total_volume_kg": 5000.0,
                },
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/chest/history",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["volume_trend"] == "declining"

    def test_get_history_insufficient_data(self):
        """Test muscle history with insufficient data."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [
                {"week_start": "2024-01-01", "week_number": 1, "year": 2024, "total_sets": 15, "total_volume_kg": 5000.0},
            ]
            mock_client.from_.return_value.select.return_value.eq.return_value.ilike.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

            response = client.get(
                "/api/v1/muscle-analytics/muscle/chest/history",
                params={"user_id": TEST_USER_ID}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["volume_trend"] == "insufficient_data"


class TestLogViewEndpoint:
    """Tests for POST /muscle-analytics/log-view"""

    def test_log_view_heatmap(self):
        """Test logging heatmap view."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [{"id": str(uuid.uuid4())}]
            mock_client.from_.return_value.insert.return_value.execute.return_value = mock_result

            response = client.post(
                "/api/v1/muscle-analytics/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "view_type": "heatmap",
                    "session_duration_seconds": 30,
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "logged"

    def test_log_view_muscle_detail(self):
        """Test logging muscle detail view."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client

            mock_result = MagicMock()
            mock_result.data = [{"id": str(uuid.uuid4())}]
            mock_client.from_.return_value.insert.return_value.execute.return_value = mock_result

            response = client.post(
                "/api/v1/muscle-analytics/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "view_type": "muscle_detail",
                    "muscle_group": "chest",
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "logged"

    def test_log_view_handles_error(self):
        """Test view logging handles database errors gracefully."""
        with patch("api.v1.muscle_analytics.get_supabase_db") as mock_db:
            mock_client = MagicMock()
            mock_db.return_value.client = mock_client
            mock_client.from_.return_value.insert.return_value.execute.side_effect = Exception("DB Error")

            response = client.post(
                "/api/v1/muscle-analytics/log-view",
                json={
                    "user_id": TEST_USER_ID,
                    "view_type": "heatmap",
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "error"


class TestHelperFunctions:
    """Tests for helper functions."""

    def test_time_range_conversion(self):
        """Test time range to days conversion."""
        from api.v1.muscle_analytics import get_days_for_time_range

        assert get_days_for_time_range(TimeRange.ONE_WEEK) == 7
        assert get_days_for_time_range(TimeRange.TWO_WEEKS) == 14
        assert get_days_for_time_range(TimeRange.FOUR_WEEKS) == 28
        assert get_days_for_time_range(TimeRange.EIGHT_WEEKS) == 56
        assert get_days_for_time_range(TimeRange.TWELVE_WEEKS) == 84

    def test_intensity_color(self):
        """Test intensity to color conversion."""
        from api.v1.muscle_analytics import get_intensity_color

        color, hex_color = get_intensity_color(0.9)
        assert color == "high"
        assert hex_color == "#FF4444"

        color, hex_color = get_intensity_color(0.6)
        assert color == "medium"

        color, hex_color = get_intensity_color(0.3)
        assert color == "low"

        color, hex_color = get_intensity_color(0.1)
        assert color == "none"

    def test_frequency_recommendation(self):
        """Test frequency recommendation logic."""
        from api.v1.muscle_analytics import get_frequency_recommendation

        assert get_frequency_recommendation(0.5) == "undertrained"
        assert get_frequency_recommendation(2.0) == "optimal"
        assert get_frequency_recommendation(5.0) == "overtrained"

    def test_balance_status(self):
        """Test balance status determination."""
        from api.v1.muscle_analytics import get_balance_status

        status, rec = get_balance_status(1.0, 0.8, 1.2)
        assert status == "balanced"

        status, rec = get_balance_status(1.4, 0.8, 1.2)
        assert status == "imbalanced"

        status, rec = get_balance_status(2.0, 0.8, 1.2)
        assert status == "severe_imbalance"

        status, rec = get_balance_status(0, 0.8, 1.2)
        assert status == "insufficient_data"
