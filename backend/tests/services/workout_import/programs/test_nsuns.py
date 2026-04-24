"""Smoke tests for the nSuns adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode, LoadPrescriptionKind
from services.workout_import.programs import nsuns

from .conftest import build_nsuns_xlsx


@pytest.mark.asyncio
async def test_nsuns_parse(test_user_id):
    data = build_nsuns_xlsx()
    result = await nsuns.parse(
        data=data,
        filename="nsuns_4day.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )

    assert result.mode == ImportMode.TEMPLATE
    assert result.template is not None
    assert result.template.training_max_factor == 0.9  # nSuns uses Wendler TM
    day = result.template.weeks[0].days[0]
    assert day.exercises
    # Last set of Bench Press prescription is AMRAP ("x1+").
    bench = day.exercises[0]
    assert bench.exercise_name_raw == "Bench Press"
    assert bench.sets[-1].rep_target.amrap_last is True
    # Percent-of-TM prescription.
    assert bench.sets[0].load_prescription.kind == LoadPrescriptionKind.PERCENT_TM.value
