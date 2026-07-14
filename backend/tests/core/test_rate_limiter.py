"""
Tests for the rate limiter module.

Tests the get_real_client_ip function which handles reverse proxy scenarios
where X-Forwarded-For or X-Real-IP headers are present.

BEHAVIOR CHANGE (commit bfae5a80) — these tests were originally written against
the first version of `get_real_client_ip`, which trusted ANY inbound proxy
header unconditionally:

    X-Forwarded-For -> first IP        (always trusted)
    X-Real-IP       -> value           (always trusted)
    request.client.host
    "127.0.0.1"

That contract was RETIRED because it is an IP-spoofing hole: when the app is
reachable directly (local dev, a direct-to-instance hit that bypasses the edge),
any client could send `X-Forwarded-For: <anything>` and choose its own
rate-limit bucket, making the per-IP limiter trivially evadable. The current
contract is:

    if os.environ["RENDER"] is set:   # i.e. we really are behind Render's proxy
        X-Forwarded-For -> first IP   (trusted ONLY here)
    request.client.host
    "127.0.0.1"

X-Real-IP is no longer honored at all (Render — the only proxy in front of this
service — always sets X-Forwarded-For).

The tests below now assert that CURRENT contract, and additionally pin the
guarantee the change bought: an UNTRUSTED X-Forwarded-For / X-Real-IP must not
be able to move the rate-limit key. The original intent (proxy headers resolve
to the real client; never crash; graceful 127.0.0.1 fallback) is preserved.
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


@pytest.fixture(autouse=True)
def not_behind_proxy(monkeypatch):
    """Default every test to 'not running on Render' (proxy headers untrusted).

    Autouse so a RENDER var leaking in from the developer's shell can never
    silently turn the spoofing-protection tests into passes.
    """
    monkeypatch.delenv("RENDER", raising=False)


@pytest.fixture
def behind_render(monkeypatch, not_behind_proxy):
    """Simulate running behind Render's reverse proxy.

    Render injects RENDER=true into every service's environment; that env var is
    the signal `get_real_client_ip` uses to decide X-Forwarded-For is trustworthy.
    """
    monkeypatch.setenv("RENDER", "true")


class TestGetRealClientIp:
    """Tests for get_real_client_ip function."""

    def test_x_forwarded_for_single_ip(self, behind_render):
        """Should extract IP from X-Forwarded-For header with single IP."""
        request = MockRequest(
            headers={"X-Forwarded-For": "192.168.1.100"}
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_x_forwarded_for_multiple_ips(self, behind_render):
        """Should extract first IP from X-Forwarded-For header with multiple IPs."""
        request = MockRequest(
            headers={"X-Forwarded-For": "192.168.1.100, 10.0.0.1, 172.16.0.1"}
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_x_forwarded_for_with_whitespace(self, behind_render):
        """Should handle whitespace in X-Forwarded-For header."""
        request = MockRequest(
            headers={"X-Forwarded-For": "  192.168.1.100  ,  10.0.0.1  "}
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_x_real_ip_header(self, behind_render):
        """X-Real-IP is NO LONGER a trusted IP source — even behind the proxy.

        Retired behavior: this used to assert get_real_client_ip(...) == the
        X-Real-IP value. Support for X-Real-IP was removed in bfae5a80; Render
        (the only proxy fronting this service) always sets X-Forwarded-For, so
        honoring a second, unvalidated header only widened the spoofing surface.
        Guarantee protected now: an X-Real-IP header cannot select the caller's
        rate-limit bucket; resolution falls through to the direct client IP.
        """
        request = MockRequest(
            headers={"X-Real-IP": "203.0.113.50"},
            client_host="10.0.0.50",
        )
        assert get_real_client_ip(request) == "10.0.0.50"

    def test_x_real_ip_with_whitespace(self, behind_render):
        """Whitespace-padded X-Real-IP is likewise ignored (see test above).

        Retired behavior: used to assert the header was stripped and returned.
        The header is no longer read at all, so with no direct client the
        resolver must land on the documented 127.0.0.1 fallback rather than the
        attacker-supplied value.
        """
        request = MockRequest(
            headers={"X-Real-IP": "  203.0.113.50  "}
        )
        ip = get_real_client_ip(request)
        assert ip == "127.0.0.1"
        assert ip != "203.0.113.50"

    def test_x_forwarded_for_takes_priority_over_x_real_ip(self, behind_render):
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

    def test_proxy_header_priority_over_direct_client(self, behind_render):
        """Proxy headers should take priority over direct client IP."""
        request = MockRequest(
            headers={"X-Forwarded-For": "192.168.1.100"},
            client_host="10.0.0.1"
        )
        assert get_real_client_ip(request) == "192.168.1.100"

    def test_ipv6_address_in_x_forwarded_for(self, behind_render):
        """Should handle IPv6 addresses in X-Forwarded-For."""
        request = MockRequest(
            headers={"X-Forwarded-For": "2001:db8::1, 10.0.0.1"}
        )
        assert get_real_client_ip(request) == "2001:db8::1"

    def test_empty_x_forwarded_for(self, behind_render):
        """Should fallback when X-Forwarded-For is empty."""
        request = MockRequest(
            headers={"X-Forwarded-For": ""},
            client_host="10.0.0.1"
        )
        # Empty string is falsy, so should fallback to client.host
        assert get_real_client_ip(request) == "10.0.0.1"


class TestSpoofingProtection:
    """The guarantee bfae5a80 added: proxy headers are untrusted off-Render.

    Without these, the rate limiter is evadable — a direct caller picks its own
    bucket by rotating X-Forwarded-For and never hits a limit.
    """

    def test_x_forwarded_for_ignored_when_not_behind_render(self):
        """A spoofed X-Forwarded-For must not override the real socket IP."""
        request = MockRequest(
            headers={"X-Forwarded-For": "1.2.3.4"},
            client_host="10.0.0.1",
        )
        ip = get_real_client_ip(request)
        assert ip == "10.0.0.1"
        assert ip != "1.2.3.4"

    def test_x_real_ip_ignored_when_not_behind_render(self):
        """A spoofed X-Real-IP must not override the real socket IP."""
        request = MockRequest(
            headers={"X-Real-IP": "1.2.3.4"},
            client_host="10.0.0.1",
        )
        ip = get_real_client_ip(request)
        assert ip == "10.0.0.1"
        assert ip != "1.2.3.4"

    def test_rotating_spoofed_headers_share_one_key_off_render(self):
        """Rotating the header must NOT mint a fresh rate-limit key per request."""
        keys = {
            get_real_client_ip(
                MockRequest(headers={"X-Forwarded-For": f"1.2.3.{n}"}, client_host="10.0.0.1")
            )
            for n in range(1, 6)
        }
        assert keys == {"10.0.0.1"}


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

    def test_render_proxy_scenario(self, behind_render):
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

    def test_render_without_x_forwarded_for(self, behind_render):
        """
        Handle case where Render doesn't set X-Forwarded-For.

        Should fallback gracefully without crashing.
        """
        request = MockRequest()
        request.client = None

        ip = get_real_client_ip(request)
        assert ip == "127.0.0.1"  # Graceful fallback

    def test_aws_alb_scenario(self, behind_render):
        """
        Simulate AWS ALB (Application Load Balancer) behavior.

        ALB typically sets X-Forwarded-For header. Trusted only because the
        deployment marker says we really are behind the platform's proxy.
        """
        request = MockRequest(
            headers={"X-Forwarded-For": "54.239.28.85, 172.31.0.100"}
        )

        ip = get_real_client_ip(request)
        assert ip == "54.239.28.85"

    def test_cloudflare_scenario(self, behind_render):
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

    def test_nginx_proxy_scenario(self, behind_render):
        """
        Simulate nginx reverse proxy behavior (X-Real-IP only).

        Retired behavior: this used to assert the X-Real-IP value was returned.
        X-Real-IP is no longer a trusted source (bfae5a80) — the only proxy in
        front of this service is Render, which sets X-Forwarded-For. So an
        X-Real-IP-only proxy now resolves to the connecting socket's address
        (the proxy itself), NOT the header value. Pinning this keeps the removal
        deliberate: if nginx is ever put in front of the service, this test is
        the one that must be revisited alongside re-adding trusted X-Real-IP.
        """
        request = MockRequest(
            headers={"X-Real-IP": "192.0.2.1"},
            client_host="10.10.10.1",  # the nginx box's own address
        )

        ip = get_real_client_ip(request)
        assert ip == "10.10.10.1"
        assert ip != "192.0.2.1"
