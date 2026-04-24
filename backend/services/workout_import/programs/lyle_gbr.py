"""
Lyle McDonald Generic Bulking Routine — Lift Vault community .xlsx.

4-day Upper/Lower, 12-week volume tracker. Wide layout:
  Exercise | Sets | Reps | Weight Wk1 | Weight Wk2 | ... | Weight Wk12

We read the whole sheet, one row per exercise, and emit 12 weeks × 2-4 days
from the tab layout. User-fill weight cells become filled history if any
are numeric (a common re-shared "Copy of Copy of" pattern).
"""
from __future__ import annotations

import re
from datetime import datetime, timezone
from typing import Optional
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

logger = get_logger(__name__)


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
        logger.error(f"❌ [lyle_gbr] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result("lyle_gbr", warnings=[f"could not open: {e}"])

    unit = S.normalize_unit_hint(unit_hint)
    weeks_by_number: dict[int, dict[int, PrescribedDay]] = {}
    filled: list = []
    warnings: list[str] = []

    # Each tab = one workout day (Upper A / Lower A / Upper B / Lower B or
    # "Day 1" / "Day 2" etc).
    for day_idx, ws in enumerate(wb.worksheets, start=1):
        if any(k in ws.title.lower() for k in ("read", "instruct", "settings")):
            continue
        _parse_day_tab(
            ws=ws, day_number=day_idx, weeks_by_number=weeks_by_number,
            filled=filled, unit=unit,
        )

    if not weeks_by_number:
        return S.empty_parse_result("lyle_gbr", warnings=warnings + ["no rows parsed"])

    weeks: list[PrescribedWeek] = []
    for wn in sorted(weeks_by_number):
        days_map = weeks_by_number[wn]
        days = [days_map[dn] for dn in sorted(days_map)]
        weeks.append(PrescribedWeek(week_number=wn, days=days))
    days_per_week = max(len(w.days) for w in weeks)

    template = S.build_template(
        user_id=user_id,
        source_app="lyle_gbr",
        program_name="Generic Bulking Routine",
        program_creator="Lyle McDonald",
        total_weeks=len(weeks),
        days_per_week=days_per_week,
        unit_hint=unit,
        weeks=weeks,
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="Lyle GBR — 4-day Upper/Lower, 12 weeks. Absolute weights per "
              "week; user fills progressively.",
    )

    strength_rows = []
    if filled:
        strength_rows = S.collect_filled_history_rows(
            user_id=user_id,
            source_app="lyle_gbr_history",
            performed_at_fallback=datetime.now(tz=timezone.utc),
            template=template,
            filled_rows=filled,
        )

    return ParseResult(
        mode=(ImportMode.PROGRAM_WITH_FILLED_HISTORY if strength_rows
              else ImportMode.TEMPLATE),
        source_app="lyle_gbr",
        template=template,
        strength_rows=strength_rows,
    )


def _parse_day_tab(
    *, ws, day_number: int,
    weeks_by_number: dict[int, dict[int, PrescribedDay]],
    filled: list,
    unit: WeightUnit,
) -> None:
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return

    header_idx: Optional[int] = None
    for i, row in enumerate(rows[:10]):
        lowered = [str(c).strip().lower() if c is not None else "" for c in row]
        if "exercise" in lowered:
            header_idx = i
            break
    if header_idx is None:
        return

    header = [str(c).strip().lower() if c is not None else "" for c in rows[header_idx]]
    col_ex = header.index("exercise") if "exercise" in header else None
    col_sets = header.index("sets") if "sets" in header else None
    col_reps = header.index("reps") if "reps" in header else None
    # Identify per-week weight columns.
    week_cols: dict[int, int] = {}
    for i, h in enumerate(header):
        m = re.search(r"wk\s*(\d+)|week\s*(\d+)", h, re.IGNORECASE)
        if m:
            wn = int(m.group(1) or m.group(2))
            week_cols[wn] = i

    if col_ex is None or not week_cols:
        return

    for row in rows[header_idx + 1 :]:
        name_cell = row[col_ex] if col_ex is not None else None
        if name_cell is None or not str(name_cell).strip():
            continue
        name = str(name_cell).strip()
        if name.lower() == "exercise":
            continue

        sets_count = S.safe_int(row[col_sets]) if col_sets is not None else 3
        sets_count = sets_count or 3
        rep_target, amrap_last = S.parse_rep_target(
            row[col_reps] if col_reps is not None else None
        )
        rep_target = rep_target or RepTarget(min=8, max=10)

        for wn, col in week_cols.items():
            if col >= len(row):
                continue
            weight_kg = S.parse_weight_cell(row[col], unit)
            load_presc = (
                S.absolute_kg_prescription(weight_kg)
                if weight_kg is not None
                else S.unspecified_prescription()
            )
            prescribed = [
                PrescribedSet(
                    order=i,
                    set_type=SetType.AMRAP if (amrap_last and i == sets_count - 1)
                              else SetType.WORKING,
                    rep_target=rep_target,
                    load_prescription=load_presc,
                )
                for i in range(sets_count)
            ]
            # Find or create the day entry for this week.
            wk_map = weeks_by_number.setdefault(wn, {})
            day = wk_map.setdefault(
                day_number,
                PrescribedDay(day_number=day_number, day_label=ws.title, exercises=[]),
            )
            day.exercises.append(PrescribedExercise(
                order=len(day.exercises),
                exercise_name_raw=name,
                sets=prescribed,
            ))

            if weight_kg is not None:
                filled.append((name, weight_kg, rep_target.min,
                               1, f"{ws.title} — Wk {wn}"))
