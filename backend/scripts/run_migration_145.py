#!/usr/bin/env python3
"""
Run migration 145 - Exercise Completion Sounds.

Adds exercise completion sound preferences to the sound_preferences table,
allowing users to customize the chime that plays when all sets of an exercise are done.
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
    """Execute migration 145."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "145_exercise_completion_sounds.sql"

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

        print(f"\nRunning migration: 145_exercise_completion_sounds.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 145 completed!")

        # Verify the columns were added
        with conn.cursor() as cur:
            cur.execute("""
                SELECT column_name, data_type, column_default
                FROM information_schema.columns
                WHERE table_name = 'sound_preferences'
                AND column_name IN ('exercise_completion_sound_enabled', 'exercise_completion_sound_type')
                ORDER BY column_name
            """)
            columns = cur.fetchall()
            if columns:
                print(f"\nVERIFIED: {len(columns)} column(s) added:")
                for col in columns:
                    print(f"  - {col[0]} ({col[1]}, default: {col[2]})")
            else:
                print("WARNING: Expected columns not found")

            # Check constraint was added
            cur.execute("""
                SELECT conname
                FROM pg_constraint
                WHERE conname = 'sound_preferences_exercise_completion_type_check'
            """)
            constraint = cur.fetchone()
            if constraint:
                print(f"VERIFIED: Constraint '{constraint[0]}' created")

        conn.close()
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"WARNING: Column or constraint already exists (this is OK)")
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
