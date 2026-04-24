"""Smoke test for the Boostcamp JSON adapter."""
from __future__ import annotations

import pytest

from services.workout_import.adapters import boostcamp
from services.workout_import.canonical import ImportMode

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_boostcamp_parse_basic(test_user_id):
    data = load_fixture("boostcamp_sample.json")
    result = await boostcamp.parse(
        data=data,
        filename="boostcamp_export.json",
        user_id=test_user_id,
        unit_hint="lb",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "boostcamp"
    assert result.mode == ImportMode.HISTORY
    # 3 squat sets + 2 bench sets = 5.
    assert len(result.strength_rows) == 5

    assert_common_row_invariants(result.strength_rows, "boostcamp")

    # First squat: 225 lb × 8 RPE 7.
    squat_rows = [r for r in result.strength_rows if r.exercise_name_raw == "Back Squat"]
    assert squat_rows[0].reps == 8
    assert squat_rows[0].rpe == pytest.approx(7.0)
    assert squat_rows[0].original_weight_value == pytest.approx(225.0)
    # Unit hint lb → ~102 kg.
    assert squat_rows[0].weight_kg == pytest.approx(102.06, abs=0.1)

    # workout_name carries through.
    assert all(r.workout_name == "Wave 1 - Squat" for r in result.strength_rows)
