"""
Tests for additional API endpoints: achievements, exercises, hydration.

Tests:
- Achievement types and user achievements
- Streaks and personal records
- Exercise CRUD operations
- Hydration logging and goals

Run with: pytest backend/tests/test_additional_apis.py -v
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock, AsyncMock
from datetime import datetime, date, timedelta, timezone
import uuid

from main import app


client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock Supabase database for testing."""
    with patch('api.v1.achievements.get_supabase_db') as mock:
        db_mock = MagicMock()
        mock.return_value = db_mock
        yield db_mock


@pytest.fixture
def mock_exercises_db():
    """Mock Supabase database for exercises."""
    with patch('api.v1.exercises.get_supabase_db') as mock:
        db_mock = MagicMock()
        mock.return_value = db_mock
        yield db_mock


@pytest.fixture
def mock_hydration_db():
    """Mock Supabase database for hydration."""
    with patch('api.v1.hydration.get_supabase_db') as mock:
        db_mock = MagicMock()
        mock.return_value = db_mock
        yield db_mock


@pytest.fixture
def sample_user_id():
    """Sample user ID."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_achievement_types():
    """Sample achievement type data."""
    return [
        {
            "id": "streak_7_days",
            "name": "7-Day Warrior",
            "description": "Complete 7 days in a row",
            "category": "streaks",
            "icon": "fire",
            "tier": "bronze",
            "points": 50,
            "threshold_value": 7,
            "threshold_unit": "days",
            "is_repeatable": False,
        },
        {
            "id": "pr_bench",
            "name": "Bench PR",
            "description": "Set a new bench press PR",
            "category": "strength",
            "icon": "dumbbell",
            "tier": "silver",
            "points": 100,
            "threshold_value": None,
            "threshold_unit": None,
            "is_repeatable": True,
        },
    ]


@pytest.fixture
def sample_exercise():
    """Sample exercise data."""
    return {
        "id": "ex_001",  # Must be string per Exercise model
        "external_id": "ex_001",
        "name": "Bench Press",
        "category": "strength",
        "subcategory": "chest",
        "difficulty_level": 2,
        "primary_muscle": "chest",
        "secondary_muscles": '["triceps", "shoulders"]',  # JSON string per model
        "equipment_required": '["barbell", "bench"]',  # JSON string per model
        "body_part": "upper body",
        "equipment": "barbell",
        "target": "pectorals",
        "default_sets": 4,
        "default_reps": 8,
        "default_duration_seconds": None,
        "default_rest_seconds": 90,
        "min_weight_kg": 20,
        "calories_per_minute": 8,
        "instructions": "Lie on bench. Lower bar to chest. Press up.",  # String per model
        "tips": '["Keep elbows at 45 degrees"]',  # JSON string per model
        "contraindicated_injuries": '["shoulder"]',  # JSON string per model
        "gif_url": "https://example.com/bench.gif",
        "video_url": None,
        "is_compound": True,
        "is_unilateral": False,
        "tags": '["push", "compound"]',  # JSON string per model
        "is_custom": False,
        "created_by_user_id": None,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def sample_hydration_log():
    """Sample hydration log data."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": str(uuid.uuid4()),
        "drink_type": "water",
        "amount_ml": 500,
        "workout_id": None,
        "notes": None,
        "logged_at": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================
# ACHIEVEMENT TYPES TESTS
# ============================================================

class TestAchievementTypes:
    """Test achievement type endpoints."""

    def test_get_all_achievement_types(self, mock_supabase_db, sample_achievement_types):
        """Test getting all achievement types."""
        mock_supabase_db.client.table.return_value.select.return_value.execute.return_value.data = sample_achievement_types

        response = client.get("/api/v1/achievements/types")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["id"] == "streak_7_days"

    def test_get_achievements_by_category(self, mock_supabase_db, sample_achievement_types):
        """Test getting achievements filtered by category."""
        streaks_only = [a for a in sample_achievement_types if a["category"] == "streaks"]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = streaks_only

        response = client.get("/api/v1/achievements/types/category/streaks")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["category"] == "streaks"

    def test_get_achievement_types_error(self, mock_supabase_db):
        """Test error handling for achievement types."""
        mock_supabase_db.client.table.return_value.select.return_value.execute.side_effect = Exception("DB Error")

        response = client.get("/api/v1/achievements/types")

        assert response.status_code == 500


# ============================================================
# USER ACHIEVEMENTS TESTS
# ============================================================

class TestUserAchievements:
    """Test user achievement endpoints."""

    def test_get_user_achievements(self, mock_supabase_db, sample_user_id, sample_achievement_types):
        """Test getting user achievements."""
        user_achievement = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "achievement_id": "streak_7_days",
            "earned_at": datetime.now(timezone.utc).isoformat(),
            "trigger_value": 7,
            "trigger_details": {"streak_type": "workout"},
            "is_notified": True,
            "achievement_types": sample_achievement_types[0],
        }

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [user_achievement]

        response = client.get(f"/api/v1/achievements/user/{sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["user_id"] == sample_user_id

    def test_get_achievements_summary(self, mock_supabase_db, sample_user_id, sample_achievement_types):
        """Test getting achievements summary."""
        user_achievement = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "achievement_id": "streak_7_days",
            "earned_at": datetime.now(timezone.utc).isoformat(),
            "trigger_value": 7,
            "achievement_types": sample_achievement_types[0],
        }

        streak = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "streak_type": "workout",
            "current_streak": 10,
            "longest_streak": 15,
            "last_activity_date": date.today().isoformat(),
            "streak_start_date": (date.today() - timedelta(days=10)).isoformat(),
        }

        pr = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "exercise_name": "Bench Press",
            "record_type": "weight",
            "record_value": 100,
            "record_unit": "kg",
            "previous_value": 95,
            "improvement_percentage": 5.26,
            "workout_id": None,
            "achieved_at": datetime.now(timezone.utc).isoformat(),
        }

        # Mock all queries
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [user_achievement]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [streak]
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = [pr]

        response = client.get(f"/api/v1/achievements/user/{sample_user_id}/summary")

        assert response.status_code == 200
        data = response.json()
        assert "total_points" in data
        assert "total_achievements" in data
        assert "current_streaks" in data
        assert "personal_records" in data

    def test_get_unnotified_achievements(self, mock_supabase_db, sample_user_id, sample_achievement_types):
        """Test getting unnotified achievements."""
        unnotified = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "achievement_id": "streak_7_days",
            "earned_at": datetime.now(timezone.utc).isoformat(),
            "trigger_value": 7,
            "is_notified": False,
            "achievement_types": sample_achievement_types[0],
        }

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [unnotified]

        response = client.get(f"/api/v1/achievements/user/{sample_user_id}/unnotified")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["is_first_time"] is True

    def test_mark_achievements_notified(self, mock_supabase_db, sample_user_id):
        """Test marking achievements as notified."""
        mock_supabase_db.client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.post(
            f"/api/v1/achievements/user/{sample_user_id}/mark-notified",
            json=["achievement_id_1", "achievement_id_2"]
        )

        assert response.status_code == 200
        assert response.json()["success"] is True


# ============================================================
# STREAKS TESTS
# ============================================================

class TestStreaks:
    """Test streak endpoints."""

    def test_get_user_streaks(self, mock_supabase_db, sample_user_id):
        """Test getting user streaks."""
        streak = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "streak_type": "workout",
            "current_streak": 14,
            "longest_streak": 21,
            "last_activity_date": date.today().isoformat(),
            "streak_start_date": (date.today() - timedelta(days=14)).isoformat(),
        }

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [streak]

        response = client.get(f"/api/v1/achievements/user/{sample_user_id}/streaks")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["current_streak"] == 14

    def test_update_streak_continue(self, mock_supabase_db, sample_user_id):
        """Test updating streak (continuing)."""
        yesterday = date.today() - timedelta(days=1)
        streak = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "streak_type": "workout",
            "current_streak": 5,
            "longest_streak": 10,
            "last_activity_date": yesterday.isoformat(),
        }

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [streak]
        mock_supabase_db.client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        # Mock achievement check
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.post(f"/api/v1/achievements/user/{sample_user_id}/streaks/workout/update")

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_update_streak_already_today(self, mock_supabase_db, sample_user_id):
        """Test updating streak when already updated today."""
        today = date.today()
        streak = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "streak_type": "workout",
            "current_streak": 5,
            "longest_streak": 10,
            "last_activity_date": today.isoformat(),
        }

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [streak]

        response = client.post(f"/api/v1/achievements/user/{sample_user_id}/streaks/workout/update")

        assert response.status_code == 200
        assert "Already updated today" in response.json()["message"]


# ============================================================
# PERSONAL RECORDS TESTS
# ============================================================

class TestPersonalRecords:
    """Test personal records endpoints."""

    def test_get_user_prs(self, mock_supabase_db, sample_user_id):
        """Test getting user PRs."""
        pr = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "exercise_name": "Squat",
            "record_type": "weight",
            "record_value": 150,
            "record_unit": "kg",
            "previous_value": 140,
            "improvement_percentage": 7.14,
            "workout_id": None,
            "achieved_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [pr]

        response = client.get(f"/api/v1/achievements/user/{sample_user_id}/prs")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["exercise_name"] == "Squat"

    def test_get_prs_by_exercise(self, mock_supabase_db, sample_user_id):
        """Test getting PRs filtered by exercise."""
        pr = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "exercise_name": "Bench Press",
            "record_type": "weight",
            "record_value": 100,
            "record_unit": "kg",
            "achieved_at": datetime.now(timezone.utc).isoformat(),
        }

        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value.data = [pr]

        response = client.get(f"/api/v1/achievements/user/{sample_user_id}/prs?exercise_name=Bench%20Press")

        assert response.status_code == 200

    def test_check_and_record_pr_new(self, mock_supabase_db, sample_user_id):
        """Test checking and recording a new PR."""
        # No existing PR
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        # Insert new PR
        new_pr = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "exercise_name": "Deadlift",
            "record_type": "weight",
            "record_value": 200,
            "record_unit": "kg",
            "achieved_at": datetime.now(timezone.utc).isoformat(),
        }
        mock_supabase_db.client.table.return_value.insert.return_value.execute.return_value.data = [new_pr]

        response = client.post(
            f"/api/v1/achievements/user/{sample_user_id}/prs/check",
            params={
                "exercise_name": "Deadlift",
                "record_type": "weight",
                "value": 200,
                "unit": "kg",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["is_new_pr"] is True

    def test_check_pr_not_beat(self, mock_supabase_db, sample_user_id):
        """Test checking PR when value doesn't beat current."""
        existing_pr = {
            "id": str(uuid.uuid4()),
            "user_id": sample_user_id,
            "exercise_name": "Squat",
            "record_type": "weight",
            "record_value": 150,
            "record_unit": "kg",
        }
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.execute.return_value.data = [existing_pr]

        response = client.post(
            f"/api/v1/achievements/user/{sample_user_id}/prs/check",
            params={
                "exercise_name": "Squat",
                "record_type": "weight",
                "value": 140,  # Lower than 150
                "unit": "kg",
            }
        )

        assert response.status_code == 200
        assert response.json()["is_new_pr"] is False


# ============================================================
# EXERCISE TESTS
# ============================================================

class TestExercises:
    """Test exercise endpoints."""

    def test_list_exercises(self, mock_exercises_db, sample_exercise):
        """Test listing exercises."""
        mock_exercises_db.list_exercises.return_value = [sample_exercise]

        response = client.get("/api/v1/exercises/")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "Bench Press"

    def test_list_exercises_with_filters(self, mock_exercises_db, sample_exercise):
        """Test listing exercises with filters."""
        mock_exercises_db.list_exercises.return_value = [sample_exercise]

        response = client.get("/api/v1/exercises/?category=strength&body_part=upper%20body")

        assert response.status_code == 200

    def test_get_exercise_by_id(self, mock_exercises_db, sample_exercise):
        """Test getting exercise by ID (integer)."""
        mock_exercises_db.get_exercise.return_value = sample_exercise

        response = client.get("/api/v1/exercises/1")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "ex_001"  # ID from fixture
        assert data["name"] == "Bench Press"

    def test_get_exercise_not_found(self, mock_exercises_db):
        """Test getting non-existent exercise."""
        mock_exercises_db.get_exercise.return_value = None

        response = client.get("/api/v1/exercises/999")

        assert response.status_code == 404

    def test_get_exercise_by_external_id(self, mock_exercises_db, sample_exercise):
        """Test getting exercise by external ID."""
        mock_exercises_db.get_exercise_by_external_id.return_value = sample_exercise

        response = client.get("/api/v1/exercises/external/ex_001")

        assert response.status_code == 200

    def test_create_exercise(self, mock_exercises_db, sample_exercise):
        """Test creating an exercise."""
        mock_exercises_db.create_exercise.return_value = sample_exercise

        response = client.post(
            "/api/v1/exercises/",
            json={
                "name": "Bench Press",
                "category": "strength",
                "primary_muscle": "chest",
                "default_sets": 4,
                "default_reps": 8,
            }
        )

        assert response.status_code == 200
        assert response.json()["name"] == "Bench Press"

    def test_delete_exercise(self, mock_exercises_db, sample_exercise):
        """Test deleting an exercise."""
        mock_exercises_db.get_exercise.return_value = sample_exercise
        mock_exercises_db.delete_exercise.return_value = None

        response = client.delete("/api/v1/exercises/1")

        assert response.status_code == 200
        assert "deleted" in response.json()["message"].lower()

    def test_delete_exercise_not_found(self, mock_exercises_db):
        """Test deleting non-existent exercise."""
        mock_exercises_db.get_exercise.return_value = None

        response = client.delete("/api/v1/exercises/999")

        assert response.status_code == 404


# ============================================================
# HYDRATION TESTS
# ============================================================

class TestHydration:
    """Test hydration endpoints."""

    def test_log_hydration(self, mock_hydration_db, sample_user_id, sample_hydration_log):
        """Test logging hydration intake."""
        sample_hydration_log["user_id"] = sample_user_id
        mock_hydration_db.table.return_value.insert.return_value.execute.return_value.data = [sample_hydration_log]

        response = client.post(
            "/api/v1/hydration/log",
            json={
                "user_id": sample_user_id,
                "drink_type": "water",
                "amount_ml": 500,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["amount_ml"] == 500
        assert data["drink_type"] == "water"

    def test_get_daily_hydration(self, mock_hydration_db, sample_user_id, sample_hydration_log):
        """Test getting daily hydration summary."""
        sample_hydration_log["user_id"] = sample_user_id
        mock_hydration_db.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.return_value.data = [
            sample_hydration_log,
            {**sample_hydration_log, "amount_ml": 300, "drink_type": "protein_shake"},
        ]

        # Mock goal query
        mock_hydration_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "hydration_goal_ml": 2500
        }

        response = client.get(f"/api/v1/hydration/daily/{sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert "total_ml" in data
        assert "goal_ml" in data
        assert "goal_percentage" in data

    def test_get_hydration_logs(self, mock_hydration_db, sample_user_id, sample_hydration_log):
        """Test getting hydration logs."""
        sample_hydration_log["user_id"] = sample_user_id
        mock_hydration_db.table.return_value.select.return_value.eq.return_value.gte.return_value.order.return_value.limit.return_value.execute.return_value.data = [sample_hydration_log]

        response = client.get(f"/api/v1/hydration/logs/{sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 0

    def test_delete_hydration_log(self, mock_hydration_db):
        """Test deleting hydration log."""
        log_id = str(uuid.uuid4())
        mock_hydration_db.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = [{"id": log_id}]

        response = client.delete(f"/api/v1/hydration/log/{log_id}")

        assert response.status_code == 200
        assert response.json()["status"] == "deleted"

    def test_delete_hydration_log_not_found(self, mock_hydration_db):
        """Test deleting non-existent hydration log."""
        log_id = str(uuid.uuid4())
        mock_hydration_db.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = []

        response = client.delete(f"/api/v1/hydration/log/{log_id}")

        assert response.status_code == 404

    def test_get_hydration_goal(self, mock_hydration_db, sample_user_id):
        """Test getting hydration goal."""
        mock_hydration_db.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "hydration_goal_ml": 3000
        }

        response = client.get(f"/api/v1/hydration/goal/{sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["daily_goal_ml"] == 3000

    def test_update_hydration_goal(self, mock_hydration_db, sample_user_id):
        """Test updating hydration goal."""
        mock_hydration_db.table.return_value.upsert.return_value.execute.return_value.data = [{}]

        response = client.put(
            f"/api/v1/hydration/goal/{sample_user_id}",
            json={"daily_goal_ml": 3500}
        )

        assert response.status_code == 200
        assert response.json()["daily_goal_ml"] == 3500

    def test_quick_log_hydration(self, mock_hydration_db, sample_user_id, sample_hydration_log):
        """Test quick log hydration."""
        sample_hydration_log["user_id"] = sample_user_id
        mock_hydration_db.table.return_value.insert.return_value.execute.return_value.data = [sample_hydration_log]

        response = client.post(
            f"/api/v1/hydration/quick-log/{sample_user_id}",
            params={"drink_type": "water", "amount_ml": 250}
        )

        assert response.status_code == 200


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_achievements_db_error(self, mock_supabase_db, sample_user_id):
        """Test database error handling in achievements."""
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.side_effect = Exception("DB Error")

        response = client.get(f"/api/v1/achievements/user/{sample_user_id}")

        assert response.status_code == 500

    def test_exercises_db_error(self, mock_exercises_db):
        """Test database error handling in exercises."""
        mock_exercises_db.list_exercises.side_effect = Exception("DB Error")

        response = client.get("/api/v1/exercises/")

        assert response.status_code == 500

    def test_hydration_db_error(self, mock_hydration_db, sample_user_id):
        """Test database error handling in hydration."""
        mock_hydration_db.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.execute.side_effect = Exception("DB Error")

        response = client.get(f"/api/v1/hydration/daily/{sample_user_id}")

        assert response.status_code == 500


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
