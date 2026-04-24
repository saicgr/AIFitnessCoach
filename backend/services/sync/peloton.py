"""
Peloton provider.

Peloton has no public OAuth API. Two working integration patterns exist:

1. **Cookie-auth + unofficial GraphQL** — hit ``https://api.onepeloton.com`` with
   the session cookie a browser gets after logging in. The endpoints are
   technically internal and unversioned, but community integrations (e.g.
   ``pylotoncycle``) have used them reliably for years.
2. **File upload fallback** — the user downloads their workout history CSV
   from ``members.onepeloton.com`` and imports it through the workout-import
   file path. This is already handled by ``services.workout_import``; the
   sync provider here simply advertises it as an option for users who don't
   want to share credentials.

This module implements path (1) and documents (2) as the recommended
fallback in the docstring.
"""
from __future__ import annotations

import logging
import os
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

import httpx

from services.sync.oauth_base import (
    ReauthRequiredError,
    SyncAccount,
    SyncProvider,
    SyncProviderError,
    TokenBundle,
    register_provider,
)
from services.workout_import.canonical import CanonicalCardioRow

logger = logging.getLogger(__name__)

PELOTON_API = "https://api.onepeloton.com"


_PELOTON_FITNESS_MAP: Dict[str, Optional[str]] = {
    "cycling": "indoor_cycle",
    "running": "run",
    "walking": "hike",
    "strength": None,             # Strength classes have no per-set data
    "yoga": "yoga",
    "stretching": None,
    "meditation": None,
    "cardio": "other",
    "bootcamp": "other",
    "rowing": "row",
}


@register_provider("peloton")
class PelotonProvider(SyncProvider):
    """Pull-only. Cookie-auth via the member login endpoint.

    Flow:
    1. ``begin_auth`` returns a native-form URL.
    2. ``exchange_code`` receives ``email\\tpassword`` as the "code", posts
       against ``/auth/login``, captures the session cookie, persists it as
       the access_token.
    3. ``fetch_since`` re-uses the cookie to list workouts.
    """

    supports_webhooks = False
    supports_strength = False
    default_lookback_days = 90

    def begin_auth(self, user_id: UUID) -> str:
        base = os.environ.get("BACKEND_BASE_URL") or "https://aifitnesscoach-zqi3.onrender.com"
        return f"{base.rstrip('/')}/connect/peloton?user_id={user_id}"

    def exchange_code(self, code: str, state: str) -> TokenBundle:
        # Either we receive a username/password pair from the Flutter form, or
        # we fall back to a service-account if the user opted into it during
        # beta. Service-account creds are **per-app**, not per-user.
        email, password = _extract_credentials(code)
        session = httpx.post(
            f"{PELOTON_API}/auth/login",
            json={"username_or_email": email, "password": password},
            timeout=15.0,
        )
        if session.status_code in (401, 403):
            raise ReauthRequiredError("Peloton login rejected")
        if session.status_code >= 400:
            raise SyncProviderError(f"Peloton login {session.status_code}")
        data = session.json()
        user_id_peloton = str(data.get("user_id") or "")
        session_id = session.cookies.get("peloton_session_id") or ""
        if not session_id:
            raise SyncProviderError("Peloton login succeeded but returned no session cookie")
        # We treat the cookie as the "access token". Refresh is N/A — just
        # require reconnect when it expires.
        return TokenBundle(
            access_token=session_id,
            refresh_token=None,
            expires_at=datetime.now(timezone.utc) + timedelta(days=14),
            scopes=["workouts:read"],
            provider_user_id=user_id_peloton,
        )

    def refresh_token(self, account: SyncAccount) -> TokenBundle:
        raise ReauthRequiredError("Peloton sessions can't be refreshed; reconnect")

    def fetch_since(self, account: SyncAccount, since: datetime) -> List[CanonicalCardioRow]:
        cookies = {"peloton_session_id": account.access_token}
        user_id_peloton = account.provider_user_id
        if not user_id_peloton:
            raise SyncProviderError("No Peloton user_id on account")

        url = f"{PELOTON_API}/api/user/{user_id_peloton}/workouts"
        params = {"limit": 100, "page": 0, "joins": "ride"}
        rows: List[CanonicalCardioRow] = []
        for _ in range(10):
            resp = httpx.get(url, params=params, cookies=cookies, timeout=30.0)
            if resp.status_code in (401, 403):
                raise ReauthRequiredError("Peloton cookie rejected; reconnect required")
            if resp.status_code >= 400:
                raise SyncProviderError(f"Peloton fetch {resp.status_code}")
            payload = resp.json() or {}
            workouts = payload.get("data") or []
            if not workouts:
                break
            for workout in workouts:
                row = _peloton_workout_to_cardio(
                    workout, user_id=account.user_id, sync_account_id=account.id
                )
                if row and row.performed_at >= since:
                    rows.append(row)
            # Pagination.
            show_next = payload.get("show_next")
            total_pages = payload.get("page_count") or 1
            if not show_next or params["page"] + 1 >= total_pages:
                break
            params["page"] += 1
        logger.info(
            f"🚲 [peloton] fetched {len(rows)} workouts for user={account.user_id}"
        )
        return rows


# ─────────────────────────── Helpers ───────────────────────────

def _extract_credentials(code: str) -> tuple[str, str]:
    # Preferred: "email\tpassword" pair from the Flutter form.
    if "\t" in code:
        email, password = code.split("\t", 1)
        return email.strip(), password.strip()
    # Fallback: service-account from env (beta-only).
    email = os.environ.get("PELOTON_EMAIL")
    password = os.environ.get("PELOTON_PASSWORD")
    if email and password:
        return email, password
    raise SyncProviderError(
        "Peloton credentials not provided and no service-account configured"
    )


def _peloton_workout_to_cardio(
    workout: Dict[str, Any],
    *,
    user_id: UUID,
    sync_account_id: UUID,
) -> Optional[CanonicalCardioRow]:
    fitness = str(workout.get("fitness_discipline") or "").lower()
    mapped = _PELOTON_FITNESS_MAP.get(fitness, "other" if fitness else None)
    if mapped is None:
        return None
    started_ts = workout.get("start_time")
    if not started_ts:
        return None
    try:
        started = datetime.fromtimestamp(int(started_ts), tz=timezone.utc)
    except (TypeError, ValueError):
        return None
    duration = int(workout.get("end_time", 0) or 0) - int(started_ts)
    if duration <= 0:
        duration = int((workout.get("ride") or {}).get("duration") or 0)
    if duration <= 0:
        return None

    distance_km = (
        (workout.get("overall_summary") or {}).get("distance")
        or (workout.get("ride") or {}).get("distance")
    )
    distance_m = None
    if distance_km is not None:
        try:
            distance_m = float(distance_km) * 1000.0
        except (TypeError, ValueError):
            distance_m = None

    external_id = str(workout.get("id") or "") or None
    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="peloton",
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
        avg_heart_rate=_maybe_int((workout.get("overall_summary") or {}).get("avg_heart_rate")),
        max_heart_rate=_maybe_int((workout.get("overall_summary") or {}).get("max_heart_rate")),
        avg_watts=_maybe_int((workout.get("overall_summary") or {}).get("avg_power")),
        max_watts=_maybe_int((workout.get("overall_summary") or {}).get("max_power")),
        calories=_maybe_int((workout.get("overall_summary") or {}).get("calories")),
        notes=((workout.get("ride") or {}).get("title")),
        source_app="peloton",
        source_external_id=external_id,
        source_row_hash=row_hash,
        sync_account_id=sync_account_id,
    )


def _maybe_int(v: Any) -> Optional[int]:
    if v is None:
        return None
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None
