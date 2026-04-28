"""Shared fixtures for the workout_export tests."""
from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID, uuid4
from typing import List

import pytest

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
    SetType,
    WeightUnit,
)


@pytest.fixture
def test_user_id() -> UUID:
    # Deterministic UUID so hash-based dedup tests are reproducible.
    return UUID("11111111-1111-1111-1111-111111111111")


def _mk_strength(
    user_id: UUID,
    *,
    performed_at: datetime,
    workout_name: str,
    exercise: str,
    set_number: int,
    weight_kg: float,
    reps: int,
    rpe: float = 8.0,
    set_type: SetType = SetType.WORKING,
    notes: str = "",
) -> CanonicalSetRow:
    source_app = "zealova"
    return CanonicalSetRow(
        user_id=user_id,
        performed_at=performed_at,
        workout_name=workout_name,
        exercise_name_raw=exercise,
        exercise_name_canonical=exercise,
        set_number=set_number,
        set_type=set_type,
        weight_kg=weight_kg,
        original_weight_value=weight_kg,
        original_weight_unit=WeightUnit.KG,
        reps=reps,
        rpe=rpe,
        notes=notes,
        source_app=source_app,
        source_row_hash=CanonicalSetRow.compute_row_hash(
            user_id=user_id,
            source_app=source_app,
            performed_at=performed_at,
            exercise_name_canonical=exercise,
            set_number=set_number,
            weight_kg=weight_kg,
            reps=reps,
        ),
    )


@pytest.fixture
def sample_strength_rows(test_user_id) -> List[CanonicalSetRow]:
    """Three rows across two sessions, matching the smallest meaningful
    dataset for round-trip tests."""
    d1 = datetime(2025, 3, 28, 17, 29, 0, tzinfo=timezone.utc)
    d2 = datetime(2025, 3, 30, 18, 0, 0, tzinfo=timezone.utc)
    return [
        _mk_strength(test_user_id, performed_at=d1, workout_name="Pull Day",
                     exercise="Barbell Row", set_number=1,
                     weight_kg=80.0, reps=8, rpe=7.5),
        _mk_strength(test_user_id, performed_at=d1, workout_name="Pull Day",
                     exercise="Barbell Row", set_number=2,
                     weight_kg=85.0, reps=6, rpe=8.5),
        _mk_strength(test_user_id, performed_at=d2, workout_name="Push Day",
                     exercise="Bench Press", set_number=1,
                     weight_kg=100.0, reps=5, rpe=9.0),
    ]


@pytest.fixture
def sample_cardio_rows(test_user_id) -> List[CanonicalCardioRow]:
    d1 = datetime(2025, 4, 2, 6, 30, 0, tzinfo=timezone.utc)
    return [
        CanonicalCardioRow(
            user_id=test_user_id,
            performed_at=d1,
            activity_type="run",
            duration_seconds=1800,
            distance_m=5000.0,
            avg_heart_rate=155,
            max_heart_rate=172,
            calories=420,
            source_app="zealova",
            source_row_hash=CanonicalCardioRow.compute_row_hash(
                user_id=test_user_id,
                source_app="zealova",
                performed_at=d1,
                activity_type="run",
                duration_seconds=1800,
                distance_m=5000.0,
            ),
        ),
    ]
