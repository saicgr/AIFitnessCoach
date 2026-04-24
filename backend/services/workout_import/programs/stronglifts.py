"""
StrongLifts 5×5 — Mehdi. iOS/Android app export as CSV.

Columns (from support.stronglifts.com): Workout date, Workout number,
Workout name, Program Name, Body weight, Exercise, Sets & Reps.

Reps per set slash-joined in one column: "5/5/5/5/3". A/B encoded in
"Workout name" = "Workout A" | "Workout B". Weight in the user's app unit
(one single unit per file).

StrongLifts is ALWAYS history mode — there is no template export. We still
surface a canonical 5×5 A/B plan alongside the parsed history so the
template player has something to run if the user activates it.
"""
from __future__ import annotations

import csv
import io
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from core.logger import get_logger

from ..canonical import (
    CanonicalSetRow,
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
    unit = S.normalize_unit_hint(unit_hint)
    warnings: list[str] = []
    strength_rows: list[CanonicalSetRow] = []

    try:
        text = data.decode("utf-8-sig", errors="ignore")
    except Exception:
        text = data.decode("latin-1", errors="ignore")

    reader = csv.DictReader(io.StringIO(text))
    rows = list(reader)

    # Emit one CanonicalSetRow per set parsed from the slash-delimited cell.
    for r in rows:
        date_str = r.get("Workout date") or r.get("workout date") or ""
        name = r.get("Exercise") or r.get("exercise")
        sets_reps = r.get("Sets & Reps") or r.get("sets & reps") or ""
        workout_name = r.get("Workout name") or r.get("workout name")
        body_weight = S.safe_float(r.get("Body weight"))
        if not name or not sets_reps:
            continue
        performed_at = _parse_date(date_str)

        reps_list = _parse_slash_reps(sets_reps)
        # Weight is usually in a separate column ("Weight") — StrongLifts
        # exports vary; look for both naming conventions.
        weight_cell = r.get("Weight") or r.get("weight") or ""
        weight_kg = S.parse_weight_cell(weight_cell, unit)

        for i, reps in enumerate(reps_list):
            if reps is None:
                continue
            rh = S.deterministic_row_hash(
                user_id=user_id,
                source_app="stronglifts",
                performed_at=performed_at,
                exercise_name_canonical=name.strip().lower(),
                set_number=i + 1,
                weight_kg=weight_kg,
                reps=reps,
            )
            strength_rows.append(CanonicalSetRow(
                user_id=user_id,
                performed_at=performed_at,
                workout_name=workout_name,
                exercise_name_raw=name,
                set_number=i + 1,
                set_type=SetType.WORKING,
                weight_kg=weight_kg,
                reps=reps,
                source_app="stronglifts",
                source_row_hash=rh,
            ))

    template = _canonical_stronglifts_template(user_id=user_id, unit=unit)

    return ParseResult(
        mode=(ImportMode.PROGRAM_WITH_FILLED_HISTORY if strength_rows
              else ImportMode.HISTORY),
        source_app="stronglifts",
        strength_rows=strength_rows,
        template=template,
        warnings=warnings,
    )


def _parse_slash_reps(s: str) -> list[Optional[int]]:
    if not s:
        return []
    parts = [p.strip() for p in s.replace("|", "/").replace(",", "/").split("/")]
    out: list[Optional[int]] = []
    for p in parts:
        if not p:
            out.append(None)
            continue
        try:
            out.append(int(p))
        except ValueError:
            out.append(None)
    return out


def _parse_date(s: str) -> datetime:
    if not s:
        return datetime.now(tz=timezone.utc)
    for fmt in ("%Y-%m-%d", "%m/%d/%Y", "%d/%m/%Y", "%Y/%m/%d"):
        try:
            dt = datetime.strptime(s, fmt)
            return dt.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    # Fallback — try fromisoformat for "2024-01-02 10:00:00"
    try:
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return datetime.now(tz=timezone.utc)


def _canonical_stronglifts_template(*, user_id: UUID, unit: WeightUnit):
    def ex(order: int, lift: str, sets: int, reps: int) -> PrescribedExercise:
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
                for i in range(sets)
            ],
        )

    day_a = PrescribedDay(
        day_number=1, day_label="Workout A",
        exercises=[
            ex(0, "Back Squat", 5, 5),
            ex(1, "Bench Press", 5, 5),
            ex(2, "Barbell Row", 5, 5),
        ],
    )
    day_b = PrescribedDay(
        day_number=2, day_label="Workout B",
        exercises=[
            ex(0, "Back Squat", 5, 5),
            ex(1, "Overhead Press", 5, 5),
            ex(2, "Deadlift", 1, 5),
        ],
    )

    return S.build_template(
        user_id=user_id,
        source_app="stronglifts",
        program_name="StrongLifts 5×5",
        program_creator="Mehdi",
        total_weeks=1,
        days_per_week=2,
        unit_hint=unit,
        weeks=[PrescribedWeek(week_number=1, days=[day_a, day_b])],
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,
        notes="StrongLifts 5×5 A/B alternation; +2.5 kg every successful "
              "session, deload 10% after 3 failed attempts.",
    )
