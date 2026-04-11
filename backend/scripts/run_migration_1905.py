#!/usr/bin/env python3
"""Run migration 1905 - Chipotle standard menu overrides."""
import os
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
    file_path = migrations_dir / "1905_chipotle_standard_menu_overrides.sql"

    print("Running migration 1905: Chipotle standard menu overrides...")
    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
            user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
        )
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()

        # Verify items were inserted
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*) FROM food_nutrition_overrides
                WHERE restaurant_name = 'Chipotle'
            """)
            count = cur.fetchone()[0]
            print(f"  SUCCESS: {count} Chipotle menu items in food_nutrition_overrides")

        conn.close()
        print("Done!")
    except Exception as e:
        print(f"FAILED: {e}")
        raise

if __name__ == "__main__":
    run_migration()
