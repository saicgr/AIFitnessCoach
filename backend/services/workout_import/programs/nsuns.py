"""
nSuns 4/5/6-day program — .xlsx + Google Sheets community copies.

Columns: `Exercise | Set | Reps | %TM | Weight`.
Rep column encodes AMRAP like `x1+`, `x3+`, `x5+`.
TM = 90% of 1RM — same Wendler convention (training_max_factor = 0.9).

Progression: a hidden `LOG` tab captures AMRAP reps each week and recalcs
the TM. We don't need that — the template player resolves against the
user's LIVE 1RM, which updates automatically when they log an AMRAP.
"""
from __future__ import annotations

from typing import Optional
from uuid import UUID

from core.logger import get_logger

from ..canonical import (
    ImportMode,
    LoadPrescriptionKind,
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
        logger.error(f"❌ [nsuns] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result("nsuns", warnings=[f"could not open workbook: {e}"])

    unit = S.normalize_unit_hint(unit_hint)
    one_rms = _extract_1rms(wb, unit)
    warnings: list[str] = []

    weeks_by_number: dict[int, PrescribedWeek] = {}

    for ws in wb.worksheets:
        t = ws.title.lower()
        if any(k in t for k in ("instruction", "readme", "log", "settings", "1rm")):
            continue
        _parse_day_sheet(ws, weeks_by_number)

    if not weeks_by_number:
        return S.empty_parse_result("nsuns", warnings=warnings + ["no day sheets parsed"])

    weeks = [weeks_by_number[n] for n in sorted(weeks_by_number)]
    days_per_week = max(len(w.days) for w in weeks)

    template = S.build_template(
        user_id=user_id,
        source_app="nsuns",
        program_name=_infer_program_name(filename),
        program_creator="u/nsuns",
        total_weeks=max(1, len(weeks)),
        days_per_week=days_per_week,
        unit_hint=unit,
        weeks=weeks,
        one_rm_inputs=one_rms,
        training_max_factor=0.9,  # nSuns uses Wendler-style TM = 0.9 × 1RM
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="nSuns: last set of every AMRAP line is x_+ (min reps but keep going).",
    )

    return ParseResult(
        mode=ImportMode.TEMPLATE,
        source_app="nsuns",
        template=template,
        warnings=warnings,
    )


def _infer_program_name(filename: str) -> str:
    s = filename.lower()
    if "6" in s and "day" in s:
        return "nSuns 6-Day"
    if "5" in s and "day" in s:
        return "nSuns 5-Day"
    if "4" in s and "day" in s:
        return "nSuns 4-Day"
    return "nSuns 5/3/1"


def _extract_1rms(wb, unit: WeightUnit) -> dict[str, float]:
    out: dict[str, float] = {}
    label_map = {
        "squat": "squat_kg",
        "bench": "bench_kg",
        "deadlift": "deadlift_kg",
        "ohp": "ohp_kg",
        "overhead press": "ohp_kg",
        "press": "ohp_kg",
    }
    for ws in wb.worksheets:
        for row_idx in range(1, 40):
            for col_idx in range(1, 12):
                val = ws.cell(row=row_idx, column=col_idx).value
                if not isinstance(val, str):
                    continue
                s = val.strip().lower()
                for key, slug in label_map.items():
                    if key in s and ("1rm" in s or "max" in s):
                        right = ws.cell(row=row_idx, column=col_idx + 1).value
                        w = S.safe_float(right)
                        if w is not None and slug not in out:
                            out[slug] = (w if unit == WeightUnit.KG else w * 0.45359237)
    return out


def _parse_day_sheet(ws, weeks_by_number: dict[int, PrescribedWeek]) -> None:
    """Each day tab lists exercises vertically with a Set/Reps/%TM triple.
    We assign it to week 1 day N where N is derived from the tab title."""
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return

    import re
    m = re.search(r"day\s*(\d+)", ws.title, re.IGNORECASE)
    day_number = int(m.group(1)) if m else (len(weeks_by_number.get(1, PrescribedWeek(week_number=1, days=[])).days) + 1)

    # Locate header.
    header_idx: Optional[int] = None
    for i, row in enumerate(rows[:15]):
        lowered = [str(c).strip().lower() if c is not None else "" for c in row]
        if "exercise" in lowered and ("set" in lowered or "sets" in lowered):
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
    col_set = idx_of("set", "sets")
    col_reps = idx_of("reps")
    col_pct = idx_of("%tm", "% tm", "%1rm", "% 1rm")
    if col_ex is None:
        return

    current_exercise: Optional[str] = None
    exercise_obj: Optional[PrescribedExercise] = None

    week = weeks_by_number.setdefault(1, PrescribedWeek(week_number=1, days=[]))
    day = PrescribedDay(day_number=day_number, day_label=ws.title, exercises=[])
    week.days.append(day)

    for row in rows[header_idx + 1 :]:
        exercise_cell = row[col_ex] if col_ex is not None else None
        reps_cell = row[col_reps] if col_reps is not None else None
        pct_cell = row[col_pct] if col_pct is not None else None
        set_cell = row[col_set] if col_set is not None else None

        if exercise_cell is not None and str(exercise_cell).strip():
            name = str(exercise_cell).strip()
            if name.lower() in {"exercise"}:
                continue
            current_exercise = name
            exercise_obj = PrescribedExercise(
                order=len(day.exercises),
                exercise_name_raw=name,
                sets=[],
            )
            day.exercises.append(exercise_obj)

        if exercise_obj is None:
            continue

        rep_target, amrap_last = S.parse_rep_target(reps_cell)
        if rep_target is None:
            continue
        percent = S.parse_percent(pct_cell)

        load_presc = (
            S.LoadPrescription(
                kind=LoadPrescriptionKind.PERCENT_TM,
                value_min=percent[0],
                value_max=percent[1],
                reference_1rm_exercise=_ref_for(current_exercise or ""),
            )
            if percent is not None
            else S.unspecified_prescription()
        )
        set_num = S.safe_int(set_cell) or (len(exercise_obj.sets) + 1)

        exercise_obj.sets.append(
            PrescribedSet(
                order=len(exercise_obj.sets),
                set_type=SetType.AMRAP if amrap_last else SetType.WORKING,
                rep_target=rep_target,
                load_prescription=load_presc,
            )
        )


def _ref_for(exercise_name: str) -> Optional[str]:
    s = exercise_name.lower()
    if "squat" in s:
        return "back_squat"
    if "bench" in s:
        return "bench_press"
    if "deadlift" in s:
        return "deadlift"
    if "press" in s:
        return "overhead_press"
    return None
