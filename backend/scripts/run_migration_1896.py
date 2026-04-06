#!/usr/bin/env python3
"""Run migration 1896: Unclaimed crates accumulation.

Adds get_unclaimed_crates() function and updates claim_daily_crate()
to accept a date parameter so past unclaimed crates can be claimed.
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


def run():
    migration_path = Path(__file__).parent.parent / "migrations" / "1896_unclaimed_crates_accumulation.sql"
    sql = migration_path.read_text()

    conn = psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
    )
    conn.autocommit = True

    try:
        with conn.cursor() as cur:
            print("[1896] Running migration: unclaimed crates accumulation...")
            cur.execute(sql)
            print("[1896] Migration complete!")

            # Verify functions exist
            cur.execute("""
                SELECT routine_name FROM information_schema.routines
                WHERE routine_name IN ('get_unclaimed_crates', 'claim_daily_crate')
                AND routine_schema = 'public'
                ORDER BY routine_name;
            """)
            functions = [row[0] for row in cur.fetchall()]
            print(f"[1896] Verified functions: {functions}")

    finally:
        conn.close()


if __name__ == "__main__":
    run()
