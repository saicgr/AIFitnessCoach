#!/usr/bin/env python3
"""Run migration 1899: Add set timing columns to performance_logs.

Adds set_duration_seconds and rest_duration_seconds columns to track
how long each set takes and actual rest taken before each set.
"""
import os
import sys

import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")

SQL = """
ALTER TABLE performance_logs
  ADD COLUMN IF NOT EXISTS set_duration_seconds INTEGER,
  ADD COLUMN IF NOT EXISTS rest_duration_seconds INTEGER;

COMMENT ON COLUMN performance_logs.set_duration_seconds IS 'Time in seconds from set start to completion';
COMMENT ON COLUMN performance_logs.rest_duration_seconds IS 'Actual rest taken before this set (null for first set)';
"""

def main():
    print(f"Connecting to {DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}...")
    conn = psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
        sslmode="require",
    )
    try:
        conn.autocommit = True
        with conn.cursor() as cur:
            print("Running migration 1899: Add set timing columns...")
            cur.execute(SQL)
            print("Migration 1899 applied successfully.")

            # Verify columns exist
            cur.execute("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'performance_logs'
                  AND column_name IN ('set_duration_seconds', 'rest_duration_seconds')
                ORDER BY column_name;
            """)
            rows = cur.fetchall()
            for col, dtype in rows:
                print(f"  Verified: {col} ({dtype})")
            if len(rows) != 2:
                print("WARNING: Expected 2 columns, found", len(rows))
                sys.exit(1)
            print("All columns verified.")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
