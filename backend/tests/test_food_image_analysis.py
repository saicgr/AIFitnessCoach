"""
Test for food image analysis functionality.

Tests the analyze_food_image function in GeminiService with a real food image.
Image source: Wikipedia Commons (Public Domain)
https://commons.wikimedia.org/wiki/File:Good_Food_Display_-_NCI_Visuals_Online.jpg

Run with:
    cd backend && python -m pytest tests/test_food_image_analysis.py -v -s

Or run directly:
    cd backend && python tests/test_food_image_analysis.py
"""

import asyncio
import base64
import json
import os
import sys

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def get_test_image_base64() -> str:
    """Load the test food image and return as base64."""
    image_path = os.path.join(os.path.dirname(__file__), "fixtures", "test_food.jpg")

    if not os.path.exists(image_path):
        raise FileNotFoundError(
            f"Test image not found at {image_path}. "
            "Please ensure test_food.jpg exists in tests/fixtures/"
        )

    with open(image_path, "rb") as f:
        image_data = f.read()

    return base64.b64encode(image_data).decode("utf-8")


async def test_analyze_food_image():
    """Test the analyze_food_image function with a real food image."""
    from services.gemini_service import GeminiService

    print("\n" + "=" * 60)
    print("FOOD IMAGE ANALYSIS TEST")
    print("=" * 60)

    service = GeminiService()
    image_b64 = get_test_image_base64()

    print(f"\nImage size: {len(base64.b64decode(image_b64)) / 1024:.1f} KB")
    print("Analyzing image with Gemini...\n")

    result = await service.analyze_food_image(image_b64, "image/jpeg")

    assert result is not None, "analyze_food_image returned None"

    # Validate structure
    assert "food_items" in result, "Missing 'food_items' in result"
    assert "total_calories" in result, "Missing 'total_calories' in result"
    assert "protein_g" in result, "Missing 'protein_g' in result"
    assert "carbs_g" in result, "Missing 'carbs_g' in result"
    assert "fat_g" in result, "Missing 'fat_g' in result"
    assert "feedback" in result, "Missing 'feedback' in result"

    food_items = result["food_items"]
    assert isinstance(food_items, list), "food_items should be a list"
    assert len(food_items) > 0, "Should detect at least one food item"

    # Print results
    print("-" * 60)
    print("RESULTS:")
    print("-" * 60)

    print(f"\nFood items detected: {len(food_items)}")
    for i, item in enumerate(food_items, 1):
        name = item.get("name", "Unknown")
        amount = item.get("amount", "N/A")
        calories = item.get("calories", 0)
        protein = item.get("protein_g", 0)
        carbs = item.get("carbs_g", 0)
        fat = item.get("fat_g", 0)
        weight_g = item.get("weight_g", "N/A")
        unit = item.get("unit", "g")
        count = item.get("count")
        weight_per_unit = item.get("weight_per_unit_g")

        print(f"  {i}. {name}")
        print(f"     Amount: {amount}")
        print(f"     Calories: {calories} | P: {protein}g | C: {carbs}g | F: {fat}g")
        print(f"     Weight: {weight_g}{unit}", end="")
        if count and weight_per_unit:
            print(f" ({count} x {weight_per_unit}g each)")
        else:
            print()

    print(f"\n{'─' * 40}")
    print("TOTALS:")
    print(f"  Calories: {result.get('total_calories')}")
    print(f"  Protein:  {result.get('protein_g')}g")
    print(f"  Carbs:    {result.get('carbs_g')}g")
    print(f"  Fat:      {result.get('fat_g')}g")
    print(f"  Fiber:    {result.get('fiber_g', 'N/A')}g")

    print(f"\n{'─' * 40}")
    print("FEEDBACK:")
    print(f"  {result.get('feedback', 'No feedback provided')}")

    print("\n" + "=" * 60)
    print("TEST PASSED")
    print("=" * 60 + "\n")

    return result


async def test_weight_count_fields(result: dict = None):
    """Test that weight/count fields are returned for portion editing.

    Args:
        result: Optional pre-existing result from analyze_food_image.
                If not provided, will make a new API call.
    """
    from services.gemini_service import GeminiService

    print("\n" + "=" * 60)
    print("WEIGHT/COUNT FIELDS TEST")
    print("=" * 60)

    if result is None:
        service = GeminiService()
        image_b64 = get_test_image_base64()
        print("\nAnalyzing image for weight/count fields...")
        result = await service.analyze_food_image(image_b64, "image/jpeg")
    else:
        print("\nUsing result from previous test...")

    assert result is not None, "analyze_food_image returned None"

    food_items = result.get("food_items", [])
    assert len(food_items) > 0, "Should detect food items"

    # Check that weight/count fields are present
    fields_found = {
        "weight_g": False,
        "unit": False,
        "count_or_null": False,
        "weight_per_unit_or_null": False,
    }

    print("\nChecking weight/count fields in food items:")
    for item in food_items:
        name = item.get("name", "Unknown")

        # Check weight_g
        if "weight_g" in item and item["weight_g"] is not None:
            fields_found["weight_g"] = True

        # Check unit
        if "unit" in item and item["unit"] in ["g", "ml", "oz", "cups", "tsp", "tbsp"]:
            fields_found["unit"] = True

        # Check count (can be null for non-countable items)
        if "count" in item:
            fields_found["count_or_null"] = True

        # Check weight_per_unit_g (can be null for non-countable items)
        if "weight_per_unit_g" in item:
            fields_found["weight_per_unit_or_null"] = True

        # Print item details
        weight = item.get("weight_g", "N/A")
        unit = item.get("unit", "?")
        count = item.get("count")
        wpu = item.get("weight_per_unit_g")

        count_str = f"{count} x {wpu}g" if count and wpu else "N/A"
        print(f"  - {name}: {weight}{unit} (count: {count_str})")

    # Verify all expected fields are found
    print("\nField verification:")
    for field, found in fields_found.items():
        status = "[PASS]" if found else "[FAIL]"
        print(f"  {status} {field}: {'Found' if found else 'Not found'}")

    assert fields_found["weight_g"], "weight_g field not found in any item"
    assert fields_found["unit"], "unit field not found or invalid in any item"

    print("\n" + "=" * 60)
    print("WEIGHT/COUNT FIELDS TEST PASSED")
    print("=" * 60 + "\n")


async def test_trailing_comma_fix():
    """Test that the trailing comma fix works correctly."""
    from services.gemini_service import GeminiService

    print("\n" + "=" * 60)
    print("TRAILING COMMA FIX TEST")
    print("=" * 60)

    service = GeminiService()

    # Test cases with trailing commas (invalid JSON that LLMs often produce)
    test_cases = [
        (
            '{"name": "Apple", "calories": 95,}',
            "Simple trailing comma"
        ),
        (
            '{"items": [1, 2, 3,]}',
            "Trailing comma in array"
        ),
        (
            '{\n  "food": "Rice",\n  "cal": 200,\n}',
            "Trailing comma with newlines"
        ),
        (
            '{"a": {"b": 1,}, "c": [1,],}',
            "Nested trailing commas"
        ),
    ]

    all_passed = True
    for malformed, description in test_cases:
        fixed = service._fix_trailing_commas(malformed)
        try:
            json.loads(fixed)
            print(f"  [PASS] {description}")
        except json.JSONDecodeError as e:
            print(f"  [FAIL] {description}: {e}")
            all_passed = False

    assert all_passed, "Some trailing comma tests failed"

    print("\n" + "=" * 60)
    print("TRAILING COMMA FIX TEST PASSED")
    print("=" * 60 + "\n")


async def run_all_tests():
    """Run all async tests in a single event loop."""
    print("\n" + "#" * 60)
    print("# RUNNING FOOD IMAGE ANALYSIS TESTS")
    print("#" * 60)

    # Run trailing comma fix test
    await test_trailing_comma_fix()

    # Run food image analysis test and capture result
    result = await test_analyze_food_image()

    # Run weight/count fields test using the same result (avoids extra API call)
    await test_weight_count_fields(result)

    print("\nAll tests completed successfully!")


def run_tests():
    """Run all tests."""
    asyncio.run(run_all_tests())


if __name__ == "__main__":
    run_tests()
