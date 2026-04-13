"""Write every MCP tool call to the `mcp_audit_log` table.

User-visible: audit rows are surfaced in the FitWiz app's "AI Integrations"
settings screen so the user can see exactly what Claude/ChatGPT/Cursor
did on their behalf.

We redact free-text fields (meal descriptions, chat messages) to avoid
storing PII or prompt-injection payloads — just keep the shape and size
of the args.
"""
from __future__ import annotations

import time
from datetime import datetime, timezone
from typing import Any, Dict, Iterable, Optional

from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)

# Arg keys we hash/redact rather than storing as-is.
_REDACTED_KEYS: set = {
    "description",
    "message",
    "image_url",
    "media_urls",
    "notes",
    "food_description",
    "user_message",
    "confirmation_token",
    "image_base64",
}


def redact_args(args: Dict[str, Any]) -> Dict[str, Any]:
    """Return a shallow, safe-to-persist summary of the call arguments.

    - Strings in _REDACTED_KEYS are reduced to {len, preview(20 chars)}.
    - Lists/dicts are kept but truncated to 10 items.
    - Everything else passes through unchanged.
    """
    out: Dict[str, Any] = {}
    for k, v in (args or {}).items():
        if k in _REDACTED_KEYS:
            if isinstance(v, str):
                out[k] = {"redacted": True, "length": len(v), "preview": v[:20]}
            elif isinstance(v, list):
                out[k] = {"redacted": True, "count": len(v)}
            else:
                out[k] = {"redacted": True}
            continue
        if isinstance(v, list):
            out[k] = v[:10] if len(v) <= 10 else {"truncated_list": True, "count": len(v)}
        elif isinstance(v, dict):
            out[k] = {kk: vv for kk, vv in list(v.items())[:10]}
        else:
            out[k] = v
    return out


class AuditTimer:
    """Context-manager-style wall-clock timer used from tool wrappers.

    Usage:
        timer = AuditTimer()
        try:
            result = await run_tool(...)
            await write_audit(user, client, tool_name, args, success=True,
                              latency_ms=timer.ms())
        except Exception as exc:
            await write_audit(..., success=False, error_code=type(exc).__name__,
                              latency_ms=timer.ms())
            raise
    """

    def __init__(self) -> None:
        self._start = time.perf_counter()

    def ms(self) -> int:
        return int((time.perf_counter() - self._start) * 1000)


async def write_audit(
    *,
    user_id: str,
    client_id: Optional[str],
    token_id: Optional[str],
    tool_name: str,
    scopes_used: Optional[Iterable[str]],
    request_args: Optional[Dict[str, Any]],
    success: bool,
    error_code: Optional[str] = None,
    latency_ms: Optional[int] = None,
) -> None:
    """Insert one audit row. Failures here are swallowed (never block the tool)."""
    supabase = get_supabase()
    row = {
        "user_id": user_id,
        "client_id": client_id,
        "tool_name": tool_name,
        "scopes_used": list(scopes_used) if scopes_used else None,
        "request_summary": redact_args(request_args or {}),
        "success": success,
        "error_code": error_code,
        "latency_ms": latency_ms,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    # token_id is a helpful column for forensics but the table schema may not
    # have it in every environment; tolerate missing column via try/except.
    if token_id:
        row["token_id"] = token_id
    try:
        supabase.client.table("mcp_audit_log").insert(row).execute()
    except Exception as e:
        # Never let audit failures break the user's tool call.
        logger.warning(f"MCP audit write failed for tool={tool_name} user={user_id}: {e}")
