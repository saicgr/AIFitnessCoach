"""
Strava bulk-export adapter.

Strava ships a ZIP containing:
  - `activities.csv`  — summary row per activity (all sports)
  - `activities/<id>.gpx|.tcx|.fit` — per-activity track file
  - `media/` — photos (ignored here)

We prefer the CSV as the source of truth (it is the canonical Strava
representation) and decorate with GPS polyline + splits from the
per-activity file when available. `activity_id` becomes source_external_id
so a webhook re-sync dedupes against the same row.

Activity-type mapping (edge case from plan):
  Ride          → cycle
  Run           → run
  Hike          → hike
  WeightTraining, Workout, Crossfit, Elliptical → routed based on keyword
  (WeightTraining → skip here, would be routed to strength elsewhere)
"""
from __future__ import annotations

import csv
import io
import re
import zipfile
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
    parse_duration_string,
    safe_float,
    safe_int,
)
from .generic_gpx import parse_gpx_bytes


# Strava exports dates in one of two formats depending on locale at sign-up.
# Both represent UTC.
_STRAVA_DATE_FORMATS = (
    "%b %d, %Y, %I:%M:%S %p",       # "Mar 28, 2025, 5:29:00 PM"
    "%Y-%m-%d %H:%M:%S",            # "2025-03-28 17:29:00"
    "%b %d, %Y %I:%M:%S %p",        # older variant, no comma after year
    "%b %d, %Y, %I:%M:%S %p UTC",   # newer variants occasionally append UTC
)


def _parse_strava_date(raw: str) -> datetime:
    s = (raw or "").strip().replace(" ", " ")  # NBSP that appears in some exports
    if not s:
        raise ValueError("empty date")
    for fmt in _STRAVA_DATE_FORMATS:
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    # ISO with timezone as a last resort.
    try:
        return ensure_tz_aware(datetime.fromisoformat(s.replace("Z", "+00:00")), "UTC")
    except ValueError as e:
        raise ValueError(f"unrecognized Strava date: {s!r}") from e


def _read_activities_csv(blob: bytes) -> list[dict[str, str]]:
    """Decode activities.csv. Strava uses utf-8 with a BOM on Windows
    exports — handle both. Returns a list of row dicts with lowercased
    header keys for consistent access."""
    text = blob.decode("utf-8-sig", errors="replace")
    reader = csv.DictReader(io.StringIO(text))
    rows: list[dict[str, str]] = []
    for raw_row in reader:
        if not raw_row:
            continue
        rows.append({(k or "").strip().lower(): (v or "").strip() for k, v in raw_row.items()})
    return rows


def _find_activities_csv(zf: zipfile.ZipFile) -> Optional[bytes]:
    for name in zf.namelist():
        if name.endswith("activities.csv"):
            return zf.read(name)
    return None


def _find_track_file(zf: zipfile.ZipFile, activity_id: str) -> Optional[tuple[str, bytes]]:
    """Strava names per-activity files `activities/<id>.<ext>` and sometimes
    ZIP-gzips them on export (`activities/<id>.gpx.gz`). We pick the first
    match, preferring GPX over TCX over FIT."""
    candidates: list[tuple[int, str, bytes]] = []
    for name in zf.namelist():
        if not name.startswith("activities/"):
            continue
        stem = name[len("activities/"):]
        if not stem.startswith(f"{activity_id}."):
            continue
        try:
            blob = zf.read(name)
        except Exception:
            continue
        # Preference order: gpx(1) > tcx(2) > fit(3). Lower = better.
        lower = name.lower()
        if ".gpx" in lower:
            priority = 1
        elif ".tcx" in lower:
            priority = 2
        elif ".fit" in lower:
            priority = 3
        else:
            priority = 9
        # Strip gzip wrapper inline — Strava sometimes compresses.
        if lower.endswith(".gz"):
            try:
                import gzip
                blob = gzip.decompress(blob)
            except Exception:
                continue
        candidates.append((priority, name, blob))
    if not candidates:
        return None
    candidates.sort(key=lambda x: x[0])
    return candidates[0][1], candidates[0][2]


def _row_to_cardio(
    row: dict[str, str],
    user_id: UUID,
    polyline: Optional[str] = None,
    splits: Optional[list[dict[str, Any]]] = None,
) -> Optional[CanonicalCardioRow]:
    """Build a cardio row from one activities.csv row + optional track data.
    Returns None for strength activities — the caller should route those to
    strength_rows via the workout_history pipeline."""
    activity_raw = row.get("activity type") or row.get("activity_type")
    if not activity_raw:
        return None

    # Filter strength activities out entirely — they're not cardio. (The
    # service layer writes them via the strength-import pipeline.) Normalize
    # whitespace/hyphens so "Weight Training" and "WeightTraining" both hit.
    _norm_type = activity_raw.lower().replace(" ", "_").replace("-", "_")
    if any(kw in _norm_type for kw in STRENGTH_ACTIVITY_KEYWORDS):
        return None

    activity_type = normalize_activity_type(activity_raw) or "other"

    date_raw = row.get("activity date") or row.get("activity_date")
    if not date_raw:
        return None
    try:
        performed_at = _parse_strava_date(date_raw)
    except ValueError:
        return None

    # Strava CSV duration is seconds (numeric) or HH:MM:SS depending on export version.
    duration_s = parse_duration_string(row.get("moving time") or row.get("elapsed time"))
    if not duration_s:
        return None

    # Distance is in km by default; convert to meters. Empty string → None.
    dist_km = safe_float(row.get("distance"))
    distance_m = km_to_meters(dist_km) if dist_km is not None else None

    activity_id = row.get("activity id") or row.get("activity_id") or None
    avg_hr = safe_int(row.get("average heart rate"))
    max_hr = safe_int(row.get("max heart rate"))
    avg_watts = safe_int(row.get("average watts"))
    calories = safe_int(row.get("calories"))
    elevation_gain = safe_float(row.get("elevation gain"))
    rpe_raw = safe_float(row.get("perceived exertion") or row.get("relative effort"))

    avg_pace, avg_speed = derive_pace_and_speed(duration_s, distance_m)

    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="strava",
        performed_at=performed_at,
        activity_type=activity_type,
        duration_seconds=duration_s,
        distance_m=distance_m,
    )

    notes = row.get("activity name") or None

    return CanonicalCardioRow(
        user_id=user_id,
        performed_at=performed_at,
        activity_type=activity_type,
        duration_seconds=duration_s,
        distance_m=round(distance_m, 2) if distance_m else None,
        elevation_gain_m=elevation_gain,
        avg_heart_rate=avg_hr,
        max_heart_rate=max_hr,
        avg_watts=avg_watts,
        avg_pace_seconds_per_km=avg_pace,
        avg_speed_mps=avg_speed,
        calories=calories,
        rpe=rpe_raw if rpe_raw and 0 <= rpe_raw <= 10 else None,
        notes=notes,
        gps_polyline=polyline,
        splits_json=splits,
        source_app="strava",
        source_external_id=str(activity_id) if activity_id else None,
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
    warnings: list[str] = []
    cardio_rows: list[CanonicalCardioRow] = []

    # Happy path: ZIP containing activities.csv (+ optionally per-activity files).
    if data[:4] == b"PK\x03\x04":
        with zipfile.ZipFile(io.BytesIO(data)) as zf:
            csv_blob = _find_activities_csv(zf)
            if csv_blob is None:
                warnings.append("Strava ZIP missing activities.csv — falling back to GPX scan")
                # Some exports only contain per-activity files in a share bundle.
                for name in zf.namelist():
                    if name.lower().endswith(".gpx"):
                        try:
                            blob = zf.read(name)
                            rows = parse_gpx_bytes(data=blob, user_id=user_id, source_app="strava")
                            cardio_rows.extend(rows)
                        except Exception as e:
                            warnings.append(f"Skipping {name}: {e}")
            else:
                for row in _read_activities_csv(csv_blob):
                    activity_id = row.get("activity id") or row.get("activity_id") or ""
                    polyline: Optional[str] = None
                    splits: Optional[list[dict[str, Any]]] = None
                    if activity_id:
                        track = _find_track_file(zf, activity_id)
                        if track is not None:
                            _, blob = track
                            # Only decorate with polyline/splits if we got a GPX.
                            # TCX/FIT parsing would need the dedicated adapters.
                            if blob[:5] == b"<?xml" or b"<gpx" in blob[:200]:
                                try:
                                    decorated = parse_gpx_bytes(
                                        data=blob, user_id=user_id, source_app="strava"
                                    )
                                    if decorated:
                                        polyline = decorated[0].gps_polyline
                                        splits = decorated[0].splits_json
                                except Exception as e:
                                    warnings.append(f"GPX decorate failed for {activity_id}: {e}")
                    cardio_row = _row_to_cardio(row, user_id, polyline=polyline, splits=splits)
                    if cardio_row is not None:
                        cardio_rows.append(cardio_row)
    else:
        # Not a ZIP — treat as a bare CSV export (some users extract first).
        for row in _read_activities_csv(data):
            cardio_row = _row_to_cardio(row, user_id)
            if cardio_row is not None:
                cardio_rows.append(cardio_row)

    return ParseResult(
        mode=ImportMode.CARDIO_ONLY,
        source_app="strava",
        cardio_rows=cardio_rows,
        warnings=warnings,
    )
