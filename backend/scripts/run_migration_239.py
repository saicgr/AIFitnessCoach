#!/usr/bin/env python3
"""
Run migration 239 - Add device info columns to users table.

Changes:
  - Adds device_model, is_foldable, os_version columns
  - Adds screen_width, screen_height columns
  - Adds last_device_update timestamp column
  - Adds indexes on is_foldable and device_platform for analytics
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
    """Execute migration 239."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "239_device_info_columns.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 239: Device Info Columns")
    print("=" * 60)
    print()
    print("This migration adds columns for:")
    print("  - device_model (VARCHAR(100))")
    print("  - is_foldable (BOOLEAN)")
    print("  - os_version (VARCHAR(20))")
    print("  - screen_width, screen_height (INT)")
    print("  - last_device_update (TIMESTAMPTZ)")
    print("  - Indexes on is_foldable and device_platform")
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
            cur.execute("""
                SELECT column_name, data_type, column_default
                FROM information_schema.columns
                WHERE table_name = 'users'
                  AND column_name IN (
                    'device_model', 'is_foldable', 'os_version',
                    'screen_width', 'screen_height', 'last_device_update'
                  )
                ORDER BY column_name
            """)
            rows = cur.fetchall()

            print(f"\n  New columns added ({len(rows)}/6):")
            for col_name, data_type, default in rows:
                default_str = f" DEFAULT {default}" if default else ""
                print(f"    {col_name}: {data_type}{default_str}")

            if len(rows) == 6:
                print("\n  All 6 columns verified!")
            else:
                missing = {'device_model', 'is_foldable', 'os_version',
                           'screen_width', 'screen_height', 'last_device_update'} - {r[0] for r in rows}
                print(f"\n  WARNING: Missing columns: {missing}")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 239 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
