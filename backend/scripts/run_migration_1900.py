#!/usr/bin/env python3
"""Run migration 1900 - Fix body_measurements RLS policies."""
import os
from pathlib import Path
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")

def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    file_path = migrations_dir / "1900_fix_body_measurements_rls.sql"

    print("Running migration 1900: Fix body_measurements RLS policies...")
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
        print("SUCCESS: body_measurements RLS policies updated")

        # Verify
        with conn.cursor() as cur:
            cur.execute("""
                SELECT policyname, cmd
                FROM pg_policies
                WHERE tablename = 'body_measurements'
                ORDER BY policyname
            """)
            print("\nCurrent policies:")
            for row in cur.fetchall():
                print(f"  {row[0]} ({row[1]})")

        conn.close()
    except Exception as e:
        print(f"FAILED: {e}")
        raise

if __name__ == "__main__":
    run_migration()
