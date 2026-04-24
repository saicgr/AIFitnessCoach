"""Fitbit Takeout JSON adapter tests."""
import json
from pathlib import Path
from uuid import uuid4

import pytest

from services.workout_import.adapters import fitbit
from services.workout_import.canonical import ImportMode

FIX = Path(__file__).parent.parent.parent.parent / "fixtures" / "workout_imports"


@pytest.mark.asyncio
async def test_fitbit_parses_array_skipping_strength():
    data = (FIX / "fitbit_sample.json").read_bytes()
    result = await fitbit.parse(
        data=data, filename="exercise.json", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    # 3 rows: Run, Walk, Weight Training (skip) → 2 cardio.
    assert result.source_app == "fitbit"
    assert len(result.cardio_rows) == 2
    types = {r.activity_type for r in result.cardio_rows}
    assert "run" in types
    assert "walk" in types


@pytest.mark.asyncio
async def test_fitbit_run_ms_to_seconds_conversion():
    data = (FIX / "fitbit_sample.json").read_bytes()
    result = await fitbit.parse(
        data=data, filename="exercise.json", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    run = next(r for r in result.cardio_rows if r.activity_type == "run")
    assert run.duration_seconds == 1860  # 1,860,000 ms
    assert run.avg_heart_rate == 152
    assert run.distance_m == 5600.0  # 5.6 km
    assert run.source_external_id == "98765432"


@pytest.mark.asyncio
async def test_fitbit_walk_mile_unit_converted():
    data = (FIX / "fitbit_sample.json").read_bytes()
    result = await fitbit.parse(
        data=data, filename="exercise.json", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    walk = next(r for r in result.cardio_rows if r.activity_type == "walk")
    # 1.25 mi → ~2011 m
    assert 2000 < (walk.distance_m or 0) < 2020


@pytest.mark.asyncio
async def test_fitbit_wrapped_activities_key():
    """Some scrapers wrap the array under {'activities': [...]}. Ensure we
    unwrap that shape just like the flat array."""
    wrapped = {"activities": [
        {"logId": 1, "activityName": "Run", "duration": 1200000,
         "startTime": "04/01/25 06:00:00", "distance": 3.0,
         "distanceUnit": "Kilometer"},
    ]}
    result = await fitbit.parse(
        data=json.dumps(wrapped).encode(), filename="f.json", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    assert len(result.cardio_rows) == 1
