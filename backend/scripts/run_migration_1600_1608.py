#!/usr/bin/env python3
"""Run migrations 1600-1608: Food nutrition overrides expansion (~370 items)."""
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
    ("1600_overrides_erewhon.sql", "Erewhon Market (~92 items)"),
    ("1601_overrides_sweetgreen_cava.sql", "Sweetgreen + CAVA (~78 items)"),
    ("1602_overrides_pressed_juicery.sql", "Pressed Juicery (~20 items)"),
    ("1603_overrides_trader_joes_expansion.sql", "Trader Joe's expansion (~31 items)"),
    ("1604_overrides_dairy_queen.sql", "Dairy Queen (~19 items)"),
    ("1605_overrides_olive_garden_epl_cf.sql", "Olive Garden, El Pollo Loco, Cheesecake Factory (~34 items)"),
    ("1606_overrides_factor_trifecta.sql", "Factor + Trifecta meals (~32 items)"),
    ("1607_overrides_health_brands.sql", "Health brands: OWYN, LMNT, Kodiak, etc. (~40 items)"),
    ("1608_overrides_good_gather_simple_truth.sql", "Good & Gather + Simple Truth (~26 items)"),
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
        # Count by restaurant
        cur.execute("""
            SELECT restaurant_name, count(*)
            FROM food_nutrition_overrides
            WHERE restaurant_name IN (
                'Erewhon','Sweetgreen','CAVA','Pressed Juicery',
                'Trader Joe''s','Dairy Queen','Olive Garden',
                'El Pollo Loco','The Cheesecake Factory',
                'Factor','Trifecta','Good & Gather','Simple Truth',
                'OWYN','LMNT','Kodiak Cakes','Banza','Food for Life',
                'Ratio','Fairlife','Quest','Barebells','Ghost',
                'Chobani','Halo Top'
            )
            GROUP BY restaurant_name
            ORDER BY count(*) DESC
        """)
        rows = cur.fetchall()
        total_items = sum(r[1] for r in rows)
        print(f"\nItems by brand ({total_items} total):")
        for name, count in rows:
            print(f"  {name}: {count}")

        # Spot-check per-100g math
        print("\nSpot-check (cal_per_serving = cal_per_100g * serving / 100):")
        cur.execute("""
            SELECT display_name,
                   calories_per_100g,
                   COALESCE(default_serving_g, default_weight_per_piece_g) as serving,
                   ROUND(calories_per_100g * COALESCE(default_serving_g, default_weight_per_piece_g) / 100) as cal_per_serving
            FROM food_nutrition_overrides
            WHERE restaurant_name IN ('Erewhon','Dairy Queen','Factor','CAVA','Fairlife')
            ORDER BY random()
            LIMIT 10
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
