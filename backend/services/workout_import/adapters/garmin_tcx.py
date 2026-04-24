"""
Garmin TCX adapter.

TCX (Training Center XML) is Garmin's older interchange format; still
emitted by Garmin Connect alongside FIT, and by Peloton when the user
requests GPX/TCX-format workout files. TCX carries the same data as FIT
(laps, HR, cadence, watts) but in XML — which means no `fitparse`
dependency.

Differences from generic GPX:
  - TCX stores distance + elevation directly instead of requiring
    Haversine derivation (the device measured them).
  - Lap-level data is a first-class structure; we emit it as `splits_json`.
  - Activity type lives in `<Activity Sport="Biking|Running|Other">`.
"""
from __future__ import annotations

import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID

from ..canonical import CanonicalCardioRow, ImportMode, ParseResult
from ._cardio_common import (
    derive_pace_and_speed,
    ensure_tz_aware,
    normalize_activity_type,
)
from .generic_gpx import _encode_polyline, _parse_gpx_time


_TCX_NS = "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
_TCX_EXT_NS = "http://www.garmin.com/xmlschemas/ActivityExtension/v2"


def _ns(tag: str) -> str:
    return f"{{{_TCX_NS}}}{tag}"


def _find_text(parent: ET.Element, path: str) -> Optional[str]:
    el = parent.find(path)
    if el is not None and el.text:
        return el.text.strip()
    return None


def _parse_activity(activity: ET.Element, user_id: UUID) -> Optional[CanonicalCardioRow]:
    sport_raw = activity.attrib.get("Sport") or "Other"
    activity_type = normalize_activity_type(sport_raw) or "other"

    laps = activity.findall(_ns("Lap"))
    if not laps:
        return None

    # Sum lap-level totals — trusting the device's measurement is more
    # accurate than recomputing from trackpoints for cycling (where
    # trackpoint sampling rate is coarse).
    total_distance_m = 0.0
    total_duration_s = 0.0
    total_calories = 0
    hrs: list[int] = []
    max_hr: Optional[int] = None
    cadences: list[int] = []
    watts_list: list[int] = []
    points: list[tuple[float, float]] = []
    splits: list[dict[str, Any]] = []
    start_time: Optional[datetime] = None

    for lap in laps:
        lap_start = lap.attrib.get("StartTime")
        if lap_start:
            try:
                lap_start_dt = _parse_gpx_time(lap_start)
                if start_time is None or lap_start_dt < start_time:
                    start_time = lap_start_dt
            except Exception:
                pass
        lap_time_s = float(_find_text(lap, _ns("TotalTimeSeconds")) or 0)
        lap_distance_m = float(_find_text(lap, _ns("DistanceMeters")) or 0)
        total_duration_s += lap_time_s
        total_distance_m += lap_distance_m
        cal_text = _find_text(lap, _ns("Calories"))
        if cal_text:
            try:
                total_calories += int(cal_text)
            except ValueError:
                pass
        avg_hr_text = _find_text(lap, f"{_ns('AverageHeartRateBpm')}/{_ns('Value')}")
        if avg_hr_text:
            try:
                hrs.append(int(avg_hr_text))
            except ValueError:
                pass
        max_hr_text = _find_text(lap, f"{_ns('MaximumHeartRateBpm')}/{_ns('Value')}")
        if max_hr_text:
            try:
                v = int(max_hr_text)
                max_hr = v if max_hr is None else max(max_hr, v)
            except ValueError:
                pass

        # Per-lap trackpoints for HR / cadence / watts / polyline build.
        for track in lap.findall(_ns("Track")):
            for tpt in track.findall(_ns("Trackpoint")):
                pos = tpt.find(_ns("Position"))
                if pos is not None:
                    lat_t = _find_text(pos, _ns("LatitudeDegrees"))
                    lon_t = _find_text(pos, _ns("LongitudeDegrees"))
                    try:
                        if lat_t and lon_t:
                            points.append((float(lat_t), float(lon_t)))
                    except ValueError:
                        pass
                hr_t = _find_text(tpt, f"{_ns('HeartRateBpm')}/{_ns('Value')}")
                if hr_t:
                    try:
                        hrs.append(int(hr_t))
                    except ValueError:
                        pass
                cad_t = _find_text(tpt, _ns("Cadence"))
                if cad_t:
                    try:
                        cadences.append(int(cad_t))
                    except ValueError:
                        pass
                # Watts live in the v2 extension namespace.
                tpx = tpt.find(_ns("Extensions"))
                if tpx is not None:
                    for child in tpx.iter():
                        if child.tag.endswith("}Watts") and child.text:
                            try:
                                watts_list.append(int(child.text))
                            except ValueError:
                                pass

        if lap_time_s > 0 and lap_distance_m > 0:
            splits.append({
                "lap_seconds": int(round(lap_time_s)),
                "lap_distance_m": round(lap_distance_m, 2),
                "pace_seconds_per_km": round(lap_time_s / (lap_distance_m / 1000), 2) if lap_distance_m >= 100 else None,
            })

    if total_duration_s <= 0:
        return None
    if start_time is None:
        id_text = _find_text(activity, _ns("Id"))
        if id_text:
            try:
                start_time = _parse_gpx_time(id_text)
            except Exception:
                start_time = datetime.now(tz=timezone.utc)
        else:
            start_time = datetime.now(tz=timezone.utc)

    avg_hr = int(round(sum(hrs) / len(hrs))) if hrs else None
    avg_cadence = int(round(sum(cadences) / len(cadences))) if cadences else None
    avg_watts = int(round(sum(watts_list) / len(watts_list))) if watts_list else None
    max_watts = max(watts_list) if watts_list else None
    avg_pace, avg_speed = derive_pace_and_speed(int(total_duration_s), total_distance_m)

    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="garmin",
        performed_at=start_time,
        activity_type=activity_type,
        duration_seconds=int(total_duration_s),
        distance_m=total_distance_m,
    )

    # Activity ID doubles as external_id for Garmin Connect downloads.
    external_id = _find_text(activity, _ns("Id"))

    return CanonicalCardioRow(
        user_id=user_id,
        performed_at=ensure_tz_aware(start_time, "UTC"),
        activity_type=activity_type,
        duration_seconds=int(total_duration_s),
        distance_m=round(total_distance_m, 2) if total_distance_m > 0 else None,
        avg_heart_rate=avg_hr,
        max_heart_rate=max_hr,
        avg_cadence=avg_cadence,
        avg_watts=avg_watts,
        max_watts=max_watts,
        avg_pace_seconds_per_km=avg_pace,
        avg_speed_mps=avg_speed,
        calories=total_calories or None,
        gps_polyline=_encode_polyline(points) if points else None,
        splits_json=splits or None,
        source_app="garmin",
        source_external_id=external_id,
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
    try:
        root = ET.fromstring(data)
    except ET.ParseError as e:
        return ParseResult(
            mode=ImportMode.CARDIO_ONLY,
            source_app="garmin",
            warnings=[f"TCX parse error: {e}"],
        )

    rows: list[CanonicalCardioRow] = []
    # Root is either <TrainingCenterDatabase> (typical) or <Activities>.
    for activity in root.findall(f".//{_ns('Activity')}"):
        row = _parse_activity(activity, user_id)
        if row is not None:
            rows.append(row)

    return ParseResult(
        mode=ImportMode.CARDIO_ONLY,
        source_app="garmin",
        cardio_rows=rows,
    )
