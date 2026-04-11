#!/usr/bin/env python3
"""Run migration 1907 - Add traceability columns to food_reports."""
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
    file_path = migrations_dir / "1907_food_reports_traceability.sql"

    print("Running migration 1907: Add traceability columns to food_reports...")
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

        # Verify columns were added
        with conn.cursor() as cur:
            cur.execute("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'food_reports'
                  AND column_name IN ('report_type', 'original_query', 'analysis_response', 'all_food_items')
                ORDER BY ordinal_position
            """)
            rows = cur.fetchall()
            if rows:
                for row in rows:
                    print(f"  SUCCESS: column='{row[0]}', type={row[1]}")
            else:
                print("  WARNING: traceability columns not found after migration")

        conn.close()
        print("Done!")
    except Exception as e:
        print(f"FAILED: {e}")
        raise

if __name__ == "__main__":
    run_migration()
