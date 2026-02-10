#!/usr/bin/env python3
"""
Run migration 226 - Scope staple exercises to gym profiles.

Adds gym_profile_id column to staple_exercises, updates unique index,
and recreates the user_staples_with_details view with profile info.
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
    """Execute migration 226."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "226_staple_gym_profile.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 226: Scope Staple Exercises to Gym Profiles")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Adds gym_profile_id column to staple_exercises")
    print("  - Creates index for profile-scoped queries")
    print("  - Updates unique constraint for profile-aware dedup")
    print("  - Recreates user_staples_with_details view with profile info")
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

        # Verify changes
        print("\n" + "=" * 60)
        print("Verifying migration...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Check column exists
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.columns
                    WHERE table_schema = 'public'
                    AND table_name = 'staple_exercises'
                    AND column_name = 'gym_profile_id'
                )
            """)
            exists = cur.fetchone()[0]
            print(f"\n  Column 'gym_profile_id' exists: {exists}")

            # Check indexes
            cur.execute("""
                SELECT indexname FROM pg_indexes
                WHERE tablename = 'staple_exercises'
                ORDER BY indexname
            """)
            indexes = cur.fetchall()
            print(f"\n  Indexes on staple_exercises:")
            for idx in indexes:
                print(f"    - {idx[0]}")

            # Check view exists
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.views
                    WHERE table_schema = 'public'
                    AND table_name = 'user_staples_with_details'
                )
            """)
            view_exists = cur.fetchone()[0]
            print(f"\n  View 'user_staples_with_details' exists: {view_exists}")

            # Check view columns
            cur.execute("""
                SELECT column_name FROM information_schema.columns
                WHERE table_schema = 'public'
                AND table_name = 'user_staples_with_details'
                ORDER BY ordinal_position
            """)
            columns = cur.fetchall()
            print(f"\n  View columns:")
            for col in columns:
                print(f"    - {col[0]}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 226 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
