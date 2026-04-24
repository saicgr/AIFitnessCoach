"""
Apple Health provider.

There is **no server-side OAuth** for HealthKit. Apple's model is "on-device
only": the iOS ``HKHealthStore`` bridge (exposed to Flutter via the ``health``
package) returns workouts directly to the app, and the app POSTs them to our
``POST /sync/apple-health/push`` endpoint.

So the provider class is intentionally thin:
- ``begin_auth`` returns a dummy URL — the Flutter side bypasses it and just
  calls ``health.requestAuthorization`` directly.
- ``exchange_code`` records a "connected" marker row with no tokens
  (``access_token`` is a literal placeholder string).
- ``fetch_since`` returns an empty list — pull is client-driven.
- ``receive_healthkit_sync`` is the actual work horse invoked by the API
  endpoint; it converts the Flutter payload into canonical cardio + strength
  rows.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Union
from uuid import UUID, uuid4

from services.sync.oauth_base import (
    SyncAccount,
    SyncProvider,
    TokenBundle,
    register_provider,
)
from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
    WeightUnit,
)

logger = logging.getLogger(__name__)


# HealthKit's ``HKWorkoutActivityType`` raw name → our cardio enum.
_HEALTHKIT_WORKOUT_MAP: Dict[str, Optional[str]] = {
    "running": "run",
    "hiking": "hike",
    "walking": "hike",
    "cycling": "cycle",
    "indoor_cycling": "indoor_cycle",
    "swimming": "swim",
    "rowing": "row",
    "elliptical": "elliptical",
    "stair_climbing": "stair_stepper",
    "yoga": "yoga",
    "traditional_strength_training": "strength",   # marker; strength rows written separately
    "functional_strength_training": "strength",
    "cross_training": "other",
    "high_intensity_interval_training": "other",
    "mixed_cardio": "other",
}


@register_provider("apple_health")
class AppleHealthProvider(SyncProvider):
    supports_webhooks = False    # HealthKit is push-from-device
    supports_strength = True
    default_lookback_days = 90

    def begin_auth(self, user_id: UUID) -> str:
        # There's no remote consent screen — return the marker URL the client
        # app understands as "handled in-app".
        return f"fitwiz://connect/apple_health?user_id={user_id}"

    def exchange_code(self, code: str, state: str) -> TokenBundle:
        # No tokens exist. We still create a row in ``oauth_sync_accounts`` so
        # the UI can show "Connected" and the user can later disconnect.
        return TokenBundle(
            access_token="APPLE_HEALTHKIT_DEVICE_BRIDGE",
            refresh_token=None,
            expires_at=None,
            scopes=["workouts", "heart_rate"],
            provider_user_id=f"apple:{uuid4().hex}",
        )

    def refresh_token(self, account: SyncAccount) -> TokenBundle:
        # Nothing to refresh; return whatever's there.
        return TokenBundle(
            access_token=account.access_token,
            refresh_token=None,
            expires_at=None,
            scopes=account.scopes,
            provider_user_id=account.provider_user_id,
        )

    def fetch_since(self, account: SyncAccount, since: datetime):
        # Pull is client-driven; nothing to do server-side.
        return []

    # ───────── Called by the HTTP endpoint ─────────

    def receive_healthkit_sync(
        self,
        user_id: UUID,
        activities: List[Dict[str, Any]],
        *,
        sync_account_id: Optional[UUID] = None,
    ) -> Dict[str, List[Union[CanonicalCardioRow, CanonicalSetRow]]]:
        """Convert a batch of HealthKit workouts into canonical rows.

        ``activities`` is the list the Flutter HealthKit bridge posts. Each entry
        looks like::

            {
              "type": "running" | "traditional_strength_training" | ...,
              "start": "2024-03-18T14:22:10.000+00:00",
              "end":   "2024-03-18T15:01:42.000+00:00",
              "duration_seconds": 2372,
              "distance_m": 7340.5,
              "calories": 512,
              "avg_heart_rate": 148,
              "max_heart_rate": 176,
              "exercises": [   # only for strength workouts; optional
                {"name": "Bench Press", "sets": [{"weight_kg": 80, "reps": 8}, ...]},
                ...
              ]
            }

        Returns a dict::

            {"cardio_rows": [...], "strength_rows": [...]}
        """
        cardio_rows: List[CanonicalCardioRow] = []
        strength_rows: List[CanonicalSetRow] = []

        for activity in activities:
            raw_type = str(activity.get("type") or "").lower()
            started = _parse_iso(activity.get("start"))
            ended = _parse_iso(activity.get("end"))
            if started is None:
                continue
            duration = int(activity.get("duration_seconds") or 0)
            if duration <= 0 and ended:
                duration = max(0, int((ended - started).total_seconds()))
            if duration <= 0:
                continue

            # Strength: explode into canonical set rows. If no exercises are
            # attached, fall back to a single cardio "other" row so the session
            # still appears in totals.
            mapped_cardio = _HEALTHKIT_WORKOUT_MAP.get(raw_type, "other")
            exercises = activity.get("exercises") or []
            if raw_type.endswith("strength_training") and exercises:
                for exercise in exercises:
                    name = (exercise.get("name") or "").strip()
                    if not name:
                        continue
                    for idx, set_row in enumerate(exercise.get("sets") or [], start=1):
                        weight_kg = _maybe_float(set_row.get("weight_kg"))
                        reps = _maybe_int(set_row.get("reps"))
                        hash_src = CanonicalSetRow.compute_row_hash(
                            user_id=user_id,
                            source_app="apple_health",
                            performed_at=started,
                            exercise_name_canonical=name,
                            set_number=idx,
                            weight_kg=weight_kg,
                            reps=reps,
                        )
                        strength_rows.append(
                            CanonicalSetRow(
                                user_id=user_id,
                                performed_at=started,
                                workout_name=activity.get("title"),
                                exercise_name_raw=name,
                                exercise_name_canonical=name,
                                set_number=idx,
                                weight_kg=weight_kg,
                                original_weight_value=weight_kg,
                                original_weight_unit=WeightUnit.KG,
                                reps=reps,
                                source_app="apple_health",
                                source_row_hash=hash_src,
                            )
                        )
                continue

            if mapped_cardio is None:
                continue
            # Strength workouts without per-exercise breakdowns would otherwise
            # land here with activity_type='strength', but we deliberately skip
            # them: a featureless strength session carries no useful volume
            # signal for the AI, and logging it as cardio muddies the user's
            # cardio totals.
            if mapped_cardio == "strength":
                continue
            distance_m = _maybe_float(activity.get("distance_m"))
            row_hash = CanonicalCardioRow.compute_row_hash(
                user_id=user_id,
                source_app="apple_health",
                performed_at=started,
                activity_type=mapped_cardio,
                duration_seconds=duration,
                distance_m=distance_m,
            )
            cardio_rows.append(
                CanonicalCardioRow(
                    user_id=user_id,
                    performed_at=started,
                    activity_type=mapped_cardio,
                    duration_seconds=duration,
                    distance_m=distance_m,
                    avg_heart_rate=_maybe_int(activity.get("avg_heart_rate")),
                    max_heart_rate=_maybe_int(activity.get("max_heart_rate")),
                    calories=_maybe_int(activity.get("calories")),
                    notes=activity.get("title"),
                    source_app="apple_health",
                    source_external_id=activity.get("uuid"),
                    source_row_hash=row_hash,
                    sync_account_id=sync_account_id,
                )
            )
        logger.info(
            f"🍎 [apple_health] parsed {len(cardio_rows)} cardio + "
            f"{len(strength_rows)} strength rows for user={user_id}"
        )
        return {"cardio_rows": cardio_rows, "strength_rows": strength_rows}


# ─────────────────────────── Helpers ───────────────────────────

def _parse_iso(raw: Optional[str]) -> Optional[datetime]:
    if not raw:
        return None
    s = str(raw)
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
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


def _maybe_float(v: Any) -> Optional[float]:
    if v is None:
        return None
    try:
        return float(v)
    except (TypeError, ValueError):
        return None
