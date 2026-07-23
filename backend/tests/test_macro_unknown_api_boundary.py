"""Regression tests for the API/client boundary of the "unknown macros" state.

`services/gemini/parsers.enforce_macro_integrity` is the chokepoint that turns
"this item has calories but no protein/carbs/fat" into an honest explicit
`None` — on the item AND on the meal totals. Those tests live in
`test_food_macro_integrity.py` / `test_food_macro_integrity_e2e.py`.

This module covers the NEXT hop, where that honest `None` used to be destroyed:

  1. `LogFoodResponse` declared `protein_g/carbs_g/fat_g` as non-Optional
     floats. `api/v1/nutrition/food_logging.py` passes the post-integrity
     totals straight into it, so a meal with ONE unknown-macro item raised a
     Pydantic ValidationError during response serialization — an honest
     "we don't know" surfaced to the user as a 500.
  2. `LogDirectRequest` declared `total_protein/total_carbs/total_fat` as
     required ints, so the confirm-then-save path could not even TRANSMIT the
     unknown: the client had to substitute a fabricated 0 (or eat a 422).
  3. `models/saved_food.py:AiPerGramData` declared its per-gram factors as
     `float = 0.0`. `flag_unknown_macros` deliberately POPS the protein/carbs/
     fat factors off an unknown item so the client cannot re-multiply them —
     and the `0.0` default rebuilt them as a confident "0 g per gram".
  4. `FoodItemRanking` declared item macros as `float = 0.0`, same defect one
     level down.

Nothing here uses mock macro numbers: the payloads are produced by running the
real `enforce_macro_integrity` / `flag_unknown_macros` / `build_ai_per_gram`.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from api.v1.nutrition.models import (  # noqa: E402
    FoodItemRanking,
    LogDirectRequest,
    LogFoodResponse,
)
from models.saved_food import AiPerGramData, SavedFoodItem  # noqa: E402
from services.gemini.parsers import (  # noqa: E402
    build_ai_per_gram,
    enforce_macro_integrity,
    flag_unknown_macros,
)


def _meal_with_one_unknown_item() -> dict:
    """A REAL post-integrity payload: two items, one with unknown macros.

    Shape mirrors what `food_logging.py` holds right before it constructs a
    `LogFoodResponse` (`_TOTAL_KEY_FAMILIES` family #1: protein_g/carbs_g/...).
    """
    payload = {
        "food_items": [
            {
                "name": "Grilled chicken breast",
                "calories": 284,
                "protein_g": 53.4,
                "carbs_g": 0.0,
                "fat_g": 6.2,
                "fiber_g": 0.0,
                "weight_g": 174.0,
            },
            {
                # Calories known, macro split genuinely unknown, not alcohol.
                "name": "House curry sauce",
                "calories": 210,
                "weight_g": 120.0,
            },
        ],
        "protein_g": 53.4,
        "carbs_g": 0.0,
        "fat_g": 6.2,
        "fiber_g": 0.0,
        "total_calories": 494,
    }
    enforce_macro_integrity(payload, "test_macro_unknown_api_boundary")
    # Sanity: the chokepoint really did NULL the totals for us.
    assert payload["protein_g"] is None
    assert payload["carbs_g"] is None
    assert payload["fat_g"] is None
    assert payload["macros_unknown"] is True
    return payload


class TestLogFoodResponseTransmitsUnknown:
    """Ceiling #1 — the live 500."""

    def test_response_serializes_null_macros_without_validation_error(self):
        payload = _meal_with_one_unknown_item()

        # This is verbatim what food_logging.py does with the integrity output.
        response = LogFoodResponse(
            success=True,
            food_log_id="fl-123",
            food_items=payload["food_items"],
            total_calories=payload["total_calories"],
            protein_g=payload["protein_g"],
            carbs_g=payload["carbs_g"],
            fat_g=payload["fat_g"],
            fiber_g=payload["fiber_g"],
            macros_unknown=payload["macros_unknown"],
            macros_unknown_items=payload["macros_unknown_items"],
            macros_known_subtotal=payload["macros_known_subtotal"],
        )

        body = response.model_dump()
        # None, NOT 0.0 — the whole point.
        assert body["protein_g"] is None
        assert body["carbs_g"] is None
        assert body["fat_g"] is None
        assert body["protein_g"] != 0.0
        # Calories are still known and must NOT be nulled.
        assert body["total_calories"] == 494

    def test_response_carries_the_reason_for_the_null(self):
        payload = _meal_with_one_unknown_item()
        response = LogFoodResponse(
            success=True,
            food_log_id="fl-123",
            food_items=payload["food_items"],
            total_calories=payload["total_calories"],
            protein_g=payload["protein_g"],
            carbs_g=payload["carbs_g"],
            fat_g=payload["fat_g"],
            macros_unknown=payload["macros_unknown"],
            macros_unknown_items=payload["macros_unknown_items"],
            macros_known_subtotal=payload["macros_known_subtotal"],
        )
        body = response.model_dump()
        assert body["macros_unknown"] is True
        assert body["macros_unknown_items"] == ["House curry sauce"]
        # The partial sum over the items we DO know — labelled as a subtotal,
        # never promoted to the meal total.
        assert body["macros_known_subtotal"]["protein_g"] == 53.4
        assert body["macros_known_subtotal"]["fat_g"] == 6.2

    def test_json_round_trip_keeps_null_null(self):
        payload = _meal_with_one_unknown_item()
        response = LogFoodResponse(
            success=True,
            food_log_id="fl-123",
            food_items=payload["food_items"],
            total_calories=payload["total_calories"],
            protein_g=payload["protein_g"],
            carbs_g=payload["carbs_g"],
            fat_g=payload["fat_g"],
            macros_unknown=True,
        )
        revived = LogFoodResponse.model_validate_json(response.model_dump_json())
        assert revived.protein_g is None
        assert revived.carbs_g is None
        assert revived.fat_g is None
        assert revived.macros_unknown is True

    def test_known_macros_still_serialize_unchanged(self):
        """Back-compat: a fully-known meal is untouched by the nullability."""
        response = LogFoodResponse(
            success=True,
            food_log_id="fl-456",
            food_items=[],
            total_calories=284,
            protein_g=53.4,
            carbs_g=0.0,
            fat_g=6.2,
        )
        body = response.model_dump()
        assert body["protein_g"] == 53.4
        # A REAL zero (chicken breast has ~0 g carbs) stays a zero — the fix
        # must not turn legitimate zeros into nulls.
        assert body["carbs_g"] == 0.0
        assert body["macros_unknown"] is None


class TestLogDirectRequestTransmitsUnknown:
    """Ceiling #2 — the confirm-then-save path."""

    def test_accepts_null_macro_totals(self):
        payload = _meal_with_one_unknown_item()
        # `_TOTAL_KEY_FAMILIES` family #3 is exactly LogDirectRequest's names.
        confirm_body = {
            "user_id": "u-1",
            "meal_type": "dinner",
            "food_items": payload["food_items"],
            "total_calories": payload["total_calories"],
            "total_protein": None,
            "total_carbs": None,
            "total_fat": None,
            "macros_unknown": True,
            "macros_unknown_items": payload["macros_unknown_items"],
            "macros_known_subtotal": payload["macros_known_subtotal"],
        }
        req = LogDirectRequest(**confirm_body)
        assert req.total_protein is None
        assert req.total_carbs is None
        assert req.total_fat is None
        assert req.total_calories == 494
        # The flags survive the boundary instead of being silently dropped.
        assert req.macros_unknown is True
        assert req.macros_unknown_items == ["House curry sauce"]
        assert req.macros_known_subtotal["protein_g"] == 53.4

    def test_omitted_macro_totals_default_to_none_not_zero(self):
        req = LogDirectRequest(
            user_id="u-1",
            meal_type="snack",
            food_items=[],
            total_calories=120,
        )
        assert req.total_protein is None
        assert req.total_carbs is None
        assert req.total_fat is None

    def test_known_totals_still_accepted(self):
        req = LogDirectRequest(
            user_id="u-1",
            meal_type="lunch",
            food_items=[],
            total_calories=494,
            total_protein=53,
            total_carbs=0,
            total_fat=6,
        )
        assert req.total_protein == 53
        # A genuine 0 g carbs stays 0, distinct from None.
        assert req.total_carbs == 0
        assert req.total_carbs is not None


class TestAiPerGramDataNeverFabricatesZero:
    """Ceiling #3 — the per-gram scaling factors."""

    def test_stripped_macro_factors_hydrate_as_none(self):
        item = {
            "name": "House curry sauce",
            "calories": 210,
            "weight_g": 120.0,
            "ai_per_gram": build_ai_per_gram(
                {"calories": 210, "protein_g": 0, "carbs_g": 0, "fat_g": 0}, 120.0
            ),
        }
        flag_unknown_macros(item, "test_macro_unknown_api_boundary")
        # The parser stripped the macro factors; only calories survive.
        assert "protein" not in item["ai_per_gram"]

        per_gram = AiPerGramData(**item["ai_per_gram"])
        assert per_gram.protein is None
        assert per_gram.carbs is None
        assert per_gram.fat is None
        assert per_gram.protein != 0.0
        # Calories ARE known — the factor must survive.
        assert per_gram.calories == pytest.approx(210 / 120.0, rel=1e-3)

    def test_real_factors_are_preserved(self):
        per_gram_dict = build_ai_per_gram(
            {"calories": 284, "protein_g": 53.4, "carbs_g": 0.0, "fat_g": 6.2},
            174.0,
        )
        per_gram = AiPerGramData(**per_gram_dict)
        assert per_gram.protein == pytest.approx(53.4 / 174.0, rel=1e-3)
        assert per_gram.fat == pytest.approx(6.2 / 174.0, rel=1e-3)

    def test_saved_food_item_round_trips_unknown_per_gram(self):
        item = SavedFoodItem(
            name="House curry sauce",
            calories=210,
            ai_per_gram=AiPerGramData(calories=1.75),
        )
        dumped = item.model_dump()
        assert dumped["ai_per_gram"]["protein"] is None
        assert dumped["protein_g"] is None


class TestFoodItemRankingNeverFabricatesZero:
    """Ceiling #4 — the per-item macros in the ranked response."""

    def test_missing_macros_are_none_not_zero(self):
        item = FoodItemRanking(name="House curry sauce", calories=210)
        assert item.protein_g is None
        assert item.carbs_g is None
        assert item.fat_g is None

    def test_flagged_item_survives_validation(self):
        raw = {"name": "House curry sauce", "calories": 210}
        flag_unknown_macros(raw, "test_macro_unknown_api_boundary")
        item = FoodItemRanking(
            name=raw["name"],
            calories=raw["calories"],
            protein_g=raw["protein_g"],
            carbs_g=raw["carbs_g"],
            fat_g=raw["fat_g"],
            macros_unknown=raw["macros_unknown"],
        )
        assert item.protein_g is None
        assert item.macros_unknown is True

    def test_real_zero_macro_is_kept(self):
        # Chicken breast really is ~0 g carbs — not the same as unknown.
        item = FoodItemRanking(
            name="Grilled chicken breast", calories=284, protein_g=53.4,
            carbs_g=0.0, fat_g=6.2,
        )
        assert item.carbs_g == 0.0
        assert item.carbs_g is not None
        assert item.macros_unknown is None
