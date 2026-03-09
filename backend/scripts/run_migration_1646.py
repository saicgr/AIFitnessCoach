#!/usr/bin/env python3
"""Run migration 1646: Add region column to food_nutrition_overrides."""
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
    file_path = migrations_dir / "1646_add_region_column.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1646_add_region_column.sql")
    print(f"  Adds region TEXT column + partial index to food_nutrition_overrides")

    try:
        with open(file_path, 'r') as f:
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

    # Verification
    print(f"\n{'='*60}")
    print("VERIFICATION")
    print(f"{'='*60}")

    with conn.cursor() as cur:
        cur.execute("""
            SELECT column_name, data_type FROM information_schema.columns
            WHERE table_name = 'food_nutrition_overrides' AND column_name = 'region'
        """)
        col = cur.fetchone()
        print(f"\n  Column 'region' exists: {col is not None}")
        if col:
            print(f"  Data type: {col[1]}")

        cur.execute("""
            SELECT indexname FROM pg_indexes
            WHERE tablename = 'food_nutrition_overrides' AND indexname = 'idx_food_overrides_region'
        """)
        idx = cur.fetchone()
        print(f"  Index 'idx_food_overrides_region' exists: {idx is not None}")

    conn.close()
    print(f"\n{'='*60}")
    print("DONE")
    return True

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
