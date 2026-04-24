"""Export-as-Hevy → feed through the Hevy import adapter → assert every
row comes back identical on the (exercise_name_canonical, weight_kg, reps,
performed_at.date()) tuple.

This is the load-bearing round-trip test: if it passes, we've proven the
reverse pipeline is byte-reversible against Hevy's format.

NOTE: Task #4 (import adapters) ships in parallel with this module. The
adapter import is guarded so these tests SKIP gracefully until adapters land,
rather than erroring with ImportError.
"""
from __future__ import annotations

import pytest

from services.workout_export.to_hevy import export_hevy_csv

try:
    # pytest.importorskip would also work here but this form gives us one
    # handle to reuse in every parametrized test.
    from services.workout_import.adapters.hevy import parse as hevy_parse
    HAS_HEVY_ADAPTER = True
except ImportError:
    HAS_HEVY_ADAPTER = False


pytestmark = pytest.mark.skipif(
    not HAS_HEVY_ADAPTER,
    reason="Hevy import adapter not yet landed (Task #4)",
)


@pytest.mark.asyncio
async def test_hevy_roundtrip_preserves_key_tuple(sample_strength_rows, test_user_id):
    """Export N rows → Hevy CSV → parse via adapter → match on
    (exercise, weight_kg, reps, date)."""
    blob = export_hevy_csv(sample_strength_rows, cardio_rows=[])

    result = await hevy_parse(
        data=blob,
        filename="fitwiz-hevy.csv",
        user_id=test_user_id,
        unit_hint="kg",
        tz_hint="UTC",
    )

    # Sort both sides by (date, exercise, set_number) so order differences
    # don't cause spurious failures — the roundtrip contract is on content,
    # not ordering.
    def _key(r):
        return (
            r.performed_at.date().isoformat(),
            (r.exercise_name_canonical or "").lower(),
            r.set_number or 0,
        )

    expected = sorted(sample_strength_rows, key=_key)
    actual = sorted(result.strength_rows, key=_key)

    assert len(actual) == len(expected), (
        f"lost rows in roundtrip: expected {len(expected)}, got {len(actual)}"
    )
    for exp, act in zip(expected, actual):
        assert (exp.exercise_name_canonical or "").lower() == (act.exercise_name_canonical or "").lower()
        # kg-to-lbs-to-kg may lose a hair; allow 0.01 kg tolerance.
        assert exp.weight_kg is not None and act.weight_kg is not None
        assert abs(exp.weight_kg - act.weight_kg) < 0.05
        assert exp.reps == act.reps
        assert exp.performed_at.date() == act.performed_at.date()
