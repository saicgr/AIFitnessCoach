"""
Tests for the L4 meal-level plausibility ceiling (E2E register #130).

2026-07-30: a photo of a food spread logged 4,591 kcal / 601 g protein as ONE
dinner. Every item individually passed L1 (schema bounds) through L3
(apply_tripwires) — the worst offender, "roasted whole turkey" (2,505 kcal /
435 g protein), even had internally-consistent per-item arithmetic. Nothing
summed the MEAL, so nothing caught it. `apply_meal_plausibility_ceiling` (and
its wiring into `enforce_macro_integrity`) is the fix under test here.
"""
import pytest

from services.gemini.parsers import (
    MEAL_CALORIE_PLAUSIBILITY_CEILING,
    MEAL_PROTEIN_PLAUSIBILITY_CEILING_G,
    apply_meal_plausibility_ceiling,
    enforce_macro_integrity,
)


def _turkey_spread_payload():
    """A reconstruction of the actual E2E #130 payload shape (6 items,
    dominated by an oversized 'roasted whole turkey' entry)."""
    return {
        "food_items": [
            {"name": "Roasted Whole Turkey", "calories": 2505, "protein_g": 435.0,
             "carbs_g": 0.0, "fat_g": 90.0, "weight_g": 1400.0},
            {"name": "Mashed Potatoes", "calories": 620, "protein_g": 12.0,
             "carbs_g": 90.0, "fat_g": 22.0, "weight_g": 400.0},
            {"name": "Green Bean Casserole", "calories": 380, "protein_g": 8.0,
             "carbs_g": 30.0, "fat_g": 24.0, "weight_g": 300.0},
            {"name": "Stuffing", "calories": 450, "protein_g": 10.0,
             "carbs_g": 60.0, "fat_g": 18.0, "weight_g": 250.0},
            {"name": "Cranberry Sauce", "calories": 210, "protein_g": 0.5,
             "carbs_g": 52.0, "fat_g": 0.2, "weight_g": 140.0},
            {"name": "Dinner Rolls (basket)", "calories": 426, "protein_g": 12.0,
             "carbs_g": 60.0, "fat_g": 12.0, "weight_g": 200.0},
        ],
        # Totals intentionally understate the real E2E #130 numbers slightly
        # (which peaked at 601g protein) — 477.5g protein / 4591 kcal is
        # already ~2x this module's ceilings and is realistic per-item.
        "total_calories": 4591,
        "protein_g": 477.5,
        "carbs_g": 292.0,
        "fat_g": 166.2,
        "fiber_g": 10.0,
    }


def _normal_meal_payload():
    """An ordinary, plausible dinner — must NOT be flagged."""
    return {
        "food_items": [
            {"name": "Grilled Chicken Breast", "calories": 330, "protein_g": 62.0,
             "carbs_g": 0.0, "fat_g": 7.2, "weight_g": 200.0},
            {"name": "Steamed Rice", "calories": 260, "protein_g": 5.0,
             "carbs_g": 57.0, "fat_g": 0.6, "weight_g": 200.0},
            {"name": "Broccoli", "calories": 55, "protein_g": 4.0,
             "carbs_g": 11.0, "fat_g": 0.6, "weight_g": 150.0},
        ],
        "total_calories": 645,
        "protein_g": 71.0,
        "carbs_g": 68.0,
        "fat_g": 8.4,
        "fiber_g": 6.0,
    }


class TestApplyMealPlausibilityCeiling:
    def test_flags_implausible_spread(self):
        payload = _turkey_spread_payload()
        result = apply_meal_plausibility_ceiling(payload, "test")

        assert result["requires_user_confirmation"] is True
        assert result["meal_plausibility_flag"] is True
        assert result["_meal_tripwire_reasons"], "must record WHY it was flagged"

        # Every item — not just the worst offender — surfaces the wired,
        # client-read confirm flag (logged_meals_section.dart reads this
        # per-item, not a meal-level key).
        for item in result["food_items"]:
            assert item["requires_user_confirmation"] is True
            assert item["confidence"] == "low"
            assert item["_tripwire_reasons"]

    def test_does_not_flag_plausible_meal(self):
        payload = _normal_meal_payload()
        result = apply_meal_plausibility_ceiling(payload, "test")

        assert "requires_user_confirmation" not in result
        assert "meal_plausibility_flag" not in result
        for item in result["food_items"]:
            assert "requires_user_confirmation" not in item

    def test_calorie_only_breach_flags(self):
        """A meal that breaches ONLY the calorie ceiling (not protein) still flags."""
        payload = {
            "food_items": [
                {"name": "Party-size Nacho Platter", "calories": 3400,
                 "protein_g": 60.0, "carbs_g": 300.0, "fat_g": 180.0,
                 "weight_g": 1200.0},
            ],
        }
        result = apply_meal_plausibility_ceiling(payload, "test")
        assert result["requires_user_confirmation"] is True
        assert any("kcal" in r for r in result["_meal_tripwire_reasons"])

    def test_protein_only_breach_flags(self):
        """A meal that breaches ONLY the protein ceiling (not calories) still flags."""
        payload = {
            "food_items": [
                {"name": "Protein Powder Mega-Shake", "calories": 1200,
                 "protein_g": 300.0, "carbs_g": 40.0, "fat_g": 10.0,
                 "weight_g": 900.0},
            ],
        }
        result = apply_meal_plausibility_ceiling(payload, "test")
        assert result["requires_user_confirmation"] is True
        assert any("protein" in r for r in result["_meal_tripwire_reasons"])

    def test_exactly_at_ceiling_does_not_flag(self):
        """Boundary: AT the ceiling (not over) must not flag — '>' not '>='."""
        payload = {
            "food_items": [
                {"name": "Large Meal", "calories": MEAL_CALORIE_PLAUSIBILITY_CEILING,
                 "protein_g": MEAL_PROTEIN_PLAUSIBILITY_CEILING_G,
                 "carbs_g": 50.0, "fat_g": 50.0, "weight_g": 800.0},
            ],
        }
        result = apply_meal_plausibility_ceiling(payload, "test")
        assert "requires_user_confirmation" not in result


class TestEnforceMacroIntegrityWiresInCeiling:
    """`enforce_macro_integrity` is the actual chokepoint every food-analysis
    payload (including the vision/photo-scan flow, via
    api/v1/nutrition/food_logging_stream.py) passes through — the ceiling must
    fire from there, not just when called directly."""

    def test_enforce_macro_integrity_flags_implausible_spread(self):
        payload = _turkey_spread_payload()
        result = enforce_macro_integrity(payload, "test")
        assert result["requires_user_confirmation"] is True
        assert result["meal_plausibility_flag"] is True
        for item in result["food_items"]:
            assert item["requires_user_confirmation"] is True

    def test_enforce_macro_integrity_leaves_normal_meal_unflagged_by_l4(self):
        payload = _normal_meal_payload()
        result = enforce_macro_integrity(payload, "test")
        assert "meal_plausibility_flag" not in result
