"""Generic CSV fallback adapter.

When the format detector can't fingerprint a CSV against a known app, we
still give it a best-effort pass here. Strategy:

  1. Normalize header names (lowercase + strip punctuation).
  2. Fuzzy-match against known synonyms for each canonical field:
       date      ← "date", "timestamp", "workout_date", "performed_on"
       exercise  ← "exercise", "exercise_name", "movement", "lift"
       weight    ← "weight", "weight_kg", "weight_lbs", "load", "kg", "lbs"
       reps      ← "reps", "repetitions", "reps_done", "r"
       sets      ← "sets", "set_count" (→ explode if >1 and no per-set row)
       set_num   ← "set", "set_number", "set_order", "set_index"
  3. If the weight column explicitly encodes unit in its name ("weight_kg"
     / "weight (lbs)"), honor that; else default to ``unit_hint``.

Rows that can't even be assigned a date + exercise are skipped with a
warning.
"""
from __future__ import annotations

import re
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

SOURCE_APP = "generic_csv"

_DATE_CANDIDATES = (
    "date", "workout_date", "performed_at", "performed_on", "timestamp",
    "start_time", "date_time", "day", "time",
)
_EXERCISE_CANDIDATES = (
    "exercise", "exercise_name", "exercise_title", "movement", "lift", "name",
)
_WEIGHT_CANDIDATES = (
    "weight_kg", "weight(kg)", "weight kg",
    "weight_lbs", "weight(lbs)", "weight lbs", "weight(lb)", "weight_lb",
    "weight", "load", "kg", "lbs", "lb",
)
_REPS_CANDIDATES = (
    "reps", "repetitions", "reps_done", "rep_count", "r",
)
_SET_NUM_CANDIDATES = (
    "set_number", "set_order", "set_index", "set", "set #", "set_no",
)
_SETS_CANDIDATES = (
    "sets", "set_count", "num_sets",
)
_NOTES_CANDIDATES = (
    "notes", "note", "comment", "comments",
)
_RPE_CANDIDATES = (
    "rpe", "rpe_rating",
)


def _normalize(key: str) -> str:
    return re.sub(r"[^a-z0-9 _()]", "", key.strip().lower())


def _find_column(headers_normalized: Dict[str, str], candidates: tuple) -> Optional[str]:
    """Return the original header whose normalized form matches any candidate."""
    for cand in candidates:
        norm = _normalize(cand)
        for normalized, original in headers_normalized.items():
            if normalized == norm:
                return original
            # Also allow "workout date" == "workoutdate".
            if normalized.replace(" ", "") == norm.replace(" ", ""):
                return original
    return None


def _infer_unit_from_col(colname: str, default: WeightUnit) -> WeightUnit:
    lower = colname.lower()
    if "kg" in lower:
        return WeightUnit.KG
    if "lb" in lower:
        return WeightUnit.LB
    return default


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

    first_row: Optional[dict] = None
    rows_iter = iter_csv_rows(data)
    for candidate in rows_iter:
        if any(v for v in candidate.values()):
            first_row = candidate
            break
    if first_row is None:
        return ParseResult(mode=ImportMode.HISTORY, source_app=SOURCE_APP, warnings=["empty CSV"])

    headers_normalized = {_normalize(k): k for k in first_row.keys() if isinstance(k, str)}
    date_col = _find_column(headers_normalized, _DATE_CANDIDATES)
    ex_col = _find_column(headers_normalized, _EXERCISE_CANDIDATES)
    wt_col = _find_column(headers_normalized, _WEIGHT_CANDIDATES)
    reps_col = _find_column(headers_normalized, _REPS_CANDIDATES)
    set_num_col = _find_column(headers_normalized, _SET_NUM_CANDIDATES)
    sets_col = _find_column(headers_normalized, _SETS_CANDIDATES)
    notes_col = _find_column(headers_normalized, _NOTES_CANDIDATES)
    rpe_col = _find_column(headers_normalized, _RPE_CANDIDATES)

    if not (date_col and ex_col):
        warnings.append(
            f"Could not infer Date/Exercise columns from headers: {list(first_row.keys())[:10]}"
        )
        return ParseResult(mode=ImportMode.HISTORY, source_app=SOURCE_APP, warnings=warnings)

    # Yield first_row back into the main loop.
    def _rows():
        yield first_row
        yield from rows_iter

    for raw_row in _rows():
        if is_header_repeat(raw_row, (date_col, ex_col)):
            continue

        exercise_name = (raw_row.get(ex_col) or "").strip()
        if not exercise_name:
            continue

        performed_at = parse_datetime(raw_row.get(date_col), tz_hint)
        if performed_at is None:
            warnings.append(f"unparseable Date: {raw_row.get(date_col)!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        explicit_unit = _infer_unit_from_col(wt_col, default_unit) if wt_col else default_unit
        value, unit = parse_weight_cell(
            raw_row.get(wt_col) if wt_col else None, default_unit=explicit_unit,
        )
        weight_kg = to_kg(value, unit) if value is not None else None

        reps, is_amrap, _ = parse_reps_cell(raw_row.get(reps_col) if reps_col else None)
        if reps is None and weight_kg is None:
            continue

        # set_number — prefer explicit col; else explode on sets column.
        set_number: Optional[int] = None
        sets_to_explode = 1
        if set_num_col:
            raw_sn = (raw_row.get(set_num_col) or "").strip()
            try:
                set_number = int(float(raw_sn)) if raw_sn else None
            except ValueError:
                set_number = None
        elif sets_col:
            raw_sets = (raw_row.get(sets_col) or "1").strip()
            try:
                sets_to_explode = max(1, int(float(raw_sets)))
            except ValueError:
                sets_to_explode = 1

        rpe = parse_rpe(raw_row.get(rpe_col)) if rpe_col else None
        notes = (raw_row.get(notes_col) or "").strip() if notes_col else None
        if notes == "":
            notes = None

        canonical = exercise_name.lower()

        for i in range(sets_to_explode):
            sn = set_number if sets_to_explode == 1 else (i + 1)
            row_hash = CanonicalSetRow.compute_row_hash(
                user_id=user_id,
                source_app=SOURCE_APP,
                performed_at=performed_at,
                exercise_name_canonical=canonical,
                set_number=sn,
                weight_kg=weight_kg,
                reps=reps,
            )
            rows.append(CanonicalSetRow(
                user_id=user_id,
                performed_at=performed_at,
                exercise_name_raw=exercise_name,
                exercise_name_canonical=canonical,
                set_number=sn,
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
