"""Smoke test for the Fitbod CSV adapter."""
from __future__ import annotations

import pytest

from services.workout_import.adapters import fitbod
from services.workout_import.canonical import ImportMode, SetType

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_fitbod_parse_basic(test_user_id):
    data = load_fixture("fitbod_sample.csv")
    result = await fitbod.parse(
        data=data,
        filename="fitbod_export.csv",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "fitbod"
    assert result.mode == ImportMode.HISTORY

    # multiplier=3 rows explode into 3 rows each.
    # 1 warmup + 3 expanded squats + 1 heavy squat + 3 expanded RDLs = 8 rows.
    assert len(result.strength_rows) == 8

    assert_common_row_invariants(result.strength_rows, "fitbod")

    warmup = result.strength_rows[0]
    assert warmup.set_type == SetType.WARMUP.value
    # Header declares kg, so 60 kg stays 60 kg.
    assert warmup.weight_kg == pytest.approx(60.0)

    # First exploded row has set_number=1 of 3.
    exploded = [r for r in result.strength_rows
                if r.weight_kg == 100.0 and r.set_type == SetType.WORKING.value]
    assert len(exploded) == 3
    assert [r.set_number for r in exploded] == [1, 2, 3]
