"""
Emit a Fitbod-compatible CSV.

Fitbod columns (Settings → Data → Export Workouts):
    Date, Exercise, Reps, Weight(kg), Duration(s), Distance(m), Incline,
    Resistance, isWarmup, Note, multiplier

Format-critical details:
    • Date format: "YYYY-MM-DD HH:MM:SS ±ZZZZ" — TZ offset IS included
      (Fitbod's export is TZ-aware). We render `%z` formatted as ±ZZZZ.
    • Weight is always in kg; there is no unit column.
    • isWarmup: "yes" / "no" literal strings.
    • multiplier: normally "1" for single reps at stated weight. We emit "1"
      unless the canonical row has a distinct hint — covers the common case
      and keeps the importer happy.
    • Incline / Resistance are machine-specific; we leave them blank. Fitbod
      itself leaves them blank for free-weight rows too.
"""
from __future__ import annotations

import csv
import io
from datetime import datetime
from typing import List, Optional

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
    SetType,
)


# Match Fitbod's ACTUAL export column names verbatim.
FITBOD_COLUMNS = [
    "Date",
    "Exercise",
    "Reps",
    "Weight (kg)",
    "Duration (seconds)",
    "Distance (meters)",
    "Incline",
    "Resistance",
    "isWarmup",
    "Note",
    "multiplier",
]


def _fmt_datetime(dt: datetime) -> str:
    if dt is None:
        return ""
    # Python's %z renders as "+0000" (no colon) which matches Fitbod's export.
    # If tzinfo is somehow missing we fall back to "+0000" to keep the column
    # width consistent rather than emitting a naive string.
    base = dt.strftime("%Y-%m-%d %H:%M:%S")
    tz = dt.strftime("%z") or "+0000"
    return f"{base} {tz}"


def _is_warmup_literal(set_type) -> str:
    """Fitbod's real export uses lowercase 'true'/'false', not yes/no."""
    val = set_type if isinstance(set_type, str) else (set_type.value if set_type else "working")
    return "true" if val == SetType.WARMUP.value else "false"


def _strength_row(row: CanonicalSetRow) -> dict:
    return {
        "Date": _fmt_datetime(row.performed_at),
        "Exercise": row.exercise_name_raw or row.exercise_name_canonical or "",
        "Reps": "" if row.reps is None else row.reps,
        "Weight (kg)": "" if row.weight_kg is None else f"{row.weight_kg:.2f}",
        "Duration (seconds)": "" if row.duration_seconds is None else row.duration_seconds,
        "Distance (meters)": "" if row.distance_m is None else f"{row.distance_m:.2f}",
        "Incline": "",
        "Resistance": "",
        "isWarmup": _is_warmup_literal(row.set_type),
        "Note": row.notes or "",
        "multiplier": 1,
    }


def _cardio_row(row: CanonicalCardioRow) -> dict:
    return {
        "Date": _fmt_datetime(row.performed_at),
        "Exercise": row.activity_type.replace("_", " ").title(),
        "Reps": "",
        "Weight (kg)": "",
        "Duration (seconds)": row.duration_seconds,
        "Distance (meters)": "" if row.distance_m is None else f"{row.distance_m:.2f}",
        "Incline": "",
        "Resistance": "",
        "isWarmup": "false",
        "Note": row.notes or "",
        "multiplier": 1,
    }


def export_fitbod_csv(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
    *,
    include_strength: bool = True,
    include_cardio: bool = True,
) -> bytes:
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=FITBOD_COLUMNS, extrasaction="ignore")
    writer.writeheader()

    if include_strength:
        for r in strength_rows:
            writer.writerow(_strength_row(r))
    if include_cardio:
        for r in cardio_rows:
            writer.writerow(_cardio_row(r))

    return buf.getvalue().encode("utf-8")
