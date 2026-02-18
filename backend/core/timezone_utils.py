"""
Timezone utilities for converting between user-local dates and UTC.

All date-based queries should use these helpers so that a user's "today"
is correctly resolved regardless of their timezone.
"""

import logging
from datetime import datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

logger = logging.getLogger(__name__)

# ── public helpers ──────────────────────────────────────────────────────


def local_date_to_utc_range(date_str: str, timezone_str: str) -> tuple[str, str]:
    """
    Convert a 'YYYY-MM-DD' date in the user's timezone to a UTC start/end
    ISO-timestamp pair covering that entire local day.

    Returns:
        (utc_start_iso, utc_end_iso) – both suitable for Supabase .gte/.lte filters.
    """
    tz = _safe_zone(timezone_str)
    y, m, d = int(date_str[:4]), int(date_str[5:7]), int(date_str[8:10])
    local_start = datetime(y, m, d, 0, 0, 0, tzinfo=tz)
    local_end = datetime(y, m, d, 23, 59, 59, tzinfo=tz)
    return (
        local_start.astimezone(ZoneInfo("UTC")).isoformat(),
        local_end.astimezone(ZoneInfo("UTC")).isoformat(),
    )


def get_user_today(timezone_str: str) -> str:
    """Return today's date string ('YYYY-MM-DD') in the user's timezone."""
    tz = _safe_zone(timezone_str)
    return datetime.now(tz).strftime("%Y-%m-%d")


def get_user_now_iso(timezone_str: str) -> str:
    """Return the current UTC ISO timestamp (for logged_at columns)."""
    # We don't shift the stored timestamp – Postgres stores UTC.
    # But we need this to ensure we're recording "now" accurately.
    return datetime.now(ZoneInfo("UTC")).isoformat()


def resolve_timezone(request, db=None, user_id: str | None = None) -> str:
    """
    Determine the user's IANA timezone.

    Priority:
        1. X-User-Timezone request header (sent by the mobile app)
        2. users.timezone DB column (if db + user_id provided)
        3. Fallback to 'UTC'
    """
    # 1. Header
    header_tz = request.headers.get("x-user-timezone")
    if header_tz and _is_valid_tz(header_tz):
        return header_tz

    # 2. DB lookup
    if db is not None and user_id:
        try:
            user = db.get_user(user_id)
            db_tz = (user or {}).get("timezone")
            if db_tz and _is_valid_tz(db_tz):
                return db_tz
        except Exception as e:
            logger.warning(f"Could not read user timezone from DB: {e}")

    return "UTC"


# ── private helpers ─────────────────────────────────────────────────────


def _is_valid_tz(tz_str: str) -> bool:
    """Return True if *tz_str* is a valid IANA timezone identifier."""
    try:
        ZoneInfo(tz_str)
        return True
    except (ZoneInfoNotFoundError, KeyError, ValueError):
        return False


def _safe_zone(tz_str: str) -> ZoneInfo:
    """Return ZoneInfo for *tz_str*, falling back to UTC on bad input."""
    try:
        return ZoneInfo(tz_str)
    except (ZoneInfoNotFoundError, KeyError, ValueError):
        logger.warning(f"Invalid timezone '{tz_str}', falling back to UTC")
        return ZoneInfo("UTC")
