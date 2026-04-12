#!/usr/bin/env python3
"""Run migration 1908 - Add inflammation score and ultra-processed tracking to food_logs."""
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
    file_path = migrations_dir / "1908_add_inflammation_score.sql"

    print("Running migration 1908: Add inflammation score and ultra-processed tracking to food_logs...")
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
                WHERE table_name = 'food_logs'
                  AND column_name IN ('inflammation_score', 'is_ultra_processed', 'image_url')
                ORDER BY ordinal_position
            """)
            rows = cur.fetchall()
            print(f"Verified columns: {rows}")
            if len(rows) >= 3:
                print("Migration 1908 applied successfully!")
            else:
                print(f"WARNING: Expected 3 columns, found {len(rows)}")

        conn.close()
    except Exception as e:
        print(f"Migration failed: {e}")
        raise

if __name__ == "__main__":
    run_migration()
