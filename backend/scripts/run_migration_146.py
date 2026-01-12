#!/usr/bin/env python3
"""
Run migration 146 - Add Device Source Columns.

Adds device_source columns to track WearOS vs phone data across multiple tables.
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
    """Execute migration 146."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "146_add_device_source_columns.sql"

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

        print(f"\nRunning migration: 146_add_device_source_columns.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 146 completed!")

        # Verify columns were added
        tables = ['workout_logs', 'performance_logs', 'cardio_sessions', 'food_logs', 'weight_logs', 'fasting_sessions', 'workouts']
        with conn.cursor() as cur:
            for table in tables:
                cur.execute(f"""
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = '{table}'
                    AND column_name = 'device_source'
                """)
                col = cur.fetchone()
                if col:
                    print(f"  ✓ {table}.device_source")
                else:
                    print(f"  ✗ {table}.device_source NOT FOUND")

        conn.close()
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"WARNING: Column already exists (this is OK)")
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
