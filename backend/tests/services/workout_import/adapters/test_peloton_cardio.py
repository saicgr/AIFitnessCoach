"""Peloton CSV adapter tests."""
from pathlib import Path
from uuid import uuid4

import pytest

from services.workout_import.adapters import peloton_csv
from services.workout_import.canonical import ImportMode

FIX = Path(__file__).parent.parent.parent.parent / "fixtures" / "workout_imports"


@pytest.mark.asyncio
async def test_peloton_parses_four_row_csv():
    data = (FIX / "peloton_sample.csv").read_bytes()
    result = await peloton_csv.parse(
        data=data, filename="peloton.csv", user_id=uuid4(),
        unit_hint="lb", tz_hint="America/New_York",
        mode_hint=ImportMode.CARDIO_ONLY,
    )
    # 4 rows; Strength is skipped → 3 cardio rows.
    assert result.source_app == "peloton"
    assert len(result.cardio_rows) == 3


@pytest.mark.asyncio
async def test_peloton_cycling_to_indoor_cycle_with_watts():
    data = (FIX / "peloton_sample.csv").read_bytes()
    result = await peloton_csv.parse(
        data=data, filename="peloton.csv", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    cycling = [r for r in result.cardio_rows if r.activity_type == "indoor_cycle"]
    assert len(cycling) == 1
    c = cycling[0]
    assert c.duration_seconds == 30 * 60
    assert c.avg_watts == 175
    assert c.avg_cadence == 85
    assert c.source_external_id == "ABC123"
    assert c.calories == 380
    # Distance: 9.24 mi → ~14870 m
    assert 14000 < (c.distance_m or 0) < 15500


@pytest.mark.asyncio
async def test_peloton_running_class():
    data = (FIX / "peloton_sample.csv").read_bytes()
    result = await peloton_csv.parse(
        data=data, filename="peloton.csv", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    runs = [r for r in result.cardio_rows if r.activity_type == "run"]
    assert len(runs) == 1
    # 2.45 mi in 20 min
    assert runs[0].duration_seconds == 20 * 60
    assert 3800 < (runs[0].distance_m or 0) < 4100


@pytest.mark.asyncio
async def test_peloton_strength_skipped():
    data = (FIX / "peloton_sample.csv").read_bytes()
    result = await peloton_csv.parse(
        data=data, filename="peloton.csv", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    for r in result.cardio_rows:
        assert r.activity_type != "strength"
        # "Andy Speer strength class" was the 4th row — should not appear.
        assert r.source_external_id != "JKL012"
