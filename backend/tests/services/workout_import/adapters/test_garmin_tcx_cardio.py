"""Garmin TCX adapter tests."""
from pathlib import Path
from uuid import uuid4

import pytest

from services.workout_import.adapters import garmin_tcx
from services.workout_import.canonical import ImportMode

FIX = Path(__file__).parent.parent.parent.parent / "fixtures" / "workout_imports"


@pytest.mark.asyncio
async def test_garmin_tcx_parses_biking_activity_with_laps():
    data = (FIX / "garmin_sample.tcx").read_bytes()
    result = await garmin_tcx.parse(
        data=data, filename="ride.tcx", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    assert result.source_app == "garmin"
    assert len(result.cardio_rows) == 1
    row = result.cardio_rows[0]
    assert row.activity_type == "cycle"
    # Two laps (3600 + 1800 seconds = 5400)
    assert row.duration_seconds == 5400
    assert row.distance_m == 42000.0
    # 3 HR samples: lap avg 142 + trackpoint 120 + trackpoint 160
    # The adapter averages per-trackpoint; we just check it's in range.
    assert row.avg_heart_rate is not None
    assert 120 <= row.avg_heart_rate <= 172
    assert row.max_heart_rate == 172
    assert row.calories == 1000  # 680 + 320
    # Splits_json has two lap entries
    assert row.splits_json and len(row.splits_json) == 2
