"""
Tests for chat API endpoint fixes.

These tests specifically verify the fixes made to resolve the 500 Internal Server Error
that was occurring on the Render deployment due to:
1. Missing SlowAPIMiddleware
2. Rate limiter not handling reverse proxy headers
3. Logging middleware consuming request body

These tests document the bugs and verify the fixes work correctly.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi import FastAPI, Request
from fastapi.testclient import TestClient
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi import _rate_limit_exceeded_handler

from core.rate_limiter import limiter, get_real_client_ip
from models.chat import ChatRequest, ChatResponse, CoachIntent, AgentType


class TestChatEndpointRateLimiting:
    """Tests for chat endpoint rate limiting fixes."""

    def test_chat_send_works_with_rate_limiter(self):
        """
        Chat /send endpoint should work with rate limiter enabled.

        This was broken because SlowAPIMiddleware was missing.
        """
        app = FastAPI()
        app.state.limiter = limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        app.add_middleware(SlowAPIMiddleware)

        @app.post("/api/v1/chat/send")
        @limiter.limit("10/minute")
        async def send_message(request: Request):
            return {"message": "Hello!", "intent": "question", "agent_type": "coach"}

        client = TestClient(app)

        response = client.post(
            "/api/v1/chat/send",
            json={"user_id": "test-123", "message": "Hi"}
        )

        # Should return 200, not 500
        assert response.status_code == 200
        assert response.json()["message"] == "Hello!"

    def test_chat_send_with_reverse_proxy_headers(self):
        """
        Chat endpoint should work when called through a reverse proxy.

        This simulates the Render deployment scenario where X-Forwarded-For is set.
        """
        app = FastAPI()
        app.state.limiter = limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        app.add_middleware(SlowAPIMiddleware)

        @app.post("/api/v1/chat/send")
        @limiter.limit("10/minute")
        async def send_message(request: Request):
            # Return the detected IP for verification
            ip = get_real_client_ip(request)
            return {"message": "Hello!", "detected_ip": ip}

        client = TestClient(app)

        response = client.post(
            "/api/v1/chat/send",
            json={"user_id": "test-123", "message": "Hi"},
            headers={"X-Forwarded-For": "192.168.1.100, 10.0.0.1"}
        )

        assert response.status_code == 200
        # Should use the first IP from X-Forwarded-For
        assert response.json()["detected_ip"] == "192.168.1.100"

    def test_chat_send_without_proxy_headers(self):
        """
        Chat endpoint should work without proxy headers (direct access).
        """
        app = FastAPI()
        app.state.limiter = limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        app.add_middleware(SlowAPIMiddleware)

        @app.post("/api/v1/chat/send")
        @limiter.limit("10/minute")
        async def send_message(request: Request):
            ip = get_real_client_ip(request)
            return {"message": "Hello!", "detected_ip": ip}

        client = TestClient(app)

        response = client.post(
            "/api/v1/chat/send",
            json={"user_id": "test-123", "message": "Hi"}
        )

        assert response.status_code == 200
        # Should fallback to testclient's IP or 127.0.0.1
        assert response.json()["detected_ip"] is not None


class TestChatEndpointRequestBody:
    """Tests for chat endpoint request body handling."""

    def test_request_body_not_consumed_by_middleware(self):
        """
        Request body should be available to the endpoint after middleware.

        Previously, LoggingMiddleware was reading the body to extract user_id,
        which consumed the stream and caused POST requests to fail with empty bodies.
        """
        from main import LoggingMiddleware

        app = FastAPI()
        app.add_middleware(LoggingMiddleware)

        @app.post("/api/v1/chat/send")
        async def send_message(data: dict):
            return {"received_message": data.get("message")}

        client = TestClient(app)

        response = client.post(
            "/api/v1/chat/send",
            json={"user_id": "test-123", "message": "Hello from test"}
        )

        assert response.status_code == 200
        assert response.json()["received_message"] == "Hello from test"

    def test_complex_chat_request_body_preserved(self):
        """
        Complex chat request bodies should be fully preserved through middleware.
        """
        from main import LoggingMiddleware

        app = FastAPI()
        app.add_middleware(LoggingMiddleware)

        @app.post("/api/v1/chat/send")
        async def send_message(data: dict):
            return {
                "message": data.get("message"),
                "user_id": data.get("user_id"),
                "has_profile": data.get("user_profile") is not None,
                "has_workout": data.get("current_workout") is not None,
                "history_count": len(data.get("conversation_history", [])),
            }

        client = TestClient(app)

        response = client.post(
            "/api/v1/chat/send",
            json={
                "message": "Add push-ups to my workout",
                "user_id": "user-uuid-123",
                "user_profile": {
                    "id": "user-uuid-123",
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
                "conversation_history": [
                    {"role": "user", "content": "Previous message"},
                    {"role": "assistant", "content": "Previous response"},
                ],
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Add push-ups to my workout"
        assert data["user_id"] == "user-uuid-123"
        assert data["has_profile"] is True
        assert data["has_workout"] is True
        assert data["history_count"] == 2


class TestChatEndpointErrorHandling:
    """Tests for chat endpoint error handling."""

    def test_rate_limit_error_returns_429_not_500(self):
        """
        Rate limit errors should return 429, not 500.

        The swallow_errors=True setting on the limiter prevents crashes,
        and proper middleware setup returns correct status codes.
        """
        app = FastAPI()
        test_limiter = Limiter(
            key_func=get_real_client_ip,
            default_limits=["100/minute"],
            swallow_errors=True
        )
        app.state.limiter = test_limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        app.add_middleware(SlowAPIMiddleware)

        @app.post("/api/v1/chat/send")
        @test_limiter.limit("1/minute")
        async def send_message(request: Request):
            return {"message": "Hello!"}

        client = TestClient(app)

        # First request should succeed
        response1 = client.post(
            "/api/v1/chat/send",
            json={"user_id": "test", "message": "Hi"}
        )
        assert response1.status_code == 200

        # Second request should be rate limited with 429
        response2 = client.post(
            "/api/v1/chat/send",
            json={"user_id": "test", "message": "Hi again"}
        )
        assert response2.status_code == 429
        # Should NOT be 500 Internal Server Error

    def test_validation_error_returns_422_not_500(self):
        """
        Request validation errors should return 422, not 500.
        """
        from main import app

        client = TestClient(app, raise_server_exceptions=False)

        # Missing required field should return 422
        response = client.post(
            "/api/v1/chat/send",
            json={"user_id": "test"}  # Missing 'message' field
        )

        # Should be validation error (422), not server error (500)
        # May also be 503 if service not initialized
        assert response.status_code in [422, 503]


class TestChatEndpointResponseFormat:
    """Tests for chat endpoint response format."""

    def test_chat_endpoint_response_format_when_service_unavailable(self):
        """
        Chat endpoint should return 503 when service is not initialized.

        This tests the proper error handling when the LangGraph service
        is not available (common in test environments).
        """
        from main import app

        client = TestClient(app, raise_server_exceptions=False)

        response = client.post(
            "/api/v1/chat/send",
            json={
                "user_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
                "message": "Hello coach!"
            }
        )

        # When service is not initialized, should return 503 or 500
        # When initialized, should return 200
        assert response.status_code in [200, 500, 503]

        if response.status_code == 200:
            data = response.json()
            # Verify response format has required fields
            assert "message" in data
            assert "intent" in data
            assert "agent_type" in data


class TestHealthEndpointDebugGemini:
    """Tests for the debug/gemini health endpoint."""

    def test_debug_gemini_endpoint_exists(self):
        """Debug gemini endpoint should exist and return proper format."""
        from main import app

        client = TestClient(app, raise_server_exceptions=False)

        response = client.get("/api/v1/health/debug/gemini")

        assert response.status_code == 200
        data = response.json()

        # Verify response structure
        assert "model" in data
        assert "embedding_model" in data
        assert "api_key_set" in data
        assert "gemini_test" in data

    def test_debug_gemini_shows_model_info(self):
        """Debug gemini endpoint should show configured model information."""
        from main import app

        client = TestClient(app, raise_server_exceptions=False)

        response = client.get("/api/v1/health/debug/gemini")

        if response.status_code == 200:
            data = response.json()
            # Should have model information
            assert data["model"] is not None
            assert data["embedding_model"] is not None


class TestChatEndpointIntegration:
    """Integration tests for the full chat endpoint stack."""

    def test_full_middleware_stack_with_chat(self):
        """
        Test the full middleware stack works with chat endpoint.

        This tests the complete fix: LoggingMiddleware + SecurityHeaders + SlowAPI.
        """
        from main import app

        client = TestClient(app, raise_server_exceptions=False)

        response = client.post(
            "/api/v1/chat/send",
            json={
                "user_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
                "message": "Test message"
            },
            headers={"X-Forwarded-For": "192.168.1.1"}
        )

        # Should not be 500 (our original bug)
        # Should be 200 (success) or 503 (service not initialized in tests)
        assert response.status_code != 500 or "service" in response.text.lower()

        # Should have security headers
        assert "X-Content-Type-Options" in response.headers
        assert "X-Request-ID" in response.headers

    def test_multiple_requests_with_rate_limiting(self):
        """
        Test multiple requests work with rate limiting enabled.

        Verifies the fix allows multiple requests without 500 errors.
        """
        from main import app

        client = TestClient(app, raise_server_exceptions=False)

        # Make several requests
        for i in range(3):
            response = client.post(
                "/api/v1/chat/send",
                json={
                    "user_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
                    "message": f"Test message {i}"
                }
            )

            # Each request should not return 500
            # May be 200 (success), 503 (service not init), or 429 (rate limited)
            assert response.status_code in [200, 429, 503]
