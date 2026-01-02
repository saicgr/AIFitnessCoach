"""
Tests for the Progress Charts API endpoints.

Tests the /api/v1/progress/* endpoints that provide
progress visualization data for charts.

Run with: pytest tests/test_progress_charts.py -v
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, date, timedelta

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.v1.progress import (
    TimeRange,
    ChartType,
    WeeklyStrengthData,
    WeeklyVolumeData,
    ExerciseStrengthData,
    StrengthProgressionResponse,
    VolumeProgressionResponse,
    ExerciseProgressionResponse,
    ProgressSummaryResponse,
    ChartViewLogRequest,
    _get_cutoff_date,
    _get_week_number,
    _get_year,
    _calculate_strength_summary,
    _calculate_volume_trend,
    _calculate_exercise_improvement,
)


# ============================================================================
# Unit Tests for Helper Functions
# ============================================================================

class TestGetCutoffDate:
    """Tests for the _get_cutoff_date helper function."""

    def test_four_weeks_cutoff(self):
        """Should return date 4 weeks ago."""
        cutoff = _get_cutoff_date(TimeRange.FOUR_WEEKS)
        expected = (datetime.now() - timedelta(weeks=4)).date()
        assert cutoff == expected

    def test_eight_weeks_cutoff(self):
        """Should return date 8 weeks ago."""
        cutoff = _get_cutoff_date(TimeRange.EIGHT_WEEKS)
        expected = (datetime.now() - timedelta(weeks=8)).date()
        assert cutoff == expected

    def test_twelve_weeks_cutoff(self):
        """Should return date 12 weeks ago."""
        cutoff = _get_cutoff_date(TimeRange.TWELVE_WEEKS)
        expected = (datetime.now() - timedelta(weeks=12)).date()
        assert cutoff == expected

    def test_all_time_returns_none(self):
        """Should return None for all_time range."""
        cutoff = _get_cutoff_date(TimeRange.ALL_TIME)
        assert cutoff is None


class TestGetWeekNumber:
    """Tests for the _get_week_number helper function."""

    def test_valid_date_string(self):
        """Should extract week number from valid date string."""
        result = _get_week_number("2024-01-15")
        assert isinstance(result, int)
        assert 1 <= result <= 53

    def test_datetime_string(self):
        """Should handle datetime string with time component."""
        result = _get_week_number("2024-01-15T10:00:00Z")
        assert isinstance(result, int)

    def test_invalid_date_returns_zero(self):
        """Should return 0 for invalid date string."""
        result = _get_week_number("invalid-date")
        assert result == 0


class TestGetYear:
    """Tests for the _get_year helper function."""

    def test_valid_date_string(self):
        """Should extract year from valid date string."""
        result = _get_year("2024-01-15")
        assert result == 2024

    def test_datetime_string(self):
        """Should handle datetime string."""
        result = _get_year("2024-06-20T10:00:00Z")
        assert result == 2024

    def test_invalid_date_returns_current_year(self):
        """Should return current year for invalid date."""
        result = _get_year("invalid-date")
        assert result == datetime.now().year


class TestCalculateStrengthSummary:
    """Tests for the _calculate_strength_summary helper function."""

    def test_empty_data_returns_defaults(self):
        """Should return default values for empty data."""
        result = _calculate_strength_summary([])

        assert result["total_volume_kg"] == 0
        assert result["total_sets"] == 0
        assert result["avg_weekly_volume_kg"] == 0
        assert result["top_muscle_group"] is None
        assert result["volume_trend"] == "no_data"

    def test_calculates_totals(self):
        """Should calculate total volume and sets correctly."""
        data = [
            WeeklyStrengthData(
                week_start="2024-01-01",
                week_number=1,
                year=2024,
                muscle_group="chest",
                total_sets=20,
                total_reps=200,
                total_volume_kg=5000.0,
                max_weight_kg=100.0,
                workout_count=4,
            ),
            WeeklyStrengthData(
                week_start="2024-01-08",
                week_number=2,
                year=2024,
                muscle_group="back",
                total_sets=18,
                total_reps=180,
                total_volume_kg=4500.0,
                max_weight_kg=90.0,
                workout_count=4,
            ),
        ]
        result = _calculate_strength_summary(data)

        assert result["total_volume_kg"] == 9500.0
        assert result["total_sets"] == 38

    def test_identifies_top_muscle_group(self):
        """Should identify muscle group with highest volume."""
        data = [
            WeeklyStrengthData(
                week_start="2024-01-01",
                week_number=1,
                year=2024,
                muscle_group="chest",
                total_sets=10,
                total_reps=100,
                total_volume_kg=2000.0,
                max_weight_kg=80.0,
                workout_count=2,
            ),
            WeeklyStrengthData(
                week_start="2024-01-01",
                week_number=1,
                year=2024,
                muscle_group="back",
                total_sets=15,
                total_reps=150,
                total_volume_kg=4000.0,
                max_weight_kg=100.0,
                workout_count=3,
            ),
        ]
        result = _calculate_strength_summary(data)

        assert result["top_muscle_group"] == "back"

    def test_calculates_improving_trend(self):
        """Should identify improving trend when second half volume is higher."""
        data = [
            WeeklyStrengthData(
                week_start="2024-01-01", week_number=1, year=2024,
                muscle_group="chest", total_sets=10, total_reps=100,
                total_volume_kg=1000.0, max_weight_kg=50.0, workout_count=2,
            ),
            WeeklyStrengthData(
                week_start="2024-01-08", week_number=2, year=2024,
                muscle_group="chest", total_sets=10, total_reps=100,
                total_volume_kg=1100.0, max_weight_kg=55.0, workout_count=2,
            ),
            WeeklyStrengthData(
                week_start="2024-01-15", week_number=3, year=2024,
                muscle_group="chest", total_sets=12, total_reps=120,
                total_volume_kg=1500.0, max_weight_kg=60.0, workout_count=2,
            ),
            WeeklyStrengthData(
                week_start="2024-01-22", week_number=4, year=2024,
                muscle_group="chest", total_sets=14, total_reps=140,
                total_volume_kg=1800.0, max_weight_kg=65.0, workout_count=2,
            ),
        ]
        result = _calculate_strength_summary(data)

        assert result["volume_trend"] == "improving"

    def test_calculates_declining_trend(self):
        """Should identify declining trend when second half volume is lower."""
        data = [
            WeeklyStrengthData(
                week_start="2024-01-01", week_number=1, year=2024,
                muscle_group="chest", total_sets=14, total_reps=140,
                total_volume_kg=2000.0, max_weight_kg=70.0, workout_count=2,
            ),
            WeeklyStrengthData(
                week_start="2024-01-08", week_number=2, year=2024,
                muscle_group="chest", total_sets=12, total_reps=120,
                total_volume_kg=1800.0, max_weight_kg=65.0, workout_count=2,
            ),
            WeeklyStrengthData(
                week_start="2024-01-15", week_number=3, year=2024,
                muscle_group="chest", total_sets=10, total_reps=100,
                total_volume_kg=1200.0, max_weight_kg=60.0, workout_count=2,
            ),
            WeeklyStrengthData(
                week_start="2024-01-22", week_number=4, year=2024,
                muscle_group="chest", total_sets=8, total_reps=80,
                total_volume_kg=1000.0, max_weight_kg=55.0, workout_count=2,
            ),
        ]
        result = _calculate_strength_summary(data)

        assert result["volume_trend"] == "declining"


class TestCalculateVolumeTrend:
    """Tests for the _calculate_volume_trend helper function."""

    def test_empty_data_returns_no_data(self):
        """Should return no_data for empty list."""
        result = _calculate_volume_trend([])

        assert result["direction"] == "no_data"
        assert result["percent_change"] == 0

    def test_identifies_peak_week(self):
        """Should identify week with highest volume."""
        data = [
            WeeklyVolumeData(
                week_start="2024-01-01", week_number=1, year=2024,
                workouts_completed=3, total_minutes=120, avg_duration_minutes=40.0,
                total_volume_kg=3000.0, total_sets=30, total_reps=300,
            ),
            WeeklyVolumeData(
                week_start="2024-01-08", week_number=2, year=2024,
                workouts_completed=4, total_minutes=160, avg_duration_minutes=40.0,
                total_volume_kg=5000.0, total_sets=40, total_reps=400,
            ),
            WeeklyVolumeData(
                week_start="2024-01-15", week_number=3, year=2024,
                workouts_completed=3, total_minutes=120, avg_duration_minutes=40.0,
                total_volume_kg=3500.0, total_sets=35, total_reps=350,
            ),
        ]
        result = _calculate_volume_trend(data)

        assert result["peak_volume_kg"] == 5000.0
        assert result["peak_week"] == "2024-01-08"

    def test_calculates_improving_direction(self):
        """Should identify improving direction."""
        data = [
            WeeklyVolumeData(
                week_start="2024-01-01", week_number=1, year=2024,
                workouts_completed=2, total_minutes=80, avg_duration_minutes=40.0,
                total_volume_kg=2000.0, total_sets=20, total_reps=200,
            ),
            WeeklyVolumeData(
                week_start="2024-01-08", week_number=2, year=2024,
                workouts_completed=3, total_minutes=120, avg_duration_minutes=40.0,
                total_volume_kg=3500.0, total_sets=35, total_reps=350,
            ),
        ]
        result = _calculate_volume_trend(data)

        assert result["direction"] == "improving"
        assert result["percent_change"] > 0


class TestCalculateExerciseImprovement:
    """Tests for the _calculate_exercise_improvement helper function."""

    def test_empty_data_returns_no_improvement(self):
        """Should return no improvement for empty data."""
        result = _calculate_exercise_improvement([])

        assert result["has_improvement"] is False
        assert result["weight_increase_kg"] == 0
        assert result["rm_increase_kg"] == 0

    def test_calculates_weight_increase(self):
        """Should calculate weight increase correctly."""
        data = [
            ExerciseStrengthData(
                exercise_name="Bench Press", muscle_group="chest",
                week_start="2024-01-01", times_performed=4,
                max_weight_kg=80.0, estimated_1rm_kg=90.0,
            ),
            ExerciseStrengthData(
                exercise_name="Bench Press", muscle_group="chest",
                week_start="2024-01-15", times_performed=4,
                max_weight_kg=90.0, estimated_1rm_kg=100.0,
            ),
        ]
        result = _calculate_exercise_improvement(data)

        assert result["has_improvement"] is True
        assert result["weight_increase_kg"] == 10.0
        assert result["rm_increase_kg"] == 10.0

    def test_calculates_percentage_increase(self):
        """Should calculate percentage increase correctly."""
        data = [
            ExerciseStrengthData(
                exercise_name="Squat", muscle_group="legs",
                week_start="2024-01-01", times_performed=3,
                max_weight_kg=100.0, estimated_1rm_kg=120.0,
            ),
            ExerciseStrengthData(
                exercise_name="Squat", muscle_group="legs",
                week_start="2024-02-01", times_performed=3,
                max_weight_kg=110.0, estimated_1rm_kg=130.0,
            ),
        ]
        result = _calculate_exercise_improvement(data)

        assert result["weight_increase_percent"] == 10.0
        assert round(result["rm_increase_percent"], 1) == 8.3


# ============================================================================
# API Endpoint Tests
# ============================================================================

class TestStrengthOverTimeEndpoint:
    """Tests for GET /progress/strength-over-time endpoint."""

    def test_endpoint_exists(self, client):
        """Test that strength endpoint exists."""
        response = client.get(
            "/api/v1/progress/strength-over-time?user_id=test-user"
        )
        assert response.status_code != 404

    def test_requires_user_id(self, client):
        """Test that user_id is required."""
        response = client.get("/api/v1/progress/strength-over-time")
        assert response.status_code == 422

    @patch('api.v1.progress.get_supabase_db')
    def test_returns_strength_data(self, mock_db, client):
        """Should return strength progression data."""
        mock_result = MagicMock()
        mock_result.data = [
            {
                "week_start": "2024-01-01",
                "muscle_group": "chest",
                "total_sets": 20,
                "total_reps": 200,
                "total_volume_kg": 5000,
                "max_weight_kg": 100,
                "workout_count": 4,
            },
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/progress/strength-over-time?user_id=test-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "muscle_groups" in data
        assert "summary" in data

    @patch('api.v1.progress.get_supabase_db')
    def test_accepts_time_range_parameter(self, mock_db, client):
        """Should accept time_range parameter."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/progress/strength-over-time?user_id=test-user&time_range=4_weeks"
        )

        assert response.status_code == 200

    @patch('api.v1.progress.get_supabase_db')
    def test_accepts_muscle_group_filter(self, mock_db, client):
        """Should accept muscle_group filter parameter."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/progress/strength-over-time?user_id=test-user&muscle_group=chest"
        )

        assert response.status_code == 200


class TestVolumeOverTimeEndpoint:
    """Tests for GET /progress/volume-over-time endpoint."""

    def test_endpoint_exists(self, client):
        """Test that volume endpoint exists."""
        response = client.get(
            "/api/v1/progress/volume-over-time?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.progress.get_supabase_db')
    def test_returns_volume_data(self, mock_db, client):
        """Should return volume progression data."""
        mock_result = MagicMock()
        mock_result.data = [
            {
                "week_start": "2024-01-01",
                "week_number": 1,
                "year": 2024,
                "workouts_completed": 3,
                "total_minutes": 120,
                "avg_duration_minutes": 40,
                "total_volume_kg": 4000,
                "total_sets": 40,
                "total_reps": 400,
            },
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/progress/volume-over-time?user_id=test-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "trend" in data


class TestExerciseProgressionEndpoint:
    """Tests for GET /progress/exercise/{exercise_name} endpoint."""

    def test_endpoint_exists(self, client):
        """Test that exercise endpoint exists."""
        response = client.get(
            "/api/v1/progress/exercise/bench-press?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.progress.get_supabase_db')
    def test_returns_exercise_data(self, mock_db, client):
        """Should return exercise-specific progression data."""
        mock_result = MagicMock()
        mock_result.data = [
            {
                "exercise_name": "Bench Press",
                "muscle_group": "chest",
                "week_start": "2024-01-01",
                "times_performed": 4,
                "max_weight_kg": 80,
                "estimated_1rm_kg": 90,
            },
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.ilike.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/progress/exercise/bench-press?user_id=test-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "improvement" in data
        assert data["exercise_name"] == "bench-press"


class TestProgressSummaryEndpoint:
    """Tests for GET /progress/summary endpoint."""

    def test_endpoint_exists(self, client):
        """Test that summary endpoint exists."""
        response = client.get(
            "/api/v1/progress/summary?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.progress.get_supabase_db')
    def test_returns_summary_data(self, mock_db, client):
        """Should return progress summary data."""
        mock_rpc_result = MagicMock()
        mock_rpc_result.data = [{
            "total_workouts": 50,
            "total_volume_kg": 100000,
            "total_prs": 10,
            "first_workout_date": "2024-01-01",
            "last_workout_date": "2024-03-15",
            "volume_increase_percent": 25.5,
            "avg_weekly_workouts": 4.2,
            "current_streak": 7,
        }]

        mock_muscle_result = MagicMock()
        mock_muscle_result.data = [
            {"muscle_group": "chest", "total_sets": 100, "total_volume_kg": 20000},
        ]

        mock_prs_result = MagicMock()
        mock_prs_result.data = []

        mock_best_week_result = MagicMock()
        mock_best_week_result.data = [{
            "week_start": "2024-02-15",
            "total_volume_kg": 8000,
            "workouts_completed": 5,
            "total_sets": 50,
        }]

        mock_db_instance = MagicMock()
        mock_db_instance.client.rpc.return_value.execute.return_value = mock_rpc_result

        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.limit.return_value = mock_query

        # Different results for different table calls
        def table_side_effect(table_name):
            query = MagicMock()
            query.select.return_value = query
            query.eq.return_value = query
            query.gte.return_value = query
            query.order.return_value = query
            query.limit.return_value = query

            if table_name == "muscle_group_weekly_volume":
                query.execute.return_value = mock_muscle_result
            elif table_name == "personal_records":
                query.execute.return_value = mock_prs_result
            elif table_name == "weekly_progress_summary":
                query.execute.return_value = mock_best_week_result
            else:
                query.execute.return_value = MagicMock(data=[])
            return query

        mock_db_instance.client.table = MagicMock(side_effect=table_side_effect)
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/progress/summary?user_id=test-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert "total_workouts" in data
        assert "total_volume_kg" in data
        assert "muscle_group_breakdown" in data


class TestLogChartViewEndpoint:
    """Tests for POST /progress/log-view endpoint."""

    def test_endpoint_exists(self, client):
        """Test that log-view endpoint exists."""
        response = client.post(
            "/api/v1/progress/log-view",
            json={
                "user_id": "test-user",
                "chart_type": "strength",
                "time_range": "12_weeks",
            }
        )
        assert response.status_code != 404

    @patch('api.v1.progress.get_supabase_db')
    def test_logs_chart_view(self, mock_db, client):
        """Should log chart view successfully."""
        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.insert.return_value.execute.return_value = MagicMock(data=[{}])
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.post(
            "/api/v1/progress/log-view",
            json={
                "user_id": "test-user",
                "chart_type": "strength",
                "time_range": "12_weeks",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    @patch('api.v1.progress.get_supabase_db')
    def test_handles_logging_error_gracefully(self, mock_db, client):
        """Should handle logging error without failing request."""
        mock_db_instance = MagicMock()
        mock_db_instance.client.table.side_effect = Exception("DB error")
        mock_db.return_value = mock_db_instance

        response = client.post(
            "/api/v1/progress/log-view",
            json={
                "user_id": "test-user",
                "chart_type": "volume",
                "time_range": "4_weeks",
            }
        )

        # Should not fail, just return success=False
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False


class TestMuscleGroupsEndpoint:
    """Tests for GET /progress/muscle-groups/{user_id} endpoint."""

    def test_endpoint_exists(self, client):
        """Test that muscle-groups endpoint exists."""
        response = client.get(
            "/api/v1/progress/muscle-groups/test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.progress.get_supabase_db')
    def test_returns_muscle_groups(self, mock_db, client):
        """Should return list of trained muscle groups."""
        mock_result = MagicMock()
        mock_result.data = [
            {"muscle_group": "chest"},
            {"muscle_group": "back"},
            {"muscle_group": "legs"},
            {"muscle_group": "chest"},  # Duplicate to test uniqueness
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value = mock_query
        mock_query.eq.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/progress/muscle-groups/test-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert "muscle_groups" in data
        assert "count" in data
        # Should be unique
        assert len(set(data["muscle_groups"])) == data["count"]


# ============================================================================
# Response Model Tests
# ============================================================================

class TestWeeklyStrengthDataModel:
    """Tests for the WeeklyStrengthData model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        data = WeeklyStrengthData(
            week_start="2024-01-01",
            week_number=1,
            year=2024,
            muscle_group="chest",
            total_sets=20,
            total_reps=200,
            total_volume_kg=5000.0,
            max_weight_kg=100.0,
            workout_count=4,
        )

        assert data.week_start == "2024-01-01"
        assert data.muscle_group == "chest"
        assert data.total_volume_kg == 5000.0


class TestTimeRangeEnum:
    """Tests for the TimeRange enum."""

    def test_all_values_defined(self):
        """Should have all expected time range values."""
        assert TimeRange.FOUR_WEEKS.value == "4_weeks"
        assert TimeRange.EIGHT_WEEKS.value == "8_weeks"
        assert TimeRange.TWELVE_WEEKS.value == "12_weeks"
        assert TimeRange.ALL_TIME.value == "all_time"


class TestChartTypeEnum:
    """Tests for the ChartType enum."""

    def test_all_values_defined(self):
        """Should have all expected chart type values."""
        assert ChartType.STRENGTH.value == "strength"
        assert ChartType.VOLUME.value == "volume"
        assert ChartType.SUMMARY.value == "summary"
        assert ChartType.MUSCLE_GROUP.value == "muscle_group"
        assert ChartType.ALL.value == "all"


class TestChartViewLogRequestModel:
    """Tests for the ChartViewLogRequest model."""

    def test_required_fields(self):
        """Should require user_id, chart_type, and time_range."""
        request = ChartViewLogRequest(
            user_id="test-user",
            chart_type=ChartType.STRENGTH,
            time_range=TimeRange.TWELVE_WEEKS,
        )

        assert request.user_id == "test-user"
        assert request.chart_type == ChartType.STRENGTH

    def test_optional_fields(self):
        """Should accept optional fields."""
        request = ChartViewLogRequest(
            user_id="test-user",
            chart_type=ChartType.MUSCLE_GROUP,
            time_range=TimeRange.EIGHT_WEEKS,
            muscle_group="chest",
            session_duration_seconds=120,
        )

        assert request.muscle_group == "chest"
        assert request.session_duration_seconds == 120
