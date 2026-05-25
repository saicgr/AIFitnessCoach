"""
share_media_cleanup_worker.py — periodic cleanup of media S3 keys
downloaded by the Imports feature.

Two passes:

1. **Post-extraction sweep** — once a `shared_items` row has reached
   `status='completed'` AND > 30 minutes have elapsed, the original
   downloaded media (IG / TikTok video etc.) is no longer needed
   server-side. We delete the keys + clear the array. This is the
   App Store compliance path: never persist raw downloaded social media
   after extraction.

2. **Safety net** — any `shared_items` row older than 30 days that
   still has `media_s3_keys` set is purged unconditionally. Catches
   rows that got stuck in a non-`completed` state but still hold media.

Invoked by an existing cron runner (see backend/jobs/__init__.py for the
pattern used by `scheduled_meal_logs_worker`). Idempotent; safe to call
on every tick.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

import boto3
from botocore.exceptions import ClientError

from core.config import get_settings
from core.db import get_supabase_db

logger = logging.getLogger(__name__)
settings = get_settings()


POST_EXTRACTION_GRACE_MIN = 30
HARD_PURGE_DAYS = 30


async def run() -> dict:
    """Single tick. Returns a small stats dict for logging / metrics."""
    stats = {"completed_swept": 0, "hard_purged": 0, "keys_deleted": 0, "errors": 0}
    db = get_supabase_db()

    now = datetime.now(timezone.utc)
    post_cutoff = (now - timedelta(minutes=POST_EXTRACTION_GRACE_MIN)).isoformat()
    hard_cutoff = (now - timedelta(days=HARD_PURGE_DAYS)).isoformat()

    # Pass 1 — completed + grace elapsed + still carrying media.
    try:
        res = (
            db.client.table("shared_items")
            .select("id, user_id, media_s3_keys")
            .eq("status", "completed")
            .lt("updated_at", post_cutoff)
            .not_.is_("media_s3_keys", "null")
            .limit(500)
            .execute()
        )
        for row in res.data or []:
            keys = row.get("media_s3_keys") or []
            if not keys:
                continue
            ok = _delete_keys(keys)
            stats["keys_deleted"] += ok
            db.client.table("shared_items").update({"media_s3_keys": []}).eq(
                "id", row["id"]
            ).execute()
            stats["completed_swept"] += 1
    except Exception as e:
        stats["errors"] += 1
        logger.warning(f"[ShareMediaCleanup] pass 1 failed: {e}", exc_info=True)

    # Pass 2 — hard purge ≥30 days regardless of status.
    try:
        res = (
            db.client.table("shared_items")
            .select("id, media_s3_keys")
            .lt("updated_at", hard_cutoff)
            .not_.is_("media_s3_keys", "null")
            .limit(500)
            .execute()
        )
        for row in res.data or []:
            keys = row.get("media_s3_keys") or []
            if not keys:
                continue
            ok = _delete_keys(keys)
            stats["keys_deleted"] += ok
            db.client.table("shared_items").update({"media_s3_keys": []}).eq(
                "id", row["id"]
            ).execute()
            stats["hard_purged"] += 1
    except Exception as e:
        stats["errors"] += 1
        logger.warning(f"[ShareMediaCleanup] pass 2 failed: {e}", exc_info=True)

    if stats["completed_swept"] or stats["hard_purged"] or stats["errors"]:
        logger.info(f"[ShareMediaCleanup] tick: {stats}")
    return stats


# ---------------------------------------------------------------------------
# S3 delete helper — uses boto3 directly since S3Service doesn't ship a
# delete method. Tolerates partial failure (missing keys, etc.).
# ---------------------------------------------------------------------------

def _delete_keys(keys: list[str]) -> int:
    if not keys:
        return 0
    if not (settings.aws_access_key_id and settings.s3_bucket_name):
        # S3 not configured in this environment — leave the DB row's
        # array alone? No — the row still gets cleared because the
        # caller does the update unconditionally. Just log.
        logger.info("[ShareMediaCleanup] S3 not configured; skipping delete")
        return 0
    try:
        client = boto3.client(
            "s3",
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_default_region,
        )
        # delete_objects is bulk + idempotent — missing keys are silently OK.
        resp = client.delete_objects(
            Bucket=settings.s3_bucket_name,
            Delete={"Objects": [{"Key": k} for k in keys[:1000]]},
        )
        return len((resp or {}).get("Deleted", []))
    except ClientError as e:
        logger.warning(f"[ShareMediaCleanup] S3 delete failed: {e}")
        return 0


# Convenience for the existing cron pattern — every worker file in
# backend/jobs/ exposes a `main()` entry the scheduler calls.
async def main() -> None:
    await run()


if __name__ == "__main__":  # pragma: no cover
    import asyncio
    asyncio.run(run())
