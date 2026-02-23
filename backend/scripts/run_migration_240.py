#!/usr/bin/env python3
"""
Run migration 240 - Fix fuzzy search to also search equipment column.

Changes:
  - Updates fuzzy_search_exercises_api to search equipment column
  - Returns all columns from exercise_library_cleaned (SETOF)
  - Adds trigram index on equipment column
  - Fixes: "treadmill" search now finds exercises with equipment='treadmill'
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
    """Execute migration 240."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "240_fix_fuzzy_search_equipment.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 240: Fix Fuzzy Search Equipment")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Updates fuzzy search to also search equipment column")
    print("  - Returns all columns from exercise_library_cleaned")
    print("  - Adds trigram index on equipment for fast fuzzy search")
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
            # Test fuzzy search for "treadmill"
            cur.execute("""
                SELECT name, equipment
                FROM fuzzy_search_exercises('treadmill', 10)
            """)
            rows = cur.fetchall()
            print(f"\n  fuzzy_search_exercises('treadmill'): {len(rows)} results")
            for name, equip in rows[:5]:
                print(f"    - {name} (equipment: {equip})")

            # Test fuzzy search API for "treadmill"
            cur.execute("""
                SELECT name, equipment
                FROM fuzzy_search_exercises_api('treadmill', NULL, NULL, 10)
            """)
            rows = cur.fetchall()
            print(f"\n  fuzzy_search_exercises_api('treadmill'): {len(rows)} results")
            for name, equip in rows[:5]:
                print(f"    - {name} (equipment: {equip})")

            # Test typo tolerance
            cur.execute("""
                SELECT name, equipment
                FROM fuzzy_search_exercises('threadmill', 5)
            """)
            rows = cur.fetchall()
            print(f"\n  fuzzy_search_exercises('threadmill') [typo test]: {len(rows)} results")
            for name, equip in rows[:3]:
                print(f"    - {name} (equipment: {equip})")

            # Check equipment trigram index
            cur.execute("""
                SELECT indexname FROM pg_indexes
                WHERE indexname = 'idx_exercise_library_equipment_trgm'
            """)
            row = cur.fetchone()
            print(f"\n  Equipment trigram index: {'EXISTS' if row else 'MISSING'}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 240 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
