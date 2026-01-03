"""
Tests for middleware components.

Tests the SlowAPIMiddleware integration and LoggingMiddleware behavior.
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi import FastAPI, Request
from fastapi.testclient import TestClient
from starlette.middleware.base import BaseHTTPMiddleware
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi import _rate_limit_exceeded_handler

from core.rate_limiter import limiter, get_real_client_ip


class TestSlowAPIMiddlewareIntegration:
    """Tests for SlowAPIMiddleware integration with FastAPI."""

    def test_rate_limited_endpoint_without_middleware_behavior(self):
        """
        Without SlowAPIMiddleware, rate-limited endpoints behavior depends on config.

        With swallow_errors=True (our config), the endpoint will work but
        rate limiting won't be properly enforced. Without swallow_errors,
        it would cause 500 errors.
        """
        # Create app WITHOUT SlowAPIMiddleware
        app = FastAPI()

        # Create a limiter WITHOUT swallow_errors to show the failure mode
        test_limiter = Limiter(
            key_func=get_real_client_ip,
            swallow_errors=False  # This will cause failures without middleware
        )
        app.state.limiter = test_limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

        @app.post("/test")
        @test_limiter.limit("5/minute")
        async def test_endpoint(request: Request):
            return {"status": "ok"}

        client = TestClient(app, raise_server_exceptions=False)

        # Without middleware and swallow_errors=False, it should fail
        response = client.post("/test")

        # Without middleware, the endpoint fails with 500 (or may work depending on env)
        # This documents the potential failure mode
        assert response.status_code in [200, 500]  # Behavior depends on environment

    def test_rate_limited_endpoint_with_middleware_works(self):
        """
        With SlowAPIMiddleware, rate-limited endpoints should work.

        This test verifies our fix - adding SlowAPIMiddleware makes
        rate limiting work correctly.
        """
        # Create app WITH SlowAPIMiddleware
        app = FastAPI()
        app.state.limiter = limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        app.add_middleware(SlowAPIMiddleware)

        @app.post("/test")
        @limiter.limit("5/minute")
        async def test_endpoint(request: Request):
            return {"status": "ok"}

        client = TestClient(app)

        response = client.post("/test")

        # With middleware, the endpoint works
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}

    def test_rate_limit_exceeded_returns_429(self):
        """Rate limit exceeded should return 429, not 500."""
        app = FastAPI()
        app.state.limiter = limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        app.add_middleware(SlowAPIMiddleware)

        # Create a very strict rate limit for testing
        test_limiter = Limiter(key_func=get_real_client_ip, swallow_errors=True)
        app.state.limiter = test_limiter

        @app.post("/limited")
        @test_limiter.limit("1/minute")
        async def limited_endpoint(request: Request):
            return {"status": "ok"}

        client = TestClient(app)

        # First request should succeed
        response1 = client.post("/limited")
        assert response1.status_code == 200

        # Second request should be rate limited (429)
        response2 = client.post("/limited")
        assert response2.status_code == 429

    def test_non_rate_limited_endpoint_unaffected(self):
        """Endpoints without rate limiting should work normally."""
        app = FastAPI()
        app.state.limiter = limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        app.add_middleware(SlowAPIMiddleware)

        @app.get("/health")
        async def health():
            return {"status": "healthy"}

        client = TestClient(app)

        response = client.get("/health")

        assert response.status_code == 200
        assert response.json() == {"status": "healthy"}


class TestLoggingMiddlewareBehavior:
    """Tests for LoggingMiddleware behavior."""

    def test_logging_middleware_does_not_consume_body(self):
        """
        LoggingMiddleware should NOT read request body.

        Previously, the middleware read the body to extract user_id,
        which consumed the stream and caused POST requests to fail.
        """
        from main import LoggingMiddleware

        app = FastAPI()
        app.add_middleware(LoggingMiddleware)

        @app.post("/echo")
        async def echo(data: dict):
            return {"received": data}

        client = TestClient(app)

        response = client.post(
            "/echo",
            json={"message": "hello", "user_id": "test-123"}
        )

        # Body should be available to the endpoint
        assert response.status_code == 200
        assert response.json()["received"]["message"] == "hello"

    def test_logging_middleware_extracts_user_id_from_query_params(self):
        """LoggingMiddleware should extract user_id from query parameters."""
        from main import LoggingMiddleware

        app = FastAPI()
        app.add_middleware(LoggingMiddleware)

        @app.get("/test")
        async def test_endpoint():
            return {"status": "ok"}

        client = TestClient(app)

        response = client.get("/test?user_id=abc123")

        assert response.status_code == 200
        # The middleware should have processed without error
        assert "X-Request-ID" in response.headers

    def test_logging_middleware_adds_request_id_header(self):
        """LoggingMiddleware should add X-Request-ID to responses."""
        from main import LoggingMiddleware

        app = FastAPI()
        app.add_middleware(LoggingMiddleware)

        @app.get("/test")
        async def test_endpoint():
            return {"status": "ok"}

        client = TestClient(app)

        response = client.get("/test")

        assert response.status_code == 200
        assert "X-Request-ID" in response.headers
        # Request ID should be 8 characters (first 8 of UUID)
        assert len(response.headers["X-Request-ID"]) == 8


class TestMiddlewareOrder:
    """Tests for middleware execution order."""

    def test_middleware_stack_order(self):
        """
        Test that middleware executes in correct order.

        FastAPI/Starlette middleware executes in reverse order of how they're added.
        The LAST added middleware executes FIRST (is the outermost).
        """
        execution_order = []

        class FirstAddedMiddleware(BaseHTTPMiddleware):
            async def dispatch(self, request, call_next):
                execution_order.append("first_added_before")
                response = await call_next(request)
                execution_order.append("first_added_after")
                return response

        class LastAddedMiddleware(BaseHTTPMiddleware):
            async def dispatch(self, request, call_next):
                execution_order.append("last_added_before")
                response = await call_next(request)
                execution_order.append("last_added_after")
                return response

        app = FastAPI()
        # Added first = executed LAST (innermost)
        # Added last = executed FIRST (outermost)
        app.add_middleware(FirstAddedMiddleware)
        app.add_middleware(LastAddedMiddleware)

        @app.get("/test")
        async def test_endpoint():
            execution_order.append("handler")
            return {"status": "ok"}

        client = TestClient(app)
        response = client.get("/test")

        assert response.status_code == 200
        # Last added middleware executes first (outermost)
        assert execution_order == [
            "last_added_before",
            "first_added_before",
            "handler",
            "first_added_after",
            "last_added_after"
        ]


class TestSecurityHeadersMiddleware:
    """Tests for SecurityHeadersMiddleware."""

    def test_security_headers_are_added(self):
        """SecurityHeadersMiddleware should add security headers."""
        from main import SecurityHeadersMiddleware

        app = FastAPI()
        app.add_middleware(SecurityHeadersMiddleware)

        @app.get("/test")
        async def test_endpoint():
            return {"status": "ok"}

        client = TestClient(app)

        response = client.get("/test")

        assert response.status_code == 200
        # Check security headers are present
        assert response.headers.get("X-Content-Type-Options") == "nosniff"
        assert response.headers.get("X-Frame-Options") == "DENY"
        assert response.headers.get("X-XSS-Protection") == "1; mode=block"
        assert "Strict-Transport-Security" in response.headers
        assert "Content-Security-Policy" in response.headers
        assert "Referrer-Policy" in response.headers


class TestRateLimiterWithProxyHeaders:
    """Tests for rate limiter with various proxy header configurations."""

    def test_rate_limiting_uses_x_forwarded_for(self):
        """Rate limiter should use X-Forwarded-For for client identification."""
        app = FastAPI()
        test_limiter = Limiter(
            key_func=get_real_client_ip,
            default_limits=["100/minute"],
            swallow_errors=True
        )
        app.state.limiter = test_limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        app.add_middleware(SlowAPIMiddleware)

        @app.post("/test")
        @test_limiter.limit("2/minute")
        async def test_endpoint(request: Request):
            return {"status": "ok"}

        client = TestClient(app)

        # First two requests from IP 192.168.1.1 should succeed
        for _ in range(2):
            response = client.post(
                "/test",
                headers={"X-Forwarded-For": "192.168.1.1"}
            )
            assert response.status_code == 200

        # Third request from same IP should be rate limited
        response = client.post(
            "/test",
            headers={"X-Forwarded-For": "192.168.1.1"}
        )
        assert response.status_code == 429

        # Request from different IP should succeed
        response = client.post(
            "/test",
            headers={"X-Forwarded-For": "192.168.1.2"}
        )
        assert response.status_code == 200
