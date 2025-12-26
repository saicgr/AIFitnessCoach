"""
Tests for social user search API endpoints.

Tests cover:
- GET /users/search - Search users by name
- GET /users/suggestions - Get friend suggestions
- GET /users/{user_id}/profile - Get user profile
"""
import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException


class TestSearchUsers:
    """Tests for search_users endpoint."""

    @pytest.mark.asyncio
    async def test_search_users_success(self):
        """Test successful user search."""
        from api.v1.social.users import search_users

        mock_client = MagicMock()

        # Mock user search results
        mock_client.table.return_value.select.return_value.ilike.return_value.neq.return_value.limit.return_value.execute.return_value.data = [
            {"id": "user-2", "name": "John Doe", "avatar_url": None, "bio": "Fitness enthusiast"},
            {"id": "user-3", "name": "Johnny Smith", "avatar_url": "https://example.com/avatar.jpg", "bio": None},
        ]

        # Mock connections check (following)
        mock_client.table.return_value.select.return_value.eq.return_value.in_.return_value.execute.return_value.data = []

        # Mock pending requests
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.in_.return_value.execute.return_value.data = []

        # Mock privacy settings
        mock_client.table.return_value.select.return_value.in_.return_value.execute.return_value.data = []

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await search_users(user_id="user-1", query="john", limit=20)

        assert len(result) == 2
        assert result[0].name == "John Doe"
        assert result[1].name == "Johnny Smith"

    @pytest.mark.asyncio
    async def test_search_users_empty_query_returns_empty(self):
        """Test that empty query returns empty list."""
        from api.v1.social.users import search_users

        result = await search_users(user_id="user-1", query="", limit=20)
        assert result == []

    @pytest.mark.asyncio
    async def test_search_users_with_whitespace_only(self):
        """Test that whitespace-only query returns empty list."""
        from api.v1.social.users import search_users

        result = await search_users(user_id="user-1", query="   ", limit=20)
        assert result == []

    @pytest.mark.asyncio
    async def test_search_users_excludes_current_user(self):
        """Test that search excludes the current user from results."""
        from api.v1.social.users import search_users

        mock_client = MagicMock()

        # Mock empty results (user searched for themselves)
        mock_client.table.return_value.select.return_value.ilike.return_value.neq.return_value.limit.return_value.execute.return_value.data = []

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await search_users(user_id="user-1", query="user-1", limit=20)

        # Verify neq was called to exclude current user
        mock_client.table.return_value.select.return_value.ilike.return_value.neq.assert_called_with("id", "user-1")
        assert result == []


class TestGetFriendSuggestions:
    """Tests for get_friend_suggestions endpoint."""

    @pytest.mark.asyncio
    async def test_get_suggestions_with_mutual_friends(self):
        """Test suggestions based on mutual friends."""
        from api.v1.social.users import get_friend_suggestions

        mock_client = MagicMock()

        # Mock current user's following
        mock_following = MagicMock()
        mock_following.data = [{"following_id": "user-2"}]

        # Mock friends of friends
        mock_fof = MagicMock()
        mock_fof.data = [
            {"follower_id": "user-2", "following_id": "user-3"},
            {"follower_id": "user-2", "following_id": "user-4"},
        ]

        # Mock user profiles
        mock_profiles = MagicMock()
        mock_profiles.data = [
            {"id": "user-3", "name": "Suggested Friend 1", "avatar_url": None, "bio": None},
            {"id": "user-4", "name": "Suggested Friend 2", "avatar_url": None, "bio": None},
        ]

        # Mock stats
        mock_stats = MagicMock()
        mock_stats.data = []

        # Mock privacy
        mock_privacy = MagicMock()
        mock_privacy.data = []

        def table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "user_connections":
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_following
                mock_table.select.return_value.in_.return_value.execute.return_value = mock_fof
            elif table_name == "users":
                mock_table.select.return_value.in_.return_value.execute.return_value = mock_profiles
            elif table_name == "workout_logs":
                mock_table.select.return_value.in_.return_value.execute.return_value = mock_stats
            elif table_name == "user_privacy_settings":
                mock_table.select.return_value.in_.return_value.execute.return_value = mock_privacy
            return mock_table

        mock_client.table.side_effect = table_side_effect

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await get_friend_suggestions(user_id="user-1", limit=10)

        assert len(result) == 2
        assert all("mutual friend" in s.suggestion_reason.lower() for s in result)

    @pytest.mark.asyncio
    async def test_get_suggestions_fallback_to_active_users(self):
        """Test fallback to active users when no mutual friends."""
        from api.v1.social.users import get_friend_suggestions

        mock_client = MagicMock()

        # Mock no following
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        # Mock fallback active users
        mock_client.table.return_value.select.return_value.neq.return_value.limit.return_value.execute.return_value.data = [
            {"id": "user-2", "name": "Active User", "avatar_url": None, "bio": None}
        ]

        # Mock privacy
        mock_client.table.return_value.select.return_value.in_.return_value.execute.return_value.data = []

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await get_friend_suggestions(user_id="user-1", limit=10)

        assert len(result) == 1
        assert "Active on" in result[0].suggestion_reason


class TestGetUserProfile:
    """Tests for get_user_profile endpoint."""

    @pytest.mark.asyncio
    async def test_get_profile_success(self):
        """Test successful profile retrieval."""
        from api.v1.social.users import get_user_profile

        mock_client = MagicMock()

        # Mock user profile
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "user-2",
            "name": "John Doe",
            "avatar_url": "https://example.com/avatar.jpg",
            "bio": "Fitness lover",
        }

        # Mock following check
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        # Mock pending requests
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        # Mock privacy settings
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        # Mock workout count
        mock_count_result = MagicMock()
        mock_count_result.count = 42
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_count_result

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await get_user_profile(target_user_id="user-2", user_id="user-1")

        assert result.id == "user-2"
        assert result.name == "John Doe"

    @pytest.mark.asyncio
    async def test_get_profile_not_found(self):
        """Test 404 for non-existent user."""
        from api.v1.social.users import get_user_profile

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await get_user_profile(target_user_id="nonexistent", user_id="user-1")

        assert exc_info.value.status_code == 404
