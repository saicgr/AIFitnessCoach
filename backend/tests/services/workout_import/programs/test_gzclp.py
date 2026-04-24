"""Smoke tests for the GZCLP adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode
from services.workout_import.programs import gzclp

from .conftest import build_gzclp_xlsx


@pytest.mark.asyncio
async def test_gzclp_parse(test_user_id):
    data = build_gzclp_xlsx()
    result = await gzclp.parse(
        data=data,
        filename="gzclp_v4.5.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )

    assert result.mode == ImportMode.TEMPLATE
    assert result.template is not None
    assert result.template.days_per_week == 4     # A1 / B1 / A2 / B2
    # T1 exercise has 5 sets ending in AMRAP.
    day_a1 = result.template.weeks[0].days[0]
    t1 = day_a1.exercises[0]
    assert len(t1.sets) == 5
    assert t1.sets[-1].rep_target.amrap_last is True
    # T3 exercise — 3×15+.
    t3 = day_a1.exercises[2]
    assert len(t3.sets) == 3
    assert t3.sets[-1].rep_target.amrap_last is True
    assert t3.sets[-1].rep_target.min == 15
