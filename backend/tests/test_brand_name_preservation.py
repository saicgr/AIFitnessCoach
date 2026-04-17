"""End-to-end tests asserting that Gemini-driven food analysis does NOT
substitute English brand/food names with foreign-language trademarks
and that meal-level inflammation fields are populated.

These tests hit the real Gemini API (no mocks) because the bug lives
entirely in the model's free-form output — mocking it would defeat the
purpose. Each test takes 5-15 s.

Run:
    cd backend && pytest -xvs tests/test_brand_name_preservation.py
"""
import asyncio
import os
import sys

import pytest

# Ensure backend/ is on the path so `services.*` imports resolve when
# pytest is invoked from repo root.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.gemini_service import GeminiService  # noqa: E402


# Session-scoped event loop so the google-genai aiohttp session survives
# across tests. Without this, pytest-asyncio's default function-scoped loop
# gets closed between tests and the SDK raises "Event loop is closed".
@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
def gemini_service(event_loop):
    return GeminiService()


FORBIDDEN_FOREIGN_TOKENS = {
    "fromage la vache qui rit",
    "vache qui rit",
    "la vache qui rit",
    "fromage",  # bare French "cheese" — if Gemini uses this it has slipped
    "lait d'avoine",
    "shoyu",
    "phô mai",
    "phô",
    "bò cười",
}


def _flatten_item_names(result: dict) -> list[str]:
    return [
        (item.get("name") or "")
        for item in (result.get("food_items") or [])
    ]


def _assert_english_item_names(result: dict, description: str) -> None:
    """Assert every item name is ASCII-only and contains no forbidden
    foreign trademark tokens."""
    assert result and result.get("food_items"), (
        f"Gemini returned no food_items for {description!r}: {result!r}"
    )
    for name in _flatten_item_names(result):
        lower = name.lower()
        for bad in FORBIDDEN_FOREIGN_TOKENS:
            assert bad not in lower, (
                f"Foreign-language name leaked for query {description!r}: "
                f"item name {name!r} contains forbidden token {bad!r}"
            )
        assert name.isascii(), (
            f"Non-ASCII item name for query {description!r}: {name!r} — "
            f"prompt rule + sanitizer both failed"
        )


@pytest.mark.asyncio
@pytest.mark.parametrize("description", [
    "laughing cow cheese",
    "laughing cow cheese with 4 bacon and 10 ritz cracker",
    "lsughing cow cheese",                  # typo — spelling correction must NOT swap to French
    "LAUGHING COW CHEESE",                  # casing
    "laughing cow with crackers",           # partial
    "oat milk latte",                       # should stay English, not "lait d'avoine"
    "soy sauce with rice",                  # should stay English, not "shoyu"
])
async def test_item_names_stay_in_users_language(gemini_service, description):
    result = await gemini_service.parse_food_description(description=description)
    _assert_english_item_names(result, description)


@pytest.mark.asyncio
async def test_inflammation_populated_for_mixed_meal(gemini_service):
    """Meal-level inflammation_score + is_ultra_processed must surface for
    the exact screenshot case (cheese + bacon + Ritz)."""
    description = "laughing cow cheese with 4 bacon and 10 ritz cracker"
    result = await gemini_service.parse_food_description(description=description)
    assert result, "Gemini returned None"
    assert result.get("inflammation_score") is not None, (
        f"meal-level inflammation_score is null for {description!r}: {result!r}"
    )
    assert 1 <= int(result["inflammation_score"]) <= 10
    assert result.get("is_ultra_processed") is True, (
        f"Ritz crackers + bacon should flag is_ultra_processed for {description!r}; "
        f"got {result.get('is_ultra_processed')!r}"
    )


@pytest.mark.asyncio
async def test_user_typed_accent_is_preserved(gemini_service):
    """Regression: the ASCII sanitizer must NOT strip accents the user
    wrote themselves. If the user types jalapeños, the item should stay
    a jalapeño-related noun, not drift to an unrelated foreign phrase."""
    result = await gemini_service.parse_food_description(description="jalapeños on the side")
    names = " ".join(_flatten_item_names(result)).lower()
    # Either accent preserved or ASCII "jalapenos" is fine — both point to the
    # same food. What we must avoid is the sanitizer wiping it to a generic
    # English phrase that isn't about jalapeños at all.
    assert "jalape" in names, (
        f"Sanitizer stripped a user-typed accent and lost the food identity. "
        f"Names={names!r}"
    )


@pytest.mark.asyncio
async def test_inflammation_fallback_computes_from_per_item_scores(monkeypatch):
    """Unit-style test of the fallback helper: verifies that when Gemini
    returns per-item scores but null meal-level, the fallback computes
    a sensible calorie-weighted meal score."""
    from services.gemini.nutrition import compute_meal_inflammation

    items = [
        {"inflammation_score": 6, "calories": 200, "is_ultra_processed": False},
        {"inflammation_score": 9, "calories": 300, "is_ultra_processed": True},
        {"inflammation_score": 8, "calories": 100, "is_ultra_processed": True},
    ]
    score, upf = compute_meal_inflammation(items)
    # Weighted avg = (6*200 + 9*300 + 8*100) / 600 = 4700 / 600 ≈ 7.83 → 8
    assert score == 8, f"expected weighted score 8, got {score}"
    assert upf is True, f"expected is_ultra_processed True, got {upf}"

    score_empty, upf_empty = compute_meal_inflammation([])
    assert score_empty is None
    assert upf_empty is None

    score_missing, upf_missing = compute_meal_inflammation([
        {"calories": 100},  # no inflammation_score
    ])
    assert score_missing is None
    assert upf_missing is None


def test_sanitize_foreign_name_replaces_non_ascii():
    """Unit test for the sanitizer helper — happy path."""
    from services.gemini.parsers import _sanitize_foreign_name

    assert _sanitize_foreign_name(
        "Fromage La Vache Qui Rit",
        "laughing cow cheese with 4 bacon",
    ) == "Laughing Cow Cheese"

    # ASCII input is returned unchanged.
    assert _sanitize_foreign_name("Laughing Cow Cheese", "laughing cow cheese") == "Laughing Cow Cheese"

    # No query → no replacement possible, name kept as-is.
    assert _sanitize_foreign_name("Fromage La Vache Qui Rit", None) == "Fromage La Vache Qui Rit"

    # User typed the foreign name themselves → keep it (token overlap).
    assert _sanitize_foreign_name("Phô Mai Con Bò Cười", "phô mai") == "Phô Mai Con Bò Cười"

    # Count prefix is stripped: "4 bacon" should not become "4 Bacon".
    assert _sanitize_foreign_name("Lardon Fumé", "4 bacon slices") in {"Bacon Slices"}


def test_sanitize_foreign_name_edge_cases():
    """Edge cases that must not crash or over-fire."""
    from services.gemini.parsers import _sanitize_foreign_name

    # Empty name → empty out.
    assert _sanitize_foreign_name("", "laughing cow cheese") == ""

    # Empty query → keep name.
    assert _sanitize_foreign_name("Fromage", "") == "Fromage"
    assert _sanitize_foreign_name("Fromage", "   ") == "Fromage"

    # Query is only numbers/stopwords — nothing substantive to borrow from.
    assert _sanitize_foreign_name("Fromage", "the of and") == "Fromage"
    assert _sanitize_foreign_name("Fromage", "4 10 20") == "Fromage"

    # Partial overlap (one shared token) → keep name. e.g. Gemini adds a
    # qualifier but user's token is in there.
    assert _sanitize_foreign_name(
        "Philadelphia Cream Cheese",
        "cream cheese on bagel",
    ) == "Philadelphia Cream Cheese"

    # User typed French themselves → Gemini might translate to English →
    # the English name will trigger the foreign-looking check because
    # the query carries French tokens that don't overlap. Wait — actually
    # "Laughing Cow Cheese" is plain English, which doesn't look foreign.
    # The sanitizer will NOT fire. That's acceptable: if the user writes
    # French, Gemini probably keeps it French, and the sanitizer is not
    # our main defense for that direction.
    result = _sanitize_foreign_name(
        "Laughing Cow Cheese",
        "la vache qui rit",
    )
    assert result == "Laughing Cow Cheese"

    # But if Gemini returns a FRENCH name and user typed French, both
    # sides align and sanitizer keeps it.
    result2 = _sanitize_foreign_name(
        "La Vache Qui Rit",
        "la vache qui rit",
    )
    assert result2 == "La Vache Qui Rit"

    # Very long query doesn't crash; keep name unchanged if no good chunk.
    long_query = "hello " * 500  # 500 tokens, single chunk > 6 tokens → skipped
    result = _sanitize_foreign_name("Fromage La Vache Qui Rit", long_query)
    assert result == "Fromage La Vache Qui Rit"  # no usable chunk

    # Casing preserved via title() when sanitizer fires.
    assert _sanitize_foreign_name(
        "Fromage",  # foreign token
        "chicken tikka masala",
    ) == "Chicken Tikka Masala"

    # Chunk with 7+ tokens (no delimiters) is skipped (too long to be a food name).
    assert _sanitize_foreign_name(
        "Fromage",
        "i really really really really really wanted something",
    ) == "Fromage"  # every chunk post-split is too long


def test_sanitize_foreign_name_does_not_rewrite_english_composites():
    """Regression guard: composite-meal ingredients like 'Black Beans' or
    'Corn Salsa' have zero token overlap with a query like 'chipotle bowl
    with chicken and rice', but they are plain English — the sanitizer
    must NOT rewrite them. The `_looks_foreign` guard handles this."""
    from services.gemini.parsers import _sanitize_foreign_name

    query = "chipotle bowl with chicken and rice"
    assert _sanitize_foreign_name("Black Beans", query) == "Black Beans"
    assert _sanitize_foreign_name("Corn Salsa", query) == "Corn Salsa"
    assert _sanitize_foreign_name("Guacamole", query) == "Guacamole"
    assert _sanitize_foreign_name("Shredded Cheese", query) == "Shredded Cheese"
    assert _sanitize_foreign_name("White Rice", query) == "White Rice"

    # But a truly foreign name in the same meal IS rewritten.
    assert _sanitize_foreign_name("Pommes Frites", query) == "Chipotle Bowl"
    assert _sanitize_foreign_name("Fromage Blanc", query) == "Chipotle Bowl"


def test_compute_meal_inflammation_edge_cases():
    """Edge cases for the inflammation fallback helper."""
    from services.gemini.nutrition import compute_meal_inflammation

    # Single item.
    assert compute_meal_inflammation([
        {"inflammation_score": 7, "calories": 200, "is_ultra_processed": True},
    ]) == (7, True)

    # Zero-cal items (e.g. water, black coffee) — weighted avg must not
    # divide by zero; falls back to unweighted mean.
    score, upf = compute_meal_inflammation([
        {"inflammation_score": 2, "calories": 0},
        {"inflammation_score": 4, "calories": 0},
    ])
    assert score == 3, f"unweighted mean of 2,4 should round to 3, got {score}"
    assert upf is None

    # Missing calories key → treated as 0.
    score, upf = compute_meal_inflammation([
        {"inflammation_score": 5},
        {"inflammation_score": 9},
    ])
    assert score == 7, f"expected 7, got {score}"

    # None calories → treated as 0.
    score, upf = compute_meal_inflammation([
        {"inflammation_score": 5, "calories": None},
    ])
    assert score == 5

    # Score > 10 is clamped (defensive — Gemini shouldn't but could).
    score, upf = compute_meal_inflammation([
        {"inflammation_score": 15, "calories": 100},
    ])
    assert score == 10

    # Score < 1 is clamped.
    score, upf = compute_meal_inflammation([
        {"inflammation_score": -5, "calories": 100},
    ])
    assert score == 1

    # Mix of valid and invalid items — invalid ones are skipped.
    score, upf = compute_meal_inflammation([
        {"calories": 100},  # no score → skip
        {"inflammation_score": 8, "calories": 200, "is_ultra_processed": True},
    ])
    assert score == 8
    assert upf is True


# ─── Additional live Gemini tests (more brands and generic foods) ────────

ADDITIONAL_FORBIDDEN_TOKENS = {
    # English foods → French translations we must NEVER see
    "lait",
    "pain",
    "fromage",
    "riz",
    "beurre",
    "jambon",
    "poulet",
    "boeuf",
    "porc",
    "pomme de terre",
    "pommes frites",
    # English-brand → foreign names
    "pâte à tartiner",
    "taureau rouge",
    "mac do",
    "sbux",
    # Hindi / Devanagari tokens (a user typing English must not get Hindi back)
    "चिकन",
    "दाल",
    "बिरयानी",
}


@pytest.mark.asyncio
@pytest.mark.parametrize("description", [
    # Other at-risk brands
    "nutella on toast",
    "philadelphia cream cheese bagel",
    "red bull energy drink",
    "coca cola and a snickers bar",
    # Generic English food words that translate cleanly in French
    "a glass of milk",
    "slice of bread with butter",
    "bowl of rice and chicken",
    "ham and cheese sandwich",
    # Restaurant chains
    "mcdonald's big mac and fries",
    "starbucks caramel latte",
    "chipotle chicken burrito bowl",
    # Traditional dishes that should stay as-written (not translated to another language)
    "chicken biryani",
    "pad thai with shrimp",
    "beef pho",
    "chicken tikka masala",
    "hummus and pita",
])
async def test_broader_brand_and_food_coverage(gemini_service, description):
    """Covers 15+ realistic user queries beyond laughing cow cheese.
    All item names must stay in English (the user's chosen language)
    and must not leak French/Spanish/Hindi tokens."""
    result = await gemini_service.parse_food_description(description=description)
    _assert_english_item_names(result, description)
    names = " ".join(_flatten_item_names(result)).lower()
    for bad in ADDITIONAL_FORBIDDEN_TOKENS:
        assert bad not in names, (
            f"Forbidden foreign token {bad!r} leaked in names {names!r} "
            f"for query {description!r}"
        )


@pytest.mark.asyncio
async def test_multi_item_meal_only_translates_one_item(gemini_service):
    """The sanitizer must operate per-item. Verify that a meal with ONE
    at-risk item and multiple safe items still produces correct names
    for every item."""
    description = "laughing cow cheese with 3 scrambled eggs and 2 slices of toast"
    result = await gemini_service.parse_food_description(description=description)
    assert result and result.get("food_items")
    names = [(item.get("name") or "").lower() for item in result["food_items"]]
    names_joined = " ".join(names)

    # Laughing Cow must be English.
    assert any("laughing cow" in n or "cow cheese" in n for n in names), (
        f"No laughing-cow-style item in names: {names!r}"
    )
    assert "fromage" not in names_joined
    assert "vache" not in names_joined

    # Eggs and toast must still be present and English.
    assert any("egg" in n for n in names), f"No egg item in {names!r}"
    assert any("toast" in n or "bread" in n for n in names), f"No toast item in {names!r}"
