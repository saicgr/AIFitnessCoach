"""fitwiz://nutrition/* resources — daily summary snapshot."""
from __future__ import annotations

import json
from datetime import date, timedelta
from typing import Any

from core.db import get_supabase_db
from core.timezone_utils import get_user_today, resolve_timezone
from mcp.auth.scopes import require_scope
from mcp.middleware.auth import AuthError, require_user


def register(mcp_app: Any) -> None:
    @mcp_app.resource("fitwiz://nutrition/summary")
    async def nutrition_summary_7d() -> str:
        """7-day nutrition summary — totals per day."""
        try:
            ctx = mcp_app.get_context()
            user = await require_user(ctx)
            require_scope(user.get("mcp_scopes") or [], "read:nutrition")
            db = get_supabase_db()
            # MCP has no HTTP Request, so the zone comes from users.timezone.
            # The 7 days must be the USER's calendar days — walking back from a
            # UTC "today" both shifts the window and makes each day's totals
            # span the wrong 24h for anyone west of Greenwich.
            user_tz = resolve_timezone(None, db, user["id"])
            today = date.fromisoformat(get_user_today(user_tz))
            days = []
            for i in range(7):
                d = (today - timedelta(days=i)).isoformat()
                try:
                    summary = db.get_daily_nutrition_summary(user["id"], d, timezone_str=user_tz)
                except Exception:
                    summary = None
                days.append({"date": d, "summary": summary})
            return json.dumps({"days": days}, default=str, indent=2)
        except AuthError as e:
            return json.dumps({"error": e.code, "message": e.message})
        except Exception as e:
            return json.dumps({"error": "resource_error", "detail": str(e)[:200]})
