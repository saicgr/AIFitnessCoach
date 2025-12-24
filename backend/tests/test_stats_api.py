"""
Tests for Comprehensive Stats API endpoints.

Tests all stats aggregation endpoints including:
- Overview stats
- Quick stats
- Workout frequency
- Weight trends
- Nutrition statistics
- Volume progression
"""
import pytest
from unittest.mock import Mock, MagicMock, patch
from datetime import datetime, timedelta
from fastapi.testclient import TestClient


# Mock data generators
def generate_mock_workout_logs(user_id: str, count: int = 10):
    """Generate mock workout logs."""
    logs = []
    base_date = datetime.now() - timedelta(days=30)

    for i in range(count):
        logs.append({
            "id": f"log-{i}",
            "user_id": user_id,
            "completed_at": (base_date + timedelta(days=i*3)).isoformat(),
            "duration_minutes": 45 + (i % 15),
            "exercises_performance": [
                {
                    "exercise_name": "Bench Press",
                    "sets": [
                        {"reps": 10, "weight_kg": 60 + i},
                        {"reps": 8, "weight_kg": 65 + i},
                    ]
                }
            ]
        })

    return logs


def generate_mock_achievements(user_id: str, count: int = 5):
    """Generate mock user achievements."""
    achievements = []

    for i in range(count):
        achievements.append({
            "id": f"ach-{i}",
            "user_id": user_id,
            "achievement_id": f"workout_{10 + i*10}",
            "earned_at": (datetime.now() - timedelta(days=i*7)).isoformat(),
            "trigger_value": 10 + i*10,
            "trigger_details": {"workout_count": 10 + i*10},
            "is_notified": True,
            "achievement_types": {
                "id": f"workout_{10 + i*10}",
                "name": f"Complete {10 + i*10} Workouts",
                "icon": "🏆",
                "category": "consistency",
                "tier": "bronze"
            }
        })

    return achievements


def generate_mock_personal_records(user_id: str, count: int = 3):
    """Generate mock personal records."""
    exercises = ["Bench Press", "Squat", "Deadlift"]
    prs = []

    for i in range(min(count, len(exercises))):
        prs.append({
            "id": f"pr-{i}",
            "user_id": user_id,
            "exercise_name": exercises[i],
            "record_type": "weight",
            "record_value": 100 + i*20,
            "record_unit": "kg",
            "previous_value": 90 + i*20,
            "improvement_percentage": 11.1,
            "achieved_at": (datetime.now() - timedelta(days=i*14)).isoformat()
        })

    return prs


def generate_mock_body_measurements(user_id: str, count: int = 10):
    """Generate mock body measurements."""
    measurements = []
    base_date = datetime.now() - timedelta(days=90)

    for i in range(count):
        measurements.append({
            "id": f"meas-{i}",
            "user_id": user_id,
            "measured_at": (base_date + timedelta(days=i*9)).isoformat(),
            "weight_kg": 75.0 - (i * 0.5),
            "body_fat_percent": 18.0 - (i * 0.2),
            "bmi": 23.5 - (i * 0.1),
            "waist_cm": 85.0 - (i * 0.3),
            "chest_cm": 100.0,
            "bicep_left_cm": 35.0,
            "bicep_right_cm": 35.0,
            "thigh_left_cm": 58.0,
            "thigh_right_cm": 58.0
        })

    return measurements


def generate_mock_food_logs(user_id: str, days: int = 7):
    """Generate mock food logs."""
    logs = []
    base_date = datetime.now() - timedelta(days=days)

    for i in range(days):
        # 2-3 meals per day
        for meal in range(2 + (i % 2)):
            logs.append({
                "id": f"food-{i}-{meal}",
                "user_id": user_id,
                "logged_at": (base_date + timedelta(days=i, hours=8 + meal*5)).isoformat(),
                "total_calories": 500 + (meal * 100),
                "protein_g": 30 + (meal * 10),
                "carbs_g": 50 + (meal * 15),
                "fat_g": 15 + (meal * 5)
            })

    return logs


def generate_mock_hydration_logs(user_id: str, days: int = 7):
    """Generate mock hydration logs."""
    logs = []
    base_date = datetime.now() - timedelta(days=days)

    for i in range(days):
        logs.append({
            "id": f"hydration-{i}",
            "user_id": user_id,
            "logged_at": (base_date + timedelta(days=i)).isoformat(),
            "amount_ml": 2000 + (i * 100)
        })

    return logs


class TestStatsOverview:
    """Tests for comprehensive stats overview endpoint."""

    @patch('api.v1.stats.get_supabase_db')
    def test_get_overview_success(self, mock_db, client):
        """Test successful stats overview retrieval."""
        user_id = "test-user-123"

        # Mock database responses
        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        # Mock workout logs count
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.count = 25

        # Mock workout logs for duration
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = \
            generate_mock_workout_logs(user_id, 10)

        # Mock streak data
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "current_streak": 7,
            "longest_streak": 14
        }]

        # Mock achievements
        mock_client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = \
            generate_mock_achievements(user_id, 5)

        # Mock personal records
        mock_prs = generate_mock_personal_records(user_id, 3)

        # Mock body measurements
        mock_measurements = generate_mock_body_measurements(user_id, 1)

        # Configure the mock to return different data for different table calls
        def table_side_effect(table_name):
            mock_table = MagicMock()

            if table_name == "workout_logs":
                mock_table.select.return_value.eq.return_value.execute.return_value.count = 25
                mock_table.select.return_value.eq.return_value.execute.return_value.data = generate_mock_workout_logs(user_id, 10)
                mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.count = 5
            elif table_name == "user_streaks":
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
                    "current_streak": 7,
                    "longest_streak": 14
                }]
            elif table_name == "user_achievements":
                mock_table.select.return_value.eq.return_value.execute.return_value.count = 15
                mock_table.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = \
                    generate_mock_achievements(user_id, 5)
            elif table_name == "personal_records":
                mock_table.select.return_value.eq.return_value.execute.return_value.count = 3
                mock_table.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = mock_prs
            elif table_name == "body_measurements":
                mock_table.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = mock_measurements

            return mock_table

        mock_client.table.side_effect = table_side_effect

        response = client.get(f"/api/v1/stats/overview/{user_id}")

        assert response.status_code == 200
        data = response.json()

        # Verify structure
        assert "quick_stats" in data
        assert "recent_achievements" in data
        assert "top_prs" in data
        assert "body_measurements" in data

        # Verify quick_stats content
        quick_stats = data["quick_stats"]
        assert "total_workouts" in quick_stats
        assert "current_streak" in quick_stats
        assert "longest_streak" in quick_stats

    @patch('api.v1.stats.get_supabase_db')
    def test_get_overview_no_data(self, mock_db, client):
        """Test overview with no user data."""
        user_id = "new-user-456"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        # Mock empty responses
        def table_side_effect(table_name):
            mock_table = MagicMock()
            mock_table.select.return_value.eq.return_value.execute.return_value.count = 0
            mock_table.select.return_value.eq.return_value.execute.return_value.data = []
            mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
            mock_table.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []
            return mock_table

        mock_client.table.side_effect = table_side_effect

        response = client.get(f"/api/v1/stats/overview/{user_id}")

        assert response.status_code == 200
        data = response.json()

        # Should still return valid structure with zeros
        assert data["quick_stats"]["total_workouts"] == 0
        assert len(data["recent_achievements"]) == 0
        assert len(data["top_prs"]) == 0


class TestQuickStats:
    """Tests for quick stats endpoint."""

    @patch('api.v1.stats.get_supabase_db')
    def test_get_quick_stats_success(self, mock_db, client):
        """Test successful quick stats retrieval."""
        user_id = "test-user-123"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        # Mock workout counts
        def table_side_effect(table_name):
            mock_table = MagicMock()

            if table_name == "workout_logs":
                # Total workouts
                mock_table.select.return_value.eq.return_value.execute.return_value.count = 50
                # With duration data
                mock_table.select.return_value.eq.return_value.execute.return_value.data = \
                    generate_mock_workout_logs(user_id, 10)
                # This week
                mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.count = 3
            elif table_name == "user_streaks":
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
                    "current_streak": 5,
                    "longest_streak": 12
                }]
            elif table_name == "user_achievements":
                mock_table.select.return_value.eq.return_value.execute.return_value.count = 8
            elif table_name == "personal_records":
                mock_table.select.return_value.eq.return_value.execute.return_value.count = 5

            return mock_table

        mock_client.table.side_effect = table_side_effect

        response = client.get(f"/api/v1/stats/quick/{user_id}")

        assert response.status_code == 200
        data = response.json()

        assert data["total_workouts"] >= 0
        assert data["current_streak"] >= 0
        assert data["longest_streak"] >= 0
        assert data["total_achievements"] >= 0
        assert data["total_prs"] >= 0


class TestWorkoutFrequency:
    """Tests for workout frequency endpoint."""

    @patch('api.v1.stats.get_supabase_db')
    def test_get_workout_frequency_success(self, mock_db, client):
        """Test successful workout frequency retrieval."""
        user_id = "test-user-123"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        # Mock workout logs over 12 weeks
        mock_logs = generate_mock_workout_logs(user_id, 24)

        mock_table = MagicMock()
        mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.data = mock_logs
        mock_client.table.return_value = mock_table

        response = client.get(f"/api/v1/stats/workout-frequency/{user_id}?weeks=12")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        # Should have weekly data
        if data:
            assert "week_start_date" in data[0]
            assert "week_number" in data[0]
            assert "workouts_count" in data[0]
            assert "total_minutes" in data[0]

    @patch('api.v1.stats.get_supabase_db')
    def test_get_workout_frequency_custom_weeks(self, mock_db, client):
        """Test workout frequency with custom week count."""
        user_id = "test-user-123"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        mock_table = MagicMock()
        mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.data = \
            generate_mock_workout_logs(user_id, 8)
        mock_client.table.return_value = mock_table

        response = client.get(f"/api/v1/stats/workout-frequency/{user_id}?weeks=4")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)


class TestWeightTrend:
    """Tests for weight trend endpoint."""

    @patch('api.v1.stats.get_supabase_db')
    def test_get_weight_trend_success(self, mock_db, client):
        """Test successful weight trend retrieval."""
        user_id = "test-user-123"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        # Mock body measurements
        mock_measurements = generate_mock_body_measurements(user_id, 10)

        mock_table = MagicMock()
        mock_table.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value.data = \
            mock_measurements
        mock_client.table.return_value = mock_table

        response = client.get(f"/api/v1/stats/weight-trend/{user_id}?days=90")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        if data:
            assert "date" in data[0]
            assert "weight_kg" in data[0]
            # Optional fields
            assert "body_fat_percent" in data[0]
            assert "bmi" in data[0]

    @patch('api.v1.stats.get_supabase_db')
    def test_get_weight_trend_no_measurements(self, mock_db, client):
        """Test weight trend with no measurements."""
        user_id = "new-user-789"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        mock_table = MagicMock()
        mock_table.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value.data = []
        mock_client.table.return_value = mock_table

        response = client.get(f"/api/v1/stats/weight-trend/{user_id}?days=90")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0


class TestNutritionStats:
    """Tests for nutrition statistics endpoint."""

    @patch('api.v1.stats.get_supabase_db')
    def test_get_nutrition_stats_success(self, mock_db, client):
        """Test successful nutrition stats retrieval."""
        user_id = "test-user-123"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        # Mock food and hydration logs
        mock_food_logs = generate_mock_food_logs(user_id, 7)
        mock_hydration_logs = generate_mock_hydration_logs(user_id, 7)

        def table_side_effect(table_name):
            mock_table = MagicMock()

            if table_name == "food_logs":
                mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.data = \
                    mock_food_logs
            elif table_name == "hydration_logs":
                mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.data = \
                    mock_hydration_logs

            return mock_table

        mock_client.table.side_effect = table_side_effect

        response = client.get(f"/api/v1/stats/nutrition/{user_id}?days=7")

        assert response.status_code == 200
        data = response.json()

        assert "avg_daily_calories" in data
        assert "avg_daily_protein_g" in data
        assert "avg_daily_carbs_g" in data
        assert "avg_daily_fat_g" in data
        assert "avg_daily_water_ml" in data
        assert "days_tracked" in data
        assert "calorie_trend" in data

        # Averages should be reasonable
        assert data["avg_daily_calories"] >= 0
        assert data["avg_daily_protein_g"] >= 0

    @patch('api.v1.stats.get_supabase_db')
    def test_get_nutrition_stats_no_data(self, mock_db, client):
        """Test nutrition stats with no data."""
        user_id = "new-user-456"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        def table_side_effect(table_name):
            mock_table = MagicMock()
            mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.data = []
            return mock_table

        mock_client.table.side_effect = table_side_effect

        response = client.get(f"/api/v1/stats/nutrition/{user_id}?days=7")

        assert response.status_code == 200
        data = response.json()

        # Should return zeros for averages
        assert data["avg_daily_calories"] == 0
        assert data["days_tracked"] == 0


class TestVolumeProgress:
    """Tests for training volume progression endpoint."""

    @patch('api.v1.stats.get_supabase_db')
    def test_get_volume_progress_success(self, mock_db, client):
        """Test successful volume progress retrieval."""
        user_id = "test-user-123"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        # Mock workout logs with performance data
        mock_logs = generate_mock_workout_logs(user_id, 10)

        mock_table = MagicMock()
        mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.data = mock_logs
        mock_client.table.return_value = mock_table

        response = client.get(f"/api/v1/stats/volume-progress/{user_id}?days=30")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        if data:
            assert "date" in data[0]
            assert "total_sets" in data[0]
            assert "total_reps" in data[0]
            assert "total_weight_kg" in data[0]


class TestStatsErrorHandling:
    """Tests for error handling in stats endpoints."""

    @patch('api.v1.stats.get_supabase_db')
    def test_overview_database_error(self, mock_db, client):
        """Test overview endpoint handles database errors."""
        user_id = "test-user-123"

        # Mock database error
        mock_db.side_effect = Exception("Database connection failed")

        response = client.get(f"/api/v1/stats/overview/{user_id}")

        assert response.status_code == 500
        assert "detail" in response.json()

    @patch('api.v1.stats.get_supabase_db')
    def test_quick_stats_database_error(self, mock_db, client):
        """Test quick stats endpoint handles database errors."""
        user_id = "test-user-123"

        mock_db.side_effect = Exception("Database error")

        response = client.get(f"/api/v1/stats/quick/{user_id}")

        assert response.status_code == 500


class TestStatsEdgeCases:
    """Tests for edge cases in stats calculations."""

    @patch('api.v1.stats.get_supabase_db')
    def test_zero_workout_duration_handled(self, mock_db, client):
        """Test that zero duration workouts are handled correctly."""
        user_id = "test-user-123"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        # Mock workout with zero duration
        mock_logs = [{
            "id": "log-1",
            "user_id": user_id,
            "completed_at": datetime.now().isoformat(),
            "duration_minutes": 0,
            "exercises_performance": []
        }]

        def table_side_effect(table_name):
            mock_table = MagicMock()

            if table_name == "workout_logs":
                mock_table.select.return_value.eq.return_value.execute.return_value.count = 1
                mock_table.select.return_value.eq.return_value.execute.return_value.data = mock_logs
                mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.count = 1
            else:
                mock_table.select.return_value.eq.return_value.execute.return_value.count = 0
                mock_table.select.return_value.eq.return_value.execute.return_value.data = []
                mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

            return mock_table

        mock_client.table.side_effect = table_side_effect

        response = client.get(f"/api/v1/stats/quick/{user_id}")

        assert response.status_code == 200
        data = response.json()

        # Should handle division by zero gracefully
        assert data["avg_workout_duration"] == 0

    @patch('api.v1.stats.get_supabase_db')
    def test_negative_days_parameter(self, mock_db, client):
        """Test that negative days parameter is handled."""
        user_id = "test-user-123"

        mock_client = MagicMock()
        mock_db.return_value.client = mock_client

        mock_table = MagicMock()
        mock_table.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value.data = []
        mock_client.table.return_value = mock_table

        # API should still work even with negative days (will just use that in calculation)
        response = client.get(f"/api/v1/stats/weight-trend/{user_id}?days=-10")

        # Should still return 200, just with no data
        assert response.status_code in [200, 422]  # 422 if validation rejects negative
