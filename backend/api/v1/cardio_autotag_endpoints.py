"""
Cardio Auto-Tag Endpoints
-------------------------

User-facing endpoints over `services/cardio_autotag_service.py`:

* `POST /cardio-logs/{id}/recompute-tags` — manual re-run after a user edits
  a session (e.g. corrects elevation or splits).
* `GET  /cardio-logs/tags-summary?days=30` — cumulative counters for the
  profile / cardio-history summary header.

Auth + owner verification reuse the same helpers as `cardio_logs.py`. The
router prefix matches the sibling cardio_logs router so the URL paths share
the same namespace.
"""
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

from services.cardio_autotag_service import (
    update_tags,
    TAG_HILL, TAG_NEGATIVE_SPLIT, TAG_NEW_ROUTE, TAG_DAWN, TAG_DUSK, TAG_PR,
)

logger = get_logger(__name__)
router = APIRouter(prefix="/cardio-logs", tags=["Cardio Auto-Tags"])


_SUMMARY_LABEL_MAP = {
    TAG_HILL: "hill_workouts",
    TAG_NEGATIVE_SPLIT: "negative_splits",
    TAG_NEW_ROUTE: "new_routes",
    TAG_DAWN: "dawn_runs",
    TAG_DUSK: "dusk_runs",
    TAG_PR: "pr_sessions",
}


def _fetch_owner(db, cardio_log_id: str):
    """Look up (user_id, table) for an id. Mirrors the auto-detection in the
    service so the auth check works whether the id lives in cardio_logs or
    cardio_sessions."""
    for table in ("cardio_logs", "cardio_sessions"):
        try:
            res = (
                db.client.table(table)
                .select("id, user_id")
                .eq("id", cardio_log_id)
                .limit(1)
                .execute()
            )
            if res.data:
                return res.data[0]["user_id"], table
        except Exception as e:
            logger.debug(f"[CardioAutoTag] owner probe {table}: {e}")
            continue
    return None, None


@router.post("/{cardio_log_id}/recompute-tags")
async def recompute_tags(
    cardio_log_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Manual recompute — invoked by the client when a user edits a session
    (corrects splits, adjusts elevation, etc.) or by an admin support flow."""
    try:
        db = get_supabase_db()
        owner_id, table = _fetch_owner(db, cardio_log_id)
        if not owner_id:
            raise HTTPException(status_code=404, detail="Cardio log not found")
        verify_user_ownership(current_user, owner_id)

        tags = update_tags(db, cardio_log_id)
        return {
            "id": cardio_log_id,
            "table": table,
            "tags": tags,
            "tag_count": len(tags),
        }
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"[CardioAutoTag] recompute error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_autotag")


@router.get("/tags-summary")
async def tags_summary(
    days: int = Query(default=30, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
):
    """Cumulative tag counters across both `cardio_logs` and `cardio_sessions`
    for the past `days` days. Used by the profile header + cardio-history
    summary chip strip ("3 hill workouts, 2 negative splits this month").
    """
    user_id = current_user.get("id") or current_user.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unknown user")
    try:
        db = get_supabase_db()
        since = (datetime.now(tz=timezone.utc) - timedelta(days=days)).isoformat()

        counters: Dict[str, int] = {label: 0 for label in _SUMMARY_LABEL_MAP.values()}
        for table in ("cardio_logs", "cardio_sessions"):
            try:
                res = (
                    db.client.table(table)
                    .select("tags, performed_at")
                    .eq("user_id", user_id)
                    .gte("performed_at", since)
                    .execute()
                )
            except Exception as e:
                # Table may not exist in some environments; skip — don't fail
                # the whole summary because one of the two tables is missing.
                logger.debug(f"[CardioAutoTag] summary probe {table}: {e}")
                continue
            for row in res.data or []:
                row_tags = row.get("tags") or []
                if not isinstance(row_tags, list):
                    continue
                for tag in row_tags:
                    label = _SUMMARY_LABEL_MAP.get(tag)
                    if label:
                        counters[label] += 1
        counters["days"] = days
        return counters
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[CardioAutoTag] summary error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_autotag")
