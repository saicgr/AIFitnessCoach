"""Strava bulk-export adapter tests."""
import os
from pathlib import Path
from uuid import uuid4

import pytest

from services.workout_import.adapters import strava_export
from services.workout_import.canonical import ImportMode

FIX = Path(__file__).parent.parent.parent.parent / "fixtures" / "workout_imports"


@pytest.mark.asyncio
async def test_strava_parses_activities_csv_in_zip():
    data = (FIX / "strava_sample.zip").read_bytes()
    user_id = uuid4()
    result = await strava_export.parse(
        data=data, filename="strava_sample.zip", user_id=user_id,
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    assert result.source_app == "strava"
    assert result.mode == ImportMode.CARDIO_ONLY
    # 4 rows in fixture — Run, VirtualRide, Hike, WeightTraining;
    # WeightTraining is routed to strength path (skipped here) → 3 cardio rows.
    assert len(result.cardio_rows) == 3

    rows_by_type = {r.activity_type: r for r in result.cardio_rows}
    assert "run" in rows_by_type
    assert "indoor_cycle" in rows_by_type  # VirtualRide → indoor_cycle
    assert "hike" in rows_by_type

    run = rows_by_type["run"]
    assert run.duration_seconds == 3600
    assert 10000 < run.distance_m < 11000  # 10.5 km → ~10500 m
    assert run.avg_heart_rate == 148
    assert run.max_heart_rate == 172
    assert run.calories == 620
    assert run.source_external_id == "11111111111"
    assert run.gps_polyline is not None  # decorated from per-activity GPX
    assert run.source_row_hash  # stable hash


@pytest.mark.asyncio
async def test_strava_skips_strength_rows():
    """Strava `WeightTraining` activity type should NOT produce cardio rows."""
    data = (FIX / "strava_sample.zip").read_bytes()
    result = await strava_export.parse(
        data=data, filename="strava_sample.zip", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    for row in result.cardio_rows:
        assert "weight" not in row.activity_type.lower()
        assert "strength" not in row.activity_type.lower()


@pytest.mark.asyncio
async def test_strava_hash_is_deterministic():
    data = (FIX / "strava_sample.zip").read_bytes()
    user_id = uuid4()
    r1 = await strava_export.parse(
        data=data, filename="s.zip", user_id=user_id,
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    r2 = await strava_export.parse(
        data=data, filename="s.zip", user_id=user_id,
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    hashes_1 = {r.source_row_hash for r in r1.cardio_rows}
    hashes_2 = {r.source_row_hash for r in r2.cardio_rows}
    assert hashes_1 == hashes_2
