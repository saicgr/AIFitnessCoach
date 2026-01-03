"""
Shared rate limiter for all API endpoints.

This module provides a single Limiter instance that should be used across
all API endpoints to ensure consistent rate limiting behavior.

Usage in endpoints:
    from core.rate_limiter import limiter

    @router.post("/endpoint")
    @limiter.limit("5/minute")
    async def my_endpoint(request: Request, ...):
        ...

Note: The limiter must be attached to the FastAPI app in main.py:
    app.state.limiter = limiter
"""
from slowapi import Limiter
from starlette.requests import Request


def get_real_client_ip(request: Request) -> str:
    """
    Extract the real client IP address, handling reverse proxies.

    When deployed behind a reverse proxy (like Render, AWS ALB, etc.),
    the request.client.host will be the proxy's IP, not the real client.
    We need to check X-Forwarded-For header for the real client IP.
    """
    # Check X-Forwarded-For header first (set by reverse proxies)
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        # Take the first IP (original client)
        return forwarded_for.split(",")[0].strip()

    # Check X-Real-IP header (used by some proxies)
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip.strip()

    # Fallback to direct client IP (may be None behind proxy)
    if request.client and request.client.host:
        return request.client.host

    # Ultimate fallback - use a default to prevent errors
    return "127.0.0.1"


# Single shared limiter instance
# Uses custom key function for reverse proxy compatibility (e.g., Render)
# Default global limit: 100 requests per minute
limiter = Limiter(key_func=get_real_client_ip, default_limits=["100/minute"])
