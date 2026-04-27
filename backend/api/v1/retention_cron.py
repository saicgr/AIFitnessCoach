"""
Data retention cron jobs.

Enforces the retention windows we committed to in the Zealova privacy policy
(section 7 — Data Retention). Without this, promises like "chat history is
retained for up to 12 months, then automatically deleted" are copy-only —
and section 7 was flagged during our privacy audit as unimplemented.

Current jobs:
    * chat_history  — delete rows older than 12 months
    * push_nudge_log — delete rows older than 90 days (already capped in
                       practice by the 14-day dedup window, but we expire
                       the analytics tail so nothing ages indefinitely)
    * media_jobs    — prune completed media classification jobs older than
                       30 days (metadata only; S3 lifecycle policies handle
                       the blobs themselves)

Invocation: external scheduler POSTs daily to `/api/v1/retention/cron`
    with `X-Cron-Secret`, same pattern as `push_nudge_cron` (`/nudges/cron`)
    and `email_cron` (`/emails/cron`). There is no separate Render Cron
    service — the same Render web service receives the ping.
Security: X-Cron-Secret header (HMAC compare_digest).
"""
from __future__ import annotations

import hmac
from datetime import datetime, timedelta, timezone
from typing import Dict, Optional

from fastapi import APIRouter, Header, HTTPException, Request

from core.config import get_settings
from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)
router = APIRouter()


# --- Retention windows ------------------------------------------------------
# Keep these two constants synchronized with the retention section of
# privacy_policy.html. If you change one, update the other and ship both.
CHAT_HISTORY_RETENTION_DAYS = 365   # 12 months, per privacy policy §7
PUSH_NUDGE_LOG_RETENTION_DAYS = 90  # 3 months
MEDIA_JOB_RETENTION_DAYS = 30       # 1 month of job metadata


def _verify_cron_secret(x_cron_secret: Optional[str]) -> None:
    """Raise 401 / 503 unless the request carries the configured cron secret."""
    settings = get_settings()
    secret = settings.cron_secret
    if not secret:
        raise HTTPException(
            status_code=503,
            detail="Cron not configured — set CRON_SECRET env var",
        )
    if not x_cron_secret or not hmac.compare_digest(x_cron_secret, secret):
        raise HTTPException(status_code=401, detail="Invalid cron secret")


def _prune_older_than(table: str, column: str, days: int) -> int:
    """Delete rows from `table` where `column < now() - days`.

    Returns the number of rows removed. Errors are logged and re-raised so
    the cron runner surfaces a non-2xx (Render will alert on failures).
    """
    cutoff_iso = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    supabase = get_supabase().client
    # Supabase/PostgREST requires a filter on delete; gte/lte match semantics.
    result = supabase.table(table).delete().lt(column, cutoff_iso).execute()
    rows = result.data or []
    count = len(rows)
    logger.info(
        f"retention: pruned {count} rows from {table} "
        f"where {column} < {cutoff_iso} ({days}d)"
    )
    return count


@router.post("/cron")
async def run_retention_cron(
    request: Request,
    x_cron_secret: Optional[str] = Header(default=None, alias="X-Cron-Secret"),
) -> Dict[str, int]:
    """Run every configured retention sweep and return per-table counts.

    Each sweep is wrapped in its own try/except so a failure on one table
    doesn't prevent the others from running. We still return a non-2xx
    response if any sweep fails so the cron runner retries.
    """
    _verify_cron_secret(x_cron_secret)

    results: Dict[str, int] = {}
    failures: Dict[str, str] = {}

    sweeps = (
        ("chat_history", "timestamp", CHAT_HISTORY_RETENTION_DAYS),
        ("push_nudge_log", "created_at", PUSH_NUDGE_LOG_RETENTION_DAYS),
        ("media_jobs", "created_at", MEDIA_JOB_RETENTION_DAYS),
    )
    for table, column, days in sweeps:
        try:
            results[table] = _prune_older_than(table, column, days)
        except Exception as e:
            logger.error(f"retention: sweep failed for {table}: {e}", exc_info=True)
            failures[table] = str(e)

    if failures:
        # Surface partial failure so the cron runner retries, but include
        # the per-table counts we did manage to prune.
        raise HTTPException(
            status_code=500,
            detail={"pruned": results, "failed": failures},
        )

    return {"pruned": results, "status": "ok"}
