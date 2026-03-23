#!/usr/bin/env python3
"""Run migration 1872: Jonah's Seafood House menu nutritional data."""
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
    file_path = migrations_dir / "1872_jonahs_seafood_house.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1872_jonahs_seafood_house.sql")
    print(f"  Inserts 55 Jonah's Seafood House menu items into food_nutrition_overrides")

    try:
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"  SUCCESS - 55 items inserted/updated")
    except Exception as e:
        conn.rollback()
        print(f"  FAILED: {e}")
        conn.close()
        return False

    # Verify
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM food_nutrition_overrides WHERE restaurant_name = 'Jonah''s Seafood House'")
            count = cur.fetchone()[0]
            print(f"  Verification: {count} Jonah's Seafood House items in table")
    except Exception as e:
        print(f"  Verification query failed: {e}")

    conn.close()
    print(f"{'='*60}\n")
    return True

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
