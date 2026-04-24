"""Smoke test for the generic CSV fallback adapter.

Fuzzy column matching should recognize ``workout_date`` → date,
``movement`` → exercise, ``weight_kg`` → weight (kg), ``repetitions`` → reps,
``set_number`` → set_number.
"""
from __future__ import annotations

import pytest

from services.workout_import.adapters import generic_csv
from services.workout_import.canonical import ImportMode

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_generic_csv_parse_basic(test_user_id):
    data = load_fixture("generic_csv_sample.csv")
    result = await generic_csv.parse(
        data=data,
        filename="mystery_export.csv",
        user_id=test_user_id,
        unit_hint="lb",   # overridden by "weight_kg" column name
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "generic_csv"
    assert result.mode == ImportMode.HISTORY
    assert len(result.strength_rows) == 5

    assert_common_row_invariants(result.strength_rows, "generic_csv")

    # "weight_kg" column name → unit detected as kg even though unit_hint=lb.
    first = result.strength_rows[0]
    assert first.original_weight_unit == "kg"
    assert first.weight_kg == pytest.approx(90.0)

    # set_number honored from the explicit column.
    assert [r.set_number for r in result.strength_rows
            if r.exercise_name_raw == "Front Squat"] == [1, 2, 3]
