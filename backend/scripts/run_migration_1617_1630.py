#!/usr/bin/env python3
"""Run migrations 1617-1630: Food nutrition overrides — bodybuilding, weight loss, superfoods, alcohol, grocery (~405 items)."""
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
    ("1617_overrides_protein_powders.sql", "Protein powders: ON, Dymatize, MyProtein, TL, Isopure, Legion, Gorilla Mind (~30 items)"),
    ("1618_overrides_huel_expansion.sql", "Huel expansion: Black, Original, RTD, Hot & Savory, Bars, Greens (~14 items)"),
    ("1619_overrides_smoothie_chains.sql", "Smoothie King, Tropical Smoothie Cafe, Jamba (~20 items)"),
    ("1620_overrides_bodybuilding_staples.sql", "Oikos, StarKist, Magic Spoon, MuscleEgg, Legendary Foods (~35 items)"),
    ("1621_overrides_supplements_extras.sql", "Vital Proteins, collagen, pre-workout, creatine, greens, protein chips (~30 items)"),
    ("1622_overrides_weight_loss_frozen_meals.sql", "Smart Ones, Evol, Atkins Frozen, Freshly, HC Power Bowls (~30 items)"),
    ("1623_overrides_zero_cal_condiments_beverages.sql", "Walden Farms, G Hughes, Zevia, Crystal Light, sweeteners (~35 items)"),
    ("1624_overrides_low_cal_bread_pasta_snacks.sql", "Schmidt 647, Sara Lee 45-cal, Mission CB, Yasso, SmartSweets (~35 items)"),
    ("1625_overrides_diet_shakes_keto_products.sql", "SlimFast, Atkins bars/shakes, Rebel, Fat Snax (~30 items)"),
    ("1626_overrides_exotic_meat_brands_bone_broth_superfoods.sql", "Force of Nature, EPIC, Kettle & Fire, Navitas, Bob's Red Mill (~35 items)"),
    ("1627_overrides_metabolism_brands_fruit_snacks.sql", "Bulletproof, Jade Leaf, Bragg, Four Sigmatic, That's It, Bare, Dole (~30 items)"),
    ("1628_overrides_dunkin_peets.sql", "Dunkin' + Peet's Coffee (~25 items)"),
    ("1629_overrides_alcohol_spirits_cocktails.sql", "Spirits, cocktails, branded beer/seltzer (~25 items)"),
    ("1630_overrides_grocery_brand_gaps.sql", "Barilla, Tyson, Perdue, Progresso, Hillshire Farm (~20 items)"),
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
        # Bodybuilder brands
        print("\n--- Bodybuilder brands ---")
        cur.execute("""
            SELECT restaurant_name, count(*)
            FROM food_nutrition_overrides
            WHERE restaurant_name IN (
                'Optimum Nutrition','Dymatize','Myprotein','Transparent Labs',
                'Isopure','Legion Athletics','Gorilla Mind','Huel',
                'Smoothie King','Tropical Smoothie Cafe','Jamba',
                'Oikos','StarKist','Bumble Bee','Magic Spoon',
                'Vital Proteins','AG1','Nick''s'
            )
            GROUP BY restaurant_name ORDER BY count(*) DESC
        """)
        rows = cur.fetchall()
        total_bb = sum(r[1] for r in rows)
        print(f"Items by brand ({total_bb} total):")
        for name, count in rows:
            print(f"  {name}: {count}")

        # Weight loss brands
        print("\n--- Weight loss brands ---")
        cur.execute("""
            SELECT restaurant_name, count(*)
            FROM food_nutrition_overrides
            WHERE restaurant_name IN (
                'Smart Ones','Evol','Atkins','Freshly','Walden Farms',
                'G Hughes','Zevia','Crystal Light','SlimFast',
                'Schmidt 647','Egglife','Miracle Noodle','Palmini',
                'Yasso','Skinny Pop','SmartSweets','Green Giant',
                'Fat Snax','Rebel Creamery'
            )
            GROUP BY restaurant_name ORDER BY count(*) DESC
        """)
        rows = cur.fetchall()
        total_wl = sum(r[1] for r in rows)
        print(f"Items by brand ({total_wl} total):")
        for name, count in rows:
            print(f"  {name}: {count}")

        # Hormonal/metabolism/superfood brands
        print("\n--- Superfood/metabolism brands ---")
        cur.execute("""
            SELECT restaurant_name, count(*)
            FROM food_nutrition_overrides
            WHERE restaurant_name IN (
                'Force of Nature','EPIC','Kettle & Fire','Navitas Organics',
                'Bob''s Red Mill','Sunfood','Bulletproof','Jade Leaf',
                'Bragg','Four Sigmatic','Laird Superfood',
                'That''s It','Bare','Dole','Natierra'
            )
            GROUP BY restaurant_name ORDER BY count(*) DESC
        """)
        rows = cur.fetchall()
        total_sf = sum(r[1] for r in rows)
        print(f"Items by brand ({total_sf} total):")
        for name, count in rows:
            print(f"  {name}: {count}")

        # Coffee/alcohol/grocery brands
        print("\n--- Coffee/alcohol/grocery brands ---")
        cur.execute("""
            SELECT restaurant_name, count(*)
            FROM food_nutrition_overrides
            WHERE restaurant_name IN (
                'Dunkin''','Peet''s Coffee','Generic Spirits',
                'Generic Cocktails','Michelob','White Claw','Truly',
                'Corona','Guinness','Barilla','Tyson','Perdue',
                'Progresso','Hillshire Farm'
            )
            GROUP BY restaurant_name ORDER BY count(*) DESC
        """)
        rows = cur.fetchall()
        total_cag = sum(r[1] for r in rows)
        print(f"Items by brand ({total_cag} total):")
        for name, count in rows:
            print(f"  {name}: {count}")

        grand_total = total_bb + total_wl + total_sf + total_cag
        print(f"\n=== GRAND TOTAL NEW ITEMS: {grand_total} ===")

        # Spot-check per-100g math
        print("\nSpot-check (cal_per_serving = cal_per_100g * serving / 100):")
        cur.execute("""
            SELECT display_name,
                   calories_per_100g,
                   COALESCE(default_serving_g, default_weight_per_piece_g) as serving,
                   ROUND(calories_per_100g * COALESCE(default_serving_g, default_weight_per_piece_g) / 100) as cal_per_serving
            FROM food_nutrition_overrides
            WHERE restaurant_name IN (
                'Optimum Nutrition','Huel','Smoothie King','StarKist',
                'Smart Ones','Walden Farms','SlimFast','Force of Nature',
                'Bulletproof','Dunkin''','Generic Spirits','Barilla'
            )
            ORDER BY random()
            LIMIT 15
        """)
        for row in cur.fetchall():
            print(f"  {row[0]}: {row[3]} cal/serving ({row[2]}g)")

    conn.close()
    print(f"\n{'='*60}")
    print(f"DONE: {total_success} succeeded, {total_fail} failed")
    return total_fail == 0

if __name__ == "__main__":
    success = run_migrations()
    sys.exit(0 if success else 1)
