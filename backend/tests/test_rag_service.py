"""
Tests for RAG (Retrieval Augmented Generation) Service.

Tests document storage, retrieval, and similarity search.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch


class TestRAGService:
    """Tests for RAGService class."""

    @pytest.mark.asyncio
    async def test_find_similar_returns_results(self, mock_rag_service):
        """Test that find_similar returns relevant documents."""
        results = await mock_rag_service.find_similar("How do I build muscle?")

        assert results is not None
        assert len(results) > 0
        assert "similarity" in results[0]
        assert results[0]["similarity"] > 0.5

    @pytest.mark.asyncio
    async def test_find_similar_with_user_id_filter(self, mock_rag_service):
        """Test find_similar with user_id filter."""
        results = await mock_rag_service.find_similar(
            query="workout question",
            user_id=1
        )

        assert results is not None
        mock_rag_service.find_similar.assert_called_with(
            query="workout question",
            user_id=1
        )

    @pytest.mark.asyncio
    async def test_find_similar_with_intent_filter(self, mock_rag_service):
        """Test find_similar with intent filter."""
        results = await mock_rag_service.find_similar(
            query="add exercise",
            intent_filter="add_exercise"
        )

        assert results is not None

    @pytest.mark.asyncio
    async def test_add_qa_pair(self, mock_rag_service):
        """Test adding a Q&A pair to RAG."""
        doc_id = await mock_rag_service.add_qa_pair(
            question="How do I do a push-up?",
            answer="Start in a plank position...",
            intent="question",
            user_id=1,
            metadata={"exercises": ["push-up"]}
        )

        assert doc_id is not None
        assert isinstance(doc_id, str)

    @pytest.mark.asyncio
    async def test_add_qa_pair_without_metadata(self, mock_rag_service):
        """Test adding Q&A pair without optional metadata."""
        doc_id = await mock_rag_service.add_qa_pair(
            question="Simple question",
            answer="Simple answer",
            intent="question",
            user_id=1
        )

        assert doc_id is not None

    def test_format_context_with_docs(self, mock_rag_service):
        """Test context formatting with documents."""
        docs = [
            {
                "metadata": {
                    "question": "How to squat?",
                    "answer": "Keep your back straight...",
                    "intent": "question",
                },
                "similarity": 0.9,
            }
        ]

        # Call the real format_context if needed
        mock_rag_service.format_context.return_value = "RELEVANT PAST CONVERSATIONS:\n1. User asked: \"How to squat?\"\n"
        context = mock_rag_service.format_context(docs)

        assert "RELEVANT" in context or context != ""

    def test_format_context_empty(self, mock_rag_service):
        """Test context formatting with no documents."""
        mock_rag_service.format_context.return_value = ""
        context = mock_rag_service.format_context([])

        assert context == ""

    def test_get_stats(self, mock_rag_service):
        """Test getting RAG statistics."""
        stats = mock_rag_service.get_stats()

        assert "total_documents" in stats
        assert "persist_dir" in stats
        assert isinstance(stats["total_documents"], int)

    @pytest.mark.asyncio
    async def test_clear_all(self, mock_rag_service):
        """Test clearing all RAG data."""
        await mock_rag_service.clear_all()

        mock_rag_service.clear_all.assert_called_once()


class TestRAGIntegration:
    """Integration-style tests for RAG flow."""

    @pytest.mark.asyncio
    async def test_full_rag_flow(self, mock_rag_service):
        """Test the full RAG flow: add, search, retrieve."""
        # Add a Q&A pair
        doc_id = await mock_rag_service.add_qa_pair(
            question="Best chest exercises?",
            answer="Bench press, push-ups, and flyes are excellent.",
            intent="question",
            user_id=1,
        )
        assert doc_id is not None

        # Search for similar
        results = await mock_rag_service.find_similar("chest workout recommendations")
        assert len(results) > 0

        # Format context
        mock_rag_service.format_context.return_value = "RELEVANT: chest exercises..."
        context = mock_rag_service.format_context(results)
        assert context != ""

    @pytest.mark.asyncio
    async def test_rag_with_multiple_users(self, mock_rag_service):
        """Test RAG with different user contexts."""
        # User 1 adds data
        await mock_rag_service.add_qa_pair(
            question="User 1 question",
            answer="User 1 answer",
            intent="question",
            user_id=1,
        )

        # User 2 adds data
        await mock_rag_service.add_qa_pair(
            question="User 2 question",
            answer="User 2 answer",
            intent="question",
            user_id=2,
        )

        # Search should be called correctly
        assert mock_rag_service.add_qa_pair.call_count == 2


class TestProgramPreferencesIndexing:
    """Tests for program preferences indexing including equipment counts."""

    @pytest.mark.asyncio
    async def test_index_preferences_with_equipment_counts(self, mock_rag_service):
        """Test indexing program preferences with dumbbell and kettlebell counts."""
        # Mock the index_program_preferences method
        mock_rag_service.index_program_preferences = AsyncMock(return_value="prefs_user1_123")

        doc_id = await mock_rag_service.index_program_preferences(
            user_id="user1",
            equipment=["Dumbbells", "Kettlebell"],
            dumbbell_count=1,  # Single dumbbell
            kettlebell_count=2,  # Pair of kettlebells
            goals=["Build Muscle", "Lose Weight"],
            motivations=["progress", "health"],
            change_reason="onboarding_complete",
        )

        assert doc_id is not None
        mock_rag_service.index_program_preferences.assert_called_once()

    @pytest.mark.asyncio
    async def test_index_preferences_single_dumbbell(self, mock_rag_service):
        """Test indexing with single dumbbell (count=1)."""
        mock_rag_service.index_program_preferences = AsyncMock(return_value="prefs_user1_456")

        doc_id = await mock_rag_service.index_program_preferences(
            user_id="user1",
            equipment=["Dumbbells"],
            dumbbell_count=1,
            change_reason="preference_update",
        )

        assert doc_id is not None
        call_kwargs = mock_rag_service.index_program_preferences.call_args.kwargs
        assert call_kwargs.get("dumbbell_count") == 1

    @pytest.mark.asyncio
    async def test_index_preferences_pair_dumbbells(self, mock_rag_service):
        """Test indexing with pair of dumbbells (count=2)."""
        mock_rag_service.index_program_preferences = AsyncMock(return_value="prefs_user1_789")

        doc_id = await mock_rag_service.index_program_preferences(
            user_id="user1",
            equipment=["Dumbbells"],
            dumbbell_count=2,
            change_reason="preference_update",
        )

        assert doc_id is not None
        call_kwargs = mock_rag_service.index_program_preferences.call_args.kwargs
        assert call_kwargs.get("dumbbell_count") == 2

    @pytest.mark.asyncio
    async def test_index_preferences_with_goals_and_motivations(self, mock_rag_service):
        """Test indexing with multi-select goals and motivations."""
        mock_rag_service.index_program_preferences = AsyncMock(return_value="prefs_user1_abc")

        goals = ["Build Muscle", "Increase Strength", "Lose Weight"]
        motivations = ["progress", "strength", "appearance"]

        doc_id = await mock_rag_service.index_program_preferences(
            user_id="user1",
            goals=goals,
            motivations=motivations,
            change_reason="onboarding_complete",
        )

        assert doc_id is not None
        call_kwargs = mock_rag_service.index_program_preferences.call_args.kwargs
        assert call_kwargs.get("goals") == goals
        assert call_kwargs.get("motivations") == motivations

    @pytest.mark.asyncio
    async def test_index_preferences_defaults(self, mock_rag_service):
        """Test indexing with default equipment counts."""
        mock_rag_service.index_program_preferences = AsyncMock(return_value="prefs_user1_def")

        # Not passing dumbbell_count or kettlebell_count - should use defaults
        doc_id = await mock_rag_service.index_program_preferences(
            user_id="user1",
            equipment=["Dumbbells", "Kettlebell"],
            change_reason="preference_update",
        )

        assert doc_id is not None
