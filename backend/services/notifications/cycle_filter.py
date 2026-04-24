"""
Cycle-aware reminder filter.

Progress-photo reminders can be misleading for menstruating users during
their period because of water-retention fluctuation. When `users.cycle_aware_reminders`
is opted-in AND today's local date falls within menstruation days 1–5 of
the user's most recent cycle log, this filter returns False so the notification
scheduler skips the photo reminder.

Opt-out (default) always returns True — no behaviour change for users who
didn't enable the feature.
"""
from __future__ import annotations

import logging
from datetime import date, timedelta
from typing import Optional

from core.supabase_client import get_supabase

logger = logging.getLogger("cycle_filter")


async def should_send_photo_reminder(
    *,
    user_id: str,
    local_date: date,
) -> bool:
    """Return True if it's OK to deliver a progress-photo reminder today."""
    sb = get_supabase()

    # Fast path: is the user opted in at all?
    user_row = sb.client.table("users").select(
        "cycle_aware_reminders"
    ).eq("id", user_id).maybe_single().execute()
    if not user_row or not user_row.data:
        return True
    if not user_row.data.get("cycle_aware_reminders"):
        return True

    # Latest cycle log
    latest = sb.client.table("menstrual_cycle_logs").select(
        "cycle_start_date, cycle_length_days, period_length_days"
    ).eq("user_id", user_id).order(
        "cycle_start_date", desc=True
    ).limit(1).execute()
    if not latest or not latest.data:
        # Opt-in but no log — fail open (deliver reminder).
        return True

    row = latest.data[0]
    cycle_start = _parse_date(row.get("cycle_start_date"))
    cycle_len = int(row.get("cycle_length_days") or 28)
    period_len = int(row.get("period_length_days") or 5)
    if not cycle_start:
        return True

    # Project the latest logged cycle forward if today is past its nominal end.
    # This handles the common case where the user logged cycle N weeks ago
    # and has since started a new cycle without logging it.
    days_since_start = (local_date - cycle_start).days
    if days_since_start < 0:
        # Log is in the future (time-zone edge case); treat as current cycle.
        day_in_cycle = 1
    else:
        day_in_cycle = (days_since_start % cycle_len) + 1

    if 1 <= day_in_cycle <= period_len:
        logger.info(
            f"[cycle_filter] skipping photo reminder for {user_id}: "
            f"day {day_in_cycle} of cycle (period_len={period_len})"
        )
        return False
    return True


def _parse_date(value) -> Optional[date]:
    """Coerce Supabase date string / date obj to a date."""
    if value is None:
        return None
    if isinstance(value, date):
        return value
    try:
        return date.fromisoformat(str(value)[:10])
    except ValueError:
        return None
