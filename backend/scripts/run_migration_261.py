#!/usr/bin/env python3
"""
Run migration 261 - Fix batch_lookup_foods timeout.

Also re-runs food_database_rpc.sql to update the source-of-truth function definition.

Changes:
  - Adds SET LOCAL statement_timeout = '5000' (5s max) to batch_lookup_foods
  - Removes slow ILIKE fallbacks that bypass GIN trigram indexes
  - Simplifies ORDER BY to use similarity() only
"""

import sys
from pathlib import Path

import psycopg2


# Database connection (Supabase PostgreSQL)
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def run_migration():
    """Execute migration 261 and updated food_database_rpc.sql."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    migration_files = [
        "food_database_rpc.sql",
        "261_fix_food_batch_lookup_timeout.sql",
    ]

    print("=" * 60)
    print("MIGRATION 261: Fix batch_lookup_foods Timeout")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Adds 5s statement_timeout to batch_lookup_foods")
    print("  - Removes ILIKE fallbacks that cause sequential scans")
    print("  - Simplifies ORDER BY to use trigram similarity only")
    print()
    print("Connecting to database...")

    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST,
            port=DATABASE_PORT,
            dbname=DATABASE_NAME,
            user=DATABASE_USER,
            password=DATABASE_PASSWORD,
            sslmode="require"
        )
        print("Connected successfully!")

        for migration_file in migration_files:
            file_path = migrations_dir / migration_file

            if not file_path.exists():
                print(f"\nERROR: Migration file not found: {file_path}")
                return False

            print(f"\n{'=' * 60}")
            print(f"Running: {migration_file}")
            print("=" * 60)

            with open(file_path, 'r') as f:
                sql_content = f.read()

            try:
                with conn.cursor() as cur:
                    cur.execute(sql_content)
                conn.commit()
                print(f"SUCCESS: {migration_file} completed!")
            except Exception as e:
                print(f"ERROR in {migration_file}: {e}")
                conn.rollback()
                return False

        # Verify the function exists and has been updated
        print("\n" + "=" * 60)
        print("Verifying migration...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Check batch_lookup_foods function exists
            cur.execute("""
                SELECT routine_name, routine_type
                FROM information_schema.routines
                WHERE routine_name IN ('batch_lookup_foods', 'search_food_database')
                  AND routine_schema = 'public'
                ORDER BY routine_name
            """)
            rows = cur.fetchall()
            print(f"\n  Functions found ({len(rows)}):")
            for name, rtype in rows:
                print(f"    {name}: {rtype}")

            # Verify batch_lookup_foods contains statement_timeout
            cur.execute("""
                SELECT prosrc
                FROM pg_proc
                WHERE proname = 'batch_lookup_foods'
            """)
            src = cur.fetchone()
            if src and 'statement_timeout' in src[0]:
                print("\n  batch_lookup_foods has statement_timeout: YES")
            else:
                print("\n  WARNING: statement_timeout not found in batch_lookup_foods")

            # Verify ILIKE is removed from batch_lookup_foods
            if src and 'ILIKE' not in src[0]:
                print("  ILIKE fallbacks removed: YES")
            else:
                print("  WARNING: ILIKE still present in batch_lookup_foods")

            # Quick functional test - call batch_lookup_foods with a test input
            print("\n  Running functional test...")
            try:
                cur.execute("SELECT * FROM batch_lookup_foods(ARRAY['rice', 'chicken'])")
                test_rows = cur.fetchall()
                print(f"  Functional test: batch_lookup_foods returned {len(test_rows)} rows")
                for row in test_rows:
                    print(f"    Input: {row[0]} -> Match: {row[2]} (sim: {row[9]:.3f})" if row[2] else f"    Input: {row[0]} -> No match")
            except Exception as e:
                print(f"  Functional test failed: {e}")
                conn.rollback()

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 261 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
