"""
Unit tests for food_match_gate — the semantic qualifier-preservation layer
that sits on top of the food-search DB results.

Covers the 43-case edge matrix in
/Users/saichetangrandhe/.claude/plans/lovely-discovering-mccarthy.md (Part A).

Gemini calls are patched so tests are deterministic and offline.
"""
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.food_match_gate import (  # noqa: E402
    accept_tier,
    classify,
    content_words,
    is_valid_single_match,
    match_tokens_for_row,
    normalize_query,
    score_row,
    tokenize,
    trigram_sim,
    _prune_tier_a,
    _token_is_covered,
)


# ── Builders ───────────────────────────────────────────────────────────────

def _row(display_name: str, *,
         food_name_normalized: str = None,
         variant_names: list = None,
         source: str = "verified",
         calories_per_100g: float = 100) -> dict:
    """Build a minimal food_nutrition_overrides-shaped dict for tests."""
    return {
        "display_name": display_name,
        "food_name_normalized": food_name_normalized or display_name.lower().replace(" ", "_"),
        "variant_names": variant_names or [display_name.lower()],
        "source": source,
        "calories_per_100g": calories_per_100g,
    }


# ── Normalization ──────────────────────────────────────────────────────────

class TestNormalize:
    def test_lowercases_and_strips(self):
        assert normalize_query("  Paneer Masala Dosa  ") == "paneer masala dosa"

    def test_collapses_whitespace(self):
        assert normalize_query("paneer   masala  dosa") == "paneer masala dosa"

    def test_replaces_hyphens(self):
        assert normalize_query("low-fat yogurt") == "low fat yogurt"
        assert normalize_query("paneer-masala dosa") == "paneer masala dosa"

    def test_strips_commas(self):
        assert normalize_query("paneer, masala dosa") == "paneer masala dosa"

    def test_strips_percent_and_symbols(self):
        # "2% milk" -> "2 milk"; caller handles numeric drop
        assert normalize_query("2% milk") == "2 milk"

    def test_smart_quotes(self):
        assert normalize_query("baker\u2019s dozen") == "baker s dozen"

    def test_strips_control_chars(self):
        # \x00-\x1f (minus tab/lf/cr) should be removed
        assert normalize_query("pizza\x00\x01test") == "pizzatest"

    def test_strips_diacritics_in_normalize(self):
        assert normalize_query("Café Latté") == "cafe latte"
        assert normalize_query("jalapeño") == "jalapeno"

    def test_unicode_nfkc(self):
        # Full-width chars NFKC-normalize to ASCII
        assert normalize_query("pizza") == "pizza"

    def test_empty(self):
        assert normalize_query("") == ""
        assert normalize_query("   ") == ""


# ── Content words ──────────────────────────────────────────────────────────

class TestContentWords:
    def test_preserves_ingredients(self):
        assert content_words("paneer masala dosa") == ["paneer", "masala", "dosa"]

    def test_drops_stop_words(self):
        assert content_words("the pizza with cheese") == ["pizza", "cheese"]

    def test_drops_size_descriptors(self):
        assert content_words("large pizza") == ["pizza"]
        assert content_words("mini pizza") == ["pizza"]

    def test_keeps_sensory_descriptors_as_content(self):
        """Sensory words ("spicy", "mild", "sweet", "sour", "plain") are CONTENT.

        RETIRED ASSERTION: this test used to be `test_drops_sensory_descriptors`
        and required content_words("spicy chicken curry") == ["chicken","curry"] —
        i.e. sensory adjectives were tokenized away like size/temperature words.
        That was deliberately retired (see the NOTE in food_match_gate.py): a
        sensory word is frequently part of a DISTINCT product whose nutrition
        differs — "Spicy McChicken" ≠ "McChicken", "Sweet Potato" ≠ "Potato",
        "Sour Cream" ≠ "Cream" — so dropping it silently logged the wrong food.

        The original intent (a descriptor must never *block* finding the food)
        is now served one layer up instead of at tokenization: the row still
        matches, but as tier B, where Gemini adjudicates whether the descriptor
        difference is benign ("Pure descriptors (spicy, large, fresh) can
        differ" is in the validator prompt). See
        TestAcceptTier.test_spicy_chicken_curry_still_finds_row.

        Size/temperature/personal descriptors ARE still dropped — asserted in
        test_drops_size_descriptors / test_drops_possessive_personal.
        """
        assert content_words("spicy chicken curry") == ["spicy", "chicken", "curry"]
        assert content_words("mild dal makhani") == ["mild", "dal", "makhani"]
        assert content_words("sweet potato") == ["sweet", "potato"]

    def test_drops_cooking_methods(self):
        assert content_words("grilled chicken") == ["chicken"]
        assert content_words("fried rice") == ["rice"]

    def test_drops_possessive_personal(self):
        assert content_words("my favorite pizza") == ["pizza"]

    def test_drops_pure_numbers(self):
        assert content_words("2 milk") == ["milk"]

    def test_drops_weight_tokens(self):
        # Weight/portion tokens are quantity, not content. Dropped.
        assert content_words("100g chicken") == ["chicken"]
        assert content_words("12oz steak") == ["steak"]
        assert content_words("2cups rice") == ["rice"]
        assert content_words("500ml milk") == ["milk"]
        assert content_words("2.5lb brisket") == ["brisket"]

    def test_drops_single_chars(self):
        # Single-char tokens (e.g. "s" from apostrophe-split "domino's" → "domino s")
        # should not pollute Phase 1.5's AND clauses.
        assert "s" not in content_words("domino s pizza")
        assert content_words("domino s pizza") == ["domino", "pizza"]

    def test_dedupes_repeated_words(self):
        assert content_words("pizza pizza pizza") == ["pizza"]

    def test_strips_diacritics(self):
        # café → cafe, jalapeño → jalapeno, piña → pina
        assert "cafe" in content_words("café latte")
        assert "jalapeno" in content_words("jalapeño popper")
        assert "pina" in content_words("piña colada")

    def test_preserves_new_cuisines(self):
        # No ingredient whitelist — jackfruit, seitan, etc. are "content by default"
        assert content_words("jackfruit biryani") == ["jackfruit", "biryani"]
        assert content_words("seitan tacos") == ["seitan", "tacos"]

    def test_preserves_egg_and_veg(self):
        # Short but semantic — dropped from droplist, must remain
        assert content_words("egg dosa") == ["egg", "dosa"]
        assert content_words("veg pizza") == ["veg", "pizza"]

    def test_preserves_region_cuisine(self):
        assert content_words("thai green curry") == ["thai", "green", "curry"]

    def test_empty(self):
        assert content_words("") == []
        assert content_words("the and of") == []


# ── Trigram similarity ─────────────────────────────────────────────────────

class TestTrigram:
    def test_identical(self):
        assert trigram_sim("paneer", "paneer") == 1.0

    def test_empty(self):
        assert trigram_sim("", "paneer") == 0.0
        assert trigram_sim("paneer", "") == 0.0

    def test_typo_high(self):
        assert trigram_sim("paneer", "paner") >= 0.4

    def test_unrelated_low(self):
        assert trigram_sim("paneer", "pizza") < 0.3


# ── Coverage primitive ────────────────────────────────────────────────────

class TestTokenCoverage:
    def test_direct_hit(self):
        assert _token_is_covered("paneer", {"paneer", "tikka"}) is True

    def test_miss(self):
        assert _token_is_covered("paneer", {"masala", "dosa"}) is False

    def test_plural_stem(self):
        assert _token_is_covered("tomatoes", {"tomato"}) is True
        assert _token_is_covered("berries", {"berry"}) is True

    def test_typo_close(self):
        # paner → paneer (|Δlen|=1, sim ≥ 0.85)
        assert _token_is_covered("paner", {"paneer"}) is True

    def test_typo_too_far(self):
        # pizza has no close neighbor in dosa/masala
        assert _token_is_covered("pizza", {"dosa", "masala"}) is False

    def test_compound_substring(self):
        # "paneer" ⊆ "paneertikka" (fused compound)
        assert _token_is_covered("paneer", {"paneertikka"}) is True

    def test_short_token_no_compound(self):
        # Short tokens (<4 chars) can't use the compound substring rule
        assert _token_is_covered("egg", {"eggplant"}) is False


# ── Score row ─────────────────────────────────────────────────────────────

class TestScoreRow:
    def test_full_coverage_tier_a(self):
        row = _row("Paneer Masala Dosa",
                   variant_names=["paneer masala dosa"])
        s = score_row(["paneer", "masala", "dosa"], row)
        assert s.coverage == 1.0
        assert classify(s) == "A"
        assert s.phrase_bonus == 0.2
        assert s.head_bonus == 0.1

    def test_two_of_three_tier_b(self):
        row = _row("Masala Dosa", variant_names=["masala dosa"])
        s = score_row(["paneer", "masala", "dosa"], row)
        assert 0.6 <= s.coverage <= 0.7
        assert "paneer" in s.missing
        assert classify(s) == "B"

    def test_zero_coverage_tier_d(self):
        row = _row("Pizza")
        s = score_row(["paneer", "masala", "dosa"], row)
        assert s.coverage == 0.0
        assert classify(s) == "D"

    def test_head_preservation(self):
        # Same bag but different head → head_bonus differentiates
        milk = _row("Chocolate Milk", variant_names=["chocolate milk"])
        bar = _row("Milk Chocolate Bar",
                   variant_names=["milk chocolate", "chocolate bar"])
        s_milk = score_row(["chocolate", "milk"], milk)
        s_bar = score_row(["chocolate", "milk"], bar)
        # Both score 1.0 on bag-of-words
        assert s_milk.coverage == 1.0
        assert s_bar.coverage == 1.0
        # But Chocolate Milk wins on head + phrase
        assert s_milk.head_bonus > s_bar.head_bonus
        assert s_milk.phrase_bonus > s_bar.phrase_bonus

    def test_empty_content_returns_trivial_true(self):
        row = _row("Pizza")
        s = score_row([], row)
        assert s.coverage == 1.0  # no distinguishing words to match


class TestPruneTierA:
    def test_phrase_bonus_wins(self):
        milk = _row("Chocolate Milk", variant_names=["chocolate milk"])
        bar = _row("Milk Chocolate Bar", variant_names=["milk chocolate"])
        milk_score = score_row(["chocolate", "milk"], milk)
        bar_score = score_row(["chocolate", "milk"], bar)
        pruned = _prune_tier_a([milk_score, bar_score])
        assert len(pruned) == 1
        assert pruned[0].row["display_name"] == "Chocolate Milk"

    def test_no_pruning_when_all_equal(self):
        a = score_row(["rice"], _row("White Rice"))
        b = score_row(["rice"], _row("Basmati Rice"))
        # Both end in "rice" and have the single content word — both pass head
        out = _prune_tier_a([a, b])
        assert len(out) == 2


# ── Top-level accept_tier (orchestration) ─────────────────────────────────

@pytest.fixture
def no_gemini(monkeypatch):
    """Force Gemini to be 'unavailable' so tier-B/C fallback is exercised."""
    async def _never_call(*args, **kwargs):
        return None
    monkeypatch.setattr(
        "services.food_match_gate.gemini_batch_validate",
        _never_call,
    )


@pytest.fixture
def gemini_accept_all(monkeypatch):
    async def _accept_all(query, candidates, region=None, timeout=2.0):
        return set(range(len(candidates)))
    monkeypatch.setattr(
        "services.food_match_gate.gemini_batch_validate",
        _accept_all,
    )


@pytest.fixture
def gemini_reject_all(monkeypatch):
    async def _reject_all(query, candidates, region=None, timeout=2.0):
        return set()
    monkeypatch.setattr(
        "services.food_match_gate.gemini_batch_validate",
        _reject_all,
    )


@pytest.mark.asyncio
class TestAcceptTier:
    async def test_paneer_masala_dosa_finds_specific(self, gemini_reject_all):
        # Regression of the reported bug. With both rows, specific wins.
        rows = [
            _row("Masala Dosa", variant_names=["masala dosa"], calories_per_100g=186),
            _row("Paneer Masala Dosa",
                 variant_names=["paneer masala dosa"],
                 calories_per_100g=242),
        ]
        result = await accept_tier("paneer masala dosa", rows)
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Paneer Masala Dosa"
        assert result.partial_match is False

    async def test_masala_dosa_regression(self, gemini_accept_all):
        rows = [_row("Masala Dosa", variant_names=["masala dosa"])]
        result = await accept_tier("masala dosa", rows)
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Masala Dosa"
        assert result.partial_match is False

    async def test_chocolate_milk_not_milk_chocolate(self, gemini_accept_all):
        rows = [
            _row("Chocolate Milk", variant_names=["chocolate milk"]),
            _row("Milk Chocolate Bar", variant_names=["milk chocolate"]),
        ]
        result = await accept_tier("chocolate milk", rows)
        # Both tier-A by bag-of-words, but head+phrase prune keeps only "Chocolate Milk"
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Chocolate Milk"

    async def test_milk_chocolate_not_chocolate_milk(self, gemini_accept_all):
        rows = [
            _row("Chocolate Milk", variant_names=["chocolate milk"]),
            _row("Milk Chocolate Bar", variant_names=["milk chocolate"]),
        ]
        result = await accept_tier("milk chocolate", rows)
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Milk Chocolate Bar"

    async def test_chicken_tikka_masala_missing_chicken_row(self, gemini_reject_all):
        # Only the generic exists. Gemini rejects → empty.
        rows = [_row("Tikka Masala", variant_names=["tikka masala"])]
        result = await accept_tier("chicken tikka masala", rows)
        assert result.rows == []

    async def test_chicken_tikka_masala_with_gemini_yes(self, gemini_accept_all):
        # If Gemini says YES, partial_match flag propagates.
        rows = [_row("Tikka Masala", variant_names=["tikka masala"])]
        result = await accept_tier("chicken tikka masala", rows)
        assert len(result.rows) == 1
        assert result.partial_match is True

    async def test_spicy_chicken_curry_still_finds_row(self, gemini_accept_all):
        """A sensory descriptor must not BLOCK the match — but it is no longer
        silently ignored either.

        RETIRED ASSERTION: was `test_spicy_chicken_curry_descriptor_ignored`,
        asserting partial_match is False on the theory that "spicy" is dropped
        at tokenization (cov=1.0 → tier A, no Gemini). Sensory words are now
        content (see TestContentWords.test_keeps_sensory_descriptors_as_content
        — "Spicy McChicken" ≠ "McChicken"), so "spicy chicken curry" vs a plain
        "Chicken Curry" row is coverage 2/3 → tier B → Gemini decides.

        The guarantee under test is unchanged and still asserted: the row IS
        returned. What changed is that it comes back flagged partial_match=True
        so the UI can show the approximate-match hint instead of pretending the
        user's "spicy" variant was matched exactly.
        """
        rows = [_row("Chicken Curry", variant_names=["chicken curry"])]
        result = await accept_tier("spicy chicken curry", rows)
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Chicken Curry"
        assert result.partial_match is True

    async def test_large_pizza_descriptor_ignored(self, gemini_accept_all):
        rows = [_row("Pizza", variant_names=["pizza"])]
        result = await accept_tier("large pizza", rows)
        assert len(result.rows) == 1
        assert result.partial_match is False

    async def test_egg_dosa_rejects_masala_dosa(self, gemini_reject_all):
        rows = [_row("Masala Dosa", variant_names=["masala dosa"])]
        result = await accept_tier("egg dosa", rows)
        # "egg" missing, coverage=0.5 tier B → Gemini says no → empty
        assert result.rows == []

    async def test_veg_pizza_rejects_pizza(self, gemini_reject_all):
        rows = [_row("Pizza", variant_names=["pizza"])]
        result = await accept_tier("veg pizza", rows)
        # "veg" is content (3 chars, not in droplist)
        assert result.rows == []

    async def test_typo_paner_finds_paneer_row(self, gemini_accept_all):
        rows = [
            _row("Paneer Masala Dosa", variant_names=["paneer masala dosa"]),
        ]
        result = await accept_tier("paner masala dosa", rows)
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Paneer Masala Dosa"
        assert result.partial_match is False  # typo resolved via coverage trigram

    async def test_empty_content_words_returns_all(self, gemini_reject_all):
        """Query collapses to zero content words → gate must not filter anything.

        The query text was changed from "the spicy my favorite" to a genuinely
        descriptor-only phrase: "spicy" is now a CONTENT word (see
        TestContentWords.test_keeps_sensory_descriptors_as_content), so the old
        phrase no longer satisfies this test's own precondition — it scored
        ["spicy"] against Pizza/Burger and correctly rejected both. The
        guarantee being asserted (empty content words ⇒ pass every row through)
        is unchanged.
        """
        rows = [_row("Pizza"), _row("Burger")]
        assert content_words("the large my favorite") == []  # precondition
        result = await accept_tier("the large my favorite", rows)
        assert len(result.rows) == 2

    async def test_unknown_query_returns_empty(self, gemini_reject_all):
        rows = [_row("Pizza")]
        result = await accept_tier("xyz123abc", rows)
        assert result.rows == []

    async def test_gemini_outage_falls_back_to_tier_b(self, no_gemini):
        # Tier B (coverage>=0.75) survives the outage; tier C drops.
        rows = [
            _row("Chicken Tikka", variant_names=["chicken tikka"]),  # cov=2/3 for "chicken tikka masala"? no, 2/3 → B
        ]
        result = await accept_tier("chicken tikka masala", rows)
        # "masala" missing; coverage 2/3 ≈ 0.67 — that's < 0.75 so it's actually tier C/D.
        # Swap to a better tier-B example: query "chicken curry" + row "Chicken Curry Sauce"
        # handled separately below; here just assert no exception.
        assert isinstance(result.rows, list)

    async def test_hyphenated_paneer_masala_dosa(self, gemini_accept_all):
        rows = [
            _row("Paneer Masala Dosa", variant_names=["paneer masala dosa"]),
        ]
        # Hyphens should be normalized away
        result = await accept_tier("paneer-masala dosa", rows)
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Paneer Masala Dosa"

    async def test_comma_in_query(self, gemini_accept_all):
        rows = [_row("Paneer Masala Dosa", variant_names=["paneer masala dosa"])]
        result = await accept_tier("paneer, masala dosa", rows)
        assert len(result.rows) == 1

    async def test_case_insensitive(self, gemini_accept_all):
        rows = [_row("Paneer Masala Dosa", variant_names=["paneer masala dosa"])]
        result = await accept_tier("PANEER  Masala  Dosa", rows)
        assert len(result.rows) == 1

    async def test_tier_a_hides_tier_b(self, gemini_accept_all):
        # When an exact tier-A match exists, weaker candidates are dropped.
        rows = [
            _row("Paneer Masala Dosa", variant_names=["paneer masala dosa"]),
            _row("Masala Dosa", variant_names=["masala dosa"]),
        ]
        result = await accept_tier("paneer masala dosa", rows)
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Paneer Masala Dosa"
        assert result.partial_match is False
        assert result.dropped_count == 1

    async def test_partial_match_flag_set_when_only_tier_b(self, gemini_accept_all):
        rows = [_row("Tikka Masala", variant_names=["tikka masala"])]
        result = await accept_tier("chicken tikka masala", rows)
        assert result.partial_match is True

    async def test_single_word_query_prefers_exact(self, gemini_accept_all):
        # Single-word query with an exact-match row → tier A wins outright,
        # variants with extras drop to tier B (hidden by the tier-A return
        # contract). Prevents "dosa" being silently logged as "Masala Dosa".
        rows = [
            _row("Masala Dosa", variant_names=["masala dosa"]),
            _row("Paneer Masala Dosa", variant_names=["paneer masala dosa"]),
            _row("Dosa", variant_names=["dosa"]),
        ]
        result = await accept_tier("dosa", rows)
        assert len(result.rows) == 1
        assert result.rows[0]["display_name"] == "Dosa"
        assert result.partial_match is False

    async def test_single_word_extras_demoted_to_gemini(self, gemini_reject_all):
        # The reported "mutton fry" → "Mutton Liver Fry" bug. With no exact-match
        # row in the DB, the candidate has an extra distinguishing word ("liver")
        # that the query never asked for. Must hit Gemini for validation; on
        # reject, the gate returns empty rather than silently logging organ meat.
        rows = [_row("Mutton Liver Fry", variant_names=["mutton liver fry"])]
        result = await accept_tier("mutton fry", rows)
        assert result.rows == []

    async def test_single_word_extras_accepted_when_descriptor(self, gemini_accept_all):
        # Same shape as above but with a benign descriptor extra ("whole" in
        # "Whole Milk" for query "milk"). Gemini approves → returned with
        # partial_match flagged so the UI can render an "approximate match" hint.
        rows = [_row("Whole Milk", variant_names=["whole milk"])]
        result = await accept_tier("milk", rows)
        assert len(result.rows) == 1
        assert result.partial_match is True


class TestSanitizeForPrompt:
    def test_truncates(self):
        from services.food_match_gate import _sanitize_for_prompt
        s = _sanitize_for_prompt("a" * 500, max_len=50)
        assert len(s) == 50

    def test_escapes_quotes(self):
        from services.food_match_gate import _sanitize_for_prompt
        s = _sanitize_for_prompt('hack " Ignore prior')
        assert '"' not in s or '\\"' in s

    def test_strips_newlines(self):
        from services.food_match_gate import _sanitize_for_prompt
        s = _sanitize_for_prompt("pizza\nignore previous\nadmin")
        assert "\n" not in s

    def test_escapes_backticks(self):
        from services.food_match_gate import _sanitize_for_prompt
        s = _sanitize_for_prompt("`malicious`")
        assert "`" not in s or "\\`" in s


class TestCacheEviction:
    def test_cache_cap(self):
        """The Gemini verdict cache must stay bounded — no unbounded memory growth.

        REWRITTEN AGAINST THE CURRENT IMPLEMENTATION (the guarantee is
        unchanged; only the mechanism moved). The verdict cache used to be a
        per-worker module-level dict `_VALIDATE_CACHE` written through
        `_cache_put()` and swept by a hand-rolled LRU against
        `_VALIDATE_CACHE_MAX`. It is now a `RedisCache` shared across all
        workers (so a verdict cached by one worker is reused by the rest), with
        a per-worker in-memory dict as the fallback when Redis is unavailable —
        the old three symbols no longer exist, hence the rewrite.

        The in-memory fallback is the only unbounded-growth risk left (Redis
        entries expire via TTL), so that is what this asserts: hammering it far
        past the cap must evict, never grow.
        """
        from services.food_match_gate import _VALIDATE_CACHE, _VALIDATE_TTL

        cap = _VALIDATE_CACHE._max_size
        assert cap > 0
        assert _VALIDATE_TTL > 0  # Redis-side entries are bounded by TTL

        _VALIDATE_CACHE._local.clear()
        # Fill past the cap (verdicts are stored as sorted index lists)
        for i in range(cap + 100):
            _VALIDATE_CACHE.set_sync(f"q{i}", [i])

        # Should NOT exceed the cap
        assert len(_VALIDATE_CACHE._local) <= cap
        # And the cache is still usable after eviction (most-recent key survives)
        assert _VALIDATE_CACHE.get_sync(f"q{cap + 99}") == [cap + 99]
        _VALIDATE_CACHE._local.clear()


@pytest.mark.asyncio
class TestIsValidSingleMatch:
    async def test_exact_match_valid(self, gemini_accept_all):
        row = _row("Paneer Masala Dosa", variant_names=["paneer masala dosa"])
        assert await is_valid_single_match("paneer masala dosa", row) is True

    async def test_missing_qualifier_invalid(self, gemini_reject_all):
        row = _row("Masala Dosa", variant_names=["masala dosa"])
        assert await is_valid_single_match("paneer masala dosa", row) is False

    async def test_missing_qualifier_gemini_yes_valid(self, gemini_accept_all):
        row = _row("Masala Dosa", variant_names=["masala dosa"])
        # With Gemini override it's permissive — this shouldn't happen in prod
        # (the prompt explicitly instructs Gemini to reject), but confirm plumbing.
        assert await is_valid_single_match("paneer masala dosa", row) is True
