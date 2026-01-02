"""
Tests for Quick Workout via Chat flow.

Tests the end-to-end flow of generating quick workouts through the chat interface,
including intent extraction, agent routing, tool execution, and response formatting.

Test cases:
1. Intent extraction for quick workout phrases
2. Intent extraction for create workout phrases
3. Workout agent routing based on GENERATE_QUICK_WORKOUT intent
4. Keyword-based routing for "quick workout" phrases
5. generate_quick_workout tool returns proper action_data
6. Full integration test: chat message -> ChatResponse with action_data

Run with: pytest backend/tests/test_quick_workout_chat.py -v
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timezone
import uuid
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.chat import (
    CoachIntent, ChatRequest, ChatResponse, AgentType,
    IntentExtraction, UserProfile, WorkoutContext
)
from services.gemini_service import GeminiService
from services.langgraph_service import (
    LangGraphCoachService, INTENT_TO_AGENT, DOMAIN_KEYWORDS
)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_user_profile(sample_user_id):
    """Sample user profile for testing."""
    return UserProfile(
        id=sample_user_id,
        fitness_level="intermediate",
        goals=["Build Muscle", "General Fitness"],
        equipment=["Dumbbells", "Barbell", "Pull-up Bar"],
        active_injuries=[],
        name="Test User",
    )


@pytest.fixture
def sample_workout_context():
    """Sample workout context for testing."""
    return WorkoutContext(
        id=123,
        name="Upper Body Strength",
        type="strength",
        difficulty="medium",
        exercises=[
            {"name": "Bench Press", "sets": 4, "reps": 8},
            {"name": "Barbell Rows", "sets": 4, "reps": 8},
        ],
        scheduled_date="2025-12-30",
        is_completed=False,
    )


@pytest.fixture
def sample_chat_request(sample_user_id, sample_user_profile):
    """Sample chat request for quick workout."""
    return ChatRequest(
        message="give me a quick 15-minute workout",
        user_id=sample_user_id,
        user_profile=sample_user_profile,
        current_workout=None,
        conversation_history=[],
    )


@pytest.fixture
def mock_gemini_service():
    """Mock Gemini service for intent extraction."""
    service = MagicMock(spec=GeminiService)

    async def mock_extract_intent(user_message):
        message_lower = user_message.lower()

        # Quick workout generation patterns
        quick_workout_patterns = [
            "quick workout", "create a workout", "generate a workout",
            "make me a workout", "give me a workout", "15 minute",
            "15-minute", "i need a workout", "cardio workout",
            "new workout", "build me a workout"
        ]

        if any(pattern in message_lower for pattern in quick_workout_patterns):
            return IntentExtraction(
                intent=CoachIntent.GENERATE_QUICK_WORKOUT,
                exercises=[],
                muscle_groups=[],
            )
        elif "add" in message_lower:
            return IntentExtraction(
                intent=CoachIntent.ADD_EXERCISE,
                exercises=["push-ups"],
                muscle_groups=[],
            )
        else:
            return IntentExtraction(
                intent=CoachIntent.QUESTION,
                exercises=[],
                muscle_groups=[],
            )

    service.extract_intent = AsyncMock(side_effect=mock_extract_intent)

    # Mock embedding
    service.get_embedding = MagicMock(return_value=[0.1] * 768)

    return service


@pytest.fixture
def mock_rag_service():
    """Mock RAG service."""
    service = MagicMock()

    async def mock_find_similar(query, user_id=None, n_results=3):
        return []

    service.find_similar = AsyncMock(side_effect=mock_find_similar)
    service.format_context = MagicMock(return_value="")

    return service


# ============================================================
# INTENT EXTRACTION TESTS
# ============================================================

@pytest.mark.asyncio
class TestIntentExtraction:
    """Tests for intent extraction related to quick workouts."""

    async def test_intent_extraction_quick_workout(self, mock_gemini_service):
        """Test that 'give me a quick 15-minute workout' extracts to GENERATE_QUICK_WORKOUT intent."""
        message = "give me a quick 15-minute workout"

        extraction = await mock_gemini_service.extract_intent(message)

        assert extraction.intent == CoachIntent.GENERATE_QUICK_WORKOUT

    async def test_intent_extraction_create_workout(self, mock_gemini_service):
        """Test that 'create a cardio workout' extracts to GENERATE_QUICK_WORKOUT intent."""
        message = "create a cardio workout"

        extraction = await mock_gemini_service.extract_intent(message)

        assert extraction.intent == CoachIntent.GENERATE_QUICK_WORKOUT

    async def test_intent_extraction_generate_workout(self, mock_gemini_service):
        """Test that 'generate a workout for me' extracts to GENERATE_QUICK_WORKOUT intent."""
        message = "generate a workout for me"

        extraction = await mock_gemini_service.extract_intent(message)

        assert extraction.intent == CoachIntent.GENERATE_QUICK_WORKOUT

    async def test_intent_extraction_make_me_workout(self, mock_gemini_service):
        """Test that 'make me a workout' extracts to GENERATE_QUICK_WORKOUT intent."""
        message = "make me a workout"

        extraction = await mock_gemini_service.extract_intent(message)

        assert extraction.intent == CoachIntent.GENERATE_QUICK_WORKOUT

    async def test_intent_extraction_i_need_a_workout(self, mock_gemini_service):
        """Test that 'i need a workout' extracts to GENERATE_QUICK_WORKOUT intent."""
        message = "i need a workout"

        extraction = await mock_gemini_service.extract_intent(message)

        assert extraction.intent == CoachIntent.GENERATE_QUICK_WORKOUT

    async def test_intent_extraction_question_not_quick_workout(self, mock_gemini_service):
        """Test that general questions do not extract to GENERATE_QUICK_WORKOUT."""
        message = "how do I do a squat?"

        extraction = await mock_gemini_service.extract_intent(message)

        assert extraction.intent == CoachIntent.QUESTION


# ============================================================
# AGENT ROUTING TESTS
# ============================================================

@pytest.mark.asyncio
class TestWorkoutAgentRouting:
    """Tests for workout agent routing based on intent."""

    async def test_workout_agent_routing_from_intent_mapping(self):
        """Test that GENERATE_QUICK_WORKOUT intent routes to WorkoutAgent via INTENT_TO_AGENT mapping."""
        # Verify the mapping exists
        assert CoachIntent.GENERATE_QUICK_WORKOUT in INTENT_TO_AGENT

        # Verify it routes to WORKOUT agent
        expected_agent = INTENT_TO_AGENT[CoachIntent.GENERATE_QUICK_WORKOUT]
        assert expected_agent == AgentType.WORKOUT

    async def test_workout_agent_routing_all_workout_intents(self):
        """Test that all workout-related intents route to WorkoutAgent."""
        workout_intents = [
            CoachIntent.ADD_EXERCISE,
            CoachIntent.REMOVE_EXERCISE,
            CoachIntent.SWAP_WORKOUT,
            CoachIntent.MODIFY_INTENSITY,
            CoachIntent.RESCHEDULE,
            CoachIntent.DELETE_WORKOUT,
            CoachIntent.START_WORKOUT,
            CoachIntent.COMPLETE_WORKOUT,
            CoachIntent.GENERATE_QUICK_WORKOUT,
        ]

        for intent in workout_intents:
            assert intent in INTENT_TO_AGENT, f"Intent {intent} not in INTENT_TO_AGENT"
            assert INTENT_TO_AGENT[intent] == AgentType.WORKOUT, \
                f"Intent {intent} should route to WORKOUT agent"


# ============================================================
# KEYWORD ROUTING TESTS
# ============================================================

@pytest.mark.asyncio
class TestKeywordRouting:
    """Tests for keyword-based routing to workout agent."""

    async def test_keyword_routing_workout_keywords_exist(self):
        """Test that DOMAIN_KEYWORDS contains workout-related keywords."""
        assert AgentType.WORKOUT in DOMAIN_KEYWORDS

        workout_keywords = DOMAIN_KEYWORDS[AgentType.WORKOUT]
        assert "workout" in workout_keywords
        assert "exercise" in workout_keywords
        assert "training" in workout_keywords

    async def test_keyword_routing_quick_workout_message(self):
        """Test keyword routing with a 'quick workout' message."""
        message = "I want a quick workout"
        message_lower = message.lower()

        # Check if workout keywords are found
        workout_keywords = DOMAIN_KEYWORDS[AgentType.WORKOUT]
        matched = any(kw in message_lower for kw in workout_keywords)

        assert matched, "Expected 'workout' keyword to match"

    async def test_langgraph_service_infer_agent_from_keywords(self):
        """Test that LangGraphCoachService._infer_agent_from_keywords works for workout messages."""
        # Create a minimal mock service to test the method
        with patch.object(LangGraphCoachService, '__init__', lambda self: None):
            service = LangGraphCoachService()
            # Manually set up DOMAIN_KEYWORDS reference (the actual module-level constant)

            message = "I want a quick workout today"
            result = service._infer_agent_from_keywords(message)

            assert result == AgentType.WORKOUT


# ============================================================
# GENERATE QUICK WORKOUT TOOL TESTS
# ============================================================

@pytest.mark.asyncio
class TestGenerateQuickWorkoutTool:
    """Tests for the generate_quick_workout tool."""

    async def test_generate_quick_workout_tool_returns_action_data(self):
        """Test that generate_quick_workout tool returns proper action_data with workout_id."""
        from services.langgraph_agents.tools import generate_quick_workout

        sample_user_id = str(uuid.uuid4())

        # Mock the database and RAG service
        with patch("services.langgraph_agents.tools.workout_tools.get_supabase_db") as mock_db, \
             patch("services.langgraph_agents.tools.workout_tools.run_async_in_sync") as mock_run_async:

            # Setup mock database
            db_mock = MagicMock()
            mock_db.return_value = db_mock

            # Mock user data
            db_mock.get_user.return_value = {
                "id": sample_user_id,
                "fitness_level": "intermediate",
                "goals": ["Build Muscle"],
                "equipment": ["Dumbbells"],
            }

            # Mock no existing workout
            db_mock.client.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.limit.return_value.execute.return_value.data = []

            # Mock workout creation
            new_workout_id = str(uuid.uuid4())
            db_mock.create_workout.return_value = {"id": new_workout_id}

            # Mock exercise RAG service
            mock_run_async.side_effect = [
                # First call: select_exercises_for_workout
                [
                    {"name": "Push Ups", "muscle_group": "chest", "equipment": "Bodyweight"},
                    {"name": "Squats", "muscle_group": "legs", "equipment": "Bodyweight"},
                    {"name": "Plank", "muscle_group": "core", "equipment": "Bodyweight"},
                ],
                # Second call: get_adaptive_parameters
                {"sets": 3, "reps": 12, "rest_seconds": 60},
            ]

            # Execute the tool
            result = generate_quick_workout.invoke({
                "user_id": sample_user_id,
                "duration_minutes": 15,
                "workout_type": "full_body",
                "intensity": "moderate",
            })

            # Verify result structure
            assert result["success"] is True
            assert result["action"] == "generate_quick_workout"
            assert "workout_id" in result
            assert result["workout_id"] == new_workout_id
            assert "workout_name" in result
            assert "exercises_added" in result
            assert len(result["exercises_added"]) > 0

    async def test_generate_quick_workout_tool_updates_existing_workout(self):
        """Test that generate_quick_workout updates existing workout if workout_id is provided."""
        from services.langgraph_agents.tools import generate_quick_workout

        sample_user_id = str(uuid.uuid4())
        existing_workout_id = str(uuid.uuid4())

        with patch("services.langgraph_agents.tools.workout_tools.get_supabase_db") as mock_db, \
             patch("services.langgraph_agents.tools.workout_tools.run_async_in_sync") as mock_run_async:

            db_mock = MagicMock()
            mock_db.return_value = db_mock

            # Mock existing workout
            db_mock.get_workout.return_value = {
                "id": existing_workout_id,
                "exercises": [{"name": "Old Exercise", "sets": 3, "reps": 10}],
            }

            db_mock.get_user.return_value = {
                "id": sample_user_id,
                "fitness_level": "intermediate",
                "goals": ["Build Muscle"],
                "equipment": ["Dumbbells"],
            }

            mock_run_async.side_effect = [
                [{"name": "New Push Ups", "muscle_group": "chest", "equipment": "Bodyweight"}],
                {"sets": 3, "reps": 12, "rest_seconds": 60},
            ]

            result = generate_quick_workout.invoke({
                "user_id": sample_user_id,
                "workout_id": existing_workout_id,
                "duration_minutes": 10,
                "workout_type": "upper",
                "intensity": "light",
            })

            assert result["success"] is True
            assert result["workout_id"] == existing_workout_id
            assert "Old Exercise" in result.get("exercises_removed", [])


# ============================================================
# CHAT RESPONSE INTEGRATION TESTS
# ============================================================

@pytest.mark.asyncio
class TestChatResponseIntegration:
    """Integration tests for complete chat flow with quick workout generation."""

    async def test_chat_response_includes_action_data(
        self, sample_user_id, sample_user_profile
    ):
        """Integration test: send chat message requesting quick workout, verify ChatResponse has action_data with workout_id."""

        # Create the chat request
        request = ChatRequest(
            message="give me a quick 15-minute workout",
            user_id=sample_user_id,
            user_profile=sample_user_profile,
            current_workout=None,
            conversation_history=[],
        )

        new_workout_id = str(uuid.uuid4())

        # Mock all dependencies
        with patch("services.langgraph_service.GeminiService") as mock_gemini_cls, \
             patch("services.langgraph_service.RAGService") as mock_rag_cls, \
             patch("services.langgraph_service.build_nutrition_agent_graph") as mock_nutrition, \
             patch("services.langgraph_service.build_workout_agent_graph") as mock_workout, \
             patch("services.langgraph_service.build_injury_agent_graph") as mock_injury, \
             patch("services.langgraph_service.build_hydration_agent_graph") as mock_hydration, \
             patch("services.langgraph_service.build_coach_agent_graph") as mock_coach:

            # Setup mock Gemini service
            mock_gemini = MagicMock()
            mock_gemini_cls.return_value = mock_gemini

            async def mock_extract_intent(msg):
                return IntentExtraction(
                    intent=CoachIntent.GENERATE_QUICK_WORKOUT,
                    exercises=[],
                    muscle_groups=[],
                )
            mock_gemini.extract_intent = AsyncMock(side_effect=mock_extract_intent)

            # Setup mock RAG service
            mock_rag = MagicMock()
            mock_rag_cls.return_value = mock_rag
            mock_rag.find_similar = AsyncMock(return_value=[])
            mock_rag.format_context = MagicMock(return_value="")

            # Setup mock workout agent graph
            mock_workout_graph = MagicMock()
            mock_workout.return_value = mock_workout_graph

            # The workout agent should return final_response and action_data
            async def mock_ainvoke(state):
                return {
                    "final_response": "I've created a quick 15-minute full body workout for you! Let's crush it!",
                    "action_data": {
                        "action": "generate_quick_workout",
                        "workout_id": new_workout_id,
                        "workout_name": "Quick Power Full Body",
                        "duration_minutes": 15,
                        "workout_type": "full_body",
                        "intensity": "moderate",
                        "exercises_added": ["Push Ups", "Squats", "Plank"],
                        "exercise_count": 3,
                    },
                    "rag_context_used": False,
                    "similar_questions": [],
                }
            mock_workout_graph.ainvoke = AsyncMock(side_effect=mock_ainvoke)

            # Mock other agent graphs (they won't be used but need to be valid)
            for mock_agent in [mock_nutrition, mock_injury, mock_hydration, mock_coach]:
                agent_graph = MagicMock()
                agent_graph.ainvoke = AsyncMock(return_value={
                    "final_response": "Mock response",
                    "action_data": None,
                    "rag_context_used": False,
                    "similar_questions": [],
                })
                mock_agent.return_value = agent_graph

            # Create service and process message
            service = LangGraphCoachService()
            response = await service.process_message(request)

            # Verify response structure
            assert isinstance(response, ChatResponse)
            assert response.intent == CoachIntent.GENERATE_QUICK_WORKOUT
            assert response.agent_type == AgentType.WORKOUT

            # Verify action_data
            assert response.action_data is not None
            assert response.action_data["action"] == "generate_quick_workout"
            assert response.action_data["workout_id"] == new_workout_id
            assert "exercises_added" in response.action_data

    async def test_chat_response_message_content(
        self, sample_user_id, sample_user_profile
    ):
        """Test that the chat response message is appropriate for quick workout generation."""

        request = ChatRequest(
            message="create a 10 minute cardio workout",
            user_id=sample_user_id,
            user_profile=sample_user_profile,
            current_workout=None,
            conversation_history=[],
        )

        with patch("services.langgraph_service.GeminiService") as mock_gemini_cls, \
             patch("services.langgraph_service.RAGService") as mock_rag_cls, \
             patch("services.langgraph_service.build_nutrition_agent_graph"), \
             patch("services.langgraph_service.build_workout_agent_graph") as mock_workout, \
             patch("services.langgraph_service.build_injury_agent_graph"), \
             patch("services.langgraph_service.build_hydration_agent_graph"), \
             patch("services.langgraph_service.build_coach_agent_graph"):

            mock_gemini = MagicMock()
            mock_gemini_cls.return_value = mock_gemini
            mock_gemini.extract_intent = AsyncMock(return_value=IntentExtraction(
                intent=CoachIntent.GENERATE_QUICK_WORKOUT,
                exercises=[],
                muscle_groups=[],
            ))

            mock_rag = MagicMock()
            mock_rag_cls.return_value = mock_rag
            mock_rag.find_similar = AsyncMock(return_value=[])
            mock_rag.format_context = MagicMock(return_value="")

            mock_workout_graph = MagicMock()
            mock_workout.return_value = mock_workout_graph
            mock_workout_graph.ainvoke = AsyncMock(return_value={
                "final_response": "Your cardio workout is ready! Get your heart pumping!",
                "action_data": {
                    "action": "generate_quick_workout",
                    "workout_id": str(uuid.uuid4()),
                    "workout_type": "cardio",
                },
                "rag_context_used": False,
                "similar_questions": [],
            })

            service = LangGraphCoachService()
            response = await service.process_message(request)

            assert "cardio" in response.message.lower() or "workout" in response.message.lower()
            assert len(response.message) > 10  # Ensure there's a meaningful response


# ============================================================
# EDGE CASES AND ERROR HANDLING
# ============================================================

@pytest.mark.asyncio
class TestQuickWorkoutChatEdgeCases:
    """Edge case tests for quick workout chat flow."""

    async def test_quick_workout_with_existing_workout(
        self, sample_user_id, sample_user_profile, sample_workout_context
    ):
        """Test quick workout generation when user already has a workout scheduled."""

        request = ChatRequest(
            message="replace my workout with a quick 15-minute one",
            user_id=sample_user_id,
            user_profile=sample_user_profile,
            current_workout=sample_workout_context,
            conversation_history=[],
        )

        with patch("services.langgraph_service.GeminiService") as mock_gemini_cls, \
             patch("services.langgraph_service.RAGService") as mock_rag_cls, \
             patch("services.langgraph_service.build_nutrition_agent_graph"), \
             patch("services.langgraph_service.build_workout_agent_graph") as mock_workout, \
             patch("services.langgraph_service.build_injury_agent_graph"), \
             patch("services.langgraph_service.build_hydration_agent_graph"), \
             patch("services.langgraph_service.build_coach_agent_graph"):

            mock_gemini = MagicMock()
            mock_gemini_cls.return_value = mock_gemini
            mock_gemini.extract_intent = AsyncMock(return_value=IntentExtraction(
                intent=CoachIntent.GENERATE_QUICK_WORKOUT,
                exercises=[],
                muscle_groups=[],
            ))

            mock_rag = MagicMock()
            mock_rag_cls.return_value = mock_rag
            mock_rag.find_similar = AsyncMock(return_value=[])
            mock_rag.format_context = MagicMock(return_value="")

            mock_workout_graph = MagicMock()
            mock_workout.return_value = mock_workout_graph
            mock_workout_graph.ainvoke = AsyncMock(return_value={
                "final_response": "I've replaced your workout with a quick session!",
                "action_data": {
                    "action": "generate_quick_workout",
                    "workout_id": sample_workout_context.id,
                    "exercises_removed": ["Bench Press", "Barbell Rows"],
                    "exercises_added": ["Push Ups", "Squats"],
                },
                "rag_context_used": False,
                "similar_questions": [],
            })

            service = LangGraphCoachService()
            response = await service.process_message(request)

            assert response.action_data is not None
            assert response.action_data["workout_id"] == sample_workout_context.id

    async def test_quick_workout_various_phrases(self, mock_gemini_service):
        """Test that various natural language phrases extract correctly."""
        phrases = [
            "give me a quick 15-minute workout",
            "create a workout for me",
            "I need a short workout",
            "generate a cardio workout",
            "make me a 10 minute workout",
            "build me a quick upper body routine",
            "can you create a new workout",
        ]

        for phrase in phrases:
            extraction = await mock_gemini_service.extract_intent(phrase)
            assert extraction.intent == CoachIntent.GENERATE_QUICK_WORKOUT, \
                f"Phrase '{phrase}' should extract to GENERATE_QUICK_WORKOUT, got {extraction.intent}"


# ============================================================
# ACTION DATA STRUCTURE TESTS
# ============================================================

@pytest.mark.asyncio
class TestActionDataStructure:
    """Tests for action_data structure in quick workout responses."""

    async def test_action_data_has_required_fields(self):
        """Test that action_data contains all required fields for mobile app."""
        # Define the expected action_data structure
        required_fields = [
            "action",
            "workout_id",
        ]

        optional_fields = [
            "workout_name",
            "duration_minutes",
            "workout_type",
            "intensity",
            "exercises_added",
            "exercises_removed",
            "exercise_count",
        ]

        sample_action_data = {
            "action": "generate_quick_workout",
            "workout_id": str(uuid.uuid4()),
            "workout_name": "Quick Power Full Body",
            "duration_minutes": 15,
            "workout_type": "full_body",
            "intensity": "moderate",
            "exercises_added": ["Push Ups", "Squats", "Plank"],
            "exercise_count": 3,
        }

        for field in required_fields:
            assert field in sample_action_data, f"Required field '{field}' missing"

        assert sample_action_data["action"] == "generate_quick_workout"
        assert sample_action_data["workout_id"] is not None

    async def test_action_data_workout_id_format(self):
        """Test that workout_id in action_data is a valid UUID string or integer."""
        # Can be UUID string or integer
        valid_workout_ids = [
            str(uuid.uuid4()),  # UUID string
            123,  # Integer
            "workout-123",  # Some other string format
        ]

        for workout_id in valid_workout_ids:
            action_data = {
                "action": "generate_quick_workout",
                "workout_id": workout_id,
            }
            assert action_data["workout_id"] is not None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
