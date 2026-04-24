"""Smoke tests for the AI-fallback adapters.

We can't hit Gemini in unit tests, so we:

  * patch ``gemini_generate_with_retry`` to return a canned response shaped
    like ``_GeminiExtractResponse``; assert the adapter turns the LLM rows
    into canonical rows correctly.
  * verify ``ai_fallback_pdf`` is an alias to ``ai_fallback.parse``.
"""
from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import pytest

from services.workout_import.adapters import ai_fallback, ai_fallback_pdf
from services.workout_import.adapters.ai_fallback import _GeminiExtractResponse, _GeminiSetRow
from services.workout_import.canonical import ImportMode

from .conftest import TEST_USER_ID


def _fake_response(rows):
    payload = _GeminiExtractResponse(
        source_app_guess="Unknown Gym Journal",
        warnings=[],
        rows=rows,
    )
    return SimpleNamespace(parsed=payload)


@pytest.mark.asyncio
async def test_ai_fallback_transforms_gemini_rows():
    rows = [
        _GeminiSetRow(
            performed_at="2026-04-01T09:00:00",
            workout_name="Push A",
            exercise_name="Bench Press",
            set_number=1,
            set_type="working",
            weight=135,
            weight_unit="lb",
            reps=10,
            rpe=7.0,
            notes=None,
        ),
        _GeminiSetRow(
            performed_at="2026-04-01T09:00:00",
            workout_name="Push A",
            exercise_name="Bench Press",
            set_number=2,
            set_type="working",
            weight=155,
            weight_unit="lb",
            reps=8,
            rpe=8.0,
            notes=None,
        ),
    ]
    fake = _fake_response(rows)

    fake_settings = SimpleNamespace(gemini_model="gemini-test")
    fake_types_module = SimpleNamespace(
        Part=SimpleNamespace(from_bytes=lambda data, mime_type: ("part", mime_type)),
        GenerateContentConfig=lambda **kw: kw,
    )
    with patch.dict(
        "sys.modules",
        {
            "google.genai": SimpleNamespace(types=fake_types_module),
            "core.config": SimpleNamespace(settings=fake_settings),
        },
    ), patch(
        "services.gemini.constants.gemini_generate_with_retry",
        new=AsyncMock(return_value=fake),
    ):
        result = await ai_fallback.parse(
            data=b"%PDF-1.4 fake pdf bytes",
            filename="gym_journal.pdf",
            user_id=TEST_USER_ID,
            unit_hint="lb",
            tz_hint="America/Chicago",
            mode_hint=ImportMode.HISTORY,
        )

    assert result.source_app.startswith("ai_parsed")
    assert len(result.strength_rows) == 2
    # tz-aware + hash stable.
    for row in result.strength_rows:
        assert row.performed_at.tzinfo is not None
        assert len(row.source_row_hash) == 64
        # 135 lb → ~61.2 kg.
    assert result.strength_rows[0].weight_kg == pytest.approx(61.23, abs=0.1)


@pytest.mark.asyncio
async def test_ai_fallback_missing_sdk_returns_warning():
    """When google.genai isn't importable, adapter returns an empty result
    with a warning — never crashes."""
    with patch.dict("sys.modules", {"google.genai": None}):
        result = await ai_fallback.parse(
            data=b"%PDF-1.4",
            filename="mystery.pdf",
            user_id=TEST_USER_ID,
            unit_hint="kg",
            tz_hint="UTC",
            mode_hint=ImportMode.HISTORY,
        )
    assert result.strength_rows == []
    assert any("Gemini" in w for w in result.warnings)


def test_pdf_alias_is_same_parse():
    assert ai_fallback_pdf.parse is ai_fallback.parse
