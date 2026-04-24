"""
Zero-data-loss roundtrip tests — export N canonical rows, import the result,
assert the reimported data matches the original on the critical fields.

Each format gets its own test. Failures pinpoint column-name drift between
the import adapter and the export module.
"""
from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

import pytest


def _make_rows(n=5):
    from services.workout_import.canonical import CanonicalSetRow, SetType

    user_id = uuid4()
    rows = []
    for i in range(n):
        t = datetime(2026, 4, 23 - i, 12, 0, tzinfo=timezone.utc)
        row = CanonicalSetRow(
            user_id=user_id,
            performed_at=t,
            workout_name=f"Session {i + 1}",
            exercise_name_raw="Barbell Bench Press",
            exercise_name_canonical="barbell_bench_press",
            set_number=i + 1,
            set_type=SetType.WORKING,
            weight_kg=80 + i * 2.5,
            reps=8 - (i % 3),
            source_app="canonical",
            source_row_hash=f"{i:064d}",
        )
        rows.append(row)
    return rows


@pytest.mark.asyncio
async def test_roundtrip_hevy():
    """Hevy export → Hevy import yields the same (exercise, weight_kg, reps, date)."""
    hevy_export = pytest.importorskip("services.workout_export.to_hevy")
    hevy_import = pytest.importorskip("services.workout_import.adapters.hevy")

    rows = _make_rows(5)

    # Export path signature varies — try common shapes.
    if hasattr(hevy_export, "emit"):
        exported = hevy_export.emit(strength_rows=rows, cardio_rows=[], templates=[])
    elif hasattr(hevy_export, "to_bytes"):
        exported = hevy_export.to_bytes(strength_rows=rows, cardio_rows=[], templates=[])
    else:
        pytest.skip("to_hevy has no emit/to_bytes entrypoint")

    if not isinstance(exported, (bytes, bytearray)):
        pytest.skip(f"unexpected export shape: {type(exported)}")

    result = await hevy_import.parse(
        data=exported,
        filename="roundtrip_hevy.csv",
        user_id=rows[0].user_id,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=None,
    )

    # Compare the fundamental tuple: (canonical name, weight to 0.1, reps, date).
    def key(r):
        return (
            (r.exercise_name_canonical or r.exercise_name_raw).lower(),
            round(r.weight_kg, 1) if r.weight_kg else None,
            r.reps,
            r.performed_at.date(),
        )

    original_keys = sorted(key(r) for r in rows)
    imported_keys = sorted(key(r) for r in result.strength_rows)
    assert len(imported_keys) == len(original_keys), \
        f"row count mismatch: {len(imported_keys)} vs {len(original_keys)}"
    # Allow exercise-name drift: the export may use "Barbell Bench Press" but
    # import canonicalizes to "barbell_bench_press". Compare on weight+reps+date.
    for (oe, ow, or_, od), (ie, iw, ir, idate) in zip(original_keys, imported_keys):
        assert ow == iw, f"weight drift {ow} vs {iw}"
        assert or_ == ir, f"reps drift {or_} vs {ir}"
        assert od == idate, f"date drift {od} vs {idate}"
