"""Fasting MCP tools — reads and writes.

Read tools (scope read:fasting):
  - get_fasting_status  (active fast, if any, + streak)
  - get_fasting_history

Write tools (scope write:fasting):
  - start_fast
  - end_fast

All tools funnel through `run_tool` in `mcp.tools.__init__`, which handles
auth, scopes, rate limiting, anomaly detection, confirmation, and auditing.

Reuse, not reimplementation: every impl calls straight into the same
`api/v1/fasting.py` / `api/v1/fasting_endpoints.py` handlers the Flutter app
uses. Those handlers take `current_user: dict = Depends(get_current_user)` —
a plain Python default that FastAPI's DI resolves at the HTTP layer; calling
them directly from here with an explicit `current_user=user` (the same dict
`require_user` already resolved) works identically, no HTTP round-trip
needed. `end_fast` also takes `http_request: Request` (used only to read the
X-User-Timezone header via `resolve_timezone`) — that function explicitly
handles `request=None` by falling back to the DB `users.timezone` column, so
passing None here is safe and correct for an MCP caller.
"""
from __future__ import annotations

from mcp.server import Context  # SDK Context class, re-exported (package-shadow workaround)

from typing import Any, Dict, Optional

from core.logger import get_logger
from mcp.tools import run_tool

logger = get_logger(__name__)


def _dump(obj: Any) -> Any:
    """Normalize a pydantic BaseModel (or list/None of them) into plain JSON."""
    if obj is None:
        return None
    if isinstance(obj, list):
        return [_dump(o) for o in obj]
    if hasattr(obj, "model_dump"):
        return obj.model_dump()
    return obj


# ─── start_fast ───────────────────────────────────────────────────────────────

async def _start_fast_impl(
    user: dict,
    protocol: str,
    protocol_type: str,
    goal_duration_minutes: int,
    started_at: Optional[str] = None,
    mood_before: Optional[str] = None,
    notes: Optional[str] = None,
) -> Dict[str, Any]:
    """Start a new fast. protocol e.g. '16:8', '18:6', '5:2', '24h', 'OMAD';
    protocol_type is 'tre' | 'modified' | 'extended' | 'custom'."""
    from api.v1.fasting import start_fast, StartFastRequest

    body = StartFastRequest(
        user_id=user["id"],
        protocol=protocol,
        protocol_type=protocol_type,
        goal_duration_minutes=goal_duration_minutes,
        started_at=started_at,
        mood_before=mood_before,
        notes=notes,
    )
    result = await start_fast(data=body, current_user=user)
    return {"fast": _dump(result)}


# ─── end_fast ─────────────────────────────────────────────────────────────────

async def _end_fast_impl(
    user: dict,
    fast_id: str,
    notes: Optional[str] = None,
    mood_after: Optional[str] = None,
    energy_level: Optional[int] = None,
) -> Dict[str, Any]:
    """End an active fast and return the completion result + updated streak."""
    from api.v1.fasting import end_fast, EndFastRequest

    body = EndFastRequest(
        user_id=user["id"],
        notes=notes,
        mood_after=mood_after,
        energy_level=energy_level,
    )
    result = await end_fast(fast_id=fast_id, data=body, http_request=None, current_user=user)
    return _dump(result)


# ─── get_fasting_status ───────────────────────────────────────────────────────

async def _get_fasting_status_impl(user: dict) -> Dict[str, Any]:
    """Return the active fast (if any) plus the user's current streak."""
    from api.v1.fasting import get_active_fast
    from api.v1.fasting_endpoints import get_streak

    active = await get_active_fast(user_id=user["id"], current_user=user)

    streak: Optional[Dict[str, Any]] = None
    try:
        streak = _dump(await get_streak(user_id=user["id"], current_user=user))
    except Exception as e:
        logger.warning(f"get_fasting_status: streak lookup failed: {e}")

    return {"active_fast": _dump(active), "streak": streak}


# ─── get_fasting_history ──────────────────────────────────────────────────────

async def _get_fasting_history_impl(
    user: dict,
    limit: int = 50,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
) -> Dict[str, Any]:
    """List the user's completed/cancelled fasts (most recent first)."""
    from api.v1.fasting import get_fasting_history

    limit = max(1, min(int(limit or 50), 200))
    result = await get_fasting_history(
        user_id=user["id"],
        current_user=user,
        limit=limit,
        offset=0,
        from_date=from_date,
        to_date=to_date,
    )
    fasts = _dump(result) or []
    return {"fasts": fasts, "count": len(fasts)}


# ─── Tool registrar (called from server.py) ──────────────────────────────────

def register(mcp_app: Any) -> None:
    """Attach all fasting tools to a FastMCP app instance."""

    @mcp_app.tool(
        name="start_fast",
        description=(
            "Start a new fast. protocol is e.g. '16:8', '18:6', '20:4', '5:2', "
            "'24h', '36h', '48h', 'OMAD', or a custom label. protocol_type is "
            "'tre' (time-restricted eating), 'modified', 'extended', or 'custom'. "
            "goal_duration_minutes is the target fast length in minutes."
        ),
    )
    async def start_fast(
        ctx: Context,
        protocol: str,
        protocol_type: str,
        goal_duration_minutes: int,
        started_at: Optional[str] = None,
        mood_before: Optional[str] = None,
        notes: Optional[str] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "start_fast",
            required_scope="write:fasting",
            impl=_start_fast_impl,
            args={
                "protocol": protocol,
                "protocol_type": protocol_type,
                "goal_duration_minutes": goal_duration_minutes,
                "started_at": started_at,
                "mood_before": mood_before,
                "notes": notes,
            },
        )

    @mcp_app.tool(
        name="end_fast",
        description="End the user's active fast and return the completion result and updated streak.",
    )
    async def end_fast(
        ctx: Context,
        fast_id: str,
        notes: Optional[str] = None,
        mood_after: Optional[str] = None,
        energy_level: Optional[int] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "end_fast",
            required_scope="write:fasting",
            impl=_end_fast_impl,
            args={
                "fast_id": fast_id,
                "notes": notes,
                "mood_after": mood_after,
                "energy_level": energy_level,
            },
        )

    @mcp_app.tool(
        name="get_fasting_status",
        description="Return the user's currently active fast (if any) and their fasting streak.",
    )
    async def get_fasting_status(ctx: Context) -> Dict[str, Any]:
        return await run_tool(
            ctx, "get_fasting_status",
            required_scope="read:fasting",
            impl=_get_fasting_status_impl,
            args={},
        )

    @mcp_app.tool(
        name="get_fasting_history",
        description=(
            "List the user's past fasts. Supports optional from_date/to_date "
            "(YYYY-MM-DD) and a limit (default 50, max 200)."
        ),
    )
    async def get_fasting_history(
        ctx: Context,
        limit: int = 50,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "get_fasting_history",
            required_scope="read:fasting",
            impl=_get_fasting_history_impl,
            args={"limit": limit, "from_date": from_date, "to_date": to_date},
        )
