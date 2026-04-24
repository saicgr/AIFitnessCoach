"""Hevy CSV adapter.

Hevy exports one row per set. The canonical column names (as of Hevy v6+):

    Title, Start Time, End Time, Description, Exercise Title,
    Superset ID, Exercise Notes, Set Index, Set Type, Weight (kg),
    Weight (lbs), Reps, Distance (meters), Duration (seconds), RPE

Notable Hevy quirks (edge cases in the plan):

  * ``Set Index`` is 0-based (we bump to 1-based for canonical ``set_number``).
  * ``Set Type`` is one of ``normal | warmup | failure | dropset``.
  * ``Weight (kg)`` and ``Weight (lbs)`` are both populated by the app. Hevy
    converts in-app from the user's display unit, so the two are redundant;
    we honor the user's ``unit_hint`` / profile unit to pick which to trust.
  * ``Superset ID`` is a string UUID-ish token when the exercise is part of a
    superset; blank otherwise (edge #25).
  * Date format: ``"28 Mar 2025, 17:29"`` (edge #36) — dateparser handles it.
  * Cardio rows (running, cycling) show up with Distance/Duration and no
    weight/reps; we silently skip them (cardio adapters own those rows).
"""
from __future__ import annotations

from datetime import timezone
from typing import Dict, Optional
from uuid import UUID

from ..canonical import (
    CanonicalSetRow,
    ImportMode,
    ParseResult,
    SetType,
    WeightUnit,
)
from ._common import (
    iter_csv_rows,
    is_header_repeat,
    parse_datetime,
    parse_reps_cell,
    parse_rpe,
    parse_weight_cell,
    to_kg,
)


SOURCE_APP = "hevy"

_SET_TYPE_MAP: Dict[str, SetType] = {
    "normal": SetType.WORKING,
    "warmup": SetType.WARMUP,
    "warm up": SetType.WARMUP,
    "warm-up": SetType.WARMUP,
    "failure": SetType.FAILURE,
    "dropset": SetType.DROPSET,
    "drop set": SetType.DROPSET,
    "amrap": SetType.AMRAP,
}


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: Optional[ImportMode] = None,
) -> ParseResult:
    unit_pref = WeightUnit.LB if (unit_hint or "").lower() == "lb" else WeightUnit.KG
    rows: list[CanonicalSetRow] = []
    warnings: list[str] = []
    header_cols = ("Title", "Exercise Title", "Set Index")

    for raw_row in iter_csv_rows(data):
        if is_header_repeat(raw_row, header_cols):
            continue

        exercise_name = (raw_row.get("Exercise Title") or "").strip()
        if not exercise_name:
            continue

        # Skip cardio rows — distance-only, no weight/reps.
        weight_kg_cell = raw_row.get("Weight (kg)") or raw_row.get("Weight_kg")
        weight_lb_cell = raw_row.get("Weight (lbs)") or raw_row.get("Weight_lbs")
        reps_cell = raw_row.get("Reps")
        distance_cell = raw_row.get("Distance (meters)") or raw_row.get("Distance")
        if not (weight_kg_cell or weight_lb_cell) and not reps_cell and distance_cell:
            continue

        performed_at = parse_datetime(raw_row.get("Start Time"), tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Start Time: {raw_row.get('Start Time')!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        # Hevy encodes BOTH units in the header — prefer the user-hint column.
        if unit_pref == WeightUnit.KG and weight_kg_cell is not None:
            value, unit = parse_weight_cell(weight_kg_cell, default_unit=WeightUnit.KG)
        elif weight_lb_cell is not None:
            value, unit = parse_weight_cell(weight_lb_cell, default_unit=WeightUnit.LB)
        elif weight_kg_cell is not None:
            value, unit = parse_weight_cell(weight_kg_cell, default_unit=WeightUnit.KG)
        else:
            value, unit = None, None

        weight_kg = to_kg(value, unit) if value is not None else None

        reps, is_amrap, _ = parse_reps_cell(reps_cell)
        if reps is None and weight_kg is None:
            # nothing to record
            continue

        set_index_raw = (raw_row.get("Set Index") or "").strip()
        try:
            set_number: Optional[int] = int(float(set_index_raw)) + 1 if set_index_raw else None
        except ValueError:
            set_number = None

        set_type_str = (raw_row.get("Set Type") or "normal").strip().lower()
        set_type = _SET_TYPE_MAP.get(set_type_str, SetType.WORKING)
        if is_amrap and set_type == SetType.WORKING:
            set_type = SetType.AMRAP

        superset_id = (raw_row.get("Superset ID") or "").strip() or None

        workout_name = (raw_row.get("Title") or "").strip() or None
        notes_parts = [
            (raw_row.get("Exercise Notes") or "").strip(),
            (raw_row.get("Description") or "").strip(),
        ]
        notes = " | ".join(p for p in notes_parts if p) or None

        rpe = parse_rpe(raw_row.get("RPE"))
        duration_raw = (raw_row.get("Duration (seconds)") or "").strip()
        try:
            duration_seconds = int(float(duration_raw)) if duration_raw else None
        except ValueError:
            duration_seconds = None

        canonical = exercise_name.lower()
        row_hash = CanonicalSetRow.compute_row_hash(
            user_id=user_id,
            source_app=SOURCE_APP,
            performed_at=performed_at,
            exercise_name_canonical=canonical,
            set_number=set_number,
            weight_kg=weight_kg,
            reps=reps,
        )

        rows.append(CanonicalSetRow(
            user_id=user_id,
            performed_at=performed_at,
            workout_name=workout_name,
            exercise_name_raw=exercise_name,
            exercise_name_canonical=canonical,
            set_number=set_number,
            set_type=set_type,
            weight_kg=weight_kg,
            original_weight_value=value,
            original_weight_unit=unit,
            reps=reps,
            duration_seconds=duration_seconds,
            rpe=rpe,
            superset_id=superset_id,
            notes=notes,
            source_app=SOURCE_APP,
            source_row_hash=row_hash,
        ))

    preview = [r.model_dump(mode="json") for r in rows[:20]]

    return ParseResult(
        mode=ImportMode.HISTORY,
        source_app=SOURCE_APP,
        strength_rows=rows,
        warnings=warnings,
        sample_rows_for_preview=preview,
    )
