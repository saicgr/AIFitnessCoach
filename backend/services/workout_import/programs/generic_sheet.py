"""
Generic Google Sheets / XLSX template fallback.

Handles the catch-all shape common to free templates (Spreadsheet Point,
Bony to Beastly, "workout tracker" templates):

  * Row 1 has a dropdown for muscle group.
  * Columns: `Exercise | Set 1 | Set 2 | Set 3 | Set 4 | Notes` where each
    set cell contains `reps×weight` like "8×135" or "10x45kg".
  * OR wide layout: `Exercise | Target | Wk1 | Wk2 | ... | Wk12`.

We walk every sheet, locate the header row, and emit a single PrescribedDay
per tab. When a clear weeks-across layout is detected we emit multiple weeks.
"""
from __future__ import annotations

import re
from datetime import datetime, timezone
from typing import Optional, Tuple
from uuid import UUID

from core.logger import get_logger

from ..canonical import (
    ImportMode,
    ParseResult,
    PrescribedDay,
    PrescribedExercise,
    PrescribedSet,
    PrescribedWeek,
    RepTarget,
    SetType,
    WeightUnit,
)
from . import _shared as S
from ..format_detector import TemplateClassifier

logger = get_logger(__name__)


_RE_REPS_X_WEIGHT = re.compile(
    r"(\d{1,3})\s*[x×@]\s*(\d{1,4}(?:[.,]\d+)?)\s*(kg|lb|lbs)?",
    re.IGNORECASE,
)


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: ImportMode,
) -> ParseResult:
    try:
        wb = S.load_workbook_from_bytes(data)
    except Exception as e:
        logger.error(f"❌ [generic_sheet] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result(
            "generic_sheet", warnings=[f"could not open workbook: {e}"]
        )

    unit = S.normalize_unit_hint(unit_hint)
    weeks: list[PrescribedWeek] = []
    filled: list = []
    warnings: list[str] = []

    for sheet_idx, ws in enumerate(wb.worksheets):
        if any(k in ws.title.lower() for k in ("instruction", "readme", "settings")):
            continue
        week = _parse_tab(ws=ws, day_idx=sheet_idx + 1, unit=unit, filled=filled)
        if week is not None:
            weeks.append(week)

    if not weeks:
        return S.empty_parse_result(
            "generic_sheet",
            warnings=warnings + ["no parseable exercise rows in any tab"],
        )

    # Collapse weeks: if every "week" we built is actually day N of week 1,
    # merge them.
    merged_week = _merge_singleton_days(weeks)

    # Observe signals for TemplateClassifier so the caller's dispatcher can
    # decide history vs template if the detector punted.
    signals = S.collect_signals_from_workbook(wb, creator_needles=())
    score, _scores = TemplateClassifier.score(
        date_fill_ratio=signals.date_fill_ratio,
        weight_fill_ratio=signals.weight_fill_ratio,
        formula_density=signals.formula_density,
        has_protected_cells=signals.has_protected_cells,
        has_single_1rm_input=signals.has_single_1rm_input,
        tab_names_are_weeks=signals.tab_names_are_weeks,
        tab_names_are_dates=signals.tab_names_are_dates,
        has_copyright_header=signals.has_copyright_header,
    )
    classified_mode = TemplateClassifier.mode_from_score(score)

    days_per_week = max(len(w.days) for w in merged_week) if merged_week else 1
    template = S.build_template(
        user_id=user_id,
        source_app="generic_sheet",
        program_name="Custom Program",
        program_creator=None,
        total_weeks=len(merged_week),
        days_per_week=days_per_week,
        unit_hint=unit,
        weeks=merged_week,
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="Generic spreadsheet fallback adapter.",
    )

    strength_rows = []
    if filled:
        strength_rows = S.collect_filled_history_rows(
            user_id=user_id,
            source_app="generic_sheet_history",
            performed_at_fallback=datetime.now(tz=timezone.utc),
            template=template,
            filled_rows=filled,
        )

    # mode_hint respected when the detector already decided; otherwise let
    # the classifier pick.
    if mode_hint in (ImportMode.HISTORY, ImportMode.TEMPLATE,
                     ImportMode.PROGRAM_WITH_FILLED_HISTORY):
        mode = mode_hint
    elif classified_mode == ImportMode.HISTORY:
        mode = ImportMode.HISTORY
    elif strength_rows:
        mode = ImportMode.PROGRAM_WITH_FILLED_HISTORY
    else:
        mode = ImportMode.TEMPLATE

    return ParseResult(
        mode=mode,
        source_app="generic_sheet",
        template=template,
        strength_rows=strength_rows,
        warnings=warnings,
    )


def _parse_tab(
    *, ws, day_idx: int, unit: WeightUnit, filled: list,
) -> Optional[PrescribedWeek]:
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return None

    # Find the header row.
    header_idx: Optional[int] = None
    for i, row in enumerate(rows[:15]):
        lowered = [str(c).strip().lower() if c is not None else "" for c in row]
        if "exercise" in lowered:
            header_idx = i
            break
    if header_idx is None:
        return None

    header = [str(c).strip().lower() if c is not None else "" for c in rows[header_idx]]
    col_ex = header.index("exercise")

    # Detect "wide layout" with week columns.
    week_cols: dict[int, int] = {}
    for i, h in enumerate(header):
        m = re.search(r"(?:wk|week)\s*(\d+)", h, re.IGNORECASE)
        if m:
            week_cols[int(m.group(1))] = i

    # Detect "set columns" (Set 1 / Set 2 / ...).
    set_cols: list[int] = []
    for i, h in enumerate(header):
        if re.match(r"^\s*set\s*\d+\s*$", h):
            set_cols.append(i)

    day = PrescribedDay(day_number=day_idx, day_label=ws.title, exercises=[])

    if week_cols:
        return _parse_wide_layout(
            rows=rows, header_idx=header_idx, col_ex=col_ex,
            week_cols=week_cols, ws_title=ws.title, unit=unit, filled=filled,
        )

    # "Set 1..Set 4" layout: emit the day; each set cell contributes a
    # prescribed set with absolute weight.
    for row in rows[header_idx + 1 :]:
        name_cell = row[col_ex] if col_ex < len(row) else None
        if name_cell is None or not str(name_cell).strip():
            continue
        name = str(name_cell).strip()
        if name.lower() == "exercise":
            continue

        prescribed: list[PrescribedSet] = []
        for i, c in enumerate(set_cols):
            if c >= len(row):
                continue
            cell = row[c]
            reps, weight = _parse_reps_times_weight(cell, unit)
            if reps is None and weight is None:
                continue
            load_presc = (
                S.absolute_kg_prescription(weight)
                if weight is not None
                else S.unspecified_prescription()
            )
            prescribed.append(PrescribedSet(
                order=i,
                set_type=SetType.WORKING,
                rep_target=RepTarget(min=reps or 8, max=reps or 8),
                load_prescription=load_presc,
            ))
            if weight is not None and reps is not None:
                filled.append((name, weight, reps, i + 1, ws.title))

        if not prescribed:
            # Fallback: one working set with unspecified load.
            prescribed = [PrescribedSet(
                order=0, set_type=SetType.WORKING,
                rep_target=RepTarget(min=8, max=12),
                load_prescription=S.unspecified_prescription(),
            )]
        day.exercises.append(PrescribedExercise(
            order=len(day.exercises),
            exercise_name_raw=name,
            sets=prescribed,
        ))

    if not day.exercises:
        return None
    return PrescribedWeek(week_number=1, days=[day])


def _parse_wide_layout(
    *, rows, header_idx: int, col_ex: int, week_cols: dict[int, int],
    ws_title: str, unit: WeightUnit, filled: list,
) -> PrescribedWeek:
    """Return a single PrescribedWeek containing one day; per-week weight
    columns feed filled history."""
    day = PrescribedDay(day_number=1, day_label=ws_title, exercises=[])
    for row in rows[header_idx + 1 :]:
        name_cell = row[col_ex] if col_ex < len(row) else None
        if name_cell is None or not str(name_cell).strip():
            continue
        name = str(name_cell).strip()
        if name.lower() == "exercise":
            continue

        prescribed = [PrescribedSet(
            order=0,
            set_type=SetType.WORKING,
            rep_target=RepTarget(min=8, max=12),
            load_prescription=S.unspecified_prescription(),
        )]
        day.exercises.append(PrescribedExercise(
            order=len(day.exercises),
            exercise_name_raw=name,
            sets=prescribed,
        ))

        for wn, col in week_cols.items():
            if col >= len(row):
                continue
            weight_kg = S.parse_weight_cell(row[col], unit)
            if weight_kg is not None:
                filled.append((name, weight_kg, 8, 1, f"{ws_title} Wk{wn}"))
    return PrescribedWeek(week_number=1, days=[day])


def _parse_reps_times_weight(
    cell, unit: WeightUnit,
) -> Tuple[Optional[int], Optional[float]]:
    """Parse "8×135", "10 x 45kg", "8 @ 185" into (reps, weight_kg)."""
    if cell is None:
        return None, None
    if isinstance(cell, (int, float)):
        # Treat a bare number as weight only.
        return None, S.parse_weight_cell(cell, unit)
    s = str(cell).strip()
    if not s:
        return None, None
    m = _RE_REPS_X_WEIGHT.search(s)
    if m:
        reps = int(m.group(1))
        weight_raw = S.parse_eu_decimal(m.group(2))
        unit_tag = (m.group(3) or "").lower()
        if unit_tag in {"lb", "lbs"}:
            weight_kg = weight_raw * 0.45359237 if weight_raw else None
        elif unit_tag == "kg":
            weight_kg = weight_raw
        else:
            weight_kg = S.parse_weight_cell(m.group(2), unit)
        return reps, weight_kg
    # Fallback — try pure weight.
    return None, S.parse_weight_cell(s, unit)


def _merge_singleton_days(weeks: list[PrescribedWeek]) -> list[PrescribedWeek]:
    """Collapse `[Week(day1), Week(day2), ...]` into `[Week(day1, day2, ...)]`
    because multiple tabs are usually multiple days of the same program, not
    different weeks."""
    if not weeks:
        return weeks
    # Only merge if every week currently has exactly one day.
    if not all(len(w.days) == 1 for w in weeks):
        return weeks
    merged_days: list[PrescribedDay] = []
    for i, w in enumerate(weeks):
        day = w.days[0]
        day.day_number = i + 1
        merged_days.append(day)
    return [PrescribedWeek(week_number=1, days=merged_days)]
