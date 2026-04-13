"""Per-user-per-client rate limits for MCP tool calls.

Limits are defined in `MCPConfig` and enforced via Redis counters
(INCR + EXPIRE). If Redis is unavailable, `RedisCache` transparently
falls back to an in-process dict so single-worker dev still rate-limits
correctly.

Buckets per (user_id, client_id):
  - per-minute global       — RATE_LIMIT_PER_MIN
  - per-hour global         — RATE_LIMIT_PER_HOUR
  - per-hour writes         — WRITE_LIMIT_PER_HOUR       (writes only)
  - per-hour chat           — CHAT_LIMIT_PER_HOUR        (chat_with_coach)
  - per-hour generate       — GENERATE_LIMIT_PER_HOUR    (generate_workout_plan)
"""
from __future__ import annotations

import time
from typing import Iterable, Optional

from core.logger import get_logger
from core.redis_cache import RedisCache
from mcp.config import get_mcp_config

logger = get_logger(__name__)
_cfg = get_mcp_config()

# Tools that mutate user data — subject to WRITE_LIMIT_PER_HOUR.
WRITE_TOOLS: set = {
    "log_meal_from_text",
    "log_meal_from_image",
    "log_water",
    "log_completed_set",
    "log_body_weight",
    "adjust_set_weight",
    "modify_workout",
    "generate_workout_plan",
    "update_user_goal",
}

# Specialized-limit tool sets (additive — a tool can be in WRITE_TOOLS AND here).
CHAT_TOOLS: set = {"chat_with_coach"}
GENERATE_TOOLS: set = {"generate_workout_plan"}


class RateLimitExceeded(Exception):
    """Raised when any rate-limit bucket is exhausted.

    `bucket` names the tripped bucket for logging; `retry_after_sec`
    is the wall-clock time until the next window starts.
    """

    def __init__(self, bucket: str, retry_after_sec: int):
        self.bucket = bucket
        self.retry_after_sec = retry_after_sec
        super().__init__(f"Rate limit exceeded: {bucket}; retry in {retry_after_sec}s")


# ─── Internal helpers ────────────────────────────────────────────────────────

# RedisCache stores JSON-serialized values. We (ab)use it as a counter by
# storing ints. It handles set/get; we need to do read-modify-write.
# True atomic INCR would be ideal but requires raw redis access; for our
# rate-limit scale (30/min/user), the tiny race window is acceptable.

_minute_cache = RedisCache(prefix="mcp_rl_min", ttl_seconds=60)
_hour_cache = RedisCache(prefix="mcp_rl_hr", ttl_seconds=3600)
_write_cache = RedisCache(prefix="mcp_rl_wr", ttl_seconds=3600)
_chat_cache = RedisCache(prefix="mcp_rl_ch", ttl_seconds=3600)
_gen_cache = RedisCache(prefix="mcp_rl_gn", ttl_seconds=3600)


async def _incr(cache: RedisCache, key: str) -> int:
    """Read-modify-write counter. Returns the new count."""
    current = await cache.get(key)
    new = (int(current) if current is not None else 0) + 1
    await cache.set(key, new)
    return new


def _bucket_key(user_id: str, client_id: Optional[str], window_id: int) -> str:
    """Per-user-per-client bucket key, partitioned by the current window."""
    cid = str(client_id or "unknown")
    return f"{user_id}:{cid}:{window_id}"


# ─── Entry point ─────────────────────────────────────────────────────────────

async def check_rate_limits(
    user_id: str,
    client_id: Optional[str],
    tool_name: str,
) -> None:
    """Raise RateLimitExceeded if any applicable bucket is over limit."""
    now = int(time.time())
    minute_win = now // 60
    hour_win = now // 3600

    # 1. Per-minute global
    count = await _incr(_minute_cache, _bucket_key(user_id, client_id, minute_win))
    if count > _cfg.RATE_LIMIT_PER_MIN:
        raise RateLimitExceeded("per_minute", 60 - (now % 60))

    # 2. Per-hour global
    count = await _incr(_hour_cache, _bucket_key(user_id, client_id, hour_win))
    if count > _cfg.RATE_LIMIT_PER_HOUR:
        raise RateLimitExceeded("per_hour", 3600 - (now % 3600))

    # 3. Write bucket (only for write tools)
    if tool_name in WRITE_TOOLS:
        count = await _incr(_write_cache, _bucket_key(user_id, client_id, hour_win))
        if count > _cfg.WRITE_LIMIT_PER_HOUR:
            raise RateLimitExceeded("writes_per_hour", 3600 - (now % 3600))

    # 4. Chat bucket
    if tool_name in CHAT_TOOLS:
        count = await _incr(_chat_cache, _bucket_key(user_id, client_id, hour_win))
        if count > _cfg.CHAT_LIMIT_PER_HOUR:
            raise RateLimitExceeded("chat_per_hour", 3600 - (now % 3600))

    # 5. Generate bucket
    if tool_name in GENERATE_TOOLS:
        count = await _incr(_gen_cache, _bucket_key(user_id, client_id, hour_win))
        if count > _cfg.GENERATE_LIMIT_PER_HOUR:
            raise RateLimitExceeded("generate_per_hour", 3600 - (now % 3600))
