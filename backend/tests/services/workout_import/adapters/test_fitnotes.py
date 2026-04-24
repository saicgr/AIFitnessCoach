"""Smoke test for the FitNotes dual-unit CSV adapter."""
from __future__ import annotations

import pytest

from services.workout_import.adapters import fitnotes
from services.workout_import.canonical import ImportMode

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_fitnotes_parse_basic(test_user_id):
    data = load_fixture("fitnotes_sample.csv")
    result = await fitnotes.parse(
        data=data,
        filename="fitnotes.csv",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "fitnotes"
    assert result.mode == ImportMode.HISTORY
    # 3 strength rows (cardio row filtered out).
    assert len(result.strength_rows) == 3

    assert_common_row_invariants(result.strength_rows, "fitnotes")

    # kg preferred over lbs when both present.
    squat_rows = [r for r in result.strength_rows
                  if r.exercise_name_raw == "Barbell Squat"]
    assert squat_rows[0].weight_kg == pytest.approx(100.0)
    assert squat_rows[0].original_weight_unit == "kg"

    # No cardio row leaked in.
    assert all(r.exercise_name_raw != "Running" for r in result.strength_rows)
