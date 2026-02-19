#!/usr/bin/env python3
"""
Run migration 261 - Fix search_food_database statement timeout.

Re-runs food_database_rpc.sql (source of truth) + 261 migration.

Changes:
  - Removes ILIKE '%query%' fallbacks that bypass GIN trigram indexes
  - Queries base table with is_primary = TRUE instead of view
  - Lowers trigram threshold to 0.1 for better typo coverage
  - Adds SET statement_timeout = '8000' (8s max) to search_food_database
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection (Supabase PostgreSQL)
DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD", "d2nHU5oLZ1GCz63B")


def run_migration():
    """Execute migration 261 and updated food_database_rpc.sql."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    migration_files = [
        "food_database_rpc.sql",
        "261_fix_food_search_timeout.sql",
    ]

    print("=" * 60)
    print("MIGRATION 261: Fix search_food_database Timeout")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Removes ILIKE fallbacks that cause sequential scans")
    print("  - Queries base table with is_primary filter")
    print("  - Lowers trigram threshold to 0.1 for typo coverage")
    print("  - Adds 8s statement_timeout to search_food_database")
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

        # Verify the function has been updated
        print("\n" + "=" * 60)
        print("Verifying migration...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Check search_food_database function source
            cur.execute("""
                SELECT prosrc
                FROM pg_proc
                WHERE proname = 'search_food_database'
            """)
            src = cur.fetchone()
            if src:
                has_ilike = 'ILIKE' in src[0]
                has_is_primary = 'is_primary' in src[0]
                has_threshold_01 = "0.1" in src[0]
                print(f"\n  search_food_database:")
                print(f"    ILIKE removed:     {'YES' if not has_ilike else 'NO (WARNING)'}")
                print(f"    is_primary filter: {'YES' if has_is_primary else 'NO (WARNING)'}")
                print(f"    Threshold 0.1:     {'YES' if has_threshold_01 else 'NO (WARNING)'}")

            # Quick functional test
            print("\n  Running functional test...")
            try:
                cur.execute("SELECT * FROM search_food_database('apple', 5, 0)")
                test_rows = cur.fetchall()
                print(f"  search_food_database('apple') returned {len(test_rows)} rows")
                for row in test_rows:
                    print(f"    {row[1]} ({row[2]}) - {row[5]} cal/100g, sim={row[13]:.3f}")
            except Exception as e:
                print(f"  Functional test failed: {e}")
                conn.rollback()

            # Test typo query that was timing out
            print()
            try:
                cur.execute("SELECT * FROM search_food_database('applw', 5, 0)")
                test_rows = cur.fetchall()
                print(f"  search_food_database('applw') returned {len(test_rows)} rows")
                for row in test_rows:
                    print(f"    {row[1]} ({row[2]}) - {row[5]} cal/100g, sim={row[13]:.3f}")
            except Exception as e:
                print(f"  Typo test failed: {e}")
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
