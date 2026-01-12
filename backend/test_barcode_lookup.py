"""
Test script for barcode lookup with caching and USDA fallback.
"""
import asyncio
import sys
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend')

from services.food_database_service import get_food_database_service


async def test_barcode_lookup():
    """Test barcode lookup with various barcodes."""
    service = get_food_database_service()

    # Test barcodes
    test_cases = [
        ("071757077713", "Valid barcode from logs (likely cereal/snack)"),
        ("5000159407236", "Coca-Cola UK"),
        ("012000001536", "Pepsi"),
        ("invalid_barcode", "Invalid - should be rejected"),
        ("https://youtube.com", "URL - should be rejected"),
        ("12345", "Too short - should be rejected"),
    ]

    print("=" * 60)
    print("BARCODE LOOKUP TEST")
    print("=" * 60)

    for barcode, description in test_cases:
        print(f"\n--- Testing: {description} ---")
        print(f"Barcode: {barcode}")

        try:
            result = await service.lookup_barcode(barcode)

            if result:
                print(f"✅ FOUND: {result.product_name}")
                print(f"   Brand: {result.brand}")
                print(f"   Calories: {result.nutrients.calories_per_100g} per 100g")
                print(f"   Protein: {result.nutrients.protein_per_100g}g per 100g")
                print(f"   Image URL: {result.image_url[:50] if result.image_url else 'None'}...")
            else:
                print(f"❌ NOT FOUND (or invalid format)")

        except Exception as e:
            print(f"⚠️ ERROR: {e}")

    print("\n" + "=" * 60)
    print("Testing cache hit (second lookup should be instant)")
    print("=" * 60)

    # Test cache by looking up same barcode again
    import time
    barcode = "071757077713"

    print(f"\nFirst lookup for {barcode}...")
    start = time.time()
    result1 = await service.lookup_barcode(barcode)
    time1 = time.time() - start
    print(f"Time: {time1:.3f}s")

    print(f"\nSecond lookup for {barcode} (should be cached)...")
    start = time.time()
    result2 = await service.lookup_barcode(barcode)
    time2 = time.time() - start
    print(f"Time: {time2:.3f}s")

    if time2 < time1 / 2:
        print(f"✅ Cache working! Second lookup was {time1/time2:.1f}x faster")
    else:
        print(f"⚠️ Cache may not be working (times similar)")

    # Cleanup
    await service.close()


if __name__ == "__main__":
    asyncio.run(test_barcode_lookup())
