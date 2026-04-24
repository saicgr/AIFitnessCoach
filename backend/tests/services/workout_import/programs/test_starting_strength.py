"""Smoke tests for the Starting Strength adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode
from services.workout_import.programs import starting_strength

from .conftest import build_starting_strength_xlsx


@pytest.mark.asyncio
async def test_starting_strength_parse(test_user_id):
    data = build_starting_strength_xlsx()
    result = await starting_strength.parse(
        data=data,
        filename="starting_strength_log.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )

    assert result.template is not None
    assert result.template.days_per_week == 2  # A/B alternation
    day_a = result.template.weeks[0].days[0]
    assert day_a.day_label == "Workout A"
    names_a = [ex.exercise_name_raw for ex in day_a.exercises]
    assert "Back Squat" in names_a
    assert "Bench Press" in names_a
    assert "Deadlift" in names_a

    # Two rows of history (one per date).
    assert len(result.strength_rows) >= 2
    assert any(r.exercise_name_raw == "Back Squat" for r in result.strength_rows)
