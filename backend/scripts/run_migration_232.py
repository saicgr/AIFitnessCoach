#!/usr/bin/env python3
"""
Run migration 232 - Fix Daily Login JSON Serialization.

Flattens the process_daily_login RPC response to avoid nested JSONB
which causes Supabase Python client serialization issues.

Changes:
- Removes nested active_events array (sets to NULL)
- Fixes field names: daily_bonus -> daily_xp, streak_bonus -> streak_milestone_xp
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
    """Execute migration 232."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = "232_fix_daily_login_json.sql"
    file_path = migrations_dir / migration_file

    print("=" * 60)
    print("MIGRATION 232: Fix Daily Login JSON Serialization")
    print("=" * 60)
    print()
    print("This migration flattens the process_daily_login RPC response:")
    print("  - Removes nested active_events array (sets to NULL)")
    print("  - Fixes field names: daily_bonus -> daily_xp")
    print("  - Fixes field names: streak_bonus -> streak_milestone_xp")
    print("  - Fixes Supabase Python client serialization issue")
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

        # Verify function was updated
        print("\n" + "=" * 60)
        print("Verifying updated function...")
        print("=" * 60)

        with conn.cursor() as cur:
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM pg_proc
                    WHERE proname = 'process_daily_login'
                )
            """)
            exists = cur.fetchone()[0]
            status = "YES" if exists else "NO"
            print(f"  {status} - process_daily_login()")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 232 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
