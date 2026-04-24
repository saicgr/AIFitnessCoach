"""Jefit adapter — CSV or XLSX with a **packed** logs column.

Jefit uses a single ``logs`` cell per exercise per session like:

    "45x10,55x8,60x6"        ← per-set, comma-separated
    "45 x 10, 55 x 8"         ← spaces variant
    "45x10;55x8;60x6"         ← some exports use semicolons
    "45kg x 10, 55kg x 8"     ← older exports suffix the unit

Unit is NOT encoded in the header — caller's ``unit_hint`` decides (edge #1).

XLSX exports are handled via pandas → DataFrame → each row becomes a dict
for the same per-set explosion loop.
"""
from __future__ import annotations

import io
import re
from datetime import timezone
from typing import Iterable, List, Optional
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

SOURCE_APP = "jefit"

# Accepts "45x10", "45 x 10", "45kg x 10", "45 lbs x 10", "45×10"
_SET_RE = re.compile(
    r"^\s*(?P<weight>-?\d+(?:[.,]\d+)?)\s*(?P<unit>kg|lbs?|)\s*[x×]\s*(?P<reps>\d+(?:\+)?)\s*$",
    re.IGNORECASE,
)


def _iter_rows(data: bytes, filename: str) -> Iterable[dict]:
    """Yield dict-rows from CSV or XLSX."""
    lower = filename.lower()
    if lower.endswith(".xlsx") or lower.endswith(".xlsm") or lower.endswith(".xls"):
        try:
            import pandas as pd
        except ImportError:
            return
        df = pd.read_excel(io.BytesIO(data))
        for rec in df.to_dict(orient="records"):
            yield {str(k): ("" if v is None else str(v)) for k, v in rec.items()}
        return
    # Default: CSV.
    yield from iter_csv_rows(data)


def _split_logs_cell(raw: str) -> List[str]:
    """Split ``"45x10,55x8,60x6"`` into the individual ``WxR`` tokens.
    Accepts comma, semicolon, or pipe as separator (edge case: exports vary
    by region)."""
    # Normalize all separators to comma.
    s = raw.replace(";", ",").replace("|", ",")
    return [part.strip() for part in s.split(",") if part.strip()]


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
    header_cols = ("Date", "Exercise", "logs")

    for raw_row in _iter_rows(data, filename):
        if is_header_repeat(raw_row, header_cols):
            continue

        exercise_name = (raw_row.get("Exercise") or raw_row.get("exercise") or "").strip()
        if not exercise_name:
            continue

        logs_cell = (raw_row.get("logs") or raw_row.get("Logs") or "").strip()
        if not logs_cell:
            continue

        date_raw = (raw_row.get("Date") or raw_row.get("date") or "").strip()
        performed_at = parse_datetime(date_raw, tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Date: {date_raw!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        workout_name = (raw_row.get("Workout") or raw_row.get("Routine") or "").strip() or None
        notes = (raw_row.get("Notes") or raw_row.get("Note") or "").strip() or None

        tokens = _split_logs_cell(logs_cell)
        canonical = exercise_name.lower()

        for idx, token in enumerate(tokens, start=1):
            m = _SET_RE.match(token)
            if not m:
                warnings.append(f"unparseable set token: {token!r}")
                continue

            explicit_unit = (m.group("unit") or "").lower()
            unit: Optional[WeightUnit]
            if explicit_unit in ("kg",):
                unit = WeightUnit.KG
            elif explicit_unit in ("lb", "lbs"):
                unit = WeightUnit.LB
            else:
                unit = default_unit

            value, _ = parse_weight_cell(m.group("weight"), default_unit=unit)
            reps, is_amrap, _ = parse_reps_cell(m.group("reps"))
            if reps is None and value is None:
                continue

            weight_kg = to_kg(value, unit) if value is not None else None

            row_hash = CanonicalSetRow.compute_row_hash(
                user_id=user_id,
                source_app=SOURCE_APP,
                performed_at=performed_at,
                exercise_name_canonical=canonical,
                set_number=idx,
                weight_kg=weight_kg,
                reps=reps,
            )
            rows.append(CanonicalSetRow(
                user_id=user_id,
                performed_at=performed_at,
                workout_name=workout_name,
                exercise_name_raw=exercise_name,
                exercise_name_canonical=canonical,
                set_number=idx,
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
