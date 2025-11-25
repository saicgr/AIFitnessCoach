"""
Tests for OpenAI Service.

Tests intent extraction, chat responses, and embeddings.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from models.chat import IntentExtraction, CoachIntent


class TestOpenAIService:
    """Tests for OpenAIService class."""

    @pytest.mark.asyncio
    async def test_extract_intent_add_exercise(self, mock_openai_service):
        """Test intent extraction for adding exercise."""
        result = await mock_openai_service.extract_intent("add push-ups to my workout")

        assert result.intent == CoachIntent.ADD_EXERCISE
        assert "push-ups" in result.exercises

    @pytest.mark.asyncio
    async def test_extract_intent_remove_exercise(self, mock_openai_service):
        """Test intent extraction for removing exercise."""
        result = await mock_openai_service.extract_intent("remove squats please")

        assert result.intent == CoachIntent.REMOVE_EXERCISE

    @pytest.mark.asyncio
    async def test_extract_intent_swap_workout(self, mock_openai_service):
        """Test intent extraction for swapping workout."""
        result = await mock_openai_service.extract_intent("I want a different workout today")

        assert result.intent == CoachIntent.SWAP_WORKOUT

    @pytest.mark.asyncio
    async def test_extract_intent_modify_intensity(self, mock_openai_service):
        """Test intent extraction for modifying intensity."""
        result = await mock_openai_service.extract_intent("make it easier please")

        assert result.intent == CoachIntent.MODIFY_INTENSITY
        assert result.modification == "easier"

    @pytest.mark.asyncio
    async def test_extract_intent_report_injury(self, mock_openai_service):
        """Test intent extraction for reporting injury."""
        result = await mock_openai_service.extract_intent("my shoulder hurts")

        assert result.intent == CoachIntent.REPORT_INJURY
        assert result.body_part == "shoulder"

    @pytest.mark.asyncio
    async def test_extract_intent_question(self, mock_openai_service):
        """Test intent extraction for general question."""
        result = await mock_openai_service.extract_intent("what's the best way to warm up?")

        assert result.intent == CoachIntent.QUESTION

    @pytest.mark.asyncio
    async def test_chat_returns_response(self, mock_openai_service):
        """Test that chat returns a response."""
        response = await mock_openai_service.chat("Hello, coach!")

        assert response is not None
        assert isinstance(response, str)
        assert "Mock response" in response

    @pytest.mark.asyncio
    async def test_chat_with_system_prompt(self, mock_openai_service):
        """Test chat with system prompt."""
        response = await mock_openai_service.chat(
            "Help me with my form",
            system_prompt="You are an expert fitness coach."
        )

        assert response is not None
        mock_openai_service.chat.assert_called_once()

    @pytest.mark.asyncio
    async def test_chat_with_conversation_history(self, mock_openai_service):
        """Test chat with conversation history."""
        history = [
            {"role": "user", "content": "I want to build muscle"},
            {"role": "assistant", "content": "Great goal! Let's start with compound exercises."},
        ]

        response = await mock_openai_service.chat(
            "What exercises should I do?",
            conversation_history=history
        )

        assert response is not None

    @pytest.mark.asyncio
    async def test_get_embedding(self, mock_openai_service):
        """Test embedding generation."""
        embedding = await mock_openai_service.get_embedding("test text")

        assert embedding is not None
        assert isinstance(embedding, list)
        assert len(embedding) == 1536  # ada-002 dimension

    def test_get_coach_system_prompt(self, mock_openai_service):
        """Test system prompt generation."""
        prompt = mock_openai_service.get_coach_system_prompt("User context here")

        assert prompt is not None
        assert isinstance(prompt, str)


class TestIntentExtraction:
    """Tests for IntentExtraction model."""

    def test_intent_extraction_defaults(self):
        """Test IntentExtraction with defaults."""
        extraction = IntentExtraction(intent=CoachIntent.QUESTION)

        assert extraction.intent == CoachIntent.QUESTION
        assert extraction.exercises == []
        assert extraction.muscle_groups == []
        assert extraction.modification is None
        assert extraction.body_part is None

    def test_intent_extraction_full(self):
        """Test IntentExtraction with all fields."""
        extraction = IntentExtraction(
            intent=CoachIntent.ADD_EXERCISE,
            exercises=["bench press", "rows"],
            muscle_groups=["chest", "back"],
            modification="harder",
            body_part="shoulder",
        )

        assert extraction.intent == CoachIntent.ADD_EXERCISE
        assert len(extraction.exercises) == 2
        assert len(extraction.muscle_groups) == 2
        assert extraction.modification == "harder"
        assert extraction.body_part == "shoulder"
