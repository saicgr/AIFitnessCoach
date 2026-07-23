"""
Regression tests — a food with real calories must never round-trip to
protein=0 AND carbs=0 AND fat=0.

Production incident (2026-07): a chocolate layer cake + strawberry coulis
logged as calories=385, protein=0, carbs=0, fat=0. 3 of that user's 5 logs and
7 of 207 logs across all users showed calories > 0 with all-zero macros.

Root cause chain:
  1. Gemini returns per-item macros.
  2. `GeminiService._enhance_food_items_with_nutrition_db`
     (services/gemini/parsers.py) looks the item up in `food_nutrition_overrides`.
  3. The lookup service coerces NULL macro columns to 0.0
     (services/food_database_lookup_service_helpers.py:549), so a row imported
     calories-only comes back as {calories_per_100g: 350, protein: 0, carbs: 0,
     fat: 0}.
  4. The DB branch then OVERWROTE the AI's real macros with those zeros while
     keeping the (non-zero) calories.
  5. Callers re-sum the item macros into the meal totals, and /log-direct
     faithfully persists 385 kcal / 0P / 0C / 0F.

These tests fail against the pre-fix code.
"""

import sys
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from services.gemini.parsers import (  # noqa: E402
    ai_item_macros_unknown,
    build_ai_per_gram,
    db_row_macros_unusable,
    derive_meal_totals,
    enforce_macro_integrity,
)


# ---------------------------------------------------------------------------
# derive_meal_totals — meal totals are the SUM of the items, never a separate
# number the model returned. (2026-07: 714 kcal plate persisted 0P/0C/0F while
# every item carried macros.)
# ---------------------------------------------------------------------------

class TestDeriveMealTotals:
    def test_totals_recomputed_from_items_when_model_returned_zero(self):
        payload = {
            "food_items": [
                {"name": "salmon", "calories": 391, "protein_g": 37.4, "carbs_g": 0, "fat_g": 26.3},
                {"name": "polenta", "calories": 130, "protein_g": 3, "carbs_g": 26, "fat_g": 1},
            ],
            # The model left the meal-level macros at 0 (the bug's signature).
            "total_calories": 0,
            "protein_g": 0, "carbs_g": 0, "fat_g": 0,
        }
        derive_meal_totals(payload, "test")
        assert payload["total_calories"] == 521
        assert payload["protein_g"] == 40.4
        assert payload["carbs_g"] == 26
        assert payload["fat_g"] == 27.3

    def test_unknown_macro_item_leaves_total_for_gate_to_null(self):
        payload = {
            "food_items": [
                {"name": "vodka", "calories": 231, "macros_unknown": True,
                 "protein_g": None, "carbs_g": None, "fat_g": None},
                {"name": "lime", "calories": 5, "protein_g": 0, "carbs_g": 1, "fat_g": 0},
            ],
            "total_protein_g": 99, "total_carbs_g": 99, "total_fat_g": 99,
            "total_calories": 0,
        }
        derive_meal_totals(payload, "test")
        # Calories always known → summed. Protein unknown (an item is unknown)
        # → left untouched so enforce_macro_integrity nulls + labels it.
        assert payload["total_calories"] == 236
        enforce_macro_integrity(payload, "test")
        assert payload["total_protein_g"] is None
        assert payload.get("macros_unknown") is True

    def test_menu_payload_totals_family(self):
        # A menu-scan-shaped payload using the total_* family.
        payload = {
            "food_items": [
                {"name": "cake", "calories": 680, "protein_g": 8, "carbs_g": 78, "fat_g": 38},
            ],
            "total_calories": 0, "total_protein": 0, "total_carbs": 0, "total_fat": 0,
        }
        derive_meal_totals(payload, "menu")
        assert payload["total_calories"] == 680
        assert payload["total_protein"] == 8
        assert payload["total_carbs"] == 78
        assert payload["total_fat"] == 38

    def test_idempotent(self):
        payload = {
            "food_items": [{"name": "x", "calories": 100, "protein_g": 5, "carbs_g": 10, "fat_g": 2}],
            "protein_g": 0, "carbs_g": 0, "fat_g": 0, "total_calories": 0,
        }
        derive_meal_totals(payload, "a")
        first = dict(payload)
        derive_meal_totals(payload, "b")
        assert payload["protein_g"] == first["protein_g"]
        assert payload["total_calories"] == first["total_calories"]


# ---------------------------------------------------------------------------
# Unit-level guards
# ---------------------------------------------------------------------------

class TestMacroIntegrityHelpers:
    def test_calories_only_db_row_is_unusable(self):
        """The Phase-1 backfill gap: calories present, every macro NULL→0.0."""
        assert db_row_macros_unusable({
            "calories_per_100g": 350.0,
            "protein_per_100g": 0.0,
            "carbs_per_100g": 0.0,
            "fat_per_100g": 0.0,
        }) is True

    def test_db_row_with_one_populated_macro_is_usable(self):
        """A single zero macro is legitimate (butter ≈ 0g protein / 0g carbs)."""
        assert db_row_macros_unusable({
            "calories_per_100g": 717.0,
            "protein_per_100g": 0.0,
            "carbs_per_100g": 0.0,
            "fat_per_100g": 81.0,
        }) is False

    def test_zero_calorie_db_row_is_not_flagged(self):
        """Water / black coffee: 0 cal + 0 macros is real data, not a gap."""
        assert db_row_macros_unusable({
            "calories_per_100g": 0.0,
            "protein_per_100g": 0.0,
            "carbs_per_100g": 0.0,
            "fat_per_100g": 0.0,
        }) is False

    def test_none_row_is_not_flagged(self):
        assert db_row_macros_unusable(None) is False

    def test_ai_item_with_calories_and_no_macros_is_unknown(self):
        assert ai_item_macros_unknown(
            {"name": "Chocolate Layer Cake", "calories": 385}
        ) is True

    def test_ai_item_with_explicit_zero_macros_and_calories_is_unknown(self):
        """4*0 + 4*0 + 9*0 != 385 kcal — this is missing data, not a real 0."""
        assert ai_item_macros_unknown({
            "name": "Chocolate Layer Cake", "calories": 385,
            "protein_g": 0, "carbs_g": 0, "fat_g": 0,
        }) is True

    def test_zero_calorie_item_is_not_unknown(self):
        assert ai_item_macros_unknown({
            "name": "Water", "calories": 0,
            "protein_g": 0, "carbs_g": 0, "fat_g": 0,
        }) is False

    def test_item_with_one_real_macro_is_not_unknown(self):
        assert ai_item_macros_unknown({
            "name": "Olive Oil", "calories": 119,
            "protein_g": 0, "carbs_g": 0, "fat_g": 13.5,
        }) is False

    def test_build_ai_per_gram_omits_macros_the_ai_never_returned(self):
        """A macro the model never returned must not become a confident 0.0
        per-gram factor the client multiplies into the daily totals."""
        per_gram = build_ai_per_gram({"calories": 385}, 250.0)
        assert per_gram is not None
        assert per_gram["calories"] == round(385 / 250, 3)
        assert "protein" not in per_gram
        assert "carbs" not in per_gram
        assert "fat" not in per_gram

    def test_build_ai_per_gram_keeps_real_macros(self):
        per_gram = build_ai_per_gram(
            {"calories": 400, "protein_g": 12.0, "carbs_g": 55.0, "fat_g": 15.0},
            300.0,
        )
        assert per_gram["protein"] == round(12.0 / 300, 4)
        assert per_gram["carbs"] == round(55.0 / 300, 4)
        assert per_gram["fat"] == round(15.0 / 300, 4)


# ---------------------------------------------------------------------------
# End-to-end through the enhancement pipeline
# ---------------------------------------------------------------------------

@pytest.fixture
def gemini_service():
    from services.gemini_service import GeminiService
    return GeminiService()


@pytest.fixture
def mock_food_db():
    with patch("services.food_database_lookup_service.get_food_db_lookup_service") as mock_get:
        mock_service = AsyncMock()
        mock_get.return_value = mock_service
        yield mock_service


class TestNoZeroMacroRoundTrip:
    @pytest.mark.asyncio
    async def test_calories_only_db_hit_does_not_zero_the_ai_macros(
        self, gemini_service, mock_food_db
    ):
        """THE regression. DB row has calories but no macros; the AI does have
        macros. Pre-fix, the DB branch overwrote protein/carbs/fat with 0 and
        kept the calories → 'calories>0, macros 0/0/0' in the food log.
        """
        food_items = [{
            "name": "Chocolate Layer Cake",
            "calories": 875, "protein_g": 8.0, "carbs_g": 110.0, "fat_g": 45.0,
            "fiber_g": 3.0, "weight_g": 250, "amount": "1 slice",
        }]
        mock_food_db.batch_lookup_foods.return_value = {
            "Chocolate Layer Cake": {
                "display_name": "Chocolate Layer Cake",
                "calories_per_100g": 350.0,
                # NULL in the DB → coerced to 0.0 by the lookup service.
                "protein_per_100g": 0.0,
                "carbs_per_100g": 0.0,
                "fat_per_100g": 0.0,
                "fiber_per_100g": 0.0,
            },
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        assert len(result) == 1
        item = result[0]
        # The core invariant: calories > 0 must never coexist with 0/0/0 macros.
        assert item["calories"] > 0
        assert not (
            (item.get("protein_g") or 0) == 0
            and (item.get("carbs_g") or 0) == 0
            and (item.get("fat_g") or 0) == 0
        ), f"calories={item['calories']} persisted with all-zero macros: {item}"
        # The partial row is treated as a miss → the AI's own macros survive.
        assert item["usda_data"] is None
        assert item["protein_g"] == 8.0
        assert item["carbs_g"] == 110.0
        assert item["fat_g"] == 45.0
        assert item.get("requires_user_confirmation") is True

    @pytest.mark.asyncio
    async def test_meal_totals_are_not_all_zero_after_partial_db_hits(
        self, gemini_service, mock_food_db
    ):
        """The production log verbatim: 2 items, calories>0, totals 0/0/0."""
        food_items = [
            {"name": "Chocolate Layer Cake", "calories": 875, "protein_g": 8.0,
             "carbs_g": 110.0, "fat_g": 45.0, "fiber_g": 3.0, "weight_g": 250},
            {"name": "Strawberry Coulis", "calories": 10, "protein_g": 0.1,
             "carbs_g": 2.5, "fat_g": 0.0, "fiber_g": 0.2, "weight_g": 30},
        ]
        calories_only_row = {
            "calories_per_100g": 350.0, "protein_per_100g": 0.0,
            "carbs_per_100g": 0.0, "fat_per_100g": 0.0, "fiber_per_100g": 0.0,
        }
        mock_food_db.batch_lookup_foods.return_value = {
            "Chocolate Layer Cake": dict(calories_only_row),
            "Strawberry Coulis": dict(calories_only_row, calories_per_100g=33.0),
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        total_calories = sum(i.get("calories", 0) or 0 for i in result)
        total_protein = sum(i.get("protein_g", 0) or 0 for i in result)
        total_carbs = sum(i.get("carbs_g", 0) or 0 for i in result)
        total_fat = sum(i.get("fat_g", 0) or 0 for i in result)

        assert total_calories > 0
        assert not (total_protein == 0 and total_carbs == 0 and total_fat == 0), (
            f"meal totals: {total_calories} kcal / {total_protein}P "
            f"/ {total_carbs}C / {total_fat}F"
        )

    @pytest.mark.asyncio
    async def test_db_miss_with_no_ai_macros_is_flagged_not_zeroed(
        self, gemini_service, mock_food_db
    ):
        """No DB match AND the model returned no macros → genuinely unknown.
        We must NOT invent a split and must NOT present 0 as confident data.
        """
        food_items = [{
            "name": "Grandma's Mystery Casserole",
            "calories": 385, "weight_g": 250, "amount": "1 serving",
        }]
        mock_food_db.batch_lookup_foods.return_value = {
            "Grandma's Mystery Casserole": None,
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        item = result[0]
        assert item.get("macros_unknown") is True
        assert item.get("requires_user_confirmation") is True
        assert item.get("confidence") == "low"
        # No fabricated macro split anywhere.
        assert item.get("protein_g") is None
        assert "protein" not in (item.get("ai_per_gram") or {})
        assert "carbs" not in (item.get("ai_per_gram") or {})
        assert "fat" not in (item.get("ai_per_gram") or {})

    @pytest.mark.asyncio
    async def test_zero_calorie_food_is_not_flagged_unknown(
        self, gemini_service, mock_food_db
    ):
        """Water really is 0 cal / 0 macros — no confirmation prompt."""
        food_items = [{
            "name": "Water", "calories": 0, "protein_g": 0.0, "carbs_g": 0.0,
            "fat_g": 0.0, "fiber_g": 0.0, "weight_g": 250, "amount": "1 glass",
        }]
        mock_food_db.batch_lookup_foods.return_value = {
            "Water": {
                "calories_per_100g": 0.0, "protein_per_100g": 0.0,
                "carbs_per_100g": 0.0, "fat_per_100g": 0.0, "fiber_per_100g": 0.0,
            },
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        item = result[0]
        assert item["calories"] == 0
        assert item.get("macros_unknown") is not True

    @pytest.mark.asyncio
    async def test_complete_db_row_still_wins_over_ai_estimate(
        self, gemini_service, mock_food_db
    ):
        """Guard against over-correcting: a row with real macros is still the
        source of truth (single-zero macros stay legitimate)."""
        food_items = [{
            "name": "Butter", "calories": 100, "protein_g": 1.0, "carbs_g": 1.0,
            "fat_g": 11.0, "fiber_g": 0.0, "weight_g": 14, "amount": "1 tbsp",
        }]
        mock_food_db.batch_lookup_foods.return_value = {
            "Butter": {
                "calories_per_100g": 717.0, "protein_per_100g": 0.0,
                "carbs_per_100g": 0.0, "fat_per_100g": 81.0,
                "fiber_per_100g": 0.0,
            },
        }

        result = await gemini_service._enhance_food_items_with_nutrition_db(food_items)

        item = result[0]
        assert item["usda_data"] is not None
        assert item["calories"] == round(717.0 * 14 / 100)
        assert item["fat_g"] == round(81.0 * 14 / 100, 1)
        assert item.get("macros_unknown") is not True
