"""
Emit a Strong-app compatible CSV.

Strong's published columns (Settings → Export Strong Data):
    Date, Workout Name, Duration, Exercise Name, Set Order, Weight,
    Weight Unit, Reps, RPE, Distance, Distance Unit, Seconds, Notes,
    Workout Notes

Format-critical details:
    • Date format: "YYYY-MM-DD HH:MM:SS" (ISO-ish, no timezone).
    • Duration: human-readable "1h 12m" style string — NOT seconds. The
      importer handles this via `parse_duration_string()`.
    • Set Order is 1-indexed (matching our canonical set_number shape).
    • Weight column is in the user's preferred unit, with Weight Unit =
      'lbs' or 'kg' telling Strong which one. We avoid silent conversion
      drift by converting from kg → lbs once and emitting the converted
      number with its unit tag.
    • Distance column is the raw number, Distance Unit is 'km' / 'mi' / 'm'.
      We default to 'km' because that's what Strong uses in its own exports
      from the EU/metric region; round-trips still work because the adapter
      reads the unit column.
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
)


STRONG_COLUMNS = [
    "Date",
    "Workout Name",
    "Duration",
    "Exercise Name",
    "Set Order",
    "Weight",
    "Weight Unit",
    "Reps",
    "RPE",
    "Distance",
    "Distance Unit",
    "Seconds",
    "Notes",
    "Workout Notes",
]


def _fmt_datetime(dt: datetime) -> str:
    if dt is None:
        return ""
    # Strong doesn't include timezone in its export; the importer attaches
    # the user's tz_hint at re-import time.
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def _fmt_duration(seconds: Optional[int]) -> str:
    """Render "1h 12m" style. Strong never uses seconds in the Duration col.

    When hours == 0, we drop the "0h" prefix and render minute-only ("30m")
    — matches Strong's own export convention, and keeps the importer's
    `parse_duration_string()` happy either way.
    """
    if not seconds or seconds <= 0:
        return ""
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    if hours and minutes:
        return f"{hours}h {minutes}m"
    if hours:
        return f"{hours}h"
    return f"{minutes}m"


def _convert_weight(weight_kg: Optional[float], unit: str) -> Optional[float]:
    if weight_kg is None:
        return None
    if unit == "lbs":
        return float(Decimal(str(weight_kg)) / LB_TO_KG)
    return weight_kg


def _strength_row(row: CanonicalSetRow, user_unit: str) -> dict:
    w = _convert_weight(row.weight_kg, user_unit)
    # Set Order is 1-indexed. Default to 1 when unknown.
    set_order = row.set_number if row.set_number and row.set_number > 0 else 1
    return {
        "Date": _fmt_datetime(row.performed_at),
        "Workout Name": row.workout_name or "Workout",
        "Duration": "",                                  # unknown at per-set granularity
        "Exercise Name": row.exercise_name_canonical or row.exercise_name_raw or "",
        "Set Order": set_order,
        "Weight": "" if w is None else f"{w:.2f}",
        "Weight Unit": user_unit,
        "Reps": "" if row.reps is None else row.reps,
        "RPE": "" if row.rpe is None else f"{row.rpe:.1f}",
        "Distance": "",
        "Distance Unit": "",
        "Seconds": "" if row.duration_seconds is None else row.duration_seconds,
        "Notes": row.notes or "",
        "Workout Notes": "",
    }


def _cardio_row(row: CanonicalCardioRow) -> dict:
    km = None
    if row.distance_m is not None:
        km = float(Decimal(str(row.distance_m)) / Decimal("1000"))
    return {
        "Date": _fmt_datetime(row.performed_at),
        "Workout Name": row.activity_type.replace("_", " ").title(),
        "Duration": _fmt_duration(row.duration_seconds),
        "Exercise Name": row.activity_type.replace("_", " ").title(),
        "Set Order": 1,
        "Weight": "",
        "Weight Unit": "",
        "Reps": "",
        "RPE": "" if row.rpe is None else f"{row.rpe:.1f}",
        "Distance": "" if km is None else f"{km:.3f}",
        "Distance Unit": "km" if km is not None else "",
        "Seconds": row.duration_seconds,
        "Notes": row.notes or "",
        "Workout Notes": "",
    }


def export_strong_csv(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
    user_unit: str = "lbs",
    *,
    include_strength: bool = True,
    include_cardio: bool = True,
) -> bytes:
    user_unit = user_unit.lower()
    if user_unit not in ("kg", "lbs"):
        user_unit = "lbs"

    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=STRONG_COLUMNS, extrasaction="ignore")
    writer.writeheader()

    if include_strength:
        for r in strength_rows:
            writer.writerow(_strength_row(r, user_unit))
    if include_cardio:
        for r in cardio_rows:
            writer.writerow(_cardio_row(r))

    return buf.getvalue().encode("utf-8")
