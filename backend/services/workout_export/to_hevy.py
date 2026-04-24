"""
Emit a Hevy-compatible CSV from canonical rows.

Hevy's published CSV schema (export from Hevy app → Settings → Export Data):
    title, start_time, end_time, description, exercise_title, superset_id,
    exercise_notes, set_index, set_type, weight_kg, weight_lbs, reps,
    distance_km, duration_seconds, rpe

Format-critical details:
    • Date format: "28 Mar 2025, 17:29" (no timezone; Hevy interprets as the
      user's local tz at import time).
    • set_index is 0-based in Hevy's own exports — matching here so re-import
      goes straight through.
    • Both weight_kg AND weight_lbs columns ship on every row. Hevy's
      importer picks whichever one is non-empty; we populate both.
    • A row with weight=0 means bodyweight; we keep the zero in weight_kg
      (and its lbs twin) rather than leaving blanks — that matches Hevy's
      own export behavior and prevents their importer from interpreting
      blanks as "missing".
    • set_type values Hevy accepts: 'normal' (the default 'working'),
      'warmup', 'failure', 'dropset'. Everything else degrades to 'normal'
      so the CSV stays importable.
    • Cardio rows (activity_type != strength) are emitted with exercise_title
      derived from activity_type and distance_km + duration_seconds populated.
"""
from __future__ import annotations

import csv
import io
from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
    LB_TO_KG,
    SetType,
)


# Match Hevy's ACTUAL export headers verbatim — title-case + parenthetical units.
# This is what users' real files look like; roundtrip imports rely on these names.
HEVY_COLUMNS = [
    "Title",
    "Start Time",
    "End Time",
    "Description",
    "Exercise Title",
    "Superset ID",
    "Exercise Notes",
    "Set Index",
    "Set Type",
    "Weight (kg)",
    "Weight (lbs)",
    "Reps",
    "Distance (meters)",
    "Duration (seconds)",
    "RPE",
]


# Hevy's own set-type vocabulary. Anything not in here degrades to 'normal'.
_SET_TYPE_MAP = {
    SetType.WORKING.value: "normal",
    SetType.WARMUP.value: "warmup",
    SetType.FAILURE.value: "failure",
    SetType.DROPSET.value: "dropset",
}


def _fmt_datetime(dt: datetime) -> str:
    """Hevy uses "28 Mar 2025, 17:29" (day-first, no seconds, no TZ)."""
    if dt is None:
        return ""
    return dt.strftime("%d %b %Y, %H:%M")


def _kg_to_lbs(kg: Optional[float]) -> Optional[float]:
    if kg is None:
        return None
    # 1 / LB_TO_KG kept as a Decimal so we don't drift on the inverse.
    return float(Decimal(str(kg)) / LB_TO_KG)


def _strength_row_to_csv(row: CanonicalSetRow) -> dict:
    set_type = _SET_TYPE_MAP.get(
        row.set_type if isinstance(row.set_type, str) else (row.set_type.value if row.set_type else "working"),
        "normal",
    )
    # Hevy's end_time == start_time when we don't know how long the set took.
    start = _fmt_datetime(row.performed_at)

    # set_index is 0-based in Hevy's exports. Canonical set_number is
    # 1-based (matches how humans count sets). Subtract 1, clamp at 0.
    set_idx = max(0, (row.set_number - 1) if row.set_number else 0)

    weight_kg = row.weight_kg
    weight_lbs = _kg_to_lbs(weight_kg)

    return {
        "Title": row.workout_name or "Workout",
        "Start Time": start,
        "End Time": start,
        "Description": "",
        # Prefer the user-facing raw name Hevy would have written.
        "Exercise Title": row.exercise_name_raw or row.exercise_name_canonical or "",
        "Superset ID": row.superset_id or "",
        "Exercise Notes": row.notes or "",
        "Set Index": set_idx,
        "Set Type": set_type,
        "Weight (kg)": "" if weight_kg is None else f"{weight_kg:.2f}",
        "Weight (lbs)": "" if weight_lbs is None else f"{weight_lbs:.2f}",
        "Reps": "" if row.reps is None else row.reps,
        "Distance (meters)": "",
        "Duration (seconds)": "" if row.duration_seconds is None else row.duration_seconds,
        "RPE": "" if row.rpe is None else f"{row.rpe:.1f}",
    }


def _cardio_row_to_csv(row: CanonicalCardioRow) -> dict:
    start = _fmt_datetime(row.performed_at)
    # Hevy doesn't have a dedicated cardio schema in its CSV — it uses the
    # same set-shaped rows with a cardio exercise_title. Distance is in
    # METERS per Hevy's header ("Distance (meters)").
    return {
        "Title": row.activity_type.replace("_", " ").title(),
        "Start Time": start,
        "End Time": start,
        "Description": "",
        "Exercise Title": row.activity_type.replace("_", " ").title(),
        "Superset ID": "",
        "Exercise Notes": row.notes or "",
        "Set Index": 0,
        "Set Type": "normal",
        "Weight (kg)": "",
        "Weight (lbs)": "",
        "Reps": "",
        "Distance (meters)": "" if row.distance_m is None else f"{row.distance_m:.1f}",
        "Duration (seconds)": row.duration_seconds,
        "RPE": "" if row.rpe is None else f"{row.rpe:.1f}",
    }


def export_hevy_csv(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
    *,
    include_strength: bool = True,
    include_cardio: bool = True,
) -> bytes:
    """Emit a Hevy-compatible CSV as utf-8 bytes.

    Strength rows appear first (chronological), then cardio rows — matches
    Hevy's own export ordering and makes diffing a round-trip trivial.
    """
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=HEVY_COLUMNS, extrasaction="ignore")
    writer.writeheader()

    if include_strength:
        for r in strength_rows:
            writer.writerow(_strength_row_to_csv(r))
    if include_cardio:
        for r in cardio_rows:
            writer.writerow(_cardio_row_to_csv(r))

    return buf.getvalue().encode("utf-8")
