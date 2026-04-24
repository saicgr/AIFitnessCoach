"""
Fitbit Takeout JSON adapter.

Fitbit GDPR Takeout ships `exercise-YYYY-MM-DD.json` files with a top-level
JSON array where each element is an activity dict:

    {
      "logId": 123456789,
      "activityName": "Run",
      "activityTypeId": 90013,
      "averageHeartRate": 148,
      "calories": 412,
      "duration": 1825000,              # milliseconds
      "steps": 5322,
      "startTime": "03/28/25 17:29:00",
      "distance": 5.2,
      "distanceUnit": "Kilometer",
      ...
    }

The adapter also accepts single-dict payloads (some scrapers flatten) and
newline-delimited JSON (ndjson). Timestamps are in user-local time with a
format like "MM/DD/YY HH:MM:SS" — we interpret them in `tz_hint`.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID
from zoneinfo import ZoneInfo

from ..canonical import CanonicalCardioRow, ImportMode, ParseResult
from ._cardio_common import (
    STRENGTH_ACTIVITY_KEYWORDS,
    derive_pace_and_speed,
    ensure_tz_aware,
    km_to_meters,
    miles_to_meters,
    normalize_activity_type,
    safe_float,
    safe_int,
)


_FITBIT_DATETIME_FORMATS = (
    "%m/%d/%y %H:%M:%S",       # "03/28/25 17:29:00"
    "%Y-%m-%dT%H:%M:%S.%f",    # "2025-03-28T17:29:00.000"
    "%Y-%m-%dT%H:%M:%S",       # newer variants
    "%Y-%m-%d %H:%M:%S",
)


def _parse_start_time(raw: str, tz_hint: str) -> Optional[datetime]:
    if not raw:
        return None
    s = str(raw).strip()
    # ISO with Z
    try:
        if s.endswith("Z"):
            return datetime.fromisoformat(s[:-1] + "+00:00")
        dt = datetime.fromisoformat(s)
        if dt.tzinfo is not None:
            return dt
    except ValueError:
        pass
    for fmt in _FITBIT_DATETIME_FORMATS:
        try:
            dt = datetime.strptime(s, fmt)
            # Fitbit's naive timestamps are user-local; tz_hint is the user's
            # profile timezone captured at import time. Falls back to UTC.
            try:
                return dt.replace(tzinfo=ZoneInfo(tz_hint)) if tz_hint else dt.replace(tzinfo=timezone.utc)
            except Exception:
                return dt.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def _activity_to_row(activity: dict[str, Any], user_id: UUID, tz_hint: str) -> Optional[CanonicalCardioRow]:
    name = activity.get("activityName") or activity.get("activity_name") or ""
    if not name:
        return None
    # Normalize "Weight Training" → "weight_training" so the keyword set
    # (underscore + compact forms) catches it regardless of separator.
    _norm_name = name.lower().replace(" ", "_").replace("-", "_")
    if any(kw in _norm_name for kw in STRENGTH_ACTIVITY_KEYWORDS):
        # Fitbit strength activities don't carry per-set data; the strength
        # pipeline handles those via a separate path. Here we just skip.
        return None
    activity_type = normalize_activity_type(name) or "other"

    performed_at = _parse_start_time(activity.get("startTime") or activity.get("start_time") or "", tz_hint)
    if performed_at is None:
        return None

    # Fitbit duration is milliseconds — convert to seconds.
    duration_ms = safe_int(activity.get("duration"))
    duration_seconds = int(round(duration_ms / 1000)) if duration_ms and duration_ms > 0 else None
    if not duration_seconds:
        # Some trackers emit `activeDuration` alongside duration (duration
        # includes paused time). Fall back to whichever is present.
        active_ms = safe_int(activity.get("activeDuration"))
        duration_seconds = int(round(active_ms / 1000)) if active_ms and active_ms > 0 else None
    if not duration_seconds:
        return None

    distance = safe_float(activity.get("distance"))
    unit = (activity.get("distanceUnit") or "").lower()
    if distance is not None and distance > 0:
        # Order matters: "kilometer" contains "meter", so check km first.
        if "kilomet" in unit or unit == "km":
            distance_m = km_to_meters(distance)
        elif "mile" in unit or unit == "mi":
            distance_m = miles_to_meters(distance)
        elif unit in ("m", "meter", "meters"):
            distance_m = distance
        else:
            # Default Fitbit distance unit is km regardless of locale display.
            distance_m = km_to_meters(distance)
    else:
        distance_m = None

    avg_hr = safe_int(activity.get("averageHeartRate"))
    calories = safe_int(activity.get("calories"))
    elevation = safe_float(activity.get("elevationGain"))
    avg_pace, avg_speed = derive_pace_and_speed(duration_seconds, distance_m)

    external_id = activity.get("logId") or activity.get("log_id") or None

    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="fitbit",
        performed_at=performed_at,
        activity_type=activity_type,
        duration_seconds=duration_seconds,
        distance_m=distance_m,
    )

    return CanonicalCardioRow(
        user_id=user_id,
        performed_at=performed_at,
        activity_type=activity_type,
        duration_seconds=duration_seconds,
        distance_m=round(distance_m, 2) if distance_m else None,
        elevation_gain_m=elevation,
        avg_heart_rate=avg_hr,
        calories=calories,
        avg_pace_seconds_per_km=avg_pace,
        avg_speed_mps=avg_speed,
        source_app="fitbit",
        source_external_id=str(external_id) if external_id else None,
        source_row_hash=row_hash,
    )


def _iter_activities(payload: Any):
    """Yield activity dicts from whatever Fitbit gave us: array / single
    object / ndjson. Nested fields like `activities` at the root are
    unwrapped once (Fitbit sometimes wraps the list under that key)."""
    if isinstance(payload, list):
        yield from payload
    elif isinstance(payload, dict):
        if "activities" in payload and isinstance(payload["activities"], list):
            yield from payload["activities"]
        else:
            yield payload


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: ImportMode,
) -> ParseResult:
    warnings: list[str] = []
    text = data.decode("utf-8-sig", errors="replace").strip()

    activities: list[dict[str, Any]] = []
    try:
        payload = json.loads(text)
        activities = list(_iter_activities(payload))
    except json.JSONDecodeError:
        # Try newline-delimited JSON.
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                activities.append(json.loads(line))
            except json.JSONDecodeError as e:
                warnings.append(f"Skipped malformed Fitbit line: {e}")

    cardio_rows: list[CanonicalCardioRow] = []
    for activity in activities:
        try:
            row = _activity_to_row(activity, user_id, tz_hint)
            if row is not None:
                cardio_rows.append(row)
        except Exception as e:
            warnings.append(f"Skipped Fitbit activity ({activity.get('activityName')}): {e}")

    return ParseResult(
        mode=ImportMode.CARDIO_ONLY,
        source_app="fitbit",
        cardio_rows=cardio_rows,
        warnings=warnings,
    )
