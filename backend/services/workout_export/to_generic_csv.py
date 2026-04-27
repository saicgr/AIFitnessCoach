"""
Emit an expanded "maximum-fidelity" CSV that mirrors the canonical schema
column-for-column.

This is the format power users ask for when they don't care about Hevy/Strong
compatibility and just want every field Zealova holds. Because the headers
match CanonicalSetRow / CanonicalCardioRow field names 1:1, the matching
import adapter for this format is trivially "read the CSV, call
CanonicalSetRow(**row)".

Two CSVs get concatenated in one blob, separated by the literal line
`# ─── STRENGTH ───` / `# ─── CARDIO ───` so a single file holds both. The
downstream importer splits on the delimiter. This keeps the export a single
file (easier to share via AirDrop / email) without forcing users to manage
a ZIP for the common case.
"""
from __future__ import annotations

import csv
import io
from datetime import datetime
from typing import Any, List, Optional

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
)


STRENGTH_COLUMNS = [
    "user_id", "performed_at", "workout_name",
    "exercise_name_raw", "exercise_name_canonical", "exercise_id",
    "set_number", "set_type", "weight_kg", "original_weight_value",
    "original_weight_unit", "reps", "duration_seconds", "distance_m",
    "rpe", "rir", "superset_id", "notes",
    "source_app", "source_row_hash",
]

CARDIO_COLUMNS = [
    "user_id", "performed_at", "activity_type", "duration_seconds",
    "distance_m", "elevation_gain_m",
    "avg_heart_rate", "max_heart_rate",
    "avg_pace_seconds_per_km", "avg_speed_mps",
    "avg_watts", "max_watts", "avg_cadence", "avg_stroke_rate",
    "training_effect", "vo2max_estimate",
    "calories", "rpe", "notes",
    "gps_polyline", "splits_json",
    "source_app", "source_external_id", "source_row_hash",
    "sync_account_id",
]


def _iso(dt: Optional[datetime]) -> str:
    if dt is None:
        return ""
    return dt.isoformat()


def _cell(v: Any) -> Any:
    """CSV doesn't have null — blank string maps to None on reimport."""
    if v is None:
        return ""
    if isinstance(v, datetime):
        return v.isoformat()
    if isinstance(v, (dict, list)):
        import json as _json
        return _json.dumps(v, default=str)
    return v


def _row_to_dict(row, columns: List[str]) -> dict:
    d = row.model_dump()
    return {k: _cell(d.get(k)) for k in columns}


def export_generic_csv(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
    *,
    include_strength: bool = True,
    include_cardio: bool = True,
) -> bytes:
    buf = io.StringIO()

    if include_strength:
        buf.write("# ─── STRENGTH ───\n")
        w = csv.DictWriter(buf, fieldnames=STRENGTH_COLUMNS, extrasaction="ignore")
        w.writeheader()
        for r in strength_rows:
            w.writerow(_row_to_dict(r, STRENGTH_COLUMNS))

    if include_cardio:
        buf.write("# ─── CARDIO ───\n")
        w = csv.DictWriter(buf, fieldnames=CARDIO_COLUMNS, extrasaction="ignore")
        w.writeheader()
        for r in cardio_rows:
            w.writerow(_row_to_dict(r, CARDIO_COLUMNS))

    return buf.getvalue().encode("utf-8")
