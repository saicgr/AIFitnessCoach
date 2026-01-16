#!/usr/bin/env python3
"""
Run migration 155 - Weight Increments.

Creates:
1. weight_increments table
2. RLS policies
3. Indexes

Enables user-customizable weight increment settings per equipment type.
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
    """Execute migration 155."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "155_weight_increments.sql"

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

        print(f"\nRunning migration: 155_weight_increments.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 155 completed!")

        # Verify table was created
        with conn.cursor() as cur:
            cur.execute("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'weight_increments'
                ORDER BY ordinal_position
            """)
            columns = cur.fetchall()
            print("\nCreated weight_increments table with columns:")
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
