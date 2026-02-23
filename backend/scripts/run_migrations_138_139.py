#!/usr/bin/env python3
"""
Migration Runner Script for migrations 138-139.
Executes SQL migration files against the Supabase PostgreSQL database.
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
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


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
    print("Migrations 138-139")
    print("="*60)

    # Define migration files
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_files = [
        migrations_dir / "138_fix_workout_logs_service_role_rls.sql",
        migrations_dir / "139_add_timestamps.sql",
    ]

    # Check files exist
    for f in migration_files:
        if not f.exists():
            print(f"ERROR: Migration file not found: {f}")
            return 1

    print(f"\nFound {len(migration_files)} migration files to run:")
    for f in migration_files:
        print(f"  - {os.path.basename(f)}")

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

    # Track results
    results = {
        'success': [],
        'warnings': [],
        'errors': []
    }

    # Run each migration
    for file_path in migration_files:
        success, error = run_migration(conn, file_path)
        filename = os.path.basename(file_path)

        if success:
            if error == "already_exists":
                results['warnings'].append(filename)
            else:
                results['success'].append(filename)
        else:
            results['errors'].append((filename, error))

    # Close connection
    conn.close()

    # Print summary
    print("\n" + "="*60)
    print("MIGRATION SUMMARY")
    print("="*60)

    print(f"\nSuccessful: {len(results['success'])}")
    for f in results['success']:
        print(f"  + {f}")

    if results['warnings']:
        print(f"\nWarnings (objects already exist): {len(results['warnings'])}")
        for f in results['warnings']:
            print(f"  ~ {f}")

    if results['errors']:
        print(f"\nErrors: {len(results['errors'])}")
        for f, err in results['errors']:
            print(f"  X {f}")
            print(f"    {err[:200]}...")
        return 1

    print("\nAll migrations completed!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
