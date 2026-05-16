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
from fastapi import Request
import json
import logging
import os
from slowapi import Limiter
from starlette.requests import Request

logger = logging.getLogger(__name__)


def get_real_client_ip(request: Request) -> str:
    """
    Extract the real client IP address, handling reverse proxies.

    Only trusts X-Forwarded-For when running behind Render's reverse proxy
    (detected via the RENDER environment variable). This prevents IP spoofing
    when the app is accessed directly.
    """
    # Only trust proxy headers when running behind Render's reverse proxy
    if os.environ.get("RENDER"):
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()

    # Use direct client IP
    if request.client and request.client.host:
        return request.client.host

    return "127.0.0.1"


# Single shared limiter instance (IP-based)
# Uses custom key function for reverse proxy compatibility (e.g., Render)
# Default global limit: 100 requests per minute
# swallow_errors=True prevents 500 errors if rate limiting fails
import os as _os
# BENCH_BYPASS_RATELIMIT=1 disables the limiter entirely so the Phase-2
# full-sweep bench script can fire 500+ scans through one local instance
# without hitting the 10/min per-endpoint cap. NEVER set this in prod.
_BENCH_BYPASS = _os.environ.get("BENCH_BYPASS_RATELIMIT") == "1"
limiter = Limiter(
    key_func=get_real_client_ip,
    default_limits=[] if _BENCH_BYPASS else ["100/minute"],
    swallow_errors=True,
    enabled=not _BENCH_BYPASS,
)


def get_user_id_from_request(request: Request) -> str:
    """
    Extract user_id from request for user-based rate limiting.

    Must be synchronous — slowapi 0.1.9 calls key_func without awaiting.
    Body parsing happens only if Starlette has already cached it on the
    request object (middleware/endpoint has read it). Otherwise we fall
    back to query params, then IP.
    """
    try:
        user_id = request.query_params.get("user_id")
        if user_id:
            return f"user:{user_id}"

        # Only inspect body if Starlette has already cached it (sync-safe).
        body_bytes = getattr(request, "_body", None)
        if body_bytes:
            try:
                body = json.loads(body_bytes)
                user_id = body.get("user_id") if isinstance(body, dict) else None
                if user_id:
                    return f"user:{user_id}"
            except (json.JSONDecodeError, TypeError):
                pass

    except Exception as e:
        logger.debug(f"User ID extraction failed: {e}")

    return get_real_client_ip(request)


# User-based limiter instance for authenticated endpoints
# More reliable than IP-based limiting behind proxies
user_limiter = Limiter(
    key_func=get_user_id_from_request,
    default_limits=[] if _BENCH_BYPASS else ["100/minute"],
    swallow_errors=True,
    enabled=not _BENCH_BYPASS,
)


def structured_rate_limit_handler(request: Request, exc):
    """Custom 429 handler that returns a JSON body the Flutter client can
    branch on (errorCode='RATE_LIMITED' + retry_after_seconds), instead of
    slowapi's plain "Rate limit exceeded" string.

    Also includes a Retry-After header so HTTP intermediaries can honor it.
    """
    from fastapi.responses import JSONResponse

    # slowapi attaches the limit string (e.g. "30 per 1 minute") to exc.detail.
    # Parse the window seconds from it; default to 60.
    retry_after_seconds = 60
    try:
        detail_str = str(getattr(exc, "detail", "") or "")
        # detail looks like "30 per 1 minute" / "10 per 5 second"
        parts = detail_str.lower().split(" per ")
        if len(parts) == 2:
            window = parts[1].strip()
            if "second" in window:
                n = int(window.split()[0])
                retry_after_seconds = max(1, n)
            elif "minute" in window:
                n = int(window.split()[0])
                retry_after_seconds = max(1, n * 60)
            elif "hour" in window:
                n = int(window.split()[0])
                retry_after_seconds = max(1, n * 3600)
    except Exception:
        pass

    body = {
        "code": "RATE_LIMITED",
        "message": (
            "Too many requests in a short window. Please wait before trying again."
        ),
        "retry_after_seconds": retry_after_seconds,
        "detail": str(getattr(exc, "detail", "rate_limit_exceeded")),
    }
    headers = {"Retry-After": str(retry_after_seconds)}
    return JSONResponse(status_code=429, content=body, headers=headers)
