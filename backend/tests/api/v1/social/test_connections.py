"""
Tests for social connections API endpoints.

Tests cover:
- POST /connections - Create connection
- DELETE /connections/{following_id} - Delete connection
- GET /connections/followers/{user_id} - Get followers
- GET /connections/following/{user_id} - Get following
- GET /connections/friends/{user_id} - Get mutual friends
"""
import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException

from models.social import UserConnectionCreate, ConnectionType


class TestCreateConnection:
    """Tests for create_connection endpoint."""

    @pytest.mark.asyncio
    async def test_create_connection_success(self):
        """Test successful connection creation."""
        from api.v1.social.connections import create_connection

        mock_client = MagicMock()
        # Mock no existing connection
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
        # Mock successful insert
        mock_client.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": "conn-1",
            "follower_id": "user-1",
            "following_id": "user-2",
            "connection_type": "friend",
            "status": "active",
            "created_at": "2024-01-15T00:00:00Z",
        }]

        connection_create = UserConnectionCreate(
            following_id="user-2",
            connection_type=ConnectionType.FRIEND,
        )

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await create_connection("user-1", connection_create)

        assert result.id == "conn-1"
        assert result.follower_id == "user-1"
        assert result.following_id == "user-2"

    @pytest.mark.asyncio
    async def test_create_connection_self_follow_fails(self):
        """Test that self-following raises 400."""
        from api.v1.social.connections import create_connection

        connection_create = UserConnectionCreate(
            following_id="user-1",
            connection_type=ConnectionType.FRIEND,
        )

        with pytest.raises(HTTPException) as exc_info:
            await create_connection("user-1", connection_create)

        assert exc_info.value.status_code == 400
        assert "yourself" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_create_connection_already_following(self):
        """Test that duplicate connection raises 400."""
        from api.v1.social.connections import create_connection

        mock_client = MagicMock()
        # Mock existing connection
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": "existing-conn"
        }]

        connection_create = UserConnectionCreate(
            following_id="user-2",
            connection_type=ConnectionType.FRIEND,
        )

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await create_connection("user-1", connection_create)

        assert exc_info.value.status_code == 400
        assert "already following" in exc_info.value.detail.lower()


class TestDeleteConnection:
    """Tests for delete_connection endpoint."""

    @pytest.mark.asyncio
    async def test_delete_connection_success(self):
        """Test successful connection deletion."""
        from api.v1.social.connections import delete_connection

        mock_client = MagicMock()
        mock_client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{"id": "conn-1"}]

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await delete_connection("user-1", "user-2")

        assert result["message"] == "Connection deleted successfully"

    @pytest.mark.asyncio
    async def test_delete_connection_not_found(self):
        """Test delete non-existent connection raises 404."""
        from api.v1.social.connections import delete_connection

        mock_client = MagicMock()
        mock_client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await delete_connection("user-1", "user-2")

        assert exc_info.value.status_code == 404


class TestGetFollowers:
    """Tests for get_followers endpoint."""

    @pytest.mark.asyncio
    async def test_get_followers_success(self):
        """Test successful followers retrieval."""
        from api.v1.social.connections import get_followers

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {
                "id": "conn-1",
                "follower_id": "user-2",
                "following_id": "user-1",
                "connection_type": "friend",
                "status": "active",
                "users": {
                    "id": "user-2",
                    "name": "John Doe",
                    "avatar_url": "https://example.com/avatar.jpg"
                }
            }
        ]

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_followers("user-1")

        assert len(result) == 1
        assert result[0].user_profile.name == "John Doe"

    @pytest.mark.asyncio
    async def test_get_followers_with_connection_type_filter(self):
        """Test followers retrieval with connection type filter."""
        from api.v1.social.connections import get_followers

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_followers("user-1", connection_type=ConnectionType.FAMILY)

        assert result == []


class TestGetFollowing:
    """Tests for get_following endpoint."""

    @pytest.mark.asyncio
    async def test_get_following_success(self):
        """Test successful following retrieval."""
        from api.v1.social.connections import get_following

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {
                "id": "conn-1",
                "follower_id": "user-1",
                "following_id": "user-2",
                "connection_type": "friend",
                "status": "active",
                "users": {
                    "id": "user-2",
                    "name": "Jane Doe",
                    "avatar_url": None
                }
            }
        ]

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_following("user-1")

        assert len(result) == 1
        assert result[0].user_profile.name == "Jane Doe"


class TestGetFriends:
    """Tests for get_friends endpoint."""

    @pytest.mark.asyncio
    async def test_get_friends_success(self):
        """Test successful mutual friends retrieval."""
        from api.v1.social.connections import get_friends

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {
                "friend_id": "user-2",
                "users": {
                    "id": "user-2",
                    "name": "Mutual Friend",
                    "avatar_url": "https://example.com/avatar.jpg"
                }
            }
        ]

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_friends("user-1")

        assert len(result) == 1
        assert result[0].name == "Mutual Friend"

    @pytest.mark.asyncio
    async def test_get_friends_empty(self):
        """Test empty friends list."""
        from api.v1.social.connections import get_friends

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_friends("user-1")

        assert result == []
