"""Smoke tests for the Renaissance Periodization adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode, LoadPrescriptionKind
from services.workout_import.programs import rp

from .conftest import build_rp_xlsx


@pytest.mark.asyncio
async def test_rp_parse_two_weeks(test_user_id):
    data = build_rp_xlsx()
    result = await rp.parse(
        data=data,
        filename="male_physique_template_2.0.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )

    assert result.mode == ImportMode.TEMPLATE
    assert result.template is not None
    assert result.template.total_weeks == 2
    # Week 1 RIR=3 → RPE target = 10 - 3 = 7; week 2 RIR=2 → RPE=8.
    wk1_first = result.template.weeks[0].days[0].exercises[0]
    kind = wk1_first.sets[0].load_prescription.kind
    assert kind == LoadPrescriptionKind.RPE_TARGET.value
    assert wk1_first.sets[0].load_prescription.value_min == pytest.approx(7.0)
    wk2_first = result.template.weeks[1].days[0].exercises[0]
    assert wk2_first.sets[0].load_prescription.value_min == pytest.approx(8.0)
