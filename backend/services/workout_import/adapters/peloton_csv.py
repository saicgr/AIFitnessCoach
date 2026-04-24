"""
Peloton CSV adapter.

Peloton emails a CSV when the user hits Settings → Download Workouts.
Header (circa 2024):
    Workout Timestamp, Live/On-Demand, Instructor Name, Length (minutes),
    Fitness Discipline, Type, Title, Class Timestamp, Total Output,
    Avg. Watts, Avg. Resistance, Avg. Cadence (RPM), Avg. Speed (mph),
    Distance (mi), Calories Burned, Avg. Heartrate, Avg. Incline,
    Avg. Pace (min/mi), Workout ID

Peloton's CSV is rider-centric — distance is in miles, pace is in min/mi.
We convert both to meters + sec/km so downstream code never sees imperial.
"""
from __future__ import annotations

import csv
import io
import re
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID

from ..canonical import CanonicalCardioRow, ImportMode, ParseResult
from ._cardio_common import (
    derive_pace_and_speed,
    ensure_tz_aware,
    miles_to_meters,
    normalize_activity_type,
    parse_duration_string,
    safe_float,
    safe_int,
)


# Fitness Discipline → our enum. Peloton's taxonomy is flat so the mapping
# is small — everything else lands as 'other'.
_DISCIPLINE_MAP = {
    "cycling": "indoor_cycle",
    "running": "run",
    "walking": "walk",
    "strength": None,                # routed via strength pipeline, not here
    "yoga": "yoga",
    "stretching": "yoga",
    "meditation": "other",
    "cardio": "hiit",
    "rowing": "erg",
    "outdoor": "run",                # "Outdoor Running" appears under Outdoor
    "bootcamp": "hiit",
    "bike bootcamp": "hiit",
    "tread bootcamp": "hiit",
}


def _parse_peloton_ts(raw: str) -> Optional[datetime]:
    """Peloton timestamps: '2025-03-28 17:29 (EDT)' — strip the TZ label
    since we don't have a full zoneinfo mapping for 3-letter abbreviations;
    treat the naive portion as UTC. Users care about date alignment more
    than second-precision offset here.
    """
    if not raw:
        return None
    s = raw.strip()
    # Strip the trailing "(EDT)" / "(UTC)" and anything after.
    s = re.sub(r"\s*\([^)]+\)\s*$", "", s).strip()
    # Formats seen: '2025-03-28 17:29', '2025-03-28 17:29:00', ISO with Z.
    for fmt in ("%Y-%m-%d %H:%M", "%Y-%m-%d %H:%M:%S"):
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    try:
        return ensure_tz_aware(datetime.fromisoformat(s.replace("Z", "+00:00")), "UTC")
    except ValueError:
        return None


def _row_to_cardio(row: dict[str, str], user_id: UUID) -> Optional[CanonicalCardioRow]:
    discipline_raw = (row.get("fitness discipline") or "").strip().lower()
    activity_type = _DISCIPLINE_MAP.get(discipline_raw)
    if activity_type is None:
        # Null entry == strength; skip here so the strength pipeline can pick up.
        # If the discipline is unrecognized but non-empty, fall through to 'other'.
        if discipline_raw in {"strength"}:
            return None
        activity_type = normalize_activity_type(discipline_raw) or "other"

    performed_at = _parse_peloton_ts(row.get("workout timestamp") or "")
    if performed_at is None:
        return None

    # Length is in minutes — convert to seconds. Peloton exports ints as "30".
    length_min = safe_float(row.get("length (minutes)"))
    duration_seconds = int(round(length_min * 60)) if length_min and length_min > 0 else None
    if not duration_seconds:
        return None

    # Distance in miles (cycling + running + walking).
    distance_mi = safe_float(row.get("distance (mi)"))
    distance_m = miles_to_meters(distance_mi) if distance_mi else None

    avg_watts = safe_int(row.get("avg. watts") or row.get("avg_watts"))
    avg_cadence = safe_int(row.get("avg. cadence (rpm)") or row.get("avg_cadence"))
    avg_hr = safe_int(row.get("avg. heartrate") or row.get("avg_heartrate"))
    calories = safe_int(row.get("calories burned") or row.get("calories_burned"))
    total_output = safe_int(row.get("total output"))

    avg_pace, avg_speed = derive_pace_and_speed(duration_seconds, distance_m)

    workout_id = row.get("workout id") or row.get("workout_id") or None
    title = row.get("title") or None
    instructor = row.get("instructor name") or None
    note_parts = [p for p in (title, f"with {instructor}" if instructor else None) if p]
    notes = " — ".join(note_parts) if note_parts else None

    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="peloton",
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
        avg_heart_rate=avg_hr,
        avg_watts=avg_watts,
        avg_cadence=avg_cadence,
        avg_pace_seconds_per_km=avg_pace,
        avg_speed_mps=avg_speed,
        calories=calories,
        notes=notes,
        source_app="peloton",
        source_external_id=str(workout_id) if workout_id else None,
        source_row_hash=row_hash,
    )


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: ImportMode,
) -> ParseResult:
    text = data.decode("utf-8-sig", errors="replace")
    reader = csv.DictReader(io.StringIO(text))
    cardio_rows: list[CanonicalCardioRow] = []
    warnings: list[str] = []
    for raw in reader:
        row = {(k or "").strip().lower(): (v or "").strip() for k, v in raw.items()}
        try:
            cardio = _row_to_cardio(row, user_id)
            if cardio is not None:
                cardio_rows.append(cardio)
        except Exception as e:
            warnings.append(f"Skipped Peloton row: {e}")

    return ParseResult(
        mode=ImportMode.CARDIO_ONLY,
        source_app="peloton",
        cardio_rows=cardio_rows,
        warnings=warnings,
    )
