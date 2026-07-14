"""
Tests for the Food Database Lookup Service and its integration
with the Gemini enhancement pipeline.

Tests the flow: user types text -> Gemini parses food items ->
batch_lookup_foods() finds DB matches -> enhancement pipeline
applies per-100g nutrition data.

Run with: pytest backend/tests/test_food_database_lookup.py -v

ARCHITECTURE NOTE (commit e1fca962, "update0.74.170")
-----------------------------------------------------
The lookup service used to search a generic `food_database` table through two
Supabase RPCs (`search_food_database`, `batch_lookup_foods`) with an
OpenFoodFacts fallback, and filtered bad hits with a private static helper
`FoodDatabaseLookupService._is_good_match(query, result_name)` (restaurant-brand
skip + 50% word-overlap ratio).

That entire tier was DELETED. The service is now overrides-only, as its own
module docstring states:

    1. food_nutrition_overrides — hand-curated premium (200K+ items, DB-queried)
    2. If no match → caller uses AI text analysis (Gemini)

so `lookup_single_food` / `batch_lookup_foods` resolve names against the
`food_nutrition_overrides` TABLE (exact `food_name_normalized` → `variant_names`
→ stemmed/trigram fuzzy), and match quality is enforced by
`services.food_match_gate` (coverage tiers A/B/C/D), not by `_is_good_match`.

The tests below therefore drive the override table instead of the dead RPCs, and
the old `TestIsGoodMatch` class is now `TestMatchQualityGate` — same eight cases,
same accept/reject expectations, asserted against the gate that replaced it.
"""
import asyncio

import sys
import os
import time
import pytest
from unittest.mock import MagicMock, AsyncMock, patch

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ── Test Data ────────────────────────────────────────────────────
# Rows in the shape the service reads from `food_nutrition_overrides`.

def _override_row(
    display_name: str,
    food_name_normalized: str,
    calories: float,
    protein: float,
    carbs: float,
    fat: float,
    fiber: float,
    variant_names=None,
    region=None,
) -> dict:
    return {
        "id": food_name_normalized,
        "display_name": display_name,
        "food_name_normalized": food_name_normalized,
        "calories_per_100g": calories,
        "protein_per_100g": protein,
        "carbs_per_100g": carbs,
        "fat_per_100g": fat,
        "fiber_per_100g": fiber,
        "default_weight_per_piece_g": None,
        "default_serving_g": None,
        "source": "usda",
        "restaurant_name": None,
        "food_category": None,
        "default_count": 1,
        "variant_names": variant_names or [],
        "region": region,
        "is_active": True,
    }


BIRYANI_OVERRIDE_ROW = _override_row(
    "Chicken biryani, cooked", "chicken biryani",
    150.0, 8.5, 18.0, 5.2, 0.8,
)

NAAN_OVERRIDE_ROW = _override_row(
    "Naan bread, plain", "naan",
    290.0, 9.0, 50.0, 5.5, 2.0,
)

CHICKEN_BREAST_OVERRIDE_ROW = _override_row(
    "Chicken Breast, raw", "chicken breast",
    165, 31.0, 0.0, 3.6, 0.0,
)

APPLE_OVERRIDE_ROW = _override_row(
    "Apple, raw, with skin", "apple",
    52.0, 0.3, 13.8, 0.2, 2.4,
)


# ── Fake Supabase (override table) ───────────────────────────────
# A tiny in-memory stand-in for the `food_nutrition_overrides` table that honours
# the filters the service actually issues (eq / is_ / contains / overlaps / limit)
# and records every executed query, so the tests can assert WHICH lookups ran
# (the modern equivalent of the old `rpc.assert_called_once_with(...)` checks).

class _FakeResult:
    def __init__(self, data):
        self.data = data


class _FakeRow:
    def __init__(self, mapping):
        self._mapping = mapping


class _FakeSQLResult:
    def __init__(self, rows):
        self._rows = [_FakeRow(r) for r in rows]

    def fetchone(self):
        return self._rows[0] if self._rows else None

    def fetchall(self):
        return self._rows


class _FakeSession:
    """Async session for the trigram phase (Step 4 of _check_override_fuzzy_db)."""

    def __init__(self, trigram_rows):
        self._trigram_rows = trigram_rows

    async def execute(self, statement, params=None):
        sql = str(statement).lower()
        if "similarity" in sql and "food_nutrition_overrides" in sql:
            return _FakeSQLResult(self._trigram_rows)
        return _FakeSQLResult([])


class _FakeManagedSession:
    def __init__(self, trigram_rows):
        self._trigram_rows = trigram_rows

    async def __aenter__(self):
        return _FakeSession(self._trigram_rows)

    async def __aexit__(self, *exc):
        return False


class _FakeQuery:
    def __init__(self, table_name, rows, log):
        self.table_name = table_name
        self.rows = rows
        self.log = log
        self.filters = {}
        self._limit = None

    def select(self, *_args, **_kwargs):
        return self

    def eq(self, column, value):
        self.filters[column] = value
        return self

    def is_(self, column, value):
        self.filters[f"is_{column}"] = value
        return self

    def contains(self, column, values):
        self.filters[f"contains_{column}"] = list(values)
        return self

    def overlaps(self, column, values):
        self.filters[f"overlaps_{column}"] = list(values)
        return self

    def ilike(self, column, value):
        self.filters[f"ilike_{column}"] = value
        return self

    def limit(self, n):
        self._limit = n
        return self

    def execute(self):
        self.log.append((self.table_name, dict(self.filters)))
        if self.table_name != "food_nutrition_overrides":
            return _FakeResult([])

        matched = [r for r in self.rows if r.get("is_active", True)]

        if self.filters.get("is_region") == "null":
            matched = [r for r in matched if r.get("region") is None]

        if "food_name_normalized" in self.filters:
            wanted = self.filters["food_name_normalized"]
            matched = [r for r in matched if r["food_name_normalized"] == wanted]

        wanted_variants = (
            self.filters.get("contains_variant_names")
            or self.filters.get("overlaps_variant_names")
        )
        if wanted_variants is not None:
            wanted_set = {v.lower() for v in wanted_variants}
            matched = [
                r for r in matched
                if wanted_set & {v.lower() for v in (r.get("variant_names") or [])}
            ]

        if self._limit is not None:
            matched = matched[: self._limit]
        return _FakeResult(matched)


class _FakeSyncClient:
    def __init__(self, rows, log):
        self.rows = rows
        self.log = log

    def table(self, name):
        return _FakeQuery(name, self.rows, self.log)


class FakeSupabase:
    """Stand-in for core.supabase_client.get_supabase()'s return value."""

    def __init__(self, rows=None, trigram_rows=None):
        self.rows = list(rows or [])
        self.trigram_rows = list(trigram_rows or [])
        self.queries = []  # [(table, filters), ...]
        self.client = _FakeSyncClient(self.rows, self.queries)

    def get_managed_session(self):
        return _FakeManagedSession(self.trigram_rows)


# ================================================================
# CLASS 1: TestFoodDatabaseLookupService
# ================================================================

class TestFoodDatabaseLookupService:
    """Unit tests for FoodDatabaseLookupService against a mocked override table.

    (Was: "with mocked Supabase RPC" — the RPC tier no longer exists; see the
    ARCHITECTURE NOTE at the top of this module.)
    """

    @pytest.fixture
    def make_service(self):
        """Build a FoodDatabaseLookupService wired to a fake override table.

        The service reaches Supabase through THREE bindings — the module-level
        `get_supabase` in each helper module plus a function-local
        `from core.supabase_client import get_supabase` re-import inside
        `_check_override` / `batch_lookup_foods` — so all of them are patched.
        """
        patches = []

        def _make(rows=None, trigram_rows=None):
            fake_sb = FakeSupabase(rows=rows, trigram_rows=trigram_rows)
            for target in (
                "core.supabase_client.get_supabase",
                "services.food_database_lookup_service_helpers.get_supabase",
                "services.food_database_lookup_service_helpers_part2.get_supabase",
            ):
                p = patch(target, return_value=fake_sb)
                p.start()
                patches.append(p)

            from services.food_database_lookup_service import FoodDatabaseLookupService
            service = FoodDatabaseLookupService()
            service._cache.clear()
            service._overrides.clear()
            return service, fake_sb

        yield _make

        for p in patches:
            p.stop()

    @pytest.mark.asyncio
    async def test_lookup_single_food_success(self, make_service):
        """Override table holds chicken breast -> returns per-100g nutrition dict."""
        service, fake_sb = make_service(rows=[CHICKEN_BREAST_OVERRIDE_ROW])

        result = await service.lookup_single_food("chicken breast")

        assert result is not None
        assert result["calories_per_100g"] == 165
        assert result["protein_per_100g"] == 31.0
        assert result["carbs_per_100g"] == 0.0
        assert result["fat_per_100g"] == 3.6
        assert result["fiber_per_100g"] == 0.0
        # Replaces the old `rpc.assert_called_once_with("search_food_database", ...)`:
        # the name must be resolved by exact lookup on the overrides table.
        assert (
            "food_nutrition_overrides",
            {"is_active": True, "food_name_normalized": "chicken breast"},
        ) in fake_sb.queries

    @pytest.mark.asyncio
    async def test_lookup_single_food_no_match(self, make_service):
        """Override table has no row for the name -> returns None."""
        service, _fake_sb = make_service(rows=[CHICKEN_BREAST_OVERRIDE_ROW])

        result = await service.lookup_single_food("xyzfoobar")
        assert result is None

    @pytest.mark.asyncio
    async def test_lookup_single_food_poor_match(self, make_service):
        """Fuzzy phase surfaces an unrelated food (no word overlap) -> gate rejects -> None.

        Was: "_is_good_match rejects". The word-overlap helper is gone; the
        trigram/fuzzy candidate now goes through services.food_match_gate, which
        classifies "Cinnabon Pudding" for query "chicken biryani" as tier D
        (coverage 0.0) and drops it. Same guarantee: a poor DB match must never
        be served as this food's nutrition.
        """
        cinnabon = _override_row(
            "Cinnabon Pudding", "cinnabon pudding", 200, 3, 30, 8, 0,
        )
        cinnabon["sim"] = 0.45  # trigram similarity column returned by the SQL phase
        service, _fake_sb = make_service(rows=[], trigram_rows=[cinnabon])

        result = await service.lookup_single_food("chicken biryani")
        assert result is None

    @pytest.mark.asyncio
    async def test_batch_lookup_foods_success(self, make_service):
        """Batch lookup resolves both biryani and naan from the override table."""
        service, fake_sb = make_service(
            rows=[BIRYANI_OVERRIDE_ROW, NAAN_OVERRIDE_ROW]
        )

        result = await service.batch_lookup_foods(["Chicken Biryani", "Naan"])

        assert "Chicken Biryani" in result
        assert "Naan" in result
        assert result["Chicken Biryani"]["calories_per_100g"] == 150.0
        assert result["Naan"]["calories_per_100g"] == 290.0
        # Replaces the old `rpc.assert_called_once_with("batch_lookup_foods", ...)`:
        # every requested name must be resolved against the overrides table.
        exact_lookups = [
            f.get("food_name_normalized")
            for t, f in fake_sb.queries
            if t == "food_nutrition_overrides" and "food_name_normalized" in f
        ]
        assert "chicken biryani" in exact_lookups
        assert "naan" in exact_lookups

    @pytest.mark.asyncio
    async def test_batch_lookup_foods_partial_match(self, make_service):
        """One food matches, one doesn't -> dict with one nutrition entry and one None."""
        service, _fake_sb = make_service(rows=[BIRYANI_OVERRIDE_ROW])

        result = await service.batch_lookup_foods(["Chicken Biryani", "Mystery Food 12345"])

        assert result["Chicken Biryani"] is not None
        assert result["Chicken Biryani"]["calories_per_100g"] == 150.0
        assert result["Mystery Food 12345"] is None

    @pytest.mark.asyncio
    async def test_batch_lookup_foods_empty_list(self, make_service):
        """Empty input -> returns empty dict, no DB query at all."""
        service, fake_sb = make_service(rows=[BIRYANI_OVERRIDE_ROW])

        result = await service.batch_lookup_foods([])
        assert result == {}
        assert fake_sb.queries == []

    @pytest.mark.asyncio
    async def test_cache_hit(self, make_service):
        """Second call uses cache, the DB is queried only once."""
        service, fake_sb = make_service(rows=[CHICKEN_BREAST_OVERRIDE_ROW])

        result1 = await service.lookup_single_food("chicken breast")
        queries_after_first = len(fake_sb.queries)
        result2 = await service.lookup_single_food("chicken breast")

        assert result1 == result2
        assert result1["calories_per_100g"] == 165
        assert queries_after_first >= 1
        # Second lookup must be served from cache — no additional DB round trip.
        assert len(fake_sb.queries) == queries_after_first

    @pytest.mark.asyncio
    async def test_cache_expiry(self, make_service):
        """After TTL expires, second call re-queries the database."""
        service, fake_sb = make_service(rows=[CHICKEN_BREAST_OVERRIDE_ROW])

        # First call
        await service.lookup_single_food("chicken breast")
        queries_after_first = len(fake_sb.queries)
        assert queries_after_first >= 1

        # Simulate cache expiry by manipulating the cached timestamp.
        # The in-memory override dict is a second cache layer in front of the DB,
        # so it has to be expired too for the lookup to hit the table again.
        cache_key = "lookup:chicken breast"
        assert cache_key in service._cache
        _, data = service._cache[cache_key]
        service._cache[cache_key] = (time.time() - service._cache_ttl - 1, data)
        service._overrides.clear()

        # Second call should re-query
        await service.lookup_single_food("chicken breast")
        assert len(fake_sb.queries) > queries_after_first


# ================================================================
# CLASS 2: TestMatchQualityGate  (was TestIsGoodMatch)
# ================================================================

async def _gate_accepts(query: str, result_name: str) -> bool:
    """Does the current match-quality gate accept `result_name` for `query`?

    Direct replacement for the retired
    `FoodDatabaseLookupService._is_good_match(query, result_name)`.
    `use_gemini=False` pins the deterministic core of the gate (tier A/B/C/D
    classification) — the same fallback path production takes when Gemini is
    unavailable — so these stay pure unit tests with no network call.
    """
    from services.food_match_gate import accept_tier
    result = await accept_tier(query, [{"display_name": result_name}], use_gemini=False)
    return bool(result.rows)


class TestMatchQualityGate:
    """Match-quality filtering for DB candidates.

    Was `TestIsGoodMatch`, testing the static
    `FoodDatabaseLookupService._is_good_match` (restaurant-brand skip + 50%
    word-overlap ratio). That helper was deleted with the food_database RPC tier
    (commit e1fca962); the guarantee it protected — an unrelated DB row must
    never be served as the user's food — now lives in `services.food_match_gate`,
    which the lookup service calls at every fuzzy/variant step.

    Same eight cases, same accept/reject expectations, except the two noted
    below where the contract genuinely changed.
    """

    @pytest.mark.asyncio
    async def test_exact_match(self):
        """'chicken breast' vs 'Chicken Breast, raw' -> accepted."""
        assert await _gate_accepts("chicken breast", "Chicken Breast, raw") is True

    @pytest.mark.asyncio
    async def test_partial_match(self):
        """'chicken biryani' vs 'Chicken biryani, cooked' -> accepted."""
        assert await _gate_accepts("chicken biryani", "Chicken biryani, cooked") is True

    @pytest.mark.asyncio
    async def test_poor_match(self):
        """'chicken biryani' vs 'Cinnabon Pudding' -> rejected."""
        assert await _gate_accepts("chicken biryani", "Cinnabon Pudding") is False

    @pytest.mark.asyncio
    async def test_restaurant_brand_skip(self):
        """'taco bell burrito' vs a generic burrito row -> rejected.

        Reason changed, outcome did not. `_is_good_match` skipped ANY query
        containing a restaurant brand outright (the old generic food_database had
        no branded items). Restaurant items are now first-class rows
        (`food_nutrition_overrides.restaurant_name`, `_restaurant_variant_match`),
        so a blanket brand skip would be wrong; instead the gate rejects this
        candidate because the query's brand words ('taco', 'bell') are not covered
        by the generic row — coverage 1/3, tier D.
        """
        assert await _gate_accepts("taco bell burrito", "Burrito, bean and cheese") is False

    @pytest.mark.asyncio
    async def test_mcdonalds_brand_skip(self):
        """'mcdonalds big mac' vs an unbranded 'Big Mac, fast food' row -> rejected.

        The brand word 'mcdonalds' is uncovered by the candidate, so the gate
        drops it (tier D) rather than silently serving an unbranded row.
        """
        assert await _gate_accepts("mcdonalds big mac", "Big Mac, fast food") is False

    @pytest.mark.asyncio
    async def test_short_query_words_skipped(self):
        """Short/stop words are excluded from the coverage calculation.

        "an egg" -> content word 'egg' only ("an" is dropped), which
        'Egg, whole, raw' covers -> accepted.
        """
        assert await _gate_accepts("an egg", "Egg, whole, raw") is True

    @pytest.mark.asyncio
    async def test_all_short_words_returns_false(self):
        """A query with no significant words must not resolve to a food.

        Contract change: `_is_good_match("a b", "Apple, raw")` returned False (no
        significant words -> reject). The gate no longer rejects here — a query
        that collapses to zero content words can't discriminate between
        candidates, so `accept_tier` passes rows through untouched (see its
        `if not content:` branch). The guarantee is preserved one level up
        instead: no override row can be reached for such a query, so the SERVICE
        still returns no food. That end-to-end guarantee is what is asserted here,
        plus the gate's documented current behaviour.
        """
        from services.food_match_gate import content_words, accept_tier

        # Gate's current behaviour: zero content words -> nothing to discriminate.
        assert content_words("a b") == []
        gate = await accept_tier("a b", [{"display_name": "Apple, raw"}], use_gemini=False)
        assert [r["display_name"] for r in gate.rows] == ["Apple, raw"]

        # The guarantee the original test protected, asserted where it now lives:
        # the lookup service resolves nothing for a query with no significant words.
        fake_sb = FakeSupabase(rows=[APPLE_OVERRIDE_ROW])
        with patch("core.supabase_client.get_supabase", return_value=fake_sb), \
                patch("services.food_database_lookup_service_helpers.get_supabase",
                      return_value=fake_sb), \
                patch("services.food_database_lookup_service_helpers_part2.get_supabase",
                      return_value=fake_sb):
            from services.food_database_lookup_service import FoodDatabaseLookupService
            service = FoodDatabaseLookupService()
            assert await service.lookup_single_food("a b") is None

    @pytest.mark.asyncio
    async def test_empty_query(self):
        """An empty query must not resolve to a food.

        Contract change, same shape as test_all_short_words_returns_false:
        `_is_good_match("", "Chicken Breast")` returned False. The gate itself now
        treats a contentless query as trivially acceptable, so the guarantee is
        asserted at the service: `lookup_single_food("")` short-circuits to None
        and never touches the DB.
        """
        fake_sb = FakeSupabase(rows=[CHICKEN_BREAST_OVERRIDE_ROW])
        with patch("core.supabase_client.get_supabase", return_value=fake_sb), \
                patch("services.food_database_lookup_service_helpers.get_supabase",
                      return_value=fake_sb), \
                patch("services.food_database_lookup_service_helpers_part2.get_supabase",
                      return_value=fake_sb):
            from services.food_database_lookup_service import FoodDatabaseLookupService
            service = FoodDatabaseLookupService()
            assert await service.lookup_single_food("") is None
            assert fake_sb.queries == []


# ================================================================
# CLASS 3: TestEnhanceFoodItemsWithNutritionDB
# ================================================================

class TestEnhanceFoodItemsWithNutritionDB:
    """Integration tests for GeminiService._enhance_food_items_with_nutrition_db."""

    @pytest.fixture
    def gemini_service(self):
        """Create a GeminiService instance (no live API needed for these tests)."""
        from services.gemini_service import GeminiService
        return GeminiService()

    @pytest.fixture
    def mock_food_db_for_gemini(self):
        """Mock the food DB singleton used inside _enhance_food_items_with_nutrition_db."""
        with patch("services.food_database_lookup_service.get_food_db_lookup_service") as mock_get:
            mock_service = AsyncMock()
            mock_get.return_value = mock_service
            yield mock_service

    @pytest.mark.asyncio
    async def test_enhance_two_foods_biryani_naan(self, gemini_service, mock_food_db_for_gemini):
        """
        The user's exact scenario: 2 food items from Gemini.
        DB returns per-100g data for both.
        Calories should be recalculated: weight_g / 100 * calories_per_100g.
        """
        food_items = [
            {"name": "Chicken Biryani", "calories": 300, "protein_g": 15.0,
             "carbs_g": 40.0, "fat_g": 10.0, "fiber_g": 1.0,
             "weight_g": 350, "amount": "1 plate"},
            {"name": "Naan", "calories": 260, "protein_g": 8.0,
             "carbs_g": 45.0, "fat_g": 5.0, "fiber_g": 1.5,
             "weight_g": 90, "amount": "1 piece"},
        ]

        # Mock batch_lookup_foods to return nutrition for both
        mock_food_db_for_gemini.batch_lookup_foods.return_value = {
            "Chicken Biryani": {
                "calories_per_100g": 150.0, "protein_per_100g": 8.5,
                "carbs_per_100g": 18.0, "fat_per_100g": 5.2, "fiber_per_100g": 0.8,
            },
            "Naan": {
                "calories_per_100g": 290.0, "protein_per_100g": 9.0,
                "carbs_per_100g": 50.0, "fat_per_100g": 5.5, "fiber_per_100g": 2.0,
            },
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        assert len(result) == 2

        # Chicken Biryani: 350g * 150/100 = 525 cal
        biryani = result[0]
        assert biryani["calories"] == round(150.0 * 350 / 100)  # 525
        assert biryani["protein_g"] == round(8.5 * 350 / 100, 1)  # 29.8
        assert biryani["usda_data"] is not None
        assert biryani["ai_per_gram"] is None

        # Naan: 90g * 290/100 = 261 cal
        naan = result[1]
        assert naan["calories"] == round(290.0 * 90 / 100)  # 261
        assert naan["protein_g"] == round(9.0 * 90 / 100, 1)  # 8.1
        assert naan["usda_data"] is not None

    @pytest.mark.asyncio
    async def test_enhance_food_no_db_match_uses_ai_estimate(self, gemini_service, mock_food_db_for_gemini):
        """DB returns None for a food -> AI estimate kept, ai_per_gram calculated."""
        food_items = [
            {"name": "Exotic Superfood Bowl", "calories": 400, "protein_g": 12.0,
             "carbs_g": 55.0, "fat_g": 15.0, "fiber_g": 6.0,
             "weight_g": 300, "amount": "1 bowl"},
        ]

        mock_food_db_for_gemini.batch_lookup_foods.return_value = {
            "Exotic Superfood Bowl": None,
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        assert len(result) == 1
        item = result[0]
        assert item["usda_data"] is None
        assert item["ai_per_gram"] is not None
        # ai_per_gram.calories = 400 / 300 = 1.333
        assert item["ai_per_gram"]["calories"] == round(400 / 300, 3)

    @pytest.mark.asyncio
    async def test_enhance_food_zero_calories_trusts_db(self, gemini_service, mock_food_db_for_gemini):
        """DB returns 0 calories with 0 macros (legit zero-cal food) -> trusts DB data."""
        food_items = [
            {"name": "Water", "calories": 0, "protein_g": 0.0,
             "carbs_g": 0.0, "fat_g": 0.0, "fiber_g": 0.0,
             "weight_g": 250, "amount": "1 glass"},
        ]

        mock_food_db_for_gemini.batch_lookup_foods.return_value = {
            "Water": {
                "calories_per_100g": 0.0, "protein_per_100g": 0.0,
                "carbs_per_100g": 0.0, "fat_per_100g": 0.0, "fiber_per_100g": 0.0,
            },
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        assert len(result) == 1
        item = result[0]
        # Zero calories + zero macros from DB -> legitimate zero-cal food, trust DB
        assert item["usda_data"] is not None
        assert item["calories"] == 0
        assert item["protein_g"] == 0.0
        assert item["carbs_g"] == 0.0
        assert item["fat_g"] == 0.0

    @pytest.mark.asyncio
    async def test_enhance_food_zero_calories_high_macros_uses_ai(self, gemini_service, mock_food_db_for_gemini):
        """DB returns 0 calories but has high macros (incomplete data) -> falls back to AI."""
        food_items = [
            {"name": "Mystery Food", "calories": 200, "protein_g": 10.0,
             "carbs_g": 25.0, "fat_g": 5.0, "fiber_g": 2.0,
             "weight_g": 150, "amount": "1 serving"},
        ]

        mock_food_db_for_gemini.batch_lookup_foods.return_value = {
            "Mystery Food": {
                "calories_per_100g": 0.0, "protein_per_100g": 15.0,
                "carbs_per_100g": 30.0, "fat_per_100g": 8.0, "fiber_per_100g": 3.0,
            },
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        assert len(result) == 1
        item = result[0]
        # Zero calories but high macros -> incomplete DB data, fall back to AI
        assert item["usda_data"] is None
        assert item["ai_per_gram"] is not None

    @pytest.mark.asyncio
    async def test_enhance_with_use_usda_flag(self, gemini_service):
        """use_usda=True -> calls _lookup_single_usda via asyncio.gather."""
        food_items = [
            {"name": "Rice", "calories": 200, "protein_g": 4.0,
             "carbs_g": 45.0, "fat_g": 0.5, "fiber_g": 0.6,
             "weight_g": 150, "amount": "1 cup"},
        ]

        with patch.object(gemini_service, "_lookup_single_usda", new_callable=AsyncMock) as mock_usda:
            mock_usda.return_value = {
                "calories_per_100g": 130.0, "protein_per_100g": 2.7,
                "carbs_per_100g": 28.0, "fat_per_100g": 0.3, "fiber_per_100g": 0.4,
            }

            with patch("services.usda_food_service.get_usda_food_service") as mock_get_usda:
                mock_usda_service = MagicMock()
                mock_get_usda.return_value = mock_usda_service

                result = await gemini_service._enhance_food_items_with_nutrition_db(
                    food_items, use_usda=True
                )

            assert len(result) == 1
            assert mock_usda.called
            # Rice: 150g * 130/100 = 195 cal
            assert result[0]["calories"] == round(130.0 * 150 / 100)

    @pytest.mark.asyncio
    async def test_enhance_food_db_exception_graceful(self, gemini_service, mock_food_db_for_gemini):
        """DB throws exception -> all items get AI fallback, no crash."""
        food_items = [
            {"name": "Pasta", "calories": 350, "protein_g": 12.0,
             "carbs_g": 60.0, "fat_g": 5.0, "fiber_g": 2.5,
             "weight_g": 250, "amount": "1 plate"},
        ]

        mock_food_db_for_gemini.batch_lookup_foods.side_effect = Exception("DB connection timeout")

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        assert len(result) == 1
        item = result[0]
        # Should have AI fallback, not crash
        assert item["usda_data"] is None


# ================================================================
# CLASS 4: TestTextFlowEndToEnd
# ================================================================

class TestTextFlowEndToEnd:
    """Full text logging flow tests: text -> Gemini parse -> DB lookup -> enhanced result."""

    @pytest.fixture
    def gemini_service(self):
        from services.gemini_service import GeminiService
        return GeminiService()

    @pytest.mark.asyncio
    async def test_text_flow_chicken_biryani_and_naan(self, gemini_service):
        """
        Full flow: 'I ate chicken biryani and naan'
        -> parse_food_description returns 2 items
        -> batch_lookup_foods returns nutrition for both
        -> totals recalculated from DB data.
        """
        parsed_response = {
            "food_items": [
                {"name": "Chicken Biryani", "amount": "1 plate", "calories": 300,
                 "protein_g": 15.0, "carbs_g": 40.0, "fat_g": 10.0, "fiber_g": 1.0,
                 "weight_g": 350, "goal_score": 6, "goal_alignment": "good",
                 "reason": "Rice dish with protein"},
                {"name": "Naan", "amount": "1 piece", "calories": 260,
                 "protein_g": 8.0, "carbs_g": 45.0, "fat_g": 5.0, "fiber_g": 1.5,
                 "weight_g": 90, "goal_score": 5, "goal_alignment": "moderate",
                 "reason": "Refined flour bread"},
            ],
            "total_calories": 560,
            "protein_g": 23.0,
            "carbs_g": 85.0,
            "fat_g": 15.0,
            "fiber_g": 2.5,
            "ai_suggestion": "Consider adding a side salad for extra fiber.",
        }

        batch_db_results = {
            "Chicken Biryani": {
                "calories_per_100g": 150.0, "protein_per_100g": 8.5,
                "carbs_per_100g": 18.0, "fat_per_100g": 5.2, "fiber_per_100g": 0.8,
            },
            "Naan": {
                "calories_per_100g": 290.0, "protein_per_100g": 9.0,
                "carbs_per_100g": 50.0, "fat_per_100g": 5.5, "fiber_per_100g": 2.0,
            },
        }

        with patch.object(gemini_service, "parse_food_description", new_callable=AsyncMock) as mock_parse:
            mock_parse.return_value = parsed_response

            with patch("services.food_database_lookup_service.get_food_db_lookup_service") as mock_get_db:
                mock_db_service = AsyncMock()
                mock_db_service.batch_lookup_foods.return_value = batch_db_results
                mock_get_db.return_value = mock_db_service

                # Simulate what the endpoint does: parse then enhance
                result = await gemini_service.parse_food_description(
                    description="I ate chicken biryani and naan"
                )

                assert result is not None
                assert len(result["food_items"]) == 2

                # Now enhance (as the real flow does after parsing)
                enhanced = await gemini_service._enhance_food_items_with_nutrition_db(
                    result["food_items"]
                )

                assert len(enhanced) == 2

                # Verify batch_lookup_foods was called with the right names
                mock_db_service.batch_lookup_foods.assert_called_once_with(
                    ["Chicken Biryani", "Naan"]
                )

                # Verify recalculated calories
                biryani_cal = round(150.0 * 350 / 100)  # 525
                naan_cal = round(290.0 * 90 / 100)       # 261
                total_cal = sum(item["calories"] for item in enhanced)

                assert enhanced[0]["calories"] == biryani_cal
                assert enhanced[1]["calories"] == naan_cal
                assert total_cal == biryani_cal + naan_cal

    @pytest.mark.asyncio
    async def test_text_flow_single_food(self, gemini_service):
        """'an apple' -> 1 food -> DB lookup -> correct result."""
        parsed_response = {
            "food_items": [
                {"name": "Apple", "amount": "1 medium", "calories": 95,
                 "protein_g": 0.5, "carbs_g": 25.0, "fat_g": 0.3, "fiber_g": 4.4,
                 "weight_g": 182, "goal_score": 7, "goal_alignment": "good",
                 "reason": "Healthy snack with fiber"},
            ],
            "total_calories": 95,
            "protein_g": 0.5,
            "carbs_g": 25.0,
            "fat_g": 0.3,
            "fiber_g": 4.4,
        }

        with patch.object(gemini_service, "parse_food_description", new_callable=AsyncMock) as mock_parse:
            mock_parse.return_value = parsed_response

            with patch("services.food_database_lookup_service.get_food_db_lookup_service") as mock_get_db:
                mock_db_service = AsyncMock()
                mock_db_service.batch_lookup_foods.return_value = {
                    "Apple": {
                        "calories_per_100g": 52.0, "protein_per_100g": 0.3,
                        "carbs_per_100g": 13.8, "fat_per_100g": 0.2, "fiber_per_100g": 2.4,
                    },
                }
                mock_get_db.return_value = mock_db_service

                result = await gemini_service.parse_food_description(
                    description="an apple"
                )
                assert result is not None

                enhanced = await gemini_service._enhance_food_items_with_nutrition_db(
                    result["food_items"]
                )

                assert len(enhanced) == 1
                # Apple: 182g * 52/100 = 94.64 -> 95 rounded
                assert enhanced[0]["calories"] == round(52.0 * 182 / 100)
                assert enhanced[0]["usda_data"] is not None

    @pytest.mark.asyncio
    async def test_text_flow_db_failure_still_succeeds(self, gemini_service):
        """DB throws -> AI estimates used -> still produces valid results."""
        food_items = [
            {"name": "Sandwich", "amount": "1 whole", "calories": 450,
             "protein_g": 20.0, "carbs_g": 50.0, "fat_g": 18.0, "fiber_g": 3.0,
             "weight_g": 250},
        ]

        with patch("services.food_database_lookup_service.get_food_db_lookup_service") as mock_get_db:
            mock_db_service = AsyncMock()
            mock_db_service.batch_lookup_foods.side_effect = Exception("Connection refused")
            mock_get_db.return_value = mock_db_service

            # Should not raise
            enhanced = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

            assert len(enhanced) == 1
            item = enhanced[0]
            # AI fallback used
            assert item["usda_data"] is None
            # Original calories preserved (no DB data to override)
            # The ai_per_gram won't be set because the exception path
            # sets nutrition_results = [None] * len, so it goes to the
            # "no match" branch which calculates ai_per_gram


# ================================================================
# CLASS 5: TestBatchLookupVariantNames
# ================================================================

SALMON_OVERRIDE_ROW = {
    "display_name": "Salmon (Cooked)",
    "food_name_normalized": "salmon_cooked",
    "calories_per_100g": 208.0,
    "protein_per_100g": 20.4,
    "carbs_per_100g": 0.0,
    "fat_per_100g": 13.4,
    "fiber_per_100g": 0.0,
    "default_weight_per_piece_g": None,
    "default_serving_g": 150.0,
    "source": "usda",
    "restaurant_name": None,
    "food_category": "protein",
    "default_count": 1,
    "variant_names": ["salmon", "cooked salmon", "baked salmon", "grilled salmon", "atlantic salmon", "salmon fillet"],
    "region": None,
    "is_active": True,
}


class TestBatchLookupVariantNames:
    """Tests that batch_lookup_foods checks variant_names when exact match fails."""

    @pytest.fixture
    def mock_food_db_service(self):
        """Create a FoodDatabaseLookupService with mocked Supabase."""
        with patch("services.food_database_lookup_service.get_supabase") as mock_get_sb:
            mock_sb = MagicMock()
            mock_get_sb.return_value = mock_sb

            from services.food_database_lookup_service import FoodDatabaseLookupService
            service = FoodDatabaseLookupService()
            service._cache.clear()
            service._overrides.clear()
            service._overrides_loaded_at = 1  # Mark as loaded
            yield service, mock_sb

    @pytest.mark.asyncio
    async def test_batch_finds_grilled_salmon_via_variant(self, mock_food_db_service):
        """'Grilled Salmon' has no exact override but variant_names contains 'grilled salmon'.
        batch_lookup should find it via .contains() query."""
        service, mock_sb = mock_food_db_service

        # Exact match returns nothing
        mock_exact = MagicMock()
        mock_exact.data = []

        # Variant match returns salmon override
        mock_variant = MagicMock()
        mock_variant.data = [SALMON_OVERRIDE_ROW]

        # Chain: .table().select().eq().eq().limit().execute() for exact
        # Then: .table().select().eq().contains().limit().execute() for variant
        call_count = [0]
        original_table = mock_sb.client.table

        def mock_table_factory(table_name):
            mock_table = MagicMock()
            mock_select = MagicMock()
            mock_table.select.return_value = mock_select

            mock_eq1 = MagicMock()
            mock_select.eq.return_value = mock_eq1

            # First .eq() call → second .eq() for exact match
            mock_eq2 = MagicMock()
            mock_eq2.limit.return_value.execute.return_value = mock_exact
            mock_eq1.eq.return_value = mock_eq2

            # .contains() for variant match
            mock_contains = MagicMock()
            mock_contains.limit.return_value.execute.return_value = mock_variant
            mock_eq1.contains.return_value = mock_contains

            return mock_table

        mock_sb.client.table = mock_table_factory

        result = await service.batch_lookup_foods(["Grilled Salmon"])

        assert "Grilled Salmon" in result
        assert result["Grilled Salmon"] is not None
        assert result["Grilled Salmon"]["calories_per_100g"] == 208.0
        assert result["Grilled Salmon"]["protein_per_100g"] == 20.4

    @pytest.mark.asyncio
    async def test_batch_exact_match_skips_variant(self, mock_food_db_service):
        """'salmon_cooked' has exact food_name_normalized match — variant check should be skipped."""
        service, mock_sb = mock_food_db_service

        # Exact match returns salmon override
        mock_exact = MagicMock()
        mock_exact.data = [SALMON_OVERRIDE_ROW]

        mock_sb.client.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = mock_exact

        result = await service.batch_lookup_foods(["salmon_cooked"])

        assert "salmon_cooked" in result
        assert result["salmon_cooked"] is not None
        assert result["salmon_cooked"]["calories_per_100g"] == 208.0

    @pytest.mark.asyncio
    async def test_batch_no_match_returns_none(self, mock_food_db_service):
        """Food with no override AND no variant match returns None."""
        service, mock_sb = mock_food_db_service

        mock_empty = MagicMock()
        mock_empty.data = []

        def mock_table_factory(table_name):
            mock_table = MagicMock()
            mock_select = MagicMock()
            mock_table.select.return_value = mock_select
            mock_eq1 = MagicMock()
            mock_select.eq.return_value = mock_eq1
            mock_eq1.eq.return_value.limit.return_value.execute.return_value = mock_empty
            mock_eq1.contains.return_value.limit.return_value.execute.return_value = mock_empty
            return mock_table

        mock_sb.client.table = mock_table_factory

        result = await service.batch_lookup_foods(["Mystery Alien Food XYZ"])

        assert "Mystery Alien Food XYZ" in result
        assert result["Mystery Alien Food XYZ"] is None

    @pytest.mark.asyncio
    async def test_batch_variant_match_cached_for_future(self, mock_food_db_service):
        """After a variant match, same name on second call should use cache (no DB query)."""
        service, mock_sb = mock_food_db_service

        mock_empty = MagicMock()
        mock_empty.data = []
        mock_variant = MagicMock()
        mock_variant.data = [SALMON_OVERRIDE_ROW]

        def mock_table_factory(table_name):
            mock_table = MagicMock()
            mock_select = MagicMock()
            mock_table.select.return_value = mock_select
            mock_eq1 = MagicMock()
            mock_select.eq.return_value = mock_eq1
            mock_eq1.eq.return_value.limit.return_value.execute.return_value = mock_empty
            mock_eq1.contains.return_value.limit.return_value.execute.return_value = mock_variant
            return mock_table

        mock_sb.client.table = mock_table_factory

        # First call — goes to DB
        result1 = await service.batch_lookup_foods(["Grilled Salmon"])
        assert result1["Grilled Salmon"] is not None
        assert result1["Grilled Salmon"]["calories_per_100g"] == 208.0

        # Second call — should use cache
        result2 = await service.batch_lookup_foods(["Grilled Salmon"])
        assert result2["Grilled Salmon"] is not None
        assert result2["Grilled Salmon"]["calories_per_100g"] == 208.0


# ================================================================
# CLASS 6: TestCalorieSanityFilter
# ================================================================

class TestCalorieSanityFilter:
    """Tests that the API search endpoint rejects entries with bad calorie data."""

    def test_bad_data_detection_logic(self):
        """Entries with <5 cal/100g but non-trivial macros are bad data."""
        # Simulate the sanity check logic from nutrition.py
        bad_items = [
            {"name": "Salmon Grilled", "calories_per_100g": 2, "protein_per_100g": 20, "fat_per_100g": 10, "carbs_per_100g": 0, "source": "local_db"},
            {"name": "Broccoli", "calories_per_100g": 0, "protein_per_100g": 3, "fat_per_100g": 0.5, "carbs_per_100g": 7, "source": "local_db"},
        ]
        good_items = [
            {"name": "Water", "calories_per_100g": 0, "protein_per_100g": 0, "fat_per_100g": 0, "carbs_per_100g": 0, "source": "local_db"},
            {"name": "Good Salmon", "calories_per_100g": 208, "protein_per_100g": 20, "fat_per_100g": 13, "carbs_per_100g": 0, "source": "local_db"},
            {"name": "Saved Meal", "calories_per_100g": 3, "protein_per_100g": 15, "fat_per_100g": 5, "carbs_per_100g": 20, "source": "saved"},
        ]

        def is_bad_data(item):
            cal = float(item.get("calories_per_100g") or 0)
            prot = float(item.get("protein_per_100g") or 0)
            fat = float(item.get("fat_per_100g") or 0)
            carbs = float(item.get("carbs_per_100g") or 0)
            source = item.get("source", "")
            if source in ("saved", "saved_item"):
                return False  # Don't filter saved foods
            return cal < 5 and (prot > 1 or fat > 1 or carbs > 1)

        for item in bad_items:
            assert is_bad_data(item), f"Should be flagged as bad: {item['name']}"

        for item in good_items:
            assert not is_bad_data(item), f"Should NOT be flagged: {item['name']}"


# ================================================================
# CLASS 7: TestEnhanceWithVariantOverrides
# ================================================================

class TestEnhanceWithVariantOverrides:
    """Tests that _enhance_food_items_with_nutrition_db correctly overrides
    Gemini's bad estimates when override data is found via variant matching."""

    @pytest.fixture
    def gemini_service(self):
        from services.gemini_service import GeminiService
        return GeminiService()

    @pytest.fixture
    def mock_food_db_for_gemini(self):
        with patch("services.food_database_lookup_service.get_food_db_lookup_service") as mock_get:
            mock_service = AsyncMock()
            mock_get.return_value = mock_service
            yield mock_service

    @pytest.mark.asyncio
    async def test_enhance_grilled_salmon_overrides_bad_gemini_estimate(self, gemini_service, mock_food_db_for_gemini):
        """Gemini says salmon = 4 kcal (wrong), but override has 208 cal/100g.
        Enhancement should replace Gemini's bad estimate with correct value."""
        food_items = [
            {"name": "Grilled Salmon", "calories": 4, "protein_g": 0.5,
             "carbs_g": 0, "fat_g": 0.3, "fiber_g": 0,
             "weight_g": 150, "amount": "150g"},
        ]

        mock_food_db_for_gemini.batch_lookup_foods.return_value = {
            "Grilled Salmon": {
                "calories_per_100g": 208.0, "protein_per_100g": 20.4,
                "carbs_per_100g": 0.0, "fat_per_100g": 13.4, "fiber_per_100g": 0.0,
            },
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        assert len(result) == 1
        salmon = result[0]
        # 208 * 150/100 = 312, NOT Gemini's 4
        assert salmon["calories"] == 312
        assert salmon["usda_data"] is not None
        assert salmon["ai_per_gram"] is None

    @pytest.mark.asyncio
    async def test_enhance_full_meal_all_items_enhanced(self, gemini_service, mock_food_db_for_gemini):
        """Full meal: all items should get correct calories from overrides."""
        food_items = [
            {"name": "Grilled Salmon", "calories": 4, "protein_g": 0.5,
             "carbs_g": 0, "fat_g": 0.3, "fiber_g": 0,
             "weight_g": 150, "amount": "150g"},
            {"name": "Quinoa", "calories": 572, "protein_g": 20,
             "carbs_g": 100, "fat_g": 10, "fiber_g": 5,
             "weight_g": 185, "amount": "185g"},
            {"name": "Roasted Broccoli", "calories": 52, "protein_g": 5,
             "carbs_g": 10, "fat_g": 1, "fiber_g": 4,
             "weight_g": 150, "amount": "150g"},
        ]

        mock_food_db_for_gemini.batch_lookup_foods.return_value = {
            "Grilled Salmon": {
                "calories_per_100g": 208.0, "protein_per_100g": 20.4,
                "carbs_per_100g": 0.0, "fat_per_100g": 13.4, "fiber_per_100g": 0.0,
            },
            "Quinoa": {
                "calories_per_100g": 120.0, "protein_per_100g": 4.4,
                "carbs_per_100g": 21.3, "fat_per_100g": 1.9, "fiber_per_100g": 2.8,
            },
            "Roasted Broccoli": {
                "calories_per_100g": 35.0, "protein_per_100g": 2.4,
                "carbs_per_100g": 7.2, "fat_per_100g": 0.4, "fiber_per_100g": 3.3,
            },
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        assert len(result) == 3

        salmon = result[0]
        assert salmon["calories"] == round(208.0 * 150 / 100)  # 312
        assert salmon["usda_data"] is not None

        quinoa = result[1]
        assert quinoa["calories"] == round(120.0 * 185 / 100)  # 222
        assert quinoa["usda_data"] is not None

        broccoli = result[2]
        assert broccoli["calories"] == round(35.0 * 150 / 100)  # 52 (was already correct)
        assert broccoli["usda_data"] is not None

        # Total should be reasonable (not 4 + 572 + 52 = 628 from Gemini)
        total = sum(item["calories"] for item in result)
        assert total > 500  # 312 + 222 + 52 = 586
