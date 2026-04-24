"""Smoke tests for the StrongLifts CSV adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode
from services.workout_import.programs import stronglifts

from .conftest import build_stronglifts_csv


@pytest.mark.asyncio
async def test_stronglifts_parse(test_user_id):
    data = build_stronglifts_csv()
    result = await stronglifts.parse(
        data=data,
        filename="stronglifts_export.csv",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.HISTORY,
    )

    # Both rows have slash reps → 5 + 5 sets emitted.
    assert result.mode == ImportMode.PROGRAM_WITH_FILLED_HISTORY
    assert len(result.strength_rows) == 10  # 5 sets squat + 5 sets bench
    squat_rows = [r for r in result.strength_rows if r.exercise_name_raw == "Squat"]
    assert len(squat_rows) == 5
    assert squat_rows[0].reps == 5
    # The template is also produced so user can run it standalone.
    assert result.template is not None
    assert result.template.program_name.startswith("StrongLifts")
