"""
Strava provider — OAuth 2.0 (auth-code, **not** PKCE; Strava doesn't support it)
+ push webhooks via Strava's Push Subscriptions API.

Activity-type → Zealova cardio enum mapping:

    Run                → run
    TrailRun           → run
    Walk / Hike        → hike
    Ride / GravelRide  → cycle
    VirtualRide        → indoor_cycle
    MountainBikeRide   → cycle
    Swim               → swim
    Rowing / VirtualRow→ row
    WeightTraining     → (skipped — Strava has no per-set data)
    *                  → other

Rate limits per the Strava API:
    100 requests / 15 minutes
    1000 requests / day

We surface ``ProviderRateLimitedError`` on HTTP 429; the orchestrator records
``last_sync_status='rate_limited'`` and tries again on the next cron tick.
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging
import os
import secrets
import time
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

import httpx

from services.sync.oauth_base import (
    ProviderRateLimitedError,
    ReauthRequiredError,
    SyncAccount,
    SyncProvider,
    SyncProviderError,
    TokenBundle,
    register_provider,
)
from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
)

logger = logging.getLogger(__name__)

STRAVA_AUTH_URL = "https://www.strava.com/oauth/authorize"
STRAVA_TOKEN_URL = "https://www.strava.com/api/v3/oauth/token"
STRAVA_API_BASE = "https://www.strava.com/api/v3"
STRAVA_PUSH_BASE = "https://www.strava.com/api/v3/push_subscriptions"

# Scopes we request. "activity:read_all" includes private activities.
STRAVA_SCOPES = ["read", "activity:read_all", "profile:read_all"]

# Strava activity_type → our cardio enum + "skip" marker for strength.
_ACTIVITY_TYPE_MAP: Dict[str, Optional[str]] = {
    "Run": "run",
    "TrailRun": "run",
    "VirtualRun": "run",
    "Walk": "hike",
    "Hike": "hike",
    "Ride": "cycle",
    "GravelRide": "cycle",
    "MountainBikeRide": "cycle",
    "EBikeRide": "cycle",
    "VirtualRide": "indoor_cycle",
    "Swim": "swim",
    "Rowing": "row",
    "VirtualRow": "row",
    "WeightTraining": None,            # Strava has no per-set data
    "Workout": None,
    "Crossfit": None,
    "Yoga": "yoga",
    "Elliptical": "elliptical",
    "StairStepper": "stair_stepper",
}


@register_provider("strava")
class StravaProvider(SyncProvider):
    """Implements the full Strava OAuth + webhook flow.

    ``stravalib`` is intentionally avoided for the HTTP layer because:
    1. It wraps every response in its own dataclasses, which are awkward to
       convert into our canonical rows (and fight our datetime-with-tz rule).
    2. Its version pinning dragged ``pydantic<2`` historically.

    We do still *list* ``stravalib`` in requirements.txt for dev scripts and
    tests that want a nicer object graph; the prod path uses ``httpx`` + raw
    JSON.
    """

    supports_webhooks = True
    supports_strength = False   # Strava offers no per-set data
    default_lookback_days = 90

    # ───────────────────────────── OAuth ─────────────────────────────

    def begin_auth(self, user_id: UUID) -> str:
        client_id = self._client_id()
        redirect_uri = self._redirect_uri()
        # State carries the user_id + nonce. Signed in the callback endpoint;
        # here we just pack it.
        state = self._sign_state(str(user_id))
        params = {
            "client_id": client_id,
            "response_type": "code",
            "redirect_uri": redirect_uri,
            "approval_prompt": "auto",
            "scope": ",".join(STRAVA_SCOPES),
            "state": state,
        }
        qs = "&".join(f"{k}={_url_quote(v)}" for k, v in params.items())
        return f"{STRAVA_AUTH_URL}?{qs}"

    def exchange_code(self, code: str, state: str) -> TokenBundle:
        resp = httpx.post(
            STRAVA_TOKEN_URL,
            data={
                "client_id": self._client_id(),
                "client_secret": self._client_secret(),
                "code": code,
                "grant_type": "authorization_code",
            },
            timeout=15.0,
        )
        data = _raise_for_status_and_parse(resp)
        return TokenBundle(
            access_token=data["access_token"],
            refresh_token=data.get("refresh_token"),
            expires_at=_expires_at_from_epoch(data.get("expires_at")),
            scopes=STRAVA_SCOPES,
            provider_user_id=str(data.get("athlete", {}).get("id") or ""),
        )

    def refresh_token(self, account: SyncAccount) -> TokenBundle:
        if not account.refresh_token:
            raise ReauthRequiredError("No refresh token on Strava account")
        resp = httpx.post(
            STRAVA_TOKEN_URL,
            data={
                "client_id": self._client_id(),
                "client_secret": self._client_secret(),
                "refresh_token": account.refresh_token,
                "grant_type": "refresh_token",
            },
            timeout=15.0,
        )
        if resp.status_code == 400:
            # Strava returns 400 Bad Request with "errors: [{code: 'invalid'}]"
            # when the refresh token is revoked.
            raise ReauthRequiredError("Strava refresh token is invalid")
        data = _raise_for_status_and_parse(resp)
        return TokenBundle(
            access_token=data["access_token"],
            refresh_token=data.get("refresh_token") or account.refresh_token,
            expires_at=_expires_at_from_epoch(data.get("expires_at")),
            scopes=account.scopes or STRAVA_SCOPES,
            provider_user_id=account.provider_user_id,
        )

    # ─────────────────────────── Data pull ───────────────────────────

    def fetch_since(self, account: SyncAccount, since: datetime) -> List[CanonicalCardioRow]:
        """Fetch activities since ``since``. Paginates 30 results at a time."""
        headers = {"Authorization": f"Bearer {account.access_token}"}
        params = {
            "after": int(since.timestamp()),
            "per_page": 200,
            "page": 1,
        }
        rows: List[CanonicalCardioRow] = []
        # Cap total pages so a bad server doesn't hang the cron.
        for _ in range(25):
            resp = httpx.get(
                f"{STRAVA_API_BASE}/athlete/activities",
                params=params,
                headers=headers,
                timeout=30.0,
            )
            if resp.status_code == 401:
                raise ReauthRequiredError("Strava access token rejected")
            if resp.status_code == 429:
                raise ProviderRateLimitedError()
            data = _raise_for_status_and_parse(resp)
            if not data:
                break
            for activity in data:
                row = _strava_activity_to_cardio(activity, user_id=account.user_id,
                                                 sync_account_id=account.id)
                if row is not None:
                    rows.append(row)
            if len(data) < params["per_page"]:
                break
            params["page"] += 1
        logger.info(
            f"🏃 [strava] fetched {len(rows)} activities for user={account.user_id} since={since.isoformat()}"
        )
        return rows

    # ──────────────────────────── Webhook ────────────────────────────

    def register_webhook(self, account: SyncAccount) -> Optional[str]:
        """Subscribe to Strava push events for *this app*.

        Note: Strava push subscriptions are **per application**, not per user —
        one subscription covers every authenticated athlete. So we idempotently
        create the app subscription the first time any user connects, and reuse
        the same subscription id for every subsequent ``register_webhook`` call.
        """
        try:
            existing_id = _ensure_strava_app_subscription()
        except SyncProviderError:
            raise
        except Exception as e:  # pragma: no cover — network flake
            logger.warning(f"[strava] webhook subscribe failed: {e}")
            return None
        return existing_id

    def unregister_webhook(self, account: SyncAccount) -> None:
        """Note: we do *not* tear down the app-level subscription when a single
        user disconnects — other users are still relying on it. The bookkeeping
        is at the app level, not the account level. No-op."""
        return None

    # ─────────────────────── Signature verification ───────────────────

    @staticmethod
    def verify_webhook_signature(body: bytes, signature: Optional[str]) -> bool:
        """Verify Strava's ``X-Hub-Signature-256`` against ``STRAVA_VERIFY_TOKEN``.

        Strava's subscription-side verification uses the ``hub.verify_token``
        challenge + HMAC-SHA256 over the body. We accept both because their
        docs are inconsistent: recent push payloads use the HMAC header.
        Unsigned requests are rejected.
        """
        verify_token = os.environ.get("STRAVA_VERIFY_TOKEN", "")
        if not verify_token:
            logger.error("[strava] STRAVA_VERIFY_TOKEN is unset — rejecting webhook")
            return False
        if not signature:
            return False
        # Header format: "sha256=<hex>"
        prefix = "sha256="
        if signature.startswith(prefix):
            signature = signature[len(prefix):]
        mac = hmac.new(verify_token.encode(), body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(mac, signature)

    # ─────────────────────────── Private ────────────────────────────

    @staticmethod
    def _client_id() -> str:
        v = os.environ.get("STRAVA_CLIENT_ID")
        if not v:
            raise SyncProviderError("STRAVA_CLIENT_ID is not configured")
        return v

    @staticmethod
    def _client_secret() -> str:
        v = os.environ.get("STRAVA_CLIENT_SECRET")
        if not v:
            raise SyncProviderError("STRAVA_CLIENT_SECRET is not configured")
        return v

    @staticmethod
    def _redirect_uri() -> str:
        # The public HTTPS URL the backend is reachable at. Must exactly match
        # the URL registered on the Strava app dashboard or the OAuth exchange fails.
        base = os.environ.get("BACKEND_BASE_URL") or "https://aifitnesscoach-zqi3.onrender.com"
        return f"{base.rstrip('/')}/api/v1/sync/oauth/strava/callback"

    @staticmethod
    def _sign_state(user_id: str) -> str:
        """Sign the state token with the verify-token secret. Format: ``<user>.<nonce>.<sig>``."""
        secret = os.environ.get("STRAVA_VERIFY_TOKEN", "") or os.environ.get(
            "OAUTH_TOKEN_ENCRYPTION_KEY", ""
        )
        nonce = secrets.token_urlsafe(12)
        payload = f"{user_id}.{nonce}"
        sig = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()[:16]
        return f"{payload}.{sig}"


# ─────────────────────────── Helpers ───────────────────────────

def _url_quote(v: str) -> str:
    from urllib.parse import quote
    return quote(str(v), safe="")


def _raise_for_status_and_parse(resp: httpx.Response) -> Any:
    if resp.status_code == 429:
        raise ProviderRateLimitedError()
    if resp.status_code == 401:
        raise ReauthRequiredError("Strava token rejected")
    if resp.status_code >= 400:
        # Strava error shape: {"message":"...","errors":[{...}]}. Omit body from
        # exception message in prod — it sometimes echoes the (short-lived) code.
        raise SyncProviderError(
            f"Strava API error {resp.status_code}", retriable=(resp.status_code >= 500)
        )
    try:
        return resp.json()
    except json.JSONDecodeError:
        raise SyncProviderError("Strava returned non-JSON response")


def _expires_at_from_epoch(epoch: Optional[int]) -> Optional[datetime]:
    if epoch is None:
        return None
    try:
        return datetime.fromtimestamp(int(epoch), tz=timezone.utc)
    except (TypeError, ValueError):
        return None


def _strava_activity_to_cardio(
    activity: Dict[str, Any],
    *,
    user_id: UUID,
    sync_account_id: UUID,
) -> Optional[CanonicalCardioRow]:
    """Map a Strava activity dict to ``CanonicalCardioRow``. Returns None if
    the activity is a non-mappable strength session."""
    strava_type = activity.get("type") or activity.get("sport_type") or "Workout"
    mapped = _ACTIVITY_TYPE_MAP.get(strava_type, "other")
    if mapped is None:
        return None

    started_str = activity.get("start_date")
    if not started_str:
        return None
    performed_at = _parse_strava_datetime(started_str)
    if performed_at is None:
        return None

    duration = int(activity.get("elapsed_time") or activity.get("moving_time") or 0)
    if duration <= 0:
        return None
    distance_m = float(activity.get("distance") or 0) or None
    external_id = str(activity.get("id") or "") or None

    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="strava",
        performed_at=performed_at,
        activity_type=mapped,
        duration_seconds=duration,
        distance_m=distance_m,
    )

    return CanonicalCardioRow(
        user_id=user_id,
        performed_at=performed_at,
        activity_type=mapped,
        duration_seconds=duration,
        distance_m=distance_m,
        elevation_gain_m=_maybe_float(activity.get("total_elevation_gain")),
        avg_heart_rate=_maybe_int(activity.get("average_heartrate")),
        max_heart_rate=_maybe_int(activity.get("max_heartrate")),
        avg_speed_mps=_maybe_float(activity.get("average_speed")),
        avg_watts=_maybe_int(activity.get("average_watts")),
        max_watts=_maybe_int(activity.get("max_watts")),
        calories=_maybe_int(activity.get("calories")),
        notes=activity.get("name"),
        gps_polyline=(activity.get("map") or {}).get("summary_polyline"),
        source_app="strava",
        source_external_id=external_id,
        source_row_hash=row_hash,
        sync_account_id=sync_account_id,
    )


def _parse_strava_datetime(raw: str) -> Optional[datetime]:
    # Strava serializes as "2024-03-18T14:22:10Z"
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(raw)
    except ValueError:
        return None
    return dt.astimezone(timezone.utc)


def _maybe_int(v: Any) -> Optional[int]:
    if v is None:
        return None
    try:
        return int(v)
    except (TypeError, ValueError):
        return None


def _maybe_float(v: Any) -> Optional[float]:
    if v is None:
        return None
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def _ensure_strava_app_subscription() -> Optional[str]:
    """Idempotently create the app-level push subscription. Returns its id.

    Strava's push API is: ``POST /push_subscriptions`` to create, ``GET`` to
    list, ``DELETE /push_subscriptions/{id}`` to tear down. It 400s with
    ``already exists`` if we try to re-create — we catch that and list to find
    the existing id.
    """
    client_id = os.environ.get("STRAVA_CLIENT_ID")
    client_secret = os.environ.get("STRAVA_CLIENT_SECRET")
    verify_token = os.environ.get("STRAVA_VERIFY_TOKEN", "")
    base = os.environ.get("BACKEND_BASE_URL") or "https://aifitnesscoach-zqi3.onrender.com"
    callback_url = f"{base.rstrip('/')}/api/v1/sync/webhooks/strava"

    if not (client_id and client_secret and verify_token):
        raise SyncProviderError("Strava webhook env vars not configured")

    # First: see if a subscription already exists.
    resp = httpx.get(
        STRAVA_PUSH_BASE,
        params={"client_id": client_id, "client_secret": client_secret},
        timeout=15.0,
    )
    if resp.status_code == 200:
        existing = resp.json()
        if isinstance(existing, list) and existing:
            return str(existing[0].get("id"))

    # Create.
    resp = httpx.post(
        STRAVA_PUSH_BASE,
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "callback_url": callback_url,
            "verify_token": verify_token,
        },
        timeout=15.0,
    )
    if resp.status_code >= 400:
        # 400 "already exists" is a race between concurrent registrations — re-list.
        if resp.status_code == 400 and b"already exists" in resp.content.lower():
            resp2 = httpx.get(
                STRAVA_PUSH_BASE,
                params={"client_id": client_id, "client_secret": client_secret},
                timeout=15.0,
            )
            existing = resp2.json() if resp2.status_code == 200 else []
            if isinstance(existing, list) and existing:
                return str(existing[0].get("id"))
        raise SyncProviderError(f"Strava subscription create failed: {resp.status_code}")
    data = resp.json()
    return str(data.get("id"))
