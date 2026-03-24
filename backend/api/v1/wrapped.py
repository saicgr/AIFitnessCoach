"""
Fitness Wrapped API endpoints.

Generates Spotify-Wrapped-style monthly fitness recaps with
aggregated stats and AI-generated personality cards.
"""

from fastapi import APIRouter, Depends, HTTPException, Request
import re

from core.logger import get_logger
from core.auth import get_current_user
from core.rate_limiter import limiter
from core.exceptions import safe_internal_error
from services.wrapped_service import get_or_generate_wrapped, get_available_periods, get_wrapped_summary

router = APIRouter()
logger = get_logger(__name__)

_PERIOD_RE = re.compile(r"^\d{4}-\d{2}$")


@router.get("/summary")
@limiter.limit("10/minute")
async def wrapped_summary(
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Return a high-level summary: all available wrapped periods with
    personality/volume info, current month progress, and collected
    personality count.
    """
    user_id = str(current_user["id"])
    auth_id = str(current_user.get("auth_id", user_id))
    logger.info(f"Getting wrapped summary for user={user_id}")

    try:
        summary = await get_wrapped_summary(user_id, auth_id)
        return summary
    except Exception as e:
        logger.error(f"Failed to get wrapped summary: {e}")
        raise safe_internal_error(e, "wrapped_summary")


@router.get("/available")
@limiter.limit("10/minute")
async def list_available_periods(
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Return months where the user has 3+ completed workouts,
    sorted newest first.
    """
    user_id = str(current_user["id"])
    auth_id = str(current_user.get("auth_id", user_id))
    logger.info(f"Listing available wrapped periods for user={user_id}")

    try:
        periods = await get_available_periods(user_id)
        return {"periods": periods}
    except Exception as e:
        logger.error(f"Failed to list wrapped periods: {e}")
        raise safe_internal_error(e, "wrapped_available_periods")


@router.get("/{period_key}")
@limiter.limit("5/minute")
async def get_wrapped(
    period_key: str,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Return the Fitness Wrapped for a specific month (e.g. "2026-02").
    Generates on first request, returns cached data on subsequent requests.
    """
    user_id = str(current_user["id"])
    auth_id = str(current_user.get("auth_id", user_id))
    logger.info(f"Getting wrapped for user={user_id} period={period_key}")

    # Validate period_key format
    if not _PERIOD_RE.match(period_key):
        raise HTTPException(status_code=400, detail="Invalid period_key format. Use YYYY-MM (e.g. 2026-02).")

    try:
        data = await get_or_generate_wrapped(user_id, period_key, auth_id=auth_id)
        return data
    except Exception as e:
        logger.error(f"Failed to generate wrapped: {e}")
        raise safe_internal_error(e, "wrapped_generate")
