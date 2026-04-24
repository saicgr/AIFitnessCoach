"""Fitbod CSV adapter.

Fitbod exports one row per set (tip-toe: its "multiplier" column lets a
single row represent N identical sets, so we still explode). Columns:

    Date, Exercise, Reps, Weight (kg), Duration (seconds), isWarmup,
    Note, multiplier

Quirks:

  * Header explicitly encodes ``kg`` — we don't need a unit prompt (edge #1
    inverse). Fallback to ``unit_hint`` if the column is named ``Weight``
    without a unit (older Fitbod exports).
  * ``isWarmup`` is the literal string ``"true"`` / ``"false"``.
  * ``multiplier`` > 1 means "this set was logged N times" — explode into N
    rows with sequential ``set_number`` (edge #19 cousin).
  * Cardio rows: Fitbod lumps cardio into the same sheet with ``Reps=0`` and
    a ``Duration (seconds)`` value. We silently skip them.
  * Date format ``"YYYY-MM-DD HH:MM:SS +ZZZZ"`` is reliable (edge #38).
"""
from __future__ import annotations

from datetime import timezone
from typing import Optional
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
    parse_weight_cell,
    to_kg,
)

SOURCE_APP = "fitbod"


def _bool_cell(raw: Optional[str]) -> bool:
    if raw is None:
        return False
    return str(raw).strip().lower() in {"true", "yes", "1", "y"}


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: Optional[ImportMode] = None,
) -> ParseResult:
    default_unit = WeightUnit.LB if (unit_hint or "").lower() == "lb" else WeightUnit.KG
    rows: list[CanonicalSetRow] = []
    warnings: list[str] = []

    # Fitbod columns may be either "Weight (kg)" or "Weight" depending on
    # export version; sniff it on the first row and stick with it.
    weight_col_kg = "Weight (kg)"
    weight_col_generic = "Weight"

    for raw_row in iter_csv_rows(data):
        if is_header_repeat(raw_row, ("Date", "Exercise", "Reps")):
            continue

        exercise_name = (raw_row.get("Exercise") or "").strip()
        if not exercise_name:
            continue

        performed_at = parse_datetime(raw_row.get("Date"), tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Date: {raw_row.get('Date')!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        if raw_row.get(weight_col_kg) is not None and raw_row.get(weight_col_kg) != "":
            value, unit = parse_weight_cell(raw_row[weight_col_kg], default_unit=WeightUnit.KG)
        else:
            value, unit = parse_weight_cell(
                raw_row.get(weight_col_generic), default_unit=default_unit,
            )
        weight_kg = to_kg(value, unit) if value is not None else None

        reps, is_amrap, _ = parse_reps_cell(raw_row.get("Reps"))
        duration_raw = (raw_row.get("Duration (seconds)") or raw_row.get("Duration") or "").strip()
        try:
            duration_seconds = int(float(duration_raw)) if duration_raw else None
        except ValueError:
            duration_seconds = None

        # Skip cardio-only rows.
        if reps is None and weight_kg is None and duration_seconds:
            continue
        if reps == 0 and weight_kg is None:
            continue

        is_warmup = _bool_cell(raw_row.get("isWarmup"))
        set_type = SetType.WARMUP if is_warmup else (SetType.AMRAP if is_amrap else SetType.WORKING)
        notes = (raw_row.get("Note") or raw_row.get("Notes") or "").strip() or None

        mult_raw = (raw_row.get("multiplier") or raw_row.get("Multiplier") or "1").strip()
        try:
            multiplier = max(1, int(float(mult_raw)))
        except ValueError:
            multiplier = 1

        canonical = exercise_name.lower()

        for i in range(multiplier):
            set_number = i + 1 if multiplier > 1 else None
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
                exercise_name_raw=exercise_name,
                exercise_name_canonical=canonical,
                set_number=set_number,
                set_type=set_type,
                weight_kg=weight_kg,
                original_weight_value=value,
                original_weight_unit=unit,
                reps=reps,
                duration_seconds=duration_seconds,
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
