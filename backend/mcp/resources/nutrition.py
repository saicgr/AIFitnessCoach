"""fitwiz://nutrition/* resources — daily summary snapshot."""
from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from typing import Any

from core.db import get_supabase_db
from mcp.auth.scopes import require_scope
from mcp.middleware.auth import AuthError, require_user


def register(mcp_app: Any) -> None:
    @mcp_app.resource("fitwiz://nutrition/summary")
    async def nutrition_summary_7d(ctx) -> str:
        """7-day nutrition summary — totals per day."""
        try:
            user = await require_user(ctx)
            require_scope(user.get("mcp_scopes") or [], "read:nutrition")
            db = get_supabase_db()
            today = datetime.now(timezone.utc).date()
            days = []
            for i in range(7):
                d = (today - timedelta(days=i)).isoformat()
                try:
                    summary = db.get_daily_nutrition_summary(user["id"], d, timezone_str=None)
                except Exception:
                    summary = None
                days.append({"date": d, "summary": summary})
            return json.dumps({"days": days}, default=str, indent=2)
        except AuthError as e:
            return json.dumps({"error": e.code, "message": e.message})
        except Exception as e:
            return json.dumps({"error": "resource_error", "detail": str(e)[:200]})
