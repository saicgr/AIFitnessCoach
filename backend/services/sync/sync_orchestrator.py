"""
Sync orchestrator.

Two responsibilities:

1. **Pull-sync cron** — every 15 min, find ``oauth_sync_accounts`` rows with
   ``status='active' AND auto_import=true AND (last_sync_at IS NULL OR
   last_sync_at < now() - interval '15 minutes')``, call the matching
   provider's ``fetch_since``, and bulk-insert the canonical rows via the
   existing ``WorkoutHistoryImporter._bulk_insert_cardio`` /
   ``_bulk_insert_strength`` helpers.

2. **Webhook drain** — dequeue unprocessed ``oauth_sync_webhook_events`` rows,
   look up the target account, pull the specific activity ids referenced by
   the payload, and feed them through the same importer. Marks each event
   with ``processed_at`` / ``error``.

Runs under Render's cron type (see ``render.yaml``):

    python -m services.sync.sync_orchestrator

Or under the in-process scheduler for local dev:

    python -m services.sync.sync_orchestrator --once
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
import time
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

from core.db import get_supabase_db

from services.sync.oauth_base import (
    ProviderRateLimitedError,
    ReauthRequiredError,
    SyncAccount,
    SyncProvider,
    SyncProviderError,
    get_provider,
)
from services.sync.token_encryption import encrypt_token
from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
)
from services.workout_import.service import WorkoutHistoryImporter

logger = logging.getLogger(__name__)

CRON_INTERVAL_MIN = 15
DEFAULT_LOOKBACK_DAYS = 90
MAX_ACCOUNTS_PER_RUN = 500
MAX_WEBHOOK_EVENTS_PER_RUN = 1000
MAX_CONSECUTIVE_ERRORS_BEFORE_PAUSE = 10


# ────────────────────────── Public entry points ──────────────────────────

def run_once() -> Dict[str, int]:
    """Single cron tick: drain webhooks, then pull-sync due accounts.

    Returns a summary for logging / test assertions.
    """
    logger.info("🔄 [sync] orchestrator tick started")
    drained = drain_webhook_events()
    pulled = run_pull_sync()
    summary = {**drained, **pulled}
    logger.info(f"✅ [sync] orchestrator tick complete: {summary}")
    return summary


# ─────────────────────────── Pull-sync loop ──────────────────────────────

def run_pull_sync() -> Dict[str, int]:
    """Iterate over due accounts and sync each. Never raises — errors are
    captured per-account to ``oauth_sync_accounts.last_error``.
    """
    db = get_supabase_db()
    accounts = _fetch_due_accounts(db)
    importer = WorkoutHistoryImporter()
    cardio_written = 0
    strength_written = 0
    accounts_synced = 0
    accounts_failed = 0

    for row in accounts:
        try:
            account = SyncAccount.from_db_row(row)
        except Exception as e:
            logger.error(f"[sync] bad row id={row.get('id')}: {e}")
            accounts_failed += 1
            continue

        provider_slug = account.provider
        try:
            provider = get_provider(provider_slug)
        except SyncProviderError as e:
            _record_error(db, account, str(e))
            accounts_failed += 1
            continue

        try:
            if _needs_refresh(account):
                _refresh_account(db, account, provider)
            since = account.last_sync_at or (
                datetime.now(timezone.utc) - timedelta(days=provider.default_lookback_days)
            )
            rows = provider.fetch_since(account, since)
            strength_rows = [r for r in rows if isinstance(r, CanonicalSetRow)]
            cardio_rows = [r for r in rows if isinstance(r, CanonicalCardioRow)]
            if not account.import_strength:
                strength_rows = []
            if not account.import_cardio:
                cardio_rows = []
            inserted_cardio = importer._bulk_insert_cardio(db, cardio_rows, account.id)
            inserted_strength = importer._bulk_insert_strength(db, strength_rows, account.id)
            cardio_written += inserted_cardio
            strength_written += inserted_strength
            _record_success(
                db,
                account,
                inserted_cardio=inserted_cardio,
                inserted_strength=inserted_strength,
            )
            accounts_synced += 1
            # SECURITY: never log the plaintext access_token — only length.
            logger.info(
                f"🟢 [sync:{provider_slug}] user={account.user_id} "
                f"access_token_len={len(account.access_token)} "
                f"+{inserted_cardio}c/+{inserted_strength}s"
            )
        except ReauthRequiredError as e:
            _mark_reauth_required(db, account, str(e))
            accounts_failed += 1
        except ProviderRateLimitedError:
            _record_rate_limited(db, account)
            accounts_failed += 1
        except SyncProviderError as e:
            _record_error(db, account, str(e))
            accounts_failed += 1
        except Exception as e:
            logger.exception(f"[sync] unexpected error for {provider_slug}: {e}")
            _record_error(db, account, f"unexpected: {type(e).__name__}")
            accounts_failed += 1

    return {
        "accounts_synced": accounts_synced,
        "accounts_failed": accounts_failed,
        "cardio_rows_written": cardio_written,
        "strength_rows_written": strength_written,
    }


# ─────────────────────────── Webhook drain ──────────────────────────────

def drain_webhook_events() -> Dict[str, int]:
    """Process unprocessed webhook events oldest-first.

    Each event points to an external activity; we resolve the target account
    by ``(provider, external_user_id)`` and issue a bounded ``fetch_since`` over
    a 48-hour window around the event time, then bulk insert. This reuses the
    existing dedup path so replayed webhooks are no-ops.
    """
    db = get_supabase_db()
    importer = WorkoutHistoryImporter()
    result = (
        db.client.table("oauth_sync_webhook_events")
        .select("*")
        .is_("processed_at", "null")
        .order("received_at", desc=False)
        .limit(MAX_WEBHOOK_EVENTS_PER_RUN)
        .execute()
    )
    events = result.data or []
    processed = 0
    failed = 0

    for event in events:
        event_id = event["id"]
        provider_slug = event["provider"]
        external_user_id = event["external_user_id"]
        event_type = event["event_type"]
        attempts = int(event.get("process_attempts", 0)) + 1

        try:
            # Deauthorize is a metadata-only event — no sync fetch needed.
            if event_type == "deauthorize":
                _soft_revoke_account(db, provider_slug, external_user_id)
                _mark_event_processed(db, event_id, attempts, error=None)
                processed += 1
                continue

            account_row = _find_account_by_external(db, provider_slug, external_user_id)
            if account_row is None:
                _mark_event_processed(
                    db, event_id, attempts,
                    error="account not found (stale webhook?)",
                )
                failed += 1
                continue
            account = SyncAccount.from_db_row(account_row)
            provider = get_provider(provider_slug)
            if _needs_refresh(account):
                _refresh_account(db, account, provider)

            # Pull a small window around the event. Idempotent — dedup hash.
            since = datetime.now(timezone.utc) - timedelta(hours=48)
            rows = provider.fetch_since(account, since)
            strength_rows = [r for r in rows if isinstance(r, CanonicalSetRow)]
            cardio_rows = [r for r in rows if isinstance(r, CanonicalCardioRow)]
            if not account.import_strength:
                strength_rows = []
            if not account.import_cardio:
                cardio_rows = []
            importer._bulk_insert_cardio(db, cardio_rows, account.id)
            importer._bulk_insert_strength(db, strength_rows, account.id)

            _record_success(
                db, account,
                inserted_cardio=len(cardio_rows),
                inserted_strength=len(strength_rows),
            )
            _mark_event_processed(db, event_id, attempts, error=None)
            processed += 1
        except ReauthRequiredError as e:
            _mark_event_processed(db, event_id, attempts, error=str(e))
            failed += 1
        except Exception as e:
            logger.exception(f"[sync] webhook drain error for {provider_slug}: {e}")
            _mark_event_processed(db, event_id, attempts, error=str(e)[:200])
            failed += 1
    return {"webhook_events_processed": processed, "webhook_events_failed": failed}


# ─────────────────────────── DB helpers ───────────────────────────

def _fetch_due_accounts(db) -> List[Dict[str, Any]]:
    """Accounts that need a pull-sync right now."""
    cutoff = (datetime.now(timezone.utc) - timedelta(minutes=CRON_INTERVAL_MIN)).isoformat()
    # We split into two queries: last_sync_at IS NULL and last_sync_at < cutoff.
    # Supabase's Python client chains .or_() with commas.
    try:
        result = (
            db.client.table("oauth_sync_accounts")
            .select("*")
            .eq("status", "active")
            .eq("auto_import", True)
            .or_(f"last_sync_at.is.null,last_sync_at.lt.{cutoff}")
            .limit(MAX_ACCOUNTS_PER_RUN)
            .execute()
        )
        return result.data or []
    except Exception as e:
        logger.error(f"[sync] _fetch_due_accounts failed: {e}")
        return []


def _needs_refresh(account: SyncAccount) -> bool:
    if account.expires_at is None:
        return False
    return (account.expires_at - datetime.now(timezone.utc)).total_seconds() < 300


def _refresh_account(db, account: SyncAccount, provider: SyncProvider) -> None:
    bundle = provider.refresh_token(account)
    update = {
        "access_token_encrypted": encrypt_token(bundle.access_token),
        "expires_at": bundle.expires_at.isoformat() if bundle.expires_at else None,
    }
    if bundle.refresh_token:
        update["refresh_token_encrypted"] = encrypt_token(bundle.refresh_token)
    if bundle.scopes:
        update["scopes"] = bundle.scopes
    db.client.table("oauth_sync_accounts").update(update).eq("id", str(account.id)).execute()
    # Mutate in-memory so the subsequent fetch_since uses the new token.
    account.access_token = bundle.access_token
    if bundle.refresh_token:
        account.refresh_token = bundle.refresh_token
    account.expires_at = bundle.expires_at
    if bundle.scopes:
        account.scopes = list(bundle.scopes)
    logger.info(
        f"🔑 [sync:{account.provider}] refreshed access_token for user={account.user_id} "
        f"(len={len(bundle.access_token)})"
    )


def _record_success(db, account: SyncAccount, *, inserted_cardio: int, inserted_strength: int) -> None:
    now_iso = datetime.now(timezone.utc).isoformat()
    status_tag = "ok"
    if inserted_cardio + inserted_strength == 0:
        status_tag = "ok"   # explicitly "ok" even if no new rows — sync succeeded
    db.client.table("oauth_sync_accounts").update({
        "last_sync_at": now_iso,
        "last_sync_status": status_tag,
        "last_error": None,
        "error_count": 0,
    }).eq("id", str(account.id)).execute()


def _record_error(db, account: SyncAccount, error: str) -> None:
    new_count = account.error_count + 1
    update: Dict[str, Any] = {
        "last_sync_at": datetime.now(timezone.utc).isoformat(),
        "last_sync_status": "failed",
        "last_error": error[:500],
        "error_count": new_count,
    }
    # Runaway failures → pause to prevent hammering the provider.
    if new_count >= MAX_CONSECUTIVE_ERRORS_BEFORE_PAUSE:
        update["status"] = "error"
    db.client.table("oauth_sync_accounts").update(update).eq("id", str(account.id)).execute()


def _record_rate_limited(db, account: SyncAccount) -> None:
    # Don't bump error_count — rate-limits are healthy back-pressure, not bugs.
    db.client.table("oauth_sync_accounts").update({
        "last_sync_at": datetime.now(timezone.utc).isoformat(),
        "last_sync_status": "rate_limited",
    }).eq("id", str(account.id)).execute()


def _mark_reauth_required(db, account: SyncAccount, detail: str) -> None:
    db.client.table("oauth_sync_accounts").update({
        "status": "expired",
        "last_sync_status": "failed",
        "last_error": detail[:500],
    }).eq("id", str(account.id)).execute()


def _soft_revoke_account(db, provider_slug: str, external_user_id: str) -> None:
    db.client.table("oauth_sync_accounts").update({
        "status": "revoked",
        "last_error": "User revoked access from provider",
    }).eq("provider", provider_slug).eq("provider_user_id", external_user_id).execute()


def _find_account_by_external(db, provider_slug: str, external_user_id: str) -> Optional[Dict[str, Any]]:
    result = (
        db.client.table("oauth_sync_accounts")
        .select("*")
        .eq("provider", provider_slug)
        .eq("provider_user_id", external_user_id)
        .limit(1)
        .execute()
    )
    rows = result.data or []
    return rows[0] if rows else None


def _mark_event_processed(db, event_id: str, attempts: int, *, error: Optional[str]) -> None:
    db.client.table("oauth_sync_webhook_events").update({
        "processed_at": datetime.now(timezone.utc).isoformat(),
        "process_attempts": attempts,
        "error": error[:500] if error else None,
    }).eq("id", event_id).execute()


# ───────────────────────────── CLI ─────────────────────────────

def _parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="FitWiz OAuth sync orchestrator")
    p.add_argument("--once", action="store_true", help="Run a single tick and exit")
    p.add_argument("--loop", action="store_true", help="Loop forever (local dev only)")
    return p.parse_args(argv)


def _configure_logging() -> None:
    level = logging.INFO if not os.environ.get("DEBUG") else logging.DEBUG
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )


def main(argv: Optional[List[str]] = None) -> int:
    _configure_logging()
    args = _parse_args(argv)
    if args.loop:
        # For local dev only — prod uses Render cron.
        while True:
            try:
                run_once()
            except Exception as e:
                logger.exception(f"[sync] orchestrator loop error: {e}")
            time.sleep(CRON_INTERVAL_MIN * 60)
    else:
        run_once()
    return 0


if __name__ == "__main__":
    sys.exit(main())
