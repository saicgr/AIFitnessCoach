"""Strong round-trip. See test_roundtrip_hevy.py for the pattern."""
from __future__ import annotations

import pytest

from services.workout_export.to_strong import export_strong_csv

try:
    from services.workout_import.adapters.strong import parse as strong_parse
    HAS_STRONG_ADAPTER = True
except ImportError:
    HAS_STRONG_ADAPTER = False


pytestmark = pytest.mark.skipif(
    not HAS_STRONG_ADAPTER,
    reason="Strong import adapter not yet landed (Task #4)",
)


@pytest.mark.asyncio
async def test_strong_roundtrip_preserves_key_tuple(sample_strength_rows, test_user_id):
    blob = export_strong_csv(sample_strength_rows, [], user_unit="kg")

    result = await strong_parse(
        data=blob,
        filename="fitwiz-strong.csv",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
    )

    def _key(r):
        return (
            r.performed_at.date().isoformat(),
            (r.exercise_name_canonical or "").lower(),
            r.set_number or 0,
        )

    expected = sorted(sample_strength_rows, key=_key)
    actual = sorted(result.strength_rows, key=_key)

    assert len(actual) == len(expected)
    for exp, act in zip(expected, actual):
        assert (exp.exercise_name_canonical or "").lower() == (act.exercise_name_canonical or "").lower()
        assert exp.weight_kg is not None and act.weight_kg is not None
        assert abs(exp.weight_kg - act.weight_kg) < 0.05
        assert exp.reps == act.reps
        assert exp.performed_at.date() == act.performed_at.date()
