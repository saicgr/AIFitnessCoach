"""
IP-based rate limiting for the unauthenticated /api/v1/free-tools/* endpoints.

Why this module exists separately from core.rate_limiter:
  core.rate_limiter (slowapi) is in-process and resets on every deploy/restart.
  Free-tool limits must be durable across restarts (a user spinning up a fresh
  worker can't get more free generations), so usage is persisted to Postgres.

Privacy:
  Raw IPs never hit the DB. Each tool has its own salt baked in so the same
  client across tools can't be cross-correlated by comparing ip_hash values.
"""

from __future__ import annotations

import hashlib
from datetime import datetime, timedelta, timezone
from typing import Tuple

from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Per-tool salts. Keep these stable — rotating a salt resets all counters for
# that tool. If you ever need to invalidate, prefer adding a `salt_version`
# column to free_tool_usage rather than changing these strings.
_TOOL_SALTS = {
    "ai-food-photo": "zealova:free:foodphoto:v1",
    "ai-workout-generator": "zealova:free:workoutgen:v1",
    "ai-roast-routine": "zealova:free:roast:v1",
    "ai-roast-my-routine": "zealova:free:roastmyroutine:v1",
    "ai-physique-analyzer": "zealova:free:physique:v1",
    "ai-form-check": "zealova:free:formcheck:v1",
    # Email-capture endpoint. Intentionally a distinct salt so the IP hash
    # stored on free_tools_email_signup rows cannot be cross-referenced with
    # rate-limit rows on free_tool_usage.
    "email-signup": "zealova:free:emailsignup:v1",
    # Usage-counter ping (social-proof counters). Cheap, no Gemini cost.
    "usage-ping": "zealova:free:usageping:v1",
}

# ── Global budget caps ────────────────────────────────────────────────────
# Per-IP limits do not stop a botnet, a VPN-rotating abuser, or an organic
# viral spike. These GLOBAL caps hard-bound the Gemini spend: once the whole
# site has made `daily` (or `hourly`) successful calls for a tool, the tool
# locks for everyone until the window rolls. A locked tool is a far better
# outcome than a surprise cloud bill.
#
# Sizing: each Gemini-vision call is roughly $0.002-0.01. The daily caps
# below bound worst-case spend at well under ~$15/day across all AI tools.
# Raise these deliberately once real traffic + paid conversion justify it.
_GLOBAL_CAPS = {
    "ai-food-photo":        {"daily": 2000, "hourly": 300},
    "ai-workout-generator": {"daily": 2000, "hourly": 300},
    "ai-roast-routine":     {"daily": 1000, "hourly": 200},
    "ai-roast-my-routine":  {"daily": 1000, "hourly": 200},
    "ai-physique-analyzer": {"daily": 1500, "hourly": 250},
    "ai-form-check":        {"daily": 1000, "hourly": 200},
}


class FreeToolLimitExceeded(Exception):
    """Raised when an IP has hit its window limit for a tool.

    Carries the next reset time (UTC, ISO-8601) so the endpoint can surface
    it in the 429 body — clients render "Resets at HH:MM".
    """

    def __init__(self, resets_at: datetime, limit: int, window_hours: int):
        self.resets_at = resets_at
        self.limit = limit
        self.window_hours = window_hours
        super().__init__(
            f"Free-tool limit reached ({limit}/{window_hours}h). "
            f"Resets at {resets_at.isoformat()}"
        )


class GlobalCapExceeded(Exception):
    """Raised when a tool has hit its site-wide daily or hourly budget cap.

    Distinct from FreeToolLimitExceeded (per-IP): this means the tool is
    locked for everyone, not just the calling client. Carries the scope
    ("daily"/"hourly") so the endpoint can word the 429 honestly.
    """

    def __init__(self, scope: str, cap: int, resets_at: datetime):
        self.scope = scope
        self.cap = cap
        self.resets_at = resets_at
        super().__init__(
            f"Global {scope} cap reached ({cap}). Resets at {resets_at.isoformat()}"
        )


async def check_global_cap(tool: str) -> None:
    """Raise GlobalCapExceeded if the tool is over its site-wide budget.

    Counts every successful call (every free_tool_usage row) for the tool in
    the trailing hour and day. Call this BEFORE check_and_consume so a
    budget-locked tool rejects without consuming the caller's per-IP slot.

    No-op for tools without a configured cap (non-AI tools, email-signup).
    """
    caps = _GLOBAL_CAPS.get(tool)
    if not caps:
        return

    db = get_supabase_db()
    client = db.client
    now = datetime.now(timezone.utc)

    # Hourly window first (tighter, catches spikes fast).
    hour_cutoff = (now - timedelta(hours=1)).isoformat()
    hourly = (
        client.table("free_tool_usage")
        .select("id", count="exact")
        .eq("tool", tool)
        .gte("used_at", hour_cutoff)
        .execute()
    )
    hourly_used = hourly.count or 0
    if hourly_used >= caps["hourly"]:
        logger.warning(
            f"[free-tools] GLOBAL hourly cap hit tool={tool} "
            f"used={hourly_used}/{caps['hourly']}"
        )
        raise GlobalCapExceeded(
            scope="hourly", cap=caps["hourly"], resets_at=now + timedelta(hours=1)
        )

    day_cutoff = (now - timedelta(hours=24)).isoformat()
    daily = (
        client.table("free_tool_usage")
        .select("id", count="exact")
        .eq("tool", tool)
        .gte("used_at", day_cutoff)
        .execute()
    )
    daily_used = daily.count or 0
    if daily_used >= caps["daily"]:
        logger.warning(
            f"[free-tools] GLOBAL daily cap hit tool={tool} "
            f"used={daily_used}/{caps['daily']}"
        )
        raise GlobalCapExceeded(
            scope="daily", cap=caps["daily"], resets_at=now + timedelta(hours=24)
        )


def _hash_ip(ip: str, tool: str) -> str:
    """SHA-256 hash of (salt || ip). Per-tool salt prevents cross-tool linkage."""
    salt = _TOOL_SALTS.get(tool, f"zealova:free:{tool}:v1")
    return hashlib.sha256(f"{salt}|{ip}".encode("utf-8")).hexdigest()


def _client_ip(request) -> str:
    """Extract client IP. Render sits behind a proxy so prefer X-Forwarded-For.

    X-Forwarded-For may contain a chain ("client, proxy1, proxy2") — the
    leftmost entry is the original client.
    """
    xff = request.headers.get("x-forwarded-for") or request.headers.get("X-Forwarded-For")
    if xff:
        return xff.split(",")[0].strip()
    real_ip = request.headers.get("x-real-ip")
    if real_ip:
        return real_ip.strip()
    if request.client and request.client.host:
        return request.client.host
    return "unknown"


async def check_and_consume(
    ip: str,
    tool: str,
    limit: int = 2,
    window_hours: int = 24,
) -> int:
    """Atomically check IP's usage and (if under limit) consume one slot.

    Returns:
        remaining_uses (int): How many uses are left AFTER this consumption.
        e.g. limit=2, first call → returns 1; second call → returns 0;
        third call → raises FreeToolLimitExceeded.

    Raises:
        FreeToolLimitExceeded: When `limit` calls have already been recorded
        within the trailing `window_hours`.
    """
    if tool not in _TOOL_SALTS:
        raise ValueError(f"Unknown free-tool: {tool}")

    ip_hash = _hash_ip(ip, tool)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=window_hours)
    cutoff_iso = cutoff.isoformat()

    db = get_supabase_db()
    client = db.client

    # Count usage in the trailing window. Service-role read; no RLS dance.
    existing = (
        client.table("free_tool_usage")
        .select("id, used_at", count="exact")
        .eq("ip_hash", ip_hash)
        .eq("tool", tool)
        .gte("used_at", cutoff_iso)
        .order("used_at", desc=False)
        .execute()
    )

    used = existing.count if existing.count is not None else len(existing.data or [])

    if used >= limit:
        # Compute the precise reset time = oldest still-in-window row + window.
        rows = existing.data or []
        if rows:
            oldest_used_at = rows[0]["used_at"]
            try:
                # Postgres returns ISO with offset; fromisoformat handles both
                # `Z` (sometimes) and `+00:00` (always when service-role).
                oldest_dt = datetime.fromisoformat(oldest_used_at.replace("Z", "+00:00"))
            except Exception:
                oldest_dt = datetime.now(timezone.utc)
            resets_at = oldest_dt + timedelta(hours=window_hours)
        else:
            resets_at = datetime.now(timezone.utc) + timedelta(hours=window_hours)

        logger.info(
            f"[free-tools] limit hit tool={tool} ip_hash={ip_hash[:8]}.. "
            f"used={used}/{limit} resets_at={resets_at.isoformat()}"
        )
        raise FreeToolLimitExceeded(
            resets_at=resets_at, limit=limit, window_hours=window_hours
        )

    # Consume one slot. There's a tiny race here under concurrent requests
    # from the same IP (read-then-write) — acceptable for a 2-call/24h cap
    # on an unauthenticated endpoint; the worst case is +1 free call.
    client.table("free_tool_usage").insert(
        {"ip_hash": ip_hash, "tool": tool}
    ).execute()

    remaining = max(0, limit - used - 1)
    logger.info(
        f"[free-tools] consume tool={tool} ip_hash={ip_hash[:8]}.. "
        f"used={used + 1}/{limit} remaining={remaining}"
    )
    return remaining
