#!/usr/bin/env python3
"""
Migration Runner Script for fixed migrations.
Runs the 9 corrected migrations against Supabase PostgreSQL database.
"""

import os
import sys
from pathlib import Path

import psycopg2
from psycopg2 import sql


# Database connection from environment
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")

# The 9 fixed migrations in order
FIXED_MIGRATIONS = [
    "077_performance_comparison.sql",
    "089_cardio_sessions.sql",
    "089_leverage_progressions.sql",
    "090_enhanced_sets_reps_control.sql",
    "096_progress_analytics.sql",
    "107_calibration_workouts.sql",
    "114_fasting_impact_analysis.sql",
    "116_muscle_analytics.sql",
    "119_food_search_cache.sql",
]


def get_migration_files():
    """Get the specific fixed migration files."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    files = []
    for migration in FIXED_MIGRATIONS:
        file_path = migrations_dir / migration
        if file_path.exists():
            files.append(str(file_path))
        else:
            print(f"WARNING: Migration file not found: {migration}")

    return files


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
    print("FitWiz Fixed Migration Runner")
    print("Running 9 fixed migrations")
    print("="*60)

    # Get migration files
    migration_files = get_migration_files()

    if not migration_files:
        print("No migration files found!")
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
