"""
Tests for Onboarding API endpoints.

These tests verify that the HTTP layer works correctly, including:
- Rate limiters accept the correct parameter types
- Request bodies are properly parsed
- Response models are correctly serialized

This is SEPARATE from test_onboarding.py which tests the LangGraph service logic.
These tests catch issues like the rate limiter parameter naming bug.
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock


class TestOnboardingEndpoints:
    """Tests for onboarding API endpoints at the HTTP layer."""

    def test_parse_response_endpoint_accepts_request(self, client):
        """
        Test that /parse-response endpoint accepts valid request body.

        This catches the rate limiter bug where the parameter was named
        'http_request' instead of 'request', causing:
        'parameter 'request' must be an instance of starlette.requests.Request'
        """
        response = client.post(
            "/api/v1/onboarding/parse-response",
            json={
                "user_id": "test-user-123",
                "message": "I'm 25 years old",
                "current_data": {"name": "TestUser"}
            }
        )

        # Should NOT get 500 with rate limiter error
        # Can be 200 (success) or 503 (service unavailable if AI fails)
        assert response.status_code != 500 or "rate" not in response.text.lower(), \
            f"Rate limiter parameter error: {response.text}"

        # Endpoint should exist (not 404)
        assert response.status_code != 404, "Endpoint not found"

    def test_validate_data_endpoint_accepts_request(self, client):
        """Test that /validate-data endpoint accepts valid request body."""
        response = client.post(
            "/api/v1/onboarding/validate-data",
            json={
                "user_id": "test-user-123",
                "data": {
                    "name": "TestUser",
                    "age": 25,
                    "goals": ["Build Muscle"]
                }
            }
        )

        # Should NOT get 500 with rate limiter error
        assert response.status_code != 500 or "rate" not in response.text.lower(), \
            f"Rate limiter parameter error: {response.text}"

        assert response.status_code != 404, "Endpoint not found"

    def test_save_conversation_endpoint_accepts_request(self, client):
        """Test that /save-conversation endpoint accepts valid request body."""
        response = client.post(
            "/api/v1/onboarding/save-conversation",
            json={
                "user_id": "test-user-123",
                "conversation_history": [
                    {"role": "user", "content": "Hello"},
                    {"role": "assistant", "content": "Hi there!"}
                ],
                "collected_data": {"name": "TestUser"}
            }
        )

        # Should NOT get 500 with rate limiter error
        assert response.status_code != 500 or "rate" not in response.text.lower(), \
            f"Rate limiter parameter error: {response.text}"

        assert response.status_code != 404, "Endpoint not found"

    def test_parse_response_returns_json(self, client):
        """Test that parse-response returns valid JSON response."""
        response = client.post(
            "/api/v1/onboarding/parse-response",
            json={
                "user_id": "test-user-123",
                "message": "I'm 25 years old",
                "current_data": {"name": "TestUser"}
            }
        )

        # Should return JSON (not crash with 500)
        # Can be 200 (success) or 503 (AI service unavailable)
        if response.status_code == 200:
            data = response.json()
            # Response should be a dict
            assert isinstance(data, dict), "Response should be a dict"

    def test_parse_response_missing_user_id(self, client):
        """Test that missing user_id returns validation error."""
        response = client.post(
            "/api/v1/onboarding/parse-response",
            json={
                "message": "I'm 25 years old",
                "current_data": {}
            }
        )

        # Should return 422 Unprocessable Entity for validation error
        assert response.status_code == 422, \
            f"Expected 422 for missing user_id, got {response.status_code}"

    def test_parse_response_missing_message(self, client):
        """Test that missing message returns validation error."""
        response = client.post(
            "/api/v1/onboarding/parse-response",
            json={
                "user_id": "test-user-123",
                "current_data": {}
            }
        )

        # Should return 422 Unprocessable Entity for validation error
        assert response.status_code == 422, \
            f"Expected 422 for missing message, got {response.status_code}"


class TestOnboardingRateLimiting:
    """Tests to verify rate limiting configuration works correctly."""

    def test_rate_limiter_does_not_crash_on_request(self, client):
        """
        Verify the rate limiter decorator doesn't crash due to parameter naming.

        The bug was: @limiter.limit("10/minute") requires the first parameter
        to be named exactly 'request' (type: starlette.requests.Request).

        If it was named 'http_request', the decorator would fail with:
        'parameter 'request' must be an instance of starlette.requests.Request'
        """
        # Make a request to a rate-limited endpoint
        response = client.post(
            "/api/v1/onboarding/parse-response",
            json={
                "user_id": "test-user-123",
                "message": "test",
                "current_data": {}
            }
        )

        # The response should NOT be a 500 error about rate limiter
        if response.status_code == 500:
            error_text = response.text.lower()
            assert "starlette.requests.request" not in error_text, \
                "Rate limiter parameter naming bug detected!"
            assert "parameter 'request'" not in error_text, \
                "Rate limiter parameter naming bug detected!"


class TestOnboardingEndpointRouting:
    """Tests to verify endpoint routing is configured correctly."""

    def test_onboarding_router_mounted(self, client):
        """Test that onboarding router is mounted under /api/v1/onboarding/."""
        # Check that at least one onboarding endpoint exists
        response = client.post(
            "/api/v1/onboarding/parse-response",
            json={
                "user_id": "test",
                "message": "test",
                "current_data": {}
            }
        )

        # Should not be 404 (endpoint not found)
        assert response.status_code != 404, \
            "Onboarding router not mounted at /api/v1/onboarding/"

    def test_validate_data_route_exists(self, client):
        """Test that validate-data endpoint is accessible."""
        response = client.post(
            "/api/v1/onboarding/validate-data",
            json={"user_id": "test", "data": {}}
        )

        assert response.status_code != 404, \
            "validate-data endpoint not found"

    def test_save_conversation_route_exists(self, client):
        """Test that save-conversation endpoint is accessible."""
        response = client.post(
            "/api/v1/onboarding/save-conversation",
            json={
                "user_id": "test",
                "conversation_history": [],
                "collected_data": {}
            }
        )

        assert response.status_code != 404, \
            "save-conversation endpoint not found"
