"""Smoke tests for the Jeff Nippard adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import (
    ImportMode,
    LoadPrescriptionKind,
)
from services.workout_import.programs import nippard

from .conftest import build_nippard_xlsx


@pytest.mark.asyncio
async def test_nippard_parse_basic(test_user_id):
    data = build_nippard_xlsx()
    result = await nippard.parse(
        data=data,
        filename="Jeff Nippard Powerbuilding v3.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="America/Chicago",
        mode_hint=ImportMode.TEMPLATE,
    )

    # Adapter should find both the template and the user-filled history row.
    assert result.template is not None
    assert result.mode == ImportMode.PROGRAM_WITH_FILLED_HISTORY
    assert result.template.program_creator == "Jeff Nippard"
    assert result.template.total_weeks >= 1
    assert result.template.unit_hint in ("kg", "lb")

    weeks = result.template.weeks
    assert weeks, "expected at least one prescribed week"
    day = weeks[0].days[0]
    names = [ex.exercise_name_raw for ex in day.exercises]
    assert "Back Squat" in names
    assert "Overhead Press" in names

    back_squat = next(ex for ex in day.exercises if ex.exercise_name_raw == "Back Squat")
    # 75-80% percent-of-1RM captured.
    first_set = back_squat.sets[0]
    assert first_set.load_prescription.kind == LoadPrescriptionKind.PERCENT_1RM.value
    assert first_set.load_prescription.value_min == pytest.approx(0.75)
    assert first_set.load_prescription.value_max == pytest.approx(0.80)
    # Reference canonical lift correctly.
    assert first_set.load_prescription.reference_1rm_exercise == "back_squat"

    # 1RM inputs captured from header.
    assert result.template.one_rm_inputs.get("squat_kg") == pytest.approx(140)

    # Filled history row for Back Squat.
    assert len(result.strength_rows) >= 1
    hist = result.strength_rows[0]
    assert hist.exercise_name_raw == "Back Squat"
    assert hist.weight_kg == pytest.approx(105, rel=1e-3)
    assert hist.reps == 5
