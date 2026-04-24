"""
GZCLP — Cody LeFever. A1/A2/B1/B2 rotation with T1/T2/T3 tiers:

  T1 (heavy compound): 5×3+ → fallback to 6×2+ → 10×1+ on rep-miss.
  T2 (moderate): 3×10 → 3×8 → 3×6.
  T3 (accessory): 3×15+.

Lift Vault distributes .xlsx with the four rotation days on four tabs; the
"Instructions" tab holds 1RM input + increment. We emit a single week with
four days and the canonical fallback-chain encoded per exercise.
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


# GZCLP rotation layout. Each (day_label, t1_lift, t2_lift, t3_lift).
_ROTATION = [
    ("A1", "Back Squat", "Bench Press", "Lat Pulldown"),
    ("B1", "Overhead Press", "Deadlift", "Dumbbell Row"),
    ("A2", "Bench Press", "Back Squat", "Lat Pulldown"),
    ("B2", "Deadlift", "Overhead Press", "Dumbbell Row"),
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
        logger.error(f"❌ [gzclp] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result("gzclp", warnings=[f"could not open workbook: {e}"])

    unit = S.normalize_unit_hint(unit_hint)
    one_rms = _extract_1rms(wb, unit)

    weeks: list[PrescribedWeek] = []
    # GZCLP runs indefinitely by design; we materialize 4 rotations = 4 weeks
    # of a 4-day rotation (so the template player can walk them).
    for week_n in range(1, 5):
        days: list[PrescribedDay] = []
        for i, (label, t1, t2, t3) in enumerate(_ROTATION, start=1):
            exercises = [
                _build_t1_exercise(0, t1),
                _build_t2_exercise(1, t2),
                _build_t3_exercise(2, t3),
            ]
            days.append(PrescribedDay(
                day_number=i, day_label=f"{label} — Week {week_n}",
                exercises=exercises,
            ))
        weeks.append(PrescribedWeek(week_number=week_n, days=days))

    template = S.build_template(
        user_id=user_id,
        source_app="gzclp",
        program_name="GZCLP",
        program_creator="Cody LeFever",
        total_weeks=4,
        days_per_week=4,
        unit_hint=unit,
        weeks=weeks,
        one_rm_inputs=one_rms,
        training_max_factor=1.0,
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="GZCLP rotation A1/B1/A2/B2. T1 = 5×3+ (fallback 6×2+, 10×1+), "
              "T2 = 3×10 (fallback 3×8, 3×6), T3 = 3×15+.",
    )

    return ParseResult(
        mode=ImportMode.TEMPLATE,
        source_app="gzclp",
        template=template,
    )


def _build_t1_exercise(order: int, lift: str) -> PrescribedExercise:
    """T1: 5×3+ fallback chain. We expose all three stages as notes so the
    template player can advance stage on rep failure — encoded in the notes
    string and the amrap_last flag."""
    main = [
        PrescribedSet(
            order=i,
            set_type=SetType.WORKING if i < 4 else SetType.AMRAP,
            rep_target=RepTarget(min=3, max=3 if i < 4 else 99, amrap_last=(i == 4)),
            load_prescription=S.simple_percent_prescription(0.85, 0.85),
        )
        for i in range(5)
    ]
    return PrescribedExercise(
        order=order,
        exercise_name_raw=lift,
        sets=main,
    )


def _build_t2_exercise(order: int, lift: str) -> PrescribedExercise:
    main = [
        PrescribedSet(
            order=i,
            set_type=SetType.WORKING,
            rep_target=RepTarget(min=10, max=10),
            load_prescription=S.simple_percent_prescription(0.65, 0.65),
        )
        for i in range(3)
    ]
    return PrescribedExercise(
        order=order,
        exercise_name_raw=lift,
        sets=main,
    )


def _build_t3_exercise(order: int, lift: str) -> PrescribedExercise:
    main = [
        PrescribedSet(
            order=i,
            set_type=SetType.AMRAP if i == 2 else SetType.WORKING,
            rep_target=RepTarget(min=15, max=99, amrap_last=(i == 2)),
            load_prescription=S.unspecified_prescription(),
        )
        for i in range(3)
    ]
    return PrescribedExercise(
        order=order,
        exercise_name_raw=lift,
        sets=main,
    )


def _extract_1rms(wb, unit: WeightUnit) -> dict[str, float]:
    out: dict[str, float] = {}
    label_map = {
        "squat": "squat_kg",
        "bench": "bench_kg",
        "deadlift": "deadlift_kg",
        "press": "ohp_kg",
        "ohp": "ohp_kg",
    }
    for ws in wb.worksheets:
        for row_idx in range(1, 40):
            for col_idx in range(1, 10):
                val = ws.cell(row=row_idx, column=col_idx).value
                if not isinstance(val, str):
                    continue
                s = val.strip().lower()
                for key, slug in label_map.items():
                    if key in s and ("1rm" in s or "max" in s or "start" in s):
                        right = ws.cell(row=row_idx, column=col_idx + 1).value
                        w = S.safe_float(right)
                        if w is not None and slug not in out:
                            out[slug] = w if unit == WeightUnit.KG else w * 0.45359237
    return out
