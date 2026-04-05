#!/usr/bin/env python3
"""Run migration 1892: Fix auth_rls_initplan performance warnings.

Wraps auth.uid(), auth.role(), auth.jwt(), and current_setting() calls
in RLS policies with subselects to prevent per-row re-evaluation.

Fixes 548 Supabase linter auth_rls_initplan warnings.
"""
import os, sys, re
from pathlib import Path
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")


def count_bare_calls(conn):
    """Count policies with bare auth/current_setting calls (not wrapped in subselect)."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT policyname, tablename, qual, with_check
            FROM pg_policies
            WHERE schemaname = 'public'
        """)
        rows = cur.fetchall()

    count = 0
    for pname, tname, qual, with_check in rows:
        for col_text in [qual, with_check]:
            if col_text is None:
                continue
            for func in ['auth.uid()', 'auth.role()', 'auth.jwt()']:
                for m in re.finditer(re.escape(func), col_text):
                    prefix = col_text[max(0, m.start()-20):m.start()].lower()
                    if 'select ' not in prefix:
                        count += 1
                        break
                else:
                    continue
                break
            else:
                # Check current_setting separately
                for m in re.finditer(r'current_setting\(', col_text):
                    prefix = col_text[max(0, m.start()-20):m.start()].lower()
                    if 'select ' not in prefix:
                        count += 1
                        break
    return count


def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    file_path = migrations_dir / "1892_fix_auth_rls_initplan.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1892_fix_auth_rls_initplan.sql")
    print(f"  Wraps bare auth/current_setting calls in RLS policy subselects")
    print(f"{'='*60}")

    try:
        # Count affected policies before
        count_before = count_bare_calls(conn)
        print(f"\n  Policies with bare auth/setting calls before: {count_before}")

        # Run the migration
        sql = file_path.read_text()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()

        # Count affected policies after
        count_after = count_bare_calls(conn)
        print(f"  Policies with bare auth/setting calls after:  {count_after}")
        print(f"  Policies fixed: {count_before - count_after}")

        print(f"\n  Migration completed successfully!")

    except Exception as e:
        conn.rollback()
        print(f"\n  ERROR: {e}")
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    run_migration()
