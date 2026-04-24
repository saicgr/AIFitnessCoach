"""Shared fixtures for adapter tests."""
from __future__ import annotations

import os
from pathlib import Path
from uuid import UUID

import pytest

FIXTURE_DIR = Path(__file__).resolve().parents[3] / "fixtures" / "workout_imports"
TEST_USER_ID = UUID("11111111-1111-1111-1111-111111111111")


def load_fixture(name: str) -> bytes:
    path = FIXTURE_DIR / name
    return path.read_bytes()


@pytest.fixture
def test_user_id() -> UUID:
    return TEST_USER_ID


@pytest.fixture
def fixture_dir() -> Path:
    return FIXTURE_DIR


def assert_common_row_invariants(rows, source_app: str):
    """Assertions every adapter's output must satisfy."""
    assert len(rows) > 0, f"{source_app} adapter produced no rows"
    for row in rows:
        # tz-aware timestamp
        assert row.performed_at.tzinfo is not None, (
            f"{source_app}: performed_at must be tz-aware"
        )
        # source_app matches
        assert row.source_app == source_app or row.source_app.startswith(source_app), (
            f"{source_app}: unexpected source_app {row.source_app}"
        )
        # row hash present and correct length
        assert row.source_row_hash, f"{source_app}: missing source_row_hash"
        assert len(row.source_row_hash) == 64, (
            f"{source_app}: source_row_hash must be 64 hex chars, got "
            f"{len(row.source_row_hash)}"
        )
        # exercise name populated
        assert row.exercise_name_raw, f"{source_app}: missing exercise_name_raw"
    # At least one set has a positive weight (fixtures are designed that way).
    assert any(
        (r.weight_kg or 0) > 0 for r in rows
    ), f"{source_app}: expected at least one row with positive weight_kg"
