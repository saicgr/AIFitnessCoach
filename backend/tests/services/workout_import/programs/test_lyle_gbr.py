"""Smoke tests for the Lyle McDonald GBR adapter."""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode
from services.workout_import.programs import lyle_gbr

from .conftest import build_lyle_gbr_xlsx


@pytest.mark.asyncio
async def test_lyle_gbr_parse(test_user_id):
    data = build_lyle_gbr_xlsx()
    result = await lyle_gbr.parse(
        data=data,
        filename="lyle_gbr.xlsx",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )

    # 3 weeks from Wk1/Wk2/Wk3 columns.
    assert result.template is not None
    assert result.template.total_weeks == 3
    # User filled in weights for all 3 weeks → history emitted.
    assert result.mode == ImportMode.PROGRAM_WITH_FILLED_HISTORY
    assert len(result.strength_rows) >= 6  # 2 exercises × 3 weeks
