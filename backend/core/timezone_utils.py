"""
Timezone utilities for converting between user-local dates and UTC.

All date-based queries should use these helpers so that a user's "today"
is correctly resolved regardless of their timezone.
"""

import logging
from datetime import datetime
from typing import Optional
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


def target_date_to_utc_iso(date_str: str, timezone_str: str) -> str:
    """
    Convert a 'YYYY-MM-DD' local date to a UTC ISO timestamp at noon local time.
    Used when the user explicitly picks a date for logging (e.g., logging food to yesterday).
    Noon avoids edge cases where midnight could cross UTC day boundaries.
    """
    tz = _safe_zone(timezone_str)
    y, m, d = int(date_str[:4]), int(date_str[5:7]), int(date_str[8:10])
    return datetime(y, m, d, 12, 0, 0, tzinfo=tz).astimezone(ZoneInfo("UTC")).isoformat()


def user_today_date(request, db=None, user_id: Optional[str] = None):
    """
    Drop-in replacement for ``date.today()`` that respects the user's timezone.

    Returns a ``date`` object for "today" in the user's local timezone,
    resolved from the X-User-Timezone header or DB.

    Usage in any endpoint::

        from core.timezone_utils import user_today_date
        today = user_today_date(request, db, user_id)
        # now use `today` exactly as you would `date.today()`
    """
    tz_str = resolve_timezone(request, db, user_id)
    user_date = datetime.now(_safe_zone(tz_str)).date()
    utc_date = datetime.now(ZoneInfo("UTC")).date()
    if user_date != utc_date:
        logger.info(f"🕐 [TZ] user={user_id} tz={tz_str} user_today={user_date} utc_today={utc_date} (differ!)")
    else:
        logger.debug(f"🕐 [TZ] user={user_id} tz={tz_str} today={user_date}")
    return user_date


def resolve_timezone(request, db=None, user_id: Optional[str] = None) -> str:
    """
    Determine the user's IANA timezone.

    Priority:
        1. X-User-Timezone request header (sent by the mobile app)
        2. users.timezone DB column (if db + user_id provided)
        3. Fallback to 'UTC'
    """
    # 1. Header (try IANA first, then map abbreviation)
    header_tz = request.headers.get("x-user-timezone") if request is not None else None
    if header_tz:
        if _is_valid_tz(header_tz):
            logger.debug(f"🕐 [TZ] Resolved timezone from header: {header_tz} (user={user_id})")
            return header_tz
        # Flutter fallback sends abbreviations like "IST" — map to IANA
        mapped = _TZ_ABBREVIATION_MAP.get(header_tz.upper())
        if mapped:
            logger.info(f"🕐 [TZ] Mapped abbreviation '{header_tz}' -> '{mapped}' (user={user_id})")
            return mapped
        logger.warning(f"🕐 [TZ] Unknown timezone header '{header_tz}', trying DB (user={user_id})")

    # 2. DB lookup
    if db is not None and user_id:
        try:
            user = db.get_user(user_id)
            db_tz = (user or {}).get("timezone")
            if db_tz and _is_valid_tz(db_tz):
                logger.debug(f"🕐 [TZ] Resolved timezone from DB: {db_tz} (user={user_id})")
                return db_tz
        except Exception as e:
            logger.warning(f"🕐 [TZ] Could not read user timezone from DB: {e}", exc_info=True)

    logger.warning(f"🕐 [TZ] Falling back to UTC — no timezone found (user={user_id}, header={header_tz})")
    return "UTC"


# ── private helpers ─────────────────────────────────────────────────────


def _is_valid_tz(tz_str: str) -> bool:
    """Return True if *tz_str* is a valid IANA timezone identifier."""
    try:
        ZoneInfo(tz_str)
        return True
    except (ZoneInfoNotFoundError, KeyError, ValueError):
        return False


# Last-resort map: abbreviation → IANA.
# The Flutter app now sends proper IANA identifiers via flutter_timezone,
# so this map should rarely be hit (only old app versions or fallback paths).
# Abbreviations are inherently ambiguous (e.g. "CST" = US Central / China / Cuba),
# so we pick the most likely match for a fitness app's user base.
_TZ_ABBREVIATION_MAP = {
    # Americas
    "EST": "America/New_York",    "EDT": "America/New_York",
    "CST": "America/Chicago",     "CDT": "America/Chicago",
    "MST": "America/Denver",      "MDT": "America/Denver",
    "PST": "America/Los_Angeles", "PDT": "America/Los_Angeles",
    "AKST": "America/Anchorage",  "AKDT": "America/Anchorage",
    "HST": "Pacific/Honolulu",
    "AST": "America/Halifax",     "ADT": "America/Halifax",
    "NST": "America/St_Johns",    "NDT": "America/St_Johns",
    "ART": "America/Argentina/Buenos_Aires",
    "BRT": "America/Sao_Paulo",   "BRST": "America/Sao_Paulo",
    "CLT": "America/Santiago",    "CLST": "America/Santiago",
    "COT": "America/Bogota",
    "PET": "America/Lima",
    "VET": "America/Caracas",
    # Europe
    "GMT": "Europe/London",       "BST": "Europe/London",
    "CET": "Europe/Paris",        "CEST": "Europe/Paris",
    "EET": "Europe/Athens",       "EEST": "Europe/Athens",
    "WET": "Europe/Lisbon",       "WEST": "Europe/Lisbon",
    "MSK": "Europe/Moscow",
    "TRT": "Europe/Istanbul",
    # Asia
    "IST": "Asia/Kolkata",
    "PKT": "Asia/Karachi",
    "NPT": "Asia/Kathmandu",
    "BDT": "Asia/Dhaka",
    "MMT": "Asia/Yangon",
    "ICT": "Asia/Bangkok",
    "WIB": "Asia/Jakarta",
    "WITA": "Asia/Makassar",
    "WIT": "Asia/Jayapura",
    "SGT": "Asia/Singapore",
    "MYT": "Asia/Kuala_Lumpur",
    "PHT": "Asia/Manila",
    "CST+8": "Asia/Shanghai",
    "HKT": "Asia/Hong_Kong",
    "TWT": "Asia/Taipei",
    "JST": "Asia/Tokyo",
    "KST": "Asia/Seoul",
    "GST": "Asia/Dubai",
    "IRST": "Asia/Tehran",
    "AFT": "Asia/Kabul",
    "UZT": "Asia/Tashkent",
    # Oceania
    "AEST": "Australia/Sydney",   "AEDT": "Australia/Sydney",
    "ACST": "Australia/Adelaide", "ACDT": "Australia/Adelaide",
    "AWST": "Australia/Perth",
    "NZST": "Pacific/Auckland",   "NZDT": "Pacific/Auckland",
    "FJT": "Pacific/Fiji",
    # Africa
    "CAT": "Africa/Johannesburg",
    "EAT": "Africa/Nairobi",
    "WAT": "Africa/Lagos",
    "SAST": "Africa/Johannesburg",
}


def _safe_zone(tz_str: str) -> ZoneInfo:
    """Return ZoneInfo for *tz_str*, falling back to UTC on bad input."""
    try:
        return ZoneInfo(tz_str)
    except (ZoneInfoNotFoundError, KeyError, ValueError):
        logger.warning(f"Invalid timezone '{tz_str}', falling back to UTC", exc_info=True)
        return ZoneInfo("UTC")
