"""
Tests for social reactions API endpoints.

Tests cover:
- POST /reactions - Add reaction
- DELETE /reactions/{activity_id} - Remove reaction
- GET /reactions/{activity_id} - Get reactions summary
"""
import pytest
from unittest.mock import MagicMock, patch
from fastapi import BackgroundTasks, HTTPException
from starlette.requests import Request

from models.social import ActivityReactionCreate, ReactionType


def make_request(method: str = "POST", path: str = "/reactions") -> Request:
    """Build a real starlette Request for direct endpoint calls.

    add_reaction / remove_reaction are wrapped in @limiter.limit(...) (slowapi),
    whose wrapper asserts the `request` argument is a real
    starlette.requests.Request and reads request["path"], request.client and
    request.state. Calling the endpoint function with only its business args
    (as these tests used to) blows up inside slowapi before any product code
    runs. `state` must be in the scope because slowapi writes
    request.state.view_rate_limit / _rate_limiting_complete.
    """
    return Request(
        {
            "type": "http",
            "http_version": "1.1",
            "method": method,
            "scheme": "http",
            "server": ("testserver", 80),
            "path": path,
            "raw_path": path.encode(),
            "query_string": b"",
            "root_path": "",
            "headers": [],
            "client": ("127.0.0.1", 12345),
            "state": {},
        }
    )


class TestAddReaction:
    """Tests for add_reaction endpoint."""

    @pytest.mark.asyncio
    async def test_add_reaction_new_success(self):
        """Test successful new reaction creation."""
        from api.v1.social.reactions import add_reaction

        mock_client = MagicMock()
        # Mock no existing reaction
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
        # Mock successful insert
        mock_client.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": "reaction-1",
            "activity_id": "activity-1",
            "user_id": "user-1",
            "reaction_type": "cheer",
            "created_at": "2024-01-15T00:00:00Z",
        }]

        reaction_create = ActivityReactionCreate(
            activity_id="activity-1",
            reaction_type=ReactionType.CHEER,
        )

        with patch("api.v1.social.reactions.get_supabase_client", return_value=mock_client):
            with patch("api.v1.social.reactions.get_social_rag_service"):
                result = await add_reaction(
                    request=make_request(),
                    user_id="user-1",
                    reaction=reaction_create,
                    background_tasks=BackgroundTasks(),
                    current_user={"id": "user-1"},
                )

        assert result.id == "reaction-1"
        assert result.reaction_type == "cheer"

    @pytest.mark.asyncio
    async def test_add_reaction_update_existing(self):
        """Test updating existing reaction.

        Reaction type updated: this test used ReactionType.LOVE. There is no
        such member — the enum is CHEER/FIRE/STRONG/CLAP/HEART, and the DB
        column has only ever allowed 'cheer','fire','strong','clap','heart'
        (migrations/028_social_features.sql), so 'love' could never round-trip.
        Same guarantee protected: when a reaction already exists for
        (activity, user), add_reaction UPDATEs it (no second insert) and
        returns the new reaction_type.
        """
        from api.v1.social.reactions import add_reaction

        mock_client = MagicMock()
        # Mock existing reaction
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": "existing-reaction"
        }]
        # Mock successful update
        mock_client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": "existing-reaction",
            "activity_id": "activity-1",
            "user_id": "user-1",
            "reaction_type": "heart",
            "created_at": "2024-01-15T00:00:00Z",
        }]

        reaction_create = ActivityReactionCreate(
            activity_id="activity-1",
            reaction_type=ReactionType.HEART,
        )

        with patch("api.v1.social.reactions.get_supabase_client", return_value=mock_client):
            with patch("api.v1.social.reactions.get_social_rag_service"):
                result = await add_reaction(
                    request=make_request(),
                    user_id="user-1",
                    reaction=reaction_create,
                    background_tasks=BackgroundTasks(),
                    current_user={"id": "user-1"},
                )

        assert result.id == "existing-reaction"
        assert result.reaction_type == "heart"
        # Update path taken, not insert.
        mock_client.table.return_value.update.assert_called_once_with(
            {"reaction_type": "heart"}
        )
        mock_client.table.return_value.insert.assert_not_called()


class TestRemoveReaction:
    """Tests for remove_reaction endpoint."""

    @pytest.mark.asyncio
    async def test_remove_reaction_success(self):
        """Test successful reaction removal."""
        from api.v1.social.reactions import remove_reaction

        mock_client = MagicMock()
        # Mock finding reaction
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{"id": "reaction-1"}]
        # Mock successful delete
        mock_client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{"id": "reaction-1"}]

        with patch("api.v1.social.reactions.get_supabase_client", return_value=mock_client):
            with patch("api.v1.social.reactions.get_social_rag_service"):
                result = await remove_reaction(
                    request=make_request("DELETE", "/reactions/activity-1"),
                    user_id="user-1",
                    activity_id="activity-1",
                    background_tasks=BackgroundTasks(),
                    current_user={"id": "user-1"},
                )

        assert result["message"] == "Reaction removed successfully"

    @pytest.mark.asyncio
    async def test_remove_reaction_not_found(self):
        """Test remove non-existent reaction raises 404."""
        from api.v1.social.reactions import remove_reaction

        mock_client = MagicMock()
        # Mock no reaction found
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.reactions.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await remove_reaction(
                    request=make_request("DELETE", "/reactions/activity-1"),
                    user_id="user-1",
                    activity_id="activity-1",
                    background_tasks=BackgroundTasks(),
                    current_user={"id": "user-1"},
                )

        assert exc_info.value.status_code == 404


class TestGetReactions:
    """Tests for get_reactions endpoint."""

    @pytest.mark.asyncio
    async def test_get_reactions_success(self):
        """Test successful reactions summary retrieval."""
        from api.v1.social.reactions import get_reactions

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"reaction_type": "cheer", "user_id": "user-1"},
            {"reaction_type": "cheer", "user_id": "user-2"},
            {"reaction_type": "love", "user_id": "user-3"},
        ]

        with patch("api.v1.social.reactions.get_supabase_client", return_value=mock_client):
            result = await get_reactions("activity-1")

        assert result.total_count == 3
        assert result.reactions_by_type["cheer"] == 2
        assert result.reactions_by_type["love"] == 1

    @pytest.mark.asyncio
    async def test_get_reactions_with_user_reaction(self):
        """Test reactions summary includes user's reaction."""
        from api.v1.social.reactions import get_reactions

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"reaction_type": "cheer", "user_id": "user-1"},
            {"reaction_type": "love", "user_id": "user-2"},
        ]

        with patch("api.v1.social.reactions.get_supabase_client", return_value=mock_client):
            result = await get_reactions("activity-1", user_id="user-1")

        assert result.user_reaction == ReactionType.CHEER

    @pytest.mark.asyncio
    async def test_get_reactions_empty(self):
        """Test empty reactions."""
        from api.v1.social.reactions import get_reactions

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.reactions.get_supabase_client", return_value=mock_client):
            result = await get_reactions("activity-1")

        assert result.total_count == 0
        assert result.reactions_by_type == {}
