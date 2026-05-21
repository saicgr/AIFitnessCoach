"""Health & activity tools — exposes the wearable health snapshot to the
LangGraph agents.

A single on-demand tool, ``get_health_activity_summary``, that the coach
calls when the user asks about their sleep, recovery, steps, heart rate,
water, recent workouts, or weight trend and the answer is not already in
the pre-fetched ``health_context`` prompt block (Phase B2).

It delegates to ``HealthActivityMixin.get_health_activity_snapshot`` on
``UserContextService`` (Phase B1) via the same sync-wrap pattern sibling
tools use (``run_async_in_sync``), since LangChain offloads sync tools to
worker threads while the snapshot coroutine is bound to the main loop.

Hard rules (per CLAUDE.md + the approved plan):
  * No mock / fabricated data. The "no wearable" state is NORMAL — the
    snapshot returns ``{"has_data": False, ...}`` and this tool surfaces
    that cleanly so the agent answers generally without inventing numbers.
  * Health data is Art. 9 sensitive — the snapshot itself is consent-gated
    upstream; this tool just relays the result.

See plan Phase B2.
"""
from __future__ import annotations

from typing import Any, Dict

from langchain_core.tools import tool

from core.logger import get_logger

from .base import run_async_in_sync

logger = get_logger(__name__)


@tool
def get_health_activity_summary(
    user_id: str,
    days: int = 7,
) -> Dict[str, Any]:
    """
    Get the user's wearable health & activity snapshot.

    Use this tool when the user asks about their sleep, recovery / readiness,
    daily steps, step goal progress, active calories, resting / average heart
    rate, water intake, recent workouts, or body-weight trend — and the
    answer is not already visible in the conversation context.

    The data comes from the user's connected wearable (Health Connect /
    HealthKit). If the user has no wearable or has not granted health-data
    consent, this returns ``has_data: False`` — that is a NORMAL state, NOT
    an error. In that case answer generally and NEVER invent numbers.

    Args:
        user_id: The user's UUID (string).
        days: Trailing window in days for the step/calorie/HR averages
            (default 7).

    Returns:
        On success, a dict with ``success: True`` and ``has_data`` plus the
        snapshot fields (``last_night_sleep``, ``recovery``, ``steps``,
        ``active_calories``, ``heart_rate``, ``water_ml``, ``recent_workouts``,
        ``weight``, ``goals``, ``staleness``). When the user has no wearable
        or no consent: ``has_data: False`` with a ``reason`` and a plain
        ``message`` — surface that, do not fabricate numbers.
    """
    logger.info(
        f"Tool: Getting health activity summary for user {user_id}, days={days}"
    )

    try:
        # Imported lazily so the tools package has no import-time dependency
        # on the user_context service graph.
        from services.user_context.service import UserContextService

        service = UserContextService()
        snapshot = run_async_in_sync(
            service.get_health_activity_snapshot(str(user_id), days=days)
        )

        if not snapshot.get("has_data"):
            reason = snapshot.get("reason", "no_activity_data")
            if reason == "no_consent":
                message = (
                    "This user has not granted health-data access, so no "
                    "wearable health data is available. Answer generally and "
                    "do not invent any numbers."
                )
            else:
                message = (
                    "This user has no connected wearable or synced health "
                    "data. Answer generally and do not invent any numbers."
                )
            return {
                "success": True,
                "action": "get_health_activity_summary",
                "user_id": str(user_id),
                "has_data": False,
                "reason": reason,
                "message": message,
            }

        return {
            "success": True,
            "action": "get_health_activity_summary",
            "user_id": str(user_id),
            "has_data": True,
            **snapshot,
        }

    except Exception as e:
        logger.error(f"get_health_activity_summary failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "get_health_activity_summary",
            "user_id": str(user_id),
            "has_data": False,
            "message": f"Failed to get health activity summary: {str(e)}",
        }


# Registry slice — mirrors the ISSUE_*_TOOLS / WELLNESS_TOOLS convention so
# tools/__init__.py can splat it into ALL_TOOLS.
HEALTH_TOOLS = [
    get_health_activity_summary,
]
