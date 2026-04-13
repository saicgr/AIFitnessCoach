"""
End-to-end verification script for Part A food_match_gate fix.

Runs the ACTUAL gate module against hand-crafted rows that mirror what
Supabase returns for key queries. No pytest fixtures, no mocks (Gemini is
force-disabled so we exercise the deterministic path).

Run:
    cd backend && python tests/e2e_verify_food_gate.py
"""
import asyncio
import os
import sys
from typing import List, Dict

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Force Gemini to be unavailable so we only test the deterministic coverage path.
# (Real end-to-end with Gemini would be tested via curl against a live backend.)
import services.food_match_gate as fmg


async def _disabled_gemini(*args, **kwargs):
    return None


fmg.gemini_batch_validate = _disabled_gemini

from services.food_match_gate import accept_tier  # noqa: E402


# ── Rows mirroring Supabase state (verified via MCP) ───────────────────────

PANEER_MASALA_DOSA = {
    "display_name": "Paneer Masala Dosa",
    "food_name_normalized": "paneer_masala_dosa_indian",
    "variant_names": ["paneer masala dosa", "paneer dosa",
                      "masala dosa with paneer", "dosa paneer masala"],
    "source": "research",
    "calories_per_100g": 242,
    "protein_per_100g": 10.5,
}
MASALA_DOSA_IN = {
    "display_name": "Masala Dosa",
    "food_name_normalized": "masala_dosa_indian",
    "variant_names": ["masala dosa"],
    "source": "research",
    "calories_per_100g": 186,
    "protein_per_100g": 5.4,
}
MASALA_DOSA_MY = {
    "display_name": "Masala Dosa",
    "food_name_normalized": "masala_dosa_malaysian",
    "variant_names": ["masala dosa"],
    "source": "research",
    "calories_per_100g": 168,
    "protein_per_100g": 5.4,
}
PANEER_BUTTER_MASALA = {
    "display_name": "Paneer Butter Masala",
    "food_name_normalized": "paneer_butter_masala_indian",
    "variant_names": ["paneer butter masala"],
    "source": "research",
    "calories_per_100g": 186,
    "protein_per_100g": 8.6,
}
CHOCOLATE_MILK = {
    "display_name": "Chocolate Milk",
    "food_name_normalized": "chocolate_milk_american",
    "variant_names": ["chocolate milk"],
    "source": "research",
    "calories_per_100g": 83,
}
MILK_CHOCOLATE_BAR = {
    "display_name": "Milk Chocolate Bar",
    "food_name_normalized": "milk_chocolate",
    "variant_names": ["milk chocolate", "hershey bar", "chocolate bar"],
    "source": "research",
    "calories_per_100g": 535,
}


def header(title: str):
    print(f"\n{'=' * 70}\n{title}\n{'=' * 70}")


def summarize(tag: str, rows: List[Dict], partial: bool):
    print(f"  [{tag}] partial_match={partial}, rows={len(rows)}")
    for r in rows[:5]:
        print(f"    • {r['display_name']} "
              f"(region={r.get('food_name_normalized','?')[-10:]}, "
              f"{int(r.get('calories_per_100g',0))} kcal/100g)")


async def main():
    header("CASE 1: 'paneer masala dosa' — expect Paneer Masala Dosa ONLY")
    rows = [
        PANEER_MASALA_DOSA,        # Phase 1 exact hit
        MASALA_DOSA_IN,            # Phase 2 trigram sim=0.46
        MASALA_DOSA_MY,            # Phase 2 trigram sim=0.46
        PANEER_BUTTER_MASALA,      # Phase 2 trigram sim=0.44
    ]
    result = await accept_tier("paneer masala dosa", rows)
    summarize("result", result.rows, result.partial_match)
    assert len(result.rows) == 1, f"expected 1 row, got {len(result.rows)}"
    assert result.rows[0]["display_name"] == "Paneer Masala Dosa"
    assert result.partial_match is False
    print("  ✓ PASS — bug fix works")

    header("CASE 2: 'masala dosa' regression — expect plain Masala Dosa FIRST")
    rows = [MASALA_DOSA_IN, MASALA_DOSA_MY, PANEER_MASALA_DOSA]
    result = await accept_tier("masala dosa", rows)
    summarize("result", result.rows, result.partial_match)
    assert len(result.rows) >= 1
    # All are tier A (Paneer Masala Dosa covers both content words via its tokens).
    # But rank by shortest display_name first — plain Masala Dosa should come before.
    assert "Masala Dosa" == result.rows[0]["display_name"], \
        f"top row is {result.rows[0]['display_name']}"
    assert result.partial_match is False
    print("  ✓ PASS — no regression")

    header("CASE 3: 'chocolate milk' — expect Chocolate Milk, NOT Milk Chocolate")
    rows = [CHOCOLATE_MILK, MILK_CHOCOLATE_BAR]
    result = await accept_tier("chocolate milk", rows)
    summarize("result", result.rows, result.partial_match)
    assert len(result.rows) == 1
    assert result.rows[0]["display_name"] == "Chocolate Milk"
    print("  ✓ PASS — word order preserved")

    header("CASE 4: 'milk chocolate' — expect Milk Chocolate Bar, NOT Chocolate Milk")
    rows = [CHOCOLATE_MILK, MILK_CHOCOLATE_BAR]
    result = await accept_tier("milk chocolate", rows)
    summarize("result", result.rows, result.partial_match)
    assert len(result.rows) == 1
    assert result.rows[0]["display_name"] == "Milk Chocolate Bar"
    print("  ✓ PASS — reverse order also preserved")

    header("CASE 5: 'chicken tikka masala' with NO chicken row (Gemini disabled)")
    # Gemini disabled → falls back to tier-B-only (coverage>=0.5, <1.0)
    rows = [
        {"display_name": "Tikka Masala", "food_name_normalized": "tikka_masala",
         "variant_names": ["tikka masala"], "source": "research",
         "calories_per_100g": 180},
    ]
    result = await accept_tier("chicken tikka masala", rows)
    summarize("result", result.rows, result.partial_match)
    # Gemini fallback: tier B (2/3 coverage) is accepted silently
    assert len(result.rows) == 1
    assert result.partial_match is True
    print("  ✓ PASS — Gemini-outage fallback keeps tier B silently")

    header("CASE 6: 'paner masala dosa' (typo) — expect Paneer Masala Dosa")
    rows = [PANEER_MASALA_DOSA, MASALA_DOSA_IN]
    result = await accept_tier("paner masala dosa", rows)
    summarize("result", result.rows, result.partial_match)
    assert result.rows[0]["display_name"] == "Paneer Masala Dosa"
    print("  ✓ PASS — typo resolved via trigram coverage")

    header("CASE 7: 'spicy chicken curry' — descriptor ignored")
    rows = [
        {"display_name": "Chicken Curry", "food_name_normalized": "chicken_curry",
         "variant_names": ["chicken curry"], "source": "research",
         "calories_per_100g": 200},
    ]
    result = await accept_tier("spicy chicken curry", rows)
    summarize("result", result.rows, result.partial_match)
    assert len(result.rows) == 1
    assert result.partial_match is False  # tier A — spicy dropped
    print("  ✓ PASS — sensory descriptor correctly ignored")

    header("CASE 8: Unknown query 'xyz123abc' — expect EMPTY")
    rows = [MASALA_DOSA_IN, PANEER_MASALA_DOSA]
    result = await accept_tier("xyz123abc", rows)
    summarize("result", result.rows, result.partial_match)
    assert result.rows == []
    print("  ✓ PASS — no silent fallback to wrong food")

    print("\n" + "=" * 70)
    print("  ALL 8 END-TO-END CASES PASSED")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(main())
