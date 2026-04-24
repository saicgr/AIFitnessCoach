"""Generic GPX fallback adapter tests."""
from pathlib import Path
from uuid import uuid4

import pytest

from services.workout_import.adapters import generic_gpx
from services.workout_import.canonical import ImportMode

FIX = Path(__file__).parent.parent.parent.parent / "fixtures" / "workout_imports"


@pytest.mark.asyncio
async def test_generic_gpx_extracts_cycling_type():
    data = (FIX / "generic_gpx_sample.gpx").read_bytes()
    result = await generic_gpx.parse(
        data=data, filename="ride.gpx", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    assert result.source_app == "generic_gpx"
    assert len(result.cardio_rows) == 1
    row = result.cardio_rows[0]
    # <type>cycling</type> → cycle
    assert row.activity_type == "cycle"
    assert row.duration_seconds == 60 * 60  # 07:00 → 08:00
    assert row.elevation_gain_m is not None and row.elevation_gain_m > 0
    assert row.gps_polyline is not None


@pytest.mark.asyncio
async def test_generic_gpx_hash_stable_cross_call():
    data = (FIX / "generic_gpx_sample.gpx").read_bytes()
    user_id = uuid4()
    r1 = await generic_gpx.parse(
        data=data, filename="r.gpx", user_id=user_id,
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    r2 = await generic_gpx.parse(
        data=data, filename="r.gpx", user_id=user_id,
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    assert r1.cardio_rows[0].source_row_hash == r2.cardio_rows[0].source_row_hash
