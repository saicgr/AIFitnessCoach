"""Regression gate for the fabricated-dish class in the vision OCR path.

Row 3 of the 2026-07-28 E2E register: a blank scan came back as "Tandoori
Chicken", $18, 320 kcal, ready to log. Two independent defects produced it and
both are pinned here:

1. THE ESCAPE HATCH WAS UNREACHABLE. Every OCR prompt told the model to answer
   {"unreadable": true, ...} on a blank/illegible image, but the same call binds
   a Pydantic `response_schema`, and constrained decoding can only emit
   DECLARED properties. `unreadable` was not declared, so the model could not
   say "I can't read this" — it had to fill the required entries array.
2. IT FILLED THE ARRAY FROM THE PROMPT'S OWN EXAMPLE. The format illustration
   carried realistic values ("Tandoor House" / "Tandoori Chicken Half" / 14.95 /
   487 kcal; "Steakhouse 71" / "10-oz New York Strip"; "Spice Garden Buffet" /
   "Chicken Biryani"), so an echo was indistinguishable from a real reading.

Plus row 2's residual: no server-side dimension floor, so a 631-byte 1x1 JPEG
was accepted and ran a full analysis.

None of these tests call Gemini or S3.
"""
import io
import json
import re

import pytest

from models.gemini_schemas import (
    BillAnalysisResponse,
    BuffetAnalysisResponse,
    MenuAnalysisResponse,
)
from services import vision_service as vs


# Literals that used to sit in the OCR prompts and were echoed back to users as
# loggable dishes. None of them may ever reappear in this module.
RETIRED_EXEMPLAR_LITERALS = [
    "Tandoor House",
    "Tandoori Chicken",
    "Yogurt-marinated",
    "Served with choice of one (1) Side",
    "14.95",
    "487",
    "Spice Garden Buffet",
    "Chicken Biryani",
    "538",
    "Steakhouse 71",
    "10-oz New York Strip",
    "Béarnaise",
    "Mashed Potatoes",
    "Sales Tax",
    "7.24",
    "76.0",
    "38.0",
]


def _jpeg(width: int, height: int) -> bytes:
    from PIL import Image

    buf = io.BytesIO()
    Image.new("RGB", (width, height), (255, 255, 255)).save(buf, format="JPEG")
    return buf.getvalue()


# ── 1. The prompts carry placeholders, never data ────────────────────────────


def test_no_retired_exemplar_literal_survives_anywhere_in_vision_service():
    """Source-level scan: the whole module, so no prompt branch can regress."""
    with open(vs.__file__, "r", encoding="utf-8") as fh:
        source = fh.read()
    offenders = [lit for lit in RETIRED_EXEMPLAR_LITERALS if lit in source]
    assert not offenders, (
        f"realistic exemplar literals are back in vision_service.py: {offenders} — "
        "an unreadable scan echoes these back as a priced, loggable dish"
    )


@pytest.mark.parametrize(
    "exemplar",
    [vs._MENU_EXEMPLAR_JSON, vs._BUFFET_EXEMPLAR_JSON, vs._BILL_EXEMPLAR_JSON],
)
def test_every_ocr_exemplar_is_placeholders_and_zeros(exemplar):
    parsed = json.loads(exemplar)
    assert parsed["restaurant_name"] == vs._EX_RESTAURANT

    entries = (
        parsed.get("lines")
        or parsed.get("dishes")
        or [d for s in parsed.get("sections", []) for d in s["dishes"]]
    )
    assert entries, "exemplar must still illustrate at least one entry"
    for entry in entries:
        assert re.fullmatch(r"<[A-Z_]+>", entry["name"]), entry["name"]
        for money_or_macro in ("price", "unit_price", "calories", "protein_g",
                               "carbs_g", "fat_g", "weight_g"):
            if money_or_macro in entry and entry[money_or_macro] is not None:
                assert entry[money_or_macro] == 0, (
                    f"{money_or_macro} must be a zero placeholder, "
                    f"got {entry[money_or_macro]}"
                )


@pytest.mark.parametrize("mode", ["menu", "buffet", "bill"])
def test_every_ocr_mode_carries_the_content_check(mode):
    """The menu branch was hardened alone; bill and buffet fabricated freely."""
    block = vs._ocr_content_check_block(mode)
    assert "CONTENT CHECK" in block
    assert '"unreadable": true' in block
    assert "NEVER invent" in block
    assert "PLACEHOLDER TOKEN" in block


# ── 2. The escape hatch is emittable under the bound schema ──────────────────


@pytest.mark.parametrize(
    "model", [MenuAnalysisResponse, BuffetAnalysisResponse, BillAnalysisResponse]
)
def test_response_schema_declares_the_unreadable_escape_hatch(model):
    props = model.model_json_schema()["properties"]
    assert "unreadable" in props, (
        f"{model.__name__} does not declare `unreadable` — constrained decoding "
        "then forbids the exact answer the CONTENT CHECK demands"
    )
    assert "unreadable_reason" in props
    assert "unreadable" in model.model_json_schema()["required"], (
        "`unreadable` must be REQUIRED — when it was optional the model simply "
        "omitted it and went straight to inventing entries"
    )


@pytest.mark.parametrize(
    "model", [MenuAnalysisResponse, BuffetAnalysisResponse, BillAnalysisResponse]
)
def test_genai_transform_keeps_unreadable_on_the_wire_schema(model):
    """Pydantic declaring it is not enough — the SDK must ship it to Gemini."""
    from google.genai import _transformers as transformers

    try:
        schema = transformers.t_schema(None, model)
    except TypeError:  # older/newer SDK signature
        schema = transformers.t_schema(model)
    assert "unreadable" in schema.properties
    assert schema.required and schema.required[0] != "", schema.required
    assert "unreadable" in schema.required
    # Ordered FIRST, so the verdict is committed before the entries array opens.
    assert schema.property_ordering[0] == "unreadable", schema.property_ordering


# ── 3. Echoes are stripped deterministically ─────────────────────────────────


def test_menu_exemplar_echo_is_stripped():
    result = {
        "analysis_type": "menu",
        "restaurant_name": vs._EX_RESTAURANT,
        "sections": [{"section_name": "mains", "dishes": [
            {"name": vs._EX_DISH, "price": 0.0, "calories": 0},
            {"name": "Palak Paneer", "price": 12.0, "calories": 410},
        ]}],
    }
    dropped = vs._strip_exemplar_echoes(result, "menu")
    assert dropped == 1
    assert result["restaurant_name"] is None
    names = [d["name"] for s in result["sections"] for d in s["dishes"]]
    assert names == ["Palak Paneer"]


def test_bill_and_buffet_echoes_are_stripped():
    bill = {"lines": [{"name": vs._EX_LINE_ITEM}, {"name": "Side Caesar Salad"}]}
    assert vs._strip_exemplar_echoes(bill, "bill") == 1
    assert [ln["name"] for ln in bill["lines"]] == ["Side Caesar Salad"]

    buffet = {"dishes": [{"name": vs._EX_DISH}, {"name": ""}, {"name": "Dal Tadka"}]}
    assert vs._strip_exemplar_echoes(buffet, "buffet") == 2
    assert [d["name"] for d in buffet["dishes"]] == ["Dal Tadka"]


def test_real_dish_names_are_never_stripped():
    result = {"dishes": [{"name": "Grilled Chicken Thali"}, {"name": "Naan"}]}
    assert vs._strip_exemplar_echoes(result, "buffet") == 0
    assert len(result["dishes"]) == 2


# ── 4. Server-side dimension floor ───────────────────────────────────────────


def test_one_by_one_jpeg_is_rejected_for_every_mode():
    tiny = _jpeg(1, 1)
    assert len(tiny) < 2000
    for mode in ("plate", "menu", "buffet", "bill"):
        assert vs.degenerate_image_reason(tiny, mode), (
            f"1x1 JPEG accepted in {mode} mode"
        )


def test_ocr_floor_is_higher_than_the_plate_floor():
    small = _jpeg(320, 240)
    assert vs.degenerate_image_reason(small, "plate") is None
    assert vs.degenerate_image_reason(small, "menu") is not None
    assert vs.degenerate_image_reason(_jpeg(1200, 900), "menu") is None


def test_unmeasurable_image_is_not_rejected():
    """The floor must never reject an image it could not measure (e.g. HEIC)."""
    assert vs.degenerate_image_reason(b"\x00\x01\x02not-an-image", "menu") is None


@pytest.mark.asyncio
async def test_degenerate_image_short_circuits_before_any_gemini_call(monkeypatch):
    def _boom(*args, **kwargs):
        raise AssertionError("Gemini was called for a degenerate image")

    monkeypatch.setattr(vs, "gemini_generate_with_retry", _boom)
    service = vs.VisionService()

    result = await service.analyze_food_from_s3_keys(
        s3_keys=["irrelevant"],
        mime_types=["image/jpeg"],
        analysis_mode="menu",
        image_bytes_override=[_jpeg(1, 1)],
    )
    assert result["unreadable"] is True
    assert result["sections"] == []
    assert "1x1" in result["unreadable_reason"]


# ── 5. End-to-end: a fabricated/unreadable response never becomes a dish ─────


class _FakeGeminiResponse:
    def __init__(self, text):
        self.text = text


def _fake_gemini(payload, gate="YES"):
    """Routes by method_name so the subject gate and the extraction differ.

    `gate` may be a string answer or an Exception to raise.
    """
    async def _call(*args, **kwargs):
        if kwargs.get("method_name") == "vision_subject_gate":
            if isinstance(gate, Exception):
                raise gate
            return _FakeGeminiResponse(gate)
        return _FakeGeminiResponse(payload)

    return _call


# A fabricated-but-realistic menu response — what the model actually returned
# from a blank 1400x1000 page before the subject gate existed.
FABRICATED_MENU = json.dumps({
    "analysis_type": "menu",
    "unreadable": False,
    "restaurant_name": "The Coffee Club",
    "sections": [{"section_name": "breakfast", "dishes": [{
        "name": "Big Breakfast", "calories": 850, "protein_g": 35.0,
        "carbs_g": 45.0, "fat_g": 60.0, "price": 18.0, "currency": "USD",
        "rating": "yellow", "inflammation_score": 7,
        "inflammation_triggers": ["processed_meat"], "fodmap_rating": "low",
        "added_sugar_g": 0.0, "is_ultra_processed": False,
    }]}],
})


@pytest.mark.asyncio
async def test_subject_gate_no_overrides_a_fabricated_extraction(monkeypatch):
    """The gate's NO is authoritative — this is the row-3 defect, live-measured."""
    monkeypatch.setattr(
        vs, "gemini_generate_with_retry", _fake_gemini(FABRICATED_MENU, gate="NO")
    )
    service = vs.VisionService()
    result = await service.analyze_food_from_s3_keys(
        s3_keys=["irrelevant"], mime_types=["image/jpeg"], analysis_mode="menu",
        image_bytes_override=[_jpeg(1400, 1000)],
    )
    assert result["unreadable"] is True
    assert result["sections"] == []
    assert "Coffee Club" not in json.dumps(result)


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "gate", ["YES", "maybe?", RuntimeError("gate call blew up")],
    ids=["yes", "unusable-answer", "gate-error"],
)
async def test_subject_gate_never_blocks_a_readable_scan(monkeypatch, gate):
    """A gate that says yes — or cannot answer — must not cost the user a scan."""
    monkeypatch.setattr(
        vs, "gemini_generate_with_retry", _fake_gemini(FABRICATED_MENU, gate=gate)
    )
    service = vs.VisionService()
    result = await service.analyze_food_from_s3_keys(
        s3_keys=["irrelevant"], mime_types=["image/jpeg"], analysis_mode="menu",
        image_bytes_override=[_jpeg(1400, 1000)],
    )
    assert result.get("unreadable") is not True
    assert vs._entry_count(result, "menu") == 1


@pytest.mark.parametrize("mode", ["menu", "bill", "buffet", "plate"])
def test_subject_gate_prompt_is_mode_aware(mode):
    prompt = vs._subject_gate_prompt(mode)
    assert "YES or NO" in prompt
    if mode in ("menu", "bill"):
        assert "READ" in prompt
    else:
        assert "food or drink" in prompt


@pytest.mark.asyncio
async def test_echoed_exemplar_response_is_not_returned_as_a_dish(monkeypatch):
    """The row-3 symptom itself: the model answers with the prompt's example."""
    monkeypatch.setattr(
        vs, "gemini_generate_with_retry", _fake_gemini(vs._MENU_EXEMPLAR_JSON)
    )
    service = vs.VisionService()

    result = await service.analyze_food_from_s3_keys(
        s3_keys=["irrelevant"],
        mime_types=["image/jpeg"],
        analysis_mode="menu",
        image_bytes_override=[_jpeg(1400, 1000)],
    )
    assert result["unreadable"] is True
    assert result["sections"] == []
    assert result["restaurant_name"] is None


@pytest.mark.asyncio
async def test_model_declared_unreadable_is_honoured(monkeypatch):
    monkeypatch.setattr(
        vs,
        "gemini_generate_with_retry",
        _fake_gemini(
            '{"analysis_type": "menu", "restaurant_name": null, "sections": [],'
            ' "unreadable": true, "unreadable_reason": "blank white page"}'
        ),
    )
    service = vs.VisionService()

    result = await service.analyze_food_from_s3_keys(
        s3_keys=["irrelevant"],
        mime_types=["image/jpeg"],
        analysis_mode="menu",
        image_bytes_override=[_jpeg(1400, 1000)],
    )
    assert result["unreadable"] is True
    assert result["unreadable_reason"] == "blank white page"


@pytest.mark.asyncio
async def test_unreadable_page_never_enters_the_recall_gate(monkeypatch):
    """A short/empty extraction must not be re-split and re-run on a blank page.

    The split retry gave the model two MORE chances to fill a required array —
    i.e. two more chances to invent a dish.
    """
    monkeypatch.setattr(
        vs,
        "gemini_generate_with_retry",
        _fake_gemini(
            '{"analysis_type": "menu", "restaurant_name": null, "sections": [],'
            ' "unreadable": true, "unreadable_reason": "solid grey frame"}'
        ),
    )

    def _no_split(*args, **kwargs):
        raise AssertionError("recall gate split an unreadable page")

    monkeypatch.setattr(vs, "_split_page_vertically", _no_split)

    service = vs.VisionService()

    async def _fake_download(_key):
        return _jpeg(1400, 1000)

    monkeypatch.setattr(service, "_download_image_from_s3", _fake_download)

    result, diagnostics = await service.analyze_menu_page(
        s3_key="irrelevant", mime_type="image/jpeg", analysis_mode="menu"
    )
    assert result["unreadable"] is True
    assert diagnostics["retried"] is False
    assert diagnostics["unreadable"] is True


@pytest.mark.asyncio
async def test_degenerate_page_is_rejected_before_the_count_call(monkeypatch):
    def _boom(*args, **kwargs):
        raise AssertionError("Gemini was called for a degenerate page")

    monkeypatch.setattr(vs, "gemini_generate_with_retry", _boom)
    service = vs.VisionService()

    async def _fake_download(_key):
        return _jpeg(1, 1)

    monkeypatch.setattr(service, "_download_image_from_s3", _fake_download)

    result, diagnostics = await service.analyze_menu_page(
        s3_key="irrelevant", mime_type="image/jpeg", analysis_mode="menu"
    )
    assert result["unreadable"] is True
    assert diagnostics["unreadable"] is True


# ── 6. The HTTP boundary rejects it too ──────────────────────────────────────

MOCK_USER_ID = "11111111-2222-3333-4444-555555555555"


@pytest.fixture
def client():
    from fastapi.testclient import TestClient

    from core.auth import get_current_user
    from main import app

    app.dependency_overrides[get_current_user] = lambda: {
        "id": MOCK_USER_ID, "email": "test@example.com",
    }
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.parametrize("mode", ["menu", "bill", "buffet", "auto"])
def test_multi_image_endpoint_400s_on_a_degenerate_upload(client, mode):
    """A 631-byte 1x1 JPEG used to be accepted and run a full Gemini analysis."""
    tiny = _jpeg(1, 1)
    response = client.post(
        "/api/v1/nutrition/log-multi-image-stream",
        data={"user_id": MOCK_USER_ID, "meal_type": "lunch", "analysis_mode": mode},
        files=[("images", ("blank.jpg", tiny, "image/jpeg"))],
    )
    assert response.status_code == 400, response.text
    assert "too small to read" in response.json()["detail"]


def test_single_image_endpoints_400_on_a_degenerate_upload(client):
    tiny = _jpeg(1, 1)
    for path in ("log-image-stream", "analyze-image-stream"):
        response = client.post(
            f"/api/v1/nutrition/{path}",
            data={"user_id": MOCK_USER_ID, "meal_type": "lunch"},
            files=[("image", ("blank.jpg", tiny, "image/jpeg"))],
        )
        assert response.status_code == 400, f"{path}: {response.text}"
        assert "too small to read" in response.json()["detail"]


# ── 7. The unreadable shape every consumer keys off ──────────────────────────


@pytest.mark.parametrize(
    "mode,key", [("menu", "sections"), ("buffet", "dishes"), ("bill", "lines"),
                 ("plate", "food_items")],
)
def test_unreadable_result_shape(mode, key):
    result = vs.build_unreadable_result(mode, "blank white frame")
    assert result["analysis_type"] == mode
    assert result["unreadable"] is True
    assert result["unreadable_reason"] == "blank white frame"
    assert result[key] == []
