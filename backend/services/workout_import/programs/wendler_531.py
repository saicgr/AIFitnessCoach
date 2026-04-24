"""
Jim Wendler 5/3/1 — community-made spreadsheets. Canonical is Poteto v1.28.xlsx.

Input tab holds: TM per lift (Squat/Bench/DL/OHP), kg/lb toggle, increment,
plate-rounding multiple. Cycle tabs are printable-one-per-page.

Conventions we encode:

  * TM = 0.9 × true 1RM   →  training_max_factor = 0.9 on the template.
  * Warm-ups: 40% / 50% / 60% × 5 / 5 / 3 (of TM).
  * Main sets (the 5/3/1 trinity):
      Week 1: 65% × 5, 75% × 5, 85% × 5+      (last set AMRAP)
      Week 2: 70% × 3, 80% × 3, 90% × 3+
      Week 3: 75% × 5, 85% × 3, 95% × 1+
      Week 4 (deload): 40% × 5, 50% × 5, 60% × 5
  * BBB supplemental: 5×10 @ 50/60/65/70% TM — the book lists % but the
    spreadsheet's "BBB" tab has a dropdown. We read the dropdown value.
  * Hidden "Calc" tab resolves plate math — we ignore it and let the
    template player do the rounding using rounding_multiple_kg.

Because the official 5/3/1 product is a PDF book and the spreadsheet varies
wildly (Poteto, Lift Vault, BBB, Beefcake), we lean on well-known %-week
structure when we can't extract every row.
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


# Canonical 5/3/1 main-set structure.
_MAIN_PATTERN = {
    1: [(0.65, 5, False), (0.75, 5, False), (0.85, 5, True)],
    2: [(0.70, 3, False), (0.80, 3, False), (0.90, 3, True)],
    3: [(0.75, 5, False), (0.85, 3, False), (0.95, 1, True)],
    4: [(0.40, 5, False), (0.50, 5, False), (0.60, 5, False)],  # deload
}

_WARMUPS = [(0.40, 5), (0.50, 5), (0.60, 3)]

_LIFTS_ORDER = [
    ("squat", "back_squat", "Back Squat"),
    ("bench", "bench_press", "Bench Press"),
    ("deadlift", "deadlift", "Deadlift"),
    ("press", "overhead_press", "Overhead Press"),
]


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
        logger.error(f"❌ [wendler_531] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result(
            "wendler_531", warnings=[f"could not open workbook: {e}"]
        )

    unit = S.normalize_unit_hint(unit_hint)
    one_rms = _extract_tm_inputs(wb, unit)
    increment_kg, rounding_kg = _extract_math_inputs(wb, unit)
    warnings: list[str] = []

    # Build the canonical 4-week 5/3/1 program. One day per lift, four weeks,
    # warmups + 3 main sets + optional BBB supplemental.
    weeks: list[PrescribedWeek] = []
    for week_number in range(1, 5):
        pattern = _MAIN_PATTERN[week_number]
        days: list[PrescribedDay] = []
        for day_number, (short, ref, pretty) in enumerate(_LIFTS_ORDER, start=1):
            prescribed_sets: list[PrescribedSet] = []
            # Warmups.
            for i, (pct, reps) in enumerate(_WARMUPS):
                prescribed_sets.append(
                    PrescribedSet(
                        order=i,
                        set_type=SetType.WARMUP,
                        rep_target=RepTarget(min=reps, max=reps),
                        load_prescription=S.LoadPrescription(
                            kind=LoadPrescriptionKind.PERCENT_TM,
                            value_min=pct,
                            value_max=pct,
                            reference_1rm_exercise=ref,
                        ),
                    )
                )
            # Main sets.
            offset = len(_WARMUPS)
            for i, (pct, reps, amrap) in enumerate(pattern):
                prescribed_sets.append(
                    PrescribedSet(
                        order=offset + i,
                        set_type=SetType.AMRAP if amrap else SetType.WORKING,
                        rep_target=RepTarget(
                            min=reps,
                            max=reps if not amrap else 99,
                            amrap_last=amrap,
                        ),
                        load_prescription=S.LoadPrescription(
                            kind=LoadPrescriptionKind.PERCENT_TM,
                            value_min=pct,
                            value_max=pct,
                            reference_1rm_exercise=ref,
                        ),
                    )
                )
            days.append(PrescribedDay(
                day_number=day_number,
                day_label=f"{pretty} Day (Week {week_number})",
                exercises=[PrescribedExercise(
                    order=0,
                    exercise_name_raw=pretty,
                    warmup_set_count=len(_WARMUPS),
                    sets=prescribed_sets,
                )],
            ))
        weeks.append(PrescribedWeek(week_number=week_number, days=days,
                                    label="Deload" if week_number == 4 else None))

    # If we can detect BBB supplemental % on an explicit tab, layer a 5×10
    # supplemental exercise per day — same lift at {50,60,65,70}% TM.
    bbb_percent = _extract_bbb_percent(wb)
    if bbb_percent is not None:
        for week in weeks:
            for day in week.days:
                ref = _LIFTS_ORDER[day.day_number - 1][1]
                pretty = _LIFTS_ORDER[day.day_number - 1][2]
                bbb_sets = [
                    PrescribedSet(
                        order=i,
                        set_type=SetType.WORKING,
                        rep_target=RepTarget(min=10, max=10),
                        load_prescription=S.LoadPrescription(
                            kind=LoadPrescriptionKind.PERCENT_TM,
                            value_min=bbb_percent,
                            value_max=bbb_percent,
                            reference_1rm_exercise=ref,
                        ),
                    )
                    for i in range(5)
                ]
                day.exercises.append(PrescribedExercise(
                    order=len(day.exercises),
                    exercise_name_raw=f"{pretty} — BBB 5×10",
                    sets=bbb_sets,
                ))

    template = S.build_template(
        user_id=user_id,
        source_app="wendler_531",
        program_name="5/3/1" + (" BBB" if bbb_percent is not None else ""),
        program_creator="Jim Wendler",
        total_weeks=4,
        days_per_week=4,
        unit_hint=unit,
        weeks=weeks,
        one_rm_inputs=one_rms,
        training_max_factor=0.9,  # TM = 0.9 × true 1RM — the defining Wendler feature
        rounding_multiple_kg=rounding_kg,
        program_version="Poteto-compatible",
        notes="5/3/1 TM = 0.9 × true 1RM. Last set of main work is AMRAP "
              "(5+, 3+, 1+).",
    )

    return ParseResult(
        mode=ImportMode.TEMPLATE,
        source_app="wendler_531",
        template=template,
        warnings=warnings,
    )


# ─────────────────────────── Helpers ───────────────────────────

def _extract_tm_inputs(wb, unit: WeightUnit) -> dict[str, float]:
    """Walk every sheet (including hidden ones — Poteto hides Calc by default)
    looking for labels "Squat TM", "Squat 1RM", etc. Returns kg values."""
    tms: dict[str, float] = {}
    label_map = {
        "squat": "squat_kg",
        "bench": "bench_kg",
        "deadlift": "deadlift_kg",
        "press": "ohp_kg",
        "ohp": "ohp_kg",
    }
    # Also resolve via named ranges: Poteto exposes TM_Squat / TM_Bench / ...
    for key in ("TM_Squat", "TM_Bench", "TM_Deadlift", "TM_Press", "TM_OHP"):
        v = S.find_named_range(wb, key)
        if v is not None:
            w = S.safe_float(v)
            if w is not None:
                canon = key.lower().replace("tm_", "")
                canon = "ohp" if canon == "press" else canon
                tms[label_map.get(canon, f"{canon}_kg")] = _as_kg(w, unit)

    for ws in wb.worksheets:
        for row_idx in range(1, 40):
            for col_idx in range(1, 12):
                val = ws.cell(row=row_idx, column=col_idx).value
                if not isinstance(val, str):
                    continue
                s = val.strip().lower()
                for key, slug in label_map.items():
                    if s.startswith(key) and ("tm" in s or "1rm" in s or "training max" in s):
                        right = ws.cell(row=row_idx, column=col_idx + 1).value
                        w = S.safe_float(right)
                        if w is not None and slug not in tms:
                            tms[slug] = _as_kg(w, unit)
    return tms


def _extract_math_inputs(wb, unit: WeightUnit) -> tuple[float, float]:
    """Return (weekly_increment_kg, rounding_multiple_kg). Defaults follow
    Wendler's book: upper-body increment 2.5 kg (5 lb), lower-body 5 kg (10 lb).
    Poteto exposes both as named ranges `UpperInc` / `LowerInc` / `Round`."""
    default_rounding = 2.5 if unit == WeightUnit.KG else 2.27
    default_increment = 2.5 if unit == WeightUnit.KG else 2.27
    rnd = S.find_named_range(wb, "Round") or S.find_named_range(wb, "Rounding")
    inc = S.find_named_range(wb, "UpperInc") or S.find_named_range(wb, "Increment")
    rnd_f = S.safe_float(rnd)
    inc_f = S.safe_float(inc)
    return (
        _as_kg(inc_f, unit) if inc_f else default_increment,
        _as_kg(rnd_f, unit) if rnd_f else default_rounding,
    )


def _extract_bbb_percent(wb) -> Optional[float]:
    """Return the BBB supplemental percentage fraction (0.50..0.70) if the
    workbook has an explicit 'BBB' tab or named range."""
    for ws in wb.worksheets:
        if "bbb" not in ws.title.lower():
            continue
        # Scan first few rows for a % cell.
        for row in ws.iter_rows(max_row=20, values_only=True):
            for cell in row:
                if cell is None:
                    continue
                p = S.parse_percent(cell)
                if p is not None and 0.40 <= p[0] <= 0.80:
                    return p[0]
    return None


def _as_kg(v: Optional[float], unit: WeightUnit) -> float:
    if v is None:
        return 0.0
    if unit == WeightUnit.LB:
        return float(v) * 0.45359237
    return float(v)
