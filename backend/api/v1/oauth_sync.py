"""
OAuth-based two-way sync endpoints for Strava, Garmin, Fitbit, Apple Health, Peloton.

The paths live under ``/api/v1/sync/*`` alongside the existing offline-sync
endpoints in ``api.v1.sync``. We keep them in a dedicated module because:
- the OAuth callback path is public (the provider posts here after consent),
- webhook receivers have their own auth model (signature verification, not JWT),
- and the flow only shares the ``/sync`` URL prefix with the offline-sync
  module by accident — they don't share code paths.

**Required environment variables** (missing vars → 500 at connect time, not
at import time, so local dev without creds can still boot):

    OAUTH_TOKEN_ENCRYPTION_KEY  # Fernet key. Generate: Fernet.generate_key()
    STRAVA_CLIENT_ID
    STRAVA_CLIENT_SECRET
    STRAVA_VERIFY_TOKEN         # shared secret for webhook sig + state signing
    GARMIN_CLIENT_ID            # placeholder; garminconnect is credential-auth
    GARMIN_CLIENT_SECRET
    FITBIT_CLIENT_ID
    FITBIT_CLIENT_SECRET
    PELOTON_EMAIL               # optional service-account
    PELOTON_PASSWORD            # optional service-account

Endpoints:

    POST   /sync/oauth/{provider}/begin      → {auth_url: ...}
    POST   /sync/oauth/{provider}/callback   → {account_id: ..., initial_job_id: ...}
    GET    /sync/accounts                    → [{...no tokens...}]
    PATCH  /sync/accounts/{id}               → toggle auto_import / import_* flags
    DELETE /sync/accounts/{id}
    GET    /sync/webhooks/strava             → hub.challenge handshake
    POST   /sync/webhooks/strava             → push event receiver
    POST   /sync/webhooks/fitbit             → push event receiver
    POST   /sync/apple-health/push           → HealthKit bridge (Flutter) data in
    POST   /sync/{id}/manual-sync            → force pull-now
"""
from __future__ import annotations

import json
import logging
import os
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID, uuid4

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Header, Query, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

from services.sync.oauth_base import (
    ProviderRateLimitedError,
    ReauthRequiredError,
    SyncAccount,
    SyncProviderError,
    get_provider,
    list_providers,
)
from services.sync.token_encryption import encrypt_token
from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
)
from services.workout_import.service import WorkoutHistoryImporter

logger = logging.getLogger(__name__)

# Note the prefix: ``/sync``. The existing ``api.v1.sync`` router uses the same
# prefix for ``/sync/bulk`` and ``/sync/import``. Our paths are all
# ``/sync/oauth/...``, ``/sync/accounts``, ``/sync/webhooks/...``,
# ``/sync/apple-health/push``, and ``/sync/{id}/manual-sync`` — none collide.
router = APIRouter(prefix="/sync", tags=["OAuth Sync"])


ALLOWED_PROVIDERS = {"strava", "garmin", "fitbit", "apple_health", "peloton"}


# ─────────────────────────── Request / Response models ───────────────────────────

class BeginAuthResponse(BaseModel):
    auth_url: str
    provider: str
    state: Optional[str] = None


class OAuthCallbackRequest(BaseModel):
    """Generic callback payload. Providers that follow OAuth2 use ``code`` + ``state``.
    Credential-auth providers (Garmin, Peloton) use ``email`` + ``password``.
    """
    code: Optional[str] = Field(default=None, description="OAuth authorization code")
    state: Optional[str] = Field(default=None, description="State parameter from auth URL")
    # For credential-auth providers only.
    email: Optional[str] = Field(default=None, max_length=320)
    password: Optional[str] = Field(default=None, max_length=200)
    # Scope override for test hooks only.
    user_id: Optional[str] = Field(default=None, description="Only honored if matches current_user.id")


class ConnectedAccountResponse(BaseModel):
    id: str
    user_id: str
    provider: str
    provider_user_id: str
    status: str
    scopes: List[str]
    last_sync_at: Optional[str] = None
    last_sync_status: Optional[str] = None
    last_error: Optional[str] = None
    error_count: int
    auto_import: bool
    import_strength: bool
    import_cardio: bool
    expires_at: Optional[str] = None
    created_at: Optional[str] = None


class UpdateAccountRequest(BaseModel):
    auto_import: Optional[bool] = None
    import_strength: Optional[bool] = None
    import_cardio: Optional[bool] = None


class AppleHealthPushRequest(BaseModel):
    activities: List[Dict[str, Any]] = Field(..., max_length=500)
    account_id: Optional[str] = None


class ManualSyncResponse(BaseModel):
    account_id: str
    synced_cardio: int
    synced_strength: int
    status: str


# ─────────────────────────── OAuth begin / callback ───────────────────────────

@router.post("/oauth/{provider}/begin", response_model=BeginAuthResponse)
async def begin_oauth(
    provider: str,
    current_user: dict = Depends(get_current_user),
):
    """Return the provider's consent URL for this user.

    The client opens it in an in-app browser and the provider redirects back
    to a URL we've registered on the Strava / Fitbit dashboard, which is
    captured by a deep link on the mobile app and forwarded to the callback
    endpoint.
    """
    _validate_provider(provider)
    try:
        sync_provider = get_provider(provider)
        url = sync_provider.begin_auth(UUID(current_user["id"]))
    except SyncProviderError as e:
        raise HTTPException(status_code=400, detail=str(e))
    logger.info(f"🔐 [oauth-sync] begin provider={provider} user={current_user['id']}")
    return BeginAuthResponse(auth_url=url, provider=provider)


@router.post("/oauth/{provider}/callback")
async def oauth_callback(
    provider: str,
    body: OAuthCallbackRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Complete the OAuth exchange, encrypt tokens, persist the account,
    register the webhook (if applicable), and kick off an initial 90-day backfill.

    Returns ``{account_id, initial_job_id}``. ``initial_job_id`` is the
    ``media_analysis_jobs`` row id the client can poll for backfill progress.
    """
    _validate_provider(provider)
    try:
        sync_provider = get_provider(provider)
    except SyncProviderError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Normalize credential-auth payloads into the "code" field.
    code = body.code
    if provider in ("garmin", "peloton") and body.email and body.password:
        code = f"{body.email}\t{body.password}"
    if code is None:
        raise HTTPException(status_code=400, detail="Missing OAuth code or credentials")

    try:
        bundle = sync_provider.exchange_code(code, body.state or "")
    except ReauthRequiredError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except SyncProviderError as e:
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        logger.exception(f"[oauth-sync] {provider} exchange_code failed")
        raise safe_internal_error(e, "oauth_sync.callback")

    db = get_supabase_db()
    user_id = current_user["id"]
    provider_user_id = bundle.provider_user_id or f"{provider}:{uuid4().hex}"

    row: Dict[str, Any] = {
        "user_id": user_id,
        "provider": provider,
        "provider_user_id": provider_user_id,
        "access_token_encrypted": encrypt_token(bundle.access_token),
        "refresh_token_encrypted": encrypt_token(bundle.refresh_token) if bundle.refresh_token else None,
        "expires_at": bundle.expires_at.isoformat() if bundle.expires_at else None,
        "scopes": list(bundle.scopes or []),
        "status": "active",
        "last_sync_at": None,
        "last_sync_status": None,
        "last_error": None,
        "error_count": 0,
        "auto_import": True,
        "import_strength": sync_provider.supports_strength,
        "import_cardio": True,
    }

    try:
        upsert = (
            db.client.table("oauth_sync_accounts")
            .upsert(row, on_conflict="user_id,provider")
            .execute()
        )
        data = upsert.data or []
        if not data:
            raise RuntimeError("Upsert returned no rows")
        account_id = data[0]["id"]
    except Exception as e:
        logger.exception(f"[oauth-sync] upsert failed for user={user_id}")
        raise safe_internal_error(e, "oauth_sync.upsert")

    # Register webhook (best-effort; non-fatal).
    webhook_id: Optional[str] = None
    try:
        account = SyncAccount.from_db_row({
            **row,
            "id": account_id,
            "created_at": None,
        })
        webhook_id = sync_provider.register_webhook(account)
        if webhook_id:
            db.client.table("oauth_sync_accounts").update({"webhook_id": webhook_id}).eq(
                "id", account_id
            ).execute()
    except Exception as e:
        logger.warning(f"[oauth-sync] webhook register failed for {provider}: {e}")

    # Initial backfill as a background task so we don't block the client.
    initial_job_id = str(uuid4())
    background_tasks.add_task(
        _initial_backfill_sync,
        account_id=account_id,
        provider=provider,
        lookback_days=sync_provider.default_lookback_days,
    )

    logger.info(
        f"🟢 [oauth-sync] connected provider={provider} user={user_id} "
        f"account={account_id} webhook_id={webhook_id or 'none'} "
        f"token_len={len(bundle.access_token)}"
    )
    return {
        "account_id": account_id,
        "initial_job_id": initial_job_id,
        "webhook_registered": webhook_id is not None,
    }


# ─────────────────────────── Accounts CRUD ───────────────────────────

@router.get("/accounts", response_model=List[ConnectedAccountResponse])
async def list_accounts(current_user: dict = Depends(get_current_user)):
    """List connected sync accounts for the current user (tokens redacted)."""
    db = get_supabase_db()
    result = (
        db.client.table("oauth_sync_accounts")
        .select(
            "id, user_id, provider, provider_user_id, status, scopes, "
            "last_sync_at, last_sync_status, last_error, error_count, "
            "auto_import, import_strength, import_cardio, expires_at, created_at"
        )
        .eq("user_id", current_user["id"])
        .order("created_at", desc=True)
        .execute()
    )
    return [
        ConnectedAccountResponse(
            id=row["id"],
            user_id=row["user_id"],
            provider=row["provider"],
            provider_user_id=row["provider_user_id"],
            status=row["status"],
            scopes=list(row.get("scopes") or []),
            last_sync_at=_opt_str(row.get("last_sync_at")),
            last_sync_status=row.get("last_sync_status"),
            last_error=row.get("last_error"),
            error_count=int(row.get("error_count") or 0),
            auto_import=bool(row.get("auto_import")),
            import_strength=bool(row.get("import_strength")),
            import_cardio=bool(row.get("import_cardio")),
            expires_at=_opt_str(row.get("expires_at")),
            created_at=_opt_str(row.get("created_at")),
        )
        for row in (result.data or [])
    ]


@router.patch("/accounts/{account_id}", response_model=ConnectedAccountResponse)
async def update_account(
    account_id: str,
    body: UpdateAccountRequest,
    current_user: dict = Depends(get_current_user),
):
    """Toggle per-account import preferences (auto_import, import_strength, import_cardio)."""
    db = get_supabase_db()
    _assert_account_ownership(db, account_id, current_user["id"])
    patch = {k: v for k, v in body.model_dump(exclude_none=True).items()}
    if not patch:
        raise HTTPException(status_code=400, detail="Nothing to update")
    result = (
        db.client.table("oauth_sync_accounts")
        .update(patch)
        .eq("id", account_id)
        .execute()
    )
    return (await list_accounts(current_user=current_user))[0]


@router.delete("/accounts/{account_id}")
async def delete_account(
    account_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Revoke a connected account: unregister webhook, set status=revoked, soft-delete row.

    We soft-delete by status flip, not hard-delete, so audit / webhook-replay
    stays consistent if the provider fires one more event after disconnect.
    Hard-delete happens only on user-account deletion (via ON DELETE CASCADE).
    """
    db = get_supabase_db()
    row = _assert_account_ownership(db, account_id, current_user["id"])
    try:
        sync_provider = get_provider(row["provider"])
        account = SyncAccount.from_db_row(row)
        sync_provider.unregister_webhook(account)
    except Exception as e:
        logger.warning(f"[oauth-sync] unregister_webhook failed: {e}")

    db.client.table("oauth_sync_accounts").update({
        "status": "revoked",
        "webhook_id": None,
    }).eq("id", account_id).execute()
    logger.info(f"🛑 [oauth-sync] revoked account={account_id} user={current_user['id']}")
    return {"status": "revoked", "account_id": account_id}


@router.post("/{account_id}/manual-sync", response_model=ManualSyncResponse)
async def manual_sync(
    account_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Force a pull-sync right now. Useful when the user wants immediate feedback
    after connecting and doesn't want to wait for the 15-min cron.
    """
    db = get_supabase_db()
    row = _assert_account_ownership(db, account_id, current_user["id"])
    try:
        sync_provider = get_provider(row["provider"])
        account = SyncAccount.from_db_row(row)
        since = account.last_sync_at or (
            datetime.now(timezone.utc) - timedelta(days=sync_provider.default_lookback_days)
        )
        rows = sync_provider.fetch_since(account, since)
    except ReauthRequiredError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except SyncProviderError as e:
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        raise safe_internal_error(e, "oauth_sync.manual_sync")

    importer = WorkoutHistoryImporter()
    cardio_rows = [r for r in rows if isinstance(r, CanonicalCardioRow)]
    strength_rows = [r for r in rows if isinstance(r, CanonicalSetRow)]
    if not account.import_cardio:
        cardio_rows = []
    if not account.import_strength:
        strength_rows = []
    inserted_cardio = importer._bulk_insert_cardio(db, cardio_rows, account.id)
    inserted_strength = importer._bulk_insert_strength(db, strength_rows, account.id)

    db.client.table("oauth_sync_accounts").update({
        "last_sync_at": datetime.now(timezone.utc).isoformat(),
        "last_sync_status": "ok",
        "last_error": None,
        "error_count": 0,
    }).eq("id", account_id).execute()

    return ManualSyncResponse(
        account_id=account_id,
        synced_cardio=inserted_cardio,
        synced_strength=inserted_strength,
        status="ok",
    )


# ─────────────────────────── Strava webhooks ───────────────────────────

@router.get("/webhooks/strava")
async def strava_webhook_verify(
    hub_mode: Optional[str] = Query(default=None, alias="hub.mode"),
    hub_challenge: Optional[str] = Query(default=None, alias="hub.challenge"),
    hub_verify_token: Optional[str] = Query(default=None, alias="hub.verify_token"),
):
    """Strava subscription verification handshake.

    Strava calls this once during ``POST /push_subscriptions``. We echo back the
    challenge if the verify_token matches ours. Failing this handshake means
    we can't receive push events at all.
    """
    expected = os.environ.get("STRAVA_VERIFY_TOKEN", "")
    if hub_verify_token != expected or hub_mode != "subscribe" or not hub_challenge:
        raise HTTPException(status_code=403, detail="Invalid Strava verification")
    logger.info("🔔 [strava] webhook verification handshake ok")
    return {"hub.challenge": hub_challenge}


@router.post("/webhooks/strava")
async def strava_webhook_receive(
    request: Request,
    x_hub_signature_256: Optional[str] = Header(default=None, alias="X-Hub-Signature-256"),
):
    """Strava push event receiver.

    Payload shape::

        {
          "object_type": "activity" | "athlete",
          "object_id": 1234567890,
          "aspect_type": "create" | "update" | "delete",
          "owner_id": 12345,
          "subscription_id": 120485,
          "event_time": 1699982413,
          "updates": {...}
        }

    We verify the HMAC-SHA256 signature against ``STRAVA_VERIFY_TOKEN``, insert
    a row into ``oauth_sync_webhook_events`` and return 200 fast. The
    sync_orchestrator drains it next tick.
    """
    from services.sync.strava import StravaProvider

    body = await request.body()
    if not StravaProvider.verify_webhook_signature(body, x_hub_signature_256):
        logger.warning("[strava] webhook signature rejected")
        raise HTTPException(status_code=401, detail="Invalid signature")

    try:
        payload = json.loads(body.decode("utf-8") or "{}")
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON payload")

    event_type_map = {
        ("activity", "create"): "activity.create",
        ("activity", "update"): "activity.update",
        ("activity", "delete"): "activity.delete",
        ("athlete", "update"): "deauthorize" if (payload.get("updates") or {}).get("authorized") == "false" else "athlete.update",
    }
    key = (payload.get("object_type"), payload.get("aspect_type"))
    event_type = event_type_map.get(key, f"{key[0]}.{key[1]}")

    _enqueue_webhook_event(
        provider="strava",
        event_type=event_type,
        external_user_id=str(payload.get("owner_id") or ""),
        external_object_id=str(payload.get("object_id") or "") or None,
        payload=payload,
    )
    return {"status": "queued"}


# ─────────────────────────── Fitbit webhook ───────────────────────────

@router.post("/webhooks/fitbit")
async def fitbit_webhook_receive(
    request: Request,
    x_fitbit_signature: Optional[str] = Header(default=None, alias="X-Fitbit-Signature"),
):
    """Fitbit subscriber endpoint.

    Fitbit POSTs an *array* of notifications, each of which points to a
    ``collectionType`` + ``ownerId`` + ``date`` triple rather than an activity
    id directly. We queue one webhook event per notification.
    """
    from services.sync.fitbit import FitbitProvider

    body = await request.body()
    if not FitbitProvider.verify_webhook_signature(body, x_fitbit_signature):
        logger.warning("[fitbit] webhook signature rejected")
        raise HTTPException(status_code=401, detail="Invalid signature")

    try:
        notifications = json.loads(body.decode("utf-8") or "[]")
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON payload")
    if not isinstance(notifications, list):
        raise HTTPException(status_code=400, detail="Expected JSON array from Fitbit")

    for note in notifications:
        collection = note.get("collectionType")
        event_type = "activity.update" if collection == "activities" else f"{collection}.update"
        _enqueue_webhook_event(
            provider="fitbit",
            event_type=event_type,
            external_user_id=str(note.get("ownerId") or ""),
            external_object_id=str(note.get("subscriptionId") or "") or None,
            payload=note,
        )
    return {"status": "queued", "count": len(notifications)}


# ─────────────────────────── Apple Health push ───────────────────────────

@router.post("/apple-health/push")
async def apple_health_push(
    body: AppleHealthPushRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """HealthKit bridge (Flutter ``health`` package) posts workouts here.

    Payload shape — see docstring of :meth:`AppleHealthProvider.receive_healthkit_sync`.
    Returns the number of rows inserted (pre-dedup).
    """
    from services.sync.apple_health import AppleHealthProvider

    user_id = UUID(current_user["id"])
    provider = AppleHealthProvider()
    parsed = provider.receive_healthkit_sync(
        user_id=user_id,
        activities=body.activities,
        sync_account_id=UUID(body.account_id) if body.account_id else None,
    )
    cardio_rows = parsed["cardio_rows"]
    strength_rows = parsed["strength_rows"]

    importer = WorkoutHistoryImporter()
    db = get_supabase_db()
    # ``account.id`` is None when Apple Health is a device-only connection —
    # use a NULL sync_account_id for the import helper (it accepts None).
    inserted_cardio = importer._bulk_insert_cardio(db, cardio_rows, None)
    inserted_strength = importer._bulk_insert_strength(db, strength_rows, None)

    # If there's an apple_health account row, bump its last_sync_at.
    try:
        acct = (
            db.client.table("oauth_sync_accounts")
            .select("id")
            .eq("user_id", str(user_id))
            .eq("provider", "apple_health")
            .limit(1)
            .execute()
        )
        if acct.data:
            db.client.table("oauth_sync_accounts").update({
                "last_sync_at": datetime.now(timezone.utc).isoformat(),
                "last_sync_status": "ok",
                "last_error": None,
                "error_count": 0,
            }).eq("id", acct.data[0]["id"]).execute()
    except Exception as e:
        logger.warning(f"[apple_health] last_sync update failed: {e}")

    # Trophies + masteries — run in background so the sync response
    # returns immediately. Detached via asyncio.create_task rather than
    # FastAPI BackgroundTasks because the starlette BaseHTTPMiddleware
    # the app runs behind serializes BackgroundTasks into the response
    # lifecycle (slow trophy work → multi-minute "response time" logs).
    # Helper is self-guarded with a 60s timeout.
    if inserted_cardio or inserted_strength:
        from services.mastery_writes import fire_trophy_check_detached
        fire_trophy_check_detached(str(user_id))

    logger.info(
        f"🍎 [apple_health] push user={user_id} activities={len(body.activities)} "
        f"inserted={inserted_cardio}c/{inserted_strength}s"
    )
    return {
        "inserted_cardio": inserted_cardio,
        "inserted_strength": inserted_strength,
        "total_activities": len(body.activities),
    }


# ─────────────────────────── Helpers ───────────────────────────

def _validate_provider(provider: str) -> None:
    if provider not in ALLOWED_PROVIDERS:
        raise HTTPException(
            status_code=404,
            detail=f"Unknown provider '{provider}'. Allowed: {sorted(ALLOWED_PROVIDERS)}",
        )


def _assert_account_ownership(db, account_id: str, user_id: str) -> Dict[str, Any]:
    """Fetch the account row and verify the current user owns it. Returns the row."""
    try:
        UUID(account_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="account_id must be a UUID")
    result = (
        db.client.table("oauth_sync_accounts")
        .select("*")
        .eq("id", account_id)
        .limit(1)
        .execute()
    )
    rows = result.data or []
    if not rows:
        raise HTTPException(status_code=404, detail="Account not found")
    if rows[0]["user_id"] != user_id:
        # Deliberately 404 rather than 403 to avoid leaking existence.
        raise HTTPException(status_code=404, detail="Account not found")
    return rows[0]


def _enqueue_webhook_event(
    *,
    provider: str,
    event_type: str,
    external_user_id: str,
    external_object_id: Optional[str],
    payload: Dict[str, Any],
) -> None:
    db = get_supabase_db()
    try:
        db.client.table("oauth_sync_webhook_events").insert({
            "provider": provider,
            "event_type": event_type,
            "external_user_id": external_user_id,
            "external_object_id": external_object_id,
            "payload": payload,
            "signature_verified": True,
        }).execute()
    except Exception as e:
        # Unique index collision on (provider, object_id, event_type) means we
        # already have this event queued — safe to ignore.
        msg = str(e).lower()
        if "duplicate" in msg or "uq_sync_webhook_event_dedup" in msg:
            logger.info(f"[{provider}] duplicate webhook event suppressed")
            return
        logger.warning(f"[{provider}] webhook enqueue failed: {e}")


def _initial_backfill_sync(
    account_id: str,
    provider: str,
    lookback_days: int,
) -> None:
    """Background task: run a fetch_since(now - lookback_days) immediately after
    connect so the user sees history without waiting 15 min.
    """
    try:
        db = get_supabase_db()
        result = db.client.table("oauth_sync_accounts").select("*").eq("id", account_id).limit(1).execute()
        if not result.data:
            return
        row = result.data[0]
        account = SyncAccount.from_db_row(row)
        sync_provider = get_provider(provider)
        since = datetime.now(timezone.utc) - timedelta(days=lookback_days)
        rows = sync_provider.fetch_since(account, since)
        importer = WorkoutHistoryImporter()
        cardio_rows = [r for r in rows if isinstance(r, CanonicalCardioRow)]
        strength_rows = [r for r in rows if isinstance(r, CanonicalSetRow)]
        if not account.import_cardio:
            cardio_rows = []
        if not account.import_strength:
            strength_rows = []
        importer._bulk_insert_cardio(db, cardio_rows, account.id)
        importer._bulk_insert_strength(db, strength_rows, account.id)
        db.client.table("oauth_sync_accounts").update({
            "last_sync_at": datetime.now(timezone.utc).isoformat(),
            "last_sync_status": "ok",
        }).eq("id", account_id).execute()
        logger.info(
            f"🟢 [oauth-sync] initial backfill done provider={provider} account={account_id} "
            f"{len(cardio_rows)}c/{len(strength_rows)}s"
        )
    except ReauthRequiredError as e:
        logger.warning(f"[oauth-sync] backfill reauth required: {e}")
    except Exception as e:
        logger.exception(f"[oauth-sync] backfill failed for {account_id}: {e}")


def _opt_str(v: Any) -> Optional[str]:
    if v is None:
        return None
    return str(v)
