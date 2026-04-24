"""Strong (strong.app) CSV adapter.

Strong's export columns:

    Date, Workout Name, Exercise Name, Set Order, Weight, Reps,
    Distance, Seconds, Notes, Workout Notes, RPE, Duration

Quirks:

  * Strong does **not** encode the weight unit anywhere in the file — it
    matches the user's in-app setting. The caller's ``unit_hint`` is
    authoritative (edges #1 + #37).
  * Dates are ``YYYY-MM-DD HH:MM:SS`` (no timezone) — we attach ``tz_hint``.
  * ``Set Order`` is 1-based and **repeats** for drop-set chains (edge #4 in
    the universal-gotchas list), so we do NOT dedupe on ``(date, exercise,
    set_order)``.
  * ``Duration`` is a free-form string like ``"1h 12m"`` or ``"58s"``;
    cardio rows set ``Distance`` + ``Seconds`` instead of ``Weight`` +
    ``Reps`` — we silently skip those (edge #29 rest-day blanks too).
  * Rest-day exports sometimes appear as blank exercise rows — skipped.
"""
from __future__ import annotations

import re
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

SOURCE_APP = "strong"

_DURATION_RE = re.compile(r"(\d+)\s*(h|hr|hour|m|min|s|sec)", re.IGNORECASE)


def _parse_duration_string(raw: Optional[str]) -> Optional[int]:
    """Convert Strong's ``"1h 12m 30s"`` into seconds (edge #37)."""
    if not raw:
        return None
    s = str(raw).strip()
    if not s:
        return None
    total = 0
    for qty, unit in _DURATION_RE.findall(s):
        q = int(qty)
        u = unit[0].lower()
        if u == "h":
            total += q * 3600
        elif u == "m":
            total += q * 60
        elif u == "s":
            total += q
    return total or None


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
    header_cols = ("Date", "Exercise Name", "Set Order")

    for raw_row in iter_csv_rows(data):
        if is_header_repeat(raw_row, header_cols):
            continue

        exercise_name = (raw_row.get("Exercise Name") or "").strip()
        if not exercise_name:
            continue  # rest-day blank row

        weight_cell = raw_row.get("Weight")
        reps_cell = raw_row.get("Reps")
        if not weight_cell and not reps_cell:
            # Cardio-only or empty row; cardio adapter owns those.
            continue

        performed_at = parse_datetime(raw_row.get("Date"), tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Date: {raw_row.get('Date')!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        value, unit = parse_weight_cell(weight_cell, default_unit=default_unit)
        weight_kg = to_kg(value, unit) if value is not None else None

        reps, is_amrap, _ = parse_reps_cell(reps_cell)
        if reps is None and weight_kg is None:
            continue

        set_order_raw = (raw_row.get("Set Order") or "").strip()
        try:
            set_number: Optional[int] = int(float(set_order_raw)) if set_order_raw else None
        except ValueError:
            set_number = None

        workout_name = (raw_row.get("Workout Name") or "").strip() or None
        notes_parts = [
            (raw_row.get("Notes") or "").strip(),
            (raw_row.get("Workout Notes") or "").strip(),
        ]
        notes = " | ".join(p for p in notes_parts if p) or None

        rpe = parse_rpe(raw_row.get("RPE"))
        duration_seconds = _parse_duration_string(raw_row.get("Duration"))
        if duration_seconds is None:
            # Fitness of Seconds col (cardio) — skip for strength.
            seconds_cell = (raw_row.get("Seconds") or "").strip()
            if seconds_cell.isdigit():
                duration_seconds = int(seconds_cell) or None

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
            set_type=SetType.AMRAP if is_amrap else SetType.WORKING,
            weight_kg=weight_kg,
            original_weight_value=value,
            original_weight_unit=unit,
            reps=reps,
            duration_seconds=duration_seconds,
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
