"""
Centralized exception handling utilities.

Provides safe error responses that don't leak internal details to clients.

Usage:
    from core.exceptions import safe_internal_error

    try:
        ...
    except Exception as e:
        raise safe_internal_error(e, "workout_generation")
"""
import logging
from fastapi import HTTPException

logger = logging.getLogger(__name__)


def safe_internal_error(e: Exception, context: str = "") -> HTTPException:
    """
    Log the full error internally and return a safe HTTPException.

    Args:
        e: The original exception
        context: A label for where the error occurred (e.g., "workout_generation")

    Returns:
        HTTPException with generic message (no internal details leaked)
    """
    logger.error(f"Internal error in {context}: {e}", exc_info=True)
    return HTTPException(
        status_code=500,
        detail="An internal error occurred. Please try again."
    )
