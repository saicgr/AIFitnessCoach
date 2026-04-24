"""Smoke test for the Gravitus-style generic CSV adapter."""
from __future__ import annotations

import pytest

from services.workout_import.adapters import gravitus
from services.workout_import.canonical import ImportMode

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_gravitus_parse_basic(test_user_id):
    data = load_fixture("gravitus_sample.csv")
    result = await gravitus.parse(
        data=data,
        filename="gravitus.csv",
        user_id=test_user_id,
        unit_hint="lb",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "gravitus"
    assert result.mode == ImportMode.HISTORY
    # 3 barbell rows + 1 pull-up row (weight=0 is valid for bodyweight).
    assert len(result.strength_rows) == 4

    assert_common_row_invariants(result.strength_rows, "gravitus")

    # RPE preserved.
    assert result.strength_rows[0].rpe == pytest.approx(7.0)

    # Bodyweight row kept with weight_kg=0.0.
    pullup = [r for r in result.strength_rows if "Pull" in r.exercise_name_raw][0]
    assert pullup.weight_kg == pytest.approx(0.0)
    assert pullup.reps == 8
