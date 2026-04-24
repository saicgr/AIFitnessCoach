"""FitNotes CSV adapter.

FitNotes is the only export in the wild that populates **both**
``Weight (kg)`` and ``Weight (lbs)`` columns on every row (edge case #2).
We prefer kg, but cross-check it against lbs and warn if the two disagree
by more than 0.1 kg post-conversion — a drift that big almost always means
the user hand-edited the CSV.

Full column set:

    Date, Exercise, Category, Weight (kg), Weight (lbs), Reps,
    Distance, Distance Unit, Time, Comment

Quirks:

  * ``Distance Unit`` enum is unique to FitNotes (km | mi | m | y).
  * Cardio rows use Distance + Time with zero Weight/Reps — skipped here,
    cardio adapter owns them.
  * ``Time`` cell is `HH:MM:SS` — parsed as duration seconds.
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

SOURCE_APP = "fitnotes"


def _parse_hms(raw: Optional[str]) -> Optional[int]:
    if not raw:
        return None
    parts = str(raw).strip().split(":")
    try:
        nums = [int(p) for p in parts]
    except ValueError:
        return None
    if len(nums) == 3:
        return nums[0] * 3600 + nums[1] * 60 + nums[2]
    if len(nums) == 2:
        return nums[0] * 60 + nums[1]
    if len(nums) == 1:
        return nums[0]
    return None


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: Optional[ImportMode] = None,
) -> ParseResult:
    rows: list[CanonicalSetRow] = []
    warnings: list[str] = []

    for raw_row in iter_csv_rows(data):
        if is_header_repeat(raw_row, ("Date", "Exercise", "Weight (kg)")):
            continue

        exercise_name = (raw_row.get("Exercise") or "").strip()
        if not exercise_name:
            continue

        performed_at = parse_datetime(raw_row.get("Date"), tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Date: {raw_row.get('Date')!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        kg_cell = raw_row.get("Weight (kg)") or raw_row.get("Weight(kg)")
        lb_cell = raw_row.get("Weight (lbs)") or raw_row.get("Weight(lbs)")

        kg_value, _ = parse_weight_cell(kg_cell, default_unit=WeightUnit.KG)
        lb_value, _ = parse_weight_cell(lb_cell, default_unit=WeightUnit.LB)

        # Prefer kg when present; cross-check against lb.
        if kg_value is not None:
            weight_kg = kg_value
            original_value = kg_value
            original_unit = WeightUnit.KG
            if lb_value is not None:
                converted_from_lb = to_kg(lb_value, WeightUnit.LB) or 0.0
                if abs(converted_from_lb - weight_kg) > 0.1:
                    warnings.append(
                        f"{exercise_name}: kg/lb columns disagree "
                        f"({weight_kg:.2f}kg vs {converted_from_lb:.2f}kg)"
                    )
        elif lb_value is not None:
            weight_kg = to_kg(lb_value, WeightUnit.LB)
            original_value = lb_value
            original_unit = WeightUnit.LB
        else:
            weight_kg = None
            original_value = None
            original_unit = None

        reps, is_amrap, _ = parse_reps_cell(raw_row.get("Reps"))

        # Cardio row — has distance/time, no reps/weight. Skip.
        duration_seconds = _parse_hms(raw_row.get("Time"))
        if reps is None and weight_kg is None:
            if duration_seconds:
                continue  # cardio adapter owns this
            continue

        notes = (raw_row.get("Comment") or raw_row.get("Note") or "").strip() or None

        canonical = exercise_name.lower()
        row_hash = CanonicalSetRow.compute_row_hash(
            user_id=user_id,
            source_app=SOURCE_APP,
            performed_at=performed_at,
            exercise_name_canonical=canonical,
            set_number=None,
            weight_kg=weight_kg,
            reps=reps,
        )
        rows.append(CanonicalSetRow(
            user_id=user_id,
            performed_at=performed_at,
            exercise_name_raw=exercise_name,
            exercise_name_canonical=canonical,
            set_type=SetType.AMRAP if is_amrap else SetType.WORKING,
            weight_kg=weight_kg,
            original_weight_value=original_value,
            original_weight_unit=original_unit,
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
