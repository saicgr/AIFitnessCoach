"""Tripwire counters that auto-revoke compromised MCP clients.

Keeps a small in-process sliding-window counter per
(user_id, client_id, tool_name). If a hard threshold is crossed — e.g.
>50 `log_meal_from_text` calls in 5 minutes — we immediately call
`revoke_all_mcp_tokens` for that user so Claude/ChatGPT is kicked out.

This is a belt-and-suspenders layer on top of rate_limit.py:
rate-limits reject the individual request; anomaly detection revokes the
entire token family. Both are needed because a sophisticated attacker
could alternate between tools to stay under any single bucket.

In-process state is fine because a real abuse loop will hit any one
worker many times. The Redis-backed rate-limiter already covers
multi-worker scenarios; this layer is a backstop for the hottest tools.
"""
from __future__ import annotations

import time
from collections import defaultdict, deque
from typing import Deque, Dict, Tuple

from core.logger import get_logger
from mcp.config import get_mcp_config
from mcp.subscription import revoke_all_mcp_tokens

logger = get_logger(__name__)
_cfg = get_mcp_config()


# Per-tool windows (seconds) and thresholds (events). Add entries here as
# new abuse patterns show up in the audit log.
#
# The any-tool tripwire catches generic blasts; tool-specific ones catch
# targeted abuse (e.g. filling the food log with garbage entries).
_TRIPWIRES: Dict[str, Tuple[int, int]] = {
    # tool_name: (window_seconds, max_events)
    "log_meal_from_text": (300, _cfg.ANOMALY_LOG_MEAL_PER_5MIN),
    "log_meal_from_image": (300, _cfg.ANOMALY_LOG_MEAL_PER_5MIN),
    "__any__": (60, _cfg.ANOMALY_ANY_TOOL_PER_MIN),
}

# Sliding-window of event timestamps per key. Keys are (user_id, client_id, tool_name)
# and one extra ("__any__" tool) per (user_id, client_id) for the blanket counter.
_WINDOWS: Dict[Tuple[str, str, str], Deque[float]] = defaultdict(deque)


class AnomalyTripped(Exception):
    """Raised after auto-revocation. Tool wrapper returns a clear error."""

    def __init__(self, tool_name: str, window_sec: int, count: int):
        self.tool_name = tool_name
        self.window_sec = window_sec
        self.count = count
        super().__init__(
            f"Anomaly tripwire: {count} calls to {tool_name} in {window_sec}s — tokens revoked"
        )


def _record(key: Tuple[str, str, str], now: float, window_sec: int) -> int:
    """Append `now` to the window and drop expired entries. Returns length."""
    dq = _WINDOWS[key]
    cutoff = now - window_sec
    while dq and dq[0] < cutoff:
        dq.popleft()
    dq.append(now)
    return len(dq)


async def check_anomaly(user_id: str, client_id: str, tool_name: str) -> None:
    """Record the call and raise AnomalyTripped if any tripwire fires.

    Side effects: on trip, revokes all MCP tokens for the user (so every
    other connected integration is kicked too — matches the
    "assume-compromised" posture).
    """
    now = time.time()
    client_id = str(client_id or "unknown")

    # Per-tool tripwire (if configured for this tool)
    tool_wire = _TRIPWIRES.get(tool_name)
    if tool_wire:
        window, limit = tool_wire
        count = _record((user_id, client_id, tool_name), now, window)
        if count > limit:
            logger.warning(
                f"MCP anomaly: user={user_id} client={client_id} tool={tool_name} "
                f"count={count} > {limit} in {window}s — revoking all tokens"
            )
            try:
                await revoke_all_mcp_tokens(user_id, reason="anomaly_detected")
            except Exception as e:
                logger.error(f"Failed to revoke on anomaly trip: {e}", exc_info=True)
            raise AnomalyTripped(tool_name, window, count)

    # Blanket any-tool tripwire
    any_wire = _TRIPWIRES["__any__"]
    window, limit = any_wire
    count = _record((user_id, client_id, "__any__"), now, window)
    if count > limit:
        logger.warning(
            f"MCP anomaly (any-tool): user={user_id} client={client_id} "
            f"count={count} > {limit} in {window}s — revoking all tokens"
        )
        try:
            await revoke_all_mcp_tokens(user_id, reason="anomaly_detected")
        except Exception as e:
            logger.error(f"Failed to revoke on anomaly trip: {e}", exc_info=True)
        raise AnomalyTripped("__any__", window, count)
