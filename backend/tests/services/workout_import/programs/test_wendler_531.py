"""Smoke tests for the Wendler 5/3/1 adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode, LoadPrescriptionKind
from services.workout_import.programs import wendler_531

from .conftest import build_wendler_xlsx


@pytest.mark.asyncio
async def test_wendler_531_canonical_structure(test_user_id):
    data = build_wendler_xlsx()
    result = await wendler_531.parse(
        data=data,
        filename="531_poteto_v1_28.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )

    assert result.mode == ImportMode.TEMPLATE
    assert result.template is not None
    assert result.template.total_weeks == 4
    assert result.template.days_per_week == 4
    assert result.template.training_max_factor == 0.9  # TM = 0.9 × true 1RM

    # Week 1 squat day — warmups + 3 main sets (last is AMRAP).
    day1 = result.template.weeks[0].days[0]
    lift = day1.exercises[0]
    assert lift.exercise_name_raw == "Back Squat"
    sets = lift.sets
    # 3 warmups + 3 main = 6 sets.
    assert len(sets) == 6
    # Last main set AMRAP flag on week 1.
    assert sets[-1].rep_target.amrap_last is True
    # Every set uses PERCENT_TM prescription.
    for s in sets:
        assert s.load_prescription.kind == LoadPrescriptionKind.PERCENT_TM.value

    # Seed 1RM captured.
    assert result.template.one_rm_inputs.get("squat_kg") == pytest.approx(126)
