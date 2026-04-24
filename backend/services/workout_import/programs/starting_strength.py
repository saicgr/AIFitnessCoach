"""
Starting Strength (Mark Rippetoe) — community Google Sheets / .xlsx.

Columns (typical): `Date | Squat 3×5 | Bench 3×5 | Press 3×5 | Deadlift 1×5
| Power Clean 5×3 | BW | Notes`. Absolute weights (not percent-based);
user types next weight and the sheet increments ±5 lb / ±2.5 kg by default.

A/B alternation is inferred from which lifts are populated on a given row.
We encode a 2-day canonical rotation (Workout A / Workout B) — the per-row
dates, if populated, also surface as filled history.
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


_LIFT_COLUMN_HINTS = {
    "squat": "Back Squat",
    "bench": "Bench Press",
    "press": "Overhead Press",
    "ohp": "Overhead Press",
    "deadlift": "Deadlift",
    "power clean": "Power Clean",
    "clean": "Power Clean",
}

_LIFT_SETS = {
    "Back Squat": (3, 5),
    "Bench Press": (3, 5),
    "Overhead Press": (3, 5),
    "Deadlift": (1, 5),
    "Power Clean": (5, 3),
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
        logger.error(f"❌ [starting_strength] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result(
            "starting_strength", warnings=[f"could not open workbook: {e}"]
        )

    unit = S.normalize_unit_hint(unit_hint)
    warnings: list[str] = []
    filled: list = []

    # Canonical 2-day A/B split as the template backbone.
    day_a = PrescribedDay(
        day_number=1, day_label="Workout A",
        exercises=[
            _ss_exercise(0, "Back Squat"),
            _ss_exercise(1, "Bench Press"),
            _ss_exercise(2, "Deadlift"),
        ],
    )
    day_b = PrescribedDay(
        day_number=2, day_label="Workout B",
        exercises=[
            _ss_exercise(0, "Back Squat"),
            _ss_exercise(1, "Overhead Press"),
            _ss_exercise(2, "Power Clean"),
        ],
    )

    week = PrescribedWeek(week_number=1, days=[day_a, day_b])

    # Walk the workbook and pick up any filled per-day rows as history.
    for ws in wb.worksheets:
        if "instruction" in ws.title.lower() or "readme" in ws.title.lower():
            continue
        _extract_history_rows(ws, unit, filled)

    template = S.build_template(
        user_id=user_id,
        source_app="starting_strength",
        program_name="Starting Strength",
        program_creator="Mark Rippetoe",
        total_weeks=1,
        days_per_week=2,
        unit_hint=unit,
        weeks=[week],
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="Starting Strength A/B alternation. Load is absolute (not %) — "
              "the template player adds the linear progression increment each "
              "successful session.",
    )

    strength_rows = []
    if filled:
        strength_rows = S.collect_filled_history_rows(
            user_id=user_id,
            source_app="starting_strength_history",
            performed_at_fallback=datetime.now(tz=timezone.utc),
            template=template,
            filled_rows=filled,
        )

    return ParseResult(
        mode=(ImportMode.PROGRAM_WITH_FILLED_HISTORY if strength_rows
              else ImportMode.TEMPLATE),
        source_app="starting_strength",
        template=template,
        strength_rows=strength_rows,
        warnings=warnings,
    )


def _ss_exercise(order: int, lift: str) -> PrescribedExercise:
    sets_count, reps = _LIFT_SETS[lift]
    return PrescribedExercise(
        order=order,
        exercise_name_raw=lift,
        sets=[
            PrescribedSet(
                order=i,
                set_type=SetType.WORKING,
                rep_target=RepTarget(min=reps, max=reps),
                load_prescription=S.unspecified_prescription(),
            )
            for i in range(sets_count)
        ],
    )


def _extract_history_rows(ws, unit: WeightUnit, filled: list) -> None:
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return
    header_idx: Optional[int] = None
    for i, row in enumerate(rows[:10]):
        lowered = [str(c).strip().lower() if c is not None else "" for c in row]
        if any(k in " ".join(lowered) for k in ("squat", "bench", "press", "deadlift")):
            header_idx = i
            break
    if header_idx is None:
        return
    header = [str(c).strip().lower() if c is not None else "" for c in rows[header_idx]]
    # Map each column to a canonical lift name if the header matches a hint.
    col_to_lift: dict[int, str] = {}
    for i, h in enumerate(header):
        for key, canonical in _LIFT_COLUMN_HINTS.items():
            if key in h:
                col_to_lift[i] = canonical
                break

    for row in rows[header_idx + 1 :]:
        for col, lift in col_to_lift.items():
            if col >= len(row):
                continue
            weight_kg = S.parse_weight_cell(row[col], unit)
            if weight_kg is None:
                continue
            # SS sheets log one rep count per cell or an assumed 3×5 etc.
            reps = _LIFT_SETS[lift][1]
            filled.append((lift, weight_kg, reps, 1, f"SS {ws.title}"))
