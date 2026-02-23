#!/usr/bin/env python3
"""
Run migration 234 - Comprehensive warmup/stretch exercises.

Adds ~140 exercises across 12 categories:
  Treadmill, Stepper, Bike, Elliptical, Rowing, Bar Hangs, Jump Rope,
  Dynamic Warmups, Static Stretches, Foam Roller, Mobility Drills, Yoga.

Also recreates stretch/warmup/combined views to include new exercises.
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
    """Execute migration 234."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "234_comprehensive_warmups_stretches.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 234: Comprehensive Warmup/Stretch Exercises")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Adds ~140 exercises across 12 categories")
    print("  - Treadmill, Stepper, Bike, Elliptical, Rowing")
    print("  - Bar Hangs, Jump Rope, Dynamic Warmups")
    print("  - Static Stretches, Foam Roller, Mobility, Yoga")
    print("  - Recreates stretch/warmup/combined views")
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
            # Count exercises by category
            cur.execute("""
                SELECT category, COUNT(*)
                FROM exercise_library
                WHERE category IN ('cardio', 'warmup', 'stretching', 'mobility', 'yoga', 'strength')
                GROUP BY category
                ORDER BY category
            """)
            rows = cur.fetchall()
            print("\n  Exercises by category:")
            total = 0
            for cat, cnt in rows:
                print(f"    {cat}: {cnt}")
                total += cnt
            print(f"    TOTAL: {total}")

            # Count exercises by equipment for new categories
            cur.execute("""
                SELECT equipment, COUNT(*)
                FROM exercise_library
                WHERE category IN ('warmup', 'stretching', 'mobility', 'yoga')
                   OR (category = 'cardio' AND equipment IN ('treadmill', 'stair_climber', 'stationary_bike', 'elliptical', 'rowing_machine', 'jump_rope'))
                   OR (category = 'strength' AND equipment = 'pull_up_bar')
                GROUP BY equipment
                ORDER BY equipment
            """)
            rows = cur.fetchall()
            print("\n  Exercises by equipment (new categories):")
            for equip, cnt in rows:
                print(f"    {equip}: {cnt}")

            # Count timed exercises
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE is_timed = TRUE
            """)
            timed_count = cur.fetchone()[0]
            print(f"\n  Timed exercises (is_timed=TRUE): {timed_count}")

            # Check views exist
            for view_name in ['stretch_exercises_cleaned', 'warmup_exercises_cleaned', 'warmup_stretch_exercises']:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.views
                        WHERE table_schema = 'public'
                        AND table_name = %s
                    )
                """, (view_name,))
                exists = cur.fetchone()[0]
                print(f"\n  View '{view_name}' exists: {exists}")

                if exists:
                    cur.execute(f"SELECT COUNT(*) FROM {view_name}")
                    cnt = cur.fetchone()[0]
                    print(f"  View '{view_name}' row count: {cnt}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 234 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
