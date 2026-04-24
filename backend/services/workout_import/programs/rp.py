"""
Renaissance Periodization — Male/Female Physique Template 2.0, Powerlifting
Template.

Delivered as .xlsx or .xlsm (some versions use VBA to auto-add/remove sets
weekly based on the user's Pump + Performance ratings). We load with
keep_vba=False + data_only=True so we read the last-saved computed state
and ignore VBA entirely.

Unique RP columns:
  Exercise | Sets | Reps | Load | RIR | Pump rating | Performance rating | Notes

Rep encoding: "8-10 reps @ 3 RIR", RIR decreases by 1 each week, deload final.
MEV/MRV landmark cells per muscle group — labeled on a dedicated "Volume"
or "Landmarks" tab which we skip for the prescription tree (we emit it as a
note on the template).
"""
from __future__ import annotations

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

_COL_EXERCISE = ("exercise",)
_COL_SETS = ("sets",)
_COL_REPS = ("reps", "rep range")
_COL_LOAD = ("load", "weight", "load (kg)", "load (lb)")
_COL_RIR = ("rir",)
_COL_PUMP = ("pump", "pump rating", "pump rating (0-3)")
_COL_PERF = ("performance", "performance rating", "performance rating (-2..+2)")
_COL_NOTES = ("notes",)


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
        logger.error(f"❌ [rp] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result("rp", warnings=[f"could not open workbook: {e}"])

    unit = S.normalize_unit_hint(unit_hint)
    weeks_by_number: dict[int, PrescribedWeek] = {}
    warnings: list[str] = []

    for ws in wb.worksheets:
        title_lower = ws.title.lower()
        if any(k in title_lower for k in (
            "read me", "readme", "instruction", "volume", "landmark",
            "mev", "mrv", "settings", "macro",
        )):
            continue
        _parse_mesocycle_tab(ws, weeks_by_number)

    if not weeks_by_number:
        return S.empty_parse_result("rp", warnings=warnings + ["no prescription rows found"])

    weeks = [weeks_by_number[n] for n in sorted(weeks_by_number)]
    days_per_week = max(len(w.days) for w in weeks) if weeks else 1

    template = S.build_template(
        user_id=user_id,
        source_app="rp",
        program_name=_infer_program_name(filename),
        program_creator="Renaissance Periodization (Mike Israetel)",
        total_weeks=len(weeks),
        days_per_week=days_per_week,
        unit_hint=unit,
        weeks=weeks,
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="RP mesocycle: RIR decreases each week, final week deload. "
              "Pump + Performance ratings (not parsed) govern weekly volume progression.",
    )

    return ParseResult(
        mode=ImportMode.TEMPLATE,
        source_app="rp",
        template=template,
        warnings=warnings,
    )


def _infer_program_name(filename: str) -> str:
    s = filename.lower()
    if "female" in s:
        return "Female Physique Template 2.0"
    if "powerlifting" in s:
        return "RP Powerlifting Template"
    if "male" in s or "physique" in s:
        return "Male Physique Template 2.0"
    return "Renaissance Periodization Template"


def _parse_mesocycle_tab(ws, weeks_by_number: dict[int, PrescribedWeek]) -> None:
    """RP tabs are typically per-mesocycle or per-day. A mesocycle tab has a
    "Week 1 / Week 2 / ... / Deload" banner set; a per-day tab has one day's
    prescription with weeks horizontally.

    We handle both by locating the header row + scanning. This is best-effort —
    RP has many community layouts.
    """
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return

    header_idx: Optional[int] = None
    for i, row in enumerate(rows):
        lowered = [str(c).strip().lower() if c is not None else "" for c in row]
        if "exercise" in lowered:
            header_idx = i
            break
    if header_idx is None:
        return

    header = [str(c).strip().lower() if c is not None else "" for c in rows[header_idx]]

    def col(aliases: tuple[str, ...]) -> Optional[int]:
        for i, c in enumerate(header):
            if c in aliases:
                return i
        return None

    col_ex = col(_COL_EXERCISE)
    col_sets = col(_COL_SETS)
    col_reps = col(_COL_REPS)
    col_load = col(_COL_LOAD)
    col_rir = col(_COL_RIR)
    col_notes = col(_COL_NOTES)
    if col_ex is None:
        return

    current_week = 1
    order_counter = 0
    day_exercises: list[PrescribedExercise] = []

    def flush_day():
        nonlocal day_exercises, order_counter
        if not day_exercises:
            return
        wk = weeks_by_number.setdefault(
            current_week, PrescribedWeek(week_number=current_week, days=[])
        )
        wk.days.append(
            PrescribedDay(
                day_number=len(wk.days) + 1,
                day_label=ws.title,
                exercises=day_exercises,
            )
        )
        day_exercises = []
        order_counter = 0

    import re

    for row in rows[header_idx + 1 :]:
        # WEEK N row / Deload row — banner.
        first = row[0]
        if isinstance(first, str):
            mw = re.search(r"week\s*(\d+)", first, re.IGNORECASE)
            if mw:
                new_week = int(mw.group(1))
                if new_week != current_week:
                    flush_day()
                    current_week = new_week
                continue
            if "deload" in first.lower():
                flush_day()
                current_week += 1
                continue

        exercise = row[col_ex] if col_ex is not None else None
        if exercise is None or str(exercise).strip() == "":
            continue
        name = str(exercise).strip()
        if name.lower() in {"exercise", "rest"}:
            continue

        sets_count = S.safe_int(row[col_sets]) if col_sets is not None else None
        sets_count = sets_count or 3

        rep_target, amrap_last = S.parse_rep_target(
            row[col_reps] if col_reps is not None else None
        )
        rep_target = rep_target or RepTarget(min=8, max=12, amrap_last=False)

        rir_val = S.safe_int(row[col_rir]) if col_rir is not None else None
        notes_val = row[col_notes] if col_notes is not None else None

        load_cell = row[col_load] if col_load is not None else None
        percent = S.parse_percent(load_cell)

        if percent is not None:
            load_presc = S.simple_percent_prescription(percent[0], percent[1])
        elif rir_val is not None:
            # RP uses RIR as the primary load cue.
            load_presc = S.LoadPrescription(
                kind=S.LoadPrescriptionKind.RPE_TARGET,
                value_min=float(10 - rir_val),  # RPE = 10 - RIR
                value_max=float(10 - rir_val),
            )
        else:
            load_presc = S.unspecified_prescription()

        prescribed = []
        for i in range(sets_count):
            prescribed.append(
                PrescribedSet(
                    order=i,
                    set_type=SetType.WORKING,
                    rep_target=rep_target,
                    load_prescription=load_presc,
                    rir_target=(RepTarget(min=rir_val, max=rir_val)
                                if rir_val is not None else None),
                    notes=str(notes_val) if notes_val else None,
                )
            )

        day_exercises.append(
            PrescribedExercise(
                order=order_counter,
                exercise_name_raw=name,
                sets=prescribed,
            )
        )
        order_counter += 1

    flush_day()
