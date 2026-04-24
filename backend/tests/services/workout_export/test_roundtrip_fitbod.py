"""Fitbod round-trip. See test_roundtrip_hevy.py for the pattern."""
from __future__ import annotations

import pytest

from services.workout_export.to_fitbod import export_fitbod_csv

try:
    from services.workout_import.adapters.fitbod import parse as fitbod_parse
    HAS_FITBOD_ADAPTER = True
except ImportError:
    HAS_FITBOD_ADAPTER = False


pytestmark = pytest.mark.skipif(
    not HAS_FITBOD_ADAPTER,
    reason="Fitbod import adapter not yet landed (Task #4)",
)


@pytest.mark.asyncio
async def test_fitbod_roundtrip_preserves_key_tuple(sample_strength_rows, test_user_id):
    blob = export_fitbod_csv(sample_strength_rows, [])

    result = await fitbod_parse(
        data=blob,
        filename="fitwiz-fitbod.csv",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
    )

    def _key(r):
        return (
            r.performed_at.date().isoformat(),
            (r.exercise_name_canonical or "").lower(),
        )

    # Fitbod doesn't preserve set_number — roundtrip dedup collapses drop-set
    # rows for the same (exercise, date). Compare on the coarser key.
    expected_rows = sorted(sample_strength_rows, key=_key)
    actual_rows = sorted(result.strength_rows, key=_key)

    assert len(actual_rows) == len(expected_rows)
    for exp, act in zip(expected_rows, actual_rows):
        assert (exp.exercise_name_canonical or "").lower() == (act.exercise_name_canonical or "").lower()
        assert exp.weight_kg is not None and act.weight_kg is not None
        assert abs(exp.weight_kg - act.weight_kg) < 0.05
        assert exp.reps == act.reps
        assert exp.performed_at.date() == act.performed_at.date()
