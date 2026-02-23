#!/usr/bin/env python3
"""
Run migration 255 - Add soft delete (SCD2) to food_logs.

Adds a deleted_at TIMESTAMPTZ column and a partial index on non-deleted rows.
Follows the same pattern as saved_foods and user_recipes tables.
"""

import os
import sys
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
    """Execute migration 255."""
    print("=" * 60)
    print("MIGRATION 255: Add Soft Delete to food_logs")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Adds deleted_at TIMESTAMPTZ column to food_logs")
    print("  - Creates partial index for efficient non-deleted queries")
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

        with open("backend/migrations/255_food_logs_soft_delete.sql", "r") as f:
            sql = f.read()

        print(f"\n{'=' * 60}")
        print("Executing migration SQL...")
        print("=" * 60)

        with conn.cursor() as cur:
            cur.execute(sql)

        conn.commit()
        print("SUCCESS: Migration applied!")

        # Verify
        print(f"\n{'=' * 60}")
        print("Verifying migration...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Check column exists
            cur.execute("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'food_logs' AND column_name = 'deleted_at'
            """)
            row = cur.fetchone()
            if row:
                print(f"  Column: {row[0]} ({row[1]})")
            else:
                print("  WARNING: deleted_at column NOT found!")

            # Check index exists
            cur.execute("""
                SELECT indexname
                FROM pg_indexes
                WHERE tablename = 'food_logs'
                  AND indexname = 'idx_food_logs_user_not_deleted'
            """)
            row = cur.fetchone()
            if row:
                print(f"  Index: {row[0]}")
            else:
                print("  WARNING: idx_food_logs_user_not_deleted index NOT found!")

        conn.close()
        print(f"\n{'=' * 60}")
        print("Migration 255 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
