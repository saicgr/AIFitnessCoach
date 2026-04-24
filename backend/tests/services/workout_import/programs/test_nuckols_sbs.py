"""Smoke tests for the Greg Nuckols / Stronger By Science 28-Programs adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode
from services.workout_import.programs import nuckols_sbs

from .conftest import build_nuckols_sbs_xlsx


@pytest.mark.asyncio
async def test_nuckols_sbs_parse(test_user_id):
    data = build_nuckols_sbs_xlsx()
    result = await nuckols_sbs.parse(
        data=data,
        filename="greg_nuckols_28_programs.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )

    # Filled history present (Week 2 Day 1 has Sets Completed + Reps on Last Set).
    assert result.mode == ImportMode.PROGRAM_WITH_FILLED_HISTORY
    assert result.template is not None
    assert result.template.program_creator.startswith("Greg Nuckols")
    assert result.template.total_weeks == 2

    # Squat prescription reference.
    wk1 = result.template.weeks[0]
    day = wk1.days[0]
    # Adapter emits "Back Squat" (canonicalized from tab name "Squat 3-day Medium").
    assert day.exercises[0].exercise_name_raw == "Back Squat"
    lp = day.exercises[0].sets[0].load_prescription
    assert lp.value_min == pytest.approx(0.80)

    # Filled row from Week 2.
    assert len(result.strength_rows) == 1
    row = result.strength_rows[0]
    assert row.reps == 4
    assert row.set_number == 5  # Sets Completed = 5
