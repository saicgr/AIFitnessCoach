#!/usr/bin/env python3
"""
Run migration 136 - Optimize performance_logs for efficient exercise history queries.
"""

import os
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
    """Execute migration 136."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "136_optimize_performance_logs.sql"

    if not migration_file.exists():
        print(f"ERROR: Migration file not found: {migration_file}")
        return False

    print(f"Connecting to database...")

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

        print(f"\nRunning migration: 136_optimize_performance_logs.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 136 completed!")

        # Verify the function was created
        with conn.cursor() as cur:
            cur.execute("""
                SELECT routine_name
                FROM information_schema.routines
                WHERE routine_name = 'get_exercise_history'
            """)
            result = cur.fetchone()
            if result:
                print("VERIFIED: get_exercise_history function exists")
            else:
                print("WARNING: get_exercise_history function not found")

        conn.close()
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"WARNING: Some objects already exist (this is OK)")
            print(f"Details: {error_msg[:300]}")
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
