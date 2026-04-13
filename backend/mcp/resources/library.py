"""fitwiz://exercises/library resource — exercise catalog listing.

Returns a summary of the exercise library (names, muscle groups, equipment)
so MCP clients can reason about what exercises exist without needing RAG
access. We intentionally don't include instructional text here to keep
the payload small and to avoid lifting training data into a public
resource URI.
"""
from __future__ import annotations

import json
from typing import Any

from core.db import get_supabase_db
from core.logger import get_logger
from mcp.auth.scopes import require_scope
from mcp.middleware.auth import AuthError, require_user

logger = get_logger(__name__)


def register(mcp_app: Any) -> None:
    @mcp_app.resource("fitwiz://exercises/library")
    async def exercises_library(ctx) -> str:
        try:
            user = await require_user(ctx)
            # read:workouts gives visibility into the exercise library too —
            # no separate scope for it, since it's app-wide static data.
            require_scope(user.get("mcp_scopes") or [], "read:workouts")
            db = get_supabase_db()
            try:
                result = db.client.table("exercises") \
                    .select("id, name, target, body_part, equipment, secondary_muscles") \
                    .limit(2000) \
                    .execute()
                exercises = result.data or []
            except Exception as e:
                logger.error(f"exercises_library query failed: {e}", exc_info=True)
                exercises = []
            return json.dumps({"count": len(exercises), "exercises": exercises}, default=str)
        except AuthError as e:
            return json.dumps({"error": e.code, "message": e.message})
        except Exception as e:
            return json.dumps({"error": "resource_error", "detail": str(e)[:200]})
