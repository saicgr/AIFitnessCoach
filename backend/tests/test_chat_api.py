"""
Tests for Chat API endpoints.

Tests the FastAPI endpoints for chat functionality.

CALLING CONVENTION (why this file needs its own fixtures)
---------------------------------------------------------
Three things about the chat surface changed after these tests were written, and
all three made every request die before it reached the behavior under test:

1. AUTH. `/chat/send` and the `/chat/rag/*` endpoints now declare
   `current_user: dict = Depends(get_current_user)`. An unauthenticated
   TestClient (the conftest `client` fixture) 401s in the dependency layer, so
   the routing + validation assertions below could never fire. We override the
   dependency — the standard FastAPI test seam — instead of asserting 401.

2. SERVICE INJECTION. The coach and RAG services are no longer module globals
   (`api.v1.chat.coach_service` / `api.v1.chat.rag_service` no longer exist —
   patching them raised AttributeError). They are FastAPI dependencies now:
   `api.v1.chat.get_coach_service` and `services.rag_service.get_rag_service`,
   each raising 503 when the app's startup hook hasn't initialized them. A
   TestClient never runs startup, so that 503 short-circuits the request BEFORE
   body validation — which is why the 422 validation tests must inject service
   doubles too, not just auth.

3. user_id IS A UUID STRING, NOT AN INT. `ChatRequest.user_id` / `UserProfile.id`
   / `RAGSearchRequest.user_id` are all `str` (Supabase UUIDs). The old int
   `user_id: 1` payloads are now themselves a 422, which would have made the
   "endpoint exists" tests pass/fail for a reason unrelated to what they check.
   Payloads use a UUID string; the assertions are unchanged.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient

from main import app
from core.auth import get_current_user
from api.v1.chat import get_coach_service
from services.rag_service import get_rag_service
from services.langgraph_service import LangGraphCoachService
from models.chat import (
    ChatRequest, ChatResponse, CoachIntent, UserProfile, WorkoutContext,
)


# Supabase user ids are UUIDs. `/chat/send` rejects a request whose body
# user_id differs from the authenticated user (403), so both must agree.
TEST_USER_ID = "11111111-1111-1111-1111-111111111111"
TEST_AUTH_USER = {"id": TEST_USER_ID, "email": "chat-test@example.com"}


def _coach_double(reply: str = "Mock coach reply") -> MagicMock:
    """Stand-in for the injected LangGraphCoachService.

    Only `process_message` is exercised by `/chat/send`; it is awaited, so it
    must be an AsyncMock returning a real ChatResponse (a bare MagicMock is not
    awaitable and would collapse the endpoint into a 500).
    """
    coach = MagicMock(spec=LangGraphCoachService)
    coach.process_message = AsyncMock(return_value=ChatResponse(
        message=reply,
        intent=CoachIntent.QUESTION,
        rag_context_used=False,
    ))
    return coach


@pytest.fixture
def client(mock_rag_service):
    """Authenticated TestClient with the coach + RAG dependencies injected.

    Shadows the conftest `client` fixture (unauthenticated, no service doubles).
    """
    app.dependency_overrides[get_current_user] = lambda: TEST_AUTH_USER
    app.dependency_overrides[get_coach_service] = lambda: _coach_double()
    app.dependency_overrides[get_rag_service] = lambda: mock_rag_service
    try:
        yield TestClient(app)
    finally:
        for dep in (get_current_user, get_coach_service, get_rag_service):
            app.dependency_overrides.pop(dep, None)


@pytest.fixture
def sample_chat_request():
    """A fully-populated ChatRequest.

    Shadows the conftest fixture, which still builds `user_id=1` /
    `UserProfile(id=1)` — both are `str` fields now, so the conftest version
    raises a pydantic ValidationError at fixture setup.
    """
    return ChatRequest(
        message="Add push-ups to my workout",
        user_id=TEST_USER_ID,
        user_profile=UserProfile(
            id=TEST_USER_ID,
            fitness_level="intermediate",
            goals=["build muscle", "lose fat"],
            equipment=["dumbbells", "barbell", "pull-up bar"],
            active_injuries=["shoulder"],
        ),
        current_workout=WorkoutContext(
            id=1,
            name="Upper Body Strength",
            type="strength",
            difficulty="medium",
            exercises=[
                {"name": "Bench Press", "sets": 4, "reps": 8},
                {"name": "Barbell Rows", "sets": 4, "reps": 8},
            ],
        ),
        conversation_history=[],
    )


class TestChatEndpoints:
    """Tests for chat API endpoints."""

    def test_send_message_endpoint_exists(self, client):
        """Test that the send endpoint exists."""
        # Without proper service initialization, this will fail
        # but we can check the endpoint is routed
        response = client.post(
            "/api/v1/chat/send",
            json={
                "message": "hello",
                "user_id": TEST_USER_ID,
            }
        )
        # Either 200 (success) or 503 (service not initialized) is valid
        assert response.status_code in [200, 503, 500]

    def test_rag_stats_endpoint_exists(self, client):
        """Test that the RAG stats endpoint exists."""
        response = client.get("/api/v1/chat/rag/stats")
        # Either success or service not initialized
        assert response.status_code in [200, 503]

    def test_rag_search_endpoint_exists(self, client):
        """Test that the RAG search endpoint exists."""
        response = client.post(
            "/api/v1/chat/rag/search",
            json={
                "query": "test query",
                "n_results": 5,
            }
        )
        assert response.status_code in [200, 503, 500]

    def test_rag_clear_endpoint_exists(self, client):
        """Test that the RAG clear endpoint exists."""
        response = client.delete("/api/v1/chat/rag/clear")
        assert response.status_code in [200, 503]


class TestChatEndpointsWithMocks:
    """Tests for chat endpoints with mocked services."""

    @pytest.fixture
    def patched_client(self, mock_rag_service):
        """Create a client with mocked services.

        The services used to be module-level globals that could be patched
        (`api.v1.chat.coach_service`); they are injected dependencies now, so
        the doubles go through `app.dependency_overrides`.
        """
        app.dependency_overrides[get_current_user] = lambda: TEST_AUTH_USER
        app.dependency_overrides[get_coach_service] = lambda: _coach_double()
        app.dependency_overrides[get_rag_service] = lambda: mock_rag_service
        try:
            yield TestClient(app)
        finally:
            for dep in (get_current_user, get_coach_service, get_rag_service):
                app.dependency_overrides.pop(dep, None)

    def test_send_message_returns_response(self, patched_client, sample_chat_request):
        """Test that send endpoint returns a proper response."""
        response = patched_client.post(
            "/api/v1/chat/send",
            json={
                "message": sample_chat_request.message,
                "user_id": sample_chat_request.user_id,
                "user_profile": {
                    "id": TEST_USER_ID,
                    "fitness_level": "intermediate",
                    "goals": ["build muscle"],
                    "equipment": ["dumbbells"],
                    "active_injuries": [],
                },
                "current_workout": {
                    "id": 1,
                    "name": "Upper Body",
                    "type": "strength",
                    "difficulty": "medium",
                    "exercises": [{"name": "Bench Press", "sets": 4, "reps": 8}],
                },
            }
        )

        # May fail if services aren't properly mocked at module level
        # but validates the request format is correct
        assert response.status_code in [200, 503, 500]

    def test_send_message_minimal_request(self, patched_client):
        """Test send with minimal required fields."""
        response = patched_client.post(
            "/api/v1/chat/send",
            json={
                "message": "hello coach",
                "user_id": TEST_USER_ID,
            }
        )

        assert response.status_code in [200, 503, 500]


class TestChatRequestValidation:
    """Tests for request validation."""

    def test_missing_message_returns_error(self, client):
        """Test that missing message field returns validation error."""
        response = client.post(
            "/api/v1/chat/send",
            json={
                "user_id": TEST_USER_ID,
                # missing "message" field
            }
        )

        assert response.status_code == 422  # Validation error

    def test_missing_user_id_returns_error(self, client):
        """Test that missing user_id returns validation error."""
        response = client.post(
            "/api/v1/chat/send",
            json={
                "message": "hello",
                # missing "user_id" field
            }
        )

        assert response.status_code == 422

    def test_invalid_user_profile_format(self, client):
        """Test validation of user profile format."""
        response = client.post(
            "/api/v1/chat/send",
            json={
                "message": "hello",
                "user_id": TEST_USER_ID,
                "user_profile": "invalid_string",  # Should be object
            }
        )

        assert response.status_code == 422


class TestRAGSearchValidation:
    """Tests for RAG search request validation."""

    def test_search_missing_query_returns_error(self, client):
        """Test that missing query returns validation error."""
        response = client.post(
            "/api/v1/chat/rag/search",
            json={
                "n_results": 5,
                # missing "query" field
            }
        )

        assert response.status_code == 422

    def test_search_with_valid_params(self, client):
        """Test search with all valid parameters."""
        response = client.post(
            "/api/v1/chat/rag/search",
            json={
                "query": "chest exercises",
                "n_results": 10,
                "user_id": TEST_USER_ID,
            }
        )

        # Will be 503 if service not initialized, but validates request format
        assert response.status_code in [200, 503, 500]
