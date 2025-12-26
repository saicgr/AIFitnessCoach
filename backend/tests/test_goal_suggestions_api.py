"""
Tests for Goal Suggestions API endpoints.

Tests the AI-generated goal suggestions including:
- Getting suggestions by category
- Dismissing suggestions
- Accepting suggestions to create goals
- Caching behavior
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
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


class TestGetGoalSuggestions:
    """Tests for GET /goals/suggestions endpoint."""

    def test_get_suggestions_returns_categories(self, client, mock_supabase):
        """Test that suggestions are returned organized by category."""
        mock_db, mock_client = mock_supabase

        # Mock cached suggestions
        cached_data = [
            {
                "id": "sug1",
                "user_id": "user123",
                "suggestion_type": "performance_based",
                "exercise_name": "Push-ups",
                "goal_type": "single_max",
                "suggested_target": 35,
                "reasoning": "Beat your PR of 32!",
                "confidence_score": 0.85,
                "source_data": {"personal_best": 32},
                "category": "beat_your_records",
                "priority_rank": 0,
                "is_dismissed": False,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "expires_at": (datetime.now(timezone.utc) + timedelta(hours=12)).isoformat(),
            },
            {
                "id": "sug2",
                "user_id": "user123",
                "suggestion_type": "popular_with_friends",
                "exercise_name": "Squats",
                "goal_type": "weekly_volume",
                "suggested_target": 100,
                "reasoning": "3 friends doing this!",
                "confidence_score": 0.75,
                "source_data": {"friend_count": 3},
                "category": "popular_with_friends",
                "priority_rank": 0,
                "is_dismissed": False,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "expires_at": (datetime.now(timezone.utc) + timedelta(hours=12)).isoformat(),
            },
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            # Setup chained mock calls
            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gt.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=cached_data)

            response = client.get(
                "/v1/personal-goals/goals/suggestions",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()

            assert "categories" in data
            assert "total_suggestions" in data
            assert "generated_at" in data
            assert "expires_at" in data

    def test_get_suggestions_empty_for_new_user(self, client, mock_supabase):
        """Test suggestions for new user with no history."""
        mock_db, mock_client = mock_supabase

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gt.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.limit.return_value = mock_table
            mock_table.or_.return_value = mock_table
            mock_table.in_.return_value = mock_table
            mock_table.delete.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(
                "/v1/personal-goals/goals/suggestions",
                params={"user_id": "newuser123"}
            )

            # Should still succeed with default suggestions
            assert response.status_code == 200

    def test_force_refresh_regenerates_suggestions(self, client, mock_supabase):
        """Test that force_refresh bypasses cache."""
        mock_db, mock_client = mock_supabase

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gt.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.limit.return_value = mock_table
            mock_table.or_.return_value = mock_table
            mock_table.in_.return_value = mock_table
            mock_table.delete.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(
                "/v1/personal-goals/goals/suggestions",
                params={"user_id": "user123", "force_refresh": True}
            )

            assert response.status_code == 200
            # Verify delete was called to clear old suggestions
            assert mock_table.delete.called


class TestDismissSuggestion:
    """Tests for POST /goals/suggestions/{id}/dismiss endpoint."""

    def test_dismiss_suggestion_success(self, client, mock_supabase):
        """Test dismissing a suggestion."""
        mock_db, mock_client = mock_supabase

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[{"id": "sug1"}])

            response = client.post(
                "/v1/personal-goals/goals/suggestions/sug1/dismiss",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "dismissed"
            assert data["suggestion_id"] == "sug1"

    def test_dismiss_suggestion_not_found(self, client, mock_supabase):
        """Test dismissing non-existent suggestion."""
        mock_db, mock_client = mock_supabase

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.post(
                "/v1/personal-goals/goals/suggestions/nonexistent/dismiss",
                params={"user_id": "user123"}
            )

            assert response.status_code == 404


class TestAcceptSuggestion:
    """Tests for POST /goals/suggestions/{id}/accept endpoint."""

    def test_accept_suggestion_creates_goal(self, client, mock_supabase):
        """Test accepting a suggestion creates a new goal."""
        mock_db, mock_client = mock_supabase

        suggestion_data = {
            "id": "sug1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "suggested_target": 35,
        }

        created_goal = {
            "id": "goal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 35,
            "current_value": 0,
            "status": "active",
            "is_pr_beaten": False,
            "week_start": date.today().isoformat(),
            "week_end": (date.today() + timedelta(days=6)).isoformat(),
            "personal_best": None,
            "source_suggestion_id": "sug1",
            "visibility": "friends",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.update.return_value = mock_table

            # First call - get suggestion
            # Second call - check existing goal
            # Third call - get personal best
            # Fourth call - insert goal
            # Fifth call - update suggestion as dismissed
            mock_table.execute.side_effect = [
                MagicMock(data=[suggestion_data]),
                MagicMock(data=[]),  # No existing goal
                MagicMock(data=[]),  # No personal best
                MagicMock(data=[created_goal]),  # Created goal
                MagicMock(data=[{"id": "sug1", "is_dismissed": True}]),  # Updated suggestion
            ]

            response = client.post(
                "/v1/personal-goals/goals/suggestions/sug1/accept",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["exercise_name"] == "Push-ups"
            assert data["target_value"] == 35

    def test_accept_suggestion_with_override(self, client, mock_supabase):
        """Test accepting suggestion with custom target."""
        mock_db, mock_client = mock_supabase

        suggestion_data = {
            "id": "sug1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "suggested_target": 35,
        }

        created_goal = {
            "id": "goal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,  # Overridden
            "current_value": 0,
            "status": "active",
            "is_pr_beaten": False,
            "week_start": date.today().isoformat(),
            "week_end": (date.today() + timedelta(days=6)).isoformat(),
            "personal_best": None,
            "source_suggestion_id": "sug1",
            "visibility": "friends",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.update.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[suggestion_data]),
                MagicMock(data=[]),
                MagicMock(data=[]),
                MagicMock(data=[created_goal]),
                MagicMock(data=[{"id": "sug1", "is_dismissed": True}]),
            ]

            response = client.post(
                "/v1/personal-goals/goals/suggestions/sug1/accept",
                params={"user_id": "user123"},
                json={"target_override": 50, "visibility": "public"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["target_value"] == 50

    def test_accept_suggestion_duplicate_goal(self, client, mock_supabase):
        """Test accepting suggestion when goal already exists this week."""
        mock_db, mock_client = mock_supabase

        suggestion_data = {
            "id": "sug1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "suggested_target": 35,
        }

        existing_goal = {
            "id": "existing_goal",
        }

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[suggestion_data]),
                MagicMock(data=[existing_goal]),  # Existing goal found
            ]

            response = client.post(
                "/v1/personal-goals/goals/suggestions/sug1/accept",
                params={"user_id": "user123"}
            )

            assert response.status_code == 400
            assert "already exists" in response.json()["detail"]


class TestSuggestionsSummary:
    """Tests for GET /goals/suggestions/summary endpoint."""

    def test_get_summary_with_suggestions(self, client, mock_supabase):
        """Test getting summary with active suggestions."""
        mock_db, mock_client = mock_supabase

        suggestions = [
            {"category": "beat_your_records", "expires_at": (datetime.now(timezone.utc) + timedelta(hours=12)).isoformat()},
            {"category": "beat_your_records", "expires_at": (datetime.now(timezone.utc) + timedelta(hours=12)).isoformat()},
            {"category": "popular_with_friends", "expires_at": (datetime.now(timezone.utc) + timedelta(hours=12)).isoformat()},
        ]

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gt.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=suggestions)

            response = client.get(
                "/v1/personal-goals/goals/suggestions/summary",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["total_suggestions"] == 3
            assert data["categories_with_suggestions"] == 2
            assert data["has_friend_suggestions"] is True

    def test_get_summary_no_suggestions(self, client, mock_supabase):
        """Test getting summary with no suggestions."""
        mock_db, mock_client = mock_supabase

        with patch("api.v1.personal_goals.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gt.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(
                "/v1/personal-goals/goals/suggestions/summary",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["total_suggestions"] == 0
            assert data["categories_with_suggestions"] == 0
            assert data["has_friend_suggestions"] is False
