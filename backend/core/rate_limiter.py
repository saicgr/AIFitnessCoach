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
from slowapi.util import get_remote_address

# Single shared limiter instance
# Uses client IP address for rate limiting
# Default global limit: 100 requests per minute
limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])
