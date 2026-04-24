"""Smoke test for the Jefit packed-logs adapter."""
from __future__ import annotations

import pytest

from services.workout_import.adapters import jefit
from services.workout_import.canonical import ImportMode

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_jefit_parse_basic(test_user_id):
    data = load_fixture("jefit_sample.csv")
    result = await jefit.parse(
        data=data,
        filename="jefit_log.csv",
        user_id=test_user_id,
        unit_hint="lb",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "jefit"
    assert result.mode == ImportMode.HISTORY
    # 3 exercises × 3 sets each = 9 rows.
    assert len(result.strength_rows) == 9

    assert_common_row_invariants(result.strength_rows, "jefit")

    # First bench row: 135 lb × 10, set_number=1.
    bench_rows = [r for r in result.strength_rows
                  if r.exercise_name_raw.lower() == "bench press"]
    assert len(bench_rows) == 3
    assert bench_rows[0].set_number == 1
    assert bench_rows[0].reps == 10
    assert bench_rows[0].original_weight_value == pytest.approx(135.0)
    assert bench_rows[0].original_weight_unit == "lb"
    # Converted to kg.
    assert bench_rows[0].weight_kg == pytest.approx(61.23, abs=0.1)

    # set_numbers are sequential per exercise (1..3).
    assert [r.set_number for r in bench_rows] == [1, 2, 3]
