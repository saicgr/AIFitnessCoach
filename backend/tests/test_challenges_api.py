"""
Tests for Challenges API endpoints.

Tests:
- Send challenges to friends
- Get received/sent challenges
- Accept/decline challenges
- Complete/abandon challenges
- Challenge notifications
- Challenge statistics

Run with: pytest backend/tests/test_challenges_api.py -v
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone, timedelta
import uuid

from main import app
from models.workout_challenges import (
    ChallengeStatus, NotificationType,
    SendChallengeRequest, CompleteChallengeRequest, AbandonChallengeRequest,
)


client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Mock Supabase client for testing."""
    with patch('api.v1.challenges.get_supabase') as mock:
        supabase_mock = MagicMock()
        mock.return_value.client = supabase_mock
        yield supabase_mock


@pytest.fixture
def mock_social_rag():
    """Mock Social RAG service for testing."""
    with patch('api.v1.challenges.get_social_rag_service') as mock:
        rag_mock = MagicMock()
        collection_mock = MagicMock()
        rag_mock.get_social_collection.return_value = collection_mock
        mock.return_value = rag_mock
        yield rag_mock, collection_mock


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_friend_id():
    """Sample friend ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_challenge_id():
    """Sample challenge ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_workout_data():
    """Sample workout data for challenges."""
    return {
        "duration_minutes": 45,
        "total_volume": 5000,
        "exercises_count": 8,
        "exercises": [
            {"name": "Bench Press", "sets": 4, "reps": 10, "weight_kg": 80},
            {"name": "Squats", "sets": 4, "reps": 8, "weight_kg": 100},
        ]
    }


# ============================================================
# SEND CHALLENGES TESTS
# ============================================================

class TestSendChallenges:
    """Test sending challenges to friends."""

    def test_send_challenge_success(self, mock_supabase, mock_social_rag, sample_user_id, sample_friend_id, sample_workout_data):
        """Test successfully sending a challenge to a friend."""
        rag_mock, collection_mock = mock_social_rag
        challenge_id = str(uuid.uuid4())

        # Mock user lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Test User"}
        ]

        # Mock challenge insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": challenge_id,
            "from_user_id": sample_user_id,
            "to_user_id": sample_friend_id,
            "workout_name": "Upper Body Strength",
            "workout_data": sample_workout_data,
            "status": "pending",
            "is_retry": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        }]

        response = client.post(
            f"/api/v1/challenges/send?user_id={sample_user_id}",
            json={
                "to_user_ids": [sample_friend_id],
                "workout_name": "Upper Body Strength",
                "workout_data": sample_workout_data,
                "challenge_message": "Beat this!",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["challenges_sent"] == 1
        assert challenge_id in data["challenge_ids"]
        assert "Challenge sent" in data["message"]

        # Verify ChromaDB was called
        collection_mock.add.assert_called()

    def test_send_challenge_cannot_challenge_self(self, mock_supabase, sample_user_id, sample_workout_data):
        """Test that user cannot challenge themselves."""
        response = client.post(
            f"/api/v1/challenges/send?user_id={sample_user_id}",
            json={
                "to_user_ids": [sample_user_id],  # Same as sender
                "workout_name": "Upper Body Strength",
                "workout_data": sample_workout_data,
            }
        )

        assert response.status_code == 400
        assert "Cannot challenge yourself" in response.json()["detail"]

    def test_send_challenge_multiple_friends(self, mock_supabase, mock_social_rag, sample_user_id, sample_workout_data):
        """Test sending challenge to multiple friends."""
        rag_mock, collection_mock = mock_social_rag
        friend_ids = [str(uuid.uuid4()) for _ in range(3)]

        # Mock user lookups
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "User"}
        ]

        # Mock challenge inserts
        def mock_insert(data):
            mock_result = MagicMock()
            mock_result.execute.return_value.data = [{
                "id": str(uuid.uuid4()),
                **data,
                "status": "pending",
                "is_retry": False,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
            }]
            return mock_result

        mock_supabase.table.return_value.insert = mock_insert

        response = client.post(
            f"/api/v1/challenges/send?user_id={sample_user_id}",
            json={
                "to_user_ids": friend_ids,
                "workout_name": "Full Body Workout",
                "workout_data": sample_workout_data,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["challenges_sent"] == 3
        assert len(data["challenge_ids"]) == 3

    def test_send_retry_challenge(self, mock_supabase, mock_social_rag, sample_user_id, sample_friend_id, sample_workout_data):
        """Test sending a retry challenge."""
        rag_mock, collection_mock = mock_social_rag
        original_challenge_id = str(uuid.uuid4())
        new_challenge_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Test User"}
        ]

        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": new_challenge_id,
            "from_user_id": sample_user_id,
            "to_user_id": sample_friend_id,
            "workout_name": "Upper Body",
            "workout_data": sample_workout_data,
            "status": "pending",
            "is_retry": True,
            "retried_from_challenge_id": original_challenge_id,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        }]

        response = client.post(
            f"/api/v1/challenges/send?user_id={sample_user_id}",
            json={
                "to_user_ids": [sample_friend_id],
                "workout_name": "Upper Body",
                "workout_data": sample_workout_data,
                "is_retry": True,
                "retried_from_challenge_id": original_challenge_id,
            }
        )

        assert response.status_code == 200

        # Verify retry was logged to ChromaDB
        call_args = collection_mock.add.call_args
        assert "RETRIED" in call_args.kwargs["documents"][0]


# ============================================================
# GET CHALLENGES TESTS
# ============================================================

class TestGetChallenges:
    """Test getting received and sent challenges."""

    def test_get_received_challenges(self, mock_supabase, sample_user_id):
        """Test getting challenges received by user."""
        challenge_id = str(uuid.uuid4())
        from_user_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(
            data=[{
                "id": challenge_id,
                "from_user_id": from_user_id,
                "to_user_id": sample_user_id,
                "workout_name": "Leg Day",
                "workout_data": {"duration_minutes": 60},
                "status": "pending",
                "is_retry": False,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
                "from_user": {"name": "Friend", "avatar_url": None},
            }],
            count=1
        )

        response = client.get(
            f"/api/v1/challenges/received?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert len(data["challenges"]) == 1
        assert data["challenges"][0]["id"] == challenge_id

    def test_get_received_challenges_with_status_filter(self, mock_supabase, sample_user_id):
        """Test filtering received challenges by status."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.eq.return_value.range.return_value.execute.return_value = MagicMock(
            data=[],
            count=0
        )

        response = client.get(
            f"/api/v1/challenges/received?user_id={sample_user_id}&status=accepted"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0

    def test_get_sent_challenges(self, mock_supabase, sample_user_id):
        """Test getting challenges sent by user."""
        challenge_id = str(uuid.uuid4())
        to_user_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(
            data=[{
                "id": challenge_id,
                "from_user_id": sample_user_id,
                "to_user_id": to_user_id,
                "workout_name": "Push Day",
                "workout_data": {"duration_minutes": 45},
                "status": "pending",
                "is_retry": False,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
                "to_user": {"name": "Target Friend", "avatar_url": None},
            }],
            count=1
        )

        response = client.get(
            f"/api/v1/challenges/sent?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["challenges"][0]["from_user_id"] == sample_user_id

    def test_get_challenges_pagination(self, mock_supabase, sample_user_id):
        """Test challenge pagination."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(
            data=[],
            count=50
        )

        response = client.get(
            f"/api/v1/challenges/received?user_id={sample_user_id}&page=2&page_size=10"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 2
        assert data["page_size"] == 10


# ============================================================
# ACCEPT/DECLINE CHALLENGES TESTS
# ============================================================

class TestAcceptDeclineChallenges:
    """Test accepting and declining challenges."""

    def test_accept_challenge_success(self, mock_supabase, mock_social_rag, sample_user_id, sample_challenge_id):
        """Test accepting a pending challenge."""
        rag_mock, collection_mock = mock_social_rag

        # Mock challenge lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "from_user_id": str(uuid.uuid4()),
            "to_user_id": sample_user_id,
            "workout_name": "Full Body",
            "workout_data": {"duration_minutes": 60},
            "status": "pending",
        }]

        # Mock update
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "from_user_id": str(uuid.uuid4()),
            "to_user_id": sample_user_id,
            "workout_name": "Full Body",
            "workout_data": {"duration_minutes": 60},
            "status": "accepted",
            "accepted_at": datetime.now(timezone.utc).isoformat(),
            "is_retry": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        }]

        response = client.post(
            f"/api/v1/challenges/accept/{sample_challenge_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "accepted"

    def test_accept_challenge_not_found(self, mock_supabase, sample_user_id, sample_challenge_id):
        """Test accepting a non-existent challenge."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        response = client.post(
            f"/api/v1/challenges/accept/{sample_challenge_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 404
        assert "Challenge not found" in response.json()["detail"]

    def test_accept_already_accepted_challenge(self, mock_supabase, sample_user_id, sample_challenge_id):
        """Test accepting an already accepted challenge."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "status": "accepted",  # Already accepted
        }]

        response = client.post(
            f"/api/v1/challenges/accept/{sample_challenge_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 400
        assert "already accepted" in response.json()["detail"]

    def test_decline_challenge_success(self, mock_supabase, sample_user_id, sample_challenge_id):
        """Test declining a pending challenge."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "status": "pending",
        }]

        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "status": "declined",
        }]

        response = client.post(
            f"/api/v1/challenges/decline/{sample_challenge_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        assert "declined" in response.json()["message"]

    def test_decline_challenge_not_found(self, mock_supabase, sample_user_id, sample_challenge_id):
        """Test declining a non-existent challenge."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        response = client.post(
            f"/api/v1/challenges/decline/{sample_challenge_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 404


# ============================================================
# COMPLETE CHALLENGE TESTS
# ============================================================

class TestCompleteChallenge:
    """Test completing challenges with results."""

    def test_complete_challenge_win(self, mock_supabase, mock_social_rag, sample_user_id, sample_challenge_id):
        """Test completing a challenge and winning (beating the target)."""
        rag_mock, collection_mock = mock_social_rag

        original_stats = {"duration_minutes": 60, "total_volume": 5000}
        challenged_stats = {"duration_minutes": 55, "total_volume": 5500}  # Better stats

        # Mock challenge lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "from_user_id": str(uuid.uuid4()),
            "to_user_id": sample_user_id,
            "workout_name": "Full Body",
            "workout_data": original_stats,
            "status": "accepted",
            "from_user": {"name": "Challenger", "avatar_url": None},
        }]

        # Mock update
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "status": "completed",
            "did_beat": True,
            "challenger_stats": original_stats,
            "challenged_stats": challenged_stats,
            "from_user_id": str(uuid.uuid4()),
            "to_user_id": sample_user_id,
            "workout_name": "Full Body",
            "workout_data": original_stats,
            "is_retry": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        }]

        # Mock activity feed insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{}]

        response = client.post(
            f"/api/v1/challenges/complete/{sample_challenge_id}?user_id={sample_user_id}",
            json={
                "challenge_id": sample_challenge_id,
                "workout_log_id": str(uuid.uuid4()),
                "challenged_stats": challenged_stats,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data["did_beat"] is True

    def test_complete_challenge_loss(self, mock_supabase, mock_social_rag, sample_user_id, sample_challenge_id):
        """Test completing a challenge and losing (not beating the target)."""
        rag_mock, collection_mock = mock_social_rag

        original_stats = {"duration_minutes": 45, "total_volume": 6000}
        challenged_stats = {"duration_minutes": 60, "total_volume": 4000}  # Worse stats

        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "from_user_id": str(uuid.uuid4()),
            "to_user_id": sample_user_id,
            "workout_name": "Full Body",
            "workout_data": original_stats,
            "status": "accepted",
            "from_user": {"name": "Challenger", "avatar_url": None},
        }]

        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "status": "completed",
            "did_beat": False,
            "challenger_stats": original_stats,
            "challenged_stats": challenged_stats,
            "from_user_id": str(uuid.uuid4()),
            "to_user_id": sample_user_id,
            "workout_name": "Full Body",
            "workout_data": original_stats,
            "is_retry": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        }]

        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{}]

        response = client.post(
            f"/api/v1/challenges/complete/{sample_challenge_id}?user_id={sample_user_id}",
            json={
                "challenge_id": sample_challenge_id,
                "workout_log_id": str(uuid.uuid4()),
                "challenged_stats": challenged_stats,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["did_beat"] is False

    def test_complete_challenge_not_accepted(self, mock_supabase, sample_user_id, sample_challenge_id):
        """Test completing a challenge that is not accepted yet."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "status": "pending",  # Not accepted
        }]

        response = client.post(
            f"/api/v1/challenges/complete/{sample_challenge_id}?user_id={sample_user_id}",
            json={
                "challenge_id": sample_challenge_id,
                "workout_log_id": str(uuid.uuid4()),
                "challenged_stats": {"duration_minutes": 30},
            }
        )

        assert response.status_code == 400
        assert "must be accepted" in response.json()["detail"]


# ============================================================
# ABANDON CHALLENGE TESTS
# ============================================================

class TestAbandonChallenge:
    """Test abandoning challenges midway."""

    def test_abandon_challenge_success(self, mock_supabase, mock_social_rag, sample_user_id, sample_challenge_id):
        """Test abandoning an accepted challenge."""
        rag_mock, collection_mock = mock_social_rag

        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "from_user_id": str(uuid.uuid4()),
            "to_user_id": sample_user_id,
            "workout_name": "Full Body",
            "workout_data": {"duration_minutes": 60},
            "status": "accepted",
            "from_user": {"name": "Challenger", "avatar_url": None},
        }]

        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "status": "abandoned",
            "quit_reason": "Too tired",
            "partial_stats": {"duration_minutes": 20, "exercises_completed": 3},
            "from_user_id": str(uuid.uuid4()),
            "to_user_id": sample_user_id,
            "workout_name": "Full Body",
            "workout_data": {"duration_minutes": 60},
            "is_retry": False,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        }]

        response = client.post(
            f"/api/v1/challenges/abandon/{sample_challenge_id}?user_id={sample_user_id}",
            json={
                "challenge_id": sample_challenge_id,
                "quit_reason": "Too tired",
                "partial_stats": {"duration_minutes": 20, "exercises_completed": 3},
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "abandoned"
        assert data["quit_reason"] == "Too tired"

    def test_abandon_challenge_not_accepted(self, mock_supabase, sample_user_id, sample_challenge_id):
        """Test abandoning a challenge that is not accepted."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_challenge_id,
            "status": "pending",
        }]

        response = client.post(
            f"/api/v1/challenges/abandon/{sample_challenge_id}?user_id={sample_user_id}",
            json={
                "challenge_id": sample_challenge_id,
                "quit_reason": "Changed my mind",
            }
        )

        assert response.status_code == 400
        assert "only abandon accepted" in response.json()["detail"].lower()


# ============================================================
# NOTIFICATIONS TESTS
# ============================================================

class TestChallengeNotifications:
    """Test challenge notifications."""

    def test_get_notifications(self, mock_supabase, sample_user_id):
        """Test getting challenge notifications."""
        notification_id = str(uuid.uuid4())
        challenge_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(
            data=[{
                "id": notification_id,
                "challenge_id": challenge_id,
                "user_id": sample_user_id,
                "notification_type": "challenge_received",
                "is_read": False,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "challenge": {
                    "id": challenge_id,
                    "workout_name": "Leg Day",
                },
            }],
            count=1
        )

        # Mock unread count
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(
            count=1
        )

        response = client.get(
            f"/api/v1/challenges/notifications?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["unread_count"] == 1
        assert len(data["notifications"]) == 1

    def test_get_unread_notifications_only(self, mock_supabase, sample_user_id):
        """Test getting only unread notifications."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[],
            count=0
        )

        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(
            count=0
        )

        response = client.get(
            f"/api/v1/challenges/notifications?user_id={sample_user_id}&unread_only=true"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["unread_count"] == 0

    def test_mark_notification_read(self, mock_supabase, sample_user_id):
        """Test marking a notification as read."""
        notification_id = str(uuid.uuid4())

        mock_supabase.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": notification_id,
            "is_read": True,
        }]

        response = client.put(
            f"/api/v1/challenges/notifications/{notification_id}/read?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        assert "read" in response.json()["message"].lower()


# ============================================================
# STATISTICS TESTS
# ============================================================

class TestChallengeStats:
    """Test challenge statistics."""

    def test_get_challenge_stats(self, mock_supabase, sample_user_id):
        """Test getting user's challenge statistics."""
        # Mock all the count queries
        mock_result = MagicMock()
        mock_result.count = 5

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result
        mock_supabase.table.return_value.select.return_value.eq.return_value.in_.return_value.execute.return_value = mock_result
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        # Mock RPC for retry stats
        mock_supabase.rpc.return_value.execute.return_value.data = [{
            "total_retries": 3,
            "retries_won": 2,
            "retry_win_rate": 66.67,
            "most_retried_workout": "Leg Day Challenge",
        }]

        response = client.get(
            f"/api/v1/challenges/stats/{sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == sample_user_id
        assert "challenges_sent" in data
        assert "challenges_received" in data
        assert "win_rate" in data
        assert "total_retries" in data
        assert "retry_win_rate" in data


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_chromadb_failure_doesnt_fail_request(self, mock_supabase, sample_user_id, sample_friend_id, sample_workout_data):
        """Test that ChromaDB failure doesn't fail the main request."""
        challenge_id = str(uuid.uuid4())

        with patch('api.v1.challenges.get_social_rag_service') as mock_rag:
            rag_mock = MagicMock()
            collection_mock = MagicMock()
            collection_mock.add.side_effect = Exception("ChromaDB error")
            rag_mock.get_social_collection.return_value = collection_mock
            mock_rag.return_value = rag_mock

            mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
                {"name": "Test User"}
            ]

            mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
                "id": challenge_id,
                "from_user_id": sample_user_id,
                "to_user_id": sample_friend_id,
                "workout_name": "Test",
                "workout_data": sample_workout_data,
                "status": "pending",
                "is_retry": False,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
            }]

            response = client.post(
                f"/api/v1/challenges/send?user_id={sample_user_id}",
                json={
                    "to_user_ids": [sample_friend_id],
                    "workout_name": "Test",
                    "workout_data": sample_workout_data,
                }
            )

            # Should still succeed even if ChromaDB fails
            assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
