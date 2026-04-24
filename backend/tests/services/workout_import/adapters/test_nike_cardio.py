"""Nike Run Club GPX adapter tests."""
from pathlib import Path
from uuid import uuid4

import pytest

from services.workout_import.adapters import nike_run_club
from services.workout_import.canonical import ImportMode

FIX = Path(__file__).parent.parent.parent.parent / "fixtures" / "workout_imports"


@pytest.mark.asyncio
async def test_nike_parses_gpx_as_run():
    data = (FIX / "nike_sample.gpx").read_bytes()
    result = await nike_run_club.parse(
        data=data, filename="morning.gpx", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    assert result.source_app == "nike"
    assert len(result.cardio_rows) == 1
    run = result.cardio_rows[0]
    assert run.activity_type == "run"
    # 30 min from first to last trkpt (06:15 → 06:45)
    assert run.duration_seconds == 30 * 60
    assert run.distance_m is not None and run.distance_m > 0
    assert run.gps_polyline is not None
    assert run.performed_at.tzinfo is not None
