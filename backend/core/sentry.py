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
from core.logger import logger


def _before_send(event: dict, hint: dict) -> Optional[dict]:
    """Drop expected 4xx HTTPExceptions so they don't count against quota."""
    exc_info = (hint or {}).get("exc_info")
    if not exc_info:
        return event
    try:
        from fastapi import HTTPException  # local import to avoid circulars
    except Exception:
        return event
    exc_type, exc_value, _ = exc_info
    if exc_type is HTTPException:
        status = getattr(exc_value, "status_code", 500)
        if 400 <= status < 500:
            return None
    return event


def init_sentry(settings: Settings) -> bool:
    """
    Initialize Sentry if a DSN is configured.

    Returns True when Sentry is active, False otherwise. Never raises —
    a broken Sentry should not take the API down.
    """
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
    release = f"fitwiz-backend@{version}"

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
