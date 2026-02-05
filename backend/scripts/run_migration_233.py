#!/usr/bin/env python3
"""
Run migration 233 - Fix Hormonal Health Tables RLS Policies.

Updates RLS policies on hormonal_profiles, hormone_logs, kegel_preferences,
and kegel_sessions tables to allow backend server-side access.

Changes:
- Adds ((select auth.uid()) IS NULL) condition to allow server-side calls
- Adds ((select auth.role()) = 'service_role') condition for service role access
- Following the same pattern as migration 112 (users table fix)
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
    """Execute migration 233."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "233_fix_hormonal_health_rls.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 233: Fix Hormonal Health Tables RLS Policies")
    print("=" * 60)
    print()
    print("This migration updates RLS policies on:")
    print("  - hormonal_profiles")
    print("  - hormone_logs")
    print("  - kegel_preferences")
    print("  - kegel_sessions")
    print()
    print("Changes:")
    print("  - Adds auth.uid() IS NULL condition for server-side calls")
    print("  - Adds service_role bypass condition")
    print("  - Fixes 406 Not Acceptable errors from backend")
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

        # Verify policies were updated
        print("\n" + "=" * 60)
        print("Verifying updated policies...")
        print("=" * 60)

        tables = ['hormonal_profiles', 'hormone_logs', 'kegel_preferences', 'kegel_sessions']

        with conn.cursor() as cur:
            for table in tables:
                cur.execute("""
                    SELECT policyname FROM pg_policies
                    WHERE tablename = %s
                    ORDER BY policyname
                """, (table,))
                policies = cur.fetchall()
                policy_names = [p[0] for p in policies]
                print(f"\n  {table}:")
                for name in policy_names:
                    print(f"    - {name}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 233 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
