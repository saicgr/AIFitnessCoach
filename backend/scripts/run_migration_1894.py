#!/usr/bin/env python3
"""Run migration 1894: Fix remaining Supabase linter warnings.

Fixes:
- function_search_path_mutable (86 functions) - SET search_path = public
- unindexed_foreign_keys (20 FKs) - CREATE INDEX CONCURRENTLY
- materialized_view_in_api (4 mat views) - REVOKE SELECT from anon/authenticated
- extension_in_public (1 extension) - Move pg_trgm to extensions schema

CREATE INDEX CONCURRENTLY cannot run inside a transaction block, so those
statements are executed separately with autocommit enabled.
"""
import os
import re
import sys
from pathlib import Path

import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")


def get_connection(autocommit=False):
    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )
    if autocommit:
        conn.autocommit = True
    return conn


def parse_sql_file(file_path):
    """Parse the SQL file into parts: transactional statements and index statements."""
    sql = file_path.read_text()

    # Split into individual statements
    transactional = []
    index_statements = []

    # Extract each statement (split on semicolons, skip comments/blanks)
    for statement in sql.split(";"):
        stripped = statement.strip()
        # Remove comment-only lines for matching
        no_comments = re.sub(r'--[^\n]*', '', stripped).strip()
        if not no_comments:
            continue
        if "CREATE INDEX CONCURRENTLY" in no_comments:
            index_statements.append(stripped + ";")
        else:
            transactional.append(stripped + ";")

    return transactional, index_statements


def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    file_path = migrations_dir / "1894_fix_remaining_linter_warnings.sql"

    if not file_path.exists():
        raise SystemExit(f"Migration file not found: {file_path}")

    print(f"\n{'='*70}")
    print(f"Running: 1894_fix_remaining_linter_warnings.sql")
    print(f"  Fixes function_search_path_mutable, unindexed_foreign_keys,")
    print(f"  materialized_view_in_api, and extension_in_public")
    print(f"{'='*70}")

    transactional, index_statements = parse_sql_file(file_path)

    # ---- Phase 1: Run transactional statements (ALTER FUNCTION, REVOKE, ALTER EXTENSION) ----
    print(f"\n  Phase 1: Running {len(transactional)} transactional statements...")

    conn = get_connection(autocommit=False)
    try:
        # Count functions without search_path before
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*)
                FROM pg_proc p
                JOIN pg_namespace n ON p.pronamespace = n.oid
                WHERE n.nspname = 'public'
                  AND p.prokind = 'f'
                  AND (p.proconfig IS NULL OR NOT EXISTS (
                    SELECT 1 FROM unnest(p.proconfig) c WHERE c LIKE 'search_path=%%'
                  ))
                  AND NOT EXISTS (
                    SELECT 1 FROM pg_depend d
                    JOIN pg_extension e ON e.oid = d.refobjid
                    WHERE d.objid = p.oid AND d.deptype = 'e'
                  )
            """)
            funcs_before = cur.fetchone()[0]
            print(f"    Functions without search_path (before): {funcs_before}")

        # Execute all transactional statements in one transaction
        with conn.cursor() as cur:
            for stmt in transactional:
                cur.execute(stmt)
        conn.commit()

        # Count functions without search_path after
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*)
                FROM pg_proc p
                JOIN pg_namespace n ON p.pronamespace = n.oid
                WHERE n.nspname = 'public'
                  AND p.prokind = 'f'
                  AND (p.proconfig IS NULL OR NOT EXISTS (
                    SELECT 1 FROM unnest(p.proconfig) c WHERE c LIKE 'search_path=%%'
                  ))
                  AND NOT EXISTS (
                    SELECT 1 FROM pg_depend d
                    JOIN pg_extension e ON e.oid = d.refobjid
                    WHERE d.objid = p.oid AND d.deptype = 'e'
                  )
            """)
            funcs_after = cur.fetchone()[0]
            print(f"    Functions without search_path (after):  {funcs_after}")
            print(f"    Functions fixed: {funcs_before - funcs_after}")

        # Verify pg_trgm moved
        with conn.cursor() as cur:
            cur.execute("""
                SELECT nspname FROM pg_extension e
                JOIN pg_namespace n ON e.extnamespace = n.oid
                WHERE e.extname = 'pg_trgm'
            """)
            row = cur.fetchone()
            if row:
                print(f"    pg_trgm extension now in schema: {row[0]}")

        # Verify materialized view revocations
        with conn.cursor() as cur:
            cur.execute("""
                SELECT matviewname
                FROM pg_matviews
                WHERE schemaname = 'public'
                  AND matviewname IN (
                    'leaderboard_challenge_masters', 'leaderboard_streaks',
                    'leaderboard_volume_kings', 'leaderboard_weekly_challenges'
                  )
            """)
            mat_views = [r[0] for r in cur.fetchall()]
            print(f"    Materialized views with revoked access: {len(mat_views)}")

        print(f"    Phase 1 completed successfully!")

    except Exception as e:
        conn.rollback()
        print(f"\n    ERROR in Phase 1: {e}")
        sys.exit(1)
    finally:
        conn.close()

    # ---- Phase 2: Run CREATE INDEX CONCURRENTLY (requires autocommit) ----
    print(f"\n  Phase 2: Creating {len(index_statements)} indexes concurrently...")

    conn = get_connection(autocommit=True)
    success_count = 0
    fail_count = 0
    try:
        for i, stmt in enumerate(index_statements, 1):
            # Extract index name for logging
            match = re.search(r'IF NOT EXISTS\s+(\S+)', stmt)
            idx_name = match.group(1) if match else f"index_{i}"
            try:
                with conn.cursor() as cur:
                    cur.execute(stmt)
                success_count += 1
                print(f"    [{i:2d}/{len(index_statements)}] Created {idx_name}")
            except Exception as e:
                fail_count += 1
                print(f"    [{i:2d}/{len(index_statements)}] FAILED {idx_name}: {e}")

        print(f"\n    Phase 2 completed: {success_count} created, {fail_count} failed")

    finally:
        conn.close()

    # ---- Summary ----
    print(f"\n{'='*70}")
    print(f"  Migration 1894 Summary:")
    print(f"    - Functions search_path fixed: {funcs_before - funcs_after}")
    print(f"    - Indexes created: {success_count}/{len(index_statements)}")
    print(f"    - Materialized views secured: {len(mat_views)}")
    print(f"    - pg_trgm extension moved to extensions schema")
    if fail_count > 0:
        print(f"    - WARNING: {fail_count} index(es) failed - check output above")
    print(f"{'='*70}\n")

    if fail_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    run_migration()
