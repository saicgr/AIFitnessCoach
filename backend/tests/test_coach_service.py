"""
Tests for Coach Service.

Tests the main orchestration layer that coordinates OpenAI and RAG.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from models.chat import (
    ChatRequest, ChatResponse, IntentExtraction, CoachIntent,
    UserProfile, WorkoutContext
)
from services.coach_service import CoachService


class TestCoachService:
    """Tests for CoachService class."""

    @pytest.mark.asyncio
    async def test_process_message_basic(
        self, mock_coach_service, sample_chat_request
    ):
        """Test basic message processing."""
        response = await mock_coach_service.process_message(sample_chat_request)

        assert response is not None
        assert isinstance(response, ChatResponse)
        assert response.message is not None
        assert response.intent is not None

    @pytest.mark.asyncio
    async def test_process_message_extracts_intent(
        self, mock_coach_service, sample_chat_request
    ):
        """Test that intent is extracted from message."""
        sample_chat_request.message = "add push-ups to my workout"
        response = await mock_coach_service.process_message(sample_chat_request)

        assert response.intent == CoachIntent.ADD_EXERCISE

    @pytest.mark.asyncio
    async def test_process_message_uses_rag(
        self, mock_coach_service, sample_chat_request, mock_rag_service
    ):
        """Test that RAG is used for context."""
        response = await mock_coach_service.process_message(sample_chat_request)

        # RAG should have been queried
        mock_rag_service.find_similar.assert_called_once()

    @pytest.mark.asyncio
    async def test_process_message_stores_qa(
        self, mock_coach_service, sample_chat_request, mock_rag_service
    ):
        """Test that Q&A is stored for future RAG."""
        response = await mock_coach_service.process_message(sample_chat_request)

        # Q&A should be stored
        mock_rag_service.add_qa_pair.assert_called_once()

    @pytest.mark.asyncio
    async def test_process_message_with_add_exercise_action(
        self, mock_coach_service, sample_chat_request
    ):
        """Test action data for add_exercise intent."""
        sample_chat_request.message = "add pull-ups to my workout"
        response = await mock_coach_service.process_message(sample_chat_request)

        assert response.action_data is not None
        assert response.action_data["action"] == "add_exercise"
        assert "workout_id" in response.action_data

    @pytest.mark.asyncio
    async def test_process_message_with_remove_exercise_action(
        self, mock_coach_service, sample_chat_request
    ):
        """Test action data for remove_exercise intent."""
        sample_chat_request.message = "remove squats from the workout"
        response = await mock_coach_service.process_message(sample_chat_request)

        assert response.action_data is not None
        assert response.action_data["action"] == "remove_exercise"

    @pytest.mark.asyncio
    async def test_process_message_with_swap_workout_action(
        self, mock_coach_service, sample_chat_request
    ):
        """Test action data for swap_workout intent."""
        sample_chat_request.message = "I want a different workout today"
        response = await mock_coach_service.process_message(sample_chat_request)

        assert response.action_data is not None
        assert response.action_data["action"] == "swap_workout"

    @pytest.mark.asyncio
    async def test_process_message_with_injury_report(
        self, mock_coach_service, sample_chat_request
    ):
        """Test action data for injury report."""
        sample_chat_request.message = "my shoulder hurts a lot"
        response = await mock_coach_service.process_message(sample_chat_request)

        assert response.action_data is not None
        assert response.action_data["action"] == "report_injury"
        assert response.action_data["body_part"] == "shoulder"

    @pytest.mark.asyncio
    async def test_process_message_question_no_action(
        self, mock_coach_service, sample_chat_request
    ):
        """Test that questions don't produce action data."""
        sample_chat_request.message = "what's the best rep range for hypertrophy?"
        response = await mock_coach_service.process_message(sample_chat_request)

        assert response.intent == CoachIntent.QUESTION
        # Questions don't trigger actions
        assert response.action_data is None

    @pytest.mark.asyncio
    async def test_process_message_without_workout(
        self, mock_coach_service, sample_user_profile
    ):
        """Test processing when no current workout is set."""
        request = ChatRequest(
            message="How do I do a deadlift?",
            user_id=1,
            user_profile=sample_user_profile,
            current_workout=None,
            conversation_history=[],
        )

        response = await mock_coach_service.process_message(request)

        assert response is not None
        assert response.action_data is None  # No workout to modify


class TestCoachServiceContextBuilding:
    """Tests for context building logic."""

    def test_build_context_with_user_profile(self, mock_coach_service, sample_user_profile):
        """Test context building with user profile."""
        context = mock_coach_service._build_context(
            user_profile=sample_user_profile,
            current_workout=None,
            rag_context="",
        )

        assert "intermediate" in context.lower()
        assert "build muscle" in context.lower()

    def test_build_context_with_workout(
        self, mock_coach_service, sample_user_profile, sample_workout_context
    ):
        """Test context building with workout."""
        context = mock_coach_service._build_context(
            user_profile=sample_user_profile,
            current_workout=sample_workout_context,
            rag_context="",
        )

        assert "Upper Body Strength" in context
        assert "Bench Press" in context

    def test_build_context_with_injuries(self, mock_coach_service, sample_user_profile):
        """Test context building includes injuries."""
        context = mock_coach_service._build_context(
            user_profile=sample_user_profile,
            current_workout=None,
            rag_context="",
        )

        assert "shoulder" in context.lower()

    def test_build_context_with_rag(self, mock_coach_service, sample_user_profile):
        """Test context building includes RAG context."""
        rag_context = "RELEVANT PAST CONVERSATIONS:\n1. User asked about chest exercises"

        context = mock_coach_service._build_context(
            user_profile=sample_user_profile,
            current_workout=None,
            rag_context=rag_context,
        )

        assert "RELEVANT PAST CONVERSATIONS" in context


class TestCoachServiceActionData:
    """Tests for action data building logic."""

    def test_build_action_data_add_exercise(
        self, mock_coach_service, sample_workout_context
    ):
        """Test action data for add exercise."""
        intent = IntentExtraction(
            intent=CoachIntent.ADD_EXERCISE,
            exercises=["pull-ups"],
            muscle_groups=["back"],
        )

        action = mock_coach_service._build_action_data(
            intent=intent,
            current_workout=sample_workout_context,
            user_message="add pull-ups",
        )

        assert action["action"] == "add_exercise"
        assert action["workout_id"] == sample_workout_context.id
        assert "pull-ups" in action["exercise_names"]

    def test_build_action_data_no_workout(self, mock_coach_service):
        """Test action data when no workout exists."""
        intent = IntentExtraction(intent=CoachIntent.ADD_EXERCISE)

        action = mock_coach_service._build_action_data(
            intent=intent,
            current_workout=None,
            user_message="add something",
        )

        assert action is None

    def test_build_action_data_question_intent(
        self, mock_coach_service, sample_workout_context
    ):
        """Test that question intent produces no action."""
        intent = IntentExtraction(intent=CoachIntent.QUESTION)

        action = mock_coach_service._build_action_data(
            intent=intent,
            current_workout=sample_workout_context,
            user_message="what is the best exercise?",
        )

        assert action is None
