#!/usr/bin/env python3
"""
Focused local test for the multi-item fusion bug fix.

Bug: "chicken fry, dal, rice and curd" was returning "chicken fried rice"
(a single hallucinated dish) instead of 4 separate items.

Runs the exact analyze_food() code path used by /nutrition/analyze-text.
No backend server or auth required — just .env with Gemini + Supabase creds.

Usage:
    cd backend && python3 tests/test_multi_item_fusion_fix.py
    cd backend && python3 tests/test_multi_item_fusion_fix.py --splitter-only  # skip Gemini
"""
import asyncio
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()


async def test_splitter_only():
    """Pure unit test of the splitter — no Gemini, no DB.

    Loads overrides from Supabase first so the compound-food guard
    (mac and cheese, fish and chips, etc.) fires correctly.
    """
    from services.food_analysis.cache_service_helpers_part2 import FoodAnalysisCacheServicePart2
    from services.food_database_lookup_service import get_food_db_lookup_service

    # Pre-load overrides so _split_on_and_only's compound-food protection
    # (which reads lookup_service._overrides) can find "mac and cheese" etc.
    await get_food_db_lookup_service()._load_overrides()

    class _SplitterHarness(FoodAnalysisCacheServicePart2):
        pass

    harness = _SplitterHarness()

    cases = [
        # (input, expected_item_count, must_include_lowercase_tokens)
        ("chicken fry, dal, rice and curd", 4, ["chicken fry", "dal", "rice", "curd"]),
        ("paneer fry, naan, raita", 3, ["paneer fry", "naan", "raita"]),
        ("egg bhurji, roti, pickle", 3, ["egg bhurji", "roti", "pickle"]),
        ("idli, sambar, chutney, filter coffee", 4, ["idli", "sambar", "chutney", "filter coffee"]),
        # Foreign-language comma (Chinese full-width)
        ("chicken fry，dal，rice", 3, ["chicken fry", "dal", "rice"]),
        # Devanagari danda
        ("dal।rice।roti", 3, ["dal", "rice", "roti"]),
        # Semicolons
        ("chicken fry; dal; rice", 3, ["chicken fry", "dal", "rice"]),
        # Pipes
        ("chicken fry | dal | rice", 3, ["chicken fry", "dal", "rice"]),
        # Leading/trailing separators (stripped, no empty items)
        (",chicken fry,, dal,", 2, ["chicken fry", "dal"]),
        # Compound food protected
        ("mac and cheese", 1, ["mac and cheese"]),
        ("fish and chips", 1, ["fish and chips"]),
        # Composite meal stays whole
        ("Chipotle bowl with chicken, rice, beans", 1, None),
        # "or" does NOT split
        ("dal or curry", 1, ["dal or curry"]),
        # Single item unchanged
        ("chicken", 1, ["chicken"]),
        # Single "fried rice" not over-split
        ("fried rice", 1, ["fried rice"]),
        # Duplicate bare items
        ("rice, rice, rice", 3, ["rice", "rice", "rice"]),
    ]

    failures = []
    for desc, expected_count, expected_tokens in cases:
        items = harness._split_food_description(desc)
        got_count = len(items)
        got_names = [i.food_name.lower().strip() for i in items]
        ok = got_count == expected_count
        if ok and expected_tokens is not None:
            # Each expected token must appear as a substring of some split item
            for tok in expected_tokens:
                if not any(tok in n for n in got_names):
                    ok = False
                    break
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] {desc!r:55s}  →  {got_names}  (expected {expected_count})")
        if not ok:
            failures.append((desc, expected_count, got_names))
    print(f"\n  Splitter: {len(cases) - len(failures)}/{len(cases)} passed")
    return len(failures) == 0


def test_duplicate_collapsing():
    """Unit test of the duplicate collapser."""
    from services.food_analysis.cache_service_helpers_part2 import FoodAnalysisCacheServicePart2
    from services.food_analysis.parser import ParsedFoodItem

    # Bare-count dupes → collapse
    items = [
        ParsedFoodItem(food_name="rice", quantity=1.0, raw_text="rice"),
        ParsedFoodItem(food_name="rice", quantity=1.0, raw_text="rice"),
        ParsedFoodItem(food_name="rice", quantity=1.0, raw_text="rice"),
    ]
    result = FoodAnalysisCacheServicePart2._collapse_duplicate_items(items)
    assert len(result) == 1, f"Expected 1 after collapse, got {len(result)}"
    assert result[0].quantity == 3.0, f"Expected qty=3.0, got {result[0].quantity}"
    print("  [PASS] 'rice, rice, rice' → 1 item with qty=3.0")

    # Weight-based dupes → do NOT collapse (would undercount)
    items = [
        ParsedFoodItem(food_name="rice", weight_g=200, raw_text="200g rice"),
        ParsedFoodItem(food_name="rice", weight_g=200, raw_text="200g rice"),
    ]
    result = FoodAnalysisCacheServicePart2._collapse_duplicate_items(items)
    assert len(result) == 2, f"Expected 2 (weight items not collapsed), got {len(result)}"
    print("  [PASS] '200g rice, 200g rice' → 2 items (weight preserved, no undercount)")

    # Different names → separate
    items = [
        ParsedFoodItem(food_name="rice", quantity=1.0),
        ParsedFoodItem(food_name="dal", quantity=1.0),
        ParsedFoodItem(food_name="rice", quantity=1.0),
    ]
    result = FoodAnalysisCacheServicePart2._collapse_duplicate_items(items)
    assert len(result) == 2, f"Expected 2 (rice collapsed, dal separate), got {len(result)}"
    assert result[0].food_name == "rice" and result[0].quantity == 2.0
    assert result[1].food_name == "dal"
    print("  [PASS] 'rice, dal, rice' → 2 items (rice collapsed qty=2, dal separate)")

    return True


async def test_e2e():
    """End-to-end test hitting the real Gemini + Supabase."""
    from services.food_analysis_cache_service import get_food_analysis_cache_service
    cache_svc = get_food_analysis_cache_service()

    cases = [
        # (description, expected_min_items, forbidden_item_name_substring)
        ("chicken fry, dal, rice and curd", 4, "chicken fried rice"),
        ("paneer fry, naan, raita", 3, None),
    ]

    all_pass = True
    for desc, expected_min_items, forbidden in cases:
        # Invalidate any stale cache so we exercise the fresh code path.
        await cache_svc.invalidate_cache(desc)
        t0 = time.time()
        try:
            result = await asyncio.wait_for(
                cache_svc.analyze_food(
                    description=desc,
                    user_goals=None,
                    nutrition_targets=None,
                    meal_type=None,
                ),
                timeout=60.0,
            )
        except asyncio.TimeoutError:
            print(f"  [FAIL] {desc!r} timed out after 60s")
            all_pass = False
            continue
        elapsed_ms = int((time.time() - t0) * 1000)

        if not result:
            print(f"  [FAIL] {desc!r} returned None")
            all_pass = False
            continue

        food_items = result.get("food_items") or []
        item_names = [fi.get("name", "") for fi in food_items]
        data_source = result.get("cache_source") or result.get("data_source")
        total_cal = result.get("total_calories", 0)

        ok = len(food_items) >= expected_min_items
        if forbidden and any(forbidden.lower() in n.lower() for n in item_names):
            ok = False

        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] {desc!r}")
        print(f"         items ({len(food_items)}): {item_names}")
        print(f"         total={total_cal}kcal  source={data_source}  elapsed={elapsed_ms}ms")
        if not ok:
            all_pass = False
            if len(food_items) < expected_min_items:
                print(f"         → Expected >= {expected_min_items} items, got {len(food_items)}")
            if forbidden:
                bad = [n for n in item_names if forbidden.lower() in n.lower()]
                if bad:
                    print(f"         → Forbidden name detected: {bad}")

    return all_pass


async def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--splitter-only", action="store_true",
                        help="Skip the Gemini/DB e2e test, run only pure-python checks")
    args = parser.parse_args()

    print("=" * 80)
    print("  SPLITTER UNIT TESTS")
    print("=" * 80)
    splitter_ok = await test_splitter_only()

    print("\n" + "=" * 80)
    print("  DUPLICATE-COLLAPSING UNIT TESTS")
    print("=" * 80)
    dup_ok = test_duplicate_collapsing()

    if args.splitter_only:
        print("\n(Skipping e2e — --splitter-only)")
        return 0 if (splitter_ok and dup_ok) else 1

    print("\n" + "=" * 80)
    print("  END-TO-END (Gemini + Supabase + Redis)")
    print("=" * 80)
    e2e_ok = await test_e2e()

    print("\n" + "=" * 80)
    overall = splitter_ok and dup_ok and e2e_ok
    print(f"  OVERALL: {'PASS' if overall else 'FAIL'}")
    print("=" * 80)
    return 0 if overall else 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
