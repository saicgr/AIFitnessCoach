"""
End-to-end workout-import pipeline test using the checked-in Hevy fixture.

Mocks Supabase + Chroma so we exercise the real detect → dispatch → resolve →
upsert → index code paths without requiring live credentials.
"""
from __future__ import annotations

import asyncio
import os
from unittest.mock import patch, AsyncMock
from uuid import uuid4

import pytest


HEVY_FIXTURE = "hevy_sample.csv"


def _load_fixture(fixtures_dir, name):
    path = os.path.join(fixtures_dir, name)
    if not os.path.exists(path):
        pytest.skip(f"fixture not found: {path}")
    with open(path, "rb") as f:
        return f.read()


def _build_job(user_id, s3_key="test/hevy.csv", dry_run=False, filename="hevy_sample.csv"):
    return {
        "id": str(uuid4()),
        "user_id": str(user_id),
        "s3_keys": [s3_key],
        "params": {
            "user_id": str(user_id),
            "unit_hint": "lb",
            "timezone_hint": "UTC",
            "filename": filename,
            "dry_run": dry_run,
        },
    }


@pytest.mark.asyncio
async def test_dry_run_returns_preview_without_writes(
    fake_db, fake_chroma, fake_user_id, fixtures_dir
):
    from services.workout_import.service import WorkoutHistoryImporter

    data = _load_fixture(fixtures_dir, HEVY_FIXTURE)
    job = _build_job(fake_user_id, dry_run=True)

    with patch("services.workout_import.service._download_s3_bytes",
               AsyncMock(return_value=data)):
        importer = WorkoutHistoryImporter()
        result = await importer.run(job)

    assert result["dry_run"] is True
    assert result["source_app"] in ("hevy", "generic_csv")
    # Nothing should have been written to the DB on a dry run.
    assert "inserts" not in fake_db.client._stores.get("workout_history_imports", {})
    assert result["strength_row_count"] > 0


@pytest.mark.asyncio
async def test_full_run_writes_rows(fake_db, fake_chroma, fake_user_id, fixtures_dir):
    from services.workout_import.service import WorkoutHistoryImporter

    data = _load_fixture(fixtures_dir, HEVY_FIXTURE)
    job = _build_job(fake_user_id, dry_run=False)

    with patch("services.workout_import.service._download_s3_bytes",
               AsyncMock(return_value=data)):
        importer = WorkoutHistoryImporter()
        result = await importer.run(job)

    assert result["dry_run"] is False
    # At least one row upserted into workout_history_imports.
    upserts = fake_db.client._stores.get("workout_history_imports", {}).get("upserts", [])
    assert len(upserts) > 0
    assert result["inserted_strength_rows"] > 0
    # Every row has the import_job_id set for provenance.
    assert all(r.get("import_job_id") == job["id"] for r in upserts)


@pytest.mark.asyncio
async def test_reimport_is_idempotent(
    fake_db, fake_chroma, fake_user_id, fixtures_dir
):
    """Re-running the same file yields zero new rows thanks to source_row_hash."""
    from services.workout_import.service import WorkoutHistoryImporter

    data = _load_fixture(fixtures_dir, HEVY_FIXTURE)

    with patch("services.workout_import.service._download_s3_bytes",
               AsyncMock(return_value=data)):
        importer = WorkoutHistoryImporter()
        # First run — writes rows.
        r1 = await importer.run(_build_job(fake_user_id))
        # Second run — zero new rows (all deduped by hash).
        r2 = await importer.run(_build_job(fake_user_id))

    assert r1["inserted_strength_rows"] > 0
    assert r2["inserted_strength_rows"] == 0
