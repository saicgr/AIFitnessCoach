#!/usr/bin/env python3
"""
Run migration 237 - Add section column to staple_exercises and
recreate views with exercise metadata columns.

Changes:
  1. Add `section` column (main/warmup/stretches) to staple_exercises
  2. Update unique index to include section
  3. Recreate user_staples_with_details view with section + metadata
  4. Recreate exercise_library_cleaned view with 22 metadata columns

Depends on migration 235 (adds metadata columns) and 236 (backfills them).
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
    """Execute migration 237."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "237_staple_section_and_library_view.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 237: Staple Section + Library View Metadata")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Adds `section` column to staple_exercises (main/warmup/stretches)")
    print("  - Updates unique index to include section")
    print("  - Recreates user_staples_with_details view with section + metadata")
    print("  - Recreates exercise_library_cleaned view with 22 metadata columns")
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
            # Verify section column exists
            cur.execute("""
                SELECT column_name, data_type, column_default
                FROM information_schema.columns
                WHERE table_name = 'staple_exercises' AND column_name = 'section'
            """)
            row = cur.fetchone()
            if row:
                print(f"\n  section column: type={row[1]}, default={row[2]}")
            else:
                print("\n  WARNING: section column not found!")

            # Verify constraint
            cur.execute("""
                SELECT conname FROM pg_constraint
                WHERE conname = 'check_staple_section'
            """)
            row = cur.fetchone()
            print(f"  check_staple_section constraint: {'EXISTS' if row else 'MISSING'}")

            # Verify unique index
            cur.execute("""
                SELECT indexname FROM pg_indexes
                WHERE indexname = 'idx_staple_exercises_unique'
            """)
            row = cur.fetchone()
            print(f"  idx_staple_exercises_unique index: {'EXISTS' if row else 'MISSING'}")

            # Verify user_staples_with_details view has section column
            cur.execute("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = 'user_staples_with_details' AND column_name = 'section'
            """)
            row = cur.fetchone()
            print(f"  user_staples_with_details.section: {'EXISTS' if row else 'MISSING'}")

            # Verify exercise_library_cleaned view has metadata columns
            cur.execute("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = 'exercise_library_cleaned'
                  AND column_name IN ('movement_pattern', 'default_incline_percent', 'form_complexity')
                ORDER BY column_name
            """)
            rows = cur.fetchall()
            print(f"  exercise_library_cleaned metadata columns: {[r[0] for r in rows]}")

            # Count exercises in cleaned view
            cur.execute("SELECT COUNT(*) FROM exercise_library_cleaned")
            count = cur.fetchone()[0]
            print(f"  exercise_library_cleaned total exercises: {count}")

            # Sample exercise with metadata
            cur.execute("""
                SELECT name, equipment, movement_pattern, default_incline_percent, default_speed_mph
                FROM exercise_library_cleaned
                WHERE default_incline_percent IS NOT NULL
                LIMIT 5
            """)
            rows = cur.fetchall()
            print("\n  Sample exercises with cardio metadata:")
            for name, equip, mp, incline, speed in rows:
                print(f"    {name}: equipment={equip}, pattern={mp}, incline={incline}%, speed={speed}mph")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 237 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
