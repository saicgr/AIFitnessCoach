"""Program-library MCP tools — reads and writes.

Read tools (scope read:programs):
  - get_available_programs
  - get_program_details
  - get_program_schedule
  - get_my_assigned_programs

Write tools (scope write:programs):
  - assign_program_to_schedule (slot='primary' requires confirmation — it
    ends any overlapping active primary assignment)

All tools funnel through `run_tool` in `mcp.tools.__init__`, which handles
auth, scopes, rate limiting, anomaly detection, confirmation, and auditing.

Reuse, not reimplementation: `get_program_details`/`get_program_schedule`/
`get_my_assigned_programs` call the SAME handlers the REST API and Flutter
app use (`api/v1/program_templates.py`), and `assign_program_to_schedule`
calls `assign_program_core` — the exact function already shared between the
HTTP `/assign` endpoint and the coach-chat `assign_program` tool
(`services/langgraph_agents/tools/program_tools.py`). `get_available_programs`
mirrors that same coach tool's lightweight direct-query browse (rather than
the heavier, caching `browse_library` HTTP handler, which is tuned for the
Flutter grid — Query-object defaults included).
"""
from __future__ import annotations

from mcp.server import Context  # SDK Context class, re-exported (package-shadow workaround)

from typing import Any, Dict, List, Optional

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


# ─── get_available_programs ──────────────────────────────────────────────────

async def _get_available_programs_impl(
    user: dict,
    category: Optional[str] = None,
    difficulty_level: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = 20,
) -> Dict[str, Any]:
    """Browse the published program library — lightweight cards.

    Direct query against `programs` (is_published + has_workouts), same
    predicate the coach's `recommend_program` tool uses. Kept intentionally
    simpler than the Flutter grid's `browse_library` HTTP handler (which adds
    branded-catalog merging, goal/equipment token filters, and long-TTL
    caching) — an AI client just needs a clean, filterable list.
    """
    from core.supabase_client import get_supabase

    db = get_supabase()
    limit = max(1, min(int(limit or 20), 100))

    query = (
        db.client.table("programs")
        .select(
            "id, program_name, editorial_name, program_category, "
            "difficulty_level, duration_weeks, sessions_per_week, "
            "tagline, who_for, goals, equipment_summary"
        )
        .eq("is_published", True)
        .eq("has_workouts", True)
    )
    if category:
        query = query.eq("program_category", category)
    if difficulty_level:
        query = query.eq("difficulty_level", difficulty_level)

    try:
        resp = query.execute()
    except Exception as e:
        logger.error(f"get_available_programs query failed: {e}", exc_info=True)
        return {"programs": [], "count": 0}

    rows = resp.data or []

    if search:
        needle = search.strip().lower()

        def _matches(row: Dict[str, Any]) -> bool:
            blob = " ".join(
                str(row.get(f) or "") for f in
                ("program_name", "editorial_name", "tagline", "who_for")
            ).lower()
            blob += " " + " ".join(str(g).lower() for g in (row.get("goals") or []))
            return needle in blob

        rows = [r for r in rows if _matches(r)]

    rows.sort(key=lambda r: (r.get("program_category") or "", r.get("program_name") or ""))
    rows = rows[:limit]

    programs = [
        {
            "id": str(r["id"]),
            "name": r.get("editorial_name") or r.get("program_name") or "Program",
            "category": r.get("program_category"),
            "difficulty_level": r.get("difficulty_level"),
            "duration_weeks": r.get("duration_weeks"),
            "sessions_per_week": r.get("sessions_per_week"),
            "tagline": r.get("tagline"),
            "who_for": r.get("who_for"),
            "equipment_summary": r.get("equipment_summary"),
        }
        for r in rows
    ]
    return {"programs": programs, "count": len(programs)}


# ─── get_program_details ─────────────────────────────────────────────────────

async def _get_program_details_impl(user: dict, program_id: str) -> Dict[str, Any]:
    """Full structured preview of one program (days/exercises), same payload
    the Flutter app's program-detail screen renders."""
    from api.v1.program_templates import library_program_detail

    result = await library_program_detail(program_id=program_id, current_user=user)
    return _dump(result)


# ─── get_program_schedule ────────────────────────────────────────────────────

async def _get_program_schedule_impl(
    user: dict,
    program_id: str,
    variant_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Multi-week exercise schedule for a program variant (or its default)."""
    from api.v1.program_templates import library_program_schedule

    result = await library_program_schedule(
        program_id=program_id, variant_id=variant_id, current_user=user,
    )
    return _dump(result)


# ─── get_my_assigned_programs ────────────────────────────────────────────────

async def _get_my_assigned_programs_impl(user: dict) -> Dict[str, Any]:
    """Active + recently-completed program assignments for the user."""
    from api.v1.program_templates import list_assignments

    result = await list_assignments(current_user=user)
    return _dump(result)


# ─── assign_program_to_schedule ──────────────────────────────────────────────

async def _assign_program_to_schedule_impl(
    user: dict,
    program_id: str,
    assigned_days: Optional[List[int]] = None,
    slot: str = "primary",
    duration_weeks: Optional[int] = None,
) -> Dict[str, Any]:
    """Start (assign) a published program via the SAME core logic the HTTP
    /assign endpoint and the coach-chat assign_program tool use: clone ->
    customize (level + injuries + equipment) -> create assignment -> expand
    dated workouts -> clear /today cache.

    slot='primary' (the default) ends any overlapping active primary
    assignment — that path is gated by the confirmation middleware in
    `mcp.middleware.confirmation`; this impl only runs after a valid
    confirmation_token when required.
    """
    from core.supabase_client import get_supabase
    from api.v1.program_templates import assign_program_core, CustomizeOptions

    db = get_supabase()
    try:
        result = await assign_program_core(
            db,
            user_id=user["id"],
            program_id=program_id,
            assigned_days=assigned_days or [],
            slot=(slot or "primary"),
            start_date=None,
            replace=True,
            duration_weeks=duration_weeks,
            customize=CustomizeOptions(),
        )
    except Exception as e:
        detail = getattr(e, "detail", None)
        msg = detail if isinstance(detail, str) else str(e) or "Could not start that program."
        logger.error(f"MCP assign_program_to_schedule failed: {e}", exc_info=True)
        return {"ok": False, "error": "assign_failed", "detail": msg}

    return {
        "ok": True,
        "program_id": result.get("program_id"),
        "program_name": result.get("program_name"),
        "assignment_id": result.get("assignment_id"),
        "template_id": result.get("template_id"),
        "workouts_created": result.get("workouts_created"),
    }


# ─── Tool registrar (called from server.py) ──────────────────────────────────

def register(mcp_app: Any) -> None:
    """Attach all program tools to a FastMCP app instance."""

    @mcp_app.tool(
        name="get_available_programs",
        description=(
            "Browse the published program library. Optional filters: category, "
            "difficulty_level, search (free text), limit (default 20, max 100)."
        ),
    )
    async def get_available_programs(
        ctx: Context,
        category: Optional[str] = None,
        difficulty_level: Optional[str] = None,
        search: Optional[str] = None,
        limit: int = 20,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "get_available_programs",
            required_scope="read:programs",
            impl=_get_available_programs_impl,
            args={
                "category": category,
                "difficulty_level": difficulty_level,
                "search": search,
                "limit": limit,
            },
        )

    @mcp_app.tool(
        name="get_program_details",
        description="Full structured preview of one program: days, exercises, sets/reps.",
    )
    async def get_program_details(ctx: Context, program_id: str) -> Dict[str, Any]:
        return await run_tool(
            ctx, "get_program_details",
            required_scope="read:programs",
            impl=_get_program_details_impl,
            args={"program_id": program_id},
        )

    @mcp_app.tool(
        name="get_program_schedule",
        description=(
            "Full multi-week exercise schedule for a program variant "
            "(variant_id optional — omit for the program's default)."
        ),
    )
    async def get_program_schedule(
        ctx: Context,
        program_id: str,
        variant_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "get_program_schedule",
            required_scope="read:programs",
            impl=_get_program_schedule_impl,
            args={"program_id": program_id, "variant_id": variant_id},
        )

    @mcp_app.tool(
        name="get_my_assigned_programs",
        description="List the user's active and recently-completed program assignments.",
    )
    async def get_my_assigned_programs(ctx: Context) -> Dict[str, Any]:
        return await run_tool(
            ctx, "get_my_assigned_programs",
            required_scope="read:programs",
            impl=_get_my_assigned_programs_impl,
            args={},
        )

    @mcp_app.tool(
        name="assign_program_to_schedule",
        description=(
            "Start a program from the library and schedule it. slot is 'primary' "
            "(default — replaces the current primary program, requires "
            "confirmation) or 'addon' (runs alongside, e.g. a cardio block). "
            "assigned_days is a list of weekdays (Mon=0..Sun=6); omit to start "
            "sequentially from today off the program's own training days."
        ),
    )
    async def assign_program_to_schedule(
        ctx: Context,
        program_id: str,
        assigned_days: Optional[List[int]] = None,
        slot: str = "primary",
        duration_weeks: Optional[int] = None,
        confirmation_token: Optional[str] = None,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "assign_program_to_schedule",
            required_scope="write:programs",
            impl=_assign_program_to_schedule_impl,
            args={
                "program_id": program_id,
                "assigned_days": assigned_days,
                "slot": slot,
                "duration_weeks": duration_weeks,
                "confirmation_token": confirmation_token,
            },
        )
