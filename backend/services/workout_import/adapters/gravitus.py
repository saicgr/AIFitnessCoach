"""Gravitus (and other loose "Date / Exercise Name / Weight / Reps / Set"
CSV) adapter.

Gravitus doesn't publish a public schema — the export columns vary slightly
between app versions. We match against the common shape:

    Date, Exercise Name, Weight, Reps, Set, [Notes], [RPE]

Unit not encoded → ``unit_hint`` from caller (edge #1).
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
    parse_rpe,
    parse_weight_cell,
    to_kg,
)

SOURCE_APP = "gravitus"


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

    for raw_row in iter_csv_rows(data):
        if is_header_repeat(raw_row, ("Date", "Exercise Name", "Weight", "Reps")):
            continue

        exercise_name = (raw_row.get("Exercise Name") or raw_row.get("Exercise") or "").strip()
        if not exercise_name:
            continue

        performed_at = parse_datetime(raw_row.get("Date"), tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Date: {raw_row.get('Date')!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        value, unit = parse_weight_cell(raw_row.get("Weight"), default_unit=default_unit)
        weight_kg = to_kg(value, unit) if value is not None else None
        reps, is_amrap, _ = parse_reps_cell(raw_row.get("Reps"))
        if reps is None and weight_kg is None:
            continue

        set_raw = (raw_row.get("Set") or raw_row.get("Set Number") or "").strip()
        try:
            set_number: Optional[int] = int(float(set_raw)) if set_raw else None
        except ValueError:
            set_number = None

        rpe = parse_rpe(raw_row.get("RPE"))
        notes = (raw_row.get("Notes") or raw_row.get("Note") or "").strip() or None

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
            exercise_name_raw=exercise_name,
            exercise_name_canonical=canonical,
            set_number=set_number,
            set_type=SetType.AMRAP if is_amrap else SetType.WORKING,
            weight_kg=weight_kg,
            original_weight_value=value,
            original_weight_unit=unit,
            reps=reps,
            rpe=rpe,
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
