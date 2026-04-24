"""Boostcamp adapter.

Boostcamp has no first-party export — the community scrapes the app's
session payload into JSON. The shape we support (researched from community
dumps + Juggernaut screenshots) is either:

    {
      "program": {"name": "..."},
      "sessions": [
        {
          "date": "2026-03-12T18:00:00",
          "name": "Upper A",
          "exercises": [
            {
              "name": "Bench Press",
              "sets": [
                {"weight": 135, "reps": 5, "rpe": 7, "type": "working"},
                ...
              ]
            }
          ]
        }
      ]
    }

or the flatter Juggernaut variant where ``sessions`` is top-level and
``exercises`` is named ``movements``. We normalize both into canonical rows.

Weight unit is NOT encoded — caller's ``unit_hint`` is authoritative
(edge #1).
"""
from __future__ import annotations

import json
from datetime import timezone
from typing import Any, Iterable, Optional
from uuid import UUID

from ..canonical import (
    CanonicalSetRow,
    ImportMode,
    ParseResult,
    SetType,
    WeightUnit,
)
from ._common import (
    decode_bytes,
    parse_datetime,
    parse_reps_cell,
    parse_rpe,
    parse_weight_cell,
    to_kg,
)

SOURCE_APP = "boostcamp"


def _iter_sessions(payload: Any) -> Iterable[dict]:
    if isinstance(payload, dict):
        if isinstance(payload.get("sessions"), list):
            yield from payload["sessions"]
        elif isinstance(payload.get("workouts"), list):
            yield from payload["workouts"]
        elif isinstance(payload.get("program"), dict) and isinstance(
            payload["program"].get("sessions"), list
        ):
            yield from payload["program"]["sessions"]
    elif isinstance(payload, list):
        # A raw list of sessions.
        yield from payload


def _iter_exercises(session: dict) -> Iterable[dict]:
    for key in ("exercises", "movements", "lifts"):
        if isinstance(session.get(key), list):
            yield from session[key]
            return


def _set_type_for(raw: Optional[str]) -> SetType:
    s = (raw or "").strip().lower()
    return {
        "warmup": SetType.WARMUP,
        "warm-up": SetType.WARMUP,
        "warm up": SetType.WARMUP,
        "failure": SetType.FAILURE,
        "dropset": SetType.DROPSET,
        "drop-set": SetType.DROPSET,
        "amrap": SetType.AMRAP,
        "backoff": SetType.BACKOFF,
        "cluster": SetType.CLUSTER,
        "rest_pause": SetType.REST_PAUSE,
    }.get(s, SetType.WORKING)


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: Optional[ImportMode] = None,
) -> ParseResult:
    default_unit = WeightUnit.LB if (unit_hint or "").lower() == "lb" else WeightUnit.KG
    rows: list[CanonicalSetRow] = []
    warnings: list[str] = []

    text = decode_bytes(data)
    try:
        payload = json.loads(text) if text else {}
    except json.JSONDecodeError as e:
        warnings.append(f"JSON parse failed: {e}")
        return ParseResult(
            mode=ImportMode.HISTORY,
            source_app=SOURCE_APP,
            warnings=warnings,
        )

    program_name = None
    if isinstance(payload, dict):
        program_name = ((payload.get("program") or {}).get("name") or payload.get("program_name"))

    for session in _iter_sessions(payload):
        if not isinstance(session, dict):
            continue
        session_date = session.get("date") or session.get("performed_at") or session.get("start")
        performed_at = parse_datetime(session_date, tz_hint)
        if performed_at is None:
            warnings.append(f"skipping session, unparseable date: {session_date!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)
        workout_name = session.get("name") or session.get("title") or program_name

        for exercise in _iter_exercises(session):
            if not isinstance(exercise, dict):
                continue
            exercise_name = (exercise.get("name") or exercise.get("exercise") or "").strip()
            if not exercise_name:
                continue
            canonical = exercise_name.lower()
            sets_list = exercise.get("sets") or []
            if not isinstance(sets_list, list):
                continue

            for idx, s in enumerate(sets_list, start=1):
                if not isinstance(s, dict):
                    continue
                raw_weight = s.get("weight")
                weight_unit_hint = (s.get("unit") or s.get("weight_unit") or "").lower()
                explicit_unit: Optional[WeightUnit]
                if weight_unit_hint == "kg":
                    explicit_unit = WeightUnit.KG
                elif weight_unit_hint in ("lb", "lbs"):
                    explicit_unit = WeightUnit.LB
                else:
                    explicit_unit = default_unit

                value, unit = parse_weight_cell(
                    None if raw_weight is None else str(raw_weight),
                    default_unit=explicit_unit,
                )
                weight_kg = to_kg(value, unit) if value is not None else None
                reps, is_amrap, _ = parse_reps_cell(
                    None if s.get("reps") is None else str(s.get("reps")),
                )
                if reps is None and weight_kg is None:
                    continue

                rpe = parse_rpe(None if s.get("rpe") is None else str(s.get("rpe")))
                set_type = _set_type_for(s.get("type") or s.get("set_type"))
                if is_amrap and set_type == SetType.WORKING:
                    set_type = SetType.AMRAP

                row_hash = CanonicalSetRow.compute_row_hash(
                    user_id=user_id,
                    source_app=SOURCE_APP,
                    performed_at=performed_at,
                    exercise_name_canonical=canonical,
                    set_number=idx,
                    weight_kg=weight_kg,
                    reps=reps,
                )
                rows.append(CanonicalSetRow(
                    user_id=user_id,
                    performed_at=performed_at,
                    workout_name=workout_name,
                    exercise_name_raw=exercise_name,
                    exercise_name_canonical=canonical,
                    set_number=idx,
                    set_type=set_type,
                    weight_kg=weight_kg,
                    original_weight_value=value,
                    original_weight_unit=unit,
                    reps=reps,
                    rpe=rpe,
                    notes=(s.get("notes") or exercise.get("notes") or None),
                    source_app=SOURCE_APP,
                    source_row_hash=row_hash,
                ))

    preview = [r.model_dump(mode="json") for r in rows[:20]]
    return ParseResult(
        mode=ImportMode.HISTORY,
        source_app=SOURCE_APP,
        strength_rows=rows,
        warnings=warnings,
        sample_rows_for_preview=preview,
    )
