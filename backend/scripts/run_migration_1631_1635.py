#!/usr/bin/env python3
"""Run migrations 1631-1635: Diet-specific food gap fill — organ meats, fermented foods, seaweed, grains, flours, fish, seafood, keto/Nordic/sirtfood staples (~70 items)."""
import os, sys
from pathlib import Path
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")

MIGRATIONS = [
    ("1631_overrides_organ_meats_animal_fats.sql", "Organ meats & animal fats: beef liver, heart, tongue, oxtail, bone marrow, tallow, duck fat (~12 items)"),
    ("1632_overrides_fermented_foods_seaweed.sql", "Fermented foods & seaweed: sauerkraut, kimchi, natto, kefir, nori, kelp, wakame, dulse (~13 items)"),
    ("1633_overrides_specialty_grains_flours.sql", "Ancient grains & alt flours: teff, millet, buckwheat, amaranth, almond flour, chickpea flour (~14 items)"),
    ("1634_overrides_fish_seafood_expansion.sql", "Fish & seafood: sardines, mackerel, herring, halibut, mahi-mahi, oysters, lobster (~16 items)"),
    ("1635_overrides_diet_specific_staples.sql", "Diet staples: seitan, TVP, psyllium husk, erythritol, rye crispbread, turmeric, bone broth (~15 items)"),
]

def run_migrations():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    total_success = 0
    total_fail = 0

    for filename, description in MIGRATIONS:
        file_path = migrations_dir / filename
        print(f"\n{'='*60}")
        print(f"Running: {filename}")
        print(f"  {description}")
        try:
            with open(file_path, 'r') as f:
                sql = f.read()
            with conn.cursor() as cur:
                cur.execute(sql)
            conn.commit()
            print(f"  SUCCESS")
            total_success += 1
        except Exception as e:
            conn.rollback()
            print(f"  FAILED: {e}")
            total_fail += 1

    # Verification queries
    print(f"\n{'='*60}")
    print("VERIFICATION")
    print(f"{'='*60}")

    with conn.cursor() as cur:
        # Count by food_category for new items
        print("\n--- New items by food_category ---")
        cur.execute("""
            SELECT food_category, count(*)
            FROM food_nutrition_overrides
            WHERE food_category IN (
                'organ_meat', 'cooking_fat', 'fermented_food', 'seaweed',
                'grain', 'flour', 'fish', 'shellfish', 'plant_protein',
                'supplement', 'sweetener', 'baking_ingredient', 'broth',
                'spice', 'herb', 'berry', 'bread'
            )
            AND restaurant_name IS NULL
            GROUP BY food_category ORDER BY count(*) DESC
        """)
        rows = cur.fetchall()
        total_new = sum(r[1] for r in rows)
        print(f"Generic USDA items by category ({total_new} total):")
        for cat, count in rows:
            print(f"  {cat}: {count}")

        # Spot-check specific items from each migration
        print("\n--- Spot-check key items ---")
        spot_checks = [
            'beef_liver_cooked', 'kimchi', 'nori_sheets', 'teff_cooked',
            'almond_flour', 'sardines_canned_oil', 'halibut_cooked',
            'oysters_cooked', 'seitan_cooked', 'erythritol',
            'rye_crispbread', 'turmeric_powder', 'generic_beef_bone_broth',
            'dark_chocolate_85', 'lobster_cooked'
        ]
        placeholders = ','.join(['%s'] * len(spot_checks))
        cur.execute(f"""
            SELECT display_name,
                   calories_per_100g,
                   protein_per_100g,
                   COALESCE(default_serving_g, default_weight_per_piece_g) as serving_g,
                   ROUND(calories_per_100g * COALESCE(default_serving_g, default_weight_per_piece_g) / 100) as cal_per_serving,
                   food_category
            FROM food_nutrition_overrides
            WHERE food_name_normalized IN ({placeholders})
            ORDER BY food_category, display_name
        """, spot_checks)
        for row in cur.fetchall():
            print(f"  [{row[5]}] {row[0]}: {row[1]} cal/100g, {row[2]}g P/100g, {row[4]} cal/serving ({row[3]}g)")

        # Variant name search test
        print("\n--- Variant name search test ---")
        search_terms = ['beef liver', 'sauerkraut', 'nori', 'teff', 'almond flour', 'sardines', 'seitan', 'turmeric', 'bone broth']
        for term in search_terms:
            cur.execute("""
                SELECT display_name FROM food_nutrition_overrides
                WHERE food_name_normalized ILIKE %s
                   OR display_name ILIKE %s
                   OR EXISTS (SELECT 1 FROM unnest(variant_names) v WHERE v ILIKE %s)
                LIMIT 1
            """, (f'%{term}%', f'%{term}%', f'%{term}%'))
            result = cur.fetchone()
            status = f"FOUND: {result[0]}" if result else "NOT FOUND"
            print(f"  '{term}' -> {status}")

        # Total overrides count
        cur.execute("SELECT count(*) FROM food_nutrition_overrides WHERE is_active = TRUE")
        total_all = cur.fetchone()[0]
        print(f"\n=== TOTAL ACTIVE OVERRIDES IN TABLE: {total_all} ===")

    conn.close()
    print(f"\n{'='*60}")
    print(f"DONE: {total_success} succeeded, {total_fail} failed")
    return total_fail == 0

if __name__ == "__main__":
    success = run_migrations()
    sys.exit(0 if success else 1)
