"""Smoke tests for the generic sheet fallback adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode
from services.workout_import.programs import generic_sheet, generic_xlsx, generic_xlsm

from .conftest import build_generic_sheet_xlsx


@pytest.mark.asyncio
async def test_generic_sheet_parse(test_user_id):
    data = build_generic_sheet_xlsx()
    result = await generic_sheet.parse(
        data=data,
        filename="my_workout_tracker.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.AMBIGUOUS,
    )

    # Should materialize a template from the 'Set 1..Set 4' layout.
    assert result.template is not None
    day = result.template.weeks[0].days[0]
    names = [ex.exercise_name_raw for ex in day.exercises]
    assert "Bench Press" in names
    # Filled history for every set with both reps + weight.
    assert result.strength_rows


@pytest.mark.asyncio
async def test_generic_xlsx_alias(test_user_id):
    data = build_generic_sheet_xlsx()
    result = await generic_xlsx.parse(
        data=data, filename="x.xlsx", user_id=test_user_id,
        unit_hint="kg", tz_hint="UTC", mode_hint=ImportMode.AMBIGUOUS,
    )
    assert result.template is not None


@pytest.mark.asyncio
async def test_generic_xlsm_alias(test_user_id):
    data = build_generic_sheet_xlsx()
    result = await generic_xlsm.parse(
        data=data, filename="x.xlsm", user_id=test_user_id,
        unit_hint="kg", tz_hint="UTC", mode_hint=ImportMode.AMBIGUOUS,
    )
    assert result.template is not None
