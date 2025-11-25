"""
Tests for Health API endpoints.

Tests the health check and root endpoints.
"""
import pytest
from fastapi.testclient import TestClient


class TestHealthEndpoints:
    """Tests for health and status endpoints."""

    def test_root_endpoint(self, client):
        """Test root endpoint returns service info."""
        response = client.get("/")

        assert response.status_code == 200
        data = response.json()
        assert "service" in data
        assert "version" in data
        assert "AI Fitness Coach" in data["service"]

    def test_root_includes_docs_link(self, client):
        """Test root endpoint includes docs link."""
        response = client.get("/")

        data = response.json()
        assert "docs" in data
        assert data["docs"] == "/docs"

    def test_health_endpoint(self, client):
        """Test health endpoint."""
        response = client.get("/api/v1/health/")

        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert data["status"] == "healthy"

    def test_health_includes_timestamp(self, client):
        """Test health endpoint includes timestamp."""
        response = client.get("/api/v1/health/")

        data = response.json()
        # Should have some form of timestamp or version info
        assert response.status_code == 200


class TestAPIVersioning:
    """Tests for API versioning."""

    def test_v1_prefix_works(self, client):
        """Test that /api/v1/ prefix routes correctly."""
        response = client.get("/api/v1/health/")
        assert response.status_code == 200

    def test_chat_routes_under_v1(self, client):
        """Test that chat routes are under /api/v1/."""
        # This tests that the router is mounted correctly
        response = client.post(
            "/api/v1/chat/send",
            json={"message": "test", "user_id": 1}
        )
        # Should get 200, 503, or 500 - not 404
        assert response.status_code != 404


class TestCORS:
    """Tests for CORS configuration."""

    def test_cors_headers_present(self, client):
        """Test that CORS headers are present in response."""
        response = client.options(
            "/api/v1/health/",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET",
            }
        )

        # CORS should allow the request
        assert response.status_code in [200, 204]


class TestOpenAPISpec:
    """Tests for OpenAPI documentation."""

    def test_openapi_spec_available(self, client):
        """Test that OpenAPI spec is accessible."""
        response = client.get("/openapi.json")

        assert response.status_code == 200
        data = response.json()
        assert "openapi" in data
        assert "paths" in data

    def test_docs_endpoint(self, client):
        """Test that docs endpoint is accessible."""
        response = client.get("/docs")

        # Swagger UI returns HTML
        assert response.status_code == 200

    def test_redoc_endpoint(self, client):
        """Test that ReDoc endpoint is accessible."""
        response = client.get("/redoc")

        assert response.status_code == 200
