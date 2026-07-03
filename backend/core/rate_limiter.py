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

from core.config import get_settings

logger = logging.getLogger(__name__)


def _resolve_rate_limit_storage_uri() -> str:
    """Pick the storage backend for the slowapi limiters.

    PROBLEM: slowapi's default in-memory store is PER-WORKER and
    PER-INSTANCE. With N Gunicorn workers a "10/minute" limit really allows
    ~N×10/min, and horizontal autoscaling loosens it further — at scale the
    caps are effectively not enforced.

    FIX: back the limiter with Redis (the same instance redis_cache.py uses,
    via settings.redis_url) so counters aggregate across every worker and
    instance. `limits` (slowapi's backend lib) speaks Redis natively given a
    `redis://...` storage_uri.

    GRACEFUL DEGRADATION: if REDIS_URL is unset, or Redis is unreachable at
    startup, fall back to the in-memory store ("memory://") and log a
    warning. The app must always start and serve — a degraded (per-worker)
    limiter is acceptable; a crash because Redis is down is not.

    Returns the storage URI string to hand to Limiter(storage_uri=...).
    """
    try:
        redis_url = get_settings().redis_url
    except Exception as e:  # config failure must not break the limiter
        logger.warning(
            f"Could not read settings for rate-limit storage ({e}) — "
            "using in-memory store (per-worker, does not aggregate)"
        )
        return "memory://"

    if not redis_url:
        logger.info(
            "No REDIS_URL configured — rate limiter using in-memory store "
            "(per-worker, does not aggregate across workers/instances)"
        )
        return "memory://"

    # Probe Redis reachability before committing to it. storage_from_string()
    # is lazy and won't fail here even if Redis is down, so we explicitly
    # check() and fall back to memory:// on any error.
    try:
        from limits.storage import storage_from_string

        probe = storage_from_string(redis_url)
        if not probe.check():
            raise RuntimeError("Redis storage check() returned False")
        logger.info(
            "Rate limiter using Redis store — limits aggregate across all "
            "workers and instances"
        )
        return redis_url
    except Exception as e:
        logger.warning(
            f"Redis unreachable for rate limiting ({e}) — falling back to "
            "in-memory store (per-worker, does not aggregate)"
        )
        return "memory://"


# Resolved once at import time. Either a redis:// URI (shared, aggregating)
# or "memory://" (per-worker fallback). Both limiters share this backend.
_RATE_LIMIT_STORAGE_URI = _resolve_rate_limit_storage_uri()

# Redis-only connection hardening, passed through limits.RedisStorage to
# redis.from_url(). The limits library keeps its OWN connection pool —
# main.py's Redis keepalive ping never touches it — so after a long idle
# stretch the provider reaps the TCP connection and the next rate-limit
# hit dies with SSLEOFError/ConnectionError (slowapi swallows it, one
# request goes unlimited). health_check_interval makes redis-py PING and
# transparently reconnect any pooled connection idle longer than 30s
# before reuse; socket_keepalive keeps the OS probing in between.
# MemoryStorage doesn't take these kwargs, so gate on the URI scheme.
_RATE_LIMIT_STORAGE_OPTIONS = (
    {"health_check_interval": 30, "socket_keepalive": True}
    if _RATE_LIMIT_STORAGE_URI.startswith(("redis://", "rediss://", "redis+unix://"))
    else {}
)


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
# Default IP limit: 1000 requests/minute. Deliberately high — many users
# share one IP behind carrier-grade NAT / corporate networks, so a tight
# per-IP cap punishes legitimate traffic. The real abuse guard is the tight
# per-ENDPOINT decorators on expensive routes (e.g. @limiter.limit("5/minute")
# on /generate-stream). swallow_errors=True prevents 500s if limiting fails.
import os as _os
# BENCH_BYPASS_RATELIMIT=1 disables the limiter entirely so the Phase-2
# full-sweep bench script can fire 500+ scans through one local instance
# without hitting the 10/min per-endpoint cap. NEVER set this in prod.
_BENCH_BYPASS = _os.environ.get("BENCH_BYPASS_RATELIMIT") == "1"
limiter = Limiter(
    key_func=get_real_client_ip,
    default_limits=[] if _BENCH_BYPASS else ["1000/minute"],
    storage_uri=_RATE_LIMIT_STORAGE_URI,
    storage_options=_RATE_LIMIT_STORAGE_OPTIONS,
    swallow_errors=True,
    enabled=not _BENCH_BYPASS,
)


# ---------------------------------------------------------------------------
# Crash-proof rate-limit middleware
# ---------------------------------------------------------------------------
# slowapi 0.1.9's SlowAPIMiddleware.dispatch ends with:
#     if should_inject_headers:
#         response = limiter._inject_headers(response, request.state.view_rate_limit)
# `should_inject_headers` is True whenever the limit check ran without raising,
# but `request.state.view_rate_limit` is set ONLY on the success path inside
# Limiter.__evaluate_limits. With `swallow_errors=True` and no in-memory
# fallback, a transient storage error (e.g. a Redis blip) is swallowed and the
# function returns *before* setting the attribute — yet `should_inject_headers`
# is still True. The middleware then reads a missing attribute and raises
# `AttributeError: 'State' object has no attribute 'view_rate_limit'`, which
# escapes as an HTTP 500 (seen most on `GET /`, hammered by Render health pings).
#
# This subclass reuses slowapi's own helpers but injects headers only when the
# attribute is actually present. `_inject_headers(resp, None)` is itself a no-op,
# so the guard degrades gracefully — the request succeeds without X-RateLimit-*
# headers instead of 500ing. Version-faithful with the vendored 0.1.9 dispatch.
from slowapi.middleware import (  # noqa: E402
    SlowAPIMiddleware,
    _find_route_handler,
    _should_exempt,
    sync_check_limits,
)
from starlette.responses import Response  # noqa: E402


class SafeSlowAPIMiddleware(SlowAPIMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        # Pre-seed for slowapi's DECORATOR path. Endpoints wrapped by
        # @limiter.limit(...) run extension.py's async_wrapper, which reads
        # `request.state.view_rate_limit` unconditionally AFTER the endpoint
        # returns (extension.py:739). On a swallowed storage error (Redis
        # blip) the attribute is never set, so the endpoint succeeds and
        # THEN 500s on header injection. request.state is backed by
        # scope["state"], so this seed is visible downstream; and
        # _inject_headers(resp, None) is an explicit no-op (extension.py:380
        # guards `current_limit is not None`), so the worst case is a
        # response without X-RateLimit-* headers instead of a 500.
        request.state.view_rate_limit = None

        app = request.app
        limiter_ = app.state.limiter

        if not limiter_.enabled:
            return await call_next(request)

        handler = _find_route_handler(app.routes, request.scope)
        if _should_exempt(limiter_, handler):
            return await call_next(request)

        error_response, should_inject_headers = sync_check_limits(
            limiter_, request, handler, app
        )
        if error_response is not None:
            return error_response

        response = await call_next(request)
        # GUARD: only inject when the success path actually recorded the limit.
        if should_inject_headers and hasattr(request.state, "view_rate_limit"):
            response = limiter_._inject_headers(
                response, request.state.view_rate_limit
            )
        return response


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
# More reliable than IP-based limiting behind proxies.
# Default 600/minute: the app legitimately fires ~40 calls on launch plus
# steady polling (/workouts/today every ~5s etc.), so 100/min tripped real
# users. Expensive routes still carry their own tight per-endpoint limits.
user_limiter = Limiter(
    key_func=get_user_id_from_request,
    default_limits=[] if _BENCH_BYPASS else ["600/minute"],
    storage_uri=_RATE_LIMIT_STORAGE_URI,
    storage_options=_RATE_LIMIT_STORAGE_OPTIONS,
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
