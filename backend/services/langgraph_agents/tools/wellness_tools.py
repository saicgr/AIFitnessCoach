"""Wellness logging tools — exposes `log_event` to the LangGraph agents.

Single generalized tool that the chat agent calls when it detects the
user logged any kind of wellness event (workout, food, water, sleep,
weight, mood). Routes to `POST /api/v1/events/log` via direct in-process
call rather than HTTP for latency.

See plan section C2 (2026-05-10).
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from langchain_core.tools import tool

from core.logger import get_logger
from services.logging.catalog import (
    estimate_calories,
    get_activity,
    resolve_activity,
    resolve_day_offset,
    resolve_time_of_day,
    steps_to_walking_minutes,
)

logger = get_logger(__name__)


def _run_coro(coro):
    try:
        from .base import run_async_in_sync
        return run_async_in_sync(coro)
    except Exception:
        return asyncio.get_event_loop().run_until_complete(coro)


def _resolve_occurred_at(occurred_at_hint: Optional[str], user_tz: str = "UTC") -> str:
    """Convert hints like 'this morning' / 'yesterday' to a concrete UTC ISO."""
    now = datetime.now(timezone.utc)
    if not occurred_at_hint:
        return now.isoformat()
    days_offset = resolve_day_offset(occurred_at_hint)
    target_date = now + timedelta(days=days_offset)
    tod = resolve_time_of_day(occurred_at_hint)
    if tod:
        # Use midpoint of the window
        h_start, h_end = tod
        midpoint_hour = (h_start + h_end) // 2
        target_date = target_date.replace(hour=midpoint_hour, minute=0, second=0, microsecond=0)
    return target_date.isoformat()


@tool
def log_event(
    user_id: str,
    domain: str,
    payload: Optional[Dict[str, Any]] = None,
    occurred_at_hint: Optional[str] = None,
    source: str = "chat",
) -> Dict[str, Any]:
    """Log a wellness event to the user's timeline.

    Use this whenever the user reports completing a workout, eating
    food, drinking water, sleeping, weighing themselves, or sharing
    their mood. Examples:

    - "I did 30 min yoga today" → log_event(domain='workout',
      payload={'activity_type':'yoga','duration_minutes':30})
    - "Played basketball for 1 hour" → log_event(domain='workout',
      payload={'activity_type':'basketball','duration_minutes':60})
    - "I went for a 10000 step walk" → log_event(domain='workout',
      payload={'activity_type':'walk','duration_minutes':91,
               'metadata':{'steps':10000}})
    - "Drank a gallon of water today" → log_event(domain='water',
      payload={'volume_ml':3785})
    - "Slept 8 hours last night" → log_event(domain='sleep',
      payload={'duration_minutes':480}, occurred_at_hint='last night')
    - "I weigh 175 today" → log_event(domain='weight',
      payload={'weight_kg':79.4})
    - "Feeling great today" → log_event(domain='mood',
      payload={'mood':'great'})

    Args:
        user_id: User UUID (always pulled from the chat context — the
            agent must pass it explicitly).
        domain: One of 'workout' | 'food' | 'water' | 'sleep' |
            'weight' | 'mood'.
        payload: Domain-specific dict (see examples above).
        occurred_at_hint: Optional natural-language time hint
            ('this morning', 'yesterday', 'last night', 'tonight').
            If omitted, defaults to NOW.
        source: 'chat' (default), 'voice', or 'manual'.

    Returns:
        {
          'event_id': 'workout:<uuid>',
          'domain': 'workout',
          'created': True|False,
          'name': 'Yoga session',
          'calories': 110,
          'undo_token': '<signed-token>',
          'warning': null | '...',
        }
    """
    payload = payload or {}

    # Normalize activity_type for workouts via the deterministic catalog
    if domain == "workout":
        raw = payload.get("activity_type") or payload.get("activity") or ""
        activity = get_activity(raw) or resolve_activity(raw) or get_activity("other")
        if activity:
            payload["activity_type"] = activity.canonical_id

        # Steps → minutes if duration missing
        steps = (payload.get("metadata") or {}).get("steps")
        if not payload.get("duration_minutes") and steps:
            payload["duration_minutes"] = steps_to_walking_minutes(int(steps))

    occurred_at_iso = _resolve_occurred_at(occurred_at_hint)

    async def _do_log():
        # Direct in-process call — avoids HTTP round-trip + auth re-check.
        from api.v1.wellness.events import (
            EventLogRequest, log_event as endpoint_log_event,
        )
        from fastapi import Request as _Req

        # Build a minimal request shim. The endpoint only uses request for
        # `resolve_timezone(request, db, user_id)` which falls back gracefully
        # when headers are missing.
        scope = {"type": "http", "headers": [], "method": "POST", "path": "/events/log"}
        req = _Req(scope=scope, receive=None)

        # We must pass current_user, but the endpoint only checks Depends();
        # in-process bypass: call the underlying logic by constructing the
        # request body and invoking the function directly with a stub user.
        body = EventLogRequest(
            user_id=user_id,
            domain=domain,
            source=source,
            occurred_at=occurred_at_iso,
            payload=payload,
        )
        return await endpoint_log_event(
            request=req,
            body=body,
            current_user={"id": user_id},
        )

    response = _run_coro(_do_log())

    # Returned response is already a Pydantic model — convert to dict
    result = response.model_dump() if hasattr(response, "model_dump") else dict(response)

    # Tag with action='event_logged' so build_action_data_node forwards it
    # to the frontend, which uses it to refresh todayWorkoutProvider +
    # timelineProvider and surface the inline Undo button.
    result["action"] = "event_logged"
    return result


def _agent_user_id() -> str:
    """Best-effort lookup of the current user from agent context.

    The LangGraph agent state is threaded through callsites; for tools
    invoked outside of the agent loop, this should be overridden by
    passing `__user_id__` in payload. Raises if neither is available.
    """
    # Convention: the agent's nodes inject user_id into a contextvar
    # before invoking tools. If we can't read it, fail loudly so the
    # tool isn't silently writing under the wrong user.
    try:
        import contextvars
        ctx = _AGENT_USER_ID_VAR.get()
        if not ctx:
            raise RuntimeError(
                "log_event tool invoked without a user_id in agent context. "
                "Set api.v1.wellness.events._AGENT_USER_ID_VAR before calling."
            )
        return ctx
    except Exception as e:
        raise RuntimeError(f"log_event needs user_id in agent context: {e}")


# Context var the wellness agent sets before invoking tools
import contextvars
_AGENT_USER_ID_VAR: contextvars.ContextVar[str] = contextvars.ContextVar(
    "wellness_agent_user_id", default=""
)


def set_agent_user_id(user_id: str):
    """Called by the chat agent before invoking log_event."""
    _AGENT_USER_ID_VAR.set(user_id)


# Public registry
WELLNESS_TOOLS = [log_event]
