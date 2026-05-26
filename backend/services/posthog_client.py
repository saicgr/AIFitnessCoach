"""PostHog server-side instrumentation for lifecycle events.

Thin wrapper around the official `posthog` Python SDK. The Flutter client
already captures user-facing events; this module mirrors that surface for
server-side events that the client can't see (push dispatched, email
dispatched, send failed). Together they form the closed-loop funnel
that the re-engagement system (push_nudge_cron, email_cron) needs to
become measurable.

Design notes:
  * No-op when `POSTHOG_API_KEY` is unset so a missing env var never crashes
    a cron job. The re-engagement system itself runs regardless of whether
    telemetry is wired.
  * Distinct IDs are Supabase user UUIDs. They MUST match the IDs the
    Flutter client identifies with so server + client events join on the
    same person in PostHog.
  * All event names follow the `lifecycle_*` prefix to keep them filterable
    in PostHog dashboards.
"""
from __future__ import annotations

import logging
import os
from typing import Any

import posthog

logger = logging.getLogger(__name__)

_initialized: bool = False


def init_posthog() -> None:
    """Configure the shared `posthog` module client.

    Reads `POSTHOG_API_KEY` (required) and `POSTHOG_HOST` (optional, defaults
    to PostHog cloud US). Safe to call multiple times; subsequent calls are
    no-ops. If the API key is missing, this logs once and stays silent —
    `capture_lifecycle` will short-circuit.
    """
    global _initialized
    if _initialized:
        return

    api_key = os.environ.get("POSTHOG_API_KEY", "").strip()
    if not api_key:
        logger.info(
            "POSTHOG_API_KEY not set; backend lifecycle events disabled. "
            "Set the env var in Render to enable."
        )
        return

    posthog.api_key = api_key
    host = os.environ.get("POSTHOG_HOST", "").strip()
    if host:
        posthog.host = host

    # Send synchronously-batched events; the consumer thread the SDK spawns
    # is fine for cron use and avoids the explicit flush() bookkeeping.
    posthog.disabled = False
    _initialized = True
    logger.info(
        "PostHog server client initialized (host=%s)",
        host or "https://us.i.posthog.com",
    )


def capture_lifecycle(
    user_id: str | None,
    event_name: str,
    properties: dict[str, Any] | None = None,
) -> None:
    """Fire a lifecycle event for `user_id`.

    Silently no-ops if PostHog isn't initialized or if `user_id` is empty.
    Never raises — telemetry must not break the send pipeline it observes.

    `event_name` follows the `lifecycle_*` taxonomy from the audit:
      * lifecycle_push_sent
      * lifecycle_email_sent
      * lifecycle_send_failed

    `properties` should always include a `kind` key naming the specific
    job (e.g. `kind=win_back`) so a single event name covers all jobs.
    """
    if not _initialized:
        return
    if not user_id:
        return
    try:
        posthog.capture(
            distinct_id=str(user_id),
            event=event_name,
            properties=properties or {},
        )
    except Exception as exc:  # noqa: BLE001 — telemetry must never raise
        # Log at debug to avoid spamming the log stream if PostHog itself
        # is degraded; the cron job's primary work already succeeded by the
        # time this fires.
        logger.debug("PostHog capture failed (%s): %s", event_name, exc)


def flush() -> None:
    """Force-flush the SDK's queue. Optional; the SDK auto-flushes on a
    background thread. Useful in tests or before short-lived processes
    (one-shot cron containers) exit.
    """
    if not _initialized:
        return
    try:
        posthog.flush()
    except Exception as exc:  # noqa: BLE001
        logger.debug("PostHog flush failed: %s", exc)
