"""
Centralized exception handling utilities.

Provides safe error responses that don't leak internal details to clients.

Usage:
    from core.exceptions import safe_internal_error

    try:
        ...
    except Exception as e:
        raise safe_internal_error(e, "workout_generation", user_id=user_id)

Sentry integration
------------------
`safe_internal_error` now explicitly reports to Sentry with:

    - `module` tag      → the `context` string ("skill_progressions" etc.) so
                          alerts can be filtered per subsystem in the UI.
    - `error_class` tag → short exception class name, so "APIError" /
                          "ValidationError" / etc. group cleanly in Issues.
    - `pgrst_code` tag  → when the upstream cause is a PostgREST APIError,
                          its PGRST/SQLSTATE code (e.g. "PGRST202", "23503")
                          is surfaced as a tag. Lets us write a saved search
                          like `error_class:APIError pgrst_code:23503`
                          instead of scanning message bodies.
    - `extras`          → caller-supplied **kwargs (user_id, workout_id, …)
                          attached as event extras so the Sentry breadcrumb
                          panel has actionable detail without PII in tags.

The helper still returns a generic 500 HTTPException — no internal detail
is ever leaked to the client body.
"""
from __future__ import annotations

import logging
from typing import Any, Optional

from fastapi import HTTPException

logger = logging.getLogger(__name__)


def _extract_pgrst_code(exc: BaseException) -> str | None:
    """Best-effort extraction of a PostgREST / Postgres error code.

    PostgREST's `APIError` carries `.code` ('PGRST202', '23503', …) which is
    far more useful for alert routing than the default stringification. We
    can't `isinstance` it without importing postgrest at module scope (and
    we want this file safe to import in non-DB contexts), so we sniff by
    attribute name.
    """
    code = getattr(exc, "code", None)
    if isinstance(code, str) and code:
        return code
    # Supabase sometimes wraps the dict into `args[0]`
    args = getattr(exc, "args", None)
    if args and isinstance(args[0], dict):
        val = args[0].get("code")
        if isinstance(val, str) and val:
            return val
    return None


def safe_internal_error(e: Exception, context: str = "", **extras: Any) -> HTTPException:
    """
    Log the full error internally, report to Sentry with context, and return
    a safe HTTPException.

    Args:
        e: The original exception
        context: A label for where the error occurred — becomes the `module`
            tag in Sentry (e.g., "skill_progressions", "xp").
        **extras: Arbitrary key-value pairs attached to the Sentry event as
            `extras`. Useful: `user_id`, `workout_id`, `request_id`. Anything
            passed here is only on the Sentry event, never in the HTTP body.

    Returns:
        HTTPException with generic message (no internal details leaked)
    """
    logger.error(f"Internal error in {context}: {e}", exc_info=True)

    # Best-effort Sentry capture. Wrapped in a try so a broken Sentry
    # integration can never turn a 500 into a different 500.
    try:
        from core.sentry import capture_exception_with_context
        sentry_extras: dict[str, Any] = {
            "error_class": type(e).__name__,
            **extras,
        }
        pgrst_code = _extract_pgrst_code(e)
        if pgrst_code:
            sentry_extras["pgrst_code"] = pgrst_code
        capture_exception_with_context(
            e,
            module=context or None,
            **sentry_extras,
        )
    except Exception:  # noqa: BLE001
        # Never block the error path on Sentry plumbing.
        pass

    return HTTPException(
        status_code=500,
        detail="An internal error occurred. Please try again."
    )
