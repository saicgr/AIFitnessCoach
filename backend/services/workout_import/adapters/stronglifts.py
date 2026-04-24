"""StrongLifts 5×5 adapter.

StrongLifts exports a per-workout-per-exercise row with the set-by-set reps
packed into a ``Sets & Reps`` column joined by ``/``:

    Workout Date, Workout Name, Exercise, Sets & Reps, Weight, Unit

    "5/5/5/5/3"     → 5 sets: 5, 5, 5, 5, 3 reps
    "5x5"           → 5 sets of 5 (older exports)
    "10/8/6+"       → 3 sets, last is AMRAP

Weight unit lives in a dedicated ``Unit`` column (``"kg"`` or ``"lb"``);
we honor it when present, fall back to ``unit_hint`` otherwise.
"""
from __future__ import annotations

import re
from datetime import timezone
from typing import List, Optional
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

SOURCE_APP = "stronglifts"


def _split_sets_reps(raw: str) -> List[str]:
    """Accepts ``5/5/5/5/3``, ``5x5``, ``5-5-5-5-3``, space-sep ``5 5 5``."""
    s = raw.strip()
    if not s:
        return []
    # "5x5" or "5×5" — N sets of M reps.
    m = re.match(r"^(\d+)\s*[x×]\s*(\d+(?:\+)?)$", s, re.IGNORECASE)
    if m:
        n = int(m.group(1))
        token = m.group(2)
        return [token] * n
    # Otherwise split on common separators.
    return [t for t in re.split(r"[/\-,\s]+", s) if t]


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
        if is_header_repeat(raw_row, ("Workout Date", "Exercise", "Sets & Reps")):
            continue

        exercise_name = (raw_row.get("Exercise") or "").strip()
        if not exercise_name:
            continue

        performed_at = parse_datetime(raw_row.get("Workout Date"), tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Workout Date: {raw_row.get('Workout Date')!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        unit_col = (raw_row.get("Unit") or raw_row.get("Weight Unit") or "").strip().lower()
        if unit_col == "kg":
            explicit_unit = WeightUnit.KG
        elif unit_col in ("lb", "lbs"):
            explicit_unit = WeightUnit.LB
        else:
            explicit_unit = default_unit

        value, unit = parse_weight_cell(raw_row.get("Weight"), default_unit=explicit_unit)
        weight_kg = to_kg(value, unit) if value is not None else None

        sets_reps_raw = (raw_row.get("Sets & Reps") or raw_row.get("Sets and Reps") or "").strip()
        tokens = _split_sets_reps(sets_reps_raw)
        if not tokens:
            continue

        workout_name = (raw_row.get("Workout Name") or "").strip() or None
        notes = (raw_row.get("Notes") or raw_row.get("Note") or "").strip() or None

        canonical = exercise_name.lower()

        for i, token in enumerate(tokens, start=1):
            reps, is_amrap, _ = parse_reps_cell(token)
            if reps is None:
                warnings.append(f"unparseable rep token: {token!r}")
                continue
            if reps == 0 and weight_kg is None:
                continue

            row_hash = CanonicalSetRow.compute_row_hash(
                user_id=user_id,
                source_app=SOURCE_APP,
                performed_at=performed_at,
                exercise_name_canonical=canonical,
                set_number=i,
                weight_kg=weight_kg,
                reps=reps,
            )
            rows.append(CanonicalSetRow(
                user_id=user_id,
                performed_at=performed_at,
                workout_name=workout_name,
                exercise_name_raw=exercise_name,
                exercise_name_canonical=canonical,
                set_number=i,
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
