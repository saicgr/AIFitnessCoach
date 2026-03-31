#!/usr/bin/env python3
"""Run migration 1889: Add mood/wellness columns to food_logs table."""
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
    file_path = migrations_dir / "1889_add_food_log_mood_columns.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1889_add_food_log_mood_columns.sql")
    print(f"{'='*60}")

    try:
        with conn.cursor() as cur:
            sql = file_path.read_text()
            cur.execute(sql)
            conn.commit()
            print("Migration 1889 completed successfully!")

            # Verify columns exist
            cur.execute("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'food_logs'
                AND column_name IN ('mood_before', 'mood_after', 'energy_level')
                ORDER BY column_name;
            """)
            cols = cur.fetchall()
            print(f"\nVerification - new columns on food_logs:")
            for col_name, col_type in cols:
                print(f"  {col_name}: {col_type}")
            if len(cols) == 3:
                print("\nAll 3 columns added successfully!")
            else:
                print(f"\nWARNING: Expected 3 columns, found {len(cols)}")
    except Exception as e:
        conn.rollback()
        print(f"ERROR: {e}")
        sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    run_migration()
