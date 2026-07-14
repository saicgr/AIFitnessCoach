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
from core.auth import get_current_user


# Every /goal-social endpoint is gated by `Depends(get_current_user)` and then
# asserts `current_user["id"] == user_id` (403 otherwise). The tests all act as
# "user123", so the auth dependency is overridden to return that user. Without
# the override every request dies at the JWT check with 401 before any endpoint
# logic runs, so the tests below would assert nothing about goal-social at all.
TEST_USER_ID = "user123"


@pytest.fixture(autouse=True)
def override_auth():
    """Authenticate every request in this module as TEST_USER_ID."""
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "email": "user123@example.com",
    }
    yield
    app.dependency_overrides.pop(get_current_user, None)


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

        # `select("*")` returns the whole weekly_personal_goals row — including
        # is_pr_beaten, which the leaderboard builder reads for the user's own
        # entry. The mock row must carry it or the endpoint 500s on a KeyError
        # that production data can never produce.
        goal_data = {
            "id": "goal1",
            "user_id": "user123",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "current_value": 35,
            "is_pr_beaten": False,
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
                "/api/v1/goal-social/goals/goal1/friends",
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
            "is_pr_beaten": False,
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
                "/api/v1/goal-social/goals/goal1/friends",
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
                "/api/v1/goal-social/goals/nonexistent/friends",
                params={"user_id": "user123"}
            )

            assert response.status_code == 404


class TestJoinGoal:
    """Tests for POST /goals/{id}/join endpoint."""

    def test_join_goal_success(self, client, mock_supabase):
        """Test successfully joining a friend's goal.

        Guarantee protected: joining copies the friend's goal onto the caller as
        a SHARED goal (same exercise/type/target, own progress reset) and links
        the two with a shared_goals row.

        The `is_shared` half of that used to be asserted off the response body
        (`data["is_shared"] is True`). The `WeeklyPersonalGoal` response model
        has never carried an `is_shared` (or `visibility`) field — `git log -S
        is_shared -- models/weekly_personal_goals.py` is empty — so pydantic
        silently drops it and the key simply is not in the JSON; nothing in the
        Flutter app reads it either. The flag is real, but it lives on the DB
        row, so the assertion now checks it where it is actually written: the
        weekly_personal_goals insert payload, plus the shared_goals link row.
        """
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
            # WeeklyPersonalGoal requires updated_at; the real inserted row
            # always has it (NOT NULL, defaulted by the DB).
            "updated_at": datetime.now(timezone.utc).isoformat(),
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

            # The DB call script must match what join_goal actually issues, in
            # order. It does NOT query user_connections (its gate is the goal's
            # visibility, not friendship) — the stray friendship row that used
            # to sit in slot 2 was being consumed by the "already have this goal
            # this week" check, so the endpoint short-circuited with 400 and the
            # success-path assertions below never ran.
            mock_table.execute.side_effect = [
                MagicMock(data=[original_goal]),  # 1. Get original goal
                MagicMock(data=[]),  # 2. No existing goal this week
                MagicMock(data=[]),  # 3. No personal best
                MagicMock(data=[new_goal]),  # 4. Insert new goal
                MagicMock(data=[{"id": "shared1"}]),  # 5. Insert shared_goals record
                MagicMock(data=[{"id": "goal1"}]),  # 6. Mark original goal shared
            ]

            response = client.post(
                "/api/v1/goal-social/goals/goal1/join",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["id"] == "newgoal1"
            assert data["user_id"] == "user123"
            assert data["exercise_name"] == "Push-ups"
            assert data["target_value"] == 50
            assert data["current_value"] == 0

            insert_payloads = [c.args[0] for c in mock_table.insert.call_args_list]
            assert len(insert_payloads) == 2

            # 1. The caller's copy of the goal, marked shared.
            created_goal = insert_payloads[0]
            assert created_goal["is_shared"] is True
            assert created_goal["user_id"] == "user123"
            assert created_goal["exercise_name"] == "Push-ups"
            assert created_goal["goal_type"] == "single_max"
            assert created_goal["target_value"] == 50
            assert created_goal["current_value"] == 0
            assert created_goal["visibility"] == "friends"

            # 2. The shared_goals row linking the copy back to the original.
            shared_link = insert_payloads[1]
            assert shared_link["original_goal_id"] == "goal1"
            assert shared_link["source_user_id"] == "friend1"
            assert shared_link["joined_user_id"] == "user123"
            assert shared_link["joined_goal_id"] == "newgoal1"

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
                "/api/v1/goal-social/goals/goal1/join",
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
                "/api/v1/goal-social/goals/goal1/join",
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
                "/api/v1/goal-social/goals/goal1/invite",
                params={"user_id": "user123"},
                json={"goal_id": "goal1", "invitee_id": "friend1", "message": "Join me!"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["invitee_id"] == "friend1"
            assert data["status"] == "pending"

    def test_invite_non_friend_fails(self, client, mock_supabase):
        """Test that inviting a non-friend fails.

        Guarantee protected: an invite to someone the user is not connected to
        is rejected 403 and never reaches the goal_invites insert.

        The detail assertion used to look for the substring "not friends".
        The endpoint has said "Can only invite friends" since the file was first
        committed (f3005344) — that substring never matched, it was spec drift
        in the test, not a behavior change. Pinned to the exact message so any
        future rewording is caught deliberately.
        """
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
                "/api/v1/goal-social/goals/goal1/invite",
                params={"user_id": "user123"},
                json={"goal_id": "goal1", "invitee_id": "stranger1"}
            )

            assert response.status_code == 403
            assert response.json()["detail"] == "Can only invite friends"

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
                "/api/v1/goal-social/goals/goal1/invite",
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
                "/api/v1/goal-social/goals/invites",
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
        """Test accepting an invite creates a new goal.

        The invite row must carry created_at/expires_at (both NOT NULL columns,
        and expires_at gates the "invite has expired" branch) and the embedded
        `weekly_personal_goals!inner(*)` join the endpoint selects — it reads the
        source goal off the invite row, it does not re-query it.
        """
        mock_db, mock_client = mock_supabase

        original_goal = {
            "id": "goal1",
            "user_id": "friend1",
            "exercise_name": "Push-ups",
            "goal_type": "single_max",
            "target_value": 50,
            "week_start": date.today().isoformat(),
            "week_end": (date.today() + timedelta(days=6)).isoformat(),
        }

        invite_data = {
            "id": "invite1",
            "goal_id": "goal1",
            "inviter_id": "friend1",
            "invitee_id": "user123",
            "status": "pending",
            "message": "Join me!",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
            "responded_at": None,
            "weekly_personal_goals": original_goal,
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
            **{k: v for k, v in invite_data.items() if k != "weekly_personal_goals"},
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

            # Exact DB call script the accept path issues, in order.
            mock_table.execute.side_effect = [
                MagicMock(data=[invite_data]),  # 1. Get invite (+ embedded goal)
                MagicMock(data=[]),  # 2. No existing goal this week
                MagicMock(data=[]),  # 3. No personal best
                MagicMock(data=[new_goal]),  # 4. Insert new goal
                MagicMock(data=[{"id": "shared1"}]),  # 5. Insert shared_goals record
                MagicMock(data=[{"id": "goal1"}]),  # 6. Mark original goal shared
                MagicMock(data=[updated_invite]),  # 7. Update invite -> accepted
                MagicMock(data=[updated_invite]),  # 8. Re-fetch updated invite
            ]

            response = client.post(
                "/api/v1/goal-social/goals/invites/invite1/respond",
                params={"user_id": "user123"},
                json={"accept": True}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["invite"]["status"] == "accepted"
            assert data["created_goal_id"] is not None

    def test_decline_invite(self, client, mock_supabase):
        """Test declining an invite.

        The invite row must carry created_at/expires_at — both are NOT NULL
        columns, and expires_at gates the "invite has expired" branch that runs
        before the accept/decline split.
        """
        mock_db, mock_client = mock_supabase

        invite_data = {
            "id": "invite1",
            "goal_id": "goal1",
            "inviter_id": "friend1",
            "invitee_id": "user123",
            "status": "pending",
            "message": "Join me!",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
            "responded_at": None,
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
                MagicMock(data=[invite_data]),  # 1. Get invite
                MagicMock(data=[declined_invite]),  # 2. Update invite -> declined
                MagicMock(data=[declined_invite]),  # 3. Re-fetch updated invite
            ]

            response = client.post(
                "/api/v1/goal-social/goals/invites/invite1/respond",
                params={"user_id": "user123"},
                json={"accept": False}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["invite"]["status"] == "declined"
            assert data["created_goal_id"] is None

    def test_respond_to_non_pending_invite_fails(self, client, mock_supabase):
        """Test that responding to already-responded invite fails.

        Guarantee protected: an invite whose status is not "pending" is rejected
        400 and no goal / shared_goals row is created.

        The detail assertion used to look for the substring "already". The
        endpoint has answered "Invite is not pending (status: ...)" since the
        file's first commit (f3005344) — the substring never matched, it was
        spec drift in the test, not a behavior change. Pinned to the exact
        message (which also proves the offending status is echoed back).
        """
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
                "/api/v1/goal-social/goals/invites/invite1/respond",
                params={"user_id": "user123"},
                json={"accept": True}
            )

            assert response.status_code == 400
            assert response.json()["detail"] == "Invite is not pending (status: accepted)"


class TestPendingInvitesCount:
    """Tests for GET /goals/invites/pending-count endpoint."""

    def test_get_pending_count(self, client, mock_supabase):
        """Test getting count of pending invites.

        The endpoint selects `created_at, expires_at` and folds them into
        oldest_invite_at / expires_soon_count, so the mock rows must carry those
        columns (id-only rows made it 500 on KeyError, which real rows can't do).
        """
        mock_db, mock_client = mock_supabase

        now = datetime.now(timezone.utc)

        with patch("api.v1.goal_social.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gt.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[
                # oldest of the three; expires in 6 days (not "soon")
                {
                    "id": "invite1",
                    "created_at": (now - timedelta(days=3)).isoformat(),
                    "expires_at": (now + timedelta(days=6)).isoformat(),
                },
                {
                    "id": "invite2",
                    "created_at": (now - timedelta(days=1)).isoformat(),
                    "expires_at": (now + timedelta(days=2)).isoformat(),
                },
                # expires within 24h -> counted in expires_soon_count
                {
                    "id": "invite3",
                    "created_at": (now - timedelta(hours=2)).isoformat(),
                    "expires_at": (now + timedelta(hours=5)).isoformat(),
                },
            ], count=3)

            response = client.get(
                "/api/v1/goal-social/goals/invites/pending-count",
                params={"user_id": "user123"}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["pending_count"] == 3
            assert data["expires_soon_count"] == 1
            assert data["oldest_invite_at"] is not None
