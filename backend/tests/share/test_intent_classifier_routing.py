"""Tests for backend/services/intent_classifier.py.

Pure routing-table tests + JSON parsing edge cases. The actual Gemini
call is mocked — a separate golden-set test (see plan Layer 3) would
exercise real model output, but that's gated on the i18n / paid sweep
budget.
"""
from unittest.mock import AsyncMock, patch

import pytest

from services.intent_classifier import (
    INTENT_ROUTING,
    VALID_INTENTS,
    _safe_parse_json,
    classify_intent,
)


# ---------------------------------------------------------------------------
# _safe_parse_json — tolerates fences, prefixes, mid-stream garbage.
# ---------------------------------------------------------------------------

def test_safe_parse_handles_plain_json() -> None:
    out = _safe_parse_json('{"intent":"recipe_extract"}')
    assert out == {"intent": "recipe_extract"}


def test_safe_parse_handles_markdown_fences() -> None:
    raw = '```json\n{"intent":"workout_extract"}\n```'
    assert _safe_parse_json(raw) == {"intent": "workout_extract"}


def test_safe_parse_handles_prefix_chatter() -> None:
    raw = 'Here is your JSON: {"intent":"tip_save","confidence":"medium"}'
    out = _safe_parse_json(raw)
    assert out == {"intent": "tip_save", "confidence": "medium"}


def test_safe_parse_returns_empty_on_garbage() -> None:
    assert _safe_parse_json("¯\\_(ツ)_/¯") == {}
    assert _safe_parse_json("") == {}


# ---------------------------------------------------------------------------
# Empty input bypasses the LLM and returns discuss/low.
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_empty_text_short_circuits() -> None:
    result = await classify_intent(text="")
    assert result["intent"] == "discuss"
    assert result["confidence"] == "low"
    assert result["secondary_intents"] == []


@pytest.mark.asyncio
async def test_unknown_intent_falls_back_to_discuss() -> None:
    with patch("services.intent_classifier.gemini_generate_with_retry",
               new=AsyncMock(return_value=type("R", (), {"text": '{"intent":"not_a_real_intent","confidence":"high"}'})())):
        result = await classify_intent(text="some text")
        assert result["intent"] == "discuss"


@pytest.mark.asyncio
async def test_invalid_confidence_falls_back_to_low() -> None:
    with patch("services.intent_classifier.gemini_generate_with_retry",
               new=AsyncMock(return_value=type("R", (), {"text": '{"intent":"workout_extract","confidence":"super-high"}'})())):
        result = await classify_intent(text="3x8 bench")
        assert result["confidence"] == "low"


@pytest.mark.asyncio
async def test_secondary_intents_filtered_to_valid_set() -> None:
    payload = ('{"intent":"workout_extract","confidence":"high",'
               '"secondary_intents":["recipe_extract","made_up_intent"]}')
    with patch("services.intent_classifier.gemini_generate_with_retry",
               new=AsyncMock(return_value=type("R", (), {"text": payload})())):
        result = await classify_intent(text="x")
        assert result["secondary_intents"] == ["recipe_extract"]


@pytest.mark.asyncio
async def test_gemini_error_falls_back_to_discuss() -> None:
    with patch("services.intent_classifier.gemini_generate_with_retry",
               new=AsyncMock(side_effect=RuntimeError("Gemini boom"))):
        result = await classify_intent(text="x")
        assert result["intent"] == "discuss"
        assert result["confidence"] == "low"


# ---------------------------------------------------------------------------
# INTENT_ROUTING table — required keys per intent.
# ---------------------------------------------------------------------------

def test_intent_routing_complete_coverage() -> None:
    for intent in VALID_INTENTS:
        assert intent in INTENT_ROUTING
        entry = INTENT_ROUTING[intent]
        assert isinstance(entry["redirect_screen"], str)
        assert isinstance(entry["target_entity_kind"], str)
