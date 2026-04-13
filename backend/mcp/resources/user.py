"""fitwiz://user/* resources — profile snapshot."""
from __future__ import annotations

import json
from typing import Any

from mcp.middleware.auth import AuthError, require_user
from mcp.auth.scopes import require_scope
from mcp.tools.body import _get_user_profile_impl


def register(mcp_app: Any) -> None:
    @mcp_app.resource("fitwiz://user/profile")
    async def user_profile(ctx) -> str:
        """User profile JSON. Requires read:profile scope."""
        try:
            user = await require_user(ctx)
            require_scope(user.get("mcp_scopes") or [], "read:profile")
            data = await _get_user_profile_impl(user=user)
            return json.dumps(data, default=str, indent=2)
        except AuthError as e:
            return json.dumps({"error": e.code, "message": e.message})
        except Exception as e:
            return json.dumps({"error": "resource_error", "detail": str(e)[:200]})
