#!/usr/bin/env python3
"""Run migration 1891: Enable RLS on all 332 public tables.

Fixes Supabase linter errors:
- policy_exists_rls_disabled (332 tables have policies but RLS not enabled)
- rls_disabled_in_public (same 332 tables)
- sensitive_columns_exposed (14 tables with session_id columns, subset of above)

All tables already have RLS policies defined — this just flips the switch.
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


def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    file_path = migrations_dir / "1891_enable_rls_all_tables.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1891_enable_rls_all_tables.sql")
    print(f"  Enables RLS on 332 tables that have policies but RLS disabled")
    print(f"{'='*60}")

    try:
        # Count tables without RLS before
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*)
                FROM pg_tables
                WHERE schemaname = 'public'
                  AND tablename NOT LIKE 'pg_%'
                  AND tablename NOT IN (
                    SELECT tablename FROM pg_tables t
                    JOIN pg_class c ON c.relname = t.tablename
                    WHERE t.schemaname = 'public' AND c.relrowsecurity = true
                  )
            """)
            count_before = cur.fetchone()[0]
            print(f"\n  Tables without RLS before: {count_before}")

        # Run the migration
        sql = file_path.read_text()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()

        # Count tables without RLS after
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*)
                FROM pg_tables
                WHERE schemaname = 'public'
                  AND tablename NOT LIKE 'pg_%'
                  AND tablename NOT IN (
                    SELECT tablename FROM pg_tables t
                    JOIN pg_class c ON c.relname = t.tablename
                    WHERE t.schemaname = 'public' AND c.relrowsecurity = true
                  )
            """)
            count_after = cur.fetchone()[0]
            print(f"  Tables without RLS after:  {count_after}")
            print(f"  Tables fixed: {count_before - count_after}")

        print(f"\n  Migration completed successfully!")

    except Exception as e:
        conn.rollback()
        print(f"\n  ERROR: {e}")
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    run_migration()
