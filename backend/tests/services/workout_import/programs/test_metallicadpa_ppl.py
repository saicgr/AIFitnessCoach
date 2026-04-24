"""Smoke tests for the Metallicadpa PPL adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode
from services.workout_import.programs import metallicadpa_ppl

from .conftest import build_metallicadpa_xlsx


@pytest.mark.asyncio
async def test_metallicadpa_parse(test_user_id):
    data = build_metallicadpa_xlsx()
    result = await metallicadpa_ppl.parse(
        data=data,
        filename="metallicadpa_ppl.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )

    # Bench Press row has actual weight + reps done → history present.
    assert result.mode == ImportMode.PROGRAM_WITH_FILLED_HISTORY
    assert result.template is not None
    assert len(result.strength_rows) == 1
    row = result.strength_rows[0]
    assert row.exercise_name_raw == "Bench Press"
    assert row.weight_kg == pytest.approx(82.5, rel=1e-3)
    assert row.reps == 5

    # Bench prescription has 4 sets, last AMRAP ("5/5+").
    day = result.template.weeks[0].days[0]
    bench = day.exercises[0]
    assert len(bench.sets) == 4
    assert bench.sets[-1].rep_target.amrap_last is True
