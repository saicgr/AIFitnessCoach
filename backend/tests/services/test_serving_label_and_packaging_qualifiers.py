"""Regression tests for the packaged-food accuracy fixes.

Covers two pure-function units (no DB / no TestClient — see
project_testclient_httpx_skew):

  Fix A — `parse_serving_label`: raw serving string → descriptive unit + grams.
  Fix B — `unsatisfied_packaging_qualifiers` / `extract_packaging_qualifiers`:
          packaging-size variant integrity, including the false-positive matrix
          ("king crab", "burger king", "mini eggs" must NOT fire).
"""
import pytest

from services.gemini.parsers import parse_serving_label
from services.food_match_gate import (
    unsatisfied_packaging_qualifiers as U,
    extract_packaging_qualifiers as E,
)


# ── Fix A: parse_serving_label ──────────────────────────────────────────────

@pytest.mark.parametrize("raw,label,grams", [
    ("1/4 Pizza (138g)", "1/4 pizza", 138.0),
    ("2 scoops (35 g)", "2 scoops", 35.0),
    ("1 cup (240ml)", "1 cup", 240.0),
    ("1 bar (1.6 oz)", "1 bar", 45.4),       # oz → g
    ("1 cookie (16g)", "1 cookie", 16.0),
    ("1/8 cake (40g)", "1/8 cake", 40.0),
    # Generic / bare → no descriptive label (preserves "pcs"/"servings").
    ("1 serving(s)", None, None),
    ("1 piece (23g)", None, 23.0),
    ("pcs", None, None),
    ("100g", None, 100.0),
    ("", None, None),
    (None, None, None),
])
def test_parse_serving_label(raw, label, grams):
    out = parse_serving_label(raw)
    assert out["serving_label"] == label
    assert out["grams"] == grams


# ── Fix B: packaging-qualifier integrity ────────────────────────────────────

_BASE_ALMOND_JOY = {
    "display_name": "Almond Joy Candy Bar",
    "food_name_normalized": "almond joy",
    "variant_names": ["almond joy", "almond joy bar", "almond joy candy bar"],
    "restaurant_name": "hersheys",
    "food_category": "chocolate",
}
_KING_ALMOND_JOY = {
    "display_name": "Almond Joy King Size",
    "food_name_normalized": "almond joy king size",
    "variant_names": ["almond joy king size", "almond joy king"],
    "restaurant_name": "hersheys",
    "food_category": "chocolate",
}


@pytest.mark.parametrize("queries,row,should_suppress", [
    # Wrong variant — MUST suppress (defer to AI / no false verify).
    (["almond joy king size"], _BASE_ALMOND_JOY, True),
    (["almond joy king"], _BASE_ALMOND_JOY, True),           # bare king, branded
    ([None, "Almond Joy King Size"], _BASE_ALMOND_JOY, True),  # image: name carries it
    # Correct variant / no qualifier — MUST allow.
    (["almond joy king size"], _KING_ALMOND_JOY, False),
    (["almond joy"], _BASE_ALMOND_JOY, False),               # regression anchor
    # False-positive guards — "king"/"mini"/"fun" inside real product names.
    (["burger king whopper"], {"display_name": "Burger King Whopper",
                               "restaurant_name": "burger king",
                               "food_category": "burgers", "variant_names": []}, False),
    (["king crab legs"], {"display_name": "King Crab",
                          "food_category": "seafood", "variant_names": []}, False),
    (["kings hawaiian rolls"], {"display_name": "King's Hawaiian Rolls",
                                "restaurant_name": "king's hawaiian",
                                "food_category": "bread", "variant_names": []}, False),
    (["mini eggs"], {"display_name": "Cadbury Mini Eggs", "restaurant_name": "cadbury",
                     "food_category": "chocolate", "variant_names": ["mini eggs"]}, False),
    (["large coffee"], {"display_name": "Coffee", "food_category": "beverage",
                        "variant_names": []}, False),
])
def test_unsatisfied_packaging_qualifiers(queries, row, should_suppress):
    assert bool(U(queries, row)) is should_suppress


def test_extract_packaging_qualifiers():
    assert "king size" in E("almond joy king size")
    assert E("almond joy") == set()
    assert E("almond joy fun size") == {"fun size"}
