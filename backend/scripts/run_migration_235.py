#!/usr/bin/env python3
"""
Run migration 235 - Exercise metadata columns.

Adds 22 new metadata columns to exercise_library and backfills
all ~140 exercises from migration 234 and ~25 exercises from migration 203.

Columns added:
  Movement Classification: movement_pattern, mechanic_type, force_type,
                           plane_of_motion, energy_system
  Training Parameters:     default_duration_seconds, default_rep_range_min,
                           default_rep_range_max, default_rest_seconds, default_tempo
  Cardio Machine:          default_incline_percent, default_speed_mph,
                           default_resistance_level, default_rpm, stroke_rate_spm
  Safety & Classification: contraindicated_conditions, impact_level,
                           form_complexity, stability_requirement
  Stretch/Yoga Specific:   is_dynamic_stretch, hold_seconds_min, hold_seconds_max
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
    """Execute migration 235."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "235_exercise_metadata_columns.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 235: Exercise Metadata Columns")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Adds 22 new metadata columns to exercise_library")
    print("  - Backfills ~140 exercises from migration 234")
    print("  - Backfills ~25 exercises from migration 203")
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
            # 1. Check all 22 new columns exist
            expected_columns = [
                'movement_pattern', 'mechanic_type', 'force_type',
                'plane_of_motion', 'energy_system',
                'default_duration_seconds', 'default_rep_range_min',
                'default_rep_range_max', 'default_rest_seconds', 'default_tempo',
                'default_incline_percent', 'default_speed_mph',
                'default_resistance_level', 'default_rpm', 'stroke_rate_spm',
                'contraindicated_conditions', 'impact_level',
                'form_complexity', 'stability_requirement',
                'is_dynamic_stretch', 'hold_seconds_min', 'hold_seconds_max',
            ]
            print("\n  Checking columns exist:")
            for col in expected_columns:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_schema = 'public'
                          AND table_name = 'exercise_library'
                          AND column_name = %s
                    )
                """, (col,))
                exists = cur.fetchone()[0]
                status = "OK" if exists else "MISSING"
                print(f"    {col}: {status}")

            # 2. Count exercises with movement_pattern filled
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE movement_pattern IS NOT NULL
            """)
            filled_count = cur.fetchone()[0]
            print(f"\n  Exercises with movement_pattern filled: {filled_count}")

            # 3. Count by movement_pattern
            cur.execute("""
                SELECT movement_pattern, COUNT(*)
                FROM exercise_library
                WHERE movement_pattern IS NOT NULL
                GROUP BY movement_pattern
                ORDER BY COUNT(*) DESC
            """)
            rows = cur.fetchall()
            print("\n  Exercises by movement_pattern:")
            for pattern, cnt in rows:
                print(f"    {pattern}: {cnt}")

            # 4. Count by impact_level
            cur.execute("""
                SELECT impact_level, COUNT(*)
                FROM exercise_library
                WHERE impact_level IS NOT NULL
                GROUP BY impact_level
                ORDER BY COUNT(*) DESC
            """)
            rows = cur.fetchall()
            print("\n  Exercises by impact_level:")
            for level, cnt in rows:
                print(f"    {level}: {cnt}")

            # 5. Sample some exercises to verify values
            print("\n  Sample exercise verification:")

            sample_exercises = [
                ('Treadmill Steep Incline Walk', 'locomotion', 'low_impact', 12.5),
                ('Dead Hang', 'static_hold', 'zero_impact', None),
                ('A-Skip', 'locomotion', 'low_impact', None),
                ('Standing Hamstring Stretch', 'static_hold', 'zero_impact', None),
                ('Foam Roll IT Band', 'static_hold', 'zero_impact', None),
                ('Treadmill Walk', 'locomotion', 'low_impact', 0.0),
                ('Rowing Machine Easy', 'locomotion', 'zero_impact', None),
                ('Sled Push', 'push', 'zero_impact', None),
            ]

            for name, exp_pattern, exp_impact, exp_incline in sample_exercises:
                cur.execute("""
                    SELECT movement_pattern, impact_level, default_incline_percent
                    FROM exercise_library
                    WHERE lower(exercise_name) = lower(%s)
                """, (name,))
                row = cur.fetchone()
                if row:
                    actual_pattern, actual_impact, actual_incline = row
                    pattern_ok = actual_pattern == exp_pattern
                    impact_ok = actual_impact == exp_impact
                    incline_ok = (exp_incline is None) or (actual_incline is not None and float(actual_incline) == exp_incline)
                    all_ok = pattern_ok and impact_ok and incline_ok
                    status = "OK" if all_ok else "MISMATCH"
                    print(f"    {name}: {status}")
                    if not all_ok:
                        print(f"      Expected: pattern={exp_pattern}, impact={exp_impact}, incline={exp_incline}")
                        print(f"      Actual:   pattern={actual_pattern}, impact={actual_impact}, incline={actual_incline}")
                else:
                    print(f"    {name}: NOT FOUND")

            # 6. Count exercises with is_dynamic_stretch set
            cur.execute("""
                SELECT is_dynamic_stretch, COUNT(*)
                FROM exercise_library
                WHERE is_dynamic_stretch IS NOT NULL
                GROUP BY is_dynamic_stretch
                ORDER BY is_dynamic_stretch
            """)
            rows = cur.fetchall()
            print("\n  Exercises by is_dynamic_stretch:")
            for val, cnt in rows:
                label = "dynamic" if val else "static"
                print(f"    {label}: {cnt}")

            # 7. Count exercises with hold times set
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE hold_seconds_min IS NOT NULL
            """)
            hold_count = cur.fetchone()[0]
            print(f"\n  Exercises with hold_seconds_min set: {hold_count}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 235 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
