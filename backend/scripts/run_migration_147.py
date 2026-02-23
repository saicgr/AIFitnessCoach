#!/usr/bin/env python3
"""
Run migration 147 - WearOS Sync Tracking.

Creates tables for WearOS sync events, workout completions, and heart rate samples.
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


def run_migration():
    """Execute migration 147."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "147_wearos_sync_tracking.sql"

    if not migration_file.exists():
        print(f"ERROR: Migration file not found: {migration_file}")
        return False

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

        print(f"\nRunning migration: 147_wearos_sync_tracking.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 147 completed!")

        # Verify tables were created
        with conn.cursor() as cur:
            cur.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                AND table_name IN ('wearos_sync_events', 'workout_completions', 'heart_rate_samples')
                ORDER BY table_name
            """)
            tables = cur.fetchall()
            if tables:
                print(f"\nVERIFIED: {len(tables)} table(s) created:")
                for t in tables:
                    print(f"  - {t[0]}")
            else:
                print("WARNING: Expected tables not found")

            # Check indexes
            cur.execute("""
                SELECT indexname
                FROM pg_indexes
                WHERE tablename IN ('wearos_sync_events', 'workout_completions', 'heart_rate_samples')
            """)
            indexes = cur.fetchall()
            if indexes:
                print(f"\nVERIFIED: {len(indexes)} index(es) created")

        conn.close()
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"WARNING: Table or index already exists (this is OK)")
            return True
        else:
            print(f"ERROR: {error_msg}")
            return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
