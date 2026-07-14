"""
Tests for social connections API endpoints.

Tests cover:
- POST /connections - Create connection
- DELETE /connections/{following_id} - Delete connection
- GET /connections/followers/{user_id} - Get followers
- GET /connections/following/{user_id} - Get following
- GET /connections/friends/{user_id} - Get mutual friends

HOW THESE TESTS CALL THE ENDPOINTS (updated 2026-07):
Every endpoint in this router now takes `current_user: dict = Depends(get_current_user)`
and calls `verify_user_ownership(current_user, user_id)` (IDOR guard). These tests
invoke the endpoint coroutines directly, so FastAPI never resolves the dependency —
they must pass the authenticated-user dict themselves. Without it the endpoint
received the raw `Depends(...)` object and died with
"TypeError: 'Depends' object is not subscriptable" before any endpoint logic ran.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi import HTTPException

from models.social import UserConnectionCreate, ConnectionType


def _auth(user_id: str) -> dict:
    """The dict FastAPI would have injected from Depends(get_current_user)."""
    return {"id": user_id, "email": f"{user_id}@example.com"}


def _admin_service(is_support: bool = False):
    """Mock admin service: delete_connection asks it whether the target is the support user."""
    svc = MagicMock()
    svc.is_support_user = AsyncMock(return_value=is_support)
    return svc


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
            result = await create_connection("user-1", connection_create, current_user=_auth("user-1"))

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

        with patch("api.v1.social.connections.get_supabase_client", return_value=MagicMock()):
            with pytest.raises(HTTPException) as exc_info:
                await create_connection("user-1", connection_create, current_user=_auth("user-1"))

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
                await create_connection("user-1", connection_create, current_user=_auth("user-1"))

        assert exc_info.value.status_code == 400
        assert "already following" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_create_connection_other_user_forbidden(self):
        """IDOR guard: creating a connection on behalf of another user raises 403."""
        from api.v1.social.connections import create_connection

        connection_create = UserConnectionCreate(
            following_id="user-2",
            connection_type=ConnectionType.FRIEND,
        )

        with patch("api.v1.social.connections.get_supabase_client", return_value=MagicMock()):
            with pytest.raises(HTTPException) as exc_info:
                await create_connection("victim", connection_create, current_user=_auth("attacker"))

        assert exc_info.value.status_code == 403


class TestDeleteConnection:
    """Tests for delete_connection endpoint."""

    @pytest.mark.asyncio
    async def test_delete_connection_success(self):
        """Test successful connection deletion."""
        from api.v1.social.connections import delete_connection

        mock_client = MagicMock()
        mock_client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{"id": "conn-1"}]

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client), \
             patch("api.v1.social.connections.get_admin_service", return_value=_admin_service(False)):
            result = await delete_connection("user-1", "user-2", current_user=_auth("user-1"))

        assert result["message"] == "Connection deleted successfully"

    @pytest.mark.asyncio
    async def test_delete_connection_not_found(self):
        """Test delete non-existent connection raises 404."""
        from api.v1.social.connections import delete_connection

        mock_client = MagicMock()
        mock_client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client), \
             patch("api.v1.social.connections.get_admin_service", return_value=_admin_service(False)):
            with pytest.raises(HTTPException) as exc_info:
                await delete_connection("user-1", "user-2", current_user=_auth("user-1"))

        assert exc_info.value.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_connection_support_user_forbidden(self):
        """The support user cannot be unfollowed (403)."""
        from api.v1.social.connections import delete_connection

        mock_client = MagicMock()

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client), \
             patch("api.v1.social.connections.get_admin_service", return_value=_admin_service(True)):
            with pytest.raises(HTTPException) as exc_info:
                await delete_connection("user-1", "support-user", current_user=_auth("user-1"))

        assert exc_info.value.status_code == 403
        mock_client.table.return_value.delete.assert_not_called()


class TestGetFollowers:
    """Tests for get_followers endpoint.

    RETIRED SHAPE: these used to assert a bare `List[UserConnectionWithProfile]`
    (`result[0].user_profile.name`). The endpoint now returns a cursor-paginated
    envelope — `{"items": [...], "next_cursor", "has_more", "total_count"}` — with
    each item a plain dict carrying a nested `user_profile`. The guarantee under
    test is unchanged: a follower row surfaces with its joined profile attached.
    """

    @pytest.mark.asyncio
    async def test_get_followers_success(self):
        """Test successful followers retrieval."""
        from api.v1.social.connections import get_followers

        mock_client = MagicMock()
        followers_query = mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value
        result_obj = followers_query.order.return_value.limit.return_value.execute.return_value
        result_obj.data = [
            {
                "id": "conn-1",
                "follower_id": "user-2",
                "following_id": "user-1",
                "connection_type": "friend",
                "status": "active",
                "created_at": "2024-01-15T00:00:00Z",
                "users": {
                    "id": "user-2",
                    "name": "John Doe",
                    "avatar_url": "https://example.com/avatar.jpg"
                }
            }
        ]
        result_obj.count = 1

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_followers("user-1", current_user=_auth("user-1"))

        assert len(result["items"]) == 1
        assert result["items"][0]["user_profile"]["name"] == "John Doe"
        assert result["items"][0]["follower_id"] == "user-2"
        assert result["total_count"] == 1
        assert result["has_more"] is False
        assert result["next_cursor"] is None

    @pytest.mark.asyncio
    async def test_get_followers_with_connection_type_filter(self):
        """Test followers retrieval with connection type filter."""
        from api.v1.social.connections import get_followers

        mock_client = MagicMock()
        # connection_type filter adds a third .eq() to the chain
        filtered_query = mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value
        result_obj = filtered_query.order.return_value.limit.return_value.execute.return_value
        result_obj.data = []
        result_obj.count = 0

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_followers(
                "user-1", connection_type=ConnectionType.FAMILY, current_user=_auth("user-1")
            )

        assert result["items"] == []
        assert result["total_count"] == 0
        # The filter was actually pushed down to the query
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.assert_called_once_with(
            "connection_type", ConnectionType.FAMILY.value
        )


class TestGetFollowing:
    """Tests for get_following endpoint (same paginated envelope as followers)."""

    @pytest.mark.asyncio
    async def test_get_following_success(self):
        """Test successful following retrieval."""
        from api.v1.social.connections import get_following

        mock_client = MagicMock()
        following_query = mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value
        result_obj = following_query.order.return_value.limit.return_value.execute.return_value
        result_obj.data = [
            {
                "id": "conn-1",
                "follower_id": "user-1",
                "following_id": "user-2",
                "connection_type": "friend",
                "status": "active",
                "created_at": "2024-01-15T00:00:00Z",
                "users": {
                    "id": "user-2",
                    "name": "Jane Doe",
                    "avatar_url": None
                }
            }
        ]
        result_obj.count = 1

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_following("user-1", current_user=_auth("user-1"))

        assert len(result["items"]) == 1
        assert result["items"][0]["user_profile"]["name"] == "Jane Doe"
        assert result["items"][0]["following_id"] == "user-2"
        assert result["total_count"] == 1


class TestGetFriends:
    """Tests for get_friends endpoint.

    HOW IT CALLS THE DB (updated): friends are now read from the bounded
    `user_friends` view (`.eq(...).limit(50)`) and their profiles fetched in a
    second `users` query (views carry no FKs, so the profile can't be joined).
    The mock chains follow that two-query shape; the assertions are unchanged.
    """

    @pytest.mark.asyncio
    async def test_get_friends_success(self):
        """Test successful mutual friends retrieval."""
        from api.v1.social.connections import get_friends

        mock_client = MagicMock()
        # 1) user_friends view -> friend ids
        mock_client.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value.data = [
            {"friend_id": "user-2"}
        ]
        # 2) users table -> profiles for those ids
        mock_client.table.return_value.select.return_value.in_.return_value.execute.return_value.data = [
            {
                "id": "user-2",
                "name": "Mutual Friend",
                "avatar_url": "https://example.com/avatar.jpg",
            }
        ]

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_friends("user-1", current_user=_auth("user-1"))

        assert len(result) == 1
        assert result[0].id == "user-2"
        assert result[0].name == "Mutual Friend"
        assert result[0].avatar_url == "https://example.com/avatar.jpg"

    @pytest.mark.asyncio
    async def test_get_friends_empty(self):
        """Test empty friends list."""
        from api.v1.social.connections import get_friends

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value.data = []

        with patch("api.v1.social.connections.get_supabase_client", return_value=mock_client):
            result = await get_friends("user-1", current_user=_auth("user-1"))

        assert result == []
