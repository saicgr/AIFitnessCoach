#!/usr/bin/env python3
"""
Run migration 153 - Stats Gallery for shareable stats images.

Creates:
1. stats_gallery table
2. RLS policies
3. Indexes
4. Updated_at trigger
"""

import sys
from pathlib import Path

import psycopg2


# Database connection
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def run_migration():
    """Execute migration 153."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "153_stats_gallery.sql"

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

        print(f"\nRunning migration: 153_stats_gallery.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 153 completed!")

        # Verify table was created
        with conn.cursor() as cur:
            cur.execute("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'stats_gallery'
                ORDER BY ordinal_position
            """)
            columns = cur.fetchall()
            print("\nCreated stats_gallery table with columns:")
            for col in columns:
                print(f"  - {col[0]}: {col[1]}")

        conn.close()
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
