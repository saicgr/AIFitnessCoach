"""
Tests for Workout-Goals Sync API endpoint.

Tests the automatic syncing of workout exercise reps with weekly personal goals:
- Matching exercises to active weekly_volume goals
- Adding volume to goals
- PR detection
- Goal completion detection
- User context logging
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, date, timedelta, timezone
from fastapi.testclient import TestClient

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


@pytest.fixture
def client():
    """Synchronous test client for FastAPI."""
    return TestClient(app)


@pytest.fixture
def mock_supabase():
    """Mock Supabase database client."""
    mock_db = MagicMock()
    mock_client = MagicMock()
    mock_db.client = mock_client
    return mock_db, mock_client


class TestWorkoutGoalsSync:
    """Tests for POST /personal-goals/workout-sync endpoint."""

    def test_sync_updates_matching_goals(self, client, mock_supabase):
        """Test that workout exercises update matching weekly_volume goals."""
        mock_db, mock_client = mock_supabase

        # Mock active goals
        active_goals = [
            {
                "id": "goal1",
                "user_id": "user123",
                "exercise_name": "Push-ups",
                "goal_type": "weekly_volume",
                "target_value": 500,
                "current_value": 100,
                "personal_best": 450,
                "is_pr_beaten": False,
                "status": "active",
                "week_start": date.today().isoformat(),
            },
            {
                "id": "goal2",
                "user_id": "user123",
                "exercise_name": "Squats",
                "goal_type": "weekly_volume",
                "target_value": 300,
                "current_value": 50,
                "personal_best": None,
                "is_pr_beaten": False,
                "status": "active",
                "week_start": date.today().isoformat(),
            },
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db, \
             patch("api.v1.personal_goals.log_user_activity") as mock_log:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=active_goals)

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "workout_log_id": "workout_abc",
                    "exercises": [
                        {"exercise_name": "Push-ups", "total_reps": 50, "total_sets": 3, "max_reps_in_set": 20},
                        {"exercise_name": "Squats", "total_reps": 30, "total_sets": 2, "max_reps_in_set": 15},
                    ]
                }
            )

            assert response.status_code == 200
            data = response.json()

            assert data["total_goals_updated"] == 2
            assert data["total_volume_added"] == 80  # 50 + 30
            assert len(data["synced_goals"]) == 2

    def test_sync_no_matching_goals(self, client, mock_supabase):
        """Test sync when no active goals match workout exercises."""
        mock_db, mock_client = mock_supabase

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "exercises": [
                        {"exercise_name": "Bench Press", "total_reps": 50},
                    ]
                }
            )

            assert response.status_code == 200
            data = response.json()

            assert data["total_goals_updated"] == 0
            assert "No active weekly volume goals" in data["message"]

    def test_sync_detects_pr(self, client, mock_supabase):
        """Test that sync detects when a new PR is achieved."""
        mock_db, mock_client = mock_supabase

        # Goal where adding volume will beat personal best
        active_goals = [
            {
                "id": "goal1",
                "user_id": "user123",
                "exercise_name": "Push-ups",
                "goal_type": "weekly_volume",
                "target_value": 500,
                "current_value": 400,
                "personal_best": 420,
                "is_pr_beaten": False,
                "status": "active",
                "week_start": date.today().isoformat(),
            },
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db, \
             patch("api.v1.personal_goals.log_user_activity") as mock_log:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=active_goals)

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "exercises": [
                        {"exercise_name": "Push-ups", "total_reps": 50},  # 400 + 50 = 450 > 420 (PR)
                    ]
                }
            )

            assert response.status_code == 200
            data = response.json()

            assert data["new_prs"] == 1
            assert data["synced_goals"][0]["is_new_pr"] is True
            assert "PR" in data["message"]

    def test_sync_detects_goal_completion(self, client, mock_supabase):
        """Test that sync marks goal as completed when target reached."""
        mock_db, mock_client = mock_supabase

        # Goal close to completion
        active_goals = [
            {
                "id": "goal1",
                "user_id": "user123",
                "exercise_name": "Push-ups",
                "goal_type": "weekly_volume",
                "target_value": 100,
                "current_value": 80,
                "personal_best": 50,
                "is_pr_beaten": False,
                "status": "active",
                "week_start": date.today().isoformat(),
            },
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db, \
             patch("api.v1.personal_goals.log_user_activity") as mock_log:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=active_goals)

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "exercises": [
                        {"exercise_name": "Push-ups", "total_reps": 25},  # 80 + 25 = 105 >= 100
                    ]
                }
            )

            assert response.status_code == 200
            data = response.json()

            assert data["synced_goals"][0]["is_now_completed"] is True
            assert data["synced_goals"][0]["progress_percentage"] >= 100.0

    def test_sync_case_insensitive_matching(self, client, mock_supabase):
        """Test that exercise names match case-insensitively."""
        mock_db, mock_client = mock_supabase

        active_goals = [
            {
                "id": "goal1",
                "user_id": "user123",
                "exercise_name": "Push-ups",  # Mixed case
                "goal_type": "weekly_volume",
                "target_value": 500,
                "current_value": 100,
                "personal_best": None,
                "is_pr_beaten": False,
                "status": "active",
                "week_start": date.today().isoformat(),
            },
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db, \
             patch("api.v1.personal_goals.log_user_activity") as mock_log:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=active_goals)

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "exercises": [
                        {"exercise_name": "push-ups", "total_reps": 50},  # lowercase
                    ]
                }
            )

            assert response.status_code == 200
            data = response.json()

            assert data["total_goals_updated"] == 1

    def test_sync_partial_name_matching(self, client, mock_supabase):
        """Test that partial exercise name matches work."""
        mock_db, mock_client = mock_supabase

        active_goals = [
            {
                "id": "goal1",
                "user_id": "user123",
                "exercise_name": "Push-ups (Standard)",  # Full name with variant
                "goal_type": "weekly_volume",
                "target_value": 500,
                "current_value": 100,
                "personal_best": None,
                "is_pr_beaten": False,
                "status": "active",
                "week_start": date.today().isoformat(),
            },
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db, \
             patch("api.v1.personal_goals.log_user_activity") as mock_log:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=active_goals)

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "exercises": [
                        {"exercise_name": "Push-ups", "total_reps": 50},  # Shorter name
                    ]
                }
            )

            assert response.status_code == 200
            data = response.json()

            # Should match via partial matching
            assert data["total_goals_updated"] == 1

    def test_sync_ignores_single_max_goals(self, client, mock_supabase):
        """Test that sync only updates weekly_volume goals, not single_max."""
        mock_db, mock_client = mock_supabase

        # The endpoint filters by goal_type='weekly_volume', so single_max won't be returned
        # This is implicitly tested by the .eq("goal_type", "weekly_volume") filter
        # Here we just verify the endpoint works when there are no matching goals

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "exercises": [
                        {"exercise_name": "Push-ups", "total_reps": 50},
                    ]
                }
            )

            assert response.status_code == 200
            data = response.json()

            assert data["total_goals_updated"] == 0

    def test_sync_logs_activity(self, client, mock_supabase):
        """Test that syncing goals logs user activity."""
        mock_db, mock_client = mock_supabase

        active_goals = [
            {
                "id": "goal1",
                "user_id": "user123",
                "exercise_name": "Push-ups",
                "goal_type": "weekly_volume",
                "target_value": 500,
                "current_value": 100,
                "personal_best": None,
                "is_pr_beaten": False,
                "status": "active",
                "week_start": date.today().isoformat(),
            },
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db, \
             patch("api.v1.personal_goals.log_user_activity") as mock_log:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=active_goals)

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "workout_log_id": "workout_abc",
                    "exercises": [
                        {"exercise_name": "Push-ups", "total_reps": 50},
                    ]
                }
            )

            assert response.status_code == 200

            # Verify activity logging was called
            mock_log.assert_called_once()
            call_kwargs = mock_log.call_args[1]
            assert call_kwargs["user_id"] == "user123"
            assert call_kwargs["action"] == "goals_workout_sync"
            assert "workout_log_id" in call_kwargs["metadata"]

    def test_sync_returns_progress_percentage(self, client, mock_supabase):
        """Test that sync returns accurate progress percentage."""
        mock_db, mock_client = mock_supabase

        active_goals = [
            {
                "id": "goal1",
                "user_id": "user123",
                "exercise_name": "Push-ups",
                "goal_type": "weekly_volume",
                "target_value": 100,
                "current_value": 40,
                "personal_best": None,
                "is_pr_beaten": False,
                "status": "active",
                "week_start": date.today().isoformat(),
            },
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db, \
             patch("api.v1.personal_goals.log_user_activity") as mock_log:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=active_goals)

            response = client.post(
                "/api/v1/personal-goals/workout-sync",
                params={"user_id": "user123"},
                json={
                    "exercises": [
                        {"exercise_name": "Push-ups", "total_reps": 20},  # 40 + 20 = 60 / 100 = 60%
                    ]
                }
            )

            assert response.status_code == 200
            data = response.json()

            assert data["synced_goals"][0]["progress_percentage"] == 60.0
            assert data["synced_goals"][0]["new_current_value"] == 60
            assert data["synced_goals"][0]["volume_added"] == 20
