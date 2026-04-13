"""Profile + body metrics MCP tools.

Read-only profile access and the `log_body_weight` / `update_user_goal`
write paths.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, Optional

from core.db import get_supabase_db
from core.logger import get_logger
from mcp.tools import run_tool

logger = get_logger(__name__)


# ─── get_user_profile ────────────────────────────────────────────────────────

async def _get_user_profile_impl(user: dict) -> Dict[str, Any]:
    """Return a trimmed user profile with goals/preferences."""
    db = get_supabase_db()
    full = db.get_user(user["id"])
    if not full:
        return {"ok": False, "error": "user_not_found"}

    # Ship only non-sensitive fields — no tokens, no auth secrets.
    safe_keys = {
        "id", "email", "name", "first_name", "last_name", "display_name",
        "age", "gender", "height_cm", "weight_kg",
        "fitness_level", "fitness_goals", "available_equipment",
        "weekly_workout_days", "daily_calorie_target",
        "daily_protein_target_g", "daily_carbs_target_g", "daily_fat_target_g",
        "workout_unit_preference", "body_weight_unit_preference",
        "increment_unit_preference", "timezone",
        "created_at", "updated_at",
    }
    profile = {k: v for k, v in full.items() if k in safe_keys}
    return {"ok": True, "profile": profile}


# ─── log_body_weight ─────────────────────────────────────────────────────────

async def _log_body_weight_impl(
    user: dict,
    weight: float,
    unit: str = "kg",
) -> Dict[str, Any]:
    """Insert a weight_logs row. weight is stored in kg in DB; convert if needed."""
    unit = (unit or "kg").lower()
    try:
        w = float(weight)
    except (TypeError, ValueError):
        return {"ok": False, "error": "invalid_weight"}
    if w <= 0 or w > 1000:
        return {"ok": False, "error": "weight_out_of_range"}

    if unit in ("lb", "lbs", "pound", "pounds"):
        weight_kg = round(w * 0.45359237, 3)
    elif unit in ("kg", "kilogram", "kilograms"):
        weight_kg = w
    else:
        return {"ok": False, "error": "invalid_unit"}

    db = get_supabase_db()
    row = {
        "user_id": user["id"],
        "weight_kg": weight_kg,
        "logged_at": datetime.now(timezone.utc).isoformat(),
        "source": "mcp",
    }
    try:
        result = db.client.table("weight_logs").insert(row).execute()
    except Exception as e:
        logger.error(f"log_body_weight insert failed: {e}", exc_info=True)
        return {"ok": False, "error": "insert_failed", "detail": str(e)[:200]}
    data = (result.data or [None])[0] or {}
    return {"ok": True, "log_id": data.get("id"), "weight_kg": weight_kg}


# ─── update_user_goal ────────────────────────────────────────────────────────

async def _update_user_goal_impl(
    user: dict,
    goal_type: str,
    value: Any,
) -> Dict[str, Any]:
    """Update one of the safe goal fields on the user profile.

    We allowlist which fields can be changed via MCP so a compromised
    client can't flip arbitrary booleans (e.g. is_admin).
    """
    allowed = {
        "daily_calorie_target",
        "daily_protein_target_g",
        "daily_carbs_target_g",
        "daily_fat_target_g",
        "weekly_workout_days",
        "fitness_goals",
        "fitness_level",
    }
    if goal_type not in allowed:
        return {"ok": False, "error": f"unsupported_goal:{goal_type}"}

    db = get_supabase_db()
    try:
        updated = db.update_user(user["id"], {goal_type: value})
    except Exception as e:
        logger.error(f"update_user_goal failed: {e}", exc_info=True)
        return {"ok": False, "error": "update_failed", "detail": str(e)[:200]}
    return {"ok": True, "updated": {goal_type: (updated or {}).get(goal_type, value)}}


# ─── Registrar ───────────────────────────────────────────────────────────────

def register(mcp_app: Any) -> None:
    @mcp_app.tool(
        name="get_user_profile",
        description="Return the user's profile, goals, and measurement preferences.",
    )
    async def get_user_profile(ctx) -> Dict[str, Any]:
        return await run_tool(
            ctx, "get_user_profile",
            required_scope="read:profile",
            impl=_get_user_profile_impl, args={},
        )

    @mcp_app.tool(
        name="log_body_weight",
        description="Log a body weight measurement. Unit is 'kg' or 'lbs'.",
    )
    async def log_body_weight(
        ctx, weight: float, unit: str = "kg",
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "log_body_weight",
            required_scope="write:logs",
            impl=_log_body_weight_impl,
            args={"weight": weight, "unit": unit},
        )

    @mcp_app.tool(
        name="update_user_goal",
        description=(
            "Update one allowlisted goal field on the user profile. Supported "
            "goal_type values: daily_calorie_target, daily_protein_target_g, "
            "daily_carbs_target_g, daily_fat_target_g, weekly_workout_days, "
            "fitness_goals, fitness_level."
        ),
    )
    async def update_user_goal(
        ctx, goal_type: str, value: Any,
    ) -> Dict[str, Any]:
        return await run_tool(
            ctx, "update_user_goal",
            required_scope="write:logs",
            impl=_update_user_goal_impl,
            args={"goal_type": goal_type, "value": value},
        )
