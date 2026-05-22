"""
Cycle-aware reminder filter.

Progress-photo reminders can be misleading for menstruating users during
their period because of water-retention fluctuation. When
`users.cycle_aware_reminders` is opted-in AND the cycle prediction engine
reports the user is currently in their period, this filter returns False so
the notification scheduler skips the photo reminder.

Opt-out (default) always returns True — no behaviour change for users who
didn't enable the feature. Any error fails open (reminder delivered).

Source of truth is the `cycle_periods` table via
services.cycle.cycle_predictor — the legacy `menstrual_cycle_logs` table is
no longer read.
"""
from __future__ import annotations

import logging
from datetime import date

from core.supabase_client import get_supabase
from services.cycle.cycle_predictor import predict_for_user

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

    # Opted in — ask the prediction engine whether today falls in the period.
    try:
        prediction = predict_for_user(sb.client, user_id, local_date)
    except Exception as e:  # fail open — never silently drop a reminder
        logger.warning(f"[cycle_filter] prediction failed for {user_id}: {e}")
        return True

    if prediction.get("in_period"):
        logger.info(
            f"[cycle_filter] skipping photo reminder for {user_id}: currently in period"
        )
        return False
    return True
