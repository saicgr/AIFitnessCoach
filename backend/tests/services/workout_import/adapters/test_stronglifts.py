"""Smoke test for the StrongLifts adapter (slash-joined Sets & Reps)."""
from __future__ import annotations

import pytest

from services.workout_import.adapters import stronglifts
from services.workout_import.canonical import ImportMode

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_stronglifts_parse_basic(test_user_id):
    data = load_fixture("stronglifts_sample.csv")
    result = await stronglifts.parse(
        data=data,
        filename="stronglifts.csv",
        user_id=test_user_id,
        unit_hint="lb",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "stronglifts"
    assert result.mode == ImportMode.HISTORY
    # Workout A: Squat 5, Bench 5, Row 5 → 15 rows.
    # Workout B: Squat 5 → 5 rows.
    assert len(result.strength_rows) == 20

    assert_common_row_invariants(result.strength_rows, "stronglifts")

    squat_day1 = [r for r in result.strength_rows
                  if r.exercise_name_raw == "Squat"
                  and r.performed_at.date().isoformat() == "2026-03-18"]
    assert [r.reps for r in squat_day1] == [5, 5, 5, 5, 3]
    assert [r.set_number for r in squat_day1] == [1, 2, 3, 4, 5]
    # 225 lb honored (Unit column = lb).
    assert squat_day1[0].weight_kg == pytest.approx(102.06, abs=0.1)
    assert squat_day1[0].original_weight_unit == "lb"
