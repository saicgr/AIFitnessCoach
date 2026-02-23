#!/usr/bin/env python3
"""
Run migration 225 - Create schedule_items table for Daily Schedule Planner.

Creates the schedule_items table with indexes, updated_at trigger, and RLS policies.
This fixes the 500 error on the Schedule screen's timeline view.
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
    """Execute migration 225."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "225_daily_schedule.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 225: Create schedule_items Table")
    print("=" * 60)
    print()
    print("This migration creates:")
    print("  - schedule_items table")
    print("  - Indexes for user+date, user+status, date+time")
    print("  - updated_at trigger")
    print("  - RLS policies (select, insert, update, delete)")
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

        # Verify table was created
        print("\n" + "=" * 60)
        print("Verifying table and policies...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Check table exists
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_schema = 'public'
                    AND table_name = 'schedule_items'
                )
            """)
            exists = cur.fetchone()[0]
            print(f"\n  Table 'schedule_items' exists: {exists}")

            # Check column count
            cur.execute("""
                SELECT count(*) FROM information_schema.columns
                WHERE table_schema = 'public'
                AND table_name = 'schedule_items'
            """)
            col_count = cur.fetchone()[0]
            print(f"  Column count: {col_count}")

            # Check indexes
            cur.execute("""
                SELECT indexname FROM pg_indexes
                WHERE tablename = 'schedule_items'
                ORDER BY indexname
            """)
            indexes = cur.fetchall()
            print(f"\n  Indexes:")
            for idx in indexes:
                print(f"    - {idx[0]}")

            # Check RLS policies
            cur.execute("""
                SELECT policyname FROM pg_policies
                WHERE tablename = 'schedule_items'
                ORDER BY policyname
            """)
            policies = cur.fetchall()
            print(f"\n  RLS Policies:")
            for p in policies:
                print(f"    - {p[0]}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 225 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
