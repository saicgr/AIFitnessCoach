"""
Shared helpers for cardio adapters.

Every cardio adapter deals with the same handful of concerns:
  - Activity-type mapping (`Ride` → `cycle`, `Run` → `run`, etc.)
  - Timezone-aware datetime parsing from provider-specific formats
  - Distance unit conversion (miles / km / meters)
  - Pace / speed derivation when one is present but not the other

Keeping this in one place means an activity-type taxonomy fix lands
everywhere at once instead of drifting between Strava and Garmin code.
"""
from __future__ import annotations

import re
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from zoneinfo import ZoneInfo

from ..canonical import KM_TO_M, MILE_TO_M


# The full set of activity_type values allowed by the DB CHECK constraint.
# Kept in sync with migrations/1965_create_cardio_logs.sql.
ALLOWED_ACTIVITY_TYPES = {
    "run", "trail_run", "treadmill", "walk", "hike",
    "cycle", "indoor_cycle", "mountain_bike", "gravel_bike",
    "row", "erg",
    "swim", "open_water_swim",
    "elliptical", "stair", "stepmill",
    "ski_erg", "skate_ski", "nordic_ski", "downhill_ski", "snowboard",
    "yoga", "pilates",
    "hiit", "boxing", "kickboxing",
    "other",
}


# Strength activity types — adapters that may emit both (Garmin FIT, Apple
# Health) route these to strength_rows instead of cardio_rows. Keep these
# phrases tight: bare "training" is too broad (matches "HighIntensity-
# IntervalTraining" / "CircuitTraining", which are cardio). Every keyword
# must contain a strength-specific qualifier.
STRENGTH_ACTIVITY_KEYWORDS = {
    "strength_training",
    "strengthtraining",
    "weighttraining",
    "weight_training",
    "weightlifting",
    "weight_lifting",
    "resistance_training",
    "functional_strength",
    "traditional_strength",
    "powerlifting",
    "olympic_weightlifting",
}


# Mapping from many provider dialects → our enum.
# Keys are lowercased / normalized at call time.
_ACTIVITY_MAP: dict[str, str] = {
    # Running / walking
    "run": "run",
    "running": "run",
    "virtualrun": "treadmill",
    "virtual_run": "treadmill",
    "treadmill": "treadmill",
    "treadmill_running": "treadmill",
    "trail": "trail_run",
    "trail_run": "trail_run",
    "trailrun": "trail_run",
    "trail running": "trail_run",
    "walk": "walk",
    "walking": "walk",
    "hike": "hike",
    "hiking": "hike",
    # Cycling
    "ride": "cycle",
    "cycle": "cycle",
    "cycling": "cycle",
    "biking": "cycle",
    "bike": "cycle",
    "road_biking": "cycle",
    "road biking": "cycle",
    "ebikeride": "cycle",
    "e-bike": "cycle",
    "virtualride": "indoor_cycle",
    "virtual_ride": "indoor_cycle",
    "indoor_cycling": "indoor_cycle",
    "indoorcycling": "indoor_cycle",
    "spinning": "indoor_cycle",
    "peloton": "indoor_cycle",  # Peloton CSV fallback
    "mountainbikeride": "mountain_bike",
    "mountain_biking": "mountain_bike",
    "mountain bike": "mountain_bike",
    "mtb": "mountain_bike",
    "gravelride": "gravel_bike",
    "gravel": "gravel_bike",
    # Rowing
    "rowing": "row",
    "row": "row",
    "indoor_rowing": "erg",
    "indoorrowing": "erg",
    "erg": "erg",
    # Swimming
    "swim": "swim",
    "swimming": "swim",
    "pool_swimming": "swim",
    "pool swim": "swim",
    "openwaterswim": "open_water_swim",
    "open_water_swim": "open_water_swim",
    "open_water_swimming": "open_water_swim",
    # Machines
    "elliptical": "elliptical",
    "stairclimber": "stair",
    "stair_climbing": "stair",
    "stair climbing": "stair",
    "stepper": "stair",
    "stepmill": "stepmill",
    # Ski
    "ski_erg": "ski_erg",
    "skierg": "ski_erg",
    "cross_country_skiing": "nordic_ski",
    "cross country skiing": "nordic_ski",
    "nordicskiing": "nordic_ski",
    "alpine_skiing": "downhill_ski",
    "downhill_skiing": "downhill_ski",
    "snowboard": "snowboard",
    "snowboarding": "snowboard",
    # Misc
    "yoga": "yoga",
    "pilates": "pilates",
    "hiit": "hiit",
    "boxing": "boxing",
    "kickboxing": "kickboxing",
}


def normalize_activity_type(raw: Optional[str]) -> Optional[str]:
    """Map a provider's raw activity label → our enum. Returns None for
    strength activities (caller should route those to strength_rows) and
    'other' for anything unrecognized but clearly cardio-shaped."""
    if raw is None:
        return None
    s = str(raw).strip().lower()
    if not s:
        return None
    # Normalize separators: "Trail Run" / "trail-run" / "TRAIL_RUN" → "trail_run"
    key = re.sub(r"[\s\-]+", "_", s)

    # Route strength to the strength path, not cardio.
    for kw in STRENGTH_ACTIVITY_KEYWORDS:
        if kw in key:
            return None

    if key in _ACTIVITY_MAP:
        return _ACTIVITY_MAP[key]
    # Try again without underscores to catch "virtualride" vs "virtual_ride".
    compact = key.replace("_", "")
    if compact in _ACTIVITY_MAP:
        return _ACTIVITY_MAP[compact]
    # If we got here, it's cardio-shaped but unfamiliar — "other" keeps the row.
    return "other"


def ensure_tz_aware(dt: datetime, tz_hint: Optional[str] = None) -> datetime:
    """Attach a timezone if missing. Falls back to tz_hint, then UTC.

    This is the single place the pipeline tolerates naive datetimes — any
    adapter calling CanonicalCardioRow(performed_at=...) with a naive value
    would fail the field_validator. Funneling conversions here gives us a
    single audit point.
    """
    if dt.tzinfo is not None:
        return dt
    if tz_hint:
        try:
            return dt.replace(tzinfo=ZoneInfo(tz_hint))
        except Exception:
            pass
    return dt.replace(tzinfo=timezone.utc)


def parse_duration_string(raw: Any) -> Optional[int]:
    """Parse "1h 12m", "72:15", "4:23:11", "523 sec", "1:12:45.3" → seconds.

    Handles Strong's `"1h 12m"`, Peloton's `"45:00"`, Apple Health's
    `<Workout duration="72.5">` (minutes!), and bare numeric strings.
    """
    if raw is None:
        return None
    if isinstance(raw, (int, float)):
        # Heuristic: if > 24h, caller passed seconds already; otherwise we
        # don't know. Prefer seconds-interpretation for large values.
        v = float(raw)
        if v <= 0:
            return None
        # Assume seconds. Caller converts minutes → seconds before calling
        # if they know otherwise.
        return int(round(v))

    s = str(raw).strip().lower()
    if not s:
        return None

    # "1h 12m 30s" / "1h12m" / "12m 5s"
    m = re.fullmatch(r"(?:(\d+)\s*h)?\s*(?:(\d+)\s*m)?\s*(?:(\d+(?:\.\d+)?)\s*s)?", s)
    if m and any(m.groups()):
        h = int(m.group(1) or 0)
        mm = int(m.group(2) or 0)
        sec = float(m.group(3) or 0)
        total = h * 3600 + mm * 60 + sec
        if total > 0:
            return int(round(total))

    # "HH:MM:SS" / "MM:SS" / "HH:MM:SS.f"
    parts = s.split(":")
    if 2 <= len(parts) <= 3 and all(re.match(r"^\d+(\.\d+)?$", p) for p in parts):
        if len(parts) == 3:
            h, mm, sec = float(parts[0]), float(parts[1]), float(parts[2])
        else:
            h, mm, sec = 0.0, float(parts[0]), float(parts[1])
        total = h * 3600 + mm * 60 + sec
        if total > 0:
            return int(round(total))

    # Bare number (assumed seconds).
    try:
        v = float(s)
        return int(round(v)) if v > 0 else None
    except ValueError:
        return None


def miles_to_meters(miles: Optional[float]) -> Optional[float]:
    if miles is None:
        return None
    return float(float(miles) * float(MILE_TO_M))


def km_to_meters(km: Optional[float]) -> Optional[float]:
    if km is None:
        return None
    return float(float(km) * float(KM_TO_M))


def pace_seconds_per_km(duration_seconds: Optional[int], distance_m: Optional[float]) -> Optional[float]:
    """Derive avg pace (sec/km) when both duration + distance are present."""
    if not duration_seconds or not distance_m or distance_m <= 0:
        return None
    km = distance_m / 1000.0
    if km <= 0:
        return None
    return round(duration_seconds / km, 2)


def speed_mps(duration_seconds: Optional[int], distance_m: Optional[float]) -> Optional[float]:
    if not duration_seconds or not distance_m or distance_m <= 0:
        return None
    return round(distance_m / duration_seconds, 3)


def derive_pace_and_speed(duration_seconds: Optional[int], distance_m: Optional[float]):
    """Return (avg_pace_seconds_per_km, avg_speed_mps) from duration + distance."""
    return pace_seconds_per_km(duration_seconds, distance_m), speed_mps(duration_seconds, distance_m)


def safe_int(v: Any) -> Optional[int]:
    if v is None or v == "" or v == "nan":
        return None
    try:
        f = float(v)
        # Providers sometimes emit NaN as text or as a numeric — both should
        # round-trip as None rather than silently persisting as 0.
        if f != f:  # NaN check
            return None
        return int(round(f))
    except (ValueError, TypeError):
        return None


def safe_float(v: Any) -> Optional[float]:
    if v is None or v == "" or v == "nan":
        return None
    try:
        f = float(v)
        if f != f:
            return None
        return f
    except (ValueError, TypeError):
        return None
