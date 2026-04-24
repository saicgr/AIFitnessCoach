"""
Metallicadpa PPL — reddit.com/u/metallicadpa. Google Sheet template with:

  * 12-week horizontal layout (one sheet, weeks 1-12 across columns).
  * Per-lift intensity selector (user adjusts coefficient → all downstream
    weights recompute via formula).
  * Compound rep scheme `5/5+` (4 fixed + AMRAP last set).
  * Columns: `Exercise | Sets | Reps | Weight (calc) | Reps Done | Actual Weight`.

When `Reps Done` and `Actual Weight` are populated we emit those as filled
history — a re-shared "Copy of Copy of" sheet where a previous user's numbers
are baked in is caught by this same path.
"""
from __future__ import annotations

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
        logger.error(f"❌ [metallicadpa] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result(
            "metallicadpa_ppl", warnings=[f"could not open workbook: {e}"]
        )

    unit = S.normalize_unit_hint(unit_hint)
    warnings: list[str] = []
    weeks_by_number: dict[int, PrescribedWeek] = {}
    filled: list = []

    for ws in wb.worksheets:
        if any(k in ws.title.lower() for k in ("read", "instruct", "1rm", "settings")):
            continue
        _parse_sheet(ws, weeks_by_number, filled, unit)

    if not weeks_by_number:
        return S.empty_parse_result(
            "metallicadpa_ppl", warnings=warnings + ["no rows parsed"],
        )

    weeks = [weeks_by_number[n] for n in sorted(weeks_by_number)]
    days_per_week = max(len(w.days) for w in weeks)

    template = S.build_template(
        user_id=user_id,
        source_app="metallicadpa_ppl",
        program_name="Metallicadpa PPL",
        program_creator="u/metallicadpa",
        total_weeks=len(weeks),
        days_per_week=days_per_week,
        unit_hint=unit,
        weeks=weeks,
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="Metallicadpa 12-week PPL. Rep scheme 5/5+ (last set AMRAP).",
    )

    strength_rows = []
    if filled:
        strength_rows = S.collect_filled_history_rows(
            user_id=user_id,
            source_app="metallicadpa_ppl_history",
            performed_at_fallback=datetime.now(tz=timezone.utc),
            template=template,
            filled_rows=filled,
        )

    return ParseResult(
        mode=(ImportMode.PROGRAM_WITH_FILLED_HISTORY if strength_rows
              else ImportMode.TEMPLATE),
        source_app="metallicadpa_ppl",
        template=template,
        strength_rows=strength_rows,
        warnings=warnings,
    )


def _parse_sheet(ws, weeks_by_number, filled, unit: WeightUnit) -> None:
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return

    # Header row detection.
    header_idx: Optional[int] = None
    for i, row in enumerate(rows[:15]):
        lowered = [str(c).strip().lower() if c is not None else "" for c in row]
        if "exercise" in lowered and ("sets" in lowered or "reps" in lowered):
            header_idx = i
            break
    if header_idx is None:
        return
    header = [str(c).strip().lower() if c is not None else "" for c in rows[header_idx]]

    def idx_of(*names) -> Optional[int]:
        for i, h in enumerate(header):
            if h in names:
                return i
        return None

    col_ex = idx_of("exercise")
    col_sets = idx_of("sets")
    col_reps = idx_of("reps")
    col_weight = idx_of("weight (calc)", "weight", "weight calc")
    col_reps_done = idx_of("reps done")
    col_actual_w = idx_of("actual weight")

    if col_ex is None:
        return

    # Assume whole tab is a single day of a single week (common metallicadpa
    # layout); user will see multiple days as multiple tabs if present.
    week = weeks_by_number.setdefault(1, PrescribedWeek(week_number=1, days=[]))
    day = PrescribedDay(day_number=len(week.days) + 1, day_label=ws.title, exercises=[])
    week.days.append(day)

    for row in rows[header_idx + 1 :]:
        exercise = row[col_ex] if col_ex is not None else None
        if exercise is None or not str(exercise).strip():
            continue
        name = str(exercise).strip()
        if name.lower() == "exercise":
            continue

        sets_count = S.safe_int(row[col_sets]) if col_sets is not None else None
        sets_count = sets_count or 3

        rep_target, amrap_last = S.parse_rep_target(
            row[col_reps] if col_reps is not None else None
        )
        rep_target = rep_target or RepTarget(min=8, max=8, amrap_last=False)

        calc_weight = S.parse_weight_cell(
            row[col_weight] if col_weight is not None else None, unit
        )
        load_presc = (
            S.absolute_kg_prescription(calc_weight)
            if calc_weight is not None
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
        day.exercises.append(PrescribedExercise(
            order=len(day.exercises),
            exercise_name_raw=name,
            sets=prescribed,
        ))

        actual_w = S.parse_weight_cell(
            row[col_actual_w] if col_actual_w is not None else None, unit
        )
        reps_done = S.safe_int(row[col_reps_done]) if col_reps_done is not None else None
        if actual_w is not None and reps_done is not None and reps_done > 0:
            filled.append((name, actual_w, reps_done, 1, ws.title))
