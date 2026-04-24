"""Garmin FIT binary adapter tests — cardio + strength routing."""
from pathlib import Path
from uuid import uuid4

import pytest

from services.workout_import.adapters import garmin_fit
from services.workout_import.canonical import ImportMode

FIX = Path(__file__).parent.parent.parent.parent / "fixtures" / "workout_imports"


@pytest.mark.asyncio
async def test_garmin_fit_parses_running_session():
    data = (FIX / "garmin_sample_run.fit").read_bytes()
    result = await garmin_fit.parse(
        data=data, filename="run.fit", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    assert result.source_app == "garmin"
    assert len(result.cardio_rows) == 1
    assert result.strength_rows == []
    row = result.cardio_rows[0]
    assert row.activity_type == "run"
    assert row.duration_seconds == 1800
    assert row.distance_m == 5200.0
    assert row.avg_heart_rate == 148
    assert row.max_heart_rate == 172
    assert row.elevation_gain_m == 42.0
    assert row.source_external_id is not None


@pytest.mark.asyncio
async def test_garmin_fit_routes_strength_session_to_strength_rows():
    """Edge case: strength sessions in FIT files must be routed to
    strength_rows (workout_history_imports), not cardio_logs."""
    data = (FIX / "garmin_sample_strength.fit").read_bytes()
    result = await garmin_fit.parse(
        data=data, filename="strength.fit", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    assert result.source_app == "garmin"
    # Strength session → no cardio row
    assert result.cardio_rows == []
    # Two set messages in the fixture
    assert len(result.strength_rows) == 2
    for i, row in enumerate(result.strength_rows):
        assert row.reps == 8
        # Session default weight unit = kg (writer defaulted)
        assert row.weight_kg is not None
        assert row.source_app == "garmin"
        assert row.set_number == i + 1


@pytest.mark.asyncio
async def test_garmin_fit_handles_corrupt_bytes():
    result = await garmin_fit.parse(
        data=b"not a valid fit file" * 100,
        filename="bad.fit", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    # Should return an empty result with a warning, not raise.
    assert result.cardio_rows == []
    assert result.strength_rows == []
    assert result.warnings
