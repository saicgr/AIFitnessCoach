"""
Tests for social user search API endpoints.

Tests cover:
- GET /users/search - Search users by name
- GET /users/suggestions - Get friend suggestions
- GET /users/{user_id}/profile - Get user profile

How these tests changed (and why):

1. The endpoints gained `current_user: dict = Depends(get_current_user)` and an
   IDOR check (`verify_user_ownership`). Calling them directly without passing
   `current_user` left the `Depends` sentinel in place, so the handler tried to
   subscript it ("'Depends' object is not subscriptable") before any real code
   ran. The tests now pass the authenticated user explicitly (and the paginated
   `offset` param the endpoints also gained) — i.e. they call the handlers the
   way FastAPI does.

2. /search and /suggestions no longer return a bare list; they return a
   paginated envelope {"results": [...], "total_count": N, "has_more": bool}.
   The assertions were re-pointed at that envelope; what they assert (who is
   returned, in what order, with what reason) is unchanged.

3. The query plumbing changed too: search uses `.or_(name.ilike/username.ilike)`
   + `.range()` instead of `.ilike().neq().limit()`, suggestions use the
   `get_friend_suggestions_rpc` RPC, and workout counts come from the
   `get_workout_counts` RPC. The mocks model the real chains.
"""
import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException


# ---------------------------------------------------------------------------
# Supabase mocking helpers
# ---------------------------------------------------------------------------

def _result(data, count=None):
    """A PostgREST-ish response object with .data / .count."""
    res = MagicMock()
    res.data = data
    res.count = count
    return res


def _chain(result):
    """A self-returning query-builder mock whose .execute() yields `result`."""
    builder = MagicMock()
    for method in (
        "select", "eq", "neq", "in_", "ilike", "or_", "limit",
        "range", "single", "order", "gte", "lte",
    ):
        getattr(builder, method).return_value = builder
    builder.execute.return_value = result
    return builder


def _supabase(tables=None, rpcs=None):
    """Fake supabase client: per-table and per-RPC canned results."""
    tables = tables or {}
    rpcs = rpcs or {}
    client = MagicMock()
    client.table.side_effect = lambda name: _chain(tables.get(name, _result([])))
    client.rpc.side_effect = lambda name, params=None: _chain(rpcs.get(name, _result([])))
    return client


CURRENT_USER = {"id": "user-1"}


class TestSearchUsers:
    """Tests for search_users endpoint."""

    @pytest.mark.asyncio
    async def test_search_users_success(self):
        """Test successful user search."""
        from api.v1.social.users import search_users

        mock_client = _supabase(
            tables={
                "users": _result(
                    [
                        {"id": "user-2", "name": "John Doe", "username": "johnd",
                         "avatar_url": None, "bio": "Fitness enthusiast"},
                        {"id": "user-3", "name": "Johnny Smith", "username": None,
                         "avatar_url": "https://example.com/avatar.jpg", "bio": None},
                    ],
                    count=2,
                ),
                "user_blocks": _result([]),
                "user_connections": _result([]),
                "friend_requests": _result([]),
                "user_privacy_settings": _result([]),
            },
            rpcs={"get_workout_counts": _result([{"user_id": "user-2", "workout_count": 7}])},
        )

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await search_users(
                user_id="user-1", query="john", limit=20, offset=0,
                current_user=CURRENT_USER,
            )

        assert len(result["results"]) == 2
        assert result["results"][0]["name"] == "John Doe"
        assert result["results"][1]["name"] == "Johnny Smith"
        assert result["total_count"] == 2
        assert result["has_more"] is False
        # Workout counts come from the batch RPC, keyed per user.
        assert result["results"][0]["total_workouts"] == 7
        assert result["results"][1]["total_workouts"] == 0

    @pytest.mark.asyncio
    async def test_search_users_empty_query_returns_empty(self):
        """Test that empty query returns empty list."""
        from api.v1.social.users import search_users

        result = await search_users(
            user_id="user-1", query="", limit=20, offset=0, current_user=CURRENT_USER,
        )
        assert result["results"] == []
        assert result["total_count"] == 0

    @pytest.mark.asyncio
    async def test_search_users_with_whitespace_only(self):
        """Test that whitespace-only query returns empty list."""
        from api.v1.social.users import search_users

        result = await search_users(
            user_id="user-1", query="   ", limit=20, offset=0, current_user=CURRENT_USER,
        )
        assert result["results"] == []
        assert result["total_count"] == 0

    @pytest.mark.asyncio
    async def test_search_users_marks_current_user_and_puts_self_first(self):
        """Test that the current user is identifiable in their own search results.

        Retired behavior: this test used to assert the endpoint EXCLUDED the current
        user (`.neq("id", user_id)` was called and the result was empty). The
        endpoint deliberately includes the searching user now: it flags that row with
        `is_self=True` and moves it to the front of the results (see the "put self
        first if found" branch in search_users), so the app can show "you" in search.
        The guarantee this protects is the one the original test cared about — the
        current user is never returned as if they were a stranger to follow.
        """
        from api.v1.social.users import search_users

        mock_client = _supabase(
            tables={
                # Self deliberately returned LAST by the DB, to prove the handler reorders.
                "users": _result(
                    [
                        {"id": "user-2", "name": "Johnny Stranger", "username": None,
                         "avatar_url": None, "bio": None},
                        {"id": "user-1", "name": "John Me", "username": None,
                         "avatar_url": None, "bio": None},
                    ],
                    count=2,
                ),
                "user_blocks": _result([]),
                "user_connections": _result([]),
                "friend_requests": _result([]),
                "user_privacy_settings": _result([]),
            },
        )

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await search_users(
                user_id="user-1", query="john", limit=20, offset=0,
                current_user=CURRENT_USER,
            )

        results = result["results"]
        assert len(results) == 2
        assert results[0]["id"] == "user-1"
        assert results[0]["is_self"] is True
        assert results[1]["id"] == "user-2"
        assert results[1]["is_self"] is False


class TestGetFriendSuggestions:
    """Tests for get_friend_suggestions endpoint."""

    @pytest.mark.asyncio
    async def test_get_suggestions_with_mutual_friends(self):
        """Test suggestions based on mutual friends."""
        from api.v1.social.users import get_friend_suggestions

        mock_client = _supabase(
            tables={
                # Current user follows user-2 -> the mutual-friends path is taken.
                "user_connections": _result([{"following_id": "user-2"}]),
                "user_blocks": _result([]),
                "users": _result([
                    {"id": "user-3", "name": "Suggested Friend 1", "avatar_url": None, "bio": None},
                    {"id": "user-4", "name": "Suggested Friend 2", "avatar_url": None, "bio": None},
                ]),
                "user_privacy_settings": _result([]),
                "friend_requests": _result([]),
            },
            rpcs={
                "get_friend_suggestions_rpc": _result([
                    {"suggested_user_id": "user-3", "mutual_count": 3},
                    {"suggested_user_id": "user-4", "mutual_count": 1},
                ]),
                "get_workout_counts": _result([]),
            },
        )

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await get_friend_suggestions(
                user_id="user-1", limit=10, offset=0, current_user=CURRENT_USER,
            )

        suggestions = result["results"]
        assert len(suggestions) == 2
        assert all("mutual friend" in s["suggestion_reason"].lower() for s in suggestions)
        assert suggestions[0]["id"] == "user-3"
        assert suggestions[0]["mutual_friends_count"] == 3
        assert suggestions[1]["mutual_friends_count"] == 1

    @pytest.mark.asyncio
    async def test_get_suggestions_fallback_to_active_users(self):
        """Test fallback to active users when no mutual friends."""
        from api.v1.social.users import get_friend_suggestions

        mock_client = _supabase(
            tables={
                # Follows nobody -> mutual-friends path is skipped, fallback runs.
                "user_connections": _result([]),
                "user_blocks": _result([]),
                "users": _result([
                    {"id": "user-2", "name": "Active User", "avatar_url": None, "bio": None},
                ]),
                "user_privacy_settings": _result([]),
                "friend_requests": _result([]),
            },
            rpcs={"get_workout_counts": _result([])},
        )

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await get_friend_suggestions(
                user_id="user-1", limit=10, offset=0, current_user=CURRENT_USER,
            )

        suggestions = result["results"]
        assert len(suggestions) == 1
        assert "Active on" in suggestions[0]["suggestion_reason"]
        assert suggestions[0]["mutual_friends_count"] == 0


class TestGetUserProfile:
    """Tests for get_user_profile endpoint."""

    @pytest.mark.asyncio
    async def test_get_profile_success(self):
        """Test successful profile retrieval."""
        from api.v1.social.users import get_user_profile

        mock_client = _supabase(
            tables={
                "users": _result({
                    "id": "user-2",
                    "name": "John Doe",
                    "avatar_url": "https://example.com/avatar.jpg",
                    "bio": "Fitness lover",
                }),
                "user_connections": _result([]),
                "friend_requests": _result([]),
                "user_privacy_settings": _result([]),
                "workout_logs": _result([], count=42),
            },
        )

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            result = await get_user_profile(
                target_user_id="user-2", user_id="user-1", current_user=CURRENT_USER,
            )

        assert result.id == "user-2"
        assert result.name == "John Doe"
        assert result.bio == "Fitness lover"
        assert result.total_workouts == 42
        assert result.is_following is False
        assert result.is_follower is False
        assert result.has_pending_request is False

    @pytest.mark.asyncio
    async def test_get_profile_not_found(self):
        """Test 404 for non-existent user."""
        from api.v1.social.users import get_user_profile

        mock_client = _supabase(tables={"users": _result(None)})

        with patch("api.v1.social.users.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await get_user_profile(
                    target_user_id="nonexistent", user_id="user-1",
                    current_user=CURRENT_USER,
                )

        assert exc_info.value.status_code == 404
