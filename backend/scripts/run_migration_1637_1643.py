#!/usr/bin/env python3
"""Run migrations 1637-1643: Restaurant & grocery brand expansion — salad chains, Subway, fitness snacks, trending chains, Playa/Scooter's/Carl's Jr, grocery brands, meal kits (~249 items)."""
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
    ("1637_overrides_salad_chains.sql", "Salad chains: Chopt, Just Salad, Salad and Go, Tender Greens (~49 items)"),
    ("1638_overrides_subway_expansion.sql", "Subway expansion: 6\" subs, footlongs, wraps, cookies (~25 items)"),
    ("1639_overrides_fitness_snacks_expansion.sql", "Fitness snacks: ONE Bar, think!, FitCrunch, Kodiak Cakes, Jack Link's, CLIF, RXBAR (~40 items)"),
    ("1640_overrides_trending_chains.sql", "Trending chains: Dave's Hot Chicken, Buc-ee's, Slim Chickens (~35 items)"),
    ("1641_overrides_playa_scooters_carlsjr.sql", "Playa Bowls, Scooter's Coffee, Carl's Jr (~35 items)"),
    ("1642_overrides_grocery_brands.sql", "Grocery brands: 365 Whole Foods, Kroger, H-E-B, Publix, Wegmans (~40 items)"),
    ("1643_overrides_meal_kits.sql", "Meal kits: HelloFresh, Member's Mark, Blue Apron (~25 items)"),
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
        # Count by restaurant_name for new brands
        print("\n--- New items by restaurant_name ---")
        cur.execute("""
            SELECT restaurant_name, count(*)
            FROM food_nutrition_overrides
            WHERE restaurant_name IN (
                'Chopt', 'Just Salad', 'Salad and Go', 'Tender Greens',
                'Subway', 'ONE', 'think!', 'FitCrunch', 'Kodiak Cakes',
                'Jack Link''s', 'CLIF', 'RXBAR',
                'Dave''s Hot Chicken', 'Buc-ee''s', 'Slim Chickens',
                'Playa Bowls', 'Scooter''s Coffee', 'Carl''s Jr',
                '365 by Whole Foods', 'Kroger', 'H-E-B', 'Publix', 'Wegmans',
                'HelloFresh', 'Member''s Mark', 'Blue Apron'
            )
            GROUP BY restaurant_name ORDER BY count(*) DESC
        """)
        rows = cur.fetchall()
        total_new = sum(r[1] for r in rows)
        print(f"Brand items by restaurant_name ({total_new} total):")
        for name, count in rows:
            print(f"  {name}: {count}")

        # Spot-check specific items from each migration
        print("\n--- Spot-check key items ---")
        spot_checks = [
            'chopt_classic_cobb', 'just_salad_crispy_chicken_caesar',
            'subway_chicken_teriyaki_6in', 'subway_turkey_footlong',
            'one_bar_birthday_cake', 'fitcrunch_peanut_butter',
            'daves_tender_no_spice_1pc', 'bucees_brisket_sandwich',
            'playa_og_acai_bowl', 'carlsjr_famous_star',
            '365wf_organic_chicken_breast', 'publix_pub_sub_turkey',
            'hellofresh_firecracker_meatballs', 'members_mark_rotisserie_chicken',
            'blue_apron_salmon_lemon_butter'
        ]
        placeholders = ','.join(['%s'] * len(spot_checks))
        cur.execute(f"""
            SELECT display_name,
                   calories_per_100g,
                   protein_per_100g,
                   COALESCE(default_serving_g, default_weight_per_piece_g) as serving_g,
                   ROUND(calories_per_100g * COALESCE(default_serving_g, default_weight_per_piece_g) / 100) as cal_per_serving,
                   restaurant_name
            FROM food_nutrition_overrides
            WHERE food_name_normalized IN ({placeholders})
            ORDER BY restaurant_name, display_name
        """, spot_checks)
        for row in cur.fetchall():
            print(f"  [{row[5]}] {row[0]}: {row[1]} cal/100g, {row[2]}g P/100g, {row[4]} cal/serving ({row[3]}g)")

        # Variant name search test
        print("\n--- Variant name search test ---")
        search_terms = [
            'chopt caesar', 'just salad buffalo', 'subway chicken teriyaki',
            'one bar birthday cake', 'dave\'s hot chicken', 'buc-ee\'s brisket',
            'playa bowl', 'carl\'s jr famous star', 'pub sub',
            '365 chicken', 'hellofresh', 'blue apron salmon'
        ]
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
