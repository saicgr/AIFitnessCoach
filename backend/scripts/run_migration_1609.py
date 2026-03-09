#!/usr/bin/env python3
"""Run migration 1609: Fix override serving sizes + add chocolate pastry."""
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

def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "1609_fix_override_serving_sizes.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    # Run migration
    print(f"{'='*60}")
    print(f"Running: 1609_fix_override_serving_sizes.sql")
    print(f"  Fix override serving sizes + add chocolate pastry")
    try:
        with open(migration_file, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"  SUCCESS")
    except Exception as e:
        conn.rollback()
        print(f"  FAILED: {e}")
        conn.close()
        return False

    # Verification queries
    print(f"\n{'='*60}")
    print("VERIFICATION")
    print(f"{'='*60}")

    with conn.cursor() as cur:
        # 1. Check chocolate_pastry was inserted
        print("\n1. Check chocolate_pastry inserted:")
        cur.execute("""
            SELECT food_name_normalized, display_name, calories_per_100g,
                   default_weight_per_piece_g, default_serving_g, default_count
            FROM food_nutrition_overrides
            WHERE food_name_normalized = 'chocolate_pastry'
        """)
        row = cur.fetchone()
        if row:
            print(f"  PASS: {row[1]} - {row[2]} cal/100g, piece={row[3]}g, serving={row[4]}g, count={row[5]}")
        else:
            print(f"  FAIL: chocolate_pastry not found!")

        # 2. Check rice_cakes_chocolate
        print("\n2. Check rice_cakes_chocolate (expect serving=39, count=3):")
        cur.execute("""
            SELECT food_name_normalized, display_name,
                   default_serving_g, default_count
            FROM food_nutrition_overrides
            WHERE food_name_normalized = 'rice_cakes_chocolate'
        """)
        row = cur.fetchone()
        if row:
            ok_serving = row[2] == 39
            ok_count = row[3] == 3
            status = "PASS" if (ok_serving and ok_count) else "FAIL"
            print(f"  {status}: serving_g={row[2]} (expect 39), count={row[3]} (expect 3)")
        else:
            print(f"  FAIL: rice_cakes_chocolate not found!")

        # 3. Check egg
        print("\n3. Check egg (expect serving=50, count=1):")
        cur.execute("""
            SELECT food_name_normalized, display_name,
                   default_serving_g, default_count
            FROM food_nutrition_overrides
            WHERE food_name_normalized = 'egg'
        """)
        row = cur.fetchone()
        if row:
            ok_serving = row[2] == 50
            ok_count = row[3] == 1
            status = "PASS" if (ok_serving and ok_count) else "FAIL"
            print(f"  {status}: serving_g={row[2]} (expect 50), count={row[3]} (expect 1)")
        else:
            print(f"  FAIL: egg not found!")

        # 4. Check roti
        print("\n4. Check roti (expect serving=40, count=1):")
        cur.execute("""
            SELECT food_name_normalized, display_name,
                   default_serving_g, default_count
            FROM food_nutrition_overrides
            WHERE food_name_normalized = 'roti'
        """)
        row = cur.fetchone()
        if row:
            ok_serving = row[2] == 40
            ok_count = row[3] == 1
            status = "PASS" if (ok_serving and ok_count) else "FAIL"
            print(f"  {status}: serving_g={row[2]} (expect 40), count={row[3]} (expect 1)")
        else:
            print(f"  FAIL: roti not found!")

        # 5. Diagnostic: items where serving > piece weight
        print(f"\n{'='*60}")
        print("DIAGNOSTIC: Items where default_serving_g > default_weight_per_piece_g")
        print(f"{'='*60}")
        cur.execute("""
            SELECT food_name_normalized, display_name,
                   default_weight_per_piece_g, default_serving_g, default_count
            FROM food_nutrition_overrides
            WHERE default_weight_per_piece_g IS NOT NULL
              AND default_serving_g IS NOT NULL
              AND default_serving_g > default_weight_per_piece_g
        """)
        rows = cur.fetchall()
        if rows:
            print(f"  Found {len(rows)} items:")
            for row in rows:
                print(f"    {row[0]}: piece={row[2]}g, serving={row[3]}g, count={row[4]} | display: {row[1]}")
        else:
            print(f"  None found (all serving sizes <= piece weight)")

    conn.close()
    print(f"\n{'='*60}")
    print("DONE")
    return True

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
