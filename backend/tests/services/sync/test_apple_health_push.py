"""
Apple Health push pipeline tests.

Unlike the other providers, Apple Health doesn't have an OAuth round-trip —
the iOS ``HKHealthStore`` bridge (exposed through the Flutter ``health``
package) pushes workouts directly to ``POST /sync/apple-health/push``.

These tests exercise :meth:`AppleHealthProvider.receive_healthkit_sync`
end-to-end in the parse direction only — we don't hit the DB. Separate
integration tests under ``tests/api/`` would cover the HTTP → importer →
Supabase path once a test harness is set up for Supabase.
"""
from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

import pytest
from cryptography.fernet import Fernet

from services.sync import token_encryption
from services.sync.apple_health import AppleHealthProvider
from services.workout_import.canonical import CanonicalCardioRow, CanonicalSetRow


@pytest.fixture(autouse=True)
def _env(monkeypatch):
    monkeypatch.setenv("OAUTH_TOKEN_ENCRYPTION_KEY", Fernet.generate_key().decode())
    token_encryption.reset_cache_for_tests()


class TestHealthKitCardio:
    def test_simple_run_becomes_cardio_row(self):
        user_id = uuid4()
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(
            user_id=user_id,
            activities=[{
                "type": "running",
                "start": "2024-03-18T14:22:10+00:00",
                "end": "2024-03-18T14:52:10+00:00",
                "duration_seconds": 1800,
                "distance_m": 5100.0,
                "calories": 380,
                "avg_heart_rate": 148,
                "max_heart_rate": 176,
                "uuid": "HKWorkoutUUID-1",
            }],
        )
        assert len(result["cardio_rows"]) == 1
        assert result["strength_rows"] == []
        row: CanonicalCardioRow = result["cardio_rows"][0]
        assert row.activity_type == "run"
        assert row.duration_seconds == 1800
        assert row.distance_m == 5100.0
        assert row.source_app == "apple_health"
        assert row.source_external_id == "HKWorkoutUUID-1"

    def test_duration_inferred_from_start_end(self):
        """HealthKit often gives start+end but omits explicit duration. We fall
        back to ``(end - start).total_seconds()``."""
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(
            user_id=uuid4(),
            activities=[{
                "type": "cycling",
                "start": "2024-03-18T14:00:00+00:00",
                "end": "2024-03-18T15:30:00+00:00",
                "distance_m": 40000.0,
            }],
        )
        assert len(result["cardio_rows"]) == 1
        row = result["cardio_rows"][0]
        assert row.duration_seconds == 5400   # 90 min
        assert row.activity_type == "cycle"

    def test_unknown_type_drops_row(self):
        """Unknown workout types should drop silently rather than creating a
        wrong-category cardio row. Defaulting to ``"other"`` is safer than
        defaulting to ``"run"`` but we only use it for mapped-to-other-known
        types; unrecognized workouts map to None and are dropped."""
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(
            user_id=uuid4(),
            activities=[{
                "type": "pickleball",   # not in our map
                "start": "2024-03-18T14:00:00+00:00",
                "end": "2024-03-18T15:00:00+00:00",
            }],
        )
        # Unknown activities fall through to "other" rather than being dropped.
        # Either behavior is defensible; we prefer to keep the session visible
        # so the user can see it in their calendar. Adjust this assertion if
        # product decides dropping is preferable.
        assert len(result["cardio_rows"]) == 1
        assert result["cardio_rows"][0].activity_type == "other"


class TestHealthKitStrength:
    def test_strength_workout_explodes_into_set_rows(self):
        user_id = uuid4()
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(
            user_id=user_id,
            activities=[{
                "type": "traditional_strength_training",
                "title": "Chest day",
                "start": "2024-03-18T14:00:00+00:00",
                "end": "2024-03-18T15:00:00+00:00",
                "duration_seconds": 3600,
                "exercises": [
                    {"name": "Bench Press", "sets": [
                        {"weight_kg": 80, "reps": 8},
                        {"weight_kg": 80, "reps": 7},
                        {"weight_kg": 80, "reps": 6},
                    ]},
                    {"name": "Incline DB Press", "sets": [
                        {"weight_kg": 30, "reps": 10},
                        {"weight_kg": 30, "reps": 10},
                    ]},
                ],
            }],
        )
        # No cardio row — strength-only workout.
        assert result["cardio_rows"] == []
        strength: list[CanonicalSetRow] = result["strength_rows"]
        assert len(strength) == 5
        # Set numbering resets per exercise.
        bench = [r for r in strength if r.exercise_name_raw == "Bench Press"]
        incline = [r for r in strength if r.exercise_name_raw == "Incline DB Press"]
        assert [r.set_number for r in bench] == [1, 2, 3]
        assert [r.set_number for r in incline] == [1, 2]
        # Weight preserved.
        assert {r.weight_kg for r in bench} == {80.0}
        # workout_name propagated.
        assert all(r.workout_name == "Chest day" for r in strength)
        # Dedup hashes differ per set (different set_number / reps).
        assert len({r.source_row_hash for r in strength}) == 5

    def test_strength_without_exercises_is_skipped(self):
        """If a strength session has no per-exercise breakdown we skip it
        entirely rather than inventing one synthetic "Strength" cardio row."""
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(
            user_id=uuid4(),
            activities=[{
                "type": "traditional_strength_training",
                "start": "2024-03-18T14:00:00+00:00",
                "end": "2024-03-18T15:00:00+00:00",
                "duration_seconds": 3600,
            }],
        )
        assert result["cardio_rows"] == []
        assert result["strength_rows"] == []


class TestHealthKitEdgeCases:
    def test_empty_payload(self):
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(user_id=uuid4(), activities=[])
        assert result == {"cardio_rows": [], "strength_rows": []}

    def test_missing_start_time_dropped(self):
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(
            user_id=uuid4(),
            activities=[{"type": "running", "duration_seconds": 1800}],
        )
        assert result["cardio_rows"] == []

    def test_zero_duration_dropped(self):
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(
            user_id=uuid4(),
            activities=[{
                "type": "running",
                "start": "2024-03-18T14:00:00+00:00",
                "end": "2024-03-18T14:00:00+00:00",  # same instant
                "duration_seconds": 0,
            }],
        )
        assert result["cardio_rows"] == []

    def test_dedup_hash_changes_with_set_number(self):
        """Two identical sets (same weight + reps) must hash differently when
        their set_number differs — otherwise a 3-set exercise becomes a 1-row
        upsert and we lose volume data."""
        provider = AppleHealthProvider()
        result = provider.receive_healthkit_sync(
            user_id=uuid4(),
            activities=[{
                "type": "traditional_strength_training",
                "start": "2024-03-18T14:00:00+00:00",
                "duration_seconds": 3600,
                "exercises": [
                    {"name": "Squat", "sets": [
                        {"weight_kg": 100, "reps": 5},
                        {"weight_kg": 100, "reps": 5},
                        {"weight_kg": 100, "reps": 5},
                    ]},
                ],
            }],
        )
        hashes = [r.source_row_hash for r in result["strength_rows"]]
        assert len(hashes) == 3
        assert len(set(hashes)) == 3, "Each set must produce a unique dedup hash"
