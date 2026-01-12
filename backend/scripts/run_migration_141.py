#!/usr/bin/env python3
"""
Run migration 141 - Add food image storage to food_logs.

Adds columns for S3 image URLs and source type tracking.
"""

import sys
from pathlib import Path

import psycopg2


# Database connection from environment
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def run_migration():
    """Execute migration 141."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "141_food_image_storage.sql"

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

        print(f"\nRunning migration: 141_food_image_storage.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 141 completed!")

        # Verify the columns were added
        with conn.cursor() as cur:
            cur.execute("""
                SELECT column_name, data_type, column_default
                FROM information_schema.columns
                WHERE table_name = 'food_logs'
                AND column_name IN ('image_url', 'image_storage_key', 'source_type')
                ORDER BY column_name
            """)
            columns = cur.fetchall()
            if columns:
                print(f"\nVERIFIED: New columns added to food_logs:")
                for col in columns:
                    default = f" (default: {col[2]})" if col[2] else ""
                    print(f"  - {col[0]}: {col[1]}{default}")
            else:
                print("WARNING: New columns not found in food_logs")

            # Check if index was created
            cur.execute("""
                SELECT indexname
                FROM pg_indexes
                WHERE tablename = 'food_logs'
                AND indexname = 'idx_food_logs_source_type'
            """)
            idx = cur.fetchone()
            if idx:
                print(f"VERIFIED: Index {idx[0]} created")

        conn.close()
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"WARNING: Column or index already exists (this is OK)")
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
