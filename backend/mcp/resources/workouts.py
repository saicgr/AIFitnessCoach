"""fitwiz://workouts/* resources — today + history snapshots."""
from __future__ import annotations

import json
from typing import Any

from mcp.auth.scopes import require_scope
from mcp.middleware.auth import AuthError, require_user
from mcp.tools.workouts import (
    _get_today_workout_impl,
    _get_workout_history_impl,
)


def register(mcp_app: Any) -> None:
    @mcp_app.resource("fitwiz://workouts/today")
    async def workouts_today(ctx) -> str:
        try:
            user = await require_user(ctx)
            require_scope(user.get("mcp_scopes") or [], "read:workouts")
            data = await _get_today_workout_impl(user=user)
            return json.dumps(data, default=str, indent=2)
        except AuthError as e:
            return json.dumps({"error": e.code, "message": e.message})
        except Exception as e:
            return json.dumps({"error": "resource_error", "detail": str(e)[:200]})

    @mcp_app.resource("fitwiz://workouts/history")
    async def workouts_history(ctx) -> str:
        """Last 30 days of workouts. Use the tool for filtered queries."""
        try:
            user = await require_user(ctx)
            require_scope(user.get("mcp_scopes") or [], "read:workouts")
            data = await _get_workout_history_impl(user=user, limit=30)
            return json.dumps(data, default=str, indent=2)
        except AuthError as e:
            return json.dumps({"error": e.code, "message": e.message})
        except Exception as e:
            return json.dumps({"error": "resource_error", "detail": str(e)[:200]})
