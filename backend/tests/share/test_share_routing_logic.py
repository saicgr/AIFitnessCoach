"""Tests for the pure-function routing helpers in share.py + the
intent → routing-hint map. No DB, no Gemini, no I/O — these are the
contract pieces every frontend client depends on staying stable.
"""
import pytest

from api.v1.share import (
    DAILY_CAPS,
    MAX_SIZES,
    _CONTENT_TYPE_TO_ROUTING_HINT,
    _classify_confidence,
    _intent_to_category,
    _detect_url_origin,
)
from services.intent_classifier import INTENT_ROUTING, VALID_INTENTS


# ---------------------------------------------------------------------------
# Confidence
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("content_type,expected", [
    ("food_plate", "high"),
    ("food_menu", "high"),
    ("food_buffet", "high"),
    ("exercise_form", "high"),
    ("progress_photo", "high"),
    ("gym_equipment", "high"),
    ("app_screenshot", "high"),
    ("nutrition_label", "high"),
    ("recipe_handwritten", "high"),
    ("pantry_photo", "high"),
    ("document", "low"),
    ("unknown", "low"),
])
def test_classify_confidence(content_type: str, expected: str) -> None:
    assert _classify_confidence(content_type) == expected


# ---------------------------------------------------------------------------
# Routing hint coverage — every content_type the classifier can return
# must have a routing hint defined.
# ---------------------------------------------------------------------------

REQUIRED_CONTENT_TYPES = {
    "food_plate", "food_menu", "food_buffet", "exercise_form",
    "progress_photo", "app_screenshot", "nutrition_label", "document",
    "gym_equipment", "pantry_photo", "recipe_handwritten", "unknown",
}


def test_every_content_type_has_a_routing_hint() -> None:
    for ct in REQUIRED_CONTENT_TYPES:
        assert ct in _CONTENT_TYPE_TO_ROUTING_HINT, ct


# ---------------------------------------------------------------------------
# Intent → category mapping
# ---------------------------------------------------------------------------

def test_intent_to_category_covers_every_valid_intent() -> None:
    for intent in VALID_INTENTS:
        assert _intent_to_category(intent) is not None


# ---------------------------------------------------------------------------
# Intent → routing → destination
# ---------------------------------------------------------------------------

def test_intent_routing_table_covers_every_valid_intent() -> None:
    for intent in VALID_INTENTS:
        assert intent in INTENT_ROUTING, intent
        routing = INTENT_ROUTING[intent]
        assert "redirect_screen" in routing
        assert "target_entity_kind" in routing


# ---------------------------------------------------------------------------
# URL origin detection
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("url,origin", [
    ("https://www.youtube.com/watch?v=abc",      "youtube"),
    ("https://youtu.be/abc",                     "youtube"),
    ("https://m.youtube.com/shorts/abc",         "youtube"),
    ("https://www.instagram.com/reel/abc/",      "instagram"),
    ("https://www.tiktok.com/@u/video/123",      "tiktok"),
    ("https://www.reddit.com/r/Fitness/comments/xyz", "reddit"),
    ("https://redd.it/abc",                      "reddit"),
    ("https://x.com/u/status/123",               "x"),
    ("https://twitter.com/u/status/123",         "x"),
    ("https://nytcooking.com/recipes/abc",       "web"),
])
def test_detect_url_origin(url: str, origin: str) -> None:
    assert _detect_url_origin(url) == origin


# ---------------------------------------------------------------------------
# Caps + sizes are the values the plan committed to.
# ---------------------------------------------------------------------------

def test_daily_caps_match_plan() -> None:
    assert DAILY_CAPS == {
        "url": 25,
        "image": 50,
        "text": 50,
        "audio": 20,
        "pdf": 10,
    }


def test_size_limits_match_plan() -> None:
    assert MAX_SIZES["image"] == 50 * 1024 * 1024
    assert MAX_SIZES["video"] == 500 * 1024 * 1024
    assert MAX_SIZES["audio"] == 100 * 1024 * 1024
    assert MAX_SIZES["pdf"] == 50 * 1024 * 1024
    assert MAX_SIZES["text_inline_bytes"] == 200 * 1024
    assert MAX_SIZES["text_db_truncate_bytes"] == 8 * 1024
