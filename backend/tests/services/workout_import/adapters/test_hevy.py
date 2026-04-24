"""Smoke test for the Hevy CSV adapter."""
from __future__ import annotations

import pytest

from services.workout_import.adapters import hevy
from services.workout_import.canonical import ImportMode, SetType

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_hevy_parse_basic(test_user_id):
    data = load_fixture("hevy_sample.csv")
    result = await hevy.parse(
        data=data,
        filename="hevy_workouts.csv",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "hevy"
    assert result.mode == ImportMode.HISTORY
    assert len(result.strength_rows) == 6

    assert_common_row_invariants(result.strength_rows, "hevy")

    # Set types are mapped from Hevy's vocabulary.
    first = result.strength_rows[0]
    assert first.set_type == SetType.WARMUP.value
    assert first.weight_kg == pytest.approx(60.0, rel=1e-3)

    working = result.strength_rows[1]
    assert working.set_type == SetType.WORKING.value
    assert working.set_number == 2  # 0-indexed Set Index 1 → 1-indexed 2
    assert working.rpe == pytest.approx(7.5)

    failure = result.strength_rows[3]
    assert failure.set_type == SetType.FAILURE.value

    # Superset ID preserved from fixture's dumbbell rows.
    ohp_rows = [r for r in result.strength_rows if r.exercise_name_raw.startswith("Overhead")]
    assert all(r.superset_id == "abc123" for r in ohp_rows)

    # Preview matches first 20 rows.
    assert len(result.sample_rows_for_preview) == len(result.strength_rows)
