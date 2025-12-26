"""
Tests for friend request API endpoints.

Tests cover:
- POST /friend-requests - Send friend request
- GET /friend-requests/received - Get received requests
- GET /friend-requests/sent - Get sent requests
- POST /friend-requests/{id}/accept - Accept request
- POST /friend-requests/{id}/decline - Decline request
- DELETE /friend-requests/{id} - Cancel request
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi import HTTPException

from models.friend_request import FriendRequestCreate, FriendRequestStatus


class TestSendFriendRequest:
    """Tests for send_friend_request endpoint."""

    @pytest.mark.asyncio
    async def test_send_request_success(self):
        """Test successful friend request creation."""
        from api.v1.social.friend_requests import send_friend_request

        mock_client = MagicMock()

        # Mock target user exists
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "user-2",
            "name": "John Doe",
            "avatar_url": None,
        }

        # Mock no existing request
        mock_client.table.return_value.select.return_value.or_.return_value.execute.return_value.data = []

        # Mock no existing connection
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        # Mock successful insert
        mock_client.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": "req-1",
            "from_user_id": "user-1",
            "to_user_id": "user-2",
            "status": "pending",
            "message": "Let's be friends!",
            "created_at": "2024-01-15T00:00:00Z",
        }]

        request = FriendRequestCreate(to_user_id="user-2", message="Let's be friends!")

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with patch("api.v1.social.friend_requests.create_social_notification", new_callable=AsyncMock):
                result = await send_friend_request(user_id="user-1", request=request)

        assert result.id == "req-1"
        assert result.status == FriendRequestStatus.PENDING

    @pytest.mark.asyncio
    async def test_send_request_to_self_fails(self):
        """Test that sending request to self raises 400."""
        from api.v1.social.friend_requests import send_friend_request

        request = FriendRequestCreate(to_user_id="user-1")

        with pytest.raises(HTTPException) as exc_info:
            await send_friend_request(user_id="user-1", request=request)

        assert exc_info.value.status_code == 400
        assert "yourself" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_send_request_user_not_found(self):
        """Test 404 when target user doesn't exist."""
        from api.v1.social.friend_requests import send_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        request = FriendRequestCreate(to_user_id="nonexistent")

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await send_friend_request(user_id="user-1", request=request)

        assert exc_info.value.status_code == 404

    @pytest.mark.asyncio
    async def test_send_duplicate_request_fails(self):
        """Test that duplicate pending request raises 400."""
        from api.v1.social.friend_requests import send_friend_request

        mock_client = MagicMock()

        # Mock target user exists
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "user-2",
            "name": "John",
            "avatar_url": None,
        }

        # Mock existing pending request
        mock_client.table.return_value.select.return_value.or_.return_value.execute.return_value.data = [
            {"id": "existing-req", "status": "pending"}
        ]

        request = FriendRequestCreate(to_user_id="user-2")

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await send_friend_request(user_id="user-1", request=request)

        assert exc_info.value.status_code == 400
        assert "already" in exc_info.value.detail.lower()


class TestGetReceivedRequests:
    """Tests for get_received_requests endpoint."""

    @pytest.mark.asyncio
    async def test_get_received_success(self):
        """Test successful retrieval of received requests."""
        from api.v1.social.friend_requests import get_received_requests

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
            {
                "id": "req-1",
                "from_user_id": "user-2",
                "to_user_id": "user-1",
                "status": "pending",
                "message": None,
                "created_at": "2024-01-15T00:00:00Z",
                "responded_at": None,
                "users": {"id": "user-2", "name": "John Doe", "avatar_url": None},
            }
        ]

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            result = await get_received_requests(user_id="user-1", status=None)

        assert len(result) == 1
        assert result[0].from_user_name == "John Doe"

    @pytest.mark.asyncio
    async def test_get_received_with_status_filter(self):
        """Test filtering received requests by status."""
        from api.v1.social.friend_requests import get_received_requests

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value.data = []

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            result = await get_received_requests(
                user_id="user-1",
                status=FriendRequestStatus.PENDING
            )

        assert result == []


class TestGetSentRequests:
    """Tests for get_sent_requests endpoint."""

    @pytest.mark.asyncio
    async def test_get_sent_success(self):
        """Test successful retrieval of sent requests."""
        from api.v1.social.friend_requests import get_sent_requests

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
            {
                "id": "req-1",
                "from_user_id": "user-1",
                "to_user_id": "user-2",
                "status": "pending",
                "message": "Hello!",
                "created_at": "2024-01-15T00:00:00Z",
                "responded_at": None,
                "users": {"id": "user-2", "name": "Jane Doe", "avatar_url": None},
            }
        ]

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            result = await get_sent_requests(user_id="user-1", status=None)

        assert len(result) == 1
        assert result[0].to_user_name == "Jane Doe"


class TestAcceptFriendRequest:
    """Tests for accept_friend_request endpoint."""

    @pytest.mark.asyncio
    async def test_accept_request_success(self):
        """Test successful acceptance of friend request."""
        from api.v1.social.friend_requests import accept_friend_request

        mock_client = MagicMock()

        # Mock getting the request
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "req-1",
            "from_user_id": "user-2",
            "to_user_id": "user-1",
            "status": "pending",
        }

        # Mock update
        mock_client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        # Mock connection insert
        mock_client.table.return_value.insert.return_value.execute.return_value.data = [{}]

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with patch("api.v1.social.friend_requests.create_social_notification", new_callable=AsyncMock):
                result = await accept_friend_request(request_id="req-1", user_id="user-1")

        assert result["message"] == "Friend request accepted"
        assert result["connection_created"] is True

    @pytest.mark.asyncio
    async def test_accept_request_not_recipient_fails(self):
        """Test that non-recipient cannot accept request."""
        from api.v1.social.friend_requests import accept_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "req-1",
            "from_user_id": "user-2",
            "to_user_id": "user-3",  # Different user
            "status": "pending",
        }

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await accept_friend_request(request_id="req-1", user_id="user-1")

        assert exc_info.value.status_code == 403

    @pytest.mark.asyncio
    async def test_accept_already_accepted_fails(self):
        """Test that already accepted request raises 400."""
        from api.v1.social.friend_requests import accept_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "req-1",
            "from_user_id": "user-2",
            "to_user_id": "user-1",
            "status": "accepted",  # Already accepted
        }

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await accept_friend_request(request_id="req-1", user_id="user-1")

        assert exc_info.value.status_code == 400

    @pytest.mark.asyncio
    async def test_accept_not_found(self):
        """Test 404 for non-existent request."""
        from api.v1.social.friend_requests import accept_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await accept_friend_request(request_id="nonexistent", user_id="user-1")

        assert exc_info.value.status_code == 404


class TestDeclineFriendRequest:
    """Tests for decline_friend_request endpoint."""

    @pytest.mark.asyncio
    async def test_decline_request_success(self):
        """Test successful decline of friend request."""
        from api.v1.social.friend_requests import decline_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "req-1",
            "from_user_id": "user-2",
            "to_user_id": "user-1",
            "status": "pending",
        }
        mock_client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            result = await decline_friend_request(request_id="req-1", user_id="user-1")

        assert result["message"] == "Friend request declined"

    @pytest.mark.asyncio
    async def test_decline_not_recipient_fails(self):
        """Test that non-recipient cannot decline request."""
        from api.v1.social.friend_requests import decline_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "req-1",
            "from_user_id": "user-2",
            "to_user_id": "user-3",
            "status": "pending",
        }

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await decline_friend_request(request_id="req-1", user_id="user-1")

        assert exc_info.value.status_code == 403


class TestCancelFriendRequest:
    """Tests for cancel_friend_request endpoint."""

    @pytest.mark.asyncio
    async def test_cancel_request_success(self):
        """Test successful cancellation of sent request."""
        from api.v1.social.friend_requests import cancel_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "req-1",
            "from_user_id": "user-1",  # Current user is sender
            "to_user_id": "user-2",
            "status": "pending",
        }
        mock_client.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = [{}]

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            result = await cancel_friend_request(request_id="req-1", user_id="user-1")

        assert result["message"] == "Friend request cancelled"

    @pytest.mark.asyncio
    async def test_cancel_not_sender_fails(self):
        """Test that non-sender cannot cancel request."""
        from api.v1.social.friend_requests import cancel_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "req-1",
            "from_user_id": "user-2",  # Different user is sender
            "to_user_id": "user-1",
            "status": "pending",
        }

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await cancel_friend_request(request_id="req-1", user_id="user-1")

        assert exc_info.value.status_code == 403

    @pytest.mark.asyncio
    async def test_cancel_non_pending_fails(self):
        """Test that non-pending requests cannot be cancelled."""
        from api.v1.social.friend_requests import cancel_friend_request

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "req-1",
            "from_user_id": "user-1",
            "to_user_id": "user-2",
            "status": "accepted",  # Already responded
        }

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await cancel_friend_request(request_id="req-1", user_id="user-1")

        assert exc_info.value.status_code == 400


class TestGetPendingCount:
    """Tests for get_pending_count endpoint."""

    @pytest.mark.asyncio
    async def test_get_pending_count_success(self):
        """Test getting pending request count."""
        from api.v1.social.friend_requests import get_pending_count

        mock_client = MagicMock()
        mock_result = MagicMock()
        mock_result.count = 5
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.social.friend_requests.get_supabase_client", return_value=mock_client):
            result = await get_pending_count(user_id="user-1")

        assert result["count"] == 5
