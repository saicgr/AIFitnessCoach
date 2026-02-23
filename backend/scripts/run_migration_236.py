#!/usr/bin/env python3
"""
Run migration 236 - Backfill ~1500 existing strength exercises with metadata.

Uses pattern matching to bulk-classify exercises by:
  Movement pattern, mechanic type, force type, plane of motion,
  impact level, form complexity, stability requirement, energy system,
  default training parameters, and contraindicated conditions.

Depends on migration 235 (adds the 22 metadata columns).
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
    """Execute migration 236."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "236_backfill_strength_metadata.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 236: Backfill Strength Exercise Metadata")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Classifies movement patterns (push/pull/hinge/squat/lunge/isolation/carry/rotation)")
    print("  - Sets mechanic type (compound/isolation)")
    print("  - Sets force type (push/pull/dynamic)")
    print("  - Sets plane of motion (sagittal/frontal/transverse)")
    print("  - Sets impact level (low_impact for all strength)")
    print("  - Sets form complexity (1-5 from difficulty_level)")
    print("  - Sets stability requirement (stable/semi_stable)")
    print("  - Sets energy system (anaerobic_alactic)")
    print("  - Sets default training parameters (8-12 reps, 90s rest)")
    print("  - Sets contraindicated conditions (knee/back/shoulder)")
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
            # Movement pattern distribution
            cur.execute("""
                SELECT movement_pattern, COUNT(*)
                FROM exercise_library
                WHERE movement_pattern IS NOT NULL AND category = 'strength'
                GROUP BY movement_pattern
                ORDER BY COUNT(*) DESC
            """)
            rows = cur.fetchall()
            print("\n  Movement pattern distribution (strength):")
            total_mp = 0
            for pattern, cnt in rows:
                print(f"    {pattern}: {cnt}")
                total_mp += cnt
            print(f"    TOTAL with movement_pattern: {total_mp}")

            # Mechanic type distribution
            cur.execute("""
                SELECT mechanic_type, COUNT(*)
                FROM exercise_library
                WHERE mechanic_type IS NOT NULL AND category = 'strength'
                GROUP BY mechanic_type
                ORDER BY COUNT(*) DESC
            """)
            rows = cur.fetchall()
            print("\n  Mechanic type distribution (strength):")
            for mtype, cnt in rows:
                print(f"    {mtype}: {cnt}")

            # Force type distribution
            cur.execute("""
                SELECT force_type, COUNT(*)
                FROM exercise_library
                WHERE force_type IS NOT NULL AND category = 'strength'
                GROUP BY force_type
                ORDER BY COUNT(*) DESC
            """)
            rows = cur.fetchall()
            print("\n  Force type distribution (strength):")
            for ftype, cnt in rows:
                print(f"    {ftype}: {cnt}")

            # Plane of motion distribution
            cur.execute("""
                SELECT plane_of_motion, COUNT(*)
                FROM exercise_library
                WHERE plane_of_motion IS NOT NULL AND category = 'strength'
                GROUP BY plane_of_motion
                ORDER BY COUNT(*) DESC
            """)
            rows = cur.fetchall()
            print("\n  Plane of motion distribution (strength):")
            for plane, cnt in rows:
                print(f"    {plane}: {cnt}")

            # Form complexity count
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE form_complexity IS NOT NULL AND category = 'strength'
            """)
            fc_count = cur.fetchone()[0]
            print(f"\n  Exercises with form_complexity: {fc_count}")

            # Impact level count
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE impact_level IS NOT NULL AND category = 'strength'
            """)
            il_count = cur.fetchone()[0]
            print(f"  Exercises with impact_level: {il_count}")

            # Energy system count
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE energy_system IS NOT NULL AND category = 'strength'
            """)
            es_count = cur.fetchone()[0]
            print(f"  Exercises with energy_system: {es_count}")

            # Default training params count
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE default_rep_range_min IS NOT NULL AND category = 'strength'
            """)
            tp_count = cur.fetchone()[0]
            print(f"  Exercises with default_rep_range_min: {tp_count}")

            # Stability requirement distribution
            cur.execute("""
                SELECT stability_requirement, COUNT(*)
                FROM exercise_library
                WHERE stability_requirement IS NOT NULL AND category = 'strength'
                GROUP BY stability_requirement
                ORDER BY COUNT(*) DESC
            """)
            rows = cur.fetchall()
            print("\n  Stability requirement distribution (strength):")
            for stab, cnt in rows:
                print(f"    {stab}: {cnt}")

            # Contraindicated conditions count
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE contraindicated_conditions IS NOT NULL AND category = 'strength'
            """)
            cc_count = cur.fetchone()[0]
            print(f"\n  Exercises with contraindicated_conditions: {cc_count}")

            # Sample exercises to verify correctness
            print("\n  Sample exercises (verify correctness):")
            cur.execute("""
                SELECT exercise_name, movement_pattern, mechanic_type, force_type, plane_of_motion, form_complexity
                FROM exercise_library
                WHERE category = 'strength' AND movement_pattern IS NOT NULL
                ORDER BY exercise_name
                LIMIT 10
            """)
            rows = cur.fetchall()
            for name, mp, mt, ft, pom, fc in rows:
                print(f"    {name}: pattern={mp}, mechanic={mt}, force={ft}, plane={pom}, complexity={fc}")

            # Count strength exercises without movement_pattern (unclassified)
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE category = 'strength' AND movement_pattern IS NULL
            """)
            unclassified = cur.fetchone()[0]
            print(f"\n  Unclassified strength exercises (no movement_pattern): {unclassified}")

            # Total strength exercises
            cur.execute("""
                SELECT COUNT(*)
                FROM exercise_library
                WHERE category = 'strength'
            """)
            total_strength = cur.fetchone()[0]
            print(f"  Total strength exercises: {total_strength}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 236 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
