"""Apple Health XML streaming adapter tests (edge case #103)."""
from pathlib import Path
from uuid import uuid4

import pytest

from services.workout_import.adapters import apple_health_xml
from services.workout_import.canonical import ImportMode

FIX = Path(__file__).parent.parent.parent.parent / "fixtures" / "workout_imports"


@pytest.mark.asyncio
async def test_apple_health_parses_workouts_and_skips_strength():
    data = (FIX / "apple_health_sample.xml").read_bytes()
    result = await apple_health_xml.parse(
        data=data, filename="export.xml", user_id=uuid4(),
        unit_hint="lb", tz_hint="America/New_York",
        mode_hint=ImportMode.CARDIO_ONLY,
    )
    # 4 workouts in fixture: Run, Cycling, TraditionalStrengthTraining (skip),
    # HighIntensityIntervalTraining → 3 cardio rows.
    assert result.source_app == "apple_health"
    assert len(result.cardio_rows) == 3
    types = {r.activity_type for r in result.cardio_rows}
    assert "run" in types
    assert "cycle" in types
    assert "hiit" in types
    # Strength session must NOT land in cardio.
    # We don't have strength_rows here since Apple Health workouts don't
    # carry per-set data — they're simply dropped.


@pytest.mark.asyncio
async def test_apple_health_run_units_converted():
    data = (FIX / "apple_health_sample.xml").read_bytes()
    result = await apple_health_xml.parse(
        data=data, filename="export.xml", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    run = next(r for r in result.cardio_rows if r.activity_type == "run")
    # 7.3 km → 7300 m
    assert run.distance_m == 7300.0
    # 45.5 min → 2730 s
    assert run.duration_seconds == 2730
    assert run.calories == 420


@pytest.mark.asyncio
async def test_apple_health_streaming_is_memory_bounded():
    """Create a synthetic 100-workout XML and confirm the parser handles it.
    Real exports hit 200MB+ but our CI fixture only validates the pattern."""
    header = "<?xml version='1.0' encoding='UTF-8'?>\n<HealthData locale='en_US'>\n"
    footer = "\n</HealthData>\n"
    body = []
    for i in range(100):
        body.append(
            f"<Workout workoutActivityType='HKWorkoutActivityTypeRunning' "
            f"duration='30' durationUnit='min' totalDistance='5' "
            f"totalDistanceUnit='km' sourceName='Apple Watch' "
            f"startDate='2025-0{(i%9)+1}-01 12:00:00 -0400' "
            f"endDate='2025-0{(i%9)+1}-01 12:30:00 -0400'/>"
        )
    blob = (header + "\n".join(body) + footer).encode("utf-8")
    result = await apple_health_xml.parse(
        data=blob, filename="big.xml", user_id=uuid4(),
        unit_hint="lb", tz_hint="UTC", mode_hint=ImportMode.CARDIO_ONLY,
    )
    # All 100 should parse — hashes collide where dates match (9 unique dates),
    # but hash dedup happens at the DB layer, not here.
    assert len(result.cardio_rows) == 100
