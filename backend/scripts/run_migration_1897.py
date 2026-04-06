#!/usr/bin/env python3
"""Run migration 1897: Fix claim_daily_crate function overload.

Drops the old 2-param overload and recreates the 3-param version
without nested JSONB in the return.
"""
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


def run():
    migration_path = Path(__file__).parent.parent / "migrations" / "1897_fix_claim_daily_crate_overload.sql"
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
            # Check overloads before fix
            cur.execute("""
                SELECT p.proname, pg_get_function_arguments(p.oid)
                FROM pg_proc p
                JOIN pg_namespace n ON p.pronamespace = n.oid
                WHERE p.proname = 'claim_daily_crate' AND n.nspname = 'public';
            """)
            before = cur.fetchall()
            print(f"[1897] Before: {len(before)} overload(s) of claim_daily_crate")
            for name, args in before:
                print(f"       - {name}({args})")

            print("[1897] Running migration: fix claim_daily_crate overload...")
            cur.execute(sql)
            print("[1897] Migration complete!")

            # Verify only one function remains
            cur.execute("""
                SELECT p.proname, pg_get_function_arguments(p.oid)
                FROM pg_proc p
                JOIN pg_namespace n ON p.pronamespace = n.oid
                WHERE p.proname = 'claim_daily_crate' AND n.nspname = 'public';
            """)
            after = cur.fetchall()
            print(f"[1897] After: {len(after)} overload(s) of claim_daily_crate")
            for name, args in after:
                print(f"       - {name}({args})")

    finally:
        conn.close()


if __name__ == "__main__":
    run()
