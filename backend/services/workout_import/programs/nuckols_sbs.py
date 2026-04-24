"""
Greg Nuckols / Stronger By Science — 28 Free Programs.

One .xlsx, 27 per-lift tabs + an Instructions tab. Each tab is squat-only,
bench-only, or deadlift-only — the user runs three in parallel. We merge
them all into a single CanonicalProgramTemplate so the template player can
walk a week as "squat day / bench day / deadlift day" depending on frequency.

Columns (verbatim):
  Week | Day | Sets Prescribed | Reps Prescribed | %1RM | Sets Completed
  | Reps on Last Set

User-fill columns: Sets Completed, Reps on Last Set. When populated, we emit
them as filled history. A hidden "Calc" tab recalculates the e1RM after each
AMRAP via Brzycki — we ignore the calc tab entirely since our template player
reads the user's live 1RM anyway.
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

_LIFT_HINTS = {
    "squat": "back_squat",
    "bench": "bench_press",
    "deadlift": "deadlift",
    "press": "overhead_press",
}


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
        logger.error(f"❌ [nuckols_sbs] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result("nuckols_sbs", warnings=[f"could not open workbook: {e}"])

    unit = S.normalize_unit_hint(unit_hint)
    weeks_by_number: dict[int, PrescribedWeek] = {}
    filled_history: list = []
    warnings: list[str] = []

    for ws in wb.worksheets:
        title_lower = ws.title.lower()
        if "instruction" in title_lower or "read" in title_lower or "calc" in title_lower:
            continue
        lift = _detect_lift(ws.title)
        if lift is None:
            # Non-lift tab (menu sheet etc.)
            continue
        _parse_lift_tab(ws=ws, lift=lift, unit=unit,
                        weeks_by_number=weeks_by_number,
                        filled_history=filled_history,
                        warnings=warnings)

    if not weeks_by_number:
        return S.empty_parse_result(
            "nuckols_sbs", warnings=warnings + ["no prescription rows found"]
        )

    weeks = [weeks_by_number[n] for n in sorted(weeks_by_number)]
    days_per_week = max(len(w.days) for w in weeks)

    template = S.build_template(
        user_id=user_id,
        source_app="nuckols_sbs",
        program_name="28 Free Programs",
        program_creator="Greg Nuckols / Stronger By Science",
        total_weeks=len(weeks),
        days_per_week=days_per_week,
        unit_hint=unit,
        weeks=weeks,
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="SBS 28 Programs — one tab per lift × level × frequency. "
              "e1RM progression is driven by the user's live 1RM at each session.",
    )

    strength_rows = []
    if filled_history:
        strength_rows = S.collect_filled_history_rows(
            user_id=user_id,
            source_app="nuckols_sbs_history",
            performed_at_fallback=datetime.now(tz=timezone.utc),
            template=template,
            filled_rows=filled_history,
        )

    mode = (
        ImportMode.PROGRAM_WITH_FILLED_HISTORY if strength_rows else ImportMode.TEMPLATE
    )

    return ParseResult(
        mode=mode,
        source_app="nuckols_sbs",
        template=template,
        strength_rows=strength_rows,
        warnings=warnings,
    )


def _detect_lift(tab_title: str) -> Optional[str]:
    t = tab_title.lower()
    for key, canon in _LIFT_HINTS.items():
        if key in t:
            return canon
    return None


def _parse_lift_tab(
    *,
    ws,
    lift: str,
    unit: WeightUnit,
    weeks_by_number: dict[int, PrescribedWeek],
    filled_history: list,
    warnings: list[str],
) -> None:
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return

    # Locate header row (Nuckols sheets sometimes have a title row above it).
    header_idx: Optional[int] = None
    for i, row in enumerate(rows[:15]):
        lowered = [str(c).strip().lower() if c is not None else "" for c in row]
        if "week" in lowered and "day" in lowered:
            header_idx = i
            break
    if header_idx is None:
        return

    header = [str(c).strip().lower() if c is not None else "" for c in rows[header_idx]]

    def idx_of(*names) -> Optional[int]:
        for i, h in enumerate(header):
            for n in names:
                if h == n.lower():
                    return i
        return None

    col_week = idx_of("week")
    col_day = idx_of("day")
    col_sets_p = idx_of("sets prescribed", "sets")
    col_reps_p = idx_of("reps prescribed", "reps")
    col_pct = idx_of("%1rm", "% 1rm", "%1 rm")
    col_sets_c = idx_of("sets completed")
    col_reps_last = idx_of("reps on last set", "last set reps")

    if col_week is None:
        return

    lift_name = lift.replace("_", " ").title()

    for row in rows[header_idx + 1 :]:
        wk = S.safe_int(row[col_week]) if col_week is not None else None
        day = S.safe_int(row[col_day]) if col_day is not None else None
        if wk is None or day is None:
            continue

        week = weeks_by_number.setdefault(
            wk, PrescribedWeek(week_number=wk, days=[])
        )
        # Find-or-create the corresponding day slot.
        day_obj: Optional[PrescribedDay] = None
        for d in week.days:
            if d.day_number == day:
                day_obj = d
                break
        if day_obj is None:
            day_obj = PrescribedDay(day_number=day, day_label=f"Day {day}", exercises=[])
            week.days.append(day_obj)

        sets_p = S.safe_int(row[col_sets_p]) if col_sets_p is not None else None
        reps_p = S.safe_int(row[col_reps_p]) if col_reps_p is not None else None
        pct_cell = row[col_pct] if col_pct is not None else None
        percent = S.parse_percent(pct_cell)

        rep_target = (
            RepTarget(min=reps_p or 1, max=reps_p or 1, amrap_last=True)
            if reps_p is not None
            else RepTarget(min=1, max=99, amrap_last=True)
        )
        load_presc = (
            S.simple_percent_prescription(percent[0], percent[1], reference=lift)
            if percent is not None
            else S.unspecified_prescription()
        )

        prescribed_sets = []
        for i in range(sets_p or 1):
            is_last = i == (sets_p or 1) - 1
            prescribed_sets.append(
                PrescribedSet(
                    order=i,
                    set_type=SetType.AMRAP if is_last else SetType.WORKING,
                    rep_target=rep_target,
                    load_prescription=load_presc,
                )
            )

        day_obj.exercises.append(
            PrescribedExercise(
                order=len(day_obj.exercises),
                exercise_name_raw=lift_name,
                sets=prescribed_sets,
            )
        )

        # User-filled history: only emit when sets_completed AND reps_on_last_set
        # are numeric (matches "Reps on Last Set" semantics — only the final
        # AMRAP matters for progression).
        sets_done = S.safe_int(row[col_sets_c]) if col_sets_c is not None else None
        reps_last = S.safe_int(row[col_reps_last]) if col_reps_last is not None else None
        if sets_done is not None and reps_last is not None and reps_last > 0:
            filled_history.append(
                (lift_name, None, reps_last, sets_done, f"SBS Week {wk} Day {day}")
            )
