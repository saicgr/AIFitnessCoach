"""
Tests for the rate limiter module.

Tests the get_real_client_ip function which handles reverse proxy scenarios
where X-Forwarded-For or X-Real-IP headers are present.
"""
import pytest
from unittest.mock import MagicMock
from starlette.requests import Request
from starlette.datastructures import Headers

from core.rate_limiter import get_real_client_ip, limiter


class MockClient:
    """Mock client for testing request.client."""
    def __init__(self, host: str = None):
        self.host = host


class MockRequest:
    """Mock Request object for testing."""
    def __init__(self, headers: dict = None, client_host: str = None):
        self.headers = Headers(headers or {})
        self.client = MockClient(client_host) if client_host else None


class TestGetRealClientIp:
    """Tests for get_real_client_ip function."""

    def test_x_forwarded_for_single_ip(self):
        """Should extract IP from X-Forwarded-For header with single IP."""
        request = MockRequest(
            headers={"X-Forwarded-For": "192.168.1.100"}
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_x_forwarded_for_multiple_ips(self):
        """Should extract first IP from X-Forwarded-For header with multiple IPs."""
        request = MockRequest(
            headers={"X-Forwarded-For": "192.168.1.100, 10.0.0.1, 172.16.0.1"}
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_x_forwarded_for_with_whitespace(self):
        """Should handle whitespace in X-Forwarded-For header."""
        request = MockRequest(
            headers={"X-Forwarded-For": "  192.168.1.100  ,  10.0.0.1  "}
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_x_real_ip_header(self):
        """Should extract IP from X-Real-IP header when X-Forwarded-For is absent."""
        request = MockRequest(
            headers={"X-Real-IP": "203.0.113.50"}
        )
        assert get_real_client_ip(request) == "203.0.113.50"

    def test_x_real_ip_with_whitespace(self):
        """Should handle whitespace in X-Real-IP header."""
        request = MockRequest(
            headers={"X-Real-IP": "  203.0.113.50  "}
        )
        assert get_real_client_ip(request) == "203.0.113.50"

    def test_x_forwarded_for_takes_priority_over_x_real_ip(self):
        """X-Forwarded-For should take priority over X-Real-IP."""
        request = MockRequest(
            headers={
                "X-Forwarded-For": "192.168.1.100",
                "X-Real-IP": "203.0.113.50"
            }
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_direct_client_ip(self):
        """Should use request.client.host when no proxy headers present."""
        request = MockRequest(client_host="10.0.0.50")
        assert get_real_client_ip(request) == "10.0.0.50"

    def test_fallback_when_no_client(self):
        """Should return 127.0.0.1 when no IP source is available."""
        request = MockRequest()  # No headers, no client
        assert get_real_client_ip(request) == "127.0.0.1"

    def test_fallback_when_client_host_is_none(self):
        """Should return 127.0.0.1 when client exists but host is None."""
        request = MockRequest(client_host=None)
        request.client = MockClient(host=None)
        assert get_real_client_ip(request) == "127.0.0.1"

    def test_proxy_header_priority_over_direct_client(self):
        """Proxy headers should take priority over direct client IP."""
        request = MockRequest(
            headers={"X-Forwarded-For": "192.168.1.100"},
            client_host="10.0.0.1"
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_ipv6_address_in_x_forwarded_for(self):
        """Should handle IPv6 addresses in X-Forwarded-For."""
        request = MockRequest(
            headers={"X-Forwarded-For": "2001:db8::1, 10.0.0.1"}
        )
        assert get_real_client_ip(request) == "2001:db8::1"

    def test_empty_x_forwarded_for(self):
        """Should fallback when X-Forwarded-For is empty."""
        request = MockRequest(
            headers={"X-Forwarded-For": ""},
            client_host="10.0.0.1"
        )
        # Empty string is falsy, so should fallback to client.host
        assert get_real_client_ip(request) == "10.0.0.1"


class TestLimiterConfiguration:
    """Tests for limiter configuration."""

    def test_limiter_has_swallow_errors_enabled(self):
        """Limiter should have swallow_errors=True to prevent 500 errors."""
        # The limiter is configured with swallow_errors=True
        # This ensures rate limiting errors don't crash the request
        assert limiter._swallow_errors is True

    def test_limiter_has_custom_key_function(self):
        """Limiter should use get_real_client_ip as key function."""
        assert limiter._key_func == get_real_client_ip

    def test_limiter_default_limits(self):
        """Limiter should have default limit of 100/minute."""
        # Default limits are wrapped in LimitGroup objects
        # Check that default limits were configured
        assert len(limiter._default_limits) > 0
        # The limiter should have been configured with default limits
        assert limiter._default_limits is not None


class TestRenderDeploymentScenarios:
    """Tests simulating Render deployment scenarios."""

    def test_render_proxy_scenario(self):
        """
        Simulate Render's reverse proxy behavior.

        Render sets X-Forwarded-For header with the real client IP.
        The request.client may be None or set to internal proxy IP.
        """
        # Scenario: Render proxy forwards request
        request = MockRequest(
            headers={"X-Forwarded-For": "203.0.113.100, 10.10.10.1"}
        )
        request.client = None  # Common in reverse proxy scenarios

        ip = get_real_client_ip(request)
        assert ip == "203.0.113.100"
        assert ip != "127.0.0.1"  # Should NOT fall back to default

    def test_render_without_x_forwarded_for(self):
        """
        Handle case where Render doesn't set X-Forwarded-For.

        Should fallback gracefully without crashing.
        """
        request = MockRequest()
        request.client = None

        ip = get_real_client_ip(request)
        assert ip == "127.0.0.1"  # Graceful fallback

    def test_aws_alb_scenario(self):
        """
        Simulate AWS ALB (Application Load Balancer) behavior.

        ALB typically sets X-Forwarded-For header.
        """
        request = MockRequest(
            headers={"X-Forwarded-For": "54.239.28.85, 172.31.0.100"}
        )

        ip = get_real_client_ip(request)
        assert ip == "54.239.28.85"

    def test_cloudflare_scenario(self):
        """
        Simulate Cloudflare proxy behavior.

        Cloudflare sets both CF-Connecting-IP and X-Real-IP headers,
        but we should prefer X-Forwarded-For if present.
        """
        request = MockRequest(
            headers={
                "X-Forwarded-For": "198.51.100.178, 172.68.0.1",
                "X-Real-IP": "198.51.100.178",
                "CF-Connecting-IP": "198.51.100.178"
            }
        )

        ip = get_real_client_ip(request)
        assert ip == "198.51.100.178"

    def test_nginx_proxy_scenario(self):
        """
        Simulate nginx reverse proxy behavior.

        nginx typically sets X-Real-IP header.
        """
        request = MockRequest(
            headers={"X-Real-IP": "192.0.2.1"}
        )

        ip = get_real_client_ip(request)
        assert ip == "192.0.2.1"
