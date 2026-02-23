#!/usr/bin/env python3
"""
Run migration 221 - Dynamic Checkpoint Targets.

Updates checkpoint progress functions to use dynamic targets based on
each user's selected workout days per week.
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection (Supabase PostgreSQL)
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


def run_migration():
    """Execute migration 221."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "221_dynamic_checkpoint_targets.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 221: Dynamic Checkpoint Targets")
    print("=" * 60)
    print()
    print("This migration updates checkpoint functions to use dynamic")
    print("targets based on user's days_per_week setting:")
    print("  - Weekly target = days_per_week")
    print("  - Monthly target = CEIL(days_per_week * 4.3)")
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

        if not file_path.exists():
            print(f"\nERROR: Migration file not found: {file_path}")
            return False

        print(f"\n{'=' * 60}")
        print(f"Running migration: {migration_file}")
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

        # Verify functions were updated
        print("\n" + "=" * 60)
        print("Verifying updated functions...")
        print("=" * 60)

        functions_to_check = [
            "get_user_days_per_week",
            "init_user_checkpoint_progress",
            "increment_checkpoint_workout",
        ]

        with conn.cursor() as cur:
            for func in functions_to_check:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM pg_proc
                        WHERE proname = %s
                    )
                """, (func,))
                exists = cur.fetchone()[0]
                status = "YES" if exists else "NO"
                print(f"  {status} - {func}()")

        # Test the new helper function
        print("\n" + "=" * 60)
        print("Testing get_user_days_per_week function...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Get a sample user to test
            cur.execute("SELECT id, preferences FROM users LIMIT 1")
            result = cur.fetchone()
            if result:
                user_id, prefs = result
                print(f"  Sample user ID: {user_id}")
                print(f"  Preferences: {prefs}")

                # Test the function
                cur.execute("SELECT get_user_days_per_week(%s)", (user_id,))
                days = cur.fetchone()[0]
                print(f"  Calculated days_per_week: {days}")
                print(f"  Weekly target would be: {days}")
                print(f"  Monthly target would be: {int(days * 4.3 + 0.99)}")  # CEIL approximation
            else:
                print("  No users found to test")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 221 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
