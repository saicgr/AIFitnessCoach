"""
Pytest configuration and fixtures for backend tests.

These fixtures provide mock services and test data that can be used
across all test files.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from httpx import AsyncClient, ASGITransport

import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from services.gemini_service import GeminiService
from services.rag_service import RAGService
from services.coach_service import CoachService
from models.chat import (
    ChatRequest, ChatResponse, IntentExtraction, CoachIntent,
    UserProfile, WorkoutContext
)


# ============ Mock Services ============

@pytest.fixture
def mock_gemini_service():
    """Mock Gemini service that returns predictable responses."""
    service = MagicMock(spec=GeminiService)

    # Mock chat method
    async def mock_chat(user_message, system_prompt=None, conversation_history=None):
        return f"Mock response to: {user_message[:50]}"
    service.chat = AsyncMock(side_effect=mock_chat)

    # Mock intent extraction
    async def mock_extract_intent(user_message):
        # Determine intent based on keywords
        message_lower = user_message.lower()
        if "add" in message_lower:
            intent = CoachIntent.ADD_EXERCISE
            exercises = ["push-ups"]
        elif "remove" in message_lower:
            intent = CoachIntent.REMOVE_EXERCISE
            exercises = ["squats"]
        elif "swap" in message_lower or "different" in message_lower:
            intent = CoachIntent.SWAP_WORKOUT
            exercises = []
        elif "easier" in message_lower or "harder" in message_lower:
            intent = CoachIntent.MODIFY_INTENSITY
            exercises = []
        elif "hurt" in message_lower or "pain" in message_lower:
            intent = CoachIntent.REPORT_INJURY
            exercises = []
        else:
            intent = CoachIntent.QUESTION
            exercises = []

        return IntentExtraction(
            intent=intent,
            exercises=exercises,
            muscle_groups=[],
            modification="easier" if "easier" in message_lower else None,
            body_part="shoulder" if "shoulder" in message_lower else None,
        )
    service.extract_intent = AsyncMock(side_effect=mock_extract_intent)

    # Mock embedding (768 dimensions for Gemini text-embedding-004)
    def mock_get_embedding(text):
        return [0.1] * 768
    service.get_embedding = MagicMock(side_effect=mock_get_embedding)

    # Mock system prompt
    service.get_coach_system_prompt = MagicMock(return_value="You are a fitness coach.")

    return service


@pytest.fixture
def mock_rag_service(mock_gemini_service):
    """Mock RAG service."""
    service = MagicMock(spec=RAGService)

    # Mock find_similar
    async def mock_find_similar(query, n_results=5, user_id=None, intent_filter=None):
        return [
            {
                "id": "test-doc-1",
                "document": "Q: How do I build muscle?\nA: Focus on progressive overload.",
                "metadata": {
                    "question": "How do I build muscle?",
                    "answer": "Focus on progressive overload and eating enough protein.",
                    "intent": "question",
                    "user_id": 1,
                },
                "similarity": 0.85,
            }
        ]
    service.find_similar = AsyncMock(side_effect=mock_find_similar)

    # Mock add_qa_pair
    async def mock_add_qa_pair(question, answer, intent, user_id, metadata=None):
        return "mock-doc-id-123"
    service.add_qa_pair = AsyncMock(side_effect=mock_add_qa_pair)

    # Mock format_context
    service.format_context = MagicMock(return_value="RELEVANT PAST CONVERSATIONS:\n1. User asked: \"test\"\n")

    # Mock get_stats
    service.get_stats = MagicMock(return_value={"total_documents": 10, "persist_dir": "/tmp/test"})

    # Mock clear_all
    service.clear_all = AsyncMock()

    return service


@pytest.fixture
def mock_coach_service(mock_gemini_service, mock_rag_service):
    """Mock coach service using mock dependencies."""
    return CoachService(mock_gemini_service, mock_rag_service)


# ============ Test Data ============

@pytest.fixture
def sample_user_profile():
    """Sample user profile for testing."""
    return UserProfile(
        id=1,
        fitness_level="intermediate",
        goals=["build muscle", "lose fat"],
        equipment=["dumbbells", "barbell", "pull-up bar"],
        active_injuries=["shoulder"],
    )


@pytest.fixture
def sample_workout_context():
    """Sample workout context for testing."""
    return WorkoutContext(
        id=1,
        name="Upper Body Strength",
        type="strength",
        difficulty="medium",
        exercises=[
            {"name": "Bench Press", "sets": 4, "reps": 8},
            {"name": "Barbell Rows", "sets": 4, "reps": 8},
            {"name": "Overhead Press", "sets": 3, "reps": 10},
        ],
    )


@pytest.fixture
def sample_chat_request(sample_user_profile, sample_workout_context):
    """Sample chat request for testing."""
    return ChatRequest(
        message="Add push-ups to my workout",
        user_id=1,
        user_profile=sample_user_profile,
        current_workout=sample_workout_context,
        conversation_history=[],
    )


# ============ FastAPI Test Client ============

@pytest.fixture
def client():
    """Synchronous test client for FastAPI."""
    return TestClient(app)


@pytest.fixture
async def async_client():
    """Async test client for FastAPI."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


# ============ Environment Setup ============

@pytest.fixture(autouse=True)
def mock_env(monkeypatch):
    """Mock environment variables for testing."""
    monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
    monkeypatch.setenv("GEMINI_MODEL", "gemini-2.5-flash")
    monkeypatch.setenv("USE_MOCK_DATA", "true")


# ============ Async Cleanup ============

@pytest.fixture(scope="session", autouse=True)
def suppress_async_warnings():
    """
    Session-scoped fixture to suppress async cleanup warnings from
    aiohttp/Google Genai client during test teardown.
    """
    import warnings

    warnings.filterwarnings(
        "ignore",
        message="coroutine .* was never awaited",
        category=RuntimeWarning
    )
    warnings.filterwarnings(
        "ignore",
        message=".*Task was destroyed but it is pending.*",
        category=RuntimeWarning
    )

    yield
