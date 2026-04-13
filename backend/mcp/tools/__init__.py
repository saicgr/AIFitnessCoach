"""MCP tool module.

Each submodule in this package defines a set of related tools (workouts,
nutrition, coach, body, exports). The shared `run_tool` helper here wires
up the full middleware chain so each tool only needs to implement its
domain logic.

Call convention for tool handlers:

    async def _impl(user: dict, **kwargs) -> dict: ...

    @mcp_app.tool(name="log_meal_from_text", description="...")
    async def log_meal_from_text(ctx, description, meal_type=None,
                                 consumed_at=None, confirmation_token=None):
        return await run_tool(
            ctx,
            "log_meal_from_text",
            required_scope="write:logs",
            impl=_impl,
            args={
                "description": description,
                "meal_type": meal_type,
                "consumed_at": consumed_at,
                "confirmation_token": confirmation_token,
            },
        )
"""
from __future__ import annotations

from typing import Any, Awaitable, Callable, Dict, Optional

from core.logger import get_logger
from mcp.auth.scopes import require_scope
from mcp.middleware.anomaly import AnomalyTripped, check_anomaly
from mcp.middleware.audit import AuditTimer, write_audit
from mcp.middleware.auth import AuthError, require_user
from mcp.middleware.confirmation import ConfirmationRequired, enforce_confirmation
from mcp.middleware.rate_limit import RateLimitExceeded, check_rate_limits

logger = get_logger(__name__)


def _error_envelope(code: str, message: str, **extra: Any) -> Dict[str, Any]:
    """Uniform error shape that MCP clients can parse."""
    out = {"error": code, "error_description": message, "ok": False}
    out.update(extra)
    return out


async def run_tool(
    ctx: Any,
    tool_name: str,
    *,
    required_scope: Optional[str],
    impl: Callable[..., Awaitable[Any]],
    args: Dict[str, Any],
) -> Dict[str, Any]:
    """Run a tool through the full middleware chain.

    Returns the tool result on success, or a structured error envelope
    on any failure (auth, rate-limit, scope, anomaly, confirmation, bug).
    Never raises — MCP clients get a deterministic response shape.
    """
    timer = AuditTimer()
    user: Optional[Dict[str, Any]] = None

    # 1. Auth
    try:
        user = await require_user(ctx)
    except AuthError as e:
        return _error_envelope(e.code, e.message)
    except Exception as e:  # pragma: no cover — defensive
        logger.error(f"MCP auth unexpected error in {tool_name}: {e}", exc_info=True)
        return _error_envelope("server_error", "Authentication system error")

    client_id = str(user.get("mcp_client_id") or "unknown")
    scopes = user.get("mcp_scopes") or []

    # 2. Scope
    if required_scope:
        try:
            require_scope(scopes, required_scope)
        except Exception as e:
            # require_scope raises FastAPI HTTPException with detail dict.
            detail = getattr(e, "detail", None) or {}
            code = (detail or {}).get("error") if isinstance(detail, dict) else "insufficient_scope"
            msg = (detail or {}).get("error_description") if isinstance(detail, dict) else str(e)
            await _safe_audit(
                user, tool_name, args, False, code or "insufficient_scope", timer.ms()
            )
            return _error_envelope(code or "insufficient_scope", msg or "Insufficient scope")

    # 3. Rate limit
    try:
        await check_rate_limits(user["id"], client_id, tool_name)
    except RateLimitExceeded as e:
        await _safe_audit(user, tool_name, args, False, f"rate_limit:{e.bucket}", timer.ms())
        return _error_envelope(
            "rate_limited",
            f"Rate limit exceeded ({e.bucket}). Retry in {e.retry_after_sec}s.",
            bucket=e.bucket,
            retry_after_sec=e.retry_after_sec,
        )

    # 4. Anomaly tripwire (may revoke tokens)
    try:
        await check_anomaly(user["id"], client_id, tool_name)
    except AnomalyTripped as e:
        await _safe_audit(user, tool_name, args, False, "anomaly_tripped", timer.ms())
        return _error_envelope(
            "anomaly_tripped",
            "Abnormal call pattern detected. Your MCP access has been revoked — "
            "please reconnect from the FitWiz app.",
            tool=e.tool_name,
        )

    # 5. Confirmation (for risky tools). Two-step flow: first call returns a
    # token; second call with the token proceeds.
    try:
        await enforce_confirmation(user_id=user["id"], tool_name=tool_name, args=args)
    except ConfirmationRequired as e:
        await _safe_audit(user, tool_name, args, False, "confirmation_required", timer.ms())
        return {
            "ok": False,
            "requires_confirmation": True,
            "confirmation_token": e.token,
            "reason": e.reason,
            "tool_name": e.tool_name,
            "instructions": (
                "This action requires confirmation. Re-call this tool with the "
                "same arguments plus `confirmation_token` set to the value above."
            ),
        }

    # 6. Execute
    try:
        result = await impl(user=user, **{k: v for k, v in args.items()
                                          if k != "confirmation_token"})
        await _safe_audit(user, tool_name, args, True, None, timer.ms())
        if isinstance(result, dict) and "ok" not in result:
            result = {"ok": True, **result}
        return result
    except Exception as e:
        err_code = type(e).__name__
        logger.error(f"MCP tool {tool_name} failed: {e}", exc_info=True)
        await _safe_audit(user, tool_name, args, False, err_code, timer.ms())
        return _error_envelope("tool_error", str(e) or "Tool execution failed")


async def _safe_audit(
    user: Optional[Dict[str, Any]],
    tool_name: str,
    args: Dict[str, Any],
    success: bool,
    error_code: Optional[str],
    latency_ms: int,
) -> None:
    if not user:
        return
    try:
        await write_audit(
            user_id=user["id"],
            client_id=user.get("mcp_client_id"),
            token_id=user.get("mcp_token_id"),
            tool_name=tool_name,
            scopes_used=user.get("mcp_scopes"),
            request_args=args,
            success=success,
            error_code=error_code,
            latency_ms=latency_ms,
        )
    except Exception as e:
        logger.warning(f"Audit write swallowed: {e}")
