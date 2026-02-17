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

For user-based rate limiting (better for authenticated endpoints):
    from core.rate_limiter import user_limiter

    @router.post("/endpoint")
    @user_limiter.limit("10/minute")
    async def my_endpoint(request: Request, body: MyRequest):
        ...

Note: The limiter must be attached to the FastAPI app in main.py:
    app.state.limiter = limiter
"""
import json
import time
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


# Single shared limiter instance (IP-based)
# Uses custom key function for reverse proxy compatibility (e.g., Render)
# Default global limit: 100 requests per minute
# swallow_errors=True prevents 500 errors if rate limiting fails
limiter = Limiter(
    key_func=get_real_client_ip,
    default_limits=["100/minute"],
    swallow_errors=True,  # Log errors but don't crash the request
)


# Cache for request bodies (needed because body can only be read once)
# Bounded to 1000 entries with 60s TTL to prevent unbounded growth
_request_body_cache: dict = {}
_REQUEST_CACHE_MAX_SIZE = 1000
_REQUEST_CACHE_TTL = 60  # seconds


async def get_user_id_from_request(request: Request) -> str:
    """
    Extract user_id from request body for user-based rate limiting.

    This is more reliable than IP-based limiting for authenticated endpoints,
    especially behind reverse proxies like Render where multiple users might
    share the same IP address.

    Falls back to IP-based limiting if user_id cannot be extracted.
    """
    try:
        # Try query params first (fastest)
        user_id = request.query_params.get("user_id")
        if user_id:
            return f"user:{user_id}"

        # Check if we have a cached body for this request
        request_id = id(request)
        cached_entry = _request_body_cache.get(request_id)
        if cached_entry is not None:
            body = cached_entry[1]  # (timestamp, body)
        else:
            # Read and cache the body (can only be read once)
            body_bytes = await request.body()
            if body_bytes:
                try:
                    body = json.loads(body_bytes)
                    # Evict stale entries before adding new one
                    if len(_request_body_cache) >= _REQUEST_CACHE_MAX_SIZE:
                        now = time.monotonic()
                        stale_keys = [
                            k for k, (ts, _) in _request_body_cache.items()
                            if now - ts > _REQUEST_CACHE_TTL
                        ]
                        for k in stale_keys:
                            del _request_body_cache[k]
                    _request_body_cache[request_id] = (time.monotonic(), body)
                except json.JSONDecodeError:
                    body = {}
            else:
                body = {}

        # Extract user_id from body
        user_id = body.get("user_id")
        if user_id:
            return f"user:{user_id}"

    except Exception:
        pass

    # Fall back to IP-based limiting
    return get_real_client_ip(request)


# User-based limiter instance for authenticated endpoints
# More reliable than IP-based limiting behind proxies
user_limiter = Limiter(
    key_func=get_user_id_from_request,
    default_limits=["100/minute"],
    swallow_errors=True,
)
