"""
Garmin Connect provider.

**Caveat (read me first)**: Garmin's first-class, commercial OAuth-backed
Health / Activity APIs are part of the *Garmin Health API* program, which is
enterprise-only (application + business review + dev-kit contract). The
consumer-grade integration we rely on here is the ``garminconnect`` Python
package, which authenticates against the same *Garmin Connect web app*
endpoints a browser uses — essentially a scraper. Garmin does not guarantee
stability of those endpoints; they may change without notice. Consequently:

1. This integration is disclosed to the user in ``connected_apps_screen.dart``
   as "personal use, may break if Garmin changes their internal API".
2. We never call the scraper more than once every 15 minutes per account.
3. If login flips to MFA, this provider throws :class:`ReauthRequiredError`
   and the user sees a "Reconnect" CTA.

For users who want industrial-strength sync we recommend connecting Strava
(which Garmin auto-mirrors to) instead.
"""
from __future__ import annotations

import logging
import os
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

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


_GARMIN_ACTIVITY_TYPE_MAP: Dict[str, Optional[str]] = {
    "running": "run",
    "trail_running": "run",
    "treadmill_running": "run",
    "indoor_running": "run",
    "walking": "hike",
    "hiking": "hike",
    "cycling": "cycle",
    "mountain_biking": "cycle",
    "gravel_cycling": "cycle",
    "road_biking": "cycle",
    "indoor_cycling": "indoor_cycle",
    "cyclocross": "cycle",
    "swimming": "swim",
    "open_water_swimming": "swim",
    "lap_swimming": "swim",
    "rowing": "row",
    "indoor_rowing": "row",
    "strength_training": None,   # Garmin strength is set-level but not reps/weight-grade
    "yoga": "yoga",
    "elliptical": "elliptical",
    "stair_climbing": "stair_stepper",
}


@register_provider("garmin")
class GarminProvider(SyncProvider):
    """Pull-only provider. No push; orchestrator polls every 15 min.

    Tokens here are a serialized session cookie blob from ``garminconnect``
    (email + password is swapped for a session at connect time; the session
    is then persisted as the "access_token" string — there's no OAuth2 leg).
    """

    supports_webhooks = False
    supports_strength = False
    default_lookback_days = 90

    # ─────────────────────────── OAuth ───────────────────────────

    def begin_auth(self, user_id: UUID) -> str:
        """Garmin has no OAuth redirect — the "auth" is the user typing their
        Garmin Connect email + password into a native screen on the device.

        The Flutter side collects credentials and POSTs them to
        ``/sync/oauth/garmin/callback`` with body ``{email, password}`` instead
        of the OAuth ``code`` flow. We return the well-known URL the client
        will hit for that native form so the same "connect" handler path works
        across providers; actual UI is built in ``connected_apps_screen.dart``.
        """
        base = os.environ.get("BACKEND_BASE_URL") or "https://aifitnesscoach-zqi3.onrender.com"
        return f"{base.rstrip('/')}/connect/garmin?user_id={user_id}"

    def exchange_code(self, code: str, state: str) -> TokenBundle:
        """Here ``code`` is actually ``"{email}\\t{password}"`` posted from the
        native form. Not elegant — but Garmin simply doesn't do OAuth for
        consumer apps.
        """
        try:
            email, password = code.split("\t", 1)
        except ValueError:
            raise SyncProviderError("Garmin auth payload malformed")
        try:
            from garminconnect import Garmin  # heavy import — lazy
        except ImportError as e:
            raise SyncProviderError(f"garminconnect not installed: {e}")

        try:
            client = Garmin(email, password)
            client.login()
        except Exception as e:
            # garminconnect raises its own error types, which often include the
            # password in their repr. Normalize to a clean message.
            msg = type(e).__name__
            if "MFA" in str(e) or "two" in str(e).lower():
                raise ReauthRequiredError(
                    "Garmin requires MFA — enable an app-specific password or use Strava instead"
                )
            raise SyncProviderError(f"Garmin login failed ({msg})")

        # Serialize the session so the cron can resume without re-logging in.
        session_blob = _serialize_garmin_session(client)
        profile = {}
        try:
            profile = client.get_user_profile() or {}
        except Exception:
            pass
        provider_user_id = str(profile.get("id") or profile.get("displayName") or email)

        return TokenBundle(
            access_token=session_blob,
            refresh_token=None,
            expires_at=datetime.now(timezone.utc) + timedelta(days=30),
            scopes=["activity:read"],
            provider_user_id=provider_user_id,
        )

    def refresh_token(self, account: SyncAccount) -> TokenBundle:
        """Garmin sessions can't be refreshed — we must fall back to the saved
        credentials (not stored) or ask the user to reconnect. Reconnect wins.
        """
        raise ReauthRequiredError("Garmin session expired; reconnect required")

    # ───────────────────────── Data pull ─────────────────────────

    def fetch_since(self, account: SyncAccount, since: datetime) -> List[CanonicalCardioRow]:
        try:
            from garminconnect import Garmin
        except ImportError as e:
            raise SyncProviderError(f"garminconnect not installed: {e}")

        client = _restore_garmin_session(account.access_token)
        if client is None:
            raise ReauthRequiredError("Garmin session blob invalid; reconnect required")

        # Garmin's get_activities_by_date takes date-strings in the user's
        # local calendar; safer to lean on ``get_activities`` and filter
        # client-side.
        try:
            raw = client.get_activities(0, 200) or []
        except Exception as e:
            if "401" in str(e) or "login" in str(e).lower():
                raise ReauthRequiredError("Garmin session rejected")
            raise SyncProviderError(f"Garmin fetch failed: {type(e).__name__}")

        rows: List[CanonicalCardioRow] = []
        for activity in raw:
            started = _parse_garmin_start(activity)
            if started is None or started < since:
                continue
            row = _garmin_activity_to_cardio(
                activity, user_id=account.user_id, sync_account_id=account.id, started=started
            )
            if row:
                rows.append(row)
        logger.info(
            f"⌚ [garmin] fetched {len(rows)} activities for user={account.user_id} since={since.isoformat()}"
        )
        return rows


# ─────────────────────────── Helpers ───────────────────────────

def _serialize_garmin_session(client: Any) -> str:
    """Dump the garminconnect session cookies to a newline-joined string.

    We pick a simple format over pickle so a version bump to garminconnect
    doesn't brick existing sessions on an import-time depickle failure.
    """
    try:
        # garminconnect exposes .session on newer versions.
        session = getattr(client, "session", None) or getattr(client, "_client", None)
        if session is None:
            return "EMPTY"
        cookies = session.cookies.get_dict() if hasattr(session, "cookies") else {}
        return "\n".join(f"{k}={v}" for k, v in cookies.items())
    except Exception:
        return "EMPTY"


def _restore_garmin_session(blob: str) -> Optional[Any]:
    try:
        from garminconnect import Garmin
    except ImportError:
        return None
    if not blob or blob == "EMPTY":
        return None
    try:
        client = Garmin("", "")      # placeholder — we'll inject cookies below
        session = getattr(client, "session", None) or getattr(client, "_client", None)
        if session is None:
            return None
        for line in blob.splitlines():
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            session.cookies.set(k, v)
        return client
    except Exception:
        return None


def _parse_garmin_start(activity: Dict[str, Any]) -> Optional[datetime]:
    raw = activity.get("startTimeGMT") or activity.get("startTimeLocal")
    if not raw:
        return None
    # Garmin serializes "2024-03-18 14:22:10".
    s = str(raw).replace(" ", "T")
    if "+" not in s and not s.endswith("Z"):
        s = s + "+00:00"
    elif s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(s).astimezone(timezone.utc)
    except ValueError:
        return None


def _garmin_activity_to_cardio(
    activity: Dict[str, Any],
    *,
    user_id: UUID,
    sync_account_id: UUID,
    started: datetime,
) -> Optional[CanonicalCardioRow]:
    act_type = ((activity.get("activityType") or {}).get("typeKey") or "").lower()
    mapped = _GARMIN_ACTIVITY_TYPE_MAP.get(act_type, "other" if act_type else None)
    if mapped is None:
        return None
    duration = int(activity.get("duration") or 0)
    if duration <= 0:
        return None
    distance_m = _maybe_float(activity.get("distance"))
    external_id = str(activity.get("activityId") or "") or None

    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="garmin",
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
        elevation_gain_m=_maybe_float(activity.get("elevationGain")),
        avg_heart_rate=_maybe_int(activity.get("averageHR")),
        max_heart_rate=_maybe_int(activity.get("maxHR")),
        avg_speed_mps=_maybe_float(activity.get("averageSpeed")),
        avg_watts=_maybe_int(activity.get("avgPower")),
        max_watts=_maybe_int(activity.get("maxPower")),
        avg_cadence=_maybe_int(activity.get("averageRunningCadenceInStepsPerMinute")),
        avg_stroke_rate=_maybe_int(activity.get("averageStrokeCadence")),
        calories=_maybe_int(activity.get("calories")),
        training_effect=_maybe_float(activity.get("aerobicTrainingEffect")),
        vo2max_estimate=_maybe_float(activity.get("vO2MaxValue")),
        notes=activity.get("activityName"),
        source_app="garmin",
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


def _maybe_float(v: Any) -> Optional[float]:
    if v is None:
        return None
    try:
        return float(v)
    except (TypeError, ValueError):
        return None
