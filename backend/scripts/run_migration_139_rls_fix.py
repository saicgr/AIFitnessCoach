#!/usr/bin/env python3
"""
Migration Runner Script for migration 139 RLS fix.
Fixes the workout_logs RLS policy to properly allow service role access.
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection details
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def run_migration(conn, file_path):
    """Execute a single migration file."""
    filename = os.path.basename(file_path)
    print(f"\n{'='*60}")
    print(f"Running: {filename}")
    print(f"{'='*60}")

    try:
        with open(file_path, 'r') as f:
            sql_content = f.read()

        # Execute the SQL
        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print(f"SUCCESS: {filename}")
        return True, None

    except psycopg2.Error as e:
        conn.rollback()
        error_msg = str(e)

        # Check for common "already exists" errors which are often harmless
        if "already exists" in error_msg.lower():
            print(f"WARNING: {filename} - Some objects already exist (this is usually OK)")
            print(f"  Details: {error_msg[:200]}...")
            return True, "already_exists"
        else:
            print(f"ERROR: {filename}")
            print(f"  {error_msg}")
            return False, error_msg

    except Exception as e:
        conn.rollback()
        print(f"ERROR: {filename}")
        print(f"  {str(e)}")
        return False, str(e)


def main():
    """Main entry point."""
    print("\n" + "="*60)
    print("FitWiz Database Migration Runner")
    print("Migration 139 - Fix workout_logs RLS policy")
    print("="*60)

    # Define migration files
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "139_fix_workout_logs_rls_combined.sql"

    # Check file exists
    if not migration_file.exists():
        print(f"ERROR: Migration file not found: {migration_file}")
        return 1

    print(f"\nMigration file: {os.path.basename(migration_file)}")

    # Connect to database
    print(f"\nConnecting to database at {DATABASE_HOST}...")

    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST,
            port=DATABASE_PORT,
            dbname=DATABASE_NAME,
            user=DATABASE_USER,
            password=DATABASE_PASSWORD,
            connect_timeout=30
        )
        conn.autocommit = False
        print("Connected successfully!")
    except Exception as e:
        print(f"Failed to connect to database: {e}")
        return 1

    # Run migration
    success, error = run_migration(conn, migration_file)

    # Close connection
    conn.close()

    # Print result
    print("\n" + "="*60)
    print("MIGRATION RESULT")
    print("="*60)

    if success:
        if error == "already_exists":
            print("\nMigration completed with warnings (objects already exist)")
        else:
            print("\nMigration completed successfully!")
        return 0
    else:
        print(f"\nMigration failed: {error}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
