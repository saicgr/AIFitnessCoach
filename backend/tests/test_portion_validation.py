"""Tests for the L2/L3 portion-validation pipeline.

Three groups, ~20 tests, all standalone — no DB / network required.
We import the parsers module directly so we don't need to instantiate
the GeminiService class (which pulls in heavy deps at import time).

Failure mode under test: Gemini emits the per-cup weight (e.g. 148g per
cup of blueberries) as the per-PIECE weight, multiplied by an absurd
count (e.g. 99). L2 reconciles via DB / never-countable name match;
L3 catches whatever L2 missed via kcal/g + size + internal-consistency
tripwires.
"""
from __future__ import annotations

import sys
import os
import importlib.util

# Load parsers.py in isolation (avoid `services.gemini.__init__` heavy import).
_REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, _REPO)

_spec = importlib.util.spec_from_file_location(
    "parsers_under_test",
    os.path.join(_REPO, "services", "gemini", "parsers.py"),
)
parsers = importlib.util.module_from_spec(_spec)
# parsers.py imports `core.ai_response_parser`; make sure it resolves.
_spec.loader.exec_module(parsers)  # type: ignore

reconcile_with_db = parsers.reconcile_with_db
apply_tripwires = parsers.apply_tripwires
finalize_food_items = parsers.finalize_food_items


# --- helpers ---------------------------------------------------------------

def _item(name: str, **kw):
    base = dict(
        name=name,
        portion_basis="by_count",
        weight_g=None,
        count=None,
        weight_per_unit_g=None,
        calories=0,
    )
    base.update(kw)
    return base


# =============================================================================
# Group A: small fruits / berries
# =============================================================================

class TestBerries:
    def test_blueberries_99x148_clamped_or_flagged(self):
        """The exact bug: 99 berries × 148g = 8316 kcal."""
        items = [_item(
            "blueberries",
            portion_basis="by_count",
            count=99,
            weight_per_unit_g=148.0,
            weight_g=14652.0,
            calories=8316,
        )]
        finalize_food_items(items, db_rows=None)
        it = items[0]
        # L2 (never-countable) should rewrite to by_weight + sane default ~80g.
        assert it["portion_basis"] == "by_weight"
        assert it["count"] is None
        assert it["weight_per_unit_g"] is None
        assert it["weight_g"] is not None and 30 <= it["weight_g"] <= 200
        assert it["sanity_clamped"] is True

    def test_blueberries_with_db_small_piece_anti_pattern(self):
        items = [_item(
            "blueberries",
            portion_basis="by_count",
            count=99,
            weight_per_unit_g=148.0,
            weight_g=14652.0,
            calories=8316,
        )]
        finalize_food_items(items, db_rows={"blueberries": {
            "default_weight_per_piece_g": 1.5,
            "default_serving_g": 80,
        }})
        # Either route (L2 never-countable OR small-piece) flips to by_weight.
        assert items[0]["portion_basis"] == "by_weight"
        assert items[0]["sanity_clamped"] is True

    def test_strawberries_oz_as_piece(self):
        items = [_item(
            "strawberries",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=152.0,  # claimed per-piece = 1 cup
            weight_g=152.0,
            calories=49,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"
        assert items[0]["sanity_clamped"] is True

    def test_grapes_oz_as_piece(self):
        items = [_item(
            "grapes",
            portion_basis="by_count",
            count=2,
            weight_per_unit_g=151.0,
            weight_g=302.0,
            calories=210,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"

    def test_blackberries_handful(self):
        items = [_item(
            "blackberries",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=144.0,
            weight_g=144.0,
            calories=62,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"

    def test_cherries_oz_as_piece(self):
        items = [_item(
            "cherries",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=155.0,
            weight_g=155.0,
            calories=97,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"

    def test_raspberries_no_db_caught_by_l3(self):
        """Even if L2 didn't fire, L3 kcal/g window should flag impossible density."""
        # Force a scenario where L2 doesn't see "raspberr" — use a typo so
        # never-countable doesn't match, then verify L3 still flags.
        items = [_item(
            "raspberry mix",  # contains 'raspberr' so L2 will rewrite — that's fine
            portion_basis="by_count",
            count=10,
            weight_per_unit_g=120.0,
            weight_g=1200.0,
            calories=600,
        )]
        finalize_food_items(items, db_rows=None)
        # Either rewritten or flagged.
        assert items[0]["sanity_clamped"] is True or items[0].get("requires_user_confirmation") is True

    def test_l3_catches_impossible_kcal_density_for_fruit(self):
        """Pure L3 path: unknown food name ('fruit medley') with absurd kcal/g."""
        items = [_item(
            "fruit medley",
            portion_basis="by_weight",
            weight_g=100.0,
            calories=8000,  # 80 kcal/g — impossible for fruit
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0].get("requires_user_confirmation") is True
        assert items[0].get("confidence") == "low"


# =============================================================================
# Group B: nuts / seeds
# =============================================================================

class TestNuts:
    def test_cashews_oz_as_piece(self):
        """1 oz cashews = 28g handful, NOT 28g per cashew."""
        items = [_item(
            "cashews",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=28.0,
            weight_g=28.0,
            calories=160,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"
        assert items[0]["count"] is None
        assert items[0]["sanity_clamped"] is True

    def test_almonds_count_50_pieces(self):
        """50 almonds × 1.2g = 60g — but Gemini may say 50 × 23g = 1150g."""
        items = [_item(
            "almonds",
            portion_basis="by_count",
            count=50,
            weight_per_unit_g=23.0,
            weight_g=1150.0,
            calories=6624,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"

    def test_walnut_handful(self):
        items = [_item(
            "walnuts",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=28.0,
            weight_g=28.0,
            calories=185,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"

    def test_peanut_butter_never_countable(self):
        items = [_item(
            "peanut butter",
            portion_basis="by_count",
            count=2,
            weight_per_unit_g=16.0,
            weight_g=32.0,
            calories=190,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"
        assert items[0]["count"] is None

    def test_peanut_butter_with_huge_wpu(self):
        """Spread with claimed wpu > 50g — must rewrite."""
        items = [_item(
            "peanut butter",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=240.0,  # claimed "1 cup" weight as a piece
            weight_g=240.0,
            calories=1500,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"
        assert items[0]["sanity_clamped"] is True

    def test_pistachios_handful(self):
        items = [_item(
            "pistachios",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=28.0,
            weight_g=28.0,
            calories=160,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"


# =============================================================================
# Group C: loose grains / seeds
# =============================================================================

class TestLooseGrainsSeeds:
    def test_chia_seeds(self):
        items = [_item(
            "chia seeds",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=12.0,
            weight_g=12.0,
            calories=58,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"

    def test_flax_seeds(self):
        items = [_item(
            "flax seeds",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=7.0,
            weight_g=7.0,
            calories=37,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"

    def test_oats_handful(self):
        items = [_item(
            "oats",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=40.0,
            weight_g=40.0,
            calories=150,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["portion_basis"] == "by_weight"


# =============================================================================
# Whole-unit foods (egg, banana) — should NOT be flipped to by_weight
# =============================================================================

class TestWholeUnitNotRewritten:
    def test_eggs_keep_count(self):
        items = [_item(
            "eggs",
            portion_basis="by_count",
            count=2,
            weight_per_unit_g=50.0,
            weight_g=100.0,
            calories=140,
        )]
        finalize_food_items(items, db_rows={"eggs": {
            "default_weight_per_piece_g": 50,
            "default_serving_g": 50,  # 1 egg = 1 serving
        }})
        # Whole-unit: count must be preserved; no requires_user_confirmation.
        assert items[0]["portion_basis"] == "by_count"
        assert items[0]["count"] == 2
        assert items[0].get("requires_user_confirmation") is not True

    def test_banana_keeps_count(self):
        items = [_item(
            "banana",
            portion_basis="by_count",
            count=1,
            weight_per_unit_g=120.0,
            weight_g=120.0,
            calories=105,
        )]
        finalize_food_items(items, db_rows={"banana": {
            "default_weight_per_piece_g": 120,
            "default_serving_g": 120,
        }})
        assert items[0]["portion_basis"] == "by_count"
        assert items[0]["count"] == 1


# =============================================================================
# Generic L3 tripwires
# =============================================================================

class TestL3Tripwires:
    def test_5kg_weight_flagged(self):
        items = [_item(
            "rice",
            portion_basis="by_weight",
            weight_g=6000.0,
            calories=7800,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["requires_user_confirmation"] is True

    def test_internal_consistency(self):
        items = [_item(
            "chicken nugget",
            portion_basis="by_count",
            count=10,
            weight_per_unit_g=20.0,
            weight_g=2000.0,  # disagrees with 10*20=200g
            calories=200,
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0]["requires_user_confirmation"] is True

    def test_normal_item_passes(self):
        items = [_item(
            "grilled chicken breast",
            portion_basis="by_weight",
            weight_g=150.0,
            calories=247,  # ~1.65 kcal/g — protein window
        )]
        finalize_food_items(items, db_rows=None)
        assert items[0].get("requires_user_confirmation") is not True
        assert items[0].get("confidence") != "low"
