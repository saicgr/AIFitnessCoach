#!/usr/bin/env python3
"""Run migration 1890: Add 32 generic food entries to food_nutrition_overrides.

These are common foods missing generic (region=NULL) entries, causing wrong fuzzy matches.
Uses ON CONFLICT to upsert: inserts new entries, updates existing ones with corrected values.
"""
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
    file_path = migrations_dir / "1890_add_generic_food_overrides.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1890_add_generic_food_overrides.sql")
    print(f"  Adds/updates 32 generic food entries (region=NULL)")
    print(f"{'='*60}")

    try:
        with conn.cursor() as cur:
            # Count before
            cur.execute("SELECT COUNT(*) FROM food_nutrition_overrides WHERE region IS NULL AND is_active = TRUE")
            count_before = cur.fetchone()[0]
            print(f"\n  Generic active entries before: {count_before}")

            sql = file_path.read_text()
            cur.execute(sql)
            conn.commit()

            # Count after
            cur.execute("SELECT COUNT(*) FROM food_nutrition_overrides WHERE region IS NULL AND is_active = TRUE")
            count_after = cur.fetchone()[0]
            print(f"  Generic active entries after:  {count_after}")
            print(f"  Net new entries: {count_after - count_before}")

            # Verify a sample of the inserted/updated foods
            sample_foods = [
                'coffee_black', 'ham_deli', 'pork_sausage', 'yellow_mustard',
                'flour_tortilla', 'corn_salsa', 'tuna_canned', 'bell_pepper'
            ]
            print(f"\n  Verification (sample of 8):")
            for food in sample_foods:
                cur.execute(
                    "SELECT display_name, calories_per_100g, source FROM food_nutrition_overrides "
                    "WHERE food_name_normalized = %s AND region IS NULL",
                    (food,)
                )
                row = cur.fetchone()
                if row:
                    print(f"    {food:25s} -> {row[0]:35s} {row[1]:>6.0f} cal/100g  src={row[2]}")
                else:
                    print(f"    {food:25s} -> MISSING!")

            print(f"\n  Migration 1890 completed successfully!")

    except Exception as e:
        conn.rollback()
        print(f"\n  ERROR: {e}")
        sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    run_migration()
