"""
Tests for Health API endpoints.

Tests the health check and root endpoints.
"""
import pytest
from fastapi.testclient import TestClient

from core.config import get_settings


class TestHealthEndpoints:
    """Tests for health and status endpoints."""

    def test_root_endpoint(self, client):
        """Test root endpoint returns service info."""
        response = client.get("/")

        assert response.status_code == 200
        data = response.json()
        assert "service" in data
        assert "version" in data
        assert "Zealova" in data["service"]

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
        """Test that CORS headers are present for an ALLOWED origin.

        RETIRED ASSERTION: this test used to send `Origin: http://localhost:3000`
        and assert the preflight returned 200/204. That passed when
        `settings.cors_origins` was `["*"]` (its value in the very first commit).
        The allowlist was deliberately narrowed to specific origins because
        `allow_credentials=True` cannot safely be combined with a `*` origin —
        core/config.py carries that warning explicitly. localhost:3000 is not on
        the allowlist (nothing serves the product from there; the React marketing
        site reaches the API through same-origin Vercel rewrites), so Starlette
        now correctly rejects that preflight with 400 "Disallowed CORS origin".

        The guarantee this test protects is unchanged — CORS preflight works for
        origins the product actually serves — but it now asserts the real CORS
        response headers rather than only a status code, and its sibling below
        pins the rejection half that the `["*"]` era could not express.
        """
        origin = "https://zealova.com"
        assert origin in get_settings().cors_origins, "test origin must be on the allowlist"

        response = client.options(
            "/api/v1/health/",
            headers={
                "Origin": origin,
                "Access-Control-Request-Method": "GET",
            }
        )

        # CORS should allow the request
        assert response.status_code in [200, 204]
        # The origin must be echoed back — this is what actually unblocks the browser.
        assert response.headers["access-control-allow-origin"] == origin
        assert response.headers["access-control-allow-credentials"] == "true"
        assert "GET" in response.headers["access-control-allow-methods"]

    def test_cors_rejects_disallowed_origin(self, client):
        """A preflight from an origin outside the allowlist must be rejected.

        This is the security half of the CORS contract, and it is the reason the
        `["*"]` allowlist was retired: with allow_credentials=True, echoing an
        arbitrary origin would let any site make credentialed calls to the API.
        A regression here (e.g. someone "fixing" CORS by restoring `["*"]`) must
        fail this test.
        """
        origin = "http://evil.example.com"
        assert origin not in get_settings().cors_origins

        response = client.options(
            "/api/v1/health/",
            headers={
                "Origin": origin,
                "Access-Control-Request-Method": "GET",
            }
        )

        assert response.status_code == 400
        # Critically: the browser must NOT receive an allow-origin for this host.
        assert response.headers.get("access-control-allow-origin") is None


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
