"""Two-step confirmation flow for risky tool calls.

The MCP spec has an "elicitation" primitive for interactive prompts, but
it's not universally supported. Our fallback works with any client:

  1. Client calls `modify_workout(workout_id=X, action="remove", ...)`.
  2. Server returns {"requires_confirmation": true, "confirmation_token": "abc123"}.
  3. Client re-calls same tool with `confirmation_token="abc123"` added.
  4. Server verifies the token matches the pending payload, deletes it, and
     executes.

Tokens live in `mcp_confirmation_tokens` (TTL 5 min per MCPConfig).
"""
from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from core.logger import get_logger
from core.supabase_client import get_supabase
from mcp.config import get_mcp_config

logger = get_logger(__name__)
_cfg = get_mcp_config()


class ConfirmationRequired(Exception):
    """Raised when the tool requires a confirmation round-trip.

    Tool wrapper catches this and returns a structured envelope to the
    MCP client so the caller LLM can re-invoke the tool with the token.
    """

    def __init__(self, token: str, tool_name: str, reason: str):
        self.token = token
        self.tool_name = tool_name
        self.reason = reason
        super().__init__(f"Confirmation required for {tool_name}: {reason}")


# ─── Risk classification ─────────────────────────────────────────────────────

def needs_confirmation(tool_name: str, args: Dict[str, Any]) -> Optional[str]:
    """Return a human-readable reason string if confirmation is required.

    Returns None when the call can execute immediately. Matches MCPConfig
    CONFIRMATION_REQUIRED_TOOLS entries, which are of the form
    `tool_name.sub_action`.
    """
    required: list = _cfg.CONFIRMATION_REQUIRED_TOOLS

    # modify_workout with action=remove
    if tool_name == "modify_workout" and args.get("action") == "remove":
        if "modify_workout.remove" in required:
            return "Removing exercises permanently affects your plan."

    # generate_workout_plan that replaces existing
    if tool_name == "generate_workout_plan" and args.get("replace_existing") is True:
        if "generate_workout_plan.replace" in required:
            return "This will replace your existing workout plan."

    # log_meal with >3000 kcal
    if tool_name in ("log_meal_from_text", "log_meal_from_image"):
        estimated = args.get("estimated_calories") or 0
        try:
            if int(estimated) > 3000 and "log_meal.over_3000_kcal" in required:
                return "Large meal log (>3000 kcal) — confirm the amount is correct."
        except (TypeError, ValueError):
            pass

    return None


# ─── Token lifecycle ─────────────────────────────────────────────────────────

def _new_token() -> str:
    return secrets.token_urlsafe(24)


async def issue_confirmation_token(
    *,
    user_id: str,
    tool_name: str,
    payload: Dict[str, Any],
) -> str:
    """Persist a short-lived token the client must echo back to execute."""
    token = _new_token()
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=_cfg.CONFIRMATION_TOKEN_TTL_SEC)
    supabase = get_supabase()
    try:
        supabase.client.table("mcp_confirmation_tokens").insert({
            "token": token,
            "user_id": user_id,
            "tool_name": tool_name,
            "payload": payload,
            "expires_at": expires_at.isoformat(),
        }).execute()
    except Exception as e:
        # If the table doesn't exist or insert fails, we can't safely enforce
        # the confirmation step. Log loudly and re-raise so the tool doesn't
        # silently bypass the guardrail.
        logger.error(f"Failed to issue MCP confirmation token: {e}", exc_info=True)
        raise
    return token


async def consume_confirmation_token(
    *,
    token: str,
    user_id: str,
    tool_name: str,
) -> Optional[Dict[str, Any]]:
    """Validate and delete a confirmation token.

    Returns the original payload on success, None if the token is missing,
    expired, revoked, or belongs to a different (user, tool) pair.
    """
    supabase = get_supabase()
    try:
        result = supabase.client.table("mcp_confirmation_tokens") \
            .select("token, user_id, tool_name, payload, expires_at") \
            .eq("token", token) \
            .limit(1) \
            .execute()
    except Exception as e:
        logger.error(f"MCP confirmation lookup failed: {e}", exc_info=True)
        return None

    rows = result.data or []
    if not rows:
        return None
    row = rows[0]

    if str(row["user_id"]) != str(user_id) or row["tool_name"] != tool_name:
        # Token was issued for a different user/tool — refuse.
        return None

    try:
        expires = datetime.fromisoformat(row["expires_at"].replace("Z", "+00:00"))
    except (ValueError, KeyError):
        return None
    if expires < datetime.now(timezone.utc):
        # Delete expired tokens opportunistically.
        try:
            supabase.client.table("mcp_confirmation_tokens").delete().eq("token", token).execute()
        except Exception:
            pass
        return None

    # Single-use: delete before returning so replay attempts fail.
    try:
        supabase.client.table("mcp_confirmation_tokens").delete().eq("token", token).execute()
    except Exception as e:
        logger.warning(f"Failed to delete consumed confirmation token: {e}")

    return row.get("payload") or {}


async def enforce_confirmation(
    *,
    user_id: str,
    tool_name: str,
    args: Dict[str, Any],
) -> None:
    """Raise ConfirmationRequired if needed, or consume the presented token.

    The tool wrapper calls this before executing. On first call (no token),
    this issues one and raises. On the second call (with token), this
    consumes it and returns silently.
    """
    reason = needs_confirmation(tool_name, args)
    if reason is None:
        return

    presented = args.get("confirmation_token")
    if presented:
        payload = await consume_confirmation_token(
            token=presented,
            user_id=user_id,
            tool_name=tool_name,
        )
        if payload is None:
            raise ConfirmationRequired(
                token="",
                tool_name=tool_name,
                reason="Confirmation token is invalid or expired. Re-request the action.",
            )
        return  # Confirmed — proceed.

    # No token presented — issue one and raise.
    token = await issue_confirmation_token(
        user_id=user_id,
        tool_name=tool_name,
        payload={k: v for k, v in args.items() if k != "confirmation_token"},
    )
    raise ConfirmationRequired(token=token, tool_name=tool_name, reason=reason)
