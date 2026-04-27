"""
OAuth-based two-way sync package for Zealova.

Integrates with Strava, Garmin, Fitbit, Apple Health, and Peloton so users can
pull their cardio / strength history into Zealova without manual re-entry and,
conversely, so Zealova-completed workouts can round-trip out to their preferred
platform.

Each provider is implemented as a subclass of :class:`SyncProvider` (defined in
``oauth_base.py``). A 15-minute cron driven by ``sync_orchestrator.py`` polls
pull-only providers (Garmin, Peloton); push-capable providers (Strava, Fitbit)
fire webhooks that land rows in ``oauth_sync_webhook_events`` for the same
orchestrator to drain.

Key invariants:
- Tokens live encrypted at rest in ``oauth_sync_accounts`` (Fernet AES-GCM).
- Canonical row shapes are reused from ``services.workout_import.canonical``
  so the sync path and the file-import path converge on the same ``cardio_logs``
  / ``workout_history_imports`` tables with a shared dedup hash.
- ``source_external_id`` + ``source_row_hash`` together guarantee idempotency
  across retries and re-subscriptions.
"""
from services.sync.oauth_base import (
    SyncProvider,
    SyncProviderError,
    SyncAccount,
    TokenBundle,
)
from services.sync.token_encryption import (
    encrypt_token,
    decrypt_token,
    generate_encryption_key,
)

__all__ = [
    "SyncProvider",
    "SyncProviderError",
    "SyncAccount",
    "TokenBundle",
    "encrypt_token",
    "decrypt_token",
    "generate_encryption_key",
]
