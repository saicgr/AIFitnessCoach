"""MyFitnessPal Exercise-Log CSV adapter.

MFP emails a ZIP on "Request Data" with summary rows, NOT per-set rows:

    Date, Exercise Name, Reps/Set, Sets, Weight/Set, Weight Unit,
    Exercise Calories

To get per-set data we "explode" each row into ``Sets`` identical rows
(edge case in universal-gotchas list). ``Weight Unit`` is usually ``"lbs"``
or ``"kg"`` verbatim; if absent we fall back to ``unit_hint``.
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

SOURCE_APP = "myfitnesspal"


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
        if is_header_repeat(raw_row, ("Date", "Exercise Name", "Reps/Set", "Sets")):
            continue

        exercise_name = (raw_row.get("Exercise Name") or "").strip()
        if not exercise_name:
            continue

        performed_at = parse_datetime(raw_row.get("Date"), tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Date: {raw_row.get('Date')!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        reps, is_amrap, _ = parse_reps_cell(raw_row.get("Reps/Set"))

        # Sets count drives the explosion.
        sets_raw = (raw_row.get("Sets") or "1").strip()
        try:
            sets_count = max(1, int(float(sets_raw)))
        except ValueError:
            sets_count = 1

        weight_col = raw_row.get("Weight/Set") or raw_row.get("Weight")
        unit_col = (raw_row.get("Weight Unit") or "").strip().lower()
        if unit_col == "kg":
            explicit_unit = WeightUnit.KG
        elif unit_col in ("lb", "lbs", "lb/set"):
            explicit_unit = WeightUnit.LB
        else:
            explicit_unit = default_unit

        value, unit = parse_weight_cell(weight_col, default_unit=explicit_unit)
        weight_kg = to_kg(value, unit) if value is not None else None

        if reps is None and weight_kg is None:
            continue

        notes = (raw_row.get("Notes") or raw_row.get("Note") or "").strip() or None

        canonical = exercise_name.lower()

        for i in range(sets_count):
            set_number = i + 1
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
