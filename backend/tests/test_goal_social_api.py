"""
Tests for Goal Social API endpoints.

Tests the social features for weekly goals including:
- Getting friends on a goal (leaderboard)
- Joining a friend's goal
- Inviting friends to goals
- Responding to goal invites
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


class TestGetGoalFriends:
    """Tests for GET /goals/{id}/friends endpoint."""

    def test_get_goal_friends_with_data(self, client, mock_supabase):
        """Test getting friends on a goal with friend data."""
        mock_db, mock_client = mock_supabase

        goal_data = {
            "id": "goal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "current_value": 35,
            "week_start": date.today().isoformat(),
            "visibility": "friends",
        }

        friend_goals = [
            {
                "id": "fgoal1",
                "user_id": "friend1",
                "current_value": 45,
                "target_value": 50,
                "is_pr_beaten": True,
                "users": {"id": "friend1", "display_name": "Alice", "photo_url": "http://avatar1.jpg"},
            },
            {
                "id": "fgoal2",
                "user_id": "friend2",
                "current_value": 30,
                "target_value": 50,
                "is_pr_beaten": False,
                "users": {"id": "friend2", "display_name": "Bob", "photo_url": "http://avatar2.jpg"},
            },
        ]

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.neq.return_value = mock_table
            mock_table.or_.return_value = mock_table
            mock_table.in_.return_value = mock_table
            mock_table.order.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[goal_data]),  # Goal lookup
                MagicMock(data=[{"follower_id": "user123", "following_id": "friend1"}, {"follower_id": "friend2", "following_id": "user123"}]),  # Friends
                MagicMock(data=friend_goals),  # Friend goals
            ]

            response = client.get(
                "/v1/goal-social/goals/goal1/friends",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["exercise_name"] == "Push-ups"
            assert data["goal_type"] == "single_max"
            assert data["total_friends_count"] == 2
            assert len(data["friend_entries"]) == 2
            # Should be sorted by progress (Alice 90%, Bob 60%)
            assert data["friend_entries"][0]["name"] == "Alice"

    def test_get_goal_friends_no_friends(self, client, mock_supabase):
        """Test getting friends on a goal when user has no friends."""
        mock_db, mock_client = mock_supabase

        goal_data = {
            "id": "goal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "current_value": 35,
            "week_start": date.today().isoformat(),
            "visibility": "friends",
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.neq.return_value = mock_table
            mock_table.or_.return_value = mock_table
            mock_table.in_.return_value = mock_table
            mock_table.order.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[goal_data]),
                MagicMock(data=[]),  # No friends
            ]

            response = client.get(
                "/v1/goal-social/goals/goal1/friends",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["total_friends_count"] == 0
            assert len(data["friend_entries"]) == 0

    def test_get_goal_friends_not_found(self, client, mock_supabase):
        """Test getting friends on non-existent goal."""
        mock_db, mock_client = mock_supabase

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(
                "/v1/goal-social/goals/nonexistent/friends",
                params={"user_id": "user123"}
            )

            assert response.status_code == 404


class TestJoinGoal:
    """Tests for POST /goals/{id}/join endpoint."""

    def test_join_goal_success(self, client, mock_supabase):
        """Test successfully joining a friend's goal."""
        mock_db, mock_client = mock_supabase

        original_goal = {
            "id": "goal1",
            "user_id": "friend1",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "week_start": date.today().isoformat(),
            "week_end": (date.today() + timedelta(days=6)).isoformat(),
            "visibility": "friends",
        }

        new_goal = {
            "id": "newgoal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "current_value": 0,
            "status": "active",
            "is_pr_beaten": False,
            "week_start": date.today().isoformat(),
            "week_end": (date.today() + timedelta(days=6)).isoformat(),
            "personal_best": None,
            "is_shared": True,
            "visibility": "friends",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.or_.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.update.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[original_goal]),  # Get original goal
                MagicMock(data=[{"follower_id": "user123"}]),  # Check friendship
                MagicMock(data=[]),  # No existing goal this week
                MagicMock(data=[]),  # No personal best
                MagicMock(data=[new_goal]),  # Insert new goal
                MagicMock(data=[{"id": "shared1"}]),  # Insert shared goal record
            ]

            response = client.post(
                "/v1/goal-social/goals/goal1/join",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["exercise_name"] == "Push-ups"
            assert data["is_shared"] is True

    def test_join_own_goal_fails(self, client, mock_supabase):
        """Test that joining your own goal fails."""
        mock_db, mock_client = mock_supabase

        own_goal = {
            "id": "goal1",
            "user_id": "user123",  # Same as requesting user
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "visibility": "friends",
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[own_goal])

            response = client.post(
                "/v1/goal-social/goals/goal1/join",
                params={"user_id": "user123"}
            )

            assert response.status_code == 400
            assert "own goal" in response.json()["detail"].lower()

    def test_join_private_goal_fails(self, client, mock_supabase):
        """Test that joining a private goal fails."""
        mock_db, mock_client = mock_supabase

        private_goal = {
            "id": "goal1",
            "user_id": "friend1",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "visibility": "private",
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[private_goal])

            response = client.post(
                "/v1/goal-social/goals/goal1/join",
                params={"user_id": "user123"}
            )

            assert response.status_code == 403
            assert "private" in response.json()["detail"].lower()


class TestInviteToGoal:
    """Tests for POST /goals/{id}/invite endpoint."""

    def test_invite_friend_success(self, client, mock_supabase):
        """Test successfully inviting a friend to a goal."""
        mock_db, mock_client = mock_supabase

        goal_data = {
            "id": "goal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "visibility": "friends",
        }

        invite_data = {
            "id": "invite1",
            "goal_id": "goal1",
            "inviter_id": "user123",
            "invitee_id": "friend1",
            "status": "pending",
            "message": "Join me!",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.or_.return_value = mock_table
            mock_table.insert.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[goal_data]),  # Get goal
                MagicMock(data=[{"follower_id": "user123"}]),  # Check friendship
                MagicMock(data=[]),  # No existing invite
                MagicMock(data=[invite_data]),  # Insert invite
            ]

            response = client.post(
                "/v1/goal-social/goals/goal1/invite",
                params={"user_id": "user123"},
                json={"goal_id": "goal1", "invitee_id": "friend1", "message": "Join me!"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["invitee_id"] == "friend1"
            assert data["status"] == "pending"

    def test_invite_non_friend_fails(self, client, mock_supabase):
        """Test that inviting a non-friend fails."""
        mock_db, mock_client = mock_supabase

        goal_data = {
            "id": "goal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "visibility": "friends",
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.or_.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[goal_data]),
                MagicMock(data=[]),  # Not friends
            ]

            response = client.post(
                "/v1/goal-social/goals/goal1/invite",
                params={"user_id": "user123"},
                json={"goal_id": "goal1", "invitee_id": "stranger1"}
            )

            assert response.status_code == 403
            assert "not friends" in response.json()["detail"].lower()

    def test_invite_duplicate_fails(self, client, mock_supabase):
        """Test that duplicate invite fails."""
        mock_db, mock_client = mock_supabase

        goal_data = {
            "id": "goal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "visibility": "friends",
        }

        existing_invite = {
            "id": "invite0",
            "status": "pending",
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.or_.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[goal_data]),
                MagicMock(data=[{"follower_id": "user123"}]),
                MagicMock(data=[existing_invite]),  # Existing invite
            ]

            response = client.post(
                "/v1/goal-social/goals/goal1/invite",
                params={"user_id": "user123"},
                json={"goal_id": "goal1", "invitee_id": "friend1"}
            )

            assert response.status_code == 400
            assert "already" in response.json()["detail"].lower()


class TestGetGoalInvites:
    """Tests for GET /goals/invites endpoint."""

    def test_get_pending_invites(self, client, mock_supabase):
        """Test getting pending invites for user."""
        mock_db, mock_client = mock_supabase

        invites = [
            {
                "id": "invite1",
                "goal_id": "goal1",
                "inviter_id": "friend1",
                "invitee_id": "user123",
                "status": "pending",
                "message": "Join me!",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
                "responded_at": None,
                "weekly_personal_goals": {
                    "exercise_name": "Push-ups",
                    "goal_type": "single_max",
                    "target_value": 50,
                },
                "users": {
                    "id": "friend1",
                    "display_name": "Alice",
                    "photo_url": "http://avatar.jpg",
                },
            },
        ]

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=invites)

            response = client.get(
                "/v1/goal-social/goals/invites",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1
            assert data[0]["goal_exercise_name"] == "Push-ups"
            assert data[0]["inviter_name"] == "Alice"


class TestRespondToInvite:
    """Tests for POST /goals/invites/{id}/respond endpoint."""

    def test_accept_invite_creates_goal(self, client, mock_supabase):
        """Test accepting an invite creates a new goal."""
        mock_db, mock_client = mock_supabase

        invite_data = {
            "id": "invite1",
            "goal_id": "goal1",
            "inviter_id": "friend1",
            "invitee_id": "user123",
            "status": "pending",
        }

        original_goal = {
            "id": "goal1",
            "user_id": "friend1",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "week_start": date.today().isoformat(),
            "week_end": (date.today() + timedelta(days=6)).isoformat(),
        }

        new_goal = {
            "id": "newgoal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "current_value": 0,
            "status": "active",
            "is_pr_beaten": False,
            "week_start": date.today().isoformat(),
            "week_end": (date.today() + timedelta(days=6)).isoformat(),
            "is_shared": True,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        updated_invite = {
            **invite_data,
            "status": "accepted",
            "responded_at": datetime.now(timezone.utc).isoformat(),
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.update.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[invite_data]),  # Get invite
                MagicMock(data=[original_goal]),  # Get original goal
                MagicMock(data=[]),  # No existing goal
                MagicMock(data=[]),  # No personal best
                MagicMock(data=[new_goal]),  # Insert new goal
                MagicMock(data=[{"id": "shared1"}]),  # Insert shared record
                MagicMock(data=[updated_invite]),  # Update invite
            ]

            response = client.post(
                "/v1/goal-social/goals/invites/invite1/respond",
                params={"user_id": "user123"},
                json={"accept": True}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["invite"]["status"] == "accepted"
            assert data["created_goal_id"] is not None

    def test_decline_invite(self, client, mock_supabase):
        """Test declining an invite."""
        mock_db, mock_client = mock_supabase

        invite_data = {
            "id": "invite1",
            "goal_id": "goal1",
            "inviter_id": "friend1",
            "invitee_id": "user123",
            "status": "pending",
        }

        declined_invite = {
            **invite_data,
            "status": "declined",
            "responded_at": datetime.now(timezone.utc).isoformat(),
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.update.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[invite_data]),
                MagicMock(data=[declined_invite]),
            ]

            response = client.post(
                "/v1/goal-social/goals/invites/invite1/respond",
                params={"user_id": "user123"},
                json={"accept": False}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["invite"]["status"] == "declined"
            assert data["created_goal_id"] is None

    def test_respond_to_non_pending_invite_fails(self, client, mock_supabase):
        """Test that responding to already-responded invite fails."""
        mock_db, mock_client = mock_supabase

        invite_data = {
            "id": "invite1",
            "goal_id": "goal1",
            "inviter_id": "friend1",
            "invitee_id": "user123",
            "status": "accepted",  # Already accepted
        }

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[invite_data])

            response = client.post(
                "/v1/goal-social/goals/invites/invite1/respond",
                params={"user_id": "user123"},
                json={"accept": True}
            )

            assert response.status_code == 400
            assert "already" in response.json()["detail"].lower()


class TestPendingInvitesCount:
    """Tests for GET /goals/invites/pending-count endpoint."""

    def test_get_pending_count(self, client, mock_supabase):
        """Test getting count of pending invites."""
        mock_db, mock_client = mock_supabase

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gt.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[
                {"id": "invite1"},
                {"id": "invite2"},
                {"id": "invite3"},
            ], count=3)

            response = client.get(
                "/v1/goal-social/goals/invites/pending-count",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["pending_count"] == 3
