"""Smoke test for the Strong CSV adapter."""
from __future__ import annotations

import pytest

from services.workout_import.adapters import strong
from services.workout_import.canonical import ImportMode

from .conftest import assert_common_row_invariants, load_fixture


@pytest.mark.asyncio
async def test_strong_parse_basic(test_user_id):
    data = load_fixture("strong_sample.csv")
    result = await strong.parse(
        data=data,
        filename="strong_export.csv",
        user_id=test_user_id,
        unit_hint="lb",
        tz_hint="America/Chicago",
        mode_hint=None,
    )

    assert result.source_app == "strong"
    assert result.mode == ImportMode.HISTORY
    assert len(result.strength_rows) == 5

    assert_common_row_invariants(result.strength_rows, "strong")

    # Unit hint is lb → 135 lb → ~61.24 kg.
    first = result.strength_rows[0]
    assert first.weight_kg == pytest.approx(61.23, abs=0.1)
    assert first.original_weight_value == pytest.approx(135.0)
    assert first.original_weight_unit == "lb"

    # Duration "1h 12m" → 4320 seconds.
    assert all(r.duration_seconds == 4320 for r in result.strength_rows)
