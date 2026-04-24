"""
Fitbit provider — OAuth 2.0 with PKCE + Fitbit's subscriber webhook model.

Fitbit's subscription API is *pull-on-notify* rather than *push-payload*:
when an activity changes, Fitbit POSTs a tiny notification to our subscriber
endpoint telling us which ``userId`` + collection has new data, and we then
pull the updated activities ourselves. Signature header is
``X-Fitbit-Signature`` (base64 HMAC-SHA1 over the *body* using the client
secret).
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import logging
import os
import secrets
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
from services.workout_import.canonical import CanonicalCardioRow

logger = logging.getLogger(__name__)

FITBIT_AUTH_URL = "https://www.fitbit.com/oauth2/authorize"
FITBIT_TOKEN_URL = "https://api.fitbit.com/oauth2/token"
FITBIT_API_BASE = "https://api.fitbit.com"

FITBIT_SCOPES = ["activity", "heartrate", "profile"]

_FITBIT_ACTIVITY_MAP: Dict[str, Optional[str]] = {
    "Run": "run",
    "Treadmill": "run",
    "Outdoor Bike": "cycle",
    "Bike": "cycle",
    "Spinning": "indoor_cycle",
    "Swim": "swim",
    "Walk": "hike",
    "Hike": "hike",
    "Workout": None,
    "Weights": None,
    "Yoga": "yoga",
    "Elliptical": "elliptical",
    "Stairs": "stair_stepper",
}


@register_provider("fitbit")
class FitbitProvider(SyncProvider):
    supports_webhooks = True
    supports_strength = False
    default_lookback_days = 90

    # ───────────────────── OAuth (authorization-code + PKCE) ─────────────────────

    def begin_auth(self, user_id: UUID) -> str:
        client_id = self._client_id()
        redirect_uri = self._redirect_uri()
        # PKCE S256 code verifier + challenge.
        verifier = secrets.token_urlsafe(64)
        challenge = base64.urlsafe_b64encode(
            hashlib.sha256(verifier.encode()).digest()
        ).rstrip(b"=").decode()
        # State encodes user_id + the verifier (symmetrically) so we can recover
        # it on callback. In production you'd persist this in Redis — the
        # ``oauth_flow_state`` column could hold it. We inline-encode for now.
        state = self._pack_state(str(user_id), verifier)
        params = {
            "client_id": client_id,
            "response_type": "code",
            "scope": " ".join(FITBIT_SCOPES),
            "redirect_uri": redirect_uri,
            "code_challenge": challenge,
            "code_challenge_method": "S256",
            "state": state,
        }
        qs = "&".join(f"{k}={_quote(v)}" for k, v in params.items())
        return f"{FITBIT_AUTH_URL}?{qs}"

    def exchange_code(self, code: str, state: str) -> TokenBundle:
        user_id, verifier = self._unpack_state(state)
        resp = httpx.post(
            FITBIT_TOKEN_URL,
            data={
                "client_id": self._client_id(),
                "grant_type": "authorization_code",
                "redirect_uri": self._redirect_uri(),
                "code": code,
                "code_verifier": verifier,
            },
            auth=(self._client_id(), self._client_secret()),
            timeout=15.0,
        )
        data = _raise_for_status(resp)
        return TokenBundle(
            access_token=data["access_token"],
            refresh_token=data.get("refresh_token"),
            expires_at=_expires_at(data.get("expires_in")),
            scopes=(data.get("scope") or "").split() or FITBIT_SCOPES,
            provider_user_id=data.get("user_id"),
        )

    def refresh_token(self, account: SyncAccount) -> TokenBundle:
        if not account.refresh_token:
            raise ReauthRequiredError("No refresh token on Fitbit account")
        resp = httpx.post(
            FITBIT_TOKEN_URL,
            data={
                "grant_type": "refresh_token",
                "refresh_token": account.refresh_token,
            },
            auth=(self._client_id(), self._client_secret()),
            timeout=15.0,
        )
        if resp.status_code in (400, 401):
            raise ReauthRequiredError("Fitbit refresh token invalid")
        data = _raise_for_status(resp)
        return TokenBundle(
            access_token=data["access_token"],
            refresh_token=data.get("refresh_token") or account.refresh_token,
            expires_at=_expires_at(data.get("expires_in")),
            scopes=(data.get("scope") or "").split() or account.scopes,
            provider_user_id=account.provider_user_id,
        )

    # ──────────────────────── Data pull ────────────────────────

    def fetch_since(self, account: SyncAccount, since: datetime) -> List[CanonicalCardioRow]:
        headers = {"Authorization": f"Bearer {account.access_token}"}
        rows: List[CanonicalCardioRow] = []
        # Fitbit `activities/list` pages 20 at a time, newest first.
        url = f"{FITBIT_API_BASE}/1/user/-/activities/list.json"
        params = {
            "afterDate": since.strftime("%Y-%m-%dT%H:%M:%S"),
            "sort": "asc",
            "offset": 0,
            "limit": 100,
        }
        for _ in range(20):
            resp = httpx.get(url, headers=headers, params=params, timeout=30.0)
            if resp.status_code == 401:
                raise ReauthRequiredError("Fitbit token rejected")
            if resp.status_code == 429:
                raise ProviderRateLimitedError()
            data = _raise_for_status(resp)
            activities = data.get("activities", [])
            for activity in activities:
                row = _fitbit_activity_to_cardio(
                    activity, user_id=account.user_id, sync_account_id=account.id
                )
                if row:
                    rows.append(row)
            pagination = data.get("pagination") or {}
            next_url = pagination.get("next")
            if not next_url or not activities:
                break
            # `pagination.next` is a full URL.
            url = next_url
            params = {}
        logger.info(
            f"⌚ [fitbit] fetched {len(rows)} activities for user={account.user_id} since={since.isoformat()}"
        )
        return rows

    # ──────────────────────── Webhook ────────────────────────

    def register_webhook(self, account: SyncAccount) -> Optional[str]:
        """Fitbit subscriptions: POST to ``/1/user/-/activities/apiSubscriptions/{id}.json``.

        The subscription id is app-defined; we use the account UUID so dedup
        is trivial. Returns the subscription id stored in ``webhook_id``.
        """
        sub_id = str(account.id)
        resp = httpx.post(
            f"{FITBIT_API_BASE}/1/user/-/activities/apiSubscriptions/{sub_id}.json",
            headers={"Authorization": f"Bearer {account.access_token}"},
            timeout=15.0,
        )
        if resp.status_code in (200, 201):
            return sub_id
        if resp.status_code == 401:
            raise ReauthRequiredError("Fitbit token rejected during webhook subscribe")
        logger.warning(f"[fitbit] subscription failed: {resp.status_code}")
        return None

    def unregister_webhook(self, account: SyncAccount) -> None:
        if not account.webhook_id:
            return
        httpx.delete(
            f"{FITBIT_API_BASE}/1/user/-/activities/apiSubscriptions/{account.webhook_id}.json",
            headers={"Authorization": f"Bearer {account.access_token}"},
            timeout=15.0,
        )

    @staticmethod
    def verify_webhook_signature(body: bytes, signature: Optional[str]) -> bool:
        """Fitbit ``X-Fitbit-Signature`` = base64(HMAC-SHA1(client_secret + '&', body))."""
        if not signature:
            return False
        secret = os.environ.get("FITBIT_CLIENT_SECRET", "") + "&"
        mac = hmac.new(secret.encode(), body, hashlib.sha1).digest()
        expected = base64.b64encode(mac).decode()
        return hmac.compare_digest(expected, signature)

    # ───────────────────────── Private ─────────────────────────

    @staticmethod
    def _client_id() -> str:
        v = os.environ.get("FITBIT_CLIENT_ID")
        if not v:
            raise SyncProviderError("FITBIT_CLIENT_ID not configured")
        return v

    @staticmethod
    def _client_secret() -> str:
        v = os.environ.get("FITBIT_CLIENT_SECRET")
        if not v:
            raise SyncProviderError("FITBIT_CLIENT_SECRET not configured")
        return v

    @staticmethod
    def _redirect_uri() -> str:
        base = os.environ.get("BACKEND_BASE_URL") or "https://aifitnesscoach-zqi3.onrender.com"
        return f"{base.rstrip('/')}/api/v1/sync/oauth/fitbit/callback"

    @staticmethod
    def _pack_state(user_id: str, verifier: str) -> str:
        # Symmetric HMAC — we never hand the verifier to the client. Encode
        # verifier inside the signed blob so we can recover it at callback.
        # NOTE: using OAUTH_TOKEN_ENCRYPTION_KEY so callback can unpack even
        # across restarts — no shared Redis needed for the state cache.
        from services.sync.token_encryption import encrypt_token
        return encrypt_token(f"{user_id}|{verifier}") or ""

    @staticmethod
    def _unpack_state(state: str) -> tuple[str, str]:
        from services.sync.token_encryption import decrypt_token
        plain = decrypt_token(state) or ""
        if "|" not in plain:
            raise SyncProviderError("Invalid Fitbit OAuth state")
        user_id, verifier = plain.split("|", 1)
        return user_id, verifier


# ─────────────────────────── Helpers ───────────────────────────

def _quote(v: str) -> str:
    from urllib.parse import quote
    return quote(str(v), safe="")


def _expires_at(expires_in: Optional[int]) -> Optional[datetime]:
    if expires_in is None:
        return None
    try:
        return datetime.now(timezone.utc) + timedelta(seconds=int(expires_in))
    except (TypeError, ValueError):
        return None


def _raise_for_status(resp: httpx.Response) -> Any:
    if resp.status_code == 429:
        raise ProviderRateLimitedError()
    if resp.status_code == 401:
        raise ReauthRequiredError("Fitbit token rejected")
    if resp.status_code >= 400:
        raise SyncProviderError(
            f"Fitbit API {resp.status_code}", retriable=(resp.status_code >= 500)
        )
    try:
        return resp.json()
    except Exception:
        raise SyncProviderError("Fitbit returned non-JSON response")


def _fitbit_activity_to_cardio(
    activity: Dict[str, Any],
    *,
    user_id: UUID,
    sync_account_id: UUID,
) -> Optional[CanonicalCardioRow]:
    name = activity.get("activityName") or activity.get("name") or "Workout"
    mapped = _FITBIT_ACTIVITY_MAP.get(name, "other")
    if mapped is None:
        return None
    started = _parse_fitbit_datetime(activity.get("startTime"))
    if started is None:
        return None
    duration_ms = activity.get("duration") or 0
    duration = int(int(duration_ms) / 1000) if duration_ms else int(activity.get("activeDuration", 0) / 1000)
    if duration <= 0:
        return None
    distance_m = None
    if activity.get("distance") is not None:
        # Fitbit returns distance in km by default.
        try:
            distance_m = float(activity["distance"]) * 1000.0
        except (TypeError, ValueError):
            distance_m = None

    external_id = str(activity.get("logId") or "") or None
    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="fitbit",
        performed_at=started,
        activity_type=mapped,
        duration_seconds=duration,
        distance_m=distance_m,
    )

    return CanonicalCardioRow(
        user_id=user_id,
        performed_at=started,
        activity_type=mapped,
        duration_seconds=duration,
        distance_m=distance_m,
        avg_heart_rate=_maybe_int(activity.get("averageHeartRate")),
        max_heart_rate=_maybe_int(activity.get("maxHeartRate")),
        calories=_maybe_int(activity.get("calories")),
        notes=name,
        source_app="fitbit",
        source_external_id=external_id,
        source_row_hash=row_hash,
        sync_account_id=sync_account_id,
    )


def _parse_fitbit_datetime(raw: Optional[str]) -> Optional[datetime]:
    if not raw:
        return None
    s = str(raw)
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    # Fitbit returns times without tz by default — assume user local, coerce to UTC
    # conservatively. If there's no tz, assume UTC.
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _maybe_int(v: Any) -> Optional[int]:
    if v is None:
        return None
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None
