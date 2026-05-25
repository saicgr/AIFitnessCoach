"""
share_push_notifier.py — pushes a "Imported …" / "Couldn't import …"
notification when a share-funnel pipeline finishes.

Hooks the existing NotificationService (firebase-admin / FCM). Only fires
when the user has left the app (best-effort: we always send; iOS / Android
suppress on-screen banners while in foreground). Reused by all four
orchestrator endpoints in `share_orchestrator.py` and the image classify
path in `share.py`.

Copy lives behind the `feedback_dynamic_copy_not_robotic` variant pool —
the helper randomly picks one of the variants per send so the same user
doesn't see "Imported 8 exercises" four times in a row.
"""
from __future__ import annotations

import logging
import random
from typing import Optional

from core.db import get_supabase_db
from services.notification_service_helpers import get_notification_service

logger = logging.getLogger(__name__)


# Per `feedback_no_em_dashes_marketing` — no em dashes here. Plain copy.
SUCCESS_TITLE_VARIANTS = [
    "Imported {summary}",
    "Saved {summary}",
    "Got it: {summary}",
    "Added {summary}",
]
SUCCESS_BODY_VARIANTS = [
    "Tap to review and tweak before it's final.",
    "Open it up and make any edits you want.",
    "Take a look — change anything that's off.",
    "Tap to see what we found.",
]

FAILURE_TITLE_VARIANTS = [
    "Couldn't finish that import",
    "Import didn't go through",
    "Hit a snag importing",
    "Something blocked the import",
]
FAILURE_BODY_VARIANTS = [
    "Tap to retry.",
    "Open Imports to try again.",
    "It happens — tap to retry from your imports list.",
    "Quick fix — tap to retry.",
]


async def notify_share_completed(
    *,
    user_id: str,
    shared_item_id: str,
    intent: str,
    summary: str,
) -> None:
    """Send a one-line push that a share extraction is done.

    `summary` is intent-specific:
      - workout_extract:    "8 exercises from YouTube"
      - recipe_extract:     "Chicken Tikka"
      - meal_plan_extract:  "a 7-day meal plan"
      - food_log_extract:   "your meal"
      - tip_save:           "a tip"
      - …
    """
    fcm_token = _fcm_token_for(user_id)
    if not fcm_token:
        return
    title = random.choice(SUCCESS_TITLE_VARIANTS).format(summary=summary)
    body = random.choice(SUCCESS_BODY_VARIANTS)
    try:
        await get_notification_service().send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type="imports_complete",
            data={
                "shared_item_id": shared_item_id,
                "intent": intent,
                "deep_link": "zealova://imports",
            },
        )
    except Exception as e:
        logger.warning(f"[SharePush] notify_completed failed: {e}")


async def notify_share_failed(
    *,
    user_id: str,
    shared_item_id: str,
    reason: str,
) -> None:
    fcm_token = _fcm_token_for(user_id)
    if not fcm_token:
        return
    title = random.choice(FAILURE_TITLE_VARIANTS)
    body = random.choice(FAILURE_BODY_VARIANTS)
    try:
        await get_notification_service().send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type="imports_failed",
            data={
                "shared_item_id": shared_item_id,
                "reason": (reason or "")[:160],
                "deep_link": "zealova://imports",
            },
        )
    except Exception as e:
        logger.warning(f"[SharePush] notify_failed: {e}")


def _fcm_token_for(user_id: str) -> Optional[str]:
    """Best-effort token lookup. Returns None when no token is on file or
    when the lookup itself fails — neither should block the pipeline."""
    try:
        db = get_supabase_db()
        res = (
            db.client.table("users")
            .select("fcm_token")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        if res.data and res.data[0].get("fcm_token"):
            return res.data[0]["fcm_token"]
    except Exception as e:
        logger.info(f"[SharePush] FCM token lookup failed for {user_id}: {e}")
    return None
