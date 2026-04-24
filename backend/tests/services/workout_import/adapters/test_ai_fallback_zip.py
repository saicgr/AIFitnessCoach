"""Smoke test for the ZIP-unpacker adapter.

Builds an in-memory ZIP containing two known CSV members (Hevy + Strong)
and asserts the ZIP adapter dispatches both and concatenates rows.
"""
from __future__ import annotations

import io
import zipfile

import pytest

from services.workout_import.adapters import ai_fallback_zip
from services.workout_import.canonical import ImportMode

from .conftest import TEST_USER_ID, load_fixture


@pytest.mark.asyncio
async def test_zip_dispatches_to_known_adapters():
    hevy_bytes = load_fixture("hevy_sample.csv")
    strong_bytes = load_fixture("strong_sample.csv")

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, mode="w") as zf:
        zf.writestr("hevy_workouts.csv", hevy_bytes)
        zf.writestr("strong_export.csv", strong_bytes)
    zip_bytes = buf.getvalue()

    result = await ai_fallback_zip.parse(
        data=zip_bytes,
        filename="all_my_exports.zip",
        user_id=TEST_USER_ID,
        unit_hint="lb",
        tz_hint="America/Chicago",
        mode_hint=ImportMode.HISTORY,
    )

    # Hevy 6 rows + Strong 5 rows.
    assert len(result.strength_rows) == 11
    source_apps = {r.source_app for r in result.strength_rows}
    assert "hevy" in source_apps
    assert "strong" in source_apps

    # Every row tz-aware + hashed.
    for row in result.strength_rows:
        assert row.performed_at.tzinfo is not None
        assert len(row.source_row_hash) == 64


@pytest.mark.asyncio
async def test_zip_rejects_bad_zip():
    result = await ai_fallback_zip.parse(
        data=b"not-a-zip",
        filename="broken.zip",
        user_id=TEST_USER_ID,
        unit_hint="kg",
        tz_hint="UTC",
        mode_hint=None,
    )
    assert result.strength_rows == []
    assert any("malformed" in w.lower() or "zip" in w.lower() for w in result.warnings)
