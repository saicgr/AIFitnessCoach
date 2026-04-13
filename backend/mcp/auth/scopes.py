"""Scope validation and enforcement.

Scopes gate access to specific MCP tools. Master list is in MCPConfig.SCOPES.
Requesting a scope outside that list is rejected at /oauth/authorize.
"""
from __future__ import annotations

from typing import Iterable

from fastapi import HTTPException, status

from mcp.config import get_mcp_config

_cfg = get_mcp_config()


class InvalidScopeError(ValueError):
    """Raised when a client requests an unknown or malformed scope."""


def parse_scope_string(raw: str | None) -> list[str]:
    """Parse a space-separated scope string into a validated list.

    Empty/None input returns the default scope set.
    Unknown scopes raise InvalidScopeError.
    """
    if not raw or not raw.strip():
        return list(_cfg.DEFAULT_SCOPES)

    scopes = [s.strip() for s in raw.split() if s.strip()]
    unknown = [s for s in scopes if s not in _cfg.SCOPES]
    if unknown:
        raise InvalidScopeError(f"Unknown scope(s): {', '.join(unknown)}")
    return scopes


def describe_scopes(scopes: Iterable[str]) -> list[dict[str, str]]:
    """Return [{scope, description}] for the consent screen UI."""
    return [{"scope": s, "description": _cfg.SCOPES[s]} for s in scopes if s in _cfg.SCOPES]


def require_scope(granted: Iterable[str], required: str) -> None:
    """Raise 403 if `required` is not in `granted`.

    Use at tool-handler entry to enforce per-tool scope requirements.
    """
    if required not in granted:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "insufficient_scope",
                "error_description": f"This tool requires scope '{required}'.",
                "required_scope": required,
            },
        )


def require_any_scope(granted: Iterable[str], candidates: Iterable[str]) -> None:
    """Raise 403 unless at least one of `candidates` is in `granted`."""
    granted_set = set(granted)
    if not any(c in granted_set for c in candidates):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "insufficient_scope",
                "error_description": f"This tool requires one of: {', '.join(candidates)}.",
                "required_scope": list(candidates),
            },
        )
