"""Smoke test for the MyFitnessPal summary-CSV adapter.

Key assertion: summary rows (Sets=3) explode into per-set canonical rows.
"""
from __future__ import annotations

import pytest

from services.workout_import.adapters import myfitnesspal
from services.workout_import.canonical import ImportMode

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_myfitnesspal_parse_basic(test_user_id):
    data = load_fixture("mfp_sample.csv")
    result = await myfitnesspal.parse(
        data=data,
        filename="mfp_exercise_log.csv",
        user_id=test_user_id,
        unit_hint="lb",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "myfitnesspal"
    assert result.mode == ImportMode.HISTORY
    # 3 bench + 3 squat + 1 deadlift = 7 rows post-explode.
    assert len(result.strength_rows) == 7

    assert_common_row_invariants(result.strength_rows, "myfitnesspal")

    bench_rows = [r for r in result.strength_rows if r.exercise_name_raw == "Bench Press"]
    assert [r.set_number for r in bench_rows] == [1, 2, 3]
    assert all(r.reps == 10 for r in bench_rows)
    # 135 lb → ~61.24 kg (Weight Unit column says lbs).
    assert bench_rows[0].weight_kg == pytest.approx(61.23, abs=0.1)
    assert bench_rows[0].original_weight_unit == "lb"
