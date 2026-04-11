#!/usr/bin/env python3
"""Run migration 1905 - Add measurement_unit column to users."""
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
    file_path = migrations_dir / "1906_add_measurement_unit.sql"

    print("Running migration 1905: Add measurement_unit column to users...")
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

        # Verify column was added
        with conn.cursor() as cur:
            cur.execute("""
                SELECT column_name, data_type, character_maximum_length
                FROM information_schema.columns
                WHERE table_name = 'users' AND column_name = 'measurement_unit'
            """)
            rows = cur.fetchall()
            if rows:
                for row in rows:
                    print(f"  SUCCESS: column='{row[0]}', type={row[1]}, max_length={row[2]}")
            else:
                print("  WARNING: 'measurement_unit' column not found after migration")

        conn.close()
        print("Done!")
    except Exception as e:
        print(f"FAILED: {e}")
        raise

if __name__ == "__main__":
    run_migration()
