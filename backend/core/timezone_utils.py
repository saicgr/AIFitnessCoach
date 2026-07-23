"""
Timezone utilities for converting between user-local dates and UTC.

All date-based queries should use these helpers so that a user's "today"
is correctly resolved regardless of their timezone.
"""

import logging
from datetime import date, datetime, timedelta
from typing import Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

logger = logging.getLogger(__name__)

# ── public helpers ──────────────────────────────────────────────────────


def local_day_bounds(date_str: str, timezone_str: str) -> tuple[str, str]:
    """
    Canonical HALF-OPEN UTC window ``[start, end)`` covering one whole local day.

    THIS IS THE CHOKEPOINT for every "what did the user do on their day X"
    query against a ``timestamptz`` column (``logged_at``, ``completed_at``,
    ``created_at``, …). Use it with ``.gte(start)`` / ``.lt(end)`` — never
    ``.lte(end)``.

    Why half-open: the closed ``23:59:59`` form silently drops any row in the
    final second of the local day, and — worse — invites the ``.lte`` /
    ``.gte`` symmetry that makes two adjacent days both claim the boundary row.
    ``end`` is local midnight of *the next day*, so 23h/25h DST transition days
    are exact rather than off by an hour.

    The bug this exists to prevent (2026-07-22): building a window by
    concatenating a LOCAL date with a UTC offset —
    ``f"{local_date}T00:00:00+00:00"`` — which for a UTC-4 user spans local
    20:00 yesterday → 19:59 today. It attributed 2,844 kcal of the previous
    evening's dinners to "today" on the coach card.
    """
    tz = _safe_zone(timezone_str)
    d = date(int(date_str[:4]), int(date_str[5:7]), int(date_str[8:10]))
    nxt = d + timedelta(days=1)
    start = datetime(d.year, d.month, d.day, 0, 0, 0, tzinfo=tz)
    end = datetime(nxt.year, nxt.month, nxt.day, 0, 0, 0, tzinfo=tz)
    return (
        start.astimezone(ZoneInfo("UTC")).isoformat(),
        end.astimezone(ZoneInfo("UTC")).isoformat(),
    )


def local_range_bounds(
    start_date: str, end_date: str, timezone_str: str
) -> tuple[str, str]:
    """
    Half-open UTC window ``[start, end)`` spanning local ``start_date`` 00:00
    through the END of local ``end_date`` (i.e. ``end_date + 1`` at 00:00).

    ``end_date`` is INCLUSIVE as a calendar day — passing today's local date
    covers everything logged so far today. Use ``.gte(start)`` / ``.lt(end)``.
    """
    return (
        local_day_bounds(start_date, timezone_str)[0],
        local_day_bounds(end_date, timezone_str)[1],
    )


def utc_to_local_date(value, timezone_str: str) -> str:
    """
    Bucket a ``timestamptz`` value into the user's local ``'YYYY-MM-DD'``.

    Replaces every ``str(row["logged_at"])[:10]`` / ``.date()`` in aggregation
    code. Slicing the raw UTC string buckets a 9pm-local log onto the *next*
    day for western users, which silently corrupts day-counts, streaks, and
    per-day averages even when the query window itself is correct.

    Returns ``""`` on unparseable input (callers treat that as "no day").
    """
    s = to_utc_iso(value)
    if not s:
        return ""
    try:
        return (
            datetime.fromisoformat(s)
            .astimezone(_safe_zone(timezone_str))
            .strftime("%Y-%m-%d")
        )
    except ValueError:
        return ""


def local_date_to_utc_range(date_str: str, timezone_str: str) -> tuple[str, str]:
    """
    DEPRECATED — closed-interval ``[start, end]`` form of :func:`local_day_bounds`.

    Kept so existing ``.lte``-based call sites keep working unchanged. New code
    must use :func:`local_day_bounds` (half-open, DST-exact) with ``.lt``.

    Returns:
        (utc_start_iso, utc_end_iso) – suitable for Supabase .gte/.lte filters.
    """
    start_iso, end_iso = local_day_bounds(date_str, timezone_str)
    end = datetime.fromisoformat(end_iso) - timedelta(seconds=1)
    return start_iso, end.isoformat()


def get_user_today(timezone_str: str) -> str:
    """Return today's date string ('YYYY-MM-DD') in the user's timezone."""
    tz = _safe_zone(timezone_str)
    return datetime.now(tz).strftime("%Y-%m-%d")


def get_user_now_iso(timezone_str: str) -> str:
    """Return the current UTC ISO timestamp (for logged_at columns)."""
    # We don't shift the stored timestamp – Postgres stores UTC.
    # But we need this to ensure we're recording "now" accurately.
    return datetime.now(ZoneInfo("UTC")).isoformat()


def to_utc_iso(value) -> str:
    """
    Normalize a ``logged_at``-style value to ISO8601 with an explicit UTC offset
    (e.g. ``"2026-04-14T14:15:00+00:00"``).

    Handles:
      * ``datetime`` — naive values are assumed UTC (our columns are ``timestamptz``
        stored in UTC); aware values are converted.
      * ``str`` — both offset-bearing (``"…Z"`` / ``"…+00:00"``) and naive forms.
      * ``None`` / ``""`` → ``""`` (callers serialize that as-is).

    Kept deliberately tolerant: if we can't parse, we return the input untouched
    rather than crash a response.
    """
    if value is None:
        return ""
    if isinstance(value, datetime):
        dt = value if value.tzinfo else value.replace(tzinfo=ZoneInfo("UTC"))
    elif isinstance(value, str):
        s = value.strip()
        if not s:
            return ""
        try:
            dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        except ValueError:
            return s
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=ZoneInfo("UTC"))
    else:
        return str(value)
    return dt.astimezone(ZoneInfo("UTC")).isoformat()


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

    Side effect (silent self-healing): when the header is present and valid
    AND differs from the DB value, schedule a throttled write-through to
    refresh users.timezone. This keeps cron / background jobs that can't see
    the request from inheriting a stale value forever. Throttle is 24h per
    user, fire-and-forget — never blocks the resolver.
    """
    # 1. Header (try IANA first, then map abbreviation)
    header_tz = request.headers.get("x-user-timezone") if request is not None else None
    resolved_from_header: Optional[str] = None
    if header_tz:
        if _is_valid_tz(header_tz):
            resolved_from_header = header_tz
        else:
            # Flutter fallback sends abbreviations like "IST" — map to IANA
            mapped = _TZ_ABBREVIATION_MAP.get(header_tz.upper())
            if mapped:
                logger.info(f"🕐 [TZ] Mapped abbreviation '{header_tz}' -> '{mapped}' (user={user_id})")
                resolved_from_header = mapped
            else:
                logger.warning(f"🕐 [TZ] Unknown timezone header '{header_tz}', trying DB (user={user_id})")

    if resolved_from_header:
        if db is not None and user_id:
            _maybe_write_through_timezone(db, user_id, resolved_from_header)
        logger.debug(f"🕐 [TZ] Resolved timezone from header: {resolved_from_header} (user={user_id})")
        return resolved_from_header

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


# ── self-healing write-through ──────────────────────────────────────────
# Phone sends X-User-Timezone on every request; users.timezone has historically
# been stale (often 'UTC' for accounts created before the header existed).
# When the live header disagrees with the DB column we update the DB once per
# user per 24h so that cron, backfills, and any non-HTTP context eventually
# converge on truth without manual intervention.
_TIMEZONE_WRITETHROUGH_THROTTLE_SECONDS = 24 * 60 * 60
_timezone_writethrough_last_ts: dict = {}


def _maybe_write_through_timezone(db, user_id: str, tz_str: str) -> None:
    """Refresh users.timezone if header value differs from DB and not throttled.

    Fire-and-forget. Logs but never raises — the caller is in the hot path
    of every authed request and must not be slowed or destabilized by this.
    """
    import time

    now_ts = time.monotonic()
    last_ts = _timezone_writethrough_last_ts.get(user_id)
    if last_ts is not None and (now_ts - last_ts) < _TIMEZONE_WRITETHROUGH_THROTTLE_SECONDS:
        return  # within 24h of last check — skip silently

    try:
        user = db.get_user(user_id)
    except Exception as e:
        logger.debug(f"🕐 [TZ writethrough] get_user failed for {user_id}: {e}")
        return
    if not user:
        return
    current = (user or {}).get("timezone")
    if current == tz_str:
        # DB already matches — record the timestamp so we don't re-check for
        # another 24h, but don't issue an UPDATE.
        _timezone_writethrough_last_ts[user_id] = now_ts
        return

    try:
        # supabase-py update is synchronous; the resolver itself runs inside
        # FastAPI dependency resolution where blocking the event loop briefly
        # is acceptable. If this surfaces as a hot-path cost in profiling,
        # wrap in BackgroundTasks at the caller site.
        db.client.table("users").update({"timezone": tz_str}).eq("id", user_id).execute()
        _timezone_writethrough_last_ts[user_id] = now_ts
        logger.info(
            f"🕐 [TZ writethrough] Refreshed users.timezone for {user_id}: "
            f"{current!r} -> {tz_str!r}"
        )
    except Exception as e:
        logger.warning(f"🕐 [TZ writethrough] UPDATE failed for {user_id}: {e}")


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
