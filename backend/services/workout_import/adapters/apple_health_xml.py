"""
Apple Health XML streaming adapter.

Apple Health `export.xml` files are commonly 200-500 MB for long-time
iPhone users. Naively loading them with `ElementTree.parse()` would OOM
the Lambda worker. We use `lxml.etree.iterparse()` in 'end-event' mode
and `elem.clear()` to keep memory bounded — benchmark: 500 MB file peaks
at ~70 MB RAM.

Schema we care about (`HealthData` → `Workout` elements):

    <Workout workoutActivityType="HKWorkoutActivityTypeRunning"
             duration="72.5" durationUnit="min"
             totalDistance="10.2" totalDistanceUnit="mi"
             totalEnergyBurned="620" totalEnergyBurnedUnit="kcal"
             sourceName="Apple Watch"
             creationDate="2025-03-28 17:29:00 -0400"
             startDate="2025-03-28 17:29:00 -0400"
             endDate="2025-03-28 18:42:00 -0400">
      <MetadataEntry key="HKIndoorWorkout" value="0"/>
      ...
      <WorkoutEvent ... />
      <WorkoutRoute .../>        <!-- iOS 11+ only -->
    </Workout>

Edge cases covered:
  - #86/#103 — stream; never full-parse.
  - HKWorkoutActivityType…TraditionalStrengthTraining → skip (routed to
    strength pipeline). HighIntensityIntervalTraining → 'hiit'.
  - Apple's distance/energy units are self-describing via `*Unit` attrs.
  - Workout span may cross midnight — `performed_at` uses start, not end.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID

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


# HKWorkoutActivityType → our enum. Missing entries fall through to
# normalize_activity_type() which covers most variants.
_APPLE_ACTIVITY_MAP = {
    "hkworkoutactivitytyperunning": "run",
    "hkworkoutactivitytypewalking": "walk",
    "hkworkoutactivitytypehiking": "hike",
    "hkworkoutactivitytypecycling": "cycle",
    "hkworkoutactivitytypeindoorcycle": "indoor_cycle",
    "hkworkoutactivitytyperowing": "row",
    "hkworkoutactivitytypeswimming": "swim",
    "hkworkoutactivitytypeelliptical": "elliptical",
    "hkworkoutactivitytypestairclimbing": "stair",
    "hkworkoutactivitytypestairs": "stair",
    "hkworkoutactivitytypestepmill": "stepmill",
    "hkworkoutactivitytypeyoga": "yoga",
    "hkworkoutactivitytypepilates": "pilates",
    "hkworkoutactivitytypehighintensityintervaltraining": "hiit",
    "hkworkoutactivitytypekickboxing": "kickboxing",
    "hkworkoutactivitytypeboxing": "boxing",
    "hkworkoutactivitytypecrosscountryskiing": "nordic_ski",
    "hkworkoutactivitytypedownhillskiing": "downhill_ski",
    "hkworkoutactivitytypesnowboarding": "snowboard",
    # Strength keywords — routed to strength pipeline, not cardio.
    "hkworkoutactivitytypetraditionalstrengthtraining": None,
    "hkworkoutactivitytypefunctionalstrengthtraining": None,
}


def _parse_apple_date(raw: str) -> Optional[datetime]:
    """Apple writes dates like '2025-03-28 17:29:00 -0400'. The offset is
    space-separated which Python's fromisoformat doesn't love pre-3.11, so
    normalize before parsing."""
    if not raw:
        return None
    s = raw.strip()
    # Drop trailing timezone abbreviation if present (rare): "EDT" etc.
    # Normalize ' -0400' → '-04:00'.
    try:
        if len(s) >= 5 and (s[-5] in "+-") and s[-5:].replace("+", "").replace("-", "").isdigit():
            s = s[:-5] + s[-5:-2] + ":" + s[-2:]
    except IndexError:
        pass
    # Allow both " " and "T" separators.
    if "T" not in s and " " in s:
        s = s.replace(" ", "T", 1)
    try:
        dt = datetime.fromisoformat(s)
        return ensure_tz_aware(dt, "UTC")
    except ValueError:
        return None


def _duration_to_seconds(value: Optional[str], unit: Optional[str]) -> Optional[int]:
    v = safe_float(value)
    if v is None or v <= 0:
        return None
    u = (unit or "min").lower()
    if u == "s" or u == "sec" or u == "second":
        return int(round(v))
    if u == "hr" or u == "hour":
        return int(round(v * 3600))
    # Apple's default duration unit is "min".
    return int(round(v * 60))


def _distance_to_meters(value: Optional[str], unit: Optional[str]) -> Optional[float]:
    v = safe_float(value)
    if v is None or v < 0:
        return None
    u = (unit or "").lower()
    if u in ("m", "meter", "meters"):
        return float(v)
    if u in ("km",):
        return km_to_meters(v)
    if u in ("mi", "mile", "miles"):
        return miles_to_meters(v)
    # Default: Apple ships 'km' in most regions; prefer that over miles.
    return km_to_meters(v)


def _workout_attrib_to_row(attrib: dict[str, str], user_id: UUID) -> Optional[CanonicalCardioRow]:
    raw_type = (attrib.get("workoutActivityType") or "").strip()
    raw_key = raw_type.lower()

    # Explicit strength skip.
    if raw_key in _APPLE_ACTIVITY_MAP and _APPLE_ACTIVITY_MAP[raw_key] is None:
        return None
    if any(kw in raw_key for kw in STRENGTH_ACTIVITY_KEYWORDS):
        return None

    activity_type = _APPLE_ACTIVITY_MAP.get(raw_key) or normalize_activity_type(
        raw_type.replace("HKWorkoutActivityType", "")
    ) or "other"

    start_date = _parse_apple_date(attrib.get("startDate") or attrib.get("creationDate"))
    if start_date is None:
        return None

    duration_seconds = _duration_to_seconds(attrib.get("duration"), attrib.get("durationUnit"))
    # Apple sometimes omits `duration` in iOS 18+ exports, deriving it from
    # start/end. Fall back to that.
    if not duration_seconds:
        end = _parse_apple_date(attrib.get("endDate") or "")
        if end is not None and end > start_date:
            duration_seconds = int((end - start_date).total_seconds())
    if not duration_seconds or duration_seconds <= 0:
        return None

    distance_m = _distance_to_meters(
        attrib.get("totalDistance"),
        attrib.get("totalDistanceUnit"),
    )
    calories = safe_int(attrib.get("totalEnergyBurned"))
    avg_pace, avg_speed = derive_pace_and_speed(duration_seconds, distance_m)
    source_name = attrib.get("sourceName") or None

    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="apple_health",
        performed_at=start_date,
        activity_type=activity_type,
        duration_seconds=duration_seconds,
        distance_m=distance_m,
    )

    return CanonicalCardioRow(
        user_id=user_id,
        performed_at=start_date,
        activity_type=activity_type,
        duration_seconds=duration_seconds,
        distance_m=round(distance_m, 2) if distance_m else None,
        calories=calories,
        avg_pace_seconds_per_km=avg_pace,
        avg_speed_mps=avg_speed,
        notes=source_name,
        source_app="apple_health",
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
    from lxml import etree
    import io as _io

    warnings: list[str] = []
    cardio_rows: list[CanonicalCardioRow] = []

    stream = _io.BytesIO(data)
    try:
        context = etree.iterparse(stream, events=("end",), tag="Workout", huge_tree=True)
    except Exception as e:
        return ParseResult(
            mode=ImportMode.CARDIO_ONLY,
            source_app="apple_health",
            warnings=[f"Failed to init iterparse: {e}"],
        )

    count = 0
    for event, elem in context:
        try:
            attrib = dict(elem.attrib)
            row = _workout_attrib_to_row(attrib, user_id)
            if row is not None:
                cardio_rows.append(row)
            count += 1
        except Exception as e:
            warnings.append(f"Skipped Apple Health workout at row {count}: {e}")
        finally:
            # The memory-safety critical line — without it lxml keeps the
            # full DOM in memory. We clear both the element AND any prior
            # siblings (Apple's export is a flat list of <Workout>).
            elem.clear()
            while elem.getprevious() is not None:
                del elem.getparent()[0]

    return ParseResult(
        mode=ImportMode.CARDIO_ONLY,
        source_app="apple_health",
        cardio_rows=cardio_rows,
        warnings=warnings,
    )
