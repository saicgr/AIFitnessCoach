"""
Unit tests for GymEquipmentExtractor.

Gemini + S3 are mocked at the `gemini_generate_with_retry` boundary and on the
VisionService helpers. The EquipmentResolver is stubbed with an in-memory map
so we don't touch Supabase.

Run with:
  cd backend && pytest tests/test_gym_equipment_extractor.py -v
"""
from __future__ import annotations

import json
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


# ---------- Fixtures --------------------------------------------------------

class _StubResolver:
    """Minimal EquipmentResolver stand-in keyed on a fixed alias map.

    Matches on substring to approximate the real resolver's partial-match
    behavior without hitting Supabase.
    """
    ALIAS_TO_CANON = {
        "dumbbell": "dumbbells",
        "dumbbells": "dumbbells",
        "barbell": "barbell",
        "smith machine": "smith_machine",
        "leg press": "leg_press",
        "treadmill": "treadmill",
        "elliptical": "elliptical",
        "squat rack": "squat_rack",
        "bench press": "bench_press",
        "bench": "bench",
        "cable crossover": "cable_machine",
        "cable machine": "cable_machine",
        "lat pulldown": "lat_pulldown",
        "kettlebell": "kettlebell",
        "resistance band": "resistance_bands",
    }

    def resolve(self, raw: str):
        if not raw:
            return None
        key = raw.lower().strip()
        if key in self.ALIAS_TO_CANON:
            return self.ALIAS_TO_CANON[key]
        for alias, canon in self.ALIAS_TO_CANON.items():
            if len(alias) > 2 and alias in key:
                return canon
        return None


@pytest.fixture
def stub_resolver():
    return _StubResolver()


@pytest.fixture
def mock_vision_service():
    vs = MagicMock()
    vs.model = "gemini-3-flash-preview"
    # download helpers used by the file/images paths
    vs._download_image_from_s3 = AsyncMock(return_value=b"fakefilebytes")
    vs.extract_equipment_from_document = AsyncMock()
    return vs


def _gemini_json_response(items):
    """Build a fake response object matching `gemini_generate_with_retry`'s
    return shape (an object with a `.text` attr containing JSON)."""
    return SimpleNamespace(text=json.dumps(items))


# ---------- Tests -----------------------------------------------------------


@pytest.mark.asyncio
async def test_text_source_matches_common_equipment(stub_resolver, mock_vision_service):
    from services.gym_equipment_extractor import GymEquipmentExtractor

    ext = GymEquipmentExtractor(
        vision_service=mock_vision_service,
        equipment_resolver=stub_resolver,
    )

    fake_items = [
        {"raw_name": "dumbbells", "quantity": 10, "weight_range": "5-120 lb", "confidence": 0.95},
        {"raw_name": "barbell", "quantity": 2, "confidence": 0.9},
        {"raw_name": "smith machine", "quantity": 1, "confidence": 0.92},
        {"raw_name": "leg press", "quantity": 1, "confidence": 0.9},
    ]

    with patch(
        "services.gym_equipment_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json_response(fake_items)),
    ):
        result = await ext.extract(
            source="text",
            raw_text=(
                "We have 10 dumbbells, 2 barbells, a smith machine, and a leg press"
            ),
        )

    canon = {m["canonical"] for m in result["matched"]}
    assert "dumbbells" in canon
    assert "barbell" in canon
    assert "smith_machine" in canon
    assert "leg_press" in canon
    assert result["inferred_environment"] == "commercial_gym"
    assert result["total_extracted"] == 4


@pytest.mark.asyncio
async def test_url_source_fetch_and_extract(stub_resolver, mock_vision_service):
    from services.gym_equipment_extractor import GymEquipmentExtractor

    ext = GymEquipmentExtractor(
        vision_service=mock_vision_service,
        equipment_resolver=stub_resolver,
    )

    fake_html = (
        "<html><body><ul>"
        "<li>Treadmills x 10</li>"
        "<li>Smith machine</li>"
        "<li>Dumbbells 5-120lb</li>"
        "</ul></body></html>"
    )

    # httpx.AsyncClient is instantiated inside _fetch_url_text, so we patch at
    # the import site (the extractor does `import httpx` inline).
    mock_response = MagicMock()
    mock_response.content = fake_html.encode("utf-8")
    mock_response.encoding = "utf-8"
    mock_response.headers = {"content-type": "text/html"}
    mock_response.raise_for_status = MagicMock()

    mock_client = MagicMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_client.get = AsyncMock(return_value=mock_response)

    fake_items = [
        {"raw_name": "treadmill", "quantity": 10, "confidence": 0.9},
        {"raw_name": "smith machine", "quantity": 1, "confidence": 0.95},
        {"raw_name": "dumbbells", "quantity": 1, "weight_range": "5-120 lb", "confidence": 0.9},
    ]

    with patch("httpx.AsyncClient", return_value=mock_client), patch(
        "services.gym_equipment_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json_response(fake_items)),
    ):
        result = await ext.extract(source="url", url="https://example-gym.com/equipment")

    canon = {m["canonical"] for m in result["matched"]}
    assert "smith_machine" in canon
    assert result["inferred_environment"] == "commercial_gym"


@pytest.mark.asyncio
async def test_file_pdf_source_uses_vision_helper(stub_resolver, mock_vision_service):
    from services.gym_equipment_extractor import GymEquipmentExtractor

    fake_items = [
        {"raw_name": "barbell", "confidence": 0.9},
        {"raw_name": "bench", "confidence": 0.85},
    ]
    mock_vision_service.extract_equipment_from_document.return_value = fake_items

    ext = GymEquipmentExtractor(
        vision_service=mock_vision_service,
        equipment_resolver=stub_resolver,
    )

    result = await ext.extract(
        source="file",
        s3_key="gym/equipment.pdf",
        mime_type="application/pdf",
    )

    mock_vision_service.extract_equipment_from_document.assert_awaited_once()
    canon = {m["canonical"] for m in result["matched"]}
    assert "barbell" in canon


@pytest.mark.asyncio
async def test_empty_extraction_returns_zero(stub_resolver, mock_vision_service):
    from services.gym_equipment_extractor import GymEquipmentExtractor

    ext = GymEquipmentExtractor(
        vision_service=mock_vision_service,
        equipment_resolver=stub_resolver,
    )

    with patch(
        "services.gym_equipment_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json_response([])),
    ):
        result = await ext.extract(source="text", raw_text="this gym has nothing")

    assert result["total_extracted"] == 0
    assert result["matched"] == []
    assert result["unmatched"] == []
    assert result["inferred_environment"] == "commercial_gym"


@pytest.mark.asyncio
async def test_invalid_gemini_json_raises(stub_resolver, mock_vision_service):
    from services.gym_equipment_extractor import GymEquipmentExtractor

    ext = GymEquipmentExtractor(
        vision_service=mock_vision_service,
        equipment_resolver=stub_resolver,
    )

    with patch(
        "services.gym_equipment_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=SimpleNamespace(text="this is {not valid json")),
    ):
        with pytest.raises(ValueError):
            await ext.extract(source="text", raw_text="whatever")


@pytest.mark.asyncio
async def test_environment_inference_home_gym(stub_resolver, mock_vision_service):
    from services.gym_equipment_extractor import GymEquipmentExtractor

    fake_items = [
        {"raw_name": "dumbbells", "confidence": 0.9},
        {"raw_name": "barbell", "confidence": 0.9},
        {"raw_name": "bench", "confidence": 0.9},
    ]
    ext = GymEquipmentExtractor(
        vision_service=mock_vision_service,
        equipment_resolver=stub_resolver,
    )

    with patch(
        "services.gym_equipment_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json_response(fake_items)),
    ):
        result = await ext.extract(source="text", raw_text="home gym")

    # Only home-gym-core items → home_gym
    assert result["inferred_environment"] == "home_gym"


@pytest.mark.asyncio
async def test_unmatched_bucket_populated(stub_resolver, mock_vision_service):
    from services.gym_equipment_extractor import GymEquipmentExtractor

    fake_items = [
        {"raw_name": "barbell", "confidence": 0.9},
        {"raw_name": "some weird unicorn machine xyz", "confidence": 0.4},
    ]

    ext = GymEquipmentExtractor(
        vision_service=mock_vision_service,
        equipment_resolver=stub_resolver,
    )

    with patch(
        "services.gym_equipment_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json_response(fake_items)),
    ):
        result = await ext.extract(source="text", raw_text="mixed list")

    assert len(result["matched"]) == 1
    assert len(result["unmatched"]) == 1
    assert result["unmatched"][0]["raw"].startswith("some weird unicorn")
