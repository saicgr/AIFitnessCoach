"""
Sentry error tracking — modular init for the FastAPI backend.

Kept deliberately lightweight:
- Silent no-op when SENTRY_DSN is unset (local dev, CI).
- Never blocks app startup on init failure.
- Filters 4xx client errors so only real 5xx/unexpected exceptions page us.
- Discord alerting is intentionally left untouched — Sentry runs alongside it.
"""
from __future__ import annotations

import logging
import os
from typing import Any, Optional

from core.config import Settings
from core.logger import get_logger

logger = get_logger(__name__)


def _before_send(event: dict, hint: dict) -> Optional[dict]:
    """Drop expected 4xx HTTPExceptions + benign stale-JWT AuthApiErrors so
    they don't count against quota.

    Filters applied, in order:
    1. 4xx HTTPException (fastapi OR starlette flavor — some middlewares
       surface the Starlette subclass directly, which an `exc_type is`
       check misses — hence `isinstance`).
    2. Supabase `AuthApiError` whose message matches a known stale-JWT
       marker. These fire on every request from a client whose token
       rotated or expired — 401 response is correct, Sentry event is
       noise. The marker list + helper live in `core.auth` so a later
       rename stays in one place.

    All imports are lazy + wrapped in try/except so a missing dependency
    or a rename in supabase-py can never break Sentry init.
    """
    exc_info = (hint or {}).get("exc_info")
    if not exc_info:
        return event
    _, exc_value, _ = exc_info

    try:
        from fastapi import HTTPException as _FastApiHTTPException
        from starlette.exceptions import HTTPException as _StarletteHTTPException
        if isinstance(exc_value, (_FastApiHTTPException, _StarletteHTTPException)):
            status = getattr(exc_value, "status_code", 500)
            if 400 <= status < 500:
                return None
    except Exception:
        pass  # HTTPException filter unavailable — fall through.

    try:
        from core.auth import is_stale_session_error
        if is_stale_session_error(exc_value):
            return None
    except Exception:
        pass  # core.auth not importable (shouldn't happen; defensive).

    return event


def init_sentry(settings: Settings) -> bool:
    """
    Initialize Sentry if a DSN is configured.

    Returns True when Sentry is active, False otherwise. Never raises —
    a broken Sentry should not take the API down.
    """
    # Skip Sentry under pytest. The SDK's background HTTP worker thread can
    # segfault during pytest teardown when an in-flight envelope POST is
    # interrupted (urllib3/ssl recv_into → SIGSEGV). pytest never needs
    # error tracking; suppress here so test runs on Render with SENTRY_DSN
    # set in env don't crash.
    import sys
    if "pytest" in sys.modules or os.environ.get("PYTEST_DISABLE_SENTRY") == "1":
        logger.info("ℹ️ pytest detected — Sentry init skipped.")
        return False

    dsn = settings.sentry_dsn
    if not dsn:
        logger.info("ℹ️ Sentry DSN not set — error tracking disabled.")
        return False

    try:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration
        from sentry_sdk.integrations.starlette import StarletteIntegration
        from sentry_sdk.integrations.asyncio import AsyncioIntegration
        from sentry_sdk.integrations.logging import LoggingIntegration
    except Exception as err:
        logger.warning(f"⚠️ sentry-sdk not installed — skipping init: {err}")
        return False

    env = settings.sentry_environment or settings.environment or "production"
    # Prefer explicit APP_VERSION, fall back to Render's auto-injected git SHA,
    # then to the config default. This keeps release tags meaningful even
    # when APP_VERSION isn't set.
    version = (
        settings.app_version
        if settings.app_version and settings.app_version != "0.0.0"
        else os.environ.get("RENDER_GIT_COMMIT", "0.0.0")[:12]
    )
    release = f"zealova-backend@{version}"

    try:
        sentry_sdk.init(
            dsn=dsn,
            environment=env,
            release=release,
            integrations=[
                StarletteIntegration(transaction_style="endpoint"),
                FastApiIntegration(transaction_style="endpoint"),
                AsyncioIntegration(),
                LoggingIntegration(
                    level=logging.INFO,       # breadcrumbs
                    event_level=logging.ERROR,  # reported events
                ),
            ],
            # Performance sampling — 10% by default, configurable via settings.
            traces_sample_rate=settings.sentry_traces_sample_rate,
            # Never auto-attach PII; user context is set explicitly per request.
            send_default_pii=False,
            # Attach stack traces to ALL events (including logger.error calls
            # without exc_info, capture_message, and warnings). Without this,
            # log-only events arrive in Sentry as a one-line message with no
            # frame context — making frontend triage of "where did this fire?"
            # impossible. Cost: ~1KB per event, negligible at our volume.
            attach_stacktrace=True,
            # Capture local variables in stack frames so we can see what value
            # blew up, not just where. Sentry redacts obvious secrets server-side.
            include_local_variables=True,
            # Bigger frame context window so the surrounding source lines are
            # visible in the Sentry UI without round-tripping to GitHub.
            max_request_body_size="medium",
            before_send=_before_send,
        )
    except Exception as err:
        logger.warning(f"⚠️ Sentry init failed (non-fatal): {err}")
        return False

    logger.info(f"✅ Sentry initialized: env={env} release={release}")
    return True


def set_user(user_id: Optional[str], **extra: Any) -> None:
    """Attach user context to the current Sentry scope. No-op if Sentry is off."""
    if not user_id:
        return
    try:
        import sentry_sdk
        sentry_sdk.set_user({"id": user_id, **extra})
    except Exception:
        pass


def clear_user() -> None:
    """Clear user context at the end of a request."""
    try:
        import sentry_sdk
        sentry_sdk.set_user(None)
    except Exception:
        pass


def set_request_context(
    *,
    request_id: Optional[str] = None,
    method: Optional[str] = None,
    path: Optional[str] = None,
    query: Optional[str] = None,
    user_agent: Optional[str] = None,
) -> None:
    """
    Attach request-scoped tags + context on the current Sentry scope.

    Tags are queryable in Sentry's UI; context is expanded on the event. We
    set both so that `request_id` can be searched AND shows up in the event
    body for copy-paste into our Render log viewer. Safe no-op when Sentry
    is not initialized — catches every exception so a broken integration
    can never tank a request.
    """
    try:
        import sentry_sdk
        scope = sentry_sdk.get_isolation_scope()
        if request_id:
            scope.set_tag("request_id", request_id)
        if method:
            scope.set_tag("http.method", method)
        if path:
            scope.set_tag("endpoint", path)
        if user_agent:
            scope.set_context(
                "request",
                {
                    "method": method,
                    "url": path,
                    "query_string": query or "",
                    "headers": {"user-agent": user_agent},
                },
            )
        else:
            scope.set_context(
                "request",
                {"method": method, "url": path, "query_string": query or ""},
            )
    except Exception:
        pass


def clear_request_context() -> None:
    """Clear per-request scope state at the end of a request."""
    try:
        import sentry_sdk
        scope = sentry_sdk.get_isolation_scope()
        scope.remove_tag("request_id")
        scope.remove_tag("http.method")
        scope.remove_tag("endpoint")
    except Exception:
        pass


def capture_exception_with_context(
    exc: BaseException,
    *,
    module: Optional[str] = None,
    **extras: Any,
) -> None:
    """
    Explicitly report an exception that we're about to swallow or wrap,
    with an optional module tag and free-form extras. Use this from
    `except Exception as e:` blocks that log-and-continue so Sentry still
    sees the full stack instead of losing it to downstream re-raises.
    """
    try:
        import sentry_sdk
        with sentry_sdk.new_scope() as scope:
            if module:
                scope.set_tag("module", module)
            for k, v in extras.items():
                try:
                    scope.set_extra(k, v)
                except Exception:
                    continue
            sentry_sdk.capture_exception(exc)
    except Exception:
        pass
