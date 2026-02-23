#!/usr/bin/env python3
"""
Run migration 238 - Add comprehensive health metrics columns to daily_activity.

Changes:
  - Adds hrv, blood_oxygen, body_temperature, respiratory_rate columns
  - Adds flights_climbed, basal_calories columns
  - Adds deep_sleep_minutes, light_sleep_minutes, awake_sleep_minutes, rem_sleep_minutes columns
  - Adds water_ml column
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
    """Execute migration 238."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "238_daily_activity_full_metrics.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 238: Daily Activity Full Health Metrics")
    print("=" * 60)
    print()
    print("This migration adds columns for:")
    print("  - HRV (RMSSD/SDNN), blood oxygen, body temperature, respiratory rate")
    print("  - Flights climbed, basal calories")
    print("  - Sleep phases (deep, light, awake, REM)")
    print("  - Water/hydration (ml)")
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
            # Verify all new columns exist
            cur.execute("""
                SELECT column_name, data_type, column_default
                FROM information_schema.columns
                WHERE table_name = 'daily_activity'
                  AND column_name IN (
                    'hrv', 'blood_oxygen', 'body_temperature', 'respiratory_rate',
                    'flights_climbed', 'basal_calories',
                    'deep_sleep_minutes', 'light_sleep_minutes', 'awake_sleep_minutes', 'rem_sleep_minutes',
                    'water_ml'
                  )
                ORDER BY column_name
            """)
            rows = cur.fetchall()

            print(f"\n  New columns added ({len(rows)}/11):")
            for col_name, data_type, default in rows:
                default_str = f" DEFAULT {default}" if default else ""
                print(f"    {col_name}: {data_type}{default_str}")

            if len(rows) == 11:
                print("\n  All 11 columns verified!")
            else:
                missing = {'hrv', 'blood_oxygen', 'body_temperature', 'respiratory_rate',
                           'flights_climbed', 'basal_calories',
                           'deep_sleep_minutes', 'light_sleep_minutes', 'awake_sleep_minutes', 'rem_sleep_minutes',
                           'water_ml'} - {r[0] for r in rows}
                print(f"\n  WARNING: Missing columns: {missing}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 238 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
