"""
Tests for social reactions API endpoints.

Tests cover:
- POST /reactions - Add reaction
- DELETE /reactions/{activity_id} - Remove reaction
- GET /reactions/{activity_id} - Get reactions summary
"""
import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException

from models.social import ActivityReactionCreate, ReactionType


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
                result = await add_reaction("user-1", reaction_create)

        assert result.id == "reaction-1"
        assert result.reaction_type == "cheer"

    @pytest.mark.asyncio
    async def test_add_reaction_update_existing(self):
        """Test updating existing reaction."""
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
            "reaction_type": "love",
            "created_at": "2024-01-15T00:00:00Z",
        }]

        reaction_create = ActivityReactionCreate(
            activity_id="activity-1",
            reaction_type=ReactionType.LOVE,
        )

        with patch("api.v1.social.reactions.get_supabase_client", return_value=mock_client):
            with patch("api.v1.social.reactions.get_social_rag_service"):
                result = await add_reaction("user-1", reaction_create)

        assert result.reaction_type == "love"


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
                result = await remove_reaction("user-1", "activity-1")

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
                await remove_reaction("user-1", "activity-1")

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
